/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-06 12:17:25 +0200 by michael johnston

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

#include "ULFramework/ULTopologyFrameBuilder.h"
#include "XMLLib/XMLLib.h"

static NSDictionary* iupacToPDBMap;

@implementation ULTopologyFrameBuilder

+ (void) initialize
{
	NSString* path;
	NSDictionary* defaults;

	path =  [[[NSBundle bundleForClass: [self class]] resourcePath] 	
				stringByAppendingPathComponent: @"iupacPdbMap.plist"];
	iupacToPDBMap = [NSDictionary dictionaryWithContentsOfFile: path];
	[iupacToPDBMap retain];
	
	defaults = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] 
			forKey: @"AssumeRemediatedHydrogenNames"];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
}

- (NSArray*) _convertIUPACToPDB: (NSArray*) array forMolecule: (NSString*) molecule
{
	NSDictionary* map;
	NSMutableArray* pdbArray;
	NSEnumerator* arrayEnum;
	NSString* pdbName, *iupacName;

	map = [iupacToPDBMap objectForKey: molecule];
	//If there is no map return the original array
	if(map == nil)
		return array;

	pdbArray = [NSMutableArray array];
	arrayEnum = [array objectEnumerator];
	while((iupacName = [arrayEnum nextObject]))
	{
		pdbName = [map objectForKey: iupacName];
		if(pdbName == nil)
		{
			[buildString appendFormat: @"Couldnt find pdb name for iupac name %@ in %@. Probable iupac name error.\n",
				iupacName,
				molecule];
			//If the pdb name couldnt be found use the iupac name.
			//Just use the iupac name.
			[pdbArray addObject: iupacName];
		}
		else
			[pdbArray addObject: pdbName];
	}

	return pdbArray;	
}

- (NSArray*) _getMoleculeNodesForSequence: (NSArray*) sequence
{
	NSEnumerator* seqEnum;
	id mol, class, node;
	NSMutableArray* moleculeNodes, *missingMolecules;

	moleculeNodes = [NSMutableArray array];
	missingMolecules = [NSMutableArray array];
	//huduhduhduhduh 
	class =[[[[[[topologyLibrary children] objectAtIndex:0] children] objectAtIndex:1] children] objectAtIndex:0];
	seqEnum = [sequence objectEnumerator];

	while((mol = [seqEnum nextObject]))
	{	
		node = [class findMoleculeNodeWithName: mol];
		if(node == nil)
		{
			NSWarnLog(@"Couldnt find residue - %@ - in library!", mol);
			//this is redundant - cant remember what is was for ...
			[moleculeNodes addObject: @"Missing"];
			if(![missingMolecules containsObject: mol])
				[missingMolecules addObject: mol];
		}
		else
			[moleculeNodes addObject: node];
	}

	if([missingMolecules count] != 0)
		[NSException raise: @"ULBuildException"
			format: 
			@"The following residues were not in the library\n%@\n", missingMolecules]; 
	
	return moleculeNodes;
}

- (id) initForForceField: (NSString*) aString
{
	NSString* topPath;
	NSString* topologyFileName;

	if(self == [super init])
	{
		if(aString == nil)
		{
			forceField = [[NSUserDefaults standardUserDefaults]
					objectForKey: @"DefaultForceField"];
			if(forceField == nil)
				forceField = @"Enzymix";

		}
		else
			forceField = aString;

		[forceField retain];

		topologyFileName = [NSString stringWithFormat: @"%@Topology.ffml",
					forceField];

		NSDebugLLog(@"ULTopologyFrameBuilder", 
			@"Using topology library %@", topologyFileName);
		topPath = [[[NSBundle bundleForClass: [self class]] resourcePath] 	
				stringByAppendingPathComponent: @"ForceFields"];
		topPath = [topPath stringByAppendingPathComponent: forceField];
		topPath = [topPath stringByAppendingPathComponent: topologyFileName];

		NSDebugLLog(@"ULTopologyFrameBuilder", 
			@"Creating document tree from %@", topPath);
		topologyLibrary = [[ULMolecularLibraryTree alloc] 
					documentTreeForXMLFile: topPath];
		NSDebugLLog(@"ULTopologyFrameBuilder", @"Complete.");

		if(topologyLibrary == nil)
		{
			[self release];
			[NSException raise: NSInternalInconsistencyException
				format: @"Unable to locate parameter library for force field %@",
				forceField];
		}		
	}	
	
	return self;
}

- (id) init
{
	return [self initForForceField: nil];
}

- (void) dealloc
{
	[forceField release];
	[topologyLibrary release];
	[super dealloc];
}

- (NSString*) forceField
{
	return [[forceField retain] autorelease];
}

- (id) buildTopologyForSystem: (NSArray*) sequences 
		withOptions: (NSDictionary*) options
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	int no_atoms, monomerCount, arrayIndexOffset;
	id nodeArray, atomHolder, node, sequence;
	NSMutableArray* pdbNameList, *libraryNameList, *residueList, *residueIndexes;
	NSMutableArray *atomsPerResidue, *bondedAtoms;
	NSMutableArray* connectArray, *partialCharges;
	NSMutableDictionary* topologyFrame;
	NSEnumerator *nodeEnum, *sequenceEnum;
	NSRange residueRange;

	sequenceEnum = [sequences objectEnumerator];
	pdbNameList = [NSMutableArray array];
	libraryNameList = [NSMutableArray array];
	residueList = [NSMutableArray array]; 	
	residueIndexes = [NSMutableArray array]; 
	atomsPerResidue = [NSMutableArray array]; 
	partialCharges = [NSMutableArray array]; 
	connectArray = [NSMutableArray array]; //for the interresidue connections
	bondedAtoms = [NSMutableArray array];

	[buildString release];
	buildString = [[NSMutableString stringWithCapacity: 1] retain];
	if(buildInfo != NULL)
		*buildInfo = buildString;

	NSDebugLLog(@"ULTopologyFrameBuilder", @"\nTopology Frame\n Chains %@", sequences);

	[buildString appendFormat: @"\nBuilding topology frame using %@Topology.ffml\n", forceField];

	no_atoms = 0;
	arrayIndexOffset = 1;
	while((sequence = [sequenceEnum nextObject]))
	{
		//have to add a handler here when the library is missing elements
		NSDebugLLog(@"ULTopologyFrameBuilder", @"Getting nodeArray");
		nodeArray = [self _getMoleculeNodesForSequence: sequence];
		[buildString appendString: @"Found all residues.\n"];
		NSDebugLLog(@"ULTopologyFrameBuilder", @"Complete");
		nodeEnum = [nodeArray objectEnumerator];
		
		//array index offset is 1 if the atom indices in the molecular library
		//being used start at 1 and zero if they start at zero. We want them
		//to start at 0 since these means that the indexes will correspond to 
		//the entries in atomList. Assuming for now that they start at 1 (typical fortran)
			
		monomerCount =  0;

		while((node = [nodeEnum nextObject]))
		{
			[residueList addObject: [node moleculeName]];

			/*
			 * There are two possible naming schemes for PDB hydrogens
			 * when the arrive here depending on how the user added them
			 *
			 * 1. Preremediation
			 *   This will work with Enzymix and with Charmm/Amber if
			 *   the default AssumeRemediatedHydrogenNames it NO
			 * 2. Postremediation
			 *   This will not work with Enzymix and will work by default
			 *   with Charmm/Amber (AssumeRemediatedHydrogenNames is YES)
			 */

			if([forceField isEqual:@"Enzymix"])
			{
				atomHolder = [node atomNamesFromExternalSource: @"PDB"];
			}
			else
			{
				atomHolder = [node atomNamesFromExternalSource: @"IUPAC"];
				if(![[NSUserDefaults standardUserDefaults] 
					boolForKey: @"AssumeRemediatedHydrogenNames"])
				{
					atomHolder = [self _convertIUPACToPDB: atomHolder
								  forMolecule: [node moleculeName]];
				}
			}

			[pdbNameList addObjectsFromArray: atomHolder];

			residueRange.location = [libraryNameList count];
			atomHolder = [node atomNames];
			[libraryNameList addObjectsFromArray: atomHolder];
			residueRange.length = [libraryNameList count] - residueRange.location;
			[residueIndexes addObject: [NSIndexSet indexSetWithIndexesInRange: residueRange]];

			[partialCharges addObjectsFromArray: [node partialCharges]];
			[atomsPerResidue addObject: [NSNumber numberWithInt: [atomHolder count]]];
		
			[bondedAtoms addObjectsFromArray: 
				[node bondedAtomsListWithOffset: no_atoms - arrayIndexOffset]];

			//handle the connections between monomer units

			if([node isMonomer])
			{
				if(monomerCount == 0)
				{
					[connectArray insertObject: 
						[NSNumber numberWithInt: 
						[node connectionForDirection: @"Out"] + no_atoms - arrayIndexOffset] 
						atIndex: 0];
					monomerCount++;
				}
				else
				{
					[connectArray insertObject:
						[NSNumber numberWithInt: 
						[node connectionForDirection: @"In"] + no_atoms - arrayIndexOffset]
						atIndex: 1];
						
					//we have an inter residue bond - add the atom indexes to the appropriate
					//bonded atoms list	

					[[bondedAtoms objectAtIndex: 
							[[connectArray objectAtIndex: 0] intValue]]
							addObject: [connectArray objectAtIndex: 1]];
					[[bondedAtoms objectAtIndex: 
							[[connectArray objectAtIndex: 1] intValue]]
							addObject: [connectArray objectAtIndex: 0]];
						
					[connectArray removeAllObjects];
					[connectArray insertObject: 
						[NSNumber numberWithInt: 
						[node connectionForDirection: @"Out"] + no_atoms - arrayIndexOffset]
						atIndex: 0];
					monomerCount++;
				}
			}	
			else
			{
				monomerCount = 0;
				[connectArray removeAllObjects];
			}

			no_atoms += [atomHolder count];
		}
	}

	NSDebugLLog(@"ULTopologyFrameBuilder", @"Residue names %@", residueList);
	NSDebugLLog(@"ULTopologyFrameBuilder", @"There are %d atoms", [libraryNameList count]);
	[buildString appendFormat: @"There are %d atoms in the topology frame\n", 
					[libraryNameList count]];
	[buildString appendFormat: @"\nCompleted topology frame build\n"];

	topologyFrame =  [NSMutableDictionary dictionaryWithCapacity:1];
	[topologyFrame setObject: pdbNameList forKey:@"AtomNames"];
	[topologyFrame setObject: libraryNameList forKey:@"LibraryNames"];
	[topologyFrame setObject: atomsPerResidue forKey:@"AtomsPerResidue"];
	[topologyFrame setObject: partialCharges forKey:@"PartialCharges"];
	[topologyFrame setObject: bondedAtoms forKey:@"BondedAtoms"];
	[topologyFrame setObject: residueIndexes forKey:@"ResidueIndexes"];
	[topologyFrame setObject: residueList forKey:@"ResidueList"];

	return topologyFrame;
}

@end


