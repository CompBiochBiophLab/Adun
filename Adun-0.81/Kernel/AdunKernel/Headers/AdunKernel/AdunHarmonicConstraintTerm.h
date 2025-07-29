/*
 Project: AdunKernel
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Author: Michael Johnston
 
 Created: 11/07/2008 by michael johnston
 
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
#ifndef _ADHARMONICONSTRAINTTERM_
#define _ADHARMONICONSTRAINTTERM_
 
#include <Foundation/Foundation.h> 
#include <AdunKernel/AdunDefinitions.h>
#include <AdunKernel/AdunSystem.h>
#include <AdunKernel/AdunMemoryManager.h>
#include <AdunKernel/AdForceFieldTerm.h>
#include <AdunKernel/AdunContainerDataSource.h>
#include <AdunKernel/AdGridDelegate.h>
 
/**
Defines the two types of cavity/container constraints
*/ 
typedef enum
{ 
	AdCavityInternalConstraint,
	AdCavityExternalConstraint
}
AdCavityConstraintType;
 
/**
Class representing a force-field term that applies a harmonic constraint force 
to specified elements of an AdSystem object.
The elements to be constrained can be specified in numerous ways. These include

- elements inside or outside a defined cavity or container
- elements with a certain value for a certain property e.g. PDB id == CA
- elements selected by a given selection string (not implemented yet)
\ingroup Inter
*/
@interface AdHarmonicConstraintTerm: NSObject <AdForceFieldTerm>
{
	double forceConstant;
	double energy;
	AdMatrix* forceMatrix;
	AdMatrix* originalCoordinates;
	NSIndexSet* elementIndexes;
	AdMemoryManager* memoryManager;
	id constrainedSystem;
}
/**
Designated initialiser.
Creates a AdHarmonicConstraintTerm instance which constrains the elements of
\e system given by \e indexSet using a harmonic term with force-constant \e aDouble.
*/
- (id) initWithSystem: (id) system 
	forceConstant: (double) aDouble
 constrainingElements: (NSIndexSet*) indexSet;
/**
 As initWithSystem:forceConstant:constrainingElements:() except the constrained elements of \e system
 are those inside/outside \e cavity.
 \e constraintType is either AdCavityInternalConstraint or AdCavityExternalConstraint.
 */
- (id) initWithSystem: (id) system
	forceConstant: (double) forceConstant
	       cavity: (id) cavity
       constraintType: (AdCavityConstraintType) constraintType; 
/**
As initWithSystem:forceConstant:cavity:constraintType:() where the cavity is obtained 
from \e container.
*/
- (id) initWithSystem: (id) system
	forceConstant: (double) forceConstant
	    container: (AdContainerDataSource*) container
       constraintType: (AdCavityConstraintType) constraintType;
/**
As initWithSystem:forceConstant:constrainingElements:() except the constrained elements of \e system
are those who have \e selectionValue for \e property. 
\e property is one of the columns of the systems elementProperties() matrix.
*/       
- (id) initWithSystem: (id) system
	forceConstant: (double) forceConstant
constrainingElementsWithValue: (id) selectionValue
	  forProperty: (NSString*) property;
/**
 As initWithSystem:forceConstant:constrainingElements:() except the contraines elements of \e system
 are defined by \e selectionString.
 Not yet implemented.
*/ 	  
- (id) initWithSystem: (id) system
	forceConstant: (double) forceConstant
contrainingElementsMatchingSelectionString: (NSString*) selectionString;
/**
 As initWithSystem:forceConstant:constrainingElements:() with a force constant 
 of 1000KCal/mol constraining all the elements in \e system.
*/
- (id) initWithSystem: (id) system;  
@end

#endif

