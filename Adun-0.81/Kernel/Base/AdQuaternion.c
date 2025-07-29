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
#include <Base/AdQuaternion.h>

static Vector3D x = {0.0, 1, 0, 0};
static Vector3D y = {0.0, 0, 1, 0};
static Vector3D z = {0.0, 0, 0, 1};

void AdQuaternionRotation(Vector3D *vector, Vector3D *axis, double angle)
{
	int i;
	double dot_va, hold;
	Vector3D cross_va;
 	
	if(angle == 0.0)
		return;
	
	dot_va = Ad3DDotProduct(vector, axis);

 	Ad3DCrossProduct(vector, axis, &cross_va);
 	
	for(i=0; i<3; i++)
	{	
		hold = dot_va*axis->vector[i];
		vector->vector[i] = hold + (vector->vector[i] - hold)*cos(angle) + cross_va.vector[i]*sin(angle);
	}	
}

void AdRotate3DVector(double* vector, double* angles, double* result)
{
	int i;
	Vector3D v1;

	for(i=0; i<3; i++)
		v1.vector[i] = vector[i];
	
	AdQuaternionRotation(&v1, &x, angles[0]);
	AdQuaternionRotation(&v1, &y, angles[1]);
	AdQuaternionRotation(&v1, &z, angles[2]);
	
	for(i=0; i<3; i++)
		result[i] = v1.vector[i];
}
