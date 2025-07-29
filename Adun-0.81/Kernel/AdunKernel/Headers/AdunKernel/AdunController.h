/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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

#ifndef _ADUN_CONTROLLER_
#define _ADUN_CONTROLLER_

#include <AdunKernel/AdunKernel.h>
#include "AdunKernel/AdCoreAdditions.h"
#include "AdunKernel/AdController.h"

/**
\ingroup coreConstants
The error domain for the Controllers. 
See AdControllerErrorCodes for the error codes that can come from this domain. 
\note An error with this domain is associated with loading or using a controller
 */
#define AdControllerErrorDomain @"AdController.ErrorDomain"

/**
 \ingroup coreDataTypes
 Defines the error codes for the AdController.ErrorDomain.
*/
typedef enum 
{
	AdControllerDoesNotExistError, /**< The controller bundle is not present in the Controllers/ directory */
	AdControllerPrincipalClassMissingError, /**< The controller does not have a principal class (the controller class) */
	AdControllerPrincipalClassNameError, /**< The controllers principal class does not have the same name as the controller (which is a requirement)*/
	AdControllerPrincipalClassDoesNotConfromToProtocolError /**< The controllers principal class does not conform to the AdController protocol*/
}
AdControllerErrorCodes;

/**
\ingroup coreClasses
AdController is a simple implementation of a controller and hence
the AdController & AdThreadedController protocols. It is intended to be a base class for 
other controllers providing necessary threading functionality and proper integration
into the core exit procedures.
As a controller it simply calls AdConfigurationGenerator::production:()
to start the configuration generation process.

\section subclass Subclassing

AdController provides threading, exit handling & error handling code to its subclasses.
Subclasses should only override AdController::coreWillStartSimulation:(), 
AdController::cleanUp() & runSimulation(). 
In the first case they should call the superclass implementation to set up the \e core 
and \e configurationGenerator instance variables. 

Do \e not override runController(). This method contains error handling code that wraps
runSimulation() so subclasses do not have to implement it. Instead subclasses should 
override runSimulation() replacing AdControllers implementation with their main loop.

\note 
In some cases it may be necessary to provide a custom thread creation/termination
solution. In this case it is recommended that you implement a complete
new class based on the controller protocols.
*/
@interface AdController: NSObject <AdController>
{
	BOOL notifyCore;
	int maxAttempts;	//!< The number of times to try to restart a failed production run
	NSConnection* threadConnection; //!< For communicating between the threads
	NSError* controllerError;	//!< For reporting errors in the simulation
	AdConfigurationGenerator* configurationGenerator;	//!< The configuration generator
	id core;		//!< The programs AdCore instance.
	//Initial restart related ivars - Will probably change
	BOOL restartMode;	//!< Indicates if this is a restart
	unsigned int restartStep;	//!< The step to restart the configuration generator from.
}
/**
Class method which returns the principal class for the controller called \e controllerName.
If \e error is not NULL, it contains an NSError object if there was an error loading the controller.
See AdLoadController() for information on the possible errors.
*/ 
+ (Class) principalClassForController: (NSString*) controllerName error: (NSError**) error;
/**
A wrapper around the configuration generators AdConfigurationGenerator::production: method
adding handling of expoloding simulations. If the configuration generator exits with an
error whose code is AdKernelSimulationSpaceError then a restart attempt is made. 
This involves rolling back the simulation to an earlier state, minimising and restarting.
If this attempt fails then the method exits as normal.
*/
- (BOOL) production: (NSError**) error;
/**
Subclasses should override this method, not runController(), replacing it with their main loop. 
*/
- (void) runSimulation;
/**
Temporary method - Testing controller restarting.
Subclasses should override this method and set an error.
A better mechanisim for use with all controllers will be implemented at a later date.
*/
- (void) restartController: (unsigned int) step;
@end


@interface AdController (AdControllerThreadingExtensions) <AdThreadedController>
@end

/**
 Returns an NSBundle instance representing the controller called \e name.
 If there are any problems with the controller \e error is set with an error from AdController.ErrorDomain. 
 AdControllerPrincipalClassNameError is not fatal and the bundle is still returned.
 All other errors caused this function to return nil.
 See the AdControllerErrorCodes doc for information on the possible errors.
*/
NSBundle* AdLoadController(NSString* controllerName, NSError** error);

#endif
