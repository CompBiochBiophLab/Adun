/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 14:10:58 +0200 by michael johnston

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

#ifndef _ULPROCESSMANAGER_H_
#define _ULPROCESSMANAGER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunSimulationData.h>
#include "ULFramework/ULServerInterface.h"
#include "ULFramework/ULProcess.h"
#include "ULFramework/ULIOManager.h"

/**
ULProcessManager contains, runs and manages Adun simulation processes.
It contains two LIFO queues that contain waiting and running process
respectivly aswell as a dictionary of open connections to various AdunServers.
It provides information about the various processes. 
It adopts the ULServerCommandInterface protocol to facilitate ease of passing of messages
from the View to the Server and hence to the Simulation.
\bug Calcualted elapsed time is the time since the process was created not the
time the process was running
\todo Refactor process commands to use AdServerCommandInterface
\todo Commands are currently using exceptions when really they should use NSError

\ingroup classes
*/

@interface ULProcessManager : NSObject <ULServerCommandInterface>
{
	BOOL automaticSpawn;
	NSMutableArray* spawnedStack; //!< stack of spawned currently running processes
	NSMutableArray* newStack;	//!< stack of new waiting processes
	NSMutableArray* finishedStack; //!< stack of finished processes
	NSMutableArray* hosts;
	NSMutableDictionary* connections;	//!< Dictionary of hostname:connection pairs
	NSMutableArray* standardArgs;
}
/**
Returns the applications shared ULProcessManager instance.
*/
+ (id) appProcessManager;
/**
Should be sent to the process manager when the application is about
to close. The receiver archives the waiting & running processes and
informs the server that its is closing so it doesnt send any messages
until its is started again.
*/
- (void) applicationWillClose;
/**
Should be sent to the reciever before attempting to terminate the application.
Returns NO if any running processes still have to transmit data to the
corresponding simulation process. If the application is shut down before
this is done the simulation process will crash.
*/
- (BOOL) applicationShouldClose;
/** 
Creates a new process object
*/
- (void) newProcessWithInputData: (NSDictionary*) objects 
	simulationTemplate: (id) simulationTemplate
	host: (NSString*) host;
/**
Spawns the first process in the newProcess queue (FIFO)
*/
- (void) spawnNewProcess;
/**
Sets if the receiver automatically spawns a new process
when one finishes.
*/
- (void) setAutomaticSpawn: (BOOL) value;
/**
Returns if the receiver automatically spawns a new process
when one finishes or not.
*/
- (BOOL) automaticSpawn;
/**
Description forthcomming
*/
- (int) numberWaitingProcesses;
/**
Description forthcomming
*/
- (int) numberSpawnedProcesses;
/**
Returns an array of processes waiting to be started on \e hostname
*/
- (NSArray*) waitingProcessesForHost: (NSString*) hostname;
/**
Description forthcomming
*/
- (NSArray*) allProcesses;
/**
Description forthcomming
*/
- (void) haltProcess: (ULProcess*) process;
/**
Description forthcomming
*/
- (void) startProcess: (ULProcess*) process;
/**
Description forthcomming
*/
- (void) removeProcess: (ULProcess*) process;
/**
Description forthcomming
*/
- (void) terminateProcess: (ULProcess*) process;
/**
Description forthcomming
*/
- (void) restartProcess: (ULProcess*) process;
/**
Description forthcomming
*/
- (NSArray*) hosts;
@end

#endif // _ULPROCESSMANAGER_H_

