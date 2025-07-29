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
#include "ULOutlineViewAdditions.h"

@implementation NSOutlineView (ULExpansionAdditions)

- (void) expandAllItems
{
#ifdef GNUSTEP
	[self expandItem: nil expandChildren: YES];
#else
	int noItems, i;
	id item, dataSource;
	
	dataSource = [self dataSource];
	noItems = [dataSource outlineView: self numberOfChildrenOfItem: nil];
	for(i=0; i<noItems; i++)
	{
		item = [dataSource outlineView: self child: i ofItem: nil];
		[self expandItem: item expandChildren: YES];
	}
#endif	
}

- (void) expandUntilLevel: (int) level
{
	int noRows, i, rowLevel;
	id item;

	[self expandAllItems];
	noRows = [self numberOfRows];
	for(i=noRows-1; i>=0; i--)
	{
		rowLevel = [self levelForRow: i];
		if(rowLevel == level)
		{
			item = [self itemAtRow: i];
			[self collapseItem: item collapseChildren: YES];
		}
	}
}

@end
