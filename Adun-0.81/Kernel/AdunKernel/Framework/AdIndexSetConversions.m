/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-07-15 11:25:33 +0200 by michael johnston

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

#include "AdunKernel/AdIndexSetConversions.h"

#define	GSI_ARRAY_TYPE	NSRange
#define GSI_ARRAY_TYPES	GSI_ARRAY_EXTRA
#define	GSI_ARRAY_NO_RELEASE	1
#define	GSI_ARRAY_NO_RETAIN	1

#include "GNUstepBase/GSIArray.h"

@implementation NSIndexSet (AdIndexSetConversions)

+ (id) indexSetFromRangeArray: (NSRange*) rangeArray ofLength: (int) length;
{
	NSMutableIndexSet *indexSet;
	int i;

	indexSet = [NSMutableIndexSet indexSet];
	for(i=0; i<length; i++)
		[indexSet addIndexesInRange: rangeArray[i]];

	NSDebugLLog(@"AdIndexSetConversions", @"Created index set from range array");

	return [[[[self class] alloc] initWithIndexSet: indexSet] autorelease];
}

- (NSRange*) indexSetToRangeArrayOfLength: (int*) length
{
	int i;
	NSRange* rangeArray;
	int numberOfRanges;
#if NeXT_RUNTIME != 1
	GSIArray _myArray;
	
	//Heavily tested on gnustep - Wont work on Mac since it uses
	//internal details of the gnustep implementation	
	_myArray = ((GSIArray)(self->_data));
	numberOfRanges = (_myArray == 0) ? 0 : GSIArrayCount(_myArray);
	rangeArray = (NSRange*)malloc(numberOfRanges*sizeof(NSRange));
 	for(i = 0; i < numberOfRanges; i++)
		rangeArray[i] = GSIArrayItemAtIndex(_myArray, i).ext;

	*length = numberOfRanges;
#else
	int numberOfIndexes;
	int currentRange, lastIndex, currentIndex;
	unsigned int* indexBuffer;
	
	//Test Mac OSX - More complicated since  the ivars arent documented
	//, are protected, and I dont want to have to try to figure it all out.
	numberOfRanges = [self numberOfRanges];
	*length = numberOfRanges;
	numberOfIndexes = [self count];
	rangeArray = (NSRange*)malloc(numberOfRanges*sizeof(NSRange));
	if(numberOfRanges != 0)
	{
		indexBuffer = malloc(numberOfIndexes*sizeof(int));
		[self getIndexes: indexBuffer
			maxCount: numberOfIndexes
			inIndexRange: nil];
	
		currentRange = 0;
		rangeArray[currentRange].location = indexBuffer[0];		
		lastIndex = indexBuffer[0];	
		for(i=1; i<numberOfIndexes; i++)
		{
			currentIndex = indexBuffer[i];
			//Check if the indexes are contiguous
			if(currentIndex != lastIndex + 1)
			{
				rangeArray[currentRange].length = lastIndex + 1 - rangeArray[currentRange].location;
				currentRange++;
				rangeArray[currentRange].location = currentIndex;
			}
	
			lastIndex = currentIndex;
		}
	
		//Close the last range.
		rangeArray[currentRange].length = lastIndex + 1 - rangeArray[currentRange].location;
		free(indexBuffer);
	}	
#endif	

	return rangeArray;
}

- (id) initWithCoder: (NSCoder*) decoder
{
	int byteSwapFlag;
	unsigned int i, encodedByteOrder, length;
	NSRange* rangeArray, *range;
	NSIndexSet* indexSet;

	NSDebugLLog(@"AdIndexSetConversions", @"Decoding rangeArray");

	if([decoder allowsKeyedCoding])
	{
		rangeArray = (NSRange*)[decoder decodeBytesForKey:@"" returnedLength: &length];
		encodedByteOrder = [decoder decodeIntForKey: @"EncodedByteOrder"];
	}
	else
	{
		rangeArray = (NSRange*)[decoder decodeBytesWithReturnedLength: &length];
		encodedByteOrder = [[decoder decodeObject] intValue];
	}	
	length /= sizeof(NSRange);

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

	//Swap bytes if neccessary.
	if(byteSwapFlag == AdSwapBytesToBig)
	{
		for(i=0; i < length; i++)
		{
			range = (rangeArray + i);
			range->location = NSSwapLittleIntToHost(range->location);
			range->length = NSSwapLittleIntToHost(range->length);
		}	
	}
	else if(byteSwapFlag == AdSwapBytesToLittle)
	{
		for(i=0; i < length; i++)
		{
			range = (rangeArray + i);
			range->location = NSSwapBigIntToHost(range->location);
			range->length = NSSwapBigIntToHost(range->length);
		}	
	}

	indexSet = [NSIndexSet indexSetFromRangeArray: rangeArray ofLength: length];
	NSDebugLLog(@"AdIndexSetConversions", @"Decoded %d bytes. complete", length);

	if([self isMemberOfClass: [NSMutableIndexSet class]])
	{
		[self release];
		return [indexSet mutableCopy];
	}	
	else
	{
		[self release];
		return [indexSet retain];
	}	
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	NSRange* rangeArray;
	int numberOfRanges;

	NSDebugLLog(@"AdIndexSetConversions", @"Encoding index set");
	rangeArray = [self indexSetToRangeArrayOfLength: &numberOfRanges];
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeBytes: (uint8_t*)rangeArray
			length: numberOfRanges*sizeof(NSRange)
			forKey: @""];
		[encoder encodeInt: NSHostByteOrder() forKey: @"EncodedByteOrder"];
		
	}		
	else
	{
		[encoder encodeBytes: rangeArray
			length: numberOfRanges*sizeof(NSRange)];
		[encoder encodeObject: [NSNumber numberWithInt: NSHostByteOrder()]];
	}	

	free(rangeArray);
	NSDebugLLog(@"AdIndexSetConversions", @"Encoding complete");
}

-(int) numberOfRanges
{
#if NeXT_RUNTIME != 1
	GSIArray _myArray;		
	
	_myArray = ((GSIArray)(self->_data));
	return (_myArray == 0) ? 0 : GSIArrayCount(_myArray);
#else	
	//Mac OSX - Cant access the ivars.
	//Instead parsing the description string which has the format
	//<NSXIndexSet  >[%d indexes in %d ranges ....] 
	int numberIndexes, numberRanges;
	NSRange range;
	NSString* description;
	NSScanner* scanner;
	
	if([self count] != 0)
	{
		description = [self description];
		scanner = [[NSScanner alloc] initWithString: description];
		range = [description rangeOfString: @"["];
		[scanner setCharactersToBeSkipped: 
			[[NSCharacterSet decimalDigitCharacterSet]
				invertedSet]];
		[scanner setScanLocation: range.location];		
		[scanner scanInt: &numberIndexes];
		[scanner scanInt: &numberRanges];
		[scanner release];
	}
	else
		numberRanges = 0;
	
	return numberRanges;
#endif	
}

+ (id) indexSetFromArray: (NSArray*) array
{
	NSMutableIndexSet* indexSet;
	NSIndexSet* copy;
	NSEnumerator* arrayEnum;
	id element;

	indexSet = [NSMutableIndexSet new];
	arrayEnum = [array objectEnumerator];
	while((element = [arrayEnum nextObject]))
	{
		if(![element respondsToSelector: @selector(intValue)])
		{
			[indexSet release];
			[NSException raise: NSInvalidArgumentException
				format: @"All elements in array must respond to intValue"];
		}
		[indexSet addIndex: [element intValue]];
	}

	copy = [[[self class] alloc] initWithIndexSet: indexSet];
	[indexSet release];

	return [copy autorelease];
}

@end
