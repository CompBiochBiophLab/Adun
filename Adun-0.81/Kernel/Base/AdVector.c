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


#include "Base/AdVector.h"

/**
 Allocates a matrix of Vector3D structs
 */
Vector3D** AdAllocate3DVectorMatrix(unsigned int numberOfRows, unsigned int numberOfColumns)
{
	unsigned int i, j;
	Vector3D* array, **matrix;

	array = malloc(numberOfRows*numberOfColumns*sizeof(Vector3D));
	matrix = malloc(numberOfRows*sizeof(Vector3D*));
	for(i=0, j=0; i < numberOfRows; i++, j = j + numberOfColumns)
		matrix[i] = array + j;
		
	return matrix;	
}

int AdCartesianDistanceCheck(double* position1, double* position2, double separation)
{
	if(fabs(position1[0] - position2[0]) > separation)
		return 0;
	
	if(fabs(position1[1] - position2[1]) > separation)
		return 0;
	
	if(fabs(position1[2] - position2[2]) > separation)
		return 0;
		
	return 1;					
}

int AdCartesianDistanceVectorCheck(Vector3D* separation, double distance)
{
	double* components;
	
	components = separation->vector;

	if(fabs(components[0]) > distance)
		return 0;
	
	if(fabs(components[1]) > distance)
		return 0;
	
	if(fabs(components[2]) > distance)
		return 0;
	
	return 1;
}

/**
 Frees a matrix of Vector3D structs.
 It must have been allocated using AdAllocate3DVectorMatrix().
 */
void AdFree3DVectorMatrix(Vector3D** matrix)
{
	if(matrix != NULL)
	{
		free(matrix[0]);	//frees the vector array
		free(matrix);		//frees the pointer array
	}
}

void Ad3DVectorInit(Vector3D* vector)
{
	double* array;
	
	array = vector->vector;
	array[0] = array[1] = array[2] = 0;
	vector->length = 0;
}

void Ad3DVectorScalarMultiply(Vector3D* vector, double value)
{
	double* array;
	
	array = vector->vector;
	array[0] *= value;
	array[1] *= value;
	array[2] *= value;
}

double Ad3DDotProduct(Vector3D* vector_one, Vector3D* vector_two)
{
	register int i;
	double product;
	
	for(product = 0, i=3; --i>=0;)
		product += vector_one->vector[i] * vector_two->vector[i];
	
	return product;
}


void Ad3DCrossProduct(Vector3D* v_one, Vector3D* v_two, Vector3D* result)
{
	//calculate the cross product of the two vectors v_one X v_two

	result->vector[0] = v_one->vector[1]*v_two->vector[2] - v_one->vector[2]*v_two->vector[1];

	result->vector[1] = v_one->vector[2]*v_two->vector[0] - v_one->vector[0]*v_two->vector[2]; 
	
	result->vector[2] = v_one->vector[0]*v_two->vector[1] - v_one->vector[1]*v_two->vector[0];
}


void Ad3DVectorLength(Vector3D* vec)
{
	(vec->length) =  *(vec->vector) * *(vec->vector) + *(vec->vector + 1) * *(vec->vector + 1); 
	(vec->length) += *(vec->vector + 2) * *(vec->vector + 2);
	
	(vec->length) = sqrt(vec->length);
}

void Ad3DVectorLengthSquared(Vector3D* vec)
{
	(vec->length) =  *(vec->vector) * *(vec->vector) + *(vec->vector + 1) * *(vec->vector + 1); 
	(vec->length) += *(vec->vector + 2) * *(vec->vector + 2);
}

void AdGet3DUnitVector(Vector3D* vector, Vector3D* unit_vector)
{
	register int i;	
	double length;

	length = 1/vector->length;

	for(i=0; i< 3; i++)
		unit_vector->vector[i] = vector->vector[i]*length;

	unit_vector->length = 1;
}

void AdGetRandom3DUnitVector(Vector3D* vector, gsl_rng* generator)
{
	double r, t;

	//Uses trig-method - see docs

	vector->vector[2] = gsl_ran_flat(generator, -1, 1);
	r = sqrt(1 - vector->vector[2]*vector->vector[2]);
	t = gsl_ran_flat(generator, 0, 2*M_PI);

	vector->vector[0] = r*cos(t);
	vector->vector[1] = r*sin(t);
	vector->length = 1;
}

int AdDoubleArrayMin(double* array, int noElements)
{
	int minIndex, i;
	double minValue;
	
	minIndex = 0;
	minValue = array[0];
	for(i=1; i<noElements; i++)
	{
		if(array[i] < minValue)
		{
			minValue = array[i];
			minIndex = i;
		}
	}
	
	return minIndex;
}

int AdDoubleArrayMax(double* array, int noElements)
{
	int maxIndex, i;
	double maxValue;
	
	maxIndex = 0;
	maxValue = array[0];
	for(i=1; i<noElements; i++)
	{
		if(array[i] > maxValue)
		{
			maxValue = array[i];
			maxIndex = i;
		}
	}
	
	return maxIndex;
}

/**
Returns the intersection and complement of two arrays as 
an InterSectionStruct
**/

void AdIntArrayIntersectionAndDifference(IntArrayStruct *prime, IntArrayStruct *query, IntArrayStruct *intersection, IntArrayStruct *complement)
{
	int i, j;
	int complementCount, intersectionCount;	
	int* intersectionArray, *complementArray, *primeArray, *queryArray;

	intersection->array = (int*)malloc(prime->length*sizeof(int));
	complement->array = (int*)malloc(prime->length*sizeof(int));

	primeArray = prime->array;
	queryArray = query->array;
	intersectionArray = intersection->array;
	complementArray = complement->array;

	i = j  = intersectionCount = complementCount = 0;
	while(i<prime->length)
	{	
		if(primeArray[i] == queryArray[j])
		{	
			intersectionArray[intersectionCount] = primeArray[i];
			i++;
			j++;
			intersectionCount++;
		}
		else if(primeArray[i] < queryArray[j])
		{
			complementArray[complementCount] = primeArray[i];
			i++;
			complementCount++;
		}
		else
		{
			j++;
		}

		//check if we have exhausted the query array
		
		if(j > query->length)
			break;

	}
	
	//if we didnt exhause the prime array copy all left over members to complement

	for(j=i; j<prime->length; j++)
	{
		complementArray[complementCount] = primeArray[j];
		complementCount++;
	}
			
	intersection->length = intersectionCount;
	complement->length = complementCount;
}

void AdIntArrayIntersection(IntArrayStruct *prime, IntArrayStruct *query, IntArrayStruct *intersection)
{
	int i, j;
	int intersectionCount;	
	int* intersectionArray,  *primeArray, *queryArray;

	intersection->array = (int*)malloc(prime->length*sizeof(int));

	primeArray = prime->array;
	queryArray = query->array;
	intersectionArray = intersection->array;

	i = j  = intersectionCount = 0;
	while(i<prime->length)
	{	
		if(primeArray[i] == queryArray[j])
		{	
			intersectionArray[intersectionCount] = primeArray[i];
			i++;
			j++;
			intersectionCount++;
		}
		else if(primeArray[i] < queryArray[j])
		{
			i++;
		}
		else
		{
			j++;
		}

		//check if we have exhausted the query array
		
		if(j > query->length)
			break;

	}
	
	intersection->length = intersectionCount;
}

void AdIntArrayDifference(IntArrayStruct *prime, IntArrayStruct *query, IntArrayStruct *difference)
{
	int i, j;
	int differenceCount;	
	int* differenceArray,  *primeArray, *queryArray;

	difference->array = (int*)malloc(prime->length*sizeof(int));

	primeArray = prime->array;
	queryArray = query->array;
	differenceArray = difference->array;

	i = j  = differenceCount = 0;
	while(i<prime->length)
	{	
		if(primeArray[i] == queryArray[j])
		{	
			i++;
			j++;
		}
		else if(primeArray[i] < queryArray[j])
		{
			differenceArray[differenceCount] = primeArray[i];
			differenceCount++;
			i++;
		}
		else
		{
			j++;
		}
	
		if(j > query->length)
			break;

	}
	
	difference->length = differenceCount;
}

