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

#include "privateMTChain.h"
#include "MTChain.h"
#include "MTCoordinates.h"
#include "MTStructure.h"
#include "MTMatrix44.h"


@implementation MTChain (Private)


-(void)setStructure:(MTStructure*)p_strx	//@nodoc
{
	strx = p_strx;
}


-(void)setCode:(char)p_code	//@nodoc
{
	code = p_code;
}


-(void)setSource:(NSString*)p_src	//@nodoc
{
	RETAIN(p_src);
	if (source)
	{
		RELEASE(source);
	}
	source = p_src;
}


-(void)setCompound:(NSString*)p_cmpnd	//@nodoc
{
	RETAIN(p_cmpnd);
	if (compound)
	{
		RELEASE(compound);
	}
	compound = p_cmpnd;
}


-(void)setECCode:(NSString*)p_ecc	//@nodoc
{
	RETAIN(p_ecc);
	if (eccode)
	{
		RELEASE(eccode);
	}
	eccode = p_ecc;
}


-(void)setSeqres:(NSString*)p_seqres	//@nodoc
{
	RETAIN(p_seqres);
	if (seqres)
	{
		RELEASE(seqres);
	}
	seqres = p_seqres;
}


-(void)enterHashAtom:(MTCoordinates*)atm for:(MTResidue*)res
{
	double x,y,z;
	NSNumber *hashvalue;

	x = [atm x]; y = [atm y]; z = [atm z];
	hashvalue = [self mkCoordinatesHashX:x Y:y Z:z];
	[self enterHashValue:hashvalue for:res];

	hashvalue = [self mkCoordinatesHashX:(x+hash_value_offset) Y:(y+hash_value_offset) Z:(z+hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x-hash_value_offset) Y:(y+hash_value_offset) Z:(z+hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x-hash_value_offset) Y:(y-hash_value_offset) Z:(z+hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x-hash_value_offset) Y:(y-hash_value_offset) Z:(z-hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x+hash_value_offset) Y:(y-hash_value_offset) Z:(z+hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x+hash_value_offset) Y:(y-hash_value_offset) Z:(z-hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x+hash_value_offset) Y:(y+hash_value_offset) Z:(z-hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
	hashvalue = [self mkCoordinatesHashX:(x-hash_value_offset) Y:(y+hash_value_offset) Z:(z-hash_value_offset)];
	[self enterHashValue:hashvalue for:res];
}


-(void)enterHashValue:(NSNumber*)hashvalue for:(MTResidue*)res
{
	NSMutableArray *t_arr;
	t_arr = [residuehash objectForKey: hashvalue];
	if (!t_arr)
	{
		t_arr = [NSMutableArray new];
		[residuehash setObject: t_arr forKey: hashvalue];
	}
	if (! [t_arr containsObject: res])
	{
		[t_arr addObject: res];
	}
}



-(id)rotate: (double)angle aroundAxisFrom: (MTCoordinates*)p_P1 to: (MTCoordinates*)p_P2
{
	//  move P1 (chain) to origin : M0
	//  rotate P2 around X-axis into XZ-plane : M1
	//  rotate P2' around Y-axis onto Z-axis  : M2
	//  rotate around Z-axis by given angle : M3
	//  translate back -M2, -M1, -M0

	MTCoordinates *P1 = [MTCoordinates coordsFromCoordinates: p_P1];
	MTCoordinates *P2 = [MTCoordinates coordsFromCoordinates: p_P2];
	MTCoordinates *to_origin = [MTCoordinates coordsFromCoordinates: P1];
	[to_origin scaleByScalar: (-1.0)];   // subtract
	[self translateBy: to_origin];
	[P1 add: to_origin];
	[P2 add: to_origin];

	MTCoordinates *axis = [P1 differenceTo: P2];
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
	[self rotateBy: M1];

	[P1 rotateBy: M1];
	[P2 rotateBy: M1];

	//NSLog(@"before rotation: %@ / %@", p_P1, p_P2);
	//NSLog(@"after  rotation: %@ / %@", P1, P2);

	axis = [P1 differenceTo: P2];
	[axis normalize];
	//NSLog(@"axis : %@", axis);
	
	double cos_b = d;
	double a_beta = (acos (cos_b) * 180.0 / M_PI);
	if (a < 0) { a_beta = 0.0 - a_beta; }
	//NSLog(@"                                        beta: %2f", a_beta);
	MTMatrix44 *M2 = [MTMatrix44 rotationY: a_beta];
	[self rotateBy: M2];

	[P1 rotateBy: M2];
	[P2 rotateBy: M2];

	//NSLog(@"before rotation: %@ / %@", p_P1, p_P2);
	//NSLog(@"after  rotation: %@ / %@", P1, P2);

	axis = [P1 differenceTo: P2];
	[axis normalize];
	//NSLog(@"axis : %@", axis);

	/* M3 : rotation around Z-axis */
	MTMatrix44 *M3 = [MTMatrix44 rotationZ: angle];
	[self rotateBy: M3];

	/* M2 : back from Z-axis */
	[M2 invert];
	[self rotateBy: M2];

	/* M1 : back from XZ-plane */
	[M1 invert];
	[self rotateBy: M1];

	/* M0 : back from origin */
	[to_origin scaleByScalar: (-1.0)];   // subtract
	[self translateBy: to_origin];

	return self;
	
}



@end

