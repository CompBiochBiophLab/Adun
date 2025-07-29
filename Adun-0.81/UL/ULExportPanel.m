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

#include <AppKit/AppKit.h>
#include "ULExportPanel.h"

id exportPanel = nil;

@implementation ULExportPanel

+ (id) exportPanel
{
	if(exportPanel == nil)
		exportPanel = [self new];

	return exportPanel;
}

- (id) init
{
	if(exportPanel != nil)
		return exportPanel;

	if(self = [super init])
	{
		if([NSBundle loadNibNamed: @"ExportPanel" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading export panel interface");
			return nil;
		}
	}

	exportPanel = self;

	return self;
}

- (void) awakeFromNib
{
	[matrixView setCellClass: [NSButtonCell class]];
}

- (int) runModal
{
	[panel center];
	[panel setFloatingPanel: YES];
	[panel makeKeyAndOrderFront: self];
	[NSApp runModalForWindow: panel];

	return pushedButton;
}

- (void) close: (id) sender
{
	//Get pushed button

	pushedButton = [sender tag];
	[NSApp stopModal];
	[panel close];
	[boundingBox setTitle: @"Unknown"];
} 

- (void) setObjectType: (NSString*) aString
{
	[boundingBox setTitle: 
		[NSString stringWithFormat: 
			@"Export %@ As ", aString]];
}

- (void) setChoices: (NSArray*) choices
{
	int i;
	NSArray* cells;
	NSRect matrixFrame;
	NSSize cellSize;
	id cell;

	//Size the cells we will add to fit the matrix frame
	matrixFrame = [matrixView frame];
	cellSize = matrixFrame.size;
	if([choices count] > 1)
	{
		cellSize.height = (double)cellSize.height/[choices count];
		cellSize.height -= 1;
	}	
	[matrixView setCellSize: cellSize];
	
	//Create the required cells and update the view
	[matrixView renewRows: [choices count] columns: 1];
	[matrixView sizeToCells];

	//Set the cells titles and types
	cells = [matrixView cells];
	for(i=0; i<(int)[cells count]; i++)
	{
		cell = [cells objectAtIndex: i];
		[cell setButtonType: NSRadioButton];
		[cell setTitle: [choices objectAtIndex: i]];
		//[cell setAlignment: NSCenterTextAlignment];
	}
	
	[matrixView selectCellAtRow: 0 column: 0];
	[matrixView sizeToCells];
}

- (NSString*) choice
{
	return [[matrixView selectedCell] title];
}

@end
