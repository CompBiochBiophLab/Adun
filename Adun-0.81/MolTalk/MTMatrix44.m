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


#include "MTMatrix44.h"
#include "MTCoordinates.h"


@implementation MTMatrix44


-(id)init	//@nodoc
{
	[super init];
	[super setRows:4 cols:4];
	[self atRow: 0 col: 0 value: 1.0];
	[self atRow: 1 col: 1 value: 1.0];
	[self atRow: 2 col: 2 value: 1.0];
	[self atRow: 3 col: 3 value: 1.0];
	return self;
}


-(void)dealloc	//@nodoc
{
	[super dealloc];
}


/*
 *   inverts the matrix
 */
-(MTMatrix44*)invert
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
	[self atRow: 3 col: 0 value: -[self atRow: 3 col: 0]];
	[self atRow: 3 col: 1 value: -[self atRow: 3 col: 1]];
	[self atRow: 3 col: 2 value: -[self atRow: 3 col: 2]];
	
	return self;
}


/*
 *   multiplies in-place (M' = p_M * M) with the parameter matrix
 */
-(MTMatrix44*)chainWith:(MTMatrix44*)p_mat
{
	double t[4][4];
	double vrow[4];
	double tsum=0.0;
	int irow,icol,tc;
	/* calculate temporary matrix */
	for (irow=0; irow<4; irow++)
	{
		vrow[0]=[p_mat atRow:irow col:0];
		vrow[1]=[p_mat atRow:irow col:1];
		vrow[2]=[p_mat atRow:irow col:2];
		vrow[3]=[p_mat atRow:irow col:3];
		for (icol=0; icol<4; icol++)
		{
			tsum = 0.0;
			for (tc=0; tc<4; tc++)
			{
				tsum += vrow[tc] * [self atRow:tc col:icol];
			}
			t[irow][icol] = tsum;
		}
	}
	/* copy from temporary to real matrix */
	for (irow=0; irow<4; irow++)
	{
		for (icol=0; icol<4; icol++)
		{
			[self atRow:irow col:icol value:t[irow][icol]];
		}
	}
	return self;
}


/*
 *   multiplies in-place (M' = M * p_M) with the parameter matrix
 */
-(MTMatrix44*)xIP:(MTMatrix44*)p_mat
{
	double t[4][4];
	double vrow[4];
	double tsum=0.0;
	int irow,icol,tc;
	/* calculate temporary matrix */
	for (irow=0; irow<4; irow++)
	{
		vrow[0]=[self atRow:irow col:0];
		vrow[1]=[self atRow:irow col:1];
		vrow[2]=[self atRow:irow col:2];
		vrow[3]=[self atRow:irow col:3];
		for (icol=0; icol<4; icol++)
		{
			tsum = 0.0;
			for (tc=0; tc<4; tc++)
			{
				tsum += vrow[tc] * [p_mat atRow:tc col:icol];
			}
			t[irow][icol] = tsum;
		}
	}
	/* copy from temporary to real matrix */
	for (irow=0; irow<4; irow++)
	{
		for (icol=0; icol<4; icol++)
		{
			[self atRow:irow col:icol value:t[irow][icol]];
		}
	}
	return self;
}


/*
 *   read and initializes a matrix from a string
 */
+(MTMatrix44*)matrixFromString:(NSString*)str
{
	MTMatrix44 *res = [MTMatrix44 new];
	NSScanner *sc = [NSScanner scannerWithString: str];
	[sc  setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @"[] 	,"]];
	double val;
	int irow,icol;
	for (irow=0; irow<4; irow++)
	{
		for (icol=0; icol<4; icol++)
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
	MTMatrix44 *res = [MTMatrix44 new];
	return AUTORELEASE(res);
}


/*
 *   create rotation matrix around X axis
 */
+(MTMatrix44*)rotationX:(double)alpha
{
	MTMatrix44 *res = [MTMatrix44 new];
	double rad = M_PI * alpha / 180.0;
	double cosalpha = cos(rad);
	double sinalpha = sin(rad);
	[res atRow: 1 col: 1 value: cosalpha];
	[res atRow: 1 col: 2 value: sinalpha];
	[res atRow: 2 col: 1 value: -sinalpha];
	[res atRow: 2 col: 2 value: cosalpha];
	return AUTORELEASE(res);
}

/*
 *   create rotation matrix around Y axis
 */
+(MTMatrix44*)rotationY:(double)alpha
{
	MTMatrix44 *res = [MTMatrix44 new];
	double rad = M_PI * alpha / 180.0;
	double cosalpha = cos(rad);
	double sinalpha = sin(rad);
	[res atRow: 0 col: 0 value: cosalpha];
	[res atRow: 0 col: 2 value: -sinalpha];
	[res atRow: 2 col: 0 value: sinalpha];
	[res atRow: 2 col: 2 value: cosalpha];
	return AUTORELEASE(res);
}

/*
 *   create rotation matrix around Z axis
 */
+(MTMatrix44*)rotationZ:(double)alpha
{
	MTMatrix44 *res = [MTMatrix44 new];
	double rad = M_PI * alpha / 180.0;
	double cosalpha = cos(rad);
	double sinalpha = sin(rad);
	[res atRow: 0 col: 0 value: cosalpha];
	[res atRow: 0 col: 1 value: sinalpha];
	[res atRow: 1 col: 0 value: -sinalpha];
	[res atRow: 1 col: 1 value: cosalpha];
	return AUTORELEASE(res);
}


/*
 *   rotation of an angle (degrees) around an axis
 */
+(MTMatrix44*)rotation: (double)phi aroundAxis:(MTCoordinates*)ax
{
	double rot = phi * M_PI / 180.0;
	MTMatrix44 *res = [MTMatrix44 new];
	double c = cos(rot);
	double s = sin(rot);
	double t = 1-c;
	double x = [ax x];
	double y = [ax y];
	double z = [ax z];
	[res atRow: 0 col: 0 value: (t*x*x+c)];
	[res atRow: 0 col: 1 value: (t*x*y+s*z)];
	[res atRow: 0 col: 2 value: (t*x*z-s*y)];
	[res atRow: 1 col: 0 value: (t*x*y-s*z)];
	[res atRow: 1 col: 1 value: (t*y*y+c)];
	[res atRow: 1 col: 2 value: (t*y*z+s*x)];
	[res atRow: 2 col: 0 value: (t*x*z+s*y)];
	[res atRow: 2 col: 1 value: (t*y*z-s*x)];
	[res atRow: 2 col: 2 value: (t*z*z+c)];
	[res atRow: 3 col: 3 value: 1.0];
	return AUTORELEASE(res);
}

@end

