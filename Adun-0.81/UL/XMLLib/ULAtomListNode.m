/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:14:28 +0200 by michael johnston

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

#include "ULAtomListNode.h"

@implementation ULAtomListNode
- (NSArray*) atomNames;
{
	id atom;
	NSEnumerator* atomEnum;
	NSMutableArray* atomList;

	atomEnum = [children objectEnumerator];
	atomList = [NSMutableArray arrayWithCapacity:1];

	while((atom = [atomEnum nextObject]))
		[atomList addObject: [[atom attributes] valueForKey: @"name"]];

	return atomList;
}

/**
Returns an array of the names defined by the external source \source for the atoms in the list
\param source The source that defined the names
*/
- (NSArray*) atomNamesFromExternalSource: (NSString*) source;
{
	id atom, externalName;
	NSEnumerator* atomEnum;
	NSEnumerator* externalNameEnum;
	NSMutableArray* atomList;

	atomList = [NSMutableArray arrayWithCapacity:1];
	atomEnum = [children objectEnumerator];

	while((atom = [atomEnum nextObject]))
	{
		externalNameEnum = [[atom children] objectEnumerator];
		while((externalName = [externalNameEnum nextObject]))
		{
			if([[[externalName attributes] valueForKey:@"source"] isEqual: source])
				[atomList addObject: [externalName fieldValue]];
			else
				[atomList addObject: @"Unknown"];
		}
	}

	return atomList;
}

- (NSArray*) partialCharges
{
	double partialCharge;
	id atom;
	NSEnumerator* atomEnum;
	NSMutableArray* partialCharges;

	atomEnum = [children objectEnumerator];
	partialCharges = [NSMutableArray arrayWithCapacity:1];

	while((atom = [atomEnum nextObject]))
	{
		//partial charge is an XML attribute so it will be returned as a string
		//Here its converted to an double number.
		partialCharge = [[[atom attributes] valueForKey: @"partialcharge"] doubleValue];
		[partialCharges addObject: [NSNumber numberWithDouble: partialCharge]];
	}

	return partialCharges;
}

@end
