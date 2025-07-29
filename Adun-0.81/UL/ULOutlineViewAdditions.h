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

#ifndef _ULOUTLINEVIEW_ADDITIONS_
#define _ULOUTLINEVIEW_ADDITIONS_

#include <AppKit/AppKit.h>
#include "ULFramework/ULFrameworkDefinitions.h" 

/**
Category adding some convience methods for
expanding an NSOutlineView items. The 
category also handles differences between cocoa
and gnustep implementations.
*/
@interface NSOutlineView (ULExpansionAdditions)
/**
Expands all the items in the outline view
 */
- (void) expandAllItems;
/**
Expands all the items up to \e level
*/
- (void) expandUntilLevel: (int) level;
@end

#endif
