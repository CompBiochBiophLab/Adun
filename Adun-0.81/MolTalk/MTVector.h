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


#ifndef MTVECTOR_H
#define MTVECTOR_H
 

#include <Foundation/Foundation.h>

#include "MTMatrix.h"


/*
 *   class Vector reprents a column vector, <br>
 *   a matrix with n (=dimensions) rows and a single column
 *
 */
@interface MTVector : MTMatrix
{
}

/* access */
-(int)dimension;
-(NSString*)toString;
-(NSString*)description;
-(id)atDim:(int)dim value:(double)v;
-(double)atDim:(int)dim;

/* operations */
-(double)length;
-(id)differenceTo:(MTVector*)v2;
-(double)euklideanDistanceTo:(MTVector*)v2;
-(id)add:(MTVector*)v2;
-(id)normalize;
-(id)scaleByScalar:(double)scalar;
-(double)angleBetween:(MTVector*)v2;
-(double)scalarProductBy:(MTVector*)v2;
-(id)vectorProductBy:(MTVector*)v2;
-(double)mixedProductBy:(MTVector*)v2 and:(MTVector*)v3;

/* creation */
-(id)copy;
-(id)setDimensions:(int)dim;
+(MTVector*)vectorWithDimensions:(int)dim;


@end

#endif /* MTVECTOR_H */

