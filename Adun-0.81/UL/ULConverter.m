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
#include "ULConverter.h"

@implementation ULConverter

- (id) init
{
	if((self = [super init]))
	{
		if([NSBundle loadNibNamed: @"Converter" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}

		databaseInterface = [ULDatabaseInterface databaseInterface];
		simulationData = nil;
		selectedSystem = nil;
	}

	return self;
}

- (void) awakeFromNib
{
	[systemsField setCellClass: [NSButtonCell class]];
}

- (void) dealloc
{
	[simulationData release];
	[selectedSystem release];
	[systemCollection release];
	[super dealloc];
}

- (void) open: (id) sender
{
	[tabView selectTabViewItemWithIdentifier: @"Main"];
	[window setTitle: @"Converter"];
	[window center];
	[window makeKeyAndOrderFront: self];
}

- (void) close: (id) sender
{
	[window close];
	[simulationData release];
	[systemCollection release];
	[selectedSystem release];
	simulationData =nil;
	selectedSystem = nil;
} 

- (void) convert: (id) sender
{	
	int i, numberOfSystems;
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];
	id system, cell;
	NSMutableArray *systems;
	NSArray *cells;
	NSRect matrixFrame;
	NSSize cellSize;

	simulationData = [pasteboard objectForType: @"AdSimulationData"];
	[simulationData loadData];

	if(simulationData == nil)
	{
		[tabView selectTabViewItemWithIdentifier: @"Main"];
		return;
	}	

	[simulationData retain];
	systemCollection = [simulationData systemCollection];
	[systemCollection retain];

	//FIXME: Cant store/handle container systems yet so we
	//have to remove them.
	systems = [[systemCollection fullSystems] mutableCopy];
	[systems autorelease];
	[systems removeObjectsInArray: 
		[systemCollection containerSystems]]; 
	
	numberOfSystems = [systems count];
	//Temporary - This step is necessary since the removal of
	//containers system may set the number of system to 0.
	//Set the number of system to 1 here to limit the amount 
	//of code that has to be modified to handle 0 systems.
	if(numberOfSystems == 0)
		numberOfSystems = 1;

	//Size the cells we will add to fit the matrix frame
	matrixFrame = [systemsField frame];
	cellSize = matrixFrame.size;
	cellSize.height = (double)cellSize.height/numberOfSystems;
	cellSize.height -= 1;
	[systemsField setCellSize: cellSize];
	
	//Create the required cells and update the view
	[systemsField renewRows: numberOfSystems columns: 1];
	[systemsField sizeToCells];

	//Set the cells titles and types
	cells = [systemsField cells];
	for(i=0; i<(int)[cells count]; i++)
	{
		cell = [cells objectAtIndex: i];
		if([systems count] != 0)
		{
			system = [systems objectAtIndex: i];
			[cell setButtonType: NSRadioButton];
			[cell setTitle: [system systemName]];
			//Possibly could have been disabled below
			[cell setEnabled: YES];
		}
		else
		{
			[cell setButtonType: NSRadioButton];
			[cell setTitle: @"None"];
			[cell setEnabled: NO];
		}
	}
	
	if([systems count] != 0)
	{
		//Select the first cell and set initial values
		//for the converter fields (systemName etc)
		[systemsField selectCellAtRow: 0 column: 0];
		selectedSystem = [systems objectAtIndex: 0];
		[selectedSystem retain];
		[systemNameField setStringValue: 
			[[systemsField selectedCell] title]];
		[frameNumberField setStringValue: 
			[NSString stringWithFormat: @"%d",
			[simulationData numberOfFramesForSystem: selectedSystem] - 1]];
		[totalFramesField setStringValue: 
			[NSString stringWithFormat: @"/%d",
			[simulationData numberOfFramesForSystem: selectedSystem] - 1]];
		[convertButton setEnabled: YES];	
		[window setTitle:
			[NSString stringWithFormat: 
				@"Create System from %@",
				[(AdSimulationData*)simulationData name]]];
	}
	else
	{
		selectedSystem = nil;
		[systemNameField setStringValue: @"None"];
		[frameNumberField setStringValue: @"0"];
		[totalFramesField setStringValue: @"/0"];
		[convertButton setEnabled: NO];
		[window setTitle: @"No conversion possible"];
	}

	[systemsField sizeToCells];

	[window center];
	[window makeKeyAndOrderFront: self];
}

- (void) performConversion: (id) sender
{
	int frame, numberOfCheckpoints, checkpoint;
	NSError* error = nil;
	NSString* systemName, *forceField;
	id memento, dataSource;

	checkpoint = [[frameNumberField stringValue] intValue];
	systemName = [systemNameField stringValue];
	numberOfCheckpoints = [simulationData numberTrajectoryCheckpoints];

	if(checkpoint >= numberOfCheckpoints)
	{
		NSRunAlertPanel(@"Alert",
			[NSString stringWithFormat: 
			@"Frame can be from 0 to %d inclusive", numberOfCheckpoints -1],
			@"Dismiss", nil, nil);
		return;
	}	
	
	//Extract
	memento = [simulationData mementoForSystem: selectedSystem
			inTrajectoryCheckpoint: checkpoint];
	//Handle data source topology changes.
	if([simulationData numberTopologyCheckpoints] > 0)
	{
		//There was a change 
		frame = [simulationData frameForTrajectoryCheckpoint: checkpoint];
		//We want to check the current frame aswell
		dataSource = [simulationData lastRecordedDataSourceForSystem: selectedSystem
				inRange: NSMakeRange(0,frame+1)];
		if(dataSource == nil)
			//There was no change up to this checkpoint
			dataSource = [selectedSystem dataSource];
	}
	else
		dataSource = [selectedSystem dataSource];
	
	//Take account of the force field used since it will be lost
	//during the mutable copying
	
	forceField = [dataSource valueForMetadataKey: @"ForceField"];

	/*
	 * We simply want to modify the dataSource coordinates
	 * However it may be immutable - if it is we have to
	 * make a mutable copy.
	 * Note: We should make AdunCore use mutable data sources
	 * by default
	 */
	if([dataSource isMemberOfClass: [AdDataSource class]])
		dataSource = [[dataSource mutableCopy] autorelease];

	[dataSource setElementConfiguration: 
		[memento dataMatrixWithName: @"Coordinates"]];

	//Can only save immutable objects to the database
	dataSource = [[dataSource copy] autorelease];
	[dataSource updateMetadata:
		[NSDictionary dictionaryWithObject: systemName
			forKey: @"Name"]
		inDomains: AdUserMetadataDomain];	
	
	//Create refs
	[dataSource addInputReferenceToObject: simulationData];
	[dataSource setValue: forceField
		forMetadataKey: @"ForceField"
		inDomain: AdUserMetadataDomain];
	[databaseInterface addObjectToFileSystemDatabase: dataSource]; 
	[simulationData addOutputReferenceToObject: dataSource];
	if(![databaseInterface updateOutputReferencesForObject: simulationData
		error: &error])
		ULRunErrorPanel(error);
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	NSArray* availableTypes;

	availableTypes = [[ULPasteboard appPasteboard] 
				availableTypes];

	if([availableTypes count] != 1)
		return NO;
	
	if([availableTypes containsObject: @"AdSimulationData"])
		return YES;

	return NO;
}

- (void) selectionDidChange: (id) sender
{
	int index;

	[selectedSystem release];
	index = [systemsField selectedRow];
	selectedSystem = [[systemCollection fullSystems] 
				objectAtIndex: index];
	[selectedSystem retain];

	[systemNameField setStringValue: 
		[[systemsField selectedCell] title]];
	[frameNumberField setStringValue: 
		[NSString stringWithFormat: @"%d",
		[simulationData numberOfFramesForSystem: selectedSystem] - 1]];
	[totalFramesField setStringValue: 
		[NSString stringWithFormat: @"/%d",
		[simulationData numberOfFramesForSystem: selectedSystem] - 1]];
}

@end
