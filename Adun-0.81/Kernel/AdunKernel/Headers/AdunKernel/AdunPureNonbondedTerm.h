/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-23 11:06:55 +0200 by michael johnston

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
#ifndef _ADPURENONBONDED_TERM
#define _ADPURENONBONDED_TERM
#include "Base/AdForceFieldFunctions.h"
#include "Base/AdLinkedList.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdunNonbondedTerm.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunCellListHandler.h"

/**
\ingroup Inter
Calculates the potential and the forces acting on a system due to 
coulomb electrostatic and lennard jones interactions with no modifications.

AdPureNonbondedTerm objects use an AdListHandler subclass instance to create
and manage the list of interacting pairs. The exact subclass used can be specified
on initialisation. 

If the list provided by the AdListHandler instance is invalidated due to an AdSystemContentsDidChangeNotification
(see AdListHandler documentation) the AdPureNonbondedTerm object will recreate the list. 
In this event the array of nonbonded pairs will be acquired from the system and used to rebuild the list
i.e. overriding a nonbonded pair array specified previously.

\todo Extra Documentation - Add mathematical definition of term.
\todo Extra Methods - Full init chain.
\todo Refactor - Change permittivity to relative permittivity to help clarity.
*/
@interface AdPureNonbondedTerm: AdNonbondedTerm <AdListHandlerDelegate, NSCopying>
{
	@private
	BOOL usingExternalForceMatrix;
	unsigned int updateInterval;
	double cutoff;
	double permittivity;
	double vdwPotential;	
	double estPotential; 
	double buffer;
	double* partialCharges;
	AdMatrix* forces;
	AdMatrix* parameters;
	ListElement* interactionList;
	NSString* lennardJonesType;
	AdDataMatrix* elementProperties;
	NSArray* pairs;
	NSString* messageId;
	id listHandler;
	id memoryManager;
	id system;
	Class listHandlerClass;
}
/**
As initWithSystem:() passing nil for \e system.
*/
- (id) init;
/**
As initWithSystem:cutoff:updateInterval:permittivity:nonbondedPairs:externalForceMatrix:
with the following values -

- cutoff 12.0
- updateInterval 20
- permittivity 1.0
- nonbondedPairs nil
- externalForceMatrix NULL
*/
- (id) initWithSystem: (id) system;
/**
As the designated initialiser passing AdCellListHandler for the
list handler class.
*/
- (id) initWithSystem: (id) aSystem 
	cutoff: (double) aDouble
	updateInterval: (unsigned int) anInt
	permittivity: (double) permittivityValue
	nonbondedPairs: (NSArray*) nonbondedPairs
	externalForceMatrix: (AdMatrix*) matrix;
/**
Designated initialiser.
\param system The system on which the calculation is to be performed.
\param permittivity The permittivity to be used in the electrostatic calculations.
\param aDouble The cutoff to be used.
\param anInt The period at which the list should be updated.
\param nonbondedPairs The nonbonded pairs the calculation is to be performed on. If this is
nil the object will use AdDataSource::elementPairsNotInInteractionsOfCategory: passing "Bonded" as
the category to obtain the set.
\param matrix An allocated AdMatrix instance where the calculated forces will be written. It must contain one row for
each element in the system. If the dimensions of the matrix are incorrect an NSInvalidArgumentException is raised.
If \e matrix is NULL the object will create and use its own force matrix.
\param aClass The AdListHandler subclass to be used for handling the nonbonded list. If \e aClass is not
an AdListHandler subclass an NSInvalidArgumentException is raised. If \e aClass is nil it defaults to
AdCellListHandler.
*/
- (id) initWithSystem: (id) system
	cutoff: (double) aDouble
	updateInterval: (unsigned int) anInt
	permittivity: (double) permittivityValue
	nonbondedPairs: (NSArray*) nonbondedPairs
	externalForceMatrix: (AdMatrix*) matrix
	listHandlerClass: (Class) aClass;
/**
\todo Not implemented
*/
- (void) evaluateLennardJonesForces;
/**
\todo Not implemented
*/
- (void) evaluateElectrostaticForces;
/**
Returns the permittivity used.
*/
- (double) permittivity;
/**
Sets the permittivity to \e aDouble.
*/
- (void) setPermittivity: (double) aDouble;
/**
Forces an update of the AdListHandler object the receiver
uses. If \e reset is YES the receiver resets the counter 
managed by the applications AdMainLoopTimer instance which
determines the period between automatic list updates.
*/
- (void) updateList: (BOOL) reset;
/**
Sets whether the receiver will automatically update its nonbonded list
every updateInterval() steps. 
By default this is yes for every AdNonbondedTerm object instance on its creation
*/
- (void) setAutoUpdateList: (BOOL) value;
/**
Returns a pointer to the beginning of the list of nonbonded interaction pairs the receiver uses.
Under no circumstances should elements be added or removed to this list.
It primarily provides a convienient way to avoid having to create multiple non-bonded lists.
i.e. if another object needs to iterate over the list of nonbonded pairs it can do so via
this method.
*/
- (ListElement*) interactionList;
@end

#endif
