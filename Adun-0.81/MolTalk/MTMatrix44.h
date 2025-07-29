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


#ifndef MTMATRIX44_H
#define MTMATRIX44_H

 
#include <Foundation/Foundation.h>

#include "MTMatrix.h"
#include "MTCoordinates.h"


@interface MTMatrix44 : MTMatrix
{
}

/* manipulation */
-(MTMatrix44*)invert;
-(MTMatrix44*)xIP:(MTMatrix44*)p_mat;
-(MTMatrix44*)chainWith:(MTMatrix44*)p_mat;

/* creation */
+(MTMatrix44*)matrixFromString:(NSString*)m;
+(MTMatrix44*)rotationX:(double)alpha;
+(MTMatrix44*)rotationY:(double)alpha;
+(MTMatrix44*)rotationZ:(double)alpha;
+(MTMatrix44*)rotation: (double)phi aroundAxis:(MTCoordinates*)ax;
+(id)matrixIdentity;


@end

#endif /* MTMATRIX44_H */
 
