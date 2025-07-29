/*
   Project: Adun

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

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
#ifndef _ADMINIMISER_
#define _ADMINIMISER_

#include <stdio.h>
#include <gsl/gsl_multimin.h>
#include "AdunKernel/AdunConfigurationGenerator.h"

/**
\ingroup Inter
AdMinimiser instances perform minimisations on the systems in a given AdSystemCollection instance 
using the gradients and energies of those system as calculated by the provided force fields. 

Four different minimisation algorithms are available and these can be switched between using the
setAlgorithm:() method. They are

- Fletcher Reeves Conjugate Gradient
- Polak Ribiere Conjugate Gradient
- The Broyden-Fletcher-Goldfarb-Shanno (BFGS) Algorithm
- Steepest Descent

In all cases the minimisation ends when either the defined maximum number of iterations has been completed
or when the given absolute tolerance is reached.

\section tol Tolerance & StepSize

\e Description \e Forthcomming

*/

@interface AdMinimiser: AdConfigurationGenerator 
{
	@private
	BOOL endSimulation;
	int checkFPErrorInterval;	//!< Interval at which to check for floating point errors
	NSAutoreleasePool* pool;	//!< An autorelease pool for the simulation loops
	NSArray* systems;
	AdSystemCollection* systemCollection;
	AdForceFieldCollection* forceFieldCollection;
	AdMainLoopTimer* timer;			//!< Scheduler that is incremented every simulation loop
	//Minmiser specific ivars
	BOOL converged;
	int numberOfElements;		//!< Total number of elements in the systems being minimised
	int numberOfSteps;
	int currentStep;
	double absoluteTolerance;
	double tolerance;
	double stepSize;
	double currentEnergy;
	double gradientNorm;
	gsl_multimin_function_fdf minimistationFunctions;
	const gsl_multimin_fdfminimizer_type *algorithmType;	
	NSString* algorithmName;
	NSMutableDictionary* systemRanges;
	NSArray* fullSystems;
	NSMutableDictionary* constraints;	//!< Holds constraint information - keys: system pointers, values: constraint matrix pointers.
}
/**
As initWithForceFields:() passing nil for \e aForceFieldCollection
*/
- (id) init;
/**
As initWithSystems:forceFields:() passing nil for \e aSystemCollection
*/
- (id) initWithForceFields: (AdForceFieldCollection*) aForceFieldCollection;
/**
As initWithSystems:forceFields:absoluteTolerance:numberOfSteps() with \e steps set to 10000
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection;
/**
As initWithSystems:forceFields:absoluteTolerance:numberOfSteps:algorithm:stepSize:tolerance:() passing
SteepestDescent for the algorithm and x and y for the stepsize and tolerance repectively.
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	absoluteTolerance: (double) absTol
	numberOfSteps: (unsigned int) steps;
/**
As initWithSystems:forceFields:absoluteTolerance:numberOfSteps:algorithm:stepSize:tolerance:checkFPErrorInterval:()
with \e interval set to 1000
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	absoluteTolerance: (double) absTol
	numberOfSteps: (unsigned int) steps
	algorithm: (NSString*) algorithm
	stepSize: (double) stepsize
	tolerance: (double) tol;
/**
Designated initialiser
\param aSystemCollection An AdSystemCollection instance containing the AdSystem objects that will
be simulated.
\param aForceFieldCollection An AdForceFieldCollection object used to update the forces acting on the
AdSystem instance in \e aSystemCollection. 
\param absTol When the norm of the gradient is less than this value the minimisation ends.
\param numberOfSteps The maximum number of iterations to perform.
\param aString The algorithm to be used - Choices are FletcherReevesCG, PolakRibiereCG, BFGS or SteepestDescent.
Defaults to SteepestDescent if nil. Raises an NSInvalidArgumentException if \e isnt a valid choice.
\param stepSize The distance to move in the first minimistaion step.
\param tol The meaning of this parameters depends on the chosen algorithm. See the docs.
\param interval Interval at which to check for floating point errors
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	absoluteTolerance: (double) absTol
	numberOfSteps: (unsigned int) steps
	algorithm: (NSString*) aString
	stepSize: (double) stepsize
	tolerance: (double) tol
	checkFPErrorInterval: (unsigned int) interval;
/**
Performs the minimisation process. Updates the main loop timer
at every step. The method exits when either the absolute tolerance
or maximum number of steps has been reached (or on detection of an error).
*/
- (BOOL) production: (NSError**) error;	
/**
AdMinimiser instances do not support restarting.
*/
- (BOOL) restartFrom: (int) step error: (NSError**) error;
/**
Sets the system to be simulated to \object.
The simulator observes AdSystemStatusDidChangeNotification's from the systems
it is simulating.
\param object An AdSystemCollection instance. 
*/
- (void) setSystems: (AdSystemCollection*) aCollection;
/**
Sets the force field collection to use for calculating the forces.
*/
- (void) setForceFields: (AdForceFieldCollection*) aCollection;
/**
Returns the tolerance.
*/
- (double) tolerance;
/**
Sets the tolerance to \e aDouble
*/
- (void) setTolerance: (double) aDouble;
/**
Returns the absolute tolerance
*/
- (double) absoluteTolerance;
/**
Sets the absolute tolerance to \e aDouble
*/
- (void) setAbsoluteTolerance: (double) aDouble;
/**
Returns the step size.
*/
- (double) stepSize;
/**
Sets the step size to \e aDouble
*/
- (void) setStepSize: (double) aDouble;
/**
Returns the maximum number of minimisation steps to be performed.
*/
- (unsigned int) numberOfSteps;
/**
Sets the maximum number of minimisation steps to be performed
*/
- (void) setNumberOfSteps: (unsigned int) anInt;
/**
Returns the minimisation algorithm being used-
*/
- (NSString*) algorithm;
/**
Sets the algorithm to use.
Raises an NSInvalidArgumentException if \e aString is not one of the allowed algorithms
*/
- (void) setAlgorithm: (NSString*) aString;
/**
Returns the current iteration number
*/
- (unsigned int) currentStep;
/**
Returns the norm of the current gradient
*/
- (double) gradientNorm;
/**
Returns the current energy of the minmisation process. After a production run
this is the minimum energy reached.
*/
- (double) currentEnergy;
/**
Return if the last run converged or not.
*/
- (BOOL) converged;
/**
Supply a set of constraints vectors along which no minimisation will be performed for \e system.
That is, the gradient is set to 0 along these directions.
The constraints vectors are the columns of \e aMatrix.
The number of rows in \e aMatrix must be equal to the three by the total number of elements in \e system.
Otherwise a NSInvalidArgumentException is raised.
If \e system is not one of the systems operated on by the receiver an NSInvalidArgumentException is 
raised.

If any constraints already were set for \e system they are removed.
*/
- (void) setConstraints: (AdDataMatrix*) aMatrix forSystem: (AdSystem*) system;
/**
Returns the constraint matrix containing the constraint information being applied to \e system.
If there is none this method returns nil
*/
- (AdDataMatrix*) constraintsForSystem: (AdSystem*) system;
/**
Removes any constraints set for \e system
*/
- (void) removeConstraintsForSystem: (AdSystem*) system;
@end

#endif
