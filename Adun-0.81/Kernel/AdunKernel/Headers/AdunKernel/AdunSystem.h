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
#ifndef ADUN_SYSTEM
#define ADUN_SYSTEM

#include "AdunKernel/AdMemento.h"
#include "AdunKernel/AdunMatrixStructureCoder.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunDynamics.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdunDataSet.h"
#include "AdunKernel/AdunTimer.h"
#include "AdunKernel/AdunDataSource.h"
#include "AdunKernel/AdMatrixModification.h"

@class AdInteractionSystem;


/**
Sent when status is changed. Object is the AdSystem whose status changed.
UserInfo contains two keys - PreviousStatus and CurrentStatus. 
*/
#define AdSystemStatusDidChangeNotification @"AdSystemStatusDidChangeNotification"
/**
Sent when the number of elements in the system changes. Before
this notification is sent all previous dynamic lists are removed. The notification object is the
sending system. There is no user info dictionary.
*/
#define AdSystemContentsDidChangeNotification @"AdSystemContentsDidChangeNotification"

/**
\ingroup Inter
An AdSystem object represents a set of elements whose configuration can vary. 

Two types of data are associated with the elements -  static and variable. 
The variable data includes their coordinates & velocities. This data is stored by the
AdSystem object and it provides methods to change and manipulate it.

The static data includes the topology and properties of the elements.
AdSystem instances do not store this information themselves but retrieve it from a \e data \e source.
The AdSystemDataSource protocol declares the methods used by AdSystem objects to access the contents
of their data source.

AdSystem conforms to NSCoding but only supports keyed coding. 
The AdSystemScriptingExtensions category contains extra methods useful when using
AdSystem from a scripting environment.

\n
<b> Principal Attributes </b>

- a data source
- the variable properties of the system: coordinates and velocities 

\n
<b> Mementos </b>

Modification of an AdSystem objects variable data changes its state.
Through the AdMemento protocol an AdSystem instances state can be fully or partially recorded and the result can be
used at any time to return it (or another AdSystem instance) to the recorded state. 

Mementos created by AdSystem can optionally contain the current coordinates and velocities.
You set what a memento will contain using the AdSystem::setCaptureMask: method.
\e mask is a bitwise OR of the values defined by the #AdSystemMementoValue enum.

- AdSystemCoordinatesMemento
- AdSystemVelocitiesMemento

For example, if you wish to record coordinates and velocities
\code

int mask;

mask = AdSystemCoordinatesMemento | AdSystemVelocitiesMemento;
[system setCaptureMask: mask];

\endcode

By default AdSystem objects only record coordinates in their mementos.
You can get the current mask is using AdSystem::captureMask.
A bitwise AND of the returned value and an option will be 1 if the option
is set and 0 otherwise.

\code

mask = [system captureMask];

if(mask & AdSystemCoordinatesMemento)
	//The system is recording coordinates in its mementos
else
	//The system isn't record coordinated in its mementos

\endcode	

An AdSystem memento can only be used as long as the
systems data source contains the same number of elements
as when the memento was captured e.g. There are 
200 elements in a system and a memento is recorded. If later
some elements are removed from the system the memento cannot
be used to return it to the previous state. 

\n
\b Notifications

AdSystem instances send the following notification after reloading their data

- #AdSystemContentsDidChangeNotification  

The notification object is the system and the userInfo is nil. 
Its important to note that this notification implies all the AdMatrix
structs returned by the sender have become invalid. Hence objects should not
retain references to these structures since methods that use such references
may be called in the period between when the notification is sent and the
object receives it e.g. by other objects that receive the notfication first.

\n
<b> Updating Interaction Systems </b>

AdInteractionSystem instances need to know when the coordinates of their consituent
AdSystem objects change so they can update their coordinate matrices. 
This necessitates that AdSystem instances maintain references to AdInteractionSystem objects that
contain them. However, in order to avoid circular references, they must be weak-references.

This is handled in the following way.
On creation an AdInteractionSystem object reigisters with its systems by sending registerInteractionSystem:()
to each. On deallocation it notifies them by sending removeInteractionSystem:() to each.
Each time setCoordinates:() is called, AdSystem objects notify the registered AdInteractionSystem objects
using AdInteractionSystem::systemDidUpdateCoordinates:

\section reload Reloading Data

Often you will modify the contents of a system, for example by changing a property or interaction paramater, 
and wish all other objects using the system to update themselves accordingly e.g. force-fields.
This complex process is achieved simply by calling reloadData() on the system.
This causes an AdSystemContentsDidChangeNotification to be broadcast which is observed by all interested objects.

However there are a couple of caveats that must be noted when reloading.

Firstly when you call reloadData() the element coordinates will be set to the values returned by the systems data source
(via AdDataSource::elementConfiguration).
However AdSystem objects do not modify the data source configuration unless updateDataSourceConfiguration() is called.
Therefore you must call this method before calling reloadData() - if you don't the systems coordinates will be reset. 

Secondly updateDataSourceConfiguration() requires that the data source is mutable i.e. An instance of AdMutableDataSource.
You must make sure the data source is mutable, for example by creating a mutable copy and using it, if you want
to use updateDataSourceConfiguration()

Finally you should know how the various objects react to reloading data.
For example a reload will cause AdCellListHandler to rebuild the list of nonbonded interactions which you may not want.
Different classes will have different methods for customising their behaviour on receiving AdSystemContentsDidChangeNotification.

In AdunKernel Framework the following objects observe AdSystemContentsDidChangeNotification from AdSystem instances
they work with.

- All AdForceField subclasses - These take account of interaction, parameter, configuration or contents updates.
- All AdListHandler subclasses - These take account of interaction, parameter, configuration or contents updates.
- AdCheckpointManager - This creates a topology checkpoint - Use stopCheckpointing() to modify this behaviour
- All objects that conform to AdForceFieldTerm (except AdNonbondedTerms) must handle this notification e.g. AdScaas, AdSmoothedGBTerm
- AdInteractionsSystems involving the system

AdNonbondedTerm subclasses are a special case as they learn about the reload from the AdListHandler instances they use.
Note: AdContainerDataSource does not update itself if systems they contains change. 
This is important if you've radically changed the configuration of these contained systems. 
See AdContainerDataSource for more.

\todo Internal - Change notification defines to extern variables?
\todo Missing docs - Information required to be in the data source e.g. masses? coordinates? element type?
*/

@interface AdSystem: AdMatrixStructureCoder <AdMemento, AdMatrixModification>
{
	@private
	BOOL removedTranslationalDOF; 
	int mementoMask;
	int numberOfAtoms;
	int degreesOfFreedom;
	int logInterval;
	int seed;
	double targetTemperature;
	NSString* systemName;
	NSMutableArray* interactionSystemPointers;
	AdDynamics* dynamics;
	id dataSource;
	id environment;
}
/**
Class method version of initWithDataSource:()
*/
+ (id) systemWithDataSource: (id) aDataSource;
/**
As initWithDataSource:name:initialTemperature:seed:centre:removeTranslationalDOF:
with nil for name and centre, 300 for initialTemperature, 1 for seed and YES for removeDOF.
*/
- (id) initWithDataSource: (id) aDataSource;
/**
Creates a new system using \e aDataSource as a data source.
\param aDataSource An object that conforms to the AdSystemDataSource protocol. If not an NSInvalidArgumentException
is raised. Cannot be nil.
\para name The name to be associated with the system. If nil this defaults to the data source name.
\param temperature The initial velocities of the system are drawn from a Maxwell-Boltzmann 
distribution at this temperature.
\param rngSeed Value used for initialising internal random number generators.
\param point A NSArray specifying a point in cartesian space where the centre of mass of the system will be placed. 
If nil the centre of mass of the system is defined by the configuration supplied by the systems data source.
\param value A boolean value. YES indicates that the AdSystem object should remove the translational degrees of
freedom from the system after it generates its initial velocities. Has no effect if \e dataSource is nil.
*/
- (id) initWithDataSource: (id) aDataSource
	name: (NSString*) name
	initialTemperature: (double) temperature
	seed: (int) rngSeed
	centre: (NSArray*) point
	removeTranslationalDOF: (BOOL) value;
/**
Calls the designated initialiser with the values in \e aDict.
The keys of \e aDict are defined by the names of each of the arguments
in the designated initialiser i.e. dataSource, name, initialTemperature, seed, centre &
removeTranslationalDOF. If a key is not present nil is passed for
the corresponding argument in the designated initialiser.
*/
- (id) initWithDictionary: (NSDictionary*) aDict;
/**
Removes the translational degress of freedom of the system.
Does nothing if the systems status is passive.
\note Due to the discrete nature of a simulation it is
possible that the translational deegres of freedom may
reappear during a simulation.
*/
- (void) removeTranslationalDegreesOfFreedom;
/**
Copies the values in \e matrix into
the systems coordinates matrix.
*/
- (void) setCoordinates: (AdMatrix*) aMatrix;
/**
Copies the values in \e matrix into
the systems velocties matrix.
*/
- (void) setVelocities: (AdMatrix*) aMatrix;
/**
Reinitialise the velocities drawining new values from
a Maxwell-Boltzmann distribution at the current target
temperature.
*/
- (void) reinitialiseVelocities;
/**
Moves the center of mass of the system to the origin.
Same as setCentre: passing (0,0,0).
No effect if no data source has been set.
*/
- (void) moveCentreOfMassToOrigin;
/**
Returns the centre of mass of the system as
an NSArray of NSNumbers.
*/
- (NSArray*) centre;
/**
Moves the center of mass of the system to the coordinates
contained in the array \e point. 
\param point An NSArray of NSNumbers.
*/
- (void) setCentre: (NSArray*) point;
/**
Returns the centre of mass of the system as
a Vector3D struct
*/
- (Vector3D) centreAsVector;
/**
As setCentre: but passing the coordinates as an
c-array of doubles.
*/
- (void) centreOnPoint: (double*) point;
/**
Moves the element identified by \e index to the origin
*/
- (void) centreOnElement: (unsigned int) elementIndex;
/**
Returns the name of the system. This is the same as the name of the
systems data source. If no data source has been set then this method
returns nil.
*/
- (NSString*) systemName;
/**
Returns the numner of elements in the system.
*/
- (unsigned int) numberOfElements;
/**
Returns the current kinetic energy of the system in simulation
units. If no data source has been set this method returns -1.
*/
- (double) kineticEnergy;
/**
Returns the current temperature of the system in simulation
units. If no data source has been set this method returns -1.
*/
- (double) temperature;
/**
Returns the system degrees of freedom.
If no data source has been set then this is -1.
*/
- (unsigned int) degreesOfFreedom;
/**
Returns the configuration of the elements of the system
as an AdMatrix structure.  If no data source has been set 
this method returns NULL. The returned matrix is owned
by the AdSystem object and will be freed when its released.
*/
- (AdMatrix*) coordinates;
/**
Returns the velocities of the elements of the system
as an AdMatrix structure. If no data source has been
set this method returns NULL. The returned matrix is owned
by the AdSystem object and will be freed when its released.

*/
- (AdMatrix*) velocities;
/**
Returns the masses of elements in the system.
*/
- (NSArray*) elementMasses;
/**
Returns the properties of the elements in the system.
*/
- (AdDataMatrix*) elementProperties;
/**
Returns the types of the elements in the system as given by 
the "ElementType" column of the data source element properties matrix.
*/
- (NSArray*) elementTypes;
/**
Returns the systems data source
*/
- (id) dataSource;
/**
Sets the systems data source to be \e anObject.
Note that this will not change the receivers name as
set on initialisation as this is used by other classes
to identify the object. Hence this method is mainly
for replacing a immutable data source with a mutable copy.
*/
- (void) setDataSource: (id) dataSource;
/**
Reloads the systems data source. This causes
all AdMatrix references previously returned by the object to become invalid.
When the data has been reloaded a 
#AdSystemContentsDidChangeNotification is sent. 
Reloading the data also has the effect of reinitialising the element velocities.
*/
- (void) reloadData;
/**
Updates the element configuration of the data source with
the system current configuration. The data source must respond to
setElementConfiguration. If it does not this method does nothing.
You should usually call this method before modifying the data source.
\note If you add/remove elements from the data source and call
this method \e before calling reloadData() an exception will be raised.
*/
- (void) updateDataSourceConfiguration;
/**
Returns an array containing the names of the interactions
that are present in the system. Returns nil if no data source
has been set.
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
Description forthcomming
*/
- (NSArray*) indexSetArrayForCategory: (NSString*) category;
/**
Sent by AdInteractionSystem instances 
to their constituent AdSystem objects on initialisation.
*/
- (void) registerInteractionSystem: (AdInteractionSystem*) anInteractionSystem;
/**
Sent by AdInteractionSystem instances  
to their constituent AdSystem objects on deallocation.
*/
- (void) removeInteractionSystem: (AdInteractionSystem*) anInteractionSystem;
/**
Returns the AdInteractionSystem objects the receiver is part of.
*/
- (NSArray*) interactionSystems;
/**
\todo Partial Implementation - Always returns YES.
*/
- (BOOL) validateMemento: (id) aMemento;
@end

/**
\ingroup frameworkTypes
AdSystemMementoValue defines the information that
can be included in an AdSystem memento
*/

typedef enum
{
	AdSystemCoordinatesMemento = 1, /**< A memento including the coordinates of the system*/
	AdSystemVelocitiesMemento = 2  /**< A memento including the velocites of the system*/
}
AdSystemMementoValue;

/**
\ingroup Protocols 
Defines methods implemented by AdInteractionSystem 
to enable instances to receive updates when the coordinates
of their consituent AdSystem objects change.
*/
@protocol AdSystemCoordinatesObserving
/**
Sent by the AdSystem instances of an AdInteractionSystem object
when their coordinate matrices are changed.
On receiving this message the AdInteractionSystem object updates its
coordinate matrix with \e aSystems new coordinates.
Has no effect is \e aSystem is not one of receivers systems.
*/
- (void) systemDidUpdateCoordinates: (AdSystem*) aSystem;
@end

#endif
