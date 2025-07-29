/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-02 15:34:11 +0200 by michael johnston

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
#include "AdunKernel/AdunDataSet.h"

/*
We also need the class of each object that generated the data so we can
search the correct table.
*/

@implementation AdDataSet

- (id) init
{
	return [self initWithName: @"None"];
}

- (id) initWithName: (NSString*) aString
{
	return [self initWithName: aString
			inputReferences: nil];
}

-(id) initWithName: (NSString*) aString inputReferences: (NSDictionary*) aDict;
{
	return [self initWithName: aString
		inputReferences: aDict
		dataGeneratorName: @"Unknown"
		dataGeneratorVersion: @"1.0"];
}

- (id) initWithName: (NSString*) aString 
	inputReferences: (NSDictionary*) aDict 
	dataGenerator: (NSBundle*) aBundle 
{
	NSString* generatorName;
	NSString *version;

	version = [[aBundle infoDictionary] objectForKey: @"PluginVersion"];
	generatorName = [aBundle bundleIdentifier];

	return [self initWithName: aString 
		inputReferences: aDict 
		dataGeneratorName: generatorName 
		dataGeneratorVersion: version];
}

- (id) initWithName: (NSString*) stringOne 
	inputReferences: (NSDictionary*) aDict 
	dataGeneratorName: (NSString*) stringTwo
	dataGeneratorVersion: (NSString*) aNumber
{
	if((self = [super init]))
	{
		if(stringOne != nil)
			[self setValue: stringOne 
				forMetadataKey: @"Name"
				inDomain: AdUserMetadataDomain];

		[inputReferences addEntriesFromDictionary: aDict];

		if(stringTwo != nil)
			[self setValue: stringTwo 
				forMetadataKey: @"dataGeneratorName"
				inDomain: AdSystemMetadataDomain];
		else
			[self setValue: @"Unknown"
				forMetadataKey: @"dataGeneratorName"
				inDomain: AdSystemMetadataDomain];
		
		//FIXME: Possible gnustep bug. 	When encoding aNumber if it
		//was originaly read from a propertyList file (most likely)
		//then it doesnt decode properly.
		//By creating a new string from it it works.
		//Should be invesitagted further.
		
		if(aNumber == nil)
			aNumber = @"1.0";
		
		[self setValue: [NSString stringWithString: aNumber]
			forMetadataKey: @"dataGeneratorVersion"
			inDomain: AdSystemMetadataDomain];

		dataMatrices = [NSMutableArray new];

		dataGeneratorID = [NSString stringWithFormat: @"%@_%@",
					[self valueForMetadataKey: @"dataGeneratorName"],
					aNumber];
		[dataGeneratorID retain];			

	}

	return self;
}

- (void) dealloc
{
	[dataGeneratorID release];
	[dataMatrices release];
	[super dealloc];
}

- (id) valueForKey: (NSString*) key
{
	id value;
	
	NSDebugLLog(@"AdDataSet", @"Request for key %@", key);
	NSDebugLLog(@"AdDataSet", @"Receiver class - %@", [self class]);
	
	//Check if its a request for a column
	if([self containsDataMatrixWithName: key])
	{
		value = [self dataMatrixWithName: key];
	}
	else
	{
		value = [super valueForKey: key];
	}
	
	return [[value retain] autorelease];
}

- (NSArray*) dataMatrixNames
{
	return [dataMatrices valueForKey: @"name"];
}

- (BOOL) containsDataMatrix: (AdDataMatrix*) aDataMatrix;
{
	if([dataMatrices indexOfObject: aDataMatrix] != NSNotFound)
		return YES;
	else
		return NO;
}

- (BOOL) containsDataMatrixWithName: (NSString*) aString;
{
	AdDataMatrix* dataMatrix;

	dataMatrix = [self dataMatrixWithName: aString];
	if(dataMatrix != nil)
		return YES;
	else
		return NO;
}		

- (void) addDataMatrix: (AdDataMatrix*) aDataMatrix
{
	if(aDataMatrix != nil)
		[dataMatrices addObject: aDataMatrix];
}

- (void) removeDataMatrix: (AdDataMatrix*) aDataMatrix
{
	if(aDataMatrix != nil)
		[dataMatrices removeObject: aDataMatrix];
}

- (BOOL) removeDataMatrixWithName: (NSString*) aString
{
	id dataMatrix;

	dataMatrix = [self dataMatrixWithName: aString];
	if(dataMatrix != nil)
	{
		[dataMatrices removeObject: dataMatrix];
		return YES;
	}
	else
		return NO;
}

- (NSArray*) dataMatrices
{
	return [[dataMatrices copy] autorelease];
}

- (AdDataMatrix*) dataMatrixWithName: (NSString*) aString
{
	NSEnumerator* dataMatrixEnum = [dataMatrices objectEnumerator];
	id dataMatrix;
	
	if(aString == nil)
		return nil;
	
	dataMatrix = nil;
	while((dataMatrix = [dataMatrixEnum nextObject]))
	{
		if([[dataMatrix name] isEqual: aString])
			break;
	}

	return [[dataMatrix retain] autorelease];
}

- (NSString*) dataGeneratorID
{
	return dataGeneratorID;
}

- (NSString*) dataGeneratorName
{
	return [self valueForMetadataKey: @"dataGeneratorName"];
}

- (void) setDataGeneratorName: (NSString*) aString
{
	id dataGeneratorName;

	dataGeneratorName = [self valueForMetadataKey: @"dataGeneratorName"];
	if(aString != dataGeneratorName)
		[self setValue: aString forMetadataKey: @"dataGeneratorName"];
}

- (double) dataGeneratorVersion
{
	return [[self valueForMetadataKey: @"dataGeneratorVersion"] 
			doubleValue];	
}

- (void) setDataGeneratorVersion: (double) aNumber
{
	[self setValue: [NSNumber numberWithDouble: aNumber] 
		forMetadataKey: @"dataGeneratorVersion"];
}

- (NSString*) description
{
	NSMutableString* string = [NSMutableString string];
	NSEnumerator* matrixEnum;
	AdDataMatrix* matrix;

	[string appendFormat: @"%@\n", [self name]];
	if([dataMatrices count] == 1)
		[string appendFormat: @"\nContains %d data matrix\n\n", 
			[dataMatrices count]];
	else
		[string appendFormat: @"\nContains %d data matrices\n\n", 
			[dataMatrices count]];

	matrixEnum = [dataMatrices objectEnumerator];
	while((matrix = [matrixEnum nextObject]))
		[string appendFormat: @"%@", [matrix description]];

	return string;	
}

/**
 Returns an enumerator over the data matrices
 */
- (NSEnumerator*) dataMatrixEnumerator
{
	return [dataMatrices objectEnumerator];
}

/**
 Returns an enumerator over the matrix names
 */
- (NSEnumerator*) nameEnumerator
{
	return [[dataMatrices valueForKey: @"name"] objectEnumerator];
}

//Coding

- (id) initWithCoder: (NSCoder*) decoder
{
	if((self = [super initWithCoder: decoder]))
	{
		if([decoder allowsKeyedCoding])
		{
			dataGeneratorID = [decoder decodeObjectForKey: @"dataGeneratorID"];
			dataMatrices = [decoder decodeObjectForKey: @"dataMatrices"];

		}
		else
		{
			dataGeneratorID = [decoder decodeObject];
			dataMatrices = [decoder decodeObject];
		}
		
		[dataGeneratorID retain];
		[dataMatrices retain];
	}

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	[super encodeWithCoder: encoder];
	
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeObject: dataGeneratorID forKey: @"dataGeneratorID"];
		[encoder encodeObject: dataMatrices forKey: @"dataMatrices"];
	}
	else
	{
		[encoder encodeObject: dataGeneratorID];
		[encoder encodeObject: dataMatrices];
	}
}

@end
