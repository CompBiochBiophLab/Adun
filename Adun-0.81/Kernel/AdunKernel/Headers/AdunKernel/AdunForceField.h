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
#ifndef ADUN_FORCEFIELD
#define ADUN_FORCEFIELD

#include <stdio.h>
#include <stdlib.h>
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMatrixStructureCoder.h"
#include "AdunKernel/AdForceFieldTerm.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunInteractionSystem.h"

/*!
\ingroup Inter
AdForceField an abstract class that defines the interface for objects that calculate the energy and forces associated
with the elements of an AdSystem or AdInteractionSystem object. 

The function an AdForceField object represents can be extended by adding objects that conform to the AdForceFieldTerm
protocol. 

\section note Notifications

All AdForceField subclasses should observe AdSystemContentsDidChangeNotification from their systems. 

\todo Extra Documentation - Not all force fields will calculate forces and vice versa.
\todo Affected by Task - Units.
\todo Possible Extra Functionality - Ability to use external force matrices.
*/

@interface AdForceField: AdMatrixStructureCoder 
{
}
/**
Intialises an AdForceField object that will calculate the 
energies and force of \e system.
*/
- (id) initWithSystem: (id) system;
/**
Calculates the energy associated with each force field term
for the current system.
*/
- (void) evaluateEnergies;
/**
Calculates the energy for each term
using only interactions involving the elements in \e elementIndexes.
*/
- (void) evaluateEnergiesUsingInteractionsInvolvingElements: (NSIndexSet*) elementIndexes;
/**
Returns the total energy as calculated by the last call to calculateEnergies()
*/
- (double) totalEnergy;
/**
Calculates the forces acting on the elements of the current system 
*/
- (void) evaluateForces;
/**
Calculates the forces using only interactions involving the elements in
\e elementIndexes. 
\note After calling this method the rows of the matrix returned by forces() 
corresponding to the elements in \e elementIndexes will contain the total
force for acting on that element. Other rows will only contain the forces acting on 
the corresponding element due to the elements in \e elementIndexes.
*/
- (void) evaluateForcesDueToElements: (NSIndexSet*) elementIndexes;
/**
Returns an AdMatrix containing the forces last calculated
by calculateForces(). The matrix is owned by the receiver and
will be deallocated when its released.
*/
- (AdMatrix*) forces;
/**
Returns an AdMatrix containing the accelerations associated with
the last calculated force matrix.
The rows of the returned matrix have a one-to-one correspondence with the
rows of the matrix returned by the systems coordinates method.
The matrix is owned by the receiver and will be deallocated when its released.
*/
- (AdMatrix*) accelerations;
/**
Sets all entries in the force matrix to 0
*/
- (void) clearForces;
/**
Returns an NSArray containing the last calculated energies for the terms
contained in \e array. The order of values in the returned array corresponds to the
order of terms in \e array.  If a term in \e array is not present in the array returned by
availableTerms() then \e anObject is inserted in its place.
*/
- (NSArray*) arrayOfEnergiesForTerms: (NSArray*) array notFoundMarker: (id) anObject;
/**
Returns a dictionary whose keys are the term names contained in \e array and
whose values are the last calculated potential energy for each terms. If a term in \e array 
is not present in the array returned by availableTerms() then it is not included in the
returned dictionary.
*/
- (NSDictionary*) dictionaryOfEnergiesForTerms: (NSArray*) array; 

/**
Returns the system associated with the force field object.
*/
- (id) system;
/**
Sets the force fields system to \e system.
*/
- (void) setSystem: (id) system;
/**
Returns the names of all the terms the object can calculate.
*/
- (id) availableTerms;
/**
Returns the names of all the activated terms.
*/
- (NSArray*) activatedTerms;
/**
Returns the names of all the deactivated terms.
*/
- (NSArray*) deactivatedTerms;
/**
Adds the term represent by \e object to the force field 
using \e name to identify it. \e name cannot be one of the
strings returned by coreTerms(). If it is an NSInvalidArgumentException
is raised.
\e object must confrom to the AdForceFieldTerm protocol.
If not an NSInvalidArgumentException is raised.
If \e name was already associated with a previous object
that object is removed from the force field.

The term is immediately activated and its name added to availableTerms().
The energy and forces due to the custom term will be calculated
each time an energy or force calculation method is called.
*/
- (void) addCustomTerm: (id) object withName: (NSString*) name;
/**
Calls addCustomTerm:withName:() for each entry in dict passing
the key as \e name and the value as \e object.
*/
- (void) addCustomTerms: (NSDictionary*) aDict;
/**
Removes the custom term identified by \e name from the force field. 
Does nothing if no term called \e name was added.
*/
- (void) removeCustomTermWithName: (NSString*) name;
/**
Deactivates the term identified by \e termName. It will no longer
be included when energies or forces are calculated.
\e termName can be any of the values returned by availableTerms().
Has no effect it the term is already deactivated or if there
is no term associated with \e termName.
*/
- (void) deactivateTerm: (NSString*) termName;
/**
Calls deactivateTerm:() for each string in \e names.
\param names An NSArray of NSStrings
*/
- (void) deactivateTermsWithNames: (NSArray*) names;
/**
Activates the term identified by \e termName. 
\e termName can be any of the values returned by availableTerms().
Has no effect it the term is already activated or if there
is no term associated with \e termName.
*/
- (void) activateTerm: (NSString*) termName;
/**
Calls activateTerm:() for each string in \e names.
\param names An NSArray of NSStrings
*/
- (void) activateTermsWithNames: (NSArray*) names;

@end

#endif
