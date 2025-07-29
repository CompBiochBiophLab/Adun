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


#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <Foundation/Foundation.h>

#include "MTQuaternion.h"
#include "MTMatrix44.h"
#include "MTCoordinates.h"


@implementation MTQuaternion


-(id)init	//@nodoc
{
	[super init];
	x=y=z=0.0;
	w=1.0;
	return self;
}


-(void)dealloc	//@nodoc
{
	[super dealloc];
}


/* access */
-(NSString*)toString
{
	return [NSString stringWithFormat: @"Quaternion(%1.3f,%1.3f,%1.3f,%1.3f)",x,y,z,w];
}

-(NSString*)description
{
	return [self toString];
}

-(double)x { return x; }
-(double)y { return y; }
-(double)z { return z; }
-(double)w { return w; }

/*
 *   return rotation matrix
 */
-(MTMatrix44*)rotationMatrix;
{
	MTMatrix44 *res = [MTMatrix44 matrixIdentity];
	[res atRow: 0 col: 0 value:  (1.0 - (2.0 * ((y * y) + (z * z))))];
	[res atRow: 1 col: 0 value: (2.0 * ((x * y) + (z * w)))];
	[res atRow: 2 col: 0 value: (2.0 * ((x * z) - (y * w)))];
	[res atRow: 0 col: 1 value: (2.0 * ((x * y) - (z * w)))];
	[res atRow: 1 col: 1 value: (1.0 - (2.0 * ((x * x) + (z * z))))];
	[res atRow: 2 col: 1 value: (2.0 * ((y * z) + (x * w)))];
	[res atRow: 0 col: 2 value: (2.0 * ((x * z) + (y * w)))];
	[res atRow: 1 col: 2 value: (2.0 * ((y * z) - (x * w)))];
	[res atRow: 2 col: 2 value: (1.0 - (2.0 * ((x * x) + (y * y))))];
	return res;
}


/*
 *   return the inverted quaternion
 */
-(MTQuaternion*)invert;
{
	MTQuaternion *res = [MTQuaternion identity];
	double len = (1.0 - (x*x + y*y + z*z + w*w));
	res->x = x - len;
	res->y = y - len;
	res->z = z - len;
	res->w = len;
	return res;
}


/*
 *   normalize
 */
-(id)normalize
{
	double magnitude=sqrt(x * x + y * y + z * z + w * w);
	x = x / magnitude;
	y = y / magnitude;
	z = z / magnitude;
	w = w / magnitude;
	return self;
}


/*
 *   combine this quaternion with a rotation
 */
-(id)rotate:(double)phi;
{
	MTQuaternion *q2 = [MTQuaternion rotation: phi aroundAxis: [MTCoordinates coordsWithX: x Y: y Z: z]];
	[self multiplyWith: q2];
	return self;
}


/*
 *   product between two quaternions
 */
-(id)multiplyWith: (MTQuaternion*)q2
{
	double x2,y2,z2,w2;
	x2 = [q2 x]; y2 = [q2 y]; z2 = [q2 z]; w2 = [q2 w];
	x = (w*x2 + x*w2 + y*z2 - z*y2);
	y = (w*y2 - x*z2 + y*w2 + z*x2);
	z = (w*z2 + x*y2 - y*x2 + z*w2);
	w = (w*w2 - x*x2 - y*y2 - z*z2);
	return self;
}


/*
 *   create a new quaternion
 */
+(MTQuaternion*)identity
{
	MTQuaternion *q = [MTQuaternion new];
	return AUTORELEASE(q);
}


+(MTQuaternion*)rotation:(double)phi aroundAxis:(MTCoordinates*)axis
{
	MTQuaternion *q = [MTQuaternion identity];
	double a = phi / 2.0;
	double sina = sin(a);
	q->w = cos(a);
	q->x = [axis x] * sina;
	q->y = [axis y] * sina;
	q->z = [axis z] * sina;
	return q;
}


@end

