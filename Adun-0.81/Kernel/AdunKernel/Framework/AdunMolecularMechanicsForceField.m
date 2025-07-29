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
#include "AdunKernel/AdunMolecularMechanicsForceField.h"

@class AdEnzymixForceField;
@class AdMolecularMechanicsForceField;
@class AdCharmmForceField;

static NSArray* forceFields;

BOOL forceFieldDebug = NO;

@implementation AdMolecularMechanicsForceField

+ (void) initialize
{
	static BOOL didInitialize = NO;
	BOOL diagnoseBondedFunctions, diagnoseNonbondedFunctions, diagnoseForceFieldFunctions;
	BOOL checkForceMagnitudes;
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

	if(didInitialize)
		return;
		
	forceFields = [NSArray arrayWithObjects:
			@"Enzymix",
			@"Amber",
			@"Charmm27",
			nil];
	[forceFields retain];

	//Register base debug defaults - turned off
	[userDefaults registerDefaults:
		[NSDictionary dictionaryWithObjectsAndKeys:
			NO, @"DiagnoseForceFieldFunctions",
			NO, @"DiagoseBondedForceFieldFunctions",
			NO, @"DiagnoseNonbondedForceFieldFunctions",
			nil]];
			
	//Now read the values of the above defaults.
	//If the user didnt set their own values then the
	//above values will be returned.
	
	diagnoseForceFieldFunctions = [userDefaults boolForKey: @"DiagnoseForceFieldFunctions"];
	//If this is turned on the bonded and nonbonded diagnosing is turned on by default.
	if(diagnoseForceFieldFunctions)
	{
		diagnoseBondedFunctions = YES;
		diagnoseNonbondedFunctions = YES;
	}
	else
	{
		diagnoseBondedFunctions = [userDefaults boolForKey: 
						@"DiagnoseBondedForceFieldFunctions"];
		diagnoseNonbondedFunctions = [userDefaults boolForKey:
						@"DiagnoseNonbondedForceFieldFunctions"];
	}

	//Turn on the relevant debugging by setting the value of the debug
	//globals in AdForceFieldFunctions.h to 1
	if(diagnoseBondedFunctions)
	{
		NSLog(@"Bonded force field term diagnostics turned on");
		__HarmonicBondForceDebug__ = true;
		__HarmonicBondEnergyDebug__ = true;
		__HarmonicAngleEnergyDebug__ = true;
		__HarmonicAngleForceDebug__ = true;
		__FourierTorsionEnergyDebug__ = true;
		__FourierTorsionForceDebug__ = true;
		__HarmonicImproperTorsionEnergyDebug__ = true;
		__HarmonicImproperTorsionForceDebug__ = true;
		forceFieldDebug = YES;
		AdHarmonicBondDebugInfo();
		AdHarmonicAngleDebugInfo();
		AdFourierTorsionDebugInfo();
		AdHarmonicImproperTorsionDebugInfo();
		
		fflush(stderr);
		
		NSLog(@"Force debug lines contain the force magnitude as a final term\n");
	}
	
	if(diagnoseNonbondedFunctions)
	{
		NSLog(@"Nonbonded force field term diagnostics turned on");
		__NonbondedEnergyDebug__ = true;
		__NonbondedForceDebug__ = true;
		__ShiftedNonbondedForceDebug__ = true;
		__ShiftedNonbondedEnergyDebug__ = true;
		__GRFNonbondedForceDebug__ = true;
		__GRFNonbondedEnergyDebug__ = true;
		forceFieldDebug = YES;
		
		AdNonbondedDebugInfo();
		fflush(stderr);
	}

	checkForceMagnitudes = [userDefaults boolForKey: @"CheckForceMagnitudes"];
	if(checkForceMagnitudes)
	{	
		NSLog(@"Force magnitude checking turned on.");
		NSLog(@"All force mangitudes will be checked for inifities and Nan's");
		__CheckForceMagnitude__ = true;
		forceFieldDebug = YES;
	}
	
	didInitialize = YES;
}

+ (id) classForForceField: (NSString*) forceFieldName
{
	if(![forceFields containsObject: forceFieldName])
	{
		NSWarnLog(@"Unknown force field %@", forceFieldName);
		NSWarnLog(@"Defaulting to enzymix");
		return [AdEnzymixForceField class];
	}	
	else if([forceFieldName isEqual: @"Amber"])
		return [AdMolecularMechanicsForceField class];
	else if([forceFieldName isEqual: @"Enzymix"])
		return [AdEnzymixForceField class];
	else if([forceFieldName isEqual: @"Charmm27"])
		return [AdCharmmForceField class];

	return nil;
}

+ (id) forceFieldForSystem: (AdSystem*) system
{
	Class forceFieldClass;
	NSString* forceFieldName;
	AdDataSource* dataSource;

	dataSource = [system dataSource];
	forceFieldName = [dataSource valueForMetadataKey: @"ForceField"];
	if(forceFieldName == nil)
		return nil;
	
	forceFieldClass = [self classForForceField: forceFieldName];
	if(forceFieldClass == nil)
		return nil;
		
	return [[[forceFieldClass alloc] initWithSystem: system] autorelease];
}

- (id) init
{
	return [self initWithSystem: nil];
}

- (id) initWithSystem: (id) aSystem
{
	return [self initWithSystem: aSystem nonbondedTerm: nil];
}

- (id) initWithSystem: (id) aSystem nonbondedTerm: (AdNonbondedTerm*) aTerm
{
	return [self initWithSystem: aSystem 
		nonbondedTerm: aTerm 
		customTerms: nil];
}

- (id) initWithSystem: (id) system 
	nonbondedTerm: (AdNonbondedTerm*) anObject
	customTerms: (NSDictionary*) aDict
{

	if((self = [super init]))
	{
		//Get the vdw interaction type of the subclass
		vdwInteractionType = [self vdwInteractionType];
		[vdwInteractionType retain];
	}
	
	return self;
}

- (void) dealloc
{
	AdMemoryManager* memoryManager = [AdMemoryManager appMemoryManager];

	[[NSNotificationCenter defaultCenter] 
		removeObserver: self];
	[system release];
	[state release];
	[availableTerms release];
	[customTerms release];
	[customTermNames release];
	[nonbondedTerm release];
	[vdwInteractionType release];
	[memoryManager freeMatrix: bonds];
	[memoryManager freeMatrix: angles];
	[memoryManager freeMatrix: torsions];
	[memoryManager freeMatrix: improperTorsions];
	[memoryManager freeMatrix: forceMatrix];
	[memoryManager freeMatrix: accelerationMatrix];
	[memoryManager freeArray: reciprocalMasses];
	[super dealloc];
}

//Force & Energy calculation methods.
//Here we just flush stderr if debugging is turned on.

- (void) evaluateForces
{
	if(forceFieldDebug)
		fflush(stderr);
}

- (void) evaluateForcesDueToElements: (NSIndexSet*) elementIndexes
{
	if(forceFieldDebug)
		fflush(stderr);
}

- (void) evaluateEnergies
{
	if(forceFieldDebug)
		fflush(stderr);
}

- (void) evaluateEnergiesUsingInteractionsInvolvingElements: (NSIndexSet*) elementIndexes
{
	if(forceFieldDebug)
		fflush(stderr);
}

- (AdMatrix*) evaluateFiniteDifferenceForcesForTerm: (NSString*) term
{
	AdMatrix* coordinates;
	
	//Deactivate all energy terms
	
	//Activate the requested term only
	
	//do finite difference
	/*coordinates = [[self system] coordinates];
	for(i=0; i<coordinates->no_rows; i++)
	{
		for(j=0;j<coordinates->no_columns; j++)
		{
			//Perturb-atom position
			[system object: self willBeginWritingToMatrix: 
		}
	}*/
	
}

//custom term methods

- (void) addCustomTerm: (id) object withName: (NSString*) name
{
	if([object conformsToProtocol: @protocol(AdForceFieldTerm)])
	{
		if([customTerms objectForKey: name] != nil)
		{
			[NSException raise: NSInvalidArgumentException
				format: @"A custom term called %@ already exists." 
				" Remove it before adding a new term with the same name"];
		}
		
		//Custom terms is a dictionry (hash). 
		//This means the keys are not ordered which would lead to a problem
		//for the allTerms/allEnergies methods - they would not return terms in 
		//the same order each time.
		//In order to overcome this we have to keep an additional customTermName array.
		
		[customTerms setObject: object forKey: name];
		[customTermNames addObject: name];
		[availableTerms addObject: name];
		[[state valueForKey: @"CustomTerms"] 
			setObject: [NSNumber numberWithInt: 0]
			forKey: name];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class for custom force object. Must conform to AdForceFieldTerm"];
} 

- (void) addCustomTerms: (NSDictionary*) aDict
{
	NSEnumerator* keyEnum;
	NSString* key;

	keyEnum = [aDict keyEnumerator];
	while((key = [keyEnum nextObject]))
		[self addCustomTerm: [aDict objectForKey: key] 
			withName: key];
}

- (void) setCustomTerms: (NSDictionary*) aDict
{
	NSEnumerator* keyEnum;
	NSString* termName;
	NSMutableArray* oldNames;
	NSMutableDictionary* oldTerms;

	//Remove all previous terms	
	oldTerms = [[customTerms mutableCopy] autorelease];
	oldNames = [[customTermNames mutableCopy] autorelease];
	
	[customTerms removeAllObjects];
	[customTermNames removeAllObjects];
	
	keyEnum = [aDict keyEnumerator];
	while((termName = [keyEnum nextObject]))
	{
		NS_DURING
		{
			[self addCustomTerm: [aDict objectForKey: termName]
				withName: termName];
		}
		NS_HANDLER
		{	
			[customTerms removeAllObjects];
			[customTermNames removeAllObjects];
			//Restore the old terms
			customTerms = [oldTerms retain];
			customTermNames = [oldNames retain];
			[localException raise];
		}
		NS_ENDHANDLER
	}
}

- (void) removeCustomTermWithName: (NSString*) name
{
	[customTerms removeObjectForKey: name];
	[customTermNames removeObject: name];
	[[state valueForKey: @"CustomTerms"]
		removeObjectForKey: name];
	[availableTerms removeObject: name];	
}

//Activating/Deactivating Terms

- (NSArray*) activatedTerms
{
	NSMutableArray* terms;

	terms = [self availableTerms];
	[terms removeObjectsInArray: [self deactivatedTerms]]; 

	return terms;
}

- (NSArray*) deactivatedTerms
{
	return [[[state valueForKey: @"InactiveTerms"] copy] autorelease];
}

- (void) deactivateTerm: (NSString*) termName
{
	if([availableTerms containsObject: termName])
	{
		if(![[state valueForKey: @"InactiveTerms"] containsObject: termName])
		{
			if([termName isEqual: @"HarmonicBond"])
				harmonicBond = NO;
			if([termName isEqual: @"HarmonicAngle"])
				harmonicAngle = NO;
			if([termName isEqual: @"FourierTorsion"])
				fourierTorsion = NO;
			if([termName isEqual: @"HarmonicImproperTorsion"])
				improperTorsion = NO;
			if([termName isEqual: @"Nonbonded"])
				nonbonded = NO;

			[[state valueForKey: @"InactiveTerms"] addObject: termName];
		}
	}
}

- (void) deactivateTermsWithNames: (NSArray*) names
{
	NSEnumerator* termEnum;
	id term;

	termEnum = [names objectEnumerator];
	while((term = [termEnum nextObject]))
		[self deactivateTerm: term];
}

- (void) activateTerm: (NSString*) termName
{
	if([availableTerms containsObject: termName])
	{
		if([[state valueForKey: @"InactiveTerms"] containsObject: termName])
		{
			if([termName isEqual: @"HarmonicBond"])
				harmonicBond = YES;
			if([termName isEqual: @"HarmonicAngle"])
				harmonicAngle = YES;
			if([termName isEqual: @"FourierTorsion"])
				fourierTorsion = YES;
			if([termName isEqual: @"HarmonicImproperTorsion"])
				improperTorsion = YES;
			if([termName isEqual: @"Nonbonded"])
				nonbonded = YES;

			[[state valueForKey: @"InactiveTerms"] removeObject: termName];
		}
	}
}

- (void) activateTermsWithNames: (NSArray*) names
{
	NSEnumerator* termEnum;
	id term;

	termEnum = [names objectEnumerator];
	while((term = [termEnum nextObject]))
		[self activateTerm: term];
}

- (void) clearForces
{
	int i,j;

	for(i=0; i<forceMatrix->no_rows; i++)
		for(j=0; j<3; j++)
			forceMatrix->matrix[i][j] = 0;

	[self _updateAccelerations];		
}

- (AdMatrix*) forces
{
	return forceMatrix;
}

- (AdMatrix*) accelerations
{
	return accelerationMatrix;
}

/********************

Accessors

********************/

- (double) totalEnergy
{
	return total_energy;
}

- (id) availableTerms
{
	return [[availableTerms copy] autorelease];
}

- (NSArray*) arrayOfEnergiesForTerms: (NSArray*) terms notFoundMarker: (id) anObject
{
	int index, count = 0;
	double value;
	NSArray* potentials;
	NSMutableArray* array = [NSMutableArray array];
	NSMutableArray* notFound = [NSMutableArray array];
	NSEnumerator* potentialsEnum, *notFoundEnum;
	NSString* termName;
	id object;

	potentials = [[state valueForKey: @"TermPotentials"]
			objectsForKeys: terms notFoundMarker: anObject];
	potentialsEnum = [potentials objectEnumerator];		
	while((object = [potentialsEnum nextObject]))
	{
		if(object != anObject)
		{
			value = *(double*)[object pointerValue];
			[array addObject: [NSNumber numberWithDouble: value]];
		}
		else
		{
			[array addObject: anObject];
			[notFound addObject: [terms objectAtIndex: count]];
		}
		count++;
	}		

	//Check if any of the terms not found above are custom terms.
	notFoundEnum = [notFound objectEnumerator];
	while(termName = [notFoundEnum nextObject])
	{
		if([customTermNames containsObject: termName])
		{
			object = [customTerms objectForKey: termName];
			if([object canEvaluateEnergy])
			{
				index = [terms indexOfObject: termName];
				[array replaceObjectAtIndex: index 
						 withObject: [NSNumber numberWithDouble: [object energy]]];
			}
		}
	}

	return array;
}

- (NSDictionary*) dictionaryOfEnergiesForTerms: (NSArray*) array
{
	NSArray* energies;

	energies = [self arrayOfEnergiesForTerms: array notFoundMarker: [NSNull null]];
	return [NSDictionary dictionaryWithObjects: energies
		forKeys: array];
}


//FIMXE: Their is an ambiguity in the meaning of 'term'.
//Its refering both to components AND energies.
//For example Nonbonded is listed as an availableTerm.
//but coreTerms returns both vdw and electrostatic contributions - nonbonded is not present

- (NSArray*) allTerms
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* nameEnum;
	NSString* termName;
	id object;
	
	[array addObjectsFromArray: [self coreTerms]];
	nameEnum = [customTermNames objectEnumerator];
	while(termName = [nameEnum nextObject])
	{
		object = [customTerms objectForKey: termName];
		if([object canEvaluateEnergy])
			[array addObject: termName];
	}
	
	return [[array copy] autorelease];
}

- (NSArray*) allEnergies
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* nameEnum;
	NSString* termName;
	id object;
	
	[array addObjectsFromArray: [self arrayOfCoreTermEnergies]];
	nameEnum = [customTermNames objectEnumerator];
	while(termName = [nameEnum nextObject])
	{
		object = [customTerms objectForKey: termName];
		if([object canEvaluateEnergy])
			[array addObject: [NSNumber numberWithDouble: [object energy]]];
	}
	
	return [[array copy] autorelease];
}

- (NSArray*) coreTerms
{
	return [[coreTerms retain] autorelease];
}

- (NSArray*) arrayOfCoreTermEnergies
{
	NSArray* array;

	array = [NSArray arrayWithObjects: 
			[NSNumber numberWithDouble: bnd_pot],
			[NSNumber numberWithDouble: ang_pot],
			[NSNumber numberWithDouble: tor_pot],
			[NSNumber numberWithDouble: itor_pot],
			[NSNumber numberWithDouble: vdw_pot],
			[NSNumber numberWithDouble: est_pot],
			nil];

	return array;
}

- (NSDictionary*) dictionaryOfCoreTermEnergies
{
	NSArray* energies;

	energies = [self arrayOfCoreTermEnergies];
	return [NSDictionary dictionaryWithObjects: energies
		forKeys: coreTerms];
}

- (id) system
{
	return [[system retain] autorelease];
}

- (void) setSystem: (id) object
{
	if(system != nil)
	{
		[system release];
		[[NSNotificationCenter defaultCenter] 
			removeObserver:self name:nil object: system];
		//clean up all variables relating to the last system
		[self _systemCleanUp];
	}

	system = [object retain];
	[self _initialisationForSystem];
	if(nonbondedTerm != nil)
	{
		if(system != [nonbondedTerm system])
			[nonbondedTerm setSystem: system];

		[nonbondedTerm setExternalForceMatrix: forceMatrix];
	}	

	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(_handleSystemContentsChange:)
		name: @"AdSystemContentsDidChangeNotification"
		object: system];
}

- (void) setNonbondedTerm: (AdNonbondedTerm*) aTerm
{
	[nonbondedTerm release];
	nonbondedTerm = aTerm;
	[nonbondedTerm retain];
		
	if(system != nil)	
	{
		if(system != [aTerm system] )
			[aTerm setSystem: system];
		
		[nonbondedTerm setExternalForceMatrix: forceMatrix];
	}		

	[state setObject: NSStringFromClass([aTerm class])
		 forKey: @"NonbondedTerm"];
}

- (AdNonbondedTerm*) nonbondedTerm
{
	return [[nonbondedTerm retain] autorelease];
}

- (NSString*) vdwInteractionType
{
	return @"TypeOneVDWInteraction";
}

- (NSString*) description
{
	int i;
	NSMutableString* description;
	NSDictionary* energies;
	NSArray* array;
	NSEnumerator* termEnum;
	id term, object;
	
	description = [NSMutableString string];
	[description appendFormat: @"ForceField: %@\n", [state objectForKey: @"ForceField"]];
	
	[description appendString: @"Available Terms for computation:\n"];
	for(i=0; i<(int)[availableTerms count]; i++)
		[description appendFormat: @"\t%@\n", [availableTerms objectAtIndex: i]];
	
	[description appendString: @"NonbondedTerm:\n"];
	if(nonbondedTerm == nil)
		[description appendString: @"\tNone\n"];
	else
		[description appendFormat: @"\t%@", [nonbondedTerm description]];
				
	[description appendString: @"CustomTerms:\n"];
	if([customTerms count] == 0)
		[description appendString: @"\tNone\n"];
	else
	{	
		termEnum = [customTerms objectEnumerator];
		while(term = [termEnum nextObject])
			[description appendFormat: @"\t%@\n", [term description]];
	}					
	
	array = [state valueForKey: @"InactiveTerms"];
	if([array count] != 0)
	{
		[description appendString: @"InactiveTerms:\n"];
		for(i=0; i<(int)[array count]; i++)
			[description appendFormat: @"\t%@\n", [array objectAtIndex: i]];
	}		
	
	if(system != nil)
	{
		[description appendFormat: @"System: %@\n", [system systemName]];
		[self evaluateEnergies];
		energies = [self dictionaryOfCoreTermEnergies];
		termEnum = [energies keyEnumerator];
		while(term = [termEnum nextObject])
			[description appendFormat: @"\t%25@: %10.5lf Sim Units\n", 
				term, [[energies objectForKey: term] doubleValue]];
				
		termEnum = [customTerms keyEnumerator];
		while(term = [termEnum nextObject])
		{		
			object = [customTerms objectForKey: term];
			if([object canEvaluateEnergy])
				[description appendFormat: @"\t%25@: %10.5lf Sim Units\n", 
					term, [object energy]];
		}
	}
		
	return description;
}

@end

@implementation AdMolecularMechanicsForceField (PrivateInternals)

/*
 * Resets variables and frees memory associated with the current system.
 * FIXME: Does not handle custom terms properly
 */

- (void) _systemCleanUp
{
	AdMemoryManager* memoryManager = [AdMemoryManager appMemoryManager];

	[availableTerms removeAllObjects];
	[[state valueForKey:@"InactiveTerms"] removeAllObjects];

	[nonbondedTerm setSystem: nil];
	[memoryManager freeMatrix: bonds];
	[memoryManager freeMatrix: angles];
	[memoryManager freeMatrix: torsions];
	[memoryManager freeMatrix: improperTorsions];
	[memoryManager freeMatrix: forceMatrix];
	[memoryManager freeMatrix: accelerationMatrix];
	[memoryManager freeArray: reciprocalMasses];

	harmonicBond = harmonicAngle = fourierTorsion = improperTorsion = nonbonded = NO;
	bnd_pot = ang_pot = tor_pot = vdw_pot = est_pot = itor_pot = total_energy = 0;
	bonds = angles = torsions = improperTorsions = forceMatrix = accelerationMatrix = NULL;
	reciprocalMasses = NULL;
}

- (void) _createReciprocalMassArray
{
	int i;
	NSArray* massArray;
	AdMemoryManager* memoryManager = [AdMemoryManager appMemoryManager];

	massArray = [system elementMasses];
	reciprocalMasses = [memoryManager allocateArrayOfSize: [massArray count]*sizeof(double)];
	for(i=0; i<(int)[massArray count]; i++)
		reciprocalMasses[i] = 1/[[massArray objectAtIndex: i] doubleValue];
}

/*
 * The information provided by AdSystem is in the form of AdDataMatrices.
 * We need to convert this information into a more primitive and efficent
 * form i.e. AdMatrix stuctures, for use with the C force field functions.
 */
- (AdMatrix*) _internalDataStorageForGroups: (AdDataMatrix*) groups parameters: (AdDataMatrix*) parameters
{
	int numberRows, numberColumns;
	AdMatrix* interaction;

	numberRows = [groups numberOfRows];
	numberColumns = [groups numberOfColumns] + [parameters numberOfColumns];

	interaction = [[AdMemoryManager appMemoryManager] 
			allocateMatrixWithRows: numberRows
			withColumns: numberColumns];
	return interaction;		
}

- (void) _initialisationForSystem
{
	int i, j;
	NSArray* interactionTypes;
	AdDataMatrix *groups, *parameters;

	NSDebugLLog(@"AdMolecularMechanicsForceField", 
		@"Begining system initialisation");

	no_of_atoms = [system numberOfElements];

	//allocate a force and acceleration matrix
	forceMatrix = [[AdMemoryManager appMemoryManager]
			allocateMatrixWithRows: no_of_atoms
			withColumns: 3];
	accelerationMatrix = [[AdMemoryManager appMemoryManager]
				allocateMatrixWithRows: no_of_atoms
				withColumns: 3];
	[self _createReciprocalMassArray];	

	/*
	 * Check what interaction types the system provides information for
	 * and which of these are core terms of this force field.
	 * For each one that is a core terms we convert the information
	 * provided into an internal representation which we will use with
	 * the primitive C force field functions.
	 */

	interactionTypes = [system availableInteractions];

	if([interactionTypes containsObject: @"HarmonicBond"])
	{
		harmonicBond = YES;
		groups = [system groupsForInteraction: @"HarmonicBond"];
		parameters = [system parametersForInteraction: @"HarmonicBond"];
		bonds = [self _internalDataStorageForGroups: groups
				parameters: parameters];
		
		for(i=0; i<bonds->no_rows; i++)
		{
			for(j=0; j<2; j++)
				bonds->matrix[i][j] = [[groups elementAtRow: i column: j] doubleValue];

			bonds->matrix[i][2] = [[parameters elementAtRow: i 
						ofColumnWithHeader: @"Constant"] doubleValue];
			bonds->matrix[i][3] = [[parameters elementAtRow: i 
						ofColumnWithHeader: @"Separation"] doubleValue];
		}
		
		[availableTerms addObject: @"HarmonicBond"];
	}
	else
		harmonicBond = NO;	
	
	if([interactionTypes containsObject: @"HarmonicAngle"])
	{
		harmonicAngle = YES;

		groups = [system groupsForInteraction: @"HarmonicAngle"];
		parameters = [system parametersForInteraction: @"HarmonicAngle"];
		angles = [self _internalDataStorageForGroups: groups
				parameters: parameters];
		
		for(i=0; i<angles->no_rows; i++)
		{
			for(j=0; j<(int)[groups numberOfColumns]; j++)
				angles->matrix[i][j] = [[groups elementAtRow: i column: j] doubleValue];

			angles->matrix[i][3] = [[parameters elementAtRow: i 
						ofColumnWithHeader: @"Constant"] doubleValue];
			angles->matrix[i][4] = [[parameters elementAtRow: i 
						ofColumnWithHeader: @"Angle"] doubleValue];
		}
		
		[availableTerms addObject: @"HarmonicAngle"];
	}
	else
		harmonicAngle = NO;	

	if([interactionTypes containsObject: @"FourierTorsion"])
	{
		fourierTorsion = YES;

		groups = [system groupsForInteraction: @"FourierTorsion"];
		parameters = [system parametersForInteraction: @"FourierTorsion"];
		torsions = [self _internalDataStorageForGroups: groups
				parameters: parameters];
		
		for(i=0; i<torsions->no_rows; i++)
		{
			for(j=0; j<(int)[groups numberOfColumns]; j++)
				torsions->matrix[i][j] = [[groups elementAtRow: i column: j] doubleValue];

			torsions->matrix[i][4] = [[parameters elementAtRow: i 
							ofColumnWithHeader: @"Constant"] doubleValue];
			torsions->matrix[i][5] = [[parameters elementAtRow: i 
							ofColumnWithHeader: @"Periodicity"] doubleValue];
			torsions->matrix[i][6] = [[parameters elementAtRow: i 
							ofColumnWithHeader: @"Phase"] doubleValue];
		}
		
		[availableTerms addObject: @"FourierTorsion"];
	}	
	else
		fourierTorsion = NO;	
	
	if([interactionTypes containsObject: @"HarmonicImproperTorsion"])
	{
		improperTorsion = YES;
	
		groups = [system groupsForInteraction: @"HarmonicImproperTorsion"];
		parameters = [system parametersForInteraction: @"HarmonicImproperTorsion"];
		improperTorsions = [self _internalDataStorageForGroups: groups
					parameters: parameters];
		
		for(i=0; i<improperTorsions->no_rows; i++)
		{
			for(j=0; j<(int)[groups numberOfColumns]; j++)
				improperTorsions->matrix[i][j] = [[groups elementAtRow: i column: j] doubleValue];

			improperTorsions->matrix[i][4] = [[parameters elementAtRow: i 
								ofColumnWithHeader: @"Constant"] doubleValue];
			improperTorsions->matrix[i][5] = [[parameters elementAtRow: i 
								ofColumnWithHeader: @"Angle"] doubleValue];
		}
		
		[availableTerms addObject: @"HarmonicImproperTorsion"];
	}	
	else
		improperTorsion = NO;	

	/*
	 * For VDW and Electrostatic interactions simply check
	 * if they exist. The actual calculation will be done by
	 * a nonbonded list handler object
	 */

	if([interactionTypes containsObject: @"CoulombElectrostatic"] &&
		 [interactionTypes containsObject: vdwInteractionType])
	{
		nonbonded = YES;
		[availableTerms addObject: @"Nonbonded"];
	}	
	else
		nonbonded = NO;	
}

/**
Called when we recieve an AdSystemContentsDidChangeNotification
due to the system reloading its data source.
We dont know what exactly changed so we have to reinitialise
everything.
*/

- (void) _handleSystemContentsChange: (NSNotification*) aNotification
{
	NSEnumerator* inactiveTermsEnum;
	NSMutableArray* inactiveTerms;
	NSMutableArray* removedTerms = [NSMutableArray array];
	NSString* termName;
	AdMemoryManager* memoryManager = [AdMemoryManager appMemoryManager];

	/*
	 * 1) Remove the system dependant terms from available terms.
	 * 2) Assume that custom terms (including nonbonded terms) 
	 * will handle their own updating.
	 * 3) Free topology matrices
	 * 4) Reacquire the system topology matrices.
	 * 5) Update inactive terms
	 * 6) Update the custom terms & nonbonded term with new force matrix
	 */

	NSDebugLLog(@"AdMolecularMechanicsForceField", @"System is %@", [system systemName]);
	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Received an system contents change message"); 
	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Currently available terms %@", availableTerms); 

	[availableTerms removeAllObjects];
	
	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Freeing topology and force related matrices");
	
	[memoryManager freeMatrix: bonds];
	[memoryManager freeMatrix: angles];
	[memoryManager freeMatrix: torsions];
	[memoryManager freeMatrix: improperTorsions];
	[memoryManager freeMatrix: forceMatrix];
	[memoryManager freeMatrix: accelerationMatrix];
	[memoryManager freeArray: reciprocalMasses];

	harmonicBond = harmonicAngle = fourierTorsion = improperTorsion = nonbonded = NO;
	bnd_pot = ang_pot = tor_pot = vdw_pot = est_pot = itor_pot = total_energy = 0;
	bonds = angles = torsions = improperTorsions = forceMatrix = accelerationMatrix = NULL;
	reciprocalMasses = NULL;

	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Reaquiring system information");
	
	[self _initialisationForSystem];

	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Rebuilding available terms");
	
	//Add custom terms back into available terms
	[availableTerms addObjectsFromArray: [customTerms allKeys]];

	NSDebugLLog(@"AdMolecularMechanicsForceField", 
		@"Available terms after reinitialising %@", availableTerms);

	//Check if all inactive terms are still present
	//If they are make sure they have the same state 
	inactiveTerms = [state objectForKey: @"InactiveTerms"];
	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Previous inactive terms %@", inactiveTerms); 
	NSDebugLLog(@"AdMolecularMechanicsForceField",
		@"Updating inactive terms and resetting state where necessary");

	inactiveTermsEnum = [inactiveTerms objectEnumerator];
	while((termName = [inactiveTermsEnum nextObject]))
	{
		if(![availableTerms containsObject: termName])
			[removedTerms addObject: termName];
		else
		{
			if([termName isEqual: @"HarmonicBond"])
				harmonicBond = NO;
			if([termName isEqual: @"HarmonicAngle"])
				harmonicAngle = NO;
			if([termName isEqual: @"FourierTorsion"])
				fourierTorsion = NO;
			if([termName isEqual: @"HarmonicImproperTorsion"])
				improperTorsion = NO;
			if([termName isEqual: @"Nonbonded"])
				nonbonded = NO;
		}
	}	
				
	[inactiveTerms removeObjectsInArray: removedTerms];
	
	NSDebugLLog(@"AdMolecularMechanicsForceField", 
		@"Current inactive terms %@", inactiveTerms); 
	NSDebugLLog(@"AdMolecularMechanicsForceField"
		, @"Updating nonbonded term with new force matrix");
	[nonbondedTerm setExternalForceMatrix: forceMatrix];
	NSDebugLLog(@"AdMolecularMechanicsForceField", @"Update complete");
}

- (void) _updateAccelerations
{
	int i,j;

	for(i=0; i<accelerationMatrix->no_rows; i++)
		for(j=0; j<3; j++)
			accelerationMatrix->matrix[i][j] = forceMatrix->matrix[i][j]*reciprocalMasses[i];
}

@end
