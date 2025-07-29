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


#include "MTAlPos.h"
#include "MTResidue.h"


@implementation MTAlPos

-(id)init	//@nodoc
{
	[super init];
	res1 = nil;
	res2 = nil;
	significant = YES;
	distance = -1.0;
	return self;
}


-(void)dealloc	//@nodoc
{
	//printf("MTAlPos_dealloc\n");
	if (res1)
	{
		RELEASE(res1);
	}	
	if (res2)
	{
		RELEASE(res2);
	}
	[super dealloc];
}


-(NSString*)description
{
	char char1=0;
	char char2=0;
	if (res1 == nil)
	{
		char1 = '-';
	} else {
		char1 = [[res1 oneLetterCode] characterAtIndex:0];
		if (!significant) { char1 += 32; }
	}
	if (res2 == nil)
	{
		char2 = '-';
	} else {
		char2 = [[res2 oneLetterCode] characterAtIndex:0];
		if (!significant) { char2 += 32; }
	}
	if (distance >= 0.0)
	{
		return [NSString stringWithFormat: @"%c %c %1.2f",char1,char2,distance];
	} else {
		return [NSString stringWithFormat: @"%c %c     ",char1,char2];
	}
}


/*
 *   set flag
 */ 
-(id)signify
{
	significant = YES;
	return self;
}


/*
 *   remove flag
 */ 
-(id)designify
{
	significant = NO;
	return self;
}


/*
 *   true if one of the residues is missing, indicating a gap
 */
-(BOOL)isGapped
{
	if (res1==nil || res2==nil)
	{
		return YES;
	}
	return NO;
}


/*
 *   return reference to residue
 */
-(MTResidue*)res1
{
	return res1;
}


/*
 *   return reference to residue
 */
-(MTResidue*)res2
{
	return res2;
}


/*
 *   return distance between the two residues, or -1.0 for a gapped position
 */
-(double)distance
{
	if (res1!=nil && res2!=nil)
	{
		//return [res1 distanceCATo:res2];
		return distance;
	}
	return -1.0;
}

-(void)res1:(MTResidue*)p_res1
{
	if (p_res1)
	{
		RETAIN(p_res1);
	}
	if (res1)
	{
		RELEASE(res1);
	}
	res1 = p_res1;
}

-(void)res2:(MTResidue*)p_res2
{
	if (p_res2)
	{
		RETAIN(p_res2);
	}
	if (res2)
	{
		RELEASE(res2);
	}
	res2 = p_res2;
}

-(void)distance:(double)dist
{
	if (res1 && res2)
	{
		distance = dist;
	} else {
		distance = -1.0;
	}
}


/*
 *   create alPos with pair of residues
 */ 
+(MTAlPos*)alposWithRes1:(MTResidue*)r1 res2:(MTResidue*)r2
{
	MTAlPos *res = [MTAlPos new];
	res->res1 = r1;
	if (r1)
	{
		RETAIN(res->res1);
	}
	res->res2 = r2;
	if (r2)
	{
		RETAIN(res->res2);
	}
	if (r1 && r2)
	{
		res->distance = [r1 distanceCATo:r2];
	} else {
		res->distance = -1.0;
	}
	return AUTORELEASE(res);
}


@end

