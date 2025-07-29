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


#ifndef MTMATRIX_H
#define MTMATRIX_H
 
#include <Foundation/Foundation.h>
#ifndef GNUSTEP
#include "GNUstepAdditions.h"
#endif

@class MTMatrix53;

@interface MTMatrix : NSObject
{
	@private
	double *elements;
	int rows,cols;
	BOOL transposed;
}


/* readonly access */
-(BOOL)isTransposed;
-(int)cols;
-(int)rows;
-(NSString*)toString;
-(NSString*)description;

/* getter */
-(double)atRow:(int)row col:(int)col;
-(id)matrixOfColumn:(int)col;
-(void)linearizeTo:(double*)mat maxElements:(int)count;

/* setter */
-(id)atRow:(int)row col:(int)col value:(double)v;

/* matrix operations */
-(id)transpose;
-(id)x: (MTMatrix*)m2;
-(id)mmultiply: (MTMatrix*)m2;
-(id)msubtract: (MTMatrix*)m2;
-(id)madd: (MTMatrix*)m2;
-(id)addScalar: (double)scal;
-(id)substractScalar: (double)scal;
-(id)multiplyByScalar: (double)scal;
-(id)divideByScalar: (double)scal;
-(MTMatrix*)jacobianDiagonalizeWithMaxError:(double)error;
-(MTMatrix*)centerOfMass;
-(double)sum;
-(id)square;

/* operations on single cells */
-(id)atRow:(int)row col:(int)col add:(double)v;
-(id)atRow:(int)row col:(int)col subtract:(double)v;
-(id)atRow:(int)row col:(int)col multiplyBy:(double)v;
-(id)atRow:(int)row col:(int)col divideBy:(double)v;

/* complex operations */
-(MTMatrix53*)alignTo:(MTMatrix*)m2;

/* creation */
-(id)setRows:(int)row cols:(int)col;
-(id)initFromString:(NSString*)str;
+(MTMatrix*)matrixWithRows:(int)row cols:(int)col;


@end

#endif /* MTMATRIX_H */

