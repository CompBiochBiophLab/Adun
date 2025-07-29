/* 
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 13:29:49 +0200 by michael johnston
   
   Application Controller

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

#include "ViewController.h"

@implementation ViewController

- (void) _makeSplashScreen
{
	NSRect mainScreenFrame;
	NSPoint mainScreenCenter;
	NSSize splashContentSize;
	NSRect splashWindowContentRect;
	NSImage* splashImage;

	splashImage = [[NSImage alloc] initWithContentsOfFile: 
			[[[NSBundle mainBundle] resourcePath]
				stringByAppendingPathComponent: @"splash.tiff"]];
	splashContentSize = [splashImage size];
	
	mainScreenFrame = [statusWindow frame];
	mainScreenCenter = NSMakePoint(mainScreenFrame.origin.x + mainScreenFrame.size.width/2, 
				mainScreenFrame.origin.y + mainScreenFrame.size.height/2);
#if NeXT_Foundation_LIBRARY
	//On  OSX the splash image size is half what it is on gnustep
	//making the screen very small. Hence we double the dimensions of this
	//NSSize struct which is used to set the size of the splash screen.
	//Im assuming this is due to a difference in the implementation of NSImageView
	splashContentSize.width *=2;
	splashContentSize.height *= 2;
#endif	
	splashWindowContentRect.size = splashContentSize;
	splashWindowContentRect.origin.x = mainScreenCenter.x - splashContentSize.width/2;
	splashWindowContentRect.origin.y = mainScreenCenter.y - splashContentSize.height/2;

	splashScreen = [[NSWindow alloc] initWithContentRect: splashWindowContentRect
				styleMask: NSBorderlessWindowMask
				backing: NSBackingStoreRetained
				defer: NO];

	splashScreenImageView = [[NSImageView alloc] init];
	[splashScreenImageView setImageScaling: NSScaleToFit];
	[splashScreenImageView setImage: splashImage];
	[(NSWindow*)splashScreen setContentView: splashScreenImageView];
	[splashScreen setLevel: NSFloatingWindowLevel];
	[splashScreen setOpaque: NO];

	[splashScreen makeKeyAndOrderFront: self];
}

+ (void)initialize
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	id debugLevels;

	[defaults setObject: NSHomeDirectory()  forKey:@"PDBDirectory"];
	[defaults setObject: [NSNumber numberWithBool: NO]
		forKey: @"AutomaticallyStartWaitingProcesses"];
#ifdef GNUSTEP	
	[defaults setObject: [NSHomeDirectory() stringByAppendingPathComponent: @"adun/UL.log"]
		forKey: @"LogFile"];
	[defaults setObject: @"gedit" forKey: @"Editor"];
#else	
	[defaults setObject: [NSHomeDirectory() stringByAppendingPathComponent: @".adun/UL.log"]
		     forKey: @"LogFile"];
	//On Mac we install the server package into /usr/local/bin during a real install
	[defaults setObject: @"/usr/local/bin" forKey: @"AdunServerPath"];
	//FIXME: Temporary
	[defaults setObject: [NSNumber numberWithBool: NO]
		     forKey: @"Setup"];	
#endif		     	
	[defaults setObject: [NSNumber numberWithDouble: 300] forKey: @"AutoUpdateInterval"];
	[defaults setObject: [NSNumber numberWithBool: YES] forKey: @"AutoUpdate"];
	[defaults setObject: [NSNumber numberWithBool: YES] forKey: @"CreateUnmodifiedPDBStructures"];
	[defaults setObject: [NSArray array] forKey: @"DebugLevels"];
	[defaults setObject: @"/usr/bin/gnuplot" forKey: @"GnuplotPath"];
	[defaults setObject: [NSNumber numberWithBool: YES] forKey: @"DeleteDownloadedPDBs"];
	debugLevels = [[NSProcessInfo processInfo] debugSet];
	[debugLevels addObjectsFromArray: [[NSUserDefaults standardUserDefaults] 
		objectForKey: @"DebugLevels"]];

	NSDebugLLog(@"ViewController", @"Defaults %@", defaults);

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) _isAvailableApplicationScriptingBundle
{
	NSBundle *appScriptingBundle;

#ifndef GNUSTEP	
	appScriptingBundle = [NSBundle bundleWithPath: 
				[NSHomeDirectory() stringByAppendingPathComponent:
				@"Library/Bundles/ULApplicationScripting.bundle"]];
#else
	
	appScriptingBundle = [NSBundle bundleWithPath: 
				[NSHomeDirectory() stringByAppendingPathComponent:
				@"GNUstep/Library/Bundles/ULApplicationScripting.bundle"]];
#endif				
	if(appScriptingBundle == nil)
	{
		NSWarnLog(@"Application scripting disabled");
		return NO;
	}	
	else
	{
		NSWarnLog(@"Application scripting enabled");
		return YES;
	}	
}

- (void) _loadApplicationScriptingBundle
{
	NSBundle *appScriptingBundle;

#ifndef GNUSTEP	
	appScriptingBundle = [NSBundle bundleWithPath: 
		[NSHomeDirectory() stringByAppendingPathComponent:
			@"Library/Bundles/ULApplicationScripting.bundle"]];
#else
	
	appScriptingBundle = [NSBundle bundleWithPath: 
		[NSHomeDirectory() stringByAppendingPathComponent:
			@"GNUstep/Library/Bundles/ULApplicationScripting.bundle"]];
#endif

	if((ULScriptManager = [appScriptingBundle principalClass]))
		NSDebugLLog(@"ULDatabaseInterface", @"Found application scripting bundle.\n");
	else
		[NSException raise: NSInternalInconsistencyException 
			format: @"Application scripting bundle missing principal class"];
}

- (id)init
{
	id logFile;
	id icon;
	id array;

	if((self = [super init]))
	{
	
#ifndef GNUSTEP
		//Temporary code to ease install on OSX
		if([[NSUserDefaults standardUserDefaults] boolForKey: @"Setup"])
		{
			id ioManager;
			ioManager = [ULIOManager appIOManager];
			exit(0);
		}
#endif		
	
		//redirect output

		logFile = [[NSUserDefaults standardUserDefaults] stringForKey: @"LogFile"];
		if(![[NSFileManager defaultManager] isWritableFileAtPath: 
			[logFile stringByDeletingLastPathComponent]])
		{
			logFile = [[[NSUserDefaults standardUserDefaults] 
					volatileDomainForName: NSRegistrationDomain]
					valueForKey:@"LogFile"];
			NSWarnLog(@"Invalid value for user default 'LogFile'.");
			NSWarnLog(@"The specificed directory is not writable");
			NSWarnLog(@"Switching to registered default %@", logFile);
		} 

		freopen([logFile cString], "w", stderr);

		//the methods to be forwarded to the 
		//active delegate.
		objectActions = [[NSArray alloc] initWithObjects:
					@"cut:",
					@"copy:",
					@"paste:",
					@"remove:",
					@"export:",
					@"exportAs:",
					@"import:",
					@"deselectAllRows:",
					nil];

		//simulation commands
		simulationCommands = [[NSArray alloc] initWithObjects:
					@"halt:",
					@"terminateProcess:",
					@"execute:",
					@"start:",
					@"restart:",
					nil]; 

		allowedActions = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: 
				@"start:", 
				@"remove:",
				@"display:",
				nil];
		[allowedActions setObject: array forKey: @"Waiting"];
		array = [NSArray arrayWithObjects: 
				@"halt:", 
				@"execute:",
				@"terminateProcess:",
				nil];
		[allowedActions setObject: array forKey: @"Running"];
		array = [NSArray arrayWithObjects: 
				@"restart:", 
				@"terminateProcess:",
				nil];
		[allowedActions setObject: array forKey: @"Suspended"];
		array = [NSArray arrayWithObject: 
				@"remove:"]; 
		[allowedActions setObject: array forKey: @"Finished"];

		//create the pasteboard 
		appPasteboard = [ULPasteboard new];
	}

	NSDebugLLog(@"ViewController", @"Completed initialisation");	

	return self;
}

- (void) awakeFromNib
{
	NSString* welcomeString;
	NSMenu* mainMenu;
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	id item, columns, ioManager;

	[statusWindow center];
	[self _makeSplashScreen];

	//This doesnt work on Mac
	[[NSApp mainMenu] setTitle:@"Adun"];
	//FIXME: Check if any object assumes this has
	//been created and performed certain tasks e.g. directory creation
	//without aquiring a reference to it. We shouldn't have to
	//create it here but in case the above is true we have
	//to make sure it has been initialised before anything
	//else is done.
	ioManager = [ULIOManager appIOManager];

	//FIXME: Decouple ULAnalyser and ULPreferences from ViewController.
	analyser = [[ULAnalyser alloc] initWithModelViewController: self];
	preferencesPanel = [[ULPreferences alloc] initWithModelViewController: self];
	
	propertiesPanel = [ULPropertiesPanel new];  
	systemViewController = [ULSystemViewController new];  
	converter = [ULConverter new];
	templateController = [ULTemplateViewController new];
	processManager = [ULProcessManager appProcessManager];
	databaseManager = [ULDatabaseManager new];
	[processManager setAutomaticSpawn: 
		[[NSUserDefaults standardUserDefaults]
			boolForKey: @"AutomaticallyStartWaitingProcesses"]];

	activeDelegate = databaseBrowser;

	//Load application scripting bundle if present
	if([self _isAvailableApplicationScriptingBundle])
	{
		[self _loadApplicationScriptingBundle];
		scriptManager = [ULScriptManager new];
	}
	else
		scriptManager = nil;

	//register for notifications

	[notificationCenter addObserver: self
		selector: @selector(handleServerDisconnection:)
		name: @"ULDisconnectedFromServerNotification"
		object: nil];
	[notificationCenter addObserver: self
		selector: @selector(databaseBrowserBecameActive:)
		name: @"ULDatabaseBrowserDidBecomeActiveNotification"
		object: databaseBrowser];
	[notificationCenter addObserver: self
		selector: @selector(statusTableBecameActive:)
		name: @"ULStatusTableDidBecomeActiveNotification"
		object: statusTable];
	[notificationCenter addObserver: self
		selector: @selector(userLandFinishedProcess:)
		name: @"ULProcessDidFinishNotification"
		object: processManager];
	[notificationCenter addObserver: self
		selector: @selector(handleProcessReconnectionError:)
		name: @"ULProcessManagerProcessReconnectionFailedNotification"
		object: processManager];

	[statusWindow setDelegate: self];
	welcomeString = [NSString stringWithFormat: @"\nWelcome %@.\nWorking directory is %@\n\n",
			 NSFullUserName(), [[ULIOManager appIOManager] applicationDir]];
	[self logString: welcomeString newline: YES];
	[self logString: @"-------------------------------------------------------------------------\n"
			newline: YES];

	[statusTable setProcessManager: processManager];
}

- (void)dealloc
{
	[databaseManager release];
	[scriptManager release];
	[databaseBrowser release];
	[statusTable release];
	[appPasteboard release];
	[templateController release];
	[preferencesPanel release];
	[propertiesPanel release];
	[analyser release];
	[simulationCommands release];
	[objectActions release];
	[allowedActions release];
	[super dealloc];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSConnection* connection;
	NSMutableDictionary* userInfo;

	[NSHost setHostCacheEnabled: YES];
	[simulationCreator closeWindow: self];

	//check now if there is a local instance of AdunServer running
	connection = [NSConnection connectionWithRegisteredName: @"AdunServer" host: nil];
	/*if(connection == nil)
		connection = [NSConnection connectionWithRegisteredName: @"AdunServer"
				host: nil
				usingNameServer: [NSSocketPortNameServer sharedInstance]];*/
				
	//if there is no AdunServer listening locally alert the user and ask if they want one to be started
	if(connection == nil)
		[self startAdunServer];
	
	[splashScreen orderOut: self];
	[splashScreen close];
	[splashScreenImageView release];
	[statusWindow makeKeyAndOrderFront: self];
}

- (BOOL)applicationShouldTerminate:(id)sender
{
	//Ask the process manager if we should terminate.
	//It will return NO if some launched processes are still
	//waiting to transmit their data.
	if(![processManager applicationShouldClose])
	{
		NSRunAlertPanel(@"Alert",
			@"Some running process are still waiting to transmit their data.\n\
Shutting down before this is done will cause these processes to terminate.\nPlease wait a few seconds and retry.",
			@"Dismiss",
			nil,
			nil);
		return NO;	
	}
	else
		return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotif
{
	//save the database
	[[ULDatabaseInterface databaseInterface] saveDatabase];
	//save the process state
	[processManager applicationWillClose];
	//FIXME: Seems to be necessary - However we disable for now since
	//there is a bug in one objects dealloc method which hasnt been
	//found yet
	//[self autorelease];
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName
{
}

- (void)showPrefPanel:(id)sender
{
	[preferencesPanel showPreferences: self];
}

/**
StatusTable / DatabaseBrowser directing
*/

- (void) databaseBrowserBecameActive: (NSNotification*) aNotification
{
	[statusTable setActive: NO];
	[databaseBrowser setActive: YES];
	activeDelegate = databaseBrowser;
}

- (void) statusTableBecameActive: (NSNotification*) aNotification
{
	[databaseBrowser setActive: NO];
	[statusTable setActive: YES];
	activeDelegate = statusTable;
}

/**
AdunServer launching 
**/

- (void) startAdunServer
{
	int retVal;
	NSString* launchPath;

	retVal = NSRunAlertPanel(@"Alert", 
			@"There is no AdunServer running on the local host.\nDo you wish me to start one now?\n", 
			@"Yes",
			@"No", 
			nil);

	if(retVal == NSOKButton)
	{
#if NeXT_RUNTIME	
		launchPath = [[NSUserDefaults standardUserDefaults]
				stringForKey: @"AdunServerPath"];
		launchPath = [launchPath stringByAppendingPathComponent: @"AdunServer"];		
#else				
		launchPath = [NSHomeDirectory() 
				stringByAppendingPathComponent: @"GNUstep/Tools/AdunServer"];
#endif		
		NS_DURING
		{
			[NSTask launchedTaskWithLaunchPath: launchPath
				arguments: [NSArray array]];
		}
		NS_HANDLER
		{
			NSRunAlertPanel(@"Alert",
				[NSString stringWithFormat: @"Unable to lauch AdunServer - %@",
					[localException reason]],
				@"Dismiss", 
				nil,
				nil);
		}
		NS_ENDHANDLER
	}
}

- (void) handleServerDisconnection: (NSNotification*) aNotification
{
	NSString *errorString;
	NSError * error;
	NSString* disconnectedHost;
	NSDictionary* userInfo;

	userInfo = [aNotification userInfo];

	error = [userInfo objectForKey: @"ULDisconnectionErrorKey"];
	disconnectedHost = [userInfo objectForKey: @"ULDisconnectedHostKey"];

	//display the error

	errorString = [NSString stringWithFormat: @"%@\n%@\n", 
			[[error userInfo] objectForKey: NSLocalizedDescriptionKey],
			[[error userInfo] objectForKey: @"NSRecoverySuggestionKey"]];

	[self logString: errorString newline: YES];
	NSRunAlertPanel(@"Error", errorString, @"Dismiss", nil, nil);

	//if the server that died was the local server attempt to restart it

	if([disconnectedHost isEqual: [[NSHost currentHost] name]])
		[self startAdunServer];
}

- (void) handleProcessReconnectionError: (NSNotification*) aNotification
{
	NSEnumerator* processEnum;
	NSMutableString* string = [NSMutableString new];
	id process;
	
	//The notification object is an array of the processes that
	//failed to reconnect.
	processEnum = [[aNotification object] objectEnumerator];
	while(process = [processEnum nextObject])
	{
		[string appendFormat: @"Unable to reconnect process %@\n", [process name]];
		[string appendFormat: @"Identification - %@\n", [process identification]];
		[string appendFormat: @"Started on - %@\n", [process started]];
		[string appendFormat: @"Host - %@\n", [process processHost]];
		[self logString: string newline: YES forProcess: process];
		[string deleteCharactersInRange: NSMakeRange(0, [string length])];
	}
	
	[string appendString: @"It is likely that the server(s) running on the host(s) crashed "];
	[string appendString: @"since Adun was last shut down\n"];
	[string appendString: @"However is may still be possible to retrieve the process data\n"];
	[string appendString: @"Please see the Adun documentation for more information\n"];
	[self logString: string newline: YES];
	[string release];
	
	NSRunAlertPanel(@"Alert",
		@"Unable to reconnect to simulations running at last shutdown\n. See log for more information",
		@"Dismiss",
		nil,
		nil);
}

//Check the termination status of all simulations
- (void) userLandFinishedProcess: (NSNotification*) aNotification
{
	NSError* terminationError;
	NSMutableString* logString;
	NSString* errorString;

	terminationError = [[aNotification userInfo] objectForKey: @"AdTerminationErrorKey"];
	
	if(terminationError != nil)
	{
		NSRunAlertPanel(@"Simulation Error",
			[NSString stringWithFormat: @"%@\nSee log for more details.\n", 
				[[terminationError userInfo] objectForKey: NSLocalizedDescriptionKey]],
				@"Dismiss",
				nil,
				nil);
		
		//check if we have a detailed description or a recovery suggestion	

		logString = [NSMutableString stringWithCapacity: 1];
		
		if((errorString = [[terminationError userInfo] objectForKey: @"AdDetailedDescriptionKey"]) != nil)
			[logString appendFormat: @"\n%@\n", errorString];

		if((errorString = [[terminationError userInfo] objectForKey: @"NSRecoverySuggestionKey"]) != nil)
			[logString appendFormat: @"%@\n", errorString];

		if([logString isEqual: @""])
		{
			[logString appendString: 
				[[terminationError userInfo] objectForKey: NSLocalizedDescriptionKey]];
			[logString appendString: @"\nNo extra details available on cause of termination\n"];
		}
		else
			[logString insertString: 
				[[terminationError userInfo] objectForKey: NSLocalizedDescriptionKey]
				atIndex: 0];

		[self logString: [NSString stringWithFormat: @"Simulation exited unexpectedly.\n%@\n", logString]
			newline: YES
			forProcess: [[aNotification userInfo] 
				objectForKey: @"ULTerminatedProcess"]];
	}
	else
	{
		[self logString: @"Simulation finished successfully\n" 
			newline: YES 
			forProcess: [[aNotification userInfo] 
				objectForKey: @"ULTerminatedProcess"]];
	}
}

//Logging

- (void) logString: (NSString*) string newline: (BOOL) newline
{
	NSRange endRange;

	endRange.location = 0;
	endRange.length = 0;
	[logOutput replaceCharactersInRange:endRange withString: string];
}

- (void) logString: (NSString*) string newline: (BOOL) newline forProcess: (ULProcess*) process
{
	NSString* processString;
	NSRange endRange;

	[self logString: string newline: newline]; 

	endRange.location = 0;
	endRange.length = 0;
	processString = [NSString stringWithFormat: @"Simulation - Name: %@. PID: %@.\n\n", 
				[process valueForKey: @"name"], [process valueForKey:@"processIdentifier"]];
	[logOutput replaceCharactersInRange:endRange withString: processString];
	endRange.location = 0;
	endRange.length = 0;
	[logOutput replaceCharactersInRange:endRange withString: 
		@"\n-------------------------------------------------------------------------\n"];

}

//Opening other windows

- (void) openAnalyser: (id) sender
{
	[analyser open: self];
}

//FIXME: Change to new template
- (void) newOptions: (id) sender
{
	[templateController open: (id) sender];
}

- (void) newSystem: (id) sender
{
	[systemViewController open: (id) sender];
}

/**
Menu validation 
*/

//the simulation commands are in a separate category
//but we validate them here
- (BOOL) validateSimulationCommand: (NSString*) command
{
	id selectedItem;	
	NSString *status;

	if(![[appPasteboard availableTypes] containsObject: @"ULProcess"])
		return NO;

	if([appPasteboard countOfObjectsForType: @"ULProcess"] != 1)
		return NO;
			
	status = [[[appPasteboard objectsForType: @"ULProcess"] 
			objectAtIndex: 0] 
			processStatus];
	
	if([[allowedActions objectForKey: status] 
		containsObject: command])
		return YES;
	else
		return NO;

	return YES;
}

- (BOOL) validateLogDisplay
{
	if([[appPasteboard availableTypes] containsObject: @"AdSimulationData"])
		return YES;
	
	if([[appPasteboard availableTypes] containsObject: @"ULProcess"])
		return YES;
		
	return NO;			
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	NSString* action;
	id object, objectType;
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];

	action = NSStringFromSelector([menuItem action]);

	if([objectActions containsObject: action])
		return [activeDelegate validateMenuItem: menuItem];

	if([simulationCommands containsObject: action])
		return [self validateSimulationCommand: action];

	if([action isEqual: @"properties:"])
		return [propertiesPanel validateMenuItem: menuItem];

	if([action isEqual: @"analyse:"])
		return [analyser validateMenuItem: menuItem];

	if([action isEqual: @"convert:"])
		return [converter validateMenuItem: menuItem];
		
	if([action isEqual: @"createAttributeFile:"])
		return [[ULExportController sharedExportController]
			validateCreateAttribute: self];
		
	if([action isEqual: @"viewErrorLog:"])	
		return [self validateLogDisplay];
		
	if([action isEqual: @"viewSimulationLog:"])
		return [self validateLogDisplay];
		
	if([action isEqual: @"display:"])
	{
		//FIXME: Everything should be displayable
		//FIXME: Reinsert ULProcess display
		objectType = [[pasteboard availableTypes] objectAtIndex: 0];
		if([objectType isEqual: @"AdDataSet"] || 
			[objectType isEqual: @"ULTemplate"])
		{	
			return YES;
		}	
		else
			return NO;

	}

	//FIXME: preliminary load validation - load: only works
	//with simulation creation at the moment
	if([action isEqual: @"load:"])
	{
		if([activeDelegate countOfObjectsForType: @"AdDataSource"] > 0)
			return YES;
		else if([activeDelegate countOfObjectsForType: @"ULTemplate"] > 0)
			return YES;
		else
			return NO;
	}		

	return YES;
}

/*
 * Displaying simulation logs.
 */

//Testing Services
- (void) _displayStringOSX: (NSString*) string
{
	NSPasteboard* pasteboard;
	
	//On OSX we can use the services menu to open the logs
	//since we're guaranteed TextEdit will be present
	pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes: [NSArray arrayWithObject: @"NSStringPboardType"] 
			   owner: self];
	[pasteboard setString: string
		      forType: @"NSStringPboardType"];
	NSPerformService(@"TextEdit/New Window Containing Selection", pasteboard);
}

- (void) _displayFileLinux: (NSString*) filename
{
	NSString* editor;
	NSTask* task;
	
	//On linux the user has to set the prefered editor
	//to use. It defaults to gedit.
	//We must handle launch errors.
	editor = [[NSUserDefaults standardUserDefaults]
			objectForKey: @"Editor"];
	NS_DURING
	{			
		task = [NSTask launchedTaskWithLaunchPath: editor 
			arguments: [NSArray arrayWithObject: filename]];
	}
	NS_HANDLER
	{		
		NSRunAlertPanel(@"Unable to launch editor", 
			[NSString stringWithFormat: @"Using executable path %@", editor],
			@"Dismiss",
			nil, nil);
	}
	NS_ENDHANDLER
}

- (void) _displayFileOSX: (NSString*) filename
{
	NSTask* task;
	
	//Use Console via Open on OSX
	//FIXME: Change to use NSWorkspace
	NS_DURING
	{			
		//Open should be always in the same place.
		task = [NSTask launchedTaskWithLaunchPath: @"/usr/bin/open" 
			arguments: [NSArray arrayWithObjects: @"-a", @"Console", filename, nil]];
	}
	NS_HANDLER
	{		
		NSRunAlertPanel(@"Unable to launch Console", 
				[NSString stringWithFormat: @"Could not open log %@", filename],
				@"Dismiss",
				nil, nil);
	}
	NS_ENDHANDLER
}

- (void) _viewLog: (NSString*) name
{
	BOOL isWaiting = NO;
	NSString* filename;
	ULProcess* process;
	AdSimulationData* object;
	NSString* string;
	
	if([[appPasteboard availableTypes] containsObject: @"ULProcess"])
	{
		process = [appPasteboard objectForType: @"ULProcess"];
		if([[process processStatus] isEqual: @"Waiting"])
			isWaiting = YES;
		else
			object = [process simulationData];
		
	}
	else
		object = [appPasteboard objectForType: @"AdSimulationData"];
	
	//If the object is a waiting process no log files will have been output.
	if(isWaiting)
	{
		NSRunAlertPanel(@"Process is waiting",
				@"Log files are not created until the simulation is started",
				@"Dismiss",
				nil,
				nil);
	}
	else if(object == nil)
	{
		NSRunAlertPanel(@"Process has not provided access to its log files yet",
				@"Please wait a moment and try again",
				@"Dismiss",
				nil,
				nil);
	}
	else
	{
		filename = [[object dataStorage] storagePath];
		filename = [filename stringByAppendingPathComponent: name];
		//string = [NSString stringWithContentsOfFile: filename];
		//FIMXE: Should be able to change this to use NSWorkspace on 
		//both platforms at some stage.
#if NeXT_RUNTIME == 1
		[self _displayFileOSX: filename];
#else
		[self _displayFileLinux: filename];
#endif	
	}
}

- (void) viewSimulationLog: (id) sender
{
	[self _viewLog: @"AdunCore.log"];
}
	
- (void) viewErrorLog: (id) sender
{
	[self _viewLog: @"AdunCore.errors"];
}

//Delegate to the activeDelegate
//We could avoid doing this by subclassing the outline and table views
//the delegates use and override/add these methods. This would 
//simplify things even more. However for now will stick with this
//method as there are more pressing things to do.

- (void) cut: (id) sender 
{ 	
	[activeDelegate cut: sender];
 }

- (void) copy: (id) sender 
{ 
	[activeDelegate copy: sender]; 
}

- (void) paste: (id) sender 
{ 
	[activeDelegate paste: sender]; 
}

- (void) remove: (id) sender 
{ 
	[activeDelegate remove: sender]; 
}

- (void) export: (id) sender
{
	[activeDelegate export: self];
}

- (void) exportAs: (id) sender
{
	[activeDelegate exportAs: sender];
}

- (void) import: (id) sender
{
	[activeDelegate import: self];
}

- (void) deselectAllRows: (id) sender
{
	[activeDelegate deselectAllRows: self];
}

/**
Delegate to other tools
**/

- (void) display: (id) sender 
{
	ULPasteboard* pasteboard = [ULPasteboard appPasteboard];
	NSString* objectType;
	
	objectType = [[pasteboard availableTypes] objectAtIndex: 0];

	if([objectType isEqual: @"ULTemplate"])
		[templateController display: self]; 
	else
		[analyser display: self];
}

- (void) properties: (id) sender
{
	[propertiesPanel properties: self];
}

- (void) analyse: (id) sender
{
	[analyser analyse: self];
}

- (void) convert: (id) sender
{
	[converter convert: self];
}

- (void) createAttributeFile: (id) sender
{
	[[ULExportController sharedExportController] 
		openAttributeWindow: self];
}

- (void) addDatabase: (id) sender
{
	[databaseManager showAddDatabasePanel: self];
}

- (void) removeDatabase: (id) sender
{
	[databaseManager showRemoveDatabasePanel: self];
}

//On closing the main window the application should quit
//but i'm not sure if calling applicationShouldTerminate 
//here is a good idea.

- (BOOL) windowShouldClose: (id) sender
{
	return NO;
}

@end
