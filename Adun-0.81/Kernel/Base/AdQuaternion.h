/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef QUATERNION
#define QUATERNION

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "Base/AdVector.h"

/**
\defgroup Quaternions Quaternion
\ingroup Functions

@{
**/


/**
Rotates \e vector around the arbitrary axis \e axis by \e angle (in radians) 
using quaternions.
\e axis and \e vector must both start at the origin and the norm of \e axis must be
1 i.e. it must be a unit vector.
Using quaternions a rotation that transforms a vector \f$v\f$ into \f$v'\f$ 
is given by
\f[
[0, v'] = q'.[0, v].q
\f]
where q is the representing quaternion for the rotation. q is related to the axis
of rotation \f$w\f$ and the angle \f$\theta\f$ through its definition
\f[
[\cos(\frac{\theta}{2}), w.\sin(\frac{\theta}{2})]
\f]
The above is equivalent to the following formula which uses dot and cross product.
\f[
v^{'} = w(v.w) + (v - w(v.w))cos(\theta) + (v\wedge w)sin(\theta)
\f]
*/
void AdQuaternionRotation(Vector3D* vector, Vector3D* axis, double angle);
/**
Rotates \e vector around the x,y & z axis by \e angles placing the resulting
vector in \e result. \e angles is an array of 3 doubles each an angle in radians.
*/
void AdRotate3DVector(double* vector, double* angles, double* result);

/** \@}*/


#endif 

