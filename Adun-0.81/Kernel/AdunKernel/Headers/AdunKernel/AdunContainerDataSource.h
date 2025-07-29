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
#ifndef _ADCONTAINERDATASOURCE_
#define _ADCONTAINERDATASOURCE_

#include <stdbool.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include "Base/AdVector.h"
#include "Base/AdQuaternion.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunGrid.h"
#include "AdunKernel/AdunSphericalBox.h"
#include "AdunKernel/AdunMoleculeCavity.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunDataSource.h"

/**
\ingroup Inter
AdContainerDataSource creates and manages a collection of structures of a given type in a given
volume (container). The structure's topology is defined by an object which conforms to the AdSystemDataSource protocol.
The size and shape of the volume is defined by a cavity object which must conform to AdGridDelegate.
The number of structures to be placed in the volume is calculated from the density parameter.
The units of the density parameter are defined by the mass and distance units used by the data source.

Once the number of structures is known AdContainerDataSource replecates the information in the data source
that many times and uses grid points created by an AdGrid object as initial positions for the structures.
The structures are randomly oriented when first placed.

AdContainerDataSource also provides methods that allow you to define exclusion areas within the volume updating
the molecule contents as appropriate - see the AdContainerDataSourceInsertionExtensions category.

\todo Missing Functionality - Does not calculate the grid spacing correctly
\todo Missing Functionality - Handling of cavity expansion and contraction
\todo Missing Functionality - Information on inserted systems not encoded.
\todo Internal - Remove use of "solvent" prefix from ivars.
\todo Affected by Task - Units

**/

@interface AdContainerDataSource: NSObject <AdSystemDataSource>
{
	@private
	BOOL memento;
	int seed;
	gsl_rng* twister;
	id dataSource;
	id memoryManager;
	id environment;
	NSString* currentCaptureMethod;
	NSString* systemName;
	//grid variables 
	id solventGrid;			//!< the grid matrix
	id gridDelegate;		//!< Object defining the volume
	//System variables		
	double solventDensity;		//!< the target solvent density
	double solventMass;		//!< the mass of the solvent
	int currentNumberOfMolecules;	//!< the no of molecules that are currently in the sphere
	int numberOccludedMolecules;	//!< the number of solvent molecules hidden by the solute
	int atomsPerMolecule;		//!< the number of atoms in a solvent molecule
	AdMutableDataMatrix* elementProperties;
	AdMutableDataMatrix* elementConfiguration;
	AdMutableDataMatrix* groupProperties;
	NSMutableArray* interactions;
	NSMutableDictionary* interactionGroups;
	NSMutableDictionary* interactionParameters;
	NSMutableDictionary* categories;
	NSMutableArray* nonbondedPairs;
	NSMutableArray *removedMolecules;	//!< Amount of molecules removed for each system insertion
	NSMutableArray *containedSystems;	//!< The systems that have been inserted.
}
/**
Designated initialiser.
\param source A object which provides the structure that will be
replicated throughout the cavity. Must conform to both the AdSystemDataSource and NSCopying protocols.
Cannot be nil.
\param cavity An object that implements the AdGridDelegate protocol. If it doesnt
an NSInvalidArgumentException is raised.
\param density The density of the resulting cavity. The units of density are
defined by the units used in the data source for distance and mass.
\param anInt Seed for random number generation.
\param An NSArray containing AdSystem objects that will be inserted into the container.
*/
- (id) initWithDataSource: (id) source 
	cavity: (id) cavity
	density: (double) density
	seed: (int) anInt
	containedSystems: (NSArray*) anArray;
/**
As initWithDataSource:cavity:density:seed:containedSystems:
passing nil for \e anArray.
*/
- (id) initWithDataSource: (id) source 
	cavity: (id) cavity
	density: (double) density
	seed: (int) anInt;
/**
Returns a new AdContainerDataSource instance initialised with the
values from \e dict.
The keys of \e aDict are defined by the names of each of the arguments
in the designated initialiser i.e. dataSource, cavity, density, seed &
containedSystems. If a key is not present nil is passed for
the corresponding argument in the designated initialiser.
*/
- (id) initWithDictionary: (NSDictionary*) dict;	
/**
Changes the configuration of the elements to the 
coordinates in \e aMatrix. \e aMatrix must have one
entry for each atom. Usually used by AdSystem
to synch the data source configuration with its current configuration.
When performing insertion/removal you must make sure that the
configuration in the data source is correct.
*/
- (void) setElementConfiguration: (AdDataMatrix*) configuration;
/**
Returns the container cavity.
*/
- (id) cavity;
/**
Returns the density of elements in the cavity.
*/
- (double) density;
/**
Returns the number of elements in the AdContainerDataSource objects
data source.
\todo Deprecate.
*/
- (int) atomsPerMolecule;
/**
Returns the name of the data source
*/
- (NSString*) name;
@end

/**
\ingroup Inter
Category containing methods allowing cavities and AdSystem objects to be
inserted into, and removed from,  the volume defined by the container.
The contents of the container are updated as needed i.e. Container
molecules are added removed.

\note AdContainerDataSource does not monitor AdSystemContentsDidChangeNotification
from the contained systems. In order to correctly handle addition of molecule
you must first remove the system, then modifiy it and finally reinsert the new
system.
*/
@interface AdContainerDataSource (AdContainerDataSourceInsertionExtensions)
/**
Removes container structures that lie inside the volume defined by \e cavity.
They cannot be reinserted.
If any part of a structure resides in the cavity then the whole structure is removed.
\return The number of molecules removed.
*/
- (int) setExclusionArea: (id) cavity;
/**
Inserts \e system into the volume defined by the AdContainerDataSource
instance. Molecules lying within the Van der Waals radius of any of
the systems elements are removed. The properties of the system elements
must include either type A or B Lennard Jones parameters. 
\return The number of molecule removed
*/
- (int) insertSystem: (AdSystem*) system;
/**
Removes the previously inserted system \e system. AdContainerDataSource
identifies the system by its name. The volume occupied by the
system is calculated and AdContainerDataSource attempts to insert the
same number of molecules as were removed into the volume (though this
may not always be possible).
\return The number of molecules reinserted.
*/
- (int) removeSystem: (AdSystem*) system;
/**
The number of molecules that have been removed through insertion
*/
- (int) numberOccludedMolecules;
/**
Returns an array of the AdSystem instances that have been inserted.
*/
- (NSArray*) containedSystems;
@end

#endif
