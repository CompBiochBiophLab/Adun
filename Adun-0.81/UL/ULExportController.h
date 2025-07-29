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
#ifndef _ULEXPORTCONTROLLER_
#define _ULEXPORTCONTROLLER_
#include <AppKit/AppKit.h>
#include <AdunKernel/AdunKernel.h>
#include <AdunKernel/AdunSimulationData.h>
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULTemplate.h"
#include "ULFramework/ULFrameworkFunctions.h"
#include "ULExportPanel.h"
#include "ULPasteboard.h"

/**
Controllers the outputting of adun data in different formats from the UI.
\ingroup interface
*/
@interface ULExportController: NSObject
{
	id exportPanel;
	NSDictionary* knownFormats;
	NSDictionary* displayStrings;
	ULPasteboard* pasteboard;
	NSMutableDictionary* exportMethods;
	//Chimera attribute window elements
	id attributeDataSet;			//!< Contains the data to be put into an attribute file
	id attributeWindow;			//!< The window
	id atomButton;				//!< Check box for selecting atom recipients
	id residueButton;			//!< Check box for selecting residue recipents
	NSPopUpButton* atomColumnList;		//!< Displays the columns to choose for atoms names/numbers
	NSPopUpButton* residueColumnList;		//!< Displays the columns to choose for residue names/numbers
	NSPopUpButton* attributeColumnList;	//!< Displays the columns to choose for attribtues
	NSPopUpButton* relationshipList;		//!< Displays the available relationship types
	NSPopUpButton* matrixList;		//!< Displays the matrix data.
	NSTextField* nameField;			//!< Input the attribute name.
}
+ (id) sharedExportController;
/**
Exports the object currently on the pasteboard
*/
- (void) export: (id) sender;
/**
Exports object
*/
- (void) exportObject: (id) anObject 
		toFile: (NSString*) filename 
		format: (NSString*) format;
/**
 Returns yes if the objects of class \e className can be exported as \e type.
 The valid values for type are given by the ULExportType enum.
 If \e type is not one of the above then an NSInvalidArgumentException is raised.
 */		
- (BOOL) canExportObjectofClass: (NSString*) className  as: (ULExportType) type;		
/**
Returns yes if the current object on the pasteboard can be exported as \e type.
If there is no object, or more than one object, on the pasteboard this method returns NO.
The valid values for \e type are given by the ULExportType enum.
If \e type is not one of the above then an NSInvalidArgumentException is raised.
If there is no object on the pasteboard this method returns NO.
*/
- (BOOL) canExportCurrentPasteboardObjectAs: (ULExportType) type;	

/**
Exports the current pasteboard object as \e type. 
Runs an NSSavePanel to prompt for the file name.
Raises NSInvalidArgumentException if the current pasteboard object cannot be
export as type.
*/
- (void) exportCurrentPasteboardObjectAs: (ULExportType) type;	
@end

/**
Contains methods for creating attribute files.
\ingroup interface
*/
@interface ULExportController (ChimeraAttributeFileCreation)
- (void) openAttributeWindow: (id) sender;
- (void) createAttributeFile: (id) sender;
- (void) changedMatrixSelection: (id) sender;
- (BOOL) validateCreateAttribute: (id) sender;
@end

#endif

