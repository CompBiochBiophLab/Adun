/*
 Project: AdunKernel
 
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
#ifndef _ADUN_CUBOID_BOX_
#define _ADUN_CUBOID_BOX_

#include "Base/AdVector.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunGrid.h"

/**
 \ingroup Inter
 AdCuboidBox objects define a rectangular volume. (a cuboid).
 They conform to the AdGridDelegate protocol and are for use with AdGrid.
 */

@interface AdCuboidBox: NSObject <AdGridDelegate, NSCoding>
{	
	id environment;
	double xDim;			//!< x-axis dimension
	double yDim;			//!< y-axis dimension
	double zDim;			//!< z-axis dimension
	double cuboidVolume;		//!< the volume of the box
	Vector3D cuboidCentre;		//!< centre of the box as Vector3D
	NSArray* centre;		//!< centre of box as NSArray
	NSArray* cuboidExtremes;
}
/**
 As initWithCavityCentre:xDimension:yDimension:zDimension: with all dimensions set to 20
 and the centre at the origin.
 */
- (id) init;
/**
 Initialises a new AdCuboidBox instance. 
 \param centre The position of the centre of the cuboid (arbitrary units). An array of three NSNumbers.
 \param xDim The length of the cuboid along the x axis.
 \param yDim The length of the cuboid along the y axis
 \param zDim the length of the cuboid along the z axis.
 */
- (id) initWithCavityCentre: (NSArray*) centre 
	xDimension: (double) dim1 
	yDimension: (double) dim2 
	zDimension: (double) dim3;
/**
 Sets the cavity centre to be the point defined by \e array
 \param array An array of doubles defining the center of the cavity.
 If \e array does not have three elements the center is set to the origin.
 If the object has been set as the delegate of an AdGrid instance you need
 to call AdGrid::cavityDidMove to update it after using this method.
 */
- (void) setCavityCentre: (NSArray*) array;
/**
 Returns an array containing the dimensions of the cuboid along each axis.
 */
- (NSArray*) dimensions;
/**
 Sets the x dimension length to \e value. \e value must be
 greater than zero. If not an NSInvalidArgumentException is
 raised.
 */
- (void) setXDimension: (double) value;
/**
 Sets the y dimension length to \e value. \e value must be
 greater than zero. If not an NSInvalidArgumentException is
 raised.
 */
 - (void) setYDimension: (double) value;
/**
 Sets the z dimension length to \e value. \e value must be
 greater than zero. If not an NSInvalidArgumentException is
 raised.
 */
- (void) setZDimension: (double) value;
/**
Returns the cavity centre as an NSArray
*/
- (NSArray*) centre;
@end

#endif

