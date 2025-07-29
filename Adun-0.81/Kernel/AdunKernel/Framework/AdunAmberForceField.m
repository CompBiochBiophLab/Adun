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
#include "AdunKernel/AdunAmberForceField.h"

@implementation AdAmberForceField

/******************

Creation & Maintainence

*******************/

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
				nil];

		valueArray = [NSArray arrayWithObjects:
				[NSValue valueWithPointer: &bnd_pot],
				[NSValue valueWithPointer: &ang_pot],
				[NSValue valueWithPointer: &tor_pot],
				[NSValue valueWithPointer: &itor_pot],
				[NSValue valueWithPointer: &vdw_pot],
				[NSValue valueWithPointer: &est_pot],
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

		valueArray = [NSArray arrayWithObjects: @"Amber", 
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
		bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = est_pot= total_energy = 0;
		bonds = angles = torsions = improperTorsions = forceMatrix = accelerationMatrix = NULL;
		reciprocalMasses = NULL;
	
		if(aSystem != nil)
			[self setSystem: aSystem];
	
		if(aTerm != nil)
			[self setNonbondedTerm: aTerm];

		if(aDict != nil)
			[self addCustomTerms: aDict];
	}

	return self;
}

- (void) dealloc
{
	[super dealloc];
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

	bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = est_pot = 0;
	coordinates = [system coordinates]->matrix;

	if(nonbonded && nonbondedTerm != nil)
	{
		[nonbondedTerm evaluateEnergy];
		vdw_pot = [nonbondedTerm lennardJonesEnergy];
		est_pot = [nonbondedTerm electrostaticEnergy];
	}

	if(harmonicBond)
		for(j=0; j < bonds->no_rows; j++)
			AdHarmonicBondEnergy(bonds->matrix[j], coordinates, &bnd_pot);
	
	if(harmonicAngle)
		for(j=0; j < angles->no_rows; j++)
			AdHarmonicAngleEnergy(angles->matrix[j], coordinates, &ang_pot);
	
	if(fourierTorsion)
		for(j=0; j < torsions->no_rows; j++)
			AdFourierTorsionEnergy(torsions->matrix[j], coordinates , &tor_pot);
	
	if(improperTorsion)
		for(j=0; j < improperTorsions->no_rows; j++)
			AdHarmonicImproperTorsionEnergy(improperTorsions->matrix[j], 
				coordinates, 
				&itor_pot);

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

	total_energy += bnd_pot + ang_pot + tor_pot + vdw_pot + est_pot + itor_pot;
	
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

	bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = est_pot = 0;
	coordinates = [system coordinates]->matrix;

/*	if(nonbonded && nonbondedTerm != nil)
	{
		[nonbondedTerm evaluateEnergy];
		vdw_pot = [nonbondedTerm lennardJonesEnergy];
		est_pot = [nonbondedTerm electrostaticEnergy];
	}*/

	if(harmonicBond)
		for(j=0; j < bonds->no_rows; j++)
		{	
			for(i=0; i<2; i++)
				if([elementIndexes containsIndex: bonds->matrix[j][i]])
					evaluateInteraction = YES;

			if(evaluateInteraction)		
				AdHarmonicBondEnergy(bonds->matrix[j], coordinates, &bnd_pot);
			
			evaluateInteraction = NO;
		}	
	
	if(harmonicAngle)
		for(j=0; j < angles->no_rows; j++)
		{	
			for(i=0; i<3; i++)
				if([elementIndexes containsIndex: angles->matrix[j][i]])
					evaluateInteraction = YES;

			if(evaluateInteraction)		
				AdHarmonicAngleEnergy(angles->matrix[j], coordinates, &ang_pot);
			
			evaluateInteraction = NO;
		}	

	if(fourierTorsion)
		for(j=0; j < torsions->no_rows; j++)
		{	
			for(i=0; i<4; i++)
				if([elementIndexes containsIndex: torsions->matrix[j][i]])
					evaluateInteraction = YES;

			if(evaluateInteraction)		
				AdFourierTorsionEnergy(torsions->matrix[j], coordinates , &tor_pot);
			
			evaluateInteraction = NO;
		}	
	
	if(improperTorsion)
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

	total_energy += bnd_pot + ang_pot + tor_pot + vdw_pot + est_pot + itor_pot;
	
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
	
	bnd_pot = ang_pot = tor_pot = itor_pot = vdw_pot = est_pot = 0;
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
			AdHarmonicBondForce(bonds->matrix[j], coordinates, forces, &bnd_pot);

	if(harmonicAngle)
		for(j=0; j < angles->no_rows; j++)
			AdHarmonicAngleForce(angles->matrix[j], coordinates, forces, &ang_pot);

	if(fourierTorsion)
		for(j=0; j < torsions->no_rows; j++)
			AdFourierTorsionForce(torsions->matrix[j], coordinates, forces, &tor_pot);
	
	if(improperTorsion)
		for(j=0; j < improperTorsions->no_rows; j++)
			AdHarmonicImproperTorsionForce(improperTorsions->matrix[j], 
				coordinates,
				forces,
				&itor_pot);

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

	total_energy += bnd_pot + ang_pot + tor_pot + vdw_pot + est_pot + itor_pot;

	NSDebugLLog(@"SimulationLoop", @"Energies %@", 
		[self arrayOfCoreTermEnergies]); 

	[self _updateAccelerations];
	[super evaluateForces];
}

@end
