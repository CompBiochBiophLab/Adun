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
#include "AdunKernel/AdunMinimiser.h"
#include <gsl/gsl_blas.h>

static NSArray* allowedAlgorithms;


/**
Methods that wrap calls to framework object so
pointers to the methods can be used with the GSL minimisation scheme
*/
@interface AdMinimiser (GSLWrappers)
/**
Calculates the energy of the systems in the system collection
*/
- (double) energyOfConfiguration: (const gsl_vector*) configuration usingParameters: (void*) params;
/**
Updates the configuration of the systems in system collection using \e configuration.
The sections of \e configuration corresponding to each system are given by rangeForSystem:()
Calculates the gradient (negative of the force) acting on the elements of the systems 
and writes it to \e gradient
*/
- (void) gradientOfConfiguration: (const gsl_vector*) configuration 
		usingParameters: (void*) params 
		gradientBuffer: (gsl_vector*) gradient;
/**
Updates the configuration of the systems in system collection using \e configuration.
The sections of \e configuration corresponding to each system are given by rangeForSystem:().
Calculates the gradient (negative of the force) acting on the elements of the systems and the energy. 
Stores the energy in \e energyBuffer and the gradient in \e gradient
*/
- (void) energyAndGradientOfConfiguration: (const gsl_vector*) configuration
		usingParameters: (void*) params
		energyBuffer: (double*) energyBuffer
		gradientBuffer: (gsl_vector*) gradient;
/**
Initialises the minimistiation function structure used by the gsl functions.
*/
- (void) initGSLMinimisationFunctionStruct;
@end



@implementation AdMinimiser

+ (void) initialize
{
	allowedAlgorithms = [NSArray arrayWithObjects:
				@"SteepestDescent",
				@"FletcherReevesCG",
				@"PolakRibiereCG",
				@"BFGS",
				nil];
	[allowedAlgorithms retain];			
}

- (void) _storeConfigurationInVector: (gsl_vector*) vector
{
	int i, j, k;
	AdMatrix* coordinates;
	NSRange range;
	NSEnumerator* systemEnum;
	NSValue* pointer;
	id system;

	systemEnum = [systemRanges keyEnumerator];
	while((pointer = [systemEnum nextObject]))
	{
		system = (id)[pointer pointerValue];
		range = [[systemRanges objectForKey: pointer] rangeValue];
		coordinates = [system coordinates];
		k = range.location*3;
		for(i=0; i<coordinates->no_rows; i++)
			for(j=0; j<3; j++, k++)
				gsl_vector_set(vector, k, coordinates->matrix[i][j]);
	}			
}

- (void) emptyPool
{
	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
	AdLogMemoryUsage();
}

- (void) endProduction
{
	endSimulation = YES;
}

- (id) init
{
	return [self initWithForceFields: nil];
}

- (id) initWithForceFields: (AdForceFieldCollection*) aForceFieldCollection
{
	return [self initWithSystems: nil
		forceFields: aForceFieldCollection];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
{
	return [self initWithSystems: aSystemCollection
		forceFields: aForceFieldCollection
		absoluteTolerance: 0.005
		numberOfSteps: 1E2];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	absoluteTolerance: (double) absTol
	numberOfSteps: (unsigned int) steps
{
	return [self initWithSystems: aSystemCollection
		forceFields: aForceFieldCollection
		absoluteTolerance: absTol
		numberOfSteps: steps
		algorithm: @"SteepestDescent"
		stepSize: 0.1
		tolerance: 0.1];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	absoluteTolerance: (double) absTol
	numberOfSteps: (unsigned int) steps
	algorithm: (NSString*) algorithm
	stepSize: (double) stepsize
	tolerance: (double) tol
{

	return [self initWithSystems: aSystemCollection
		forceFields: aForceFieldCollection
		absoluteTolerance: absTol
		numberOfSteps: steps
		algorithm: algorithm
		stepSize: stepsize
		tolerance: tol
		checkFPErrorInterval: 1000];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	absoluteTolerance: (double) absTol
	numberOfSteps: (unsigned int) steps
	algorithm: (NSString*) aString
	stepSize: (double) step
	tolerance: (double) tol
	checkFPErrorInterval: (unsigned int) interval
{

	if((self = [super init]))
	{
		endSimulation = NO;
		checkFPErrorInterval = interval;
		currentStep = 0;
		absoluteTolerance = fabs(absTol);
		tolerance = fabs(tol);
		stepSize = step;
		numberOfSteps = steps;
		systemRanges = [NSMutableDictionary new];
		currentEnergy = gradientNorm = 0;
		converged = NO;
		constraints = [NSMutableDictionary new];
		NSDebugLLog(@"AdSimulator", @"The maximium number of iterations  is %d", numberOfSteps);

		if(aString == nil)
			aString = @"SteepestDescent";
		
		[self setAlgorithm: aString];
		[self setForceFields: aForceFieldCollection];
		[self setSystems: aSystemCollection];
	
		timer = [AdMainLoopTimer mainLoopTimer];	
	}	
	
	return self;
}

- (void) dealloc
{	
	gsl_matrix* matrix;
	NSEnumerator* keyEnum;
	NSValue* key, *value;

	//Free any constraint matrices
	keyEnum = [constraints keyEnumerator];
	while(key = [keyEnum nextObject])
	{
		value = [constraints objectForKey: key];
		matrix = [value pointerValue];
		gsl_matrix_free(matrix);
	}
		
	[constraints release];	
	[systemCollection release];
	[systemRanges release];
	[forceFieldCollection release];
	[algorithmName release];
	[fullSystems release];
	[super dealloc];
}

- (BOOL) production: (NSError**) error
{
	int status;
	struct tms start;
	struct tms end;
	gsl_multimin_fdfminimizer *minimiser;
	gsl_vector* initialConfiguration;
	
	converged = NO;
	gradientNorm = 0;

	//Allocate and set the minimiser 
	minimiser = gsl_multimin_fdfminimizer_alloc(algorithmType, numberOfElements*3);
	[self initGSLMinimisationFunctionStruct];
	if(minimiser == NULL)
	{
		NSWarnLog(@"Error while initialising minimiser");
		return NO;
	}	
	
	initialConfiguration = gsl_vector_calloc(numberOfElements*3);
	[self _storeConfigurationInVector: initialConfiguration];

	currentEnergy =	[self energyOfConfiguration: initialConfiguration 
				usingParameters: NULL];
	NSDebugLLog(@"AdMinimiser",
		@"Initial energy %lf\n", currentEnergy);
	GSPrintf(stdout,
		@"\nBeginning minimisation using %@ algorithm - Max steps %d\n",
		algorithmName, numberOfSteps);
	GSPrintf(stdout,
		@"Initial energy %lf\n", currentEnergy);

	gsl_multimin_fdfminimizer_set(minimiser, 
		&minimistationFunctions, 
		initialConfiguration, 
		stepSize,
		tolerance);

	//Send a notification
	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"AdConfigurationGeneratorWillBeginProductionNotification"
		object: self];

	//Setup timers
	[timer sendMessage: @selector(emptyPool)
		toObject: self
		interval: 100
		name: @"Autorelease"];
	[timer sendMessage: @selector(checkFloatingPointErrors)
		toObject: self
		interval: checkFPErrorInterval
		name: @"FloatingPointErrors"];

	//Minimsation
	times(&start);
	NSDebugLLog(@"AdMinimiser", @"Beginning minimisation");
	pool = [[NSAutoreleasePool alloc] init];
	for(currentStep=0; currentStep < numberOfSteps; currentStep++)
	{
		status = gsl_multimin_fdfminimizer_iterate(minimiser);
		currentEnergy = gsl_multimin_fdfminimizer_minimum(minimiser);
		gradientNorm = gsl_blas_dnrm2(gsl_multimin_fdfminimizer_gradient(minimiser));
		[timer increment];
		
		NSDebugLLog(@"SimulationLoop",
			@"Finished minimisation - step %d",
			currentStep);
		NSDebugLLog(@"SimulationLoop", 
			@"Current energy %lf. Gradient norm %lf", 
			currentEnergy,
			gradientNorm);

		if(status) 
		{
			GSPrintf(stdout, @"Error during iteration\n");
			GSPrintf(stdout, @"Decription - %s\n", gsl_strerror(status));
			NSWarnLog(@"Error during iteration");
			NSWarnLog(@"Description - %s", gsl_strerror(status));
			break;
		}	
		
		status = gsl_multimin_test_gradient(
				gsl_multimin_fdfminimizer_gradient(minimiser), 
				absoluteTolerance);

		if(status == GSL_SUCCESS)
		{
			GSPrintf(stdout, @"Reached covergence\n");
			converged = YES;
			break;
		}	

		if(endSimulation)
		{
			GSPrintf(stdout, @"Exiting on user request\n");
			break;
		}	
	}

	times(&end);
	GSPrintf(stdout, @"Minimistation ended - step %d\n",
	 	currentStep);
	if(currentStep == 0)
		currentStep = 1;
	GSPrintf(stdout, 
		@"Final energy %lf. Gradient norm %lf. Target accuracy %lf\n\n", 
		currentEnergy,
		gradientNorm,
		absoluteTolerance); 
	NSDebugLLog(@"SimulationLoop", 
		@"Minimistation complete");

	AdLogTimingInformation(&start, &end, currentStep);
	fflush(stdout);
	
	[timer removeMessageWithName: @"FloatingPointErrors"];
	[timer removeMessageWithName: @"Autorelease"];
	gsl_multimin_fdfminimizer_free(minimiser);
	gsl_vector_free(initialConfiguration);
	minimiser = NULL;
	initialConfiguration = NULL;
	[pool release];

	return YES;
}

- (BOOL) restartFrom: (int) step error: (NSError**) error
{
	NSWarnLog(@"AdMinimiser instances do not support restarting");
	return NO;
}
/*
 * Object Accessors
 */

- (AdSystemCollection*) systems
{
	return [[systemCollection retain] autorelease];
}

- (void) setSystems: (AdSystemCollection*) aCollection
{
	int start, end;
	NSRange range;
	NSEnumerator* systemEnum;
	id system;

	//We need to assign ranges to the systems

	[systemCollection release];
        systemCollection = [aCollection retain];
	[fullSystems release];
	fullSystems = [systemCollection fullSystems];
	[fullSystems retain];
	[systemRanges removeAllObjects];
	
	numberOfElements= start = end = 0;
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		numberOfElements += [system numberOfElements];
		start = end;
		end = start + [system numberOfElements];
		range = NSMakeRange(start, [system numberOfElements]);
		[systemRanges setObject: [NSValue valueWithRange: range]
			forKey: [NSValue valueWithPointer: system]];
	}		

	NSDebugLLog(@"AdMinimiser",
		@"There are %d elements in total", numberOfElements);
	NSDebugLLog(@"AdMinimiser", 
		@"Systems and ranges %@", systemRanges);
}

- (AdForceFieldCollection*) forceFields
{
	return [[forceFieldCollection retain] autorelease];
}

- (void) setForceFields: (AdForceFieldCollection*) object 
{
	[forceFieldCollection release];
	forceFieldCollection = [object retain];
}

- (void) setNumberOfSteps: (unsigned int) anInt
{
	numberOfSteps = anInt;
}

- (unsigned int) numberOfSteps
{
	return numberOfSteps;
}

- (double) stepSize
{
	return stepSize;
}

- (void) setStepSize: (double) aDouble
{
	stepSize = aDouble;
}

- (unsigned int) currentStep
{
	return currentStep;
}

- (void) setAlgorithm: (NSString*) aString
{
	if(![allowedAlgorithms containsObject: aString])
		[NSException raise: NSInvalidArgumentException
			format: @"Unknown minimistation algorithm %@", aString];

	[algorithmName release];
	algorithmName = [aString retain];

	if([aString isEqual: @"FletcherReevesCG"])
		algorithmType = gsl_multimin_fdfminimizer_conjugate_fr;
	else if([aString isEqual: @"PolakRibiereCG"])
		algorithmType = gsl_multimin_fdfminimizer_conjugate_pr;
	else if([aString isEqual: @"SteepestDescent"])
		algorithmType = gsl_multimin_fdfminimizer_steepest_descent;
	else if([aString isEqual: @"BFGS"])
		algorithmType = gsl_multimin_fdfminimizer_vector_bfgs;
}

- (NSString*) algorithm
{
	return [[algorithmName retain] autorelease];
}

- (double) tolerance
{
	return tolerance;
}

- (void) setTolerance: (double) aDouble
{
	tolerance = fabs(aDouble);
}

- (double) absoluteTolerance
{
	return absoluteTolerance; 
}

- (void) setAbsoluteTolerance: (double) aDouble;
{
	absoluteTolerance = fabs(aDouble);
}

- (double) currentEnergy
{
	return currentEnergy;
}

- (BOOL) converged
{
	return converged;
}

- (double) gradientNorm
{
	return gradientNorm;
}

- (void) setConstraints: (AdDataMatrix*) aMatrix forSystem: (AdSystem*) system
{
	gsl_matrix* constraintMatrix;
	NSValue *pointer;

	//Check system exists
	if(![[systemCollection fullSystems] containsObject: system])
		[NSException raise: NSInvalidArgumentException
			    format: @"System %@ is not one of the full systems known by this minimiser object",
			    system];

	//Check they are the right dimension
	if((int)[aMatrix numberOfRows] != 3*numberOfElements)
		[NSException raise: NSInvalidArgumentException
			format: @"Constraint matrix has incorrect number of rows (%@, Expected - %d)"
				,[aMatrix numberOfRows], numberOfElements*3];
	
	//Remove any previous constraints set for system (if any)
	[self removeConstraintsForSystem: system];
	
	constraintMatrix = AdGSLMatrixFromAdDataMatrix(aMatrix);
	[constraints setObject: [NSValue valueWithPointer: constraintMatrix]
		forKey:  [NSValue valueWithPointer: system]];
}

- (AdDataMatrix*) constraintsForSystem: (AdSystem*) system
{
	gsl_matrix* constraintMatrix;
	NSValue* value;
	
	value = [constraints objectForKey: [NSValue valueWithPointer: system]];
	//Check if any constraints were set
	if(value == nil)
		return nil;
	
	constraintMatrix = [value pointerValue];
	return [AdDataMatrix matrixFromGSLMatrix: constraintMatrix];
}

- (void) removeConstraintsForSystem: (AdSystem*) system
{
	gsl_matrix* constraintMatrix;
	NSValue* value;
	
	value = [constraints objectForKey: [NSValue valueWithPointer: system]];
	//Check if any constraints were set
	if(value != nil)
	{
		[constraints removeObjectForKey: [NSValue valueWithPointer: system]];
		constraintMatrix = [value pointerValue];
		gsl_matrix_free(constraintMatrix);
	}
}

@end

//The GSL functions wrapping the methods in the category below.

double energyFunction(const gsl_vector* configuration, void* params);
void gradientFunction(const gsl_vector* configuration, void* params, gsl_vector* gradient);
void energyAndGradientFunction(const gsl_vector* configuration, 
	void* params, 
	double* energyBuffer, 
	gsl_vector* gradient);

double energyFunction(const gsl_vector* configuration, void* params)
{
	return [(AdMinimiser*)params energyOfConfiguration: configuration
			usingParameters: params];
}

void gradientFunction(const gsl_vector* configuration, void* params, gsl_vector* gradient)
{
	[(AdMinimiser*)params gradientOfConfiguration: configuration
		usingParameters: params
		gradientBuffer: gradient];
}

void energyAndGradientFunction(const gsl_vector* configuration, 
	void* params, double* 
	energyBuffer, 
	gsl_vector* gradient)
{
	[(AdMinimiser*)params energyAndGradientOfConfiguration: configuration
		usingParameters: params
		energyBuffer: energyBuffer
		gradientBuffer: gradient];
}		

@implementation AdMinimiser (GSLWrappers)

- (void) _updateSystemsWithConfiguration: (const gsl_vector*) configuration
{
	int i,j,k;
	double movement = 0;
	AdMatrix* coordinates;
	NSRange range;
	NSEnumerator* systemEnum;
	id system;

	//Set the new configuration
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		coordinates = [system coordinates];
		[system object: self willBeginWritingToMatrix: coordinates];
		range = [[systemRanges objectForKey: [NSValue valueWithPointer: system]]
				rangeValue];
		for(i=0, k = range.location*3; i < coordinates->no_rows; i++)
			for(j = 0; j < 3; j++, k++)
			{	movement += pow(coordinates->matrix[i][j] - gsl_vector_get(configuration, k), 2);
				coordinates->matrix[i][j] = gsl_vector_get(configuration, k);
			}	
		
		[system object: self didFinishWritingToMatrix: coordinates];
	}
}

/**
Removes the projection along a set of constraint vectors
from \e vector.
The constraint vectors are retreived from the contraints ivar which is a dictionary.
If the dictionary contains constraints for \e system this method does nothing.
*/
- (void) _applyConstraintsToForceVector: (gsl_vector*) vector forSystem: (AdSystem*) system
{
	unsigned int i;
	double projection;
	gsl_vector* constraintVector;
	gsl_matrix* constraintMatrix;
	gsl_vector_view view; 
	NSValue* value;

	value = [constraints objectForKey: [NSValue valueWithPointer: system]];
	if(value != nil)
	{
		constraintMatrix = [value pointerValue];
		//A vector structure to hold the vectors
		constraintVector = gsl_vector_alloc(vector->size);
		
		//Iterate over the constraint vectors
		for(i=0; i<constraintMatrix->size2; i++)
		{
			//Copy the constraint vector into the vector struct
			view = gsl_matrix_column(constraintMatrix, i);
			gsl_vector_memcpy(constraintVector, &view.vector);
			
			//Find the projection
			gsl_blas_ddot(vector, constraintVector, &projection);
			
			//Remove the projection along the constraint vector
			gsl_vector_scale(constraintVector, -projection);
			gsl_vector_sub(vector, constraintVector);
		}
		
		gsl_vector_free(constraintVector);
	}	
}

- (double) energyOfConfiguration: (const gsl_vector*) configuration usingParameters: (void*) params
{
	double energy = 0;
	NSEnumerator * forceFieldsEnum, *systemEnum;
	NSArray* forceFields;
	id forceField, system;
	NSMutableSet* forceFieldSet;

	[self _updateSystemsWithConfiguration: configuration];
	forceFieldSet = [NSMutableSet set];

	[forceFieldCollection evaluateEnergies];
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		forceFields = [forceFieldCollection forceFieldsForSystem: system
				activityFlag: AdActiveForceFields];
		[forceFieldSet addObjectsFromArray: forceFields];
	}	
	
	forceFieldsEnum = [forceFieldSet objectEnumerator];
	while((forceField = [forceFieldsEnum nextObject]))
		energy += [forceField totalEnergy];
	
	return energy;
}

- (void) gradientOfConfiguration: (const gsl_vector*) configuration 
		usingParameters: (void*) params 
		gradientBuffer: (gsl_vector*) gradient
{
	double energy = 0;

	[self energyAndGradientOfConfiguration: configuration
		usingParameters: params
		energyBuffer: &energy
		gradientBuffer: gradient];
}

/**
Convienience function called from energyAndGradientOfConfiguration:usingParameters:energyBuffer:gradientBuffer:
It adds the gradient information in vector, which corresponds to the atoms in \e aSystem
to the \e gradient vector.
It applies any constraints to the force-vector first.

See the main method for more.
*/
- (void) _updateGradient: (gsl_vector*) gradient 
		ofSystem: (AdSystem*) aSystem 
		withForces: (gsl_vector*) vector 
{
	unsigned int i,k;
	double value;
	NSRange gradientRange;
	
	[self _applyConstraintsToForceVector: vector 
		forSystem: aSystem];
	
	//Now update the gradient vector with the force vector
	//
	//systemRange will tell us the range assigned to the
	//atoms from interactingSystem.
	//For example, there are 10000 total atoms, and the
	//ones from 560 to 6780 are part of this system
	//The elements in the gradient vector corresponding to 
	//this system are then 560*3 - 6780*3. (3DOF's per atoms)
	gradientRange = [[systemRanges objectForKey: 
			  [NSValue valueWithPointer: aSystem]]
			   rangeValue];
	
	for(i=0, k = gradientRange.location*3; i<vector->size; i++, k++)
	{
		value = gsl_vector_get(gradient, k);
		//Force is the negative of the gradient
		value -= gsl_vector_get(vector, i);
		gsl_vector_set(gradient, k, value);
	}		
}

- (void) energyAndGradientOfConfiguration: (const gsl_vector*) configuration
		usingParameters: (void*) params
		energyBuffer: (double*) energyBuffer
		gradientBuffer: (gsl_vector*) gradient
{
	unsigned int i;
	int j, k;
	double value, energy;
	AdMatrix* forces;
	gsl_vector* myGradient, *forceVector;
	NSRange interactionRange;
	NSEnumerator * forceFieldsEnum, *systemEnum, *interactingSystemsEnum;
	NSArray* forceFields;
	NSMutableSet* forceFieldSet;
	id forceField, system, interactingSystem;
	
	/*
	 * The main points here
	 * 1) Adun gets the forces on a system by system basis
	 * 2) They are returned as matrices
	 *    So if there are three systems there will be three matrices.
	 * 3) The gsl functions require one vector containing the total
	 *    gradient on all atoms - this is the gradient parameter
	 *    passed above
	 * 
	 * This means we have to do two things
	 * 1) Change the matrices into vectors
	 * 2) For each system update the correct elements in the gradientVector
	 *    To do this we use the systemRange ivar which tells us which elements
	 *    in the gradient vector correspond to the atoms of each system.
	 */
	
	//We cant be sure whats in the gradient buffer already.
	//Since we need to add directly to the gradient elements 
	//we work on our own vector and copy the results to the buffer 
	//at the end
	myGradient = gsl_vector_calloc(numberOfElements*3);
	
	[self _updateSystemsWithConfiguration: configuration];
	forceFieldSet = [NSMutableSet set];
	[forceFieldCollection evaluateForces];

	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		forceFields = [forceFieldCollection forceFieldsForSystem: system
				activityFlag: AdActiveForceFields];
		[forceFieldSet addObjectsFromArray: forceFields];
	}	

	energy = 0;
	forceFieldsEnum = [forceFieldSet objectEnumerator];
	while((forceField = [forceFieldsEnum nextObject]))
	{
		forces = [forceField forces];
		system = [forceField system];
		
		//We have to differentiate between forces from
		//a normal system and forces from an interaction system
		if([system isKindOfClass: [AdInteractionSystem class]])
		{
			//Only use the parts of the interaction system forces that
			//correspond to full systems in the system collection
			//This usually would be both but there could be e.g. a dipole
			//system whose elements can't be moved.
			interactingSystemsEnum = [[(AdInteractionSystem*)system systems] objectEnumerator];
			while((interactingSystem = [interactingSystemsEnum nextObject]))
			{
				if([fullSystems containsObject: interactingSystem])
				{
					//Get the range for this system in the joint 
					//interaction system matrices
					interactionRange = [system rangeForSystem: interactingSystem];
							
					//Create a vector from the part of the force-matrix
					//corresponding to interactingSystem
					forceVector = gsl_vector_alloc(interactionRange.length*3);
					for(i=interactionRange.location, k = 0; i < NSMaxRange(interactionRange); i++)
						for(j=0;j<3; j++, k++)
							gsl_vector_set(forceVector, k, forces->matrix[i][j]);
					
					//This will also apply any constraints etc.
					[self _updateGradient: myGradient 
						ofSystem: interactingSystem
						withForces: forceVector];
						
					gsl_vector_free(forceVector);
				}
			}	
		}
		else
		{
			//Create a force-vector for the system
			forceVector = gsl_vector_alloc(forces->no_rows*3);
			for(i=0, k = 0; i < (unsigned int)forces->no_rows; i++)
				for(j=0;j<3; j++, k++)
					gsl_vector_set(forceVector, k, forces->matrix[i][j]);
		
			[self _updateGradient: myGradient 
				ofSystem: system 
				withForces: forceVector];
				
			gsl_vector_free(forceVector);			
		}
		
		energy += [forceField totalEnergy];
	}

	gsl_vector_memcpy(gradient, myGradient);
	gsl_vector_free(myGradient);
	*energyBuffer = energy;
}

- (void) initGSLMinimisationFunctionStruct
{
	minimistationFunctions.f = (double (*)(const gsl_vector*, void*))energyFunction;
	minimistationFunctions.df = (void (*)(const gsl_vector*, void*, gsl_vector*))gradientFunction;
	minimistationFunctions.fdf = (void (*)(const gsl_vector*, void*, double*, gsl_vector*))energyAndGradientFunction;

	minimistationFunctions.n = numberOfElements*3;
	//Set the param to be ourself to the functions can call the above methods
	minimistationFunctions.params = (void*)self;
}

@end
