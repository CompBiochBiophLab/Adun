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

#include <stdbool.h>
#include "Base/AdMatrix.h"
#include <string.h>

bool AdCheckDoubleMatrixDimensions(DoubleMatrix *matrixOne, DoubleMatrix *matrixTwo)
{
	bool rows, columns;
	
	rows = (matrixOne->no_rows == matrixTwo->no_rows) ? true : false;
	columns = (matrixOne->no_columns == matrixTwo->no_columns) ? true : false;
	return rows && columns;
}

/**
Compares two double matrices by checking if corresponding elements
are the same within the specified tolerance
*/
bool AdCompareDoubleMatrices(DoubleMatrix *matrixOne, DoubleMatrix *matrixTwo, double tolerance)
{
	bool retval = true;
	int i,j;
	double difference;

	if(!AdCheckDoubleMatrixDimensions(matrixOne, matrixTwo))
		return false;

	for(i=0; i<matrixOne->no_rows;i++)
	{
		for(j=0; j<matrixOne->no_columns;j++)
		{
			difference = matrixOne->matrix[i][j] - matrixTwo->matrix[i][j];
			if(abs(difference) > tolerance)
			{
				retval = false;
				break;
			}
		}
		
		if(retval == false)
			break;
	}
	
	return retval;
}

/** Sets a double matrix with value
\param DoubleMatrix a DoubleMatrix structure
\param value the value to be set
**/
void AdSetDoubleMatrixWithValue(DoubleMatrix *matrix_s, double value)
{
	int i, j;

	for(i=0; i<matrix_s->no_rows; i++)
		for(j=0; j<matrix_s->no_columns; j++)
			matrix_s->matrix[i][j] = value;
}

/** Sets a float matrix with value
\param FloatMatrix a FloatMatrix structure
\param value the value to be set
**/

void AdSetFloatMatrixWithValue(FloatMatrix *matrix_s,  float value)
{
	int i, j;

	for(i=0; i<matrix_s->no_rows; i++)
		for(j=0; j<matrix_s->no_rows; j++)
			matrix_s->matrix[i][j] = value;
}
/** Sets an int matrix with value
\param IntMatrix an IntMatrix structure
\param value the value to be set
**/

void AdSetIntMatrixWithValue(IntMatrix *matrix_s, int value)
{
	int i, j;

	for(i=0; i<matrix_s->no_rows; i++)
		for(j=0; j<matrix_s->no_columns; j++)
			matrix_s->matrix[i][j] = value;
}

/**
Returns a subset of matrix_s defined by start_row and end_row (inclusive)
\param matrix_s An int matrix structure
\param start_row the start_row
\param end_row the end_row
\return An IntMatrix structure for the matrix subset
**/

IntMatrix* AdIntMatrixFromRowSection(IntMatrix *matrix_s, int start_row, int end_row)
{
	int i, j, k;
	IntMatrix *ret_matrix;

	ret_matrix = AdAllocateIntMatrix(((end_row - start_row) +1), matrix_s->no_columns);

	for(i=start_row, k=0; i< (end_row +1); i++, k++)
		for(j=0; j<ret_matrix->no_columns; j++)
			ret_matrix->matrix[k][j] = matrix_s->matrix[i][j];

	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by start_row and end_row (inclusive)
\param matrix_s An FloatMatrix structure
\param start_row the start_row
\param end_row the end_row
\return A FloatMatrix structure for the matrix subset
**/
			
FloatMatrix* AdFloatMatrixFromRowSection(FloatMatrix *matrix_s, int start_row, int end_row)
{
	int i, j, k;
	FloatMatrix *ret_matrix;

	ret_matrix = AdAllocateFloatMatrix(((end_row - start_row) +1), matrix_s->no_columns);

	for(i=start_row, k=0; i< (end_row +1); i++, k++)
		for(j=0; j<ret_matrix->no_columns; j++)
			ret_matrix->matrix[k][j] = matrix_s->matrix[i][j];

	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by start_row and end_row (inclusive)
\param matrix_s An DoubleMatrix structure
\param start_row the start_row
\param end_row the end_row
\return A DoubleMatrix structure for the matrix subset
**/
DoubleMatrix* AdDoubleMatrixFromRowSection(DoubleMatrix *matrix_s, int start_row, int end_row)
{
	int i, j, k;
	DoubleMatrix *ret_matrix;

	ret_matrix = AdAllocateDoubleMatrix(((end_row - start_row) +1), matrix_s->no_columns);

	for(i=start_row, k=0; i< (end_row +1); i++, k++)
		for(j=0; j<ret_matrix->no_columns; j++)
			ret_matrix->matrix[k][j] = matrix_s->matrix[i][j];

	return ret_matrix;
}

/**
Returns a subset of matrix_s defined by the array rows
\param matrix_s An int matrix structure
\param rows An array containing the indices of the rows with which to make the new matrix
\param no_rows  the number of elements in rows
\return An IntMatrix structure for the matrix subset
**/

IntMatrix* AdIntMatrixFromRowSelection(IntMatrix *matrix_s, int* rows, int no_rows)
{
	int i, j;
	IntMatrix *ret_matrix;

	ret_matrix = AdAllocateIntMatrix(no_rows, matrix_s->no_columns);
	for(i=0; i<no_rows; i++)
		for(j=0; j<ret_matrix->no_columns; j++)
			ret_matrix->matrix[i][j] = matrix_s->matrix[rows[i]][j];	 

	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by the array rows
\param matrix_s An FloatMatrix structure
\param rows An array containing the indices of the rows with which to make the new matrix
\param no_rows  the number of elements in rows
\return An FloatMatrix structure for the matrix subset
**/

FloatMatrix* AdFloatMatrixFromRowSelection(FloatMatrix *matrix_s, int* rows, int no_rows)
{
	int i, j;
	FloatMatrix *ret_matrix;

	ret_matrix = AdAllocateFloatMatrix(no_rows, matrix_s->no_columns);
	for(i=0; i<no_rows; i++)
		for(j=0; j<ret_matrix->no_columns; j++)
			ret_matrix->matrix[i][j] = matrix_s->matrix[rows[i]][j];	
	
	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by the array rows
\param matrix_s An DoubleMatrix structure
\param rows An array containing the indices of the rows with which to make the new matrix
\param no_rows  the number of elements in rows
\return An DoubleMatrix structure for the matrix subset
**/

DoubleMatrix* AdDoubleMatrixFromRowSelection(DoubleMatrix *matrix_s, int* rows, int no_rows)
{	
	int i, j;
	DoubleMatrix *ret_matrix;

	ret_matrix = AdAllocateDoubleMatrix(no_rows, matrix_s->no_columns);
	for(i=0; i<no_rows; i++)
		for(j=0; j<ret_matrix->no_columns; j++)
			ret_matrix->matrix[i][j] = matrix_s->matrix[rows[i]][j];	
	
	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by start_column and end_column (inclusive)
\param matrix_s An IntMatrix structure
\param start_column the start_column
\param end_column the end_column
\return An IntMatrix structure for the matrix subset
**/

IntMatrix* AdIntMatrixFromColumnSection(IntMatrix *matrix_s, int start_column, int end_column)
{
	int i, j, k;
	IntMatrix *ret_matrix;

	ret_matrix = AdAllocateIntMatrix(matrix_s->no_rows, ((end_column - start_column) +1));
	
	for(i=0; i< ret_matrix->no_rows; i++)
		for(j=start_column, k=0; j<end_column+1; j++, k++)
			ret_matrix->matrix[i][k] = matrix_s->matrix[i][j];
	
	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by start_column and end_column (inclusive)
\param matrix_s A FloatMatrix structure
\param start_column the start_column
\param end_column the end_column
\return A FloatMatrix structure for the matrix subset
**/

FloatMatrix* AdFloatMatrixFromColumnSection(FloatMatrix *matrix_s, int start_column, int end_column)
{
	int i, j, k;
	FloatMatrix *ret_matrix;

	ret_matrix = AdAllocateFloatMatrix(matrix_s->no_rows, ((end_column - start_column) +1));
	
	for(i=0; i< ret_matrix->no_rows; i++)
		for(j=start_column, k=0; j<end_column+1; j++, k++)
			ret_matrix->matrix[i][k] = matrix_s->matrix[i][j];
	
	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by start_column and end_column (inclusive)
\param matrix_s A DoubleMatrix structure
\param start_column the start_column
\param end_column the end_column
\return A DoubleMatrix structure for the matrix subset
**/

DoubleMatrix* AdDoubleMatrixFromColumnSection(DoubleMatrix *matrix_s, int start_column, int end_column)
{
	int i, j, k;
	DoubleMatrix *ret_matrix;

	ret_matrix = AdAllocateDoubleMatrix(matrix_s->no_rows, ((end_column - start_column) +1));
	
	for(i=0; i< ret_matrix->no_rows; i++)
		for(j=start_column, k=0; j<end_column+1; j++, k++)
			ret_matrix->matrix[i][k] = matrix_s->matrix[i][j];
	
	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by the array columns
\param matrix_s An IntMatrix structure
\param columns An array containing the indices of the columns with which to make the new matrix
\param no_columns  the number of elements in columns
\return An IntMatrix structure for the matrix subset
**/

IntMatrix* AdIntMatrixFromColumnSelection(IntMatrix *matrix_s, int* columns, int no_columns)
{
	int i, j;
	IntMatrix *ret_matrix;

	ret_matrix = AdAllocateIntMatrix(matrix_s->no_rows, no_columns);
	for(i=0; i<ret_matrix->no_rows; i++)
		for(j=0; j<no_columns; j++)
			ret_matrix->matrix[i][j] = matrix_s->matrix[i][columns[j]];	 

	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by the array columns
\param matrix_s A FloatMatrix structure
\param columns An array containing the indices of the columns with which to make the new matrix
\param no_columns  the number of elements in columns
\return A FloatMatrix structure for the matrix subset
**/

FloatMatrix* AdFloatMatrixFromColumnSelection(FloatMatrix *matrix_s, int* columns, int no_columns)
{
	int i, j;
	FloatMatrix *ret_matrix;

	ret_matrix = AdAllocateFloatMatrix(matrix_s->no_rows, no_columns);
	for(i=0; i<ret_matrix->no_rows; i++)
		for(j=0; j<no_columns; j++)
			ret_matrix->matrix[i][j] = matrix_s->matrix[i][columns[j]];	 

	return ret_matrix;
}
/**
Returns a subset of matrix_s defined by the array columns
\param matrix_s A DoubleMatrix structure
\param columns An array containing the indices of the columns with which to make the new matrix
\param no_columns  the number of elements in columns
\return A DoubleMatrix structure for the matrix subset
**/

DoubleMatrix* AdDoubleMatrixFromColumnSelection(DoubleMatrix *matrix_s, int* columns, int no_columns)
{
	int i, j;
	DoubleMatrix *ret_matrix;

	ret_matrix = AdAllocateDoubleMatrix(matrix_s->no_rows, no_columns);
	for(i=0; i<ret_matrix->no_rows; i++)
		for(j=0; j<no_columns; j++)
			ret_matrix->matrix[i][j] = matrix_s->matrix[i][columns[j]];	 

	return ret_matrix;
}

/**
Frees a DoubleMatrix struct
\param matrix_s the struct to be freed
**/

void AdFreeDoubleMatrix(DoubleMatrix* matrix_s)
{
	free(matrix_s->matrix[0]);
	free(matrix_s->matrix);
	free(matrix_s);
}
/**
Frees an IntMatrix struct
\param matrix_s the struct to be freed
**/

void AdFreeIntMatrix(IntMatrix* matrix_s)
{

	free(matrix_s->matrix[0]);
	free(matrix_s->matrix);
	free(matrix_s);
}
/**
Frees an FloatMatrix struct
\param matrix_s the struct to be freed
**/

void AdFreeFloatMatrix(FloatMatrix* matrix_s)
{
	free(matrix_s->matrix[0]);
	free(matrix_s->matrix);
	free(matrix_s);
}
/**
Allocates a DoubleMatrix struct. It should be freed using the corresponding free function
\param no_rows the number of rows in the matrix
\param no_columns the number of columns in the matrix
\return A DoubleMatrix struct (uninitialised)
**/

DoubleMatrix* AdAllocateDoubleMatrix(int no_rows, int no_columns)
{
	int i,j;
	double* array;
	DoubleMatrix *ret_matrix;

	ret_matrix = (DoubleMatrix*)malloc(sizeof(DoubleMatrix));
	ret_matrix->no_columns = no_columns;
	ret_matrix->no_rows = no_rows;
	ret_matrix->matrix = (double**)malloc(ret_matrix->no_rows*sizeof(double*));

	array = (double*)malloc(no_rows*no_columns*sizeof(double));

	//malloc an array of pointers to act as indicies into array
	//i.e. emulating a matrix

	ret_matrix->matrix = (double**)malloc(no_rows*sizeof(double*));
	
	//array + j (array[j]) is pointer arithmetic. Unless the computer knows
	//what type of memory array points to then it may take the wrong step size
	//it isnt necessary to specify matrixs pointer type as all pointers are the same size

	for(i=0, j=0; i < no_rows; i++, j = j + no_columns)
			ret_matrix->matrix[i] = array + j;

	return ret_matrix;
}
/**
Allocates a FloatMatrix struct. It should be freed using the corresponding free function
\param no_rows the number of rows in the matrix
\param no_columns the number of columns in the matrix
\return A FloatMatrix struct (uninitialised)
**/

FloatMatrix* AdAllocateFloatMatrix(int no_rows, int no_columns)
{
	int i,j;
	float* array;
	FloatMatrix *ret_matrix;

	ret_matrix = (FloatMatrix*)malloc(sizeof(FloatMatrix));
	ret_matrix->no_columns = no_columns;
	ret_matrix->no_rows = no_rows;
	ret_matrix->matrix = (float**)malloc(ret_matrix->no_rows*sizeof(float*));

	array = (float*)malloc(no_rows*no_columns*sizeof(float));
	ret_matrix->matrix = (float**)malloc(no_rows*sizeof(float*));
	
	for(i=0, j=0; i < no_rows; i++, j = j + no_columns)
			ret_matrix->matrix[i] = array + j;

	return ret_matrix;

}

/**
Allocates an IntMatrix struct. It should be freed using the corresponding free function
\param no_rows the number of rows in the matrix
\param no_columns the number of columns in the matrix
\return An IntMatrix struct (uninitialised)
**/

IntMatrix* AdAllocateIntMatrix(int no_rows, int no_columns)
{
	int i,j;
	int* array;
	IntMatrix *ret_matrix;

	ret_matrix = (IntMatrix*)malloc(sizeof(IntMatrix));
	ret_matrix->no_columns = no_columns;
	ret_matrix->no_rows = no_rows;

	array = (int*)malloc(no_rows*no_columns*sizeof(int));
	ret_matrix->matrix = (int**)malloc(no_rows*sizeof(int*));
	
	for(i=0, j=0; i < no_rows; i++, j = j + no_columns)
			ret_matrix->matrix[i] = array + j;

	return ret_matrix;
}

/**
Copies the contents of the first matrix into the second.
The two matrices must have the same dimensions.
*/

void AdCopyAdMatrixToAdMatrix(AdMatrix* matrixOne, AdMatrix* matrixTwo)
{
	int i,j;

	if(matrixOne->no_rows != matrixTwo->no_rows)
	{
		printf("Copy error - Matrices do not have the same number of rows");
		exit(10);
	}
		
	if(matrixOne->no_columns != matrixTwo->no_columns)
	{
		printf("Copy error - Matrices do not have the same number of columns");
		exit(10);
	}

	for(i=0; i<matrixOne->no_rows; i++)
		for(j=0; j<matrixOne->no_columns; j++)
			matrixTwo->matrix[i][j] = matrixOne->matrix[i][j];
}


/*
Returns a structure containing the indexes of the columns of row \e
that have non zero values along with the values.
row->length is the number of non-zero elements in the row.
row->columnValues[i] gives the i^th non-zero value in the row while
row->columnIndexes[i] gives the corresponding column index
*/
void AdSparseMatrixRowElements(AdSparseMatrix* matrix, unsigned int rowIndex, AdSparseMatrixRow* row)
{
	int colStart, valueStart;

	//Get the position where this rows column entries start
	colStart = matrix->rowArray[rowIndex];
	
	//Set the pointer to the start of the column indexes
	//along with the number of indexes.
	row->columnIndexes = matrix->columnArray + colStart;
	row->length= matrix->rowArray[rowIndex+1] - colStart; 
	
	//Get the point in the value array where elements
	//associated with the row are stored.
	//The set the pointer to this.
	valueStart = matrix->columnArray[colStart];
	row->columnValues = matrix->values + valueStart;
}

int AdSparseMatrixSafeAddElement(AdSparseMatrix* matrix, unsigned int rowIndex, unsigned int columnIndex, double* value)
{
	bool newRow = false;

	if(rowIndex >= matrix->no_rows)
	{
		fprintf(stderr, "Row index %d exceeds matrix bounds (%d)", rowIndex, matrix->no_rows);
		return 1;
	}

	//Check that this row is at least equal to the row being currently filled
	if(matrix->rowArray[rowIndex] != -1)
		if(rowIndex < matrix->no_rows - 1)
			if(matrix->rowArray[rowIndex + 1] != -1)
			{
				fprintf(stderr, "Row %d already filled", rowIndex);
				return 1;
			}
	
	
	if(matrix->rowArray[rowIndex] == -1)
	{
		if(rowIndex != 0)
		{
			if(matrix->rowArray[rowIndex - 1] == -1)
			{
				fprintf(stderr, "Warning - Skipped row %d on add", rowIndex - 1);
				return 1;
			}
		}
		
		newRow = true;		
	}
		
	//columnIndex must be greater than last one added for this row	      
	if(!newRow)
		if(matrix->numberAdded > 0)
			if((unsigned int)matrix->columnArray[matrix->numberAdded -1] >= columnIndex)
			{
				fprintf(stderr, "Previously added column %d. Now adding column %d", 
					matrix->columnArray[matrix->numberAdded -1], columnIndex);
				return 1;	
			}
				
	AdSparseMatrixAddElement(matrix, rowIndex, columnIndex, value);
	
	return 0;
}


/*
The matrix can only be filled in row order.
That is you must add elements starting from the first nonZero and proceeding across rows
*/
void AdSparseMatrixAddElement(AdSparseMatrix* matrix, unsigned int rowIndex, unsigned int columnIndex, double* value)
{
	int index;

	//Find where we will add the element
	index = matrix->numberAdded;
	matrix->values[index] = *value;
	matrix->columnArray[index] = columnIndex;
	matrix->numberAdded++;
	
	//Check if this is a new row
	if(matrix->rowArray[rowIndex] == -1)
		matrix->rowArray[rowIndex] = index;
}

AdSparseMatrix* AdAllocateSparseMatrix(unsigned int numberRows, unsigned int numberColumns, unsigned int nonZero)
{
	int totalSize;
	void* array;
	AdSparseMatrix* matrix;
	
	matrix = malloc(sizeof(AdSparseMatrix));
	matrix->no_rows = numberRows;
	matrix->no_columns = numberColumns;
	matrix->numberNonZero = nonZero;
	
	//Allocate one chunk of contiguous memory to hold everything
	totalSize = numberRows*sizeof(int) + nonZero*sizeof(int) + nonZero*sizeof(double);
	array = calloc(totalSize, 1);
	
	matrix->rowArray = (int*)array;
	matrix->columnArray = (int*)(array + numberRows*sizeof(int));
	matrix->values = (double*)(array + numberRows*sizeof(int) + nonZero*sizeof(int));
	
	matrix->numberAdded = 0;
	
	//Set all elements of rowArray to -1 
	memset(matrix->rowArray, -1, numberRows*sizeof(int));
	
	return matrix;
}

void AdFreeSparseMatrix(AdSparseMatrix* matrix)
{
	free(matrix->rowArray);
	free(matrix);
}

int AdSparseMatrixRowLength(AdSparseMatrix* matrix, unsigned int rowIndex)
{
	int rowStart; 
	
	rowStart = matrix->rowArray[rowIndex];
	
	if(rowIndex = matrix->no_rows - 1)
		return matrix->numberNonZero - rowStart;
	else
		return matrix->rowArray[rowIndex + 1] - rowStart;
}





