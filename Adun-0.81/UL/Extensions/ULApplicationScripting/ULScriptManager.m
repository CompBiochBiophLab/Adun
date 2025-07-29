/* 
   Project: UL

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

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
#include "ULScriptManager.h"

@implementation ULScriptManager

- (id) init
{
	NSMenu *toolMenu;
	id item;

	if((self = [super init]))
	{
		manager = [STScriptsManager defaultManager];
		[manager setScriptSearchPathsToDefaults];
		[manager retain];

		if([NSBundle loadNibNamed: @"ScriptManager" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}

		toolMenu = [[[NSApp mainMenu]
				itemWithTitle: @"Tools"] submenu];
		[toolMenu addItem: [NSMenuItem separatorItem]];		
		item = [toolMenu addItemWithTitle: @"Script Manager"
			action: @selector(open:) 
			keyEquivalent: @""];
		[item setTarget: self];

		item = [toolMenu addItemWithTitle: @"Transcript"
			action: @selector(showTranscript:) 
			keyEquivalent: @""];
		[item setTarget: self];

		environment = [STEnvironment environmentWithDefaultDescription];
		[environment retain];
		[environment setObject: [ULDatabaseInterface databaseInterface]
			forName: @"DatabaseInterface"];
		[environment setObject: [ULProcessManager appProcessManager]
			forName: @"ProcessManager"];
		[environment setObject: transcript
			forName: @"Transcript"];
		[environment setObject: [ULAnalysisManager managerWithDefaultLocation]
			forName: @"AnalysisManager"];

		connections = [NSMutableDictionary new];
		runningThreads = [NSMutableArray new];
		selectedThreads = [NSMutableArray new];
		
		autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval: 10
					target: self
					selector: @selector(updateThreadTable:)
					userInfo: nil
					repeats: YES];	
	}

	return self;
}

- (void) dealloc
{
	[autoUpdateTimer release];
	[runningThreads release];
	[selectedThreads release];
	[connections release];
	[manager release];
	[environment release];
	[super dealloc];
}

- (void) awakeFromNib
{
	NSMenu* menu;
	id columns, item;

	columns = [threadTable tableColumns];
	[[[columns objectAtIndex: 0] headerCell] setStringValue: @"Script Name"];
	[[columns objectAtIndex: 0] setIdentifier: @"name"];
	[[[columns objectAtIndex: 0] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 1] headerCell] setStringValue: @"Arguments"];
	[[columns objectAtIndex: 1] setIdentifier: @"arguments"];
	[[[columns objectAtIndex: 1] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 2] headerCell] setStringValue: @"Length"];
	[[columns objectAtIndex: 2] setIdentifier: @"length"];

	[threadTable setDataSource: self];
	[threadTable setDelegate: self];
	[threadTable sizeToFit];
	[threadTable setUsesAlternatingRowBackgroundColors: YES];
	[threadTable setAllowsMultipleSelection: NO];

	//Create a context menu for the thread table which
	//allows users to kill the selected script
	menu = [[NSMenu alloc] initWithTitle: @"Threads"];
	[menu autorelease];
	item = [menu addItemWithTitle: @"Kill Selected"
			action: @selector(stopThreadedScript:) 
			keyEquivalent: @""];
	[item setTarget: self];
	[threadTable setMenu: menu];
}

- (void) updateThreadTable: (id) info
{
	NSTimeInterval interval;
	NSEnumerator* threadEnum;
	NSString* length;
	id item;

	if([runningThreads count] == 0)
		return;
	
	//Iterate over the threads and update the
	//length they have been running
	threadEnum = [runningThreads objectEnumerator];
	while((item = [threadEnum nextObject]))
	{
		interval = -1*[[item objectForKey: @"Start"]
				timeIntervalSinceNow];
		length = ULConvertTimeIntervalToString(interval);
		[item setObject: length
			forKey: @"Length"];
	}		
	
	[threadTable reloadData];
}

- (void) logScriptError: (NSError*) error
{
	NSDictionary* info;

	if(error != nil)
	{
		info = [error userInfo];
		NSRunAlertPanel(
			[info objectForKey: NSLocalizedDescriptionKey],
			[NSString stringWithFormat: @"%@\n%@",
				[info objectForKey: @"AdDetailedDescriptionKey"],
				[info objectForKey: @"NSRecoverySuggestionKey"]],
			@"Dismiss",
			nil,
			nil);
	}		
}

- (void) launch: (id) sender
{
	NSString* scriptName;
	NSArray* args;
	NSError *error = nil;

	scriptName =  [scriptList titleOfSelectedItem];
	if(![scriptName isEqual: @"None"])
	{
		//get the script args
		args = [[argField stringValue]
			componentsSeparatedByString: @" "];

		if([threadButton state] == NSOnState)
		{
			[self runThreadedScriptWithName: scriptName
				arguments: args];
		}	
		else
		{
			[self runScriptWithName: scriptName 
				arguments: args 
				error: &error];
			[self logScriptError: error];
		}	
	}	
}

- (void) runScriptWithName: (NSString*) aString arguments: (NSArray*) args error: (NSError**) error
{
	NSString* localizedDescription;
	STConversation *conversation;
	STFileScript *scriptFile;
	id result;

	scriptFile = [manager scriptWithName: aString];
	conversation = [STConversation conversationWithEnvironment: environment 
			language: [scriptFile language]];
	NS_DURING
	{
		[transcript showSystemInformation: 
			[NSString stringWithFormat: @"Running %@\n\n", aString]];
		[environment setObject: args
			forName: @"Args"];
		[conversation interpretScript: 
			[NSString stringWithContentsOfFile: [scriptFile fileName]]];
		result = [conversation result];
	}   
	NS_HANDLER
	{
		NSWarnLog(@"Caught Exception  %@ %@", localException, [localException userInfo]);
		localizedDescription = [localException reason];
		*error = AdCreateError(@"UL.ErrorDomain",
				1,
				[NSString stringWithFormat: 
					@"Script Error - %@", localizedDescription],
				@"Possible script syntax error",
				@"Contact the script developers about the problem");
	}
	NS_ENDHANDLER
}

- (void) _updateScripts
{
	NSString* name;
	NSEnumerator* scriptEnum;
	id script;

	[scriptList removeAllItems];
	scriptEnum = [[manager allScripts] objectEnumerator];

	while((script = [scriptEnum nextObject]))
	{
		name = [[script scriptName] lastPathComponent];
		name = [name stringByDeletingPathExtension];
		[scriptList addItemWithTitle: name];
	}	
	if([scriptList numberOfItems] == 0)	
		[scriptList addItemWithTitle: @"None"];
	
	[scriptList selectItemAtIndex: 0];
}

- (void) open: (id) sender
{
	[self _updateScripts];
	[window center];
	[window makeKeyAndOrderFront: self];
}

- (void) showTranscript: (id) sender
{
	[[transcript window] center];
	[[transcript window] 
		makeKeyAndOrderFront: self];
}	

- (void) close: (id) sender
{
	[window close];
}

/***
Table dataSource methods
*/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [runningThreads count];
}

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	id threadInfo;

	threadInfo = [runningThreads objectAtIndex: rowIndex];
	return [threadInfo objectForKey: [aTableColumn identifier]];
}

/**
Table delegate methods
*/

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification
{
	int row;
	id selectedRows;
	
	[selectedThreads removeAllObjects];
	selectedRows = [threadTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		[selectedThreads addObject: 
			[runningThreads objectAtIndex: row]];
		row = [selectedRows indexGreaterThanIndex: row];
	}
}

@end

/**
Adapted from AdControllerThreadingExtensions
*/
@implementation ULScriptManager (ULScriptManagerThreadingExtensions)

//Private method that runs in the simulation thread
- (void) _threadedRunScript: (NSDictionary*) aDict 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSConnection* connection;
	NSArray* ports, *args;
	NSMutableDictionary* terminationDict;
	NSString * scriptName, *threadId;
	NSError *error = nil;
	
	NSDebugLLog(@"ULScriptManager", 
		@"Script thread starting");

	ports = [aDict objectForKey: @"Ports"];
	args = [aDict objectForKey: @"Arguments"];
	scriptName = [aDict objectForKey: @"ScriptName"];
	threadId = [aDict objectForKey: @"ThreadId"];

	//Use the ports to connect to the main thread
	connection = [[NSConnection alloc]
			initWithReceivePort:[ports objectAtIndex:0]
			sendPort:[ports objectAtIndex:1]];
	[ports retain];
	
	[self runScriptWithName: scriptName 
		arguments: args 
		error: &error];

	//we're finished so notify the main thread and exit
	NSDebugLLog(@"ULScriptManager", 
		@"Script finished - notifying main thread");
	terminationDict = [NSMutableDictionary dictionary];
	[terminationDict setObject: threadId forKey: @"ThreadId"];
	if(error != nil)
		[terminationDict setObject: error forKey: @"TerminationError"];

	[self performSelectorOnMainThread: @selector(scriptFinished:)
		withObject: terminationDict
		waitUntilDone: NO];

	[ports release];
	[connection release];
	NSDebugLLog(@"ULScriptManager", 
		@"Script thread exiting");
	[pool release];
	[NSThread exit];
}

- (void) runThreadedScriptWithName: (NSString*) aString arguments: (NSArray*) args
{
	NSPort* receive_port, *send_port;
	NSArray *ports;
	NSDictionary* dict;
	NSConnection* threadConnection;
	NSMutableDictionary* threadInfo;
	NSString* threadId;

	//Set up the ports that will be used by the NSConnection 
	//for interthread communication
	receive_port = [[NSMessagePort new] autorelease];
	send_port = [[NSMessagePort new] autorelease];
	ports = [NSArray arrayWithObjects: send_port, receive_port, NULL];

	//Create the NSConnection
	threadConnection = [[NSConnection alloc] 
				initWithReceivePort:receive_port 
				sendPort:send_port];

	//we set ourselves as root object
	//The thread running the script can then get a reference to it using rootProxy
	[threadConnection setRootObject:self];

	threadId = [[NSProcessInfo processInfo] globallyUniqueString];
	[connections setObject: threadConnection
		forKey: threadId];

	//Information to pass to the thread
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
		ports, @"Ports",
		aString, @"ScriptName",
		threadId , @"ThreadId", 
		args, @"Arguments", nil];

	//Information to add to the thread table
	threadInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			aString, @"Name",
			args, @"Arguments",
			@"0.0", @"Length", 
			[NSDate date], @"Start", 
			threadId, @"ThreadId", nil];
	[runningThreads addObject: threadInfo];
	[threadTable reloadData];

	[NSThread detachNewThreadSelector: @selector(_threadedRunScript:) 
		toTarget: self
		withObject: dict];
}

//Method called when the script thread exits
//N.B. This should only be called from _threadedRunScript 
//in the script thread
- (void) scriptFinished: (NSDictionary*) terminationDict
{
	int index;
	NSConnection* threadConnection;
	NSString* threadId;
	NSEnumerator* threadEnum;
	NSError * terminationError;
	id item, ident;

	NSDebugLLog(@"ULScriptManager",
		@"Received script finished message");

	threadId = [terminationDict objectForKey: @"ThreadId"];
	threadConnection  = [connections objectForKey: threadId];
	terminationError = [terminationDict objectForKey: @"TerminationError"];
	if(terminationError != nil)
		[self logScriptError: terminationError];

	//Find the entry in runningThreads for this thread.
	index = 0;
	threadEnum = [runningThreads objectEnumerator];
	while((item = [threadEnum nextObject]))
	{
		ident = [item objectForKey: @"ThreadId"];
		if([ident isEqual: threadId])
		 	break;
		index++;	
	}		

	[runningThreads removeObjectAtIndex: index];
	[threadTable reloadData];

	NSDebugLLog(@"ULScriptManager", 
		@"Cleaning up thread");
	[threadConnection invalidate];
	[connections removeObjectForKey: threadId];
}

- (oneway void) stopScript 
{
	NSDebugLLog(@"ULScriptManager", @"Recevied stopScript message");
	[NSThread exit];
}

- (void) stopThreadedScript: (id) sender
{
	NSDictionary* threadInfo;
	NSString* threadId;
	NSConnection* threadConnection;

	//Just in case
	if([selectedThreads count] == 0)
		return;

	threadInfo = [selectedThreads objectAtIndex: 0];
	threadId = [threadInfo objectForKey: @"ThreadId"];
	threadConnection = [connections objectForKey: threadId];

	//May have ended already
	if(threadConnection == nil)
		return;
		
	NSDebugLLog(@"ULScriptManager", 
		@"Sending stopScript to %@", threadInfo);	
	[(ULScriptManager*)[threadConnection rootProxy] stopScript];
	NSDebugLLog(@"ULScriptManager", @"Done");	
}

@end
