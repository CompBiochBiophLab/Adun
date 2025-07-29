/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-07 12:52:37 +0200 by michael johnston

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

#include "ULInteractionNode.h"

@implementation ULInteractionNode

- (void) _createIdStrings
{
	NSMutableArray* atomArray;
	int i;
	XMLNode* child;

	atomArray = [NSMutableArray arrayWithCapacity:1];
	idStrings = [[NSMutableArray arrayWithCapacity:1] retain];
	childCount = [children count];

	for(i=0; i<childCount; i++)
	{
		child = [children objectAtIndex: i]; 
		if([[child name] isEqual: @"atom"])
			[atomArray addObject: [child fieldValue]];
	}

	[idStrings addObject: [atomArray componentsJoinedByString: @" "]];
	[idStrings addObject: [[[atomArray reverseObjectEnumerator] allObjects] componentsJoinedByString: @" "]];
}	

- (NSMutableArray*) idStringsForInteraction
{
	if(idStrings == nil)
		[self _createIdStrings];

	return idStrings;
}

- (void) _createConstraintArray
{
	NSEnumerator* childEnum;
	id child;

	constraints = [[NSMutableArray arrayWithCapacity:1] retain];
	childEnum = [children objectEnumerator];
	while((child = [childEnum nextObject]))
	{
		if([[child name] isEqual: @"constraint"])
			[constraints addObject: [child fieldValue]];
	}
}

- (void) _createParametersArray
{
	NSEnumerator* childEnum;
	id child;

	parameters = [[NSMutableArray arrayWithCapacity:1] retain];
	childEnum = [children objectEnumerator];
	while((child = [childEnum nextObject]))
	{
		if([[child name] isEqual: @"parameter"])
			[parameters addObject: [child fieldValue]];
	}
}

- (NSMutableArray*) constraints
{
	if(constraints == nil)
		[self _createConstraintArray];
	
	return constraints;
}	

- (NSMutableArray*) parameters
{
	if(parameters == nil)
		[self _createParametersArray];
	
	return parameters;
}	
	
@end
