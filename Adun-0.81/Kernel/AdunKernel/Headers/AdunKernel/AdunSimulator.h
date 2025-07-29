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
#ifndef _ADSIMULATOR_
#define _ADSIMULATOR_

#include <stdio.h>
#include "AdunKernel/AdunConfigurationGenerator.h"

/**
\ingroup Inter

AdSimulator instances are objects that update the configurations of a collection AdSystem objects via numerical integration. 
The AdSystem objects are contained in an AdSystemCollection instance.

The integration is based on the velocity verlet algorithm.
The algorithm has fours steps: 

- Update the velocites by half a step Set up checkpoint files

- Update the positions by a whole step
- Update the accelerations by a whole step (by using AdForceFieldCollection::evaluateForces)
- Update the positions by a half a step.

The mathematical formulas used for steps one, two and four are given below. 
In the following equations \f$\vec r\f$ is the position vector and \f$\vec v\f$ the velocity vector of an AdSystem object.
The acceleration vector \f$\vec a\f$ is the sum of the AdSystems acceleration vector, i.e. due to intra-system forces,
and the accelerations due to each AdInteractionSystem it belongs to, i.e. due to inter-system forces.
\f$t\f$ is the simulation time step.

\f[
\vec v_{i+\frac{1}{2}} =  \vec v_{i} + \frac{\vec a_{i}t}{2} \\
\f]
\f[
\vec r_{i+1} = \vec r_{i} + \vec v_{i+ \frac{1}{2}}t \\
\f]
\f[
\vec v_{i + 1} = \vec  v_{i + \frac{1}{2}} + \frac{\vec a_{i+1}t}{2} \\
\f]

In practice the first two steps are applied to each system, then the new forces are calculated and
finally the last step is applied to each system.  

AdSimulator objects use a provided AdForceFieldCollection instance to update the forces acting on the systems. 
When updating an AdSystem objects coordinates the accelerations used are those calculated by
the \e active AdForceField objects operating it and every AdInteractionSystem instance it is part of. See
AdForceFieldCollection::forceFieldsForSystem:activityFlag: for more.

<b> Components </b>

The restriction to the velocity verlet algorithm allows
us to define a uniform interface for component objects which allow customisation of the integration process.
Any number of components can be added and they are called in the order they were added. 
After each stage of the verlet algorithm a message is sent to the components allowing them to perform custom actions. 
See the AdSimulatorComponent protocol for the component interface.

\note The contents of the AdSystemCollection object should not be modified e.g. from another thread
during a call to AdSimulator::production().
\note The above is also true for the parameters of the AdSimulator object. e.g. if the time step was
changed during a production loop, the simulator components would not be informed.
*/

@interface AdSimulator: AdConfigurationGenerator 
{
	@private
	BOOL endSimulation;
	int numberOfSteps;		//!< The number of steps to be taken
	int currentStep;		//!< The current step
	int checkFPErrorInterval;	//!< Interval at which to check for floating point errors
	double timeStep;		//!< The time step
	double halfTimeStep;			//!< Half the time step
	double halfTimeStepSquared;		//!< timeStep squared divided by two
	NSAutoreleasePool* pool;	//!< An autorelease pool for the simulation loops
	NSArray* systems;
	NSMutableArray* components;
	NSMutableDictionary* systemCoordinates; //!< Contains private coordinate matrices 
	NSMutableDictionary* systemVelocities; //!< Contains private velocity matrices 
	AdSystemCollection* systemCollection;
	AdForceFieldCollection* forceFieldCollection;
	AdMainLoopTimer* timer;			//!< Scheduler that is incremented every simulation loop
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
As initWithSystems:forceFields:numberOfSteps() with \e intOne set to 1000
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection;
/**
As initWithSystems:forceFields:numberOfSteps:timeStep: passing 1 for the time step
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	numberOfSteps: (unsigned int) intOne;
/**
As initWithSystems:forceFields:components:numberOfSteps:timeStep:
passing an empty array for components.
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	numberOfSteps: (unsigned int) intOne
	timeStep: (double) aDouble;
/**
As the designated intialiser passing 100 for the floating point check interval
*/
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	components: (NSArray*) anArray
	numberOfSteps: (unsigned int) intOne
	timeStep: (double) aDouble;
/**
Designated initialiser.
\param aSystemCollection An AdSystemCollection instance containing the AdSystem objects that will
be simulated.
\param aForceFieldCollection An AdForceFieldCollection object used to update the forces acting on the
AdSystem instance in \e aSystemCollection. 
\param anArray An array of objects conforming to AdSimulatorComponent.
\param intOne The number of iterations that will be performed when production() is called.
\param aDouble Double specfying the time step used in the integration
\param intTwo The object checks for floating point errors at this interval during production.
*/
- (id) initWithSystems: (AdSystemCollection*)  aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	components: (NSArray*) anArray
	numberOfSteps: (unsigned int) intOne
	timeStep: (double) aDouble
	checkFPErrorInterval: (unsigned int) intTwo;
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
Returns the time step used for the integration in femtoseconds
*/
- (double) timeStep;
/**
Sets the time step to be used for the integration. Value must
be in femtoseconds.
*/
- (void) setTimeStep: (double) stepSize;
/**
Adds \e anObject as a component of the receiver. \e anObject must
conform to the AdSimulatorComponent protocol. If not an 
NSInvalidArgumentException is raised.
*/
- (void) addComponent: (id) anObject;
/**
Removes previously added component \e anObject from the reciever. 
Does nothing if \e anObject was never added to the receiver.
*/
- (void) removeComponent: (id) anObject;
/**
Returns all the receivers components. The order of the objects
in the returned array is the same as the order they were added.
*/
- (NSArray*) allComponents;
@end

/**
Protocol for objects that wish to act as a AdSimulator components. 
The methods are called in a strict order. Firstly the following methods
are called for each system.

- simulatorWillPerformFirstVelocityUpdateForSystem:()
- simulatorWillPerformPositionUpdateForSystem:()
- simulatorDidPerformPositionUpdateForSystem:()

The simulator then calculates the new values for the forces acting on the
systems before calling the following methods for each.

- simulatorWillPerformSecondVelocityUpdateForSystem:()
- simulatorDidPerformSecondVelocityUpdateForSystem:()

\note
Components do not have to perform actions at all steps. 

\note
To avoid circular references objects conforming to AdSimulatorComponent
should not maintain strong references to AdSimulator objects they are components of.
\ingroup Protocols
*/
@protocol AdSimulatorComponent
/**
Sent before the production loop begins. Components can acquire information
on neccessary simulation parameters here e.g. the time step etc. 
*/
- (void) simulator: (AdSimulator*) aSimulator 
		willBeginProductionWithSystems: (AdSystemCollection*) aSystemCollection 
		forceFields: (AdForceFieldCollection*) aForceFieldCollection;
/**
Sent before the simulator peforms the first velocity update.
*/
- (void) simulatorWillPerformFirstVelocityUpdateForSystem: (AdSystem*) aSystem;
/**
Sent before the simulator performs the position update and directly after
it performs the first velocity update.
*/
- (void) simulatorWillPerformPositionUpdateForSystem: (AdSystem*) aSystem;
/**
Sent directly after the simulator performs the position update i.e. before the new forces
are calculated.
*/
- (void) simulatorDidPerformPositionUpdateForSystem: (AdSystem*) aSystem;
/**
Sent before the simulator performs the second velocity update. This message
is sent after all system forces have been updated.
*/
- (void) simulatorWillPerformSecondVelocityUpdateForSystem: (AdSystem*) aSystem;
/**
Sent directly after the simulator performs the second velocity update.
*/
- (void) simulatorDidPerformSecondVelocityUpdateForSystem: (AdSystem*) aSystem;
/**
Sent when the production loop ends - Either normally or as the result of AdSimulator::endProduction()
being sent to the AdSimulator object.
*/
- (void) simulatorDidFinishProduction: (AdSimulator*) aSimulator;
@end
#endif
