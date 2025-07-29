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

#ifndef ADVOLUME_FUNCTIONS
#define ADVOLUME_FUNCTIONS

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <Base/AdVector.h>
#include <Base/AdMatrix.h>
#include <Base/AdLinkedList.h>

/**
 These are the functions for calculating volume function related quantitites and their derivatives.
 \defgroup VolumeFunctions Volume Functions.

The functions are: 

The <b>Atomic Volume Exclusion (AVE) Function </b> - \f$ H(|\mathbf{r} - \mathbf{r_{a}}|) \f$.
This is sometimes written as \f$ H(| \mathbf{r_{r}} |) \f$ where 
\f[
\mathbf{r_{r}} = \mathbf{r} - \mathbf{r_{a}} 
\f]
That is \f$ \mathbf{r_{r}} \f$ denotes the point \f$ \mathbf{r} \f$ relative to \f$ \mathbf{r_{a}} \f$.
Some of the AVE related functions take \f$ \mathbf{r_{r}} \f$ as an arguement when the exact positions
\f$ \mathbf{r_{a}} \f$ and \f$ \mathbf{r} \f$ are not needed.

The <b> Volume Exclusion Function </b>  - \f$ \mathcal{H}(\mathbf{r}; \{\mathbf{r_{a}} \}) \f$

This is a function of a point and the positions \f$\{\mathbf{r_{a}} \} \f$ of every atom in the solute.
\f[
\mathcal{H}(\mathbf{r}; \{\mathbf{r_{a}} \} = \prod_{a} H(|\mathbf{r} - \mathbf{r_{a}}|)
\f]

The <b> Volume Function </b>
\f[ v(\mathbf{r};\{\mathbf{r_{a}} \}) = 1 - \mathcal{H}(\mathbf{r}; \{\mathbf{r_{a}} \}) \f]
 
 \ingroup GBSWFunctions
 @{
 */

/**
 Precalculates some global variables which can greatly speed up the calculation.
 This avoids a large number of power and reciprocal calcs.
 */
void AdInitialiseGBSmoothingVariables(double value);

/**
 The Atomic Volume Exclusion Function (AVE) \f$ H(|r - r_{a}) \f$ is a function of the distance between an atom and a point ,\f$ r \f$.
 It measures how much an atom overlaps the point. If the atom completely overlaps the point it is 0, its
 1 if the atom does not overlap the point at all, and an intermediate value otherwise.
 The intermediate region is determined by the smoothing length.
 
 \note
 Here only the distance between the two points and the atoms radius is needed.
 However, although not explicit in the parameters, the AVE is a function of the position of the atom, \f$ r_{a} \f$, 
 and the position of the point, r.
 \todo
 Change to take vector argument.
 Its possible to avoid a number of sqrt operations if we know the distance to the point along each cartesian axis.double
 */
double AdAtomicVolumeExclusionFunction(double separation, double radius);

/**
New version of AdAtomicVolumeExclusionFunction() with built in optmised checking of
the separation between the points.
On return \e separation contains the separation vector.
However the length memeber of this structure is only set if the return value of the function
is not 0 or 1. 

\e partial is true if the return value is not 1 or 0.
\e overlap is true if the value is 0.
*/
double AdAtomicVolumeExclusionFunctionNew(double* atomPosition, double* pointPosition, 
			double radius, Vector3D* separation, bool *partial, bool *overlap);

/**
 Derivative of the atomic volume exclusion function of an atom with respect to the point where the function is being calculated.
 That is
 \f[
 \frac{ dH(|\mathbf{r} - \mathbf{r_{a}}|)}{d\mathbf{r}}
 \f]
 
 This is equivalent to the gradient of the function at the point (AdAtomicVolumeExclusionFunctionGradient()).
 Therefore the \e relativePosition is the parameter.
 This function is simply a wrapper to aid in simulating a mathematical sequence of events where the
 above quantity enters rather then grad(H(r)).
 
 This can be seen simply since 
 \f[
 \frac{ d(|\mathbf{r} - \mathbf{r_{a}})|}{d\mathbf{r}} = \frac{d(|\mathbf{r} - 
 \mathbf{r_{a}}|)}{d (\mathbf{r} - \mathbf{r_{a}})} = \frac{ d|\mathbf{r_{r}}|}{d\mathbf{r_{r}}}
 \f]
 
 The gradient is zero if \f$ \mathbf{r} \f$ is outside the smoothing region of the atom.
 */
double AdAVEFunctionPositionDerivative(Vector3D* relativePosition, double radius, Vector3D* gradientVector);

/**
 Derivative of the atomic volume exclusion function of an atom at a certain point with respect to the atoms position, \f$ \mathbf{r_{a}} \f$.
 That is
 \f[
 \frac{ dH(|\mathbf{r} - \mathbf{r_{a}}|}{d\mathbf{r_{a}}}
 \f] 
 
 This is simply \f$ -\nabla{H(|\mathbf{r_{m}} |)} \f$ (see AdAtomicVolumeExclusionFunctionGradient()).
 The gradient at the point is away from the center of the atom i.e. \f$ H(|\mathbf{r_{m}} |) \f$ increases as r get further away.
 The derivative at the atom points away from the point i.e. \f$ H(|\mathbf{r_{m}} |) \f$ increase as the atom moves away from r.
 Both have the same magnitude.
 
 The gradient is zero if \f$ \mathbf{r} \f$ is outside the smoothing region of the atom.
 */
void AdAVEFunctionAtomDerivative(Vector3D* relativePosition, double radius, Vector3D* gradientVector);


/**
 Calculates the gradient of the atomic volume exclusion function at \e relativePosition from an atom with radius \e radius.
 Note \e position is the relative position vector, \f$ \mathbf{r_{r}} \f$.
 \f[
 \frac{ dH(|\mathbf{r_{r}}|)}{d\mathbf{r_{r}}} = \frac{ dH(|\mathbf{r} - \mathbf{r_{a}}|)}{d(\mathbf{r} - \mathbf{r_{a}})}
 \f]
 
 The gradient is zero if \f$ \mathbf{r_{r}} \f$ is outside the smoothing region.
  \note This function does not calculate the gradient magnitude (the vector norm)
   However the length member of the vector is guaranteed to be only 0 when the magnitude is 0.
 */ 
void AdAtomicVolumeExclusionFunctionGradient(Vector3D* relativePosition, double radius, Vector3D* gradient);


/**
 Calculates the value of the volume exclusion function at a point, \f$ \mathbf{r} \f$, due to the solute environment 
 defined by \e coordinates and \e radii.
 This function returns 0 if any atom completly overlaps the point and 1 if no atom overlaps the point in any way.
 Otherwise some intermediate value is returned expressing the level of overlap.
 The boundaries defining no-overlap and complete overlap are given by the smoothing length;
 
 The array \e neighbourIndexes contains the indexes of the atoms which are close enough to \f$ \mathbf{r} \f$ to affect the calculation.
 That is the return value of AdAtomicVolumeExclusionFunction for these atoms is \e not likely to be 1.
 If this is NULL then all atoms in \e coordinates are used.
 
 Following from the above numberNeighbours is 0 then the result is 1 (No atom is near the point, so nothing overlaps it).
 
 \e radii is an array containing the radii to use for the atoms. Each entry in radii must correspond to the rows in \e coordinates.
 */
double AdVolumeExclusionFunction(Vector3D* r, AdMatrix* coordinates, int* neighbourIndexes, int numberNeighbours, double* radii);

/**
As the standard VEF but on return, if the function is not 0 or 1,\e contributingAtoms contains
the indexes of the atoms who parially overlap the point.
This version does not check for NULL \e neighbourIndexes
*/
double AdVolumeExclusionFunction2(Vector3D* r, AdMatrix* coordinates, 
					 int* neighbourIndexes, int numberNeighbours, double* radii, 
					 IntArrayStruct* contributingAtoms);
/**
 This is simply 1 - volume exclusion function at the point, \f$ \mathbf{r} \f$
 */
double AdVolumeFunction(Vector3D* r, AdMatrix* coordinates, int* neighbourIndexes, int numberNeighbours, double* radii);


/**
 The derivative of the volume function at point \f$ \mathbf{r} \f$ with respect to the position, \f$ \mathbf{r_{\beta}} \f$, 
 of the atom defined by \e atomIndex.
 \f[
 \frac{ dv( \mathbf{r}; \{ \mathbf{r_{a}} \} ) } {d \mathbf{r_{\beta}} }
 \f]
 In this case \f$ \mathbf{r} \f$ is a function of the atoms position,
 \f[
 \frac{ dv( \mathbf{r_{\beta}} + \mathbf{r_{m}}; \{\mathbf{r_{a}} \} ) } {d \mathbf{r_{\beta}}}
 \f]

\note This function does not calculate the gradient magnitude (the vector norm)
 However the length member of the vector is guaranteed to be only 0 when the magnitude is 0.
 
 \note If the volume exclusion function, \f$ \mathcal{H}(\mathbf{r_{\beta}} + \mathbf{r_{m}}; \{\mathbf{r_{a}} \} \f$
 is 0 then the gradient is zero. That is if the point is overlapped by an atom.
 Similarly no atoms parially overlap the point then the volume function is a constant and the gradient is 0.
*/
void AdVolumeFunctionAtomDerivative(unsigned int atomIndex, Vector3D* r, AdMatrix* coordinates, 
					   IntArrayStruct* contributingAtoms, double exclusionValue, 
					   double* radii, Vector3D* gradientVector);
	
/**
 The derivative of the volume function at point \e r with respect to the position, \f$ \mathbf{r_{\beta}} \f$, of \e atom.
 \f[
 \frac{ dv( \mathbf{r}; \{ \mathbf{r_{a}} \} ) } {d \mathbf{r_{\beta}} }
 \f] 
 In this case \f$ \mathbf{r} \f$ is \e not a function of the position of \e atom and hence this is considered the position derivative.
 On return \e gradientVector contains the vector derivative.
 \note This function does not calculate the gradient magnitude (the vector norm).
 However the length member of the vector is guaranteed to be only 0 when the magnitude is 0.
 
 \note The value of the volume exclusion function at the point must be provided.
 This is an optimisation - usually this function will be calculated for a number of atoms at the same
 point so its advantageous to only have to calculate the volume exclusion function value once.
 
 If the volume exclusion function, \f$ \mathcal{H}(\mathbf{r_{\beta}} + \mathbf{r_{m}}; \{\mathbf{r_{a}} \} \f$
 is 0 then the gradient is zero. That is if the point is overlapped by the atom.
 It is also zero if the point is outside the smoothing region of \e atom.
 Therefore passing 0.0 for \e volumeExclusionValue causes this function to return immediately.
 */
 void AdVolumeFunctionPositionDerivative(unsigned int atom, Vector3D* r, AdMatrix* coordinates, 
		double volumeExclusionValue, double* radii, Vector3D* gradient);

/** \@}**/

#endif


