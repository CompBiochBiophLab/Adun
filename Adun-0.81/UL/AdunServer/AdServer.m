/*
   Project: AdunServer

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-31 15:41:02 +0200 by michael johnston

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

#include "AdServer.h"
#include <Foundation/NSPort.h>
#ifdef GNUSTEP
#include <wait.h>
#endif

@implementation AdServer

- (void) kernelTermination: (NSNotification*) aNotification
{
	NSError* error = nil;
	NSMethodSignature* signature;
	NSInvocation* invocation;

	/*
	 * Core Exit Procedure : 
	 * On controlled exit - Posts an exit (error) message with the server via closeConnection: 
	 * On uncontrolled exit - Does nothing
	 *
	 * Here we check if the process posted an error message eariler via closeConnection.
	 * If it didn't we create an error using the exit status code and use that instead.
	 */

	int status = [[aNotification object] terminationStatus];
	int pid;
	NSNumber* processIdentifier;
	id task, process;
	NSMutableDictionary* errorInfo;

	task = [aNotification object];
	pid = [task processIdentifier];
	processIdentifier = [NSNumber numberWithInt: pid];

       	NSWarnLog(@"Kernel process %d exited with status %d. (%s)", pid, status, strerror(status));
	
	error = nil;
	NSDebugLLog(@"AdunServer", @"Checking for error from AdunCore");
	if((error = [processErrors objectForKey: processIdentifier]) != nil)
		NSWarnLog(@"Kernel posted error %@", [error userInfo]);
	else if(status != 0)
	{
		NSDebugLLog(@"AdunServer", @"No error posted - creating one now.");
		errorInfo =  [NSMutableDictionary dictionary];
		[errorInfo setObject: @"Simulation terminated by uncaught signal.\n"
			forKey: NSLocalizedDescriptionKey];
		[errorInfo setObject: [NSString stringWithFormat:
					@"Exit code %d - %s.\n", status, strerror(status)]
			forKey: @"AdDetailedDescriptionKey"];
		[errorInfo setObject: @"Please submit this event along with the system and options used\
 to the support tracker at gna.org/projects/adun.\n"
			forKey: @"NSRecoverySuggestionKey"];

		error = [NSError errorWithDomain: @"AdCoreErrorDomain"
				code: 5
				userInfo: errorInfo];
	}
	
	if([disconnectedProcesses containsObject: processIdentifier])
	{
		signature = [ULProcess instanceMethodSignatureForSelector: @selector(processDidTerminate:)];
		invocation = [NSInvocation invocationWithMethodSignature: signature];
		[invocation setSelector: @selector(processDidTerminate:)];
		
		if(error == nil)
			[invocation setArgument: &error atIndex: 2];
		else
		{	
			[invocation setArgument: &error atIndex: 2];
			[invocation retainArguments];	
		}
		
		if([storedMessages objectForKey: processIdentifier] == nil)
			[storedMessages setObject: [NSMutableArray array]
				forKey: processIdentifier];
		
		[[storedMessages objectForKey: processIdentifier] addObject: invocation];		
	}
	else
	{
		NSDebugLLog(@"AdunServer", @"Retrieving relevant process object");
		process = [processes objectForKey: [NSNumber numberWithInt: pid]];
		NSDebugLLog(@"AdunServer", @"Notifying process object of termination");
		[process processDidTerminate: error];
	}
	
	[processes removeObjectForKey: [NSNumber numberWithInt: pid]];
	[tasks removeObjectForKey: [NSNumber numberWithInt: pid]];
	[state removeObjectForKey: [NSNumber numberWithInt: pid]];
	[processErrors removeObjectForKey: [NSNumber numberWithInt: pid]];
	[interfaces removeObjectForKey: [NSNumber numberWithInt: pid]];
}

- (void) _adunCoreError
{
	[NSException raise: NSInvalidArgumentException
		format: [NSString stringWithFormat: 
			@"Couldnt execute AdunCore. Set AdunCorePath default to the correct file \
and ensure its executable. Check AdServer.log for more information."]];

}

- (BOOL) _testFileExistsIsExecutable: (NSString*) path
{
	if([[NSFileManager defaultManager] fileExistsAtPath: path])
	{
		if([[NSFileManager defaultManager] isExecutableFileAtPath: path])
			return YES;
		else
			return NO;
	}
	else
		return NO;
}

- (void) _redirectOutput
{
	id logFile;

	logFile = [[NSUserDefaults standardUserDefaults] stringForKey: @"LogFile"];
	if(![[NSFileManager defaultManager] isWritableFileAtPath:
		 [logFile stringByDeletingLastPathComponent]])
	{
		logFile = [[[NSUserDefaults standardUserDefaults] 
				volatileDomainForName: NSRegistrationDomain]
				valueForKey:@"LogFile"];
		NSWarnLog(@"Invalid value for user default 'LogFile'. The specificed directory is not writable");
		NSWarnLog(@"Switching to registered default %@", logFile);
		if(![[NSFileManager defaultManager] 
			isWritableFileAtPath: [logFile stringByDeletingLastPathComponent]])
		{
			[NSException raise: NSInternalInconsistencyException
				format: [NSString stringWithFormat:
				 @"Fallback logfile (%@) not writable. Cannot start.", logFile]];
		}
	} 

	freopen([logFile cString], "w", stderr);
}

- (void) _connectToDefaultDatabase
{
	NSString *location, *hostname, *clientName;
	NSError *error = nil;

	//Create an interface to the default filesystem database
	location = [[NSUserDefaults standardUserDefaults] stringForKey: @"DefaultDatabase"];
	hostname = [[NSHost currentHost] name];
	clientName = [NSString stringWithFormat: @"server@%@", hostname];
	defaultBackend = [[ULFileSystemDatabaseBackend alloc] 
				initWithDatabaseName: location 
				clientName: clientName 
				error: &error];
	if(error != nil)
	{
		AdLogError(error);
	}
	else
	{
		NSLog(@"Connected to default database at %@ as %@", 
			[defaultBackend databaseName], [defaultBackend clientName]);
	}
}

- (id) init
{
	int portNumber;
	id adunFile;
	id port;

	if((self = [super init]))
	{
		//redirect output
		if([[NSUserDefaults standardUserDefaults] boolForKey: @"RedirectOutput"])
			[self _redirectOutput];
		
		if([[NSUserDefaults standardUserDefaults] boolForKey: @"IsDistributed"])
		{

			NSLog(@"Using ports to enable distributed computing.\n");
			portNumber = [[NSUserDefaults standardUserDefaults] integerForKey: @"PortNumber"];
#ifdef GNUSTEP
			port = [NSSocketPort portWithNumber: portNumber
				onHost: nil
				forceAddress: nil
				listener: YES];
#else
			port = [[NSSocketPort alloc]
				initWithTCPPort: portNumber];
			[port autorelease];
#endif				
			connection = [[NSConnection alloc] 
					initWithReceivePort: port
					sendPort: nil];
			NSLog(@"Port is %@\n", [port description]);		
			NSDebugLLog(@"AdunServer", @"Connection is %@", connection);		
			NSLog(@"Connection is %@\n", connection);		
			if([connection registerName: @"AdunServer" withNameServer:
					 [NSSocketPortNameServer sharedInstance]] == NO)
			{
				NSWarnLog(@"Failed to vend!");
				exit(1);
			}
			[connection setRootObject: self];
		}
		else
		{
			NSLog(@"Using default message ports. Distributed computing facilites disabled.\n");
			
			connection = [NSConnection defaultConnection];
			[connection setRootObject: self];
			
			if([connection registerName: @"AdunServer"] == NO)
			{
				NSWarnLog(@"Failed to vend!");
				exit(1);
			}
		}

		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(kernelTermination:)
			name: NSTaskDidTerminateNotification
			object: nil];

		tasks = [NSMutableDictionary new];
		interfaces = [NSMutableDictionary new];	
		processes = [NSMutableDictionary new];
		state = [NSMutableDictionary new];
		processErrors = [NSMutableDictionary new];
		storedMessages = [NSMutableDictionary new];
		disconnectedProcesses = [NSMutableArray new];
		
		//Create the default database interface
		[self _connectToDefaultDatabase];
		
		//see if we can locate the adun core executable
		adunCorePath = [[[NSUserDefaults standardUserDefaults] stringForKey: @"AdunCorePath"] 
					stringByAppendingPathComponent: @"AdunCore"];
		[adunCorePath retain];

		if(![self _testFileExistsIsExecutable: adunCorePath])
		{
			NSWarnLog(@"Defaults value for AdunCorePath (%@) is not valid", adunCorePath);
			adunFile = [[[NSUserDefaults standardUserDefaults] 
					volatileDomainForName: NSRegistrationDomain]
					valueForKey:@"AdunCorePath"];
			
			if(![adunCorePath isEqual: adunFile])
			{
				NSWarnLog(@"Falling back on registered default.");
				adunCorePath = adunFile;
				if(![self _testFileExistsIsExecutable: adunCorePath])
				{
					NSWarnLog(@"Adun was installed into a non standard directory.");
					[self _adunCoreError];
				}
			}
			else
				[self _adunCoreError];	
		}
		else
			NSLog(@"Found Adun Core Executable at %@\n", adunCorePath);
	}
	
	fflush(stderr);

	return self;
}

- (void) dealloc
{
	[processes release];
	[tasks release];
	[interfaces release];
	[state release];
	[adunCorePath release];	
	[processErrors release];
	[disconnectedProcesses release];
	[storedMessages release];
	[defaultBackend release];

	[super dealloc];
}

@end

/**
Contains the methods used by other processes to launch and interact with remote simulations.
*/
@implementation AdServer (RemoteSimulationManagement)

//Refactor these messages to use execute:error:process

- (NSError*) startSimulation: (id) process
{
	id task;
	NSMutableDictionary* userInfo;
	NSError* error = nil;

	NSMutableArray* arguments;

	NSDebugLLog(@"AdunServer", @"Recieved a start simulation message");
	NSDebugLLog(@"AdunServer", @"Process Object is %@", [process description]);
	NSDebugLLog(@"AdunServer", @"Found Adun Core Executable at %@", adunCorePath);
	NSDebugLLog(@"AdunServer", @"Process arguments %@", [process arguments]);
				
	NS_DURING
	{
		[process setStarted: [NSDate date]];
		task = [NSTask launchedTaskWithLaunchPath: adunCorePath
			arguments: [process arguments]];

		//FIXME: Its possible that the task will send back a request
		//before we can complete the next two steps causing it to fail.
		//We need to use an identifier other than the pid which isnt available
		//until the task launches e.g. unique process object string.
		//This requires refactoring all the communication protocols however.
		
		[process setProcessIdentifier: [task processIdentifier]];
		[processes setObject: process 
			forKey: [NSNumber numberWithInt: [task processIdentifier]]];
		[tasks setObject: task 
			forKey: [NSNumber numberWithInt: [task processIdentifier]]];
		[state setObject: [NSNumber numberWithBool: NO] 
			forKey: [NSNumber numberWithInt: [task processIdentifier]]];
		
		[process setProcessStatus: @"Running"];	
	}
	NS_HANDLER
	{
		userInfo = [NSMutableDictionary dictionaryWithCapacity: 1];
		[userInfo setObject: 
			[NSString stringWithFormat: @"Unable to lauch simulation - %@", [localException reason]]
			forKey: NSLocalizedDescriptionKey];
		[process setProcessStatus: @"Error"];		

		return [NSError errorWithDomain: @"AdServerErrorDomain"
				code: 1
				userInfo: userInfo];
	}
	NS_ENDHANDLER

	return nil;
}

- (void) haltProcess: (id) process
{
	NSNumber* pid;
	id task;

	pid = [NSNumber numberWithInt: [process processIdentifier]];
	task = [tasks objectForKey: pid];
	[task suspend];
}

- (void) terminateProcess: (id) process
{
	NSNumber* pid;
	id task;

	pid = [NSNumber numberWithInt: [process processIdentifier]];
	task = [tasks objectForKey: pid];
	[task terminate];
}

- (void) restartProcess: (id) process
{
	NSNumber* pid;
	id task;

	pid = [NSNumber numberWithInt: [process processIdentifier]];
	task = [tasks objectForKey: pid];
	[task resume];
}

/*
 * Methods handling disconnection & reconnection
 */
 
- (void) processWillDisconnect: (id) process
{
	[disconnectedProcesses addObject: 
		[NSNumber numberWithInt: [process processIdentifier]]];
}

-(BOOL) reconnectProcess: (id) process
{
	BOOL terminated = NO;
	NSArray* messages;
	NSEnumerator* messageEnum;
	NSInvocation* message;
	NSString* selector;
	NSNumber* pid;
		
	pid = [NSNumber numberWithInt: [process processIdentifier]];
	if(![disconnectedProcesses containsObject: pid])
		return NO;
		
	messages = [storedMessages objectForKey: pid];
	messageEnum = [messages objectEnumerator];
	while(message = [messageEnum nextObject])
	{	
		[message setTarget: process];
		[message invoke];
		selector = NSStringFromSelector([message selector]);
		if([selector isEqual: @"processDidTerminate:"])
			terminated = YES;
	}
	
	//If the process hasnt been terminated while it was disconnected
	//add the new distant object to the process dictionaries.
	if(!terminated)
		[processes setObject: process 
			forKey: pid];
	
	[storedMessages removeObjectForKey: pid];
	[disconnectedProcesses removeObject: pid];
	
	return YES;
}

//Process Core Interface Methods
/*
 *N.B. If you declare in the protocol for DO that an paramter is "out" as in the
pointer to NSError below. It seems you have to assign a value to it or else
you get a seg fault
*/

- (id) execute: (NSDictionary*) commandDict error: (NSError**) error process: (id) process
{
	NSNumber* pid;
	id interface;
	id returnVal;

	NSDebugLLog(@"AdunServer", @"Recieved command request for process %@", process);
	pid = [NSNumber numberWithInt: [process processIdentifier]];
	interface = [interfaces objectForKey:  pid];
	if(interface == nil)
	{
		NSDebugLLog(@"AdunServer", @"The specified process has not provided its interface");
		*error = [NSError errorWithDomain: @"AdServerCommandInterfaceErrorDomain"
				code: 0
				userInfo: [NSDictionary dictionaryWithObject:
					@"The specified process has not provided its interface"
					forKey:
					NSLocalizedDescriptionKey]];

		return nil;
	}
	NSDebugLLog(@"AdunServer", @"Retrieved interface. Checking availability", process);

	if([[state objectForKey: pid] boolValue] == NO)
	{
		NSDebugLLog(@"AdunServer", @"The specified process is not accepting requests");
		*error = [NSError errorWithDomain: @"AdServerCommandInterfaceErrorDomain"
				code: 0
				userInfo: [NSDictionary dictionaryWithObject:
					@"The specified process is not accepting requests"
					forKey:
					NSLocalizedDescriptionKey]];
		return nil;
	}
	
	NSDebugLLog(@"AdunServer", @"Exectuting command %@", commandDict);

	returnVal = [[[interface execute: commandDict
			error: error] retain] autorelease];

	return returnVal;
}

- (NSMutableDictionary*) optionsForCommand: (NSString*) name process: (id) process
{
	NSNumber* pid;
	id interface;
	
	pid = [NSNumber numberWithInt: [process processIdentifier]];
	interface = [interfaces objectForKey:  pid];
	if(interface == nil)
		return nil;

	return [interface optionsForCommand: name];
}

- (NSArray*) validCommandsForProcess: (id) process
{
	NSNumber* pid;
	id interface;
	
	pid = [NSNumber numberWithInt: [process processIdentifier]];
	interface = [interfaces objectForKey:  pid];
	if(interface == nil)
		return nil;

	return [interface validCommands];
}

@end

/**
Contains the methods used by an AdunCore instance to communicate with the server 
that launched it.
Data sent back by the simulation is passed to the remote process that requested its
creation using ULProcess methods.
*/
@implementation AdServer (AdunCoreInterface)

- (void) useInterface: (id) object forProcess: (int) pid
{
	[interfaces setObject: object forKey: [NSNumber numberWithInt: pid]];
}

- (bycopy NSDictionary*) externalObjectsForProcess: (int) pid
{
	id process;

	process = [processes objectForKey: [NSNumber numberWithInt: pid]];
	return [process inputData];
}

- (bycopy NSDictionary*) templateForProcess: (int) pid
{
	id process;

	process = [processes objectForKey: [NSNumber numberWithInt: pid]];
	return [process simulationTemplate];
}

- (void) acceptingRequests: (int) pid
{
	[state setObject: [NSNumber numberWithBool: YES] forKey: [NSNumber numberWithInt: pid]];
	
	NSDebugLLog(@"AdunServer", @"Process %d is accepting requests", pid);
}

- (void) controllerData: (id) results forProcess: (int) pid
{
	id  process;
	NSNumber* processIdentifier;
	NSMethodSignature* signature;
	NSInvocation* invocation;
	
	processIdentifier = [NSNumber numberWithInt: pid];
	if([disconnectedProcesses containsObject: processIdentifier])
	{
		signature = [ULProcess instanceMethodSignatureForSelector: @selector(setControllerResults:)];
		invocation = [NSInvocation invocationWithMethodSignature: signature];
		[invocation setSelector: @selector(setControllerResults:)];
		[invocation setArgument: &results atIndex: 2];
		[invocation retainArguments];
		if([storedMessages objectForKey: processIdentifier] == nil)
			[storedMessages setObject: [NSMutableArray array]
				forKey: processIdentifier];
				
		[[storedMessages objectForKey: processIdentifier] addObject: invocation];		
	}
	else
	{
		process = [processes objectForKey: processIdentifier];
		[process setControllerResults: results];
	}	
}

- (void) simulationData: (id) data forProcess: (int) pid
{
	id  process;
	NSNumber* processIdentifier;
	NSMethodSignature* signature;
	NSInvocation* invocation;
	
	processIdentifier = [NSNumber numberWithInt: pid];
	if([disconnectedProcesses containsObject: processIdentifier])
	{
		signature = [ULProcess instanceMethodSignatureForSelector: @selector(setSimulationData:)];
		invocation = [NSInvocation invocationWithMethodSignature: signature];
		[invocation setSelector: @selector(setSimulationData:)];
		[invocation setArgument: &data atIndex: 2];
		[invocation retainArguments];
		if([storedMessages objectForKey: processIdentifier] == nil)
			[storedMessages setObject: [NSMutableArray array]
				forKey: processIdentifier];
		
		[[storedMessages objectForKey: processIdentifier] addObject: invocation];		
	}
	else
	{	
		process = [processes objectForKey: processIdentifier];
		[process setSimulationData: data];
	}
}

- (void) closeConnectionForProcess: (int) pid error: (NSError*) error
{
	[interfaces removeObjectForKey: [NSNumber numberWithInt: pid]];
	
	if(error != nil)
		[processErrors setObject: error forKey: [NSNumber numberWithInt: pid]];
}

@end

/**
Initial testing implementation of the RemoteDataManagement category lacking advanced security.
*/
@implementation AdServer (RemoteDataManagement)

- (ULFileSystemDatabaseBackend*) backendForDefaultFileSystemDatabase
{
	NSDebugLLog(@"AdunServer", @"Returning database interface %@", defaultBackend);
	return [[defaultBackend retain] autorelease];
}

- (ULFileSystemDatabaseBackend*) backendForFileSystemDatabase: (NSString*) path
{
	//Incomplete implementation
	return [self backendForDefaultFileSystemDatabase];
}

@end



