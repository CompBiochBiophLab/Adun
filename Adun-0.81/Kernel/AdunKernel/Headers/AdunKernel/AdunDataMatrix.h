/*
   Project: AdunKernel

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

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

#ifndef _ADDATAMATRIX_H_
#define _ADDATAMATRIX_H_

#include <gsl/gsl_matrix.h>
#include <Foundation/Foundation.h>
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"

/**
\ingroup Inter
Contains a matrix of values. AdDataMatrix is primarily a convenient way to
represent heterogenous matrix (tabular) data as an object
to facititate transport and transparent access. It conforms to the NSCoding
protocol and allows both keyed and non-keyed coding. It also conforms to the
NSCopying and NSMutableCopying protocols.

An instance of AdDataMatrix is a immutable: you establish its entries when it's created 
and cannot modify them afterward. 
Using the AdDataMatrix subclass AdMutableDataMatrix you can add or delete entries etc.

Each column of the matrix can hold one type of data as determined
by the data type assigned to the column.
Each data type is assiociated with a class and data is stored as an object
of the appropriate class (or a subclass of that class).

The following table indicates the current data types and the corresponding
classes - Subclasses of these data types are also stored.

- string	\e NSString
- double	\e NSDoubleNumber
- int		\e NSIntNumber

For AdDataMatrix objects the column data types are set on intialisation.

\note AdDataMatrix indexes rows and columns starting with 0 i.e. the first element
is (0,0).

\note AdDataMatrix is not performanced optimised and should not be
used where heavy access is required to the matrix elements i.e. for computations
use the AdunBase library C structures or the gsl_matrix type.

\todo Internal - Examine changing internal matrix representation to optimise performance.
\todo Extra Methods - writeToFile: and initWithContentsOfFile:
\todo Add support for NSBoolNumber
*/

@interface AdDataMatrix: NSObject <NSCoding, NSCopying, NSMutableCopying>
{
	@protected
	unsigned int numberOfRows;
	unsigned int numberOfColumns;
	NSMutableArray* columnHeaders;
	NSMutableArray* columnDataTypes;
	NSString* name;
	NSMutableArray* matrix;	//!<an array of arrays
}
/**Returns an autoreleased AdDataMatrix instance initialised
with the values of \e aMatrix
\param aMatrx An ::AdMatrix struct
\return An autoreleased AdDataMatrix instance
*/
+ (id) matrixFromADMatrix: (AdMatrix*) aMatrix;
/**Returns an autoreleased AdDataMatrix instance initialised
with the values of \e aMatrix
\param aMatrx A gsl_matrix struct
\return An autoreleased AdDataMatrix instance
*/
+ (id) matrixFromGSLMatrix: (gsl_matrix*) aMatrix;
/**Returns an autoreleased AdDataMatrix instance initialised
with the values of \e aVector
\param aMatrx An gsl_vector struct
\return An autoreleased AdDataMatrix instance
*/
+ (id) matrixFromGSLVector: (gsl_vector*) aVector;
/**
Returns an autoreleasesd AdDataMatrix instance initialised with \e aString.
\e aString must be the string representation of a csv file or
a string returned by stringRepresentation(). 
Note: If it is the former case than the first line of the csv file
will become the column headers.
*/
+ (id) matrixFromStringRepresentation: (NSString*) aString;
/**
As initWithStringRepresentation:name with name set to nil
*/
- (id) initWithStringRepresentation: (NSString*) aString;
/**
Returns an AdDataMatrix instance initialised with \e aString.
\e aString must be the string representation of a csv file or
a string returned by stringRepresentation(). 
Note: If it is the former case than the first line of the csv file
will become the column headers.
*/
- (id) initWithStringRepresentation: (NSString*) aString name: (NSString*) nameString;
/**Returns an AdDataMatrix instance initialised
with the values of \e aVector
*/
- (id) initWithGSLVector: (gsl_vector*)  aVector
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString;
/**
Returns an AdDataMatrix instance initialised
with the values of \e aMatrix.
*/
- (id) initWithGSLMatrix: (gsl_matrix*) aMatrix 
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString;
/**
Returns an AdDataMatrix instance initialised
with the values of \e aMatrix.
*/
- (id) initWithADMatrix: (AdMatrix*) aMatrix 
	columnHeaders: (NSArray*) anArray
	name: (NSString*) aString;
/**
Creates a AdDataMatrix from the data in \e matrix.
If \e matrix is nil the values of \e headers and \e name resulting object will be an 
immutable AdDataMatrix containing no data with name "None".
If \e headers is nil the are headers of \e matrix are used.
\param matrix An AdDataMatrix instance. 
\param headers Array containing the headers for each column. 
\param name  A NSString specifying the name of the matrix. If nil the name defaults to .
the name of the AdDataMatrix.
\return An initialised AdDataMatrix instance.
*/
- (id) initWithDataMatrix: (AdDataMatrix*)  matrix
	columnHeaders: (NSArray*)  anArray
	name: (NSString*) aString; 
/**
Designated initialiser.
Creates an AdDataMatrix from the arrays in \e rows.
Each entry in rows must be an NSArray and contain the same number of elements.
\e headers is an array of strings which are the headers for each of the columns. 
There must be one entry for each column. 
\param rows An NSArray of NSArrays. 
\param headers Array containing the headers for each column. 
\param name  A NSString specifying the name of the matrix. 
\return An initialised AdDataMatrix instance.
*/
- (id) initWithRows: (NSArray*) rows
	columnHeaders: (NSArray*)  anArray
	name: (NSString*) aString; 
/**
As initWithRows:columnHeaders:name passing
nil for \e anArray
*/
- (id) initWithRows: (NSArray*) rows
	name: (NSString*) aString;
/**
As initWithRows:columnHeaders:name passing
nil for \e aString
*/
- (id) initWithRows: (NSArray*) rows 
	columnHeaders: (NSArray*) anArray;
/**
As initWithRows:columnHeaders:name passing
nil for both \e aString and \e anArray.
*/
- (id) initWithRows: (NSArray*) matrix;
/**
As initWithRows: passing nil for \e matrix.
*/
- (id) init;
/**
Returns the value of the element at (\e row, \e column).
If the given column or row does not exist an NSInvalidArgumentException is raised. 
\param row The row number
\param column The column number
\return The value of the element
*/
- (id) elementAtRow: (unsigned int) row column: (unsigned int) column;
/**
Returns the value of the element at row of the column identified by \e columnHeader
to value. If more than one column has the same header the first column is used.
If the given column header or row does not exist an NSInvalidArgumentException is raised. 
\param row The row number
\param columnHeader The header of the column to be accessed.
\return The value of the element
*/
- (id) elementAtRow: (unsigned int) row ofColumnWithHeader: (NSString*) columnHeader;
/**
Returns a copy of row number \e rowIndex
*/
- (NSArray*) row: (unsigned int) rowIndex;
/**
Returns a copy of column number \e columnIndex
*/
- (NSArray*) column: (unsigned int) columnIndex;
/**
Adds the elements in row \e rowIndex to \e anArray.
*/
- (void) addRow: (unsigned int) rowIndex toArray: (NSMutableArray*) anArray;
/**
Adds the elements in column \e columnIndex to \e anArray.
*/
- (void) addColumn: (unsigned int) columnIndex toArray: (NSMutableArray*) anArray;
/**
Returns the matrix contents as an AdMatrix struct.
i.e. a C matrix of doubles. The caller owns the
returned structure as is responsible for deallocating it
(using AdMemoryManager::freeMatrix: method)
*/
- (AdMatrix*) cRepresentation;
/**
Compares the c representation of the receiver with that of \e aMatrix
using AdCompareDoubleMatrices() with a tolerance of 1E-12.
*/
- (BOOL) compareCRepresentations: (AdDataMatrix*) aMatrix;
/**
Places the matrix contents in the buffer \e aMatrix.
\e aMatrix must have the correct dimensions. If not an 
NSInvalidArgumentException is raised.
*/
- (void) cRepresentationUsingBuffer: (AdMatrix*) aMatrix;
/**
Returns an enumerator over the matrix rows.
Each row is an NSMutableArray object
*/
- (NSEnumerator*) rowEnumerator;
/**
Returns a copy of the column with header \e columnWithHeader.
If \e columnHeader matches more than one column the one with
the lowest index is returned. 
If the given column header does not exist an NSInvalidArgumentException is raised. 
*/
- (NSArray*) columnWithHeader: (NSString*) columnHeader;
/**
Like columnWithHeader: excepts adds the elements to \e anArray instead
of returning an NSArray object.
*/
- (void) addColumnWithHeader: (NSString*) columnHeader
	toArray: (NSMutableArray*) anArray;
/**
Returns an array containing the rows of the matrix (the underlying
matrix representation).
\note This method is deprecated. Use rowEnumerator to enumerate
the matrix rows or access them via row:.
*/
- (NSArray*) matrixRows;
/**
Returns the number of rows
*/
- (unsigned int) numberOfRows;
/**
Returns the number of columns
*/
- (unsigned int) numberOfColumns;
/**
Returns an array of columnHeaders.
If no specific headers have been set using setColumnHeaders:
then an array containing the default titles is returned i.e.
(Column1, Column2 ...).
*/
- (NSArray*) columnHeaders;
/**
Returns the header for column \e index.
Raises an NSRangeException if \e index is greater than
or equal to the number of columns in the receiver.
*/
- (id) headerForColumn: (unsigned int) index;
/**
If a column with \e header exists it returns
the index of the first one found. Otherwise returns
NSNotFound
*/
- (unsigned int) indexOfColumnWithHeader: (NSString*) header;
/**
An array containing the data types that can be
held in each column. See class description for more.
*/
- (NSArray*) columnDataTypes;
/**
Returns the data type associated with \e columnIndex.
If no data type has been assigned returns nil.
If \e columnIndex does not exist NSInvalidArgumentException 
is raised.
*/
- (NSString*) dataTypeForColumn: (unsigned int) columnIndex;
/**
Returns the data type associated with the column with header
\e columnHeader.
If \e columnHeader matches more than one column the data type of
the one with the lowest index is returned.
If no data type has been assigned returns nil.
If \e columnIndex does not exist NSInvalidArgumentException 
is raised.
*/
- (NSString*) dataTypeForColumnWithHeader: (NSString*) columnHeader;
/**
Returns the name of the data matrix
*/
- (NSString*) name;
/**
Uses NSLog to print the data matrix to stderr. Useful
for debugging.
*/
- (void) printMatrix;
/**
Writes a plain text representation of the data matrix
to a file.
\note Deprecated - use stringRepresentation instead
*/
- (BOOL) writeMatrixToFile: (NSString*) filename;
/**
Returns a string containing a csv representation of the matrix
*/
- (NSString*) stringRepresentation;
/**
Returns an NSIndexSet containing the indexes of rows containing \e element
*/
- (NSIndexSet*) indexesOfRowsContainingElement: (id) element;
/**
Returns an NSIndexSet containing the indexes of rows that match \e array.
A match is found if the array contains the same number of objects as the
row and objects at a given index in each array satisfy the isEqual: test.
*/
- (NSIndexSet*) indexesOfRowsMatchingArray: (NSArray*) anArray;
/**
Returns a new AdDataMatrix instance containing only the rows
specified by the indexes in \e indexSet. 
The submatrix has the same headers and name as the receiver.
If any index in \e indexSet exceeds the range of rows in the reciever
an NSRangeException is raised.
*/
- (AdDataMatrix*) submatrixFromRowSelection: (NSIndexSet*) indexSet;
/**
Returns a new AdDataMatrix instance containing only the columns
specified by the indexes in \e indexSet.
The column headers are also copied and the returned matrix has the same
name as the receiver.
If any index in \e indexSet is exceeds the range of columns in the receiver
an NSRangeException is raised.
*/
- (AdDataMatrix*) submatrixFromColumnSelection: (NSIndexSet*) indexSet;
/**
Returns a new AdDataMatrix instance containing only the rows in \e range
The submatrix has the same headers and name as the receiver.
If \e range exceeds the range of rows in the matrix an NSRangeException
is raised.
*/
- (AdDataMatrix*) submatrixWithRowRange: (NSRange) range;
/**
Returns a new AdDataMatrix instance containing data from the columns in \e range
The column headers are also copied and the returned matrix has the same
name as the receiver.
If \e range exceeds the range of columns in the matrix an NSRangeException
is raised.
*/
- (AdDataMatrix*) submatrixWithColumnRange: (NSRange) range;
@end

/**
\ingroup Inter
Mutable subclass of AdDataMatrix. AdMutableDataMatrix allows you
to change element values and add rows and columns to the matrix.

When adding data to a column AdMutableDataMatrix checks that it is of the
correct type and if not it converts it. Conversion is possible in all
cases but be aware that convering a string that is not a number to 
an int or double will result in it being replaced with a \f$0\f$

See the AdDataMatrix class documentation for more.
\todo Extra Methods - Add more remove and add methods
*/

@interface AdMutableDataMatrix: AdDataMatrix
{
}

/**Returns an autoreleased AdDataMatrix instance initialise
with the values of \e aMatrix
\param aMatrx An ::AdMatrix struct
\return An autoreleased AdDataMatrix instance
*/

+ (id) matrixFromADMatrix: (AdMatrix*) aMatrix;

/**Returns an autoreleased AdDataMatrix instance initialise
with the values of \e aMatrix
\param aMatrx A gsl_matrix struct
\return An autoreleased AdDataMatrix instance
*/

+ (id) matrixFromGSLMatrix: (gsl_matrix*) aMatrix;

/**Returns an autoreleased AdDataMatrix instance initialise
with the values of \e aVector
\param aMatrx An gsl_vector struct
\return An autoreleased AdDataMatrix instance
*/

+ (id) matrixFromGSLVector: (gsl_vector*) aVector;

/**
Designated initialiser.
Creates a matrix with \e number columns. 
\e headers is an array of strings which are the headers for each of the columns. 
There must be one entry for each column. If \e headers is nil the columns
are given default titles (Column 1, Column 2 etc.).
\e dataTypes is an array containing strings defining the data types each
column can hold. If \e dataTypes is nil the data type of each column
will be determined from the first object added to it.
\param number The number of columns
\param headers Array containing the headers for each column.
\param dataTypes Array containing the data types to be associated with each column
\return An initialised AdDataMatrix instance.
*/
- (id) initWithNumberOfColumns: (unsigned int) number 
	columnHeaders: (NSArray*)  headers
	columnDataTypes: (NSArray*) dataTypes;

/**
As initWithNumberOfColumns:columnHeaders:columnDataTypes:
with the number of columns equal to the number of elements in \e dataTypes.
*/

- (id) initWithColumnsForDataTypes: (NSArray*) dataTypes 
	withHeaders: (NSArray*) headers;
/**
Sets the element at position (\e row, \e column) to \e value. 
This method can only be used if the element already exists.
If the given column or row does not exist an NSInvalidArgumentException is raised. 
The  class of \e value must be compatible with the data type of the column.
If \e value is not compatible with the column data type, it is converted if possible
otherwise an NSInvalidArgumentException is raised.
\param row The row number
\param columns The column number
\param value The value the element is to be set to
*/
- (void) setElementAtRow: (unsigned int) row column: (unsigned int) column withValue: (id) value;

/**
Sets the element at row of the column identified by \e columnHeader
to value. If more than one column has the same header the first column is used.
If the given column header or row does not exist an NSInvalidArgumentException is raised. 
The allowed type i.e. class, of value depends on the defined type for the column.
If \e value is not compatible with the column data type, it is converted if possible
otherwise an NSInvalidArgumentException is raised.
\param row The row number
\param columnHeader The header of the column to be accessed.
\param value The value the element is to be set to
*/
- (void) setElementAtRow: (unsigned int) row 
	ofColumnWithHeader: (NSString*) columnHeader 
	withValue: (id) value;
/** 
Extends the matrix by adding copies of the rows in \e extendingMatrix to the end.
\e extendingMatrix must have the same number of columns as the AdDataMatrix instance.
The types of each column of the extending matrix must be the same as, or convertible to, the types
in the receiver. Conversion is always to the receivers type. 
If any row of \e extendingMatrix cannot be added an NSInvalidArgumentException is raised.
However all previous rows will be added normally.

\param extendingMatrix The matrix to be appended
*/
- (void) extendMatrixWithMatrix: (AdDataMatrix*) extendingMatrix;
/**
Extends the matrix with \e row appending it as a new row at the end of 
the matrix. If \e row is the first row and the column data types have not been
defined then they are defined by the class of each of the elements in \e row.
Otherwise the class of each element in \e row must match, or be convertible to,
the data type of the corresponding column.
\param array The array to be appended as a row
*/
- (void) extendMatrixWithRow: (NSArray*) row;
/**
Adds \e column to the end of the matrix. All elements in
the column must be of the same class which determines the dataType of
the column. 
\param array The array to be appended 

The number of elements in the column must be equal to the number
of rows in the matrix - if not an NSInvalidArgumentException is raised.

If there are no rows in the matrix then passing an empty array will cause an empty
extra column to be added.
The only exception to this is if the column data types were bset on initialisation.
In that case the data type for the new column can't be determined and this method raises an exception.
The new column can be added once the first row of the matrix is present however.
*/
- (void) extendMatrixWithColumn: (NSArray*) column;
/**
Adds a row using a dictionary of columnHeader:value pairs.
That is, in the new row the value for each column will be the object in \e values
whose key corresponds to that columns column header.
 
Columns not specified in the dictionary (i.e. their column header is not a key)
are given values of zero (or the equivalent).
Keys which don't have corresponding headers (i.e. indexOfColumnWithHeader:() passing the key returns NSNotFound)
are ignored.

For example a matrix has 3 columns with the following headers
('Col 1', 'Col 2' , Col 3')

Create a dictionary with the value you want to insert for each column
{'Col 1':'Milk', 'Col2':100}

Passing this dictionary to this method adds a new row with the following entries

('Milk', 0, '100)

So it is equivalent to calling extendMatrixWithRow:() with this array.
The advantage of this method is that it allows you to add values to a matrix using
columnHeader strings.
*/

- (void) extendMatrixWithColumnValues: (NSDictionary*) values;
/**
Removes row number \e rowIndex from the matrix. 
Raises an NSRangeException if \e rowIndex is outside the range of the rows in the reciever.
*/
- (void) removeRow: (unsigned int) rowIndex;
/**
Removes the rows with the indexes in indexSet from the matrix.
Raises an NSRangeException if any of the indexes are outside 
the range of the rows in the reciever.
*/
- (void) removeRowsWithIndexes: (NSIndexSet*) indexSet;
/**
Remove the rows in \e aRange from the receiver.
Raises an NSRangeException if \e aRange goes beyond the length
of the receiver. In this case no rows are removed.
*/
- (void) removeRowsInRange: (NSRange) aRange;
/**
Sets titles for each column in the array to those in \e anArray.
\param anArray An array of strings describing the contents
of each column. If the number of strings is not equal to the
number of columns an exception is raised. 
*/
- (void) setColumnHeaders: (NSArray*) anArray;
/**
Set the header of column \e columnIndex to \e string.
If columnIndex doesnt exist an NSInvalidArgumentException is raised.
*/
- (void) setHeaderOfColumn: (unsigned int) columnIndex to: (NSString*) string;
/**
Sets the name of the data matrix to \e aString.
*/
- (void) setName: (NSString*) aString;
@end

/**
AdunKernel extensions to NSArray.
\ingroup Inter
*/
@interface NSArray (AdKernelAdditions)
/**
Returns a subarray containing the elements at the indexes specified
by \e indexSet. If an index in \e indexSet exceeds the range of elements in
the receiver an NSRangeException is raised.
*/
- (NSArray*) subarrayFromElementSelection: (NSIndexSet*) indexSet;
/**
Creates an NSArray object from a C array of doubles of length \e length
*/
+ (id) arrayFromCDoubleArray: (double*) array ofLength: (int) length;
/**
Creates an NSArray object from a C array of ints of length \e length
*/
+ (id) arrayFromCIntArray: (int*) array ofLength: (int) length;
/**
 Returns a c double array of the contents of the receiver.
 If an object responds to doubleValue, it is used to retreive the 
 value put in the array.
 Otherwise 0 is used.
 The caller is owns the returned array and is responsible for freeing it.
 */
- (double*) cDoubleRepresentation;
/**
Returns the number of times \e object appears in the receiver
*/
- (int) countForObject: (id) object;
/*
Re*turns a gsl_vector struct containing the contents of the receiver.
The same considerations as outlined in cDoubleRepresentation() apply here.
*/
- (gsl_vector*) gslVectorRepresentation;
@end

//For decoding old ULMatrix objects
@interface ULMatrix: AdDataMatrix
@end

/**
\ingroup frameworkTypes
Defines the different byte swapping
states an object can face on decoding.
*/
typedef enum
{
	AdNoSwap,	/**< No byte swapping is necessary */
	AdSwapBytesToBig, 	/**< Bytes must be swapped from little-endian to big-endian */
	AdSwapBytesToLittle	/**< Bytes must be swapped from big-endian to little-endian */
}
AdByteSwapFlag;

#endif // _ADMATRIX_H_


