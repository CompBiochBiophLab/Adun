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

#ifndef _ADUN_MATRIX_
#define _ADUN_MATRIX_
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

//! \brief Structure for int matrices 
/**
\ingroup Types
*/

typedef struct
{
	int no_rows;
	int no_columns;
	int** matrix;
}
IntMatrix;


//! \brief Structure for float matrices 
/**
\ingroup Types
*/
typedef struct floatmatrix
{
	int no_rows;
	int no_columns;
	float** matrix;
}
FloatMatrix;

//! \brief Structure for double matrices 
/**
\ingroup Types
*/
typedef struct doublematrix
{
	int no_rows;
	int no_columns;
	double** matrix;
}
DoubleMatrix;

/**
Structure for storing a sparse matrix.
*/
typedef struct
{
	unsigned int no_rows;
	unsigned int no_columns;
	unsigned int numberNonZero;	//!< The space available for non zero elements
	unsigned int numberAdded;	//!< Indicates how many elements have been added to the matrix
	int* rowArray;
	int* columnArray;
	double* values;
}
AdSparseMatrix;

/**
Structure providing access to a row of a sparse matrix
*/
typedef struct
{
	unsigned int length;
	int* columnIndexes;
	double* columnValues;
}
AdSparseMatrixRow;

typedef double AdMatrixSize;

//typedefs for AdMatrix - we make AdMatrix refer to the DoubleMatrix type

typedef DoubleMatrix AdMatrix;

//prototypes
/**
\defgroup matrix Matrix
\ingroup Functions
@{
*/

/**
Returns true if the two matrices have the same dimensions, false otherwise.
*/
bool AdCheckDoubleMatrixDimensions(DoubleMatrix *matrixOne, DoubleMatrix *matrixTwo);
/**
Returns true if the absolute difference between every corresponding element of the two matrices
is less than tolerance, otherwise returns false.
Also returns false if the matrices do not have the same dimension.
*/
bool AdCompareDoubleMatrices(DoubleMatrix *matrixOne, DoubleMatrix *matrixTwo, double tolerance);

void AdSetDoubleMatrixWithValue(DoubleMatrix *, double);
void AdSetFloatMatrixWithValue(FloatMatrix *,  float);
void AdSetIntMatrixWithValue(IntMatrix *, int);

IntMatrix* AdIntMatrixFromRowSection(IntMatrix *, int , int);
FloatMatrix* AdFloatMatrixFromRowSection(FloatMatrix *, int , int);
DoubleMatrix* AdDoubleMatrixFromRowSection(DoubleMatrix *, int , int);

IntMatrix* AdIntMatrixFromRowSelection(IntMatrix *, int* , int);
FloatMatrix* AdFloatMatrixFromRowSelection(FloatMatrix *, int* , int);
DoubleMatrix* AdDoubleMatrixFromRowSelection(DoubleMatrix *, int* , int);

IntMatrix* AdIntMatrixFromColumnSection(IntMatrix *, int , int);
FloatMatrix* AdFloatMatrixFromColumnSection(FloatMatrix *, int , int);
DoubleMatrix* AdDoubleMatrixFromColumnSection(DoubleMatrix *, int , int);

IntMatrix* AdIntMatrixFromColumnSelection(IntMatrix *, int* , int);
FloatMatrix* AdFloatMatrixFromColumnSelection(FloatMatrix *, int* , int);
DoubleMatrix* AdDoubleMatrixFromColumnSelection(DoubleMatrix *, int* , int);

void AdFreeDoubleMatrix(DoubleMatrix*);
void AdFreeIntMatrix(IntMatrix*);
void AdFreeFloatMatrix(FloatMatrix*);

IntMatrix* AdAllocateIntMatrix(int, int);
FloatMatrix* AdAllocateFloatMatrix(int, int);
DoubleMatrix* AdAllocateDoubleMatrix(int, int);

/**
AdMatrix copy function.
*/
void AdCopyAdMatrixToAdMatrix(DoubleMatrix*, DoubleMatrix*);

/** 
@}
*/

/**
 \defgroup sparseMatrix Sparse Matrix
 Aduns sparse matrix format is a storage device and not intended for use with sparse-matrix algorithms.
 In this case using a dedicated sparse matrix library is required.
 \ingroup Functions
 @{
 */
 
/**
Allocates a structure for storing a sparse matrix of dimension \e numberRows * \e numberColumns
with \e nonZero non zero entries.
Free the matrix using AdFreeSparseMatrix()
*/ 
AdSparseMatrix* AdAllocateSparseMatrix(unsigned int numberRows, unsigned int numberColumns, unsigned int nonZero);

/**
Frees a matrix allocated using AdAllocateSparseMatrix()
*/
void AdFreeSparseMatrix(AdSparseMatrix* matrix); 

/**
Adds \e value as the (\e rowIndex, \e columnIndex) entry of \e matrix.

The matrix can only be filled in row order.
That is you must add elements starting from the first non zero entry and proceeding across rows.
(columnIndex must be greater than that of the last added entry and rowIndex must be equal to or greater
than that of the last added entry)
*/
void AdSparseMatrixAddElement(AdSparseMatrix* matrix, unsigned int rowIndex, unsigned int columnIndex, double* value);
/**
As AdSparseMatrixAddElement() but performs a number of checks to ensure the addition is valid.
If its not the function returns immediately with a return value of 1, otherwise it returns 0.
*/
int AdSparseMatrixSafeAddElement(AdSparseMatrix* matrix, unsigned int rowIndex, unsigned int columnIndex, double* value);
/**
Returns the number of non-zero elements in row \e rowIndex of \e matrix
*/
int AdSparseMatrixRowLength(AdSparseMatrix* matrix, unsigned int rowIndex);

/**
Sets the AdSparseRow structure \e row with information on the indexes of the columns of row \e rowIndex
that have non zero values along with their values.
row->length is the number of non-zero elements in the row.
row->columnValues[i] gives the i^th non-zero value in the row while row->columnIndexes[i] gives the corresponding column index.
*/ 
void AdSparseMatrixRowElements(AdSparseMatrix* matrix, unsigned int rowIndex, AdSparseMatrixRow* row);
 /** \}**/

#endif
