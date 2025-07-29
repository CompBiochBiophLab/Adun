/* 
   Project: UL

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

#include <AppKit/AppKit.h>
#include "ULDatabaseBrowser.h"

@implementation ULDatabaseBrowserPath

- (id) init
{
	if(self = [super init])
	{
		path = [NSMutableArray new];
	}	
		
	return self;
}

- (void) dealloc
{
	[path release];
	[super dealloc];
}

- (void) setItem: (id)  object forLevel: (int) level
{
	//NSLog(@"Setting item %@ at level %d", object, level);

	//truncate to given level
	if([self truncateToLevel: level])
	{
		//remove the object currently at the given level
		[path removeLastObject];
	}	
	//add the new object in its place
	[self addItem: object];
}

- (BOOL) truncateToLevel: (int) value
{
	int i;

	if(value > [path count])
	{
		[NSException raise: NSInvalidArgumentException
			format: @"Attempt to set item at level %d - current level %d", 
			value, 
			[self currentLevel]];
	}		
	else if(value < [path count])
	{
		//remove all objects at index higher then level
		
		for(i=[self currentLevel]; i>value; i--)
			[path removeObjectAtIndex: i];
		
		return YES;

	}

	return NO;
}

- (void) addItem: (id) object
{
	[path addObject: object];
}

- (id) itemForLevel: (int) level
{
	return [path objectAtIndex: level];
}

- (NSArray*) currentPath
{
	return [[path copy] autorelease];
}

- (int) currentLevel
{
	return [path count] - 1;
}

- (void) clearPath
{
	[path removeAllObjects];
}

@end

@implementation ULDatabaseBrowser

- (void) deselectAllRows: (id) sender
{
	int row;
	id selectedRows;
	
	selectedRows = [browserView selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		[browserView deselectRow: row];
		row = [selectedRows indexGreaterThanIndex: row];
	}
	
	[browserView setNeedsDisplay: YES];
} 

- (id) init
{
	if(self = [super init])
	{
		isActive = NO;
		selectedSystems = [NSMutableArray new];
		selectedOptions = [NSMutableArray new];
		selectedDataSets = [NSMutableArray new];
		selectedSimulations = [NSMutableArray new];
		path = [ULDatabaseBrowserPath new];
		allowedActions = [[NSArray alloc] initWithObjects:
					@"copy:",
					@"cut:", 
					@"paste:",
					@"remove:",
					@"import:",
					@"export:",
					@"delete:",
					nil];
		cut = NO;
		editedObject = nil;
		progressPanel = nil;
		currentObjects = nil;
		oldObjects = nil;
	}

	return self;
}

- (void) awakeFromNib
{
	NSError* error;
	NSEnumerator* errorEnum, *clientEnum, *schemaEnum;
	NSEnumerator* columnEnum;
	NSDictionary* userInfo;
	NSTableColumn* column;
	id lastColumn, schema, client, delete;

	databaseInterface = [[ULDatabaseInterface databaseInterface] retain];
	[browserView setDataSource: self];
	[browserView setDelegate: self];
	[browserView setAutoresizesOutlineColumn: NO];
	[viewList selectItemWithTitle: @"Database View"];

	//On receipt of any of these notifcations we reload the browser view
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(updateView:)
		name: @"ULDatabaseInterfaceDidModifyContentsNotification"
		object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(updateView:)
		name: @"ULDatabaseInterfaceDidAddBackendNotification"
		object: databaseInterface];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(updateView:)
		name: @"ULDatabaseInterfaceDidRemoveBackendNotification"
		object: databaseInterface];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(updateView:)
		name: @"ULDatabaseInterfaceConnectionDidDieNotification"
		object: databaseInterface];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(updateView:)
		name: @"ULDatabaseInterfaceDidReconnectNotification"
		object: databaseInterface];

	lastColumn = [browserView tableColumnWithIdentifier: @"Created"]; 
	[lastColumn setMinWidth: [[lastColumn headerCell] cellSize].width + 1.5];
	//This stops the cell being dark on Gnustep default theme
	[(NSTextFieldCell*)[lastColumn headerCell] setDrawsBackground: NO];

	//Font size is too big on Apple - make it smaller
	//Set the font size of the browser display
#ifndef GNUSTEP
	float size;
	id cell;
	
	columnEnum = [[browserView tableColumns] objectEnumerator];
	while(column = [columnEnum nextObject])
	{
		cell = [column dataCell];
		size = [NSFont systemFontSizeForControlSize: NSSmallControlSize];
		[cell setFont: [NSFont fontWithName: [[cell font] fontName] size: size]];
		[[column dataCell] setControlSize: NSSmallControlSize];	
	}
	
	[browserView setRowHeight:
		[[NSFont fontWithName: [[cell font] fontName] size: size]
			defaultLineHeightForFont] + 1];
#endif	
	[self willReloadData];
	[browserView reloadData];
	[self didReloadData];

	//Expand until the schemas
	[browserView expandUntilLevel: 2];		
	
	//Connect delete
 	delete = [[[[NSApp mainMenu] itemWithTitle: @"Edit"]
			submenu] itemWithTitle: @"Delete"];
	[delete setTarget: self];
	[delete setAction: @selector(delete:)];

	//Notify the user of database errors
	errorEnum = [[databaseInterface backendErrors] objectEnumerator];
	while(error = [errorEnum nextObject])
		ULRunErrorPanel(error);
}

- (void) dealloc
{
	[currentObjects release];
	[oldObjects release];
	[allowedActions release];
	[path release];
	[databaseInterface release];
	[selectedDataSets release];
	[selectedSystems release];
	[selectedOptions release];
	[selectedSimulations release];
	[super dealloc];
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

- (void) updateView: (NSNotification*) aNotification
{
	//If there is a panel running we end it if
	//endPanel has been set to YES. Otherwise we
	//let it be.
	if(progressPanel != nil && endPanel == YES)
	{	
		[progressPanel setProgressInfo: @"Complete"];
		sleep(1.5);
		[progressPanel endPanel];
		[progressPanel release];
		progressPanel = nil;
	}	
	[self willReloadData];
	[browserView reloadData];
	[self didReloadData];
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	int selectedRow, itemLevel;
	
	//deselectAllRows is active when there are more than 0 rows selected
	if([menuItem action] == @selector(deselectAllRows:))
	{
		if([[browserView selectedRowIndexes] count] > 0)
			return YES;	
		else
			return NO;
	}		

	//selectedRow is not updated when the browser
	//collapses its view (until another selection is made). 
	//This means that if the index of the last row in the collapsed view 
	//is less than the index of the last selected row
	//calling [browserView itemAtRow: [browserView selectedRow]]
	//will crash the program (or raise an exception).
	//\note File this as a bug

	selectedRow = [browserView selectedRow];
	if(selectedRow >= [browserView numberOfRows])
		return NO;
	
	if(selectedRow == -1)
		return NO;

	if([[browserView selectedRowIndexes] count] > 1)
		return NO;

	itemLevel = [browserView levelForRow: selectedRow];
	if([menuItem action] == @selector(paste:))
	{
		if(editedObject != nil && itemLevel == 1)
			return YES;
		else
			return NO;
	}		
	
	//import is active when a database schema is selected
	if([NSStringFromSelector([menuItem action]) isEqual: @"import:"])
	{
		if(itemLevel == 1)
			return YES;
		else
			return NO;
	}		

	//It the command is exportAs: we have to ask the export controller 
	//if the export is possible
	if([NSStringFromSelector([menuItem action]) isEqual: @"exportAs:"])
		return [[ULExportController sharedExportController] 
				canExportCurrentPasteboardObjectAs: [menuItem tag]];

	if([allowedActions containsObject: NSStringFromSelector([menuItem action])])
	{
		if(itemLevel == 3)
			return YES;
		else	
			return NO;
	}		

	return NO;
}

/*
 * There are three things to consider when removing an object
 * 1) Is it the last copy
 * 2) Does it have input references
 * 3) Does it have output references
 */
- (void) _remove: (BOOL) refFlag
{
	BOOL singleCopy = NO;
	BOOL outputRefsAreAccessible = NO;
	int row, lastRow, retval;
	NSIndexSet* selectedRows;
	NSEnumerator* errorEnum, *copyEnum, *refEnum;
	NSString* database;
	NSError *error = nil;
	NSArray* copies, *references, *result;
	NSMutableArray* locations = [NSMutableArray new];
	NSMutableArray* errors = [NSMutableArray new];
	id item, copy, ref;

	//FIXME: Currently remove: is activated if only one object
	//is selected
	selectedRows = [browserView selectedRowIndexes];
	row = [selectedRows firstIndex];
	
	while(row != NSNotFound)
	{
		lastRow = row;
		item = [browserView itemAtRow: row];
		[locations removeAllObjects];	

		//Check how many copies of the selected object are accesible
		copies = [databaseInterface 
				findObjectsWithID: [item objectForKey: AdObjectIdentification]
				ofClass: [item objectForKey: AdObjectClass]];
		copyEnum = [copies objectEnumerator];		
		
		//Get the database for the clients to ensure non-redundancy
		while(copy = [copyEnum nextObject])
		{
			database = [copy objectForKey: @"Database"];
			if(![locations containsObject: database])
				[locations addObject: database];	
		}

		if([locations count] == 1)
			singleCopy = YES;

		//If this is the only copy we can find and it has output references 
		//there are two possible situations
		//1) The output references are accessible through the database interface
		//	- notify the user they must delete all output references
		//2) The object was imported from another database and none of the current
		//clients has access to the databases containing the output references.
		//	- notify the user of the situation and ask if they wish to delete anyway.
		//In the case that the output refs are a mixture of one and two the user must
		//first delete all the case 1 refs.
		if(singleCopy)
		{
			references = [databaseInterface outputReferencesForObjectWithID: 
						[item objectForKey: AdObjectIdentification]
					ofClass: [item objectForKey:@"Class"]
					inSchema: [item objectForKey: @"Schema"]
					ofClient:  [item objectForKey: ULDatabaseClientName]
					error: &error];
					
			if(error != nil)
			{
				row = [selectedRows indexGreaterThanIndex: row];
				[errors addObject: error];
				error = nil;
				row = [selectedRows indexGreaterThanIndex: row];
				continue;
			}	
			else if([references count] != 0)
			{
				//Check if we have access to the reference objects - only if 
				//we cant access any do we give the option to ignore them
				outputRefsAreAccessible = NO;
				refEnum = [references objectEnumerator];
				while(ref = [refEnum nextObject])
				{
					result = [databaseInterface findObjectsWithID: [ref objectForKey: @"Identification"]
							ofClass: [ref objectForKey: @"Class"]];
					//Did we find instances of the reference object?		
					if([result count] != 0)
						outputRefsAreAccessible = YES;
				}
				
				if(outputRefsAreAccessible)
				{
					NSRunAlertPanel(@"This object contains output references",
							@"You must delete all output objects to continue",
							@"Dismiss",
							nil,
							nil);
					row = [selectedRows indexGreaterThanIndex: row];
					continue;
				}
				else
				{
					retval = NSRunAlertPanel(@"Cannot access this objects output references",
							@"They are not in any connected database.\nDo you wish to ignore these references\
 and continue removal?",
							@"Yes",
							@"No",
							nil);
							
					if(retval != NSAlertDefaultReturn)
					{
						row = [selectedRows indexGreaterThanIndex: row];
						continue;
					}
				}
			}
		}

		//If this is the only copy we can find and refFlag is No ask
		//the user if they want to remove all output references to it
		//It may be the case the other copies exist on clients we do not have
		//access to so the user may not want the references to it to be deleted.
		if(singleCopy == YES && refFlag == NO)
		{
			retval = NSRunAlertPanel(@"This is the last known copy of this object",
					@"Do you wish to also remove all references to it?",
					@"Yes",
					@"No",
					@"Cancel");

			if(retval == NSAlertDefaultReturn)
			{
				refFlag = YES;
			}	
			else if(retval == NSAlertOtherReturn)
			{
				row = [selectedRows indexGreaterThanIndex: row];
				continue;
			}	
		}			

		//For eliminiation - removing all output refs to the object
		if(refFlag && singleCopy)
		{
			//remove references to this object from 
			//all the objects that generated it. 	
			//FIXME: This only works for the file system database 
			[databaseInterface removeOutputReferencesToObjectWithID:
					[item objectForKey: @"Identification"]
				ofClass: [item objectForKey:@"Class"]
				inSchema: [item objectForKey: @"Schema"]
				ofClient: [item objectForKey: ULDatabaseClientName]
				error: &error];

			if(error != nil)
			{
				//If there was an error while removing the references
				//dont try to remove the object
				[errors addObject: error];
				error = nil;
				continue;
			}
		
		}
		else if(refFlag)
		{
			//Copies exist - Inform user and continue
			NSRunAlertPanel([NSString stringWithFormat: @"Copies of %@ detected",
					[item objectForKey: @"Name"]],
				@"References to selected item not removed",
				@"Dismiss",
				nil,
				nil);
		}

		[databaseInterface removeObjectOfClass: [item objectForKey:@"Class"]
			withID: [item objectForKey: @"Identification"]
			fromSchema: [item objectForKey: @"Schema"]
			ofClient: [item objectForKey: ULDatabaseClientName]
			error: &error];
		
		if(error != nil)
		{
			[errors addObject: error];
			error = nil;
			row = [selectedRows indexGreaterThanIndex: row];
		}
		
		row = [selectedRows indexGreaterThanIndex: row];
	}

	errorEnum = [errors objectEnumerator];
	while(error = [errorEnum nextObject])
		ULRunErrorPanel(error);
	
	[errors release];
	[locations release];

	[self willReloadData];
	[browserView reloadData];
	[self didReloadData];
	//update selection
	if(lastRow >= [browserView numberOfRows])
		lastRow = [browserView numberOfRows] - 1;

	[browserView selectRowIndexes: [NSIndexSet indexSetWithIndex: lastRow]
		byExtendingSelection: NO];
}

- (void) remove: (id) sender
{
	[self _remove: NO];
}

- (void) delete: (id) sender
{
	[self _remove: YES];
}

- (void) cut: (id) sender
{
	int selectedRow;
	id item;

	selectedRow = [browserView selectedRow];
	item = [browserView itemAtRow: selectedRow];

	[editedObject release];
	editedObject = [item retain];
	cut = YES;
}

- (void) copy: (id) sender
{
	int selectedRow;
	id item;

	selectedRow = [browserView selectedRow];
	item = [browserView itemAtRow: selectedRow];
	[editedObject release];
	editedObject = [item retain];
	cut = NO;
}

- (void) _cutAndPasteItem: (id) item 
	from: (NSString*) source 
	to: (NSString*) destination
{
	int retVal;
	NSError *error = nil;
	id realObject; //the actual unarchived object

	progressPanel = [ULProgressPanel progressPanelWithTitle:
				[NSString stringWithFormat: @"Moving %@ to %@", 
					[editedObject objectForKey: @"Name"],
					[item objectForKey: ULDatabaseClientName]]
				message: @"Moving"	
				progressInfo: @"Retrieving"];
	[progressPanel retain];			
	[progressPanel setIndeterminate: YES];	
	
	retVal = NSRunAlertPanel(@"Move",
			[NSString stringWithFormat: @"Move %@ from\n %@\n to\n %@?", 
				[editedObject objectForKey: @"Name"],
				source,
				destination],
			@"OK", 
			@"Dismiss",
			nil);
			
	if(retVal == NSOKButton)
	{
		[progressPanel runProgressPanel: NO];		
		//Indicate that we dont want the panel to end
		//on the reciept of any notifications
		endPanel = NO;

		//get the real object
		realObject = [databaseInterface unarchiveObjectWithID: 
				[editedObject objectForKey: @"Identification"]
			ofClass: [editedObject objectForKey: @"Class"]
			fromSchema: [editedObject objectForKey: @"Schema"]
			ofClient: [editedObject objectForKey: ULDatabaseClientName]
			error: &error];

		if(error != nil)
		{	
			[progressPanel endPanel];
			[progressPanel release];
			progressPanel = nil;
			editedObject = nil;
			cut = NO;
			ULRunErrorPanel(error);
			return;
		}	
		
		[progressPanel setProgressInfo: @"Adding"];
		//add it to its new database
		[databaseInterface addObject: realObject
			toSchema: [item objectForKey: ULSchemaName]
			ofClient: [item objectForKey: ULDatabaseClientName]
			error: &error];

		//only delete it from its old database
		//if we managed to add it in the previous step
		if(error != nil)
		{
			[progressPanel endPanel];
			[progressPanel release];
			progressPanel = nil;
			editedObject = nil;
			cut = NO;
			ULRunErrorPanel(error);
			return;
		}	

		//Indicate that we want the panel to end on the
		//next notification received
		endPanel = YES;
		[progressPanel setProgressInfo: @"Removing"];
		[databaseInterface removeObjectOfClass: [editedObject valueForKey:@"Class"]
			withID: [editedObject valueForKey: @"Identification"]
			fromSchema: [editedObject objectForKey: @"Schema"]
			ofClient: [editedObject objectForKey: ULDatabaseClientName]
			error: &error];
				
		if(error != nil)
		{	
			[progressPanel endPanel];
			[progressPanel release];
			progressPanel = nil;
			editedObject = nil;
			cut = NO;
			ULRunErrorPanel(error);
		}	

		sleep(1.0);
	}
	else
	{
		[progressPanel release];
		progressPanel = nil;
		editedObject = nil;
		cut = NO;
	}
}

- (void) _copyAndPasteItem: (id) item 
	from: (NSString*) source 
	to: (NSString*) destination
{
	int retVal;
	NSError *error = nil;
	id realObject; //the actual unarchived object
	
	progressPanel = [ULProgressPanel progressPanelWithTitle: 
				[NSString stringWithFormat: @"Copying %@ to %@", 
					[editedObject objectForKey: @"Name"],
					[item objectForKey: ULDatabaseClientName]]	
				message: @"Copying"
				progressInfo: @"Estimated Time - Unknown"];
	[progressPanel retain];			
	[progressPanel setIndeterminate: YES];	
	[NSApp updateWindows];

	retVal = NSRunAlertPanel(@"Copy",
			[NSString stringWithFormat: @"Copy %@ from\n %@\n to\n %@?", 
				[editedObject objectForKey: @"Name"],
				source,
				destination],
			@"OK", 
			@"Dismiss",
			nil);
	if(retVal == NSOKButton)
	{
		endPanel = YES;
		[progressPanel runProgressPanel: NO];		
		realObject = [databaseInterface unarchiveObjectWithID: 
					[editedObject objectForKey: @"Identification"]
				ofClass: [editedObject objectForKey: @"Class"]
				fromSchema: [editedObject objectForKey: @"Schema"]
				ofClient: [editedObject objectForKey: ULDatabaseClientName]
				error: &error];
		
		if(error == nil)
		{	
			[databaseInterface addObject: realObject	
				toSchema: [item objectForKey: ULSchemaName]
				ofClient: [item objectForKey: ULDatabaseClientName]
				error: &error];
			sleep(1.0);
		}		

		//If there was an error in either step 
		//clean up and report it.
		if(error != nil)
		{	
			[progressPanel endPanel];
			[progressPanel release];
			progressPanel = nil;
			editedObject = nil;
			cut = NO;
			ULRunErrorPanel(error);
		}	
	}
	else
	{
		[progressPanel release];
		progressPanel = nil;
		editedObject = nil;
		cut = NO;
	}
}

- (void) paste: (id) sender
{
	int selectedRow;
	NSString* source, *destination;
	id item;

	selectedRow = [browserView selectedRow];
	item = [browserView itemAtRow: selectedRow];

	source = [NSString stringWithFormat: @"%@/%@",
			[editedObject objectForKey: @"Database"],
			[editedObject objectForKey: @"Schema"]]; 
	destination = [NSString stringWithFormat: @"%@/%@",
			[item objectForKey: ULDatabaseClientName],
			[item objectForKey: ULSchemaName]]; 

	//FIXME: item Here is actually the destination schema item
	//not the actual item being cut/copied. The cut/copied item
	//is held in the editedObjects ivar. Fix the naming here
	//to better reflect this.

	if(cut)
	{	
		[self _cutAndPasteItem: item 
			from: source 
			to: destination];
	}
	else
	{	
		[self _copyAndPasteItem: item 
			from: source 
			to: destination];
	}	
}

- (void) export: (id) sender
{
	/*
	 * Delegate to the shared export controller.
	 * It will retrieve the selected object from us via
	 * the pasteboard.
	 */
	[[ULExportController sharedExportController] export: self];
}

/**
\e sender is the menu item that was clicked
*/
- (void) exportAs: (id) sender
{
	[[ULExportController sharedExportController] 
		exportCurrentPasteboardObjectAs: [sender tag]];
}

- (BOOL) _canImportObject: (id) object 
		toSchema: (NSString*) schemaName 
		ofClient: (NSString*) clientName 
		error: (NSError**) error
{
	NSError* internalError = nil;
	
	//FIXME: This just checks if the object is in the database,
	//not that it is in the schema specified. However at the moment
	//all databases only have one schema so this doesn't matter. However
	//it will have to be changed if or when multiple schema support is implemented.
	if([[databaseInterface backendForClient: clientName] 
		objectInDatabase: object error: &internalError])
	{
		//If no error was returned, we create one detailing that the object is already
		//present. Otherwise we use the error returned.
		if(internalError == nil)
		{
			*error = AdCreateError(ULFrameworkErrorDomain, 10, 
					@"Unable to add object. ", 
					@"Object already present in the database", nil); 
			
		}
		else		
			*error = internalError;
			
		return NO;
	}

	//Check the file storage is valid. 
	if([object isKindOfClass: [AdSimulationData class]])
		if(![[object dataStorage] isAccessible])
		{
			*error = [[object dataStorage] accessError];
			return NO;
		}
	
	return YES;
}

- (void) import: (id) sender
{
	BOOL retVal;
	int selectedRow, result;
	id object; 
	id item, openPanel, filename;
	NSError *error = nil;
	NSString* storagePath;
	AdFileSystemSimulationStorage *dataStorage;
	id string, name;
	AdMutableDataMatrix* matrix;

	selectedRow = [browserView selectedRow];
	item = [browserView itemAtRow: selectedRow];
	
	NS_DURING
	{
		progressPanel = [ULProgressPanel progressPanelWithTitle: @"Import"
					message: @"Importing"
					progressInfo: @"Estimated time - Unknown"];
		[progressPanel retain];			
		[progressPanel setIndeterminate: YES];	
		[NSApp updateWindows];

		openPanel = [NSOpenPanel openPanel];	
		[openPanel setTitle: @"Import Data"];
		result = [openPanel runModalForTypes: nil];
		filename = [openPanel filename];

		if(result == NSOKButton)
		{
			[progressPanel setMessage: 
				[NSString stringWithFormat: @"Importing file - %@",
				[filename lastPathComponent]]];
			[progressPanel runProgressPanel: NO];	
			endPanel = YES;

			if([[filename pathExtension] isEqual: @"csv"])
			{
				string = [NSString stringWithContentsOfFile: filename];
				matrix = [AdMutableDataMatrix matrixFromStringRepresentation: string];
				name =  [[filename stringByDeletingPathExtension]
						lastPathComponent];
				[matrix setName:  name];		
				object = [[AdDataSet alloc] initWithName: @"ImportedTable"];
				[object autorelease];
				[object addDataMatrix: matrix];
			}
			else
				object = [NSKeyedUnarchiver unarchiveObjectWithFile: filename];

			//If its a simulation we have to import its data aswell.
			//This is a directory with the same name as filename but 
			//with _Data appended (see export: above).
			if([object isKindOfClass: [AdSimulationData class]])
			{
				storagePath = [filename stringByAppendingString: @"_Data"];
				//Create an AdFileSystemSimulationStorage object for the data
				dataStorage = [[AdFileSystemSimulationStorage alloc]
						initForReadingSimulationDataAtPath: storagePath];
				[dataStorage autorelease];
				[object setDataStorage: dataStorage];
			}

			if([self _canImportObject: object 
				toSchema: [item objectForKey: ULSchemaName] 
				ofClient: [item objectForKey: ULDatabaseClientName]
				error: &error])
			{
				//We add non-AdSimulationData objects in the standard way
				[databaseInterface addObject: object	
					toSchema: [item objectForKey: ULSchemaName]
					ofClient: [item objectForKey: ULDatabaseClientName]
					error: &error];
			}	
			
			//If either _canImportObject:error:toSchema: or
			//addObject:toSchema:ofClient:error: set an error
			//report it.
			if(error != nil)
			{
				AdLogError(error);
				[progressPanel endPanel];
				[progressPanel release];
				progressPanel = nil;
				ULRunErrorPanel(error);
			}	

		}
		else
		{
			//If the user chose cancel we have to
			//destroy the progress panel we set up above
			[progressPanel release];
			progressPanel = nil;
		}
	}
	NS_HANDLER
	{
		//There was an exception during the import.
		//End the progress panel and display an alert panel.
		[progressPanel endPanel];
		[progressPanel release];
		progressPanel = nil;
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
	}
	NS_ENDHANDLER
}

/**
ULPasteboard delegate methods
**/

- (NSArray*) availableTypes
{
	NSMutableArray* array = [NSMutableArray array];

	if([selectedSystems count] != 0)
		[array addObject: @"AdDataSource"];
	
	if([selectedOptions count] != 0)
		[array addObject: @"ULTemplate"];
	
	if([selectedDataSets count] != 0)
		[array addObject: @"AdDataSet"];
	
	if([selectedSimulations count] != 0)
		[array addObject: @"AdSimulationData"];

	return array;	
}

- (id) objectForType: (NSString*) type
{
	NSError *error = nil;
	id item , object;

	if([type isEqual: @"AdDataSource"] && [selectedSystems count] != 0)
		item = [selectedSystems objectAtIndex: 0];
	else if([type isEqual: @"ULTemplate"] && [selectedOptions count] != 0)
		item = [selectedOptions objectAtIndex: 0];
	else if([type isEqual: @"AdDataSet"] && [selectedDataSets count] != 0)
		item = [selectedDataSets objectAtIndex: 0];
	else if([type isEqual: @"AdSimulationData"] && [selectedSimulations count] != 0)
		item = [selectedSimulations objectAtIndex: 0];
	else	
		return nil;
	
	object = [databaseInterface 
			unarchiveObjectWithID: [item objectForKey: @"Identification"]
			ofClass: [item objectForKey: @"Class"]
			fromSchema: [item objectForKey: @"Schema"]
			ofClient: [item objectForKey: ULDatabaseClientName]
			error: &error];

	if(error != nil)
		ULRunErrorPanel(error);
			
	return object;		
}

- (NSArray*) objectsForType: (NSString*) type
{
	NSMutableArray* array = [NSMutableArray array];
	NSMutableArray* errors = [NSMutableArray new];
	NSEnumerator* selectionEnum, *errorEnum;
	NSError *error = nil;
	id item, object;
	
	if([type isEqual: @"AdDataSource"] && [selectedSystems count] != 0)
		selectionEnum = [selectedSystems objectEnumerator];
	else if([type isEqual: @"ULTemplate"] && [selectedOptions count] != 0)
		selectionEnum = [selectedOptions objectEnumerator];
	else if([type isEqual: @"AdDataSet"] && [selectedDataSets count] != 0)
		selectionEnum = [selectedDataSets objectEnumerator];
	else if([type isEqual: @"AdSimulationData"] && [selectedSimulations count] != 0)
		selectionEnum = [selectedSimulations objectEnumerator];
	else
		return array;
	

	while(item = [selectionEnum nextObject])
	{
		object = [databaseInterface unarchiveObjectWithID: 
				[item objectForKey: @"Identification"]
				ofClass: [item objectForKey: @"Class"]
				fromSchema: [item objectForKey: @"Schema"]
				ofClient: [item objectForKey: ULDatabaseClientName]
				error: &error];

		if(object != nil)
			[array addObject: object];
		else if(error != nil)
			[errors addObject: error];
	}			

	errorEnum = [errors objectEnumerator];
	while(error = [errorEnum nextObject])
		ULRunErrorPanel(error);

	[errors release];	

	return array;
}

- (int) countOfObjectsForType: (NSString*) type
{
	if([type isEqual: @"AdDataSource"])
		return [selectedSystems count];

	if([type isEqual: @"ULTemplate"])
		return [selectedOptions count];

	if([type isEqual: @"AdDataSet"])
		return [selectedDataSets count];
	
	if([type isEqual: @"AdSimulationData"])
		return [selectedSimulations count];

	return 0;	
}

- (void) pasteboardChangedOwner: (id) pasteboard
{
	[self deselectAllRows: self];
	isActive = NO;
}

@end



