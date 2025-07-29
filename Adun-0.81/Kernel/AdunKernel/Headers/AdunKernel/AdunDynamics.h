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
#ifndef ADUN_DYNAMICS
#define ADUN_DYNAMICS

#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>
#include <Base/AdVector.h>
#include <Base/AdBaseFunctions.h>
#include "AdunKernel/AdMatrixModification.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"

/**
\ingroup Inter
AdDynamics is used internally by AdSystem to manage and manipulate its variable data
i.e. coordinates and velocities along with kinetic energy, temperature and
current degrees of freedom. 
It obtains the initial coordiantes along with element types and masses from its data source which must 
conform to the AdSystemDataSource protocol. AdDynamics conforms to NSCoding but only supports keyed coding.

For convience AdDynamics also directly provides arrays
containing the element types and masses. This information is also
contained in the AdDataMatrix returned by the data source's AdDataSource::elementProperties method.

AdDynamics instances are always created and used by AdSystem objects you should never
expicitly create or use one directly yourself.

\todo Extra Documentation - Required data source headers. Affects AdSystem & AdInteractionSystem.
\todo Internal - Change how AdCopyAdMatrixToAdMatrix works.
\todo Affected by Task - Units. How do we know the units of distance, velocity etc.
\todo There may be no velocity information associated with the data source - How to deal with this?
e.g. Just set temperature to 0.??
How do we know what the temperature conversion factor is?
*/

@interface AdDynamics: NSObject <AdMatrixModification>
{
	@private
	int seed;
	int numberOfElements;
	int degreesOfFreedom;
	double totalMass;
	double temperature;
	double kineticEnergy;
	double kineticEnergyToTemperature;
	double targetTemperature;
	double* masses;
	Vector3D centreOfMass;
	gsl_rng* twister;
	NSLock *coordinatesLock;
	NSLock *velocitiesLock;
	AdMatrix* coordinates;
	AdMatrix* velocities;
	NSArray* elementTypes;
	NSArray* elementMasses;
	id memoryManager;
	id dataSource;
}
/**
Designated initialiser. 
\param anObject The data source to be used. 
Must confrom to the AdSystemDataSource protocol and cannot be nil. If nil is
passed an NSInvalidArgumentException is raised.
\param initialTemperature The temperature to be used when generating the inital velocities
of the elements in Kelvin. The velocities are drawn from a Maxwell-Boltzmann distribution
at this temperature. Cannot be less than 0. If its is it defaults to 300.
\param rngSeed Integer to be used as the seed for random number generation. 
This is useful if you want the exact same velocities to be generated
on different runs.
\param value YES if you want the translational degrees of freedom of the system
to be removed, NO otherwise.
*/
- (id) initWithDataSource: (id) anObject
	targetTemperature: (double) temperature
	seed: (int) rngSeed
	removeTranslationalDOF: (BOOL) value;
/**
As initWithDataSource:targetTemperature:seed: 
using default values for \e initialTemperature, \e rngSeed
and \e value (300, 500 and YES respectively).
*/
- (id) initWithDataSource: (id) anObject;
/**
Calculates the centre of mass of the system.
The result can be retrieved using centreOfMass() 
*/
- (void) calculateCentreOfMass;
/**
Moves the center of mass of the system to the origin.
*/
- (void) moveCentreOfMassToOrigin;
/**
Moves the center of mass of the system to the coordinates
contained in the array \e point.
\note Change to Vector3D or NSArray
*/
- (void) centreOnPoint: (double*) point;
/**
Moves the element identified by \e elementIndex to the origin
*/
- (void) centreOnElement: (int) elementIndex;
/**
Reinitialise the velocities drawining new values from
a Maxwell-Boltzmann distribution at the current target
temperature.
*/
- (void) reinitialiseVelocities;
/**
Removes the translational degress of freedom of the system.
\note Due to the discrete nature of a simulation it is
possible that the translational deegres of freedom may
reappear during a simulation.
*/
- (void) removeTranslationalDOF;
/**
Returns the number of elements in the system.
The same as [dataSource numberOfElements].
*/
- (unsigned int) numberOfElements;
/**
Returns the force field types of the elements.
*/
- (NSArray*) elementTypes;
/**
Returns the element masses.
*/
- (NSArray*) elementMasses;
/**
Returns the coordinates of the system
as an AdMatrix.
*/
- (AdMatrix*) coordinates;
/**
Copies the values in \e matrix into
the systems coordinates matrix.
*/
- (void) setCoordinates: (AdMatrix*) matrix;
/**
Returns the velocites of the system
as an AdMatrix.
*/
- (AdMatrix*) velocities;
/**
Copies the values in \e matrix into
the systems velocties matrix.
*/
- (void) setVelocities: (AdMatrix*) matrix;
/**
Returns the kinetic energy.
*/
- (double) kineticEnergy;
/**
Returns the current temperature.
*/
- (double) temperature;
/**
Returns the current degrees of freedom.
*/
- (unsigned int) degreesOfFreedom;
/**
Returns the total mass of the system.
*/
- (double) totalMass;
/**
Returns the center of mass of the system.
*/
- (Vector3D) centreOfMass;
/**
Returns the last seed used to initialise
the internal random number generator.
*/
- (int) seed;
/**
Sets the seed to \e aNumber reinitialise
the random number generator.
*/
- (void) setSeed: (int) aNumber;
/**
Returns the target temperature.
*/
- (double) targetTemperature;
/**
Sets the target temperature.
*/
- (void) setTargetTemperature: (double) aNumber;
/**
Returns the data source being used by the object.
*/
- (id) dataSource;
@end

#endif

