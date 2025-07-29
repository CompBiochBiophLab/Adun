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
#ifndef _ADUN_CORE_
#define _ADUN_CORE_

#include <stdbool.h>
#include <stdio.h>
#include "Foundation/Foundation.h"
#include "AdunKernel/AdunConfigurationGenerator.h"
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunTimer.h"
#include "AdunKernel/AdCoreAdditions.h"
#include "AdunKernel/AdCoreCommand.h"
#include "AdunKernel/AdunIOManager.h"
#include "AdunKernel/AdunTemplateProcessor.h"
#include "AdunKernel/AdunController.h"
#include "AdunKernel/AdunSimulationData.h"
#include "AdunKernel/AdunMinimiser.h"
#include "AdunKernel/AdunCheckpointManager.h"

/**
AdCore is the top level object for AdunCore. It sets up the simulator, runs the simulation, handles checkpointing and
enables interactive sessions. It also
provides the controller access to the programs AdConfigurationGenerator instance. 
AdCore is a singleton hence there is only one instance for each running AdunCore program.

\note Care must be taken not to change system contents and configuration in methods called from the
main loop timer. Since the sequence of calls from the timer is undefined this could lead to
configuration being checkpointed, then the topology being changed and checkpointed and stored in
the same frame - even though the two have no relation. Only do this if you know that the configuration
before the topology change is compatible with the system after the change.

\todo Refactor Roll back methods to new class AdRollBackManager.

\section interactive Interactive Commands

If the program was run in interactive mode messages can be sent to the AdCore instance through the AdCoreCommand 
protocol enabling real time monitoring and interaction with the simulation process. 
In practice the messages are sent first to the programs shared AdIOManager instance using the AdCommandInterface protocol.
The AdIOManager object then passses them on to the AdCore instance which executes them.
\note Add error checking to all basic core commands - currently they assume that all variable, object etc
that must be setup previously have been
\ingroup coreClasses
**/

@interface AdCore: NSObject <AdCoreCommand>
{
	@private
	BOOL endSimulation;
	BOOL runLoopIsRunning;
	id controller;
	NSDate* date;
	NSAutoreleasePool* corePool;
	NSError* terminationError;
	NSDictionary* externalObjects;
	AdSystemCollection* systems;
	AdForceFieldCollection* forceFields;
	AdConfigurationGenerator* configurationGenerator;
	AdTemplateProcessor* templateProcessor;
	AdMemoryManager* memoryManager;
	AdIOManager* ioManager;
	AdCheckpointManager* checkpointManager;
	//Core command
	NSArray* validCommands;
	NSMutableDictionary* commandErrors;
	NSMutableDictionary* commandResults;
	AdSimulationData* simulationData;
	AdMinimiser* minimiser;
	//Temporary
	unsigned int tempRestartVar;	//!< Holds the step at which the simulation should be restarted
} 
/**
Returns the programs AdCore instance.
*/
+ (id) appCore;
/**
Returns the programs AdCore instance. AdCore is a singleton so
it is only initialised on the first call to this method.
*/
- (id) init;
/**
This method processes the program template and sets up
checkpointing. The template is retrieved from the
applications AdIOManager instance.
After this method has been called the configurationGenerator()
method returns the AdConfigurationGenerator instance for the program.
*/
- (BOOL) setup: (NSError**) error;
/**
This method sets up a simulation to restart from the data
supplied by the applications AdIOManager instance.
If the required information is not present this method 
raises an NSInternalInconsistencyException. 
*/
- (BOOL) prepareRestart: (NSError**) error;
/**
Starts the simulation.  
If the RunInteractive default is set to YES the simulation is started 
using AdController::runThreadedController and the main thread enters a run loop. 
If RunInteractive is NO the simulation is started using AdController::runController.
In either case before the simulation is started the controller is sent a
AdController::coreWillStartSimulation: message.

This method will not return until the simulation terminates (either normally or due
to an error).
*/
- (id) main: (NSDictionary*) dict;
/**
Calls AdController::cleanUp. Also outputs the energies collected from the
simulation as well as the controller results.
*/
- (void) cleanUp;
/**
Core command - causes the currently collected energies to be output.
It takes no options.
*/
- (id) flushEnergies: (NSDictionary*) options;
/**
Core command - returns the controller results if any.
*/
- (id) controllerResults: (NSDictionary*) options;
/**
Returns the programs AdConfigurationGenerator instance. Returns nil
if the configurationGenerator has not been created yet.
*/
- (AdConfigurationGenerator*) configurationGenerator;
/**
Returns the AdCheckpointManager instance which automates the output process.
*/
- (AdCheckpointManager*) checkpointManager;
/**
Returns the termination error (if any) associated with the simulation.
*/
- (NSError*) terminationError;
/**
Returns the simulation controller
*/
- (id) controller;
/**
Performs a minimisation of the current system. For internal use only.
*/
- (void) _minimise;
@end


/**
\ingroup coreClasses
Category containing methods to assist in rolling back the simulation to a previous state. 
Note these methods only can roll back to a state captured since the start of the current production loop.
\ingroup coreCategories
*/
@interface AdCore (AdCoreRollBackExtensions)
/**
As AdCheckpointManager::rollBackToLastCheckpoint() with an additional minimisation step
after the roll back is completed. No energies or configurations
are checkpointed from this minimisation.
*/
- (int) rollBackAndMinimise;
@end

/**
\ingroup coreClasses
Category containing methods for running the core as an interactive server.
*/
@interface AdCore (AdCoreInteractionModeExtensions)
/**
Starts a run loop in NSConnectionReplyMode thus allowing the AdCore
instance to serve requests while a simulation is running. For internal use only.
*/
- (void) startRunLoop;
/**
Returns YES if the simulation is running. NO otherwise.
\note This method is only useful when running interactively.
It works by checking if the runloop is still running.
*/
- (BOOL) simulationIsRunning;
/**
This method is called when the core recieves an AdSimulationDidFinishNotification. 
This will only happen when the core is running interactively. The notification should be
posted by the the AdController instance.
The core checks if the notification contains an error object detailing the cause of the simulation
termination. If such an error exists it will be returned by AdCore::terminationError().
This method also sets a flag which causes the runLoop to end and hence AdCore::main: to exit.
*/
- (void) simulationFinished: (NSNotification*) aNotification;
@end

#endif


