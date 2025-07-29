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
#include <math.h>

#include <Foundation/Foundation.h>

#include "MTVector.h"


@implementation MTVector


-(id)init	//@nodoc
{
	self = [super init];
	return self;
}


-(void)dealloc	//@nodoc
{
	[super dealloc];
}


/*
 *   return its dimension
 */
-(int)dimension
{
	return [super rows];
}


/*
 *   length of the vector
 */
-(double)length
{
	double len = 0.0;
	double elem;
	int i;
	for (i=0; i<[self dimension]; i++)
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
 *   calculates the angle between two vectors (in degrees)
 */
-(double)angleBetween:(MTVector*)v2
{
	double t_scal = [self scalarProductBy: v2] / [self length] / [v2 length];
	if (t_scal >= 1.0)
	{
		/* cannot compute acos(1.0) -> 0.0 */
		return 0.0;
	}
	return (acos(t_scal) * 180.0 / M_PI);
}


/*
 *   scalar product between two vectors
 */
-(double)scalarProductBy: (MTVector*)v2
{
	if ([self dimension] != [v2 dimension])
	{
		/* raise exception */
		NSLog(@"Vector-scalarProductBy: needs a vector of same length.");
		return -1.0;
	}
	double sum = 0.0;
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		sum += [self atDim: i] * [v2 atDim: i];
	}
	return sum;
}


/*
 *   normalize (to length 1.0)
 */
-(id)normalize
{
	double len = [self length];
	if (fabs(len) > 1e-10)
	{
		[self scaleByScalar: (1.0/len)];
	}
	return self;
}


/*
 *   multiply with scalar (in-place!)
 */
-(id)scaleByScalar:(double)scalar
{
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		[self atDim:i value:([self atDim:i]*scalar)];
	}
	return self;
}


/*
 *   difference between two vectors returned as a new vector
 */
-(id)differenceTo:(MTVector*)v2
{
	if ([v2 dimension] != [self dimension])
	{
		return nil;
	}
	id res = [[self class] new];
	[res setDimensions: [v2 dimension]];
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		[res atDim:i value:[v2 atDim:i]-[self atDim:i]];
	}
	return AUTORELEASE(res);
}


/*
 *   add vector v2 to this one
 */
-(id)add:(MTVector*)v2
{
	if ([v2 dimension] != [self dimension])
	{
		return nil;
	}
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		[self atDim:i value:([self atDim:i]+[v2 atDim:i])];
	}
	return self;
}

	
/*
 *   vector product between two vectors, returned as a new vector
 */
-(id)vectorProductBy: (MTVector*)v2
{
	if ([self dimension] < 3 || [v2 dimension] < 3)
	{
		return nil;
	}
	/* only consider first 3 dimensions !!! */
	MTVector *vprod = [MTVector vectorWithDimensions:3];
	double a1,a2,a3, b1,b2,b3;
	a1 = [self atDim:0]; a2 = [self atDim:1]; a3 = [self atDim:2];
	b1 = [v2 atDim:0]; b2 = [v2 atDim:1]; b3 = [v2 atDim:2];
	[vprod atDim:0 value: (a2*b3-a3*b2)];
	[vprod atDim:1 value: (a3*b1-a1*b3)];
	[vprod atDim:2 value: (a1*b2-a2*b1)];

	return vprod;
}


/*
 *   mixed product between three vectors
 */
-(double)mixedProductBy:(MTVector*)v2 and:(MTVector*)v3
{
	if ([self dimension] < 3 || [v2 dimension] < 3 || [v3 dimension] < 3)
	{
		return 0.0;
	}
	MTVector *t_v = [self vectorProductBy:v2];
	MTVector *t_v3 = [MTVector vectorWithDimensions:3];
	[t_v3 atDim:0 value:[v3 atDim:0]];
	[t_v3 atDim:1 value:[v3 atDim:1]];
	[t_v3 atDim:2 value:[v3 atDim:2]];
	return [t_v scalarProductBy: t_v3];
}


/*
 *   euklidean distance between two vectors
 */
-(double)euklideanDistanceTo: (MTVector*)v2
{
	if ([self dimension] != [v2 dimension])
	{
		/* raise exception */
		NSLog(@"Vector-euklideanDistanceTo: needs a vector of same length.");
		return -1.0;
	}
	double dist = 0.0;
	double temp1,temp2;
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		temp1 = [self atDim: i];
		temp2 = [v2 atDim: i];
		dist += (temp2-temp1)*(temp2-temp1);
	}
	return sqrt(dist);
}


/*
 *   returns a string describing this vector
 */
-(NSString*)toString
{
	NSString *res = @"<";
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		if (i==0)
		{
			res = [res stringByAppendingFormat: @"%4.2f",[self atDim: i]];
		} else {
			res = [res stringByAppendingFormat: @",%4.2f",[self atDim: i]];
		}
	}
	return [res stringByAppendingString: @">"];
}


/*
 *   same as @method(MTVector,-toString)
 */
-(NSString*)description
{
	return [self toString];
}


/*
 *   set a value for a dimension
 */
-(id)atDim:(int)dim value:(double)v
{
	[super atRow: dim col: 0 value: v];
	return self;
}


/*
 *   get a value for a dimension
 */
-(double)atDim:(int)dim
{
	return [super atRow: dim col: 0];
}


/*
 *   recreate with new dimension.<br>
 *   WARNING:!! this is destructive
 */
-(id)setDimensions:(int)dim
{
	[super setRows: dim cols: 1];
	return self;
}


/*
 *   copy vector
 */
-(id)copy
{
	MTVector *res = [MTVector new];
	[res setDimensions: [self dimension]];
	int i;
	for (i=0; i<[self dimension]; i++)
	{
		[res atDim: i value: [self atDim: i]];
	}
	return AUTORELEASE(res);
}


/*
 *   create a new vector
 */
+(MTVector*)vectorWithDimensions:(int)dim
{
	MTVector *res = [MTVector new];
	[res setDimensions:dim];
	return [res autorelease];
}


@end

