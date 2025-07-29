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
#ifndef _ADUN_IOMANAGER_
#define _ADUN_IOMANAGER_

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include "AdunKernel/AdCommandInterface.h"
#include "AdunKernel/AdCoreCommand.h"
#include "AdunKernel/AdServerInterface.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdunSimulationData.h"
#include "AdunKernel/AdunFileSystemSimulationStorage.h"
#include "AdunKernel/AdCoreAdditions.h"

/**
\ingroup coreDataTypes
Defines the run mode of the program i.e.
from the command line or the server.
*/
typedef enum
{
	AdCoreCommandLineRunMode = 1, /**< The program is being run from the command line */
	AdCoreServerRunMode = 2,	/**< The program is being run by an AdunServer */
	AdCoreUnknownRunMode		/**< The program has not determined its run mode*/
}
AdCoreRunMode;

/*!
\ingroup coreClasses
AdIOManager manages input and output from the simulation application.

- Acts as the interface to the simulation.
- Loads and processes the simulation data (options and dataSources)
- Opens, closes and provides access to file streams for the other framework objects
- Creates the simulation output directory and associated files

AdIOManager is a singleton - only one instance exists for each application. This instance
can be accessed using the appIOManager() method.

\todo
Factor out related groups of methods to categories.
See can the differences the arise from the run mode e.g. server, command,
can be factored to a delegate class. 
*/

@interface AdIOManager: NSObject <AdCommandInterface>
{
	@private
	id fileManager;
	BOOL restartRequested;
	BOOL processedArgs;	//!< Indicates if the command line has been processed.
	BOOL simulationDataSent; //!< Indicates if the simulation data object has been sent to the server
	AdCoreRunMode runMode;
	NSMutableDictionary* fileStreams;
	NSString* adunDir;
	NSString* pluginDir;
	NSString *controllerDir;
	NSString *extensionDir;
	NSString* outputDir;
	NSString* controllerOutputDir;
	NSString* logFile;		//Where stdout goes
	NSString* errorFile;		//Where stderr goes
	NSProcessInfo *adunInfo;	
	NSArray* validArgs;	//!< Array of valid arguement names.
	id serverProxy;
	id core; 	//!< The simulator core
	id serverConnection;
	id simulatorTemplate;	//!< The loaded template
	NSDictionary* externalObjects; //!< The data for the simulation
	NSProtocolChecker* checkerInterface;
	AdSimulationData* simulationData;
	id writeModeStorage;
}
/**
Returns the applications AdIOManager instance.
*/
+ (id) appIOManager;
/**
Returns the runMode of the core. AdCoreServerRunMode, AdCoreCommandLineRunMode.
*/
- (AdCoreRunMode) runMode;
/**
Creates the program and error log files.
Uses the values given by NSUserDefaults keys LogFile and ErrorFile for the file locations.
Returns YES on succesful creation. If the log files could not be created
returns NO and \e error contains an NSError object that describes the problem.
*/
- (BOOL) createLogFiles: (NSError**) error;
/**
Checks that the adun/ directory exists and has the correct structure.
Uses the value given by the NSUserDefaults key ProgramDirectory for the directory location
If it doesnt exist it is created in this location. If the structure of the directory is incorrect i.e. there are
missing directories, they structure is corrected. If the program directories can be
corrected of fixed this method returns NO and \e error contains an NSError object that describes the problem. 
*/
- (BOOL) checkProgramDirectories: (NSError**) error;
/**
Retrieves and processes the program data as specified by the program arguements.
Returns YES if the required data was loaded successfully.
Returns NO otherwise. If NO is returned \e error is set with an NSError object explaining the 
reason the data could not loaded. If processCommandLine:() has not been called this method
calls it.

The log files are copied to the simulation output directory if the RedirectOutput 
default is YES.
*/
- (BOOL) loadData: (NSError**) error;
/**
 Adds references to the objects in \e inputObjects to the
 simulation data instance. This method also adds the simulation
 template to the AdSimulationData objects metadata and sends the
 simulation data to the server if the receiver is connected to one.
*/ 
- (void) setSimulationReferences: (NSDictionary*) inputObjects;
/**
Checks that the format of the command line arguements is valid, that all the arguement keys 
are valid and that required arguement are present. 
On detecting a problem returns NO and error contains an NSError object detailing the problem encountered.
\note This method does not check if that the supplied argument values are valid. This is done by loadData:() 
createOutputDirectories:() and other methods.
*/
- (BOOL) processCommandLine: (NSError**) error;
/**
Attempts to connect to the AdServer on the localhost. This allows the server
to send commands to the simulation application via the AdCommandInterface protocol.
\param error If an error occurs, upon return contains an NSError object that describes the problem.
\return YES if a connection was made, NO otherwise.
*/
- (BOOL) connectToServer: (NSError**) error;
/**
Creates the simulation output directory
*/
- (BOOL) createSimulationOutputDirectory: (NSError**) error;
/**
Creates the controller output directory
*/
- (BOOL) createControllerOutputDirectory: (NSError**) error;
/**
Returns YES if the receiver is connected to an AdServer instance. NO otherwise.
*/
- (BOOL) isConnected;
/**
Returns YES if a simulation continuation was requested
via the command line arguments. NO otherwise.
*/
- (BOOL) restartRequested;
/**
Closes the connection to the local AdServer instance. Has no effect if a connection does not exist.
\param error If the connection is being closed for a reason other than
normal termination then this should be an NSError object describing the cause. 
Otherwise pass nil.
*/
- (void) closeConnection: (NSError*) error;
/**
Causes the AdIOManager instance to indicate to the server that it is 
ready to process requests. Has no effect if a connection was not created
using connectToServer:() or the connection attempt failed.
*/
- (void) acceptRequests;
/**
Sends the data sets in array \e anArray to the server. If the program
is not connected to a server this method does nothing.
*/
- (void) sendControllerResults: (NSArray*) anArray;
/**
Saves the entries in \e array to the controller output directory.
Each entry must be an AdDataSet instance. If not an NSInvalidArgumentException
is raised.
*/
- (void) saveResults: (NSArray*) anArray;
/**
Sets a reference to the AdCore instance of the simulator.
*/
- (void) setCore: (id) core;
/**
Creates a stream to \e file. The mode of the stream is detemined by \e fileFlag.
If file is nil or the stream cannot be created this method return NULL.
\e fileFlag also determines if the file should be created if it does not exist.
\param file The path to the file.
\param name The name to be associated with this stream. For use with getStreamForName() and closeStreamWithName().
\param flag Inidicates this mode for the stream. Value are the same as for the libc function fopen().
\return A pointer to the stream
*/
- (FILE*) openFile: (NSString*) file usingName: (NSString*) name flag: (NSString*) fileFlag;
/**
Returns the stream associated with \e name. The stream must have been previously created using
AdIOManager::openFile:usingName:flag:. If no stream called \e name exists this method return NULL.
\param name The name associated with the stream when it was created.
\return A pointer to the stream
*/
- (FILE*) getStreamForName: (NSString*) name;
/**
Closes the stream previously created using AdIOManager::openFile:usingName:flag:. \e name is
the name given to the stream when it was created. If no stream called \e name exists this method does nothing.
*/
- (void) closeStreamWithName: (NSString*) name;
/**
Closes all the stream created using AdIOManager::openFile:usingName:flag:.
*/
- (void) closeAllStreams;
/**
Returns the name of the directory to which simulation output is written.
*/
- (NSString*) simulationOutputDirectory;
/**
Returns the directory to which the controller should write its output.
*/
- (NSString*) controllerOutputDirectory;
/**
Returns the directory where controller plugins are located.
*/
- (NSString*) controllerDirectory;
/**
Returns the program working directory
*/
- (NSString*) adunDirectory;
/**
Returns the AdSimulationData instance which represents the simulation output.
*/
- (AdSimulationData*) simulationData;
/**
Returns the template for the simulation or nil
if none has been loaded.
*/
- (NSDictionary*) template;
/**
Returns any external objects retrieved from the server or
nil if there are none.
*/
- (NSDictionary*) externalObjects;
/**
Returns the AdFileSystemSimulationStorage instance used to
create the simulation data directory. 
\todo
This is currently required since the instance that created the directory
is the only one that can write to it. This method will be deprecated
when this issue is fixed.
*/
- (id) simulationWriteStorage;
@end

#endif

