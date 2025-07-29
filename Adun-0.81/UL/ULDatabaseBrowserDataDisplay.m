#include "ULDatabaseBrowser.h"

@implementation ULDatabaseBrowser (ULDatabaseBrowserDataDisplay)

/**
Outline view delegate methods
*/
- (void) willReloadData
{
	oldObjects = currentObjects;
	currentObjects = [NSMutableArray new];
}

- (void) didReloadData
{
	[oldObjects release];
	oldObjects = nil;
}

//FIXME: Consider caching availableObjects so we dont have to keep
//requesting it?
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	id object;
	int itemLevel;
	
	if(item == nil)
		itemLevel = -1;
	else	
		itemLevel = [outlineView levelForItem: item];

	switch(itemLevel)
	{
		case -1:
			object = [[databaseInterface availableClients] objectAtIndex: index];
			break;
		case 0:
			object = [[databaseInterface schemaInformationForClient: item]
					objectAtIndex: index];
			break;		

		case 1:
			object = [[databaseInterface 
					contentTypeInformationForSchema:
						[item objectForKey: ULSchemaName]
					ofClient: [item objectForKey: ULDatabaseClientName]]
					objectAtIndex: index];
			break;		
		case 2:	
			object = [databaseInterface metadataForObjectAtIndex: index
					ofClass: [item objectForKey: @"ULObjectClassName"]
					inSchema: [item objectForKey: ULSchemaName]	
					ofClient: [item objectForKey: ULDatabaseClientName]];

			//older items didnt have a Class metadata attribute which
			//means we cant distinguish system from options. We add it here
			//if its missing. This will be moved to the database index itself
			//as an update step for the new version.
			if([object objectForKey: @"Class"] ==  nil)
				[object setObject: 
					[[path itemForLevel: 2] objectForKey: @"ULObjectClassName"]
					forKey: @"Class"];
			break;
	}	

	/*NSDebugLLog(@"ULDatabaseBrowserDataDisplay", 
		@"Returning %@ - for child %d of item %@", object, index, item);*/
	NSDebugLLog(@"ULDatabaseBrowserDataDisplay", 
		    @"Returning object - for child %d of item %d", index, itemLevel);
	/*NSDebugLLog(@"ULDatabaseBrowserDataDisplay",
		@"Current path %@", [path currentPath]);*/

	[path setItem: object forLevel: itemLevel + 1];
	
	//Have to retain a reference to the outline view objects.
	[currentObjects addObject: object];
	return object;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	int itemLevel, noChildren;

	if(item == nil)
		itemLevel = -1;
	else
	{
#ifdef GNUSTEP
		//Subtle difference in how cocoa/gnustep work
		//mean we have to use different methods at this point.
		//Under gnustep \e item hasnt been assigned its real level
		//at this point and under cocoa the path does not work
		//for some unknown reason.
		itemLevel = [path currentLevel];
#else		
		itemLevel = [outlineView levelForItem: item];
#endif
	}
	
	NSDebugLLog(@"ULDatabaseBrowserDataDisplay", 
		@"Gettin number of children for item at level %d", itemLevel);
	/*NSDebugLLog(@"ULDatabaseBrowserDataDisplay", 
		@"Current path %@", [path currentPath]);*/
	
	switch(itemLevel)
	{
		case -1:
			noChildren = [[databaseInterface availableClients] count];
			break;
		case 0:
			noChildren = [[databaseInterface 
					schemaInformationForClient: item]
					count];
			break;		
		case 1:
			noChildren = [[databaseInterface 
					contentTypeInformationForSchema:
						[item objectForKey: ULSchemaName]
					ofClient: [item objectForKey: ULDatabaseClientName]] count];
			break;		
		case 2:			
			noChildren = [[databaseInterface metadataForObjectsOfClass: 
						[item objectForKey: @"ULObjectClassName"]
					inSchema: [item objectForKey: ULSchemaName]
					ofClient: [item objectForKey: ULDatabaseClientName]] count];
			break;	
		default:
			noChildren = 0;
	}			

	NSDebugLLog(@"ULDatabaseBrowserDataDisplay", 
		@"This item has %d children", noChildren);
		
	return noChildren;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	int itemLevel;

	itemLevel = [outlineView levelForItem:item];
	if(itemLevel < 3)
		return YES;
	else
		return NO;
}

- (void) outlineViewItemDidCollapse: (NSNotification*) aNotification
{
	int itemLevel;
	id item, outlineView;

	item = [[aNotification userInfo] objectForKey: @"NSObject"];
	outlineView = [aNotification object];
	itemLevel = [outlineView levelForItem:item];
#ifdef GNUSTEP
	//Again the path does not work correctly under Cocoa.
	//In addition this isn't necessary under Cocoa either.
	//However on GNUstep this still might be needed ....	
	[path truncateToLevel: itemLevel];
#endif	
}

- (id)outlineView:(NSOutlineView *)outlineView 
	objectValueForTableColumn:(NSTableColumn *)tableColumn 
	byItem:(id)item
{
	BOOL connectionState;
	int itemLevel, index;
	id obj;

	itemLevel = [outlineView levelForItem: item];

	if([[tableColumn identifier] isEqual: @"Created"])
		index = 1;
	else
		index = 0;

	NSDebugLLog(@"ULDatabaseBrowserDataDisplay",
		@"Getting value for item at level %d\n", itemLevel);

	switch(itemLevel)
	{
		case 0:
			if(index == 0)
			{
				obj = [[[NSMutableAttributedString alloc] 
					initWithString: item] autorelease];
				connectionState = [databaseInterface connectionStateForClient: item];
				if(connectionState == ULDatabaseClientConnected)
				{
					[obj addAttribute: NSForegroundColorAttributeName
						value: [NSColor blueColor]
						range: NSMakeRange(0, [obj length])];
				}
				else
				{
					[obj addAttribute: NSForegroundColorAttributeName
						value: [NSColor redColor]
						range: NSMakeRange(0, [obj length])];
				}

				return obj;	
			}
			else 
				return @"";
		case 1:
			if(index == 0)
				return [item objectForKey: ULSchemaName];	
			else
				return @"";
		case 2:
			if(index == 0)
				return [item objectForKey: @"ULObjectDisplayName"];
			else
				return @"";
		default:
			if(index == 0)
				return [item objectForKey: @"Name"];
			else
				return [item objectForKey: @"Created"];
	}		
}

/**
Outline view delegate
*/

//To allow deselectAll
- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView
{
	return YES;
}

- (void) outlineViewSelectionDidChange: (NSNotification*) aNotification
{
	int row;
	id selectedRows, item;

	//udpate whats been selected
	[selectedSystems removeAllObjects];
	[selectedOptions removeAllObjects];
	[selectedDataSets removeAllObjects];
	[selectedSimulations removeAllObjects];
	selectedRows = [browserView selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		item = [browserView itemAtRow: row];
		if([browserView levelForItem: item] >= 3)
		{
			if([[item objectForKey:@"Class"] isEqual: @"AdDataSource"])
				[selectedSystems addObject: item];
			else if([[item objectForKey: @"Class"] isEqual: @"ULTemplate"])
				[selectedOptions addObject: item];
			else if([[item objectForKey: @"Class"] isEqual: @"AdDataSet"])
				[selectedDataSets addObject: item];
			else if([[item objectForKey: @"Class"] isEqual: @"AdSimulationData"])
				[selectedSimulations addObject: item];
		}

		row = [selectedRows indexGreaterThanIndex: row];
	}
}

- (BOOL) outlineView: (NSOutlineView*) outlineView shouldSelectItem: (id) item
{
	if(!isActive)
	{
		//take ownership of the pasteboard
		//NSLog(@"Not active - taking control of pasteboard and activating self");
		[[ULPasteboard appPasteboard] setPasteboardOwner: self];
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseBrowserDidBecomeActiveNotification"
			object: self];
	}		

	return YES;
}	

@end
