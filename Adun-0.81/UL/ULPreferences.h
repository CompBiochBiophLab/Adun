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
#include "ULFramework/ULFrameworkDefinitions.h"

/**
Handles the preference panel

\ingroup interface
*/

@interface ULPreferences : NSObject
{
	id coreTraceMemory;
	id coreOutputMemoryStatistics;
	id coreRedirectOutput;
	id coreDebugLevels;
	id coreMinimisation;
	id ulPDBDirectory;
	id ulGnuplotPath;
	id ulTheme;
	id ulDebugLevels;
	id preferencesWindow;
	id preferencesTabView;
	id viewController;
	id sectionList;
	NSMutableDictionary* coreDict;
	NSMutableDictionary* ulDict;
	NSUserDefaults* defaults;
}
/**
Description forthcoming
*/
- (id) initWithModelViewController: (id) object;
/**
Description forthcoming
*/
- (void) showPreferences: (id) sender;
/**
Description forthcoming
*/
- (void) setDefault: (id) sender;
/**
Description forthcoming
*/
- (void) updateDefaults: (id) sender;
/**
Description forthcoming
*/
- (void) sectionDidChange: (id) sender;
/**
Description forthcoming
*/
- (void) setValue: (id) value 
	forKey: (NSString*) key 
	inPersistentDomainForName: (NSString*) name;
@end
