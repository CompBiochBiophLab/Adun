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
#include "AdunKernel/AdunIOManager.h"
#include "AdunKernel/AdunDataSource.h"

static id ioManager;

/**
Contains methods for handling loading simulation data
*/
@interface AdIOManager (SimulationDataLoading)
/**
Loads data specified on the command line
*/
- (BOOL) _loadCommandLineData: (NSError**) error;
/**
Loads data from a previous simulation for a continuation run
*/
- (BOOL) _loadRestartData: (NSError**) error;
/**
Retreives data from the local server
*/
- (BOOL) _loadServerData: (NSError**) error;
@end

@implementation AdIOManager

/**
Check a directory sets an error if a file is in the way of the directory.
It returns NO if the directory does not exist
 */
- (BOOL) _checkDirectory: (NSString*) directoryPath error: (NSError**) error
{
	BOOL isDir;
	
	if([fileManager fileExistsAtPath: directoryPath isDirectory: &isDir])
	{
		if(!isDir)
		{
			*error = AdCreateError(AdunCoreErrorDomain,
					       AdCoreDirectoryStructureError,
					       [NSString stringWithFormat: 
						       @"A non-directory file exists at %@", directoryPath],
					       @"The required directory cannot be created as the file is in the way.",
					       @"Move or remove the file");
			
			return NO;
		}
		
		return YES;
	}
	
	return NO;
}

- (BOOL) _createDirectory: (NSString*) directoryPath error: (NSError**) error

{
	if(![fileManager createDirectoryAtPath: directoryPath
				    attributes: nil])
	{
		
		*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreDirectoryStructureError,
				       [NSString stringWithFormat: 
					       @"Unable to create missing directory %@", directoryPath],
				       @"This is probably because the containing directory is not writable",
				       @"Change the permissions of the containing directory to allow file creation");
		
		return NO;
	}
	
	NSWarnLog(@"Created missing directory %@", directoryPath);
	
	return YES;
}

/*
 * Connecting to and disconnecting from the local
 * AdServer instance
 */

- (BOOL) connectToServer: (NSError**) error;
{
	NSDebugLLog(@"Server", 
		@"Server debug - Attempting to  connecting to AdServer using message ports");

	serverConnection = [NSConnection connectionWithRegisteredName: @"AdunServer" 
				host: nil];
	
	if(serverConnection == nil)
	{
		NSDebugLLog(@"Server",
			@"Server debug - Unable to find AdunServer on message ports.");
		NSDebugLLog(@"Server", 
			@"Server debug - Checking for a distributed computing enabled server");
		serverConnection = [NSConnection connectionWithRegisteredName: @"AdunServer" 
				host: nil 
				usingNameServer: [NSSocketPortNameServer sharedInstance]];
	}

	if(serverConnection != nil)
	{
		[serverConnection retain];
		serverProxy = [[serverConnection rootProxy] retain];
	
		NSDebugLLog(@"Server", @"Server debug - Connected to server");
		NSDebugLLog(@"Server" ,
			@"Server debug - Stats are %@", 
			[[serverProxy connectionForProxy] statistics]);

		//supply interface using an NSProtocolChecker
	
		checkerInterface = [NSProtocolChecker protocolCheckerWithTarget: self 
						protocol: @protocol(AdCommandInterface)];
		[checkerInterface retain];
		[serverProxy useInterface: checkerInterface 
			forProcess:  [[NSProcessInfo processInfo] processIdentifier]];
		return YES;
	}
	else
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreConnectionError,
				@"Unable to connect to server",
				@"If the program is being run from the server this error\
				 is fatal.",
				@"Check the server is still running.\n \
				If it is send the program logs and the server logs to the Adun developers");

		return NO;
	}	
}


- (void) closeConnection: (NSError*) error
{
	//If we're not connected just return
	if(![self isConnected])
		return;

	/*
	 * Before closing the connection check that the simulation information has been sent.
	 * It will not have been sent if we are exiting due to an exception
	 * and the exception was raised before setSimulationReferences: was called.
	 */
	
	if(!simulationDataSent)
	{
		[serverProxy simulationData: simulationData
				 forProcess: [[NSProcessInfo processInfo] processIdentifier]];
		simulationDataSent = YES;		 
	}
		
	
	NSDebugLLog(@"Server", @"Server debug - Closing connection to server. Statistics are %@", 
			[[serverProxy connectionForProxy] statistics]);
	NSDebugLLog(@"Server", @"Server debug - Connection %@", [serverProxy connectionForProxy]);
	[serverProxy closeConnectionForProcess: [[NSProcessInfo processInfo] processIdentifier]
			error: error];
	[serverProxy release];
	[serverConnection invalidate];
	[serverConnection release];
	[checkerInterface release];
	serverProxy = nil;
}

- (void) acceptRequests
{
	int pid;

	if(serverConnection != nil)
	{
		pid = [[NSProcessInfo processInfo] processIdentifier];
		[serverProxy acceptingRequests: pid];
	}
}

- (void) sendControllerResults: (NSArray*) results
{
	if(serverConnection != nil)
	{
		[serverProxy controllerData: results 
			forProcess: [[NSProcessInfo processInfo] processIdentifier]];
	}
	else
		NSWarnLog(@"Can't send controller results - Not connected to an AdunServer instance");
}

- (BOOL) isConnected
{
	if(serverConnection != nil)
		return YES;
	else
		return NO;
}

/*
 * Creation
 */

+ (id) appIOManager
{
	if(ioManager == nil)
		ioManager = [AdIOManager new];
	return ioManager;
}

- (id) init
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

	if(ioManager != nil)
		return ioManager;

	if((self = [super init]))
	{
		if(ioManager == nil)
			ioManager = self;

		fileManager = [NSFileManager defaultManager];
		fileStreams = [NSMutableDictionary new];
		[fileStreams setObject: [NSValue valueWithPointer: stdout]
				forKey: @"Standard"];
		[fileStreams setObject: [NSValue valueWithPointer: stderr] 
				forKey: @"Error"];
		
		simulationData = nil;	
		simulationDataSent = NO;	
		outputDir = controllerOutputDir = nil;
		adunDir = controllerDir = extensionDir = pluginDir = nil;
		logFile = errorFile = nil;
		simulatorTemplate = nil;
		externalObjects = nil;
		adunInfo = [NSProcessInfo processInfo];
		runMode = AdCoreUnknownRunMode;
		processedArgs = restartRequested = NO;
		validArgs = [[NSArray alloc] initWithObjects:
				@"-RunMode",
				@"-Template",
				@"-Continue",
				@"-SimulationOutputDir",
				@"-ControllerOutputDir",
				@"-ExternalObjects", 
				nil];

		//Setup defaults
		[defaults setObject: @"AdunCore.log" forKey: @"LogFile"];
		[defaults setObject: @"AdunCore.errors" forKey: @"ErrorFile"];
		[defaults setObject: [NSNumber numberWithBool: YES] forKey: @"RedirectOutput"];
		[defaults setObject: [NSNumber numberWithBool: YES] forKey: @"CreateLogFiles"];
		[defaults setObject: NSHomeDirectory() forKey: @"ProgramDirectoryLocation"];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		//Set the path ivars
#if __FREEBSD__	
		adunDir = [[[NSUserDefaults standardUserDefaults] 
			    stringForKey: @"ProgramDirectoryLocation"]
			   stringByAppendingPathComponent: @".adun"];
#else			
		adunDir = [[[NSUserDefaults standardUserDefaults] 
			    stringForKey: @"ProgramDirectoryLocation"]
			   stringByAppendingPathComponent: @"adun"];	
#endif					
		
		pluginDir = [adunDir stringByAppendingPathComponent: @"Plugins"];
		controllerDir = [pluginDir stringByAppendingPathComponent: @"Controllers"];
		extensionDir = [pluginDir stringByAppendingPathComponent: @"Extensions"];
		
		[adunDir retain];
		[pluginDir retain];
		[controllerDir retain];
		[extensionDir retain];
	}

	return self;
}

- (void) dealloc
{
	[self closeAllStreams];
	[fileStreams release];
	if(serverProxy != nil)
		[self closeConnection: nil];

	[logFile release];
	[errorFile release];
	[adunDir release];
	[controllerDir release];
	[extensionDir release];
	[pluginDir release];
		
	[outputDir release];
	[controllerOutputDir release];
	[validArgs release];

	[simulationData release];
	[writeModeStorage release];
	
	[simulatorTemplate release];
	[externalObjects release];

	ioManager = nil;
	[super dealloc];
}

- (BOOL) processCommandLine: (NSError**) error
{
	NSMutableArray* arguments, *invalidArgs;
	id value;
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

	if(processedArgs == YES)
		return YES;

	arguments = [[[NSProcessInfo processInfo] arguments] mutableCopy];
	invalidArgs = [NSMutableArray array];

	[arguments removeObjectAtIndex: 0];

	//FIXME: Check all args are valid
	/*argumentEnum = [processedArgs keyEnumerator];		
	while(argument = [argumentEnum nextObject])
		if(![validArgs containsObject: argument])
			[invalidArgs addObject: argument];

	if([invalidArgs count] > 0)
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreArgumentsError,
				@"Invalid arguements detected",
				[NSString stringWithFormat: @"The following arguements are not supported - %@", invalidArgs],
				@"Remove these arguements from the command line");
		return NO;
	}*/

	/*
	 * Check if the run mode is specified.
	 * If its not default to AdCoreCommandLineRunMode.
	 * If it is check that its CommandLine or Server.
	 * If its neither of these set an error.
	 */
	if((value = [userDefaults stringForKey: @"RunMode"]) != nil)
	{
		if([value isEqual: @"CommandLine"])
		{
			GSPrintf(stdout, @"RunMode == CommandLine\n");
			runMode = AdCoreCommandLineRunMode;
		}	
		else if([value isEqual: @"Server"])
		{
			GSPrintf(stdout, @"RunMode == Server\n");
			runMode = AdCoreServerRunMode;
		}	
		else
		{
			*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreArgumentsError,
				@"Invalid arguement detected",
				[NSString stringWithFormat: @"Invalid value for RunMode supplies - %@", value],
				@"Type 'AdunCore' without arguments to see the valid values");
			return NO;	
		}
	}
	else	
	{
		GSPrintf(stdout, @"RunMode not explicitly specified - ");
		GSPrintf(stdout, @"Defaulting to command line\n");
		runMode = AdCoreCommandLineRunMode;
	}	

	/*
	 * Check if continuation of a previous simulation was requested.
	 */
	 
	if((value = [userDefaults stringForKey: @"Continue"]) != nil)
		restartRequested = YES;

	/*
	 * If the run mode is AdCoreCommandLineRunMode and we are not
	 * continuing a previous simulation then a template must be supplied. 
	 */
	if((runMode == AdCoreCommandLineRunMode) && !restartRequested)
	{
		if((value = [userDefaults stringForKey: @"Template"]) == nil)
		{
			*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreArgumentsError,
				@"Missing required arguement",
			 	@"Template arguement required when running from command line",
				@"Type 'AdunCore' for arguement help.");
			return NO;	
		}	
	}

	fflush(stdout);
	processedArgs = YES;
	
	return YES;
}

- (AdCoreRunMode) runMode
{
	return runMode;
}

/*
 * Setup
 */

/**
Checks if path is absolute. If it is  this method returns it.
If its not the last path component is extracted and a new path
is created using the current directory.
*/
- (NSString*) _fixFilePath: (NSString*) path
{
	if(![path isAbsolutePath])
	{
		path = [path lastPathComponent];
		path = [[[NSFileManager defaultManager] 
				currentDirectoryPath] 
				stringByAppendingPathComponent: path];
	}

	return path;
}

- (BOOL) _createLogFilesForNewRun: (NSError**) error
{
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	
	//Only create the log files if requested to do so.
	if([userDefaults boolForKey: @"CreateLogFiles"] == NO)
	{
		GSPrintf(stdout, @"Log file creation supressed\n");
		return YES;
	}	
	
	logFile = [[NSUserDefaults standardUserDefaults] stringForKey: @"LogFile"];
	logFile = [self _fixFilePath: logFile];
	[logFile retain];
	
	if(![[NSFileManager defaultManager] isWritableFileAtPath:
		[logFile stringByDeletingLastPathComponent]])
	{
		[logFile release];
		logFile = [[userDefaults 
				volatileDomainForName: NSRegistrationDomain]
				valueForKey:@"LogFile"];
		[logFile retain];		
		NSWarnLog(@"Invalid value for user default 'LogFile' (%@). The specificed directory is not writable",
			  logFile);
		NSWarnLog(@"Switching to registered default %@", logFile);
		if(![[NSFileManager defaultManager] 
			isWritableFileAtPath:
			[logFile stringByDeletingLastPathComponent]])
		{
			*error = AdCreateError(AdunCoreErrorDomain,
					       AdCoreLogFileError,
					       [NSString stringWithFormat: 
						       @"Default log file (%@) not writable.", logFile],
					       @"This error may also indicate that a user supplied value for the LogFile default is invalid",
					       @"Check the write permissions on the adun/ directory.");
			return NO;		
		}
	} 
	GSPrintf(stdout, @"Log file is %@\n", logFile);
	fflush(stdout);
	
	errorFile = [[NSUserDefaults standardUserDefaults] stringForKey: @"ErrorFile"];
	errorFile = [self _fixFilePath: errorFile];
	[errorFile retain];
	if(![[NSFileManager defaultManager] isWritableFileAtPath:
		[errorFile stringByDeletingLastPathComponent]])
	{
		[errorFile release];
		errorFile = [[userDefaults
				volatileDomainForName: NSRegistrationDomain]
				valueForKey:@"ErrorFile"];
		[errorFile retain];		
		NSWarnLog(@"Invalid value for user default 'ErrorFile' (%@). The specificed directory is not writable", 
			  errorFile);
		NSWarnLog(@"Switching to registered default %@", errorFile);
		if(![[NSFileManager defaultManager] 
			isWritableFileAtPath:
			[errorFile stringByDeletingLastPathComponent]])
		{
			*error = AdCreateError(AdunCoreErrorDomain,
					       AdCoreLogFileError,
					       @"Default error file (%@) not writable.",
					       @"This error may also indicate that a user supplied value for the ErrorFile default is invalid",
					       @"Check the write permissions on the adun/ directory.");
			return NO;		
		}
	} 
	
	GSPrintf(stdout, @"Error file is %@\n", errorFile);
	fflush(stderr);
	freopen([errorFile cString], "w", stderr);
	freopen([logFile cString], "w", stdout);
	
	return YES;	
}

//On a restart outputDir is assigned here.
- (BOOL) _setupLogFilesForContinuationRun: (NSError**) error
{
	NSError* internalError = nil;
	NSString* simulationDir;
	
	simulationDir = [[NSUserDefaults standardUserDefaults] stringForKey: @"Continue"];
	simulationDir = [simulationDir stringByAppendingString: @"_Data"];
	NSLog(@"Simulation dir is %@", simulationDir);
	
	//Check if the directory is present and that a file isnt in the way
	if(![self _checkDirectory: simulationDir error: &internalError])
	{
		if(internalError == nil)
		{
			*error = AdCreateError(AdunCoreErrorDomain,
					       AdCoreSimulationDataStorageError,
					       @"Error accessing simulation data",
					       [NSString stringWithFormat: 
						       @"Specified data directory (%@) not present.", simulationDir],
					       @"Check supplied simulation name is valid.");
		}
		else
			*error = internalError;
		
		return NO;
	}
	
	//Check the directory is writable
	if(![fileManager isWritableFileAtPath: simulationDir])
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreSimulationDataStorageError,
				       @"Error accessing simulation data",
				       [NSString stringWithFormat: 
					       @"Data directory (%@) not writable.", simulationDir],
				       @"Check the write permissions of the data directory.");
		return NO;		
	}
	
	logFile = [simulationDir stringByAppendingPathComponent: @"AdunCore.log"];
	errorFile = [simulationDir stringByAppendingPathComponent: @"AdunCore.errors"];
	[logFile retain];
	[errorFile retain];
	
	//Check the log files are writable (if they exist)
	if([fileManager fileExistsAtPath: logFile])
	{
		if(![fileManager isWritableFileAtPath: logFile])
		{
			*error = AdCreateError(AdunCoreErrorDomain,
			       AdCoreLogFileError,
			       @"Error accessing log file",
			       [NSString stringWithFormat: 
				       @"Log file (%@) not writable.", logFile],
			       @"Check the write permissions in the simulation data directory.");
			return NO;		
		}
	} 

	if([fileManager fileExistsAtPath: errorFile])
	{
		if(![fileManager isWritableFileAtPath: errorFile])
		{
			*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreLogFileError,
				       @"Error accessing error file",
				       [NSString stringWithFormat: 
					       @"Error file (%@) not writable.", errorFile],
				       @"Check the write permissions in the simulation data directory.");
			return NO;		
		}
	} 

	fflush(stderr);
	freopen([errorFile cString], "a", stderr);
	freopen([logFile cString], "a", stdout);

	GSPrintf(stdout, @"%@%@", divider, divider);
	GSPrintf(stdout, @"%@ - Continuing Simulation\n", AdTimeStamp());
	NSLog(@"%@", divider);
	NSLog(@"%@ - Continuing Simulation\n", AdTimeStamp());
	NSLog(@"%@", divider);

	//Assign output dir ivar now
	//If simulationDir has no containing path then use the
	//current dir.
	outputDir = [simulationDir stringByDeletingLastPathComponent];
	if(outputDir == nil)
		outputDir = [fileManager currentDirectoryPath];
		
	[outputDir retain];	

	return YES;
}

- (BOOL) createLogFiles: (NSError**) error
{

	//If this is a new run create log files
	//as specified by the command line arguments.
	//If we are continuing a previous simulation 
	//redirect the output to the old log files instead.
	if(!restartRequested)
		return [self _createLogFilesForNewRun: error];
	else
		return [self _setupLogFilesForContinuationRun: error];
}

- (BOOL) checkProgramDirectories: (NSError**) error
{
	NSArray* directoryArray;
	NSEnumerator* directoryEnum;
	NSString* currentDirectory;
	id directory;
		
	directoryArray = [NSArray arrayWithObjects: 
				adunDir,
				pluginDir,
				controllerDir,
				extensionDir,
				nil];
	
	/*
	 * Check program directory exists and is writable.
	 * Check Plugins directory exists and is writable.
	 * Check Plugin/Controllers directory exists and is writable.
	 * Check Plugin/Extensions directory exists and is writable.
	 *
	 * If anything is missing create it. If we cant create it set an error.
	 */
	
	directoryEnum = [directoryArray objectEnumerator];
	while((directory = [directoryEnum nextObject]))
		if(![self _checkDirectory: directory error: error])
		{
			/*
			 * If checkDirectory:error set an error we return immediately..
			 * Otherwise we try to create the missing directory.
			 */

			if(*error != nil)
				return NO;

			if(![self _createDirectory: directory error: error])
				return NO;
		}		

	//Check the current working directory is accessible & writable
	//if not fall back to adun/
	currentDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
	if(currentDirectory == nil ||
		![[NSFileManager defaultManager] isWritableFileAtPath: currentDirectory] )
	{
		NSWarnLog(@"Current directory is not accessible. Changing to %@", adunDir);
		[[NSFileManager defaultManager] 
			changeCurrentDirectoryPath: adunDir];
			
	}	
				
	GSPrintf(stdout, @"Adun Directory: %@\n", adunDir);
	GSPrintf(stdout, @"Plugin Directory: %@\n", pluginDir);

	return YES;
}

/* 
 * Loading of simulation data
 */

- (BOOL) loadData: (NSError**) error
{
	BOOL successFlag = NO;
	NSString* templateFile, *dataDirectory;
	AdFileSystemSimulationStorage* readModeStorage;

	if(![self processCommandLine: error])
		return NO;

	if(!restartRequested)
	{
		if(runMode == AdCoreCommandLineRunMode)
			successFlag = [self _loadCommandLineData: error];
		else if(runMode == AdCoreServerRunMode)
			successFlag = [self _loadServerData: error];
		else
		{
			/*
			 * The run mode is still AdCoreUnknownRunMode
			 * This should not happen since processCommandLine:
			 * should set the run mode to one of these two values.
			 * If we are here its due to a bug so raise an exception.
			 */
			
			[NSException raise: NSInternalInconsistencyException
				    format: @"Bug - Program in AdCoreUnknownRunMode when it should not be."];
		}
		
	}
	else
		successFlag = [self _loadRestartData: error];
	
	return successFlag;
}

- (void) setSimulationReferences: (NSDictionary*) inputObjects
{
	NSEnumerator* dataEnum, *keyEnum;
	NSMutableDictionary* templateCopy, *objectReferences;
	id object, key;

	//Set simulation input references
	dataEnum = [inputObjects objectEnumerator];
	while((object = [dataEnum nextObject]))
		if([object isKindOfClass: [AdModelObject class]])
			[simulationData addInputReferenceToObject: object];

	//We need to update the external objects section
	//since it may be empty or have been overridden from the command line
	//If the object doesnt respond to identification we cant add it
	objectReferences = [NSMutableDictionary dictionary];
	keyEnum = [inputObjects keyEnumerator];
	while((key = [keyEnum nextObject]))
	{
		object = [inputObjects objectForKey: key];
		if([object isKindOfClass: [AdModelObject class]])
			[objectReferences setObject: [object identification]
				forKey: key];
	}

	templateCopy = [[simulatorTemplate mutableCopy] autorelease];
	[templateCopy setObject: objectReferences forKey: @"externalObjects"];

	//Add the simulation template to the metadata
	[simulationData setValue: templateCopy
		forMetadataKey: @"Simulation Options"
		inDomain: AdSystemMetadataDomain];

	[NSKeyedArchiver archiveRootObject: simulationData
		toFile: [outputDir stringByAppendingPathComponent: 
			[simulationData identification]]];

	//Send the simulation data object to the interface
	if([self isConnected])
	{
		[serverProxy simulationData: simulationData
				 forProcess: [[NSProcessInfo processInfo] processIdentifier]];
		simulationDataSent = YES;		 
	}
}

/*
 * Output directories
 */

- (BOOL) _createSimulationOutputFiles: (NSError**) error
{
	BOOL success;
	NSString* ident, *dataDirectory, *contents, *name, *link;
	id newLocation;
	AdFileSystemSimulationStorage* readModeStorage;

	//Get simulation data name
	if([simulatorTemplate objectForKey: @"metadata"] != nil)
		name = [[simulatorTemplate objectForKey: @"metadata"]
				objectForKey: @"simulationName"];
	else			
		name = @"output";

	simulationData = [AdSimulationData new];
	[simulationData setValue: name
		forMetadataKey: @"Name"];
	ident = [simulationData identification];

	[NSKeyedArchiver archiveRootObject: simulationData
		toFile: [outputDir stringByAppendingPathComponent: ident]];

	//Create the data directory
	dataDirectory = [outputDir stringByAppendingPathComponent: 
				[NSString stringWithFormat: @"%@_Data", ident]];

	writeModeStorage = [[AdFileSystemSimulationStorage alloc]
				initSimulationStorageAtPath: dataDirectory
				mode: AdSimulationStorageWriteMode
				error: error];
	readModeStorage = [[AdFileSystemSimulationStorage alloc]
				initForReadingSimulationDataAtPath: dataDirectory];
	[simulationData setDataStorage: readModeStorage];
	
	//To aid debugging etc. create a link to the dataDirectory,
	link = [outputDir stringByAppendingPathComponent: name];
	NSDebugLLog(@"AdIOManager", @"Adding link %@", link);
	if([[NSFileManager defaultManager] fileExistsAtPath: link])
	{
		NSDebugLLog(@"AdIOManager", @"Detected link present with same name");
		success = [[NSFileManager defaultManager] 
				removeFileAtPath: link 
				handler: nil];
		if(!success)
			NSWarnLog(@"Unable to remove link - %@", link);
	}		

	if(![[NSFileManager defaultManager] createSymbolicLinkAtPath: link
		pathContent: dataDirectory])
	{
		NSWarnLog(@"Failed to create link to simulation data directory %@", 
			dataDirectory);
	}	

	/**
	 * We redirect the log file output if RedirectOutput is YES.
	 * However before doing so we must check if log files were created
	 * in the first place. If they were not we dont do anything.
	*/

	if([[NSUserDefaults standardUserDefaults] 
		boolForKey: @"CreateLogFiles"] == YES)
	{
		if([[NSUserDefaults standardUserDefaults] 
			boolForKey: @"RedirectOutput"])
		{
			GSPrintf(stdout, 
				@"Attempting to redirect log files to %@\n",
				dataDirectory);
		
			//Move LogFile
			fflush(stdout);
			newLocation = [dataDirectory stringByAppendingPathComponent: 
					[logFile lastPathComponent]];
			if(![[NSFileManager defaultManager] isWritableFileAtPath:
				 [newLocation stringByDeletingLastPathComponent]])
			{
				NSWarnLog(@"Cannot redirect %@ to %@.", logFile, dataDirectory);
			}
			else
			{
				/*
				 * movePath:toPath:handler doesnt work - may have something to
				 * do with the fact that oldLogFile is stderr when we try to move it.
				 * Work around by reading in old file and writing to the new one.
				 */
				contents = [NSString stringWithContentsOfFile: logFile];
				freopen([newLocation cString], "w", stdout);
				GSPrintf(stdout, @"%@\n", contents);
				[[NSFileManager defaultManager] removeFileAtPath: logFile
					handler: nil];
				[logFile release];	
				logFile = [newLocation retain];	
				GSPrintf(stdout, @"Standard log redirected to %@\n", dataDirectory);
			}

			//Move ErrorFile
			fflush(stderr);

			newLocation = [dataDirectory stringByAppendingPathComponent:	
					[errorFile lastPathComponent]];
			if(![[NSFileManager defaultManager] isWritableFileAtPath:
				 [newLocation stringByDeletingLastPathComponent]])
			{
				NSWarnLog(@"Cannot redirect %@ to %@,", errorFile, dataDirectory);
			}
			else
			{
				/*
				 * movePath:toPath:handler doesnt work - may have something to
				 * do with the fact that oldLogFile is stderr when we try to move it.
				 * Work around by reading in old file and writing to the new one.
				 */
				contents = [NSString stringWithContentsOfFile: errorFile];
				freopen([newLocation cString], "w", stderr);
				GSPrintf(stderr, @"%@\n", contents);
				[[NSFileManager defaultManager]
					removeFileAtPath: errorFile
					handler: nil];
				[errorFile release];	
				errorFile = [newLocation retain];	
				GSPrintf(stdout, @"Error log redirected to %@\n", dataDirectory);
			}
		}
	}	

	fflush(stderr);
	fflush(stdout);

	return YES;
}

- (BOOL) _createSimulationOutputDirectory: (NSError**) error
{
	
	outputDir = [[NSUserDefaults standardUserDefaults] 
			stringForKey: @"SimulationOutputDir"];
	if(outputDir == nil)
	{
		outputDir = [[fileManager currentDirectoryPath] 
				stringByAppendingPathComponent: @"SimulationOutput"];
		NSWarnLog(@"Simulation output directory not specified. Defaulting to %@", outputDir);		
	}
	
	[outputDir retain];
	if(![self _checkDirectory: outputDir error: error])
	{
		/*
		 * If checkDirectory:error set an error we return immediately..
		 * Otherwise we try to create the missing directory.
		 */

		if(*error != nil)
			return NO;

		if(![self _createDirectory: outputDir error: error])
			return NO;
	}		

	GSPrintf(stdout, @"Simulation output directory is %@.\n", outputDir);
	
	
	return YES;
}

- (BOOL) createSimulationOutputDirectory: (NSError**) error
{
	NSString* optionsFile;
	
	//Do nothing if this is a restart
	if(restartRequested)
		return YES;

	if(![self _createSimulationOutputDirectory: error])
		return NO;

	if(![self _createSimulationOutputFiles: error])
		return NO;

	//FIXME: Temporary way to record the options used to
	//generate a simulation

	optionsFile = [[[simulationData dataStorage] 
				storagePath] 
				stringByAppendingPathComponent: @"Template"];
	[simulatorTemplate writeToFile: optionsFile atomically: NO];

	return YES;
}

- (BOOL) createControllerOutputDirectory: (NSError**) error
{
	controllerOutputDir = [[NSUserDefaults standardUserDefaults] 
			stringForKey: @"ControllerOutputDir"];

	if(controllerOutputDir == nil)
	{
		controllerOutputDir = [[fileManager currentDirectoryPath] 
				stringByAppendingPathComponent: @"ControllerOutput"];
		NSWarnLog(@"Controller output directory not specified. Defaulting to %@", controllerOutputDir);		
	}
	
	[controllerOutputDir retain];
	if(![self _checkDirectory: controllerOutputDir error: error])
	{
		/*
		 * If checkDirectory:error set an error we return immediately..
		 * Otherwise we try to create the missing directory.
		 */

		if(*error != nil)
			return NO;

		if(![self _createDirectory: controllerOutputDir error: error])
			return NO;
	}		

	GSPrintf(stdout, @"Controller output directory is %@.\n", controllerOutputDir);

	return YES;
}

- (BOOL) restartRequested
{
	return restartRequested;
}

- (void) saveResults: (NSArray*) anArray
{
	int i = 0;
	NSString* fileName;
	NSEnumerator* resultsEnum;
	id result;

	resultsEnum = [anArray objectEnumerator];
	while((result = [resultsEnum nextObject]))
	{
		if(![result isKindOfClass: [AdDataSet class]])
			[NSException raise: NSInvalidArgumentException
				format: @"Controller results can only be AdDataSet instances.\
				 This indicates a bug in the controller used."];
			
		if([result name] != @"None")
			fileName = [result name];
		else
			fileName = [NSString stringWithFormat: @"results%d.out", i];
			
		fileName = [controllerOutputDir stringByAppendingPathComponent: fileName];
		GSPrintf(stderr, @"Output data set at %@", fileName);	
		[NSKeyedArchiver archiveRootObject: result toFile: fileName];
		i++;
	}	
}

/* 
 * Accessors 
 */

- (NSString*) simulationOutputDirectory 
{
	return [[outputDir retain] autorelease];
}

- (NSString*) controllerOutputDirectory
{
	return [[controllerOutputDir retain] autorelease];
}

- (NSString*) controllerDirectory
{
	return [[controllerDir retain] autorelease];
}

- (NSString*) adunDirectory
{
	return [[adunDir retain] autorelease];
}

- (NSDictionary*) template
{
	return [[simulatorTemplate retain] autorelease];
}

- (NSDictionary*) externalObjects
{
	return [[externalObjects retain] autorelease];
}

- (AdSimulationData*) simulationData
{
	return [[simulationData retain] autorelease];
}

- (id) simulationWriteStorage
{
	return [[writeModeStorage retain] autorelease];
}

/*
 * Commands
 */

- (void) setCore: (id) object
{
	core = object;
}

- (id) core
{
	return core;
}

- (id) execute: (NSDictionary*) commandDict error: (NSError**) errorResult;
{
	NSString* command;
	SEL commandSelector;
	id result;

	NSDebugLLog(@"Execute", @"Recieved %@", commandDict);

	if((command = [commandDict objectForKey: @"command"]) == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"The command dictionary is missing the command key"];
	
	NSDebugLLog(@"Execute", @"Command is %@. Querying core %@ for validity", command, core);

	if(![core validateCommand: command])	
	{
		result = nil;
		*errorResult = AdCreateError(AdunCoreErrorDomain,
					AdCoreCommandError,
					[NSString stringWithFormat: @"The supplied command (%@) is invalid", command],
					nil,
					nil);
		return result;
	}	
	
	commandSelector = NSSelectorFromString([NSString stringWithFormat:@"%@:", command]);
	
	NSDebugLLog(@"Execute", @"Command validated. Exectuing");

	//Catch exceptions raised by any programmatic errors in the command.
	//We convert them to errors, log them, and continue the simulation.
	NS_DURING
	{
		result = [core performSelector: commandSelector 
				withObject: [commandDict objectForKey: @"options"]];
	}
	NS_HANDLER
	{
		NSWarnLog(@"Caught an %@ exception", [localException name]);
		NSWarnLog(@"Reason %@", [localException reason]);
		NSWarnLog(@"User info %@", [localException userInfo]);
		NSWarnLog(@"This exception was generated by dynamic command %@", command);
		NSWarnLog(@"Options were %@", [commandDict objectForKey: @"options"]);
		NSWarnLog(@"Continiuing simulation - there may be errors depending on the nature of the command");
		*errorResult = AdCreateError(AdunCoreErrorDomain,
				AdCoreFatalCommandError,
				[NSString stringWithFormat: 
				@"The dynamic command %@ raised an exception", command],
				@"This is probably due to a programming error in the command",
				@"Notify the adun developers supplying the log for the simulation run");
		return nil;
	}
	NS_ENDHANDLER

	NSDebugLLog(@"Execute", @"Command executed. Results %@", result);
	*errorResult = [core errorForCommand: command];
	NSDebugLLog(@"Execute", @"Error is %@", *errorResult);

	return result;
}

- (NSMutableDictionary*) optionsForCommand: (NSString*) command;
{
	return [core optionsForCommand: command];
}

- (NSArray*) validCommands
{
	return [core validCommands];
}

/*
 * Input/Output related methods
 */

- (FILE*) openFile: (NSString*) file  usingName: (NSString*) name flag: (NSString*) fileFlag
{
	const char* filename;
	const char* flag;
	FILE* file_p;

	if(file == nil)
	{
		NSWarnLog(@"There is no file called %@\n", file);
		return NULL;
	}
	
	if(![fileManager fileExistsAtPath: file])
		NSWarnLog(@"File %@ does not exist. Will create it if flag indicates\n", file);

	filename = [file cString];
	flag = [fileFlag cString];

	//open the file

	file_p = fopen(filename, flag);
	if(file_p == NULL)
	{
		NSWarnLog(@"File %@ does not exist and flag is %@\n", file, fileFlag);
		return NULL;
	}
	else
		[fileStreams setObject: [NSValue valueWithPointer: file_p] forKey: name];

	return file_p;
}

- (FILE*) getStreamForName: (NSString*) name
{
	return (FILE*)[[fileStreams objectForKey: name] pointerValue];
}

- (void) closeStreamWithName: (NSString*) name
{
	fclose([self getStreamForName: name]);
	[fileStreams removeObjectForKey: name];
}

- (void) closeAllStreams
{
	NSEnumerator *enumerator = [fileStreams keyEnumerator];
	id name;
	
	while(name = [enumerator nextObject])
		[self closeStreamWithName: name];

}

@end

/*
Contains methods for handling the loading of simulation data
in the different run modes - server, command line and restart
*/
@implementation AdIOManager (SimulationDataLoading)

- (BOOL) _loadServerData: (NSError**) error
{
	if(![self isConnected])
	{
		/*
		 * An external object should detect if we are in 
		 * AdCoreServerRunMode and the connection state before this 
		 * calling this method. Hence we could be here due to a 
		 * programmatic error.
		 *
		 * However it is also possible the server crashed after the connection
		 * was made. Therefore we set an error instead of raising
		 * an exception.
		 */
		*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreInvalidTemplateError,
				       @"Attempt to retrieve server data failed",
				       @"Program not connected to server and in AdCoreServerRunMode.",
				       @"This is possibly due to a server crash. However it could also indicate a bug in the program.");	
		return NO;
	}
	
	GSPrintf(stdout, @"Retrieving data from the server.\n");
	
	simulatorTemplate = [serverProxy templateForProcess: 
			     [[NSProcessInfo processInfo] processIdentifier]];			
	externalObjects = [serverProxy externalObjectsForProcess: 
			   [[NSProcessInfo processInfo] processIdentifier]];
	
	if(simulatorTemplate == nil)	
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreInvalidTemplateError,
				       @"Error loading template",
				       @"Server returned nil for template.", 
				       @"Notify the developers of the error sending the template used to create this simulation.");	
		return NO;
	}
	
	if(externalObjects == nil || [externalObjects count] == 0)	
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreInvalidTemplateError,
				       @"Error retrieving simulation object",
				       @"The server did not supply any data for the simulation",
				       @"Notify the developers of the error sending the template used to create this simulation.");	
		return NO;
	}
	
	[simulatorTemplate retain];
	[externalObjects retain];
	
	return YES;
}

- (BOOL) _loadCommandLineData: (NSError**) error
{
	NSString* templateFile;
	NSDictionary* dict;
	NSMutableDictionary* temp;
	NSEnumerator* keyEnum;
	id key, object;
	NSError* anError;
	
	GSPrintf(stdout, @"Retrieving data from the command line.\n");
	
	//Unarchive data in template file
	templateFile = [[NSUserDefaults standardUserDefaults]
			stringForKey: @"Template"];
	simulatorTemplate = [NSMutableDictionary dictionaryWithContentsOfFile: templateFile];
	//Check that it was unarchived correctly.
	//Further template checks will be performed by an AdTemplateProcessor object.
	if(simulatorTemplate == nil)
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				       AdCoreInvalidTemplateError,
				       @"Error loading template",
				       [NSString stringWithFormat:
					@"Unable to retrieve template from specified file %@", 
					templateFile],
				       @"Check the specified file exists and contains a valid template object");	
		
		return NO;
	}
	else
		[simulatorTemplate retain];
	
	//Read in command line external objects declarations
	
	anError = nil;
	temp = nil;
	if((dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"ExternalObjects"]) != nil)
	{
		keyEnum = [dict keyEnumerator];
		temp = [NSMutableDictionary dictionary];
		while((key = [keyEnum nextObject]))
		{
			object = [NSKeyedUnarchiver unarchiveObjectWithFile: 
				  [dict objectForKey: key]];
			if(object == nil)
			{
				anError = AdCreateError(AdunCoreErrorDomain,
							AdCoreInvalidTemplateError,
							@"Error processing command line objects",
							[NSString stringWithFormat:
							 @"Unable to retrieve object from file %@", 
							 [dict objectForKey: key]],
							@"Check the specified file exists and contains a valid object");	
				break;
			}
			[temp setObject: object
				 forKey: key];
		}
		
		[externalObjects release];
		externalObjects = [temp copy];
	}
	
	if(anError != nil)
	{
		*error = anError;
		return NO;
	}	
	else
		return YES;	
}

- (BOOL) _loadRestartData: (NSError**) error
{
	BOOL successFlag;
	int numberOfFrames, numberOfSystems, numberOfExternalObjects;
	NSString* templateFile, *dataDirectory, *name;
	NSMutableDictionary* temp;
	NSEnumerator* systemEnum;
	AdSystemCollection* systemCollection;
	AdFileSystemSimulationStorage* readModeStorage;
	id system, dataSource;
	
	simulationData = [NSKeyedUnarchiver unarchiveObjectWithFile:
			  [[NSUserDefaults standardUserDefaults] 
			   stringForKey: @"Continue"]];
	[simulationData retain];
	
	dataDirectory = [[simulationData identification]
			 stringByAppendingString: @"_Data"];
	dataDirectory = [outputDir stringByAppendingPathComponent: dataDirectory];	
	readModeStorage = [AdFileSystemSimulationStorage 
			   storageForSimulation: simulationData
			   inDirectory: outputDir
			   mode: AdSimulationStorageReadMode 
			   error: error];
	
	//Load the template
	templateFile = [dataDirectory stringByAppendingPathComponent: @"Template"];
	simulatorTemplate = [NSDictionary dictionaryWithContentsOfFile: templateFile];
	
	if(*error != nil)
	{	
		successFlag = NO;	   
	}
	else if(simulatorTemplate == nil)
	{
		//Create a new error with the data storage error underlying it.
		*error = AdErrorWithUnderlyingError(AdunCoreErrorDomain,
				       AdCoreRestartError, 
				       @"Unable to restart simulation", 
				       @"Could not access simulation storage", 
				       @"See underlying error for more information",
				       *error);
		successFlag = NO;
	}
	else
	{
		[simulationData setDataStorage: readModeStorage];
		[simulationData loadData];
		[simulatorTemplate retain];
		writeModeStorage = [[AdFileSystemSimulationStorage alloc]
				    initSimulationStorageAtPath: dataDirectory
				    mode: AdSimulationStorageAppendMode
				    error: error];	
		
		/*
		 * FIXME: There is a problem when it comes to the external objects.
		 * In the template the externalObjects section contains the names of files containing objects.
		 * However this information is not stored at the end of the simulation.
		 * Therefore on restart we cannot know which data source in the simulation data
		 * corresponds to which external object name in the template.
		 * The problem is compounded if extra external object were specified on the command line
		 * since there is no recorded information on these names at all.
		 *
		 * There are three solutions
		 * 1 - The entire object graph has to be encoded.
		 * 2 - The correspondance between the template names given to each external object  
		 * and the external objects themselves has to be recorded.
		 * 3 - The above correpsondance has to be specified by the user on restart.
		 *
		 * For now only handle case where there was one external object and one data source.
		 */
		
		temp = [[simulatorTemplate objectForKey: @"externalObjects"] mutableCopy];
		systemCollection = [simulationData systemCollection];
		numberOfFrames = [simulationData numberOfFrames];
		numberOfSystems = [[systemCollection fullSystems] count];
		numberOfExternalObjects = [temp count]; 
		if(numberOfSystems == numberOfExternalObjects)
		{
			//Get the only data source
			system = [[systemCollection fullSystems] objectAtIndex: 0];
			dataSource = [system dataSource];
			name = [[temp allKeys] objectAtIndex: 0];
			[temp setObject: dataSource forKey: name];
			externalObjects = [temp copy];
			
			NSLog(@"Loaded Restart Data -  %@", simulationData); 
			NSLog(@"External objects - %@", externalObjects);
			successFlag = YES;
		}
		else
		{
			 *error = AdCreateError(AdunCoreErrorDomain,
						AdCoreRestartError, 
						@"Error restarting simulation", 
						@"Unable to determine external object mapping", 
						@"As of version 0.81 only single system simulations can be restarted");
			 successFlag = NO;
		}
		
		[temp release];
	}	
	
	return successFlag;	
}

@end

