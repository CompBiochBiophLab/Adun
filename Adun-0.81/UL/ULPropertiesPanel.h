/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-31 16:30:43 +0200 by michael johnston

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

#ifndef _ULPROPERTIESPANEL_H_
#define _ULPROPERTIESPANEL_H_

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "ULFramework/ULDatabaseInterface.h"
#include "ULOutlineViewDelegate.h"
#include "ULInterfaceFunctions.h"
#include "ViewController.h"
#include "ULOutlineViewAdditions.h"
#include "ULPasteboard.h"

/**
\ingroup interface
Controlls the interfaces properties panel
*/

@interface ULPropertiesPanel : NSObject <ULPasteboardDataSource>
{
	BOOL result;
	int checkCount;
	NSWindow* window;
	id tabView;
	id outlineView;
	id outlineDelegate;
	id saveButton;
	id cancelButton;
	id currentModelObject;
	id annotationInput;
	id annotations;
	id referenceTable;
	NSArray* modelObjects;
	NSMutableArray *referenceData;
	NSMutableArray *availableTypes;
	NSMutableDictionary* selectedObjects;
	NSMutableDictionary* propertiesDict;
	ULDatabaseInterface* databaseInterface;
}

+ (id) propertiesPanel;
/**
Sets the current options to loaded but doesnt open the metadata window
*/
- (void) close: (id) sender;
/**
Description forthcoming
*/
- (void) displayMetadataForModelObject: (id) modelObject allowEditing: (BOOL) value;
/**
Description forthcoming
*/
- (void) displayMetadataForModelObject: (id) modelObject 
	allowEditing: (BOOL) value 
	runModal: (BOOL) flag;
/**
Description forthcoming
*/
- (BOOL) result;	
/**
Description forthcoming
*/
- (void) addAnnotation: (id) sender;

@end

#endif // _ULPROPERTIESPANEL_H_

