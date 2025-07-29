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

#include "ULProcessManager.h"

static id processManager;

@implementation ULProcessManager 

- (BOOL) _checkForServerOnHost: (NSString*) host
{
	NSPort* port;

	port = nil;
	if([host isEqual: [[NSHost currentHost] name]])
		port = [[NSMessagePortNameServer sharedInstance]
			portForName: @"AdunServer"];
		
	if(port == nil)
#ifdef GNUSTEP	
		port = [[NSSocketPortNameServer sharedInstance]
			portForName: @"AdunServer" 
			onHost: host];
#else
		port = [[NSSocketPortNameServer sharedInstance]
			portForName: @"AdunServer" 
			     host: host];
#endif			     

	if(port == nil)
		return NO;

	return YES;
}

- (void) _handleConnectionsDidDie: (NSNotification*) aNotification
{
	id host, process;
	NSEnumerator* processEnum;
	NSString* errorString, *suggestionString;
	NSError* error;
	NSMutableDictionary* errorInfo;
	NSMutableDictionary* userInfo;

	[[NSNotificationCenter defaultCenter] removeObserver: self
		name: NSConnectionDidDieNotification
		object: [aNotification object]];
	
	//check the host

	host = [[connections allKeysForObject: [aNotification object]] 
			objectAtIndex: 0];

	/*
	 * We receive this when the last simulation run by the server dies OR
	 * when the server crashes. We must distinguish between these two possibilities.
	 * 
	 * In the first case simply remove the invalid connection from the connections dict.
	 * When the next simulation is started a new one will be established
	 *
	 * In the second case we have to remove the connection, set all the processes running on 
	 * the host controlled by the server to "Disconnected", set an error and post a notification
	 * of the servers death.
	 */

	[connections removeObjectForKey: host];

	if(![self _checkForServerOnHost: host])
	{	
		NSWarnLog(@"Detected server death");

		//set all current processes on the host as disconnected

		processEnum = [spawnedStack objectEnumerator];
		while((process = [processEnum nextObject]))
			if([[process processHost] isEqual: host] && [[process processStatus] isEqual: @"Running"])
				[process setProcessStatus: @"Disconnected"];

		errorString = [NSString stringWithFormat: 
				@"Unexpected disconnection from AdunServer on host %@\nPossible server crash.", host];
		suggestionString = @"There is currently no way to reaquire a dynamic connection to disconnected simulations.\
\nHowever it is likely they are still running.\nExamine the AdunCore.logs for the disconnected process to determine the\
situation.\nDisconnected simulations will continue to collect results which can still be accessed through the results\
interface.\nPease send the file AdunServerCrash.log in the adun directory to the developers.";

		errorInfo = [NSMutableDictionary dictionary];
		[errorInfo setObject: errorString forKey: NSLocalizedDescriptionKey];
		[errorInfo setObject: suggestionString forKey: @"NSLocalizedRecoverySuggestionKey"];

		error = [NSError errorWithDomain: @"ULServerConnectionDomain" 
				code: 1
				userInfo: errorInfo];

		userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject: error forKey: @"ULDisconnectionErrorKey"];
		[userInfo setObject: host forKey: @"ULDisconnectedHostKey"];

		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDisconnectedFromServerNotification"
			object: self
			userInfo: userInfo];
	}
}

//The exceptions here should be errors

- (id) _proxyForHost: (NSString*) hostname
{
	id connection;
	NSPort* port;

	if((connection = [connections objectForKey: hostname]) == nil)
	{
		if([hostname isEqual: [[NSHost currentHost] name]])
		{
			//if we're trying to connect to the local host first try to connect to
			//AdunServer through message ports then socket ports

			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
					host: nil];
		
			if(connection == nil)
				connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
						host: hostname 
						usingNameServer: [NSSocketPortNameServer sharedInstance]]; 
		}	
		else
		{
			//if we're not trying to connect to the local host their must be
			//an AdunServer using NSSocketPorts on the remote machine

			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
					host: hostname 
					usingNameServer: [NSSocketPortNameServer sharedInstance]]; 
			NSDebugLLog(@"ULProcessManager", 
				@"Connected to host %@ hostname using connection %@", 
				hostname, connection);
		}
		
		if(connection == nil)
		{
			[[NSException exceptionWithName: @"ULCouldNotConnectToServerException" 
				reason: [NSString stringWithFormat: @"Couldn't connect to host %@.", hostname]
				userInfo: [NSDictionary dictionaryWithObject: hostname forKey: @"host"]]
				raise];
		}		

		NSDebugLLog(@"ULProcessManager", 
			@"Connection statistics %@", [connection statistics]);
		[connections setObject: connection forKey: hostname];

		//register for notifications

		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(_handleConnectionsDidDie:)
			name: NSConnectionDidDieNotification
			object: connection];
	}

	//check is connection still valid 

	if(![connection isValid])
	{
		//try to reconnect
			
		port = [connection sendPort];
	
		if([port isMemberOfClass: [NSMessagePort class]])
			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
					host: hostname 
					usingNameServer: [NSMessagePortNameServer sharedInstance]]; 
		else
			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
					host: hostname 
					usingNameServer: [NSSocketPortNameServer sharedInstance]]; 
	
		if(connection == nil)
			[NSException raise: NSInternalInconsistencyException 
				format: @"Connection for host %@ invalid and couldnt reconnect.", hostname];
		
		[connections setObject: connection forKey: hostname];
	}

	return [connection rootProxy];
}

+ (void) inititialize
{
	processManager = nil;
}

+ (id) appProcessManager
{
	if(processManager == nil)
		processManager = [ULProcessManager new];

	return [[processManager retain] autorelease];
}

/**
Restores processes that were running or waiting
when the application last closed.
*/
- (void) _restoreProcesses
{
	NSFileManager* fileManager;
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	NSString* applicationDir, *fileName, *dataDir;
	NSEnumerator* processEnum;
	NSArray* array;
	NSMutableArray* reconnectErrors = [NSMutableArray array];
	ULProcess* process;
	AdSimulationData* simulationData;
	AdFileSystemSimulationStorage* storage;
	id proxy;
	
	applicationDir	= [[ULIOManager appIOManager] applicationDir];
	fileManager = [NSFileManager defaultManager];	
	fileName = [applicationDir stringByAppendingPathComponent: @".waitingProcesses"];
	if([fileManager fileExistsAtPath: fileName])
	{						
		array = [NSKeyedUnarchiver unarchiveObjectWithFile: fileName];
		[newStack addObjectsFromArray: array]; 
		[fileManager removeFileAtPath: fileName handler: NULL];
	}
	
	fileName = [applicationDir stringByAppendingPathComponent: @".spawnedProcesses"];	
	if([fileManager fileExistsAtPath: fileName])
	{						
		array = [NSKeyedUnarchiver unarchiveObjectWithFile: fileName];
		[fileManager removeFileAtPath: fileName handler: NULL];
		processEnum = [array objectEnumerator];
		while((process = [processEnum nextObject]))
		{
			[notificationCenter
				addObserver: self
				selector: @selector(processTermination:)
				name: @"ULProcessDidFinishNotification"
				object: process];
			//Recreate a data storage object for the processes
			//AdSimulationData instance - since storage is volatile
			//it isnt encoded with it (this may change).
			//However we have to check if the simualationData was
			//sent be the server before the program was last shut down
			if((simulationData = [process simulationData]) != nil)
			{	
				//This will change when the location of the simulation
				//directory is added to the ULProcess instance along
				//with the rest of the arguments to AdunCore.
				dataDir = [[[ULDatabaseInterface databaseInterface]
						primaryFileSystemBackend] simulationDir];
				dataDir = [dataDir stringByAppendingPathComponent: 
						[NSString stringWithFormat: @"%@_Data", 
							[simulationData identification]]];
				//FIXME: Add error handling		
				storage = [[AdFileSystemSimulationStorage alloc]
						initForReadingSimulationDataAtPath: dataDir ];
				[simulationData setDataStorage: storage];
			}
			proxy = [self _proxyForHost: [process processHost]];
			//We have to handle the case where the server fails to 
			//reconnect the process. This happens when the server itself
			//crashed since the process was disconnected.
			if(![proxy reconnectProcess: process])
			{
				[reconnectErrors addObject: process];
				[notificationCenter removeObserver: self
					name: nil
					object: process];
			}
			else
				[spawnedStack addObject: process];
		}
	}		
		
	//Send a notification about any failed reconnections
	if([reconnectErrors count] > 0)
		[notificationCenter
			postNotificationName: @"ULProcessManagerProcessReconnectionFailedNotification"
			object: reconnectErrors];
}

- (id) init
{
	if(processManager != nil)
		return [processManager retain];

	if((self = [super init]))
	{
		newStack = [NSMutableArray new];
		spawnedStack = [NSMutableArray new];
		finishedStack = [NSMutableArray new];
		connections = [NSMutableDictionary new];
		automaticSpawn = NO;

		hosts = [[ULIOManager appIOManager] adunHosts];
		[hosts retain];

		NSDebugLLog(@"ULProcessManager", @"Available hosts %@", hosts);
		processManager = self;

		//The standard args for running Adun 
		//FIXME: Make this a ULProcess ivar so we can have per process options
		standardArgs = [NSMutableArray arrayWithObjects: 
					@"-SimulationOutputDir", 
					[[[ULDatabaseInterface databaseInterface] 
						primaryFileSystemBackend] simulationDir],
					@"-ControllerOutputDir", 
					[[ULIOManager appIOManager] controllerOutputDir],
					nil];
		[standardArgs retain];
		[self _restoreProcesses];
	}

	return self;
}

- (void) dealloc
{
	[newStack release];
	[spawnedStack release];
	[finishedStack release];
	[connections release];
	[hosts release];
	[standardArgs release];
	[super dealloc];
}

- (BOOL) applicationShouldClose
{
	BOOL value = YES;
	NSEnumerator* processEnum;
	ULProcess* process;
	
	processEnum = [spawnedStack objectEnumerator];
	while((process = [processEnum nextObject]))
		if(![process hasSentProcessData])
		{
			value = NO;
			break;
		}
		
	return value;	
}

- (void) applicationWillClose
{
	NSString* applicationDir;
	NSEnumerator* spawnedStackEnum;
	ULProcess* process;
	id proxy;

	applicationDir = [[ULIOManager appIOManager] applicationDir];
	
	//Send processWillDisconnect: to the server for each running process
	//This prevents the server sending any messages to these processes while
	//the application is closed.
	spawnedStackEnum = [spawnedStack objectEnumerator];
	while((process = [spawnedStackEnum nextObject]))
	{	
		proxy = [self _proxyForHost: [process processHost]];
		//Check the process hasnt finished since we started
		//enumerating.
		if(![process isFinished])
			[proxy processWillDisconnect: process];
	}
	
	if([spawnedStack count] > 0)
		[NSKeyedArchiver archiveRootObject: spawnedStack 
			toFile: [applicationDir stringByAppendingPathComponent: @".spawnedProcesses"]]; 
			
	//Write the waiting, running, and finished process information to files.
	if([newStack count] > 0)
		[NSKeyedArchiver archiveRootObject: newStack
			toFile: [applicationDir stringByAppendingPathComponent: @".waitingProcesses"]]; 
	
}

- (void) newProcessWithInputData: (NSDictionary*) aDict
		simulationTemplate: (id) simulationTemplate 
		host: (NSString*) host
{
	id process;
	int index;
	id ioManager = [ULIOManager appIOManager];

	//add the process to the newStack
	
	NSDebugLLog(@"ULProcessManager", 
		@"Creating process with objects %@ and template %@", 
		aDict, 
		simulationTemplate);
		
	process = [ULProcess processWithInputData: aDict 
			simulationTemplate: simulationTemplate
			additionalArguments: nil
			host: host];

	//Set controller output dir
	index = [standardArgs indexOfObject: @"-ControllerOutputDir"];
	[standardArgs replaceObjectAtIndex: index + 1 
				withObject: [[ioManager controllerOutputDir]
					     stringByAppendingPathComponent: [process name]]];	
	[process addArguments: standardArgs];				     
	
	[newStack addObject: process]; 
	//FIXME: Change when we change simulationTemplate to a real template
		
	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULDidCreateNewProcessNotification"
		object: self];

	NSDebugLLog(@"ULProcessManager",
		@"Added process to newStack. Currently %d objects on newStack", 
		[newStack count]);
	NSDebugLLog(@"ULProcessManager", 
		@"New object id %@", 
		[process identification]);
}

- (void) spawnNewProcess
{
	id proxy, process, host, error;
	
	NSDebugLLog(@"ULProcessManager", @"Preparing process for launch");

	if([newStack count] == 0)
		[NSException raise: NSInternalInconsistencyException
			format: @"There are no simulations waiting to be spawned"];

	process = [newStack objectAtIndex: 0];
	host = [process processHost]; 
	
	NSDebugLLog(@"ULProcessManager", @"Spawining process on host %@", host);
	
	proxy = [self _proxyForHost: host];

	GSPrintf(stdout, @"Starting Sim using proxy %@\n", proxy);
	NSDebugLLog(@"ULProcessManager", @"Process is %@ , %@, %@", 
		[process inputData], 
		[process simulationTemplate],
		[process arguments]);
	
	error = [proxy startSimulation: process];
		
	if(error == nil)
	{
		[[NSNotificationCenter defaultCenter] 
			addObserver: self
			selector: @selector(processTermination:)
			name: @"ULProcessDidFinishNotification"
			object: process];
		[newStack removeObject: process];
		[spawnedStack addObject: process];
	
		[[NSNotificationCenter defaultCenter] 
			postNotificationName: @"ULDidLaunchProcessNotification"
			object: self];
	}
	else
		[NSException raise: NSInternalInconsistencyException
			format: [error localizedDescription]];
}

- (void) processTermination: (NSNotification*) aNotification
{
	NSArray* dataSets, *waitingProcesses;
	NSEnumerator* dataSetEnum, *inputDataEnum;
	AdSimulationData *simulation;
	id process, dataSet, object;
		
	NSDebugLLog(@"ULProcessManager", @"Received a process termination message");

	process = [aNotification object];
	[[NSNotificationCenter defaultCenter] removeObserver: self
		name: nil
		object: process];
	[spawnedStack removeObject: process];
	[finishedStack addObject: process];

	//Add the simulation data to the database.
	simulation = [process simulationData];
	if(simulation != nil)
	{
		[[ULDatabaseInterface databaseInterface] 
			addObjectToFileSystemDatabase: simulation];
		
		//Add output references to the simulations input data
		//FIXME: Require way to transmit any error in the next
		//step to the user e.g. via the notification sent below
		inputDataEnum = [[process inputData] objectEnumerator];
		while((object = [inputDataEnum nextObject]))
		{
			if([object isKindOfClass: [AdModelObject class]])
			{
				[object addOutputReferenceToObject: simulation];
				[[ULDatabaseInterface databaseInterface]
					updateOutputReferencesForObject: object
					error: NULL];
			}
		}	

		/**
		Import any dataSets that the simulation created to 
		the database.  Add input references to the data sets 
		and output references to the simulation.
		*/
		if((dataSets = [process controllerResults]) != nil)
		{
			dataSetEnum = [dataSets objectEnumerator];
			while((dataSet = [dataSetEnum nextObject]))
			{
				//Add input references for the data sets.		
				[dataSet addInputReferenceToObject: simulation];
				NSDebugMLLog(@"ULProcessManager",
					@"Data set input references %@", 
					[dataSet inputReferences]);

				[[ULDatabaseInterface databaseInterface]
					addObjectToFileSystemDatabase: dataSet];

				//Add output reference to the simulation
				[simulation addOutputReferenceToObject: dataSet];
			}		
			
			NSDebugMLLog(@"ULProcessManager",
				@"Simulation output references %@", 
				[simulation outputReferences]);

			//update the database with the new output references for the simulation
			[[ULDatabaseInterface databaseInterface]
				updateOutputReferencesForObject: simulation
				error: NULL];
		}
	}
	else
		NSWarnLog(@"Simulation wrote no data");

	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULProcessDidFinishNotification"
		object: self
		userInfo: [aNotification userInfo]];
	
	//If automatic spawning is turned on we start the next process that is
	//scheduled to run on the host of the process that just finished.
	if(automaticSpawn)
	{
		waitingProcesses = [self waitingProcessesForHost: [process processHost]];
		if([waitingProcesses count] > 0)
			[self startProcess: [waitingProcesses objectAtIndex: 0]];
	}		
}

- (void) setAutomaticSpawn: (BOOL) value
{
	automaticSpawn = value;
}

- (BOOL) automaticSpawn
{
	return automaticSpawn;
}

- (int) numberWaitingProcesses
{
	return [newStack count];
}

- (int) numberSpawnedProcesses
{
	return [spawnedStack count];
}

- (NSArray*) waitingProcesses
{
	return [[newStack copy] autorelease];
}

- (NSArray*) waitingProcessesForHost: (NSString*) hostname
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* processEnum;
	ULProcess* process;
	
	processEnum = [newStack objectEnumerator];
	while((process = [processEnum nextObject]))
	{
		if([[process processHost] isEqual: hostname])
			[array addObject: process];
	}
	
	return [[array copy] autorelease];
}

- (NSArray*) spawnedProcesses
{
	return [[spawnedStack copy] autorelease];
}

- (NSArray*) finishedProcesses
{
	return [[finishedStack copy] autorelease];
}

- (NSArray*) allProcesses
{
	id array;

	array = [newStack arrayByAddingObjectsFromArray: spawnedStack];
	return [array arrayByAddingObjectsFromArray: finishedStack];
}

- (NSArray*) hosts
{
	return [[hosts copy] autorelease];
}

- (void) haltProcess: (ULProcess*) process
{
	id proxy;

	if([[process processStatus] isEqual: @"Running"])
	{
		proxy = [self _proxyForHost: [process processHost]];
		[proxy haltProcess: process];
		[process setProcessStatus: @"Suspended"];
	}
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is not running"];
	
	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULProcessStatusDidChangeNotification"
		object: self];
}

- (void) restartProcess: (ULProcess*) process
{
	id proxy;

	NSDebugMLLog(@"ULProcessManager", @"Restarting %@, status %@", 
		process, [process processStatus]);

	if([[process processStatus] isEqual: @"Suspended"])
	{
		proxy = [self _proxyForHost: [process processHost]];
		[proxy restartProcess: process];
		[process setProcessStatus: @"Running"];
	}
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is not suspended"];

	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULProcessStatusDidChangeNotification"
		object: self];
}

- (void) terminateProcess: (ULProcess*) process
{
	id proxy;
	id status;

	status = [process processStatus];
	NSDebugMLLog(@"ULProcess", @"Terminating %@, status %@", 
		process, [process processStatus]);

	if([status isEqual: @"Running"] || 
		[status isEqual: @"Suspended"])
	{
		proxy = [self _proxyForHost: [process processHost]];
		[proxy terminateProcess: process];
	}
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process has not been started"];
}

- (void) startProcess: (ULProcess*) process
{
	if([[process processStatus] isEqual: @"Waiting"])
	{
		[newStack removeObject: process];
		[newStack insertObject: process atIndex: 0];
		[self spawnNewProcess];
	}
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is not waiting"];

	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULProcessStatusDidChangeNotification"
		object: self];
}

- (void) removeProcess: (ULProcess*) process
{
	if([[process processStatus] isEqual: @"Finished"])
		[finishedStack removeObject: process];
	else if([[process processStatus] isEqual: @"Waiting"])
		[newStack removeObject: process];
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is running"];

	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULProcessStatusDidChangeNotification"
		object: self];
}

- (id) execute: (NSDictionary*) commandDict error: (NSError**) error process: (id) process
{
	id proxy;
	id result;
	id receivePort, connection;
	NSMutableDictionary* errorInfo;
	NSString* descriptionString, *suggestionString;
	
	if([[process processStatus] isEqual: @"Running"])
		proxy = [self _proxyForHost: [process processHost]];
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is not running"];

	NS_DURING
	{
		[[proxy connectionForProxy] setReplyTimeout: 10.0];
		[[proxy connectionForProxy] setRequestTimeout: 10.0];
		NSDebugLLog(@"ULProcessManager", @"Sending command %@", commandDict);
		result = [proxy execute: commandDict 
				error: error
				process: process];
		NSDebugLLog(@"ULProcessManager", @"Command exectuted. Result %@", result);		
	}
	NS_HANDLER
	{
		connection = [proxy connectionForProxy];
		
		//if the port is still valid - set an error
		if([connection isValid])
		{
			errorInfo = [NSMutableDictionary dictionary];
			
			descriptionString = [NSString stringWithFormat: @"Attempt to send command %@ to %@ timed out.\n",
						[commandDict objectForKey: @"command"], 
						[process processHost]];
			suggestionString = @"This could be due to the server being busy or the underlying operating\
system.\nTry again later.";

			[errorInfo setObject: descriptionString 
				forKey: NSLocalizedDescriptionKey];
			[errorInfo setObject: suggestionString 
				forKey: @"NSLocalizedRecoverySuggestionKey"];
			*error = [NSError errorWithDomain: @"ULServerConnectionDomain"
					code: 1
					userInfo: errorInfo];
		}	
		
		/*
		If either port (i.e. send or recieve) was invalidated and was an NSMessagePort 
		we will receive an NSConnectionDidDieNotification and we will handle the results then. 
		However if we are using socket ports we wont recieve this notification 
		for an exception on the remote (the receive) port and 
		must check for it here and raise the exception ourselves
		*/

		receivePort = [connection receivePort];
		if([receivePort isMemberOfClass: [NSSocketPort class]])
			if(![receivePort isValid])
				[[NSNotificationCenter defaultCenter] 
					postNotificationName: NSConnectionDidDieNotification
					object: [proxy connectionForProxy]];
	}
	NS_ENDHANDLER

	return result;
}

- (NSMutableDictionary*) optionsForCommand: (NSString*) name process: (id) process
{
	id proxy;
	
	if([[process processStatus] isEqual: @"Running"])
		proxy = [self _proxyForHost: [process processHost]];
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is not running"];

	return [proxy optionsForCommand: name
			process: process];
}

- (NSArray*) validCommandsForProcess: (id) process
{
	id proxy;
	

	if([[process processStatus] isEqual: @"Running"])
		proxy = [self _proxyForHost: [process processHost]];
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Selected process is not running"];

	return [proxy validCommandsForProcess: process];
}

@end
