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
#ifndef _ADCONFIGURATION_GENERATOR_
#define _ADCONFIGURATION_GENERATOR_

#include <stdio.h>
#include "AdunKernel/AdunTimer.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunSystemCollection.h"
#include "AdunKernel/AdunForceFieldCollection.h"

/**
\ingroup Inter

AdConfigurationGenerator is an abstract class representing objects that update the configuration of AdSystem objects.
Every simulation application should have one AdConfigurationGenerator subclass which performs the simulation.
The different concrete subclasses of AdConfigurationGenerator correspond to different methods for generating
new configurations (aka frames, snapshots etc.) of system elements e.g. dynamics, monte carlo, minimisation etc.

The production() method wraps each subclasses configuration generation loop. The number of times this loop is
executed is set on initialising the object or through the setNumberOfSteps:() method. On each pass through the
the applications AdMainLoopTimer instance is always incremented regardless of the configuration generation method.

If production() is run in a separate thread the endProduction() method provides a way
to end the simulation loop from the main thread before the set 
number of iterations have been completed.

<b> Numerical Stability </b>

AdConfigurationGenerator subclass instances monitor the numerical stability of 
the production process by checking for IEEE floating point errors. These are

- Invalid Operation
- Division by Zero
- Overflow 
- Underflow
- Inexact

The first three cause an AdFloatingPointException to be raised with information
on which error was detected. The production loop will exit and an NSError object
created whose error code is AdKernelFloatingPointError.

The last error is common since all irrational and transcendental
numbers are inexact and we may be adding many numbers who differ by more than 
DBL_EPSILON. Hence on detection of this error nothing is done.

Underflow errors lead to a slow loss of precision. However it is possible
that tiny forces and energies will be calculated in the course of a simulation.
When this error is detected the object logs it and continues normally. 
*/
@interface AdConfigurationGenerator: NSObject 
{
}
/**
Performs a number of configuration generation steps on the active systems.
*/
- (BOOL) production: (NSError**) error;
/**
Restarts a production loop from step  \e start.
Returns NO if the loop fails to complete for any reason. In this
case \e error will point to an NSError contain information on the reason
for the failure.
*/
- (BOOL) restartFrom: (int) step error: (NSError**) error;
/**
Ends the running production loop.
*/
- (void) endProduction;
/*
Checks for floating point errors by examining the floating point status word
for raised exceptions.  On detecting FE_INVALID, FE_OVERFLOW or FE_DIVBYZERO
this method raises an exception. Otherwise it does nothing.
*/
- (void) checkFloatingPointErrors;
/**
Returns the number of steps performed when production() is called
*/
- (unsigned int) numberOfSteps;
/**
Sets the number of intergraion steps performed when production() is called.
*/
- (void) setNumberOfSteps: (unsigned int) aNumber;
/**
Returns the current production step.
*/
- (unsigned int) currentStep;
/**
Returns the system collection the generator is currently working on
*/
- (AdSystemCollection*) systems;
/**
Returns the force field collection the generator is currently using
*/
- (AdForceFieldCollection*) forceFields;
@end
#endif
