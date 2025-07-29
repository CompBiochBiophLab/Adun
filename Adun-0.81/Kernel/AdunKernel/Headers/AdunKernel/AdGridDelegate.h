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
#ifndef _ADGRID_DELEGATE
#define _ADGRID_DELEGATE
#include <Foundation/Foundation.h>

/**
\ingroup Protocols
Defines the interace for AdGrid delegate objects. AdGrid delegates provide
information about the cavity in which the grid is created and exists.
\todo To integrate better with other objects and the actual cavity implementations
cavityCentre() should be changed to return an NSArray and a new method
centreAsVector added for returning the Vector3D struct.
This is because the use of cavityCentre in all the adopters of the protocol is
usually associated with an array e.g. initWithCavityCentre: setCavityCentre: etc.
**/

@protocol AdGridDelegate
/**
Returns the volume of the cavity. This method is should return -1 if the delegate does not know the volume.
If this is the case then AdGrid::gridWithDensity:cavity: can not be used*/
- (double) cavityVolume;
/**
Returns YES if the point specfied by \e point is in the cavity.
*/
- (BOOL) isPointInCavity: (double*) point;
/**
Returns an Vector3D  containing the center of the cavity. The object will intially use this point to generate the grid.
\todo Rename to centreAsVector.
*/
- (Vector3D*) cavityCentre;
/**
Returns the extremes of the cavity as 3 NSArrays each with the extremal values for the x,y, and z axis respectively.
*/
- (NSArray*) cavityExtremes;
@end

#endif
