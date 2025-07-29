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
#include "AdunKernel/AdunDataSource.h"

/*
For use with both AdDataSource and AdMutableDataSource
*/
@interface AdDataSource (PrivateExtensions)
- (void) _addInteraction: (NSString*) name 
	withGroups: (AdDataMatrix*)  group
	parameters: (AdDataMatrix*) parameters
	constraint: (id) object
	toCategory: (NSString*) category;
- (BOOL) _checkMatrix: (AdDataMatrix*) dataMatrixOne 
	againstMatrix: (AdDataMatrix*) dataMatrixTwo;
- (void) _raiseSizeMismatchException;
@end


/**
Temporary category for handling updates of the groupProperties
matrix of an AdDataSource when it contains (which it always
does at this time) information on elements per residue etc.
Will probably be moved to a subclass.
Currently the columns in the groupProperties matrix are called
residue, chain & atoms.
Will have to change these names but they are only used in
a few places.
\note There could also be a "group delegate" which handles
the group properties.
\note It would also be good to have a subclass for BiomolecularSystems
so we can assume the meaning of "bonded" and "nonbonded".
*/
@interface AdMutableDataSource (BiomolecularSystemExtensions)
/**
Returns the index of the residue containing element \e elementIndex
*/
- (int) _residueForElement: (unsigned int) elementIndex;
/**
Removes the element \e elementIndex from whichever group its in.
Basically involves subtracting one from the atoms column of the 
corresponding residue.
*/
- (void) _removeElementFromGroup: (unsigned int) elementIndex;
@end

@implementation AdDataSource (PrivateExtensions)

- (void) _addInteraction: (NSString*) name 
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

	[interactions addObject: name];

	//add groups & params
	if(group != nil)
		[interactionGroups setObject: 
				[[group mutableCopy] autorelease] 
			forKey: name];

	if(parameters != nil)	
		[interactionParameters setObject: 
				[[parameters mutableCopy] autorelease]
			forKey: name];

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

- (BOOL) _checkMatrix: (AdDataMatrix*) dataMatrixOne againstMatrix: (AdDataMatrix*) dataMatrixTwo
{
	return ([dataMatrixOne numberOfRows] == [dataMatrixTwo numberOfRows]) ? YES : NO;
}

- (void) _raiseSizeMismatchException
{
	[NSException raise: NSInvalidArgumentException
		format: @"Configuration and properties matrices must have the same number of rows"];
}

@end

@implementation AdDataSource

/************

Creation

*************/

- (id) init
{	
	return [self initWithElementProperties: nil
		configuration: nil];
}

- (id) initWithElementProperties: (AdDataMatrix*) propertiesMatrix
	configuration: (AdDataMatrix*) configuration
{

	return [self initWithElementProperties: propertiesMatrix
		configuration: configuration
		interactions: nil
		groupProperties: nil];
}

- (id) initWithElementProperties: (AdDataMatrix*) propertiesMatrix
	configuration: (AdDataMatrix*) configuration
	interactions: (NSDictionary*) interactionsDict
	groupProperties: (AdDataMatrix*) gProperties
{
	NSDictionary* interactionInfo;
	NSEnumerator* interactionsEnum;
	id interaction;
	
	if((self = [super init]))
	{
		memoryManager = [AdMemoryManager appMemoryManager];
		elementProperties = nil;
		elementConfiguration = nil;
		groupProperties = [gProperties mutableCopy];
		interactions = [NSMutableArray new];
		interactionGroups = [NSMutableDictionary new];
		interactionParameters = [NSMutableDictionary new];
		categories = [NSMutableDictionary new];
		nonbondedPairs = nil;

		if(propertiesMatrix != nil)
			elementProperties = [propertiesMatrix mutableCopy];

		if(configuration != nil)
			elementConfiguration = [configuration mutableCopy];
			

		if(elementProperties != nil && elementConfiguration != nil)
			if(![self _checkMatrix: elementProperties againstMatrix: elementConfiguration])
			{
				[self release];
				[self _raiseSizeMismatchException];
			}		

		interactionsEnum = [interactionsDict keyEnumerator];
		while((interaction = [interactionsEnum nextObject]))
		{
			interactionInfo = [interactionsDict objectForKey: interaction];
			[self _addInteraction: interaction
				withGroups: [interactionInfo objectForKey: @"Group"]
				parameters: [interactionInfo objectForKey: @"Parameters"]
				constraint: [interactionInfo objectForKey: @"Constraint"]
				toCategory: [interactionInfo objectForKey: @"Category"]];
		}
	}

	return self;
}

- (id) initWithDataSource: (AdDataSource*) dataSource
{
	NSMutableDictionary* interactionsDict = [NSMutableDictionary dictionary];
	NSMutableDictionary* dict;
	NSEnumerator* interactionsEnum;
	id interaction, object;

	interactionsEnum = [[dataSource availableInteractions]
				objectEnumerator];
	while((interaction = [interactionsEnum nextObject]))
	{
		dict = [NSMutableDictionary dictionary];

		object = [dataSource groupsForInteraction: interaction];
		if(object != nil)
			[dict setObject: object forKey: @"Group"];

		object = [dataSource parametersForInteraction: interaction];
		if(object != nil)
			[dict setObject: object forKey: @"Parameters"];

		object = [dataSource categoryForInteraction: interaction];
		if(object != nil)
			[dict setObject: object forKey: @"Category"];

		object = [dataSource constraintForInteraction: interaction];
		if(object != nil)
			[dict setObject: object forKey: @"Constraint"];

		[interactionsDict setObject: dict forKey: interaction];
	}	

	[self initWithElementProperties: [dataSource elementProperties]
		configuration: [dataSource elementConfiguration]
		interactions: interactionsDict
		groupProperties: [dataSource groupProperties]];
	//FIXME: Temporary - This interface is unstable
	[self setNonbondedPairs: 
		[dataSource indexSetArrayForCategory: @"Nonbonded"]];	

	return self;
}

- (void) dealloc
{
	[elementProperties release];
	[elementConfiguration release];
	[groupProperties release];
	[interactions release];
	[interactionGroups release];
	[interactionParameters release];
	[categories release];
	[nonbondedPairs release];
	[super dealloc];
}

- (unsigned int) numberOfElements
{
	return [elementConfiguration numberOfRows];
}

- (NSArray*) interactionsForCategory: (NSString*) category
{
	return [[[categories objectForKey: category] 
			copy] 
			autorelease];
}

- (NSString*) forceField
{
	return [self valueForMetadataKey: @"ForceField"];
}

- (NSArray*) availableInteractions
{
	return [[interactions copy] autorelease];
}

- (NSString*) systemName
{
	return [self name];
}

//The data source will generate this list on demand
- (NSIndexSet*) elementPairsNotInInteractionsOfCategory: (NSString*) aString
{
	NSWarnLog(@"Method %@ not implemented", NSStringFromSelector(_cmd));
	return nil;
}

- (AdDataMatrix*) elementProperties
{
	return [[elementProperties copy] autorelease];
}

- (NSIndexSet*) indexesOfElementsWithValues: (NSArray*) anArray forProperty: (NSString*) aString
{
	int i;
	id value;
	NSMutableArray* array = [NSMutableArray new];
	NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
	NSIndexSet* returnValue;

	[elementProperties addColumnWithHeader: aString toArray: array];
	for(i=0; i<(int)[array count]; i++)
	{
		value = [array objectAtIndex: i];
		if([anArray containsObject: value])
			[indexSet addIndex: i];
	}
	
	[array release];
	returnValue = [[indexSet copy] autorelease];
	[indexSet release];
	return returnValue;
}

- (AdDataMatrix*) elementConfiguration
{
	return [[elementConfiguration copy] autorelease];
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

/**
Returns an AdDataMatrix whose entries are groups of \e interaction
containing the \e elementIndex.
If there is no group matrix and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised.
If no element with \e elementIndex exists an NSInvalidArgumentException is
raised.
*/
- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction
			containingElement: (int) elementIndex
{
	//FIXME: Implement
	NSWarnLog(@"Not implemented");
	return nil;
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

- (id) constraintForInteraction: (NSString*) interaction
{
	return nil;
}

- (NSArray*) indexSetArrayForCategory: (NSString*) category;
{  
	NSWarnLog(@"AdDataSource %@ - Warning only partially implemented.",
		NSStringFromSelector(_cmd));
	return [[nonbondedPairs retain] autorelease];
}

//Temporary method - in the future this list will be created by the data source
//using elementPairsNotInInteractionsOfCategory: @"Bonded"
- (void) setNonbondedPairs: (NSMutableArray*) array
{
	if(nonbondedPairs != nil)
		[nonbondedPairs release];

	nonbondedPairs = [array copy];
}

//Preliminary
- (NSString*) description
{
	NSMutableString* description;
	NSString* category, *interactionType;
	AdDataMatrix* groups;
	NSEnumerator* interactionTypesEnum, *categoriesEnum;

	description = [NSMutableString stringWithString:@""];
	[description appendFormat:
		@"Name: %@\nNumber Of Atoms %d\n\n", [self name], [self numberOfElements]];
	[description appendString: @"Interaction Types:\n"];
	
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
 * NSCopying & NSMutableCopying
 */

- (id) copyWithZone: (NSZone*) zone
{
	id object;

	//If we are not AdDataSource alloc explicitly
	//since we must  be a mutable subclass

	if([self isMemberOfClass: [AdMutableDataSource class]])
	{
		object = [[AdDataSource allocWithZone: zone]
		   		initWithDataSource: self];
	}			
	else if(zone == NULL || zone == NSDefaultMallocZone())
	{
		object = [self retain];
	}	
	else
	{
		object = [[AdDataSource allocWithZone: zone]
				initWithDataSource: self];
		//Add special flag to force copying of properties
		//Add AdPropertiesMetadataDomain itself does nothing
		[object copyMetadataInDomains: 
				AdSystemMetadataDomain | AdUserMetadataDomain | 1024
			fromObject: self];
		[object copyInputReferencesFromObject: self];	
		[object copyOutputReferencesFromObject: self];	
	}

	return object;
}

- (id) mutableCopyWithZone: (NSZone*) zone
{
	return [[AdMutableDataSource allocWithZone: zone]
		 initWithDataSource: self];
}

@end

/*
Category Containing all the NSCoding and AdMemento 
related methods.
*/

@implementation AdDataSource (AdDataSourceCodingExtensions)

- (NSMutableArray*) _decodeIndexArrayForKey: (NSString*) key 
	usingCoder: (NSCoder*) decoder
	encodedByteOrder: (unsigned int) encodedByteOrder
{
	int i, j, count;
	int totalRanges, totalSets;
	int byteSwapFlag;
	unsigned int length;
	int* rangesPerSet, *value;
	NSRange* totalRangeArray;
	NSRange* rangeArray, *range;
	NSIndexSet* set;
	id array;

	if(key != nil)
	{
		totalRangeArray = (NSRange*)[decoder decodeBytesForKey: key 
						 returnedLength: &length];
		totalRanges = length/(sizeof(NSRange));
		rangesPerSet = (int*)[decoder decodeBytesForKey:
					[NSString stringWithFormat: @"%@.RangesPerSet", key] 
					returnedLength: &length];
		totalSets = length/sizeof(int);
	}
	else
	{
		rangesPerSet = (int*)[decoder decodeBytesWithReturnedLength: &length];
		totalSets = length/sizeof(int);
		totalRangeArray = (NSRange*)[decoder decodeBytesWithReturnedLength: &length];
		totalRanges = length/(2*sizeof(unsigned int));
	}	
	
	/*
	 * Check if we need to perform byte swapping.
	 */
	if(encodedByteOrder != NSHostByteOrder())
	{
		if(encodedByteOrder == NS_LittleEndian)
			byteSwapFlag = AdSwapBytesToBig;
		else if(encodedByteOrder == NS_BigEndian)
			byteSwapFlag = AdSwapBytesToLittle;
		else
		{
			//The index set may have been encoded before the EncodedByteOrder key was added.
			//In this case we issue a warning a default to no swapping
			NSWarnLog(@"Encoded byte order unknown - defaulting to no swapping");
			byteSwapFlag = AdNoSwap;
		}
	}
	else
		byteSwapFlag = AdNoSwap;
	
	//Swappy
	if(byteSwapFlag == AdSwapBytesToBig)
	{
		//Swap all ranges in totalRangeArray
		for(i=0; i < totalRanges; i++)
		{
			range = (totalRangeArray + i);
			range->location = NSSwapLittleIntToHost(range->location);
			range->length = NSSwapLittleIntToHost(range->length);
		}	

		//Swap the values in rangesPerSet
		for(i=0; i < totalSets; i++)
		{
			value = (rangesPerSet + i);
			*value = NSSwapLittleIntToHost(*value);
		}	
	}
	else if(byteSwapFlag == AdSwapBytesToLittle)
	{
		//Swap all ranges in totalRangeArray
		for(i=0; i < totalRanges; i++)
		{
			range = (totalRangeArray + i);
			range->location = NSSwapBigIntToHost(range->location);
			range->length = NSSwapBigIntToHost(range->length);
		}	

		//Swap the values in rangesPerSet
		for(i=0; i < totalSets; i++)
		{
			value = (rangesPerSet + i);
			*value = NSSwapBigIntToHost(*value);
		}	
	}

	array = [NSMutableArray array];
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

- (id) initWithCoder: (NSCoder*) decoder
{
	unsigned int encodedByteOrder;

	self = [super initWithCoder: decoder];
	memoryManager = [AdMemoryManager appMemoryManager];
	if([decoder allowsKeyedCoding])
	{
		elementConfiguration = [decoder decodeObjectForKey: @"Coordinates"];
		elementProperties = [decoder decodeObjectForKey: @"Properties"];
		groupProperties = [decoder decodeObjectForKey: @"GroupProperties"];
		interactions = [decoder decodeObjectForKey: @"Interactions"];
		interactionGroups = [decoder decodeObjectForKey: @"InteractionGroups"];
		interactionParameters = [decoder decodeObjectForKey: @"InteractionParameters"];
		categories = [decoder decodeObjectForKey: @"Categories"];
		encodedByteOrder = [decoder decodeIntForKey: @"EncodedByteOrder"];
		nonbondedPairs = [self _decodeIndexArrayForKey:@"NonbondedPairs"
					usingCoder: decoder
					encodedByteOrder: encodedByteOrder];

		[elementConfiguration retain];
		[elementProperties retain];
		[groupProperties retain];
		[interactions retain];
		[interactionGroups retain];
		[interactionParameters retain];
		[categories retain];
		[nonbondedPairs retain];
	}
	else
	{
		encodedByteOrder = [[decoder decodeObject] intValue];
		groupProperties = [[decoder decodeObject] retain];
		elementProperties = [[decoder decodeObject] retain];
		elementConfiguration = [[decoder decodeObject] retain];
		interactions = [[decoder decodeObject] retain];
		interactionGroups = [[decoder decodeObject] retain];
		interactionParameters = [[decoder decodeObject] retain];
		categories = [[decoder decodeObject] retain];
		nonbondedPairs = [[self _decodeIndexArrayForKey: nil
					usingCoder: decoder
					encodedByteOrder: encodedByteOrder] 
					retain];
	}
	
	return self;
}

- (void) _encodeIndexArray: (NSArray*) indexArray
		forKey: (NSString*) key 
		usingCoder: (NSCoder*) encoder 
{
	int i, j,count;
	int totalRanges, totalSets, length;
	int* rangesPerSet;
	unsigned int *totalRangeArray;
	NSRange* rangeArray;

	totalSets = [indexArray count];

	for(totalRanges= 0,i=0; i<totalSets; i++)
		totalRanges += [[indexArray objectAtIndex: i] numberOfRanges];
	
	totalRangeArray = (unsigned int*)malloc(totalRanges*2*sizeof(unsigned int));
	rangesPerSet = (int*)malloc(totalSets*sizeof(int));
	for(count = 0,i=0; i<totalSets; i++)
	{
		rangeArray = [[indexArray objectAtIndex: i] indexSetToRangeArrayOfLength: &length];
		rangesPerSet[i] = length;
		for(j=0; j<length; j++)
		{
			totalRangeArray[count] = rangeArray[j].location;
			count++;
			totalRangeArray[count] = rangeArray[j].length;
			count++;
		}
		free(rangeArray);
	}

	if(key != nil)
	{
		[encoder encodeBytes: (uint8_t*)totalRangeArray 
			length: totalRanges*2*sizeof(unsigned int) 
			forKey: key];
		[encoder encodeBytes: (uint8_t*)rangesPerSet 
			length: totalSets*sizeof(int) 
			forKey: [NSString stringWithFormat: @"%@.RangesPerSet", key]];
	}
	else
	{
		[encoder encodeBytes: (uint8_t*)rangesPerSet 
			length: totalSets*sizeof(int)];
		[encoder encodeBytes: (uint8_t*)totalRangeArray 
			length: totalRanges*2*sizeof(unsigned int)];
	}	
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	[super encodeWithCoder: encoder];
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeObject: elementConfiguration forKey: @"Coordinates"];
		[encoder encodeObject: elementProperties forKey: @"Properties"];
		[encoder encodeObject: groupProperties forKey: @"GroupProperties"];
		[encoder encodeObject: interactions forKey: @"Interactions"];
		[encoder encodeObject: interactionGroups forKey: @"InteractionGroups"];
		[encoder encodeObject: interactionParameters forKey: @"InteractionParameters"];
		[encoder encodeObject: categories forKey: @"Categories"];
		[encoder encodeInt: NSHostByteOrder() forKey: @"EncodedByteOrder"];
		[self _encodeIndexArray: nonbondedPairs 
			forKey: @"NonbondedPairs"
			usingCoder: encoder];
	}
	else
	{
		[encoder encodeObject: [NSNumber numberWithInt: NSHostByteOrder()]];
		[encoder encodeObject: groupProperties];
		[encoder encodeObject: elementProperties];
		[encoder encodeObject: elementConfiguration];
		[encoder encodeObject: interactions];
		[encoder encodeObject: interactionGroups];
		[encoder encodeObject: interactionParameters];
		[encoder encodeObject: categories];
		[self _encodeIndexArray: nonbondedPairs
			forKey: nil
			usingCoder: encoder];
	}
} 

@end


@implementation AdMutableDataSource

/*
 * Adding things
 */

- (void) addInteraction: (NSString*) name 
		withGroups: (AdDataMatrix*)  group
		parameters: (AdDataMatrix*) parameters
		constraint: (id) object
		toCategory: (NSString*) category
{
	//Calling private category implementation
	[self _addInteraction: name
		withGroups: group
		parameters: parameters
		constraint: object 
		toCategory: category];
}

/**
Adds \e group with \e parameters to the group and parameter
matrices of \e interaction. Does nothing if \e group is nil. 
Raises an NSInternalInconsistencyException if is no group matrix associated with \e interaction.
Raises an NSInvalidArgumentException if group does not have the correct number of elements.
\param group An array of element indexes. The number of indexes must be the
same as the number of columns in \e interactions group matrix. 
\param parameters An NSDictionary containing the parameters corresponding to \e group.
The keys are the column headers for the parameter matrix of \e interaction. If all keys
are not present an NSInvalidArgumentException is raised. 
\param interaction The interaction that \e group and \e parameters are to be added to.
*/
- (void) addGroup: (NSArray*) group 
		withParameters: (NSDictionary*) parameters
		toInteraction: (NSString*) interaction
{
	int lastRow;
	NSArray* headers;
	NSEnumerator* keyEnum;
	AdMutableDataMatrix *groupMatrix, *parameterMatrix;
	id key;

	groupMatrix = [interactionGroups objectForKey: interaction];

	if(group == nil)
		return;

	if(groupMatrix == nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"No group matrix exits for interaction %@", 
			interaction];

	//Check group has the correct size
	if([group count] != [groupMatrix numberOfColumns])
		[NSException raise: NSInvalidArgumentException
			format: @"Specified group %@ does not have the correct number of elements (%d)", 
			group,
			[groupMatrix numberOfRows]];

	//Check all the required parameters are specified
	parameterMatrix = [interactionParameters objectForKey: interaction];
	headers = [parameterMatrix columnHeaders];
	if(![[parameters allKeys] isEqual: headers])
		[NSException raise: NSInvalidArgumentException
			format: @"All required parameters (%@) not specified - (%@)", 
			headers,
			[parameters allKeys]];
	
	//everything is okay. Add the interaction
	[groupMatrix extendMatrixWithRow: group];
	
	//Add a row, with any values, to the parameters matrix and
	//then set it with the correct values.
	[parameterMatrix extendMatrixWithRow: [parameters allValues]];	
	lastRow = [parameterMatrix numberOfRows] - 1;
	keyEnum = [parameters keyEnumerator];	
	while((key = [keyEnum nextObject]))
		[parameterMatrix setElementAtRow: lastRow
			ofColumnWithHeader: key
			withValue: [parameters objectForKey: key]];
}

/**
Adds an element with the given \e position and \e properties to
the data source. \e properties is a NSDictionary whose keys
are the column headers of the elementProperties() matrix. All keys
are required. The new entries are added to the end of the corresponding matrices.
*/
- (void) addElementWithPosition: (NSArray*) position
		properties: (NSDictionary*) aDict
{
	int lastRow;
	NSArray* headers;
	NSEnumerator* keyEnum;
	id key;

	//Check position has the correct size
	if([position count] != 3)
		[NSException raise: NSInvalidArgumentException
			format: @"Specified position vector %@ does not have the correct dimension", 
			position];

	//Check all the required properties are specified
	headers = [elementProperties columnHeaders];
	if(![[aDict allKeys] isEqual: headers])
		[NSException raise: NSInvalidArgumentException
			format: @"All required properties (%@) not specified - (%@)", 
			headers,
			[aDict allKeys]];
	
	//everything is okay. Add the element
	[elementConfiguration extendMatrixWithRow: position];
	
	//Add a row, with any values, to the properties matrix and
	//then set it with the correct values.
	[elementProperties extendMatrixWithRow: [aDict allValues]];	
	lastRow = [elementProperties numberOfRows] - 1;
	keyEnum = [aDict keyEnumerator];	
	while((key = [keyEnum nextObject]))
		[elementProperties setElementAtRow: lastRow
			ofColumnWithHeader: key
			withValue: [aDict objectForKey: key]];
}

/*
 * Setting things
 */

- (void) setElementConfiguration: (AdDataMatrix*) dataMatrix
{
	if(elementProperties != nil)
		if(![self _checkMatrix: dataMatrix againstMatrix: elementProperties])
			[self _raiseSizeMismatchException];

	if(elementConfiguration != nil)
		[elementConfiguration release];

	elementConfiguration = [dataMatrix mutableCopy];
}

- (void) setElementProperties: (AdDataMatrix*) dataMatrix
{
	if(elementConfiguration != nil)
		if(![self _checkMatrix: dataMatrix againstMatrix: elementConfiguration])
			[self _raiseSizeMismatchException];

	if(elementProperties != nil)
		[elementProperties release];

	elementProperties = [dataMatrix mutableCopy];
}

//Temporary method - in the future this list will be created by the data source
//using elementPairsNotInInteractionsOfCategory: @"Bonded"
- (void) setNonbondedPairs: (NSMutableArray*) array
{
	if(nonbondedPairs != nil)
		[nonbondedPairs release];

	nonbondedPairs = [array copy];
}

- (void) setGroupProperties: (AdDataMatrix*) dataMatrix
{
	if(groupProperties != nil)
		[groupProperties release];

	groupProperties = [dataMatrix mutableCopy];	
}

/**
Changes the value in row \e elementIndex of the column with header \e property
in the element property matrix to \e value. Raises an NSInvalidArgumentException
if no column called \e property exists or if \e elementIndex is greater than or
equal to numberOfElements().
*/
- (void) setProperty: (NSString*) property 
		ofElement: (unsigned int) elementIndex
		toValue: (id) value
{
	[elementProperties setElementAtRow: elementIndex
		ofColumnWithHeader: property
		withValue: (id) value];
}

/**
Replaces the parameters at row \e index of the parameter matrix 
of \e interaction with the values in \e aDictionary. 
Has no effect is there are no parameters associated with \e interaction.

\param index The index of the row in the parameter matrix to be modified.
\param interaction The interaction  whose parameters are to be modified.
\param parameters An NSDictionary whose keys are column headers of the parameter matrix of \e interaction. 
The matrix is modified using AdMutableDataMatrix::setElementAtRow:ofColumnWithHeader:toValue:
where row is given by \e index, the column header by each key, and the value by the object associated with 
the key.
If any key is not a valid column header an NSInvalidArgumentException is raised. 
In this case no values are modified.
*/
- (void) setParametersAtIndex: (unsigned int) index
		ofInteraction: (NSString*) interaction	
		withValues: (NSDictionary*) aDictionary 
{
	NSArray *headers;
	NSEnumerator *keyEnum;
	AdMutableDataMatrix *parameterMatrix;
	id key;

	parameterMatrix = [interactionParameters objectForKey: interaction];
	if(parameterMatrix != nil)
		return;

	headers = [parameterMatrix columnHeaders];
	//Check all the keys in aDictionary are valid
	keyEnum = [[aDictionary allKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
	{
		if(![headers containsObject: key])
			[NSException raise: NSInvalidArgumentException
				format: @"No column called %@ in parameter matrix", 
				key];
	}

	keyEnum = [[aDictionary allKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
	{
		[parameterMatrix setElementAtRow: index
			ofColumnWithHeader: key
			withValue: [aDictionary objectForKey: key]];
	}
}

/*
 * Removing things
 */
- (void) removeGroupAtIndex: (unsigned int) index ofInteraction: (NSString*) interaction
{
	NSIndexSet* indexSet;
	AdMutableDataMatrix* groupMatrix, *parameterMatrix;

	if(![interactions containsObject: interaction])
		[NSException raise: NSInvalidArgumentException
			format: @"Interaction %@ does not exist", interaction];
	
	indexSet = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(index,1)];
	groupMatrix = [interactionGroups objectForKey: interaction];
	parameterMatrix = [interactionParameters objectForKey: interaction];
	if(groupMatrix != nil)
		[groupMatrix removeRowsWithIndexes: indexSet];
	
	if(parameterMatrix != nil)
		[parameterMatrix removeRowsWithIndexes: indexSet];
}

/**
Removes all the entries in the group matrix of \e interaction that contain \e elementIndex.
If no element with \e elementIndex exists this method does nothing.
Raises an NSInvalidArgumentException if no interaction called \e interaction exists.
Does nothing if there is no group matrix associated with \e interaction.
\return Returns the number of interactions removed.
*/
- (int) removeAllGroupsOfInteraction: (NSString*) interaction 
		containingElementIndex: (unsigned int) elementIndex 
{
	NSNumber* index;
	NSIndexSet* indexSet;
	AdMutableDataMatrix* groupMatrix, *parameterMatrix;
	
	if(![interactions containsObject: interaction])
		[NSException raise: NSInvalidArgumentException
			format: @"Interaction %@ does not exist", interaction];

	groupMatrix = [interactionGroups objectForKey: interaction];
	//If there is no groupMatrix do nothing
	if(groupMatrix == nil)
		return 0;

	index = [[NSNumber alloc] initWithInt: elementIndex];
	indexSet = [groupMatrix indexesOfRowsContainingElement: index];
	[groupMatrix removeRowsWithIndexes: indexSet];
	
	//Remove the corresponding parameters
	parameterMatrix = [interactionParameters objectForKey: interaction];
	if(parameterMatrix != nil)
		[parameterMatrix removeRowsWithIndexes: indexSet];
	
	[index release];

	return [indexSet count];
}

/**
Removes \e interaction from the data source. This includes group matrices,
parameters and constraints.
*/
- (void) removeInteraction: (NSString*) interaction	
{
	NSString* category;

	if(![interactions containsObject: interaction])
		return;

	//Remove from categories first
	category = [self categoryForInteraction: interaction];
	if(![category isEqual: @"None"])
	{
		[[categories objectForKey: category]
			removeObject: interaction];
	}

	[interactions removeObject: interaction];
	[interactionGroups removeObjectForKey: interaction];
	[interactionParameters removeObjectForKey: interaction];
}

/**
Private method which decreases every index greater than 
\e elementIndex in the group matrix of \e interaction
by one.
This ensures that each index in the group matrix refers
to the correct row in the properties and configuration
matrices after an element is removed from them.
\todo Use int matrix?
*/
- (void) _reindexElementsFrom: (unsigned int) elementIndex
	inGroupMatrixOfInteraction: (NSString*) interaction	
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	int i,j, numberOfRows, numberOfColumns;
	unsigned int value;
	AdMutableDataMatrix *groupMatrix;

	groupMatrix = [interactionGroups objectForKey: interaction];
	numberOfRows = [groupMatrix numberOfRows];
	numberOfColumns = [groupMatrix numberOfColumns];
	for(i=0; i< numberOfRows; i++)
	{
		for(j=0; j< numberOfColumns; j++)
		{
			value = [[groupMatrix elementAtRow: i
		 			column: j] intValue];
			if(value > elementIndex)
			{
				value -= 1;
				[groupMatrix setElementAtRow: i
					column: j
					withValue: [NSNumber numberWithInt: value]];
			}
		}
	}
	
	[pool release];
}

/**
Returns a copy of indexArray where \e elementIndex has been removed 
from each index set and the indexes higher than it have been decreased
by one. The index set corresponding to element index is also removed.
This method will change slightly when AdDataSource has been 
updated to use such index arrays more generaly.
*/

- (NSArray*) _reindexElementsFrom: (unsigned int) elementIndex
	inIndexArray: (NSArray*) indexArray
{
	NSMutableArray* newArray, *newArrayCopy;
	NSIndexSet *indexSet;
	NSMutableIndexSet *newSet;
	NSEnumerator* indexEnum;
	
	newArray = [NSMutableArray new];
	indexEnum = [indexArray objectEnumerator];
	//Switch to iterating over the indexSet as its
	//possibly quicker than all the copying.
	while((indexSet = [indexEnum nextObject]))
	{
		if([indexSet lastIndex] >= elementIndex)
		{
			newSet = [indexSet mutableCopy];
			[newSet shiftIndexesStartingAtIndex: elementIndex + 1
				by: -1];
			indexSet = [[newSet copy] autorelease];
			[newSet release];
		}	

		[newArray addObject: indexSet];
	}
	
	//Remove the index set corresponding to elementIndex
	//Have to keep in mind that the indexArray will not
	//have an entry for the last element. This is due to the
	//fact that the index array is currently only used
	//for nonbonded interactions each indexSet only includes
	//indexes of elements higher that it. This also means
	//that if we remove the last element we have to remove
	//the last indexSet in the indexArray.
	if(elementIndex != [newArray count])
		[newArray removeObjectAtIndex: elementIndex];
	else
		[newArray removeLastObject];

	newArrayCopy = [[newArray copy] autorelease];
	[newArray release];

	return newArrayCopy;
}

/**
Removes the element identified by \e elementIndex from the data source. 
If \e elementIndex is outside the range of elements in the recevier an
NSRangeException is raised.
All interaction groups and corresponding parameters involving this atom are removed
via removeAllGroupsOfInteraction:containingElementIndex:()
Removing an element requires that the interaction groups, which are index
based, be updated. This is because the indexes of all elements
after \e elementIndex in the configuration matrix are reduced by
one after the removal.
For example there is a group (11, 12) indicating an interaction between elements
11 & 12. If element 10 is removed this group must be changed to (10,11).
\todo Remember to update group properties
*/
- (void) removeElement: (unsigned int) elementIndex
{
	NSArray* newPairs;
	NSEnumerator* interactionEnum;
	id interaction;
	NSAutoreleasePool* pool = [NSAutoreleasePool new];

	//This will raise an NSRangeException if elementIndex
	//is too great.
	[elementConfiguration removeRow: elementIndex];
	[elementProperties removeRow: elementIndex];

	//Go through each group and remove all interactions involving
	//the element. Then renumber the indexes in the group matrix
	//to relflect the fact that we removed an element from the data source
	interactionEnum = [interactions objectEnumerator];
	while((interaction = [interactionEnum nextObject]))
	{
		[self removeAllGroupsOfInteraction: interaction
			containingElementIndex: elementIndex];
		//This method decreases every index greater than elementIndex
		//by 1.
		[self _reindexElementsFrom: elementIndex
			inGroupMatrixOfInteraction: interaction];
	}		
		
	//FIXME We need to update the values in the groupProperties
	//matrix i.e. the number of atoms per residue etc.
	//However in general we wont know which of these to update
	//or how (like residue weight ...). Hence we need to create
	//e.g. a AdBiomolecularDataSource which has defined groupProperties.
	//However for now, becuase at the moment everything is a molecule,
	//we do the update here.
	[self _removeElementFromGroup: elementIndex];

	//Update the nonbonded interactions - This will also change
	newPairs = [self _reindexElementsFrom: elementIndex
			inIndexArray: nonbondedPairs];
	[nonbondedPairs release];
	nonbondedPairs = [newPairs retain];
	
	[pool release];
}

- (void) removeElements: (NSIndexSet*) indexSet
{
	unsigned int index;
	
	//We do this check first since if the index set is empty
	//the next test will raise an NSRangeException 
	//because NSNotFound is usually a large number. 
	index = [indexSet firstIndex];
	if(index == NSNotFound)
		return;

	//check the indexes are all in range
	index = [indexSet lastIndex];
	if(index >= [self numberOfElements])
		[NSException raise: NSRangeException
			format: @"Index %d is out of range 0 - %d",
			index, [self numberOfElements]];
	
	//Start from the end -
	//If we start from the beginning when we remove
	//the first element the indexes of all the elements above
	//it will be decreased by one - hence all the indexes after the first
	//in indexSet will refer to the wrong atom. If we start
	//from the end we avoid this problem
	index = [indexSet lastIndex];	
	do
	{
		[self removeElement: index];
	}
	while((index = [indexSet indexLessThanIndex: index]) != NSNotFound);
}

@end

//Temporary - see interface declaration for more
@implementation AdMutableDataSource (BiomolecularSystemExtensions)
/**
Returns the index of the residue containing element \e elementIndex
*/
- (int) _residueForElement: (unsigned int) elementIndex
{
	int count, i, residueIndex;
	NSArray* array;
	NSEnumerator* arrayEnum;

	array = [groupProperties columnWithHeader: @"Atoms"];
	arrayEnum = [array objectEnumerator];
	for(count = 0, residueIndex= -1, i=0; i<(int)[array count]; i++)
	{
		count += [[array objectAtIndex: i] intValue];
		if((int)elementIndex < count)
		{
			residueIndex = i;
			break;
		}	
	}		

	//Check for an error
	if(residueIndex == -1)
		[NSException raise: NSInvalidArgumentException
			format: @"Unable to find residue for index %d", 
			elementIndex];

	return residueIndex;
}

/**
Removes the element \e elementIndex from whichever group its in.
Basically involves subtracting one from the atoms column of the 
corresponding residue.
*/
- (void) _removeElementFromGroup: (unsigned int) elementIndex
{
	int residueIndex, atoms;

	residueIndex = [self _residueForElement: elementIndex];
	atoms = [[groupProperties elementAtRow: residueIndex
			ofColumnWithHeader: @"Atoms"] intValue];
	atoms -= 1;
	[groupProperties setElementAtRow: residueIndex
		ofColumnWithHeader: @"Atoms"
		withValue: [NSNumber numberWithInt: atoms]];
}

@end

