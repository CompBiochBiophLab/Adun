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

#include "MTMatrix53.h"
#include "MTMatrix44.h"
#include "MTMatrix.h"
#include "MTCoordinates.h"


@implementation MTMatrix53


-(id)init	//@nodoc
{
	[super init];
	[super setRows:5 cols:3];
	[self atRow: 0 col: 0 value: 1.0];
	[self atRow: 1 col: 1 value: 1.0];
	[self atRow: 2 col: 2 value: 1.0];
	return self;
}

-(void)dealloc	//@nodoc
{
	[super dealloc];
}


/*
 *   returns the matrix for an inverse transformation
 */
-(MTMatrix53*)invert
{
	double t;
	t = [self atRow: 0 col: 1];
	[self atRow: 0 col: 1 value: [self atRow: 1 col: 0]];
	[self atRow: 1 col: 0 value: t];
	t = [self atRow: 0 col: 2];
	[self atRow: 0 col: 2 value: [self atRow: 2 col: 0]];
	[self atRow: 2 col: 0 value: t];
	t = [self atRow: 1 col: 2];
	[self atRow: 1 col: 2 value: [self atRow: 2 col: 1]];
	[self atRow: 2 col: 1 value: t];
	t = [self atRow: 3 col: 0];
	[self atRow: 3 col: 0 value: [self atRow: 4 col:0]];
	[self atRow: 4 col: 0 value: t];
	t = [self atRow: 3 col: 1];
	[self atRow: 3 col: 1 value: [self atRow: 4 col:1]];
	[self atRow: 4 col: 1 value: t];
	t = [self atRow: 3 col: 2];
	[self atRow: 3 col: 2 value: [self atRow: 4 col:2]];
	[self atRow: 4 col: 2 value: t];
	return self;
}


/*
 *   return rotation matrice
 */
-(MTMatrix44*)getRotation
{
	MTMatrix44 *res = [MTMatrix44 matrixIdentity];
	[res atRow: 0 col: 0 value: [self atRow: 0 col: 0]];
	[res atRow: 0 col: 1 value: [self atRow: 0 col: 1]];
	[res atRow: 0 col: 2 value: [self atRow: 0 col: 2]];
	[res atRow: 1 col: 0 value: [self atRow: 1 col: 0]];
	[res atRow: 1 col: 1 value: [self atRow: 1 col: 1]];
	[res atRow: 1 col: 2 value: [self atRow: 1 col: 2]];
	[res atRow: 2 col: 0 value: [self atRow: 2 col: 0]];
	[res atRow: 2 col: 1 value: [self atRow: 2 col: 1]];
	[res atRow: 2 col: 2 value: [self atRow: 2 col: 2]];
	
	return res;
}


/*
 *   return translation matrice
 */
-(MTMatrix44*)getTranslation
{
	MTMatrix44 *res = [MTMatrix44 matrixIdentity];
	[res atRow: 3 col: 0 value: [self atRow: 4 col: 0]];
	[res atRow: 3 col: 1 value: [self atRow: 4 col: 1]];
	[res atRow: 3 col: 2 value: [self atRow: 4 col: 2]];
	return res;
}


/*
 *   return reset-to-origin vector
 */
-(MTCoordinates*)getOrigin
{
	MTCoordinates *res = [MTCoordinates new];
	[res atDim: 0 value: [self atRow: 3 col: 0]];
	[res atDim: 1 value: [self atRow: 3 col: 1]];
	[res atDim: 2 value: [self atRow: 3 col: 2]];
	[res atDim: 3 value: 0.0];
	return AUTORELEASE(res);
}


/*
 *   computes the transformation of the second onto the first coordinates
 *   the coordinates are passed in 3x3 matrices:
 *     P1X P1Y P1Z
 *     P2X P2Y P2Z
 *     P3X P3Y P3Z
 */
+(MTMatrix53*)transformation3By3:(MTMatrix*)first and:(MTMatrix*)second
{
	if (!first || !second || [first rows] != 3 || [first cols] != 3
	 || [second rows] != 3 || [second cols] != 3)
	{
	        [NSException raise:@"Matrix53_transformation3By3:" format:@"Input parameters must be 3x3 matrices of three vectors."];
	}

	double center1X = [first atRow: 0 col: 0] + [first atRow: 1 col: 0] + [first atRow: 2 col: 0]; 
	double center1Y = [first atRow: 0 col: 1] + [first atRow: 1 col: 1] + [first atRow: 2 col: 1]; 
	double center1Z = [first atRow: 0 col: 2] + [first atRow: 1 col: 2] + [first atRow: 2 col: 2]; 
	double center2X = [second atRow: 0 col: 0] + [second atRow: 1 col: 0] + [second atRow: 2 col: 0]; 
	double center2Y = [second atRow: 0 col: 1] + [second atRow: 1 col: 1] + [second atRow: 2 col: 1]; 
	double center2Z = [second atRow: 0 col: 2] + [second atRow: 1 col: 2] + [second atRow: 2 col: 2]; 

	center1X /= 3.0; center1Y /= 3.0; center1Z /= 3.0;
	center2X /= 3.0; center2Y /= 3.0; center2Z /= 3.0;

	MTCoordinates *v11 = [MTCoordinates coordsWithX: ([first atRow: 1 col: 0]-[first atRow: 0 col: 0]) Y: ([first atRow: 1 col: 1]-[first atRow: 0 col: 1]) Z: ([first atRow: 1 col: 2]-[first atRow: 0 col: 2])];
	MTCoordinates *v12 = [MTCoordinates coordsWithX: ([first atRow: 2 col: 0]-[first atRow: 0 col: 0]) Y: ([first atRow: 2 col: 1]-[first atRow: 0 col: 1]) Z: ([first atRow: 2 col: 2]-[first atRow: 0 col: 2])];

	MTCoordinates *v21 = [MTCoordinates coordsWithX: ([second atRow: 1 col: 0]-[second atRow: 0 col: 0]) Y: ([second atRow: 1 col: 1]-[second atRow: 0 col: 1]) Z: ([second atRow: 1 col: 2]-[second atRow: 0 col: 2])];
	MTCoordinates *v22 = [MTCoordinates coordsWithX: ([second atRow: 2 col: 0]-[second atRow: 0 col: 0]) Y: ([second atRow: 2 col: 1]-[second atRow: 0 col: 1]) Z: ([second atRow: 2 col: 2]-[second atRow: 0 col: 2])];

	/* align normals to each other */
	MTCoordinates *n1 = [MTCoordinates coordsFromVector: [v11 vectorProductBy: v12]];
	[n1 normalize];
	MTCoordinates *n2 = [MTCoordinates coordsFromVector: [v21 vectorProductBy: v22]];
	[n2 normalize];
	MTMatrix44 *r1 = [n1 alignToZaxis];
	MTMatrix44 *r2 = [n2 alignToZaxis];

	[v11 normalize];
	[v21 normalize];
	[v11 rotateBy: r1]; // now in XY-plane
	[v21 rotateBy: r2]; // now in XY-plane

	/* check handedness */
	double handedness = 1.0; // right handed
	MTVector *thdn = [v11 vectorProductBy: v21];
	if ([thdn atDim: 2] < 0.0) 
	{
		// Z component indicates anti-parallel to Z-axis
		handedness = -1.0; // left handed
	}

	/* same rotation around normals */
	double phi = [v11 angleBetween: v21];
	MTMatrix44 *rZ = [MTMatrix44 rotationZ: (phi*handedness)];

	/* rotate second by r2 -> along Z-axis
	   rotation around Z-axis -> both relative aligned
	   rotate back from Z-axis using r1 (transposed)
        */
	[r1 transpose];
	MTMatrix44 *rot = [r1 x: rZ];
	rot = [rot x: r2];

	MTMatrix53 *trafo = [MTMatrix53 matrixIdentity];
	int i,j;
	double val;
	/* enter rotation */
	for (i=0; i<3; i++)
	{
		for (j=0; j<3; j++)
		{
			val = [rot atRow: i col: j];
			[trafo atRow: i col: j value: val];
		}
	}
	/* enter origin */
	[trafo atRow: 3 col: 0 value: center2X];
	[trafo atRow: 3 col: 1 value: center2Y];
	[trafo atRow: 3 col: 2 value: center2Z];
	/* enter translation */
	[trafo atRow: 4 col: 0 value: center1X];
	[trafo atRow: 4 col: 1 value: center1Y];
	[trafo atRow: 4 col: 2 value: center1Z];
	
	return trafo;
}


/*
 *   reads and initializes a matrix from a string
 */
+(MTMatrix53*)matrixFromString:(NSString*)str
{
/* a matrix might look like this: 
 [ [-0.506316,0.559328,0.656350] [-0.607832,-0.771377,0.188463] [0.611706,-0.303529,0.730538] [62.893028,10.183025,-0.708629] [19.371693,40.109528,10.753658] ]
*/
	MTMatrix53 *res = [MTMatrix53 new];
	NSScanner *sc = [NSScanner scannerWithString: str];
	[sc  setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @"[] 	,"]];
	double val;
	int irow,icol;
	for (irow=0; irow<5; irow++)
	{
		for (icol=0; icol<3; icol++)
		{
			if (![sc scanDouble: &val])
			{
				NSLog(@"scan failed.");
				return nil;
			}
			[res atRow: irow col: icol value: val];
		} /* icol */
	} /* irow */
	return AUTORELEASE(res);
}


/*
 *   create identity matrix
 */
+(id)matrixIdentity
{
	MTMatrix53 *res = [MTMatrix53 new];
	return AUTORELEASE(res);
}


@end

