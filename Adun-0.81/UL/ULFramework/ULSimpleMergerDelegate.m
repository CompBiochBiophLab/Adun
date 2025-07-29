/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-15 16:52:34 +0200 by michael johnston

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

#include "ULSimpleMergerDelegate.h"


@implementation ULSimpleMergerDelegate

-(void) _synchroniseFrameWithConfiguration
{
	int i, atomCount;
	id index, confNames, coordinates, obj;
	NSEnumerator* indexEnumerator;
	NSMutableArray* newNames;
	AdMutableDataMatrix *newCoords;

	//we need the atoms to be in the same order in the frame and the configuration
	//this means sorting the atom name list retrieved from the configuration file
	//and also sorting the coordinates matrix based on the frame.
	//The residues are in the correct order already. It is the order of the atoms
	//in each residue that we are correcting. 

	confNames = [configuration valueForKey:@"AtomNames"];
	coordinates = [[configuration valueForKey:@"Coordinates"] matrixRows];
	newNames = [NSMutableArray arrayWithCapacity: 1];
	newCoords = [[AdMutableDataMatrix alloc] initWithNumberOfColumns: 0
			columnHeaders: nil
			columnDataTypes: nil];
	[newCoords autorelease];		

	GSPrintf(buildOutput, @"\nBefore syncronisation\n");

	for(i = 0; i< [indexes count]; i++)
	{
		GSPrintf(buildOutput, @"%-8d%-12@%-12@\n",i, 
			[[topologyFrame valueForKey:@"AtomNames"] objectAtIndex: i],
			[indexes objectAtIndex: i]);
	}

	indexEnumerator = [indexes objectEnumerator];
	while((index = [indexEnumerator nextObject]))
	{
		if(![index isEqual: @"Missing"])	
		{
			obj = [confNames objectAtIndex: [index intValue]];
			[newNames addObject: obj];
			obj = [coordinates objectAtIndex: [index intValue]];
			[newCoords extendMatrixWithRow: obj];
		}
	}

	[configuration setObject: newNames forKey:@"AtomNames"];
	[configuration setValue: newCoords forKey: @"Coordinates"];

	GSPrintf(buildOutput, @"\nSynchronising\n");
	
	//renumber indexes to reflect changes

	for(atomCount = 0, i=0; i<[indexes count]; i++)
		if(![[indexes objectAtIndex: i] isEqual: @"Missing"])
		{
			[indexes removeObjectAtIndex: i];
			[indexes insertObject: [NSNumber numberWithInt: atomCount] 
				atIndex: i];
			atomCount++;
		}

	for(i = 0; i< [indexes count]; i++)
	{
		GSPrintf(buildOutput, @"%-8d%-12@%-12@\n",i, 
			[[topologyFrame valueForKey:@"AtomNames"] objectAtIndex: i],
			[indexes objectAtIndex: i]);
	}
	GSPrintf(buildOutput, @"\n");

}

- (id) _updateConfiguration
{	
	unsigned int* buffer;

	//we have to remove the partial charges of the atoms that are missing
	//unfortuantly gnustep has yet to implement removeObjectsWithIndexes: :-()

	buffer = malloc([totalMissingAtoms count]*sizeof(int));
	[totalMissingAtoms getIndexes: buffer 
			maxCount: [totalMissingAtoms count]
			inIndexRange: NULL];
	[[topologyFrame valueForKey: @"PartialCharges"] 
			removeObjectsFromIndices: buffer numIndices: [totalMissingAtoms count]];
	[[topologyFrame valueForKey: @"LibraryNames"] 
			removeObjectsFromIndices: buffer numIndices: [totalMissingAtoms count]];
	free(buffer);
	
	[configuration setValue: [topologyFrame valueForKey:@"LibraryNames"] forKey: @"LibraryNames"];
	[configuration setValue: [topologyFrame valueForKey:@"PartialCharges"] forKey: @"PartialCharges"];
	[configuration setValue: [topologyFrame valueForKey:@"BondedAtoms"] forKey: @"BondedAtoms"];

	NSDebugLLog(@"ULSimpleMergerDelegate", @"There are %d library names", 
			[[configuration valueForKey: @"LibraryNames"] count]);
	NSDebugLLog(@"ULSimpleMergerDelegate", @"There are %d pdb names",
			 [[configuration valueForKey: @"AtomNames"] count]);
	NSDebugLLog(@"ULSimpleMergerDelegate", @"There are %d partial charges", 
			[[configuration valueForKey: @"PartialCharges"] count]);

	return configuration;
}

//FIXME: This shouldnt begin with init

- (void) initWithConfiguration: (NSDictionary*) conf topologyFrame: (NSDictionary*) frame
{
	id path;

	configuration = conf;
	topologyFrame = frame;	

	if(indexes == nil)
		indexes = [[NSMutableArray arrayWithCapacity:1] retain];
	else
		[indexes removeAllObjects];

	if(totalMissingAtoms == nil)
		totalMissingAtoms = [[NSMutableIndexSet indexSet] retain];
	else	
		[totalMissingAtoms removeAllIndexes];

	numberOfResidues = [[topologyFrame valueForKey:@"ResidueList"] count];	
	bondedAtomsList = [topologyFrame valueForKey:@"BondedAtoms"];
	
	path = [[NSUserDefaults standardUserDefaults] stringForKey: @"BuildOutput"];
	buildOutput = fopen([path cString], "a");
	
	if(extraAtomsDict == nil)
		extraAtomsDict = [[NSMutableDictionary dictionary] retain];
	else
		[extraAtomsDict removeAllObjects];

	if(missingAtomsDict == nil)
		missingAtomsDict = [[NSMutableDictionary dictionary] retain];
	else 
		[missingAtomsDict removeAllObjects];
}

- (void) dealloc
{
	NSWarnLog(@"Implement!");
	[super dealloc];
}

- (void) matchedConfigurationAtom: (int) confAtomIndex toTopologyAtom: (int) topAtomIndex
{
	[indexes addObject: [NSNumber numberWithInt: confAtomIndex]];
}

- (void) foundTopologyAtomNotInConfiguration: (int) topIndex
{
	[indexes addObject: @"Missing"];
	[missingAtoms addObject: [NSNumber numberWithInt: topIndex]];
	[totalMissingAtoms addIndex: topIndex];
}

- (void) foundMoleculeWithExtraAtoms: (int) confMoleculeIndex
{

}

- (void) foundDuplicateConfigurationAtoms: (NSArray*) confAtomIndexes
{

}

- (void) foundConfigurationAtomNotInTopology: (int) confIndex
{
	[unidentifiedAtoms addObject: [NSNumber numberWithInt: confIndex]];
}

- (id) finalise
{
	int i, j;
	int oldValue, newValue;
	unsigned int* buffer;
	id bondedAtoms, newConf;
	
	//synchronize the pdb atom order with the frame atom order

	[self _synchroniseFrameWithConfiguration];
	
	//now remove all the missing atoms from the bondedAtomList
	
	buffer = malloc([totalMissingAtoms count]*sizeof(int));
	[totalMissingAtoms getIndexes: buffer 
			maxCount: [totalMissingAtoms count]
			inIndexRange: NULL];
	[bondedAtomsList removeObjectsFromIndices: buffer numIndices: [totalMissingAtoms count]];
	free(buffer);
	
	//renumber the connectivity matrix

	for(i=0; i<[bondedAtomsList count]; i++)
	{
		bondedAtoms  = [bondedAtomsList objectAtIndex: i];

		NSDebugLLog(@"ULSimpleMergerDelegate", @"Atom number %d (%@)", i, 
				[[configuration valueForKey:@"AtomNames"] objectAtIndex: i]);
		NSDebugLLog(@"ULSimpleMergerDelegate", @"Bonded atoms %@", bondedAtoms);

		for(j=0; j < [bondedAtoms count]; j++)
		{
			oldValue = [[bondedAtoms objectAtIndex: j] intValue];
			newValue = [[indexes objectAtIndex: oldValue] intValue];
			NSDebugLLog(@"ULSimpleMergerDelegate", @"Old value %d (%@)", oldValue, 
					[[topologyFrame valueForKey:@"AtomNames"] objectAtIndex: oldValue]);
			NSDebugLLog(@"ULSimpleMergerDelegate", @"New value %d (%@)", newValue, 
					[[configuration valueForKey:@"AtomNames"] objectAtIndex: newValue]);
			[bondedAtoms removeObjectAtIndex: j];
			[bondedAtoms insertObject: [NSNumber numberWithInt: newValue] 
				atIndex: j];
		}
	}

	newConf = [self _updateConfiguration];
	fclose(buildOutput);
	return newConf;
}

- (void) didBeginMolecule: (int) index
{
	if(missingAtoms == nil)
		missingAtoms = [[NSMutableArray arrayWithCapacity:1] retain];
	else
		[missingAtoms removeAllObjects];

	if(unidentifiedAtoms == nil)
		unidentifiedAtoms = [[NSMutableArray arrayWithCapacity:1] retain];
	else
		[unidentifiedAtoms removeAllObjects];

	currentResidueIndex = index;
}

- (void) didEndMolecule: (int) index
{
	int newAtomsInResidue;
	NSEnumerator* missingAtomEnum, *bondedAtomsEnum, *anEnum;
	id atom, bondedAtoms,anObj, bondedAtom, list;
	id residueName, atomName, atomList;

	if([missingAtoms count] != 0)
	{
		GSPrintf(buildOutput , @"\nConfiguration residue %d is missing atoms %@\n", index, missingAtoms);
		residueName = [[topologyFrame objectForKey: @"ResidueList"] objectAtIndex: index];
		atomList = [NSMutableArray array];
		[missingAtomsDict setObject: atomList 
			forKey: [NSString stringWithFormat: @"%@%d", residueName, index]];
		anEnum = [missingAtoms objectEnumerator];
		while((anObj = [anEnum  nextObject]))
		{
			atomName =  [[topologyFrame valueForKey:@"AtomNames"] 
						objectAtIndex: [anObj intValue]];
			[atomList addObject: atomName];
			GSPrintf(buildOutput, @"%@ ", atomName);
		}
		GSPrintf(buildOutput,@"\n");	
	}

	if([unidentifiedAtoms count] != 0)
	{
		GSPrintf(buildOutput, @"Configuration residue %d contains unidentified atoms (%@)\n", 
				index, unidentifiedAtoms);
		residueName = [[topologyFrame objectForKey: @"ResidueList"] objectAtIndex: index];
		atomList = [NSMutableArray array];
		[extraAtomsDict setObject: atomList 
			forKey: [NSString stringWithFormat: @"%@%d", residueName, index]];
		anEnum = [unidentifiedAtoms objectEnumerator];
		while((anObj = [anEnum  nextObject]))
		{
			atomName = [[configuration valueForKey:@"AtomNames"] 
					objectAtIndex: [anObj intValue]];
			[atomList addObject: atomName];
			GSPrintf(buildOutput, @"%@ ", atomName);
		}
		GSPrintf(buildOutput, @"\n");	
	}
	
	//remove from the connectivity matrix
	//all references to the missing atoms	

	missingAtomEnum = [missingAtoms objectEnumerator];
	while((atom = [missingAtomEnum nextObject]))
	{
		//get the atoms bonded to the missing atom

		bondedAtoms = [bondedAtomsList objectAtIndex: [atom intValue]];
		bondedAtomsEnum = [bondedAtoms objectEnumerator];

		while((bondedAtom = [bondedAtomsEnum nextObject]))
		{
			list = [bondedAtomsList objectAtIndex: [bondedAtom intValue]];
			[list removeObject: atom];
		}
	}

	//we have to update the configurations atomsPerResidue array if there are unidentified atoms
	//because those atoms will be removed from the atomName array and the coordinate matrix.
	//If we dont atomsPerResidue will be incorrect when we create the system object

	if([unidentifiedAtoms count] != 0)
	{
		//anObj is the atomPerResidue array
		anObj =  [configuration valueForKey:@"AtomsPerResidue"]; 
		newAtomsInResidue = [[anObj objectAtIndex: index] intValue] - [unidentifiedAtoms count];
		[anObj removeObjectAtIndex: index]; 
		[anObj insertObject: [NSNumber numberWithInt: newAtomsInResidue] atIndex: index];
	}

	fflush(buildOutput);
}

- (NSDictionary*) extraAtoms
{
	return extraAtomsDict;
}

- (NSDictionary*) missingAtoms
{
	return missingAtomsDict;
} 

@end
