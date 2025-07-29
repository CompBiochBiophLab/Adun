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

#include "AdunKernel/AdunDataMatrix.h"

static NSArray* allowedDataTypes;
static NSDictionary* dataTypeToClassMap;
static NSDictionary* classToDataTypeMap;
#ifndef GNUSTEP
static NSArray* integerEncodings;
#endif

@class AdMutableDataMatrix;

#ifndef GNUSTEP
//OSX - Definitons of NSIntNumber and NSDoubleNumber so they
//can be used with Cocoa. The only use of these classes is
//as keys in the classToDataTypeMap and values in dataTypeToClassMap.
@interface NSIntNumber: NSNumber
{
}
@end

@implementation NSIntNumber: NSNumber
@end

@interface NSDoubleNumber: NSNumber
{
}
@end

@implementation NSDoubleNumber
@end
#else
@class NSDoubleNumber;
@class NSIntNumber;
#endif

@implementation NSArray (AdKernelAdditions)

+ (id) arrayFromCIntArray: (int*) buffer ofLength: (int) length
{
	int i;
	id array, finalArray;
	
	array = [NSMutableArray new];
	for(i=0; i<length; i++)
		[array addObject: [NSNumber numberWithInt: buffer[i]]];
	
	//If this message was sent to NSArray return a non-mutable array	
	if(![self isSubclassOfClass: [NSMutableArray class]])
	{
		finalArray = [array copy];
		[array release];
	}
	else
		finalArray = array;
	
	return [finalArray autorelease];	
}

+ (id) arrayFromCDoubleArray: (double*) buffer ofLength: (int) length
{
	int i;
	id array, finalArray;
	
	array = [NSMutableArray new];
	for(i=0; i<length; i++)
		[array addObject: [NSNumber numberWithDouble: buffer[i]]];
		
	//If this message was sent to NSArray return a non-mutable array	
	if(![self isSubclassOfClass: [NSMutableArray class]])
	{
		finalArray = [array copy];
		[array release];
	}
	else
		finalArray = array;
		
	return [finalArray autorelease];	
}

- (NSArray*) subarrayFromElementSelection: (NSIndexSet*) indexSet
{
	int index, i;
	unsigned int* buffer;
	NSMutableArray* subarray = [NSMutableArray new];
	NSArray* arrayCopy;

	//Check for range problems
	index = [indexSet lastIndex];

	if(index != NSNotFound)
	{
		if(index >= (int)[self count])
			[NSException raise: NSRangeException
				format: @"Index %d is out of range (%d)", 
				index,
				[self count]];

		//FIXME: Switch to using buffer for efficency
		buffer = (unsigned int*)malloc([indexSet count]*sizeof(unsigned int));
		[indexSet getIndexes: buffer 
			    maxCount: [indexSet count]
			inIndexRange: NULL];
		for(i=0; i<(int)[indexSet count]; i++)
			[subarray addObject: 
				[self objectAtIndex: buffer[i]]];
		
		free(buffer);
	}	

	arrayCopy = [subarray copy];
	[subarray release];
	return [arrayCopy autorelease];
}

- (int) countForObject: (id) object
{
	int count = 0;
	NSEnumerator* arrayEnum;
	id element;
	
	arrayEnum = [self objectEnumerator];
	while((element = [arrayEnum nextObject]))
		if([element isEqual: object])
			count ++;
	
	return count;		
}

-(double*) cDoubleRepresentation;
{
	int i = 0;
	double value;
	double *cArray;
	NSEnumerator* arrayEnum;
	id object;
	
	cArray = malloc([self count]*sizeof(double));
	arrayEnum = [self objectEnumerator];
	
	while((object = [arrayEnum nextObject]))
	{
		value = 0;
		if([object respondsToSelector: @selector(doubleValue)])
			value = [object doubleValue];
		
		cArray[i] = value;	
		i++;
	}
	
	return cArray;
}

-(gsl_vector*) gslVectorRepresentation;
{
	int i = 0;
	double value;
	gsl_vector* vector;
	NSEnumerator* arrayEnum;
	id object;
	
	vector = gsl_vector_alloc([self count]);
	arrayEnum = [self objectEnumerator];
	
	while((object = [arrayEnum nextObject]))
	{
		value = 0;
		if([object respondsToSelector: @selector(doubleValue)])
			value = [object doubleValue];
		
		gsl_vector_set(vector, i, value);	
		i++;
	}
	
	return vector;
}

@end

/*
Category containing method for converting added elements
to the correct types for each column
*/
@interface AdDataMatrix (PrivateElementConversions)
/**
Returns the allowed class \e object is descended from
or nil if there is none.
*/
- (Class) allowedSuperClassForObject: (id) object;
/**
Converts object to the correct representation for column. If 
no dataType has been set for columnIndex an exception is raised.
If the conversion if not possible raise an exception.
*/
- (id) representationOfObject: (id) object forColumn: (unsigned int) columnIndex;
/**
Sets the data type for each column to be the type defined by
the class of the corresponding element in array. 
If any of the element classes have no corresponding type 
an NSInvalidArgumentException is raised. 
If the number of elements in array are not equal to the number
of columns an NSInvalidArgumentException is raised.
In the case of an exception being raised no data types are set.
*/
- (void) setDataTypesToTypesInArray: (NSArray*) array;
@end

@implementation AdDataMatrix (PrivateElementConversions)

/* 
All NSNumber subclasses and NSString respond
to stringValue, intValue and doubleValue */
- (id) convertObject: (id) object toClassForDataType: (NSString*) type
{
	if([type isEqual: @"string"])
		return [object stringValue];
	else if([type isEqual: @"int"])
		return [NSNumber numberWithInt: [object intValue]];
	else if([type isEqual: @"double"])	
		return [NSNumber numberWithDouble: [object doubleValue]];
	
	NSWarnLog(@"Cant convert to class for data type %@", type);
	return nil;
}

- (Class) allowedSuperClassForObject: (id) object
{
	NSEnumerator* allowedClassesEnum;
	Class class;
	
#ifdef GNUSTEP
	allowedClassesEnum = [[dataTypeToClassMap allValues] objectEnumerator];
	while((class = [allowedClassesEnum nextObject]))
		if([object isKindOfClass: class])
			return class;
#else
	//OSX code - The above wont work since the dataTypeToClassMap
	//contains NSIntNumber and NSDoubleNumber for allowed superclasses and 
	//these dont exist in Cocoa. Further its difficult to determine
	//what the Cocoa analogs are. Instead we find if the encoded number
	//is of int or double type and then return NSIntNumber and NSDoubleNumber
	//depending. Thus the rest of the class is essentially "decieved" into 
	//behaving as it does on GNUstep as this is the only place where the
	//distinction matters (The class is only used to determine the data type
	//e.g. int string or double).
	NSString* objectiveCType;

	if([object isKindOfClass: [NSNumber class]])
	{
		objectiveCType = [NSString stringWithCString: [object objCType]
					encoding: NSUTF8StringEncoding];
		if([integerEncodings containsObject: objectiveCType])
			return [NSIntNumber class];
		else
			return [NSDoubleNumber class];	
	}	
	else if([object isKindOfClass: [NSString class]])
		return [NSString class];
#endif

	return nil;
}

- (id) representationOfObject: (id) object forColumn: (unsigned int) columnIndex
{
	NSString *dataType;

	dataType = [columnDataTypes objectAtIndex: columnIndex];

	//check if the class of value is of the correct type 
	//(or a descendant of that type). If not we convert it.
	if(![object isKindOfClass: [dataTypeToClassMap objectForKey: dataType]]) 
	{
		object = [self convertObject: object toClassForDataType: dataType];
		if(object == nil)
			[NSException raise: NSInvalidArgumentException
				format: @"Cannot convert object of class %@", [object class]];
	}			

	return object;	
}

//Note - This can only be called once
- (void) setDataTypesToTypesInArray: (NSArray*) array
{
	NSMutableArray* typeArray = [NSMutableArray new];
	NSEnumerator* arrayEnum;
	NSString *dataType;
	id element;
	Class class;

	if([array count] != numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @"Array has incorrect number of entries"];
	
	arrayEnum = [array objectEnumerator];
	while((element = [arrayEnum nextObject]))
	{
		//First check if the elements class is a subclass of any
		//of the allowed objects.
		//Otherwise check if the class is in classToDataTypeMap
		//Note: On OSX the first condition is always true for 
		//NSNumber/NSString based objects.
		if((class = [self allowedSuperClassForObject: element]) != nil)
		{
			dataType = [classToDataTypeMap objectForKey:
					NSStringFromClass(class)];
		}
		else
		{
			dataType = [classToDataTypeMap objectForKey:
					NSStringFromClass([element class])];
			if(dataType == nil)
				[NSException raise: NSInvalidArgumentException
					format: @"AdDataMatrix - Cannot insert objects of class %@",
					[element class]];
		}

		[typeArray addObject: dataType];		
	}

	[columnDataTypes addObjectsFromArray: typeArray];
	[typeArray release];
}

@end

/*
The AdDataMatrix class implementation
*/

@implementation AdDataMatrix

/*
 * Class Methods
 */

+ (void) initialize
{
	static BOOL done = NO;

	if(!done)
	{
		allowedDataTypes = [NSArray arrayWithObjects: 
					@"string", 
					@"double", 
					@"int", nil];
		[allowedDataTypes retain];			
		
		//the classes each data type will be stored in
		dataTypeToClassMap = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSString class], @"string",
				[NSDoubleNumber class], @"double", 
				[NSIntNumber class], @"int", nil];
		[dataTypeToClassMap retain];

		//Dictionary mapping Foundation classes to data types.
		//Subclasses of the allowed classes are not included here.
		classToDataTypeMap = [NSDictionary dictionaryWithObjectsAndKeys:
				@"string", @"NSString",
				@"double", @"NSDoubleNumber", 
				@"double", @"NSFloatNumber", 
				@"int", @"NSShortNumber",
				@"int", @"NSUShortNumber",
				@"int", @"NSIntNumber",
				@"int", @"NSUIntNumber",
				@"int",	@"NSLongNumber",
				@"int",	@"NSULongNumber",
				@"int", @"NSLongLongNumber",
				@"int", @"NSULongLongNumber",
				nil];
		[classToDataTypeMap retain];
		
#if NeXT_RUNTIME == 1
		//On OSX we need to check an NSNumbers objcType to
		//determine if its an int or double. If this method
		//works the entire class may be changed to use it.
		integerEncodings = [NSArray arrayWithObjects:
					@"i", @"s", @"l", @"q", @"I", @"S", @"L", @"Q", nil];
		[integerEncodings retain];			
#endif				
								
		done = YES;
	}
}

+ (id) matrixFromGSLVector: (gsl_vector*) aVector
{
	return [[[AdDataMatrix alloc] 
			initWithGSLVector: aVector
			columnHeaders: nil
			name: nil] autorelease];
}

+ (id) matrixFromGSLMatrix: (gsl_matrix*) aMatrix
{
	return [[[AdDataMatrix alloc] 
			initWithGSLMatrix: aMatrix
			columnHeaders: nil
			name: nil] autorelease];
}

+ (id) matrixFromADMatrix: (AdMatrix*) aMatrix
{
	return [[[AdDataMatrix alloc] 
			initWithADMatrix: aMatrix
			columnHeaders: nil
			name: nil] autorelease];
}

+ (id) matrixFromStringRepresentation: (NSString*) aString
{
	return [[[AdDataMatrix alloc]
			initWithStringRepresentation: aString]
			autorelease];
}

//Initialisation

- (NSArray*) _trimAndRemoveEmptyStrings: (NSArray*) array
{
	NSArray *editedArray;
	NSMutableArray *trimmedArray;
	NSString *element;
	NSEnumerator* arrayEnum;

	//Trim the strings
	trimmedArray = [NSMutableArray array];
	arrayEnum = [array objectEnumerator];
	while((element = [arrayEnum nextObject]))
	{
		[trimmedArray addObject:
			[element stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceCharacterSet]]];

	}

	//In case the last element in the row was followed by a ","
	//This will have created an empty last object
	if([[trimmedArray lastObject] isEqual: @""])
	{
		editedArray = [trimmedArray subarrayWithRange: 
				NSMakeRange(0, [trimmedArray count] - 1)];
	}
	else
		editedArray = trimmedArray;

	return editedArray;
}

- (id) initWithStringRepresentation: (NSString*) aString 
{
	return [self initWithStringRepresentation: aString name: nil];
}

- (id) initWithStringRepresentation: (NSString*) aString name: (NSString*) nameString
{
	NSArray *row, *headers;
	NSMutableArray *rows, *array;
	NSString* string;
	NSEnumerator* arrayEnum;

	rows = [NSMutableArray array];
	array = [[[aString componentsSeparatedByString: @"\n"]
			mutableCopy] autorelease];
	headers = [[array objectAtIndex: 0]
			componentsSeparatedByString: @","];
	headers = [self _trimAndRemoveEmptyStrings: headers];		
	[array removeObjectAtIndex: 0];

	arrayEnum = [array objectEnumerator];
	while((string = [arrayEnum nextObject]))
	{
		row = [self _trimAndRemoveEmptyStrings: 
			[string componentsSeparatedByString: @","]];
		//If the row is empty dont add it
		//This will happen with incorrect string representations
		//but also if the last line containing numbers ended in "\n"
		if([row count] != 0)
			[rows addObject: row];
	}

	return [self initWithRows: rows 
		columnHeaders: headers 
		name: nameString];
}

- (id) initWithGSLVector: (gsl_vector*)  aVector
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString
{
	int i, j;
	NSMutableArray* array;

	array = [NSMutableArray new];
	for(i=0; i<(int)aVector->size; i++)
		for(j=0; j<1; j++)
			[array addObject: 
				[NSArray arrayWithObject:
					[NSNumber numberWithDouble: gsl_vector_get(aVector, i)]]];

	[self initWithRows: array
		columnHeaders: anArray
		name: aString];

	[array release];

	return self;
}

- (id) initWithGSLMatrix: (gsl_matrix*) aMatrix 
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString
{
	int i, j;
	NSMutableArray* array, *row;

	array = [NSMutableArray new];
	for(i=0; i<(int)aMatrix->size1; i++)
	{
		row = [NSMutableArray array];
		for(j=0; j<(int)aMatrix->size2; j++)
		{
			[row addObject: [NSNumber 
				numberWithDouble: gsl_matrix_get(aMatrix, i, j)]];
		}
		[array addObject: row];
	}	

	[self initWithRows: array
		columnHeaders: anArray
		name: aString];

	[array release];

	return self;
}

- (id) initWithADMatrix: (AdMatrix*) aMatrix 
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString
{
	int i, j;
	NSMutableArray* array, *row;

	array = [NSMutableArray new];
	for(i=0; i<aMatrix->no_rows; i++)
	{
		row = [NSMutableArray array];
		for(j=0; j<aMatrix->no_columns; j++)
		{
			[row addObject: [NSNumber 
				numberWithDouble: aMatrix->matrix[i][j]]];
		}
		[array addObject: row];
	}	

	[self initWithRows: array
		columnHeaders: anArray
		name: aString];

	[array release];

	return self;
}

- (id) initWithDataMatrix: (AdDataMatrix*) dataMatrix
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString
{	
	NSMutableArray* rows;
	NSEnumerator *rowEnum;
	id row;

	rows = [NSMutableArray new];
	rowEnum = [dataMatrix rowEnumerator];
	while((row = [rowEnum nextObject]))
		[rows addObject: row];
	
	if(anArray == nil && dataMatrix != nil)
		anArray = [dataMatrix columnHeaders];
	
	if(aString == nil && dataMatrix != nil)
		aString = [dataMatrix name];

	[self initWithRows: rows
		columnHeaders: anArray
		name: aString];
	
	[rows release];
	
	return self;
}

- (id) initWithRows: (NSArray*) rows
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString
{
	int i;
	NSEnumerator *rowEnum;
	NSArray *row, *firstRow;
	NSMutableArray* convertedRow;
	id element;

	if((self = [super init]))
	{
		numberOfColumns = 0;
		numberOfRows = 0;
		matrix = [NSMutableArray new];
		columnHeaders = [NSMutableArray new];
		columnDataTypes = [NSMutableArray new];
		
		if(rows != nil && ([rows count] > 0))
		{
			numberOfRows = [rows count];
			firstRow = [rows objectAtIndex: 0];
			if(![firstRow isKindOfClass: [NSArray class]])
			{
				[self release];
				[NSException raise: NSInvalidArgumentException
					format: @"The first element in rows is not an array"];
			}		
			else
				numberOfColumns = [[rows objectAtIndex: 0] count];

			//Set the column data types.
			[self setDataTypesToTypesInArray: firstRow];

			//Go through all the rows and converting the
			//elements and adding them to the matrix
			rowEnum = [rows objectEnumerator];
			while((row = [rowEnum nextObject]))
			{	
				//Check all rows have the same number of elements
				if([row count] == numberOfColumns)
				{
					convertedRow = [NSMutableArray array];
					for(i=0; i<(int)[row count]; i++)
					{
						element = [self representationOfObject:
									[row objectAtIndex: i]
								forColumn: i];
						[convertedRow addObject: element];
					}	
					[matrix addObject: convertedRow];
				}	
				else
				{
					[self release];
					[NSException raise: NSInvalidArgumentException
						format: @"The supplied rows must all have the same length"];
				}
			}	
		}	

		//Use the user supplied name if any.
		if(aString == nil)
			name = [@"None" retain];
		else	
			name = [aString copy];
			
		//Check headers
		if(anArray != nil)
		{
			//If no rows exist numberOfColumns wont have been set yet.
			if(rows == nil || ([rows count] == 0))
				numberOfColumns = [anArray count];
				
			if([anArray count] != numberOfColumns)
			{
				[self release];
				[NSException raise: NSInvalidArgumentException
					format: @"Number of headers %@ does not match number of columns %d",
					[anArray count], numberOfColumns];
			}
			else
				[columnHeaders addObjectsFromArray: anArray];
				
		}
		else
		{
			for(i=0; i<(int)numberOfColumns; i++)
				[columnHeaders addObject: 
					[NSString stringWithFormat: @"Column %d", i]];
		}			
	}

	return self;
}

- (id) initWithRows: (NSArray*) rows
	name: (NSString*) aString
{
	return [self initWithRows: rows
		columnHeaders: nil
		name: aString];
}

- (id) initWithRows: (NSArray*) rows
	columnHeaders: (NSArray*) anArray
{
	return [self initWithRows: rows
		columnHeaders: anArray
		name: nil];
}

- (id) initWithRows: (NSArray*) rows
{
	return [self initWithRows: rows
		columnHeaders: nil
		name: nil];
}

- (id) init
{
	return [self initWithRows: nil];
}

- (void) dealloc
{
	[matrix release];
	[columnDataTypes release];
	[columnHeaders release];
	[name release];
	[super dealloc];
}

- (id) valueForKey: (NSString*) key
{
	int index;
	id value;
	
	NSDebugLLog(@"AdDataMatrix", @"Request for key %@", key);
	NSDebugLLog(@"AdDataMatrix", @"Receiver class - %@", [self class]);
	
	//Check if its a request for a column
	index = [self indexOfColumnWithHeader: key];
	if(index != NSNotFound)
	{
		value = [self column: index];
	}
	else
	{
		value = [super valueForKey: key];
	}
	
	return [[value retain] autorelease];
}

- (NSString*) stringRepresentation
{
	NSMutableString* string = [NSMutableString string];
	NSEnumerator* headerEnum, *rowEnum, *valueEnum;
	id header, row, value;

	headerEnum = [columnHeaders objectEnumerator];
	while((header = [headerEnum nextObject]))
		[string appendFormat: @"%@, ", header];
	
	[string appendString: @"\n"];
	
	//Simplify by using componentsJoinedByString.
	rowEnum = [self rowEnumerator];
	while((row = [rowEnum nextObject]))
	{
		valueEnum = [row objectEnumerator];
		while((value = [valueEnum nextObject]))
			[string appendFormat: @"%@, ", value];
		[string appendString: @"\n"];
	}	

	return [[string copy] autorelease];
}

- (NSString*) description
{
	unsigned int width;
	NSMutableString* string = [NSMutableString string];
	NSEnumerator* headerEnum;
	id header;

	width = 0;
	headerEnum = [columnHeaders objectEnumerator];
	while((header = [headerEnum nextObject]))
		if(width < [header length])
			width = [header length];

	[string appendFormat: @"%@ - ", name];
	[string appendFormat: @"Dimensions - %d x %d\n", 
		numberOfRows, numberOfColumns];

	return string;
}

- (BOOL) compareCRepresentations: (AdDataMatrix*) aMatrix
{
	BOOL retval = NO;
	AdMatrix* matrixOne, *matrixTwo;
	
	matrixOne = [self cRepresentation];
	matrixTwo = [aMatrix cRepresentation];
	
	//The function returns C99 type bool
	if(AdCompareDoubleMatrices(matrixOne, matrixTwo, 1E-12) == true)
	{
		retval = YES;
	}
	
	[[AdMemoryManager appMemoryManager] freeMatrix: matrixOne];
	[[AdMemoryManager appMemoryManager] freeMatrix: matrixTwo];
	
	return retval;
}

/*
 * Accessing Elements
*/

- (id) elementAtRow: (unsigned int) rowIndex
	 column: (unsigned int) columnIndex;
{
	return [[matrix objectAtIndex: rowIndex] objectAtIndex: columnIndex];
}

- (id) elementAtRow: (unsigned int) row 
	ofColumnWithHeader: (NSString*) columnHeader 
{
	int columnIndex;

	if((columnIndex = [columnHeaders indexOfObject: columnHeader]) == NSNotFound)
		[NSException raise: NSInvalidArgumentException
			format: @"Column header %@ does not exist", columnHeader];
	
	return	[self elementAtRow: row
			column: columnIndex];
}

- (NSArray*) matrixRows
{
	NSWarnLog(@"This method is deprecated - use row: or rowEnumerator instead");
	return matrix;
}

- (NSArray*) column: (unsigned int) columnIndex
{
	NSMutableArray* columnCopy = [NSMutableArray array];

	[self addColumn: columnIndex toArray: columnCopy];
	return [[columnCopy copy] autorelease];
}

- (NSArray*) columnWithHeader: (NSString*) columnHeader
{
	int columnIndex;

	if((columnIndex = [columnHeaders indexOfObject: columnHeader]) == NSNotFound)
		[NSException raise: NSInvalidArgumentException
			format: @"Column header %@ does not exist", columnHeader];
	
	return [self column: columnIndex];
}

- (NSArray*) row: (unsigned int) rowIndex
{
	if(rowIndex >= numberOfRows)
		[NSException raise: NSInvalidArgumentException
			format: @" Row %d does not exist", rowIndex];

	return [NSArray arrayWithArray:
		[matrix objectAtIndex: rowIndex]]; 
}

- (void) addRow: (unsigned int) rowIndex toArray: (NSMutableArray*) anArray
{
	if(rowIndex >= numberOfRows)
		[NSException raise: NSInvalidArgumentException
			format: @" Row %d does not exist", rowIndex];
	
	[anArray addObjectsFromArray: 
		[matrix objectAtIndex: rowIndex]];
}

- (void) addColumn: (unsigned int) columnIndex toArray: (NSMutableArray*) anArray
{
	int i;
	id object;

	if(columnIndex >= numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @" Column %d does not exist", columnIndex];

	for(i = 0; i<(int)numberOfRows; i++)
	{
		object = [[matrix objectAtIndex: i] objectAtIndex: columnIndex]; 
		[anArray addObject: object];
	}	
}

- (void) addColumnWithHeader: (NSString*) columnHeader
		toArray: (NSMutableArray*) anArray
{
	int columnIndex;

	if((columnIndex = [columnHeaders indexOfObject: columnHeader]) == NSNotFound)
		[NSException raise: NSInvalidArgumentException
			format: @"Column header %@ does not exist", columnHeader];
	
	[self addColumn: columnIndex toArray: anArray];
}

- (NSEnumerator*) rowEnumerator
{
	return [matrix objectEnumerator];
}

/*
 * C Representations
 */

- (AdMatrix*) cRepresentation
{
	int i,j;
	AdMatrix* cMatrix;
	
	cMatrix = [[AdMemoryManager appMemoryManager]
			allocateMatrixWithRows: numberOfRows
			withColumns: numberOfColumns];

	for(i=0;i<(int)numberOfRows; i++)
		for(j=0; j<(int)numberOfColumns; j++)
			cMatrix->matrix[i][j] = [[self elementAtRow: i
						column: j] doubleValue];

	return cMatrix;					
}

- (void) cRepresentationUsingBuffer: (AdMatrix*) aMatrix
{
	int i,j;
	
	if(aMatrix->no_rows != (int)numberOfRows)
		[NSException raise: NSInvalidArgumentException
			format: @"Provided buffer has incorrect number of rows - required %d, provided %d",
			aMatrix->no_rows,
			numberOfRows];
	
	if(aMatrix->no_columns != (int)numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @"Provided buffer has incorrect number of columns - required %d, provided %d",
			aMatrix->no_columns,
			numberOfColumns];

	for(i=0;i<(int)numberOfRows; i++)
		for(j=0; j<(int)numberOfColumns; j++)
			aMatrix->matrix[i][j] = [[self elementAtRow: i
						column: j] doubleValue];
}

/*
 * Setters and Getters
 */

- (unsigned int) numberOfRows
{
	return numberOfRows;
}

- (unsigned int) numberOfColumns
{
	return numberOfColumns;
}

- (NSArray*) columnHeaders
{
	return [[columnHeaders copy] autorelease];
}

- (id) headerForColumn: (unsigned int) index
{
	return [columnHeaders objectAtIndex: index];
}

- (unsigned int) indexOfColumnWithHeader: (NSString*) header
{
	return [columnHeaders indexOfObject: header];
}

- (NSArray*) columnDataTypes
{
	return [[columnDataTypes copy] autorelease];
}

- (NSString*) dataTypeForColumn: (unsigned int) columnIndex
{
	if(columnIndex >= numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @"Column %d does not exist", columnIndex];
	
	return [columnDataTypes objectAtIndex: columnIndex];
}

- (NSString*) dataTypeForColumnWithHeader: (NSString*) columnHeader
{
	int columnIndex;

	if((columnIndex = [columnHeaders indexOfObject: columnHeader]) == NSNotFound)
		[NSException raise: NSInvalidArgumentException
			format: @"Column header %@ does not exist", columnHeader];

	return [columnDataTypes objectAtIndex: columnIndex];
}

- (NSString*) name
{
	return name;
}

/*
 * Printing the Matrix
 */

- (void) printMatrix
{
	unsigned int i;

	for(i=0; i<numberOfRows; i++)
		NSLog(@"%@\n", [[matrix objectAtIndex: i] componentsJoinedByString: @" "]);
}		

- (BOOL) writeMatrixToFile: (NSString*) filename
{
	int i;
	FILE* file_p;

	file_p = fopen([filename cString], "w");
	
	if(file_p == NULL)
		return NO;

	if(columnHeaders != nil)
		GSPrintf(file_p, @"%@\n", 
			[columnHeaders componentsJoinedByString: @" "]);

	for(i=0;i<(int)numberOfRows; i++)
		GSPrintf(file_p, @"%@\n", 
			[[matrix objectAtIndex: i] 
			componentsJoinedByString: @" "]);

	fclose(file_p);

	return YES;
}

/*
 * Searching the matrix
 */

/**
Returns an NSIndexSet containing the indexes of rows containing \e element
*/
- (NSIndexSet*) indexesOfRowsContainingElement: (id) element
{	
	int i;
	NSArray* row;
	NSIndexSet* setCopy;
	NSMutableIndexSet* indexSet = [NSMutableIndexSet new];
	
	for(i=0; i<(int)numberOfRows; i++)
	{
		row = [matrix objectAtIndex: i];
		if([row containsObject: element])
			[indexSet addIndex: i];
	}		

	setCopy = [[indexSet copy] autorelease];	
	[indexSet release];

	return setCopy;
}

/**
Returns an NSIndexSet containing the indexes of rows that match \e array.
A match is found if the array contains the same number of objects as the
row and objects at a given index in each array satisfy the isEqual: test.
*/
- (NSIndexSet*) indexesOfRowsMatchingArray: (NSArray*) anArray
{
	int i;
	NSArray* row;
	NSIndexSet* setCopy;
	NSMutableIndexSet* indexSet = [NSMutableIndexSet new];
	
	//Only search if anArray is the correct size
	if([anArray count] == numberOfColumns)
	{
		for(i=0; i<(int)numberOfRows; i++)
		{
			row = [matrix objectAtIndex: i];
			if([row isEqualToArray: anArray])
				[indexSet addIndex: i];
		}
	}	

	setCopy = [[indexSet copy] autorelease];	
	[indexSet release];

	return setCopy;
}

/*
 * Deriving new matrices
 */

/**
Returns a new AdDataMatrix instance containing only the rows
specified by the indexes in \e indexSet. 
The submatrix has the same headers and name as the receiver.
If any index in \e indexSet exceeds the range of rows in the reciever
an NSRangeException is raised.
*/
- (AdDataMatrix*) submatrixFromRowSelection: (NSIndexSet*) indexSet
{
	int index, i;
	unsigned int* buffer;
	NSMutableArray* rows = [NSMutableArray new];
	AdDataMatrix* submatrix;

	//Check for range problems
	index = [indexSet lastIndex];

	if(index != NSNotFound)
	{
		if(index >= (int)numberOfRows)
			[NSException raise: NSRangeException
				format: @"Index %d is out of row range (%d)", 
				index,
				numberOfRows - 1];
		
		//Dont use subarrayFromElementSelection: since that
		//will return an array containing the actual NSMutableArrays
		//used by the object.
		buffer = (unsigned int*)malloc([indexSet count]*sizeof(unsigned int));
		[indexSet getIndexes: buffer 
			    maxCount: [indexSet count]
			inIndexRange: NULL];
		for(i=0; i<(int)[indexSet count]; i++)
			[rows addObject: 
				[self row: buffer[i]]];
		
		free(buffer); 
	}	

	submatrix = [[AdDataMatrix alloc] 
			initWithRows: rows
			columnHeaders: [self columnHeaders]
			name: [self name]];
	[rows release];
	return [submatrix autorelease];
}

/**
Returns a new AdDataMatrix instance containing only the columns
specified by the indexes in \e indexSet.
The column headers are also copied and the returned matrix has the same
name as the receiver.
If any index in \e indexSet is exceeds the range of columns in the receiver
an NSRangeException is raised.
*/
- (AdDataMatrix*) submatrixFromColumnSelection: (NSIndexSet*) indexSet
{
	int index;
	id row;
	NSArray* array;
	NSMutableArray* rows = [NSMutableArray new];
	NSEnumerator* rowEnumerator;
	AdDataMatrix* submatrix;

	//Check for range problems
	index = [indexSet lastIndex];

	if(index != NSNotFound)
	{
		if(index >= (int)numberOfColumns)
			[NSException raise: NSRangeException
				format: @"Index %d is out of column range (%d)", 
				index,
				numberOfColumns - 1];

		rowEnumerator = [self rowEnumerator];
		while((row = [rowEnumerator nextObject]))
		{
			array = [row subarrayFromElementSelection: indexSet];
			[rows addObject: array];
		}
	}	

	array = [[self columnHeaders] 
			subarrayFromElementSelection: indexSet];
	submatrix = [[AdDataMatrix alloc] 
			initWithRows: rows
			columnHeaders: array
			name: [self name]];
	
	[rows release];
	return [submatrix autorelease];
}

/**
Returns a new AdDataMatrix instance containing only the rows in \e range
The submatrix has the same headers and name as the receiver.
If \e range exceeds the range of rows in the matrix an NSRangeException
is raised.
*/
- (AdDataMatrix*) submatrixWithRowRange: (NSRange) range
{
	return [self submatrixFromRowSelection:
		[NSIndexSet indexSetWithIndexesInRange: range]];
}

/**
Returns a new AdDataMatrix instance containing data from the columns in \e range
The column headers are also copied and the returned matrix has the same
name as the receiver.
If \e range exceeds the range of columns in the matrix an NSRangeException
is raised.
*/
- (AdDataMatrix*) submatrixWithColumnRange: (NSRange) range
{
	return [self submatrixFromColumnSelection:
		[NSIndexSet indexSetWithIndexesInRange: range]];
}

/*
 * NSCoding Methods
 */

//decoder for pre 0.7 version objects
- (id) _initWithCoderPre0_7: (NSCoder*) decoder
{
	int i,j;
	int matrixElements;
	int count;
	unsigned int length; 
	double *matrixStore;
	NSMutableArray* matrixRow;
	NSNumber *element;

	NSLog(@"Decoding pre0.7 data matrix");

	if([decoder allowsKeyedCoding])
	{
		matrix = [NSMutableArray new];
		numberOfRows = [decoder decodeIntForKey: @"Rows"];
		numberOfColumns = [decoder decodeIntForKey: @"Columns"];
		matrixStore = (double*)[decoder decodeBytesForKey: @"Matrix"
					returnedLength: &length];
		matrixElements = length/sizeof(double);
		for(i=0, count=0; i<(int)numberOfRows; i++)
		{
			matrixRow = [NSMutableArray arrayWithCapacity: 1];
			for(j=0; j<(int)numberOfColumns; j++)
			{
				element = [NSNumber numberWithDouble: matrixStore[count]];
				[matrixRow addObject: element];
				count++;
			}
			[matrix addObject: matrixRow];
		}

		columnHeaders = [decoder decodeObjectForKey: @"ColumnHeaders"];
		[columnHeaders retain];
		name = [decoder decodeObjectForKey: @"Name"];
		[name retain];
	}
	else
	{	
		//We only retain keyed decoding support.
		//Non keyed coding/decoding is only used for DO and 
		//every object sent by DO will be of the new version.
		//i.e. it will either be of 0.7+ version or decoded from
		//the database using keyed coding and updated to the 0.7 version.

		NSWarnLog(@"Non keyed decoding of pre 0.7 version AdDataMatrices not supported");
	}

	/*** update to new version ****/
	NSLog(@"Decoding pre0.7 data matrix");

	//check column headers actually exists
	if(columnHeaders == nil)
	{
		columnHeaders = [NSMutableArray new];
		for(i=0; i< (int)numberOfColumns; i++)
			[columnHeaders addObject: 
				[NSString stringWithFormat: @"Column %d", i]];
	}			

	//all columns in pre 0.7 versions are doubles when unarchived.
	columnDataTypes = [NSMutableArray new];
	for(i=0; i< (int)numberOfColumns; i++)
		[columnDataTypes addObject: @"double"];
	
	NSLog(@"Decoding pre0.7 data matrix");

	return self;
}

//Decoding - We Encode and decode strings as Unicode

- (NSArray*) _decodeNumericColumnOfType: (NSString*) dataType
	numberOfElements: (int) numberOfElements
	fromData: (NSData*) data
	start: (int) start
	end: (int*) end
	byteSwapFlag: (int) byteSwapFlag
{
	int i, step, intNumber;
	double doubleNumber;
	NSRange range;
	void *buffer;
	NSMutableArray* column = [NSMutableArray array];

	step = intNumber = 0;
	doubleNumber = 0.0;
	if([dataType isEqual: @"int"])
		step = sizeof(int);
	else if([dataType isEqual: @"double"])
		step = sizeof(double);
	else	
		[NSException raise: NSInvalidArgumentException
			format: @"Encountered unknown numeric data type %@ when coding.", 
			dataType];

	*end = start + numberOfElements*step;
	buffer = malloc(step);
	for(i=start; i< *end; i=i+step)
	{
		range = NSMakeRange(i, step);
		[data getBytes: buffer range: range];
		
		if([dataType isEqual: @"int"])
		{
			if(byteSwapFlag  == AdNoSwap)
				intNumber = *(int*)buffer;
			else if(byteSwapFlag == AdSwapBytesToBig)
				intNumber = NSSwapLittleIntToHost(*(int*)buffer);
			else if(byteSwapFlag == AdSwapBytesToLittle)
				intNumber = NSSwapBigIntToHost(*(int*)buffer);

			[column addObject:
				[NSNumber numberWithInt: intNumber]];
		}		
		else if([dataType isEqual: @"double"])
		{
			if(byteSwapFlag == AdNoSwap)
				doubleNumber = *(double*)buffer;
			else if(byteSwapFlag == AdSwapBytesToBig)
			{
				doubleNumber = NSSwapLittleDoubleToHost(*(NSSwappedDouble*)buffer);
			}
			else if(byteSwapFlag == AdSwapBytesToLittle)
				doubleNumber = NSSwapBigDoubleToHost(*(NSSwappedDouble*)buffer);

			[column addObject: 
				[NSNumber numberWithDouble: doubleNumber]];
		}	
	}

	free(buffer);
	return column;
}

- (NSArray*) _decodeStringColumnWithNumberOfElements: (int) numberOfElements
	fromData: (NSData*) data
	start: (int) start
	end: (int*) end
	byteSwapFlag: (int) byteSwapFlag
{
	int i, step, length;
	NSRange range;
	int* lengthBuffer;
	id element;
	NSData* elementData;
	NSMutableArray* column = [NSMutableArray array];

	//first extract the string lengths

	step = sizeof(int);
	*end = start + numberOfElements*step;
	lengthBuffer = malloc(numberOfElements*step);
	for(i=0; i< numberOfElements; i++)
	{
		range = NSMakeRange(start + i*step, step);
		[data getBytes: (lengthBuffer + i) range: range];
	}

	//now extract the strings
	for(i=0; i< numberOfElements; i++)
	{
		length = 0;
		if(byteSwapFlag == AdNoSwap)
			length = lengthBuffer[i];
		if(byteSwapFlag == AdSwapBytesToBig)
			length = NSSwapLittleIntToHost(lengthBuffer[i]);
		else if(byteSwapFlag == AdSwapBytesToLittle)
			length = NSSwapBigIntToHost(lengthBuffer[i]);

		start = *end;
		*end += length;
		range = NSMakeRange(start, length);
		
		//We dont have to swap chars since they
		//are only one byte long.
		elementData = [data subdataWithRange: range];
		element = [[NSString alloc]
				initWithData: elementData
				encoding: NSUTF8StringEncoding];
		[element autorelease];
		[column addObject: element];
	}

	free(lengthBuffer);
	return column;
}

//recreates the matrix from the archived data 
- (void) _extractMatrixFromNumericData: (NSData*) numericData
	stringData: (NSData*) stringData
	byteSwapFlag: (int) byteSwapFlag
{	
	int numericStart, numericEnd, i;
	int stringStart, stringEnd;
	NSEnumerator* columnDataTypesEnum;
	NSString *columnDataType;
	NSArray* column;
	
	//create the matrix
	matrix = [NSMutableArray new];
	for(i=0; i<(int)numberOfRows; i++)
		[matrix addObject: [NSMutableArray array]];

	numericStart = stringStart = 0;
	columnDataTypesEnum = [columnDataTypes objectEnumerator];
	while((columnDataType = [columnDataTypesEnum nextObject]))
	{
		if([columnDataType isEqual: @"string"])
		{
			column = [self _decodeStringColumnWithNumberOfElements: numberOfRows
					fromData: stringData
					start: stringStart
					end: &stringEnd
					byteSwapFlag: byteSwapFlag];
			stringStart = stringEnd;
		}
		else
		{
			column = [self _decodeNumericColumnOfType: columnDataType
					numberOfElements: numberOfRows
					fromData: numericData
					start: numericStart
					end: &numericEnd
					byteSwapFlag: byteSwapFlag];
			numericStart = numericEnd;
		}

		for(i=0; i<(int)numberOfRows; i++)
			[[matrix objectAtIndex: i]
				addObject: [column objectAtIndex: i]];
	}
}

/*
 * Endianness -
 * AdDataMatrix handles endianness issues in the following manner.
 *
 * Endianness is not taken into account during encoding.
 * i.e. encoding is done using the endianness of the encoding machine
 * However the endianness of the machine is encoded.
 *
 * On decoding the endianness of the decoding machine and the 
 * endianness of the archive are compared.
 *
 * If they are the same byteSwapFlag is set to AdNoSwap.
 *
 * If the host is big-endian and the archive little-endian
 * byteSwapFlag is set to AdSwapBytesToBig
 *
 * If the host is little-endian and the archive big-endian
 * byteSwapFlag is set to AdSwapBytesToLittle
 */

- (id) initWithCoder: (NSCoder*) decoder
{	
	unsigned int length, encodedByteOrder;
	void *bytes;
	NSData* numericData, *stringData;
	AdByteSwapFlag byteSwapFlag;

	if([decoder allowsKeyedCoding])
	{
		//check archive version
		if([decoder decodeObjectForKey: @"ClassVersion"] == nil)
			return [self _initWithCoderPre0_7: decoder];

		encodedByteOrder = [decoder decodeIntForKey: @"EncodedByteOrder"];
		NSDebugLLog(@"AdDataMatrix",
			@"Encoded byte order %d. Host byte order %d", encodedByteOrder, NSHostByteOrder());
		if(encodedByteOrder != NSHostByteOrder())
		{
			//This machine is a different endianess to
			//the one the object was encoded on. 
			//We have to swap the bits.
			if(encodedByteOrder == NS_LittleEndian)
				byteSwapFlag = AdSwapBytesToBig;
			else if(encodedByteOrder == NS_BigEndian)
				byteSwapFlag = AdSwapBytesToLittle;
			else
			{
				/*
				 * The encoded byte order is unknown
				 * Two possible causes :
				 * 1) This is an old archive and the byte order wasnt encoded 
				 * 2) The byte order of the encoding machine was not known.
				 * In either case we issue a warning and default to no swapping.
				 */

				NSWarnLog(@"Encoded byte order unknown - defaulting to no swapping");
				byteSwapFlag = AdNoSwap;
			}
		}
		else
		 	byteSwapFlag = AdNoSwap;
		
		NSDebugLLog(@"AdDataMatrix", @"Byte swap flag %d", byteSwapFlag);
		
		numberOfRows = [decoder decodeIntForKey: @"Rows"];
		numberOfColumns = [decoder decodeIntForKey: @"Columns"];
		columnDataTypes = [decoder decodeObjectForKey: @"ColumnDataTypes"];
		[columnDataTypes retain];
		columnHeaders = [decoder decodeObjectForKey: @"ColumnHeaders"];
		[columnHeaders retain];
		name = [decoder decodeObjectForKey: @"Name"];
		[name retain];
		NSDebugLLog(@"AdDataMatrix", @"Name: %@. Rows %d. Columns %d. Column Names %@",
			name, numberOfRows, numberOfColumns, columnHeaders);
		bytes = (void*)[decoder decodeBytesForKey: @"NumericColumns"
				returnedLength: &length];
		numericData = [NSData dataWithBytesNoCopy: bytes 
				length: length
				freeWhenDone: NO];
		NSDebugLLog(@"AdDataMatrix", @"Numeric Data - %d bytes", length);		
		bytes = (void*)[decoder decodeBytesForKey: @"StringColumns"
				returnedLength: &length];
		stringData = [NSData dataWithBytesNoCopy: bytes 
				length: length
				freeWhenDone: NO];
		NSDebugLLog(@"AdDataMatrix", @"String Data - %d bytes", length);		

		[self _extractMatrixFromNumericData: numericData
			stringData: stringData
			byteSwapFlag: byteSwapFlag];
	}
	else
	{	
		numberOfRows = [[decoder decodeObject] intValue];
		numberOfColumns = [[decoder decodeObject] intValue];
		columnHeaders = [[decoder decodeObject] retain];
		name = [[decoder decodeObject] retain];
		columnDataTypes = [[decoder decodeObject] retain];

		encodedByteOrder = [[decoder decodeObject] intValue];
		if(encodedByteOrder != NSHostByteOrder())
		{
			if(encodedByteOrder == NS_LittleEndian)
				byteSwapFlag = AdSwapBytesToBig;
			else
				byteSwapFlag = AdSwapBytesToLittle;
		}
		else
		 	byteSwapFlag = AdNoSwap;

		bytes = (void*)[decoder decodeBytesWithReturnedLength: &length];
		numericData = [NSData dataWithBytesNoCopy: bytes 
				length: length
				freeWhenDone: NO];
		bytes = (void*)[decoder decodeBytesWithReturnedLength: &length];
		stringData = [NSData dataWithBytesNoCopy: bytes 
				length: length
				freeWhenDone: NO];
		
		[self _extractMatrixFromNumericData: numericData
			stringData: stringData
			byteSwapFlag: byteSwapFlag];
	}

	return self;
}

//Encoding

- (void) _addNumericColumn: (NSArray*) column
	ofType: (NSString*) dataType
	toData: (NSMutableData*) data
{
	int intValue;
	double doubleValue;
	NSEnumerator *columnEnum;
	id element;

	if([dataType isEqual: @"double"])
	{
		columnEnum = [column objectEnumerator];
		while((element = [columnEnum nextObject]))
		{
			doubleValue = [element doubleValue];
			[data appendBytes: (const void*)&doubleValue
				   length: sizeof(double)];	
		}
		
	}	
	else if([dataType isEqual: @"int"])
	{
		columnEnum = [column objectEnumerator];
		while((element = [columnEnum nextObject]))
		{
			intValue = [element intValue];
			[data appendBytes: (const void*)&intValue
				   length: sizeof(int)];	
		}		
	}	
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Encountered unknown numeric data type %@ when coding.", 
			dataType];
}

- (NSData*) _encodeNumericColumnsAsData
{
	int i;
	NSMutableData* data;
	NSArray* column;
	
	data = [NSMutableData dataWithLength:0];
	//Only encode if theres something to encode
	if([columnDataTypes count] != 0)
		for(i=0; i<(int)numberOfColumns; i++)
		{
			column = [self column: i];
			if(![[columnDataTypes objectAtIndex: i] isEqual: @"string"])
				[self _addNumericColumn: column 
					ofType: [columnDataTypes objectAtIndex: i]
					toData: data];
		}
	
	return data;
}

- (NSData*) _encodeStringColumnsAsData
{
	int i, j;
	id element;
	NSMutableData* data;
	int* lengthBuffer;
	NSArray* column;

	lengthBuffer = malloc(numberOfRows*sizeof(int));
	data = [NSMutableData dataWithLength:0];
	//Only encode if theres something to encode
	if([columnDataTypes count] != 0)
	{
		for(i=0; i<(int)numberOfColumns; i++)
		{
			column = [self column: i];
			if([[columnDataTypes objectAtIndex: i] isEqual: @"string"])
			{
				//Go through once and add an array with the lengths of all
				//the strings
				for(j=0; j<(int)[column count]; j++)
				{
					element = [column objectAtIndex: j];
					lengthBuffer[j] = [element lengthOfBytesUsingEncoding: 
								NSUTF8StringEncoding];
					//lengthBuffer[j] += 1;			
				}		
				[data appendBytes: lengthBuffer 
					length: numberOfRows*sizeof(int)];
				
				//Now add the strings
				for(j=0; j<(int)[column count]; j++)
				{
					element = [column objectAtIndex: j];
					[data appendData: 
						[element dataUsingEncoding: NSUTF8StringEncoding]];
				}		
			}
		}
	}	
	
	free(lengthBuffer);
	return data;

}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	NSData* data;

	if([encoder allowsKeyedCoding])
	{
		[encoder encodeInt: numberOfRows forKey: @"Rows"];
		[encoder encodeInt: numberOfColumns forKey: @"Columns"];
		[encoder encodeObject: columnHeaders forKey: @"ColumnHeaders"];
		[encoder encodeObject: name forKey: @"Name"];
		[encoder encodeObject: columnDataTypes forKey: @"ColumnDataTypes"];
		[encoder encodeInt: NSHostByteOrder() forKey: @"EncodedByteOrder"];
		
		NSDebugLLog(@"AdDataMatrix", @"Encoding: %@. Rows %d. Columns %d. Column Names %@",
			name, numberOfRows, numberOfColumns, columnHeaders);
		data = [self _encodeNumericColumnsAsData];
		NSDebugLLog(@"AdDataMatrix", 
			@"Encoding %d bytes of numeric data", [data length]);
		[encoder encodeBytes: [data bytes] 
			length: [data length]
			forKey: @"NumericColumns"];

		data = [self _encodeStringColumnsAsData];
		NSDebugLLog(@"AdDataMatrix",
			@"Encoding %d bytes of string data", [data length]);
		[encoder encodeBytes: [data bytes] 
			length: [data length]
			forKey: @"StringColumns"];
				
		//Encode the lengths of all string columns

		[encoder encodeObject: [NSNumber numberWithDouble: 0.7]
			forKey: @"ClassVersion"];
	}
	else
	{
		[encoder encodeObject: [NSNumber numberWithInt: numberOfRows]];
		[encoder encodeObject: [NSNumber numberWithInt: numberOfColumns]];
		[encoder encodeObject: columnHeaders];
		[encoder encodeObject: name];
		[encoder encodeObject: columnDataTypes];
		[encoder encodeObject: [NSNumber numberWithInt: NSHostByteOrder()]];

		data = [self _encodeNumericColumnsAsData];
		[encoder encodeBytes: (uint8_t*)[data bytes]
			length: [data length]];
		data = [self _encodeStringColumnsAsData];
		[encoder encodeBytes: (uint8_t*)[data bytes]
			length: [data length]];
	}
}

#ifndef GNUSTEP

//See the AdModelObject implementation of this method
//for a description of why it is necessary.
//Note: Here we always return a copy of the object since
//if we dont certain methods will cause the program to crash
//e.g. cRepresentation.

- (id) replacementObjectForPortCoder: (NSPortCoder*) encoder
{
	return self;
}

#endif

/*
 * NSCopying & NSMutableCopying
 */

- (id) copyWithZone: (NSZone*) zone
{
	//If we are not AdDataMatrix alloc explicitly
	//since we must could be a mutable subclass

	if(![self isMemberOfClass: [AdDataMatrix class]])
		return [[AdDataMatrix allocWithZone: zone]
		   		initWithDataMatrix: self
				columnHeaders: [self columnHeaders]
				name: [self name]];

	if(zone == NULL || zone == NSDefaultMallocZone())
		return [self retain];
	else
		return [[AdDataMatrix allocWithZone: zone]
				initWithDataMatrix: self
				columnHeaders: [self columnHeaders]
				name: [self name]];
}

- (id) mutableCopyWithZone: (NSZone*) zone
{
	return [[AdMutableDataMatrix allocWithZone: zone]
		 initWithDataMatrix: self
		 columnHeaders: [self columnHeaders]
		 name: [self name]];
}

@end

/*
Mutable subclass of AdDataMatrix
*/

@implementation AdMutableDataMatrix

+ (id) matrixFromStringRepresentation: (NSString*) aString
{
	return [[[AdMutableDataMatrix alloc]
			initWithStringRepresentation: aString]
			autorelease];
}

+ (id) matrixFromGSLVector: (gsl_vector*) aVector
{
	return [[[AdMutableDataMatrix alloc] 
			initWithGSLVector: aVector
			columnHeaders: nil
			name: nil] autorelease];
}

+ (id) matrixFromGSLMatrix: (gsl_matrix*) aMatrix
{
	return [[[AdMutableDataMatrix alloc] 
			initWithGSLMatrix: aMatrix
			columnHeaders: nil
			name: nil] autorelease];
}

+ (id) matrixFromADMatrix: (AdMatrix*) aMatrix
{
	return [[[AdMutableDataMatrix alloc]
			initWithADMatrix: aMatrix
			columnHeaders: nil
			name: nil] autorelease];
}

/*
 * Init and dealloc
 */

- (id) initWithNumberOfColumns: (unsigned int) number 
	columnHeaders: (NSArray*) headers
	columnDataTypes: (NSArray*) dataTypes
{
	int i;
	id dataType;
	NSEnumerator *dataTypesEnum;
	
	//Calling [super init] creates
	//an empty matrix.
	if((self = [super init]))
	{
		numberOfColumns = number;

		//check headers
		if(headers == nil)
		{
			for(i=0; i<(int)numberOfColumns; i++)
				[columnHeaders addObject: 
					[NSString stringWithFormat: @"Column %d", i]];
		}
		else if([headers count] != numberOfColumns)
		{
			[self release];
			[NSException raise: NSInvalidArgumentException
				format: @"Number of headers %d does not match number of columns %d",
				[headers count], numberOfColumns];
		}
		else
			[columnHeaders addObjectsFromArray: headers];

		if(dataTypes != nil)
		{
			if([dataTypes count] != numberOfColumns)
			{
				[self release];
				[NSException raise: NSInvalidArgumentException
					format: @"Number of data types %d does not match number of columns %d",
					[dataTypes count], numberOfColumns];
			}
			else
			{
				dataTypesEnum = [dataTypes objectEnumerator];
				while((dataType = [dataTypesEnum nextObject]))
					if(![allowedDataTypes containsObject: dataType])
					{
						[self release];
						[NSException raise: NSInvalidArgumentException
							format: @"%@ is an invalid column data type",
							dataType];
					}

				[columnDataTypes addObjectsFromArray: dataTypes];
			}
		}	
	}

	return self;
}

- (id) initWithColumnsForDataTypes: (NSArray*) dataTypes
	withHeaders: (NSArray*) headers
{
	int columns;

	if(dataTypes == nil)
		columns = 0;
	else
		columns = (int)[dataTypes count];

	return [self initWithNumberOfColumns: columns
		columnHeaders: headers
		columnDataTypes: dataTypes];
}

- (id) init
{
	return [self initWithNumberOfColumns: 0 
			columnHeaders: nil
			columnDataTypes: nil];
}

- (void) dealloc
{
	[super dealloc];
}

/*
 * Setting Elements
*/

- (void) setElementAtRow: (unsigned int) rowIndex 
	column: (unsigned int) columnIndex 
	withValue: (id) value;
{
	//check element exists

	if(columnIndex >= numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @"Column %d does not exist", columnIndex];

	if(rowIndex >= numberOfRows)		
		[NSException raise: NSInvalidArgumentException
			format: @"Row %d does not exist", rowIndex];
	
	value = [self representationOfObject:  value
			forColumn: columnIndex];

	[[matrix objectAtIndex: rowIndex] replaceObjectAtIndex: columnIndex
		withObject: value];
}

- (void) setElementAtRow: (unsigned int) row 
	ofColumnWithHeader: (NSString*) columnHeader 
	withValue: (id) value;
{
	int columnIndex;

	if((columnIndex = [columnHeaders indexOfObject: columnHeader]) == NSNotFound)
		[NSException raise: NSInvalidArgumentException
			format: @"Column header %@ does not exist", columnHeader];
	
	[self setElementAtRow: row
		column: columnIndex
		withValue: value];
}

- (void) extendMatrixWithRow: (NSArray*) anArray
{
	int i;
	NSMutableArray* row;
	id element;

	//If numberOfColumns is 0 we initialise the matrix to
	//have the same number of columns as the first row added.
	if(numberOfColumns == 0)	
	{
		numberOfColumns = [anArray count];
		//create the headers
		for(i=0; i<(int)numberOfColumns; i++)
			[columnHeaders addObject: 
				[NSString stringWithFormat: @"Column %d", i]];
	}

	if([anArray count] == numberOfColumns)
	{	
		//If this is the first row we must set the data types 
		//(unless the data types were set on initialisation for a AdMutableDataMatrix)
		//Otherwise we convert anArrays elements to the correct classes.
		if((numberOfRows == 0) && ([columnDataTypes count] == 0))
		{
			[self setDataTypesToTypesInArray: anArray];
			row = [[NSMutableArray alloc] initWithArray: anArray];
		}
		else
		{
			row = [NSMutableArray new];
			for(i=0; i<(int)[anArray count]; i++)
			{
				element = [self representationOfObject:
							[anArray objectAtIndex: i]
						forColumn: i];
				[row addObject: element];
			}	
		}	
	
		[matrix addObject: row];
		[row release];
		numberOfRows++;
	}
	else 
	{
		[NSException raise: NSInvalidArgumentException
			format: @"Incorrect number of elements in array (%d, %d)",
			[anArray count], numberOfColumns];	
	}
}	

- (void) extendMatrixWithColumn: (NSArray*) anArray
{
	int i;
	NSString* initialObjectClass, *dataType;
	NSMutableArray* convertedArray;
	id element;
	Class class;

	//if there are any previous columns check that this one is
	//the right length
	if(numberOfColumns != 0 && numberOfRows != 0)
		if([anArray count] != numberOfRows)
			[NSException raise: NSInvalidArgumentException
				format: @"Incorrect number of elements in array (%d, %d)",
				[anArray count], numberOfRows];	
				
	//In the case where there are no rows but the column data types have been set
	//this method can't be used to add an extra column.
	//This is because we can't determine the data type for this column.
	if((numberOfRows == 0) && ([columnDataTypes count] != 0))
	{
		[NSException raise: NSInvalidArgumentException
			format: @"You cannot add an extra column where there are no rows and the column data types are set"];
	}

	convertedArray = [NSMutableArray array];
	if([anArray count] != 0)
	{
		//If there are elements in the array the first one sets the data type
		initialObjectClass = NSStringFromClass([[anArray objectAtIndex: 0] class]);
		
		if((class = [self allowedSuperClassForObject: [anArray objectAtIndex: 0]]) != nil)
		{
			dataType = [classToDataTypeMap objectForKey:
				    NSStringFromClass(class)];
		}
		else
		{
			dataType = [classToDataTypeMap objectForKey: initialObjectClass];
			if(dataType == nil)
				[NSException raise: NSInvalidArgumentException
					    format: @"AdDataMatrix - Cannot insert objects of class %@",
				 initialObjectClass];
		}	
	
		[columnDataTypes addObject: dataType];
	
		//Convert the rest of the array to the correct type.
		//We could add each element using extendMatrixWithRow:
		//however we want to check if all the objects in anArray are
		//convertible first.
	
		[convertedArray addObject: [anArray objectAtIndex: 0]];
		for(i=1; i<(int)[anArray count]; i++)
		{
			//Use numberOfColumns since we added an object to columnDataTypes
			//but haven't incremented numberOfColumns yet (done at end)
			element = [self representationOfObject: [anArray objectAtIndex: i]
						     forColumn: numberOfColumns];
			[convertedArray addObject: element];		
		}
	}
		
	//If there are no rows we have to create
	//one for each element we are going to add.
	if(numberOfRows == 0)
		for(i=0; i<(int)[convertedArray count]; i++)
		{		
			[matrix addObject: [NSMutableArray array]];
			numberOfRows++;
		}

	for(i=0; i<(int)numberOfRows; i++)
		[[matrix objectAtIndex: i] addObject: 
			[convertedArray objectAtIndex: i]];

	//Add new column header
	[columnHeaders addObject: 
		[NSString stringWithFormat: @"Column %d", numberOfColumns]];

	numberOfColumns++; 
}

- (void) extendMatrixWithColumnValues: (NSDictionary*) values
{
	unsigned int i, index;
	NSMutableArray *row;
	NSEnumerator* keyEnum;
	id key;

	//Create a row of zeros
	row = [NSMutableArray new];
	for(i=0; i<numberOfColumns; i++)
		[row addObject: [NSNumber numberWithDouble: 0]];
		
	//For each key in the dictionary find the index of the corresponding column.
	//Then replace the object at that index in row with the value of the key
	keyEnum = [values keyEnumerator];	
	while(key = [keyEnum nextObject])
	{		  	
		index = [self indexOfColumnWithHeader: key];
		if(index != NSNotFound)
		{
			[row replaceObjectAtIndex: index 
				withObject: [values objectForKey: key]];
		}
		else
			NSWarnLog(@"No column header matches key %@. Ignoring", key);
	}
	
	//Add the row
	[self extendMatrixWithRow: row];
	[row release];
}

- (void) extendMatrixWithMatrix: (AdDataMatrix*) extendingMatrix
{
	NSEnumerator* rowEnum;
	id row;

	rowEnum = [extendingMatrix rowEnumerator];
	while((row = [rowEnum nextObject]))
		[self extendMatrixWithRow: row];
}

/*
 * Removing Elements
 */

- (void) removeRowsWithIndexes: (NSIndexSet*) indexSet
{
	unsigned int* buffer;

	if([indexSet lastIndex] == NSNotFound)
		return;

	if([indexSet lastIndex] >= numberOfRows)
		[NSException raise: NSRangeException
			format: @"Index %d is out of row range %d",
			[indexSet lastIndex],
			numberOfRows];

	//maybe one day this will be implemented - only in Cocoa for now
	//[matrix removeObjectsWithIndexes: indexSet];

	buffer = (unsigned int*)malloc([indexSet count]*sizeof(unsigned int));
	[indexSet getIndexes: buffer 
			maxCount: [indexSet count]
			inIndexRange: NULL];
	[matrix	removeObjectsFromIndices: buffer numIndices: [indexSet count]];
	free(buffer); 

	numberOfRows = [matrix count];
}

- (void) removeRowsInRange: (NSRange) aRange
{
	if(NSMaxRange(aRange) > numberOfRows)
		[NSException raise: NSRangeException
			format: @"Range exceeds the number of rows in the receiver (%d, %d)",
			NSMaxRange(aRange), numberOfRows];

	[matrix removeObjectsInRange: aRange];
	numberOfRows = [matrix count];
}

- (void) removeRow: (unsigned int) rowIndex
{
	if(rowIndex >= numberOfRows)
		[NSException raise: NSRangeException
			format: @"Index %d is out of row range %d",
			rowIndex,
			numberOfRows];
	[matrix removeObjectAtIndex: rowIndex];
	numberOfRows = [matrix count];
}

- (void) setColumnHeaders: (NSArray*) anArray
{
	id holder;

	if([anArray count] != numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @"Incorrect number of elements in array (%d, %d)",
			[anArray count], numberOfRows];	

	if(anArray != columnHeaders)
	{
		holder = columnHeaders;
		columnHeaders = [anArray mutableCopy];
		[holder release];
	}	
}

- (void) setHeaderOfColumn: (unsigned int) columnIndex to: (NSString*) string
{
	if(columnIndex >= numberOfColumns)
		[NSException raise: NSInvalidArgumentException
			format: @"Column doesnt exist"];
			
	[columnHeaders replaceObjectAtIndex: columnIndex
		withObject: string];
}

- (void) setName: (NSString*) aString
{
	name = [aString retain];
}

@end
//For older classes
@implementation ULMatrix
@end
