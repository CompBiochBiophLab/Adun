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
#ifndef ADCONTROLLER
#define ADCONTROLLER

#include "AdunKernel/AdCoreAdditions.h"

@class AdCore;

/**
\ingroup coreProtocols

A controller is a object that "controls" a simulation by sending
messages to and manipulating the framework objects that make up the simulator.
The main method of a controller is runController(). This is where all work
should take place. 

\section end Ending a Simulation

The simulation can end in two ways (when it is not running interactively)

 -# The controller finishes normally.
 -# An exception occurs 
	- The controller should handle the exception and create an NSError object detailing the cause.

\section clean Cleaning Up

As part of the exit process the controller will receive a cleanUp() message.
This is where the controller should perform neccessary outputs etc. before it is deallocated.
**/

@protocol AdController 
/**
This method is called before runController() to allow
the controller to perform any setup tasks aswell as to 
obtain a reference to the core.
*/
- (void) coreWillStartSimulation: (AdCore*) core;
/**
Runs the controllers main loop. This method should catch any exception raised
from the simulation process, creating an NSError detailing them before exititng.
*/
- (void) runController;
/**
On receiving this message the controller should
output any necessary files, close streams etc.
*/
- (void) cleanUp;
/**
Returns any controller dependant results or nil if there
is none
*/
- (id) simulationResults;
/**
If the controller exited due to an error this method returns an NSError object detailing it.
Otherwise it return nil.
*/
- (NSError*) controllerError;
@end

/**
A controller is expected provide the ability to run its main loop as a thread. This allows the
user to interact with the core, asking for information on simulation status etc.,
while the simulation is running. The AdThreadedController protocol methods define the
interface for this functionality. In addition the AdController class
provides a implementation of this protocol, hence by subclassing it you get
this functionality for free.

<b>Controllers and Threads</b>

When the thread is detached your controller object is essentially duplicated -
you have one in the simulation thread \e and one in the main thread. 
These two objects will share the same instance variables but otherwise act independantly. 
Thus it is important for the two object to be able to communicate across the threads so
they can coordinate their actions.

<b>Ending a Threaded Simulation</b>

When threaded the program can exit in four ways. The first three \e must result in the
simulation thread notifying the main thread that it has finished via an AdSimulationDidFinishNotification.
Reciept of this notification begins the clean up process.

 -# The controller finishes normally.
 -# The controller on the main thread receives an stopSimulation:() message
	- The controller must cause the simulation thread to exit.
 -# An exception occurs in the simulation thread.
	- The thread should handle the exception, set an error and exit.
 -# The contoller on the main thread receives a terminateSimulation:() message
	- The controller must cause the simulation thread to exit \e without
	posting an AdSimulationDidFinishNotification.

*/

@protocol AdThreadedController
/**
Runs AdController::runController in a separate thread. 
**/
- (void) runThreadedController;
/**
This method is used by the subthread to notify the main thread controller
that it has finished. It is for internal use only and should not be called
by other objects.
*/
- (void) simulationFinished;
/**
Causes the controller to end the simulation thread
and the simulator to enter the normal termination
chain 
*/
- (void) stopSimulation: (AdCore*) core;
/**
Causes the controller to terminate the simulation thread
without entering the normal termination chain.
This method is used when an exception has been caught in the
main thread and hence it is already in the process of terminating
itself. If stopSimulation: was used it would cause a race
condition between the two exit sequences. 
*/
- (void) terminateSimulation: (AdCore*) core;

@end

#endif
