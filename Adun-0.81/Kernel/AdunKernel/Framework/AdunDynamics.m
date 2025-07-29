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

#include "AdunKernel/AdunDynamics.h"
#include "AdunKernel/AdDataSources.h"
#include "AdunKernel/AdFrameworkFunctions.h"

@implementation AdDynamics

/*
 * Accessing Data Source & Matrix Creation
 */

- (void) _initialiseVelocities
{
	int i, j;
	double var, hold;
	
	NSDebugLLog(@"AdDynamics", @"Randomly initialising velocities.");

	/*
   	 * Draw velocities from a Maxwell Distribution at the given temperature
	 * Maxwell Distribution is a gaussian with variance = sqrt(KB*T/mass)
	 * Catch when the temperature is set to zero
  	 * Not sure what the temperature limit should be..
	 * FIXME: We're assuming units here by using KB.
	 */

	if(targetTemperature > 0.001)
	{
		var = targetTemperature*KB;
		for(i=0; i<numberOfElements; i++)
		{
			hold = sqrt(var/masses[i]);		
			for(j=0; j<3; j++)
				velocities->matrix[i][j] = gsl_ran_gaussian(twister, hold);
		}
	}
	else
		for(i=0; i<numberOfElements; i++)
			for(j=0; j<3; j++)
				velocities->matrix[i][j] = 0;
}

- (void) _retrieveMasses
{
	int i;

	elementMasses = [[[dataSource elementProperties] 
				columnWithHeader: @"Mass"] copy];
	masses = [memoryManager allocateArrayOfSize: 	
			[elementMasses count]*sizeof(double)];

	for(i=0; i<(int)[elementMasses count]; i++)  	
		 masses[i] = [[elementMasses objectAtIndex: i] 	 
					 doubleValue]; 	 
}

- (void) _retrieveCoordinates
{
	NSDebugLLog(@"AdDynamics", @"Accesing data source for coordinates");
	coordinates = [[dataSource elementConfiguration]
			cRepresentation];
	numberOfElements = coordinates->no_rows;
	NSDebugLLog(@"AdDynamics", @"Number of coordinates = %d\n", numberOfElements);
	coordinatesLock = [NSLock new];
}

- (void) _retrieveAtomTypes
{
	NSDebugLLog(@"AdDynamics", @"Accesing data source for elementTypes");
	elementTypes = [[[dataSource elementProperties] 
			columnWithHeader: @"ForceFieldName"] copy];
}

/*
 * Initialisation
 */

- (id) initWithDataSource: (id) anObject
	targetTemperature: (double) initialTemperature
	seed: (int) rngSeed
	removeTranslationalDOF: (BOOL) value
{
	if((self = [super init]))
	{
		if(anObject ==  nil)
			[NSException raise: NSInvalidArgumentException
				format: @"Data source cannot be nil"];

		dataSource = anObject;
		if(initialTemperature < 0.0)
		{
			NSWarnLog(@"Target temperature cannot be negative.");
			NSWarnLog(@"Defaulting to 300");
			targetTemperature = 300;
		}
		else
			targetTemperature = initialTemperature;

		seed = rngSeed;
		velocitiesLock = coordinatesLock = nil;
	
		twister = gsl_rng_alloc(gsl_rng_mt19937);
		gsl_rng_set(twister, seed);

		memoryManager = [AdMemoryManager appMemoryManager];
		masses = NULL;

		[self _retrieveCoordinates];
		[self _retrieveAtomTypes];
		[self _retrieveMasses];

		velocities = [memoryManager allocateMatrixWithRows: numberOfElements 
				withColumns: 3];	
		velocitiesLock = [NSLock new];
		[self _initialiseVelocities];

		[self calculateCentreOfMass];

		degreesOfFreedom = 3*numberOfElements;
		if(value)
			[self removeTranslationalDOF];

		[self calculateCentreOfMass];
		kineticEnergyToTemperature =  (2*KB_1)/(degreesOfFreedom);
		kineticEnergy = AdCalculateKineticEnergy(velocities, masses);
		temperature = kineticEnergyToTemperature*kineticEnergy;
	}

	return self;
}

- (id) initWithDataSource: (id) anObject
{
	return [self initWithDataSource: anObject
		targetTemperature: 300.0
		seed: 500
		removeTranslationalDOF: YES];
}

- (id) init
{
	return [self initWithDataSource: nil];
}

- (void) dealloc
{
	if(twister != NULL)
		gsl_rng_free(twister);
		
	[elementTypes release];
	[elementMasses release];
	[coordinatesLock release];
	[velocitiesLock release];
	[memoryManager freeMatrix: coordinates];
	[memoryManager freeMatrix: velocities];
	[memoryManager freeArray: masses];
	[super dealloc];
}

/*
 * Public Methods
 */

- (void) calculateCentreOfMass
{
	int i, j;
	
	for(i=0; i<3;i++)
		centreOfMass.vector[i] = 0;
	
	for(totalMass = 0, i=0; i<numberOfElements; i++)
	{
		totalMass += masses[i];
		for(j=0; j<3;j++)
			centreOfMass.vector[j] += coordinates->matrix[i][j]*masses[i];
	}

	for(i=0; i<3; i++)
		centreOfMass.vector[i] = centreOfMass.vector[i]/totalMass;

	Ad3DVectorLength(&centreOfMass);

	NSDebugLLog(@"AdDynamics", @"Mass %lf. Centre of Mass is: %-6.2lf%-6.2lf%-6.2lf", 
			totalMass, centreOfMass.vector[0], centreOfMass.vector[1], centreOfMass.vector[2]);
}

- (void) removeTranslationalDOF
{
	NSDebugLLog(@"AdunDynamics", 
		@"Removing translational DOF - Current temperature %-8.3lf", temperature);
	
	[velocitiesLock lock];
	AdRemoveTranslationalDOF(velocities, masses);
	[velocitiesLock unlock];
	
	//Update constants and DOF
	degreesOfFreedom = 3*numberOfElements - 3;;
	kineticEnergyToTemperature =  (2*KB_1)/(degreesOfFreedom);

	//Recalculate kinetic energy
	kineticEnergy = AdCalculateKineticEnergy(velocities, masses);
	temperature = kineticEnergyToTemperature*kineticEnergy;
	NSDebugLLog(@"AdDynamics", @"New temperature %lf", temperature);
}

- (void) moveCentreOfMassToOrigin
{	
	int i,j;

	NSDebugLLog(@"AdDynamics", @"Moving centreOfMass of mass to (0,0,0)");
	[self calculateCentreOfMass];

	for(i=0; i<numberOfElements; i++)
		for(j=0; j<3; j++)
			coordinates->matrix[i][j] -= centreOfMass.vector[j];

	[self calculateCentreOfMass];
}

- (void) centreOnPoint: (double*) point
{
	int i,j;

	NSDebugLLog(@"AdDynamics", @"Moving center of mass to point %-6.2lf%-6.2lf%-6.2lf", 
		point[0], 
		point[1], 
		point[2]);

	[self moveCentreOfMassToOrigin];

	for(i=0; i<numberOfElements; i++)
		for(j=0; j<3; j++)
			coordinates->matrix[i][j] += point[j];
	[self calculateCentreOfMass];
}

- (void) centreOnElement: (int) elementIndex
{
	int i,j;
	double position[3];

	NSDebugLLog(@"AdDynamics", @"Moving element %d (%-6.2lf%-6.2lf%-6.2lf) to origin", elementIndex,
		coordinates->matrix[elementIndex][0],
		coordinates->matrix[elementIndex][1], 
		coordinates->matrix[elementIndex][2]);
	
	position[0] = coordinates->matrix[elementIndex][0];
	position[1] = coordinates->matrix[elementIndex][1];
	position[2] = coordinates->matrix[elementIndex][2];

	for(i=0; i<numberOfElements; i++)
		for(j=0; j<3; j++)
			coordinates->matrix[i][j] -= position[j];
			
	[self calculateCentreOfMass];
}

- (void) reinitialiseVelocities
{
	//Aquire a lock before writing to matrix
	NSDebugLLog(@"AdDynamics", @"Reinitialising velocities");
	[velocitiesLock lock];
	[self _initialiseVelocities];
	kineticEnergy = AdCalculateKineticEnergy(velocities, masses);
	temperature = kineticEnergyToTemperature*kineticEnergy;
	NSDebugLLog(@"AdDynamics", @"New kinetic energy %lf", kineticEnergy);
	NSDebugLLog(@"AdDynamics", @"New temperature %lf", temperature);
	[velocitiesLock unlock];
}

/*
 * Accessors 
 */

- (unsigned int) numberOfElements
{
	return numberOfElements;
}

- (unsigned int) degreesOfFreedom
{
	return degreesOfFreedom;
}

- (NSArray*) elementTypes
{
	return [[elementTypes retain]
			autorelease];
}

- (NSArray*) elementMasses
{
	return [[elementMasses retain]
			autorelease];
}

- (double) kineticEnergy
{
	return kineticEnergy;
}

- (double) temperature
{
	return temperature;
}

- (AdMatrix*) coordinates
{
	return coordinates;
}

- (AdMatrix*) velocities
{
	return velocities;
}

- (void) setCoordinates: (AdMatrix*) matrix
{
	if(coordinates == NULL)
		return;

	[coordinatesLock lock];
	AdCopyAdMatrixToAdMatrix(matrix, coordinates);
	[coordinatesLock unlock];
}

- (void) setVelocities: (AdMatrix*) matrix
{
	if(velocities == NULL)
		return;

	[velocitiesLock lock];
	AdCopyAdMatrixToAdMatrix(matrix, velocities);
	kineticEnergy = AdCalculateKineticEnergy(velocities, masses);
	temperature = kineticEnergyToTemperature*kineticEnergy;
	[velocitiesLock unlock];
}

- (double) totalMass
{
	return totalMass;
}

- (Vector3D) centreOfMass
{
	//Centre may have moved
	[self calculateCentreOfMass];
	return centreOfMass;
}

- (double) targetTemperature
{
	return targetTemperature;
}

- (int) seed
{
	return seed;
}

- (void) setSeed: (int) aNumber
{
	seed = aNumber;
	gsl_rng_set(twister, seed);
}

- (void) setTargetTemperature: (double) aNumber
{
	if(targetTemperature < 0.0)
		[NSException raise: NSInvalidArgumentException
			format: @"Temperature cannot be negative"];
		
	targetTemperature = aNumber;
}

- (id) dataSource
{
	return dataSource;
}

//AdMatrixModification

- (BOOL) allowsDirectModificationOfMatrix: (AdMatrix*) matrix;
{
	if(matrix == coordinates || matrix == velocities)
		return YES;
	else
		return NO;
}

/**
We try the lock for the matrix. If we dont
acquire it we return NO. If we do aquire we
immediatly unlock it and return YES.
*/
- (BOOL) matrixIsAvailableForModification: (AdMatrix*) matrix;
{
	NSLock* lock;

	if(matrix == coordinates)
		lock = coordinatesLock;
	else if(matrix == velocities)
		lock = velocitiesLock;
	else
		return NO;
	
	if([lock tryLock])
	{
		[lock unlock];
		return YES;
	}
	else
		return NO;

}

- (void) object: (id) object willBeginWritingToMatrix: (AdMatrix*) matrix;
{
	if(matrix == coordinates)
	{
		[coordinatesLock lock];
	}
	else if(matrix == velocities)
	{
		[velocitiesLock lock];
	}

	return;
}

- (void) object: (id) object didFinishWritingToMatrix: (AdMatrix*) matrix;
{
	if(matrix == coordinates)
	{
		[coordinatesLock unlock];
	}
	else if(matrix == velocities)
	{
		//Update kinetic energy and temperature after the write to velocities
		kineticEnergy = AdCalculateKineticEnergy(velocities, masses);
		temperature = kineticEnergyToTemperature*kineticEnergy;
		[velocitiesLock unlock];
	}
}

//NSCoding Methods

- (id) initWithCoder: (NSCoder*) decoder
{	
	AdDataMatrix* matrix;

	if([decoder allowsKeyedCoding])
	{
		memoryManager = [AdMemoryManager appMemoryManager];
		seed = [decoder decodeIntForKey: @"Seed"];
		targetTemperature = [decoder decodeDoubleForKey: @"TargetTemperature"];
		degreesOfFreedom = [decoder decodeIntForKey: @"DegreesOfFreedom"];
		dataSource = [decoder decodeObjectForKey: @"DataSource"];
		kineticEnergyToTemperature =  (2*KB_1)/(degreesOfFreedom);

		matrix = [decoder decodeObjectForKey: @"Coordinates"];
		coordinates = [matrix cRepresentation];
		matrix = [decoder decodeObjectForKey: @"Velocities"];
		velocities = [matrix cRepresentation];

		numberOfElements = coordinates->no_rows;
		coordinatesLock = [NSLock new];
		velocitiesLock = [NSLock new];

		[self _retrieveAtomTypes];
		[self _retrieveMasses];
		[self calculateCentreOfMass];

		kineticEnergy = AdCalculateKineticEnergy(velocities, masses);
		temperature = kineticEnergyToTemperature*kineticEnergy;

		twister = gsl_rng_alloc(gsl_rng_mt19937);
		gsl_rng_set(twister, seed);
}
	else
		[NSException raise: NSInvalidArgumentException 
			format: @"%@ does not support non keyed coding", [self classDescription]];

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	AdDataMatrix* matrix;

	if([encoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Encode", @"Encoding %@", [self description]);
		[encoder encodeInt: seed forKey: @"Seed"];
		[encoder encodeDouble: targetTemperature forKey: @"TargetTemperature"];
		[encoder encodeInt: degreesOfFreedom forKey: @"DegreesOfFreedom"];
		[encoder encodeConditionalObject: dataSource forKey: @"DataSource"];

		matrix = [AdDataMatrix matrixFromADMatrix: coordinates];
		[encoder encodeObject: matrix forKey: @"Coordinates"];	
		matrix = [AdDataMatrix matrixFromADMatrix: velocities];
		[encoder encodeObject: matrix forKey: @"Velocities"];	
		NSDebugLLog(@"Encode", @"Complete %@", [self description]);
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}

@end
