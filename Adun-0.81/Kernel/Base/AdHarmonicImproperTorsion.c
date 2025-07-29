/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston
   
   Created: 2006-04-03 15:06:55 +0200 by michael johnston

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

#include <Base/AdForceFieldFunctions.h>

bool __HarmonicImproperTorsionEnergyDebug__ = false;
bool __HarmonicImproperTorsionForceDebug__ = false;

void AdHarmonicImproperTorsionDebugInfo(void)
{
	fprintf(stderr, "\nHarmonic improper torsion debug on\n");
	fprintf(stderr, "Energy Info - Atom one, Atom two, Atom three, Atom four");
	fprintf(stderr, " Torsion constant, Equilibrium Angle, Calulated Angle, Cumulative Potential\n\n");
}

double AdCalculateImproperTorsionEnergy(double angle, double equilibriumAngle, double torsionConstant)
{
	return torsionConstant*pow((angle - equilibriumAngle), 2);
}

double AdCalculateImproperTorsionAngle(int* atomIndexes, double** coordinates)
{
	register int i;
	int atom_one, atom_two, atom_three, atom_four;
	double num, denom, cosine_ang, angle;
	Vector3D n_one, n_two, ba, bc, cd;
	
	atom_one = atomIndexes[0];
	atom_two = atomIndexes[1];
	atom_three = atomIndexes[2];
	atom_four = atomIndexes[3];
	
	//calculate vectors needed ba, bc, cd 
	for(i=3; --i>=0;)
	{
		*(ba.vector + i) = coordinates[atom_two][i] - coordinates[atom_one][i];
		*(bc.vector + i) = coordinates[atom_three][i] - coordinates[atom_two][i];
		*(cd.vector + i) = coordinates[atom_four][i] - coordinates[atom_three][i];
	}
	
	//calculate the cross product ba X bc, cd X cb
	
	Ad3DCrossProduct(&ba, &bc, &n_one);
	Ad3DCrossProduct(&bc, &cd, &n_two);
	Ad3DVectorLength(&n_one);
	Ad3DVectorLength(&n_two);
	
	//find the dot product of the two normal vectors to find the angle
	
	num = Ad3DDotProduct(&n_one, &n_two);
	denom = n_one.length*n_two.length;
	
	cosine_ang = num/denom;
	
	//check if the cosine of the angle is between -1 or 1. 
	//It could have slipped beyond these bounds becuase of the limits to precision of doubles
	
	if(cosine_ang > 1)
	{
		cosine_ang = 1;
		angle = 0;
	}
	else if(cosine_ang < -1)
	{
		cosine_ang = -1;
		angle = M_PI;
	}
	else
		angle = acos(cosine_ang);
		
	return angle;	
}	

void AdHarmonicImproperTorsionEnergy(double* interaction, double** coordinates, double* itor_pot)
{
	register int i;
	int atom_one, atom_two, atom_three, atom_four;
	double num, denom, cosine_ang, angle;
	double  n2_n1, n1_n2, equilibriumAngle, tor_cnst;
	Vector3D n_one, n_two, ba, bc, cd;

	atom_one = (int)interaction[0];
	atom_two = (int)interaction[1];
	atom_three = (int)interaction[2];
	atom_four = (int)interaction[3];
	tor_cnst = interaction[4];
	equilibriumAngle = interaction[5];

	//calculate vectors needed ba, bc, cd 

	for(i=3; --i>=0;)
	{
		*(ba.vector + i) = coordinates[atom_two][i] - coordinates[atom_one][i];
		*(bc.vector + i) = coordinates[atom_three][i] - coordinates[atom_two][i];
		*(cd.vector + i) = coordinates[atom_four][i] - coordinates[atom_three][i];
	}

	//calculate the cross product ba X bc, cd X cb
	
	Ad3DCrossProduct(&ba, &bc, &n_one);
	Ad3DCrossProduct(&bc, &cd, &n_two);
	Ad3DVectorLength(&n_one);
	Ad3DVectorLength(&n_two);

	//find the dot product of the two normal vectors to find the angle

	num = Ad3DDotProduct(&n_one, &n_two);
	denom = n_one.length*n_two.length;
	n2_n1 = n_two.length/n_one.length;
	n1_n2 = n_one.length/n_two.length;

	cosine_ang = num/denom;

	//check if the cosine of the angle is between -1 or 1. 
	//It could have slipped beyond these bounds becuase of the limits to precision of doubles

	if(cosine_ang > 1)
	{
		cosine_ang = 1;
		angle = 0;
	}
	else if(cosine_ang < -1)
	{
		cosine_ang = -1;
		angle = M_PI;
	}
	else
		angle = acos(cosine_ang);

	//calculate potential energy due to the bond

	*itor_pot += tor_cnst*(angle - equilibriumAngle)*(angle - equilibriumAngle);
	
#ifdef BASE_BONDED_DEBUG
	if(__HarmonicImproperTorsionEnergyDebug__)
	{
		//FIXME - Add force magnitude.
		//Currently not calculated explicitly
		fprintf(stderr, "%-6d%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			atom_three,
			atom_four,
			tor_cnst,
			equilibriumAngle,
			angle,
			*itor_pot);
	}
#endif
}


void AdHarmonicImproperTorsionForce(double* interaction, double **coordinates, double** forces, double* itor_pot)
{
	int i, j, counter;
	int atom_one, atom_two, atom_three, atom_four;
	double num, denom, cosine_ang, angle;
	double  n2_n1, n1_n2, equilibriumAngle, tor_cnst;
	double coffA, coffB;
	double dot[12], product[12];
	double *cumulativeForce;
	Vector3D n_one, n_two, ba, bc, cd, forceVector;

	//decode interaction

	atom_one = (int)interaction[0];
	atom_two = (int)interaction[1];
	atom_three = (int)interaction[2];
	atom_four = (int)interaction[3];
	tor_cnst = interaction[4];
	equilibriumAngle = interaction[5];

	//calculate vectors needed ba, bc, cd 

	for(i=3; --i>=0;)
	{
		*(ba.vector + i) = coordinates[atom_two][i] - coordinates[atom_one][i];
		*(bc.vector + i) = coordinates[atom_three][i] - coordinates[atom_two][i];
		*(cd.vector + i) = coordinates[atom_four][i] - coordinates[atom_three][i];
	}

	//calculate the cross product ba X bc, cd X cb
	
	Ad3DCrossProduct(&ba, &bc, &n_one);
	Ad3DCrossProduct(&bc, &cd, &n_two);
	Ad3DVectorLength(&n_one);
	Ad3DVectorLength(&n_two);

	//find the dot product of the two normal vectors to find the angle

	num = Ad3DDotProduct(&n_one, &n_two);
	denom = n_one.length*n_two.length;
	n2_n1 = n_two.length/n_one.length;
	n1_n2 = n_one.length/n_two.length;

	cosine_ang = num/denom;

	//check if the cosine of the angle is between -1 or 1. 
	//It could have slipped beyond these bounds becuase of the limits to precision of doubles

	if(cosine_ang > 1)
	{
		cosine_ang = 1;
		angle = 0;
	}
	else if(cosine_ang < -1)
	{
		cosine_ang = -1;
		angle = M_PI;
	}
	else
		angle = acos(cosine_ang);

	//the first derivative of the harmonic term wrt the angle
	
	coffA = 2*tor_cnst*(angle - equilibriumAngle);

	//calculate potential energy due to the torsion using above

	*itor_pot += coffA*(angle - equilibriumAngle)*0.5;

	/*
	 *Calculate the partial derivatives for the torsion angle = n1.n2/|n1||n2|	
	 *There are 12 pd's for n1.n2 and 12 for |n1||n2|. 
  	 *Its easier to calculate each of these individulally even though it looks long and complicated.
	 *Do it on an atom by atom basis. See comment below for more information.
	 */

	//atom 1

	dot[0] = bc.vector[2]*n_two.vector[1] - bc.vector[1]*n_two.vector[2];
	dot[1] = bc.vector[0]*n_two.vector[2] - bc.vector[2]*n_two.vector[0];
	dot[2] = bc.vector[1]*n_two.vector[0] - bc.vector[0]*n_two.vector[1];

	product[0] = n2_n1*(n_one.vector[1]*bc.vector[2] - n_one.vector[2]*bc.vector[1]); 
	product[1] = n2_n1*(n_one.vector[2]*bc.vector[0] - n_one.vector[0]*bc.vector[2]);
	product[2] = n2_n1*(n_one.vector[0]*bc.vector[1] - n_one.vector[1]*bc.vector[0]);
	
	//atom 2

	dot[3] = (ba.vector[1] + bc.vector[1])*n_two.vector[2] - 
		(ba.vector[2] + bc.vector[2])*n_two.vector[1] + 
		cd.vector[2]*n_one.vector[1] -
	 	cd.vector[1]*n_one.vector[2]; 

	dot[4] = (ba.vector[2] + bc.vector[2])*n_two.vector[0] - 
		(ba.vector[0] + bc.vector[0])*n_two.vector[2] + 
		cd.vector[0]*n_one.vector[2] - 
		cd.vector[2]*n_one.vector[0]; 

	dot[5] = (ba.vector[0] + bc.vector[0])*n_two.vector[1] - 
		(ba.vector[1] + bc.vector[1])*n_two.vector[0] + 
		cd.vector[1]*n_one.vector[0] - 
		cd.vector[0]*n_one.vector[1]; 
	
	product[3] = n2_n1*((ba.vector[1] + bc.vector[1])*n_one.vector[2] - (ba.vector[2] + bc.vector[2])*n_one.vector[1]) +
			n1_n2*(cd.vector[2]*n_two.vector[1] - cd.vector[1]*n_two.vector[2]);

	product[4] = n2_n1*((ba.vector[2] + bc.vector[2])*n_one.vector[0] - (ba.vector[0] + bc.vector[0])*n_one.vector[2]) + 
			n1_n2*(cd.vector[0]*n_two.vector[2] - cd.vector[2]*n_two.vector[0]);

	product[5] = n2_n1*((ba.vector[0] + bc.vector[0])*n_one.vector[1] - (ba.vector[1] + bc.vector[1])*n_one.vector[0]) + 
			n1_n2*(cd.vector[1]*n_two.vector[0] - cd.vector[0]*n_two.vector[1]);
	
	//atom 3

	dot[6] = (bc.vector[1] + cd.vector[1])*n_one.vector[2] - 
		(bc.vector[2] + cd.vector[2])*n_one.vector[1] + 
		ba.vector[2]*n_two.vector[1] - 
		ba.vector[1]*n_two.vector[2]; 

	dot[7] = (bc.vector[2] + cd.vector[2])*n_one.vector[0] - 
		(bc.vector[0] + cd.vector[0])*n_one.vector[2] + 
		ba.vector[0]*n_two.vector[2] - 
		ba.vector[2]*n_two.vector[0]; 

	dot[8] = (bc.vector[0] + cd.vector[0])*n_one.vector[1] - 
		(bc.vector[1] + cd.vector[1])*n_one.vector[0] + 
		ba.vector[1]*n_two.vector[0] - 
		ba.vector[0]*n_two.vector[1]; 
	
	product[6] = n1_n2*((bc.vector[1] + cd.vector[1])*n_two.vector[2] - (bc.vector[2] + cd.vector[2])*n_two.vector[1]) + 
			n2_n1*(ba.vector[2]*n_one.vector[1] - ba.vector[1]*n_one.vector[2]);

	product[7] = n1_n2*((bc.vector[2] + cd.vector[2])*n_two.vector[0] - (bc.vector[0] + cd.vector[0])*n_two.vector[2]) + 
			n2_n1*(ba.vector[0]*n_one.vector[2] - ba.vector[2]*n_one.vector[0]);

	product[8] = n1_n2*((bc.vector[0] + cd.vector[0])*n_two.vector[1] - (bc.vector[1] + cd.vector[1])*n_two.vector[0]) +
		 	n2_n1*(ba.vector[1]*n_one.vector[0] - ba.vector[0]*n_one.vector[1]);
	
	//atom 4
	
	dot[9] =  bc.vector[2]*n_one.vector[1] - bc.vector[1]*n_one.vector[2];
	dot[10] = bc.vector[0]*n_one.vector[2] - bc.vector[2]*n_one.vector[0];
	dot[11] = bc.vector[1]*n_one.vector[0] - bc.vector[0]*n_one.vector[1];
	
	product[9] =  n1_n2*(n_two.vector[1]*bc.vector[2] - n_two.vector[2]*bc.vector[1]); 
	product[10] = n1_n2*(n_two.vector[2]*bc.vector[0] - n_two.vector[0]*bc.vector[2]);
	product[11] = n1_n2*(n_two.vector[0]*bc.vector[1] - n_two.vector[1]*bc.vector[0]);


	/**	
		The derivative of an atom coordinate, i,  w.r.t. to the angle is 
		
		[(|n1||n2|)*(n1.n2)' - (n1.n2)(|n1||n2|)']/(|n1||n2|)^2  

		where ' indicates the derivative of the expression in brackets w.r.t. i.

		The force component along i is then the above multiplied by coffA (see above).
		However we can reduce the number of muliplications needed by a little
		manipulation of the above expression
		i.e by combining all the nonderivatives into coefficents -

		A*(n1.n2)' - B*(|n1||n2|)'

		where A = coffA/(|n1||n2|)
		and   B = (coffA*(n1.n2))/(|n1||n2|)^2

		Above we put |n1||n2| = denom and n1.n2 = num
	**/

	coffA = coffA/denom;
	coffB = (coffA*num)/denom;

	for(counter=0, i=0; i< 4; i++)
	{
		cumulativeForce = forces[(int)interaction[i]];

		for(j=0; j<3; j++, counter++)
			forceVector.vector[j] = (coffA*dot[counter] - coffB*product[counter]);

		//add the force vector to the atoms total force vector

		for(j=0; j<3; j++)
			cumulativeForce[j] += forceVector.vector[j];
	}
	
#ifdef BASE_BONDED_DEBUG
	if(__HarmonicImproperTorsionForceDebug__)
	{
		//FIXME - Add force magnitude.
		//Currently not calculated explicitly
		fprintf(stderr, "%-6d%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			atom_three,
			atom_four,
			tor_cnst,
			equilibriumAngle,
			angle,
			*itor_pot);
	}
#endif
}

