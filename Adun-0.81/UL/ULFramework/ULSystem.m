/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 14:11:40 +0200 by michael johnston

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

#include "ULFramework/ULSystem.h"
#include <AdunKernel/AdunDataSource.h>

@implementation ULSystem

- (id) init
{
	NSWarnLog(@"ULSystem is deprecated. Use AdDataSource");
	[self release];
	return [AdDataSource new];
}

- (void) dealloc
{
	[super dealloc];
}

//Method for converting ULSystem to AdDataSource
- (id) createDataSourceFromConfiguration: (id) configuration topology: (id) topology
{
	int i, elementsPerInteraction;
	AdMutableDataMatrix *elementProperties, *matrix, *groups, *parameters, *coordinates;
	AdMutableDataSource* dataSource;
	NSArray *headers;
	NSEnumerator* bondedEnum;
	id  bondedTop, column;
	
	headers = [NSArray arrayWithObjects: @"ForceFieldName",
			@"PDBName",
			@"PartialCharge",
			@"Mass",
			nil];

	//Element Information

	coordinates = [configuration valueForKey: @"Coordinates"];
	[coordinates setName: @"Coordinates"];
	
	elementProperties = [AdMutableDataMatrix new];
	[elementProperties autorelease];		
	[elementProperties extendMatrixWithColumn: 
		[configuration objectForKey: @"LibraryNames"]];
	[elementProperties extendMatrixWithColumn:
		[configuration objectForKey: @"AtomNames"]];
	[elementProperties extendMatrixWithColumn:
		[configuration objectForKey: @"PartialCharges"]];
	[elementProperties extendMatrixWithColumn:
		[configuration objectForKey: @"Masses"]];
	[elementProperties setColumnHeaders: headers];
	[elementProperties setName: @"ElementProperties"];
	
	//Add the van der waals parameters to the elementProperties
	//The first column is just indexes

	matrix = [topology valueForKeyPath: @"Nonbonded.VDWParameters.Matrix"];
	for(i=1; i<[matrix numberOfColumns]; i++)
	{
		column = [matrix column: i];
		[elementProperties extendMatrixWithColumn: column];
	}	
	
	[elementProperties setHeaderOfColumn: 4 to: @"VDWParameter A"]; 
	[elementProperties setHeaderOfColumn: 5 to: @"VDWParameter B"]; 
	
	dataSource = [[AdMutableDataSource alloc] initWithElementProperties: elementProperties
			configuration: coordinates];
	[dataSource autorelease];
	
	//Add interactions

	bondedEnum = [[topology valueForKey: @"Bonded"] objectEnumerator];
	while((bondedTop = [bondedEnum nextObject]))
	{
		elementsPerInteraction = [[bondedTop objectForKey: @"ElementsPerInteraction"] intValue];
		groups = [[AdMutableDataMatrix new] autorelease];
		parameters = [[AdMutableDataMatrix new] autorelease];
		matrix = [bondedTop objectForKey: @"Matrix"];
		if([matrix numberOfRows] > 0)
		{
			for(i=0; i<elementsPerInteraction; i++)
				[groups extendMatrixWithColumn: [matrix column: i]];

			for(i=elementsPerInteraction; i<[matrix numberOfColumns]; i++)
				[parameters extendMatrixWithColumn: [matrix column: i]];

			[dataSource addInteraction: [bondedTop objectForKey: @"InteractionType"]
				withGroups: groups
				parameters: parameters
				constraint: nil
				toCategory: @"Bonded"];
		}		
	}

	[dataSource addInteraction: @"TypeOneVDWInteraction"
		withGroups: nil
		parameters: nil
		constraint: nil
		toCategory: @"Nonbonded"];
	[dataSource addInteraction: @"CoulombElectrostatic"
		withGroups: nil
		parameters: nil
		constraint: nil
		toCategory: @"Nonbonded"];

	[dataSource setNonbondedPairs: [topology valueForKeyPath: @"Nonbonded.Interactions"]];

	int sequenceNumber, residueNumber;
	NSEnumerator* sequenceEnum, *residueEnum;
	AdMutableDataMatrix* groupProperties;
	NSMutableArray* array;
	id sequence, residue;

	sequenceEnum = [[configuration objectForKey: @"Sequences"] objectEnumerator];
	sequenceNumber = residueNumber = 0;
	array = [NSMutableArray array];
	groupProperties = [AdMutableDataMatrix new];
	[groupProperties autorelease];
	
	//The number of atoms per residue was not encode for old systems unlike new ones
	
	while((sequence = [sequenceEnum nextObject]))
	{
		residueEnum = [sequence objectEnumerator];
		while((residue = [residueEnum nextObject]))
		{
			[array addObject: residue];
			[array addObject: [NSNumber numberWithInt: sequenceNumber]];
			[groupProperties extendMatrixWithRow: array];
			residueNumber++;
			[array removeAllObjects];
		}		
				
		sequenceNumber++;		
	}

	[groupProperties setColumnHeaders: 
		[NSArray arrayWithObjects:
			@"Residue Name",
			@"Chain", 
			nil]];

	[dataSource setGroupProperties: groupProperties];

	return [[dataSource copy] autorelease];
}

/*
 * We preserve the decoding methods so we can update
 * archived ULSystems to AdDataSources
 */

- (NSMutableArray*) _decodeArrayOfDoublesForKey: key usingCoder: (NSCoder*) decoder
{
	int i, numberElements;
	unsigned int bytesLength;
	double* bytes;
	NSMutableArray* array;

	bytes = (double*)[decoder decodeBytesForKey: key returnedLength: &bytesLength];
	array = [NSMutableArray arrayWithCapacity: 1];
	numberElements = bytesLength/sizeof(double);
	for(i=0; i<numberElements; i++)
		[array addObject: [NSNumber numberWithDouble: bytes[i]]];	

	return array;
}

- (NSMutableArray*) _decodeArrayOfStringsForKey: key usingCoder: (NSCoder*) decoder
{
	id array;
	id string;

	string = [decoder decodeObjectForKey: key];
	array = [string componentsSeparatedByString: @"\\"];
	return array;
}

- (id) _decodeBondedAtomsWithCoder: (NSCoder*) decoder
{
	int i, j, check;
	int numberElements, count;
	unsigned int length;
	int* numberBondedAtomsArray;
	int* bondedAtomsArray;
	NSMutableArray* bondedAtoms, *list;
	NSNumber* index;

	numberBondedAtomsArray = (int*)[decoder decodeBytesForKey: @"NumberBondedAtomsArray"
						returnedLength: &length];
	numberElements = length/sizeof(int);
	bondedAtomsArray = (int*)[decoder decodeBytesForKey: @"BondedAtomsArray"
					returnedLength: &length];
	check = length/sizeof(int);	

	bondedAtoms = [NSMutableArray arrayWithCapacity:1];
	for(i=0, count = 0; i<numberElements; i++)
	{
		list = [NSMutableArray arrayWithCapacity:1];
		for(j=0; j<numberBondedAtomsArray[i]; j++)
		{
			index = [NSNumber numberWithInt: bondedAtomsArray[count]];
			[list addObject: index];
			count++;
		}
		[bondedAtoms addObject: list];
	}

	if(check!=count)
		[NSException raise: NSInternalInconsistencyException
			format: [NSString stringWithFormat:
			 @"Bonded atoms decode - Decoded %d indexes. Used %d.", check, count]];

	return bondedAtoms;

}

- (NSArray*) _decodeIndexArrayForKey: (NSString*) key usingCoder: (NSCoder*) decoder
{
	int i, j, count;
	int totalRanges, totalSets;
	unsigned int length;
	int* rangesPerSet;
	NSRange* totalRangeArray, *rangeArray;
	NSIndexSet* set;
	id array;

	totalRangeArray = (NSRange*)[decoder decodeBytesForKey: key returnedLength: &length];
	totalRanges = length/sizeof(NSRange);
	rangesPerSet = (int*)[decoder decodeBytesForKey:
				[NSString stringWithFormat: @"%@.RangesPerSet", key] 
				returnedLength: &length];
	totalSets = length/sizeof(int);

	array = [NSMutableArray arrayWithCapacity: 1];

	for(count = 0, i=0; i<totalSets; i++)
	{
		rangeArray = (NSRange*)malloc(rangesPerSet[i]*sizeof(NSRange));
		for(j=0; j<rangesPerSet[i]; j++)
		{	
			rangeArray[j] = totalRangeArray[count];
			count++;
		}
		set = [NSIndexSet indexSetFromRangeArray: rangeArray 
				ofLength: rangesPerSet[i]];
		[array addObject: set];
		free(rangeArray);
	}

	if(totalRanges != count)
		[NSException raise: NSInternalInconsistencyException
			format: [NSString stringWithFormat: 
			@"Did not decode the same number of ranges encoded. %d %d", count, totalRanges]];
	
	return array;
}

- (id) _decodeInteractionForKey: (NSString*) key usingCoder: (NSCoder*) decoder 
{
	NSMutableDictionary* interaction;
	id object;

	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	object = [decoder decodeObjectForKey: 
			[NSString stringWithFormat: @"%@.ElementsPerInteraction", key]];
	[interaction setObject: object forKey: @"ElementsPerInteraction"];
	object = [decoder decodeObjectForKey: 
			[NSString stringWithFormat: @"%@.InteractionsPerResidue", key]];
	[interaction setObject: object forKey: @"InteractionsPerResidue"];
	object = [decoder decodeObjectForKey: 
			[NSString stringWithFormat: @"%@.InteractionType", key]];
	[interaction setObject: object forKey: @"InteractionType"];
	object = [decoder decodeObjectForKey: 
			[NSString stringWithFormat: @"%@.Matrix", key]];
	[interaction setObject: object forKey: @"Matrix"];
	object = [self _decodeIndexArrayForKey:
			[NSString stringWithFormat: @"%@.ResidueInteractions", key]
			usingCoder: decoder];
	[interaction setObject: object forKey: @"ResidueInteractions"];

	return interaction;
}

- (id) initWithCoder: (NSCoder*) decoder
{
	id object, interaction;
	id bondedInteractionKeys, bondedInteractions;	
	id nonbondedInteractionKeys, nonbondedInteractions;
	id bondedAtoms;
	NSEnumerator* interactionsEnum;
	AdDataSource* dataSource;
	NSMutableDictionary* configuration, *topology;

	[super initWithCoder: decoder];

	if([decoder allowsKeyedCoding])
	{
		configuration = [NSMutableDictionary dictionary];
		object = [decoder decodeObjectForKey: @"Coordinates"];
		[configuration setObject: object forKey: @"Coordinates"];
		object = [self _decodeArrayOfStringsForKey: @"AtomNames" usingCoder: decoder]; 
		[configuration setObject: object forKey: @"AtomNames"];
		object = [self _decodeArrayOfStringsForKey: @"LibraryNames" usingCoder: decoder]; 
		[configuration setObject: object forKey: @"LibraryNames"];
		object = [self _decodeArrayOfDoublesForKey: @"PartialCharges" usingCoder: decoder]; 
		[configuration setObject: object forKey: @"PartialCharges"];
		object = [self _decodeArrayOfDoublesForKey: @"Masses" usingCoder: decoder]; 
		[configuration setObject: object forKey: @"Masses"];
		object = [decoder decodeObjectForKey: @"Sequences"];
		[configuration setObject: object forKey: @"Sequences"];
	
		//bonded atoms		

		bondedAtoms = [self _decodeBondedAtomsWithCoder: decoder];
		[configuration setObject: bondedAtoms forKey: @"BondedAtoms"];
		
		topology = [NSMutableDictionary dictionary];

		bondedInteractionKeys = [decoder decodeObjectForKey:@"BondedInteractions"];
		bondedInteractions = [NSMutableDictionary dictionaryWithCapacity:1];
		interactionsEnum = [bondedInteractionKeys objectEnumerator];
		while((interaction = [interactionsEnum nextObject]))
		{
			object = [self _decodeInteractionForKey: interaction usingCoder: decoder];
			[bondedInteractions setObject: object forKey: interaction];
		}
		[topology setObject: bondedInteractions forKey: @"Bonded"];

		nonbondedInteractionKeys = [decoder decodeObjectForKey:@"NonbondedInteractions"];
		nonbondedInteractions = [NSMutableDictionary dictionaryWithCapacity:1];
		interactionsEnum = [nonbondedInteractionKeys objectEnumerator];
		while((interaction = [interactionsEnum nextObject]))
		{
			if([interaction isEqual: @"Interactions"])
			{
				object = [self _decodeIndexArrayForKey: @"InteractionsArray"
						usingCoder: decoder];
				[nonbondedInteractions setObject: object forKey: interaction];
			}
			else
			{
				object = [self _decodeInteractionForKey: interaction	
						usingCoder: decoder];
				[nonbondedInteractions setObject: object forKey: interaction];
			}
		}
		[topology setObject: nonbondedInteractions forKey: @"Nonbonded"];
	}
	else
	{
		NSWarnLog(@"Non keyed coding not supported");
		[self release];
		return nil;
	}

	dataSource = [self createDataSourceFromConfiguration: configuration
			topology: topology];

	[self release];

	return dataSource;
}


- (void) encodeWithCoder: (NSCoder*) encoder
{
	NSWarnLog(@"Deprecated");
}

@end
