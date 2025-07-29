/* Copyright 2005-2006  Alexander V. Diemand

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


#ifndef MTQUATERNION_OH
#define MTQUATERNION_OH
 

#include <Foundation/Foundation.h>

@class MTMatrix44;
@class MTCoordinates;

/*
 *   class Quaternion reprents a quaternion (x,y,z,w)
 *
 */
@interface MTQuaternion : NSObject
{
	double x,y,z,w;
}

/* access */
-(NSString*)toString;
-(NSString*)description;
-(double)x;
-(double)y;
-(double)z;
-(double)w;
-(MTMatrix44*)rotationMatrix;
-(MTQuaternion*)invert;

/* operation */
-(id)normalize;
-(id)rotate:(double)phi;
-(id)multiplyWith: (MTQuaternion*)q2;

/* creation */
+(MTQuaternion*)identity;
+(MTQuaternion*)rotation:(double)phi aroundAxis:(MTCoordinates*)axis;



@end

#endif /* MTQUATERNION_OH */

