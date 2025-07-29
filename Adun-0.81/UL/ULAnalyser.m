/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

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

#include "ULAnalyser.h"

//Private category handling the toolbar
@interface ULAnalyser (NSToolbarDelegate)
@end

@implementation ULAnalyser

- (id) initWithModelViewController: (id) mVC
{
	if((self = [super init]) != nil)
	{
		if([NSBundle loadNibNamed: @"Results" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}
		
		analysisManager = [ULAnalysisManager new];
		mainViewController = mVC;
		outlineDelegate = nil;
		threadError = NO;
		selectedDataSet = nil;
		pluginDataSets = nil;
		pluginResults = nil;
		pluginError = nil;
		progressPanel = nil;
		selectedPlugin = nil;
		loadedObjects = [NSMutableArray new];
		selectedObjects = [NSMutableArray new];
		checkCount = 0;
		loadableTypes = [[NSArray alloc] initWithObjects: 
					@"AdSimulationData",
					@"ULProcess",
					@"AdDataSet",
					@"AdDataSource",
					@"MTStructure",
					nil];

		classMap = [NSDictionary dictionaryWithObjectsAndKeys:
				@"Simulation", @"AdSimulationData",
				@"Data Set", @"AdDataSet",
				@"System", @"AdDataSource",
				@"PDBStructure", @"MTStructure", nil];
		[classMap retain];
		openDataSets = [NSMutableArray new];	
	}

	return self;
}

/**FIXME: mainViewController should be accessible through some class method*/

- (id) init
{
	return [self initWithModelViewController: nil];
}

- (void) _setToolbarImages
{
	id path;

	path = [[NSBundle mainBundle] pathForImageResource: @"document-save.png"];
      	if (path != nil)
	{
		saveImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
	
	path = [[NSBundle mainBundle] pathForImageResource: @"apply.png"];
      	if (path != nil)
	{
		applyImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
	
	path = [[NSBundle mainBundle] pathForImageResource: @"reload.png"];
      	if (path != nil)
	{
		reloadImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
	
	path = [[NSBundle mainBundle] pathForImageResource: @"dataset-close.png"];
      	if (path != nil)
	{
		closeImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
	
	path = [[NSBundle mainBundle] pathForImageResource: @"export.png"];
      	if (path != nil)
	{
		exportImage = [[NSImage alloc] initWithContentsOfFile: path];
	}
}

- (void)awakeFromNib
{
	ULIOManager* ioManager; 
	NSArray* plugins, *columns;
	id tableColumn;

	ioManager = [ULIOManager appIOManager];
	
	[self updateAvailablePlugins];
	
	[optionsView sizeToFit];
	[optionsView setAutoresizesOutlineColumn: NO];

	//Allow scrolling of the value column of the template views
	tableColumn = [[optionsView tableColumns] objectAtIndex: 1]; 
	[[tableColumn dataCell] setScrollable: YES];

	[window center];
	[window setDelegate: self];

	columns = [loadedObjectsTable tableColumns];
	[[[columns objectAtIndex: 0] headerCell] setStringValue: @"Data Name"];
	[[columns objectAtIndex: 0] setIdentifier: @"dataName"];
	[[[columns objectAtIndex: 0] dataCell] setAlignment: NSCenterTextAlignment];
	[[[columns objectAtIndex: 1] headerCell] setStringValue: @"Data Type"];
	[[columns objectAtIndex: 1] setIdentifier: @"dataType"];
	[[[columns objectAtIndex: 1] dataCell] setAlignment: NSCenterTextAlignment];
	[loadedObjectsTable setDataSource: self];
	[loadedObjectsTable setDelegate: self];
	[loadedObjectsTable setAllowsMultipleSelection: YES];
  
  	[self _setToolbarImages];
	toolbar = [[NSToolbar alloc] initWithIdentifier: @"AnalyseToolbar"];
	[toolbar setAllowsUserCustomization: NO];
	[toolbar setDelegate: self];
	[window setToolbar: toolbar];
	[toolbar release];
	 
	[dataSetList setAutoenablesItems: NO];
	[pluginList setAutoenablesItems: NO]; 
	 
 	[self setupGnuplotInterface];
}

- (void) dealloc
{
	[pluginError release];
	[classMap release];
	[loadableTypes release];
	[selectedObjects release];
	[loadedObjects release];
	[analysisManager release];
	[self gnuplotDealloc];
	[outlineDelegate release];
	[selectedDataSet release];
	[pluginDataSets release];
	[pluginResults release];
	[openDataSets release];
	[super dealloc];
}

- (void) handleThreadError: (NSException*) anException
{
	NSDictionary* userInfo;
	NSError* underlyingError;
	
	userInfo = [anException userInfo];
	if((underlyingError = [userInfo objectForKey: NSUnderlyingErrorKey]) != nil)
		ULRunErrorPanel(underlyingError);	
	else
		NSRunAlertPanel(@"Error",
			[anException reason],
			@"Dismiss", 
			nil,
			nil);
	
	//In this object the subthreads obtain results while the main thread
	//displays progress. When the subthread finishes the main thread expects
	//to use the results. When a thread error occurs we dont want the main thread
	//to do what it normally would. Unfortunately exceptions dont work well with
	//the main (gui) thread often casuing it to stop responding. To get around
	//this if there is an error we set the variable threadError. When the subthread
	//exits and the main thread resumes it can check for this error. It is important
	//to make sure this is set to NO at the start of the thread and that subthreads
	//dont use it.

	threadError = YES;
}

/***************

Opening and Closing the view

*****************/

- (void) open: (id) sender
{
	NSRange endRange;

	[tabView selectTabViewItemAtIndex: 0];
	commandRange.location = [[gnuplotInterface textStorage] length];
	[self updateAvailablePlugins];
	[window makeKeyAndOrderFront: self];
}

- (void) close: (id) sender
{
	[selectedObjects removeAllObjects];
	[loadedObjects removeAllObjects];
	[loadedObjectsTable reloadData];
	
	[analysisManager removeAllInputObjects];
	[analysisManager clearOutput];
	
	[pluginList removeAllItems];
	[pluginList addItemWithTitle: @"None"];
	[pluginList selectItemWithTitle: @"None"];

	[dataView clearDataSet];
	[dataSetList removeAllItems];
	[pluginDataSets release];
	[selectedDataSet release];
	[self removeGnuplotFilesForDataSets: openDataSets];
	[openDataSets removeAllObjects];
	
	[pluginResults release];
	[currentOptions release];
	
	selectedDataSet = nil;
	currentOptions = nil;
	pluginDataSets = nil;
	pluginResults = nil;
	
	[optionsView setDataSource: nil];
	[optionsView setDelegate: nil];
	[optionsView reloadData];
	[resultsLog 
		replaceCharactersInRange: NSMakeRange(0, [[resultsLog textStorage] length])
		withString: @""];
	[window orderOut: self];
}


/***************

 Validation

****************/

//initial implementation of load validation

- (NSNumber*) _validateLoad: (id) sender
{
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];
	id type, process;
	BOOL retval;

	//only load if ULAnalyser is not the current pasteboard
	//owner (Since then the object is already loaded).

	if(checkCount == [pasteboard changeCount])
		return [NSNumber numberWithBool: NO];
	
	type = [pasteboard availableTypeFromArray: loadableTypes];
	if(type != nil)
	{
		//If were loading a process check its been started
		if([type isEqual: @"ULProcess"])
		{
			process = [pasteboard objectForType: type];
			if([[process processStatus] isEqual: @"Waiting"])
				retval = NO;
			else
				retval = YES;
		}
		else
			retval = YES;
	}	
	else	
		retval = NO;

	return [NSNumber numberWithBool: retval];	
}

//Only valid when the dataSet currently being displayed
//by ULAnalyserDataSetView i.e. the selectedDataSet, 
//is in pluginDataSets and is not already in the database
- (NSNumber*) _validateSave: (id) sender
{
	NSNumber* retval = [NSNumber numberWithBool: NO];
	ULDatabaseInterface* databaseInterface = [ULDatabaseInterface databaseInterface];
	NSArray* results;

	if(selectedDataSet != nil)
	{
		if([pluginDataSets containsObject: selectedDataSet])
		{	
			results = [databaseInterface findObjectsWithID: [selectedDataSet identification] 
					ofClass: NSStringFromClass([selectedDataSet class])];
			if([results count] == 0)	
				retval = [NSNumber numberWithBool: YES];				       
		}
	
	}
					
	return retval;
}

- (NSNumber*) _validateRemove: (id) sender
{
	if([selectedObjects count] != 0)
		return [NSNumber numberWithBool: YES];

	return [NSNumber numberWithBool: NO];	
}

- (NSNumber*) _validateDisplay: (id) sender
{
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];
	NSArray* availableTypes;

	availableTypes = [pasteboard availableTypes];
	if([availableTypes containsObject: @"AdDataSet"])
		return [NSNumber numberWithBool: YES];
	else
		return [NSNumber numberWithBool: NO];
}

- (NSNumber*) _validateAnalyse: (id) sender
{
	if([window isKeyWindow])
		return NO;
	else	
		return [self _validateLoad: sender];
}

- (BOOL) _validateExport: (id) sender
{
	//FIXME: Make ULExportController first responder to export:
	//Just put export validation here for the moment.
	//It the command is exportAs: we have to ask the export controller 
	//if the export is possible
	if([NSStringFromSelector([sender action]) isEqual: @"exportAs:"])
		return [[ULExportController sharedExportController] 
			canExportCurrentPasteboardObjectAs: [sender tag]];
	
	//Everything can be exported via the export panel
	if([[[ULPasteboard appPasteboard] availableTypes] count] == 1)
		return YES;
		
	return NO;	
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	id action;
	SEL selector;
	
	//NSPopUpButton is also a menu - however we want
	//it to be always active
	if([menuItem action] == NULL)
		return YES;
	
	action = NSStringFromSelector([menuItem action]);
	
	if([action isEqual: @"deselectAllRows:"])
	{
		if([[loadedObjectsTable selectedRowIndexes] count] > 0)
			return YES;	
		else
			return NO;
	}	

	if([action isEqual: @"loadExternal:"])
			return YES;	
	
	//Do export explicitly for now
	if([action isEqual: @"export:"] || [action isEqual: @"exportAs:"])
		return [self _validateExport: menuItem];
				
	action = [NSStringFromSelector([menuItem action]) capitalizedString];
	action = [NSString stringWithFormat: @"_validate%@", action];
	selector = NSSelectorFromString(action);

	if([self respondsToSelector: selector])
		return [[self performSelector: selector] boolValue];
	else 
		return NO;
}

/***************

Menu Commands

****************/

//These methods deal with loading AdSimulationData 
//objects data in a threaded manner.

- (void) _threadedLoadSimulation: (id) object 
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	id holder;
	
	NS_DURING
	{
		sleep(0.5);
		[object loadData];
		[progressPanel performSelectorOnMainThread: @selector(setProgressInfo:)
			withObject: @"Caching energies ..."
			waitUntilDone: NO];
		[progressPanel performSelectorOnMainThread: @selector(setProgressBarValue:)
			withObject: [NSNumber numberWithDouble: 40.0]
			waitUntilDone: NO];
		[progressPanel performSelectorOnMainThread: @selector(setProgressBarValue:)
			withObject: [NSNumber numberWithDouble: 100.0]
			waitUntilDone: YES];
		[progressPanel performSelectorOnMainThread: @selector(setProgressInfo:)
			withObject: @"Complete"
			waitUntilDone: NO];
		sleep(1.0);

		[progressPanel performSelectorOnMainThread: @selector(endPanel)
			withObject: nil
			waitUntilDone: NO];
	}
	NS_HANDLER
	{
		NSWarnLog(@"Caught plugin exception %@, %@, %@", 
			[localException name], 
			[localException reason],
			[localException userInfo]);	
		[self performSelectorOnMainThread: @selector(handleThreadError:)
			withObject: localException 
			waitUntilDone: YES];
		[progressPanel performSelectorOnMainThread: @selector(endPanel)
			withObject: nil
			waitUntilDone: NO];
	}	
	NS_ENDHANDLER

	[pool release];
	[NSThread exit];
}

- (void) _loadSimulationData: (id) simulation
{
	if(selectedDataSet != nil)
		[dataView clearDataSet];

	progressPanel = [ULProgressPanel progressPanelWithTitle: @"Loading Data"
				message: @"Loading Simulation"
				progressInfo: @"Accessing trajectory ..."];
	[progressPanel setProgressBarValue: [NSNumber numberWithDouble: 0.0]];

	//detach the thread

	threadError = NO;
	[NSThread detachNewThreadSelector: @selector(_threadedLoadSimulation:)
		toTarget: self
		withObject: simulation];
	[progressPanel runProgressPanel: YES];
}


- (void) reloadSimulation: (id) sender
{
	id simulation;

	simulation = [[ULPasteboard appPasteboard]
			objectForType: @"AdSimulationData"];
	[self _loadSimulationData: simulation];
	[self logString: [simulation description]];
}

- (void) _flushProcessEnergies: (ULProcess*) process
{
	NSMutableDictionary* commandDict;
	NSError* error;
	NSString* alertTitle;
	id result;

	if([[process valueForKey:@"processStatus"] isEqual: @"Running"])
	{
		commandDict = [NSMutableDictionary dictionary];
		[commandDict setObject: @"flushEnergies"
			forKey: @"command"];
		result = [[ULProcessManager appProcessManager]  
				execute: commandDict 
				error: &error 
				process: process];
	
		if(error != nil)
		{
			alertTitle = [NSString stringWithFormat: 
					@"Alert: %@", 
					[error domain]];
			NSRunAlertPanel(alertTitle, 
				[[error userInfo] objectForKey: NSLocalizedDescriptionKey], 
				@"Dismiss", 
				nil, 
				nil);
		}
	}
}

- (id) _retrieveControllerResults: (ULProcess*) process
{
	NSMutableDictionary* commandDict;
	NSError* error;
	NSString* alertTitle;
	id result;

	result = nil;
	if([[process valueForKey:@"processStatus"] isEqual: @"Running"])
	{
		commandDict = [NSMutableDictionary dictionary];
		[commandDict setObject: @"controllerResults"
			forKey: @"command"];
		result = [[ULProcessManager appProcessManager]  
				execute: commandDict 
				error: &error 
				process: process];
	
		if(error != nil)
		{
			alertTitle = [NSString stringWithFormat: 
					@"Alert: %@", 
					[error domain]];
			NSRunAlertPanel(alertTitle, 
				[[error userInfo] objectForKey: NSLocalizedDescriptionKey], 
				@"Dismiss", 
				nil, 
				nil);
		}
	}

	return result;
}

- (void) _loadObject: (id) object ofType: (NSString*) type
{
	NSEnumerator* dataEnum;
	id process, dataSet;
	
	process = nil;
	//if the object is a AdSimulationData we load up its data now
	//if its a ULProcess we flush its energies first
	if([type isEqual: @"AdSimulationData"])
		[self _loadSimulationData: object];
	else if([type isEqual: @"ULProcess"])
	{
		process = object;
		//extract the simulation data from the process
		[self _flushProcessEnergies: process];
		object = [process simulationData];
		type = @"AdSimulationData";
		[self _loadSimulationData: object];
	}	
	
	[self logString: [object description]];

	//Add the object to the loaded objects list
	[loadedObjects addObject: object];

	if(process != nil)
	{
		//check if there are any controller results
		//from the running simulation
		object = [self _retrieveControllerResults: process];
		NSDebugLLog(@"ULAnalyser", @"Controller results are %@", object);
		if(object != nil)
		{
			dataEnum = [object objectEnumerator];
			while(dataSet = [dataEnum nextObject])
				[loadedObjects addObject: dataSet];
		}		
	}
}

- (void) load: (id) sender
{
	NSString* type;
	NSArray* objects;
	NSEnumerator *availableTypeEnum, *objectEnum;
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];
	id object;
	
	availableTypeEnum = [[pasteboard availableTypes] objectEnumerator];
	while(type = [availableTypeEnum nextObject])
	{
		if([loadableTypes containsObject: type])
		{
			objects = [pasteboard objectsForType: type];
			objectEnum = [objects objectEnumerator];
			while(object = [objectEnum nextObject])
				[self _loadObject: object ofType: type];
		}
	}	
	//Update the loaded objects table
	[loadedObjectsTable reloadData];
}

- (void) remove: (id) sender
{
	NSEnumerator* selectedObjectsEnum;
	id object;

	selectedObjectsEnum = [selectedObjects objectEnumerator];
	while(object = [selectedObjectsEnum nextObject])
		[loadedObjects removeObject: object];
	
	[loadedObjectsTable reloadData];
	
	[selectedObjects removeAllObjects];
	[analysisManager removeAllInputObjects];
	if([loadedObjects count] > 0) 	
	{
		[loadedObjectsTable selectRowIndexes: 
			[NSIndexSet indexSetWithIndex: 0]
			byExtendingSelection: NO];
	}		
	[self updateAvailablePlugins];
	[self updatePluginOptions];
}

- (void) analyse: (id) sender
{
	[self load: self];
	[self open: self];
}

//Displays the selected data set
- (void) display: (id) sender
{
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];
	id object, type;

	//If we are not supplying the data then we must
	//load it first
	if([pasteboard changeCount] != checkCount)
	{
		[self load: self];
		object = [loadedObjects lastObject];
	}
	else
	{
		//we are supplying the data (we go through the
		//pasteboard anyway)
		type = [[pasteboard availableTypes] objectAtIndex: 0];
		object = [pasteboard objectForType: type];
	}

	[self openDataSet: object];
	[self selectDataSet: object];
	if(![window isKeyWindow])
		[self open: self];
}

//Only valid when the dataSet currently being displayed
//by ULAnalyserDataSetView is in pluginDataSets
- (void) save: (id) sender
{
	id dataSet, databaseInterface;
	AdModelObject *inputObject;
	NSEnumerator* resultsEnum, *inputObjectsEnum;
	
	//check there is an object available
	if(selectedDataSet == nil)
	{
		NSRunAlertPanel(@"Alert",
			@"No data available to be saved.",
			@"Dismiss", 
			nil,
			nil);
		return;
	}	
	
	//check if the object has already been saved
	databaseInterface = [ULDatabaseInterface databaseInterface];
	if(![databaseInterface objectInFileSystemDatabase: selectedDataSet])
	{	
		//Remove the files output for the data set.
		//We have to do this now since after returning from 
		//the properties panel the name will have changed
		//and removeGnuplotFilesForDataSet: won't remove the correct files.
		[self removeGnuplotFilesForDataSet: selectedDataSet];
	
		[[ULPropertiesPanel propertiesPanel]
			displayMetadataForModelObject: selectedDataSet
			allowEditing: YES
			runModal: YES];
		
		if([[ULPropertiesPanel propertiesPanel] result])
		{
			//The analysis manager saves the data set taking
			//care of all references
			[analysisManager saveOutputDataSet: selectedDataSet];
			
			//Reset the dataSet in the dataView and update the 
			//available data sets so the name change will be refelected
			[self setAvailableDataSets: openDataSets];
			[dataView setDataSet: selectedDataSet];
			[dataView displayData];
			[window makeKeyAndOrderFront: self];
			
			//Load the dataset into the loadedObjects table
			[loadedObjects addObject:selectedDataSet];
			[loadedObjectsTable reloadData];
		}
		
		//Regardless of whether the data set was saved we.
		//Use a thread since they may be very large.
		[NSThread detachNewThreadSelector: @selector(threadedCreateGnuplotFilesForDataSet:) 
					 toTarget: self 
				       withObject: selectedDataSet];
	}
	else
		NSRunAlertPanel(@"Error",
			@"Displayed data set already saved to database",
			@"Dismiss", 
			nil,
			nil);
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

//Handels return from exportDisplayedTable save panel.
- (void) savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	NSString* filename, *string;
	AdDataMatrix* matrix;
	
	if(returnCode == NSOKButton)
	{
		filename = [sheet filename];
		filename = [filename stringByDeletingPathExtension];
		filename = [filename stringByAppendingPathExtension: @"csv"];
		matrix = [dataView displayedMatrix];
		string = [matrix stringRepresentation];
		[string writeToFile: filename atomically: NO];
	}
}

- (void) exportDisplayedTable: (id) sender
{
	NSSavePanel* savePanel = [NSSavePanel savePanel];

	[savePanel beginSheetForDirectory:  nil
		file: nil 
		modalForWindow: window 
		modalDelegate: self 
		didEndSelector: @selector(savePanelDidEnd:returnCode:contextInfo:) 
		contextInfo: NULL];
}

- (void) deselectAllRows: (id) sender
{
	int row;
	id selectedRows;
	
	selectedRows = [loadedObjectsTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		[loadedObjectsTable deselectRow: row];
		row = [selectedRows indexGreaterThanIndex: row];
	}
	
	[loadedObjectsTable setNeedsDisplay: YES];
	[selectedObjects removeAllObjects];
	[analysisManager removeAllInputObjects];
	[self updateAvailablePlugins];
	[self updatePluginOptions];
} 

- (void) logString: (NSString*) string
{
	NSRange endRange;

	endRange.location = 0;
	endRange.length = 0;
	[resultsLog replaceCharactersInRange:endRange withString: 
		@"-------------------------------------------------------------------------\n"];
	endRange.location = 0;
	endRange.length = 0;
	[resultsLog replaceCharactersInRange:endRange withString: string];
}

//for loading pdbs
- (void) loadExternal: (NSString*) string
{
	int result;
	NSString* extension, *filename;
	NSArray* allowedFileTypes;
	NSMutableArray* filteredFiles;
	NSEnumerator* filenameEnum;
	MTStructure* structure;
	id fileBrowser;

	fileBrowser = [NSOpenPanel openPanel];
	[fileBrowser setTitle: @"Load External Object"];
	[fileBrowser setDirectory: 
		[[NSUserDefaults standardUserDefaults] 
			stringForKey:@"PDBDirectory"]];
	[fileBrowser setAllowsMultipleSelection: YES];
	allowedFileTypes = [NSArray arrayWithObjects: @"pdb", @"PDB", nil];
	result = [fileBrowser runModalForTypes: allowedFileTypes];
			
	/*
	 * Theres is a bug in runModalForTypes: (startup 0.18 and before) 
	 * that only filters the types for the selected directory
	 * and subsequent directories navigated to. Directories in the
	 * path to the pdb directory are not filtered. Hence its possible 
	 * that the user may select an incorrect filetype and we have to 
	 * check for this.
	 */
	if(result == NSOKButton)
	{
		filteredFiles = [NSMutableArray new];
		filenameEnum = [[fileBrowser filenames] objectEnumerator];
		while((filename = [filenameEnum nextObject]))
		{
			extension = [filename pathExtension];
			if(![allowedFileTypes containsObject: extension])
			{
				NSRunAlertPanel(@"Error", 
					[NSString stringWithFormat: 
						@"Unknown file type - %@\nSupported types %@", 
						extension, allowedFileTypes],
					@"Dismiss",
					nil,
					nil);
			}
			else
				[filteredFiles addObject: filename];
		}	
		
		//Load the files that passed the filter
		filenameEnum = [filteredFiles objectEnumerator];
		while((filename = [filenameEnum nextObject]))
		{
			//Ignore REMARK since some programs add data here that breaks the pdb format
			//Ignore COMPND and SOURCE - For some reason the MOL_ID entry in these sections
			//causes MolTalk to create a phantom extra chain (only for the first model however).
			//Parse all NMR models
			structure = [MTStructureFactory newStructureFromPDBFile: filename
					options: 256 + 1 + 16 + 32];
			[loadedObjects addObject: structure];
		}	

		[loadedObjectsTable reloadData];
		[filteredFiles release];
	}
}

/***************

Loaded Objects Table Data Source Methods

*****************/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [loadedObjects count];
}

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	id object;

	object = [loadedObjects objectAtIndex: rowIndex];
	if([[aTableColumn identifier] isEqual: @"dataType"])
		return [classMap objectForKey: NSStringFromClass([object class])];
	else	
	{
		if([object isKindOfClass: [AdModelObject class]])
			return [(AdModelObject*)object name];
		else
			return [object pdbcode] == nil ? @"Unknown" : [object pdbcode];
	}		
}

/***************

Loaded Objects Table Delegate Methods

*****************/

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification
{
	BOOL containsSimulationData;
	int row;
	id selectedRows, object;
	
	[selectedObjects removeAllObjects];
	[analysisManager removeAllInputObjects];
	selectedRows = [loadedObjectsTable selectedRowIndexes];
	if([selectedRows count] == 0)
		return;

	containsSimulationData = NO;
	row = [selectedRows firstIndex];
	while(row != NSNotFound)
	{
		object = [loadedObjects objectAtIndex: row];
		[selectedObjects addObject: object];
		[analysisManager addInputObject: object];
		//Enable the reload button on the toolbar if
		//a simulation has been selected.
		if([object isKindOfClass: [AdSimulationData class]])
			containsSimulationData = YES;

		row = [selectedRows indexGreaterThanIndex: row];
	}

	if(containsSimulationData)
		[reloadItem setEnabled: YES];
	else
		[reloadItem setEnabled: NO];
		
	[self updateAvailablePlugins];
	[self updatePluginOptions];
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

/***************

Window Delegate Methods

*****************/

- (void) windowDidResize: (NSNotification*) aNotification
{
	[optionsView sizeToFit];	
}

- (void) windowWillClose: (NSNotification*) aNotification
{
	[self close: self];
}

@end

/**
 Pasteboard Methods
 **/
@implementation ULAnalyser (PasteboardDataSource)

- (NSArray*) availableTypes
{
	NSString* type;
	
	if([selectedObjects count] > 0)
	{
		type = NSStringFromClass([[selectedObjects objectAtIndex: 0] class]);
		return [NSArray arrayWithObject: type];
	}	
	else
		return [NSArray array];
	
}

- (id) objectForType: (NSString*) type;
{
	if([[self availableTypes] containsObject: type])
		return [selectedObjects objectAtIndex: 0];
	else
		return nil;
}

- (NSArray*) objectsForType: (NSString*) type
{
	if([[self availableTypes] containsObject: type])
		return [NSArray arrayWithObject: [selectedObjects objectAtIndex: 0]];
	else
		return nil;	
}

- (int) countOfObjectsForType: (NSString*) type
{
	if([[self availableTypes] containsObject: type])
		return 1;
	else
		return 0;	
}

- (void) pasteboardChangedOwner: (id) pasteboard
{
	[self deselectAllRows: self];
}
@end

/**
 Contains methods for opening, selecting and closing
 the data sets displayed in the data set list 
 */
@implementation ULAnalyser (ULAnalyserDataSetOpening)

- (void) openDataSets: (NSArray*) anArray
{
	NSEnumerator* dataSetEnum;
	AdDataSet* dataSet;
	
	dataSetEnum = [anArray objectEnumerator]; 
	while(dataSet = [dataSetEnum nextObject])
		[self openDataSet: dataSet];
}

- (void) openDataSet: (AdDataSet*) aDataSet
{
	BOOL selectNewSet = NO;
	NSEnumerator* dataSetEnum;
	AdDataSet* set;
	
	if([openDataSets containsObject: aDataSet])
		return;
	
	//Check if any of the opened data sets has the same name. 
	//Only one data set with the same name can be open at the same time.
	if([dataSetList indexOfItemWithTitle: [aDataSet name]] != -1)
	{
		dataSetEnum = [openDataSets objectEnumerator];
		while(set = [dataSetEnum nextObject])
		{
			if([[set name] isEqual: [aDataSet name]])
				break;
		}
		//If this data set is displayed we want the new
		//one to replace it. Check if this is the case.
		if([dataView dataSet] == set)
			selectNewSet = YES;
		
		[self closeDataSet: set];
	}
	
	[openDataSets addObject: aDataSet];
	[self setAvailableDataSets: openDataSets];
	
	//Output the files in a dedicated thread.
	[NSThread detachNewThreadSelector: @selector(threadedCreateGnuplotFilesForDataSet:) 
				 toTarget: self 
			       withObject: aDataSet];
	
	//We only select the new set here if we
	//had to close one with the same name
	//while it was being displayed
	if(selectNewSet)
		[self selectDataSet: aDataSet];
}

- (void) closeSelectedDataSet: (id) sender
{
	[self closeDataSet: selectedDataSet];
}

- (void) closeDataSet: (AdDataSet*) aDataSet
{
	//The dataset may only be present in the openDataSets array.
	//If this is so then it will be deallocated when removed and the
	//program will crash during removeGnuplotFilesForDataSet:
	//Hence we retain/autorelease it here to prevent this.
	[[aDataSet retain] autorelease];
	if(![openDataSets containsObject: aDataSet])
		return;
	
	[openDataSets removeObject: aDataSet];
	[self setAvailableDataSets: openDataSets];
	[self removeGnuplotFilesForDataSet: aDataSet];
}

- (void) selectDataSet: (AdDataSet*) aDataSet
{
	if(![openDataSets containsObject: aDataSet])
		return;
	
	[dataSetList selectItemAtIndex: 
	 [openDataSets indexOfObject: aDataSet]];
	[self dataSetDidChange: self];	
}

- (void) setAvailableDataSets: (NSArray*) array
{
	NSEnumerator* arrayEnum;
	AdDataSet* dataSet;
	
	[dataSetList removeAllItems];
	arrayEnum = [array objectEnumerator];
	while(dataSet = [arrayEnum nextObject])
		[dataSetList addItemWithTitle: [dataSet name]];
	
	if([dataSetList numberOfItems] != 0)	
	{
		//If the last selected data set is in the new list
		//keep it selected. Otherwise select the first item.
		if([openDataSets containsObject: selectedDataSet])
		{
			[dataSetList selectItemAtIndex: 
			 [openDataSets indexOfObject: selectedDataSet]];
		}		
		else	
		{
			[dataSetList selectItemAtIndex: 0];
			[self dataSetDidChange: self];
		}	
		//Enable the close button
		[[[toolbar items] objectAtIndex: 3] setEnabled: YES];	
		//Enable the export buttonn
		[[[toolbar items] objectAtIndex: 4] setEnabled: YES];
		
	}
	else
	{		
		//Nothing is open so clear the view
		[dataView setDataSet: nil];
		[dataView clearDataSet];
		[selectedDataSet release];
		selectedDataSet = nil;
		[[[toolbar items] objectAtIndex: 3] setEnabled: NO];
		[[[toolbar items] objectAtIndex: 4] setEnabled: NO];	
	}
}

//Called when user selects a different data set
//from the data set list
- (void) dataSetDidChange: (id) sender
{
	NSString* name;
	NSEnumerator* dataSetEnum;
	AdDataSet* dataSet;
	
	name = [dataSetList titleOfSelectedItem];
	dataSetEnum = [openDataSets objectEnumerator];
	while(dataSet = [dataSetEnum nextObject])
		if([[dataSet name] isEqual: name])
		{
			[selectedDataSet release];
			selectedDataSet = dataSet;
			[selectedDataSet retain];
			[dataView setDataSet: selectedDataSet];
			[dataView displayData];
			break;
		}
}

@end

/**
Toolbar delegate methods
*/
@implementation ULAnalyser (NSToolbarDelegate)

- (NSToolbarItem*)toolbar: (NSToolbar*)toolbar
    itemForItemIdentifier: (NSString*)itemIdentifier
willBeInsertedIntoToolbar: (BOOL)flag
{
  NSToolbarItem *toolbarItem = AUTORELEASE([[NSToolbarItem alloc]
					     initWithItemIdentifier: itemIdentifier]);

	if([itemIdentifier isEqual: @"ApplyItem"])
	{
		[toolbarItem setLabel: @"Apply Plugin"];
		[toolbarItem setImage: applyImage];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(applyCurrentPlugin:)];     
		[toolbarItem setTag: 0];
		[toolbarItem setToolTip: @"Apply the current plugin to the selected data"];
	}
	else if([itemIdentifier isEqual: @"SaveItem"])
	{
		[toolbarItem setLabel: @"Save"];
		[toolbarItem setImage: saveImage];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(save:)];     
		[toolbarItem setTag: 1];
		[toolbarItem setToolTip: @"Save the currently displayed data set to the database"];
	}
	else if([itemIdentifier isEqual: @"ReloadItem"])
	{
		[toolbarItem setLabel: @"Reload"];
		[toolbarItem setImage: reloadImage];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(reloadSimulation:)];     
		[toolbarItem setEnabled: NO];
		[toolbarItem setTag: 2];
		[toolbarItem setToolTip: @"Reload the data for a running simulation"];
#if NeXT_Foundation_LIBRARY == 1		
		//Toolbar autovalidation not implemented on GNUstep (08/2007)
		[toolbarItem setAutovalidates: NO];
#endif		
		reloadItem = toolbarItem;
	}
	else if([itemIdentifier isEqual: @"CloseItem"])
	{
		[toolbarItem setLabel: @"Close"];
		[toolbarItem setImage: closeImage];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(closeSelectedDataSet:)]; 
		[toolbarItem setEnabled: NO];    
		[toolbarItem setTag: 3];
		[toolbarItem setToolTip: @"Close the currently displayed data set"];
#if NeXT_Foundation_LIBRARY == 1		
		//Toolbar autovalidation not implemented on GNUstep (08/2007)
		[toolbarItem setAutovalidates: NO];
#endif	
	}
	else if([itemIdentifier isEqual: @"ExportTable"])
	{
		[toolbarItem setLabel: @"Export Table"];
		[toolbarItem setImage: exportImage];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportDisplayedTable:)]; 
		[toolbarItem setEnabled: NO];    
		[toolbarItem setTag: 4];
		[toolbarItem setToolTip: @"Exports the currently displayed table as a comma separated value file"];
#if NeXT_Foundation_LIBRARY == 1		
		//Toolbar autovalidation not implemented on GNUstep (08/2007)
		[toolbarItem setAutovalidates: NO];
#endif	
	}	
	 
	return toolbarItem;
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects: @"ApplyItem", 
		  @"ReloadItem",
		  @"SaveItem",
		  @"CloseItem",
		  @"ExportTable",
		  nil];
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*)toolbar
{ 
  return [NSArray arrayWithObjects: @"ApplyItem", 
		  @"ReloadItem",
		  @"SaveItem", 
		  @"CloseItem",
		  @"ExportTable",
		  nil];
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{ 
	return nil;	  
}
@end
