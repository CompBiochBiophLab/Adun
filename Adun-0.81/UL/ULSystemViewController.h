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

#ifndef _ULSYSTEMVIEWCONTROLLER_
#define _ULSYSTEMVIEWCONTROLLER_

#include <AppKit/AppKit.h>
#include <ULFramework/ULIOManager.h>
#include <ULFramework/ULDatabaseInterface.h>
#include <ULFramework/ULSystemController.h>
#include <ULFramework/ULURLDownload.h>
#include "ViewController.h"
#include "ULOutlineViewDelegate.h"
#include "ULProgressPanel.h"

/**
ULSystemViewController controls the "Create System" part of the GUI.
It acts as a conduit between ULSystemController and the GUI transmitting
and handling information in both directions.

\ingroup interface

*/

@interface ULSystemViewController : NSObject
{
	BOOL isBuilding;	//!< Indicates if a build is in progress
	id forceField;		//!< The name of the forceField to be used
	id systemWindow;	//!< The "Create System" window
	id mainViewController;	//!< Reference to the mainViewController (ViewController subclass)
	id metadataController;
	id systemController;	//!< A ULSystemController instance
	id moleculePathField;	//!< The path text field
	id progressBar;
	id progressIndicator;
	id progressView;
	id pluginList;
	id forcefieldList;
	id forcefieldLabel;
	id buttonOne;		
	id buttonTwo;		
	id buttonThree;	
	id loadButton;	
	id optionsView;
	id logView;
	id tabView;
	id preprocessTabViewItem;
	id currentOptions;
	id outlineDelegate;
	NSArray* allowedFileTypes;
	//Downloading pdb ivars
	ULURLDownload* urlDownload;
	ULProgressPanel* progressPanel;
}

/**
Asks the ULSystemController instance to create a system based on the current user inputs 
(configuration file, force field and configuration plugin) by sending it a
buildSystemWithOptions: message.
*/
- (void) createSystem: (id)sender;
/**
Continues the current build after a previous error
*/
- (void) continueBuild;
/**
Cancels the current build
*/
- (void) cancelBuild;
/**
Opens the build window
*/
- (void) open: (id)sender;
/**
Closes the create system window
*/
- (void) close: (id) sender;
/**
Open a file browser
**/
- (void) showFileBrowser: (id) sender;
/**
Calls the correct method depend on the senders title
(usually button one i.e. create, analyse
*/
- (void) doButtonAction: (id) sender;
/**
Retrives the structure file specified in the molecule path field.
If the field does not contain a four letter PDB code a file browser it opened
*/
- (void) getStructureFile: (id) sender;
/**
Loads the specified structure file into the builder
after it has been retreived
*/
- (void) loadStructureFile: (NSString*) fileName;

@end

#endif
