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
#include "ULStatusTable.h"

@implementation ULStatusTable

//Gnustep deselectAll: doesnt lead to
//the rows become unhighlighted however using deselectRow:
//and setNeedsDisplay: does the trick. Also deselectRow:
//doest trigger NSTableViewSelectionDidChangeNotification
//and hence a lot of delegate methods being called which
//makes things simpler
- (void) deselectAllRows: (id) sender
{
	int row;
	id selectedRows;
	
	selectedRows = [statusTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		[statusTable deselectRow: row];
		row = [selectedRows indexGreaterThanIndex: row];
	}
	
	[statusTable setNeedsDisplay: YES];
} 

- (id) init
{
	if(self = [super init])
	{
		isActive = NO;
		selectedProcesses = [[NSMutableArray alloc] init];
	}

	return self;
}

- (void)awakeFromNib
{
	id columns;
	NSString* welcomeString;

	columns = [statusTable tableColumns];
	[[[columns objectAtIndex: 0] headerCell] setStringValue: @"Name"];
	[[columns objectAtIndex: 0] setIdentifier: @"name"];
	[[[columns objectAtIndex: 0] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 1] headerCell] setStringValue: @"Host"];
	[[columns objectAtIndex: 1] setIdentifier: @"processHost"];
	[[[columns objectAtIndex: 1] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 2] headerCell] setStringValue: @"Status"];
	[[columns objectAtIndex: 2] setIdentifier: @"processStatus"];
	[[[columns objectAtIndex: 2] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 3] headerCell] setStringValue: @"Created"];
	[[columns objectAtIndex: 3] setIdentifier: @"created"];
	[[[columns objectAtIndex: 3] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 4] headerCell] setStringValue: @"Started"];
	[[columns objectAtIndex: 4] setIdentifier: @"started"];
	[[[columns objectAtIndex: 4] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 5] headerCell] setStringValue: @"Length"];
	[[columns objectAtIndex: 5] setIdentifier: @"length"];
	[[[columns objectAtIndex: 5] dataCell] setAlignment: NSCenterTextAlignment];

	[statusTable setDataSource: self];
	[statusTable setDelegate: self];
	[statusTable sizeToFit];
	[statusTable setUsesAlternatingRowBackgroundColors: YES];

}

- (void) dealloc
{
	[selectedProcesses release];
	[super dealloc];
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	if([menuItem action] == @selector(deselectAllRows:))
	{
		if([[statusTable selectedRowIndexes] count] > 0)
			return YES;	
		else
			return NO;
	}		

	if([[statusTable selectedRowIndexes] count] > 1)
		return NO;

	if([statusTable selectedRow] == -1)
		return NO;

	if(![self respondsToSelector: [menuItem action]])
		return NO;

	return YES;

}

- (BOOL) _tryExportProcess: (id) process toFile: (NSString*) filename overwrite: (BOOL) flag
{
	NSError* error;
	int result;

	if(![processManager exportProcess: process toFile: filename overwrite: flag error: &error])
	{
		if([error code] != 10)
		{
			NSRunAlertPanel(@"Error",
				[[error userInfo] objectForKey:NSLocalizedDescriptionKey],
				@"Dismiss", 
				nil,
				nil);

			return NO;
		}
		else
		{
			result = NSRunAlertPanel(@"Error",
					[[error userInfo] objectForKey:NSLocalizedDescriptionKey],
					@"Cancel", 
					@"Overwrite",
					nil);

			if(result == NSAlertAlternateReturn)
				return YES;
			else
				return NO;
		}	
	}

	return NO;
}

- (void) export: (id) sender
{
	int row;
	id process;
	id savePanel, filename;
	int result;

	NS_DURING
	{
		row = [statusTable selectedRow];
		if(row == -1)
			[NSException raise: NSInvalidArgumentException
				format: @"No process selected"];

		savePanel = [NSSavePanel savePanel];	
		[savePanel setTitle: @"Export Process"];
		[savePanel setDirectory: 
			[NSHomeDirectory() stringByAppendingPathComponent: @"adun"]];
		result = [savePanel runModal];
		filename = [savePanel filename];

		if(result == NSOKButton)
		{
			process = [[processManager allProcesses] objectAtIndex: row];
			if([self _tryExportProcess: process toFile: filename overwrite: NO])
				[self _tryExportProcess: process toFile: filename overwrite: YES];
		}
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
	}
	NS_ENDHANDLER
}

- (void) remove: (id) sender
{
	int row;
	id process;
	
	NS_DURING
	{
		row = [statusTable selectedRow];
		if(row == -1)
			[NSException raise: NSInvalidArgumentException
				format: @"No process selected"];
		process = [[processManager allProcesses] objectAtIndex: row];
		[processManager removeProcess: process];
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
	}	
	NS_ENDHANDLER
}

/**
Notification methods
**/

- (void) handleServerDisconnection: (NSNotification*) aNotification
{
	[statusTable reloadData];
}

- (void) userLandCreatedNewProcess: (NSNotification*) aNotification
{
	[statusTable reloadData];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: NSTableViewSelectionDidChangeNotification 
		object: statusTable];
}

- (void) userLandLaunchedNewProcess: (NSNotification*) aNotification
{
	[statusTable reloadData];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: NSTableViewSelectionDidChangeNotification 
		object: statusTable];
}

- (void) userLandFinishedProcess: (NSNotification*) aNotification
{
	[statusTable reloadData];
}

- (void) userLandProcessUpdate: (NSNotification*) aNotification
{
	[statusTable reloadData];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: NSTableViewSelectionDidChangeNotification 
		object: statusTable];
}

- (void) setProcessManager: (id) object
{
	processManager = object;

	//register for notifications 
	//FIXME: temporary hack we know this method is only called once

	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(userLandCreatedNewProcess:)
		name: @"ULDidCreateNewProcessNotification"
		object: processManager];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(userLandFinishedProcess:)
		name: @"ULProcessDidFinishNotification"
		object: processManager];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(userLandLaunchedNewProcess:)
		name: @"ULDidLaunchProcessNotification"
		object: processManager];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(userLandProcessUpdate:)
		name: @"ULProcessStatusDidChangeNotification"
		object: processManager];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(handleServerDisconnection:)
		name: @"ULDisconnectedFromServerNotification"
		object: nil];
	
	[statusTable reloadData];
}

- (BOOL) isActive;
{
	return isActive;
}

- (void) setActive: (BOOL) value
{
	if(!value)
		[self deselectAllRows: self];
	isActive = value;
}

/**
Data provision
**/

- (NSArray*) availableTypes
{
	return [NSArray arrayWithObject: @"ULProcess"];	
}

- (id) objectForType: (NSString*) type;
{
	if([selectedProcesses count] == 0)
		return nil;

	return [[[selectedProcesses objectAtIndex: 0] retain] autorelease];
}

- (NSArray*) objectsForType: (NSString*) type
{
	return [[selectedProcesses copy] autorelease]; 
}

- (int) countOfObjectsForType: (NSString*) type
{
	if([type isEqual: @"ULProcess"])
		return [selectedProcesses count];
	else
		return 0;
}

- (void) pasteboardChangedOwner: (id) pasteboard
{
	[self deselectAllRows: self];
	isActive = NO;
}

/***
Table dataSource methods
*/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[processManager allProcesses] count];
}

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	id key, process;

	process = [[processManager allProcesses] objectAtIndex: rowIndex];

	if([[aTableColumn identifier] isEqual: @"options"])
		return [[process valueForKey: @"options"] 
				 valueForKey: @"name"];
	else
		return [process valueForKey: [aTableColumn identifier]];
}

/**
Table delegate methods
*/

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification
{
	int row;
	id selectedRows;
	
	[selectedProcesses removeAllObjects];
	selectedRows = [statusTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		[selectedProcesses addObject: 
			[[processManager allProcesses] objectAtIndex: row]];
		row = [selectedRows indexGreaterThanIndex: row];
	}
}

- (BOOL) tableView: (NSTableView*) table shouldSelectRow: (int) row
{
	if(!isActive)
	{
		[[ULPasteboard appPasteboard] setPasteboardOwner: self];
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULStatusTableDidBecomeActiveNotification"
			object: self];
	}		

	return YES;
}	

@end
