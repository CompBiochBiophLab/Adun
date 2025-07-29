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

#include <AppKit/AppKit.h>
#include "ULSystemViewController.h"

@interface ULSystemViewController (PDBDownloadAdditions)
- (void) downloadPDB: (NSString*) pdbID;
@end

@implementation ULSystemViewController

/************************

Initialisation Methods

************************/

- (id) init
{
	if(self = [super init])
	{
		if([NSBundle loadNibNamed: @"System" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading system controller interface");
			return nil;
		}

		systemController = [ULSystemController new];
		metadataController = [ULPropertiesPanel propertiesPanel];
		allowedFileTypes = [[NSArray arrayWithObjects: @"PDB", @"pdb", nil] retain];
		isBuilding = NO;

		//register for some notifications from about the build process state

		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(handleNotification:)
			name: @"ULSystemBuildSectionCompleted"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(handleNotification:)
			name: @"ULSystemBuildWillStart"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(handleNotification:)
			name: @"ULSystemBuildDidAbortNotification"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(handleNotification:)
			name: @"ULSystemBuilderWillBeginInitialisationNotification"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(handleNotification:)
			name: @"ULSystemBuilderWillBeginInitialisationStepNotification"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(handleNotification:)
			name: @"ULSystemBuilderCompletedInitialisationStepNotification"
			object: nil];

		[tabView setDelegate: self];
		preprocessTabViewItem = [[tabView tabViewItemAtIndex: 0] retain];
		[systemWindow center];
		[systemWindow setDelegate: self];

	}

	return self;
}

- (void) dealloc
{
	[outlineDelegate release];
	[currentOptions release];
	[systemController release];
	[allowedFileTypes release];
	[super dealloc];
}

- (void) _insertString: (NSString*) string fontType: (NSString*) fontType
{
	NSRange fontRange, range;
	NSMutableAttributedString* boldString;
	NSFont* font;
	NSFontManager *fontManager = [NSFontManager sharedFontManager];

	font = [NSFont userFontOfSize: 12];
	if([fontType isEqual: @"Bold"])
		font = [fontManager convertFont: font toHaveTrait: NSBoldFontMask];

	range = NSMakeRange([[logView textStorage] length], 0);
	[[logView textStorage] replaceCharactersInRange: range withString: string];
	fontRange = NSMakeRange(range.location, [string length]);	
 	
	[[logView textStorage] beginEditing];
	[[logView textStorage] addAttribute: NSFontAttributeName value: font range: fontRange];
	[[logView textStorage] endEditing];
	[logView scrollRangeToVisible: NSMakeRange([[logView textStorage] length], 0)];
}

- (void) handleNotification: (NSNotification*) aNotification
{
	NSRange range;
	NSMutableString* buildInfo;

	[progressView display];
	[progressIndicator display];	
	[progressBar display];	

	if([[aNotification name] isEqual: @"ULSystemBuildWillStart"])
	{
		[progressBar setDoubleValue: 0.0];
		[progressIndicator setStringValue: @"Beginning Build"];
		NSDebugLLog(@"ULSystemViewController", @"Recieved %@", [aNotification name]);
	}
	else if([[aNotification name] isEqual: @"ULSystemBuildSectionCompleted"])
	{
		[progressBar incrementBy: 25];
		[progressIndicator setStringValue: [aNotification object]];
		NSDebugLLog(@"ULSystemViewController", @"Recieved %@", [aNotification name]);

		[self _insertString: [aNotification object] fontType: @"Bold"];
		buildInfo = [NSMutableString stringWithCapacity: 1];
		[buildInfo appendString: @"\n"];
		[buildInfo appendString: [[aNotification userInfo] 
				objectForKey: @"ULBuildSectionUserInfoKey"]];
		[buildInfo appendString: @"\n"];
		[self _insertString: buildInfo fontType: @"Normal"];
	}
	else if([[aNotification name] isEqual: @"ULSystemBuildDidAbortNotification"])
	{
		[progressIndicator setStringValue: 
			[NSString stringWithFormat: @"Build Aborted! - At position %@", [aNotification object]]];
	
		[self _insertString: [aNotification object] fontType: @"Bold"];

		buildInfo = [NSMutableString stringWithCapacity: 1];
		[buildInfo appendString: @"\n"];
		[buildInfo appendString: [[aNotification userInfo] 
				objectForKey: @"ULBuildSectionUserInfoKey"]];
		[buildInfo appendString: @"\n"];
		[self _insertString: buildInfo fontType: @"Normal"];
	}	
	else if([[aNotification name] isEqual: @"ULSystemBuilderWillBeginInitialisationNotification"])
	{
		[progressBar setDoubleValue: 0.0];
		[progressIndicator setStringValue: [aNotification object]]; 
	}
	else if([[aNotification name] isEqual: @"ULSystemBuilderCompletedInitialisationStepNotification"])
	{	
		[progressBar incrementBy: 50.0];
		[progressIndicator setStringValue: [aNotification object]]; 
	}
	else if([[aNotification name] isEqual: @"ULSystemBuilderWillBeginInitialisationStepNotification"])
	{
		[progressIndicator setStringValue: [aNotification object]]; 
	}
	
	[progressIndicator display];	
	[progressBar display];	
	[progressView display];
}

- (void) _setDelegateForOptions: (id) options
{
	[outlineDelegate release];
	outlineDelegate = [[ULOutlineViewDelegate alloc]
				initWithOptions: options];	
	[optionsView setDataSource: outlineDelegate];
	[optionsView setDelegate: outlineDelegate];
	[optionsView reloadData];
}

/*
 * Updating the force field
 */

- (void) forceFieldDidChange: (id) sender
{
	[systemController setForceField: 
		[forcefieldList titleOfSelectedItem]];
}

/*
 * Updating the plugin options
 */

- (void) pluginDidChange: (id) sender
{
	//Load the new plugin
	[[systemController systemBuilder]
		loadPreprocessPlugin: [pluginList titleOfSelectedItem]];

	//Update options
	[currentOptions release];
	currentOptions = [systemController preprocessOptions];
	[currentOptions retain];
	[self _setDelegateForOptions: currentOptions];
}

/*
 * Opening and closing the create system window
 */

//Called on loading a new molecule or opening a create system window.
//Updates the plugin list and loads the first plugin (if available).
- (void) _updatePluginList
{
	NSArray* plugins;

	plugins = [[systemController systemBuilder] availablePreprocessPlugins];
	[pluginList removeAllItems];

	if([plugins count] == 0)
	{
		[pluginList addItemWithTitle: @"None"];
		[pluginList selectItemWithTitle: @"None"];
	}
	else
	{
		[pluginList addItemsWithTitles: plugins];
		[pluginList selectItemAtIndex: 0];
		//load the selected plugin
		[[systemController systemBuilder]
			loadPreprocessPlugin: [pluginList titleOfSelectedItem]];
	
	}	
}

- (void) open: (id) sender
{
	NSRange range;
	NSString* defaultForceField;

	//if the window is already open do nothing
	//except bring it to the front if neccessary
	if([systemWindow isVisible])
	{
		if(![systemWindow isKeyWindow])
			[systemWindow makeKeyAndOrderFront: self];
		
		return;
	}

	[[logView textStorage] deleteCharactersInRange: 
		NSMakeRange(0, [[logView textStorage] length])];
	
	//Clear everything from previous build
	currentOptions = nil;
	[self _setDelegateForOptions: currentOptions];
	[systemController removeMolecule];

	[self _updatePluginList];	
	[forcefieldLabel setStringValue: @"Force Field"];
	[forcefieldList removeAllItems];
	[forcefieldList addItemsWithTitles: 
		[[systemController systemBuilder] 
			availableForceFields]];
	defaultForceField = [[NSUserDefaults standardUserDefaults]
				objectForKey: @"DefaultForceField"];
	[forcefieldList selectItemWithTitle: defaultForceField];
	[systemController setForceField: defaultForceField];

	[moleculePathField setStringValue: @""];
	[systemWindow setTitle: @"Create System"];
	[progressIndicator setStringValue: @""];
	[progressBar setDoubleValue: 0.0];
	[buttonOne setTitle: @"Create"];
	[systemWindow makeKeyAndOrderFront: self];
	[systemWindow setAutodisplay: YES];

	[buttonTwo setEnabled: NO];
	[buttonThree setEnabled: NO];
	
	if([tabView numberOfTabViewItems] == 1)
		[tabView insertTabViewItem: preprocessTabViewItem
			atIndex: 0];
	//removes some display problems with the inserted tab
	[tabView selectFirstTabViewItem: self];
	[tabView selectLastTabViewItem: self];
	[[tabView selectedTabViewItem] setLabel: @"Build"];
}

- (void) close: (id) sender
{
	[optionsView setDelegate: nil];
	[optionsView setDataSource: nil];
	[optionsView reloadData];
	[outlineDelegate release];
	outlineDelegate = nil;
	[currentOptions release];
	currentOptions =  nil;
	[moleculePathField setStringValue: @""];
	[systemController removeMolecule];
	[[logView textStorage] deleteCharactersInRange: 
		NSMakeRange(0, [[logView textStorage] length])];
} 

- (void) doButtonAction: (id) sender
{
	[self createSystem: sender];
}

- (void) doButtonThreeAction: (id) sender
{
	[self continueBuild];
}

- (void) doButtonTwoAction: (id) sender
{
	[self cancelBuild];
}

/************************

Creating a System

************************/

/*
Called when a user loads a pdb.
Writes out data on the pdb to the text-view of the create sytem window
*/
- (void) _outputInfoForPDBFile: (NSString*) filename
{
	MTStructure* structure;
	ULAnalysisManager* analysisManager;
	NSString* infoString;
	
	//Ignore REMARK since some programs add data here that breaks the pdb format
	//Ignore COMPND and SOURCE - For some reason the MOL_ID entry in these sections
	//causes MolTalk to create a phantom extra chain (only for the first model however).
	structure = [MTStructureFactory newStructureFromPDBFile: filename 
			options: 256 + 16 + 32];
	analysisManager = [ULAnalysisManager managerWithDefaultLocations];
	[analysisManager addInputObject: structure];
	if([[analysisManager pluginsForCurrentInputs] containsObject: @"PDBInfo"])
	{
		[analysisManager applyPlugin: @"PDBInfo"
			withOptions: nil
			error: NULL];
		infoString = [analysisManager outputString];
		if(infoString != nil)
		{	
			[self _insertString: @"PDB Summary\n\n" fontType: @"Bold"];
			[self _insertString: infoString fontType: @"Normal"];
		}
	}
}

- (void) getStructureFile: (id) sender
{
	NSString* fieldValue;

	fieldValue = [moleculePathField stringValue];
	if([fieldValue length] == 4)
	{
		[self downloadPDB: fieldValue];
	}
	else
	{
		[moleculePathField setStringValue: @""];
		[self showFileBrowser: self];
	}
}

- (void) loadStructureFile: (NSString*) fileName
{
	NSRange endRange;
	NSMutableString* failString;

	[[logView textStorage] deleteCharactersInRange: 
		NSMakeRange(0, [[logView textStorage] length])];
	
	endRange = NSMakeRange([[logView string] length], 0);
	failString = [NSMutableString string];
	NS_DURING
	{
		[systemController setBuildMolecule: fileName];
		[self _updatePluginList];
		
		//Output some information on the pdb
		[self _outputInfoForPDBFile: fileName];
		
		//Show the correct options depending on the selected tab.
		[currentOptions release];
		if([[[tabView selectedTabViewItem] label] isEqual: @"Build"])
			currentOptions = [systemController buildOptions];
		else
			currentOptions = [systemController preprocessOptions];
		
		[currentOptions retain];
		[self _setDelegateForOptions: currentOptions];
	}
	NS_HANDLER
	{
		failString = [NSMutableString stringWithCapacity: 1];
		[failString appendString: @"Failed to load molecule ...\n"];
		[failString appendString: [localException reason]];
		[failString appendString: @"\n"];	
		
		if([[localException name] isEqual: @"ULBuildException"])
		{
			[failString appendString: [[localException userInfo] 
					objectForKey:
				@"ULBuildRecoverySuggestionKey"]];
			[failString appendString: @"\n"];	
		}
		
		[logView replaceCharactersInRange: endRange withString: failString];
		NSRunAlertPanel(@"Load Molecule Failed", 
				[localException reason], 
				@"Dismiss", 
				nil, 
				nil);
	}
	NS_ENDHANDLER		
	
}

- (void) showFileBrowser: (id) sender
{
	id fileBrowser;
	int result;

	//if there is a current build prevent loading
	//another until it ends
	if(isBuilding)
	{
		NSRunAlertPanel(@"Alert",
			@"You must continue or cancel the current build!",
			@"Dismiss", 
			nil, 
			nil);

		return;
	}

	[progressBar setDoubleValue: 0.0];
	fileBrowser = [NSOpenPanel openPanel];
	[fileBrowser setTitle: @"Load PDB"];
	[fileBrowser setDirectory: [[NSUserDefaults standardUserDefaults] stringForKey:@"PDBDirectory"]];
	[fileBrowser setAllowsMultipleSelection: NO];
	result = [fileBrowser runModalForTypes: allowedFileTypes];
	if(result == NSOKButton)
	{	
		if([allowedFileTypes containsObject: [[fileBrowser filename] pathExtension]])
			[moleculePathField setStringValue: [fileBrowser filename]];
		else
			NSRunAlertPanel(@"Error", 
					[NSString stringWithFormat: @"Unknown file type - %@\nSupported types %@", 
						[[fileBrowser filename] pathExtension], allowedFileTypes],
					@"Dismiss",
					nil,
					nil);
		[self loadStructureFile: [fileBrowser filename]];
	}
}

- (void) _logBuildError: (NSError*) buildError
{
	NSMutableString* failString;
	NSString* recoveryString;

	[self _insertString: @"*****  Detected Build Errors  *****\n\n" fontType: @"Bold"];
	failString = [NSMutableString string];

	[failString appendString: @"\n"];
	[failString appendString: [[buildError userInfo] 
		objectForKey: @"ULBuildErrorDetailedDesciptionKey"]];
	[failString appendString: @"\n"];
	
	[self _insertString: failString fontType: @"Normal"];

	recoveryString = [[buildError userInfo] 
				objectForKey: @"ULBuildErrorRecoverySuggestionKey"];
	if(recoveryString != nil)
	{	
		[self _insertString: @"***** Recovery Suggestion *****\n\n" 
			fontType: @"Bold"];
		[failString deleteCharactersInRange: NSMakeRange(0, [failString length])];
		[failString appendFormat: @"%@\n", recoveryString];
		[self _insertString: failString fontType: @"Normal"];
	}
}

- (void) _logULBuildException: (NSException*) localException
{
	NSMutableString* failString;

	[self _insertString: @"*****  Build Failed  *****\n\n" fontType: @"Bold"];
			
	failString = [NSMutableString stringWithCapacity: 1];
	[failString appendString: [localException reason]];
	[failString appendString: @"\n"];

	if([[localException userInfo] objectForKey: @"ULBuildExceptionDetailedDescriptionKey"] != nil)	
	{
		[failString appendString: [[localException userInfo] 
				objectForKey: @"ULBuildExceptionDetailedDescriptionKey"]];
		[failString appendString: @"\n"];	
	}

	if([[localException userInfo] objectForKey: @"ULBuildRecoverySuggestionKey"] != nil)	
	{
		[failString appendString: [[localException userInfo] 
				objectForKey: @"ULBuildRecoverySuggestionKey"]];
		[failString appendString: @"\n"];	
	}
	[self _insertString: failString fontType: @"Normal"];
	NSRunAlertPanel(@"Build Failed", [localException reason], @"Dismiss", nil, nil);
}

- (void) _logUnexpectedBuildException: (NSException*) localException
{
	NSMutableString* failString;

	failString = [NSMutableString stringWithCapacity: 1];
	[self _insertString: @"*****  Unexpected Build Failure  *****\n\n" fontType: @"Bold"];
	[failString appendString: [localException reason]];
	[failString appendString: @"\n"];
	if([localException userInfo] != nil)	
		[failString appendString: [[localException userInfo] description]];
		
	[failString appendString: @"\n"];	
	[failString appendString: 
		@"Please file a support request with the pdb used attached and this build log "];
	[failString appendString: @"at the Adun Project Page:"];
	[failString appendString: @"\nhttp://gna.org/projects/adun\n"];
	[self _insertString: failString fontType: @"Normal"];
	NSRunAlertPanel(@"Unexpected build failure", 
				@"See log for details", 
				@"Dismiss",
				nil, 
				nil);
}

- (void) createSystem: (id)sender
{
	BOOL cancel = NO;
	BOOL result;
	NSString* filePath;
	NSString* output;
	NSMutableString* failString;
	NSError* buildError;
	int choice;

	/*
	 * isBuilding is set to yes until the build
	 * A) Completes
	 * B) raises an exception 
	 * C) is canceled by the user
	 */

	isBuilding = YES;

	NS_DURING
	{	
		[[logView textStorage] deleteCharactersInRange: 
			NSMakeRange(0, [[logView textStorage] length])];

		[self _insertString: @"*****  Beginning Build  *****\n\n" fontType: @"Bold"];
		if(currentOptions == nil)
			[NSException raise: @"ULBuildException"
				format: @"No molecule has been loaded"];

		buildError = nil;
		if(![systemController buildSystemWithOptions: currentOptions error: &buildError])
		{
			failString = [NSMutableString string];
			[failString appendString:[[buildError userInfo] 
				objectForKey: NSLocalizedDescriptionKey]];
			[failString appendString: @"\n\n ** Check the log window for more details. **\n\n"];
			[failString appendString: @"Choose 'Continue' to ignore the errors "];
			[failString appendString: @" or 'Cancel' to abort."];
			[self _logBuildError: buildError];
			NSRunAlertPanel(@"Build Error",
				failString,
				@"Dismiss",
				nil,
				nil);	
			[buttonOne setEnabled: NO];
			[buttonTwo setEnabled: YES];
			[buttonThree setEnabled: YES];
		}
		else
		{
			[progressIndicator setStringValue: @"Complete"];
			[metadataController displayMetadataForModelObject: [systemController valueForKey:@"system"]
				allowEditing: YES
				runModal: YES];
			result = [metadataController result];	
		
			[self _insertString: @"*****  Build Complete  *****\n" fontType: @"Bold"];
			if(result)
				[systemController saveSystem];

			[systemWindow orderFront: self];

			isBuilding = NO;
		}
	}
	NS_HANDLER
	{	
		isBuilding = NO;

		if([[localException name] isEqual: @"ULBuildException"])
			[self _logULBuildException: localException];
		else
			[self _logUnexpectedBuildException: localException];
	}
	NS_ENDHANDLER
}

- (void) continueBuild
{
	BOOL result;
	NSError* buildError;
	NSMutableString* failString;

	NS_DURING
	{
		[self _insertString: @"Resuming build - ignoring previous errors.\n\n"
			fontType: @"Bold"];
		buildError = nil;
		if(![systemController resumeBuild: currentOptions error: &buildError])	
		{
			[self _logBuildError: buildError];
			failString = [NSMutableString stringWithCapacity: 1];
			[failString appendString:[[buildError userInfo] 
				objectForKey: NSLocalizedDescriptionKey]];
			[failString appendString: @"\nCheck the log window for more details.\n\n"];
			[failString appendString: @"Choose 'Continue' to ignore the errors "];
			[failString appendString: @" or 'Cancel' to abort."];
			NSRunAlertPanel(@"Build Error",
				failString,
				@"Dismiss",
				nil,
				nil);	
		}	
		else
		{
			[progressIndicator setStringValue: @"Complete"];
			[metadataController displayMetadataForModelObject: [systemController valueForKey:@"system"]
				allowEditing: YES
				runModal: YES];
			result = [metadataController result];	
				
			[self _insertString: @"*****  Build Complete  *****\n" fontType: @"Bold"];
			if(result)
				[systemController saveSystem];

			[systemWindow orderFront: self];
			[buttonOne setEnabled: YES];
			[buttonTwo setEnabled: NO];
			[buttonThree setEnabled: NO];
			isBuilding = NO;
		}
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: @"ULBuildException"])
			[self _logULBuildException: localException];
		else
			[self _logUnexpectedBuildException: localException];
			
		[buttonOne setEnabled: YES];
		[buttonTwo setEnabled: NO];
		[buttonThree setEnabled: NO];
		isBuilding = NO;
	}
	NS_ENDHANDLER
}

- (void) cancelBuild
{
	NSMutableString* failString;

	[self _insertString: @"*****  Build Canceled  *****\n\n" fontType: @"Bold"];
	failString = [NSMutableString stringWithCapacity: 1];
	[failString appendString: @"User canceled build due to above errors."];
	[failString appendString: @"\n"];
	[self _insertString: failString fontType: @"Normal"];
	[progressIndicator setStringValue: 
	[NSString stringWithFormat: @"Build Canceled"]];
	[buttonOne setEnabled: YES];
	[buttonTwo setEnabled: NO];
	[buttonThree setEnabled: NO];
	[systemController cancelBuild];
	isBuilding = NO;
}

/*
 * Applying the plugin
 */

- (void) applyPlugin: (id) sender
{
	[[logView textStorage] deleteCharactersInRange: 
		NSMakeRange(0, [[logView textStorage] length])];
	[self _insertString: [NSString stringWithFormat: 
			@"***** Applying Preprocess Plugin - %@ *****\n\n", 
			[pluginList titleOfSelectedItem]]
		fontType: @"Bold"];
	[[systemController systemBuilder]
		applyPreprocessPlugin: currentOptions];
	[self _insertString: [[systemController systemBuilder]
				preprocessOutputString]
		fontType: nil];			
	[self _insertString: @"\n***** Complete *****\n"
		fontType: @"Bold"];
}

/*
 * Save the current structure
 */

- (void) saveStructure: (id) sender
{
	int result;
	NSString* currentPath, *filename;
	NSSavePanel* savePanel;

	currentPath = [[systemController systemBuilder]
			buildMolecule];
	if(currentPath != nil)
	{
		savePanel = [NSSavePanel savePanel];	
		[savePanel setTitle: @"Save Structure"];
		[savePanel setDirectory: 
			[[NSUserDefaults standardUserDefaults]
				objectForKey: @"PDBDirectory"]];
		result = [savePanel runModal];
		filename = [savePanel filename];

		if(result == NSOKButton)
			[[systemController systemBuilder]
				writeStructureToFile: filename];
	}
	else
		NSRunAlertPanel(@"Alert",
			@"No molecule has been loaded.",
			@"Dismiss", 
			nil, 
			nil);
}

/******************

Tabview Delegate methods

********************/

- (void)tabView: (NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	id holder;

	holder = currentOptions;

	if([[tabViewItem label] isEqual: @"Preprocess"])
		currentOptions = [systemController preprocessOptions];
	else
		currentOptions = [systemController buildOptions];
		
	[currentOptions retain];
	[holder release];
	[self _setDelegateForOptions: currentOptions];
}

- (BOOL) tabView: (NSTabView *) tabView shouldSelectTabViewItem: (NSTabViewItem*) tabViewItem
{
	if(isBuilding)
	{
		NSRunAlertPanel(@"Alert",
			@"You must continue or cancel the current build!",
			@"Dismiss", 
			nil, 
			nil);
		
		return NO;
	}

	return YES;
}

/******************

Window Delegate Methods

*******************/

- (void) windowWillClose: (NSNotification*) aNotification
{
	[self close: self];
	[systemWindow orderOut:self];
}

- (BOOL) windowShouldClose: (id) sender
{
	if(isBuilding)
	{
		NSRunAlertPanel(@"Alert",
			@"You must continue or cancel the current build!",
			@"Dismiss", 
			nil, 
			nil);
		
		return NO;
	}
	
	return YES;
}

@end

@implementation ULSystemViewController (PDBDownloadAdditions)

- (void) downloadPDB: (NSString*) pdbID
{
	NSError* error;

	//Create a download connection
	urlDownload = [ULURLDownload downloadForPDB: pdbID];
	[urlDownload retain];
	
	//Register for download end notification
	[[NSNotificationCenter defaultCenter]
		addObserver: self 
		selector: @selector(downloadFinished) 
		name: ULURLDownloadDidEndNotification
		object: urlDownload];
	
	//Create and run a progress panel
	progressPanel = [[ULProgressPanel alloc] initWithTitle: @"Downloading" 
				message:  [NSString stringWithFormat: @"Downloading %@.pdb", pdbID]
				progressInfo: @"Waiting to connect ..."];
	
	[progressPanel updateStatusOnNotification: ULURLDownloadStatusNotification 
		fromObject: urlDownload];
	[progressPanel runProgressPanel: NO];
	
	//Start the download
	if(![urlDownload beginDownloadToFile: nil overwrite: YES])
	{
		//Handle error
		[progressPanel endPanel];
		[progressPanel release];
		error = [urlDownload downloadError];
		ULRunErrorPanel(error);
		[urlDownload release];
		urlDownload = nil;
		[moleculePathField setStringValue: @""];
	}
	else
	{
		//Lock the text field and load button
		[loadButton setEnabled: NO];
		[moleculePathField setSelectable: NO];
	}
}

- (void) downloadFinished
{
	BOOL deleteFile;
	NSData* data;
	NSString* filename;
	NSError* error;

	//Let the panel linger briefly
	[progressPanel orderFront];
	sleep(1.0);
	[progressPanel endPanel];
	[progressPanel release];

	//Check the result
	if((error = [urlDownload downloadError]) == nil)
	{
		filename = [urlDownload filename];
		//Check it ends in pdb - otherwise no pdb was downloaded
		if(![[filename pathExtension] isEqual: @"pdb"])
		{
			NSLog(@"Error downloading pdb");
			NSLog(@"URL %@", [urlDownload URL]);
			NSLog(@"See the file %@ for what was retrieved", filename);
			error = AdCreateError(ULFrameworkErrorDomain,
					10,
					@"Download Error",
					@"Retrieved data does not correspond to a pdb structure",
					@"Check UL.log for more information");
			ULRunErrorPanel(error);	
			[moleculePathField setStringValue: @""];	
		}
		else
		{
			//Load the file then delete it (if asked)
			[self loadStructureFile: filename];
			deleteFile = [[NSUserDefaults standardUserDefaults]
					boolForKey: @"DeleteDownloadedPDBs"];
			if(deleteFile)		
				[[NSFileManager defaultManager]
					removeFileAtPath: filename handler: NULL];
					
			//Trick so hitting load will open the file browser 
			//instead of restarting the same download.
			[moleculePathField setStringValue: [filename lastPathComponent]];	
		}
	}
	else
	{
		ULRunErrorPanel(error);
		[moleculePathField setStringValue: @""];
	}
		
	//Clean up
	[[NSNotificationCenter defaultCenter] 
		removeObserver: self 
			  name: ULURLDownloadDidEndNotification
			object: urlDownload];
	[urlDownload release];
	urlDownload = nil;
	[loadButton setEnabled: YES];
	[moleculePathField setSelectable: YES];	
	[moleculePathField setEditable: YES];	
}

@end


