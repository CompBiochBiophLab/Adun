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
#ifndef _ADUN_FORCEFIELDCOLLECTION_
#define _ADUN_FORCEFIELDCOLLECTION_

#include "AdunKernel/AdunForceField.h"
#include "AdunKernel/AdunInteractionSystem.h"
#include "AdunKernel/AdunSystem.h"

/**
\ingroup frameworkTypes
AdForceFieldActivity defines the different possible groupings
of AdForceField objects in an AdForceFieldCollection.
*/
typedef enum
{
	AdActiveForceFields = 0,	/**< All active AdForceField objects. */
	AdInactiveForceFields = 1,	/**< All inactive AdForceField objects. */
	AdAllForceFields = 2	/**< All force fields regardless of activity */
}
AdForceFieldActivity;

/** 
\ingroup Inter
AdForceFieldCollection objects represent the combined force field due to
a number of AdForceField instances. Each AdForceField instance embodies
a function \f$U = f(\vec r)\f$ where \f$\vec r\f$ is the configuration of the elements
of an AdSystem or AdInteractionSystem object.
Hence AdForceFieldCollection represents the force field
\f[
U(\vec r_{1}, ..., \vec r_{n}) = f(\vec r_{1})+,  ..., + f(\vec r_{n})
\f]
Note that there can be more than one force field operating on the same system.

<b> Force Field Status </b>

The force field represented by an AdForceFieldCollection object can
be customised by activating/deactivating the various constituent AdForceField objects.

\todo Extra Functionality - Implement some useful NSSet/NSMutableSet like methods.
**/

@interface AdForceFieldCollection: NSObject 
{	
	NSMutableArray* activeForceFields;
	NSMutableArray* inactiveForceFields;
	NSMutableArray* forceFields;
	NSArray* systems;
}
/**
As initWithForceFields:() passing an empty array.
*/
- (id) init;
/**
Designated intialiser.
Creates and returns an AdForceFieldCollection instance
containing the AdForceField objects in \e anArray.
\param anArray An array of AdForceField objects. If any of the objects in \e anArray
is not a member of the AdForceField class (or a subclass) an NSInvalidArgumentException
is raised. All force fields are active by default.
*/
- (id) initWithForceFields: (NSArray*) anArray;
/**
Adds \e aForceField to the collection. It is active by default.
*/
- (void) addForceField: (AdForceField*) aForceField;
/**
Removes \e aForceField from the collection
*/
- (void) removeForceField: (AdForceField*) aForceField;
/**
Returns an array containing all the AdForceField objects
in the collection.
*/
- (NSArray*) forceFields;
/**
Sets the force fields in the collection to those in anArray.
This has the effect of removing any previous force fields from the
collection. All the new force fields are active by default.
*/
- (void) setForceFields: (NSArray*) anArray;
/**
Evaluates the combined forces due to active members by calling
AdForceField::evaluateForces on each.
*/
- (void) evaluateForces;
/**
Calls AdForceField::evaluateEnergies on each active memeber. 
*/
- (void) evaluateEnergies;
/**
\return An NSArray containing the AdForceField objects that operate
on \e aSystem. If none of the contained objects operate on \e aSystem the
array will be empty.
\param aSystem An AdSystem instance
\param activityFlag Indicates which force fields to include. The valid values are
defined by the #AdForceFieldActivity enum.
*/
- (NSArray*) forceFieldsForSystem: (id) aSystem activityFlag: (AdForceFieldActivity) value;
/**
As forceFieldsForSystem:activityFlag: passing AdAllForceFields for \e value
*/
- (NSArray*) forceFieldsForSystem: (id) aSystem;
/**
Returns an array containing the results of calling forceFieldsForSystem:() on
each system in \e systemArray.
*/
- (NSArray*) forceFieldsForSystems: (NSArray*) systemArray;
/**
Returns the systems operated on by the contained AdForceField objects.
*/
- (NSArray*) systems;
/**
Activates a deactivated force field. If \e aForceField
is already active this method does nothing. If it is not part of the collection
an NSInvalidArgumentException is raised.
*/
- (void) activateForceField: (AdForceField*) aForceField;
/**
Deactivates a active force field. If \e aForceField
is already deactivated this method does nothing. If it is not part of the collection
an NSInvalidArgumentException is raised.
*/
- (void) deactivateForceField: (AdForceField*) aForceField;
/**
Returns YES if \e aForceField is active. NO otherwise.
Raises an NSInvalidArgumentException if \e aForceField is not part of the collection.
*/
- (BOOL) isActive: (AdForceField*) aForceField;
/**
Returns YES if \e aForceField is a member of the collection. NO otherwise.
*/
- (BOOL) isMember: (AdForceField*) aForceField;
@end

#endif

