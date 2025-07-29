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

#ifndef VECTORS
#define VECTORS

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <stdio.h>


/**
Basic vector structure for Framework
\ingroup Types
*/

typedef struct 
{
	double length;		//!< The length of the vector
	double vector[3]; 	//!< An array of three double elements
}
Vector3D;

typedef struct 
{
	double length[2];		//!< The length of the two vector
	double vector[6]; 		//!< An array of six double elements (x1, y1, x2, y2 etc);
}
DoubleVector3D;

/**
A structure for integer arrays
\ingroup Types
*/

typedef struct 
{
	int length;		//!< The length of the vector
	int* array; 	//!< An array 
}
IntArrayStruct;

/**
\defgroup Vector Vector
\ingroup Functions
@{
*/

/**
These functions are inlined only under GCC.
This is because under ICC better performance is achieved if the
ICC compiled versions are used everywhere
*/

#ifdef __GNUC__

/**
 Sets all elements in vector to 0.
 */
extern inline void Ad3DVectorInit(Vector3D* vector)
{
	double* array;
	
	array = vector->vector;
	array[0] = array[1] = array[2] = 0;
	vector->length = 0;
}


/**
 Returns 1 if position1 and position two are separated by less than sqrt(3)*separation.
 That is if the distance between the two points is less than separation on every axis.
 (A point less than separation away on each axis is maximum sqrt(3)*separation away).
 Conversely if the distance is greater than separation on any axis this function returns 0.
 (If this is the case then the minimum it can be away is separation).
 */
extern inline int AdCartesianDistanceCheck(double* position1, double* position2, double separation)
{
	if(fabs(position1[0] - position2[0]) > separation)
		return 0;
	
	if(fabs(position1[1] - position2[1]) > separation)
		return 0;
	
	if(fabs(position1[2] - position2[2]) > separation)
		return 0;
	
	return 1;
}

/**
 Similar to AdCartesianDistanceCheck().
 However in this case checks if two points separated by the vector \e separation
 are closer than \e distance
 */
extern inline int AdCartesianDistanceVectorCheck(Vector3D* separation, double distance)
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
 Multiplies \e vector by \e value
 \param vector Pointer to a Vector3D struct
 \param value A double to multiply the vector by.
 
 \note The vector length is \e NOT modified.
 **/
extern inline void Ad3DVectorScalarMultiply(Vector3D* vector, double value)
{
	double* array;
	
	array = vector->vector;
	array[0] *= value;
	array[1] *= value;
	array[2] *= value;
}

/**
 \param vector_one Pointer to a Vector3D struct
 \param vector_two Pointer to a Vector3D structs
 \return The dot product of the two vectors
 **/
extern inline double Ad3DDotProduct(Vector3D* vector_one, Vector3D* vector_two)
{
	register int i;
	double product;
	
	for(product = 0, i=3; --i>=0;)
		product += vector_one->vector[i] * vector_two->vector[i];
	
	return product;
}

/**
 Calculates the cross product of two vectors.
 \param v_one Pointer to a Vector3D struct.
 \param v_two Pointer to a Vector3D struct.
 \param result Pointer to a Vector3D struct where the result vector will be stored.
 **/
extern inline void Ad3DCrossProduct(Vector3D* v_one, Vector3D* v_two, Vector3D* result)
{
	//calculate the cross product of the two vectors v_one X v_two
	result->vector[0] = v_one->vector[1]*v_two->vector[2] - v_one->vector[2]*v_two->vector[1];
	result->vector[1] = v_one->vector[2]*v_two->vector[0] - v_one->vector[0]*v_two->vector[2]; 
	result->vector[2] = v_one->vector[0]*v_two->vector[1] - v_one->vector[1]*v_two->vector[0];
}

/**
 Calculates the length of the vector represented by Vector3D.
 struct vector and then assigns the result to vector->length.
 \param vector A pointer to a Vector3D struct.
 **/
extern inline void Ad3DVectorLength(Vector3D* vec)
{
	(vec->length) =  *(vec->vector) * *(vec->vector) + *(vec->vector + 1) * *(vec->vector + 1); 
	(vec->length) += *(vec->vector + 2) * *(vec->vector + 2);
	
	(vec->length) = sqrt(vec->length);
}

/**
 Gets squared length
 */
extern inline void Ad3DVectorLengthSquared(Vector3D* vec)
{
	(vec->length) =  *(vec->vector) * *(vec->vector) + *(vec->vector + 1) * *(vec->vector + 1); 
	(vec->length) += *(vec->vector + 2) * *(vec->vector + 2);
}

#else

//Non-inline declarations of the above functions

void Ad3DVectorInit(Vector3D* vector);
double Ad3DDotProduct(Vector3D*, Vector3D*);
void Ad3DCrossProduct(Vector3D*, Vector3D*, Vector3D*);
void Ad3DVectorLength(Vector3D* vec);
int AdCartesianDistanceCheck(double* position1, double* position2, double separation);
int AdCartesianDistanceVectorCheck(Vector3D* separation, double distance);
void Ad3DVectorScalarMultiply(Vector3D* vector, double value);
void Ad3DVectorLengthSquared(Vector3D* vec);

#endif


/**
Allocates a matrix of Vector3D structs
*/
Vector3D** AdAllocate3DVectorMatrix(unsigned int numberOfRows, unsigned int numberOfColumns);

/**
 Frees a matrix of Vector3D structs.
 It must have been allocated using AdAllocate3DVectorMatrix().
 */
void AdFree3DVectorMatrix(Vector3D** matrix);

/**
Finds the unit vector related to a given vector.
\param vector A pointer to a Vector3D struct.
\param unit_vector Pointer to the Vector3D struct where the unit vector is to be stored. 
**/
void AdGet3DUnitVector(Vector3D*, Vector3D*);

/**
In essence generates uniformly distributed points on the unit sphere using \e generator
via the trig-method.
\param vector Pointer to a Vector3D struct in which the result will be placed
\param generator Pointer to a previously allocated gsl_rng instance which will be used
to generate the necessary random numbers.
*/
void AdGetRandom3DUnitVector(Vector3D* vector, gsl_rng* generator);

/**
Return the index of the minimium element in a standard double array.
If there is more than one entry with the same value the smallest index is returned
**/
int AdDoubleArrayMin(double*, int);
/**
Return the index of the maximum element in a standard double array.
If there is more than one entry with the same value the smallest index is returned
**/
int AdDoubleArrayMax(double*, int);

void AdIntArrayIntersectionAndDifference(IntArrayStruct *prime, IntArrayStruct *query, IntArrayStruct *intersection, IntArrayStruct *complement);
void AdIntArrayIntersection(IntArrayStruct *prime, IntArrayStruct *query, IntArrayStruct *intersection);
void AdIntArrayDifference(IntArrayStruct *prime, IntArrayStruct *query, IntArrayStruct *difference);

/** \@}**/

#endif

