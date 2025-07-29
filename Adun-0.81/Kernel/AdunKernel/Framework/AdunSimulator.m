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
#include "AdunKernel/AdunSimulator.h"

@implementation AdSimulator

- (void) emptyPool
{
	[pool release];
	pool = [[NSAutoreleasePool alloc] init];
//	AdLogMemoryUsage();
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
		numberOfSteps: 1000];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	numberOfSteps: (unsigned int) intOne
{

	return [self initWithSystems: aSystemCollection
		forceFields: aForceFieldCollection
		numberOfSteps: intOne
		timeStep: 1.0];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	numberOfSteps: (unsigned int) intOne
	timeStep: (double) aDouble
{
	return [self initWithSystems: aSystemCollection
		forceFields: aForceFieldCollection
		components: [NSArray array]
		numberOfSteps: intOne
		timeStep: aDouble];
}
	
- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	components: (NSArray*) anArray
	numberOfSteps: (unsigned int) intOne
	timeStep: (double) aDouble
{
	return [self initWithSystems: aSystemCollection
		forceFields: aForceFieldCollection
		components: anArray
		numberOfSteps: intOne
		timeStep: aDouble
		checkFPErrorInterval: 100];
}

- (id) initWithSystems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	components: (NSArray*) anArray
	numberOfSteps: (unsigned int) intOne
	timeStep: (double) aDouble
	checkFPErrorInterval: (unsigned int) intTwo
{
	NSEnumerator* componentsEnum;
	id component;

	if((self = [super init]))
	{
		endSimulation = NO;
		numberOfSteps = intOne;
		NSDebugLLog(@"AdSimulator", @"The number of steps is %d", numberOfSteps);
		timeStep = aDouble;
		[self setTimeStep: timeStep];
		checkFPErrorInterval = intTwo;
		currentStep = 0;

		componentsEnum = [anArray objectEnumerator];
		while((component = [componentsEnum nextObject]))
			if(![component conformsToProtocol: @protocol(AdSimulatorComponent)])
				[NSException raise: NSInvalidArgumentException
					format: @"All components must conform to AdSimulatorComponent"];
		
		components = [anArray copy];
		timer = [AdMainLoopTimer mainLoopTimer];	
	
		[self setForceFields: aForceFieldCollection];
		[self setSystems: aSystemCollection];
	}	
	
	return self;
}

- (void) dealloc
{	
	[systems release];
	[systemCollection release];
	[forceFieldCollection release];
	[components release];
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description;
	NSEnumerator* componentEnum;
	id component;
	
	description = [NSMutableString string];
	[description appendFormat: @"Class: %@\n", NSStringFromClass([self class])];
	[description appendFormat: @"Timestep: %-4.2lf. Number of steps: %d. ", 
		timeStep, numberOfSteps];
	[description appendFormat: @"Floating point error check interval: %d\n", checkFPErrorInterval];
	[description appendFormat: @"Components:\n"];
	if([components count] > 0)
	{
		componentEnum = [components objectEnumerator];
		while(component = [componentEnum nextObject])
			[description appendFormat: @"\t%@\n", [component description]];
	}
	else
		[description appendString: @"\tNone\n"];
		
	return description;	
}

- (void) _simulateFrom: (int) start to: (int) end
{
	register int j, k;
	int numberOfAtoms, offset;
	AdMatrix* coordinates, *accelerations, *velocities;
	NSString* name;
	NSEnumerator *systemEnum, *interactionSystemEnum, *forceFieldEnum, *componentEnum;
	id system, interactionSystem, forceField, component;
	
	pool = [[NSAutoreleasePool alloc] init];
	
	//Notify all components that production is about to start
	componentEnum = [components objectEnumerator];
	while((component = [componentEnum nextObject]))
		[component simulator: self
			willBeginProductionWithSystems: systemCollection 
			forceFields: forceFieldCollection];

	//Set timers
	[timer sendMessage: @selector(emptyPool)
		toObject: self
		interval: 100
		name: @"Autorelease"];
	[timer sendMessage: @selector(checkFloatingPointErrors)
		toObject: self
		interval: checkFPErrorInterval
		name: @"FloatingPointErrors"];

	for(currentStep=start; currentStep < end; currentStep++)
	{
		NSDebugLLog(@"SimulationLoop",
			@"\nBeginning numerical integration - step %d", 
			currentStep);

		systemEnum = [systems objectEnumerator];
		while((system = [systemEnum nextObject]))
		{
			name = [system systemName];
			coordinates = [system coordinates];
			velocities = [system velocities];

			/*** First Step ***/

			[components makeObjectsPerformSelector: 
				@selector(simulatorWillPerformFirstVelocityUpdateForSystem:)
				withObject: system];

			numberOfAtoms = coordinates->no_rows;

			//Intra-System Forces
			forceFieldEnum = [[forceFieldCollection forceFieldsForSystem: system
						activityFlag: AdActiveForceFields]
						objectEnumerator];

			[system object: self willBeginWritingToMatrix: velocities]; 
			while((forceField = [forceFieldEnum nextObject]))
			{
				accelerations = [forceField accelerations];
				for(j=0; j < numberOfAtoms; j++)
					for(k=0; k<3; k++)
						velocities->matrix[j][k] +=  accelerations->matrix[j][k]*halfTimeStep;
			}

			//Inter-System Forces - Taking care of offsets
			//FIXME: Precompute for each system
			interactionSystemEnum = [[systemCollection interactionSystemsInvolvingSystem: system]
							objectEnumerator];
			while((interactionSystem = [interactionSystemEnum nextObject]))
			{
				forceFieldEnum = [[forceFieldCollection forceFieldsForSystem: interactionSystem
							activityFlag: AdActiveForceFields]
							objectEnumerator];
				//Get the offset into the acceleration matrix of 
				//the interactionSystem for this system		
				offset = [interactionSystem rangeForSystem: system].location;		
				while((forceField = [forceFieldEnum nextObject]))
				{
					accelerations = [forceField accelerations];
					for(j=0; j < numberOfAtoms; j++)
						for(k=0; k<3; k++)
							velocities->matrix[j][k] +=  accelerations->matrix[j+offset][k]*halfTimeStep;
				}			
			}
			[system object: self didFinishWritingToMatrix: velocities]; 

			/*** Second Step ***/
					
			[components makeObjectsPerformSelector: 
				@selector(simulatorWillPerformPositionUpdateForSystem:)
				withObject: system];
			[system object: self willBeginWritingToMatrix: coordinates]; 
			for(k=0; k < numberOfAtoms; k++)
				for(j=0; j< 3; j++)	
					coordinates->matrix[k][j] += velocities->matrix[k][j]*timeStep;

			[system object: self didFinishWritingToMatrix: coordinates]; 
			
			[components makeObjectsPerformSelector: 
				@selector(simulatorDidPerformPositionUpdateForSystem:)
				withObject: system];
		}

		[forceFieldCollection evaluateForces];
		
		systemEnum = [systems objectEnumerator];
		while((system = [systemEnum nextObject]))
		{
			name = [system systemName];
			velocities = [system velocities];
			numberOfAtoms = [system numberOfElements];

			/*** Final Step ***/
	
			[components makeObjectsPerformSelector: 
				@selector(simulatorWillPerformSecondVelocityUpdateForSystem:)
				withObject: system];
				
			//Intra-System Forces
			forceFieldEnum = [[forceFieldCollection forceFieldsForSystem: system]
						objectEnumerator];
			
			[system object: self willBeginWritingToMatrix: velocities]; 
			while((forceField = [forceFieldEnum nextObject]))
			{
				accelerations = [forceField accelerations];
				for(j=0; j < numberOfAtoms; j++)
					for(k=0; k<3; k++)
						velocities->matrix[j][k] +=  accelerations->matrix[j][k]*halfTimeStep;
			}

			//Inter-System Forces
			//FIXME: Precompute for each system
			interactionSystemEnum = [[systemCollection interactionSystemsInvolvingSystem: system]
							objectEnumerator];
			while((interactionSystem = [interactionSystemEnum nextObject]))
			{
				forceField = [[forceFieldCollection forceFieldsForSystem: interactionSystem
						activityFlag: AdActiveForceFields]
						objectEnumerator];
				while((forceField = [forceFieldEnum nextObject]))
				{
					accelerations = [forceField accelerations];
					offset = [interactionSystem rangeForSystem: system].location;		
					for(j=0; j < numberOfAtoms; j++)
						for(k=0; k<3; k++)
							velocities->matrix[j][k] +=  accelerations->matrix[j+offset][k]*halfTimeStep;
				}			

			}

			[system object: self didFinishWritingToMatrix: velocities]; 
			
			[components makeObjectsPerformSelector: 
				@selector(simulatorDidPerformSecondVelocityUpdateForSystem:)
				withObject: system];
		}
		
		[timer increment];
		
		NSDebugLLog(@"SimulationLoop",
			@"Finished numerical integration - step %d",
			currentStep);

		//Don't like this but it seems to be the simplest and 
		//cleanest way to get the loop to exit when you want it to.
		if(endSimulation)
			break;
	}
	
	//Notify all components that production finished
	componentEnum = [components objectEnumerator];
	while((component = [componentEnum nextObject]))
		[component simulatorDidFinishProduction: self];

	[timer removeMessageWithName: @"Autorelease"];
	[timer removeMessageWithName: @"FloatingPointErrors"];
	[pool release];
}

- (BOOL) production: (NSError**) error
{
	BOOL success;
	struct tms start;
	struct tms end;
	NSDate *startDate, *finishDate;

	NS_DURING
	{
		startDate = [NSDate date];	
		GSPrintf(stdout,
			@"Beginning numerical integration on %@ - %d steps\n",
			startDate, numberOfSteps);
			
		//Send a notification
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"AdConfigurationGeneratorWillBeginProductionNotification"
			object: self];

		times(&start);
		[self _simulateFrom: 0 to: numberOfSteps];
		times(&end);
		
		GSPrintf(stdout, @"Finished numerical integration - step %d\n\n",
			currentStep);
		NSDebugLLog(@"SimulationLoop", 
			@"Numerical integration complete");
		success = YES;	

	}
	NS_HANDLER
	{
		times(&end);
		success = NO;
		*error = [[localException userInfo] objectForKey: @"AdKnownExceptionError"];
		if(*error == nil)
		{
			//Its an unknown framework exception
			*error = AdCreateError(AdunKernelErrorDomain,
					AdKernelUnknownError,
					@"Caught an exception from framework",
					[NSString stringWithFormat: 
						@"Name %@. Reason %@", 
						[localException name], [localException reason]],
					[NSString stringWithFormat: @"User info %@", 
						[localException userInfo]]);
		}					
		
		NSWarnLog(@"Detected error in integration - step %d", currentStep);
		GSPrintf(stdout, @"Detected error in integration - step %d\n", currentStep);
	}
	NS_ENDHANDLER
	
	//Print out some timing information for people who like that sort of thing.
	AdLogTimingInformation(&start, &end, numberOfSteps);
	finishDate = [startDate addTimeInterval: -1*[startDate timeIntervalSinceNow]];
	GSPrintf(stdout, @"\nFinish date %@. Seconds since start %.3lf", finishDate, -1*[startDate timeIntervalSinceNow]);
	fflush(stdout);
	
	return success;
}

- (BOOL) restartFrom: (int) step error: (NSError**) error
{
	BOOL success;
	struct tms start;
	struct tms end;

	NS_DURING
	{
		GSPrintf(stdout,
			@"Restarting numerical integration from step %d - %d steps remaining\n",
			step, numberOfSteps - step);
		times(&start);
		[self _simulateFrom: step to: numberOfSteps];
		times(&end);

		GSPrintf(stdout, @"Finished numerical integration - step %d\n\n",
			currentStep);
		NSDebugLLog(@"SimulationLoop", 
			@"Numerical integration complete");
		success = YES;	
	}
	NS_HANDLER
	{
		times(&end);
		success = NO;
		*error = [[localException userInfo] objectForKey: @"AdKnownExceptionError"];
		if(*error == nil)
		{
			//Its an unknown framework exception
			*error = AdCreateError(AdunKernelErrorDomain,
					AdKernelUnknownError,
					@"Caught an exception from framework",
					[NSString stringWithFormat: 
						@"Name %@. Reason %@", 
						[localException name], [localException reason]],
					[NSString stringWithFormat: @"User info %@", 
						[localException userInfo]]);
		}					
		NSWarnLog(@"Detected error in integration - step %d", currentStep);
		GSPrintf(stdout, @"Detected error in integration - step %d\n", currentStep);
	}
	NS_ENDHANDLER
	
	AdLogTimingInformation(&start, &end, numberOfSteps);
	fflush(stdout);

	return success;
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
	[systemCollection release];
	if(systems != nil)
		[systems release];

        systemCollection = [aCollection retain];
	systems = [systemCollection fullSystems];
	[systems retain];		
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

- (void) addComponent: (id) anObject
{
	if(![anObject conformsToProtocol: @protocol(AdSimulatorComponent)])
		[NSException raise: NSInvalidArgumentException
			format: @"Only object conforming to AdSystemComponent can be added as components"];

	[components addObject: anObject];
}

- (void) removeComponent: (id) anObject
{
	[components removeObject: anObject];
}

- (NSArray*) allComponents
{
	return [[components copy] autorelease];
}

- (void) setNumberOfSteps: (unsigned int) anInt
{
	numberOfSteps = anInt;
}

- (unsigned int) numberOfSteps
{
	return numberOfSteps;
}

- (double) timeStep
{
	return timeStep;
}

- (void) setTimeStep: (double) aDouble
{
	timeStep = aDouble;
	halfTimeStep = timeStep*0.5;
	halfTimeStepSquared = halfTimeStep*timeStep;
}

- (unsigned int) currentStep
{
	return currentStep;
}

@end
