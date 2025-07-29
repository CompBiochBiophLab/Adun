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
#ifndef _ADSYSTEMCOLLECTION_
#define _ADSYSTEMCOLLECTION_

#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunInteractionSystem.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdunContainerDataSource.h"


/**
\ingroup Inter
AdSystemCollection instances manage a collection of AdSystem & AdInteractionSystem objects
and provide information on the relationships between them. 

\todo Extra Functionality - Implement some useful NSSet/NSMutableSet like methods.
**/

@interface AdSystemCollection: NSObject 
{
	@private
	NSMutableArray* systems;	//!< All systems 
	NSMutableArray* interactionSystems;	//!< AdInteractionSystem instances
	NSMutableArray* fullSystems;	//!< AdSystem instances
	NSMutableArray* containerSystems;
}
/**
As initWithSystems:() passing an empty array.
*/
- (id) init;
/**
Designated initialiser.
\param anArray An NSArray of AdSystem and AdInteractionSystem instances
*/
- (id) initWithSystems: (NSArray*)  anArray;
/**
Returns an array containing all the systems
*/
- (NSArray*) allSystems;
/**
Returns an array containing the AdSystem instances in the collection.
*/
- (NSArray*) fullSystems;
/**
Returns an array containing the AdInteractionSystem instances in the collection.
*/
- (NSArray*) interactionSystems;
/**
Removes \e aSystem from the collection
*/
- (void) removeSystem: (id) aSystem;
/**
Adds \e aSystem to the collection.  
*/
- (void) addSystem: (id) aSystem;
/**
Sets the systems in the collection to be those
in anArray. All previous system are removed. 
All the systems must be AdInteractionSystem or AdSystem
instances. If no an NSInvalidArgumentException is raised
and the object is left unchanged.
*/
- (void) setSystems: (NSArray*) anArray;
/**
Returns all systems who have an AdContainerDataSource.
*/
- (NSArray*) containerSystems;
/**
Returns all AdInteractionSystem instances in the collection
that involve \e aSystem.
*/
- (NSArray*) interactionSystemsInvolvingSystem: (AdSystem*) aSystem;
/**
Returns the system called \e aString (as determined by AdSystem::systemName).
If more than one system has the same name the first one found is returned.
If no system called \e aString is in the collection this method returns nil.
*/
- (id) systemWithName: (NSString*) aString;
@end

#endif
