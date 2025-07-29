/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunInteractionSystem.h"

@implementation AdInteractionSystem

- (void) _raiseSizeMismatchException
{
	[NSException raise: NSInvalidArgumentException
		format: @"Configuration and properites matrices must have the same number of rows"];
}

- (BOOL) _checkMatrix: (AdDataMatrix*) dataMatrixOne againstMatrix: (AdDataMatrix*) dataMatrixTwo
{
	return ([dataMatrixOne numberOfRows] == [dataMatrixTwo numberOfRows]) ? YES : NO;
}

/**
Checks that all the groups in \e matrix are contain elements
from both systems
*/
- (BOOL) _checkAllGroupsAreInterSystem: (AdDataMatrix*) matrix
{
	BOOL res;
	int i;
	NSEnumerator* groupEnum;
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	id group;

	groupEnum = [matrix rowEnumerator];
	while((group = [groupEnum nextObject]))
	{
		for(i=0; i<(int)[group count]; i++)
			[indexes addIndex: 
				[[group objectAtIndex: i] intValue]];

		res = [indexes containsIndexesInRange: systemOneRange] && 
			[indexes containsIndexesInRange: systemTwoRange];
		
		if(!res)
			return NO;

		[indexes removeAllIndexes];
	}

	return YES;
}

/**
On creation an interaction system can only supply
interactions that are not dependant on groups or parameters.
i.e. that can be defined by some external means (nonbonded lists etc.)
*/
- (void) _createInteractions
{
	NSEnumerator* interactionEnum, *systemEnum;
	NSMutableArray *array;
	NSMutableArray* arrayOne = [NSMutableArray array];
	NSMutableArray* arrayTwo = [NSMutableArray array];
	id system, interaction, category;

	//The interaction system can only handle interactions
	//that dont have defined groups at initialisation time. 
	//Interactions requiring explicit groups and parameters
	//have to be added later.
	array = arrayOne;
	systemEnum = [systems objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		interactionEnum = [[system availableInteractions] 
					objectEnumerator];
		while((interaction = [interactionEnum nextObject]))
		{
			if([system groupsForInteraction: interaction] == nil)
				[array addObject: interaction];
		}
		array = arrayTwo;
	}	

	availableInteractions = [arrayOne retain];

	//Categories
	categories = [NSMutableDictionary new];
	interactionEnum = [availableInteractions objectEnumerator];
	while((interaction = [interactionEnum nextObject]))
	{
		category = [[systemOne dataSource] categoryForInteraction: interaction];
		if((array = [categories objectForKey: category]) != nil)
			[array addObject: interaction];
		else
		{
			array = [NSMutableArray array];
			[array addObject: interaction];
			[categories setObject: array forKey: category];
		}
	}
}

- (void) _createCombinedSystem
{
	AdDataMatrix* systemOneProperties, *systemTwoProperties;
	
	elementProperties = [AdMutableDataMatrix new];
	elementConfiguration = [AdMutableDataMatrix new];

	[elementConfiguration extendMatrixWithMatrix: 
		[AdDataMatrix matrixFromADMatrix:
			[systemOne coordinates]]];
	[elementConfiguration extendMatrixWithMatrix: 
		[AdDataMatrix matrixFromADMatrix: 
			[systemTwo coordinates]]];
	coordinates = [elementConfiguration cRepresentation];		

	/*
	 * When combining properties there may be
	 * properties in one matrix that arent in 
	 * another. In this case the joint properties
	 * matrix includes a column for the extra 
	 * properties setting the value for the 
	 * elements without that property to 0 or "None"
	 */
	
	//FIXME: Do the above.

	systemOneProperties = [systemOne elementProperties];
	systemTwoProperties = [systemTwo elementProperties];
	
	[elementProperties extendMatrixWithMatrix: systemOneProperties];
	[elementProperties extendMatrixWithMatrix: systemTwoProperties];
	[elementProperties setColumnHeaders: 
		[systemOneProperties columnHeaders]];
	//Create an immutable copy of elementProperties for returning
	//to save having to copy it every time.
	immutableElementProperties = [elementProperties copy];

	systemOneElements = [systemOne numberOfElements];
	systemTwoElements = [systemTwo numberOfElements];
	numberOfElements = systemOneElements + systemTwoElements;

	systemOneRange = NSMakeRange(0, systemOneElements);
	systemTwoRange = NSMakeRange(systemOneElements, systemTwoElements);
}

- (void) _createNonbondedPairs
{
	int i;
	NSMutableIndexSet* indexes;
	NSRange indexRange;

	nonbondedPairs = [NSMutableArray new];
	for(i=0; i<systemOneElements; i++)
	{
		indexRange.location = systemOneElements;
		indexRange.length = numberOfElements - indexRange.location;
		indexes = [NSMutableIndexSet indexSetWithIndexesInRange: indexRange];
		[nonbondedPairs addObject: indexes];
	}
}

/**
Method used by dealloc and when we 
need to recreate the interaction system
after a change in the contents of one
of its data sources.
*/
- (void) _clearSystem
{
	[immutableElementProperties release];
	[availableInteractions release];
	[elementProperties release];
	[elementConfiguration release];
	[interactionGroups release];
	[interactionParameters release];
	[categories release];
	[nonbondedPairs release];
	[[AdMemoryManager appMemoryManager]
		freeMatrix: coordinates];
}

- (void) _handleDataSourceContentsChange: (NSNotification*) aNotification
{
	NSDebugLLog(@"AdInteractionSystem",
		@"Interaction system %@ - Received a %@ notification from %@", 
		[self systemName], [aNotification name], [[aNotification object] systemName]);
	
	//Clear everything
	[self _clearSystem];
	
	//Update everything
	[self _createCombinedSystem]; 
	[self _createNonbondedPairs];
	[self _createInteractions];

	interactionGroups = [NSMutableDictionary new];
	interactionParameters = [NSMutableDictionary new];

	NSDebugLLog(@"AdInteractionSystem", @"Sending contents did change notification");
	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"AdSystemContentsDidChangeNotification"
		object: self];

	NSDebugLLog(@"AdInteractionSystem",
		@"Update complete");
}

/*********************

Object Creation

**********************/

- (id) initWithDictionary: (NSDictionary*) dict
{
	return [self initWithSystems: 
		[dict objectForKey: @"systems"]];
}

- (id) initWithSystems: (NSArray*) array
{
	NSEnumerator *arrayEnum;
	id system;

	if((self = [super init]))
	{
		availableInteractions = nil;
		categories = nil; 
		interactionGroups = nil;
		interactionParameters = nil;

		if([array count] != 2)
			[NSException raise: NSInvalidArgumentException
				format: @"Array must contain two AdSystems"];

		arrayEnum = [array objectEnumerator];
		while((system = [arrayEnum nextObject]))
			if(![system isKindOfClass: [AdSystem class]])
				[NSException raise: NSInvalidArgumentException
					format: @"Array must contain two AdSystems"];

		systems = [array retain];
		systemOne = [systems objectAtIndex: 0];
		systemTwo = [systems objectAtIndex: 1];
		mementoMask = 0;
	
		NSDebugLLog(@"AdInteractionSystem", @"Creating interactions");
		[self _createInteractions];
		NSDebugLLog(@"AdInteractionSystem", @"Creating combined system");
		[self _createCombinedSystem]; 
		NSDebugLLog(@"AdInteractionSystem", @"Creating nonbonded pairs");
		[self _createNonbondedPairs];
		NSDebugLLog(@"AdInteractionSystem", @"Finished interaction system creation");

		interactionGroups = [NSMutableDictionary new];
		interactionParameters = [NSMutableDictionary new];

		//Register for any change in the interacting system contents
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleDataSourceContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: systemOne];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleDataSourceContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: systemTwo];

		[systemOne registerInteractionSystem: self];
		[systemTwo registerInteractionSystem: self];
	}
	
	return self;
}

- (id) initWithSystemOne: (AdSystem*) firstSystem
	systemTwo: (AdSystem*) secondSystem
{
	return [self initWithSystems: 
		[NSArray arrayWithObjects: firstSystem, secondSystem, nil]];
}

- (NSString*) description
{
	NSMutableString* description;
	NSString* category, *interactionType;
	AdDataMatrix* groups;
	NSEnumerator* interactionTypesEnum, *categoriesEnum;
	
	description = [NSMutableString string];
	[description appendFormat: @"Name: %@\n", [self systemName]];
	[description appendFormat: @"System one: %@. Range %@\n", 
		[systemOne systemName], NSStringFromRange(systemOneRange)];
	[description appendFormat: @"System one: %@. Range %@\n", 
		[systemTwo systemName], NSStringFromRange(systemTwoRange)];
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

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];
	[systemOne removeInteractionSystem: self];
	[systemTwo removeInteractionSystem: self];

	[self _clearSystem];
	[systems release];
	[super dealloc];
}

- (void) addInteraction: (NSString*) name 
	withGroups: (AdDataMatrix*)  group
	parameters: (AdDataMatrix*) parameters
	constraint: (id) object
	toCategory: (NSString*) category
{
	if(name == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Interaction name must be supplied"];

	if(parameters != nil && group == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Cant supply parameters without corresponding groups"];

	//check matrices are the correct size
	if(![self _checkMatrix: group againstMatrix: parameters])
		[self _raiseSizeMismatchException];

	//check all groups in the group matrix contain elements from both
	//systems

	if(![self _checkAllGroupsAreInterSystem: group])
		[NSException raise: NSInvalidArgumentException
			format: @"Only inter system interactions can be added"];

	[availableInteractions addObject: name];

	//add groups & params
	if(group != nil)
		[interactionGroups setObject: group forKey: name];

	if(parameters != nil)	
		[interactionParameters setObject: parameters forKey: name];

	//add interaction name to category
	if(category == nil)
		category = @"None";

	if((object = [categories objectForKey: category]) == nil)
	{
		object = [NSMutableArray array];
		[categories setObject: object forKey: category];
	}

	[object addObject: name];
}

- (void) systemDidUpdateCoordinates: (AdSystem*) aSystem
{
	unsigned int i, j;
	AdMatrix *matrix;
	NSRange range;

	matrix = NULL;
	if(aSystem == systemOne)
	{
		range = systemOneRange;
		matrix = [systemOne coordinates];
	}
	else if(aSystem == systemTwo)
	{
		range = systemTwoRange;
		matrix = [systemTwo coordinates];
	}	
	
	if(matrix != NULL)
		for(i=range.location; i<NSMaxRange(range); i++)
			for(j=0; j<3; j++)
				coordinates->matrix[i][j] = matrix->matrix[i-range.location][j];
}

/*
 * Accessors
 */

- (NSArray*) systems
{
	return systems;
}

- (unsigned int) numberOfElements
{
	return numberOfElements;
}

- (AdMatrix*) coordinates
{
	return coordinates;
}

- (NSArray*) elementMasses
{
	return [elementProperties columnWithHeader: @"Mass"];
}

- (NSArray*) elementTypes
{
	return [elementProperties columnWithHeader: @"ForceFieldName"];
}

- (AdDataMatrix*) elementProperties
{
	return [[immutableElementProperties retain]
		autorelease];
}

- (NSString*) systemName
{
	return [NSString stringWithFormat: @"%@-%@Interaction", 
			[systemOne systemName],
			[systemTwo systemName]];
}

- (NSArray*) availableInteractions
{
	return [[availableInteractions retain] autorelease];
}

- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction
{
	return [[[interactionGroups objectForKey: interaction]
		copy] autorelease];
}

- (AdDataMatrix*) parametersForInteraction: (NSString*) interaction
{
	return [[[interactionParameters objectForKey: interaction]
		copy] autorelease];
}

- (NSArray*) indexSetArrayForCategory: (NSString*) category 
{
	return [[nonbondedPairs retain] autorelease];
}

- (NSRange) rangeForSystem: (AdSystem*) aSystem
{
	if(aSystem == systemOne)
		return systemOneRange;
	else if(aSystem == systemTwo)
		return systemTwoRange;
	else
		return NSMakeRange(0,0);
}

/*
 * NSCoding
 */

- (id) initWithCoder: (NSCoder*) decoder
{
	if([decoder allowsKeyedCoding])
	{
		systems = [decoder decodeObjectForKey: @"Systems"];
		categories = [decoder decodeObjectForKey: @"Categories"];
		interactionGroups = [decoder decodeObjectForKey: @"Groups"];
		interactionParameters = [decoder decodeObjectForKey: @"Parameters"];
		availableInteractions = [decoder decodeObjectForKey: @"AvailableInteractions"];
		systemOne = [systems objectAtIndex: 0];
		systemTwo = [systems objectAtIndex: 1];
		[self _createCombinedSystem];
		[self _createNonbondedPairs];

		[systems retain];
		[categories retain];
		[interactionGroups retain];
		[interactionParameters retain];
		[availableInteractions retain];

		//Register for any change in the interacting system contents
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleDataSourceContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: systemOne];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleDataSourceContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: systemTwo];
		
		[systemOne registerInteractionSystem: self];
		[systemTwo registerInteractionSystem: self];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding",
			[self class]];
		

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{	
		[encoder encodeObject: systems forKey: @"Systems"];
		[encoder encodeObject: availableInteractions
			forKey: @"AvailableInteractions"];
		[encoder encodeObject: interactionGroups forKey: @"Groups"];
		[encoder encodeObject: interactionParameters forKey: @"Parameters"];
		[encoder encodeObject: categories forKey: @"Categories"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding",
			[self class]];
}

@end
