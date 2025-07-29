/*
 Project: Adun
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Author: Michael Johnston
 
 Created: 2008-07-23 by michael johnston
 
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
#include <AdunKernel/AdunElementSelection.h>
#include <AdunKernel/AdIndexSetConversions.h>

//Keys of a specifier dictionary.
const NSString* AdStringSpecifier = @"AdStringSpecifier";
const NSString* AdIndexSpecifier = @"AdIndexSpecifier";
const NSString* AdSpecifierType = @"AdSpecifierType";
const NSString* AdSpecifierData = @"AdSpecifierData";

//Keys of the dictionary that is passed to the designated initialiser
const NSString* AdGroupCategory = @"AdGroupCategory";
const NSString* AdGroupSubcategory = @"AdGroupSubcategory";
const NSString* AdElementCategory = @"AdElementCategory";
const NSString* AdElementSubcategory = @"AdElementSubcategory";

@implementation NSString (AdElementSelectionExtensions)

- (NSRange) rangeOfCharactersFromSet: (NSCharacterSet*) characterSet
{
	unsigned int i;
	NSRange range;
	
	//First check if any of the characters are present
	range = [self rangeOfCharacterFromSet: characterSet];
	if(range.location != NSNotFound)
	{
		for(i=range.location+1; i<[self length]; i++)
		{
			if(![characterSet characterIsMember: [self characterAtIndex: i]])
				break;
		}
		
		range.length = i - range.location;
	}
		
	return range;
}

@end

@implementation AdElementSelection

- (NSMutableDictionary*) _processSpecifier: (NSString*) specifier
{
	int location, length;
	NSRange range;
	NSCharacterSet *integerRangeSet, *alphanumericSet;
	NSArray* indices;
	NSIndexSet* indexSet;
	NSMutableDictionary* resultsDict = [NSMutableDictionary dictionary];
	
	integerRangeSet = [NSCharacterSet characterSetWithCharactersInString: @"1234567890-"];
	alphanumericSet = [NSCharacterSet alphanumericCharacterSet];
	
	range = NSMakeRange(0,[specifier length]);
	
	//Specifiers can either be integer ranges or alphanumeric
	//First check is it a range specifier then a string specifier
	if(NSEqualRanges(range, [specifier rangeOfCharactersFromSet: integerRangeSet]))
	{
		indices = [specifier componentsSeparatedByString: @"-"];
		if([indices count] > 2)
		{
			[NSException raise: NSInvalidArgumentException
				    format: @"Invalid range specifier - %@", specifier];
		}
		else
		{
			if([indices count] == 1)
			{
				indexSet = [NSIndexSet indexSetFromArray: indices];
			}
			else
			{
				location = [[indices objectAtIndex:0] intValue];
				length = [[indices objectAtIndex:1] intValue] - location;
				range = NSMakeRange(location, length);
				indexSet = [NSIndexSet indexSetWithIndexesInRange: range];
			}
			
			[resultsDict setObject: AdIndexSpecifier forKey: AdSpecifierType];
			[resultsDict setObject: indexSet forKey: AdSpecifierData];
		}
	}
	else if(NSEqualRanges(range, [specifier rangeOfCharactersFromSet: alphanumericSet]))
	{
		[resultsDict setObject: AdStringSpecifier forKey: AdSpecifierType];
		[resultsDict setObject: specifier forKey: AdSpecifierData];
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
			    format: @"Specifier - %@ - contains invalid characters", specifier];
	}
	
	return resultsDict;
}

+ (id) biomolecularSelectionWithString: (NSString*) aString
{
	NSDictionary* dictionary;

	dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				@"Residue Name", @"AdGroupCategory",
				@"PDBName", @"AdElementCategory", nil];
				
	return [[[AdElementSelection alloc] 
			initWithSelectionCategories: dictionary 
			selectionString: aString] autorelease];
}

- (id) init
{
	return [self initWithSelectionCategories: nil selectionString: nil];
}

- (id) initWithSelectionCategories: (NSDictionary*) categories
		selectionString: (NSString*) aString
{
	if(self == [super init])
	{	
		groupCategory = [categories objectForKey: AdGroupCategory];
		elementCategory = [categories objectForKey: AdElementCategory];
		specifierDict = [NSMutableDictionary new];
		
		if(groupCategory == nil || elementCategory == nil)
		{
			[self release];
			[NSException raise: NSInvalidArgumentException
				format: @"Missing required field in category dictionary %@", categories];
		}

		if(aString != nil)
			[self setSelectionString: aString];
	}
	
	return self;
}

- (void) dealloc
{
	[selectionString release];
	[specifierDict release];
	[super dealloc];
}

- (void) setSelectionString: (NSString*) aString
{
	int count;
	NSCharacterSet* categorySet, *commaSet;
	NSScanner* categoryScanner;
	NSMutableDictionary *result;
	NSString *categoryString, *categoryCode;
	NSArray *specifiers, *splitSpecifier;
	NSMutableArray* processedSpecifiers;
	NSEnumerator* specifierEnum;
	id specifier, subspecifier;
	
	[specifierDict removeAllObjects];
	
	categorySet = [NSCharacterSet characterSetWithCharactersInString: @":@"];
	commaSet = [NSCharacterSet characterSetWithCharactersInString: @","];
		
	categoryScanner = [NSScanner scannerWithString: aString];
	
	//Scan up to the first category character - this must be either : or @
	//Only two categories are possible 
	count = 0;
	while(![categoryScanner isAtEnd] && count < 2)
	{
		//Check the string begins with a category code
		if(![categoryScanner scanCharactersFromSet: categorySet intoString: &categoryCode])
		{
			[NSException raise: NSInvalidArgumentException
				format: @"Invalid initial character - %c", [aString characterAtIndex: 0]];
		}
		
		NSDebugLLog(@"AdElementSelection", @"Count %d. Category Code %@", count, categoryCode);
		
		//Scan everything for this category into a string
		//If nothing is provided this is an error
		if([categoryScanner scanUpToCharactersFromSet: categorySet 
			intoString: &categoryString])
		{	
			NSDebugLLog(@"AdElementSelection", @"Category String %@", categoryString);
			//If we are here then categoryString has some characters in it
			//Split it by commas - then check each specifier for validity
			specifiers = [categoryString componentsSeparatedByString: @","];
			processedSpecifiers = [NSMutableArray array];
			specifierEnum = [specifiers objectEnumerator];
			while((specifier = [specifierEnum nextObject]))
			{
				//Check if there are subcategories
				splitSpecifier = [specifier componentsSeparatedByString: @"."];
				if([splitSpecifier count] == 1)
				{
					//No subcategories
					result = [self _processSpecifier: specifier];
					[processedSpecifiers addObject: result];
				}
				else if([splitSpecifier count] == 2)
				{
					//Subcategory
					result = [self _processSpecifier: [splitSpecifier objectAtIndex: 0]];
					subspecifier = [self _processSpecifier: [splitSpecifier objectAtIndex: 1]];
					[result setObject: subspecifier forKey: @"AdSubcategorySpecifier"];
					[processedSpecifiers addObject: result];
				}
				else
				{
					//Error - To many '.'
					[NSException raise: NSInvalidArgumentException
						format: @"Invalid specifier - %@ - Only one subcategory may be specified", 
						specifier];
				}
			}
			
			[specifierDict setObject: processedSpecifiers forKey: categoryCode];
			
			NSDebugLLog(@"AdElementSelection", @"SpecifierDict %@", specifierDict);
		}
		else
		{	
			[NSException raise: NSInvalidArgumentException
				format: @"Specifier string invalid - category present with no specifiers"];
		}
		
		categoryCode = nil;
		categoryString = nil;
		count++;
	}
	
	//Retain the selection string if we get this far
	selectionString = [aString copy];
	
	//FIXME: Consolidate ...
	//Combine index and string specifiers in a category if they have no subcategories.
	
	NSDebugLLog(@"AdElementSelection", @"Parsing done");
}

- (NSString*) selectionString
{
	return [[selectionString retain] autorelease];
}

- (NSMutableIndexSet*) _rowsInMatrix: (AdDataMatrix*) aMatrix
			matchingSpecifiers: (NSArray*) specifiers
			categoryColumn: (NSString*) categoryColumn
			subcategoryColumn: (NSString*) subcategoryColumn
			restrictToRows: (NSIndexSet*) restrictRows
{
	unsigned int i, numberRows, index;
	unsigned int *buffer;
	NSRange matrixRange;
	NSString *name;
	NSArray *types, *categoryData;
	NSMutableArray* stringSpecifiers = [NSMutableArray array];
	NSMutableIndexSet *selectedRows = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *nonSelectedRows, *ignoreRows;
	NSDictionary* stringSpecifier;
	NSEnumerator* specifierEnum;
	id type, data;
		
	matrixRange = NSMakeRange(0, [aMatrix numberOfRows]);
	nonSelectedRows = [NSMutableIndexSet indexSetWithIndexesInRange: matrixRange];
	
	//If no specifier is given create one which selects every row in the matrix
	if(specifiers == nil || [specifiers count] == 0)
	{
		specifiers = [NSArray arrayWithObject:
				[NSDictionary dictionaryWithObjectsAndKeys:
					AdIndexSpecifier, AdSpecifierType,
					[[nonSelectedRows copy] autorelease], AdSpecifierData,
					nil]];
	}

	//restrictRows contains the indexes of the rows of the matrix
	//that the filtering should be restricted to.
	//ignoreRows is the inverse of this index set.
	if(restrictRows == nil)
	{
		ignoreRows = [NSMutableIndexSet indexSet];
	}	
	else	
	{	
		ignoreRows = [[nonSelectedRows mutableCopy] autorelease];
		[ignoreRows removeIndexes: restrictRows];
	}
	
	//Identify the AdIndexSpecifier's and collect those indexes into the variable 'indexes'.
	//Remove those indexes from nonSelectedIndexes.
	//This last part is done so the selected indexes won't be
	//searched during the string search.
	types = [specifiers valueForKey: (NSString*)AdSpecifierType];
	for(i=0; i<[types count]; i++)
	{
		type = [types objectAtIndex: i];
		data = [specifiers objectAtIndex: i];
		if([type isEqual: AdIndexSpecifier])
		{
			[selectedRows addIndexes: 
				[data objectForKey: AdSpecifierData]];
			[nonSelectedRows removeIndexes: 
				[data objectForKey: AdSpecifierData]];
		}
		else
		{
			[stringSpecifiers addObject: data];
		}
	}
	
	NSDebugLLog(@"AdElementSelection", @"Selected rows %@", selectedRows);
	
	//Remove from selectedRows any indexes which are in ignoreRows
	//Do the same for nonSelectedRows
	[selectedRows removeIndexes: ignoreRows];
	[nonSelectedRows removeIndexes: ignoreRows];
				
	//Put all non selected indexes into a buffer for speed
	numberRows = [nonSelectedRows count];
	buffer = [[AdMemoryManager appMemoryManager] 
			allocateArrayOfSize: numberRows*sizeof(int)];
	[nonSelectedRows getIndexes: buffer maxCount: numberRows inIndexRange: NULL];
	
	//Iterate through the string specifiers and find which of the groups match them.
	//FIXME: Invert iteration
	categoryData = [aMatrix columnWithHeader: categoryColumn];
	specifierEnum = [stringSpecifiers objectEnumerator];
	while((stringSpecifier = [specifierEnum nextObject]))
	{
		name = [stringSpecifier objectForKey: AdSpecifierData];
		name = [name uppercaseString];
		for(i=0; i<numberRows; i++)
		{
			index = buffer[i];
			if([[categoryData objectAtIndex: index] isEqual: name])
				[selectedRows addIndex: index];	
		}
	}
	
	[[AdMemoryManager appMemoryManager] freeArray: buffer];
	
	return selectedRows;
}

- (NSIndexSet*) matchingGroupsInDataSource: (AdDataSource*) dataSource
{
	AdDataMatrix* groupProperties;
	NSArray* groupSpecifiers;

	groupProperties = [dataSource groupProperties];
	groupSpecifiers = [specifierDict objectForKey: @":"];
	NSDebugLLog(@"AdElementSelection", @"Specifiers %@", specifierDict);
	return [self _rowsInMatrix: groupProperties 
			matchingSpecifiers: [specifierDict objectForKey: @":"]
			categoryColumn: groupCategory
			subcategoryColumn: nil 
			restrictToRows: nil];
}

- (NSIndexSet*) matchingElementsInDataSource: (AdDataSource*) dataSource
{
	int i, numberResidues;
	NSRange range;
	NSArray *elementsPerResidue;
	NSIndexSet *groupIndexes;
	NSMutableIndexSet *elementIndexes = [NSMutableIndexSet indexSet];
	AdDataMatrix *groupProperties, *elementProperties;

	groupIndexes = [self matchingGroupsInDataSource: dataSource];
		
	groupProperties = [dataSource groupProperties];
	numberResidues = [groupProperties numberOfRows];
	elementProperties = [dataSource elementProperties];
	range = NSMakeRange(0,0);
	
	/*
	 * FIXME: Need to have a column containing ranges
	 * That is need to have a column that defines the mapping between elements and groups.
	 * 'Atoms' will only work for groups which subdivide all the elements
	 * and only contain contiguous elements.
	 * However this also requires that multiple types of group properties matrix exist
	 * and the one to use can be specified (since Atoms is okay for the only current 
	 * type of group matrix).
	 */
	elementsPerResidue = [groupProperties columnWithHeader: @"Atoms"];
	for(i=0; i<numberResidues; i++)
	{
		range.location = NSMaxRange(range);
		range.length = [[elementsPerResidue objectAtIndex: i] intValue];
		if([groupIndexes containsIndex: i])
			[elementIndexes addIndexesInRange: range];
	}
		
	elementIndexes = [self _rowsInMatrix: elementProperties
				matchingSpecifiers: [specifierDict objectForKey: @"@"]
				categoryColumn: elementCategory
				subcategoryColumn: nil
				restrictToRows: elementIndexes];
				
	return elementIndexes;
}

@end
