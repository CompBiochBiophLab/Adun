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

bool __NonbondedEnergyDebug__ = false;
bool __NonbondedForceDebug__ = false;
bool __ShiftedNonbondedEnergyDebug__ = false;
bool __ShiftedNonbondedForceDebug__ = false;
bool __GRFNonbondedEnergyDebug__ = false;
bool __GRFNonbondedForceDebug__ = false;

void AdNonbondedDebugInfo(void)
{
	fprintf(stderr, "\nNonbonded debug on\n");
	fprintf(stderr, "Energy Info - Calc Type, Lennard Jones Type, Atom one, Atom two, Parameter A");
	fprintf(stderr, " Parameter B, Charge Product, Separation, Cumulative EST Potential, Cumulative LJ Potential\n");
	fprintf(stderr, "Parameter A and B will depend on LJ Type\n");
	fprintf(stderr, "Force Info - Same as energy plus force magnitude as last value\n\n");
}

void AdNonbondedEnergyLog(char* cutType, char* ljType, int a1, int a2, double ljA,
		double ljB, double charge, double sep, double estPot, double ljPot, bool flag)
{
	if(flag)
		fprintf(stderr, "%-8s%-3s%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.lf%-12.5lf\n",
			cutType, ljType, a1, a2, ljA, ljB, charge, sep, estPot, ljPot);
}

void AdNonbondedForceLog(char* cutType, char* ljType, int a1, int a2, double ljA,
		double ljB, double charge, double sep, double estPot, double ljPot, double force, bool flag)
{
	if(__CheckForceMagnitude__)
	{
		if(isnan(force) || isinf(force))
		{	
			fprintf(stderr, "Detected invalid force\n");
			AdNonbondedDebugInfo();
			fprintf(stderr, "%-8s%-3s%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.lf%-12.5lf%-12.5lf\n",
				cutType, ljType, a1, a2, ljA, ljB, charge, sep, estPot, ljPot, force);	
		}
	}

	if(flag)
		fprintf(stderr, "%-8s%-3s%-6d%-6d%-12.5lf%-12.5lf%-12.5lf%-12.5lf%-12.lf%-12.5lf%-12.5lf\n",
			cutType, ljType, a1, a2, ljA, ljB, charge, sep, estPot, ljPot, force);	
}

double AdCoulombEnergy(double separation, double chargeOne, double chargeTwo, double relativePermittivity, double constant)
{
	return (1/relativePermittivity)*constant*chargeOne*chargeTwo/pow(separation, 2);
}

double AdLennardJonesAEnergy(double separation, double a1, double b1, double a2, double b2)
{
	double holder;

	holder = pow((1/separation), 6);
	
	return (a1*a2)*pow(holder, 2) - (b1*b2)*holder;
}

double AdLennardJonesBEnergy(double separation, double wellDepth1, double equilibriumSeparation1, 
					double wellDepth2, double equilibriumSeparation2)
{
	double holder, wellDepth, equilibriumSeparation;

	wellDepth = sqrt(wellDepth1*wellDepth2);
	equilibriumSeparation = equilibriumSeparation1 + equilibriumSeparation2;
	holder = pow((equilibriumSeparation/separation), 6);
	
	return 4*wellDepth*(pow(holder, 2) - holder);
}

void AdCoulombAndLennardJonesAEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cutoff,
		double* vdw_pot, 
		double* est_pot)
{
	int atom_one, atom_two;
	double length_rec, vdw_hold, est_hold;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];

	//calculate seperation vector (r1 - r2)
	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];
	
	//calculate the interatomic distance
	Ad3DVectorLength(&seperation_s);
	
	//add this length to the linked list element the bond belongs to
	interaction->length = seperation_s.length;
	
	if(seperation_s.length > cutoff)
		return;

	//get reciprocal of seperation
	length_rec = 1/seperation_s.length;
	
	vdw_hold = pow(length_rec, 6);
	est_hold = (EPSILON_RP*chargeProduct*length_rec);
	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;

	*est_pot += est_hold;
	*vdw_pot += lennardJonesA - lennardJonesB;	

#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedEnergyLog("Normal", "A", atom_one, atom_two, lennardJonesA, lennardJonesB, 
		chargeProduct, seperation_s.length, est_hold, (lennardJonesA - lennardJonesB),
		__NonbondedEnergyDebug__); 
#endif	
}

void AdCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cutoff,
		double* vdw_pot, 
		double* est_pot)
{
	int atom_one, atom_two;
	double force_mag;
	double length_rec, vdw_hold, est_hold;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];
			
	//calculate seperation vector (r1 - r2)
	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];
	
	//calculate the interatomic distance
	Ad3DVectorLength(&seperation_s);

	//add this length to the linked list element the bond belongs to
	interaction->length = seperation_s.length;

	if(seperation_s.length > cutoff)
		return;
				
	//get reciprocal of seperation
	length_rec = 1/seperation_s.length;
	
	//calculate vdw holder
	vdw_hold = pow(length_rec, 6);

	//while this is being calculate 
	//calculate some non dependant variables

	//est holder
	est_hold = EPSILON_RP*chargeProduct*length_rec;

	//vdw holder may be finished now so calculate vdw consts
	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;
	
	*est_pot += est_hold;
	*vdw_pot += lennardJonesA - lennardJonesB;	

	force_mag = est_hold*length_rec;
	
	//add the vdw force to the est force
	force_mag +=  6*length_rec*(2*lennardJonesA - lennardJonesB);
	force_mag *= length_rec;

	//calculate the force on atom one along the vector (r1 - r2)
	//the force on atom two is the opposite of this force
	*(seperation_s.vector + 0) *= force_mag;
	*(seperation_s.vector + 1) *= force_mag;
	*(seperation_s.vector + 2) *= force_mag;
	
	forces[atom_one][0] += *(seperation_s.vector + 0);
	forces[atom_one][1] += *(seperation_s.vector + 1);
	forces[atom_one][2] += *(seperation_s.vector + 2);

	forces[atom_two][0] -= *(seperation_s.vector + 0);
	forces[atom_two][1] -= *(seperation_s.vector + 1);
	forces[atom_two][2] -= *(seperation_s.vector + 2);
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedForceLog("Normal", "A", atom_one, atom_two, lennardJonesA, lennardJonesB, 
			     chargeProduct, seperation_s.length, est_hold,
			    (lennardJonesA - lennardJonesB), force_mag,
			    __NonbondedForceDebug__); 
#endif
}

void AdCoulombAndLennardJonesAForceTest(ListElement* interaction, 
		Vector3D* seperation_s, 
		double** forces,
		double EPSILON_RP, 
		double* vdw_pot, 
		double* est_pot)
{
	int atom_one, atom_two;
	double force_mag;
	double length_rec, vdw_hold, est_hold;
	double lennardJonesA, lennardJonesB, chargeProduct;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];
			
	/*//calculate the interatomic distance
	Ad3DVectorLength(&seperation_s);*/
	
	//add this length to the linked list wlement the bond belongs to
	interaction->length = seperation_s->length;

	//get reciprocal of seperation
	length_rec = 1/seperation_s->length;
	
	//calculate vdw holder
	vdw_hold = pow(length_rec, 6);

	//while this is being calculate 
	//calculate some non dependant variables

	//est holder
	est_hold = EPSILON_RP*chargeProduct*length_rec;

	//vdw holder may be finished now so calculate vdw consts
	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;
	
	*est_pot += est_hold;
	*vdw_pot += lennardJonesA - lennardJonesB;	

	force_mag = est_hold*length_rec;
	
	//add the vdw force to the est force
	force_mag +=  6*length_rec*(2*lennardJonesA - lennardJonesB);
	force_mag *= length_rec;

	//calculate the force on atom one along the vector (r1 - r2)
	//the force on atom two is the opposite of this force
	*(seperation_s->vector + 0) *= force_mag;
	*(seperation_s->vector + 1) *= force_mag;
	*(seperation_s->vector + 2) *= force_mag;
	
	forces[atom_one][0] += *(seperation_s->vector + 0);
	forces[atom_one][1] += *(seperation_s->vector + 1);
	forces[atom_one][2] += *(seperation_s->vector + 2);

	forces[atom_two][0] -= *(seperation_s->vector + 0);
	forces[atom_two][1] -= *(seperation_s->vector + 1);
	forces[atom_two][2] -= *(seperation_s->vector + 2);
}

void AdShiftedCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cut,
		double r_cutoff2,
		double* vdw_pot, 
		double* est_pot)
{
	int atom_one, atom_two;
	double force_mag;
	double length_rec, vdw_hold, est_hold;
	double shift_fac;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];

	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];
	
	Ad3DVectorLength(&seperation_s);
	
	//add this length to the linked list element the bond belongs to
	interaction->length = seperation_s.length;
	
	if(seperation_s.length > cut)
		return;

	length_rec = 1/seperation_s.length;
	vdw_hold = pow(length_rec, 6);
	est_hold = EPSILON_RP*chargeProduct*length_rec;
	
	//est shift factor
	shift_fac = (cut - seperation_s.length)*(cut - seperation_s.length)*r_cutoff2;

	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;

	//the shifted est force is EST_HOLD*(length_rec - r_cutoff2*length)
	force_mag = (length_rec - r_cutoff2*seperation_s.length);

	*est_pot += (est_hold*shift_fac);
	*vdw_pot += lennardJonesA - lennardJonesB;	
	
	//apply the shift to the est force
	force_mag *= est_hold;

	//add the vdw force
	force_mag +=  6*length_rec*(2*lennardJonesA - lennardJonesB);
	force_mag *= length_rec;

	*(seperation_s.vector + 0) *= force_mag;
	*(seperation_s.vector + 1) *= force_mag;
	*(seperation_s.vector + 2) *= force_mag;
	
	forces[atom_one][0] += *(seperation_s.vector + 0);
	forces[atom_one][1] += *(seperation_s.vector + 1);
	forces[atom_one][2] += *(seperation_s.vector + 2);

	forces[atom_two][0] -= *(seperation_s.vector + 0);
	forces[atom_two][1] -= *(seperation_s.vector + 1);
	forces[atom_two][2] -= *(seperation_s.vector + 2);
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedForceLog("Shifted", "A", atom_one, atom_two, lennardJonesA, lennardJonesB, 
			    chargeProduct, seperation_s.length, est_hold,
			    (lennardJonesA - lennardJonesB), force_mag,
			    __ShiftedNonbondedForceDebug__); 
#endif
}

void AdGRFCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cutoff,
		double b0, 
		double b1,
		double* vdw_pot, 
		double* est_pot) 
{
	int atom_one, atom_two;
	double force_mag;
	double length_rec, vdw_hold, est_hold;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];
			
	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];

	Ad3DVectorLength(&seperation_s);
	
	//add this length to the linked list element the bond belongs to
	interaction->length = seperation_s.length;
	
	if(seperation_s.length > cutoff)
		return;
		
	length_rec = 1/seperation_s.length;
	
	vdw_hold = pow(length_rec, 6);
	est_hold = EPSILON_RP*chargeProduct*length_rec;

	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;
	
	//GRF
	*est_pot += est_hold + EPSILON_RP*chargeProduct*b0;
	*vdw_pot += lennardJonesA - lennardJonesB;	
	force_mag = est_hold*length_rec + EPSILON_RP*chargeProduct*b1*seperation_s.length;

	//add the vdw force to the est force
	force_mag +=  6*length_rec*(2*lennardJonesA - lennardJonesB);
	//Since we have to divide the separation vector by this
	force_mag *=length_rec;

	*(seperation_s.vector + 0) *= force_mag;
	*(seperation_s.vector + 1) *= force_mag;
	*(seperation_s.vector + 2) *= force_mag;
	
	forces[atom_one][0] += *(seperation_s.vector + 0);
	forces[atom_one][1] += *(seperation_s.vector + 1);
	forces[atom_one][2] += *(seperation_s.vector + 2);

	forces[atom_two][0] -= *(seperation_s.vector + 0);
	forces[atom_two][1] -= *(seperation_s.vector + 1);
	forces[atom_two][2] -= *(seperation_s.vector + 2);
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedForceLog("GRF", "A", atom_one, atom_two, lennardJonesA, lennardJonesB, 
			    chargeProduct, seperation_s.length, est_hold,
			    (lennardJonesA - lennardJonesB), force_mag,
			    __GRFNonbondedForceDebug__); 
#endif
}

void AdShiftedCoulombAndLennardJonesAEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cut,
		double r_cutoff2,
		double* vdw_pot, 
		double* est_pot)
{		
	int atom_one, atom_two;
	double length_rec, vdw_hold, est_hold;
	double shift_fac;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];
			
	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];
	
	Ad3DVectorLength(&seperation_s);
	
	//add this length to the linked list element the bond belongs to
	interaction->length = seperation_s.length;
	
	if(seperation_s.length > cut)
		return;
			
	length_rec = 1/seperation_s.length;
	
	vdw_hold = pow(length_rec, 6);
	est_hold = (EPSILON_RP*chargeProduct*length_rec);

	//est shift factor
	shift_fac = (cut - seperation_s.length)*(cut - seperation_s.length)*r_cutoff2;
	
	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;
	
	//modify the potential by the shift function
	*est_pot += (est_hold*shift_fac);
	*vdw_pot += lennardJonesA - lennardJonesB;	
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedEnergyLog("Shifted", "A", atom_one, atom_two, lennardJonesA, lennardJonesB, 
			     chargeProduct, seperation_s.length, est_hold, (lennardJonesA - lennardJonesB),
			     __ShiftedNonbondedEnergyDebug__); 
#endif
}

void AdGRFCoulombAndLennardJonesAEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cutoff,
		double b0, 
		double b1,
		double* vdw_pot, 
		double* est_pot) 
{
	int atom_one, atom_two;
	double length_rec, vdw_hold, est_hold;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];
			
	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];
	
	Ad3DVectorLength(&seperation_s);

	//add this length to the linked list element the bond belongs to
	interaction->length = seperation_s.length;
	
	if(seperation_s.length > cutoff)
		return;
	
	length_rec = 1/seperation_s.length;
	vdw_hold = pow(length_rec, 6);
	est_hold = EPSILON_RP*chargeProduct*(length_rec + b0);
	lennardJonesA *= vdw_hold*vdw_hold;
	lennardJonesB *= vdw_hold;

	*est_pot += est_hold;
	*vdw_pot += lennardJonesA - lennardJonesB;
		
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedEnergyLog("GRF", "A", atom_one, atom_two, lennardJonesA, lennardJonesB, 
			     chargeProduct, seperation_s.length, est_hold, (lennardJonesA - lennardJonesB),
			     __GRFNonbondedEnergyDebug__); 
#endif
}

/*
void AdCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double* vdw_pot, 
		double* est_pot)
{
	int atom_one, atom_two;
	double force_mag;
	double length_rec, vdw_hold, est_hold;
	double lennardJonesA, lennardJonesB, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	lennardJonesA = interaction->params[0];
	lennardJonesB = interaction->params[1];
	chargeProduct = interaction->params[2];
			
	//calculate seperation vector (r1 - r2)
	*(seperation_s.vector + 0) = coordinates[atom_one][0] - coordinates[atom_two][0];
	*(seperation_s.vector + 1) = coordinates[atom_one][1] - coordinates[atom_two][1];
	*(seperation_s.vector + 2) = coordinates[atom_one][2] - coordinates[atom_two][2];
	
	//calculate the interatomic distance
	Ad3DVectorLength(&seperation_s);


	
	
	//add this length to the linked list wlement the bond belongs to
	interaction->length = seperation_s.length;

	//get reciprocal of seperation
	length_rec = 1/seperation_s.length;
	
	//calculate vdw holder
	e = _mm_mul(d,d);
	f = _mm_mul(d,d);
	g = __mm_mul(d,d);
	e = __mm_mul(f,e);
	g = __mm_mul(g,e)
	
	//while this is being calculate 
	//calculate some non dependant variables

	//est holder
	est_hold = _mm_mul(EPSILON_RP, chargeProduct);
	est_hold = __mm_mul(est_hold, length_rec);

	//vdw holder may be finished now so calculate vdw consts
	lennardJonesA *= __mm_mul(lennardJonesA, vdw_hold)
	lennardJonesB *= __mm_mul(lennardJonesB, vdw_hold)
	lennardJonesA *= __mm_mul(lennardJonesA, vdw_hold)
	
	*est_pot += est_hold;
	*vdw_pot += lennardJonesA - lennardJonesB;	

	force_mag = __mm_mul(est_hold, length_rec);
	
	//add the vdw force to the est force
	force_mag +=  6*length_rec*(2*lennardJonesA - lennardJonesB);
	force_mag *= length_rec;

	//calculate the force on atom one along the vector (r1 - r2)
	//the force on atom two is the opposite of this force
	*(seperation_s.vector + 0) *= force_mag;
	*(seperation_s.vector + 1) *= force_mag;
	*(seperation_s.vector + 2) *= force_mag;
	
	forces[atom_one][0] += *(seperation_s.vector + 0);
	forces[atom_one][1] += *(seperation_s.vector + 1);
	forces[atom_one][2] += *(seperation_s.vector + 2);

	forces[atom_two][0] -= *(seperation_s.vector + 0);
	forces[atom_two][1] -= *(seperation_s.vector + 1);
	forces[atom_two][2] -= *(seperation_s.vector + 2);

}
*/
