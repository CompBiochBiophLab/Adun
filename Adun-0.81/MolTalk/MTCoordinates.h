/* Copyright 2003-2006  Alexander V. Diemand

    This file is part of MolTalk.

    MolTalk is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    MolTalk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with MolTalk; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 */
 
/* vim: set filetype=objc: */


#ifndef MTCOORDINATES_H
#define MTCOORDINATES_H


#include <Foundation/Foundation.h>

#include "MTVector.h"

@class MTMatrix53;
@class MTMatrix44;


@interface MTCoordinates: MTVector
{
}

/*
 *   calculate distance
 */
-(double)distanceTo:(MTCoordinates*)c2;
-(double)distanceToLineFrom:(MTCoordinates*)v2 to:(MTCoordinates*)v3;

/*
 *   setter
 */
-(id)setX:(double)newx Y:(double)newy Z:(double)newz;

/*
 *   getters
 */
-(double)x;
-(double)y;
-(double)z;

/*
 *   transform this coordinates
 */
-(id)transformBy: (MTMatrix53*)m;
-(id)rotateBy:(MTMatrix44*)m;
-(id)translateBy:(MTVector*)v;

-(MTMatrix44*)alignToZaxis;

/*
 *   creation
 */
+(MTCoordinates*)origin;
+(MTCoordinates*)coordsWithX:(double)x Y:(double)y Z:(double)z;
+(MTCoordinates*)coordsFromCoordinates:(MTCoordinates*)p_coords;
+(MTCoordinates*)coordsFromVector:(MTVector*)p_vect;
-(id)copy;


@end

#endif /* MTCOORDINATES_H */

