/*
   Project: Adun

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

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
#ifndef ADUN_MMFORCEFIELD
#define ADUN_MMFORCEFIELD

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include "Base/AdVector.h"
#include "Base/AdMatrix.h"
#include "Base/AdLinkedList.h"
#include "Base/AdForceFieldFunctions.h"
#include "AdunKernel/AdunForceField.h"
#include "AdunKernel/AdunNonbondedTerm.h"
#include "AdunKernel/AdunPureNonbondedTerm.h"

/*!
\ingroup Inter
AdMolecularMechanicsForceField is an abstract class that defines the interface for objects that calculate the
energy and forces associated with the elements of an AdSystem or AdInteractionSystem object using a molecular mechanics type
potential function. 

A molecular mechanics force field is usually defined by a function which is the sum of a number of independant mathematical terms.

\f[ U(\vec r) = \sum T_{1} + \sum T_{2} + ... + \sum T_{n} \f]

Each term represents an interaction that can occur between the elements of a system e.g. bonded, electrostatic etc.
Applying the force field function to a set of elements gives their energy.

The application of a force field involves identifying all occurances of each interaction type in the system.
Then the corresponding mathematical term is used to evaluate each occurances energy and finally all the results are summed.
It is usual that the individual terms are parameterisable functions with the parameters depending on the element types
involved in the interaction.

Each AdMolecularMechanicsForceField subclass represents a different force field function i.e. a different combination of terms.
It is important to note that they only represent the mathematical function and contain no parameter information.
The lists of occurances of each interaction along with the parameters are provided by AdSystem or AdInteractionSystem objects.
AdMolecularMechanicsForceField subclassses associate a name with each of their terms. The coreTerms() method returns
an array containing the names.  

When given a system an AdMolecularMechanicsForceField object checks which interactions are present in it 
using AdSystem::availableInteractions. 
It then extracts information for those interactions which correspond to terms in its force field using the methods
defined by the AdSystemDataSource protocol. The information required for each
term depends on the force field. For example for calculating the bonded term a force field may require a list
of all bonded elements aswell as parameters for each. The individual subclasses detail what exactly they require.

\note
This class implementes a lot of common functionality for its current subclasses since they are very similar. 
However this means that it is tightly coupled to a force field which has the following core terms :
HarmonicBond, HarmonicAngle, FourierTorsion, HarmonicImproperTorsion, CoulombElectrostatic and an VdW interaction.
If other subclasses are implemented it may be necessary to refactor this class to be more general (e.g move some functionality
back to the current subclasses).
*/

@interface AdMolecularMechanicsForceField:  AdForceField
{
	int no_of_atoms;
	int updateInterval;
	BOOL harmonicBond;
	BOOL harmonicAngle;
	BOOL fourierTorsion;
	BOOL improperTorsion;
	BOOL nonbonded;
	double bnd_pot;
	double ang_pot;
	double tor_pot;
	double itor_pot;
	double vdw_pot;
	double est_pot;
	double total_energy;
	double cutoff;
	double *reciprocalMasses;
	AdMatrix *bonds;
	AdMatrix *angles;
	AdMatrix *torsions;
	AdMatrix *improperTorsions;
	AdMatrix* forceMatrix;
	AdMatrix* accelerationMatrix;
	AdListHandler* nonbondedHandler;
	NSMutableDictionary* customTerms;
	NSMutableArray* customTermNames;
	NSMutableArray* availableTerms;	//!< The core terms that the current system provides information for
	NSArray* coreTerms;		//!< The core terms of the force field
	NSMutableDictionary* state;	//!< The current state of the force-field
	id system;
	id nonbondedTerm;  
	id bondedInteractions;
	id nonbondedInteractionTypes;
	NSString* vdwInteractionType; 	//Identifies which vdw interaction is used.
}	
/**
This method determines the correct AdMolecularMechanicsForceField subclass for \e system.
It then creates and returns an instance of it using initWithSystem:() passing \e system as the parameter.
The correct force field is determined from the value of the ForceField metadata key of the systems data source.
If this key is missing or is not recognised this method returns nil.
The currently recognised values are Enzymix, Charmm and Amber.
*/
+ (id) forceFieldForSystem: (AdSystem*) system;
/**
As initWithSystem:() passing nil for \e system
*/
- (id) init;
/**
As initWithSystem:nobondedTerm() passing nil for \e anObject
*/
- (id) initWithSystem: (id) system;
/**
As initWithSystem:nonbondedTerm:customTerms:() passing nil for \e aDict.
*/
- (id) initWithSystem: (id) system nonbondedTerm: (AdNonbondedTerm*) anObject;
/**
Initialises an new AdMolecularMechanicsForceField instance for calculating the force and energies
of \e system using the enzymix force field. 
\param system An AdSystem or AdInteractionSystem object.
\param anObject An AdNonbondedTerm object that will handle the nonbonded terms of the force field.
If the system associated with \e anObject is not the same
as \e system it is replaced by it. In addition the lennard
jones type used by \e anObject is automatically set to "A".
If \e anObject is nil and \system is not nil a default nonbonded term object is created.
This is an AdPureNonbondedTerm
instance with a cutoff of 12 and update interval of 20.
\param aDict An optional dictionary whose keys are term names and whose values
are objects that conform to the AdForceFieldTerm protocol. They will
be added to the force field using addCustomTerms:().
*/
- (id) initWithSystem: (id) system 
	nonbondedTerm: (AdNonbondedTerm*) anObject
	customTerms: (NSDictionary*) aDict;
/**
Sets the receiver to use \e anObject for calculating the nonbonded terms of
the force field. If the system associated with \e anObject is not the same
as the revceivers \e system then it is replaced with it. The lennard jones 
type used by \e anObject is set to "A" if it is not already.
*/
- (void) setNonbondedTerm: (AdNonbondedTerm*) anObject;
/**
Returns the object used to calculate the nonbonded terms of the force field.
*/
- (AdNonbondedTerm*) nonbondedTerm;
/**
\todo Partial Implementation - Does not provided energies for custom terms.
*/
- (NSArray*) arrayOfEnergiesForTerms: (NSArray*) terms notFoundMarker: (id) anObject;
/**
\bug Incorrect handling of situtation where \e name already exists.
*/
- (void) addCustomTerm: (id) object withName: (NSString*) name;
/** \bug - Does not handle the case where \e system does not contain the necessary parameters. Such
an occurance will produce a segmentation fault.
*/
- (void) setSystem: (id) anObject;
/**
Replaces the current custom terms with those in \e aDict.
All the objects being added as terms must conform to the AdForceFieldTerm
protocol. If any object does not conform to this protocol an exception is
raised. In this case the object is left in its initial state.
*/
- (void) setCustomTerms: (NSDictionary*) aDict;
/**
Returns the names of the core terms of the force field.
*/
- (NSArray*) coreTerms;
/**
Returns an array containing the last calculated energies associated
with each core term. The order of the returned array corresponds to the order
of the array returned by coreTerms().
*/
- (NSArray*) arrayOfCoreTermEnergies;
/**
Returns a dictionary whose keys are core term names and whose values are the
energies for each.
*/
- (NSDictionary*) dictionaryOfCoreTermEnergies;
/**
Returns the vdw function type used by receiver
*/
- (NSString*) vdwInteractionType;
/**
N.B. Temporary implementation
Returns an array containing the names of all the energy terms
the force field can compute.
\note The first n entries correspond to the array returned by coreTerms().
The subsequent entries are custom terms.
The order of these should be the same on each call however due to internal problems it may not be.
Hence this method only is ensured of returning a uniquely ordered array of their is only
one custom term that can calculate energy - (AdForceFieldTerm::canEvaluateEnergy() returns YES).
*/
- (NSArray*) allTerms;
/**
N.B Temporary implementation
Returns an array containing the energies of all the terms that can be computed by
the receiver.
The order corresponds to the order of terms returned by allTerms().
\note  Currently the order is only guaranteed to be correct 
when there is only one custom term that can calculate energy - (AdForceFieldTerm::canEvaluateEnergy() returns YES).
*/
- (NSArray*) allEnergies;
@end

/**
Private methods for maintaining state
These should never be called outside of the class implementation.
 */
@interface AdMolecularMechanicsForceField (PrivateInternals)
/**
Resets all system dependant ivars. Use on a change of system.
*/
- (void) _systemCleanUp;
/**
Updates the acceleration matrix with using the current forces
*/
- (void) _updateAccelerations;
/**
Allocates the force and acceleration matrices.
Initialises the internal structure representations for the standard MM force-field
interactions if they are present i.e. bond, angle, torsion, improper torsion, standard nonbonded.
*/
- (void) _initialisationForSystem;
/**
Allocates an array for holding the reciprocals of the masses of the system.
Held in instance variable reciprocalMasses
*/
- (void) _createReciprocalMassArray;
/**
Performs updates necessary when reloadData is called on a AdMolecularMechanicsForceField 
instances system.
*/
- (void) _handleSystemContentsChange: (NSNotification*) aNotification;
/**
Convience method for creating the internal AdMatrix structs used to store
the group and parameter information for each interaction.
*/
- (AdMatrix*) _internalDataStorageForGroups: (AdDataMatrix*) groups parameters: (AdDataMatrix*) parameters;
@end

#endif
