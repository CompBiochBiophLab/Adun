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


#ifndef MTALPOS_OH
#define MTALPOS_OH


#include <Foundation/Foundation.h>

@class MTResidue;

@interface MTAlPos : NSObject
{
	@private
	MTResidue *res1;
	MTResidue *res2;
	double distance;
	BOOL significant;
}

-(NSString*)description;
/*
 *   readonly access
 */
-(BOOL)isGapped;
-(double)distance;
-(MTResidue*)res1;
-(MTResidue*)res2;


/*
 *   flag it to be (not) significant
 */
-(id)signify;
-(id)designify;


/*
 *   setters
 */
-(void)res1:(MTResidue*)res1;
-(void)res2:(MTResidue*)res2;
-(void)distance:(double)dist;


/*
 *   creation
 */
+(MTAlPos*)alposWithRes1:(MTResidue*)r1 res2:(MTResidue*)r2;

@end


#endif /* MTALPOS_OH */

