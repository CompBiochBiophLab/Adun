/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
#define _GNU_SOURCE
#include <fenv.h>
#include "AdunKernel/AdunCore.h"
#include "AdunKernel/AdunController.h"

static id appCore = nil;
NSString* divider = @"-------------------------------------------------------------------------------\n";

@implementation AdCore

- (void) _createMinimiser
{
	minimiser = [[AdMinimiser alloc]
			initWithSystems: [configurationGenerator systems]
			forceFields: [configurationGenerator forceFields]
			absoluteTolerance: 0.01
			numberOfSteps: 15
			algorithm: @"BFGS"
			stepSize: 0.1
			tolerance: 0.1];
}

- (void) _minimise
{
	AdForceFieldCollection* forceFieldCollection;
	NSEnumerator *forceFieldEnum;
	id forceField;

	forceFieldCollection = [configurationGenerator forceFields];

	GSPrintf(stdout, @"%@", divider);
	GSPrintf(stdout, @"Initial energies:\n");
	[forceFieldCollection evaluateEnergies];
	forceFieldEnum = [[forceFieldCollection forceFields] objectEnumerator];
	while((forceField = [forceFieldEnum nextObject]))
		if([forceFieldCollection isActive: forceField])
			GSPrintf(stdout, @"System %@. Energy %lf\n",
				[[forceField system] systemName],
				[forceField totalEnergy]);
	
	fflush(stdout);
	[minimiser production: NULL];

	GSPrintf(stdout, @"\nFinal energies:\n");
	[forceFieldCollection evaluateEnergies];
	forceFieldEnum = [[forceFieldCollection forceFields] objectEnumerator];
	while((forceField = [forceFieldEnum nextObject]))
		if([forceFieldCollection isActive: forceField])
			GSPrintf(stdout, @"System %@. Energy %lf\n",
				[[forceField system] systemName],
				[forceField totalEnergy]);

	//Reset all the timers that were incremented
	//during the minmisation. 
	[[AdMainLoopTimer mainLoopTimer] resetAll];	
	GSPrintf(stdout, @"%@", divider);		
}

//Prints out information on the current simulator configuration
- (void) _printSummary
{
	NSEnumerator* enumerator;
	id object;

	GSPrintf(stdout, @"%@", divider);
	GSPrintf(stdout, @"\nDATA SOURCES\n\n");
	enumerator = [[systems fullSystems] objectEnumerator];
	while((object = [enumerator nextObject]))
		GSPrintf(stdout, @"%@\n", [[object dataSource] description]);
	
	GSPrintf(stdout, @"\nSYSTEMS\n\n");
	enumerator = [[systems allSystems] objectEnumerator];
	while((object = [enumerator nextObject]))
		GSPrintf(stdout, @"%@\n", [object description]);
		
	GSPrintf(stdout, @"\nFORCE FIELDS\n\n");
	enumerator = [[forceFields forceFields] objectEnumerator];
	while((object = [enumerator nextObject]))
		GSPrintf(stdout, @"%@\n", [object description]);
		
	GSPrintf(stdout, @"\nCONFIGURATION GENERATOR\n\n");
	GSPrintf(stdout, @"%@\n", [configurationGenerator description]);
	GSPrintf(stdout, @"\nCONTROLLER\n\n");
	GSPrintf(stdout, @"%@\n", [controller description]);
	GSPrintf(stdout, @"%@", divider);
}

/**
Creates the checkpoint manager for the simulation
*/
- (void) _createCheckpointManagerUsingTemplate: (NSDictionary*) template
		calculateLastGenerationStep: (BOOL) value
{		
	int lastIteration;
	double scaleFactor;
	NSString* iterationHeader;
	AdSimulationDataWriter* dataWriter;

	//Create the AdSimulationDataWriter object
	if([configurationGenerator respondsToSelector: @selector(timeStep)])
		iterationHeader = @"Time";
	else
		iterationHeader = @"Iteration";
	
	dataWriter = [[AdSimulationDataWriter alloc]
		      initWithDataStorage: [ioManager simulationWriteStorage] 
		      systems: systems
		      forceFields: forceFields
		      iterationHeader: iterationHeader];
	
	//If this is YES then the last step of the configuration generator
	//is to be calculated from the information in the data writer
	if(value)
	{
		//Unfortunately the value returned by [dataWriter lastIterationNumber]
		//does not always correpsond directly to the last configuration generation step
		//This has to be fixed e.g. set scale factor in the writer ...
		scaleFactor = 1.0;
		if([configurationGenerator respondsToSelector: @selector(timeStep)])
			scaleFactor = [(AdSimulator*)configurationGenerator timeStep];
		
		lastIteration = [[dataWriter lastIterationNumber] doubleValue]/scaleFactor;
	}
	else
		lastIteration = -1;
		
	//Create the checkpoint manager		
	checkpointManager = [[AdCheckpointManager alloc]
			     initWithConfigurationGenerator: configurationGenerator
			     lastGenerationStep: lastIteration
			     simulationDataWriter: dataWriter];
	[checkpointManager setEnergyCheckpointInterval: 
		[[template valueForKeyPath: @"checkpoint.energy"] intValue]];
	[checkpointManager setTrajectoryCheckpointInterval: 
		[[template valueForKeyPath: @"checkpoint.configuration"] intValue]];				
	[checkpointManager setFlushInterval:
		[[template valueForKeyPath: @"checkpoint.energyDump"] intValue]];
}

/*
 * Creation/Destruction
 */

+ (id) appCore
{
	if(appCore == nil)
		return [AdCore new];
	else
		return appCore;
}

- (id) init
{
	if(appCore != nil)
		return appCore;

	if((self = [super init]))
	{	
		corePool = [[NSAutoreleasePool alloc] init];
		commandErrors = [NSMutableDictionary new];
		//\note This may not be necessary - Leaving as a test
		commandResults = [NSMutableDictionary new];
		validCommands = [NSArray arrayWithObjects: 
					@"flushEnergies", 
					@"status", 
					@"reload",
					@"endSimulation", 
					@"controllerResults",
					 nil];
		[validCommands retain];

		//If the core has to exit for any reason this
		//notification will be posted
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(simulationFinished:)
			name: @"AdSimulationDidFinishNotification"
			object: nil];

		[[NSUserDefaults standardUserDefaults]
			registerDefaults: 
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt: 100], 
					@"RollBackLimit", 
					[NSNumber numberWithInt: 5],
					@"MaximumRestartAttempts",
					[NSNumber numberWithBool: YES],
					@"InitialMinimisation",
					nil]];

		memoryManager = [AdMemoryManager new];
		ioManager = [AdIOManager appIOManager];
		runLoopIsRunning = NO;
		endSimulation = NO;
		terminationError = nil;

		appCore = self;
	}	
	return self;
}

- (void) dealloc
{	
	NSDebugLLog(@"AdCore", @"Beginning deallocation");
	[corePool release];
		
	if([[NSUserDefaults standardUserDefaults]
		boolForKey: @"RunInteractive"])
	{	
		/*
		 * We need to make sure the thread gets a chance to 
		 * finish as if it doesn't it wont be deallocated.
		 * This is a problem since the thread retains the object 
		 * it was detached from (i.e. the controller) and hence 
		 * that object wont be released when the core exits if
		 * the thread hasn't already exited.
		 *
		 * If the controller retain count is not equal to one 
		 * the thread has not exited. Therefore we wait until 
		 * it is one before proceeding with deallocation so we can 
		 * be sure it will be released.
		*/

		if(controller != nil)
			while([controller retainCount] != 1)
				sleep(1);
	}			

	[checkpointManager release];
	[date release];
	[minimiser release];
	[configurationGenerator release];
	[controller release];
	[externalObjects release];
	[validCommands release];
	[terminationError release];
	NSDebugLLog(@"AdCore", @"Deallocation complete");
	[super dealloc];
}

- (BOOL) setup: (NSError**) error
{
	NSDictionary* template;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	GSPrintf(stdout, @"%@", divider);
	template = [ioManager template];
	externalObjects = [ioManager externalObjects];
	
	templateProcessor = [AdTemplateProcessor new];
	GSPrintf(stdout, @"Validating simulation template\n");
	if(![templateProcessor validateTemplate: &template error: error])
		return NO;

	GSPrintf(stdout, @"Validation complete\n\n");
	[templateProcessor setTemplate: template];
	[templateProcessor setExternalObjects: externalObjects];
	GSPrintf(stdout, @"Processing simulation template\n");
	if(![templateProcessor processTemplate: error])
		return NO;
	
	controller = [[templateProcessor controller] retain];
	configurationGenerator = [[templateProcessor configurationGenerator] retain];
	if(configurationGenerator != nil)
	{
		systems = [configurationGenerator systems];
		//FIXME Will all configuration generators use force fields?
		forceFields = [configurationGenerator forceFields];
		
	}
	externalObjects = [[templateProcessor externalObjects] retain];
	GSPrintf(stdout, @"Processing complete\n");
	GSPrintf(stdout, @"%@", divider);

	//Add references to the external object to the simulation data
	[ioManager setSimulationReferences: externalObjects];

	//Print a summary of the simulators state
	[self _printSummary];

	if(configurationGenerator != nil)
	{
		//Create a minimiser that will deal with exploding simulations
		//and perform an inital minimisation before beginning (if requested)	
		[self _createMinimiser];
		if([[NSUserDefaults standardUserDefaults] 
		    boolForKey: @"InitialMinimisation"])
		{	
			[self _minimise];
		}	
		else
			GSPrintf(stdout, @"Skipping initial minimisation as requested\n");
	
		GSPrintf(stdout, @"%@", divider);
		[self _createCheckpointManagerUsingTemplate: template 
				calculateLastGenerationStep: NO];
		
		GSPrintf(stdout, @"\n%@\n", [checkpointManager description]);
		
		GSPrintf(stdout, @"%@", divider);		
	}
			
	[templateProcessor release];
	[pool release];
	AdLogMemoryUsage();

	return YES;
}

- (BOOL) prepareRestart: (NSError**) error
{
	NSDictionary* template;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	/*
	 * Similar to setup: but with different log messages
	 */
	
	NSDebugLLog(@"AdCore", @"\n");  
	NSDebugLLog(@"AdCore", @"Setting up restart");  
	
	GSPrintf(stdout, @"%@", divider);
	template = [ioManager template];
	externalObjects = [ioManager externalObjects];
	
	NSDebugLLog(@"AdCore", @"Recreating simulator from template"); 
	templateProcessor = [AdTemplateProcessor new];
	GSPrintf(stdout, @"Validating stored simulation template\n");
	if(![templateProcessor validateTemplate: &template error: error])
		return NO;
	
	GSPrintf(stdout, @"Validation complete\n\n");
	[templateProcessor setTemplate: template];
	[templateProcessor setExternalObjects: externalObjects];
	GSPrintf(stdout, @"Recreating simulation template\n");
	if(![templateProcessor processTemplate: error])
		return NO;
	
	configurationGenerator = [[templateProcessor configurationGenerator] retain];
	systems = [configurationGenerator systems];
	forceFields = [configurationGenerator forceFields];
	controller = [[templateProcessor controller] retain];
	externalObjects = [[templateProcessor externalObjects] retain];
	GSPrintf(stdout, @"Recreation complete\n");
	GSPrintf(stdout, @"%@", divider);
	NSDebugLLog(@"AdCore", @"Done"); 
	
	NSDebugLLog(@"AdCore", @"\n");  
	
	//Set up checkpointing.
	NSDebugLLog(@"AdCore", @"Setting up checkpointing");  
	
	GSPrintf(stdout, @"%@", divider);
	
	[self _createCheckpointManagerUsingTemplate: template 
		calculateLastGenerationStep: YES];
	
	GSPrintf(stdout, @"\n%@\n", [checkpointManager description]);
	GSPrintf(stdout, @"%@", divider);
	
	NSDebugLLog(@"AdCore", @"Done"); 
	
	[templateProcessor release];
	[pool release];
	
	/*
	 * Now set the simulator state to its last recorded state
	 * Unfortunately no data is stored on the checkpoints in the previous run.
	 * That is the configuration generator step, frame number and number of previous
	 * checkpoints is not recorded.
	 * To overcome this problem rollbacks beyond the restart point are disabled.
	 */
	
	NSDebugLLog(@"AdCore", @"\n");   
	NSDebugLLog(@"AdCore", 
		@"Restoring simulation to last recorded state using roll-back mechanisms");		
				
	tempRestartVar = [checkpointManager rollBackToLastCheckpointBeforeStep: 
				[checkpointManager stepForCurrentFrame] + 1];
	
	NSDebugLLog(@"AdCore", 
		    @"Simulation ready to be restarted\n");	
	
	return YES;		
}

- (id) main: (NSDictionary*) dict
{
	GSPrintf(stdout, @"Calling controller %@\n", NSStringFromClass([controller class]));

	[controller coreWillStartSimulation: self];
	date = [[NSDate date] retain]; 
	terminationError = nil;

	if([[NSUserDefaults standardUserDefaults]
		boolForKey: @"RunInteractive"])
	{	
		//FIXME: No support for restaring in interactive mode yet
		if([ioManager restartRequested])
		{	
			terminationError = AdCreateError(AdunCoreErrorDomain, 
						AdCoreControllerError, 
						@"Unable to restart simulation",
						@"Simulation restarting not supported in interactive mode", 
						@"This featured is in the process of being added. Set RunInteractive to NO for now");
		}
		
		//Run threaded
		[controller runThreadedController];
		GSPrintf(stdout, @"Entering run loop\n");
		[self startRunLoop];
	}
	else
	{
		//FIXME: Temporary restart implementation
		//Need to find a good way of restarting a controller as 
		//obvioulsly just passing frameIteration will no be enough info.
		if([ioManager restartRequested])
		{
			//Only the default controller can be restarted.
			//Corresponds to a normal simulation
			if([controller respondsToSelector: @selector(restartController:)])
			{
				NSDebugLLog(@"AdCore", @"\n");
				NSDebugLLog(@"AdCore",
					@"Continuing simulation from step %d", tempRestartVar);
				[controller restartController: tempRestartVar];
			}
			else
			{
				terminationError = AdCreateError(AdunCoreErrorDomain, 
							AdCoreControllerError,
							@"Unable to restart simulation",
							[NSString stringWithFormat: 
								@"Controller %@ does not support restarting via Continue command",
								NSStringFromClass([controller class])],
							@"Currenly only simulations using the default controller can be restarted");
			}
				
		}
		else
		{
			//Run normally
			[controller runController];
		}
	}
		
	/*
	 * Check if the controller exited due to an error. This will
	 * be posted to AdunServer (or logged) when clean up is called.
	*/	
	terminationError = [[controller controllerError] retain];
	if(terminationError !=  nil)
		NSWarnLog(@"Error %@", [terminationError userInfo]);
	
	return nil;
}

- (void) cleanUp
{
	AdSimulationData* dataReader;
	id storage;

	GSPrintf(stdout, @"Requesting controller clean up\n");
	[controller cleanUp];
	GSPrintf(stdout, @"Saving system state\n");

	if(checkpointManager != nil)
	{
		//Close any frame that may be open
		[checkpointManager synchronize];
		
		//Output information on what was collected
		//FIXME: The checkpoint manager should be able to do this
		GSPrintf(stdout, @"Simulation data summary -\n\n");
		dataReader = [AdSimulationData new];
		storage = [[AdFileSystemSimulationStorage alloc]
			   initForReadingSimulationDataAtPath: 
			   [[[checkpointManager simulationDataWriter] 
			     dataStorage] storagePath]];
		[dataReader setDataStorage: storage];			
		[dataReader loadData];
		GSPrintf(stdout, @"%@", [dataReader description]);
		[dataReader release];
	}
		
	GSPrintf(stdout, @"Outputting controller results (if any)\n");
	/*
	 * This will raise an exception if the entires in results are not
	 * all AdDataSets. We do not catch this error since this indicates
	 * a programmatic problem with the controller used.
	 */
	NSDebugLLog(@"AdCore", @"Outputting controller results\n");
	[ioManager saveResults: [controller simulationResults]];
	NSDebugLLog(@"AdCore", @"Complete");
}

- (id) flushEnergies: (NSDictionary*) aDict
{
	[[checkpointManager simulationDataWriter] synchToStore];
	return nil;
}

- (id) controllerResults: (NSDictionary*) options
{
	return [controller simulationResults];
}

- (NSError*) terminationError
{
	return [[terminationError retain] autorelease];
}

- (AdConfigurationGenerator*) configurationGenerator
{
	return [[configurationGenerator retain] autorelease];
}

- (AdCheckpointManager*) checkpointManager
{
	return [[checkpointManager retain] autorelease];
}

- (id) controller
{
	return [[controller retain] autorelease];
}

/*
 * AdCoreCommand Protocol Methods
 */

- (NSMutableDictionary*) optionsForCommand: (NSString*) name
{
	SEL methodSelector;
	NSString* methodName;

	methodName = [NSString stringWithFormat: @"%@Options", name];
	methodSelector = NSSelectorFromString(methodName);
	if(![self respondsToSelector: methodSelector])
		return nil;
	else
		return [self performSelector: methodSelector];
}

- (BOOL) validateCommand: (NSString*) name
{
	SEL command;

	NSDebugLLog(@"Execute", @"Validating command %@", name);

	command = NSSelectorFromString([NSString stringWithFormat: @"%@:", name]);
	return [self respondsToSelector: command];
}

- (NSError*) errorForCommand: (NSString*) name
{
	return [commandErrors objectForKey: name];
}

- (NSArray*) validCommands
{
	return validCommands;
}

- (void) setErrorForCommand: (NSString*) name description: (NSString*) description
{
	id error;

	error = AdCreateError(AdunCoreErrorDomain,
			AdCoreCommandError,
			@"A command error has occured",
			description,
			nil);
	
	[commandErrors setValue: error forKey: name];
}

@end


//Methods dealing with interactivity and threading
@implementation AdCore (AdCoreInteractionModeExtensions)

- (void) startRunLoop
{
	/*
	 * We stay in the run loop until the simulation finishes.
	 * When this happens we disconnect from the server and the runloop should end.
	 * Unfortunately I cannot get the runloop to exit gracefully. 
	 * Even though all the connections are invalidated limitDateForMode: still
	 * returns [NSDate distantFuture] for NSConnectionReplyMode. This implies
	 * there is still an input source in the runloop however its impossible	
	 * to find what it is. 
	 * Instead we have to use a flag which is set to true when the core 
	 * receives a simulationFinished notification - less elegant but what
	 * can you do?
	**/

	if(!runLoopIsRunning)
	{
		runLoopIsRunning = YES;
		//send server message indicating core is ready to recieve requests
		[ioManager acceptRequests];
		//End simulation is set to YES when simulationFinished is called.
		while(!endSimulation)
			[[NSRunLoop currentRunLoop] 
				runMode: NSDefaultRunLoopMode
				beforeDate: nil];

		runLoopIsRunning = NO;
	}
}

- (BOOL) simulationIsRunning
{
	return runLoopIsRunning;
}

/**
This method is called when the core recieves a AdSimulationDidFinishNotification. 
Set endSimulation to YES so we will break out of the runloop if it is running.
Note that this method is usually only sent by an AdController instance when it
has been running in a threaded mode.
*/
- (void) simulationFinished: (NSNotification*) aNotification
{
	endSimulation = YES;
}
@end

@implementation AdCore (AdCoreRollBackExtensions)

- (int) rollBackAndMinimise
{
	int restartPoint;

	//Rollback the simulation to the last checkpoint

	GSPrintf(stdout, @"Beginning roll back of simulation\n");
	restartPoint = [checkpointManager rollBackToLastCheckpoint];
	GSPrintf(stdout, @"Roll back complete. The next production step will be step %d\n", 
		 restartPoint);
	
	//Perform a minimisation on the starting state for the restartStep
	//First the checkpoint timers have to be removed and reset
	//to avoid polluting the trajectory with the minimisation data.
	 
	[checkpointManager stopCheckpointing]; 
	
	NSWarnLog(@"Beginning minimisation of rolled back state");
	GSPrintf(stdout, @"Beginning minimisation of rolled back state\n");
	
	[minimiser setNumberOfSteps: 1000];
	[self _minimise];
	
	NSWarnLog(@"Minimisation complete - Resetting notifications");

	//Re-start checkpointing
	//We also have to reset checkpoint intervals since the relevant
	//timers are not reset when checkpointing is stopped (see AdCheckpointManager docs).
	[checkpointManager resetCheckpointIntervals];
	[checkpointManager startCheckpointing];
	
	NSWarnLog(@"Done");
	GSPrintf(stdout, @"Minimisation complete\n");
	
	return restartPoint;
}

@end
