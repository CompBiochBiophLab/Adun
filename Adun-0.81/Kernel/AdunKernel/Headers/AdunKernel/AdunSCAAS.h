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
#ifndef _ADSCAAS_
#define _ADSCASS_

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <float.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include "Base/AdVector.h"
#include "Base/AdSorter.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdForceFieldTerm.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdunContainerDataSource.h"

/** 
Object that applies Surface Constrained All-Atom Solvent (SCAAS) boundary contraints
to an AdSystem object representing a spherical container (usually containing water).

<b> Contained Systems </b>

AdSCAAS objects require the contained systems to be explicitly specified even though
they can be retrieved using AdContainerDataSource::containedSystems() on the systems.
This is to give finer grained control over who should be considered solute when
calculating solute charge since the SCAAS algorithm properly only compensates for
charged solutes when they are in the centre of the sphere.

However the number of molecules occluded by the solute(s) is taken directly from 
the container using AdContainerDataSource::numberOccludedMolecules.
i.e. it depends on who has been inserted not what systems are supplied
as containedSystems.

AdSCAAS instances observe AdSystemContentsDidChangeNotification's from both the
system it applies the boundary conditions to and all contained systems. On receiving
such a notification the object updates itself as necessary.

\todo Internal - Fix untidy mixture of naming conventions for internal variables.
\todo Extra Documentation - SCAAS algorithm and theory.
\ingroup Inter
**/

@interface AdSCAAS: AdMatrixStructureCoder <AdForceFieldTerm>
{
	@private
	BOOL isChargedSolute;
	int no_solvent_atoms;
	int no_solute_atoms;
	int atoms_per_molecule;
	int no_solvent_molecules;
	int no_surface_molecules;
	int inside_count;
	double targetTemperature;
	double KBT;			//boltzmanns contstant times the target temperature
	double solute_charge;
	double surface_region;
	double sphereRadius;
	double inner_sphere;
	double solvent_mass;		//mass of a solvent molecule
	double solvent_density;
	double occlusion_factor;
	double alpha;		 	//for equilibrium radial distance calculation		
	double beta;			//for equilibrium radial distance calculation	
	double variance;
	double sigma;
	double *polarisation_angles; 	//hold the polarisation angle of each surface molecule	
	double *solventMasses;		//Masses of the solvent molecules
	double *solventCharges;		//Charges of the solvent molecules
	IntMatrix *solventIndexMatrix;		//a matrix telling which atoms make up each molecule
	AdMatrix *forceMatrix;
	int (*comparison_pt) (const void*, const void*);
	gsl_rng* twister;	
	Vector3D *radial_distance;		//holds the centre of mass of each molecule
	Vector3D *dipoles;
	Vector3D *cavityCentre; 		
	Sort *radial_sorter;
	Sort *polarisation_sorter;
	id system;
	NSArray* containedSystems;
	id memoryManager;
}
/**
As initWithSystem:() passing nil for system.
*/
- (id) init;
/**
As initWithSystem:containerSystems:() passing nil for \e systems.
*/
- (id) initWithSystem: (AdSystem*) containerSystem;
/**
As initWithSystem:containerSystems:boundaryDepth:targetTemperature:()
with a boundary depth of 1.5 and a temperature of 300.
*/
- (id) initWithSystem: (AdSystem*) containerSystem
	containedSystems: (NSArray*) systems;
/**
Designated initialiser.
Initialises an AdSCAAS object that applies the SCAAS boundary conditions to \e containerSystem.
\param containerSystem An AdSystem object. Its data source must be an AdContainerDataSource and the
corresponding cavity must be an AdSphericalBox instance otherwise an NSInvalidArgumentException is raised.
\param systems An array of AdSystem objects that have been inserted into \e containerSystem. The SCAAS
algorithm modifies the forces it applies depending on the total charge of these objects. Passing nil
here assumes any contained systems are uncharged. Has no effect if \e containerSystem is nil. See documentation
for more.
\param depth Double specifying the depth of the SCAAS boundary from the surface of the sphere.
The object will apply forces to molecules whose centre of mass lies in this region. \e size
must be greater than 0. If its not it defaults to 1.
\param temp The target temperature for the molecules in the boundary region. Frictional forces
will be applied to these molecule to maintain this temperature. Cannot be less than 0. If it
is it defaults to 0.
*/
- (id) initWithSystem: (AdSystem*) containerSystem
	containedSystems: (NSArray*) systems 
	boundaryDepth: (double) depth 
	targetTemperature: (double) temp; 
/**
Sets the systems contained by the object returned by system() to
those in \e anArray. Has no effect if no system has been set.
*/
- (void) setContainedSystems: (NSArray*) anArray;
/**
Returns an array containing the systems contained by the AdSystem
object the receiver is operating on.
*/
- (NSArray*) containedSystems;
/**
Sets the target temperature to \e value. See initWithSystem:containedSystems:boundaryDepth:targetTemperature:()
for more information.
*/
- (void) setTargetTemperature: (double) value;
/**
Returns the target temperature.
*/
- (double) targetTemperature;
/**
Sets the depth of the bundary region to \e value. See initWithSystem:containedSystems:boundaryDepth:targetTemperature:()
for more information.
*/
- (void) setBoundaryDepth: (double) value;
/**
Returns the depth of the SCAAS boundary region.
*/
- (double) boundaryDepth;
/**
\todo Not Implemented
*/
- (void) setExternalForceMatrix: (AdMatrix*) matrix;
/**
\todo Partial Implementation - Always returns NO.
*/
- (BOOL) usesExternalForceMatrix;
@end

#endif
