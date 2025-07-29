/* 
   Project: UL

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2006-06-01 10:15:49 +0200 by michael johnston
   
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
#include "ULTemplateViewController.h"

static id templateViewController;

@implementation ULTemplateViewController

- (void) _clearSectionMenus
{	
	NSEnumerator* sectionEnum;
	NSMutableDictionary* sectionMenu;

	sectionEnum = [sections objectEnumerator];
	while(sectionMenu = [sectionEnum nextObject])
		[sectionMenu removeAllObjects];
}

- (void) _addComponentWithName: (NSString*) name toSectionMenu: (NSMutableDictionary*) menu
{
	NSMutableDictionary* newMenuItem;
	NSDictionary *values;
	NSEnumerator* keyEnum;
	NSString *key;
	
	//Create a menu item for this template which we will
	//display in the interface
	newMenuItem = [NSMutableDictionary newNodeMenu: NO];
	[menu addMenuItem: name withValue: newMenuItem];	
	
	values = [simulationTemplate valuesForObjectTemplateWithName: name];
	keyEnum = [values keyEnumerator];
	while(key = [keyEnum nextObject])
		[newMenuItem addMenuItem: key
			withValue: [values objectForKey: key]];
}

- (void) _updateTemplateView
{
	NSString* holder;
	NSMutableDictionary* menu;
	NSString* section;
	
	section = [popUpList titleOfSelectedItem];
	menu = [sections objectForKey: section];

	[outlineDelegate release];
	holder = [NSString string];
	outlineDelegate = nil;
	outlineDelegate  = [[ULOutlineViewDelegate alloc]
				initWithOptions: menu
				outlineColumnIdentifier: @"Component"];
	[currentTemplateView setDataSource: outlineDelegate];
	[currentTemplateView setDelegate: outlineDelegate];
	[currentTemplateView reloadData];
	[currentTemplateView expandAllItems];
}

- (void) _updateTemplateWithMenuValues
{
	NSEnumerator* sectionEnum, *componentEnum;
	NSMutableDictionary* sectionMenu;
	NSString *componentName;
	id values;

	sectionEnum = [sections objectEnumerator];
	while(sectionMenu = [sectionEnum nextObject])
	{
		componentEnum = [sectionMenu keyEnumerator];
		while(componentName = [componentEnum nextObject])
		{
			values = [sectionMenu objectForKey: componentName];
			[simulationTemplate setValues: values
				forObjectTemplateWithName: componentName];
		}
	}
}

+ (void) initialize
{
	templateViewController = nil;
}

+ (id) templateViewController
{
	if(templateViewController == nil)
		templateViewController = [ULTemplateViewController new];
	
	return templateViewController;
}

- (id) init
{
	NSArray* names;
	NSMutableDictionary* newSection;

	if(templateViewController != nil)
		return templateViewController;

	if(self = [super init])
	{
		sectionDescriptions = [NSDictionary dictionaryWithObjectsAndKeys:
					@"Specify the systems in your simulation", 
					@"System",
					@"Create the force field to be used", 
					@"ForceField",
					@"Specify the configuration generation method", 
					@"Configuration Generation",
					@"Choose a controller", 
					@"Controller", nil];
		[sectionDescriptions retain];

		displayNames = [NSMutableDictionary new];
		names = [[ULTemplate systemObjectTemplates]
				valueForKey: @"DisplayName"];
		names = [names sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
		[displayNames setObject: names forKey: @"System"];
		names = [[ULTemplate configurationGenerationObjectTemplates]
				valueForKey: @"DisplayName"];
		names = [names sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
		[displayNames setObject: names forKey: @"Configuration Generation"];
		names = [[ULTemplate forceFieldObjectTemplates] 
				valueForKey: @"DisplayName"];
		names = [names sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
		[displayNames setObject: names forKey: @"ForceField"];
		names = [[ULTemplate controllerTemplates] 
				valueForKey: @"Class"];
		names = [names sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
		[displayNames setObject: names forKey: @"Controller"];

		if([NSBundle loadNibNamed: @"Template" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}

		sections = [NSMutableDictionary new];
		newSection = [NSMutableDictionary newNodeMenu: NO];
		[sections setObject: newSection forKey: @"System"];
		newSection = [NSMutableDictionary newNodeMenu: NO];
		[sections setObject: newSection forKey: @"ForceField"];
		newSection = [NSMutableDictionary newNodeMenu: NO];
		[sections setObject: newSection forKey: @"Configuration Generation"];
		newSection = [NSMutableDictionary newNodeMenu: NO];
		[sections setObject: newSection forKey: @"Controller"];

		outlineDelegate = nil;

		//Maps the view section names to the ULTemplate section names
		viewToTemplateSectionMap = [NSDictionary dictionaryWithObjectsAndKeys:
						@"forceField", @"ForceField",
						@"system", @"System",
						@"configurationGeneration", @"Configuration Generation",
						@"controller", @"Controller", nil];
		[viewToTemplateSectionMap retain];				
		simulationTemplate = nil;

		templateViewController = self;
	}	

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];
	[viewToTemplateSectionMap release];
	[simulationTemplate release];
	[outlineDelegate release];
	[sections release];
	[sectionDescriptions release];
	[displayNames release];
	[super dealloc];
}

- (void) _outlineViewSelectionDidChange: (NSNotification*) aNotifcation
{
	int row, level;
	id item;
	NSDictionary* template;
	NSString* info;

	row = [currentTemplateView selectedRow];
	if(row == -1)
	{
		template = nil;
		info = @"";
	}
	else
	{
		level = [currentTemplateView levelForRow: row];
		item =  [currentTemplateView itemAtRow: row];
		
		if(level == 0)
		{
			template = [simulationTemplate objectTemplateWithName: 
					[item identifier]];
			info = [template templateDescription];
		}
		else
		{
			template = [simulationTemplate objectTemplateWithName: 
					[[item parent] identifier]];
			info = [template descriptionForKey: [item identifier]];
		}
	}	

	if(info == nil)
		info = @"No description available";

	[componentDescriptionField setStringValue: info];
}

- (void) _updateObservation
{
	[[NSNotificationCenter defaultCenter]
		removeObserver: self
		name: NSOutlineViewSelectionDidChangeNotification
		object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(_outlineViewSelectionDidChange:)
		name: NSOutlineViewSelectionDidChangeNotification
		object: currentTemplateView];
}

- (void) awakeFromNib
{
	NSString* description;
	id tableColumn;

	currentTemplateView = templateView;
	[self _updateObservation];
	[popUpList removeAllItems];
	[popUpList addItemWithTitle: @"System"];
	[popUpList addItemWithTitle: @"ForceField"];
	[popUpList addItemWithTitle: @"Configuration Generation"];
	[popUpList addItemWithTitle: @"Controller"];
	[popUpList selectItemWithTitle: @"System"];
	[componentTable setDataSource: self];
	[componentTable setDelegate: self];
	[templateWindow setDelegate: self];

	//Allow scrolling of the value column of the template views
	tableColumn = [[templateView tableColumns] objectAtIndex: 1]; 
	[[tableColumn dataCell] setScrollable: YES];
	tableColumn = [[templateDisplayView tableColumns] objectAtIndex: 1]; 
	[[tableColumn dataCell] setScrollable: YES];
}

- (void) open: (id) sender
{
	currentTemplateView = templateView;
	[self _updateObservation];
	[tabView selectTabViewItemAtIndex: 1];
	propertyViewController = [ULPropertiesPanel propertiesPanel];
	[simulationTemplate release];
	simulationTemplate = [ULMutableTemplate new];
	[popUpList selectItemWithTitle: @"System"];
	[self changeSection: self];
	[templateWindow center];
	[templateWindow setTitle: @"New Template"];
	[templateWindow makeKeyAndOrderFront: self];
}

- (void) display: (id) sender
{
	ULPasteboard* pasteboard;
	id aTemplate;

	pasteboard = [ULPasteboard appPasteboard];
	aTemplate = [pasteboard objectForType: @"ULTemplate"]; 

	[self displayTemplate: aTemplate];
}

- (void) displayTemplate: (id) aTemplate
{
	NSString* section, *name;
	NSEnumerator *sectionEnum, *templateNameEnum;
	NSDictionary* templates;
	NSMutableDictionary* menu;

	[tabView selectTabViewItemAtIndex: 2];
	currentTemplateView = templateDisplayView;
	[self _updateObservation];
	propertyViewController = [ULPropertiesPanel propertiesPanel];
	
	[simulationTemplate release];
	simulationTemplate = aTemplate; 
	[simulationTemplate retain];

	//Create the menus
	sectionEnum = [sections keyEnumerator];
	while(section = [sectionEnum nextObject])
	{
		menu = [sections objectForKey: section];
		//We have to get the template section name
		//corresponding to the view section name
		templates = [simulationTemplate objectTemplatesInSection: 
				[viewToTemplateSectionMap objectForKey: section]];
		templateNameEnum = [templates keyEnumerator];
		while(name = [templateNameEnum nextObject])
			[self _addComponentWithName: name toSectionMenu: menu];
	}

	[popUpList selectItemWithTitle: @"System"];
	[self changeSection: self];
	[self _updateTemplateView];

	[templateWindow center];
	[templateWindow setTitle: 
		[NSString stringWithFormat: @"Template %@", 
			[simulationTemplate name]]];
	[templateWindow makeKeyAndOrderFront: self];
}

- (void) _cleanUp
{
	[componentTable deselectAll: self];
	[componentTable setNeedsDisplay: YES];
	[templateView setDelegate: nil];
	[templateView setDataSource: nil];
	[templateView reloadData];
	[templateDisplayView setDelegate: nil];
	[templateDisplayView setDataSource: nil];
	[templateDisplayView reloadData];
	[self _clearSectionMenus];
}

- (void) close: (id) sender
{
	[templateWindow orderOut: self];
	[templateWindow close];
}

- (void) validate: (id) sender
{
	NSError* error;
	NSDictionary* userInfo;
	NSString* suggestion;

	[self _updateTemplateWithMenuValues];

	error = nil;
	if(![simulationTemplate validateTemplate: &error])
	{
		userInfo = [error userInfo];
		suggestion = [NSString stringWithFormat: @"%@\n%@",
				[userInfo objectForKey: @"AdDetailedDescriptionKey"],
				[userInfo objectForKey: @"NSRecoverySuggestionKey"]];
		NSRunAlertPanel(
			[userInfo objectForKey: NSLocalizedDescriptionKey],
			suggestion,
			@"Dismiss", 
			nil,
			nil);
	}
	else
	{
		NSRunAlertPanel(@"Validation successful",
			@"",
			@"Dismiss", 
			nil,
			nil);

	}
}

- (void) save: (id) sender
{
	BOOL result;
	id newTemplate;

	[self _updateTemplateWithMenuValues];
	if(![simulationTemplate validateTemplate: NULL])
	{
		NSRunAlertPanel(@"Template not valid",
			@"Run validate on it to find the problem",
			@"Dismiss", 
			nil,
			nil);
		return;	
	}

	result = NSRunAlertPanel(@"External References",
			[[simulationTemplate externalReferences] description],
			@"Continue",
			@"Cancel",
			nil);
	if(result != NSOKButton)
		return;

	/*
	 * If the template is mutable it must be a new template. 
	 * Therefore we make a immutable copy of it before saving.
	 * We then allow the user to edit the metadata of the new template.
	 * If its not then it must be an already saved template.
	 * In this case we save it directly so any values modified
	 * by the user will be saved.
	 */
	if([simulationTemplate isKindOfClass: [ULMutableTemplate class]])
	{
		newTemplate = [[simulationTemplate copy] autorelease];
		[propertyViewController displayMetadataForModelObject: newTemplate	
			allowEditing: YES
			runModal: YES];
		//Return YES or NO depending on which button was pushed.	
		result = [propertyViewController result];	
	}	
	else
	{
		result = YES;
		newTemplate = simulationTemplate;
	}	

	[self close: self];
	if(result)
		[[ULDatabaseInterface databaseInterface]
			addObjectToFileSystemDatabase: newTemplate];
}

- (void) editAsNew: (id) sender
{
	id oldTemplate;

	currentTemplateView = templateView;
	[self _updateObservation];
	oldTemplate = simulationTemplate;
	simulationTemplate = [simulationTemplate mutableCopy];
	[oldTemplate release];
	[tabView selectTabViewItemAtIndex: 1];
	[popUpList selectItemWithTitle: @"System"];
	[self changeSection: self];
	[self _updateTemplateView];
	[templateWindow center];
	[templateWindow setTitle: @"New Template"];
}

- (void) addComponent: (id) sender
{
	int selectedRow;
	NSString* section, *displayName;
	NSDictionary* template;
	NSMutableDictionary *menu;
	NSString *name;

	//Find which component was selected and
	//retrieve the corresponding template
	selectedRow = [componentTable selectedRow];

	if(selectedRow == -1)
		return;
	
	section = [popUpList titleOfSelectedItem];
	displayName = [[displayNames objectForKey: section] 
			objectAtIndex: selectedRow];

	if([section isEqual: @"Controller"])
		template = [NSDictionary templateForClass: 
				displayName];
	else	
		template = [NSDictionary templateForDisplayName: 
				displayName];

	name = [simulationTemplate addObjectTemplate: template];
	menu = [sections objectForKey: section];
	[self _addComponentWithName: name toSectionMenu: menu];
	[self _updateTemplateView];
}

- (void) removeComponent: (id) sender
{
	int itemLevel, row;
	id item;
	NSString* section, *componentName;
	NSMutableDictionary* menu;

	row = [currentTemplateView selectedRow];
	if(row == -1)
		return;

	//FIXME Add a method to ULOutlineViewDelegate to do this
	item = [currentTemplateView itemAtRow: [currentTemplateView selectedRow]];
	itemLevel = [currentTemplateView levelForItem: item];
	if(itemLevel != 0)
		return;

	componentName = [item identifier];

	section = [popUpList titleOfSelectedItem];
	menu = [sections objectForKey: section];
	[menu removeObjectForKey: componentName];
	[simulationTemplate removeObjectTemplateWithName: componentName];
	[self _updateTemplateView];
}

- (void) changeSection: (id) sender
{
	NSString* section, *description;

	section = [popUpList titleOfSelectedItem];
	description = [sectionDescriptions objectForKey: section];
	[sectionDescriptionField setStringValue: description];
	[componentTable reloadData];
	[componentTable deselectAll: self];

	[componentDescriptionField setStringValue: @""];
	[self _updateTemplateView];
}

/*
 * Component Table data source methods
 */

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	NSString* section;

	section = [popUpList titleOfSelectedItem];
	return [[displayNames objectForKey: section] count];
}

- (id)tableView:(NSTableView *)aTableView
	 objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	NSString* section;

	section = [popUpList titleOfSelectedItem];
	return [[displayNames objectForKey: section] objectAtIndex: rowIndex];
}

/*
 * Component Table delegate methods
 */

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification
{
	int selectedRow;
	NSString* section, *displayName;
	NSDictionary* template;

	selectedRow = [componentTable selectedRow];
	if(selectedRow == -1)
	{
		[componentDescriptionField setStringValue: @""];
	}
	else
	{
		section = [popUpList titleOfSelectedItem];
		displayName = [[displayNames objectForKey: section] 
				objectAtIndex: selectedRow];

		template = [NSDictionary templateForDisplayName: displayName];
		[componentDescriptionField setStringValue: 
			[template templateDescription]];
	}		
}
 
/*
 * Window delegate methods
 */

- (void) windowWillClose: (NSNotification*) aNotification
{
	[self _cleanUp];
}
 
@end
