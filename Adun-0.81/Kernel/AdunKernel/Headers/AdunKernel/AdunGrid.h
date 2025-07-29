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
#ifndef _ADGRID_
#define _ADGRID_

#include <math.h>
#include "Base/AdVector.h"
#include "Base/AdMatrix.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdunMatrixStructureCoder.h"

/**
\ingroup Inter
AdGrid instances represent a three dimensional cartesian grid in a volume defined by
the grids cavity delegate which must conform to the AdGridDelegate protocol. 
The spacing of the grid points is determined when the object is initialised. 
The units used by the object are dimensionless.

AdGrid implements the NSCoding protocol. It only supports keyed coding.

\todo Missing Functionality - Update resetCavity() or implement a cavityVolumeDidChange method
that keeps current points that are still in the cavity while adding new ones
and removing old ones. Such a method is required if you need the grid points
not to change during a volume change i.e. the grid spacing and centre is
fixed after creation. Using resetCavity as it currently is implemented
will result in a new grid being created which may not have the same characterisitics.
*/

@interface AdGrid: AdMatrixStructureCoder <NSCoding>
{
	@private
	//Optimisation vars - used for quick access
	int xTicks;
	int yTicks;
	int zTicks;
	double xSpacingR;
	double ySpacingR;
	double zSpacingR;
	double minPoint[3];	//!< The point with the minimum (x,y,z) values.
	//Ivars
	int gridPoints;
	AdMatrix* grid;
	int ticksPerAxis[3];
	double searchCutoff;
	Vector3D cavityCentre;
	NSArray* cavityExtremes;
	NSArray* gridSpacing;
	AdMemoryManager* memoryManager;
	id cavity;
}

/**
Creates a grid with the given density of points in the volume
defined by the delegate.
\todo Not implemented
*/
- (id) initWithDensity: (double) density cavity: (id) cavity;
/**
Creates a grid with the given number of ticks on each axis. The
tick spacing is defined by the cavity extremes.
\param An NSArray on integers specfying the ticks for each axis in the order x,y,z
\param cavity An object implementing the AdGridDelegate protocol
\todo Not implemented
*/
- (id) initWithDivisions: (NSArray*) divisions cavity: (id) cavity;
/**
As initWithSpacing: passing [1.0, 1.0, 1.0] for spacing.
*/
- (id) init;
/**
As initWithSpacing:cavity: passing nil for cavity.
\note No grid will be created until a cavity is supplied
*/
- (id) initWithSpacing: (NSArray*) spacing;
/**
Designated initialiser.
Creates a grid in the volume defined by \e cavity with the given spacing between ticks on each axis.
\param An NSArray of double specifying the spacing for each axis in the order x,y,z.
If nil the spacing defaults to one in each direction.
\param cavity An object implementing the AdGridDelegate protocol.
If nil the grid is not created. It will be created at the next call to setCavity: with a valid argument.
*/
- (id) initWithSpacing: (NSArray*) spacing cavity: (id) cavity;
/**
Returns an autoreleased AdGrid object containing a grid with the given density of points in the volume
defined by \e cavity.
*/
+ (id) gridWithDensity: (double) density cavity: (id) aCavity;
/**
Returns an autoreleased AdGrid object containing a grid with the given number of ticks on each axis.
 */
+ (id) gridWithDivisions: (NSArray*) divisions cavity: (id) aCavity;
/**
Returns an autoreleased AdGrid object containing a a grid with the given spacing between ticks on each axis.
*/
+ (id) gridWithSpacing: (NSArray*) spacing cavity: (id) aCavity;
/**
If the space defined by the cavity changes this message should be sent in order to update the grid.
Any objects that retain references to the grid matrix should acquire a new reference. 
The method can also be used if the cavity centre was changed. However in this case cavityDidMove() is more efficent.
If no cavity has been set this method does nothing.
*/
- (void) resetCavity;
/**
Should be sent on a change of cavity poisition. The grid object compares the old and new centers
and moves translates grid accordingly. If the volume defined by the cavity also changes you should use resetCavity instead.
This method does not affect the grid matrix references i.e. the pointer to grid matrix remains the same.
*/
- (void) cavityDidMove;
/**
Changes the grids cavity delegate to \e anObject which must conform to the AdGridDelegate protocol. If it does not
an NSInvalidArgumentException is raised. The old grid is freed (if it exists) and a new one is created.
*/
- (void) setCavity: (id) anObject;
/**
Returns the grid delegate.
*/
- (id) cavity;
/**
Returns the grid as an AdMatrix structure. The returned pointer will be invalidated
when the AdGrid instance is released, when a new cavity is set using setCavity:,
when resetCavity is called or when setSpacing is called.
*/
- (AdMatrix*) grid;
/**
Retuns the spacing between the point on each axis (dimensionless)
*/
- (NSArray*) spacing;
/**
Sets the grid spacing. If a cavity is set a grid is created with the supplied spacing. 
Any previous grids are destroyed.
*/
- (void) setSpacing: (NSArray*) anArray;
/**
Returns the number of divisions (ticks) on each axis.
*/
- (NSArray*) divisions;
/**
Returns the total number of grid points.
*/
- (int) numberOfPoints;
/**
Returns the index of the row in the grid matrix that is nearest to \e point.
However if \e point isn't within the searchCutoff() of any grid point i.e. its more than
this value away on every axis from the nearest grid point, this method returns -1.
Effectively this only returns a value if the point is within the volume covered by
the grid.
*/
- (int) indexOfGridPointNearestToPoint: (Vector3D*) point;
/**
As indexOfGridPointNearestToPoint:() but on return \e array contains the
x, y and z indexes of the grid point. 
That is the index of the x, y, z tick nearest to the point.
\e array must have space for three ints.
*/
- (int) indexOfGridPointNearestToPoint: (Vector3D*) point indexes: (int*) array;
/**
Sets the cutoff. Points outside the grid volume but within this cutoff 
will be be assigned to a grid point by indexOfGridPointNearestToPoint:().
*/
- (void) setSearchCutoff: (double) value;
/**
Returns the cutoff. Points outside the grid volume but within this cutoff 
will be be assigned to a grid point by indexOfGridPointNearestToPoint:().
*/
- (double) searchCutoff;
@end

#endif

