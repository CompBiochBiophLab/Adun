/* 
   Project: UL

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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
#include "ULFramework/ULDatabaseInterface.h"
#include "ULProgressPanel.h"
#include "ULPasteboard.h"
#include "ULExportController.h"
#include "ULInterfaceFunctions.h"
#include "ULOutlineViewAdditions.h"

/**
Displays , and allows manipulation of, Adun data stored in multiple
databases.

\todo Implement multiple object removal.
\bug When moving, i.e. cutting & pasting, an object if the removal of the original object
fails the object is still copied. (The "cut" isnt performed until "paste" is selected")

\ingroup interface
*/

@interface ULDatabaseBrowser : NSObject <ULPasteboardDataSource>
{
	BOOL endPanel;	//!< If yes the progress panel should be stopped on next notification
	BOOL cut;	//!< Indicates wheather the editedObject should be cut 
	BOOL isActive;
	id editedObject; //!< The item selected for cut or copy
	NSOutlineView* browserView;
	id viewList;
	id databaseInterface;
	NSMutableArray* selectedDataSets;
	NSMutableArray* selectedOptions;
	NSMutableArray* selectedSystems;
	NSMutableArray* selectedSimulations;
	NSArray* allowedActions;
	id path;
	ULProgressPanel* progressPanel;
	//Datadisplay ivars
	NSMutableArray* currentObjects;	//!< The objects currently displayed
	NSMutableArray* oldObjects;	//!< Stores the objects displayed before reloadData is called.
}
/**
Documentation forthcoming
*/
- (void) setActive: (BOOL) value;
/**
Documentation forthcoming
*/
- (BOOL) isActive;
@end

/**
Category containing NSOutlineView delegate and data source methods
\ingroup interface
*/
@interface ULDatabaseBrowser (ULDatabaseBrowserDataDisplay)
/**
Must be called before reloadData is sent to the browser display.
This method ensures the objects displayed before the reload aren't
prematurely released
*/
- (void) willReloadData;
/**
Must be called after reloadData is sent to the browser display.
Frees all objects displayed before the reload was called.
*/
- (void) didReloadData;
@end

@interface ULDatabaseBrowserPath: NSObject
{
	NSMutableArray* path;
}
/**
Sets the item at level \e level to be \e object and truncates
the path if \e level is less than the current level
*/
- (void) setItem: (id)  object forLevel: (int) level;
/**
Returns the item for level \e level of the path
*/
- (id) itemForLevel: (int) level;
/**
Returns the current elements of the path
*/
- (NSArray*) currentPath;
/**
Returns the current depth of the path
*/
- (int) currentLevel;
/**
Truncates the path to level \e value. If value
is greater than the current number of levels an exception
is raised.
*/
- (BOOL) truncateToLevel: (int) value;
/**
Clears the path
*/
- (void) clearPath;
/**
Adds an item to the path, increasing the level count by one
*/
- (void) addItem: (id) object;
@end

