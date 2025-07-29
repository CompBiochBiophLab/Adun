/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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

#include "AdunKernel/AdunController.h"
#include "AdunKernel/AdunCore.h"

NSBundle* AdLoadController(NSString* controllerName, NSError** error)
{
	NSString* controllerDir;
	NSBundle *controllerBundle;
	NSError* loadError;
	Class controllerClass; 
	
	NSDebugLLog(@"AdController", @"Validating controller %@", controllerName);
	controllerDir = [[AdIOManager appIOManager] controllerDirectory];
	
#ifdef GNUSTEP	
	NSDebugLLog(@"AdController",
		    @"Dynamicaly loading controller from directory: %@",
		    [controllerDir stringByAppendingPathComponent: controllerName]);
	controllerBundle = [NSBundle bundleWithPath: 
			    [controllerDir stringByAppendingPathComponent: controllerName]];
#else				
	controllerName = [controllerName stringByAppendingPathExtension: @"bundle"];
	NSDebugLLog(@"AdController",
		    @"Dynamicaly loading controller from directory: %@",
		    [controllerDir stringByAppendingPathComponent: controllerName]);
	controllerBundle = [NSBundle bundleWithPath: 
			    [controllerDir stringByAppendingPathComponent: controllerName]];
	controllerName = [controllerName stringByDeletingPathExtension];
#endif			    
	
	if(controllerBundle == nil)
	{
		//Set error
		loadError = AdCreateError(AdControllerErrorDomain, 
				AdControllerDoesNotExistError, 
				@"Error loading controller",
				[NSString stringWithFormat: 
					@"Controller %@ is not present in the controller directory (%@)", 
					controllerName, controllerDir],
				@"The controller may not have been installed or may be installed into the wrong location");
		AdLogError(loadError);
		if(error != NULL)
			*error = loadError;
			
		return nil;	
	}
	
	NSDebugLLog(@"AdController", @"Searching for main class");
	if((controllerClass = [controllerBundle principalClass]) != nil)
	{ 
		NSDebugLLog(@"AdController", @"Found main class = %@.", 
			    NSStringFromClass(controllerClass));
		
		NSDebugLLog(@"AdController", 
			    @"Testing if controller class conforms to AdController protocol.");
		if([controllerClass  conformsToProtocol:@protocol(AdController)])
		{
			NSDebugLLog(@"AdController", @"Controller class validated."); 
		}
		else
		{
			loadError = AdCreateError(AdControllerErrorDomain, 
						  AdControllerPrincipalClassDoesNotConfromToProtocolError, 
						  @"Error loading controller",
						  [NSString stringWithFormat: 
							@"Controllers principal class (%@) does not conform to the AdController protocol", 
							controllerClass],
						  @"This is a bug - Please contact the controller developers");
			AdLogError(loadError);
			if(error != NULL)
				*error = loadError;
			
			return nil;
		}
		
		if(![NSStringFromClass(controllerClass) isEqual: controllerName])
		{
			loadError = AdCreateError(AdControllerErrorDomain, 
						  AdControllerPrincipalClassDoesNotConfromToProtocolError, 
						  @"Error loading controller",
						  [NSString stringWithFormat: 
							@"Controller name (%@) and principal class name (%@) do not match",
							controllerName, NSStringFromClass(controllerClass)],
						  @"The main controller class should have the same name as the controller.\n"
						  @"However this is not an absolute requirement and this may not be a critical error");
			AdLogError(loadError);
			if(error != NULL)
				*error = loadError;
		}
	}
	else
	{
		loadError = AdCreateError(AdControllerErrorDomain, 
					  AdControllerPrincipalClassDoesNotConfromToProtocolError, 
					  @"Error loading controller",
					  [NSString stringWithFormat: @"Controller (%@) has no principal class", controllerName],
					  @"This is a bug - Please contact the controller developers.\n");
		AdLogError(loadError);
		if(error != NULL)
			*error = loadError;
		
		return nil;
	}
	
	return controllerBundle;
}

@implementation AdController

+ (Class) principalClassForController: (NSString*) controllerName error: (NSError**) error
{
	NSBundle* controllerBundle;
	Class controllerClass = nil;
	
	controllerBundle = AdLoadController(controllerName, error);
	if(controllerBundle != nil)
	{
		controllerClass = [controllerBundle principalClass];
	}
	
	return controllerClass;
}

- (id) init
{
	if((self = [super init]))
	{
		//This variable is used to communicate an error
		//in controller processing
		controllerError = nil;
		//by default we notify the core when we have finished
		notifyCore = YES;
		//Temporary ivar until better restart mechanisims added
		restartMode = NO;
		restartStep = 0;
		maxAttempts = [[NSUserDefaults standardUserDefaults] 
				integerForKey: @"MaximumRestartAttempts"];
	}

	return self;
}

- (void) dealloc
{
	[super dealloc];	
}

- (void) coreWillStartSimulation: (AdCore*) object
{
	core = object;
	configurationGenerator = [core configurationGenerator];
}

- (BOOL) handleSimulationError: (NSError**) error
{
	int errorCode, restartPoint, restartAttempts;
	BOOL retval=NO, attemptRestart;
	NSString* errorDomain;
	NSError* productionError;
	
	restartAttempts = 0;
	attemptRestart = YES;
	
	do
	{
		productionError = *error;
		errorDomain = [productionError domain];
		errorCode = [productionError code];
		//If the controller error code is AdKernelSimulationSpaceError
		//we attempt to correct the problem and restart
		NSWarnLog(@"Detected error from domain %@ - code %d", 
			  errorDomain, errorCode);
		if([errorDomain isEqual: AdunKernelErrorDomain] && 
		   errorCode == AdKernelSimulationSpaceError)
		{
			
			NSWarnLog(@"Error caused by exploding simulation");
			NSWarnLog(@"Attempting to fix");
			GSPrintf(stdout, @"Detected simulation explosion.\nAttempting to fix.\n");
			restartPoint = [core rollBackAndMinimise];
			NSWarnLog(@"Restarting from step %d - Total attempts so far %d", 
				  restartPoint, restartAttempts);
			*error = nil;
			retval = [configurationGenerator
				  restartFrom: restartPoint 
				  error: error];
			restartAttempts++;	
			if(restartAttempts == maxAttempts)
			{
				NSWarnLog(@"Could not finish production after %d restart attempts",
					  restartAttempts);
				NSWarnLog(@"Giving up");
				GSPrintf(stdout, @"Aborting production after %d restart attempts\n", 
					 restartAttempts);
				attemptRestart = NO;
			}	
		}
		else
		{
			attemptRestart = NO;
			NSWarnLog(@"Cannot handle error - exiting");
			GSPrintf(stdout, @"Detected error during production\n");
			GSPrintf(stdout, @"Unable to handle it. Exiting ...\n");
		}	
	}		
	while(!retval && attemptRestart);
	
	return retval;
}

/**
Wrapper around the configuration generators production method
adding handling of exploding simulations.
*/
- (BOOL) production: (NSError**) error 
{
	BOOL retval;

	NSDebugLLog(@"SimulationLoop",
		@"Calling production on %@", configurationGenerator);
	//Initial attempt	
	retval = [configurationGenerator production: error];

	//If it failed see can the error be handled
	if(!retval)
		retval = [self handleSimulationError: error];

	return retval;
}

/**
 Wrapper around the configuration generators restart method
 adding handling of exploding simulations.
 */
- (BOOL) restartFrom: (unsigned int) step error: (NSError**) error 
{
	BOOL retval;
	
	NSDebugLLog(@"SimulationLoop",
		    @"Calling production on %@", configurationGenerator);
	//Initial attempt	
	retval = [configurationGenerator restartFrom: step error: error];
	
	//If it failed see can the error be handled
	if(!retval)
		retval = [self handleSimulationError: error];
	
	return retval;
}

/**
Main method - Overridden by subclasses
*/
- (void) runSimulation
{
	if(controllerError != nil)
	{
		[controllerError release];
		controllerError = nil;
	}

	[self production: &controllerError];
	
	if(controllerError != nil)
		[controllerError retain];
}

/*
Testing restart method
*/
- (void) restartSimulation: (int) step
{
	if(controllerError != nil)
	{
		[controllerError release];
		controllerError = nil;
	}
	
	[self restartFrom: step error: &controllerError];
	
	if(controllerError != nil)
		[controllerError retain];
}

/*
Testing restart method - This is likely to change
*/
- (void) restartController: (unsigned int) step
{
	restartStep = step;
	restartMode = YES;
	[self runController];
}

- (void) runController
{
	NSError *error, *underlyingError;
	NSMutableDictionary* dict;

	/*
	 * We want to catch all exceptions since they will end the simulation
	 * and we want to notify the user what the cause of the failure was.
	 */
	NS_DURING
	{
		//do the controller work
		//FIXME: Temp method for doing a restart with the default controller
		if(restartMode)
		{
			[self restartSimulation: restartStep];
		}
		else
			[self runSimulation];
	}	
	NS_HANDLER
	{
		error = [[localException userInfo] 
				objectForKey: @"AdKnownExceptionError"];
		if(error == nil)
		{
			NSWarnLog(@"Simulation exited unexpectedly");
			NSWarnLog(@"Local Exception name %@", [localException name]);
			NSWarnLog(@"Reason %@",  [localException reason]);
			NSWarnLog(@"User info %@", [localException userInfo]);
		
			//Controller exceptions should have a key AdControllerException in 
			//their user info
			if([[localException userInfo] objectForKey: @"AdControllerException"] != nil)
			{
				underlyingError = AdCreateError(AdunCoreErrorDomain,
							AdCoreControllerError,
							@"Caught an exception from controller",
							[NSString stringWithFormat: 
								@"Name %@. Reason %@", 
								[localException name], [localException reason]],
							[NSString stringWithFormat: @"User info %@", 
								[localException userInfo]]);
				controllerError = AdErrorWithUnderlyingError(AdunCoreErrorDomain,
							AdCoreControllerError,
							@"Controller exited due to an exception",
							@"This could be due to a bug in the controller",
							@"Notify the controller developer of the problem supplying the simulation log.",
							underlyingError);
			}
			else
			{
				//Its an unknown framework exception
				controllerError = AdCreateError(AdunKernelErrorDomain,
							AdKernelUnknownError,
							@"Caught an exception from framework",
							[NSString stringWithFormat: 
								@"Name %@. Reason %@", 
								[localException name], [localException reason]],
							[NSString stringWithFormat: @"User info %@", 
								[localException userInfo]]);
			}					
		}
		else
		{
			controllerError = AdErrorWithUnderlyingError(AdunCoreErrorDomain,
						AdCoreControllerError,
						@"Controller exited due to a known exception",
						@"Known exceptions are caused by common simulation problems.",
						@"See the underlying error for recovery information.",
						error);
		}
	}
	NS_ENDHANDLER
}

- (id) simulationResults
{
	return nil;
}

- (NSError*) controllerError
{
	return [[controllerError retain] autorelease];
}

- (void) cleanUp
{
	//nothing to do
}

@end

@implementation AdController (AdControllerThreadingExtensions)

//Private method that runs in the simulation thread
- (void) _threadedRunController: (NSArray*) ports
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSConnection* connection;
	
	//Use the ports to connect to the main thread

	connection = [[NSConnection alloc] initWithReceivePort:[ports objectAtIndex:0]
			sendPort:[ports objectAtIndex:1]];
	[ports retain];
	
	[self runController];

	//we're finished so notify the main thread and exit
	
	NSDebugLLog(@"AdController", 
		@"Controller finished - notifying main thread");
	[self performSelectorOnMainThread: @selector(simulationFinished)
		withObject: nil
		waitUntilDone: NO];
	[ports release];
	[connection release];
	NSDebugLLog(@"AdController", 
		@"Controller thread exiting");
	[pool release];
	[NSThread exit];
}

- (void) runThreadedController
{
	NSPort* receive_port, *send_port;
	NSArray *ports;

	//set up the ports that will be used by the NSConnection 
	//for interthread communication

	/*receive_port = [[NSMessagePort new] autorelease];
	send_port = [[NSMessagePort new] autorelease];*/
	//FIXME - Retaining ports since on mac the connection doesn't retain them.
	receive_port = [NSMessagePort new];
	send_port = [NSMessagePort new];
	ports = [NSArray arrayWithObjects: send_port, receive_port, NULL];

	//create the NSConnection
	threadConnection = [[NSConnection alloc] 
				initWithReceivePort:receive_port 
				sendPort:send_port];

	//we set this object i.e. the  main thread controller as root object
	//The simulation thread can then get a reference to it using rootProxy

	[threadConnection setRootObject:self];

	//detach the thread

	controllerError = nil;
	notifyCore = YES;

	[NSThread detachNewThreadSelector: @selector(_threadedRunController:) 
		toTarget: self
		withObject: ports];
}

//Method called when the simulation thread exits
//N.B. This should only be called from _threadedRunController 
//in the simulation thread
- (void) simulationFinished
{
	//If notifyCore is yes the thread has ended either normally,
	//by stopSimulation:, or by an exception in the thread.
	//In any of these cases we notify the Core.
	//Otherwise the controller was stopped via terminateSimulation:.
	//In this case we dont send any notification 	
	
	NSDebugLLog(@"AdController",
		@"Received simulation finished message");

	if(notifyCore)
	{
		NSDebugLLog(@"AdController",
			@"Posting notification");
		[[NSNotificationCenter defaultCenter] 
			postNotificationName: @"AdSimulationDidFinishNotification"
			object: self
			userInfo: nil];
	}

	NSDebugLLog(@"AdController", 
		@"Cleaning up thread");
	[threadConnection invalidate];
	[threadConnection release];
	threadConnection = nil; 
}

- (void) stopSimulation: (AdCore*) core
{
	notifyCore = YES;
	[configurationGenerator endProduction];
}

- (void) terminateSimulation: (AdCore*) core
{
	notifyCore = NO;
	[configurationGenerator endProduction];
}	

@end
