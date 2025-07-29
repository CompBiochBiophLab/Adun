/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael  Johnston

   Created: 2005-05-31 16:30:43 +0200 by michael johnston

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

#include "ULPropertiesPanel.h"

static ULPropertiesPanel* propertyViewController;

@implementation ULPropertiesPanel

+ (void) inititialize
{
	propertyViewController = nil;
}

+ (id) propertiesPanel
{
	if(propertyViewController == nil)
		propertyViewController = [ULPropertiesPanel new];

	return propertyViewController;
}

- (id) init
{
	if(propertyViewController != nil)
		return propertyViewController;

	if((self = [super init]) != nil)
	{
		if([NSBundle loadNibNamed: @"Options" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}

		result = NO;
		[outlineView setIndentationPerLevel: [outlineView indentationPerLevel]*2.5];
		//[outlineView setHeaderView: nil];
		[window setDelegate: self];
		
		modelObjects = [[NSArray alloc] initWithObjects: 
					@"AdDataSource",
					@"ULTemplate",
					@"AdDataSet", 
					@"ULProcess",
					@"AdSimulationData", 
					nil];
		
		databaseInterface = [ULDatabaseInterface databaseInterface];
		propertyViewController = self;	
		propertiesDict = [NSMutableDictionary new];
		referenceData = [NSMutableArray new];
		availableTypes = [NSMutableArray new];
		selectedObjects = [NSMutableDictionary new];
		checkCount = -1;
	}

	return self;
}

- (void) dealloc
{
	[availableTypes release];
	[selectedObjects release];
	[referenceData release];
	[propertiesDict release];
	[modelObjects release];
	[outlineDelegate release];
	[super dealloc];
}

- (void) awakeFromNib
{	
	float defaultWidth;
	id tableColumn;
	id columns;
	id item;

#if NeXT_RUNTIME != 1
	//FIXME: This is necessary since it is impossible
	//with Gorm 1.2. to connect directly to the text view
	//in a scroll view
	annotations = [annotations documentView];
	annotationInput = [annotationInput documentView];
#endif	
	[tabView selectTabViewItemAtIndex: 0];

	//Allow scrolling of the value column of the template views
	tableColumn = [[outlineView tableColumns] objectAtIndex: 1]; 
	[[tableColumn dataCell] setScrollable: YES];

	columns = [referenceTable tableColumns];
	
	[[[columns objectAtIndex: 0] headerCell] setStringValue: @"Relationship"];
	[[columns objectAtIndex: 0] setIdentifier: @"Relationship"];
	[[[columns objectAtIndex: 0] dataCell] setAlignment: NSCenterTextAlignment];
	defaultWidth = [@"Relationship" sizeWithAttributes: nil].width;
	[[columns objectAtIndex: 0] setWidth: defaultWidth + 20];

	[[[columns objectAtIndex: 1] headerCell] setStringValue: @"Name"];
	[[columns objectAtIndex: 1] setIdentifier: @"Name"];
	[[[columns objectAtIndex: 1] dataCell] setAlignment: NSCenterTextAlignment];
	defaultWidth = [@"SomeObjectName" sizeWithAttributes: nil].width;
	[[columns objectAtIndex: 1] setWidth: defaultWidth + 20];


	[[[columns objectAtIndex: 2] headerCell] setStringValue: @"Data Type"];
	[[columns objectAtIndex: 2] setIdentifier: @"Class"];
	[[[columns objectAtIndex: 2] dataCell] setAlignment: NSCenterTextAlignment];
	defaultWidth = [@"AdSimulationData" sizeWithAttributes: nil].width;
	[[columns objectAtIndex: 2] setWidth: defaultWidth + 20];
	
	[[[columns objectAtIndex: 3] headerCell] setStringValue: @"Client"];
	[[columns objectAtIndex: 3] setIdentifier: @"DatabaseClient"];
	[[[columns objectAtIndex: 3] dataCell] setAlignment: NSCenterTextAlignment];
	defaultWidth = [@"username@localhost" sizeWithAttributes: nil].width;
	[[columns objectAtIndex: 3] setWidth: defaultWidth + 20];
	
	[[[columns objectAtIndex: 4] headerCell] setStringValue: @"Identification"];
	[[columns objectAtIndex: 4] setIdentifier: @"Identification"];
	[[[columns objectAtIndex: 4] dataCell] setAlignment: NSCenterTextAlignment];
	defaultWidth = [[[NSProcessInfo processInfo] globallyUniqueString]
				sizeWithAttributes: nil].width;
	[[columns objectAtIndex: 4] setWidth: defaultWidth + 20];

	[referenceTable setDataSource: self];
	[referenceTable setDelegate: self];
	[referenceTable setUsesAlternatingRowBackgroundColors: YES];
	[referenceTable setAllowsMultipleSelection: YES];
}

- (BOOL) result
{
	return result;
}

- (void) close: (id) sender
{
	int index;

	/*
	 * Before we close we have to make sure
	 * any messages that could potentially be dispatched
	 * to the current outline view delegate are e.g.
	 * 1) One of the outline view cells is being edited when the
	 *    window closes.
	 * 2) The next time reload data is called 
	 *    outlineView:setObjectValue:forTableColumn:byItem
	 *    is sent. 
	 * 3) If the data source has changed in the meantime the
	 *	app will crash
	 */

	if((index = [outlineView editedRow]) != -1)
		[outlineView deselectRow: index];

	if([NSApp modalWindow] != nil)
		[NSApp stopModal];
	result = NO;
	[window close];
} 

- (void) addAnnotation: (id) sender
{
	NSMutableArray* annotationArray;
	NSString* stamp, *check;
	NSMutableString* annotation;
	NSDate *date = [NSDate date];
	NSDateFormatter *formatter;
	NSString* user;
	
	annotation = [[annotationInput textStorage] mutableString];
	if([annotation length] == 0)
		return;

	formatter = [[NSDateFormatter alloc] 
			initWithDateFormat: @"%H:%M %d/%m"
			allowNaturalLanguage: NO];

	user = NSUserName();
	if([user isEqual: @""])
		user = @"Unknown";

	stamp = [NSString stringWithFormat: @"%@\t%@ -\n", 
			user, 
			[formatter stringForObjectValue: date]];
	[formatter release];

	//Check if a \n was added if not add two \n
	check = [annotation substringFromIndex: [annotation length] -1];
	if(![check isEqual: @"\n"])
		[annotation appendString: @"\n"];

	[annotation appendString: @"\n"];
	[annotation insertString: stamp atIndex: 0];

	//Add to the object metadata
	annotationArray = [currentModelObject valueForMetadataKey: @"Annotations"]; 	
	if(annotationArray == nil)
	{
		NSDebugLLog(@"ULPropertiesPanel", @"No annotation - creating");
		annotationArray = [NSMutableArray array];
		[currentModelObject setValue: annotationArray 
			forMetadataKey: @"Annotations"
			inDomain: AdUserMetadataDomain];
	}

	[annotationArray addObject: [[annotation copy] autorelease]];

	[[annotations textStorage] 
		replaceCharactersInRange: NSMakeRange(0,0)
		withString: annotation];

	[[annotationInput textStorage] 
		replaceCharactersInRange: 
		NSMakeRange(0, [[annotationInput textStorage] length])
		withString: @""];
}

- (void) displayMetadataForModelObject: (id) modelObject allowEditing: (BOOL) value
{
	[self displayMetadataForModelObject: modelObject 
		allowEditing: value
		runModal: NO];
}

- (void) saveObjectMetadata: (id) sender
{
	NSError *error = nil;

	[currentModelObject updateMetadata: 
		[propertiesDict objectForKey: @"User Metadata"]];

	if(![[currentModelObject database] isEqual: @"None"])
	{
		[databaseInterface
			updateMetadataForObject: currentModelObject
			inSchema: [currentModelObject schema]
			ofClient: [currentModelObject valueForVolatileMetadataKey: ULDatabaseClientName]
			error: &error];

		if(error != nil)
			ULRunErrorPanel(error);
	}		
	[self close: self];	
	[currentModelObject release];
	result = YES;
}

- (void) _displayAnnotations: (NSArray*) annotationArray
{
	NSEnumerator* annotationEnum;
	NSString* annotation;

	[[annotationInput textStorage]
		replaceCharactersInRange:
			NSMakeRange(0,[[annotationInput textStorage] length])
		withString: @""];
	[[annotations textStorage]
		replaceCharactersInRange:
			NSMakeRange(0,[[annotations textStorage] length])
		withString: @""];

	//display any annotations present in the text view
	if(annotationArray != nil)
	{
		annotationEnum = [annotationArray objectEnumerator];
		while(annotation = [annotationEnum nextObject])
		{
			[[annotations textStorage] 
				replaceCharactersInRange: NSMakeRange(0,0)
				withString: annotation];
		}		
	}	
}

- (void) _updateReferencePane
{
	NSEnumerator* inputRefEnum, *outputRefEnum, *dataEnum;
	id data, ref, element;

	inputRefEnum = [[currentModelObject inputReferences] 
			objectEnumerator];
	outputRefEnum = [[currentModelObject outputReferences]
				objectEnumerator];
	[referenceData removeAllObjects];
	
	while((ref = [inputRefEnum nextObject]))
	{
		data = [databaseInterface findObjectsWithID: 
			[ref objectForKey: @"Identification"]
			ofClass: [ref objectForKey: @"Class"]];
		dataEnum = [data objectEnumerator];	
		while((element = [dataEnum nextObject]))
		{
			element = [[element mutableCopy] autorelease];
			[element setObject: @"Input" forKey: @"Relationship"];
			[referenceData addObject: element];
		}	
	}	
	
	while((ref = [outputRefEnum nextObject]))
	{
		data = [databaseInterface findObjectsWithID: 
			[ref objectForKey: @"Identification"]
			ofClass: [ref objectForKey: @"Class"]];
		data = [[data mutableCopy] autorelease];	
		dataEnum = [data objectEnumerator];	
		while((element = [dataEnum nextObject]))
		{
			element = [[element mutableCopy] autorelease];
			[element setObject: @"Output" forKey: @"Relationship"];
			[referenceData addObject: element];
		}	
	}	

	[referenceTable reloadData];
	[referenceTable deselectAll: self];
}

- (void) displayMetadataForModelObject: (id) modelObject allowEditing: (BOOL) value runModal: (BOOL) flag
{
	NSMutableDictionary* user, *system, *properties;
	NSMutableArray* annotationArray;	//The text view is called annotations

	user = [[[modelObject userMetadata] mutableCopy] autorelease];
	annotationArray = [user objectForKey: @"Annotations"];
	[self _displayAnnotations: annotationArray];
	[user removeObjectForKey: @"Annotations"];

	system = [[[modelObject systemMetadata] mutableCopy] autorelease];
	properties = [[[modelObject properties] mutableCopy] autorelease];

	[propertiesDict removeAllObjects];
	[propertiesDict setObject: properties
		forKey: @"Properties"];
	[propertiesDict setObject: system
		forKey: @"System Metadata"];
	[propertiesDict setObject: user
		forKey: @"User Metadata"];

	[outlineDelegate release];
	outlineDelegate = [[ULOutlineViewDelegate alloc] 
				initWithProperties: propertiesDict
				allowEditing: value];
	[outlineView setDelegate: outlineDelegate];
	[outlineView setDataSource: outlineDelegate];

	//keep a ref to modelObject so we can save changes to its metadata
	currentModelObject = [modelObject retain];
	
	//Select correct tab
	[tabView selectTabViewItemAtIndex: 0];

	//set display for properties
	[saveButton setAction: @selector(saveObjectMetadata:)];
	[saveButton setEnabled: YES];
	[outlineView setDrawsGrid: NO];
	[outlineView setUsesAlternatingRowBackgroundColors: YES];
	[outlineView reloadData];
	//Start with everything expanded (General and Meta data)
	[outlineView expandUntilLevel:1];
	[[[[outlineView tableColumns] objectAtIndex: 0] 
		headerCell] setStringValue: @"Properties"];

	//Sets up everything to do with display the references
	[self _updateReferencePane];

	[window setDelegate: self];
	[window setTitle: 
		[NSString stringWithFormat: @"Properties - %@  (%@)",
			 [modelObject valueForKey:@"name"], NSStringFromClass([modelObject class])]];
	[window center];
	[window makeKeyAndOrderFront: self];
	if(flag)
		[NSApp runModalForWindow: window];
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	NSArray* types;
	id pasteboard;

	pasteboard = [ULPasteboard appPasteboard];
	types = [pasteboard availableTypes];
	if([types count] != 1)
		return NO;

	if([pasteboard countOfObjectsForType: [types objectAtIndex: 0]] != 1)
		return NO;

	if([modelObjects containsObject: [types objectAtIndex: 0]])
		return YES;

	return NO;
}

- (void) properties: (id) sender
{
	id modelObject, dataType, pasteboard;

	pasteboard = [ULPasteboard appPasteboard];
	dataType = [[pasteboard availableTypes] 
			objectAtIndex: 0];
	modelObject = [pasteboard objectForType: dataType]; 
	[self displayMetadataForModelObject: modelObject
		allowEditing: YES];
}

- (void) windowWillClose: (NSNotification*) aNotification
{
	if([NSApp modalWindow] != nil)
		[NSApp stopModal];
}

- (void) open: (id) sender
{
	NSWarnLog(@"Deprecated %@", NSStringFromSelector(_cmd));
}

- (void) setAndSave: (id) sender
{
	NSWarnLog(@"Deprecated %@", NSStringFromSelector(_cmd));
}

- (void) display: (id) sender
{
	NSWarnLog(@"Deprecated %@", NSStringFromSelector(_cmd));
}

/***
Table dataSource methods
*/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [referenceData count]; 
}

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{	
	id reference, item;

	reference = [referenceData objectAtIndex: rowIndex];
	if([[aTableColumn identifier] isEqual: @"DatabaseClient"])
		item = [reference objectForKey: ULDatabaseClientName];
	else	
		item = [reference objectForKey: [aTableColumn identifier]];

	return item;
}

/**
Table delegate methods
*/

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification
{
	int row;
	NSDictionary* item;
	NSString* class;
	NSMutableArray* array;
	id selectedRows;
	
	[availableTypes removeAllObjects];
	[selectedObjects removeAllObjects];

	selectedRows = [referenceTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		item = [referenceData objectAtIndex: row];
		class = [item objectForKey: @"Class"];
		if(![availableTypes containsObject: class])
			[availableTypes addObject: class];
			
		array = [selectedObjects objectForKey: class];
		if(array == nil)
		{
			array = [NSMutableArray array];
			[selectedObjects setObject: array forKey: class];
		}
		[array addObject: item];

		row = [selectedRows indexGreaterThanIndex: row];
	}
}

- (BOOL) tableView: (NSTableView*) table shouldSelectRow: (int) row
{
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];

	if([pasteboard changeCount] != checkCount)
	{
		[pasteboard setPasteboardOwner: self];
		checkCount = [pasteboard changeCount];
	}

	return YES;
}	

/**
Pasteboard Methods
**/
//Work around for gnustep deselectAll bug
- (void) deselectAllRows: (id) sender
{
	int row;
	id selectedRows;
	
	selectedRows = [referenceTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		[referenceTable deselectRow: row];
		row = [selectedRows indexGreaterThanIndex: row];
	}
	
	[referenceTable setNeedsDisplay: YES];
} 

- (NSArray*) availableTypes
{
	return [[availableTypes copy] autorelease];	
}

- (id) objectForType: (NSString*) type;
{
	NSError* error = nil;
	NSDictionary* item;
	id object;

	if(![availableTypes containsObject: type])
		return nil;
	
	item = [[selectedObjects objectForKey: type] objectAtIndex: 0];
	object = [databaseInterface unarchiveObjectWithID: 
			[item objectForKey: @"Identification"]
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
	NSMutableArray *array = [NSMutableArray array];
	NSError* error = nil;
	NSEnumerator* itemEnum;
	NSDictionary* item;
	id object;
	
	if(![availableTypes containsObject: type])
		return nil;

	itemEnum = [[selectedObjects objectForKey: type]	
			objectEnumerator];
	
	while((item = [itemEnum nextObject]))
	{
		object = [databaseInterface unarchiveObjectWithID: 
				[item objectForKey: @"Identification"]
				ofClass: [item objectForKey: @"Class"]
				fromSchema: [item objectForKey: @"Schema"]
				ofClient: [item objectForKey: ULDatabaseClientName]
				error: &error];

		if(error != nil)
			ULRunErrorPanel(error);
		else
			[array addObject: object];
	}

	return array;
}

- (int) countOfObjectsForType: (NSString*) type
{	
	if(![availableTypes containsObject: type])
		return 0;

	return [[selectedObjects objectForKey: type] count];
}

- (void) pasteboardChangedOwner: (id) pasteboard
{
	[self deselectAllRows: self];
}

@end
