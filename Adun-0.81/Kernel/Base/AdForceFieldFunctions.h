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

#ifndef AD_FORCEFIELD_FUNCTIONS
#define AD_FORCEFIELD_FUNCTIONS

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>
#include <float.h>
#include <fenv.h>
#include "Base/AdVector.h"
#include "Base/AdLinkedList.h"

/**
Debugging
*/

//If BASE_DEBUG is defined, define
//BASE_BONDED_DEBUG & BASE_NONBONDED_DEBUG if they're not
//already defined.

#ifdef BASE_DEBUG
#ifndef BASE_BONDED_DEBUG
#define BASE_BONDED_DEBUG
#endif
#ifndef BASE_NONBONDED_DEBUG
#define BASE_NONBONDED_DEBUG
#endif
#endif

extern bool __HarmonicBondEnergyDebug__;
extern bool __HarmonicBondForceDebug__;
extern bool __HarmonicAngleEnergyDebug__;
extern bool __HarmonicAngleForceDebug__;
extern bool __FourierTorsionEnergyDebug__;
extern bool __FourierTorsionForceDebug__;
extern bool __HarmonicImproperTorsionEnergyDebug__;
extern bool __HarmonicImproperTorsionForceDebug__;
extern bool __NonbondedEnergyDebug__;
extern bool __NonbondedForceDebug__;
extern bool __ShiftedNonbondedEnergyDebug__;
extern bool __ShiftedNonbondedForceDebug__;
extern bool __GRFNonbondedEnergyDebug__;
extern bool __GRFNonbondedForceDebug__;

//Turns on checking of force magnitudes for inf and nan.
//Defined in AdHarmonicBond.c - default is false.
extern bool __CheckForceMagnitude__;

void AdNonbondedEnergyLog(char* cutType, char* ljType, int a1, int a2, double ljA,
		double ljB, double charge, double sep, double estPot, double ljPot,
		bool flag);
void AdNonbondedForceLog(char* cutType, char* ljType, int a1, int a2, double ljA,
		double ljB, double charge, double sep, double estPot, double ljPot, double force, 
		bool flag);
/**
\defgroup Functions Functions
\ingroup Base
*/

/**
\defgroup Types Types
\ingroup Base
*/

/**
These are the primitive functions used to calculate the energy and force
terms of a force field. 
\defgroup ForceFieldFunctions Force Field 
\ingroup Functions
@{
*/

/*
 * Harmonic Bond
 */
 
/**
Calculates the seperation between two atoms.
\e bond is an array of two ints - each one the index of the atom in the \e coordinates matrix
*/ 
double AdCalculateAtomSeparation(int* atomIndexes, double **coordinates);
/**
Calculates the energy of a bond from the given parameters.
*/
double AdCalculateHarmonicBondEnergy(double bondDistance, double equilibriumDistance, double bondConstant);
/**
Calculates the energy of a bond from the given parameters using the enzymix formula.
*/
double AdCalculateEnzymixBondEnergy(double bondDistance, double equilibriumDistance, double bondConstant);

/** Calculates the energy of a bond using a harmonic bond function */
void AdHarmonicBondEnergy(double *bond, double **coordinates, double *bnd_pot);
/** Calculates the energy and force of a bond using a harmonic bond function */
void AdHarmonicBondForce(double* bond, double **coordinates, double **forces, double* bnd_pot);
/**
Enzymix force field uses k*(x-x0)² instead of k/2*(x-xo)² like other force fields
*/
void AdEnzymixBondEnergy(double* bond, double **coordinates, double* bnd_pot);
/**
As harmonic force except force magnitude is 2k*(x-x0) instead of k*(x-xo) like other force fields
*/
void AdEnzymixBondForce(double* bond, double **coordinates, double **forces, double* bnd_pot);

/*
 * Harmonic Angle
 */

/**
Calculates the angle between three atoms.
The atoms indexes are given in the array \e atomIndexes.
These indexes are used to access the correct row in the matrix \e coordinates.
Note: There is no checking for indexing beyond the bounds of the arrays or matrices
so make sure they are the correct size.
*/
double AdCalculateAngle(int *atomIndexes, double **coordinates);
/**
Calculates the angles energy according to enzymixis harmonic term.
*/
double AdCalculateEnzymixAngleEnergy(double angle, double equilibriumAngle, double angleConstant);
/**
Calculates the angles energy according to a standard harmonic term.
*/
double AdCalculateEnzymixAngleEnergy(double angle, double equilibriumAngle, double angleConstant);
/** Calculates the energy of an angle using a harmonic angle function */
void AdHarmonicAngleEnergy(double *interaction, double **coordinates, double *ang_pot);
void AdHarmonicAngleForce(double *interaction, double **coordinates, double **forces, double *ang_pot);
/**
Enzymix force field uses k*(x-x0)² instead of k/2*(x-xo)² like other force fields
Where x is the angle.
*/
void AdEnzymixAngleEnergy(double *interaction, double** coordinates, double *ang_pot);
void AdEnzymixAngleForce(double *interaction, double **coordinates, double **forces,  double *ang_pot);

/*
 * fourier torsion
 */

/** calculates the energy of a proper torsion using a fourier torsion function */
void AdFourierTorsionEnergy(double *interaction, double **coordinates, double *tor_pot);
int AdFourierTorsionForce(double *interaction, double **coordinates, double **forces, double *tor_pot);
/*
Calculates the torsion angle for four atoms. Torsion 4 element array each element an atom index. The
atoms position must be given by the corresponding row in coordinates.
*/
double AdCalculateTorsionAngle(int* torsion, double** coordinates);
/**
Calculates the energy of an torsion angle using a fourier type term.
*/
double AdCalculateFourierTorsionEnergy(double angle, double period, double phase, double torsionConstant);


/*
 * harmonic improper  torsion
 */

/**
Calculate the torsion angle for four atoms. Torsion 4 element array each element an atom index. The
atoms position must be given by the corresponding row in coordinates.
*/
double AdCalculateImproperTorsionAngle(int* atomIndexes, double** coordinates);

/**
Calculates the energy of an improper torsion angle using a harmonic term and the given parameters.
*/
double AdCalculateImproperTorsionEnergy(double angle, double equilibriumAngle, double torsionConstant);

/** calculates the energy of an improper torsion using a harmonic function */
void AdHarmonicImproperTorsionEnergy(double *interaction, double **coordinates , double *itor_pot);
void AdHarmonicImproperTorsionForce(double *interaction, double **coordinates, double **forces, double *itor_pot);

/** Calculates the combined energy of a coloumb electrostatic and lennard jones A term.
Lennard Jones A uses parameters A and B. These functions are optimised for use in
Adun AdForceField obects.
\todo Possibly move the separation and cutoff rejection code to AdunKernel classes  */
void AdCoulombAndLennardJonesAEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP,
		double cutoff,
		double* vdw_pot, 
		double* est_pot);
void AdCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cutoff,
		double* vdw_pot, 
		double* est_pot);
void AdShiftedCoulombAndLennardJonesAEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP,
		double cut,
		double r_cutoff2,
		double* vdw_pot, 
		double* est_pot);
void AdShiftedCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cut,
		double r_cutoff2,
		double* vdw_pot, 
		double* est_pot);
void AdGRFCoulombAndLennardJonesAEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cutoff,
		double b0, 
		double b1,
		double* vdw_pot, 
		double* est_pot); 
void AdGRFCoulombAndLennardJonesAForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cutoff,
		double b0, 
		double b1,
		double* vdw_pot, 
		double* est_pot); 
/** Calculates the combined energy of a coloumb electrostatic and lennard jones B term.
Lennard Jones A uses parameters well depth and equilibrium separation. 
These functions are optimised for use in Adun AdForceField obects.*/
void AdCoulombAndLennardJonesBEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cutoff,
		double* vdw_pot, 
		double* est_pot);
void AdCoulombAndLennardJonesBForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cutoff,
		double* vdw_pot, 
		double* est_pot);
void AdShiftedCoulombAndLennardJonesBForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cut,
		double r_cutoff2,
		double* vdw_pot, 
		double* est_pot);
void AdShiftedCoulombAndLennardJonesBEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cut,
		double r_cutoff2,
		double* vdw_pot, 
		double* est_pot);
void AdGRFCoulombAndLennardJonesBEnergy(ListElement* interaction, 
		double** coordinates, 
		double EPSILON_RP, 
		double cutoff,
		double b0, 
		double b1,
		double* vdw_pot, 
		double* est_pot); 
void AdGRFCoulombAndLennardJonesBForce(ListElement* interaction, 
		double** coordinates, 
		double** forces,
		double EPSILON_RP, 
		double cutoff,
		double b0, 
		double b1,
		double* vdw_pot, 
		double* est_pot); 
//test		
void AdCoulombAndLennardJonesAForceTest(ListElement* interaction, 
		Vector3D* seperation_s, 
		double** forces,
		double EPSILON_RP, 
		double* vdw_pot, 
		double* est_pot);

/**
Calculates the electrostatic energy using coloumbs law and the given parameters.
*/		
double AdCoulombEnergy(double separation, double chargeOne, double chargeTwo, double relativePermittivity, double constant);

/**
Calculates the lennard jones energy using the enzymix formula (parameters A and B)
*/
double AdLennardJonesAEnergy(double separation, double a1, double b1, double a2, double b2);
/**
Calculates the lennard jones energy using the formula with parameters well depth and equilibrium separation
*/
double AdLennardJonesBEnergy(double separation, double wellDepth1, double equilibriumSeparation1, 
				    double wellDepth2, double equilibriumSeparation2);
				    
/**
Debug info functions
*/
void AdNonbondedDebugInfo(void);
void AdHarmonicBondDebugInfo(void);
void AdHarmonicAngleDebugInfo(void);
void AdFourierTorsionDebugInfo(void);
void AdHarmonicImproperTorsionDebugInfo(void);
		
/** \@}**/
#endif
