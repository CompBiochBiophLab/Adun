/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 14:11:56 +0200 by michael johnston

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

#ifndef _ULPROCESS_H_
#define _ULPROCESS_H_

#include <math.h>
#include <Foundation/Foundation.h>
#include <AdunKernel/AdunModelObject.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <AdunKernel/AdunDataSource.h>
#include <AdunKernel/AdunSimulationData.h>
#include <AdunKernel/AdunFileSystemSimulationStorage.h>
#include "ULFramework/ULServerInterface.h"
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULDatabaseInterface.h"
#include "ULFramework/ULFrameworkFunctions.h"

/**
Protocol containing methods that can be called on ULProcess instances
using distributed objects.
\ingroup protocols
*/

@protocol ULClientInterface
/**
Returns the simulation template for the process
*/
- (bycopy NSDictionary*) simulationTemplate;
/**
Returns the input data for process.
*/
- (bycopy NSDictionary*) inputData;
/**
Sets the results produced by the simulation controller to \e array which must be contain AdDataSet instances.
This method is sent by the server when the simulation exits.
*/
- (void) setControllerResults: (bycopy NSArray*) array;
/**
Sets the pid of simulation the object represents
*/
- (void) setProcessIdentifier: (int) number;
/**
 Sets the status of the process
 */
- (void) setProcessStatus: (NSString*) value;
/**
 Sets the process start time.
 */
- (void) setStarted: (NSDate*) date;
/**
Sets the AdSimulationData object representing the data output.
*/
- (void) setSimulationData: (bycopy AdSimulationData*) simulationData;
/**
Notifies the process object that the simulation it represents
has terminated.
*/
- (void) processDidTerminate: (bycopy NSError*) error;
@end

/**
ULProcess instances represent an AdunCore process that will be run by an AdunServer instance.
In the following description the person/program that creates the ULProcess instance and sends
it to the server is called the \e client. The AdunServer instance running the simulation is called 
the \e server.

ULProcess objects have two purposes
- to provide the server with the necessary information to run the simulation
- to provide a way to pass information about the simulation from the server to the client

The server uses the methods defined by the ULClientInterface protocol to retrieve information about, and set attributes of, the process.
For example it retrives the simulation template and sets the processIdentifier attribute.
Most of these methods should never be called from the client side.

From the client side ULProcess instances provide methods for querying the process status, checking termination errors etc.
You can use a ULProcess instance synchronously or asynchronously.
In the first case you send the process to the sever and then wait until it is finished.

\verbatim

[server startSimulation: process];
[process waitUntilFinished];

\endverbatim

In the second you can register for a ULProcessDidFinishNotification and continue doing other tasks.

Once a simulation has started you can get access to its data using the simulationData() method.
Thus if you have started the process asynchronously you can read the simulation data as its is generated.

\section args Process Arguments

The following default arguments are passed to AdunCore and cannot be overridden

AdunCore -RunMode Server -CreateLogFiles YES -ConnectToServer YES -RunInteractive YES

Additional arguments e.g. SimulationOutputDir, InitialMinimisation can be passed using the
additionalArguments parameter on initialisation of the class.

\ingroup classes
*/
@interface ULProcess : AdModelObject <ULClientInterface>
{
	BOOL inputDataSent;	//!< Yes when the input data has been sent to the simulation process.
	BOOL templateSent;	//!< Yes when the template has been sent to the simulation process.
	BOOL isFinished;
	NSDictionary* inputData;		
	NSDictionary* simTemplate;
	NSMutableArray* simulationArgs;			
	id host;		//!< The host on which the process is to be lauched
	id status;
	id elapsed;
	id simulationData;
	int processIdentifier;
	NSArray* dataSets;	//!< Data sets returned by the process when it finished
	NSError* terminationError;
}

/**
Returns a process initialised with the given system and options. The process id
is generated on creation
*/
+ (id) processWithInputData: (NSDictionary*) aDict 
	simulationTemplate: (id) simulationTemplate
	additionalArguments: (NSArray*) anArray
	host: (NSString*) host;
- (id) initWithInputData: (NSDictionary*) aDict 
	simulationTemplate: (id) simulationTemplate
	additionalArguments: (NSArray*) anArray
	host: (NSString*) host;
/**
Returns the arguments to the AdunCore process
*/
- (NSArray*) arguments;	
/**
Adds the values in anArray to the process arguments
*/
- (void) addArguments: (NSArray*) anArray;
/**
Returns the pid of the simulation process the reciever represents
*/
- (int) processIdentifier;
/**
Returns the host the simulation process will run on (or is running on)
*/
- (NSString*) processHost;
/**
Returns the total time taken to run the simulation
*/
- (id) length;
/**
Returns the time the simulation was started at
*/
- (NSDate*) started;
/**
Returns the AdSimulationData object for the simulation.
*/
- (id) simulationData;
/**
Returns the AdDataSets produced by the simulations controller if any.
*/
- (NSArray*) controllerResults;
/**
Returns the termination error for the process (nil if none)
*/
- (NSError*) terminationError;
/**
Returns the status of the process - Waiting, Running, Suspended or Finished
*/
- (NSString*) processStatus;
/**
Returns YES is the process has finished. NO otherwise.
*/
- (BOOL) isFinished;
/**
IF called after a process has started this method will not return until its is finished.
*/
- (void) waitUntilFinished;
/**
Returns YES if the receiver has sent the process data to the
simulation process - NO otherwise.
*/
- (BOOL) hasSentProcessData;
@end

#endif // _ULPROCESS_H_

