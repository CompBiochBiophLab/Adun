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
#ifndef _ULEXPORTPANEL_
#define _ULEXPORTPANEL_
#include <AppKit/AppKit.h>
#include "ULFramework/ULFrameworkDefinitions.h"

/**
Displays export options.
\todo Could be refactored to be a generic choice panel
*/
@interface ULExportPanel : NSObject
{
	int pushedButton;
	id boundingBox;
	id matrixView;
	id panel;
}
/**
Returns the shared export panel instance
*/
+ (id) exportPanel;
/**
Sets the type pf the object being exported.
Displayed as the box title in the panel
*/
- (void) setObjectType: (NSString*) aString;
/**
Sets the format choices to display
*/
- (void) setChoices: (NSArray*) choices;
/**
Returns the title of the selected choice
*/
- (NSString*) choice;
/**
Closes the window
*/
- (void) close: (id) sender;
/**
Runs the panel in a modal session
Returns NSOKButton or NSCancelButton depending
on the button selected.
*/
- (int) runModal;
@end

#endif
