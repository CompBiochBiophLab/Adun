/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunGRFNonbondedTerm.h"

static NSArray* knownTypes;

@implementation AdGRFNonbondedTerm

- (BOOL) _checkMatrix: (AdDataMatrix*) matrix containsParametersForType: (NSString*) type
{
	NSArray* headers;

	headers = [matrix columnHeaders];
	if([type isEqual: @"A"])	
	{
		if(![headers containsObject: @"VDW A"])
			return NO;
		else if(![headers containsObject: @"VDW B"])
			return NO;
		
	}
	else if([type isEqual: @"B"])	
	{
		if(![headers containsObject: @"VDW WellDepth"])
			return NO;
		else if(![headers containsObject: @"VDW Separation"])
			return NO;
	}

	if(![headers containsObject: @"PartialCharge"])
		return NO;

	return YES;	
}

/*
 * To speed up the calculation in the type A case we
 * can precompute the product A*A and B*B for the LJ interactions
 */
- (void) _precomputeParameters
{
	int atomOne, atomTwo;
	ListElement* list_p;

	list_p = interactionList->next;
	if([lennardJonesType isEqual: @"A"])
	{	
		while(list_p->next != NULL)
		{
			atomOne = list_p->bond[0];
			atomTwo = list_p->bond[1];
			list_p->params[0] = parameters->matrix[atomOne][0]*parameters->matrix[atomTwo][0];
			list_p->params[1] = parameters->matrix[atomOne][1]*parameters->matrix[atomTwo][1];
			list_p->params[2] = partialCharges[atomOne]*partialCharges[atomTwo];
			list_p = list_p->next;
		}
	}
	else
	{
		while(list_p->next != NULL)
		{
			atomOne = list_p->bond[0];
			atomTwo = list_p->bond[1];
			list_p->params[0] = sqrt(parameters->matrix[atomOne][0]*parameters->matrix[atomTwo][0]);
			list_p->params[1] = (parameters->matrix[atomOne][1] + parameters->matrix[atomTwo][1]);
			list_p->params[2] = partialCharges[atomOne]*partialCharges[atomTwo];
			list_p = list_p->next;
		}
	}
}

/*
 * Retrieve the necessary parameters from the element properties.
 */
- (void) _initialiseParameters
{
	int numberOfElements, i;
	NSArray* parametersOne, *parametersTwo;

	numberOfElements = [system numberOfElements];
	parameters = [memoryManager
			allocateMatrixWithRows: numberOfElements
			withColumns: 2];

	if([lennardJonesType isEqual: @"A"])
	{
		//We have  LJ parameters A and B
	
		parametersOne = [elementProperties columnWithHeader: @"VDW A"];
		parametersTwo = [elementProperties columnWithHeader: @"VDW B"];

		for(i=0; i<numberOfElements; i++)
		{
			parameters->matrix[i][0] = [[parametersOne objectAtIndex: i]
							doubleValue];
			parameters->matrix[i][1] = [[parametersTwo objectAtIndex: i]
							doubleValue];
		}
	}
	else
	{
		//We have LJ parameters WellDepth and Separation
		parametersOne = [elementProperties columnWithHeader: @"VDW WellDepth"];
		parametersTwo = [elementProperties columnWithHeader: @"VDW Separation"];

		for(i=0; i<numberOfElements; i++)
		{
			parameters->matrix[i][0] = [[parametersOne objectAtIndex: i]
							doubleValue];
			parameters->matrix[i][1] = [[parametersTwo objectAtIndex: i]
							doubleValue];
		}
	}

	parametersOne = [elementProperties columnWithHeader: @"PartialCharge"];
	partialCharges = [memoryManager
				allocateArrayOfSize: numberOfElements*sizeof(double)];
	for(i=0; i<numberOfElements; i++)
		partialCharges[i] = [[parametersOne objectAtIndex: i] doubleValue];
}

- (void) _calculateGRFParameters
{
	b0 = (epsilon1 - 2*epsilon2*(1 + kappa*cutoff))/epsilon2*(1 + kappa*cutoff);
	b1 = (epsilon1 - 4*epsilon2)*(1+kappa*cutoff) - 2*epsilon2*(kappa*cutoff)*(kappa*cutoff);
	b1 /= (epsilon1 - 2*epsilon2)*(1+kappa*cutoff) + epsilon2*(kappa*cutoff)*(kappa*cutoff);

	b0 += 1;
	b0 /= cutoff;

	b1 += 1;
	b1 /= pow(cutoff,3);

	NSDebugLLog(@"GRFNonbondedCalculator", @"B0 initial value %lf. B1 inital value %lf", b0, b1);
}

- (void) _determineLJType
{
	NSArray* availableInteractions;

	availableInteractions = [system availableInteractions];
	if([availableInteractions containsObject: @"TypeOneVDWInteraction"])
		lennardJonesType =  [@"A" retain];
	else if([availableInteractions containsObject: @"TypeTwoVDWInteraction"])
		lennardJonesType =  [@"B" retain];
	else
	{
		NSWarnLog(@"Unable to determine Lennard Jones type");
		NSWarnLog(@"Interactions %@", availableInteractions);
		lennardJonesType =  [@"A" retain];
	}	
}

/*
 * Initialisation
 */

+ (void) initialize
{
	knownTypes = [NSArray arrayWithObjects:
			@"A", @"B", nil];
	[knownTypes retain];
}

- (id) init
{
	return [self initWithSystem: nil];
}

- (id) initWithSystem: (id) aSystem
{
	return [self initWithSystem: aSystem
		cutoff: 12.0
		updateInterval: 20
		epsilonOne: 1.0
		epsilonTwo: 78.0
		kappa: 0.0
		nonbondedPairs: nil
		externalForceMatrix: NULL];
}

- (id) initWithSystem: (id) aSystem 
	cutoff: (double) aDouble
	updateInterval: (unsigned int) anInt
	epsilonOne: (double) e1
	epsilonTwo: (double) e2
	kappa: (double) k
	nonbondedPairs: (NSArray*) nonbondedPairs
	externalForceMatrix: (AdMatrix*) matrix
{
	return [self initWithSystem: aSystem
		cutoff: aDouble
		updateInterval: anInt
		epsilonOne: e1
		epsilonTwo: e2
		kappa: k
		nonbondedPairs: nonbondedPairs
		externalForceMatrix: matrix
		listHandlerClass: [AdCellListHandler class]];
}

- (id) initWithSystem: (id) aSystem 
	cutoff: (double) aDouble
	updateInterval: (unsigned int) anInt
	epsilonOne: (double) e1
	epsilonTwo: (double) e2
	kappa: (double) k
	nonbondedPairs: (NSArray*) nonbondedPairs
	externalForceMatrix: (AdMatrix*) matrix
	listHandlerClass: (Class) aClass
{
	AdMatrix* coordinates;

	if((self = [super init]))
	{
		elementProperties = nil;
		pairs = nil;
		lennardJonesType = nil;
		system = nil;
		interactionList = NULL;
		partialCharges = NULL;
		forces = parameters = NULL;
		usingExternalForceMatrix = NO;
		memoryManager = [AdMemoryManager appMemoryManager];
		cutoff = aDouble;
		buffer = 1.0;
		updateInterval = anInt;
		epsilon1 = e1;
		epsilon2 = e2;
		kappa = k;
		electrostaticConstant = PI4EP_R/epsilon1;

		[self _calculateGRFParameters];
		
		if(aClass ==  nil)
			aClass = [AdCellListHandler class];

		if(![aClass isSubclassOfClass: [AdListHandler class]])	
			[NSException raise: NSInvalidArgumentException
				format: @"Supplied list handler class, %@, is not a subclass of AdListHandler",
				NSStringFromClass(aClass)];

		listHandlerClass = aClass;

		if(aSystem !=  nil)
		{
			system = [aSystem retain];
			[self _determineLJType];
			
			//Retrieve element coordinates
			coordinates = [system coordinates];
			if(coordinates == NULL)
			{
				[self release];
				[NSException raise: NSInvalidArgumentException 
					format: @"Coordinates cannot be NULL"];
			}		

			
			//Check the element properties contain the required parameters
			elementProperties = [system elementProperties];
			[elementProperties retain];
			if(![self _checkMatrix: elementProperties containsParametersForType: lennardJonesType])
			{
				[self release];
				NSWarnLog(@"Requried properties not present in - %@", [elementProperties columnHeaders]);
				[NSException raise: NSInvalidArgumentException
					format: @"Properites matrix does not contain correct parameters for LJ type %@"
					,lennardJonesType];
			}

			[self _initialiseParameters];

			//Create handler
			listHandler = [[aClass alloc] 
					initWithSystem: system
					allowedPairs: nil
					cutoff: cutoff + buffer];
			[listHandler setDelegate: self];

			messageId = [[NSProcessInfo processInfo] globallyUniqueString];
			[messageId retain];
			[[AdMainLoopTimer mainLoopTimer] 
				sendMessage: @selector(update)
				toObject: listHandler
				interval: updateInterval
				name: messageId];

			if(nonbondedPairs == nil)
				nonbondedPairs = [system indexSetArrayForCategory:@"Nonbonded"];

			[self setNonbondedPairs: nonbondedPairs];

			if(matrix == NULL)
			{
				usingExternalForceMatrix = NO;
				forces = [memoryManager allocateMatrixWithRows: coordinates->no_rows
						withColumns: 3];
			}
			else
			{
				if(matrix->no_rows != coordinates->no_rows)
				{
					[self release];
					[NSException raise: NSInvalidArgumentException
						format: @"Force matrix has incorrect number of rows"];
				}		

				if(matrix->no_columns != 3)
				{
					[self release];
					[NSException raise: NSInvalidArgumentException
						format: @"Force matrix has incorrect number of columns"];
				}		
				forces = matrix;
				usingExternalForceMatrix = YES;
			}			
			
			[self _precomputeParameters];
		}	
	}

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];

	[pairs release];
	[listHandler release];
	[elementProperties release];
	[lennardJonesType release];
	[memoryManager freeArray: partialCharges];
	[memoryManager freeMatrix: parameters];
	if(!usingExternalForceMatrix)
		[memoryManager freeMatrix: forces];
	[system release];
	if(messageId != nil)
	{
		[[AdMainLoopTimer mainLoopTimer]
			removeMessageWithName: messageId];
		[messageId release];
	}	
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];
	
	[description appendFormat: 
		     @"%@. System: %@\n\tCutoff: %5.2lf. Epsilon 1: %5.2lf. Epsilon 2: %5.2lf. Kappa: %5.2lf. Update interval: %d\n",
		NSStringFromClass([self class]), [system systemName], cutoff, 
		epsilon1, epsilon2, kappa, updateInterval];
	[description appendFormat: @"\t%@", [listHandler description]];
	
	return description;
}

/*
 * Force & Potential Calculation
 */

- (void) evaluateForces;
{
	ListElement* list_p;
	AdMatrix* coordinates;

	coordinates = [system coordinates];

	if(interactionList == NULL)
	{
		if(system != nil && pairs != nil)
		{
			[self setNonbondedPairs: 
				[system indexSetArrayForCategory:@"Nonbonded"]];
		}		
		else 
			return;
	}

	//May be quicker to get the number of nonbonded interactions and then use a for loop here
	
	vdwPotential = 0;
	estPotential = 0;

	list_p = interactionList->next;

	if([lennardJonesType isEqual: @"A"])
	{
		while(list_p->next != NULL)
		{	
			AdGRFCoulombAndLennardJonesAForce(list_p, 
				coordinates->matrix, 
				forces->matrix, 
				electrostaticConstant, 
				cutoff,
				b0,
				b1,
				&vdwPotential, 
				&estPotential);
			list_p = list_p->next;
		}
	}
	else
	{
		while(list_p->next != NULL)
		{
			AdGRFCoulombAndLennardJonesBForce(list_p, 
				coordinates->matrix, 
				forces->matrix, 
				electrostaticConstant, 
				cutoff,
				b0,
				b1,
				&vdwPotential, 
				&estPotential);
			list_p = list_p->next;
		}
	}
}

- (void) evaluateLennardJonesForces
{
	NSWarnLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateElectrostaticForces
{
	NSWarnLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateEnergy;
{
	ListElement* list_p;
	AdMatrix* coordinates;

	coordinates = [system coordinates];

	if(interactionList == NULL)
	{
		/*
		 * If system and pairs are not nil the list was invalidated by receipt of
		 * an AdSystemContentsDidChangeNotification. In this case we rebuild it
		 * using a newly acquired pair array
		 */
		if(system != nil && pairs != nil)
		{
			[self setNonbondedPairs: 
				[system indexSetArrayForCategory:@"Nonbonded"]];
		}		
		else 
			return;
	}

	vdwPotential = 0;
	estPotential = 0;

	if([lennardJonesType isEqual: @"A"])
	{
		list_p = interactionList->next;
		while(list_p->next != NULL)
		{
			AdGRFCoulombAndLennardJonesAEnergy(list_p, 
				coordinates->matrix,
				electrostaticConstant, 
				cutoff,
				b0,
				b1,
				&vdwPotential, 
				&estPotential);
			list_p = list_p->next;
		}
	}
	else
	{
		list_p = interactionList->next;
		while(list_p->next != NULL)
		{
			AdGRFCoulombAndLennardJonesBEnergy(list_p, 
				coordinates->matrix,
				electrostaticConstant, 
				cutoff,
				b0,
				b1,
				&vdwPotential, 
				&estPotential);
			list_p = list_p->next;
		}
	}
}

/*
 * List Handler Delegate Methods
 */
 
- (void) handlerDidUpdateList: (AdListHandler*) handler
{
	[self _precomputeParameters];
}

- (void) handlerDidInvalidateList: (AdListHandler*) handler
{
	interactionList = NULL;
}

- (void) handlerDidHandleContentChange: (AdListHandler*) handler
{
	int numberOfElements;

	NSDebugLLog(@"AdGRFNonbondedTerm",
		@"Received handlerDidHandleContentChange message");
	NSDebugLLog(@"AdGRFNonbondedTerm",
		@"Updating affected variables");

	//Free affected instance variables
	[elementProperties release];
	[memoryManager freeArray: partialCharges];
	[memoryManager freeMatrix: parameters];
	
	//Reaquire necessary information
	NSDebugLLog(@"AdGRFNonbondedTerm",
		@"Reinitialising parameters");
	numberOfElements = [system numberOfElements];	
	elementProperties = [[system elementProperties] retain];
	[self _initialiseParameters];		
	
	if(!usingExternalForceMatrix)
	{
		NSDebugLLog(@"AdGRFNonbondedTerm",
			@"Recreating force matrix");
		[memoryManager freeMatrix: forces];
		forces = [memoryManager allocateMatrixWithRows: numberOfElements
				withColumns: 3];
	}

	/*
	 * Reset allowed pairs
	 * We have to use the allowed pairs supplied by
	 * indexSetArrayForCategory since we dont know
	 * if any user supplied pair list is still valid.
	 */
	
	NSDebugLLog(@"AdGRFNonbondedTerm",
		@"Aqurining nonbonded pairs from system");
	[pairs release];
	pairs = [system indexSetArrayForCategory: @"Nonbonded"];
	[pairs retain];

	NSDebugLLog(@"AdGRFNonbondedTerm",
		@"Updating list handler with new pairs");
	[listHandler setAllowedPairs: pairs];
	
	//Recreate list
	
	NSDebugLLog(@"AdGRFNonbondedTerm", @"Recreating list");
	[listHandler createList];
	interactionList = [[listHandler pairList] pointerValue];
	NSDebugLLog(@"AdGRFNonbondedTerm", @"Precomputing parameters");
	[self _precomputeParameters];
	NSDebugLLog(@"AdGRFNonbondedTerm", @"Update complete");
}

/*
 * Accessors
 */

- (double) electrostaticEnergy
{
	return estPotential;
}

- (double) lennardJonesEnergy
{
	return vdwPotential;
}

- (double) energy
{
	return estPotential + vdwPotential;
}

- (NSString*) lennardJonesType
{
	return [[lennardJonesType retain]
		 autorelease];
}

- (double) cutoff
{
	return cutoff;
}

- (void) setCutoff: (double) aDouble
{
	cutoff = aDouble;
	[self _calculateGRFParameters];
	if(listHandler != nil)
		[listHandler setCutoff: cutoff + buffer];
}

- (unsigned int) updateInterval
{
	return updateInterval;
}

- (void) setUpdateInterval: (unsigned int) anInt
{
	updateInterval = anInt;
	if(listHandler != nil)
		[[AdMainLoopTimer mainLoopTimer]
			resetIntervalForMessageWithName: messageId
			to: anInt];
}

- (void) updateList: (BOOL) reset
{
	[listHandler update];
	if(reset)
		[[AdMainLoopTimer mainLoopTimer]
			resetCounterForMessageWithName: messageId];
}

- (void) setExternalForceMatrix: (AdMatrix*) matrix
{
	int numberOfElements;

	numberOfElements = [system numberOfElements];

	//Check matrix has correct dimensions
	if(matrix == NULL)
		[NSException raise: NSInvalidArgumentException
			format: @"Matrix cannot be NULL"];
	else if(matrix->no_rows != numberOfElements)
		[NSException raise: NSInvalidArgumentException
			format: @"Matrix has incorrect number of rows (%d - required %d)",
			matrix->no_rows, numberOfElements];
	else if(matrix->no_columns != 3)
		[NSException raise: NSInvalidArgumentException
			format: @"Matrix has incorrect number of columns"];

	if(!usingExternalForceMatrix)
	{
		[memoryManager freeMatrix: forces];
		usingExternalForceMatrix = YES;
	}

	forces = matrix;
}

- (AdMatrix*) forces
{
	return forces;
}

- (void) clearForces
{
	int i,j;

	for(i=0; i<forces->no_rows; i++)
		for(j=0; j<3; j++)
			forces->matrix[i][j] = 0;
}

/**
Returns YES if the object writes its forces to an external
matrix. NO otherwise.
*/
- (BOOL) usesExternalForceMatrix
{
	return usingExternalForceMatrix;
}

/**
Sets the system the term should be calculated on.
*/
- (void) setSystem: (id) anObject
{
	int numberOfElements;

	//Clear all system related variables
	if(system != nil)
	{
		[elementProperties release];
		[memoryManager freeArray: partialCharges];
		[memoryManager freeMatrix: parameters];
		
		if(!usingExternalForceMatrix)
			[memoryManager freeMatrix: forces];
		
		[system release];
	}

	system = [anObject retain];
	if(system != nil)
	{
		[self _determineLJType];

		numberOfElements = [system numberOfElements];
		elementProperties = [[system elementProperties] retain];
		usingExternalForceMatrix = NO;
		forces = [memoryManager allocateMatrixWithRows: numberOfElements
				withColumns: 3];
				
		//Require parameters and partial charges
		[self _initialiseParameters];		

		//Update handler
		if(listHandler == nil)
		{
			listHandler = [[listHandlerClass alloc] 
					initWithSystem: system
					allowedPairs: nil
					cutoff: cutoff + buffer];
			[listHandler setDelegate: self];
			messageId = [[NSProcessInfo processInfo]
					globallyUniqueString];
			[messageId retain];
			[[AdMainLoopTimer mainLoopTimer] 
				sendMessage: @selector(update)
				toObject: listHandler
				interval: updateInterval
				name: messageId];
		}
		
		[listHandler setSystem: system];
		[self setNonbondedPairs: 
			[system indexSetArrayForCategory: @"Nonbonded"]];
	}		
}

/**
Returns the system the object operates on.
*/
- (id) system
{
	return [[system retain] autorelease];
}

/**
Returns YES if the term can calculate its energy.
*/
- (BOOL) canEvaluateEnergy
{
	return YES;
}

/**
Return YES if the term can calculate forces.
*/
- (BOOL) canEvaluateForces
{
	return YES;
}

- (void) setNonbondedPairs: (NSArray*) nonbondedPairs
{
	//Cant specify pairs if there is no system
	if(system == nil)
		return;

	if(pairs != nil)
		[pairs release];

	pairs = [nonbondedPairs retain];
	[listHandler setAllowedPairs: pairs];
	[listHandler createList];
	interactionList = [[listHandler pairList] pointerValue];
	[self _precomputeParameters];
}

- (NSArray*) nonbondedPairs
{
	return [[pairs retain] autorelease];
}

- (double) epsilonOne
{
	return epsilon1;
}

- (void) setEpsilonOne: (double) value
{
	epsilon1 = value;
	[self _calculateGRFParameters];
}

- (double) epsilonTwo
{
	return epsilon2;
}

- (double) permittivity
{
	return [self epsilonOne];
}

- (void) setEpsilonTwo: (double) value
{
	epsilon2 = value;
	[self _calculateGRFParameters];
}

- (double) kappa
{
	return kappa;
}

- (void) setKappa: (double) value
{
	kappa = value;
	[self _calculateGRFParameters];
}

/**
 Returns a pointer to the beginning of the list of nonbonded interaction pairs the receiver uses.
 See interface definition for more.
 */
- (ListElement*) interactionList
{
	return interactionList;
}

- (id) copyWithZone:(NSZone *)aZone
{
	return [[[self class] alloc]
		initWithSystem: system
			cutoff: cutoff
		updateInterval: updateInterval
		    epsilonOne: epsilon1
		    epsilonTwo: epsilon2
			 kappa: kappa
		nonbondedPairs: nil
	   externalForceMatrix: NULL
	      listHandlerClass: listHandlerClass];
}

@end
