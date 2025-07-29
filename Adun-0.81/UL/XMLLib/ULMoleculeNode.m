/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:13:59 +0200 by michael johnston

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

#include "ULMoleculeNode.h"

@implementation ULMoleculeNode

- (NSArray*) atomNamesFromExternalSource: (NSString*) source;
{
	return [[children objectAtIndex:0] atomNamesFromExternalSource: source];
}

- (NSArray*) atomNames
{
	return [[children objectAtIndex:0] atomNames];
}

- (NSString*) moleculeName
{
	return [attributes valueForKey:@"name"];
}

- (NSArray*) partialCharges
{
	return [[children objectAtIndex:0] partialCharges];
}


/**
We should create a better mapping so molecules with no external connections 
have no externalconnections elements in them
*/

- (bool) _checkIfMonomer
{
	NSEnumerator* connectionEnum;
	id connection, child;
	NSEnumerator* childEnum;
	NSMutableArray* externalConnections;	

	childEnum = [children objectEnumerator];
	externalConnections = [NSMutableArray arrayWithCapacity: 1];

	//search the children for all external connections and add the connection
	//tp externalconnection array

	while((child = [childEnum nextObject]))
	{
		if([[child name] isEqual: @"externalconnection"])
			[externalConnections addObject: [[child attributes] valueForKey:@"atomindex"]];
	}

	//go through the external connections. Zeros indicate no connection. If there is something
	//other than zero then this must be a monomer 

	connectionEnum = [externalConnections objectEnumerator];
	while((connection = [connectionEnum nextObject]))
	{
		if(![connection isEqual: @"0"])
			return true;
	}

	return false;
}

- (bool) isMonomer
{
	if(monomerCheck == false)
	{
		isMonomer = [self _checkIfMonomer];
		monomerCheck = true;
	}

	return isMonomer;
}

-(AdDataMatrix*) connectivityMatrix
{
	return [[children objectAtIndex:1] connectivityMatrix];
}

-(AdDataMatrix*) connectivityMatrixWithOffset: (int) offset
{
	return [[children objectAtIndex:1] connectivityMatrixWithOffset: offset];
}

-(void) _createBondedAtomsList
{
	int  bondedIndex;
	NSMutableArray* bondedAtoms;
	NSArray *atomList;	
	NSEnumerator* rowEnum, *atomEnum;
	AdDataMatrix* connectivityMatrix;
	id atom, row, atomIndex;

	//get the connectivity matrix

	connectivityMatrix = [self connectivityMatrix];
	atomList = [[children objectAtIndex:0] children];
	
	//make an array of length number of atoms

	bondedAtomsList = [[NSMutableArray arrayWithCapacity: [atomList count]] retain];

	//for each atom index search the connectivity
	//matrix for the atoms that are bonded to it
	//and place them in an array

	atomEnum = [atomList objectEnumerator];	
	while((atom = [atomEnum nextObject]))
	{
		bondedAtoms = [NSMutableArray arrayWithCapacity:1];
		atomIndex = [[atom attributes] valueForKey:@"index"];
		rowEnum = [connectivityMatrix rowEnumerator];
		while((row = [rowEnum nextObject]))
		{
			if((bondedIndex= [row indexOfObject: atomIndex]) != NSNotFound)
			{
				if(bondedIndex== 1)
					[bondedAtoms addObject: [row objectAtIndex:0]];
				else if(bondedIndex== 0)
					[bondedAtoms addObject: [row objectAtIndex:1]];
			}
		}
		
		[bondedAtomsList addObject: bondedAtoms];
	}
}

- (NSMutableArray*) bondedAtomsList
{
	if(bondedAtomsList == nil)
		[self _createBondedAtomsList];

	return [[bondedAtomsList copy] autorelease];
}	

- (NSMutableArray*) bondedAtomsListWithOffset: (int) offset
{
	int offsetIndex;
	id bondedIndex, bondedAtoms;
	NSMutableArray* list, *offsetBondedIndexes;
	NSEnumerator* bondedAtomsEnum, *indexEnum;	

	list = [NSMutableArray arrayWithCapacity: 1];

	if(bondedAtomsList == nil)
		[self _createBondedAtomsList];

	bondedAtomsEnum = [bondedAtomsList objectEnumerator];
	while((bondedAtoms = [bondedAtomsEnum nextObject]))
	{
		offsetBondedIndexes = [NSMutableArray arrayWithCapacity:1];
		indexEnum = [bondedAtoms objectEnumerator];
		while((bondedIndex= [indexEnum nextObject]))
		{
			offsetIndex = [bondedIndex intValue] + offset;
			[offsetBondedIndexes addObject: [NSNumber numberWithInt: offsetIndex]];	
		}
		[list addObject: offsetBondedIndexes];
	}

	return list;
}	

/**
\note This method assumes that the last two children
are the external connection nodes and the first of these
is in and the second out. (Feeling lazy...)
*/

- (int) connectionForDirection: (NSString*) direction
{
	if([direction isEqual: @"In"])
	{
		return [[[[children objectAtIndex: 2] attributes] 
				valueForKey:@"atomindex"] intValue];
	}
	else if([direction isEqual: @"Out"])
	{
		return [[[[children objectAtIndex: 3] attributes] 
				valueForKey:@"atomindex"] intValue];
	}

	NSLog(@"Direction %@ is not valid", direction);
	return -1;
}

@end
