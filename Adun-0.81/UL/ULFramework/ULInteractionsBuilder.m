/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-07-14 13:34:47 +0200 by michael johnston

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

#include <math.h>
#include <AdunKernel/AdunDefinitions.h>
#include "ULFramework/ULInteractionsBuilder.h"
#include "ULFramework/ULFrameworkFunctions.h"

static int sortIndexesByNames(id indexOne, id indexTwo, void* atomNames);

static int sortIndexesByNames(id indexOne, id indexTwo, void* atomNames)
{
	NSString* atomOneName, *atomTwoName;

	atomOneName = [(NSArray*)atomNames objectAtIndex: [indexOne intValue]];
	atomTwoName = [(NSArray*)atomNames objectAtIndex: [indexTwo intValue]];

	return [atomOneName compare: atomTwoName 
		options: NSCaseInsensitiveSearch];
}

/**
Protocol adopted by objects that supply information
on the interactions and parameters of a force field
\note This is a temporary protocol. It and all objects
that use it will be deprecated when  force fields are 
written in FFML 1.0.
*/
@protocol ULForceFieldInformation
- (NSArray*) interactions;
- (NSArray*) unitsForParametersOfInteraction: (NSString*) interaction;
- (NSArray*) namesOfParametersOfInteraction: (NSString*) interaction;
@end

/*
 * Theses objects provide information on a given force field.
 * In the future this informatio will be present in the force field
 * file.
 */

static NSDictionary* classMap;

@interface ULForceFieldInformation: NSObject
{
	NSMutableDictionary* unitsForInteraction;
	NSMutableDictionary* parametersForInteraction;
}
+ (id) objectForForceField: (NSString*) forceField;
@end

@interface ULEnzymixForceFieldInformation: ULForceFieldInformation <ULForceFieldInformation>
@end

@interface ULAmberForceFieldInformation: ULForceFieldInformation <ULForceFieldInformation>
@end

@interface ULCharmm27ForceFieldInformation: ULForceFieldInformation <ULForceFieldInformation>
@end

@implementation ULForceFieldInformation

+ (void) initialize
{
	classMap = [NSDictionary dictionaryWithObjectsAndKeys:
			[ULEnzymixForceFieldInformation class], @"Enzymix",
			[ULAmberForceFieldInformation class], @"Amber",
			[ULCharmm27ForceFieldInformation class], @"Charmm27",
			nil];
	[classMap retain];		
}

+ (id) objectForForceField: (NSString*) forceField
{
	Class class;

	class = [classMap objectForKey: forceField];
	if(class == nil)
		return nil;

	return [[class new] autorelease];	
}

@end

@implementation ULEnzymixForceFieldInformation

- (id) init
{
	NSArray* array;

	if((self = [super init]))
	{
		unitsForInteraction = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicBond"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicAngle"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"None", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"FourierTorsion"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicImproperTorsion"];
		array = [NSArray arrayWithObjects: @"KCalMol-2", @"KCalMol-2", nil];
		[unitsForInteraction setObject: array forKey: @"TypeOneVDWInteraction"];
		array = [NSArray arrayWithObjects: @"AMU", @"None", nil];
		[unitsForInteraction setObject: array forKey: @"Mass"];

		parametersForInteraction = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: @"Constant", @"Separation", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicBond"];
		array = [NSArray arrayWithObjects: @"Constant", @"Angle", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicAngle"];
		array = [NSArray arrayWithObjects: @"Constant", @"Periodicity", @"Phase", nil];
		[parametersForInteraction setObject: array forKey: @"FourierTorsion"];
		array = [NSArray arrayWithObjects: @"Constant", @"Angle", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicImproperTorsion"];
		array = [NSArray arrayWithObjects: @"VDW A", @"VDW B", nil];
		[parametersForInteraction setObject: array forKey: @"TypeOneVDWInteraction"];
		array = [NSArray arrayWithObjects: @"Mass", @"ElementNumber", nil];
		[parametersForInteraction setObject: array forKey: @"Mass"];
	}

	return self;
}

- (void) dealloc
{
	[unitsForInteraction release];
	[parametersForInteraction release];
	[super dealloc];
}

- (NSArray*) interactions
{
	return [[[unitsForInteraction allKeys]
		retain] autorelease];
}

- (NSArray*) unitsForParametersOfInteraction: (NSString*) interaction
{
	return [[[unitsForInteraction objectForKey: interaction]
		retain] autorelease];
}		

- (NSArray*) namesOfParametersOfInteraction: (NSString*) interaction
{
	return [[[parametersForInteraction objectForKey: interaction]
		retain] autorelease];
}

- (NSString*) vdwType
{
	return @"TypeOneVDWInteraction";
}

@end

@implementation ULAmberForceFieldInformation

- (id) init
{
	NSArray* array;

	if((self = [super init]))
	{
		unitsForInteraction = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicBond"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicAngle"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"None", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"FourierTorsion"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicImproperTorsion"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"TypeTwoVDWInteraction"];
		array = [NSArray arrayWithObjects: @"AMU", @"None", nil];
		[unitsForInteraction setObject: array forKey: @"Mass"];

		parametersForInteraction = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: @"Constant", @"Separation", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicBond"];
		array = [NSArray arrayWithObjects: @"Constant", @"Angle", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicAngle"];
		array = [NSArray arrayWithObjects: @"Constant", @"Periodicity", @"Phase", nil];
		[parametersForInteraction setObject: array forKey: @"FourierTorsion"];
		array = [NSArray arrayWithObjects: @"Constant", @"Angle", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicImproperTorsion"];
		array = [NSArray arrayWithObjects: @"VDW WellDepth", @"VDW Separation", nil];
		[parametersForInteraction setObject: array forKey: @"TypeTwoVDWInteraction"];
		array = [NSArray arrayWithObjects: @"Mass", @"ElementNumber", nil];
		[parametersForInteraction setObject: array forKey: @"Mass"];
	}

	return self;
}

- (void) dealloc
{
	[unitsForInteraction release];
	[parametersForInteraction release];
	[super dealloc];
}

- (NSArray*) interactions
{
	return [[[unitsForInteraction allKeys]
		retain] autorelease];
}

- (NSArray*) unitsForParametersOfInteraction: (NSString*) interaction
{
	return [[[unitsForInteraction objectForKey: interaction]
		retain] autorelease];
}

- (NSArray*) namesOfParametersOfInteraction: (NSString*) interaction
{
	return [[[parametersForInteraction objectForKey: interaction]
		retain] autorelease];
}

- (NSString*) vdwType
{
	return @"TypeTwoVDWInteraction";
}

@end

//Not ready yet
@implementation ULCharmm27ForceFieldInformation

- (id) init
{
	NSArray* array;

	if((self = [super init]))
	{
		unitsForInteraction = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicBond"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicAngle"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"None", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"FourierTorsion"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Degree", nil];
		[unitsForInteraction setObject: array forKey: @"HarmonicImproperTorsion"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"TypeTwoVDWInteraction"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"1-4Interaction"];
		array = [NSArray arrayWithObjects: @"KCalMol", @"Angstrom", nil];
		[unitsForInteraction setObject: array forKey: @"UreyBradley"];
		array = [NSArray arrayWithObjects: @"AMU", nil];
		[unitsForInteraction setObject: array forKey: @"Mass"];

		parametersForInteraction = [NSMutableDictionary new];
		array = [NSArray arrayWithObjects: @"Constant", @"Separation", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicBond"];
		array = [NSArray arrayWithObjects: @"Constant", @"Angle", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicAngle"];
		array = [NSArray arrayWithObjects: @"Constant", @"Periodicity", @"Phase", nil];
		[parametersForInteraction setObject: array forKey: @"FourierTorsion"];
		array = [NSArray arrayWithObjects: @"Constant", @"Angle", nil];
		[parametersForInteraction setObject: array forKey: @"HarmonicImproperTorsion"];
		array = [NSArray arrayWithObjects: @"VDW WellDepth", @"VDW Separation", nil];
		[parametersForInteraction setObject: array forKey: @"TypeTwoVDWInteraction"];
		array = [NSArray arrayWithObjects: @"1-4 VDW WellDepth", @"1-4 VDW Separation", nil];
		[parametersForInteraction setObject: array forKey: @"1-4Interaction"];
		array = [NSArray arrayWithObjects: @"Constant", @"Separation", nil];
		[parametersForInteraction setObject: array forKey: @"UreyBradley"];
		array = [NSArray arrayWithObjects: @"Mass", nil];
		[parametersForInteraction setObject: array forKey: @"Mass"];
	}

	return self;
}

- (void) dealloc
{
	[unitsForInteraction release];
	[parametersForInteraction release];
	[super dealloc];
}

- (NSArray*) interactions
{
	return [[[unitsForInteraction allKeys]
		retain] autorelease];
}

- (NSArray*) unitsForParametersOfInteraction: (NSString*) interaction
{
	return [[[unitsForInteraction objectForKey: interaction]
		retain] autorelease];
}

- (NSArray*) namesOfParametersOfInteraction: (NSString*) interaction
{
	return [[[parametersForInteraction objectForKey: interaction]
		retain] autorelease];
}

- (NSString*) vdwType
{
	return @"TypeTwoVDWInteraction";
}

@end

/*
 * ULInterfaceBuilder
 */

@interface ULInteractionsBuilder (TemporaryDataSourceConversions)
- (id) createDataSourceFromConfiguration: (id) configuration topology: (id) topology;
@end

@implementation ULInteractionsBuilder

/***
Converting Parameters
**/

- (NSArray*) convertParameters: (NSArray*) parameters withUnits: (NSArray*) units
{
	int i;
	NSMutableArray* convertedArray = [NSMutableArray array];
	id unit;
	double parameter, conversionConstant;

	if([parameters count] != [units count])
	{
		NSWarnLog(@"Parameters %@. Units %@", parameters, units);
		[NSException raise: NSInvalidArgumentException
			format: @"Number of parameters %d does not match number of units %d",
			[parameters count],
			[units count]];
	}

	//We want to convert energies to simulation units and degrees to radians
	//We cycle through the units and convert whichever ones we need
	
	for(i=0; i<(int)[units count]; i++)
	{
		unit = [units objectAtIndex: i];
		parameter = [[parameters objectAtIndex: i] doubleValue];
		if([unitsToConvert containsObject: unit])
		{
			conversionConstant = [[constantForUnit objectForKey:unit] 
						doubleValue];
			parameter *= conversionConstant;
		}

		[convertedArray addObject: 
			[NSNumber numberWithDouble: parameter]];
	}

	return convertedArray;
}

/************************

Finding parameters

************************/

//Necessary for improper torsion assignment
//Check that the trigonal atom matches the begining or end of the tag
//If trigonal atom matches, look for all possible combinations of atoms in the tag to match
//return the idices of the matching atoms in the "correct" order (parameter order)
//if no match retuns NULL
- ( NSArray * ) _matchImproperTorsion: (NSArray*) idStrings 
			 toParamLabel: (NSString*) idString fromRow: (id) row
{
	int i, number, index,trigonal;
	NSNumber *trigonalIndex;
	NSMutableArray *atomsTopo, *atomsParam;
	NSMutableDictionary *atomsTopoDic, *atomsParamDic;
	NSMutableArray *rowOut, *rowIn;
	id iObject;
	
	atomsParam = [NSMutableArray arrayWithCapacity:1]; 
	atomsTopo  = [NSMutableArray arrayWithCapacity:1];
	
	[atomsTopo addObjectsFromArray: 
         [idString componentsSeparatedByString: @" "]];
	
	[atomsParam addObjectsFromArray: 
         [[idStrings objectAtIndex: 0] componentsSeparatedByString: @" "]];
	
	//Dont do anything if parameters use only one atom
	if ( [atomsParam count ] < 4 )
		return NULL;
	
	//Check to see if the trigonal atom matches and remove it from the list
	//Charmm parameters have the trigonal atom at the begining or end
	
	if (![[atomsParam objectAtIndex: 0] isEqual: [atomsTopo objectAtIndex: 2]])
		if (![[atomsParam objectAtIndex: 3] isEqual: [atomsTopo objectAtIndex: 2]])
			return NULL;
	
	if ([[atomsParam objectAtIndex: 0] isEqual: [atomsTopo objectAtIndex: 2]] )
		trigonal = 0;
	else
		trigonal = 3;
		
	[atomsTopo removeObjectAtIndex: 2];
	[atomsParam removeObjectAtIndex: trigonal];
	
	rowIn =  [NSMutableArray arrayWithCapacity:1];
	[rowIn addObjectsFromArray: row];
	trigonalIndex = [ rowIn objectAtIndex: 2 ];
	[rowIn removeObjectAtIndex: 2 ];
	
	//check all permutations of the remaining 3 atom names
	atomsTopoDic = [NSMutableDictionary dictionaryWithCapacity:1];
	atomsParamDic = [NSMutableDictionary dictionaryWithCapacity:1];
	for( i=0;i<3;i++)
	{
		[atomsTopoDic setObject: [NSNumber numberWithInt: 0] 
				 forKey: [atomsTopo objectAtIndex: i]];
		[atomsParamDic setObject:[NSNumber numberWithInt: 0 ] 
				  forKey: [atomsParam objectAtIndex: i]];
	}
	
	for( i=0;i<3;i++)
	{  
		number =  [[atomsTopoDic objectForKey: [atomsTopo objectAtIndex: i]]
			   intValue ];
		number++;
		[atomsTopoDic setObject: [NSNumber numberWithInt: number] 
				 forKey: [atomsTopo objectAtIndex: i]];
		number =  [[atomsParamDic objectForKey: [atomsParam objectAtIndex: i]]
			   intValue];
		number++;
		[atomsParamDic setObject:[NSNumber numberWithInt: number] 
				  forKey: [atomsParam objectAtIndex: i]];
	}
	
	// if its a match place the atoms in the correct order (parameter order)
	if ( [ atomsTopoDic isEqualToDictionary: atomsParamDic] )
	{
		rowOut = [NSMutableArray arrayWithCapacity:4 ];
		for(i=0;i<3;i++)
		{
			iObject = [atomsParam objectAtIndex: i ];
			index = [atomsTopo indexOfObject: iObject ];
			[atomsTopo removeObjectAtIndex: index ];
			[rowOut addObject: [rowIn objectAtIndex: index ]];
			[rowIn removeObjectAtIndex: index ];
		}
		[rowOut insertObject: trigonalIndex atIndex: trigonal];
		return rowOut;
	}
	else
	{
		return NULL;
	}
}

/**
This is a workaround until FFML is fully developed.
We know we are working with Enzymix so we can make
certain assumptions here e.g. the diehedral interactions
note: Improper Torsions that have no parameters are removed
*/

- (void) _findParametersForInteractions: (NSDictionary*) topology ofAtoms: (NSMutableArray*) atomList
{
	int rowCount;
	id class, interaction, row, trow, atom;
	NSEnumerator *interactionEnum, *rowEnum, *atomEnum;	
	NSDictionary* topologyClassNodes;
	NSMutableArray* atomArray, *newRow;
	NSString* interactionType, *idString;
	NSMutableString* failString, *missingParams;
	NSMutableIndexSet* unknownInteractions;
	AdMutableDataMatrix* newMatrix;	//The matrix with parameters
	NSArray* convertedParameters, *interactionUnits, *idStrings;
	
	//get the correct topology information
	
	topologyClassNodes = [parameterLibrary topologiesForClass: @"generic"];
	
	NSDebugLLog(@"ULInteractionsBuilder", 
		    @"Finding parameters for %@", 
		    [topology valueForKey:@"InteractionType"]);
	
	rowEnum = [[topology valueForKey:@"Matrix"] rowEnumerator];
	class = [topologyClassNodes valueForKey:[topology valueForKey:@"InteractionType"]];
	atomArray  = [NSMutableArray arrayWithCapacity:1];
	interactionType = [topology valueForKey: @"InteractionType"];
	unknownInteractions = [NSMutableIndexSet indexSet];
	
	failString = [NSMutableString stringWithCapacity: 1];
	missingParams = [NSMutableString stringWithCapacity: 1];
	newMatrix = [[AdMutableDataMatrix new] autorelease];
	newRow = [NSMutableArray array];
	rowCount = 0;	
	interactionUnits = [forceFieldInfo unitsForParametersOfInteraction: interactionType];
	
	while((row = [rowEnum nextObject]))
	{
		//Hackity hack hack hack!
		//We also have to set an array explaining the units of 
		//the parameters to be returned.
		
		if([interactionType isEqual:@"FourierTorsion"] && 
		   [forceField isEqual:@"Enzymix"] )
		{
			[atomArray addObject: 
			 [atomList objectAtIndex: [[row objectAtIndex:1] intValue]]];
			[atomArray addObject: 
			 [atomList objectAtIndex: [[row objectAtIndex:2] intValue]]];
		}
		else if([interactionType isEqual:@"HarmonicImproperTorsion"] && 
			[forceField isEqual:@"Enzymix"])
		{
			[atomArray addObject: 
			 [atomList objectAtIndex: [[row objectAtIndex:2] intValue]]];
		}
		else
		{
			atomEnum = [row objectEnumerator];
			while((atom = [atomEnum nextObject]))
				[atomArray addObject:
				 [atomList objectAtIndex: [atom intValue]]];
		}
		
		idString = [atomArray componentsJoinedByString:@" "];
		interactionEnum = [[class children] objectEnumerator];
		while((interaction = [interactionEnum nextObject]))
		{
			idStrings = [interaction idStringsForInteraction];
			if ( [interactionType isEqual:@"HarmonicImproperTorsion"] )
			{ 
				// find if a improper torsion matches
				// Enzymix will just return NULL
				trow = [self _matchImproperTorsion: idStrings
						      toParamLabel: idString
							   fromRow: row ];
				// if trow is not NULL it means we found parameters therefore
				// place atoms in the right order and force a parameter match
				if ( trow != NULL)
				{
					row = trow;
					idString = [ idStrings objectAtIndex: 0 ];
				}
			}
			
			if([idStrings containsObject: idString])
			{
				[newRow removeAllObjects];
				[newRow addObjectsFromArray: [interaction parameters]];
				[newRow addObjectsFromArray: [interaction constraints]];
				
				//FFML 1.0 should return an array of paramters
				//Plus their names and their units. For now we have
				//to hack this part. We know were dealing with
				//Enyzmix so we could set the conversions above.
				
				convertedParameters = [self convertParameters: newRow 
								    withUnits: interactionUnits];
				[newRow removeAllObjects];			
				[newRow addObjectsFromArray: row];
				[newRow addObjectsFromArray: convertedParameters];
				[newMatrix extendMatrixWithRow: newRow];
				//Search for multiple matching lines for torsions only
				if (! ( [interactionType isEqual:@"FourierTorsion"] ||
				       [interactionType isEqual:@"HarmonicImproperTorsion"] ) )
					break;
			}
		}
		
		if([newRow count] == 0)
		{
			[missingParams appendString: @"("];
			[missingParams appendString: [atomArray componentsJoinedByString: @", "]];
			[missingParams appendFormat: @")\n"];	
			[unknownInteractions addIndex: rowCount];
		} 
		else
			[newRow removeAllObjects];
		
		[atomArray removeAllObjects];
		rowCount++;
	}
	
	// hack: 1-4 interactions and UB terms cannot have missing parameters
	if([missingParams length] > 0 && (![interactionType isEqual:  @"1-4Interaction"]  &&
					  ![interactionType isEqual:  @"UreyBradley"] ))
	{
		[failString appendFormat:
			@"\nUnable to find parameters for the following %@ interactions.\n",
			interactionType];
		[failString appendString: missingParams];
		
		if([interactionType isEqual: @"HarmonicBond"] || [interactionType isEqual: @"HarmonicAngle"])
		{
			GSPrintf(buildOutput, @"%@\n", failString);
			GSPrintf(buildOutput, @"Aborting build\n");
			[[NSException exceptionWithName: @"ULBuildException"
						 reason: [NSString stringWithFormat: @"Missing %@ parameters.", interactionType]
					       userInfo: [NSDictionary dictionaryWithObject: failString
								forKey: @"ULBuildExceptionDetailedDescriptionKey"]] 
			 raise];
		}
		else if ([interactionType isEqual: @"HarmonicImproperTorsion"]) 
		{
			GSPrintf(buildOutput, @"\nIgnore missing improper torsions for aromatic groups\n");
			GSPrintf(buildOutput, @"%@",failString);
		}
		else	
		{
			[errorString appendString: failString];
			[buildString appendFormat: @"\t\tRemoved %d %@ interactions.\nSee errors.\n", 
			 [unknownInteractions count],
			 interactionType];
		}
	}
	
	//set the new matrix
	[topology setValue: newMatrix forKey: @"Matrix"]; 
}

/*********************

Interaction Building

**********************/

- (id) _buildBondsForAtoms: (NSMutableArray*) atomNames withBondedAtoms: (NSMutableArray*) bondedAtomsList
{
	int i;
	NSEnumerator* bondedAtomsListEnum, *bondedAtomsEnum;
	NSMutableDictionary* interaction;
	NSMutableArray* row;
	id bondedAtoms, atomIndex;
	AdMutableDataMatrix* bondMatrix;

	bondMatrix = [[AdMutableDataMatrix alloc] 
			initWithNumberOfColumns: 0
			columnHeaders: nil
			columnDataTypes: nil];
	[bondMatrix autorelease];		
	bondedAtomsListEnum = [bondedAtomsList objectEnumerator];

	i = 0;
	while((bondedAtoms = [bondedAtomsListEnum nextObject]))
	{
		bondedAtomsEnum = [bondedAtoms objectEnumerator];
		while((atomIndex = [bondedAtomsEnum nextObject]))
			if([atomIndex intValue] > i)
			{
				row = [NSMutableArray arrayWithCapacity:2];
				[row addObject: [NSNumber numberWithInt: i]];
				[row addObject: atomIndex];
				[bondMatrix extendMatrixWithRow: row];
			}
		i++;
	}

	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"HarmonicBond" forKey: @"InteractionType"];
	[interaction setValue: [NSNumber numberWithInt: 2] forKey: @"ElementsPerInteraction"];
	[interaction setValue: bondMatrix forKey: @"Matrix"];
	[self _findParametersForInteractions: interaction ofAtoms: atomNames];

	GSPrintf(buildOutput, @"There are %d bonded interactions\n", [bondMatrix numberOfRows]);
	[buildString appendFormat: @"\t\tThere are %d bonds\n", [bondMatrix numberOfRows]];
	return interaction;
}

- (id) _buildAnglesForAtoms: (NSMutableArray*) atomNames withBondedAtoms: (NSMutableArray*) bondedAtomsList
{
	int i, j, atom;
	NSEnumerator *bondedAtomsListEnum;
	NSMutableArray *angle;
	NSMutableDictionary* interaction;
	AdMutableDataMatrix *angleMatrix;
	id bondedAtoms; 

	angleMatrix = [[AdMutableDataMatrix alloc] 
			initWithNumberOfColumns:0 
			columnHeaders: nil
			columnDataTypes: nil];
	[angleMatrix autorelease];		
	bondedAtomsListEnum = [bondedAtomsList objectEnumerator];

	atom = 0;	
	while((bondedAtoms = [bondedAtomsListEnum nextObject]))
	{
		if([bondedAtoms count] > 1)
			for(i=0; i<[bondedAtoms count] - 1; i++)
				for(j=i+1; j < [bondedAtoms count]; j++)	
				{
					angle = [NSMutableArray arrayWithCapacity: 3];
					[angle addObject: [bondedAtoms objectAtIndex: i]];
					[angle addObject: [NSNumber numberWithInt: atom]];
					[angle addObject: [bondedAtoms objectAtIndex: j]];
					[angleMatrix extendMatrixWithRow: angle];
				}
		atom++;
	}
	
	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"HarmonicAngle" forKey: @"InteractionType"];
	[interaction setValue: [NSNumber numberWithInt: 3] forKey: @"ElementsPerInteraction"];
	[interaction setValue: angleMatrix forKey: @"Matrix"];
	[self _findParametersForInteractions: interaction ofAtoms: atomNames];

	GSPrintf(buildOutput,@"There are %d angle interactions\n", [angleMatrix numberOfRows]);
	[buildString appendFormat: @"\t\tThere are %d angle interactions\n", [angleMatrix numberOfRows]];
	return interaction;
}


- (id) _buildTorsionsForAtoms: (NSMutableArray*) atomNames 
		withBondedAtoms: (NSMutableArray*) bondedAtomsList 
		bonds: (AdDataMatrix*) bondMatrix
{
	int atomOneIndex, atomTwoIndex, connections1, connections2;
	NSEnumerator* bondEnum, *arrayTwoEnum, *arrayOneEnum;
	AdMutableDataMatrix* torsionMatrix;
	NSMutableDictionary* interaction;
	NSMutableArray* torsion;
	id firstAtomIndex, lastAtomIndex, bond;

	bondEnum = [bondMatrix rowEnumerator];
	torsionMatrix = [[AdMutableDataMatrix alloc] 
				initWithNumberOfColumns: 0 
				columnHeaders: nil
				columnDataTypes: nil];	
	[torsionMatrix autorelease];			

	//now use the bond list to build the torsions
	//each bond is a possible torsion center

	while((bond = [bondEnum nextObject]))
	{
		atomOneIndex = [[bond objectAtIndex:0] intValue];
		atomTwoIndex = [[bond objectAtIndex:1] intValue];
		connections1 = [[bondedAtomsList objectAtIndex: atomOneIndex] count];
		connections2 = [[bondedAtomsList objectAtIndex: atomTwoIndex] count];

		if(connections1 > 1 && connections2 > 1)
		{
			arrayOneEnum = [[bondedAtomsList objectAtIndex: atomOneIndex] objectEnumerator];
			while((firstAtomIndex = [arrayOneEnum nextObject]))
				if([firstAtomIndex intValue] != atomTwoIndex)
				{ 
					arrayTwoEnum = [[bondedAtomsList objectAtIndex: atomTwoIndex] 
										objectEnumerator];
					while((lastAtomIndex = [arrayTwoEnum nextObject]))
						if([lastAtomIndex intValue] != atomOneIndex)
						{
							torsion = [NSMutableArray arrayWithCapacity: 4];
							[torsion addObject: firstAtomIndex];
							[torsion addObject: [bond objectAtIndex: 0]];
							[torsion addObject: [bond objectAtIndex: 1]];
							[torsion addObject: lastAtomIndex];	
							[torsionMatrix extendMatrixWithRow: torsion];
						}
				}
		}
	}
	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"FourierTorsion" forKey: @"InteractionType"];
	[interaction setValue: [NSNumber numberWithInt: 4] forKey: @"ElementsPerInteraction"];
	[interaction setValue: torsionMatrix forKey: @"Matrix"];
	[self _findParametersForInteractions: interaction ofAtoms: atomNames];

	GSPrintf(buildOutput, @"There are %d torsion interactions\n", [torsionMatrix numberOfRows]);
	[buildString appendFormat: @"\t\tThere are %d proper torsion interactions\n", [torsionMatrix numberOfRows]];
	return interaction;
}

/*
Improper Torsions Note:

The itor interactions have the center as the third atom.
The other atoms are in alphabetical order (AMBER convention applied to Enzymix).
Charmm puts the trigonal atom first or last
If we dont find parameters for the itor then it is removed
*/

- (id) _buildImproperTorsionsForAtoms: (NSMutableArray*) atomNames 
		withBondedAtoms: (NSMutableArray*) bondedAtomsList 
		bonds: (AdDataMatrix*) bondMatrix
{
	int i;
	id bondedAtoms;
	AdMutableDataMatrix* improperMatrix;
	NSMutableDictionary* interaction;
	NSMutableArray* itor;

	improperMatrix = [[AdMutableDataMatrix alloc]
				initWithNumberOfColumns: 0
				columnHeaders: nil
				columnDataTypes: nil];
	[improperMatrix autorelease];			

	//The possible improper torsions are atoms that have three bonds
	//So we simply search for each of these in bonded atoms list

	for(i=0; i<[bondedAtomsList count]; i++)
	{
		bondedAtoms = [bondedAtomsList objectAtIndex: i];
		if([bondedAtoms count] == 3)
		{
			itor = [NSMutableArray array];

			//do we need to define a particular order!?

			[itor addObject: [bondedAtoms objectAtIndex: 0]];
			[itor addObject: [bondedAtoms objectAtIndex: 1]];
			[itor addObject: [bondedAtoms objectAtIndex: 2]];
			[itor sortUsingFunction: sortIndexesByNames 
				context: (void*)atomNames];
			[itor insertObject: [NSNumber numberWithInt: i]
				   atIndex: 2];
			[improperMatrix extendMatrixWithRow: itor]; 
		}
	}
		
	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"HarmonicImproperTorsion"
		forKey: @"InteractionType"];
	[interaction setValue: [NSNumber numberWithInt: 4] 
		forKey: @"ElementsPerInteraction"];
	[interaction setValue: improperMatrix
		forKey: @"Matrix"];
	[self _findParametersForInteractions: interaction 
		ofAtoms: atomNames];

	GSPrintf(buildOutput, @"There are %d improper torsion interactions\n", [improperMatrix numberOfRows]);
	[buildString appendFormat: @"\t\tThere are %d improper torsion interactions\n",
		 [improperMatrix numberOfRows]];

	return interaction;
}

- (id) _buildVDWForAtoms: (NSMutableArray*) atomNames withBondedAtoms: (NSMutableArray*) bondedAtomsList
{
	int i;
	AdMutableDataMatrix* vdwMatrix;
	NSMutableDictionary* interaction;
	NSMutableArray* row;

	vdwMatrix = [[AdMutableDataMatrix alloc] 
			initWithNumberOfColumns: 0
			columnHeaders: nil
			columnDataTypes: nil];
	[vdwMatrix autorelease];		

	for(i=0; i<[atomNames count]; i++)
	{
		row = [NSMutableArray arrayWithCapacity: 1];
		[row addObject: [NSNumber numberWithInt: i]];
		[vdwMatrix extendMatrixWithRow: row];
	}

	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: [forceFieldInfo vdwType]
		forKey: @"InteractionType"];
	[interaction setValue: vdwMatrix forKey: @"Matrix"];
	[interaction setValue: [NSNumber numberWithInt: 1] forKey: @"ElementsPerInteraction"];
	[self _findParametersForInteractions: interaction ofAtoms: atomNames];

	return interaction;
}

- (id) _build14ForAtoms: (NSMutableArray*) atomNames 
		withBondedInteractions: (NSMutableArray*) bondedInteractions 
		withVDWAtoms: (NSMutableArray*) vdwAtomsList
{
	int i,index;
	int noAtoms,noTorsions,noList14;
	int firstatm,lastatm, noInteraction14;
	double eps1,eps2,rmin1,rmin2;
	NSMutableArray* list14; 
	AdMutableDataMatrix* vdw14Matrix, *matrix14;
	NSMutableArray* row;
	NSArray* matrixRow;
	NSMutableDictionary* interaction14, *params14, *params14Scaled;
	NSMutableIndexSet* indexes;
	NSNumber* atom1,* atom2;
	NSMutableDictionary* interaction;
	id torsions, itors,torMatrix;
	
	noAtoms = [atomNames count];
	vdw14Matrix = [AdMutableDataMatrix new];
	matrix14 = [AdMutableDataMatrix new];
	[matrix14 autorelease];
	
	row = [NSMutableArray array];
	for(i=0; i<noAtoms; i++)
	{
		[row addObject: [NSNumber numberWithInt: i]];
		[vdw14Matrix extendMatrixWithRow: row];
		[row removeAllObjects];
	}
	
	interaction14 = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction14 setValue: @"1-4Interaction" forKey: @"InteractionType"];
	[interaction14 setValue: vdw14Matrix forKey: @"Matrix"];
	[interaction14 setValue: [NSNumber numberWithInt: 1] forKey: @"ElementsPerInteraction"];
	[self _findParametersForInteractions: interaction14 ofAtoms: atomNames];   
	noInteraction14 =[ [interaction14 valueForKey:@"Matrix"] numberOfRows ];
	params14Scaled = [NSMutableDictionary dictionaryWithCapacity: noInteraction14  ];
	
	//create a dictionary with the scaled 1-4 VDW parameters
	for(i=0; i<noInteraction14; i++)
	{
		matrixRow = [ [interaction14 valueForKey:@"Matrix"] row: i];
		[ params14Scaled setObject: matrixRow forKey: [ matrixRow objectAtIndex: 0 ] ];
	}
	
	//create a dictionary with the std. VDW parameters
	noInteraction14 =[ [vdwAtomsList valueForKey:@"Matrix"] numberOfRows ];
	params14 = [NSMutableDictionary dictionaryWithCapacity: noInteraction14  ];
	for(i=0; i<noInteraction14; i++)
	{
		matrixRow = [ [vdwAtomsList valueForKey:@"Matrix"] row: i];
		[ params14 setObject: matrixRow forKey: [ matrixRow objectAtIndex: 0 ] ];
	}
	
	//create a list of 1-4 interactions using the torsion list
	list14 = [NSMutableArray arrayWithCapacity: 1];
	for(i=0; i<noAtoms-1; i++)
	{
		indexes = [NSMutableIndexSet indexSet ];
		[list14 addObject: indexes];
	}
	torsions = [ bondedInteractions valueForKey: @"FourierTorsion" ];
	torMatrix = [ torsions valueForKey:@"Matrix" ];
	noTorsions = [ torMatrix numberOfRows ];
	for(i=0; i<noTorsions; i++)
	{
		itors = [torMatrix row: i];
		firstatm = [[ itors objectAtIndex: 0 ] intValue];
		lastatm = [[ itors objectAtIndex: 3 ] intValue];
		if ( firstatm < lastatm )
			[ [ list14 objectAtIndex: firstatm ] addIndex: lastatm ];
		else
			[ [ list14 objectAtIndex: lastatm ] addIndex: firstatm ];
	}
	
	noList14 = 0;
	for(i=0; i<[list14 count]; i++)
		noList14 += [[list14 objectAtIndex:i] count];
	GSPrintf(buildOutput, @"There are %d 1-4 interactions\n", noList14);
	[buildString appendFormat: @"\t\tThere are %d 1-4 interactions\n", noList14];
	
	//build a matrix for the interaction
	row = [NSMutableArray arrayWithCapacity: 4];
	for(i=0; i<noAtoms-1; i++)
	{
		indexes = [ list14 objectAtIndex: i ];
		index = [indexes firstIndex];
		atom1 = [NSNumber numberWithInt: i ];
		while(index != NSNotFound)
		{
			atom2 = [NSNumber numberWithInt: index];
			matrixRow = [ params14 objectForKey: atom1];
			eps1  = [ [ matrixRow objectAtIndex: 1 ] doubleValue ];
			rmin1 = [ [ matrixRow objectAtIndex: 2 ] doubleValue ];
			matrixRow = [ params14 objectForKey: atom2];
			eps2  = [ [ matrixRow objectAtIndex: 1 ] doubleValue ];
			rmin2 = [ [ matrixRow objectAtIndex: 2 ] doubleValue ];
			
			if (([ params14Scaled objectForKey: atom1] != nil ) ) 
			{
				matrixRow =  [ params14Scaled objectForKey: atom1];
				eps1  = [ [ matrixRow objectAtIndex: 1 ] doubleValue ];
				rmin1 = [ [ matrixRow objectAtIndex: 2 ] doubleValue ];
			}
			if (([ params14Scaled objectForKey: atom2] != nil ) ) 
			{
				matrixRow =  [ params14Scaled objectForKey: atom2] ;
				eps2  = [ [ matrixRow objectAtIndex: 1 ] doubleValue ];
				rmin2 = [ [ matrixRow objectAtIndex: 2 ] doubleValue ];
			}         
			
			[row addObject: atom1 ];
			[row addObject: atom2 ];
			[row addObject: [NSNumber numberWithDouble: (sqrt(eps1*eps2)) ]];
			[row addObject: [NSNumber numberWithDouble: (rmin1+rmin2) ]];
			[matrix14 extendMatrixWithRow: row];
			[row removeAllObjects];
			index = [indexes indexGreaterThanIndex: index];
		}
	}
	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"1-4Interaction" forKey: @"InteractionType"];
	[interaction setValue: [NSNumber numberWithInt: 2] forKey: @"ElementsPerInteraction"];
	[interaction setValue: matrix14 forKey: @"Matrix"];
	
	[vdw14Matrix release];
	return interaction;
}


- (id) _buildUreyBradleyForAtoms: (NSMutableArray*) atomNames 
                 withBondedAtoms: (NSMutableArray*) bondedAtomsList
{
	int i, j, atom;
	NSEnumerator *bondedAtomsListEnum;
	NSMutableArray *angle;
	NSMutableDictionary* interaction;
	AdMutableDataMatrix *ubMatrix;
	id bondedAtoms; 

	ubMatrix = [[AdMutableDataMatrix alloc] 
			initWithNumberOfColumns:0 
			columnHeaders: nil
			columnDataTypes: nil];
	[ubMatrix autorelease];		
	bondedAtomsListEnum = [bondedAtomsList objectEnumerator];

	atom = 0;	
	while((bondedAtoms = [bondedAtomsListEnum nextObject]))
	{
		if([bondedAtoms count] > 1)
			for(i=0; i<[bondedAtoms count] - 1; i++)
				for(j=i+1; j < [bondedAtoms count]; j++)	
				{
					angle = [NSMutableArray arrayWithCapacity: 3];
					[angle addObject: [bondedAtoms objectAtIndex: i]];
					[angle addObject: [NSNumber numberWithInt: atom]];
					[angle addObject: [bondedAtoms objectAtIndex: j]];
					[ubMatrix extendMatrixWithRow: angle];
				}
		atom++;
	}
	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"UreyBradley" forKey: @"InteractionType"];
	[interaction setValue: [NSNumber numberWithInt: 3] forKey: @"ElementsPerInteraction"];
	[interaction setValue: ubMatrix forKey: @"Matrix"];
	[self _findParametersForInteractions: interaction ofAtoms: atomNames];
   
   ubMatrix = [ interaction objectForKey: @"Matrix"];
	GSPrintf(buildOutput,@"There are %d UreyBradley interactions\n", [ubMatrix numberOfRows]);
	[buildString appendFormat: @"\t\tThere are %d UreyBradley interactions\n", [ubMatrix numberOfRows]];
	return interaction;
}

- (id) _findMassesForAtoms: (NSMutableArray*) atomNames
{
	int i;
	AdMutableDataMatrix* massMatrix;
	NSMutableDictionary* interaction;
	NSMutableArray* row;

	massMatrix = [[AdMutableDataMatrix alloc]
			initWithNumberOfColumns: 0
			columnHeaders: 0
			columnDataTypes: 0];
	[massMatrix autorelease];		

	for(i=0; i<[atomNames count]; i++)
	{
		row = [NSMutableArray arrayWithCapacity: 1];
		[row addObject: [NSNumber numberWithInt: i]];
		[massMatrix extendMatrixWithRow: row];
	}

	interaction = [NSMutableDictionary dictionaryWithCapacity: 1];
	[interaction setValue: @"Mass" forKey: @"InteractionType"];
	[interaction setValue: massMatrix forKey: @"Matrix"];
	[interaction setValue: [NSNumber numberWithInt: 1] forKey: @"ElementsPerInteraction"];
	[self _findParametersForInteractions: interaction ofAtoms: atomNames];

	return interaction;
}

- (id) _buildNonBondedForAtoms: (NSMutableArray*) atomNames 
		bondedInteractions: (NSMutableDictionary*) bondedInteractions
		atomsPerResidue: (NSMutableArray*) atomsPerResidue
{
	int i, j, elementsPerInteraction;
	int noAtoms, noResidues, index, residueStart, residueEnd;
	NSMutableArray* nonbonded; 
	NSMutableIndexSet* indexes, *topIndexes, *interactionIndexes;
	NSEnumerator *interactionEnum;
	NSRange indexRange;
	id topology, matrix, interaction;

	noAtoms = [atomNames count];
	noResidues = [atomsPerResidue count];
	nonbonded = [NSMutableArray arrayWithCapacity: 1];
	
	for(i=0; i<noAtoms-1; i++)
	{
		indexRange.location = i+1;
		indexRange.length = noAtoms - indexRange.location;
		indexes = [NSMutableIndexSet indexSetWithIndexesInRange: indexRange];
		[nonbonded addObject: indexes];
	}

	residueEnd = 0;
	interactionIndexes = [NSMutableIndexSet indexSet];

	index = 0;
	for(i=0; i<[nonbonded count]; i++)
		index += [[nonbonded objectAtIndex:i] count];

	NSDebugLLog(@"ULInteractionsBuilder", 
		@"There are %d nonbonded interactions before removal", 
		index);

	for(i=0; i<noResidues; i++)
	{	

		residueStart = residueEnd;
		residueEnd += [[atomsPerResidue objectAtIndex: i] intValue];

		//the last atom has no nonbonded interactions (newtons third law)
		//so we shouldnt iterate on it

		if(residueEnd == noAtoms)
			residueEnd = residueEnd - 1;

		interactionEnum = [[bondedInteractions allValues] objectEnumerator];
		
		while((topology = [interactionEnum nextObject]))
		{
			if([[topology valueForKey:@"InteractionType"] isEqual: @"VDW"])
				continue;			

			topIndexes =  [[topology valueForKey:@"ResidueInteractions"] 
						objectAtIndex: i];
			elementsPerInteraction = [[topology valueForKey:@"ElementsPerInteraction"] intValue];
			matrix = [topology valueForKey:@"Matrix"];
					
			//for each of the interactions in this residue go through
			//all the atoms in the residue. If they are invovled in the interaction
			//remove them from the nonbonded index set
			
			index = [topIndexes firstIndex];
			while(index != NSNotFound)
			{
				interaction = [matrix row: index];
				for(j=0; j<elementsPerInteraction; j++)
					[interactionIndexes addIndex: [[interaction objectAtIndex: j] intValue]];

				for(j=residueStart; j<residueEnd; j++)
					if([interactionIndexes containsIndex: j])
						[[nonbonded objectAtIndex: j] removeIndexes: interactionIndexes];
				
				index = [topIndexes indexGreaterThanIndex: index];
				[interactionIndexes removeAllIndexes];
			}
		}
	}

	index = 0;
	for(i=0; i<[nonbonded count]; i++)
		index += [[nonbonded objectAtIndex:i] count];

	GSPrintf(buildOutput, @"There are %d nonbonded interactions\n", index);
	[buildString appendFormat: @"\t\tThere are %d nonbonded interactions\n", index];

	return nonbonded;
}

/*************************

Interactions Per Residue

**************************/

- (id) _residueIndexes: (NSMutableArray*) atomsPerResidue
{
	NSIndexSet *indexSet;
	NSRange indexRange;
	NSEnumerator* residueEnum;
	NSMutableArray* residueIndexes;
	id number;

	residueIndexes = [NSMutableArray arrayWithCapacity:1];
	residueEnum = [atomsPerResidue objectEnumerator];
	indexRange.location = 0;
	while((number = [residueEnum nextObject]))
	{
		indexRange.length = [number intValue];	
		indexSet = [NSIndexSet indexSetWithIndexesInRange: indexRange];
		[residueIndexes addObject: indexSet];
		indexRange.location += indexRange.length;
	}	

	return residueIndexes;
}


- (id) _subsetOfInteractions: (NSMutableDictionary*) interaction
	 withIndexesInRange: (NSRange) indexRange 
	 startAt: (int) startIndex
	 endAt: (int) endIndex
{
	int i, j, elementsPerInteraction;
	AdDataMatrix* interactionMatrix;
	NSMutableIndexSet* searchSet, *resultSet;
	id row, index, end;

	interactionMatrix = [interaction valueForKey:@"Matrix"];
	elementsPerInteraction = [[interaction valueForKey:@"ElementsPerInteraction"] intValue];
	searchSet = [NSIndexSet indexSetWithIndexesInRange: indexRange];
	resultSet = [NSMutableIndexSet indexSet];
	end = [NSNumber numberWithInt: endIndex +1];	

	for(j=startIndex; j<[interactionMatrix numberOfRows]; j++)
	{
		row = [interactionMatrix row: j];
		if([row containsObject: end])
			break;

		for(i=0; i<elementsPerInteraction; i++)
		{
			index = [row objectAtIndex: i];
			if([searchSet containsIndex: [index intValue]])
			{
				[resultSet addIndex: j];
				break;
			}
		}
	}

	return resultSet;
}

- (void) _interactionsPerResidue: (NSMutableDictionary*) interaction residueIndexes: (NSArray*) residueIndexes
{
	int startIndex, endIndex, i, noResidues;
	NSRange indexRange;
	NSMutableArray* subsetIndexes;	//array of IndexSets - one for each residue
	NSMutableArray* interactionsPerResidue;
	id indexSet;

	subsetIndexes = [NSMutableArray arrayWithCapacity: 1];
	interactionsPerResidue = [NSMutableArray arrayWithCapacity: 1];
	startIndex = endIndex = 0;
	noResidues = [residueIndexes count];

	for(i=0; i< noResidues; i++)
	{
		indexRange.location = [[residueIndexes objectAtIndex: i] firstIndex];
		indexRange.length = [[residueIndexes objectAtIndex: i] count];

		if(i!= noResidues - 1)
			endIndex = [[residueIndexes objectAtIndex: i +1] lastIndex];
		else
			endIndex = [[residueIndexes lastObject] lastIndex];
		
		indexSet = [self _subsetOfInteractions: interaction 
					withIndexesInRange: indexRange 
					startAt: startIndex
					endAt: endIndex];

		[subsetIndexes addObject: indexSet];
		[interactionsPerResidue addObject: 
			[NSNumber numberWithInt: [indexSet count]]];
		
		if([indexSet count] != 0)
			startIndex = [indexSet firstIndex];
	}

	[interaction setValue: subsetIndexes forKey: @"ResidueInteractions"];
	[interaction setValue: interactionsPerResidue forKey: @"InteractionsPerResidue"];
	NSDebugLLog(@"ULInteractionsBuilder",
		@"%@\n%@", 
		[interaction objectForKey: @"InteractionType"], 
		interactionsPerResidue);
}

- (void) _setBuildError: (NSError**) buildError
{
	NSMutableDictionary* userInfo;

	[errorString insertString: @" and have been omitted.\n" atIndex: 0];
	[errorString insertString: @"The following interactions were missing paramters\n"
		atIndex: 0];

	userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject: @"Errors while retrieving parameters for system.\n"
		forKey: NSLocalizedDescriptionKey];
	[userInfo setObject: errorString
		forKey: @"ULBuildErrorDetailedDesciptionKey"];
	[userInfo setObject: @"Depending on the force field these omissions may or may not be critical.\n"
		forKey: @"ULBuildErrorRecoverySuggestionKey"];
	
	*buildError = [NSError errorWithDomain: @"ULBuildErrorDomain"
				code: 4
				userInfo: userInfo];
}

/********************

Public Methods

*********************/

- (id) initForForceField: (NSString*)  aString
{
	NSString* libraryPath, *parameterFileName;

	if((self = [super init]))
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
		
		parameterFileName = [NSString stringWithFormat: @"%@Parameters.ffml",
				forceField];

		NSDebugLLog(@"ULInteractionsBuilder", 
			@"Using parameter library %@", parameterFileName);
		libraryPath = [[[NSBundle bundleForClass: [self class]] resourcePath] 	
				stringByAppendingPathComponent: @"ForceFields"];
		libraryPath = [libraryPath stringByAppendingPathComponent: forceField];
		libraryPath = [libraryPath stringByAppendingPathComponent: parameterFileName];
		NSDebugLLog(@"ULInteractionsBuilder", 
			@"Parameter library path %@", libraryPath);

		NSDebugLLog(@"ULInteractionsBuilder", @"Creating document tree for parmLib");
		parameterLibrary = [[ULParameterTree alloc] 
					documentTreeForXMLFile: libraryPath];

		if(parameterLibrary == nil)
		{
			[self release];
			[NSException raise: NSInternalInconsistencyException
				format: @"Unable to locate parameter library for force field %@",
				forceField];
		}		

		NSDebugLLog(@"ULInteractionsBuilder", @"Complete");

		//Temporary
		unitsToConvert = [NSArray arrayWithObjects: 
					@"KCalMol", 
					@"Degree",
					@"KCalMol-2",
					nil];
		[unitsToConvert retain];			

		constantForUnit = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithDouble: BOND_FACTOR], @"KCalMol",
					[NSNumber numberWithDouble: DEG_2_RAD], @"Degree", 
					[NSNumber numberWithDouble: sqrt(BOND_FACTOR)],
					@"KCalMol-2", nil];
		[constantForUnit retain];		

		forceFieldInfo = [ULForceFieldInformation objectForForceField: forceField];
		[forceFieldInfo retain];
	}
	
	return self;
}

- (void) dealloc
{
	[forceField release];
	[parameterLibrary release];
	[unitsToConvert release];
	[constantForUnit release];
	[forceFieldInfo release];
	[super dealloc];
}	

- (NSString*) forceField
{
	return [[forceField retain] autorelease];
}

- (id) buildInteractionsForConfiguration: (id) configuration 
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	NSError *error = nil;
	NSMutableDictionary* interactions, *topology, *nonbonded;
	NSMutableArray* libraryNameList;
	NSMutableArray* bondedAtoms;
	NSMutableArray* residueIndexes;
	id interaction, nonbondedInteractions, masses, path;
	
	path = [[NSUserDefaults standardUserDefaults] stringForKey: @"BuildOutput"];
	buildOutput = fopen([path cString], "a");

	[buildString release];
	buildString = [[NSMutableString string] retain];
	if(buildInfo != NULL)
		*buildInfo = buildString;
	errorString = [NSMutableString string];

	interactions = [NSMutableDictionary dictionary];
	nonbonded = [NSMutableDictionary dictionary];
	libraryNameList = [configuration valueForKey: @"LibraryNames"];
	bondedAtoms = [configuration valueForKey:@"BondedAtoms"];
	topology = [NSMutableDictionary dictionary];

	NSDebugLLog(@"ULInteractionsBuilder", @"%@", 
		[configuration valueForKey: @"AtomsPerResidue"]);

	residueIndexes = [self _residueIndexes: [configuration valueForKey: @"AtomsPerResidue"]];

	[buildString appendString: @"\nBuilding interaction lists\n"];

	/*
   	 * Build the bonded interactions first
	 */
	
	[buildString appendString: @"\tHarmonicBonds:\n"];
	interaction = [self _buildBondsForAtoms: libraryNameList withBondedAtoms: bondedAtoms];
	[interactions setObject: interaction forKey: [interaction valueForKey: @"InteractionType"]];
	[self _interactionsPerResidue: interaction residueIndexes: residueIndexes];
	
	[buildString appendString: @"\tHarmonicAngles:\n"];
	interaction = [self _buildAnglesForAtoms: libraryNameList withBondedAtoms: bondedAtoms];
	[interactions setObject: interaction forKey: [interaction valueForKey: @"InteractionType"]];
	[self _interactionsPerResidue: interaction residueIndexes: residueIndexes];
	
	[buildString appendString: @"\tFourierTorsions:\n"];
	   interaction = [self _buildTorsionsForAtoms: libraryNameList 	
			withBondedAtoms: bondedAtoms 
			bonds: [interactions valueForKeyPath: @"HarmonicBond.Matrix"]];
	[interactions setObject: interaction forKey: [interaction valueForKey: @"InteractionType"]];
	[self _interactionsPerResidue: interaction residueIndexes: residueIndexes];
	
	//testing improper torsions

	[buildString appendString: @"\tHarmonicImproperTorsions:\n"];
	interaction = [self _buildImproperTorsionsForAtoms: libraryNameList 	
			withBondedAtoms: bondedAtoms 
			bonds: [interactions valueForKeyPath: @"HarmonicBond.Matrix"]];
	[interactions setObject: interaction forKey: [interaction valueForKey: @"InteractionType"]];
	[self _interactionsPerResidue: interaction residueIndexes: residueIndexes];

	[topology setValue: interactions forKey: @"Bonded"];
	
	/*
	 * Now the nonbonded interactions
	 */

	[buildString appendString: @"\tNonbonded Interactions\n"];
	nonbondedInteractions = [self _buildNonBondedForAtoms: [configuration valueForKey:@"AtomNames"]
					bondedInteractions: [topology valueForKey:@"Bonded"]
					atomsPerResidue: [configuration valueForKey:@"AtomsPerResidue"]];	
	[nonbonded setValue: nonbondedInteractions forKey: @"Interactions"];
	
	interaction = [self _buildVDWForAtoms: libraryNameList withBondedAtoms: bondedAtoms];
	[self _interactionsPerResidue: interaction residueIndexes: residueIndexes];
	[nonbonded setValue: interaction forKey: @"VDWParameters"];

	[topology setValue: nonbonded forKey:@"Nonbonded"];
   //build the 1-4 VDW and electrostatic if the ff has them:
   if([ [forceFieldInfo interactions] containsObject: @"1-4Interaction"])
   {
      interaction = [self _build14ForAtoms: libraryNameList 
                     withBondedInteractions: [topology valueForKey:@"Bonded"]
                     withVDWAtoms: [nonbonded objectForKey: @"VDWParameters"] ];
      [self _interactionsPerResidue: interaction residueIndexes: residueIndexes];
      [ [topology objectForKey: @"Bonded" ] setObject: interaction 
         forKey: @"1-4Interaction" ];
   }
   //build the UreyBradley Interactions
   if([ [forceFieldInfo interactions] containsObject: @"UreyBradley"])
   {
      interaction = [self _buildUreyBradleyForAtoms: libraryNameList
                                    withBondedAtoms: bondedAtoms];
      [self _interactionsPerResidue: interaction residueIndexes: residueIndexes];
      [ [topology objectForKey: @"Bonded" ] setObject: interaction 
         forKey: @"UreyBradley" ];
   }


	//we have to retrieve the masses as if they were an interaction
	
	interaction = [self _findMassesForAtoms: libraryNameList];

	//now we will extract the masses as an array

	masses = [[interaction valueForKey:@"Matrix"] column: 1];
 	[configuration setValue: masses forKey: @"Masses"];
	/*
	 * Create an AdDataSource from all the information
	 * First we have to convert the information into the correct
	 * format then use it to initialise the data source
	 */
	
	fclose(buildOutput);
	[buildString appendString: @"\nCompleted interactions build\n"];

	if([errorString length] != 0)
	{
		[self _setBuildError: &error];
		AdLogError(error);
		if(buildError != NULL)
			*buildError = error;
	}		

	return [self createDataSourceFromConfiguration: configuration
		topology: topology];
}


@end

//This category is for translating the current information generated by the
//build into something close to the format we would like it to be.
//The exact format will depend on a number of factors (ffml format,
//information extracted from ffml, final core requirements).
//The forms and output here represent an intermediate step.

@implementation ULInteractionsBuilder (TemporaryDataSourceConversions)

- (AdMutableDataSource*) _initDataSourceFromConfiguration: (id) configuration 
			topology: (id) topology
{
	int i;
	AdDataMatrix* matrix;
	AdMutableDataMatrix *properties, *coordinates;
	AdMutableDataSource* dataSource;
	NSArray *headers;
	NSString* vdwType;
	id column;

	headers = [NSArray arrayWithObjects: @"ForceFieldName",
			@"PDBName",
			@"PartialCharge",
			@"Mass",
			nil];

	//Element Information

	coordinates = [configuration valueForKey: @"Coordinates"];
	[coordinates setName: @"Coordinates"];
	
	properties = [AdMutableDataMatrix new];
	[properties autorelease];		
	[properties extendMatrixWithColumn: 
		[configuration objectForKey: @"LibraryNames"]];
	[properties extendMatrixWithColumn:
		[configuration objectForKey: @"AtomNames"]];
	[properties extendMatrixWithColumn:
		[configuration objectForKey: @"PartialCharges"]];
	[properties extendMatrixWithColumn:
		[configuration objectForKey: @"Masses"]];
	[properties setColumnHeaders: headers];
	[properties setName: @"ElementProperties"];
	
	//Add the van der waals parameters to the properties
	//The first column of matrix is just indexes

	matrix = [topology valueForKeyPath: @"Nonbonded.VDWParameters.Matrix"];
	for(i=1; i<[matrix numberOfColumns]; i++)
	{
		column = [matrix column: i];
		[properties extendMatrixWithColumn: column];
	}	
	
	vdwType = [forceFieldInfo vdwType];
	[properties setHeaderOfColumn: 4 
		to: [[forceFieldInfo namesOfParametersOfInteraction: vdwType]
			objectAtIndex: 0]]; 
	[properties setHeaderOfColumn: 5 
		to: [[forceFieldInfo namesOfParametersOfInteraction: vdwType]
			objectAtIndex: 1]]; 
	dataSource = [[AdMutableDataSource alloc] initWithElementProperties: properties
			configuration: coordinates];
	
	return [dataSource autorelease];
}

- (void) _addBondedInteractionsTo: (AdMutableDataSource*) dataSource fromTopology: (id) topology
{
	int i, elementsPerInteraction;
	AdDataMatrix *matrix;
	AdMutableDataMatrix *groups, *parameters;
	NSEnumerator* bondedEnum;
	id  bondedTop;

	NSString* interaction;

	bondedEnum = [[topology valueForKey: @"Bonded"] objectEnumerator];
	while((bondedTop = [bondedEnum nextObject]))
	{
		interaction = [bondedTop objectForKey: @"InteractionType"];
		elementsPerInteraction = [[bondedTop objectForKey: @"ElementsPerInteraction"] intValue];
		groups = [[AdMutableDataMatrix new] autorelease];
		parameters = [[AdMutableDataMatrix new] autorelease];
		matrix = [bondedTop objectForKey: @"Matrix"];
		//FIXME: Interactions are added to topology even if there are none!
		if([matrix numberOfRows] > 0)
		{
			for(i=0; i<elementsPerInteraction; i++)
				[groups extendMatrixWithColumn: [matrix column: i]];

			for(i=elementsPerInteraction; i<[matrix numberOfColumns]; i++)
				[parameters extendMatrixWithColumn: [matrix column: i]];

			[groups setName: [NSString stringWithFormat:
						@"%@Groups", interaction]];
			[parameters setName: [NSString stringWithFormat: 
						@"%@Parameters", interaction]];

			[parameters setColumnHeaders:
				[forceFieldInfo namesOfParametersOfInteraction: interaction]];
			[dataSource addInteraction: interaction
				withGroups: groups
				parameters: parameters
				constraint: nil
				toCategory: @"Bonded"];
		}		
	}
}

//This conversion requires the most hacking ...
//Assuming VDWParameters exist and that the force field
//contains VDW and Electrostatic terms.
- (void) _addNonbondedInteractionsTo: (AdMutableDataSource*) dataSource fromTopology: (id) topology
{
	NSString* vdwType;

	//What type of vdw parameters does this force field use?
	vdwType = [forceFieldInfo vdwType];
	
	//Add interactions
	[dataSource addInteraction: vdwType
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
}

- (void) _addGroupPropertiesTo: (id) dataSource fromConfiguration: (id) configuration
{
	int sequenceNumber, residueNumber;
	NSEnumerator* sequenceEnum, *residueEnum;
	AdMutableDataMatrix* groupProperties;
	NSMutableArray* array;
	id sequence, residue, atomsPerResiude;

	sequenceEnum = [[configuration objectForKey: @"Sequences"] objectEnumerator];
	sequenceNumber = residueNumber = 0;
	array = [NSMutableArray array];
	groupProperties = [AdMutableDataMatrix new];
	[groupProperties autorelease];
	atomsPerResiude = [configuration objectForKey: @"AtomsPerResidue"];
	while((sequence = [sequenceEnum nextObject]))
	{
		residueEnum = [sequence objectEnumerator];
		while((residue = [residueEnum nextObject]))
		{
			[array addObject: residue];
			[array addObject: [NSNumber numberWithInt: sequenceNumber]];
			[array addObject: [atomsPerResiude objectAtIndex: residueNumber]];
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
			@"Atoms",
			nil]];
	[groupProperties setName: @"GroupProperties"];		

	[dataSource setGroupProperties: groupProperties];
}


- (id) createDataSourceFromConfiguration: (id) configuration topology: (id) topology
{
	AdMutableDataSource* dataSource;
	
	NSDebugLLog(@"ULInteractionsBuilder", 
		@"Creating data source from configuration");
	dataSource = [self _initDataSourceFromConfiguration: configuration
			topology: topology];
	NSDebugLLog(@"ULInteractionsBuilder", 
		@"Adding group properties from configuration");
	[self _addGroupPropertiesTo: dataSource 
		fromConfiguration: configuration];
	NSDebugLLog(@"ULInteractionsBuilder", 
		@"Adding bonded interactions");
	[self _addBondedInteractionsTo: dataSource
		fromTopology: topology];
	NSDebugLLog(@"ULInteractionsBuilder", 
		@"Adding nonbonded");
	[self _addNonbondedInteractionsTo: dataSource 
		fromTopology: topology];
	NSDebugLLog(@"ULInteractionsBuilder", 
		@"Complete");
	
	return [[dataSource copy] autorelease];
}

@end


