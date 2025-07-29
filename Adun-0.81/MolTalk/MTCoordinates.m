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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>


#include "MTCoordinates.h"
#include "MTMatrix53.h"
#include "MTMatrix44.h"



@implementation MTCoordinates


-(id)init	//@nodoc
{
	[super setDimensions: 4];
	[self atDim: 0 value: 0.0];
	[self atDim: 1 value: 0.0];
	[self atDim: 2 value: 0.0];
	[self atDim: 3 value: 1.0];
	return self;
}


-(void)dealloc	//@nodoc
{
	[super dealloc];
}


-(id)differenceTo: (MTCoordinates *)other
{
	MTCoordinates *res = [MTCoordinates origin];
	int i;
	for (i=0; i<3; i++)
	{
		[res atDim: i value: ([other atDim: i] - [self atDim: i])];
	}
	return res;
}


/*
 *  *   add vector v2 to this one
 *   */
-(id)add:(MTVector*)v2
{
	if ([v2 dimension] < 3)
	{
		return nil;
	}
	int i;
	for (i=0; i<3; i++)
	{
		[self atDim:i value:([self atDim:i]+[v2 atDim:i])];
	}
	return self;
}


/*
 *   length of the vector
 */
-(double)length
{
	double len = 0.0;
	double elem;
	int i;
	for (i=0; i<3; i++)
	{
		elem = [self atDim:i];
		len += (elem*elem);
	}
	if (len > 0.0)
	{
		return sqrt(len);
	}
	return len;
}


/*
 *   calculates distance between the two coordinates
 */
-(double)distanceTo:(MTCoordinates*)c2
{
	return [self euklideanDistanceTo: c2];
}

/*
 *   calculate distance of this coordinates to the line given by (v2,v3)
 */
-(double)distanceToLineFrom:(MTCoordinates*)v2 to:(MTCoordinates*)v3
{
/*
 *              D
 *              |
 *         P    |A
 *     ----x----x------------ plane
 *              |
 *              |
 *              O
 *  Abbildung von OP auf OD(Normale): OD . OP / |OD| => h
 *  Streckung von OD mit h ergiebt OA
 *  Distanz ist gegeben von A zu P   []
 */
	/* calculate plane through this point with normal: v3-v2 */
	MTCoordinates *normal = [v2 differenceTo: v3];
	MTCoordinates *base = [v2 differenceTo: self];
	double h = [base scalarProductBy: normal]/[normal length];
	[(MTVector*)[[normal normalize] scaleByScalar: h] add:v2];
	return [self distanceTo: normal];
}


/*
 *   normalize
 */
-(id)normalize
{
	double dist = 0.0;
	double t;
	int i;
	for (i=0; i<3; i++) // only first 3 dimensions
	{
		t = [self atDim: i];
		dist += (t * t);
	}
	dist = sqrt(dist);
	[self scaleByScalar: (1.0 / dist)];
	return self;
}


/*
 *   overwrite so we won't add up all 4 dimensions but only the 3 real ones 
 */
-(double)euklideanDistanceTo:(MTVector*)v2
{
	double dist = 0.0;
	double t;
	int i;
	for (i=0; i<3; i++) // only first 3 dimensions
	{
		t = [v2 atDim: i] - [self atDim: i];
		dist += (t * t);
	}
	return sqrt(dist);
}


/*
 *   set coordinates to the new values
 */
-(id)setX:(double)newx Y:(double)newy Z:(double)newz
{
	[self atDim: 0 value: newx];
	[self atDim: 1 value: newy];
	[self atDim: 2 value: newz];
	return self;
}


-(double)x
{
	return [self atDim: 0];
}


-(double)y
{
	return [self atDim: 1];
}


-(double)z
{
	return [self atDim: 2];
}


-(id)translateBy:(MTVector*)v
{
	if ([v dimension] < 3)
	{
		// raise exception
		NSLog(@"Coordinates-translateBy: needs a vector of length at least 3.");
		return nil;
	}
	[self atDim: 0 value: ([self x] + [v atDim: 0])];
	[self atDim: 1 value: ([self y] + [v atDim: 1])];
	[self atDim: 2 value: ([self z] + [v atDim: 2])];
	return self;
}


-(id)rotateBy:(MTMatrix44*)m
{
	/*         0  1  2  3
	 * 0     |r1 r2 r3 t1|      |x|
	 * 1     |r4 r5 r6 t2|      |y|
	 * 2 M = |r7 r8 r9 t3|  v = |z|
	 * 3     |o1 o2 o3 1 |      |1|
	 *
	 *           |r1*x+r2*y+r3*z+t1*1|
	 *           |r4*x+r5*x+r6*z+t2*1|
	 * v' = Mv = |r7*x+r8*x+r9*z+t3*1|
	 *           |o1*x+o2*x+o3*z+1*1 |
	 *
	 */
	double x,y,z;
	double t1,t2,t3;
	double r1,r2,r3,r4,r5,r6,r7,r8,r9;
	x=[self x]-[m atRow:3 col:0]; y=[self y]-[m atRow:3 col:1]; z=[self z]-[m atRow:3 col:2];
	t1=[m atRow:0 col:3]; t2=[m atRow:1 col:3]; t3=[m atRow:2 col:3];
	r1=[m atRow:0 col:0]; r2=[m atRow:0 col:1]; r3=[m atRow:0 col:2];
	r4=[m atRow:1 col:0]; r5=[m atRow:1 col:1]; r6=[m atRow:1 col:2];
	r7=[m atRow:2 col:0]; r8=[m atRow:2 col:1]; r9=[m atRow:2 col:2];
	[self setX:(r1*x+r2*y+r3*z+t1)
	 	 Y:(r4*x+r5*y+r6*z+t2)
	 	 Z:(r7*x+r8*y+r9*z+t3)];
	return self;
}


-(id)transformBy:(MTMatrix53*)m
{
	/*         0  1  2
	 * 0     |r1 r2 r3|      |x|
	 * 1     |r4 r5 r6|      |y|
	 * 2 M = |r7 r8 r9|  v = |z|
	 * 3     |o1 o2 o3|      |1|
	 * 4     |t1 t2 t3|
	 *
	 *           |r1*x+r2*y+r3*z+t1*1|
	 *           |r4*x+r5*x+r6*z+t2*1|
	 * v' = Mv = |r7*x+r8*x+r9*z+t3*1|
	 *           |o1*x+o2*x+o3*z+1*1 |
	 *
	 */
	double x,y,z;
	double t1,t2,t3;
	double r1,r2,r3,r4,r5,r6,r7,r8,r9;
	x=[self x]-[m atRow:3 col:0]; y=[self y]-[m atRow:3 col:1]; z=[self z]-[m atRow:3 col:2];
	t1=[m atRow:4 col:0]; t2=[m atRow:4 col:1]; t3=[m atRow:4 col:2];
	r1=[m atRow:0 col:0]; r2=[m atRow:0 col:1]; r3=[m atRow:0 col:2];
	r4=[m atRow:1 col:0]; r5=[m atRow:1 col:1]; r6=[m atRow:1 col:2];
	r7=[m atRow:2 col:0]; r8=[m atRow:2 col:1]; r9=[m atRow:2 col:2];
	[self setX:(r1*x+r2*y+r3*z+t1)
	 	 Y:(r4*x+r5*y+r6*z+t2)
	 	 Z:(r7*x+r8*y+r9*z+t3)];
	return self;
}


/*
 *   return the rotation matrix to align the vector along the Z-axis
 */
-(MTMatrix44*)alignToZaxis
{
	MTCoordinates *axis = [self copy];
	[axis normalize];
	//NSLog(@"axis : %@", axis);
	double a = [axis x];
	double b = [axis y];
	double c = [axis z];
	double d = sqrt( (b * b) + (c * c) );
	double cos_a = c / d;
	double a_alpha = (acos (cos_a) * 180.0 / M_PI);
	if (b >= 0) { a_alpha = 0.0 - a_alpha; }
	//NSLog(@"                                        alpha: %2f", a_alpha);
	MTMatrix44 *M1 = [MTMatrix44 rotationX: a_alpha];
#ifdef REALLY_DEBUG
	[axis rotateBy: M1];
	[axis normalize];
	NSLog(@"axis : %@", axis);
#endif

	double cos_b = d;
	double a_beta = (acos (cos_b) * 180.0 / M_PI);
	if (a < 0) { a_beta = 0.0 - a_beta; }
	//NSLog(@"                                        beta: %2f", a_beta);
	MTMatrix44 *M2 = [MTMatrix44 rotationY: a_beta];
#ifdef REALLY_DEBUG
	[axis rotateBy: M2];
	[axis normalize];
	NSLog(@"axis : %@", axis);
#endif

	MTMatrix44 *res = [M2 x: M1];

#ifdef REALLY_DEBUG
	axis = [self copy];
	[axis normalize];
	[axis rotateBy: res];
	NSLog(@"test : %@", axis);
#endif

	return res;
}


/*
 *   scalar product between two vectors
 */
-(double)scalarProductBy: (MTVector*)v2
{
	if ([self dimension] != [v2 dimension])
	{
		// raise exception
		NSLog(@"Coordinates-scalarProductBy: needs a vector of same length.");
		return -1.0;
	}
	double sum = 0.0;
	int i;
	for (i=0; i<3; i++)
	{
		sum += [self atDim: i] * [v2 atDim: i];
	}
	return sum;
}


/*
 *   create new coordinates at the origin (0,0,0)
 */
+(MTCoordinates*)origin
{
	MTCoordinates *origin = [[self alloc] init];
	return AUTORELEASE(origin);
}


/*
 *   create new coordinates with the given values
 */
+(MTCoordinates*)coordsWithX:(double)p_x Y:(double)p_y Z:(double)p_z
{
	MTCoordinates *coords = [[self alloc] init];
	[coords setX: p_x Y:p_y Z:p_z];
	return AUTORELEASE(coords);
}

/*
 *   make copy of given coordinates
 */
+(MTCoordinates*)coordsFromVector:(MTVector*)p_vect
{
	MTCoordinates *coords = [[self alloc] init];
	[coords setX:[p_vect atDim:0]  Y:[p_vect atDim:1] Z:[p_vect atDim:2]];
	return AUTORELEASE(coords);
}


/*
 *   make copy of given coordinates
 */
+(MTCoordinates*)coordsFromCoordinates:(MTCoordinates*)p_coords
{
	MTCoordinates *coords = [[self alloc] init];
	[coords setX:[p_coords x]  Y:[p_coords y] Z:[p_coords z]];
	[coords atDim: 3 value: 1.0];
	return AUTORELEASE(coords);
}


/*
 *   make copy of given coordinates
 */
-(id)copy
{
	MTCoordinates *coords = [[[self class] alloc] init];
	[coords setX:[self x]  Y:[self y] Z:[self z]];
	return AUTORELEASE(coords);
}


@end
 
