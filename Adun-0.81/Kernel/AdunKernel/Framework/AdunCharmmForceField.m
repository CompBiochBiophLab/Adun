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
#include "AdunKernel/AdunCharmmForceField.h"

/**
This category overrides some of the private internals declared in
AdMolecularMechanicsForceField.
They basically add functionality for dealing with extra interactions
(1-4 nonbonded and Urey-Bradely) which Charmm has but other MM force-fields
may no.
It also adds two new method - initalize14 and freeList.
*/
@interface AdCharmmForceField (PrivateInternals)
/**
See super docs.
*/
- (void) _systemCleanUp;
/**
 See super docs.
 */
- (void) _initialisationForSystem;
/**
 See super docs.
 */
- (void) _handleSystemContentsChange: (NSNotification*) aNotification;
/**
Initialises the linked list used for the 1-4 interactions.
*/
- (void) _initialize14;
/**
Frees the list created with the above method.
*/
- (void) _freeList;
@end

@implementation AdCharmmForceField

- (id) initWithSystem: (id) aSystem nonbondedTerm: (AdNonbondedTerm*) aTerm customTerms: (NSDictionary*) aDict
{
	NSArray* valueArray, *keyArray;
	NSDictionary *termPotentials;

	if((self = [super initWithSystem: aSystem nonbondedTerm: aTerm customTerms: aDict]))
	{
		coreTerms = [[NSArray alloc] initWithObjects: 
			     @"HarmonicBond",
			     @"HarmonicAngle",
			     @"FourierTorsion", 
			     @"HarmonicImproperTorsion", 
			     @"TypeTwoVDWInteraction",
			     @"CoulombElectrostatic",
			     @"1-4VDW",
			     @"1-4Coulomb",
			     @"UreyBradley",
			     nil];

		valueArray = [NSArray arrayWithObjects:
			      [NSValue valueWithPointer: &bnd_pot],
			      [NSValue valueWithPointer: &ang_pot],
			      [NSValue valueWithPointer: &tor_pot],
			      [NSValue valueWithPointer: &itor_pot],
			      [NSValue valueWithPointer: &vdw_pot],
			      [NSValue valueWithPointer: &est_pot],
			      [NSValue valueWithPointer: &i14vdw_pot],
			      [NSValue valueWithPointer: &i14est_pot],
			      [NSValue valueWithPointer: &ub_pot],
			      nil];
		termPotentials = [NSDictionary dictionaryWithObjects: valueArray forKeys: coreTerms];		

		keyArray = [NSArray arrayWithObjects:
				@"ForceField", 
				@"NonbondedTerm", 
				@"InactiveTerms", 
				@"TermPotentials",
				@"TotalPotential", 
				@"CustomTerms", 
				 nil];

		valueArray = [NSArray arrayWithObjects: @"Charmm", 
				@"Pure Cutoff",
				[NSMutableArray arrayWithCapacity: 1],
				termPotentials, 
				[NSValue valueWithPointer: &total_energy],
				[NSMutableDictionary dictionaryWithCapacity: 1],
				nil];


		customTerms = [NSMutableDictionary new];
		customTermNames = [NSMutableArray new];
		state = [[NSMutableDictionary dictionaryWithObjects: valueArray forKeys: keyArray] retain];
		availableTerms = [NSMutableArray new];
		bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = est_pot = ub_pot = i14vdw_pot = i14est_pot = total_energy = 0;
		bonds = angles = torsions = improperTorsions = ub =  forceMatrix = accelerationMatrix = NULL;
		reciprocalMasses = NULL;
		
		//Default relative permittivity to use for 1-4 interactions
		//If a nonbonded term is set its permittivity will be used instead.
		relativePermittivity = 1.0;
		//EPSILON is 4*PI*vacuumPermittivity in sim units.
		epsilon_rp = 1.0/(EPSILON*relativePermittivity);
		
		if(aSystem != nil)
			[self setSystem: aSystem];
		
		if(aTerm != nil)
			[self setNonbondedTerm: aTerm];
		
		if(aDict != nil)
			[self addCustomTerms: aDict];
	}
	
	return self;
}


- (NSString*) vdwInteractionType
{
	return @"TypeTwoVDWInteraction";
}

/******************

Public Methods

*******************/

- (void) evaluateEnergies
{
	register int j;
	double potential;
	double **coordinates;
	NSEnumerator* customTermsEnum;	
	id term, customPotentials;


	bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = est_pot = ub_pot= i14vdw_pot = i14est_pot = 0;
	coordinates = [system coordinates]->matrix;

	if(nonbonded && nonbondedTerm != nil)
	{
		[nonbondedTerm evaluateEnergy];
		vdw_pot = [nonbondedTerm lennardJonesEnergy];
		est_pot = [nonbondedTerm electrostaticEnergy];
	}

	if(harmonicBond)
		for(j=0; j < bonds->no_rows; j++)
			AdEnzymixBondEnergy(bonds->matrix[j], coordinates, &bnd_pot);
	
	if(harmonicAngle)
		for(j=0; j < angles->no_rows; j++)
			AdEnzymixAngleEnergy(angles->matrix[j], coordinates, &ang_pot);
	
	if(fourierTorsion)
		for(j=0; j < torsions->no_rows; j++)
			AdFourierTorsionEnergy(torsions->matrix[j], coordinates , &tor_pot);
	
	if(improperTorsion)
		for(j=0; j < improperTorsions->no_rows; j++)
			AdHarmonicImproperTorsionEnergy(improperTorsions->matrix[j], 
				coordinates, 
				&itor_pot);

	if(interaction14)
	{
		list_p = list_14;
		for(j=0; j < noList_14; j++)
		{
			list_p = list_p->next;
			AdCoulombAndLennardJonesBEnergy(list_p,
							coordinates,epsilon_rp,1000,&i14vdw_pot,&i14est_pot);
		}
	}
	
	if(ureyBradley)
	{
		for(j=0; j < ub->no_rows; j++)
			AdEnzymixBondEnergy(ub->matrix[j], coordinates, &ub_pot);
	}

	total_energy = 0;
	if([customTerms count] != 0)
	{
		customPotentials = [state valueForKey: @"CustomTerms"];
		customTermsEnum = [customTerms keyEnumerator];
		while((term = [customTermsEnum nextObject]))
		{	
			[[customTerms objectForKey: term]  evaluateEnergy];
			potential = [[customTerms objectForKey: term] energy];	
			total_energy += potential;
			[customPotentials setValue: [NSNumber numberWithDouble: potential]
				forKey: term];
		}
	}

	total_energy += bnd_pot + ang_pot + tor_pot + vdw_pot + est_pot + itor_pot + ub_pot + i14vdw_pot + i14est_pot;
	
	[super evaluateEnergies];
}

/*
 * Add code to handle force field terms
 * i.e. checking if the respond to evaluateEnergiesUsingInteractionsInvolvingElements:
 * Im not even sure this is an AdForceFieldTerm protocol method
 */
- (void) evaluateEnergiesUsingInteractionsInvolvingElements: (NSIndexSet*) elementIndexes
{
	BOOL evaluateInteraction = NO;
	register int j, i;
	double **coordinates;

	bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = ub_pot = est_pot = i14vdw_pot = i14est_pot = 0;
	coordinates = [system coordinates]->matrix;

/*	if(nonbonded && nonbondedTerm != nil)
	{
		[nonbondedTerm evaluateEnergy];
		vdw_pot = [nonbondedTerm lennardJonesEnergy];
		est_pot = [nonbondedTerm electrostaticEnergy];
	}*/

	if(harmonicBond)
	{
		for(j=0; j < bonds->no_rows; j++)
		{	
			for(i=0; i<2; i++)
				if([elementIndexes containsIndex: bonds->matrix[j][i]])
					evaluateInteraction = YES;
			
			if(evaluateInteraction)		
				AdEnzymixBondEnergy(bonds->matrix[j], coordinates, &bnd_pot);
			
			evaluateInteraction = NO;
		}	
	}
		
	if(harmonicAngle)
	{
		for(j=0; j < angles->no_rows; j++)
		{	
			for(i=0; i<3; i++)
				if([elementIndexes containsIndex: angles->matrix[j][i]])
					evaluateInteraction = YES;
			
			if(evaluateInteraction)		
				AdEnzymixAngleEnergy(angles->matrix[j], coordinates, &ang_pot);
			
			evaluateInteraction = NO;
		}	
	}
		
	if(fourierTorsion)
	{
		for(j=0; j < torsions->no_rows; j++)
		{	
			for(i=0; i<4; i++)
				if([elementIndexes containsIndex: torsions->matrix[j][i]])
					evaluateInteraction = YES;
			
			if(evaluateInteraction)		
				AdFourierTorsionEnergy(torsions->matrix[j], coordinates , &tor_pot);
			
			evaluateInteraction = NO;
		}	
	}
		
	if(improperTorsion)
	{
		for(j=0; j < improperTorsions->no_rows; j++)
		{	
			for(i=0; i<4; i++)
				if([elementIndexes containsIndex: improperTorsions->matrix[j][i]])
					evaluateInteraction = YES;
			
			if(evaluateInteraction)		
				AdHarmonicImproperTorsionEnergy(improperTorsions->matrix[j], 
								coordinates, 
								&itor_pot);
			
			evaluateInteraction = NO;
		}	
	}
		
	if(interaction14)
	{
		list_p = list_14;
		for(j=0; j < noList_14; j++)
		{	
			list_p = list_p->next;
			if( ( [elementIndexes containsIndex: list_p->bond[0]] ) || 
			   ( [elementIndexes containsIndex: list_p->bond[1]] ) )
				evaluateInteraction = YES;
			
			if(evaluateInteraction)		
				AdCoulombAndLennardJonesBEnergy(list_p, coordinates,
								epsilon_rp, 1000,
								&i14vdw_pot, &i14est_pot);
			
			evaluateInteraction = NO;
		}	
	}
	
	if(ureyBradley)
	{
		for(j=0; j < ub->no_rows; j++)
		{	
			for(i=0; i<2; i++)
				if([elementIndexes containsIndex: ub->matrix[j][i]])
					evaluateInteraction = YES;
			
			if(evaluateInteraction)		
				AdEnzymixBondEnergy(ub->matrix[j], coordinates, &ub_pot);
			
			evaluateInteraction = NO;
		}	
	}
		
	total_energy = 0;
	/*if([customTerms count] != 0)
	{
		customPotentials = [state valueForKey: @"CustomTerms"];
		customTermsEnum = [customTerms keyEnumerator];
		while(term = [customTermsEnum nextObject])
		{	
			[[customTerms objectForKey: term]  evaluateEnergy];
			potential = [[customTerms objectForKey: term] energy];	
			total_energy += potential;
			[customPotentials setValue: [NSNumber numberWithDouble: potential]
				forKey: term];
		}
	}*/

	total_energy += bnd_pot + ang_pot + tor_pot + vdw_pot + ub_pot + est_pot + itor_pot + i14vdw_pot + i14est_pot;
	
	[super evaluateEnergiesUsingInteractionsInvolvingElements: elementIndexes];
}

- (void) evaluateForces
{
	register int j, i;
	double potential;
	AdMatrix* customForce;
	double **coordinates, **forces;
	NSEnumerator* customTermsEnum;	
	id term, customPotentials;
	
	//Clear the force matrix
	[self clearForces];
	
	bnd_pot = ang_pot = tor_pot = itor_pot = ub_pot = vdw_pot = est_pot = i14vdw_pot = i14est_pot = 0;
	coordinates = [system coordinates]->matrix;
	forces = forceMatrix->matrix;

	NSDebugLLog(@"SimulationLoop",
		@"Begining force calculation for %@", 
		[system systemName]);

	if(nonbonded && nonbondedTerm != nil)
	{
		[nonbondedTerm evaluateForces];
		vdw_pot = [nonbondedTerm lennardJonesEnergy];
		est_pot = [nonbondedTerm electrostaticEnergy];
	}

	if(harmonicBond)
		for(j=0; j < bonds->no_rows; j++)
			AdEnzymixBondForce(bonds->matrix[j], coordinates, forces, &bnd_pot);

	if(harmonicAngle)
		for(j=0; j < angles->no_rows; j++)
			AdEnzymixAngleForce(angles->matrix[j], coordinates, forces, &ang_pot);

	if(fourierTorsion)
		for(j=0; j < torsions->no_rows; j++)
			AdFourierTorsionForce(torsions->matrix[j], coordinates, forces, &tor_pot);
	
	if(improperTorsion)
		for(j=0; j < improperTorsions->no_rows; j++)
			AdHarmonicImproperTorsionForce(improperTorsions->matrix[j], 
				coordinates,
				forces,
				&itor_pot);

	if(interaction14)
	{
		list_p = list_14;
		for(j=0; j < noList_14; j++)
		{
			list_p = list_p->next;
			AdCoulombAndLennardJonesBForce(list_p,
						       coordinates,forces,epsilon_rp,1000,&i14vdw_pot,&i14est_pot);
		}
	} 

	if(ureyBradley)
		for(j=0; j < ub->no_rows; j++)
			AdEnzymixBondForce(ub->matrix[j], coordinates, forces, &ub_pot);

	total_energy = 0;
	if([customTerms count] != 0)
	{
		customPotentials = [state valueForKey: @"CustomTerms"];
		customTermsEnum = [customTerms keyEnumerator];
		while((term = [customTermsEnum nextObject]))
		{	
			[[customTerms objectForKey: term]  evaluateForces];
			potential = [[customTerms objectForKey: term] energy];	
			total_energy += potential;
			[customPotentials setValue: [NSNumber numberWithDouble: potential]
				forKey: term];
					
			customForce = [[customTerms objectForKey: term] forces];
			for(i=0; i<customForce->no_rows; i++)
				for(j=0; j<3; j++)
					forces[i][j] += customForce->matrix[i][j];
		}
	}

	total_energy += bnd_pot + ang_pot + tor_pot + vdw_pot + est_pot + ub_pot + itor_pot + i14vdw_pot + i14est_pot;

	NSDebugLLog(@"SimulationLoop", @"Energies %@", [self arrayOfCoreTermEnergies]); 

	[self _updateAccelerations];
	[super evaluateForces];
}

- (void) dealloc
{
   [self _freeList];
   [super dealloc];
}

- (void) deactivateTerm: (NSString*) termName
{
	[super deactivateTerm:  termName ];
	if([availableTerms containsObject: termName])
	{
		if(![[state valueForKey: @"InactiveTerms"] containsObject: termName])
		{
			if([termName isEqual: @"1-4Interaction"])
				interaction14 = NO;
			if([termName isEqual: @"UreyBradley"])
				ureyBradley = NO;
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
	[super activateTerm:  termName ];
	if([availableTerms containsObject: termName])
	{
		if([[state valueForKey: @"InactiveTerms"] containsObject: termName])
		{
			if([termName isEqual: @"1-4Interaction"])
				interaction14 = YES;
			if([termName isEqual: @"UreyBradley"])
				ureyBradley = YES;
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

/********************

Accessors

********************/


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
		 [NSNumber numberWithDouble: i14vdw_pot],
		 [NSNumber numberWithDouble: i14est_pot],
		 [NSNumber numberWithDouble: ub_pot],
		 nil];

	return array;
}

- (void) setNonbondedTerm: (AdNonbondedTerm*) aTerm
{
	[super setNonbondedTerm: aTerm];
	
	//Get the permittivity set for the nonbonded term
	//to use with the 1-4 interactions.
	if(nonbondedTerm != nil)
	{
		relativePermittivity = [nonbondedTerm permittivity];
		//EPSILON is 4*PI*vacuumPermittivity in sim units.
		epsilon_rp = 1.0/(EPSILON*relativePermittivity);
	}		
}

@end

@implementation  AdCharmmForceField (PrivateInternals)

- (void) _systemCleanUp
{
	[ super _systemCleanUp ];
	[ self _freeList];
}

- (void) _initialisationForSystem
{
	int i;
	NSArray* interactionTypes;
	AdDataMatrix *groups, *parameters;
	
	[ super _initialisationForSystem ];
	interactionTypes = [system availableInteractions];
	
	if([interactionTypes containsObject: @"1-4Interaction"])
	{
		interaction14 = YES;
		[ self _initialize14 ];
		[availableTerms addObject: @"1-4Interaction"];
	}
	else
		interaction14 = NO;	
	
	if([interactionTypes containsObject: @"UreyBradley"])
	{
		ureyBradley = YES;
		groups = [system groupsForInteraction: @"UreyBradley"];
		parameters = [system parametersForInteraction: @"UreyBradley"];
		ub = [self _internalDataStorageForGroups: groups
					      parameters: parameters];
		
		for(i=0; i<ub->no_rows; i++)
		{
			ub->matrix[i][0] = [[groups elementAtRow: i column: 0] doubleValue];
			ub->matrix[i][1] = [[groups elementAtRow: i column: 2] doubleValue];
			ub->matrix[i][2] = [[parameters elementAtRow: i 
						  ofColumnWithHeader: @"Constant"] doubleValue];
			ub->matrix[i][3] = [[parameters elementAtRow: i 
						  ofColumnWithHeader: @"Separation"] doubleValue];
		}
		
		[availableTerms addObject: @"UreyBradley"];
	}
	else
		ureyBradley = NO;
}

- (void) _handleSystemContentsChange: (NSNotification*) aNotification
{
	NSEnumerator* inactiveTermsEnum;
	NSMutableArray* inactiveTerms;
	NSString* termName;
	AdMemoryManager* memoryManager = [AdMemoryManager appMemoryManager];
	
	[super _handleSystemContentsChange: aNotification ];
	[memoryManager freeArray: ub];
	[self _freeList];
	
	interaction14 = ureyBradley = NO;
	ub_pot = i14vdw_pot = i14est_pot = 0;
	ub = NULL;
	
	inactiveTerms = [state objectForKey: @"InactiveTerms"];
	inactiveTermsEnum = [inactiveTerms objectEnumerator];
	while((termName = [inactiveTermsEnum nextObject]))
	{
		if([termName isEqual: @"1-4Interaction"])
			interaction14 = NO;
		if([termName isEqual: @"UreyBradley"])
			ureyBradley = NO;
	}					
}

- (void) _initialize14
{
	int i,no14;
	int atom1, atom2;
	AdDataMatrix* elementProperties;
	NSArray *partialCharge;
	AdDataMatrix *groups14, *parameters14;
	NSArray *row;
	double eps,rmin,q1,q2;
	ListElement *endin_p;
	
	list_14 =  (ListElement*)malloc(sizeof(ListElement));
	endin_p = AdLinkedListCreate(list_14);
	elementProperties = [system elementProperties];
	
	//get the parameters for Coulomb interaction
	partialCharge = [elementProperties columnWithHeader: @"PartialCharge"];
	//get scaled parameters
	groups14 = [system groupsForInteraction: @"1-4Interaction"];
	parameters14 = [system parametersForInteraction: @"1-4Interaction"];
	no14 = [ groups14 numberOfRows ];
	//build a linked list for the interaction 
	for(i=0; i<no14; i++)
	{
		row = [groups14 row: i ];
		atom1 = [[row objectAtIndex: 0 ] intValue];
		atom2 = [[row objectAtIndex: 1 ] intValue];
		row = [parameters14 row: i];
		q1 = [[partialCharge objectAtIndex: atom1 ] doubleValue];
		q2 = [[partialCharge objectAtIndex: atom2 ] doubleValue];
		eps = [[row objectAtIndex: 0 ] doubleValue];
		rmin = [[row objectAtIndex: 1 ] doubleValue];
		
		list_p = (ListElement*)malloc(sizeof(ListElement));         
		list_p->bond[0] = atom1;
		list_p->bond[1] = atom2;
		list_p->length = 0.0;
		list_p->params[0] = eps;
		list_p->params[1] = rmin;
		list_p->params[2] = (q1*q2);
		AdSafeLinkedListAdd(list_p, endin_p, 0);
	}
	noList_14=AdLinkedListCount(list_14) - 1;
	return;
}

- (void) _freeList
{
	ListElement *holder;
	//if in_p is initalised a list exists

	//TODO: Create list free function
	if(list_14 != NULL)
	{
		list_p = list_14;
		while(list_p->next != NULL)	
		{		
			holder = list_p->next;
			free(list_p);
			list_p= holder;
		}
		free(list_p);	
		list_14 = NULL;
	}
}	

@end
