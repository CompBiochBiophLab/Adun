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

#include <Base/AdForceFieldFunctions.h>

bool __FourierTorsionEnergyDebug__ = false;
bool __FourierTorsionForceDebug__ = false;

void AdFourierTorsionDebugInfo(void)
{
	fprintf(stderr, "\nFourier torsion debug on\n");
	fprintf(stderr, "Energy Info - Atom one, Atom two, Atom three, Atom four");
	fprintf(stderr, " Torsion constant, Period, Phase, Calculated Angle, Cumulative Potential\n\n");
}

double AdCalculateFourierTorsionEnergy(double angle, double period, double phase, double torsionConstant)
{
	return torsionConstant*(1 + cos(period*angle - phase)); 
}

void AdFourierTorsionEnergy(double *interaction, double** coordinates, double* tor_pot)
{
	register int i;
	int atom_one, atom_two, atom_three, atom_four;
	double num, denom, cosine_ang, angle;
	double  n2_n1, n1_n2, period, phase, holder, tor_cnst;
	Vector3D n_one, n_two, ba, bc, cd;

	//decode interaction

	atom_one = (int)interaction[0];
	atom_two = (int)interaction[1];
	atom_three = (int)interaction[2];
	atom_four = (int)interaction[3];
	tor_cnst = interaction[4];
	period = interaction[5];
	phase = interaction[6];

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

	if(cosine_ang >= 1)
	{
		cosine_ang = 1;
		angle = 1E-15;
	}
	else if(cosine_ang <= -1)
	{
		cosine_ang = -1;
		angle = M_PI;
	}
	else
		angle = acos(cosine_ang);

	//calculate potential energy due to the interaction

	if(phase == 0)
	{
		holder = cos(period*angle);
		if(isnan(holder))
		{
			fprintf(stderr, "AdFourierTorsion - ERROR\n");
			fprintf(stderr, "Angle %lf. Period %lf\n", angle, period);
			fprintf(stderr, "Cosine %lf. Numerator %lf. Denominator %lf\n",
				cosine_ang, num, denom);
			fprintf(stderr, "Atoms %d %d %d %d\n",
				atom_one, atom_two, atom_three, atom_four);
			fprintf(stderr, "Force constant %lf. Phase %lf\n",
				tor_cnst, phase);
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_one][0],	
				coordinates[atom_one][1],	
				coordinates[atom_one][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_two][0],	
				coordinates[atom_two][1],	
				coordinates[atom_two][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_three][0],	
				coordinates[atom_three][1],	
				coordinates[atom_three][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_four][0],	
				coordinates[atom_four][1],	
				coordinates[atom_four][2]);	
			fflush(stderr);	
		}
			
		
		*tor_pot += tor_cnst*(1 + holder);
	}
	else if(phase == M_PI)
	{
		holder = cos(period*angle);
		if(isnan(holder))
		{
			fprintf(stderr, "AdFourierTorsion - ERROR\n");
			fprintf(stderr, "Angle %lf. Period %lf\n", angle, period);
			fprintf(stderr, "Cosine %lf. Numerator %lf. Denominator %lf\n",
				cosine_ang, num, denom);
			fprintf(stderr, "Atoms %d %d %d %d\n",
				atom_one, atom_two, atom_three, atom_four);
			fprintf(stderr, "Force constant %lf. Phase %lf\n",
				tor_cnst, phase);
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_one][0],	
				coordinates[atom_one][1],	
				coordinates[atom_one][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_two][0],	
				coordinates[atom_two][1],	
				coordinates[atom_two][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_three][0],	
				coordinates[atom_three][1],	
				coordinates[atom_three][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_four][0],	
				coordinates[atom_four][1],	
				coordinates[atom_four][2]);	
			fflush(stderr);	
		}

		*tor_pot += tor_cnst*(1 - holder);
	}
	else
	{
		holder = cos(period*angle - phase);
		if(isnan(holder))
		{
			fprintf(stderr, "AdFourierTorsion - ERROR\n");
			fprintf(stderr, "Angle %lf. Period %lf\n", angle, period);
			fprintf(stderr, "Cosine %lf. Numerator %lf. Denominator %lf\n",
				cosine_ang, num, denom);
			fprintf(stderr, "Atoms %d %d %d %d\n",
				atom_one, atom_two, atom_three, atom_four);
			fprintf(stderr, "Force constant %lf. Phase %lf\n",
				tor_cnst, phase);
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_one][0],	
				coordinates[atom_one][1],	
				coordinates[atom_one][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_two][0],	
				coordinates[atom_two][1],	
				coordinates[atom_two][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_three][0],	
				coordinates[atom_three][1],	
				coordinates[atom_three][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_four][0],	
				coordinates[atom_four][1],	
				coordinates[atom_four][2]);	
			fflush(stderr);	
		}

		*tor_pot += tor_cnst*(1 + holder);
	}
	
#ifdef BASE_BONDED_DEBUG
	if(__FourierTorsionEnergyDebug__)
	{
		fprintf(stderr, "%-6d%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			atom_three,
			atom_four,
			tor_cnst,
			period,
			phase,
			angle,
			*tor_pot);
	}
#endif
}

int AdFourierTorsionForce(double *interaction, double** coordinates, double** forces, double *tor_pot)
{
	register int i, j;
	int counter;
	int atom_one, atom_two, atom_three, atom_four;
	double num, denom, cosine_ang, angle;
	double A, B, n2_n1, n1_n2, period, phase, holder, tor_cnst;
	double dot[12], product[12];
	double *forceVector;
	Vector3D n_one, n_two, ba, bc, cd, torsionForce;
	int error=0;

	//decode interaction
	
	atom_one = (int)interaction[0];
	atom_two = (int)interaction[1];
	atom_three = (int)interaction[2];
	atom_four = (int)interaction[3];
	tor_cnst = interaction[4];
	period = interaction[5];
	phase = interaction[6];

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
	
	if(cosine_ang >= 1)
	{
		cosine_ang = 1;
		angle = 1E-15;
	}
	else if(cosine_ang <= -1)
	{
		cosine_ang = -1;
		angle = M_PI;
	}
	else
		angle = acos(cosine_ang);

	//find some reoccuring quantities and common premultiplication factors now

	/*
	 * The derivative is df/dtheta * dtheta/du * du/dr 
	 * There are twelve partial derivates of du/dr however the first part is constant
	 * and is given by
	 *
	 * -nK[sin(n*theta)cos(gamma) - cos(n*theta)sin(gamma)]/sin(theta)
	 *
	 * where n is the period, K is the constant and gamma is the phase.
	 * Below this is called A. However typically n is 2 or 3 and gamma is 0 or 180.
	 * These cases lead to a simplification of the above.
	 * 
	 * n=2, gamma=0
	 *
	 * -4*K*cos(\theta)
	 *
	 * n = 3, gamma=0
	 *
	 * -12*K*cos(theta)*cos(theta) - 3*K
	 *
	 * gamma = 180 simply changes the sign.
	 * 
	 * If n is one then it everything reduces to k or -k.
	 *
	 * du/dr also can be written as
	 *
	 * [f'(r) - cos(theta)g'(r)]/|n1||n2| 
	 *
	 * Here f'(r) is the derivative of n1.n2 w.r.t. r and
	 * g'(r) is the derivative of |n1||n2| w.r.t. r. 
	 * 
	 * In the following the denominator |n1||n2| has been incorporated into A
	 */
	
	if(phase==0 || phase == M_PI)
	{
		if(period == 1)
		{
			A = -tor_cnst;
		}
		else if(period == 2)
		{
			A = -4*tor_cnst*cosine_ang; 	
		}
		else if(period == 3)
		{
			A = -12*tor_cnst*cosine_ang*cosine_ang - 3*tor_cnst;
		}
		else
			A = -1*tor_cnst*sin(period*angle)/sin(angle);

		if(phase==M_PI)
			A *= -1;
	}	
	else
	{
		A = -1*tor_cnst*(sin(period*angle)*cos(phase) - 
			cos(period*angle)*sin(phase))/sin(angle);
	}

	A /= denom;

	//calculate potential energy due to the interaction

	if(phase == 0)
	{
		holder = cos(period*angle);
		if(isnan(holder))
		{
			fprintf(stderr, "AdFourierTorsion - ERROR\n");
			fprintf(stderr, "Angle %lf. Period %lf\n", angle, period);
			fprintf(stderr, "Cosine %lf. Numerator %lf. Denominator %lf\n",
				cosine_ang, num, denom);
			fprintf(stderr, "Atoms %d %d %d %d\n",
				atom_one, atom_two, atom_three, atom_four);
			fprintf(stderr, "Force constant %lf. Phase %lf\n",
				tor_cnst, phase);
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_one][0],	
				coordinates[atom_one][1],	
				coordinates[atom_one][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_two][0],	
				coordinates[atom_two][1],	
				coordinates[atom_two][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_three][0],	
				coordinates[atom_three][1],	
				coordinates[atom_three][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_four][0],	
				coordinates[atom_four][1],	
				coordinates[atom_four][2]);	
			fflush(stderr);	
			error=1;
		}
		
		*tor_pot += tor_cnst*(1 + holder);
	}
	else if(phase == M_PI)
	{
		holder = cos(period*angle);
		if(isnan(holder))
		{
			fprintf(stderr, "AdFourierTorsion - ERROR\n");
			fprintf(stderr, "Angle %lf. Period %lf\n", angle, period);
			fprintf(stderr, "Cosine %lf. Numerator %lf. Denominator %lf\n",
				cosine_ang, num, denom);
			fprintf(stderr, "Atoms %d %d %d %d\n",
				atom_one, atom_two, atom_three, atom_four);
			fprintf(stderr, "Force constant %lf. Phase %lf\n",
				tor_cnst, phase);
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_one][0],	
				coordinates[atom_one][1],	
				coordinates[atom_one][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_two][0],	
				coordinates[atom_two][1],	
				coordinates[atom_two][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_three][0],	
				coordinates[atom_three][1],	
				coordinates[atom_three][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_four][0],	
				coordinates[atom_four][1],	
				coordinates[atom_four][2]);	
			fflush(stderr);	
			error=1;
		}

		*tor_pot += tor_cnst*(1 - holder);
	}	
	else
	{
		holder = cos(period*angle - phase);
		if(isnan(holder))
		{
			fprintf(stderr, "AdFourierTorsion - ERROR\n");
			fprintf(stderr, "Angle %lf. Period %lf\n", angle, period);
			fprintf(stderr, "Cosine %lf. Numerator %lf. Denominator %lf\n",
				cosine_ang, num, denom);
			fprintf(stderr, "Atoms %d %d %d %d\n",
				atom_one, atom_two, atom_three, atom_four);
			fprintf(stderr, "Force constant %lf. Phase %lf\n",
				tor_cnst, phase);
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_one][0],	
				coordinates[atom_one][1],	
				coordinates[atom_one][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_two][0],	
				coordinates[atom_two][1],	
				coordinates[atom_two][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_three][0],	
				coordinates[atom_three][1],	
				coordinates[atom_three][2]);	
			fprintf(stderr, "%-12lf %-12lf %-12lf\n",
				coordinates[atom_four][0],	
				coordinates[atom_four][1],	
				coordinates[atom_four][2]);	
			fflush(stderr);	
			error=1;
		}

		*tor_pot += tor_cnst*(1 + holder);
	}
	
	B = A*cosine_ang;

	/*
	 *Calculate the partial derivatives	
	 *There are 12 pd's for n1.n2 and 12 for |n1||n2|. 
  	 *Its easier to calculate each of these individulally even though it looks long and complicated.
	 *Do it on an atom by atom basis
	 * 
	 */

	//atom 1

	dot[0] = bc.vector[2]*n_two.vector[1] - bc.vector[1]*n_two.vector[2];
	dot[1] = bc.vector[0]*n_two.vector[2] - bc.vector[2]*n_two.vector[0];
	dot[2] = bc.vector[1]*n_two.vector[0] - bc.vector[0]*n_two.vector[1];

	product[0] = n2_n1*(n_one.vector[1]*bc.vector[2] - n_one.vector[2]*bc.vector[1]); 
	product[1] = n2_n1*(n_one.vector[2]*bc.vector[0] - n_one.vector[0]*bc.vector[2]);
	product[2] = n2_n1*(n_one.vector[0]*bc.vector[1] - n_one.vector[1]*bc.vector[0]);
	
	//atom 2

	dot[3] = (ba.vector[1] + bc.vector[1])*n_two.vector[2] - (ba.vector[2] + bc.vector[2])*n_two.vector[1] + cd.vector[2]*n_one.vector[1] - cd.vector[1]*n_one.vector[2]; 
	dot[4] = (ba.vector[2] + bc.vector[2])*n_two.vector[0] - (ba.vector[0] + bc.vector[0])*n_two.vector[2] + cd.vector[0]*n_one.vector[2] - cd.vector[2]*n_one.vector[0]; 
	dot[5] = (ba.vector[0] + bc.vector[0])*n_two.vector[1] - (ba.vector[1] + bc.vector[1])*n_two.vector[0] + cd.vector[1]*n_one.vector[0] - cd.vector[0]*n_one.vector[1]; 
	
	product[3] = n2_n1*((ba.vector[1] + bc.vector[1])*n_one.vector[2] - (ba.vector[2] + bc.vector[2])*n_one.vector[1]) + n1_n2*(cd.vector[2]*n_two.vector[1] - cd.vector[1]*n_two.vector[2]);
	product[4] = n2_n1*((ba.vector[2] + bc.vector[2])*n_one.vector[0] - (ba.vector[0] + bc.vector[0])*n_one.vector[2]) + n1_n2*(cd.vector[0]*n_two.vector[2] - cd.vector[2]*n_two.vector[0]);
	product[5] = n2_n1*((ba.vector[0] + bc.vector[0])*n_one.vector[1] - (ba.vector[1] + bc.vector[1])*n_one.vector[0]) + n1_n2*(cd.vector[1]*n_two.vector[0] - cd.vector[0]*n_two.vector[1]);
	
	//atom 3

	dot[6] = (bc.vector[1] + cd.vector[1])*n_one.vector[2] - (bc.vector[2] + cd.vector[2])*n_one.vector[1] + ba.vector[2]*n_two.vector[1] - ba.vector[1]*n_two.vector[2]; 
	dot[7] = (bc.vector[2] + cd.vector[2])*n_one.vector[0] - (bc.vector[0] + cd.vector[0])*n_one.vector[2] + ba.vector[0]*n_two.vector[2] - ba.vector[2]*n_two.vector[0]; 
	dot[8] = (bc.vector[0] + cd.vector[0])*n_one.vector[1] - (bc.vector[1] + cd.vector[1])*n_one.vector[0] + ba.vector[1]*n_two.vector[0] - ba.vector[0]*n_two.vector[1]; 
	
	product[6] = n1_n2*((bc.vector[1] + cd.vector[1])*n_two.vector[2] - (bc.vector[2] + cd.vector[2])*n_two.vector[1]) + n2_n1*(ba.vector[2]*n_one.vector[1] - ba.vector[1]*n_one.vector[2]);
	product[7] = n1_n2*((bc.vector[2] + cd.vector[2])*n_two.vector[0] - (bc.vector[0] + cd.vector[0])*n_two.vector[2]) + n2_n1*(ba.vector[0]*n_one.vector[2] - ba.vector[2]*n_one.vector[0]);
	product[8] = n1_n2*((bc.vector[0] + cd.vector[0])*n_two.vector[1] - (bc.vector[1] + cd.vector[1])*n_two.vector[0]) + n2_n1*(ba.vector[1]*n_one.vector[0] - ba.vector[0]*n_one.vector[1]);
	

	//atom 4
	
	dot[9] =  bc.vector[2]*n_one.vector[1] - bc.vector[1]*n_one.vector[2];
	dot[10] = bc.vector[0]*n_one.vector[2] - bc.vector[2]*n_one.vector[0];
	dot[11] = bc.vector[1]*n_one.vector[0] - bc.vector[0]*n_one.vector[1];
	
	product[9] =  n1_n2*(n_two.vector[1]*bc.vector[2] - n_two.vector[2]*bc.vector[1]); 
	product[10] = n1_n2*(n_two.vector[2]*bc.vector[0] - n_two.vector[0]*bc.vector[2]);
	product[11] = n1_n2*(n_two.vector[0]*bc.vector[1] - n_two.vector[1]*bc.vector[0]);
	
	counter = 0;

	for(i=0; i< 4; i++)
	{
		forceVector = forces[(int)interaction[i]];

		for(j=0; j<3; j++)
		{
			torsionForce.vector[j] = (A*dot[counter] - B*product[counter]);
			counter += 1;
		}

		//add the an acceleration vector to the atoms total acceleration vector

		for(j=0; j<3; j++)
			forceVector[j] += torsionForce.vector[j];
	}
	
#ifdef BASE_BONDED_DEBUG
	if(__FourierTorsionForceDebug__)
	{
		//FIXME - Add force magnitude.
		//Currently not calculated explicitly
		fprintf(stderr, "%-6d%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			atom_three,
			atom_four,
			tor_cnst,
			period,
			phase,
			angle,
			*tor_pot);
	}
#endif
	return error;
}

double AdCalculateTorsionAngle(int* torsion, double** coordinates)
{
	register int i;
	int atom_one, atom_two, atom_three, atom_four;
	double num, denom, cosine_ang, angle;
	double n2_n1, n1_n2;
	Vector3D n_one, n_two, ba, bc, cd;

	atom_one = torsion[0];
	atom_two = torsion[1];
	atom_three = torsion[2];
	atom_four = torsion[3];

	//Calculate vectors needed ba, bc, cd 
	for(i=3; --i>=0;)
	{
		*(ba.vector + i) = coordinates[atom_two][i] - coordinates[atom_one][i];
		*(bc.vector + i) = coordinates[atom_three][i] - coordinates[atom_two][i];
		*(cd.vector + i) = coordinates[atom_four][i] - coordinates[atom_three][i];
	}

	//Calculate the cross product ba X bc, cd X cb
	Ad3DCrossProduct(&ba, &bc, &n_one);
	Ad3DCrossProduct(&bc, &cd, &n_two);
	Ad3DVectorLength(&n_one);
	Ad3DVectorLength(&n_two);

	//Find the dot product of the two normal vectors to find the angle
	num = Ad3DDotProduct(&n_one, &n_two);
	denom = n_one.length*n_two.length;
	n2_n1 = n_two.length/n_one.length;
	n1_n2 = n_one.length/n_two.length;

	cosine_ang = num/denom;

	//Check if the cosine of the angle is between -1 or 1. 
	//It could have slipped beyond these bounds becuase of the limits to precision of doubles
	if(cosine_ang >= 1)
	{
		cosine_ang = 1;
		angle = 1E-15;
	}
	else if(cosine_ang <= -1)
	{
		cosine_ang = -1;
		angle = M_PI;
	}
	else
		angle = acos(cosine_ang);

	return angle;
}
