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

 
#ifndef _PCAPPPROJ_APPCONTROLLER_H
#define _PCAPPPROJ_APPCONTROLLER_H

#include <AppKit/AppKit.h>
#include "ULFramework/ULFramework.h"
#include "ULSystemViewController.h"
#include "ULAnalyser.h"
#include "ULPreferences.h"
#include "ULStatusTable.h"
#include "ULDatabaseBrowser.h"
#include "ULSimulationCreator.h"
#include "ULTemplateViewController.h"
#include "ULPasteboard.h"
#include "ULConverter.h"
#include "ULDatabaseManager.h"

/**
ViewController is the main view controller class. It controls the 'Adun Status' window
and is responisble for displaying general information from the model aswell as spawning
simulations.

\todo All objects should be displayable i.e. should respond to the "display" command.
\ingroup interface
*/

@interface ViewController : NSObject
{
	id processManager;
	id propertiesPanel;		//!< The ULPropertiesPanel instance
	id systemViewController; 	//!< The ULSystemViewController instance
	id analyser;
	id converter;
	id templateController;
	id databaseBrowser;
	id simulationCreator; 
	id preferencesPanel;
	id statusTable;
	id statusWindow;
	id logOutput;
	id splashScreen;
	id splashScreenImageView;
	id activeDelegate;
	id objectActions;
	id simulationCommands;
	id appPasteboard;
	id databaseManager;
	id scriptManager;
	Class ULScriptManager;
	//temporary
	NSMutableDictionary* allowedActions;
}

/**
Description forthcoming
*/
+ (void)initialize;
/**
Description forthcoming
*/
- (id)init;
/**
Description forthcoming
*/
- (void)dealloc;
/**
Description forthcoming
*/
- (void)awakeFromNib;
/**
Description forthcoming
*/
- (void)applicationDidFinishLaunching:(NSNotification *)aNotif;
/**
Description forthcoming
*/
- (BOOL)applicationShouldTerminate:(id)sender;
/**
Description forthcoming
*/
- (void)applicationWillTerminate:(NSNotification *)aNotif;
/**
Description forthcoming
*/
- (BOOL)application:(NSApplication *)application openFile:(NSString *)fileName;
/**
Description forthcoming
*/
- (void)showPrefPanel:(id)sender;
/**
Description forthcoming
*/
- (void) newSystem: (id) sender;
/**
Description forthcoming
*/
- (void) newOptions: (id) sender;
/**
Description forthcoming
*/
- (void) logString: (NSString*) string newline: (BOOL) newline;
/**
Description forthcoming
*/
- (void) logString: (NSString*) string newline: (BOOL) newline forProcess: (ULProcess*) process;
/**
Description forthcoming
*/
- (void) startAdunServer;
/**
Description forthcoming
*/
- (void) openAnalyser: (id) sender;
/**
Description forthcoming
*/
- (void) addDatabase: (id) sender;
/**
Description forthcoming
*/
- (void) removeDatabase: (id) sender;
/**
Description forthcoming
*/
- (void) viewSimulationLog: (id) sender;
/**
Description forthcoming
*/
- (void) viewErrorLog: (id) sender;
@end

#endif
