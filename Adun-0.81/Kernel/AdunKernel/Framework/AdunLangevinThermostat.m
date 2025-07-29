/*
   Project: AdunKernel

   Copyright (C) 2005-2007 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunLangevinThermostat.h"

@implementation AdLangevinThermostat

/*
Fills the rows of \e matrix with random acceleration vectors whose mean magnitude is 0 and variance
is (6*Kb*T*gamma)/(mass*timeStep). The mass used for each row is given by the array \e masses.
\e masses must have the same number of elements as rows in \e matrix.

A note - many descriptions take a component view.
The say the mean of a vector component is 0 and their is 2*m*gamma*kb*T 
(see tamar schlick book and Advanced Polymer Science, 2005, 173, 105)
i.e.
< F_{x}.F_{x}> = 2*m*gamma*kb*T
This is variance because the mean is 0. 

Sometimes this is mistakenly denoted as the <F(t).F(t)>.
This is actually the average value of the dot product of the force vectors ..
which is the average of their squared length  ...
which is the variance of their magnitude if their mean is zero.
Var(|F|) = < (|F| - |F|_{av})(|F| - |F|_{av}) > = < |F|^2 > (mean 0) = < F.F>

From the above we can write <F.F> as < F_{x}^{2} + F_{y}^{2} + F_{z}^{2}>
the mean of a sum is the same as the sum of the means.
<F.F> = <F_{x}^{2}> + <F_{y}^2> + <F_{z}^{2}> = 6*m*gamma*kb*T.

So if the components variance is 2*m*gamma*kb*T then the vectors variance is  6*m*gamma*kb*T.
For me its more natural to think of force in terms of a vector (since it is a vector)
so I adopt the vector method here.
You can find more at http://cmm.info.nih.gov/intro_simulation/node24.html for example.

*/
- (void) _generateRandomAccelerations: (AdMatrix*) matrix usingMasses: (double*) masses
{
	register int i, j;
	double sigma, holder, randomMagnitude;
	Vector3D vector;
	
	for (i=0; i < matrix->no_rows; i++)
	{
		holder = (variance*gamma)/(masses[i]*timeStep);
		sigma = sqrt(holder);
		randomMagnitude = gsl_ran_gaussian(twister, sigma);
		AdGetRandom3DUnitVector(&vector, twister);
	
		for(j=0; j < 3; j++)
			matrix->matrix[i][j] = randomMagnitude*vector.vector[j];
	}
}

- (void) _createSystemForceMatricesAndMassArrays
{
	int i;
	double* masses;
	NSEnumerator* systemEnum;
	id system;
	NSArray* massArray;
	AdMatrix* matrix;
	AdMemoryManager *memoryManager;

	memoryManager = [AdMemoryManager appMemoryManager];
	matrixDict = [NSMutableDictionary new];
	massesDict = [NSMutableDictionary new];
	systemEnum = [[systemCollection fullSystems] 
			objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		NSDebugLLog(@"AdLangevinThermostat",
			@"Generating initial random accelerations for %@", [system systemName]);
		matrix = [memoryManager allocateMatrixWithRows: [system numberOfElements]
				withColumns: 3];
		massArray = [system elementMasses];
		
		masses = [memoryManager allocateArrayOfSize: [massArray count]*sizeof(double)];
		for(i=0; i<(int)[massArray count]; i++)
			masses[i] = [[massArray objectAtIndex: i] doubleValue];
			
		[self _generateRandomAccelerations: matrix usingMasses: masses];
		[massesDict setObject: [NSValue valueWithPointer: masses] 
			forKey: [NSValue valueWithPointer: system]];	
		[matrixDict setObject: [NSValue valueWithPointer: matrix]
			forKey: [NSValue valueWithPointer: system]];
		NSDebugLLog(@"AdLangevinThermostat",
			@"Complete");
	}
}

- (void) _destroySystemForceMatricesAndMassArrays
{
	NSEnumerator* matrixEnum, *massesEnum;
	NSValue* valueObject;
	AdMemoryManager *memoryManager;

	memoryManager = [AdMemoryManager appMemoryManager];
	matrixEnum = [matrixDict objectEnumerator];
	while(valueObject = [matrixEnum nextObject])
		[memoryManager freeMatrix: (AdMatrix*)[valueObject pointerValue]];

	massesEnum = [massesDict objectEnumerator];
	while((valueObject = [massesEnum nextObject]))
		[memoryManager freeArray: (void*)[valueObject pointerValue]];

	[matrixDict release];
	matrixDict = nil;
	massesDict = nil;
}

//Sent to AdLangevinThermostat instance by the main loop timer instance
//every removeDOFInterval steps if removeDOF is YES.
- (void) _removeTranslationalDOF
{
	NSEnumerator* systemEnum;
	AdSystem* system;
	
	NSDebugLLog(@"AdLangevinThermostat", @"Removing translational DOF for all systems");
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while(system = [systemEnum nextObject])
	{
		NSDebugLLog(@"AdLangevinThermostat", @"System %@", [system systemName]);
		[system removeTranslationalDegreesOfFreedom];
	}
	
	NSDebugLLog(@"AdLangevinThermostat", @"Done");
}

- (id) init
{
	return [self initWithTargetTemperature: 300.0];
}

- (id) initWithTargetTemperature: (double) doubleOne
{
	return [self initWithTargetTemperature: doubleOne
			gamma: 0.05];
}

- (id) initWithTargetTemperature: (double) doubleOne
	gamma: (double) doubleTwo
{
	return [self initWithTargetTemperature: doubleOne
		gamma: doubleTwo
		seed: 332];
}

- (id) initWithTargetTemperature: (double) doubleOne 
	gamma: (double) doubleTwo
	seed: (int) anInt
{
	return [self initWithTargetTemperature: doubleOne
		gamma: doubleTwo 
		seed: anInt 
		removeDOFInterval: 1000];
}

- (id) initWithTargetTemperature: (double) doubleOne 
			   gamma: (double) doubleTwo
			    seed: (int) anInt
		removeDOFInterval: (int) interval
{
	if((self = [super init]))
	{
		[self setTargetTemperature: doubleOne];
		[self setGamma: doubleTwo];
		twister = gsl_rng_alloc(gsl_rng_mt19937);
		gsl_rng_set(twister,anInt);
		matrixDict = nil;
		massesDict = nil;
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
	//In case simulatorDidFinishProduction: was not called
	[self _destroySystemForceMatricesAndMassArrays];
	if(twister != NULL)
		gsl_rng_free(twister);
		
	//Should be removed when the simulator send simulatorDidFinishProduction
	//But just in case
	if(removeDOF)	
		[[AdMainLoopTimer mainLoopTimer]
			removeMessageWithName: @"langevinResetDOFMessage"];
		
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];
	
	[description appendFormat: @"%@. Target temperature %5.2lf. Gamma %5.2lf", 
		NSStringFromClass([self class]), targetTemperature, gamma];
	
	return description;	
}

- (void) simulator: (AdSimulator*) aSimulator 
		willBeginProductionWithSystems: (AdSystemCollection*) aSystemCollection 
		forceFields: (AdForceFieldCollection*) aForceFieldCollection
{
	systemCollection = aSystemCollection;
	timeStep = [aSimulator timeStep];
	[self _createSystemForceMatricesAndMassArrays];
	
	//If asked to reset the translational DOF set up a timer message
	if(removeDOF)
	{
		NSDebugLLog(@"AdLangevinThermostat", 
			@"Removing translational degrees of freedom every %d steps", removeDOFInterval);
		[[AdMainLoopTimer mainLoopTimer]
			sendMessage: @selector(_removeTranslationalDOF)
			toObject: self 
			interval: removeDOFInterval 
			name: @"langevinResetDOFMessage"];
	}
}

- (void) simulatorDidFinishProduction: (AdSimulator*) aSimulator
{
	[self _destroySystemForceMatricesAndMassArrays];
	systemCollection = nil;
	
	if(removeDOF)	
		[[AdMainLoopTimer mainLoopTimer]
			removeMessageWithName: @"langevinResetDOFMessage"];
}

- (void) simulatorWillPerformFirstVelocityUpdateForSystem: (AdSystem*) aSystem
{
	int i, j;
	double halfTimeStep;
	AdMatrix* velocities, *randomAccelerations;

	halfTimeStep = timeStep/2;
	velocities = [aSystem velocities];
	randomAccelerations = [[matrixDict objectForKey: [NSValue valueWithPointer: aSystem]]
				pointerValue];

	if(randomAccelerations == NULL)
	{
		NSWarnLog(@"AdLangevinThermostat - Passed system not in provided collection");
		return;
	}	
		
	[aSystem object: self willBeginWritingToMatrix: velocities];

	for(i=0; i<velocities->no_rows; i++)
		for(j=0; j<velocities->no_columns; j++)
			velocities->matrix[i][j] += halfTimeStep*(randomAccelerations->matrix[i][j]
							- gamma*velocities->matrix[i][j]);

	[aSystem object: self didFinishWritingToMatrix: velocities];
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

- (void) simulatorDidPerformSecondVelocityUpdateForSystem: (AdSystem*) aSystem
{
	int i, j;
	double factor;
	double *masses;
	AdMatrix* velocities, *randomAccelerations;

	factor = 1/(2 + gamma*timeStep);
	
	//Generate a new random acceleration matrix for this system
	randomAccelerations = [[matrixDict objectForKey: [NSValue valueWithPointer: aSystem]]
				pointerValue];
	if(randomAccelerations == NULL)
	{
		NSWarnLog(@"AdLangevinThermostat - Passed system not in provided collection");
		return;
	}	

	masses = [[massesDict objectForKey: [NSValue valueWithPointer: aSystem]]
			pointerValue];

	//Update the random acceleration matrix
	[self _generateRandomAccelerations: randomAccelerations 
		usingMasses: masses];

	velocities = [aSystem velocities];
	[aSystem object: self willBeginWritingToMatrix: velocities];
	
	for(i=0; i<velocities->no_rows; i++)
		for(j=0; j<velocities->no_columns; j++)
			velocities->matrix[i][j] = factor*(2*velocities->matrix[i][j] + randomAccelerations->matrix[i][j]*timeStep);

	[aSystem object: self didFinishWritingToMatrix: velocities];
}

- (void) setGamma: (double) value
{
	gamma = value;
}

- (double) gamma
{
	return gamma;
}

- (void) setTargetTemperature: (double) aValue
{
	if(aValue < 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Target temperature must be greater than 0"];
			
	targetTemperature = aValue;
	variance = 6*KB*targetTemperature;
}

- (double) targetTemperature
{
	return targetTemperature;
}

- (void) setSeed: (int) anInt
{
	gsl_rng_set(twister,anInt);
}

@end
