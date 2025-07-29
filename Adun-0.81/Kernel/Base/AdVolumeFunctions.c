/*
 Project: AdunBase
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
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

#include "AdVolumeFunctions.h"

static double smoothingLength;
static double smoothingConstantA;
static double smoothingConstantB;

/*
 Precalculates some global variables which can greatly speed up the calculation.
 This avoids a large number of power and reciprocal calcs.
 */
void AdInitialiseGBSmoothingVariables(double value)
{
	smoothingLength = value;
	smoothingConstantA = 3/(4*smoothingLength);
	smoothingConstantB = 1/(4*pow(smoothingLength, 3));	
}	

/*
 Calculates the contribution to the atomic exclusion function for a point a distance
 \e separation from an atom which has PB radius \e radius.
 */
 double AdAtomicVolumeExclusionFunction(double separation, double radius)
{ 
	double lower, upper, difference, value;
	
	lower = radius - smoothingLength;
	//If the atom is closer than the lower boundary return 0
	if(separation < lower)
		return 0;
	
	//If its further than the upper boundary return 1
	upper = radius + smoothingLength;
	if(separation > upper)
		return 1;
	else
	{	
		//Find how far the atom is from the boundary defined by the radius
		difference = separation - radius;
		value = 0.5 + smoothingConstantA*difference - smoothingConstantB*pow(difference, 3);
	}
	
	return value;
}

 double AdAtomicVolumeExclusionFunctionNew(double* atomPosition, 
		double* pointPosition, 
		double radius, 
		Vector3D* separation, 
		bool *partial, bool* overlap)
{ 
	double lower, upper, difference, value, length;
	double* vec;
	
	*partial = false;
	*overlap = false;
	vec = separation->vector;
	vec[0] = pointPosition[0] - atomPosition[0];
	vec[1] = pointPosition[1] - atomPosition[1];
	vec[2] = pointPosition[2] - atomPosition[2];
	
	//If its further than the sqrt(3)*(upper boundary) return 1
	//This is 1.5*(upperBoundary)
	upper = radius + smoothingLength;
	if((AdCartesianDistanceVectorCheck(separation, upper)) == 0)
		return 1;
	
	//First do quick check for exclusion
	//If its closer than sqrt(3)/2*(lowerBoundary) return 0
	//This is 0.866*(lowerBoundary).
	//We can't use lower as the distance since this function
	//will then return 1 if the point is closer than 1.5*lower.
	//However in this case the point could be greater than lower.
	lower = radius - smoothingLength;
	if((AdCartesianDistanceVectorCheck(separation, 0.5*lower)) == 1)
	{
		*overlap = true;
		return 0;
	}
		
	//If we are still in the function we have to calculate 
	//the actual separation
	Ad3DVectorLengthSquared(separation);
	length = separation->length;
	
	if(length > upper*upper)
		return 1;
	
	//If the atom is closer than the lower boundary return 0
	if(length < lower*lower)
	{
		*overlap = true;
		return 0;
	}
		
	length = sqrt(length);
	separation->length = length;
	//Find how far the atom is from the boundary defined by the radius
	difference = length - radius;
	value = 0.5 + difference*(smoothingConstantA - smoothingConstantB*difference*difference);
	
	*partial = true;
	
	return value;
}

/*
 Derivative of the atomic volume exclusion function of an atom with respect to the point where the function is
 being calculated. That is
 \f[
 \frac{ dH(|r - r_{a}|}{dr}
 \f]
 
 The is equivalent to the gradient of the function at the point. 
 This function is simply a wrapper to aid in simulating a mathematical sequence of events where the
 above quantity enters rather then grad(H(r)).
 
 This can be seen simply since 
 \f[
 \frac{ d(|r - r_{a}|}{dr} = d(|r - r_{a}|)(d (r - r_{a})
 \f]
 */
 double AdAVEFunctionPositionDerivative(Vector3D* relativePosition, double radius, Vector3D* gradientVector)
{
	AdAtomicVolumeExclusionFunctionGradient(relativePosition, radius, gradientVector);
}

/*
 Derivative of the atomic volume exclusion function of an atom at a certain point with respect to the atoms position
 That is
 \f[
 \frac{ dH(|r - r_{a}|}{dr_{a}}
 \f] 
 
 This is actually -1*grad(H(r)).
 The gradient at the point is away from the center of the atom i.e. H(r) increases as r gets further away.
 The derivative at the atom points away from the point i.e. H(r) increases as the atom moves away from r.
 Both have the same magnitude.
 */
 void AdAVEFunctionAtomDerivative(Vector3D* relativePosition, double radius, Vector3D* gradientVector)
{	
	//The derivative w.r.t. to the position of the atom is the negative 
	//of the gradient of the exclusion function at the point. grad(H(|r_r|))
	AdAtomicVolumeExclusionFunctionGradient(relativePosition, radius, gradientVector);
	if(gradientVector->length != 0)
	{
		gradientVector->vector[0] *= -1;
		gradientVector->vector[1] *= -1;
		gradientVector->vector[2] *= -1;
	}
}

/*
 Returns the gradient of the atomic volume exclusion function at a point \e position from an atom.
 i.e the derivative w.r.t to the points position relative to the atom.
 */
 void AdAtomicVolumeExclusionFunctionGradient(Vector3D* relativePosition, double radius, Vector3D* gradient)
{
	int isZero = 0;
	double separation, difference, value;
	double* v1, *v2;
	
	separation = relativePosition->length;
	
	//If the atom is closer than the lower boundary the gradient is 0
	if(separation < (radius - smoothingLength))
		isZero = 1;
	else if(separation > (radius + smoothingLength))
		isZero = 1;
	
	v1 = gradient->vector;
	
	if(isZero == 1)
	{
		v1[0] = v1[1] = v1[2] = 0;
		gradient->length = 0;
	}
	else
	{	
		v2 = relativePosition->vector;
		//Find how far the atom is from the boundary defined by the radius
		difference = separation - radius;
		value = (smoothingConstantA - 3*smoothingConstantB*difference*difference)/separation;
		v1[0] = value*v2[0];
		v1[1] = value*v2[1];
		v1[2] = value*v2[2];
		//This is just to differentiate from 0.
		//We dont calculate the length to avoid unnecessary square roots
		gradient->length = 1;
	}
}

/*
 Calculates the value of the volume exclusion function at a point, r, due to the solute environment defined by \e coordinates and \e radii. 
 This function returns 0 if any atom completly overlaps the point; 
 1 if no atom overlaps the point in any way.
 Otherwise some intermediate value is returned expressing the level of overlap.
 The boundaries defining no-overlap and complete overlap are given by the smoothing length;
 
 The array \e neighbourIndexes contains the indexes of the atoms which are
 close enough to \e r to affect the calculation - if this is NULL all the atoms are used.
 That is the return value of AdAtomicVolumeExclusionFunction for these atoms is \e not
 likely to be 1.
 
 The atomic volume function depends on the definition of the point.
 Usually the point is determined relative to a certain atom, a. 
 Therefore the function depends on the position of a, and the position of all other atoms.
 */
 double AdVolumeExclusionFunction(Vector3D* r, AdMatrix* coordinates, int* neighbourIndexes, int numberNeighbours, double* radii)
{
	bool partial, overlap;
	int i, j, index;
	double retVal, value, smoothingBoundary, checkVal;
	double** matrix;
	Vector3D vector;	
	
	//If numberNeighbours is 0 then the volume exclusion function is 1.
	//i.e. no atoms overlap the point at all. It is completly in the solvent.
	if(numberNeighbours == 0)
		return 1.0;
	
	//Dereference the coordinates matrix;
	matrix = coordinates->matrix;
	
	//If a neighbour array is passed used it.
	if(neighbourIndexes != NULL)
	{
		for(retVal = 1, i=0; i<numberNeighbours; i++)
		{
			index = neighbourIndexes[i];
			value = AdAtomicVolumeExclusionFunctionNew(coordinates->matrix[index], 
					r->vector, 
					radii[index],
					&vector, &partial, &overlap);				
					
			//Since the value of the exclusion function is a product of the 
			//atomic exclusion functions, if any of these are 0 then the total is also 0.
			//Thus we can break out of this loop if this happens.
			
			if(overlap)
			{
				retVal = 0;
				i = numberNeighbours;
				
			}
			else if(partial)
			{
				retVal *= value;
			}
		}
	}
	else
	{
		for(retVal = 1, i=0; i<coordinates->no_rows; i++)
		{
			value = AdAtomicVolumeExclusionFunctionNew(coordinates->matrix[i], 
								   r->vector, 
								   radii[i],
								   &vector, &partial, &overlap);
		
			//Since the value of the exclusion function is a product of the atomic exclusion functions
			//If any of these are 0 then the total is also 0.
			//Thus we can break out of this loop if this happens.
			if(partial)
			{
				retVal *= value;
			}
			else if(overlap)
			{
				retVal = 0;
				break;
			}
		}
	}
	
	return retVal;
}

/**
Ad AdVolumeExclusionFunction but also returning the atoms that contribute the function that
aren't 0 or 1.
If the function is 0 the length of this array is 0.
*/
 double AdVolumeExclusionFunction2(Vector3D* r, AdMatrix* coordinates, 
		int* neighbourIndexes, int numberNeighbours, double* radii, IntArrayStruct* contributingAtoms)
{
	bool partial, overlap;
	int i, j, index, count;
	double retVal, smoothingBoundary, checkVal;
	double** matrix;
	Vector3D separation;	
	//Variables for manually d AdAtomicVolumeExclusionFunctionNew()
	double lower, upper, difference;
	double atomicExclusionValue, length, radius;
	double* atomPosition, *pointPosition;
	
	//If numberNeighbours is 0 then the volume exclusion function is 1.
	//i.e. no atoms overlap the point at all. It is completly in the solvent.
	if(numberNeighbours == 0)
		return 1.0;
	
	//Dereference the coordinates matrix;
	matrix = coordinates->matrix;
	pointPosition = r->vector;
	
	//If a neighbour array is passed used it.
	for(count = 0, retVal = 1, i=0; i<numberNeighbours; i++)
	{
		index = neighbourIndexes[i];
	
		/******* Manual Inline ************/
		
		atomPosition = matrix[index];
		radius = radii[index];
		
		separation.vector[0] = pointPosition[0] - atomPosition[0];
		separation.vector[1] = pointPosition[1] - atomPosition[1];
		separation.vector[2] = pointPosition[2] - atomPosition[2];
		
		partial = false;
		overlap = false;
		
		upper = radius + smoothingLength;
		if((AdCartesianDistanceVectorCheck(&separation, upper)) == 0)
		{
			atomicExclusionValue = 1;
		}
		else
		{	
			lower = radius - smoothingLength;
			if((AdCartesianDistanceVectorCheck(&separation, 0.5*lower)) == 1)
			{
				atomicExclusionValue = 0;
				overlap = true;
			}
			else
			{
				Ad3DVectorLengthSquared(&separation);
				length = separation.length;
				if(length > upper*upper)
				{
					atomicExclusionValue = 1;
				}
				else if(length < lower*lower)
				{
					atomicExclusionValue = 0;
					overlap = true;
				}
				else
				{	
					partial = true;
					length = sqrt(length);
					separation.length = length;
					difference = length - radius;
					atomicExclusionValue = 0.5 + difference*(smoothingConstantA - 
										 smoothingConstantB*difference*difference);
				}
			}
		}
		
		/****************************/		
		
		//Since the value of the exclusion function is a product of the 
		//atomic exclusion functions, if any of these are 0 then the total is also 0.
		//Thus we can break out of this loop if this happens.
		//Also no need to multiply if value is 1.
		
		if(overlap)
		{
			retVal = 0;
			i = numberNeighbours;
			count = 0;
		}
		else if(partial)
		{
			retVal *= atomicExclusionValue;
			contributingAtoms->array[count] = index;
			count++;
		}
	}
	
	contributingAtoms->length  = count;
	
	return retVal;
}

/*
 This is simply 1 - volume exclusion function at the point, r.
 */
 double AdVolumeFunction(Vector3D* r, AdMatrix* coordinates, int* neighbourIndexes, int numberNeighbours, double* radii)
{
	return 1 - AdVolumeExclusionFunction(r, coordinates, neighbourIndexes, numberNeighbours, radii);
}

/*
 The derivative of the volume function at point \e r with respect to the position of \e atom.
 In this case r is a function of the atom position r = r_1 + r_m (hence atom)
 */
 void AdVolumeFunctionAtomDerivative(unsigned int atomIndex, Vector3D* r, AdMatrix* coordinates, 
		IntArrayStruct* contributingAtoms, double exclusionValue, double* radii, Vector3D* gradientVector)
{
	int i, index, numberAtoms;
	int* array;
	double atomicExclusionValue, holder;
	double **matrix;
	Vector3D vector, separation;
	//Variables for manually d AdAtomicVolumeExclusionFunctionNew()
	double lower, upper, difference;
	double value, length, radius;
	double* atomPosition, *pointPosition, *vec;

	numberAtoms = contributingAtoms->length;
	//If the numberNeighbours is 0 then the gradient is 0.
	if(numberAtoms == 0)
	{
		Ad3DVectorInit(gradientVector);
		return;
	}
		
	vec = gradientVector->vector;	
		
	//Loop over all the atoms that contribute to the volume exclusion function at the point.
	//Calculating the position derivative of each atom NOT including the atom the derivative is with respect too
	matrix = coordinates->matrix;
	array = contributingAtoms->array;
	for(i=0; i<numberAtoms; i++)
	{
		index = array[i];
		
		//Skip the atom this derivative is w.r.t
		if((unsigned int)index == atomIndex)
			continue;
		
		//Calculate the atomic exclusion function value for the current at the point.
		//As below the compiler will not  the AVEF function and calls to
		//are generating a massing overhead (25% of time in function) 
		//- so I have manually d it.
		
		/******* Manual Inline ************/
		
		atomPosition = matrix[index];
		pointPosition = r->vector;
		radius = radii[index];
		
		separation.vector[0] = pointPosition[0] - atomPosition[0];
		separation.vector[1] = pointPosition[1] - atomPosition[1];
		separation.vector[2] = pointPosition[2] - atomPosition[2];
		
		upper = radius + smoothingLength;
		if((AdCartesianDistanceVectorCheck(&separation, upper)) == 0)
		{
			atomicExclusionValue = 1;
		}
		else
		{	
			lower = radius - smoothingLength;
			if((AdCartesianDistanceVectorCheck(&separation, 0.5*lower)) == 1)
			{
				atomicExclusionValue = 0;
			}
			else
			{
				Ad3DVectorLengthSquared(&separation);
				length = separation.length;
				if(length > upper*upper)
				{
					atomicExclusionValue = 1;
				}
				else if(length < lower*lower)
				{
					atomicExclusionValue = 0;
				}
				else
				{	
					length = sqrt(length);
					separation.length = length;
					difference = length - radius;
					atomicExclusionValue = 0.5 + difference*(smoothingConstantA - 
								smoothingConstantB*difference*difference);
				}
			}
		}
		
		/****************************/
	
		//If the atomicExclusionValue is 0 for any atom
		//Then the volumeExclusionValue will be 0 and hence the
		//gradient will be zero.							  
		if(atomicExclusionValue < 1E-10)
		{
			Ad3DVectorInit(gradientVector);
			return;
		}
									  							  
		//For each atom, not including a, calculate the derivative of their
		//atomic volume exclusion function at the point with respect to the point
		//However if the atomicExclusionValue of the atom is 1 skip it
		//since its gradient will be zero.
		if(atomicExclusionValue < 1)
		{
			AdAVEFunctionPositionDerivative(&separation, radii[index], &vector);
		
			holder = 1/atomicExclusionValue;
			Ad3DVectorScalarMultiply(&vector, holder);
			vec[0] += vector.vector[0];
			vec[1] += vector.vector[1];
			vec[2] += vector.vector[2];
		}
	}
	
	//The minus changes this to volume function derivative.
	Ad3DVectorScalarMultiply(gradientVector, -exclusionValue);
}

/*
 The derivative of the volume function at point \e r with respect to the position of \e atom.
 In this case r is not a function of the position of \e atom and hence this is considered the position derivative.
 
 This only has a value if no atom completely overlaps this point AND if the point lies within
 the smoothing region of \e atom.
*/
 void AdVolumeFunctionPositionDerivative(unsigned int atom, Vector3D* r, AdMatrix* coordinates, 
		double volumeExclusionValue, double* radii, Vector3D* gradient)
{
	double atomicExclusionValue;
	double factor;
	Vector3D separation;
	
	//If the volumeExclusionValue is zero then the gradient is zero.
	//That is some other atom completely overlaps the point.
	if(volumeExclusionValue == 0)
	{
		Ad3DVectorInit(gradient);
		return;
	}
	
	//r_m is the relative position vector
	//Calculate the value of the AVE of atom at the point r
	//H(|r - r_1|)
	//NOTE: The compiler will not  AdAtomicVolumeExclusionFunctionNew
	//and since it is called very often this is generating a large overhead.
	//Hence its code is implemented directly here.
	//Looks slightly different due to inlining needs - check original for docs.
	
	/******* Manual Inline ************/
	
	double lower, upper, difference;
	double value, length, radius;
	double* atomPosition, *pointPosition;
	
	atomPosition = coordinates->matrix[atom];
	pointPosition = r->vector;
	radius = radii[atom];
	
	separation.vector[0] = pointPosition[0] - atomPosition[0];
	separation.vector[1] = pointPosition[1] - atomPosition[1];
	separation.vector[2] = pointPosition[2] - atomPosition[2];
	
	upper = radius + smoothingLength;
	if((AdCartesianDistanceVectorCheck(&separation, upper)) == 0)
	{
		atomicExclusionValue = 1;
	}
	else
	{	
		lower = radius - smoothingLength;
		if((AdCartesianDistanceVectorCheck(&separation, 0.5*lower)) == 1)
		{
			atomicExclusionValue = 0;
		}
		else
		{
			Ad3DVectorLengthSquared(&separation);
			length = separation.length;
			if(length > upper*upper)
			{
				atomicExclusionValue = 1;
			}
			else if(length < lower*lower)
			{
				atomicExclusionValue = 0;
			}
			else
			{	
				length = sqrt(length);
				separation.length = length;
				difference = length - radius;
				atomicExclusionValue = 0.5 + difference*(smoothingConstantA - 
							smoothingConstantB*difference*difference);
			}
		}
	}
		
	/****************************/
	
	//If the atomicExclusionValue is 1 OR 0 the gradient is 0 so
	//we can exit early.
	//That is this point does not lie in the smoothing region
	//of this atom.
	//Note we use direct comparison of doubles since we
	//are assured that exactly 1 or 0 will be returned in the
	//cases that the exclusion function has these values.
	if(atomicExclusionValue == 1 || atomicExclusionValue == 0)
	{
		Ad3DVectorInit(gradient);
		return;
	}
		
	//The derivative of the AVE of the atom at the point with respect to
	//the atom position. Note this could normally be zero, but if so
	//we would have exitied already.
	AdAVEFunctionAtomDerivative(&separation, radii[atom], gradient);
	
	//Factor is the exclusion function minus the contribution of \e atom.
	factor = volumeExclusionValue/atomicExclusionValue;
	
	//The final gradient magnitude is -factor*gradient.
	//The minus is because this is the volume function derivative NOT the volume exclusion function derivative
	Ad3DVectorScalarMultiply(gradient, -factor);
}

