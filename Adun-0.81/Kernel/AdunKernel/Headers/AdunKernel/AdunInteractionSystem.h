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
#ifndef _ADUNINTERACTIONSYSTEM_
#define _ADUNINTERACTIONSYSTEM_

#include "AdunKernel/AdunMatrixStructureCoder.h"
#include "AdunKernel/AdDataSources.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunTimer.h"
#include "AdunKernel/AdunListHandler.h"

/**
\ingroup Inter
An AdInteractionSystem instance represents the interaction of two AdSystem objects. 
The AdInteractionSystem interface shares many methods with AdSystems interface enabling
polymorphism e.g. with AdForceField objects.

\n
<b> Principal Attributes </b>

- The inter-system interactions.

\n
<b> Combined Attributes </b>

A number of the attributes of AdInteractionSystem objects are \e combined attributes. They are based on values provided
by the objects two AdSystem instances.  The combined attributes are

- coordinates()
- elementProperties()
- elementMasses()
- elementTypes()

The arrays/matrices associated with these attributes contain a entry/row for each element in the interacting systems. 
The entries (or rows) refering to the elements of a given system are always contiguous. 
In addition they always occupy the same range i.e. if in the coordinate matrix 
the range of rows refering to the coordinates of a system is 0-500, the same range refers to the elements of that
system in all other combined attribute objects. The method rangeForSystem:() returns the range
for a given system.

The values in a combined attribute cannot be changed unless the values it is based on change. For most of these attributes
this is an infrequent occurance that requires modification and reloading of a systems data source.
The exception is the coordinates matrix. This will change frequently during a configuration generation process
since the coordinates of the contained AdSystem instances will (usually) be changing during each step of the production loop.
The AdSystem class documentation describes how an AdInteractionSystem instances coordinate matrix
is kept up-to-date with these changing values.

\n
\b Notifications

AdInteractionSystem objects observe #AdSystemContentsDidChangeNotification 's from their AdSystems. Currently on receiving
such a notification they essentially reinitialise themselves i.e. all added interactions are lost. This behaviour will
be changed in the future to handle such occurances in greater detail.

#AdSystemContentsDidChangeNotification - Indicates the system has changed in some way e.g. element properties, number of elements or
the system topology. Implies that AdSystem::reloadData() was called on one of the consituent AdSystem objects.
The notification object is the AdInteractionSystem. There is no user info dictionary. 

\todo Missing Functionality - Handling of bonded interactions between two systems
\todo Extra Methods - Implement subset of the AdMutableDataSource methods. 
\todo Affected by Task - Units.
*/

@interface AdInteractionSystem: AdMatrixStructureCoder <AdSystemCoordinatesObserving>
{
	@private
	int numberOfElements;
	int systemOneElements;
	int systemTwoElements;
	int mementoMask;
	NSRange systemOneRange;
	NSRange systemTwoRange;
	AdMatrix *coordinates;
	NSArray* systems;
	NSMutableArray* availableInteractions;
	NSMutableArray* nonbondedPairs;
	NSMutableDictionary* interactionGroups;
	NSMutableDictionary* interactionParameters;
	NSMutableDictionary* categories;
	AdSystem* systemOne;
	AdSystem* systemTwo;
	AdMutableDataMatrix* elementProperties;
	AdMutableDataMatrix* elementConfiguration;
	AdDataMatrix* immutableElementProperties;
	AdMutableDataMatrix* groupProperties;
}

/**
Calls the initWithSystems:() using the values in \e dict.
\e dict must have one key, systems, whose value is an array
of AdSystem instances.
*/
- (id) initWithDictionary: (NSDictionary*) dict;
/**
Designated initialiser.
Initialises an AdInteractionSystem representing the interactions between the two
AdSystem objects in \e anArray.
\param anArray An NSArray containing two AdSystem instances. Required.
*/
- (id) initWithSystems: (NSArray*) anArray;
/**
Initialises an AdInteractionSystem representing the interactions between two
AdSystem objects.
\param firstSystem An AdSystem instance.
\param secondSystem An AdSystem instance.
*/
- (id) initWithSystemOne: (AdSystem*) firstSystem
	systemTwo: (AdSystem*) secondSystem; 
/**
Returns the name of the system. This is <e>firstSystemNamesecondSystemName<\e>Interaction
*/
- (NSString*) systemName;
/**
Returns the configuration of the elements of the system
as an AdMatrix structure. This is the combined configuration 
of the interacting systems. The elements of the first system
in the data source array appear first. If no data source has been set 
this method returns NULL. The returned matrix is owned by the
receiver and will be deallocated by it when it is released.
*/
- (AdMatrix*) coordinates;
/**
Returns the masses of all the interacting elements
*/
- (NSArray*) elementMasses;
/**
Returns a an AdDataMatrix containing the combined
properties of all the interacting elements
*/
- (AdDataMatrix*) elementProperties;
/**
Returns the types of the elements in the system
*/
- (NSArray*) elementTypes;
/**
Returns the interacting systems
*/
- (NSArray*) systems;
/**
Returns the range of indexes in the combined attributes
returned by the receiver which refer to the elements of \e aSystem.
If \e aSystem is not part of the AdInteractionSystem object the 
returned range has location and length 0. See the class documentation for more.
\return An NSRange containing the range
*/
- (NSRange) rangeForSystem: (AdSystem*) aSystem;
/**
Returns the combined number of elements in both systems
*/
- (unsigned int) numberOfElements;
/**
See AdDataSource for method description.
Allows additional interaction type with specific
groups and parameters to be added to the system. Each entry
in \e group must contain indexes of elements from both
systems. If not an NSInternalInconsistencyException is
raised.
*/
- (void) addInteraction: (NSString*) name
	withGroups: (AdDataMatrix*)  group
	parameters: (AdDataMatrix*) parameters
	constraint: (id) anObject
	toCategory: (NSString*) category;
/**
Returns an array containing the names of the interactions
that occur between the two systems. 
\todo Expand Documentation
*/
- (NSArray*) availableInteractions;
/**
Returns the group matrix for the interaction \e interaction.
If there is no group matrix and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised. If no
data source has been set this method returns nil.
*/
- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction;
/**
Returns the parameters matrix for the interaction \e interaction.
If there are no parameters and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised. If no
data source has been set this method returns nil.
*/
- (AdDataMatrix*) parametersForInteraction: (NSString*) interaction;
/**
Returns the index set array for \e category.
If there is no index set array and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised.
\todo Partial Implmentation - At the moment this will just return
the index set array associated with the nonbonded interactions in a
molecular mechanics force field.
*/
- (NSArray*) indexSetArrayForCategory: (NSString*) category;
@end

#endif
