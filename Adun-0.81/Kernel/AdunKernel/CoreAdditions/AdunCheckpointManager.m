/*
   Project: AdunCore

   Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunCheckpointManager.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunSimulator.h"

@implementation AdCheckpointManager

+ (id) checkpointManagerForConfigurationGenerator: (AdConfigurationGenerator*) generator
		simulationDataWriter: (AdSimulationDataWriter*) aWriter
{		
	return [[[self new] 
			initWithConfigurationGenerator: generator
			simulationDataWriter: aWriter] autorelease];
}

- (id) initWithConfigurationGenerator: (AdConfigurationGenerator*) generator
	simulationDataWriter: (AdSimulationDataWriter*) aWriter
{	
	return [self initWithConfigurationGenerator: generator 
			lastGenerationStep: -1
			simulationDataWriter: aWriter];
}

- (id) initWithConfigurationGenerator: (AdConfigurationGenerator*) generator
	lastGenerationStep: (int) value
	simulationDataWriter: (AdSimulationDataWriter*) aWriter	
{	

	if((self = [super init]))
	{
		configurationGenerator = [generator retain];
		dataWriter = [aWriter retain];
	
		productionCheckpoints = [NSMutableArray new];
		
		//If the configuration generator value is not -1
		//then we set the production boundary and production checkpoint now.
		//This is because this means the configuration generator is being restarted
		//rather than started for the first time.
		//Otherwise we wait until production start
		//This information is not read from the configurationGenerator since it
		//is only set when the restart run actually starts.
		stepForCurrentFrame = value;
		if(stepForCurrentFrame != -1)
		{
			productionBoundary = [dataWriter lastFrame];
			[productionCheckpoints addObject: 
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt: stepForCurrentFrame], @"Step",
					[NSNumber numberWithInt: productionBoundary], @"Frame", nil]];			
		}
		
		energyInterval = 500;
		trajectoryInterval = 500;
		flushInterval = 500;
		
		//Use of names means this won't work if their is more than one
		//instance
		[[AdMainLoopTimer mainLoopTimer] 
			sendMessage: @selector(checkpointTrajectory)
			toObject: self
			interval: trajectoryInterval 
			name: @"TrajectoryCheckpoint"];
		[[AdMainLoopTimer mainLoopTimer] 
			sendMessage: @selector(checkpointEnergy)
			toObject: self
			interval: energyInterval
			name: @"EnergyCheckpoint"];
		[[AdMainLoopTimer mainLoopTimer] 
			sendMessage: @selector(synchToStore)
			toObject: dataWriter
			interval: flushInterval
			name: @"FlushEnergies"];	
		
		//Start her up ...	
		[self startCheckpointing];	
	}
	
	return self;
}

-(void) dealloc
{
	[self stopCheckpointing];
	[configurationGenerator release];
	[productionCheckpoints release];
	[dataWriter release];
	
	[[AdMainLoopTimer mainLoopTimer]
		removeMessageWithName: @"TrajectoryCheckpoint"];
	[[AdMainLoopTimer mainLoopTimer]
		removeMessageWithName: @"EnergyCheckpoint"];
	[[AdMainLoopTimer mainLoopTimer]
		removeMessageWithName: @"FlushEnergies"];	
	
	[super dealloc];
}

- (void) startCheckpointing
{
	checkpointsEnergy = YES;
	checkpointsTopology = YES;
	checkpointsTrajectory = YES;
	
	//Observe the required notifications
	//AdSystemContentsDidChangeNotification and 
	//AdConfigurationGeneratorWillBeginProductionNotification

	//Remove from all notification in case adding the same
	//one twice does something - docs unclear on this point
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleSystemContentsChange:)
		name: @"AdSystemContentsDidChangeNotification"
		object: nil];
	
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(handleProductionStart:)
		name: @"AdConfigurationGeneratorWillBeginProductionNotification"
		object: configurationGenerator];
}

- (void) stopCheckpointing
{
	checkpointsEnergy = NO;
	checkpointsTopology = NO;
	checkpointsTrajectory = NO;
	
	//Stop observing notifications
	[[NSNotificationCenter defaultCenter]
		removeObserver: self 
		name: @"AdSystemContentsDidChangeNotification" 
		object: nil];
		
	[[NSNotificationCenter defaultCenter]
		removeObserver: self 
		name: @"AdConfigurationGeneratorWillBeginProductionNotification" 
		object: configurationGenerator];
	
	[self synchronize];
}

- (void) resetCheckpointIntervals
{
	[[AdMainLoopTimer mainLoopTimer]
		resetCounterForMessageWithName: @"EnergyCheckpoint"];
	[[AdMainLoopTimer mainLoopTimer]
		resetCounterForMessageWithName: @"TrajectoryCheckpoint"];
	[[AdMainLoopTimer mainLoopTimer]
		resetCounterForMessageWithName: @"FlushEnergies"];
}

- (NSString*) description
{
	NSMutableString *string = [NSMutableString string];
	
	[string appendFormat: @"Energy Interval - %d\n", energyInterval];
	[string appendFormat: @"Configuration Interval - %d\n", trajectoryInterval];
	[string appendFormat: @"Energy flush interval - %d\n", flushInterval];
	
	return string;
}

- (void) synchronize
{
	[dataWriter closeFrame];
	[dataWriter synchToStore];
}

- (BOOL) checkpointsTrajectory
{
	return checkpointsTrajectory;
}

- (BOOL) checkpointsTopology
{
	return checkpointsTopology;
}

- (BOOL) checkpointsEnergy
{	
	return checkpointsEnergy;
}

- (void) setCheckpointsTopology: (BOOL) value
{
	checkpointsTopology = value;
}

- (void) setCheckpointsTrajectory: (BOOL) value
{
	checkpointsTrajectory = value;
}

- (void) setCheckpointsEnergy: (BOOL) value
{
	checkpointsEnergy = value;
}

- (unsigned int) flushInterval
{
	return flushInterval;
	
}

- (void) setFlushInterval: (unsigned int) value
{
	flushInterval = value;
	[[AdMainLoopTimer mainLoopTimer]
	 resetIntervalForMessageWithName: @"FlushEnergies" 
	 to: flushInterval];
}

- (unsigned int) energyCheckpointInterval
{
	return energyInterval;
}

- (unsigned int) trajectoryCheckpointInterval
{
	return trajectoryInterval;
}

- (void) setEnergyCheckpointInterval: (unsigned int) value
{
	energyInterval = value;
	[[AdMainLoopTimer mainLoopTimer]
		resetIntervalForMessageWithName: @"EnergyCheckpoint" 
		to: energyInterval];
}

- (void) setTrajectoryCheckpointInterval: (unsigned int) value
{
	trajectoryInterval = value;
	[[AdMainLoopTimer mainLoopTimer]
	 resetIntervalForMessageWithName: @"TrajectoryCheckpoint" 
	 to: trajectoryInterval];
}

- (AdSimulationDataWriter*) simulationDataWriter
{
	return [[dataWriter retain] autorelease];
}

/**
Returns the checkpoint number, the configuration generator step and
the simulation writer trajecotry frame number corresponding to the last time a trajecory was recored before \e limit
FIXME: Change how this is done.
*/
- (NSDictionary*) infoForLastTrajectoryCheckpointBeforeStep: (int) limitStep
{
	int i, step, frame, index;
	NSMutableDictionary* dict;
	AdSimulationData* dataReader;
	
	dataReader = [AdSimulationData new];
	[dataReader setDataStorage: [dataWriter dataStorage]];
	[dataReader loadData];
	
	//We should always find at least the first frame (step  -1)
	for(frame = 0, i=0; i<(int)[productionCheckpoints count]; i++)
	{
		frame = [[[productionCheckpoints objectAtIndex: i] 
			  objectForKey: @"Frame"] intValue];
		step = [[[productionCheckpoints objectAtIndex: i] 
			 objectForKey: @"Step"] intValue];
		if(step <= limitStep)
		{
			if([[dataReader dataRecordedInFrame: frame]
			    containsObject: @"Trajectory"])
				break;
		}		
	}
	
	dict = [[productionCheckpoints objectAtIndex: i] mutableCopy];
	
	//Find the trajectory checkpointing corresponding to frame
	for(i=(int)[dataReader numberTrajectoryCheckpoints] -1; i>=0; i--)
	{
		index = [dataReader frameForTrajectoryCheckpoint: i];
		if(index == frame)
			break;
	}
	
	[dict setObject: [NSNumber numberWithInt: i]
		 forKey: @"Checkpoint"];
	
	[dataReader autorelease];
	
	return [dict autorelease];
}

- (unsigned int) numberOfCheckpoints
{
	return [productionCheckpoints count];
}

- (unsigned int) stepForCurrentFrame
{
	return stepForCurrentFrame;
}

- (NSDictionary*) infoForCheckpoint: (unsigned int) number
{
	return [productionCheckpoints objectAtIndex: number];
}

@end

/**
AdCheckpointManager instances associate steps (iterations) of the configuration generator
with frames recorded by the simulation data writer.
For example the 10000 th step may be associated with the 10 frame.

The step associated with the frame be currently written (the 'open frame') is
held in the instance variable stepForCurrentFrame
*/

@implementation AdCheckpointManager (PrivateInternals)

/**
 Opens a frame for the current configuration generator step,
 closing the previously opened frame. 
 This method has no effect if called more than once for a given
 iteration of the configuration generator.
 This method also adds an entry to the productionCheckpoints array
 corresponding to the closed frame.
 */
- (void) openFrame
{
	int currentStep;
	NSNumber* number; 
	
	currentStep = [configurationGenerator currentStep];
	//Check if the current configuration generator step
	//is the same as the step associated with the current frame.
	if(currentStep == stepForCurrentFrame)
		return;		//We have already opened a frame for this iteration
	else
	{
		//This is a different iteration to the last one recorded
		//Close the last frame and open a new one.
		NSDebugLLog(@"AdCheckpointManager",
			    @"Opening new frame : Iteration %d - last iteration %d",
			    currentStep, stepForCurrentFrame);
			    
		if([dataWriter isOpenFrame])	    
			[dataWriter closeFrame];
		
		//Add an entry for the closed frame in productionCheckpoints	
		[productionCheckpoints insertObject: 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt: stepForCurrentFrame], 
				@"Step",
				[NSNumber numberWithInt: [dataWriter lastFrame]],
				@"Frame", nil]
					    atIndex: 0];
		//Update		
		stepForCurrentFrame = currentStep;
		if([configurationGenerator respondsToSelector: @selector(timeStep)])
		{
			number = [NSNumber numberWithDouble: 
				  currentStep*[(id)configurationGenerator timeStep]];
		}			
		else
			number = [NSNumber numberWithDouble: currentStep];
		
		[dataWriter openFrame: number];
	}
}

//Recieved when a production loop starts
- (void) handleProductionStart: (NSNotification*) notification
{
	//Close any frame open since the last
	[dataWriter closeFrame];
	[productionCheckpoints removeAllObjects];
	
	//Evaluate the current energies
	//This makes sure the correct energies are recorded
	[[configurationGenerator forceFields] evaluateEnergies]; 
	
	/*
	 Intial production checkpoint.
	 The timer is fired at the end of every step of the 
	 production loop. However since the first step is 0
	 this means iteration "0" will be the checkpoint
	 at the end of the first integration. Therefore we use -1
	 to indicate the initial energies/configuration
	 */
	[dataWriter openFrame: [NSNumber numberWithDouble: -1]];
	[dataWriter addTrajectoryCheckpoint];
	[dataWriter addEnergyCheckpoint];
	[dataWriter closeFrame];
	
	//Set the production boundary if it hasn't been set already.
	//We cant roll back past this point
	if(stepForCurrentFrame == -1)
	{
		productionBoundary = [dataWriter lastFrame];
		[productionCheckpoints addObject: 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt: stepForCurrentFrame], 
				@"Step",
				[NSNumber numberWithInt: productionBoundary],
				@"Frame", nil]];
	}
}

//Recieved when a system reloads its data
- (void) handleSystemContentsChange: (NSNotification*) aNotification
{
	id object;
	
	//Check if this is an AdSystem object
	//FIXME: This will have to change when AdInteractionSystems
	//can handle bonded interactions
	object = [aNotification object];
	if(![object isKindOfClass: [AdSystem class]])
		return;
	
	if(checkpointsTopology)
	{
		[self openFrame];
		NSDebugLLog(@"AdCheckpointManager",
			    @"Adding topology checkpoint to frame %d", stepForCurrentFrame);
		[dataWriter addTopologyCheckpointForSystem: object];
	}
	else
		NSDebugLLog(@"AdCheckpointManager",
			    @"Requested not to checkpoint topologies");
}

- (void) checkpointEnergy
{
	if([self checkpointsEnergy])
	{
		//Opens the frame if its not already open
		[self openFrame];
		[dataWriter addEnergyCheckpoint];
	}
}

- (void) checkpointTrajectory
{
	if([self checkpointsTrajectory])
	{
		[self openFrame];
		[dataWriter addTrajectoryCheckpoint];
	}
}

@end

@implementation AdCheckpointManager (RollBackMethods)

- (int) rollBackToLastCheckpoint
{
	int currentStep, limitStep, rollBackLimit;
	
	/* 
	 * Get the last trajectory checkpoint at least RollBackLimit steps before now
	 */
	currentStep = [configurationGenerator currentStep];
	rollBackLimit = [[NSUserDefaults standardUserDefaults]
			 integerForKey: @"RollBackLimit"];
	limitStep = currentStep - rollBackLimit;	
	NSWarnLog(@"Current step: %d", currentStep);
	
	return [self rollBackToLastCheckpointBeforeStep: limitStep];
}

//Break this into parts.
- (int) rollBackToLastCheckpointBeforeStep: (int) limitStep
{
	BOOL oldValue;
	int captureMask, index;
	int restartStep, restartFrame, topologyCheckpoint, restartCheckpoint;
	NSEnumerator* systemEnum;
	NSMutableArray* changedSystems = [NSMutableArray array];
	id dict;		
	id dataSource, memento, system;
	AdSystemCollection* initialCollection;
	AdSimulationData* dataReader;
	AdFileSystemSimulationStorage* storage;
	
	//Before beginning make sure all data is written out
	//and create a data reader.
	[dataWriter synchToStore];
	
	dataReader = [AdSimulationData new];
	storage = [[AdFileSystemSimulationStorage alloc]
		   initForReadingSimulationDataAtPath: 
		   [[dataWriter dataStorage] storagePath]];
	[dataReader setDataStorage: storage];			
	[dataReader loadData];
	
	/*
	 * The rolling back is complicated by a number of factors ....
	 * The steps:
	 * 1) Get the last trajectory checkpoint made after limitStep
	 *    without crossing any production boundaries. We dont cross these boundaries
	 *    because we cannot be sure of the relevance of any previous production run
	 *    to the current one.
	 * 2) Check for any topology changes in the interval between then and now.
	 *	A) If there was a change then:
	 *		i) Find who changed
	 *		ii) Find the last topology checkpoint for it before the choosen trajectory checkpoint
	 *		iii) If there is none use starting topology
	 * 3) Reset the system with the coordinates and possibly velocities/topology
	 * 	A) If no velocities reinitialise them
	 * 4) Roll back the simulation data
	 * 5) Reset all related AdCore instance variables
	 */
	
	//We cant go before step -1 (The very first checkpoint)
	if(limitStep < -1)
		limitStep = -1;
	
	NSWarnLog(@"Beginning roll back of simulation\n");
	NSWarnLog(@"Limit step %d. Last recorded frame %d", 
		  limitStep, [dataWriter lastFrame]);
	
	dict = [self infoForLastTrajectoryCheckpointBeforeStep: limitStep];
	restartStep = [[dict objectForKey: @"Step"] intValue]; 
	restartFrame = [[dict objectForKey: @"Frame"] intValue];
	restartCheckpoint = [[dict objectForKey: @"Checkpoint"] intValue];
	
	NSWarnLog(@"Restarting from production step %d. Frame %d. Trajectory checkpoint %d\n", 
		  restartStep, restartFrame, restartCheckpoint);
	
	//Check if any topology changes occured between restartFrame and now
	NSWarnLog(@"Checking for topology changes");
	if((topologyCheckpoint = [dataWriter lastTopologyCheckpoint]) > restartFrame)
	{
		NSWarnLog(@"Topology changed after the restart frame - in frame %d", topologyCheckpoint);
		NSWarnLog(@"Checking who changed");
		//Find who changed
		systemEnum = [[[dataWriter systems] fullSystems] objectEnumerator];
		while((system = [systemEnum nextObject]))
		{
			dataSource = [dataReader dataSourceForSystem: system
						inTopologyCheckpoint: topologyCheckpoint];
			if(dataSource != nil)
			{
				NSWarnLog(@"Changed system %@", [system systemName]);
				NSWarnLog(@"Marking for topology roll back");
				[changedSystems addObject: system];
			}	
		}
	}
	else
		NSWarnLog(@"None found");
	
	//Revert all systems to their state at restartFrame
	NSWarnLog(@"\n");
	NSWarnLog(@"Returning systems to their state at step %d", restartStep);
	systemEnum = [[[dataWriter systems] fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		NSWarnLog(@"System %@", [system systemName]);
		memento = [dataReader mementoForSystem: system 
				inTrajectoryCheckpoint: restartCheckpoint];
		if([changedSystems containsObject: system])
		{
			NSWarnLog(@"This system was marked for a topology roll back");
			dataSource = [dataReader lastRecordedDataSourceForSystem: system
									 inRange: NSMakeRange(0,restartFrame)];
			if(dataSource == nil)
			{
				//We have to retrieve the orginal data source
				initialCollection = [dataReader systemCollection] ;
				dataSource = [[initialCollection systemWithName: [system systemName]] 
					      dataSource];
			}
			NSWarnLog(@"Resetting and reloading topology");
			[system setDataSource: dataSource];
			[system reloadData];
			NSWarnLog(@"Complete");
		}	
		NSWarnLog(@"Rolling back dynamic state");
		[system returnToState: memento];
		NSWarnLog(@"Complete");
		//If no velocites were included in the memento reinitialise them now
		captureMask = [[memento valueForMetadataKey: @"MementoMask"]
			       intValue];
		if(!(captureMask & AdSystemVelocitiesMemento))
			[system reinitialiseVelocities];
	}
	
	NSWarnLog(@"\n");
	NSWarnLog(@"All systems rolled back. Deleting data acquired after restart step");
	//Delete all data after restartFrame
	[dataWriter rollBackToFrame: restartFrame];
	[dataReader release];
	[storage release];
	NSWarnLog(@"Complete. Simulation data synched to current state");
	
	/*
	 * We have to reset the checkpoint related instance variables 
	 * - frameIteration & productionCheckpoints - so they reflect the
	 * rolled back state. This means they must show that the last checkpointed
	 * frame was the restart frame. This is slightly tricky since AdCheckpointManager
	 * does not close a frame until the next one is open. Therefore we
	 * have to account for the fact that when openFrame() is next called
	 * it will peform frame closing related tasks on the restartFrame.
	 *
	 * To do this we remove all entries from productionCheckpoints that
	 * correspond to frames after the restart frame including the restartFrame
	 * itself. This is because when openFrame() closes the
	 * the restartFrame it will add data on it to productionCheckpoints.
	 * Hence we must remove its entry aswell to avoid duplicates.
	 */
	
	//The elements in the productionCheckpoints ivar are similar to dict.
	//The only difference is they don't have the Checkpoint key.
	//By removing this key we can use indexOfObject to find the correct entry.
	dict = [[dict mutableCopy] autorelease];
	[dict removeObjectForKey: @"Checkpoint"];
	
	NSWarnLog(@"Updating internal ivars to reflect new state");
	stepForCurrentFrame = restartStep;
	index = [productionCheckpoints indexOfObject: dict];
	[productionCheckpoints removeObjectsInRange: NSMakeRange(index, [productionCheckpoints count])];
	
	//Reset the timer
	[[AdMainLoopTimer mainLoopTimer] resetAll];
	
	//Broadcast a system contents did change for each system to ensure
	//everything is updated to the new coodinates 
	//We set checkpointsTopology to NO since we dont need to
	
	NSWarnLog(@"Notifying all objects of change in system contents\n");
	
	oldValue = checkpointsTopology;
	checkpointsTopology = NO;
	systemEnum = [[[dataWriter systems] fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		NSWarnLog(@"Broadcasting notification of change for %@", [system systemName]);
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"AdSystemContentsDidChangeNotification"
		 object: system];
		NSWarnLog(@"Done");
	}	
	checkpointsTopology = oldValue;
	
	//restartStep corresponds to the state we went back to. 
	//Since the state was captured at the end of this step any production
	//loop restarting should start from restartStep + 1
 	NSWarnLog(@"Roll back complete. The next production step will be step %d\n", restartStep + 1);
	
	return restartStep + 1;
}

@end

