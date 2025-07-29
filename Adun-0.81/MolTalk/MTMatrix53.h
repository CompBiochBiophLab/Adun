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


#ifndef MTMATRIX53_H
#define MTMATRIX53_H


#include <Foundation/Foundation.h>

#include "MTMatrix.h"


@class MTCoordinates;
@class MTMatrix44;
@class MTMatrix;

@interface MTMatrix53 : MTMatrix
{
}

/* manipulation */
-(MTMatrix53*)invert;

/* getter */
-(MTMatrix44*)getRotation;
-(MTMatrix44*)getTranslation;
-(MTCoordinates*)getOrigin;

/* creation */
+(MTMatrix53*)matrixFromString:(NSString*)m;
+(id)matrixIdentity;
+(MTMatrix53*)transformation3By3:(MTMatrix*)first and:(MTMatrix*)second;


@end

#endif /* MTMATRIX53_H */
 
