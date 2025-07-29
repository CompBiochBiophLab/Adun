/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:14:15 +0200 by michael johnston

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

#include "ULConnectivityNode.h"

@implementation ULConnectivityNode

- (void) _createConnectivityMatrix
{
	//we'll retain the matrix to avoid having to do this
	//over and over

	int row;
	id connection;
	NSEnumerator* connectionEnum;

	connectivityMatrix = [[AdMutableDataMatrix alloc] 
				initWithNumberOfColumns: 2 
				columnHeaders: nil
				columnDataTypes: nil];

	connectionEnum = [children objectEnumerator];	

	row = 0;
	while((connection = [connectionEnum nextObject]))
	{
		[connectivityMatrix extendMatrixWithRow: 
			[NSArray arrayWithObjects:
				[[connection attributes] valueForKey:@"atomoneindex"],
				[[connection attributes] valueForKey:@"atomtwoindex"],
				nil]];
		row++;
	}
}
	
- (AdDataMatrix*) connectivityMatrix
{
	if(connectivityMatrix == nil)
		[self _createConnectivityMatrix];

	return connectivityMatrix;
}

- (AdDataMatrix*) connectivityMatrixWithOffset: (int) offset
{
	int norows, row, offsetIndex;
	AdMutableDataMatrix* offsetMatrix;
	NSMutableArray *rowArray = [NSMutableArray array];

	if(connectivityMatrix == nil)
		[self _createConnectivityMatrix];

	norows = [connectivityMatrix numberOfRows];
	offsetMatrix = [[AdMutableDataMatrix alloc] 
			initWithNumberOfColumns: 2
			columnHeaders: nil
			columnDataTypes: nil];
	[offsetMatrix autorelease];		
	
	for(row=0; row < norows; row++)
	{
		offsetIndex = [[connectivityMatrix elementAtRow: row column: 0] intValue] + offset;
		[rowArray addObject: [NSNumber numberWithInt: offsetIndex]];
		offsetIndex = [[connectivityMatrix elementAtRow: row column: 1] intValue] + offset;
		[rowArray addObject: [NSNumber numberWithInt: offsetIndex]];
		[offsetMatrix extendMatrixWithRow: rowArray];
		[rowArray removeAllObjects];
	}

	return offsetMatrix;
}
@end
