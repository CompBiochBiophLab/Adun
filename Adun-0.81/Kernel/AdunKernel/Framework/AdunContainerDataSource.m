/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-23 11:06:55 +0200 by michael johnston

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
#include "AdunKernel/AdunContainerDataSource.h"

//Methods for expanding matrices and building interactions &
//placing molecules at grid sites.
@interface AdContainerDataSource (Private)
- (AdMutableDataMatrix*) _expandMatrix: (AdDataMatrix*) matrix times: (int) number;
- (AdMutableDataMatrix*) _expandGroupMatrix: (AdDataMatrix*) matrix times: (int) number;
- (void) _createInteractions;
- (void) _retrieveElementInformation;
- (void) _createNonbondedPairs;
- (void) _placeMolecules: (AdMatrix*) coordinates atSites: (int*) sites;
@end

@implementation AdContainerDataSource (Private)

- (AdMutableDataMatrix*) _expandGroupMatrix: (AdDataMatrix*) matrix times: (int) number
{
	int i, j;
	int index, elementsPerGroup, factor;
	AdMutableDataMatrix* expandedMatrix = [AdMutableDataMatrix new];
	NSMutableArray *newRow = [NSMutableArray array];
	NSEnumerator* rowEnum;
	id row;

	elementsPerGroup = [matrix numberOfColumns];
	for(i=0; i<number; i++)
	{
		factor = i*atomsPerMolecule;
		rowEnum = [matrix rowEnumerator];
		while((row = [rowEnum nextObject]))
		{
			for(j=0; j<elementsPerGroup; j++)
			{
				index = [[row objectAtIndex: j] intValue];
				index += factor;
				[newRow addObject: 
					[NSNumber numberWithInt: index]];
			}		
			[expandedMatrix extendMatrixWithRow: newRow];
			[newRow removeAllObjects];
		}
	}

	[expandedMatrix setColumnHeaders:
		[matrix columnHeaders]];

	return [expandedMatrix autorelease];
}

- (AdMutableDataMatrix*) _expandMatrix: (AdDataMatrix*) matrix times: (int) number
{
	int i;
	AdMutableDataMatrix* expandedMatrix = [AdMutableDataMatrix new];
	NSEnumerator* rowEnum;
	id row;

	for(i=0; i<number; i++)
	{
		rowEnum = [matrix rowEnumerator];
		while((row = [rowEnum nextObject]))
			[expandedMatrix extendMatrixWithRow: row];
	}

	[expandedMatrix setColumnHeaders:
		[matrix columnHeaders]];
	
	return [expandedMatrix autorelease];
}

/*
 * Creates the group and parameter matrices  
 * based on the number of molecules in the sphere.
 * This is done be replicating the information from
 * the data source i.e. for one molecule.
 */
- (void) _createInteractions
{
	NSEnumerator *interactionsEnum;
	NSString *interaction, *category;
	NSMutableArray *array;
	AdDataMatrix *solventGroup, *solventParameters;
	AdDataMatrix *group, *parameters;
	
	//free previous
	if(interactions != nil)
	{
		[interactions release];
		[categories release];
		[interactionGroups release];
		[interactionParameters release];
	}	
	
	interactionGroups = [NSMutableDictionary new];
	interactionParameters = [NSMutableDictionary new];
	interactions = [NSMutableArray new];
	categories = [NSMutableDictionary new];
	
	NSDebugLLog(@"AdContainerDataSource", 
		@"Retrieving bonded interactions from data source");  
	
	interactionsEnum = [[dataSource availableInteractions]
				objectEnumerator];
	while((interaction = [interactionsEnum nextObject]))
	{
		[interactions addObject: interaction]; 
		category = [dataSource categoryForInteraction: interaction];
		if((array = [categories objectForKey: category]) != nil)
			[array addObject: interaction];
		else
		{
			array = [NSMutableArray array];
			[array addObject: interaction];
			[categories setObject: array forKey: category];

		}
		
		group = [dataSource groupsForInteraction: interaction];
		if(group != nil)
		{
			solventGroup = [self _expandGroupMatrix: group 
					times: currentNumberOfMolecules];
			[interactionGroups setObject: solventGroup
				forKey: interaction];
			parameters = [dataSource parametersForInteraction: 
					interaction];
			if(parameters != nil)
			{
				solventParameters = [self _expandMatrix: parameters
							times: currentNumberOfMolecules];
				[interactionParameters 
					setObject: solventParameters
					forKey: interaction];			
			}
		 }	
	}

	NSDebugLLog(@"AdContainerDataSource", 
		@"Complete");  
}

- (void) _retrieveElementInformation
{
	if(elementProperties != nil)
	{	
		[elementProperties release];
		[groupProperties release];
	}

	elementProperties = [self _expandMatrix: [dataSource elementProperties]
				times: currentNumberOfMolecules];
	groupProperties = [self _expandMatrix: [dataSource groupProperties]
				times: currentNumberOfMolecules];
	[elementProperties retain];
	[groupProperties retain];
}

/*
 * Creates the nonbonded pair list for the atoms in the sphere
 * using the pair list from the data source.
 */
- (void) _createNonbondedPairs
{
	int i, j;
	int currentNumberOfAtoms, currentAtom, index, offsetIndex;
	id dataSourceNonbonded;
	NSMutableIndexSet* indexes, *sourceIndexes, *currentInteractions;
	NSRange indexRange;
	
	NSDebugLLog(@"AdContainerDataSource", 
		@"Retrieving Nonbonded interactions from data source");

	if(nonbondedPairs != nil)
		[nonbondedPairs release];

	//First create the inter molecule nonbonded list.
	//We create entries for the last molecule so we 
	//can easily add an intra-molecule interactions in the next step.

	currentNumberOfAtoms = [elementConfiguration numberOfRows];
	nonbondedPairs = [NSMutableArray new];
	//FIXME: indexSetArrayForInteraction currently returns the nonbonded
	//list however the exact interface is unstable.
	dataSourceNonbonded = [dataSource indexSetArrayForCategory:@"Nonbonded"];
	for(i=0; i<currentNumberOfMolecules; i++)
		for(j=0; j<atomsPerMolecule; j++)
		{
			indexRange.location = (i+1)*atomsPerMolecule;
			indexRange.length = currentNumberOfAtoms - indexRange.location;
			indexes = [NSMutableIndexSet indexSetWithIndexesInRange: indexRange];
			[nonbondedPairs addObject: indexes];
		}

	//add the intra molecule nonbonded interactions
	for(currentAtom = 0,i=0; i<currentNumberOfMolecules; i++)
	{
		for(j=0; j<atomsPerMolecule - 1; j++)
		{
			currentInteractions = [nonbondedPairs objectAtIndex: currentAtom];
			sourceIndexes = [dataSourceNonbonded objectAtIndex: j];
			index = [sourceIndexes firstIndex];
			while(index != NSNotFound)
			{
				offsetIndex = index + i*atomsPerMolecule;
				[currentInteractions addIndex: offsetIndex];
				index = [sourceIndexes indexGreaterThanIndex: index];
			}

			currentAtom++;
		}
		//skip the last atom in each molecule
		currentAtom++;
	}

	//remove the last atom entry since its not needed
	[nonbondedPairs removeLastObject];

	NSDebugLLog(@"AdContainerDataSource", @"Complete");
}

//Coordinates is a C matrix containing the coordinates
//of all the molecules in the sphere. 
- (void) _randomlyOrientMoleculesWithAtomicCoordinates: (AdMatrix*) coordinates atomsPerMolecule: (int) aPM
{
	int i, k,j, currentAtom;
	int numberOfMolecules;
	double angle[3];
	double rotated[3];
	
	numberOfMolecules = coordinates->no_rows/aPM;
	for(currentAtom=0, j=0; j< numberOfMolecules; j++)
	{
		//generate 3 random angles between -pi and pi
		for(i=0; i<3; i++)
			angle[i] = (2*gsl_rng_uniform(twister) -1)*M_PI;			
	
		//rotate each molecule by the angles in angle
		//this involves rotating each atom of the molecule seperately

  		for(i=0; i < aPM; i++)
  		{	
			AdRotate3DVector(coordinates->matrix[currentAtom], angle, rotated);
			for(k=0; k<3; k++)
				coordinates->matrix[currentAtom][k] = rotated[k];

			currentAtom++;
  		}
	}
}

//Coordinates are the coordinates of the atoms of the molecules.
//There are assumed to be atomsPerMolecule atoms in each molecule
- (void) _placeMolecules: (AdMatrix*) coordinates atSites: (int*) sites
{
	int i, j, k;
	int numberOfMolecules;
	int current_site, current_atom;
	AdMatrix* gridMatrix;

	numberOfMolecules = coordinates->no_rows/atomsPerMolecule;

	//Randomly orientate the molecules
	[self _randomlyOrientMoleculesWithAtomicCoordinates: coordinates
		atomsPerMolecule: atomsPerMolecule];

	//Place the molecules at the grid points
	gridMatrix = [solventGrid grid];
	for(i=0; i<numberOfMolecules; i++)
	{
		current_site = sites[i];
		current_atom = i*atomsPerMolecule;
		for(j=current_atom; j<current_atom + atomsPerMolecule; j++)
			for(k=0; k<3; k++)
				coordinates->matrix[j][k] += gridMatrix->matrix[current_site][k];
	}
}

@end


@implementation AdContainerDataSource

- (BOOL) _checkMatrix: (AdDataMatrix*) dataMatrixOne againstMatrix: (AdDataMatrix*) dataMatrixTwo
{
	return ([dataMatrixOne numberOfRows] == [dataMatrixTwo numberOfRows]) ? YES : NO;
}

- (void) _raiseSizeMismatchException
{
	[NSException raise: NSInvalidArgumentException
		format: @"Configuration and properites matrices must have the same number of rows"];
}

/**
Calculates the number of molecules necessary to fill the sphere
with the correct density. Creates the elementProperties and
groupProperties matrices
*/
- (void) _calculateContents
{
	int i;
	NSArray* masses;
	AdDataMatrix *dataSourceProperties, *singleMoleculeConfiguration;

	singleMoleculeConfiguration = [dataSource elementConfiguration];
	dataSourceProperties = [dataSource elementProperties];

	//find the data source mass and hence the number of molecules in the sphere
	
	masses = [dataSourceProperties columnWithHeader: @"Mass"];
	for(solventMass=0, i=0; i<(int)[singleMoleculeConfiguration numberOfRows]; i++)
		solventMass += [[masses objectAtIndex: i] doubleValue]; 

	NSDebugLLog(@"AdContainerDataSource", @"Mass %lf", solventMass); 

	currentNumberOfMolecules = solventDensity*[gridDelegate cavityVolume]/solventMass;
	atomsPerMolecule = [singleMoleculeConfiguration numberOfRows];
	NSDebugLLog(@"AdContainerDataSource",
		@"Current number of molecules %d. Atoms per molecule %d.", 
		currentNumberOfMolecules, atomsPerMolecule);
}

/*
 * Populating the Container 
 */

- (int*) _chooseGridPoints
{
	int i;
	int *array, *point_array;
	AdMatrix* gridMatrix;	

	NSDebugLLog(@"AdContainerDataSource",
		@"Choosing grid_points for %d molecules.\n", 
		currentNumberOfMolecules);

	//create an array of size grid_points, containing the numbers between 0 and grid_points
	
	gridMatrix = [solventGrid grid];
	array = (int*)[memoryManager allocateArrayOfSize: gridMatrix->no_rows*sizeof(int)];
	for(i=0; i < gridMatrix->no_rows; i++)
		array[i] = i;
	
	gsl_ran_shuffle(twister, array, gridMatrix->no_rows, sizeof(int));
	
	//malloc memory for the array to hold the choosen grid points
	
	point_array = (int*)[memoryManager allocateArrayOfSize: 
				currentNumberOfMolecules*sizeof(int)];
	for(i=0; i<currentNumberOfMolecules; i++)
		point_array[i] = array[i];

	[memoryManager freeArray: array];
	
	return point_array;	
}	

- (void) _populateBox
{
	int* points;	
	int i, j;
	AdMatrix* coordinates;

	//Choose a number of grid points equal to 
	//the number of molecles in the box
	points = [self _chooseGridPoints];
	
	//Create a matrix containing currentNumberOfMolecules copies
	//of the data source molecule coordinates

	elementConfiguration = [self _expandMatrix: [dataSource elementConfiguration]
				times: currentNumberOfMolecules];
	[elementConfiguration retain];			
		
	//Work with the AdMatrix representation of the coordinates	
	coordinates = [elementConfiguration cRepresentation];

	//Place solvent molecules at each point
	[self _placeMolecules: coordinates atSites: points];	
	
	for(i=0; i<coordinates->no_rows; i++)
		for(j=0; j<3; j++)
			[elementConfiguration setElementAtRow: i
				column: j
				withValue: [NSNumber numberWithDouble: 
						coordinates->matrix[i][j]]];

	[memoryManager freeMatrix: coordinates];			
}

/*
 * Creation and Maintainence
 */

- (void) _createGrid
{
	NSMutableArray* spacing;
	
	//Create the grid on which we'll place the solvent	
	//FIXME: calculate this correctly!!!!
	spacing = [NSMutableArray arrayWithObjects:
			 [NSNumber numberWithDouble: 3.0],
			 [NSNumber numberWithDouble: 3.0],
			 [NSNumber numberWithDouble: 3.0],
			 nil];
	
	NSDebugLLog(@"AdContainerDataSource", @"Grid spacing %@", spacing);

	solventGrid = [AdGrid gridWithSpacing: spacing 
				cavity: gridDelegate];
	[solventGrid retain];
}

- (id) initWithDictionary: (NSDictionary*) dict
{
	return [self initWithDataSource: [dict objectForKey: @"dataSource"]
		cavity: [dict objectForKey: @"cavity"]
		density: [[dict objectForKey: @"density"] doubleValue]
		seed: [[dict objectForKey: @"seed"] intValue]
		containedSystems: [dict objectForKey: @"containedSystems"]];
}

- (id) initWithDataSource: (id) source 
	cavity: (id) cavity
	density: (double) density
	seed: (int) anInt
{

	return [self initWithDataSource: source
		cavity: cavity
		density: density
		seed: anInt
		containedSystems: nil];
}

- (id) initWithDataSource: (id) source 
	cavity: (id) cavity
	density: (double) density
	seed: (int) anInt
	containedSystems: (NSArray*) anArray
{
	NSEnumerator* containedSystemsEnum;
	id containedObject;

	if((self = [super init]))
	{
		
		memoryManager = [AdMemoryManager appMemoryManager];
		memento = NO;
		currentCaptureMethod = @"Standard";
		seed = anInt;
		
		if([cavity conformsToProtocol: @protocol(AdGridDelegate)])
			gridDelegate = [cavity retain];
		else
			[NSException raise: NSInvalidArgumentException
				format: @"Cavity object must conform to AdGridDelegate protocol"];

		if(density <= 0)
			[NSException raise: NSInvalidArgumentException
				format: @"Density must be greater than 0"];

		solventDensity = density;
		twister = gsl_rng_alloc(gsl_rng_mt19937);
		gsl_rng_set(twister, seed);
		numberOccludedMolecules = 0;
		currentNumberOfMolecules = 0;
		atomsPerMolecule = 0;
		removedMolecules = [NSMutableArray new];
		containedSystems = [NSMutableArray new];

		NSDebugLLog(@"AdContainerDataSource", 
			@"Density %lf", solventDensity);
			
		[self _createGrid];

		if(source == nil)
		{
			[self release];
			[NSException raise: NSInvalidArgumentException
				format: @"Data source cannot be nil"];
		}		
		else		
		{
			dataSource = [source copy];
			[self _calculateContents];
			[self _retrieveElementInformation];
			[self _populateBox];
			[self _createInteractions];
			[self _createNonbondedPairs];
		}	

		systemName = [NSString stringWithFormat: @"%@Container", 
				[dataSource name]];
		[systemName retain];	

		//Insert any supplied systems
		if(anArray != nil)
		{
			//Check they are all AdSystem instances
			containedSystemsEnum = [anArray objectEnumerator];
			while((containedObject = [containedSystemsEnum nextObject]))
				if(![containedObject isMemberOfClass: [AdSystem class]])
				{
					[self release];
					[NSException raise: NSInvalidArgumentException
						format: @"Can only insert AdSystem objects"];
				}

			containedSystemsEnum = [anArray objectEnumerator];
			while((containedObject = [containedSystemsEnum nextObject]))
				[self insertSystem: containedObject];
		}
		else
			containedSystems = [NSMutableArray new];

	}

	return self;
}

- (void) dealloc
{
	[interactions release];
	[categories release];
	[interactionGroups release];
	[interactionParameters release];
	[nonbondedPairs release];
	[elementProperties release];
	[groupProperties release];
	[elementConfiguration release];
	[removedMolecules release];
	[containedSystems release];
	[gridDelegate release];
	[solventGrid release];
	[dataSource release];
	[systemName release];
	if(twister != NULL)
		gsl_rng_free(twister);
	
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description;
	NSString* category, *interactionType;
	AdDataMatrix* groups;
	NSEnumerator* interactionTypesEnum, *categoriesEnum;
	
	description = [NSMutableString stringWithString:@""];
	[description appendFormat: @"Name: %@\nNumber Of Atoms %d\n\n", 
		[self systemName], [self numberOfElements]];
	[description appendFormat: @"Container: %@", gridDelegate];
	[description appendFormat: @"Density: %-8.3lf\n", solventDensity];
	[description appendString: @"\nInteraction Types:\n"];
	
	//FIXME: Add category method
	//categoriesEnum = [[self categories] objectEnumerator];
	categoriesEnum = [categories keyEnumerator];
	while((category = [categoriesEnum nextObject]))
	{
		[description appendFormat: @"\nCategory %@:\n", category];
		interactionTypesEnum = [[categories objectForKey: category] 
					objectEnumerator];
		//FIXME Should check for groups and index sets associated with interaction
		//[description appendString: @"\nCategory level interactions - "];
		while((interactionType = [interactionTypesEnum nextObject]))
		{
			[description appendFormat: @"\t%15@", interactionType];
			groups = [interactionGroups objectForKey: interactionType];
			if(groups != nil)
				[description appendFormat: @"%10d\n", [groups numberOfRows]];
			else
				[description appendString: @"\n"];
		}		
	}
	
	//Temporary
	int total;
	NSEnumerator* pairsEnum;
	id set;
	
	total = 0;
	pairsEnum = [nonbondedPairs objectEnumerator];
	while((set = [pairsEnum nextObject]))
		total += [set count];
	
	[description appendFormat: @"\nThere are %d nonbonded pairs\n", total];

	return description;
}

/*
 * Accessors
 */

- (unsigned int) numberOfElements
{
	return [elementConfiguration numberOfRows];
}

- (int) atomsPerMolecule
{
	return atomsPerMolecule;
}

- (unsigned int) numberOfStructures
{
	return currentNumberOfMolecules;
}

//Deprecate - Replaced by name() to maintain
//polymorphism with AdDataSource.:
- (NSString*) systemName
{
	return [self name];
}

- (NSString*) name
{
	return [[systemName retain] autorelease];
}

- (id) dataSource
{
	return [[dataSource retain] autorelease];
}

- (NSArray*) interactionsForCategory: (NSString*) category
{
	return [[[categories objectForKey: category] copy] autorelease];
}

- (NSArray*) availableInteractions
{
	return [[interactions copy] autorelease];
}

- (AdDataMatrix*) elementProperties
{
	return [[elementProperties copy] autorelease];
}

- (AdDataMatrix*) elementConfiguration
{
	return [[elementConfiguration copy] autorelease];
}

- (void) setElementConfiguration: (AdDataMatrix*) dataMatrix
{
	if(elementProperties != nil)
		if(![self _checkMatrix: dataMatrix againstMatrix: elementProperties])
			[self _raiseSizeMismatchException];

	if(elementConfiguration != nil)
		[elementConfiguration release];

	elementConfiguration = [dataMatrix mutableCopy];
}

- (AdDataMatrix*) groupProperties
{
	return [[groupProperties copy] autorelease];
}

- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction;
{
	if(![interactions containsObject: interaction])
		[NSException raise: NSInvalidArgumentException
			format: @"Interaction %@ does not exist", interaction];
	
	return [[[interactionGroups objectForKey: interaction]
			copy] autorelease];
}

- (AdDataMatrix*) parametersForInteraction: (NSString*) interaction;
{
	if(![interactions containsObject: interaction])
		[NSException raise: NSInvalidArgumentException
			format: @"Interaction %@ does not exist", interaction];
	
	return [[[interactionParameters objectForKey: interaction]
			copy] autorelease];
}

- (NSString*) categoryForInteraction: (NSString*) interaction;
{
	NSEnumerator* categoryEnum;
	id category;
	
	if(![interactions containsObject: interaction])
		return nil;

	categoryEnum = [categories keyEnumerator];
	while((category = [categoryEnum nextObject]))
		if([[categories objectForKey: category] containsObject: interaction])
			return [[category retain] autorelease];

	return nil;		
}

- (NSArray*) indexSetArrayForCategory: (NSString*) category
{
	return [[nonbondedPairs retain] autorelease];
}

- (id) cavity
{
	return [[gridDelegate retain] autorelease];
}

- (double) density
{
	return solventDensity;
}

/*
 * NSCoding
 */

- (id) initWithCoder: (NSCoder*) decoder
{
	if([decoder allowsKeyedCoding])
	{
		int i; 
		NSArray* masses;

		dataSource = [decoder decodeObjectForKey: @"DataSource"];
		elementConfiguration = [decoder decodeObjectForKey: @"ElementConfiguration"];
		elementProperties = [decoder decodeObjectForKey: @"ElementProperties"];
		groupProperties = [decoder decodeObjectForKey: @"GroupProperties"];
		solventGrid = [decoder decodeObjectForKey: @"SolventGrid"];
		solventDensity = [decoder decodeDoubleForKey: @"SolventDensity"];
		numberOccludedMolecules = [decoder decodeDoubleForKey: @"ObscuredMolecules"];
		atomsPerMolecule = [decoder decodeIntForKey: @"AtomsPerMolecule"];
		seed = [decoder decodeIntForKey: @"Seed"];
		gridDelegate = [decoder decodeObjectForKey: @"GridDelegate"];
		systemName = [decoder decodeObjectForKey: @"Name"];	
		
		[elementProperties retain];			
		[elementConfiguration retain];
		[solventGrid retain];
		[gridDelegate retain];
		[groupProperties retain];
		[dataSource retain];
		[systemName retain];
		
		currentNumberOfMolecules = [elementConfiguration numberOfRows]/atomsPerMolecule;

		//Calculate solvent mass
		masses = [elementProperties columnWithHeader: @"Mass"];
		for(solventMass=0, i=0; i<atomsPerMolecule; i++)
			solventMass += [[masses objectAtIndex: i] doubleValue]; 

		twister = gsl_rng_alloc(gsl_rng_mt19937);
		gsl_rng_set(twister, seed);

		[self _createInteractions];
	}
	else
		[NSException raise: NSInvalidArgumentException 
			format: @"%@ does not support non keyed coding", [self classDescription]];

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Encode", @"Encoding %@", [self description]);
		[encoder encodeObject: dataSource forKey: @"DataSource"];	
		[encoder encodeObject: systemName forKey: @"Name"];	
		[encoder encodeObject: elementConfiguration forKey: @"ElementConfiguration"];
		[encoder encodeObject: elementProperties  forKey: @"ElementProperties"];
		[encoder encodeObject: groupProperties forKey: @"GroupProperties"];
		[encoder encodeObject: solventGrid forKey: @"SolventGrid"];
		[encoder encodeDouble: solventDensity forKey: @"SolventDensity"];
		[encoder encodeDouble: numberOccludedMolecules forKey: @"ObscuredMolecules"];
		[encoder encodeObject: gridDelegate forKey: @"GridDelegate"];
		[encoder encodeInt: seed forKey: @"Seed"];
		[encoder encodeInt: atomsPerMolecule forKey: @"AtomsPerMolecule"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}

@end

//Category containing methods for insertion and extraction
@implementation AdContainerDataSource (AdContainerDataSourceInsertionExtensions)

/*
 *  Insertion
 */

-(void) _removeAtomsWithIndexes: (NSIndexSet*) indexes
{
	NSDebugLLog(@"AdContainerDataSource", @"Clearing the current system");
	NSDebugLLog(@"AdContainerDataSource", @"There are %d current molecules", currentNumberOfMolecules);

	[elementConfiguration removeRowsWithIndexes: indexes];
	currentNumberOfMolecules = [elementConfiguration numberOfRows]/atomsPerMolecule;

	NSDebugLLog(@"AdContainerDataSource", @"Rebuilt coordinate matrix");

	//rebuild interactions
	[self _retrieveElementInformation];
	[self _createInteractions];
	[self _createNonbondedPairs];
}

- (int) setExclusionArea: (id) cavity
{
	int i;
	int numberRemovedMolecules;
	NSMutableIndexSet *obscuredIndexes;
	AdMatrix* coordinates;

	obscuredIndexes = [NSMutableIndexSet indexSet];
	coordinates = [elementConfiguration cRepresentation];

	//find which molecules have to been excluded
	//by checking if the first atom in the molecule is in the cavity
	for(i=0; i<coordinates->no_rows; i = i+atomsPerMolecule)
		if([cavity isPointInCavity: coordinates->matrix[i]])
			[obscuredIndexes addIndexesInRange: NSMakeRange(i, atomsPerMolecule)];

	NSDebugLLog(@"AdContainerDataSource", @"The following atoms are obscured %@", 
		obscuredIndexes); 
	[self _removeAtomsWithIndexes: obscuredIndexes];
	numberRemovedMolecules = [obscuredIndexes count]/atomsPerMolecule;
	numberOccludedMolecules += numberRemovedMolecules;
	NSDebugLLog(@"AdContainerDataSource", @"There are now %d obscured molecules", 
		numberOccludedMolecules); 

	[memoryManager freeMatrix: coordinates];	

	return numberRemovedMolecules;
} 

- (int) insertSystem: (AdSystem*) system
{
	int numberRemovedMolecules;
	id cavity;
	AdDataMatrix* coordinates;
	
	coordinates = [AdDataMatrix matrixFromADMatrix: [system coordinates]];

	//The cavity surface is defined by the vdw radius of each atom.
	//However the vdw radius of the solvent atoms must also be taken
	//into account. Hence we place atoms at least 2*vdw radii away.
	//There are obviously more accurate ways to do this.
	cavity = [[AdMoleculeCavity alloc]
			initWithSystem: system 
			factor: 2.0];

	[cavity autorelease];
	numberRemovedMolecules = [self setExclusionArea: cavity];
	
	[removedMolecules addObject: 
		[NSNumber numberWithInt: numberRemovedMolecules]];
	[containedSystems addObject: 
		system];

	return numberRemovedMolecules;	
}

/*
 * Extraction
 */

- (BOOL) _checkPoint: (double*) point distance: (double) distance usingCoordinates: (AdMatrix*) coordinates
{
	int j;
	Vector3D dist;

	for (j=0; j<coordinates->no_rows; j++)
	{
		dist.vector[0] = coordinates->matrix[j][0] - point[0];
		dist.vector[1] = coordinates->matrix[j][1] - point[1];
		dist.vector[2] = coordinates->matrix[j][2] - point[2];
		Ad3DVectorLengthSquared(&dist);
		if(dist.length <= distance*distance)
			return NO;
	}

	return YES;
}

- (int) removeSystem: (AdSystem*) system
{
	int numberRemovedMolecules, i, j, systemIndex;
	int* points; 
	double *point;
	AdMatrix* gridMatrix, *coordinates;
	id cavity;
	AdDataMatrix* newConf, *matrix, *configuration;

	NSDebugLLog(@"AdContainerDataSource", 
		@"Removing system %@", system);
	
	if(![containedSystems containsObject: system])
	{
		NSWarnLog(@"System %@ was not inserted", [system description]);
		return 0;
	}

	//Get the number of molecules removed when system was inserted
	//Then remove this data and the system for the relevant arrays.
	systemIndex = [containedSystems indexOfObject: system];
	numberRemovedMolecules = [[removedMolecules objectAtIndex: systemIndex] intValue];
	[containedSystems removeObjectAtIndex: systemIndex];
	[removedMolecules removeObjectAtIndex: systemIndex];
	
	//find the current cavity
	configuration = [AdDataMatrix matrixFromADMatrix: [system coordinates]];
	cavity = [[AdMoleculeCavity alloc]
			initWithSystem: system	
			factor: 1.0];

	/*
	 * We need to locate numberRemovedMolecules points in this
	 * volume and insert new molecule at them. We also have to
	 * make sure none of the new points is near any current atoms.
	 */
	
	 points  = [memoryManager allocateArrayOfSize:
	 		numberRemovedMolecules*sizeof(int)];
	 gridMatrix = [solventGrid grid];
	 coordinates = [elementConfiguration cRepresentation];
	 for(j =0, i=0; i<gridMatrix->no_rows; i++)
	 {
	 	point = gridMatrix->matrix[i];
	 	if([cavity isPointInCavity: point])
			if([self _checkPoint: point distance: 1.5 usingCoordinates: coordinates])
			{	
				points[j] = i;
				j++;
			}	
		
		if(j == numberRemovedMolecules)
			break;
	}	
	[memoryManager freeMatrix: coordinates];

	NSDebugLLog(@"AdContainerDataSource", 
		@"Current number of molecules %d. Number removed %d. Number of atoms %d", 
		currentNumberOfMolecules, 
		numberRemovedMolecules,
		[elementConfiguration numberOfRows]);

	if(j!=numberRemovedMolecules)
		NSWarnLog(@"Only able to reinsert %d of %d molecules", 
			j , numberRemovedMolecules);
	
	newConf = [self _expandMatrix: [dataSource elementConfiguration]
			times: numberRemovedMolecules];
	coordinates = [newConf cRepresentation];	
	
	//Place solvent molecules at each point
	[self _placeMolecules: coordinates atSites: points];	
	matrix = [AdDataMatrix matrixFromADMatrix: coordinates];
	[elementConfiguration extendMatrixWithMatrix: matrix];
	currentNumberOfMolecules += j;
	numberOccludedMolecules -= j;
	
	NSDebugLLog(@"AdContainerDataSource",
		@"There are now %d molecules and %d occluded molecules", 
		currentNumberOfMolecules, 
		numberOccludedMolecules);
	
	//Update properties and interactions
	[self _retrieveElementInformation];
	[self _createInteractions];
	[self _createNonbondedPairs];

	[memoryManager freeMatrix: coordinates];
	[memoryManager freeArray: points];

	NSDebugLog(@"AdContainerDataSource",
		@"Number of molecules reinserted %d", j);

	return j;
}

- (int) numberOccludedMolecules
{
	return numberOccludedMolecules;
}

- (NSArray*) containedSystems
{
	return [[containedSystems copy] autorelease];
}

@end
