#include "ULAnalyser.h"

@implementation ULAnalyser (ULAnalyserPluginExtensions)

- (void) updateAvailablePlugins
{
	NSArray* availablePlugins;

	availablePlugins = [analysisManager pluginsForCurrentInputs];
	[pluginList removeAllItems];
	[pluginList addItemsWithTitles: availablePlugins];
	//If the last selected plugin is still in the list select
	//it. Otherwise select the first available one.
	//If there are no available plugins we show "None".

	NSDebugLLog(@"ULAnalyser", @"Available plugins %@", availablePlugins);
	
	if([availablePlugins containsObject: selectedPlugin])
		[pluginList selectItemWithTitle: selectedPlugin];
	else if([availablePlugins count] == 0)
	{
		[selectedPlugin release];
		selectedPlugin = [@"None" retain];
		[pluginList addItemWithTitle: @"None"];
		[pluginList selectItemWithTitle: selectedPlugin];
	}
	else
	{
		[pluginList selectItemAtIndex: 0];
		[selectedPlugin release];
		selectedPlugin = [pluginList titleOfSelectedItem];
		[selectedPlugin retain];
	}	
}

//Displays save panels for the files returned by a plugin
- (void) _displayPluginFiles: (NSArray*) pluginFiles
{
	int returnCode;
	NSEnumerator* dataEnum;
	NSDictionary* fileData;
	NSString* fileDescription, *filename;
	NSSavePanel* savePanel;
	id fileContents;
	
	dataEnum = [pluginFiles objectEnumerator];
	while(fileData = [dataEnum nextObject])
	{
		fileContents = [fileData objectForKey: @"ULAnalysisPluginFileContents"];
		fileDescription = [fileData objectForKey: @"ULAnalysisPluginFileDescription"];
		if([fileContents respondsToSelector: @selector(writeToFile:atomically:)])
		{
			savePanel = [NSSavePanel savePanel];
			if(fileDescription == nil)
				fileDescription = @"No description provided";	
				
			[savePanel setMessage: fileDescription];	
			[savePanel setTitle: @"Save Plugin Results File"];
			returnCode = [savePanel runModalForDirectory: nil file: nil];
			if(returnCode == NSOKButton)
			{	
				filename = [savePanel filename];
				[fileContents writeToFile: filename atomically: NO];
			}
		}
		else
			NSRunAlertPanel(@"Invalid content object - cannot write to file", 
				@"File content objects returned by plugins must implement writeToFile:atomically:",
				@"Dismiss",
				nil, nil);
	}
}

/******************

Displaying Plugin Options

******************/

- (void) updatePluginOptions
{
	[self displayOptionsForPlugin];
}

- (void) pluginChanged: (id) sender
{
	NSDebugLLog(@"ULAnalyser", @"Plugin changed to %@", 
			 [pluginList titleOfSelectedItem]);

	if(![selectedPlugin isEqual: [pluginList titleOfSelectedItem]])
	{
		[selectedPlugin release];
		selectedPlugin = [[pluginList titleOfSelectedItem] retain];
		[self displayOptionsForPlugin];
	}
}

- (void) displayOptionsForPlugin
{
	if([analysisManager containsInputObjects] == YES && 
		![[pluginList titleOfSelectedItem] isEqual: @"None"])
	{
		[currentOptions release];
		NS_DURING
		{
			currentOptions = [analysisManager optionsForPlugin: 
						[pluginList titleOfSelectedItem]];
		}
		NS_HANDLER
		{
			NSRunAlertPanel(@"Alert",
				[localException reason],
				@"Dismiss", 
				nil,
			nil);
		}
		NS_ENDHANDLER

		NSDebugLLog(@"ULAnalyser", @"New options %@ - %@", currentOptions, selectedPlugin);

		[currentOptions retain];
		[outlineDelegate release];
		outlineDelegate  = [[ULOutlineViewDelegate alloc]
					initWithOptions: currentOptions];
		[optionsView setDataSource: outlineDelegate];
		[optionsView setDelegate: outlineDelegate];
		[optionsView reloadData];
	}
	else if([[pluginList titleOfSelectedItem] isEqual: @"None"])
	{
		[currentOptions release];
		currentOptions = nil;
		[outlineDelegate release];
		outlineDelegate  = [[ULOutlineViewDelegate alloc]
					initWithOptions: currentOptions];
		[optionsView setDataSource: outlineDelegate];
		[optionsView setDelegate: outlineDelegate];
		[optionsView reloadData];
	}
}


/***************

Applying the current plugin

****************/

- (void) _forwardPluginNotification: (NSNotification*) aNotification
{
	NSNotification* newNotification;

	if([aNotification object] != self)
	{
		/*
		 * Sequenece of events here deserves explanation. The thing to 
		 * remember is the progress panel object and this object 
		 * i.e. ULAnalyser are accessible from both threads.
		 * 1) The thread applying the current plugin receives a notification 
		 * and this method is called (in that thread) since we registered for it
		 * in the method below - N.B Notifications are always delivered in 
		 * the thread they are sentry.
		 * 2) We want the progress panel to get this notification - or one like it 
		 * - but from the main thread NOT from this thread. This is because 
		 * the gui is not thread safe.
 		 * 3) We stop the progress panel getting this exact notification by setting
		 * it to look for a different notifcation object i.e. The object of this 
		 * notification is nil while the object the progress panel needs is this one.
		 * 4) We create a new notification with the same name but with self as the object
		 * 5) We post the notification on the main thread using 
		 * performSelectorOnMainThread:withObject:waitUntilDone:
		 * 6) The progress panel recieves the notification from the main thread. 
		 * However there is one last twist. 
		 * 7) Since below we registered this object for the same notification name 
		 * with a nil object this method will get called again but this time on 
		 * the main thread! We dont want to get caught in an infinite loop so the "if"
		 * statement above identifies if this is the original notification or the new one.
		 */

		newNotification = [NSNotification notificationWithName: [aNotification name]
			object: self
			userInfo: [aNotification userInfo]];

		[[NSNotificationCenter defaultCenter]
			performSelectorOnMainThread: @selector(postNotification:)
			withObject: newNotification
			waitUntilDone: NO];
	}
}

- (void) _threadedApplyCurrentPlugin
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	id holder;

	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(_forwardPluginNotification:)
		name: @"ULAnalysisPluginDidCompleteStepNotification"
		object: nil];

	NS_DURING
	{
		holder = pluginResults;
		NSDebugLLog(@"ULAnalyser", @"Applying plugin");
		NSDebugLLog(@"ULAnalyser", @"Options %@", currentOptions);
		pluginResults = [analysisManager applyPlugin: [pluginList titleOfSelectedItem]
					withOptions: currentOptions
					error: &pluginError];
		
		[pluginError retain];	
		[pluginResults retain];
		[holder release];

		NSDebugLLog(@"ULAnalyser", @"Plugin analysis completed");

		[progressPanel performSelectorOnMainThread: @selector(setProgressInfo:)
			withObject: @"Complete"
			waitUntilDone: NO];
		[progressPanel performSelectorOnMainThread: @selector(setProgressBarValue:)
			withObject: [NSNumber numberWithDouble: 100.0]
			waitUntilDone: YES];
		sleep(1);
		[progressPanel performSelectorOnMainThread: @selector(endPanel)
			withObject: nil
			waitUntilDone: NO];

		[[NSNotificationCenter defaultCenter] removeObserver: self
			name: @"ULAnalysisPluginDidCompleteStepNotification"
			object: nil];
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

- (void) applyCurrentPlugin: (id) sender
{
	NSString* pluginString;
	NSArray* pluginFiles;
	id holder, anArray;

	NSDebugLLog(@"ULAnalyser",
		@"Applying plugin %@", [pluginList titleOfSelectedItem]);

	//Clear any error from the last run.
	[pluginError release];
	pluginError == nil;
	pluginString = nil;

	//We dont thread energy converter since its very fast.
	if([[pluginList titleOfSelectedItem] isEqual: @"EnergyConverter"])
	{
		holder = pluginResults;
		NS_DURING
		{
			pluginResults = [analysisManager applyPlugin: @"EnergyConverter"
						withOptions: currentOptions
						error: NULL];
			[pluginResults retain];
			[holder release];
		}
		NS_HANDLER
		{
			NSWarnLog(@"Caught plugin exception %@, %@, %@", 
				[localException name], 
				[localException reason],
				[localException userInfo]);	
			NSRunAlertPanel(@"Error",
				[localException reason],
				@"Dismiss", 
				nil,
				nil);
		}
		NS_ENDHANDLER
	}
	else if([[pluginList titleOfSelectedItem] isEqual: @"None"])
	{
		NSRunAlertPanel(@"Alert",
			@"No plugin has been selected",
			@"Dismiss",
			nil,
			nil);
	}
	else
	{
		NSDebugLLog(@"ULAnalyser", @"Creating progress panel");
		progressPanel = [ULProgressPanel progressPanelWithTitle: @"Progress Panel"
					message: @"Processing"
					progressInfo: @"Applying Plugin ..."];
		[progressPanel setPanelTitle: [NSString stringWithFormat:
						 @"Progress - %@", [pluginList titleOfSelectedItem]]];
		[progressPanel setProgressBarValue: [NSNumber numberWithDouble: 0.0]];
		[progressPanel updateStatusOnNotification: @"ULAnalysisPluginDidCompleteStepNotification"
			fromObject: self];

		//detach the thread and wait

		NSDebugLLog(@"ULAnalyser", @"Detaching thread");
		threadError = NO;
		[NSThread detachNewThreadSelector: @selector(_threadedApplyCurrentPlugin)
			toTarget: self
			withObject: nil];

		NSDebugLLog(@"ULAnalyser", @"Running panel");
		[progressPanel runProgressPanel: YES];
		NSDebugLLog(@"ULAnalyser", @"Complete");

		//check if there were errors
		//If there was an error pluginResults will either be the same
		//as before or nil. If there was no error we check the returned
		//object is valid.
		if(!threadError)
		{
			//plugin results is retained in the thread above
			if(![pluginResults isKindOfClass: [NSDictionary class]])
			{
				NSRunAlertPanel(@"Alert",
					@"Plugin returned invalid object",
					@"Dismiss",
					nil,
					nil);
				
				[pluginResults release];
				pluginResults = nil;
			}
		}	

		[progressPanel removeStatusNotification: @"ULAnalysisPluginDidCompleteStepNotification"
			fromObject: self];
	}

	//Check if an error object was returned
	if(pluginError == nil)
	{
		NSDebugLLog(@"ULAnalyser", @"Retrieving plugin results");
		pluginString = [pluginResults objectForKey: @"ULAnalysisPluginString"];
		pluginFiles = [pluginResults objectForKey: @"ULAnalysisPluginFiles"];
		if((anArray = [pluginResults objectForKey: @"ULAnalysisPluginDataSets"]) != nil)
		{
			//populate the data set list with names
			[pluginDataSets release];
			pluginDataSets = [anArray retain];
			[self openDataSets: pluginDataSets];
			[self selectDataSet: [pluginDataSets objectAtIndex: 0]];
		}	
		else
		{
			[pluginDataSets release];
			pluginDataSets = nil;
		}	
		
		if(pluginFiles != nil)
			[self _displayPluginFiles: pluginFiles];
		
		if(pluginString != nil)
			[self logString: [NSString stringWithFormat: 
				@"Analysis Plugin - %@.\n\n%@\n", 
				[pluginList titleOfSelectedItem], 
				pluginString]];		
	}
	else
		ULRunErrorPanel(pluginError);
}

@end

