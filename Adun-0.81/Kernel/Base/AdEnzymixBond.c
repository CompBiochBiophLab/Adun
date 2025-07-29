/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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

/**
\note Using double quotes here with icc causes
many "function x referenced but not defined"
for external functions. I cannot figure this
out at all..
*/
#include <Base/AdForceFieldFunctions.h>

double AdCalculateAtomSeparation(int* atomIndexes, double **coordinates)
{
	register int i;
	int indexOne, indexTwo;
	Vector3D seperation_s;
	
	//Get atom indexes
	indexOne = atomIndexes[0];
	indexTwo = atomIndexes[1];
	
	//calculate interatomic distance
	for(i=3; --i>=0;)
		*(seperation_s.vector + i) = coordinates[indexOne][i] - coordinates[indexTwo][i];
	
	//calculate the length of the seperation vector
	
	Ad3DVectorLength(&seperation_s);	
	
	return seperation_s.length;
}

double AdCalculateEnzymixBondEnergy(double bondDistance, double equilibriumDistance, double bondConstant)
{
	return bondConstant*pow((bondDistance - equilibriumDistance), 2);
}

double AdCalculateHarmonicBondEnergy(double bondDistance, double equilibriumDistance, double bondConstant)
{
	return 0.5*bondConstant*pow((bondDistance - equilibriumDistance), 2);
}

/**
Enxymix bond functions. Enzymix force field uses k*(x-x0)² instead of k/2*(x-xo)²
like other force fields
*/

void AdEnzymixBondEnergy(double* bond, double **coordinates, double* bnd_pot)
{
	register int i;
	int atom_one, atom_two;
	double eq_sep, bnd_cnst, forceMag;
	Vector3D seperation_s;

	//translate the information in bond

	atom_one = (int)bond[0];
	atom_two = (int)bond[1];
	bnd_cnst = bond[2];	
	eq_sep = bond[3];

	//calculate interatomic distance
	
	for(i=3; --i>=0;)
		*(seperation_s.vector + i) = coordinates[atom_two][i] - coordinates[atom_one][i];

	//calculate the length of the seperation vector

	Ad3DVectorLength(&seperation_s);

	//calcualte acceleration magnitude

	forceMag = -1*bnd_cnst*(seperation_s.length - eq_sep);

	//calculate potential

	*bnd_pot = *bnd_pot - forceMag*(seperation_s.length - eq_sep);
	
#ifdef BASE_BONDED_DEBUG
	if(__HarmonicBondEnergyDebug__)
	{
		fprintf(stderr, "%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			bnd_cnst,
			eq_sep,
			seperation_s.length,
			*bnd_pot);
	}
#endif
}

void AdEnzymixBondForce(double* bond, double** coordinates, double** forces, double* bnd_pot)
{
	register int i;
	int atom_one, atom_two;
	double forceMag, eq_sep, bnd_cnst, holder, rlength;
	Vector3D seperation_s;

	//translate the information in bond

	atom_one = (int)bond[0];
	atom_two = (int)bond[1];
	bnd_cnst = bond[2];	
	eq_sep = bond[3];

	//calculate interatomic distance
	
	for(i=3; --i>=0;)
		*(seperation_s.vector + i) = coordinates[atom_two][i] - coordinates[atom_one][i];

	//calculate the length of the seperation vector

	Ad3DVectorLength(&seperation_s);

	//calcualte acceleration magnitude

	forceMag = -1*bnd_cnst*(seperation_s.length - eq_sep);

	//calculate potential

	*bnd_pot = *bnd_pot - forceMag*(seperation_s.length - eq_sep);

	rlength = 1/seperation_s.length;

	//calculate acceleration on atom one

	for(i=0; i<3; i++)
	{	
		holder = 2*forceMag*seperation_s.vector[i]*rlength;
		forces[atom_two][i] += holder;
		forces[atom_one][i] -= holder;
	}
	
#ifdef BASE_BONDED_DEBUG
	if(__CheckForceMagnitude__)
	{
		if(isnan(forceMag) || isinf(forceMag))
		{	
			fprintf(stderr, "Detected invalid force\n");
			AdHarmonicBondDebugInfo();
			fprintf(stderr, "%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
				atom_one,
				atom_two,
				bnd_cnst,
				eq_sep,
				seperation_s.length,
				*bnd_pot,
				forceMag);
			
		}
	}

	if(__HarmonicBondForceDebug__ == true)
	{
		fprintf(stderr, "%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.5lf\n",
			atom_one,
			atom_two,
			bnd_cnst,
			eq_sep,
			seperation_s.length,
			*bnd_pot,
			2*forceMag);
	}
#endif
}


