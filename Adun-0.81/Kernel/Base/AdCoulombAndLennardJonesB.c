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

void AdCoulombAndLennardJonesBEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cutoff,
		double* vdw_pot, 
		double* est_pot)
{
	int atom_one, atom_two;
	double length_rec, vdw_hold, est_hold;
	double eqSeparation, wellDepth, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	wellDepth = interaction->params[0];
	eqSeparation = interaction->params[1];
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
	
	vdw_hold = pow(eqSeparation*length_rec, 6);
	est_hold = (EPSILON_RP*chargeProduct*length_rec);

	*vdw_pot += wellDepth*vdw_hold*(vdw_hold - 2);	
	*est_pot += est_hold;
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedEnergyLog("Normal", "B", atom_one, atom_two, wellDepth, eqSeparation, 
			     chargeProduct, seperation_s.length, est_hold, *vdw_pot,
			     __NonbondedEnergyDebug__); 
#endif
}

void AdCoulombAndLennardJonesBForce(ListElement* interaction, 
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
	double wellDepth, eqSeparation, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	wellDepth = interaction->params[0];
	eqSeparation = interaction->params[1];
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
	
	//calculate vdw holder (r*/r)^6 
	vdw_hold = pow(eqSeparation*length_rec, 6);

	//est holder
	est_hold = EPSILON_RP*chargeProduct*length_rec;

	//Precompute wellDepth*vdw_hold since it occurs twice
	*est_pot += est_hold;
	wellDepth *= vdw_hold;
	//Note wellDepth here is the actual wellDepth*vdw_hold
	*vdw_pot += wellDepth*(vdw_hold - 2);	

	force_mag = est_hold*length_rec;
	//add the vdw force to the est force
	force_mag +=  12*length_rec*wellDepth*(vdw_hold - 1);
	//We have to find the unit vector in the direction
	//given by seperation_s. We divide force_mag by separation_s
	//length here so we dont have to do it three times below.
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
	AdNonbondedForceLog("Normal", "B", atom_one, atom_two, wellDepth, eqSeparation, 
			    chargeProduct, seperation_s.length, est_hold, *vdw_pot, force_mag,
			    __NonbondedForceDebug__); 
#endif
}


void AdShiftedCoulombAndLennardJonesBForce(ListElement* interaction, 
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
	double wellDepth, eqSeparation, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	wellDepth = interaction->params[0];
	eqSeparation = interaction->params[1];
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
	vdw_hold = pow(eqSeparation*length_rec, 6);
	est_hold = EPSILON_RP*chargeProduct*length_rec;
	
	//est shift factor
	shift_fac = (cut - seperation_s.length)*(cut - seperation_s.length)*r_cutoff2;

	//the shifted est force is EST_HOLD*(length_rec - r_cutoff2*length)
	force_mag = (length_rec - r_cutoff2*seperation_s.length);

	wellDepth *= vdw_hold;
	*est_pot += (est_hold*shift_fac);
	*vdw_pot += wellDepth*(vdw_hold - 2);	
	
	//apply the shift to the est force
	force_mag *= est_hold;

	//add the vdw force
	force_mag +=  12*length_rec*wellDepth*(vdw_hold - 1);
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
	AdNonbondedForceLog("Shifted", "A", atom_one, atom_two, wellDepth, eqSeparation, 
			    chargeProduct, seperation_s.length, est_hold, *vdw_pot, force_mag,
			    __ShiftedNonbondedForceDebug__); 
#endif
}

void AdGRFCoulombAndLennardJonesBForce(ListElement* interaction, 
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
	double wellDepth, eqSeparation, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	wellDepth = interaction->params[0];
	eqSeparation = interaction->params[1];
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
	
	vdw_hold = pow(eqSeparation*length_rec, 6);
	est_hold = EPSILON_RP*chargeProduct*length_rec;
	wellDepth *= vdw_hold;
	*vdw_pot += wellDepth*(vdw_hold - 2);	
	
	//GRF
	*est_pot += est_hold + EPSILON_RP*chargeProduct*b0;
	force_mag = est_hold*length_rec + EPSILON_RP*chargeProduct*b1*seperation_s.length;

	//add the vdw force to the est force
	
	force_mag +=  12*length_rec*wellDepth*(vdw_hold - 1);
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
	AdNonbondedForceLog("GRF", "A", atom_one, atom_two, wellDepth, eqSeparation, 
			    chargeProduct, seperation_s.length, est_hold, *vdw_pot, force_mag,
			    __GRFNonbondedForceDebug__); 
#endif
}

void AdShiftedCoulombAndLennardJonesBEnergy(ListElement* interaction, 
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
	double wellDepth, eqSeparation, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	wellDepth = interaction->params[0];
	eqSeparation = interaction->params[1];
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
	
	vdw_hold = pow(eqSeparation*length_rec, 6);
	est_hold = (EPSILON_RP*chargeProduct*length_rec);

	//est shift factor
	shift_fac = (cut - seperation_s.length)*(cut - seperation_s.length)*r_cutoff2;
	
	//modify the potential by the shift function
	*vdw_pot += wellDepth*vdw_hold*(vdw_hold - 2);	
	*est_pot += (est_hold*shift_fac);
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedEnergyLog("Shifted", "A", atom_one, atom_two, wellDepth, eqSeparation, 
			     chargeProduct, seperation_s.length, est_hold, *vdw_pot,
			     __ShiftedNonbondedEnergyDebug__); 
#endif
}

void AdGRFCoulombAndLennardJonesBEnergy(ListElement* interaction, 
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
	double wellDepth, eqSeparation, chargeProduct;
	Vector3D seperation_s;
	
	atom_one = interaction->bond[0];
	atom_two = interaction->bond[1];
	wellDepth = interaction->params[0];
	eqSeparation = interaction->params[1];
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
	vdw_hold = pow(eqSeparation*length_rec, 6);
	est_hold = EPSILON_RP*chargeProduct*(length_rec + b0);

	*vdw_pot += wellDepth*vdw_hold*(vdw_hold - 2);	
	*est_pot += est_hold;
	
#ifdef BASE_NONBONDED_DEBUG
	AdNonbondedEnergyLog("GRF", "A", atom_one, atom_two, wellDepth, eqSeparation, 
			     chargeProduct, seperation_s.length, est_hold, *vdw_pot,
			     __GRFNonbondedEnergyDebug__); 
#endif
}

