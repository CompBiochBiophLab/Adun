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

bool __HarmonicAngleEnergyDebug__ = false;
bool __HarmonicAngleForceDebug__ = false;

void AdHarmonicAngleDebugInfo(void)
{
	fprintf(stderr, "\nHarmonic angle debug on\n");
	fprintf(stderr, "Energy Info - Atom one, Atom two, Atom three");
	fprintf(stderr, " Angle constant, Equilibrium Angle, Cosine Angle, Calculated Angle, Cumulative Potential\n\n");
}

void AdHarmonicAngleForce(double *interaction, double **coordinates, double **forces, double *ang_pot)
{
	register int i;
	int atom_one, atom_two, atom_three; 
	double coff_A, ang_cnst, eq_ang;
	double cosine_ang, angle, d_theta, forceMag;
	double forceOne, forceThree;
	double numerator, denominator, dtheta_du; 
	Vector3D ba_v, bc_v;

	//decode interaction
	atom_one = (int)interaction[0];
	atom_two = (int)interaction[1];
	atom_three = (int)interaction[2];
	ang_cnst = interaction[3];	
	eq_ang = interaction[4];

	//find the two vectors ba_v, bc_v
	for(i=0; i<3; i++)
	{
		ba_v.vector[i] = coordinates[atom_one][i] - coordinates[atom_two][i];
		bc_v.vector[i] = coordinates[atom_three][i] - coordinates[atom_two][i];
	}
	
	//ba.bc/|ba||bc| = cos(theta)
	//therefore calculate ba.bc 
	numerator = Ad3DDotProduct(&ba_v, &bc_v);
	
	//now find the length of ba and bc
	Ad3DVectorLength(&ba_v);
	Ad3DVectorLength(&bc_v);

	//find |ba|*|bc|
	denominator = ba_v.length*bc_v.length;

	//now calculate cosine of theta
	cosine_ang = numerator/denominator;
	
#ifdef SAFE_ANGLE	
	//check if the cosin_ang has slipped beyond 
	//the valid range due to numerical imprecision.
	if(cosine_ang > 1)
		cosine_ang = 1;
	else if(cosine_ang < -1)
		cosine_ang = -1;
#endif
	//find the associated angle
	angle = acos(cosine_ang);

	//calculate d_theta and hence the potential and the angular acceleration 
	d_theta =  angle - eq_ang;
	forceMag = -ang_cnst*d_theta;
	*ang_pot -= forceMag*d_theta*0.5;

	//find dtheta_du
	dtheta_du = (1 - cosine_ang*cosine_ang);
	dtheta_du = -1/sqrt(dtheta_du);

	//calculate coff_A 
	coff_A = (forceMag*dtheta_du);

	//find the nine partial derivatives needed
	for(i=0; i<3;i++)
	{
		forceOne = (coff_A/denominator)*( bc_v.vector[i] - (bc_v.length/ba_v.length)*cosine_ang*ba_v.vector[i]);
		forceThree = (coff_A/denominator)*( ba_v.vector[i] - (ba_v.length/bc_v.length)*cosine_ang*bc_v.vector[i]);

		forces[atom_two][i] -= (forceOne + forceThree);
		forces[atom_one][i] += forceOne;
		forces[atom_three][i] += forceThree;
	}
	
#ifdef BASE_BONDED_DEBUG
	if(__CheckForceMagnitude__)
	{
		if(isnan(forceMag) || isinf(forceMag) || isnan(coff_A) || isinf(coff_A))
		{	
			fprintf(stderr, "Detected invalid force\n");
			AdHarmonicAngleDebugInfo();
			fprintf(stderr, "%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
				atom_one,
				atom_two,
				atom_three,
				ang_cnst,
				eq_ang,
				angle,
				*ang_pot,
				forceMag);
		}
	}

	if(__HarmonicAngleForceDebug__)
	{
		fprintf(stderr, "%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			atom_three,
			ang_cnst,
			eq_ang,
			angle,
			*ang_pot,
			forceMag);
	}
#endif
}

void AdHarmonicAngleEnergy(double* interaction, double** coordinates, double* ang_pot)
{
	register int i;
	int atom_one, atom_two, atom_three; 
	double ang_cnst, eq_ang;
	double cosine_ang, angle, d_theta, forceMag;
	double numerator, denominator; 
	Vector3D ba_v, bc_v;

	//decode interaction
	atom_one = (int)interaction[0];
	atom_two = (int)interaction[1];
	atom_three = (int)interaction[2];
	ang_cnst = interaction[3];	
	eq_ang = interaction[4];

	//find the two vectors ba_v, bc_v
	for(i=0; i<3; i++)
	{
		ba_v.vector[i] = coordinates[atom_one][i] - coordinates[atom_two][i];
		bc_v.vector[i] = coordinates[atom_three][i] - coordinates[atom_two][i];
	}
	
	//ba.bc/|ba||bc| = cos(theta)
	//therefore calculate ba.bc 
	numerator = Ad3DDotProduct(&ba_v, &bc_v);
	
	//now find the length of ba and bc
	Ad3DVectorLength(&ba_v);
	Ad3DVectorLength(&bc_v);

	//find |ba|*|bc|
	denominator = ba_v.length*bc_v.length;

	//now calculate cosine of theta
	cosine_ang = numerator/denominator;
	
#ifdef SAFE_ANGLE	
	//check if the cosin_ang has slipped beyond 
	//the valid range due to numerical imprecision.
	if(cosine_ang > 1)
		cosine_ang = 1;
	else if(cosine_ang < -1)
		cosine_ang = -1;
#endif		

	//find the associated angle
	angle = acos(cosine_ang);

	//calculate d_theta and hence the potential and the angular acceleration 
	d_theta =  angle - eq_ang;
	forceMag = -ang_cnst*d_theta;
	*ang_pot -= forceMag*d_theta*0.5;
	
#ifdef BASE_BONDED_DEBUG
	if(__HarmonicAngleEnergyDebug__)
	{
		fprintf(stderr, "%-6d%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf%\n",
			atom_one,
			atom_two,
			atom_three,
			ang_cnst,
			eq_ang,
			cosine_ang,
			angle,
			*ang_pot);
	}
#endif
}
