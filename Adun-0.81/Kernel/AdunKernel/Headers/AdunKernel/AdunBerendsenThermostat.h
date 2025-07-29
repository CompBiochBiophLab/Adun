#ifndef _ADBERENDSENTHERMOSTAT_
#define _ADBERENDSENTHERMOSTAT_
#include "AdunKernel/AdunSimulator.h"

/**
\ingroup Inter
AdBerendenThermostat objects are simulator components that control the simulation temperature 
by scaling the velocities of the systems being integrated.

The thermostat is set with a target temperature at which it keeps the simulation.
In addition in can be set with an initial temperature from which it gradually warms the system.
The warming is done by increasing the temperature at intervals designated on initialisation.
The number of steps during the warming process is also set on initialisation.

The scaling is applied on receipt of simulatorDidPerformSecondVelocityUpdateForSystem:().
*/
@interface AdBerendsenThermostat: NSObject <AdSimulatorComponent>
{
	BOOL removeDOF; //!< Indicates if the translation DOF should be periodically be removed
	BOOL warm;	//< Indicates if we are warming the system gradually to the target temperature
	int removeDOFInterval; //!< The interval at which the removal should be done.
	unsigned int warmingSteps;
	unsigned int warmingStepDuration;
	double targetTemperature;
	double initialTemperature;
	double currentTemperature;
	double warmingIncrement;
	double timeStep;
	double couplingFactor;
	double timePerCouplingFactor;
	AdSystemCollection* systemCollection;
}
/**
As initWithTargetTemperature:couplingFactor: with
a target temperature of 300 and a coupling factor of 100
*/
- (id) init;
/**
As initWithTargetTemperature:couplingFactor:removeDOFInterval: with
interval set to 1000.
*/
- (id) initWithTargetTemperature: (double) doubleOne
	couplingFactor: (double) doubleTwo;
/**
 \param doubleOne The target temperature for the thermostat.
 \param doubleTwo The coupling factor for the thermostat.
 \param interval Interval at which to remove translation DOF from the systems being simulated.
	If this is less than zero no removal is done.
 */	
- (id) initWithTargetTemperature: (double) doubleOne
		  couplingFactor: (double) doubleTwo
		  removeDOFInterval: (int) interval;
/**
 Designated initialiser.
 \param target The target temperature for the thermostat.
 \param initial The temperature at which to start thermostating
 \param numberOfSteps The number of steps to make between the initial and target temperature
 \param duration The time to spend at each temperature step
 \param doubleTwo The coupling factor for the thermostat.
 \param interval Interval at which to remove translation DOF from the systems being simulated.
 If this is less than zero no removal is done.

*/		  
- (id) initWithTargetTemperature: (double) target
	      initialTemperature: (double) initial
		    numberOfSteps: (unsigned int) steps
		    stepDuration: (unsigned int) duration 
		  couplingFactor: (double) doubleTwo
	       removeDOFInterval: (int) interval;		  
/**
Sets the target temperature for the thermostat to \e aDouble.
If \e aDouble is less than 0 an NSInvalidArgumentException is raised.
*/
- (void) setTargetTemperature: (double) aDouble;
/**
Returns the target temperature
*/
- (double) targetTemperature;
/**
Sets the intial temperature for the thermostat to \e aDouble.
If \e aDouble is less than 0 an NSInvalidArgumentException is raised.
By default the initial temperature is equal to the target Temperature.
*/
- (void) setInitialTemperature: (double) aDouble;
/**
 Returns the initial temperature
 */
- (double) initialTemperature;

/**
Sets the coupling factor. The same coupling factor
is used for all systems.
*/
- (void) setCouplingFactor: (double) aDouble;
/**
Returns the coupling factor.
*/
- (double) couplingFactor;
@end

#endif
