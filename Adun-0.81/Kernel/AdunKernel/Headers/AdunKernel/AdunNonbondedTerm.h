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
#ifndef ADUN_NONBONDED_TERM
#define ADUN_NONBONDED_TERM

#include <Base/AdBaseFunctions.h>	
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdDataSources.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdForceFieldTerm.h"

/*!
\ingroup Inter
AdNonbondedTerm is an abstract class and is not meant to be instantiated i.e.
you must use one of its concrete descedants.

AdNonbondedTerm subclasses are objects that calculate the combined lennard jones and coulomb 
electrostatic forces/energies acting on a (molecular) system. The method used to acquire the list 
of interacting pairs depends on the subclass e.g. it could be via an AdListHandler subclass or other methods.

The set of allowed pairs can be provided to the AdNonbondedTerm object. This set
must be an NSArray of NSIndexSets (see AdListHandler for more). If no such set is provided the object
will retrieve one from the system using AdDataSource::elementPairsNotInInteractionsOfCategory:
passing "Bonded" as the category.

Each AdNonbondedTerm subclass defines a different algorithm for performing the calculation.
The mathematical form to be used for the lennard jones term can be specified however the system must contain the required
parameters.

\todo Extra Documentation - Information on different LJ types.
\todo Affected by Task - Units. All the terms assume certain units by using #EPSILON and related constants
\todo Extra Documentation - Information on the necessary parameters.
*/


@interface AdNonbondedTerm: AdMatrixStructureCoder <AdForceFieldTerm>
{
	BOOL endThread;		//Used to tell the thread to end
	BOOL threadFinished;	//Used to notify thread calculation has finished
	BOOL beginThreadedCalculation;	//Used to tell the thread to start calculating
}	
/**
\param system The system on which the calculation is to be perfomed.
\param aDouble The cutoff to be used.
\param anInt The period at which the list should be updated.
\param nonbondedPairs The nonbonded pairs the calculation is to be performed on. If this is
nil the object will use AdDataSource::elementPairsNotInInteractionsOfCategory: passing "Bonded" as
the category to obtain the set.
\param matrix An allocated AdMatrix instance where the calculated forces will be written. It must contain one row for
each element in the system. If the matrix is not of the correct dimension an NSInvalidArgumentException is raised.
If NULL the object will create and use its own matrix.
*/
- (id) initWithSystem: (id) system
	cutoff: (double) aDouble
	updateInterval: (unsigned int) anInt
	nonbondedPairs: (NSArray*) nonbondedPairs
	externalForceMatrix: (AdMatrix*) matrix;
/**
Calculates the energy of the system due to lennard jones interactions.
See the subclass documentation for the exact algorithm used.
*/
- (void) evaluateLennardJonesEnergy;
/**
Calculates the energy of the system due to electrostatic interactions.
See the subclass documentation for the exact algorithm used.
*/
- (void) evaluateElectrostaticEnergy;

/**
Calculates the forces acting on the system due to lennard jones interactions.
See the subclass documentation for the exact algorithm used.
The cumulative force on each atom is added to the corresponding entry in 
the objects force matrix.
If usesExternalForceMatrix() returns NO then the matrix
is cleared before the calculation begins.
The lennard jones energy of the system is also calculated.
*/
- (void) evaluateLennardJonesForces;
/**
Calculates the forces acting on the system due to electrostatic interactions.
See the subclass documentation for the exact algorithm used.
The cumulative force on each atom is added to the corresponding entry in 
the objects force matrix. If usesExternalForceMatrix() returns NO then the matrix
is cleared before the calculation begins.
The electrostatic energy of the system is also calculated.
*/
- (void) evaluateElectrostaticForces;
/**
Returns the electrostatic potential energy of the system
as calculated by the last call to either evaluateEnergy(), evaluateElectrostaticEnergy() or evaluateForces().
*/
- (double) electrostaticEnergy;
/**
Returns the lennardJones potential energy of the system
as calculated by the last call to either evaluateEnergy(), evaluateLennardJonesEnergy() or evaluateForces().
*/
- (double) lennardJonesEnergy;
/**
The form of the lennard jones interaction being used. Either A or B.
*/
- (NSString*) lennardJonesType;
/**
Set the list of nonbonded elements to \e nonbondedPairs
*/
- (void) setNonbondedPairs: (NSArray*) nonbondedPairs;
/**
Returns the nonbonded pair array.
*/
- (NSArray*) nonbondedPairs;
/**
Returns the cutoff being used
*/
- (double) cutoff;
/**
Set the cutoff to \e aDouble
*/
- (void) setCutoff: (double) aDouble;
/**
Returns the update interval
*/
- (unsigned int) updateInterval;
/**
Sets the update interval
*/
- (void) setUpdateInterval: (unsigned int) updateInterval;
/**
Clears the force matrix used by the receiver.
Take care when usingExternalForceMatrix is YES.
*/
- (void) clearForces;
@end

#endif
