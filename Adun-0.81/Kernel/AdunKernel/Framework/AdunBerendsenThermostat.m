#include "AdunKernel/AdunBerendsenThermostat.h"

@implementation AdBerendsenThermostat

//Sent to AdBerendsenThermostat instance by the main loop timer instance
//every removeDOFInterval steps if removeDOF is YES.
- (void) _removeTranslationalDOF
{
	NSEnumerator* systemEnum;
	AdSystem* system;
	
	NSDebugLLog(@"AdBerendsenThermostat", @"Removing translational DOF for all systems");
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while(system = [systemEnum nextObject])
	{
		NSDebugLLog(@"AdBerendsenThermostat", @"System %@", [system systemName]);
		[system removeTranslationalDegreesOfFreedom];
	}
	
	NSDebugLLog(@"AdBerendsenThermostat", @"Done");
}

- (void) _updateTemperature
{
	currentTemperature += warmingIncrement;
	NSLog(@"Updating temperature from %lf to %lf",
		currentTemperature - warmingIncrement, currentTemperature);
	NSLog(@"%@", [self description]);
	//If we've reached the target temperature stop warming
	if(abs(currentTemperature - targetTemperature) < 1)
	{
		NSLog(@"Target temperature reached");
		[[AdMainLoopTimer mainLoopTimer]
		 removeMessageWithName: @"berendsenThermostatWarmingMessage"];
	}	
}

- (id) init
{
	return [self initWithTargetTemperature: 300.0
		couplingFactor: 100.0];
}

- (id) initWithTargetTemperature: (double) doubleOne
	couplingFactor: (double) doubleTwo
{
	return [self initWithTargetTemperature: doubleOne 
			couplingFactor: doubleTwo 
			removeDOFInterval: 1000];
}

- (id) initWithTargetTemperature: (double) target
		  couplingFactor: (double) doubleTwo
	       removeDOFInterval: (int) interval
{	       
	
	return [self initWithTargetTemperature: target 
		initialTemperature: target
		numberOfSteps: 0 
		stepDuration: 0 
		couplingFactor: doubleTwo
		removeDOFInterval: interval];
}

- (id) initWithTargetTemperature: (double) target
		initialTemperature: (double) initial
		numberOfSteps: (unsigned int) numberOfSteps
		stepDuration: (unsigned int) duration 
		couplingFactor: (double) doubleTwo
		removeDOFInterval: (int) interval
{
	if((self = [super init]))
	{
		[self setTargetTemperature: target];
		[self setInitialTemperature: initial];
		warmingSteps = numberOfSteps;
		warmingStepDuration = duration;
		
		couplingFactor = doubleTwo;
		timeStep = 1;
		timePerCouplingFactor = (double)timeStep/couplingFactor;
		systemCollection = nil;
		removeDOFInterval = interval;
		removeDOF = NO;
		
		if(removeDOFInterval >= 0)
			removeDOF = YES;		
	}
	
	return self;
}

- (void) dealloc
{
	//Just in case simulatorDidFinishProduction() wasn't called.
	if(removeDOF)	
	{
		[[AdMainLoopTimer mainLoopTimer]
		 removeMessageWithName: @"berendsenResetDOFMessage"];	
	}

	if(warm)
	{	
		[[AdMainLoopTimer mainLoopTimer]
		 removeMessageWithName: @"berendsenThermostatWarmingMessage"];
	}
	
	[super dealloc];				
}

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];
	
	if(!warm)
	{
		[description appendFormat: @"%@. Target temperature %5.2lf. Coupling factor %5.2lf", 
		 NSStringFromClass([self class]), targetTemperature, couplingFactor];
	}
	else
	{
		[description appendFormat: @"%@. InitialTemperature %5.2lf. CurrentTemperature %5.2lf. Target temperature %5.2lf.\n" 
			"\tWarming steps %d. Warming step duration %d sim steps. Coupling factor %5.2lf", 
		 NSStringFromClass([self class]), initialTemperature, currentTemperature, targetTemperature, 
			warmingSteps, warmingStepDuration, couplingFactor];
	}

	
	return description;	
}

- (void) simulator: (AdSimulator*) aSimulator 
		willBeginProductionWithSystems: (AdSystemCollection*) aSystemCollection 
		forceFields: (AdForceFieldCollection*) aForceFieldCollection
{
	double difference;

	timeStep = [aSimulator timeStep];
	timePerCouplingFactor = (double)timeStep/couplingFactor;
	systemCollection = aSystemCollection;
	
	//If asked to reset the translational DOF set up a timer message
	if(removeDOF)
	{
		NSDebugLLog(@"AdBerendsenThermostat", 
			    @"Removing translational degrees of freedom every %d steps", removeDOFInterval);
		[[AdMainLoopTimer mainLoopTimer]
		 sendMessage: @selector(_removeTranslationalDOF)
		 toObject: self 
		 interval: removeDOFInterval 
		 name: @"berendsenResetDOFMessage"];
	}

	//If asked to warm the system set up a timer message
	if(warm)
	{
		NSLog(@"Warming requested. Difference %-5.2lf. Warming increment %5.2lf", warmingIncrement); 
		[[AdMainLoopTimer mainLoopTimer]
		 sendMessage: @selector(_updateTemperature) 
		 toObject: self 
		 interval: warmingStepDuration 
		 name: @"berendsenThermostatWarmingMessage"];
	}
}

- (void) simulatorDidPerformSecondVelocityUpdateForSystem: (AdSystem*) system
{
	int j,k;
	double temperature, factor;
	AdMatrix* velocities;

	temperature = [system temperature];

	if(temperature == 0)
	{
		factor = 0;
	}	
	else
	{
		factor = 1 - timePerCouplingFactor*(1 - (currentTemperature/temperature));
		factor = sqrt(factor);
	}	
	
	velocities = [system velocities];

	[system object: self willBeginWritingToMatrix: velocities]; 

	for(j=0; j < velocities->no_rows; j++)
		for(k=0; k<3; k++)
			velocities->matrix[j][k] *= factor;
	
	[system object: self didFinishWritingToMatrix: velocities]; 
}

- (void) setTargetTemperature: (double) aDouble
{
	if(aDouble < 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Target temperature cannot be less than 0"];

	targetTemperature = aDouble;
}

- (double) targetTemperature
{
	return targetTemperature;
}

- (void) setInitialTemperature: (double) aDouble
{
	double difference;

	if(aDouble < 0)
		[NSException raise: NSInvalidArgumentException
			    format: @"Initial temperature cannot be less than 0"];
	
	initialTemperature = aDouble;
	currentTemperature = initialTemperature;
	
	difference = targetTemperature - initialTemperature;
	
	if(warmingSteps != 0)
		warmingIncrement = difference/warmingSteps;
	
	warm = NO;
	if(fabs(initialTemperature - targetTemperature) > 1)
	{
		warm = YES;
	}
}

- (double) initialTemperature
{
	return initialTemperature;
}

- (void) setNumberOfSteps: (unsigned int) numberOfSteps
{
	double difference;

	warmingSteps = numberOfSteps;
	
	//Update warmingIncrement
	difference = targetTemperature - initialTemperature;
	if(warmingSteps != 0)
		warmingIncrement = difference/(double)warmingSteps;
}

- (unsigned int) numberOfSteps
{
	return warmingSteps;
}

- (void) setStepDuration: (unsigned int) duration
{
	warmingStepDuration = duration;
}

- (unsigned int) stepDuration
{
	return warmingStepDuration;
}

- (void) setCouplingFactor: (double) aDouble
{
	couplingFactor = aDouble;
	timePerCouplingFactor = (double)timeStep/couplingFactor;
	
	NSLog(@"Coupling factor is %lf", aDouble);
}

- (double) couplingFactor
{
	return couplingFactor;
}
	
- (void) simulatorWillPerformFirstVelocityUpdateForSystem: (AdSystem*) aSystem
{
	//Does nothing here
}

- (void) simulatorWillPerformPositionUpdateForSystem: (AdSystem*) aSystem
{
	//Does nothing here
}

- (void) simulatorDidPerformPositionUpdateForSystem: (AdSystem*) aSystem
{
	//Does nothing here
}

- (void) simulatorWillPerformSecondVelocityUpdateForSystem: (AdSystem*) aSystem
{
	//Does nothing here
}

- (void) simulatorDidFinishProduction: (AdSimulator*) aSimulator
{
	systemCollection = nil;
	
	if(removeDOF)	
		[[AdMainLoopTimer mainLoopTimer]
			removeMessageWithName: @"berendsenResetDOFMessage"];
	
	//The simulator may be finished before we've fully warmed the system				
	if(warm)
	{	
		[[AdMainLoopTimer mainLoopTimer]
			 removeMessageWithName: @"berendsenThermostatWarmingMessage"];
	}		 
}

@end

