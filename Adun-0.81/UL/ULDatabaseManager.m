/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "ULDatabaseManager.h"

@implementation ULDatabaseManager

- (id) init
{
	if((self = [super init]))
	{
		if([NSBundle loadNibNamed: @"DatabasePanel" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}

		databaseInterface = [ULDatabaseInterface databaseInterface];
	}

	return self;
}

- (void) closeDatabasePanel: (id)sender
{
	[databasePanel close];
}

- (void) addDatabase: (id)sender
{
	BOOL value, createDB;
	NSError* error = nil;
	NSString* name, *location;
	NSDictionary* userInfo;
	ULFileSystemDatabaseBackend* backend;

	name = [addClientField stringValue];
	location = [databaseLocation stringValue];

	//Check the specified client name isnt already in use
	if([[databaseInterface availableClients] containsObject: name])
	{
		NSRunAlertPanel(
			[NSString stringWithFormat: @"Name %@ already in use.", name],
			@"Choose another name and try again.",
			@"Dismiss",
			nil, nil);
		return;
	}

	if([name isEqual: @""])
	{
		NSRunAlertPanel(
			[NSString stringWithFormat: @"Client name cannot be empty", name],
			@"Choose another name and try again.",
			@"Dismiss",
			nil, nil);
		return;
	}
	
	if([location isEqual: @""])
	{
		NSRunAlertPanel(
			[NSString stringWithFormat: @"Location cannot be empty", name],
			@"Choose an existing database or a location for a new one.",
			@"Dismiss",
			nil, nil);
		return;
	}


	//FIXME: Only handle File based backends at the moment
	createDB = YES;
	value = [[NSFileManager defaultManager]
		 directoryExistsAtPath: location
		 error: &error];
	if(!value)
	{
		NSLog(@"No directory called %@", location);
		if(error != nil)
		{
			userInfo = [error userInfo];
			NSRunAlertPanel(
				[userInfo objectForKey: NSLocalizedDescriptionKey],
				[userInfo objectForKey: @"AdDetailedDescriptionKey"],
				@"Dismiss",
				nil, nil);
			createDB = NO;
		}	
		else
		{
			value = NSRunAlertPanel(
				[NSString stringWithFormat: 
					@"No database at location %@", location],
				@"Do you wish to create one?",
				@"Yes",
				@"No", nil);
		
			if(value == NSOKButton)
			{
				value = [[NSFileManager defaultManager]
					createDirectoryAtPath: location
					attributes: nil
					error: &error];
				if(!value)
				{
					userInfo = [error userInfo];
					NSRunAlertPanel(
						[userInfo objectForKey: NSLocalizedDescriptionKey],
						[userInfo objectForKey: @"AdDetailedDescriptionKey"],
						@"Dismiss",
						nil, nil);
					createDB = NO;	
				}
				else
					createDB = YES;

			}
			else
			 	createDB = NO;
		}
	}

	[self closeDatabasePanel: self];

	if(createDB)
	{
		//NOTE: The format of the location field can be
		//host:database. This defintion can handle both remote
		//SQL type databases and file system dbs.
		//e.g. thymus.imim.es:Adun
		//thymus.imim.es:/home/michael/adun/Database.

		backend = [[ULFileSystemDatabaseBackend alloc]
				initWithDatabaseName: location
				clientName: name
				error: &error];
		if(error != nil)
		{
			userInfo = [error userInfo];
			NSRunAlertPanel(
				[userInfo objectForKey: NSLocalizedDescriptionKey],
				[userInfo objectForKey: @"AdDetailedDescriptionKey"],
				@"Dismiss",
				nil, nil);

		}
		else
			[[ULDatabaseInterface databaseInterface]	
				addBackend: backend];
	}		
}

- (void) removeDatabase: (id)sender
{
	NSString* name;

	name = [removeClientField stringValue];
	if(![[databaseInterface availableClients] containsObject: name])
	{
		NSRunAlertPanel(
			@"Error",
			[NSString stringWithFormat: @"No client called %@ exists", name],
			@"Dismiss",
			nil, nil);
		return;	
	}

	[self closeDatabasePanel: self];

	NS_DURING
	{
		[databaseInterface removeBackendForClient: name];
	}
	NS_HANDLER
	{
		//Exception is raised on attempting to remove the primary
		//file system backend
		if([[localException name] isEqual: @"NSInvalidArgumentException"])
		{
			NSRunAlertPanel(
				@"Error",
				@"You cannot remove the primary file system backend",
				@"Dismiss",
				nil, nil);
		}
		else
			[localException raise];
	}
	NS_ENDHANDLER
}

- (void) showAddDatabasePanel: (id)sender
{
	[tabView selectTabViewItemAtIndex: 0];
	[actionButton setTitle: @"Add"];
	[actionButton setAction: @selector(addDatabase:)];
	[actionButton setTarget: self];
	[databasePanel setTitle: @"Add Database"];
 	[databasePanel center];
	[databasePanel setFloatingPanel: YES];
	[databasePanel makeKeyAndOrderFront: self];
}

- (void) showRemoveDatabasePanel: (id)sender
{
	[tabView selectTabViewItemAtIndex: 1];
	[actionButton setTitle: @"Remove"];
	[actionButton setAction: @selector(removeDatabase:)];
	[actionButton setTarget: self];
	[databasePanel setTitle: @"Remove Database"];
 	[databasePanel center];
	[databasePanel setFloatingPanel: YES];
	[databasePanel makeKeyAndOrderFront: self];
}

@end
