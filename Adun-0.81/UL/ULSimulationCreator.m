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
#include "ULSimulationCreator.h"

@implementation ULSimulationCreator

- (BOOL) _checkInputData
{
	BOOL missingData = NO;
	NSArray* inputDataNames;
	NSEnumerator* externalNamesEnum;
	NSString* name;

	inputDataNames = [inputData allKeys];
	externalNamesEnum = [[simulationTemplate externalReferences]
				objectEnumerator];
	while(name = [externalNamesEnum nextObject])
		if(![inputDataNames containsObject: name])
		{
			missingData = YES;
			break;
		}

	if(!missingData)
		return YES;
	else	
		return NO;
}

- (NSMutableDictionary*) _createCoreTemplate
{
	NSMutableDictionary* coreTemplate;
	NSDictionary* metadata, *checkpointing;

	coreTemplate = [simulationTemplate coreRepresentation];

	metadata = [NSDictionary dictionaryWithObject: 
				[simulationNameField stringValue]
			forKey: @"simulationName"];
	[coreTemplate setObject: metadata forKey: @"metadata"];

	checkpointing = [NSDictionary dictionaryWithObjectsAndKeys: 
				[energyField stringValue], @"energy",
				[configurationField stringValue], @"configuration",
				[energyDumpField stringValue], @"energyDump",
				nil];
	[coreTemplate setObject: checkpointing forKey: @"checkpoint"];
	[coreTemplate setObject: [NSDictionary dictionary]
		forKey: @"externalObjects"];

	return coreTemplate;
}

/*
Checks that the external references defined
by the template refer to data types we can handle -
i.e. AdDataSource or AdDataSet.
*/
- (BOOL) _checkTemplateReferences
{
	BOOL allowedReferenceTypes;
	NSEnumerator *externalReferenceEnum, *externalTypeEnum;
	NSArray* externalTypes;
	id type, externalReference;

	allowedReferenceTypes = YES;
	externalReferenceEnum = [[simulationTemplate externalReferences]
					objectEnumerator];
	while(allowedReferenceTypes && 
		(externalReference = [externalReferenceEnum nextObject]))
	{
		allowedReferenceTypes = NO;
		externalTypes = [[simulationTemplate externalReferenceTypes]
					objectForKey: externalReference];
		//Check the types allowed for this reference
		//If any of them are valid we set allowedReferenceTypes
		//to YES and continue. 
		//Otherwise its set to NO and the loop will end.
		externalTypeEnum = [externalTypes objectEnumerator];
		while(type = [externalTypeEnum nextObject])
		{
			if([inputDataTypes containsObject: type])
				allowedReferenceTypes = YES;
		}		
	}			


	if(!allowedReferenceTypes)
		NSRunAlertPanel(@"Unable to load template",
			[NSString stringWithFormat:
				@"Template contains external reference to unsupported data.\nReference %@, type %@.",
				externalReference,
				type],
			@"Dismiss",
			nil,
			nil);

	return allowedReferenceTypes;
}


- (id) init
{
	if(self = [super init])
	{
		inputData = [NSMutableDictionary new];
		//Can add more in the future
		inputDataTypes = [NSArray arrayWithObjects: 		
					@"AdDataSource", 
					@"AdDataSet",
					nil];
		[inputDataTypes retain];		
		processManager = [ULProcessManager appProcessManager];
		pasteboard = [ULPasteboard appPasteboard]; 
		inputTypeDisplayNames = [NSDictionary dictionaryWithObjectsAndKeys:
						@"System", @"AdDataSource",
						@"DataSet", @"AdDataSet", nil];
		[inputTypeDisplayNames retain];				

	}

	return self;
}

- (void) dealloc
{
	[simulationTemplate release];
	[inputData release];
	[inputDataTypes release];
	[inputTypeDisplayNames release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[selectHostButton removeAllItems];
	[selectHostButton addItemsWithTitles: [processManager hosts]];
	[selectHostButton selectItemAtIndex: 0];

	[tabView selectTabViewItemAtIndex: 0];
	[window setDelegate: self];
	[externalDataTable setDataSource: self];

/*	[sectionList removeAllItems];
	[sectionList addItemWithTitle: @"General"];
	[sectionList addItemWithTitle: @"Input Data"];
	[sectionList addItemWithTitle: @"Checkpointing"];
	[sectionList addItemWithTitle: @"Host"];
	[sectionList selectItemWithTitle: @"General"];*/
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	NSString* action;

	action = NSStringFromSelector([menuItem action]);
	if([action isEqual: @"load:"])
	{
		if([pasteboard countOfObjectsForType: @"ULTemplate"] == 1)
			return YES;

		if([pasteboard availableTypeFromArray: inputDataTypes] != nil)
		{
			if(simulationTemplate == nil)
				return NO;
			else	
				return YES;
		}		
		else
			return NO;
	}		

	return YES;
}

/*
- (void) sectionDidChange: (id) sender
{
	NSString* section;
	
	section = [sectionList titleOfSelectedItem];
	[sectionList setNeedsDisplay: YES];
	[tabView selectTabViewItemWithIdentifier: section];
	//FIXME: Gnustep Bug - For some reason the above call 
	//stops the popup list from changing to section.
	//Have to force the change.
	[sectionList selectItemWithTitle: section];
}*/

- (void) createSimulation: (id) sender
{
	//NSFloatingWindowLevel is incompatible with
	//NSPopupButton on gnome so I have remove use
	//of the pop up button in favour of normal tabs.
	[window setLevel: NSFloatingWindowLevel];
	
	//[sectionList setNeedsDisplay: YES];
	[tabView selectTabViewItemWithIdentifier: @"General"];
	//[sectionList selectItemWithTitle: @"General"];
	[energyDumpField setStringValue: @"1000"];
	[templateField setStringValue: @""];
	[simulationNameField setStringValue: @"Output"];
	[window center];
	[window makeKeyAndOrderFront: self];
}

- (void) createProcess: (id) sender
{
	BOOL retVal, create;
	NSMutableDictionary* coreTemplate;

	create = YES;	
	
	if(![self _checkInputData])
	{
		retVal = NSRunAlertPanel(@"Alert",
				@"All input data slots not filled",
				@"Continue",
				@"Cancel",
				nil);
		if(retVal != NSOKButton)
			create = NO;
	}		

	if(create)
	{
		//Create the core template 
		//FIXME: Later may add all elements to template instace
		//and use that - Requires modification of ULProcess & ULProcessManager
		coreTemplate = [self _createCoreTemplate];
		host = [selectHostButton titleOfSelectedItem];
		[processManager newProcessWithInputData: [[inputData copy] autorelease]
			simulationTemplate: coreTemplate
			host: host];
	}	
}

- (void) load: (id) sender
{
	BOOL allowedReferenceTypes;
	int selectedRow;
	NSString* availableType, *name; 
	NSArray *dataTypes;
	id data;

	availableType = [pasteboard availableTypeFromArray: 
				[NSArray arrayWithObjects: @"ULTemplate",
					@"AdDataSource", @"AdDataSet", nil]];
	if([inputDataTypes containsObject: availableType])
	{
		/*
		 * Get selected externalDataTable entry
		 * Check if types are compatible
		 * Load data and add name to the table
		 * Get rid of anything that was previously there.
		 * Update input data dictionary
		 */
		selectedRow = [externalDataTable selectedRow];
		if(selectedRow < 0)
		{
			NSRunAlertPanel(@"Alert",
				@"No input data row selected",
				@"Dismiss",
				nil,
				nil);
			return;
		}	
		name = [[simulationTemplate externalReferences] 
				objectAtIndex: selectedRow];
		dataTypes = [[simulationTemplate externalReferenceTypes] 
				objectForKey: name];
		if([dataTypes containsObject: availableType])
		{
			data = [pasteboard objectForType: availableType];
			[inputData setObject: data forKey: name];
			[externalDataTable reloadData];
		}
		else
			NSRunAlertPanel(@"Alert",
				@"Types are not compatible",
				@"Dismiss",
				nil,
				nil);
	}
	else if([availableType isEqual: @"ULTemplate"])
	{
		[simulationTemplate release];
		simulationTemplate = [pasteboard objectForType: @"ULTemplate"];
		[simulationTemplate retain];

		//Check the external reference data types
		//We can only handle external references to AdDataSets & AdDataSources
		//at the moment
		allowedReferenceTypes = [self _checkTemplateReferences];
			
		if(allowedReferenceTypes)
		{
			[templateField setStringValue: [simulationTemplate name]];
			[externalDataTable reloadData];
		}
		else
		{
			[simulationTemplate release];
			simulationTemplate = nil;
		}
	}
}

- (void) displayTemplate: (id) sender
{
	if(simulationTemplate != nil)
		[[ULTemplateViewController templateViewController]
			displayTemplate: simulationTemplate];
}

- (void) close: (id) sender
{
	[simulationTemplate release];
	simulationTemplate = nil;
	[inputData removeAllObjects];
	[externalDataTable reloadData];
	[energyDumpField setStringValue: @"1000"];
	[configurationField setStringValue: @"100"];
	[energyField setStringValue: @"100"];
}

- (void) closeWindow: (id) sender
{
	[self close: sender];
	[window close];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	return [[simulationTemplate externalReferences] count];
}

- (id)tableView:(NSTableView *)aTableView
	 objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	id columnId, data, type;
	NSString* name, *string;
	NSArray* types;
	NSMutableArray* allowedTypes = [NSMutableArray array];
	NSEnumerator* inputTypesEnum;

	columnId = [aTableColumn identifier];	
	name = [[simulationTemplate externalReferences] objectAtIndex: rowIndex];

	if([columnId isEqual: @"name"])
		return name;
	else if([columnId isEqual: @"dataType"])
	{
		types = [[simulationTemplate externalReferenceTypes] 
				objectForKey: name];
		//We can only handle AdDataSet & AdDataSource
		//so we make sure thats all we display
		inputTypesEnum = [inputDataTypes objectEnumerator];
		while(type = [inputTypesEnum nextObject])
		{
			if([types containsObject: type])
				[allowedTypes addObject:
					[inputTypeDisplayNames objectForKey: type]];
		}			
		
		return [allowedTypes componentsJoinedByString: @", "];
	}	
	else if([columnId isEqual: @"data"])
	{
		data = [inputData objectForKey: name];
		if(data != nil)
			return [(AdModelObject*)data name];
		else
			return @"None loaded";
	}		
}

- (void) windowWillClose: (id) sender
{
	[self close: self];
}

@end
