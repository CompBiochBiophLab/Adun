/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston 

   Created: 2005-12-09 14:47:28 +0100 by michael johnston

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
#ifndef _ULMENUEXTENSIONS_
#define _ULMENUEXTENSIONS_
#include <Foundation/Foundation.h>
#include "ULFramework/ULFrameworkDefinitions.h"

/**
\ingroup classes
Adds methods to NSMutableDictionary enabling to be
used to display plugin options.
\todo Divide into node or leaf interface e.g. ULLeafMenuExtensions etc.
Rename leaf menus to 'selection' menus.
Update newNodeMenu to be more explanatory.
*/
@interface NSMutableDictionary (ULMenuExtensions)
/**
Returns an autoreleased NSMutableDictionary configured to
act as a node menu. A node menus items have associated values.
These can strings, numbers or other menues.
If flag is YES the submenu items can be selected/deselected.
*/
+ (id) newNodeMenu: (BOOL) flag;
/**
Returns an autoreleased NSMutableDictionary configured to
act as a leaf menu. A leaf menus items cannot have values.
A leaf menu is a selection menu by default.
*/
+ (id) newLeafMenu;
/**
Returns YES if the menu is a node menu NO otherwise
*/
- (BOOL) isNodeMenu;
/**
If the receiver is a selection menu sets the type - Multiple or Single.
Does nothing if \e type is not an allowed type.
*/
- (void) setSelectionMenuType: (NSString*) type;
/**
Returns the selection menu type or nil if this is not a selection menu
*/
- (NSString*) selectionMenuType;
/**
Returns the selected items or nil if this is not a selection menu
*/
- (NSArray*) selectedItems;
/**
Adds an item to the menu. Only for use with leaf menus.
*/
- (void) addMenuItem: (NSString*) aString;
/**
Adds the strings in \e anArray as menu items
Only for use with leaf menus.
*/
- (void) addMenuItems: (NSArray*) anArray;
/**
Returns an array of the menu item names.
*/
- (NSArray*) menuItems;
/**
Adds an item called \e aString with value \e value. Only for use with node menus.
\e value can be a string, number or another menu
*/
- (void) addMenuItem: (NSString*) aString withValue: (id) value;
/**
Removes the item called \e aString along with any associated value if
the receiver is a node menu.
Does nothing if there is no item called \e aString.
*/
- (void) removeMenuItem: (NSString*) aString;
/**
Returns the value associated with the item \e aString
*/
- (id) valueForMenuItem: (NSString*) aString;
/**
Sets a default selection for the menu
*/
- (void) setDefaultSelection: (NSString*) name;
/**
Sets a default selection for the menu
*/
- (void) setDefaultSelections: (NSArray*) anArray;
/**
Sets the value of menu item \e aString to 'Selected'.
Only for use with leaf menus.
*/
- (void) selectMenuItem: (NSString*) aString;
/**
 Deselected the value of menu item \e aString.
 Only for use with leaf menus.
 */
- (void) deselectMenuItem: (NSString*) aString;
@end

#endif
