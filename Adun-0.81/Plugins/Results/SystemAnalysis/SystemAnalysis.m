/*
   Project: SystemAnalysis

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2007-03-20 by michael johnston

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

#include "SystemAnalysis.h"
#include "math.h"

@implementation SystemAnalysis

- (void) updateProgressToStep: (int) completedSteps 
		ofTotalSteps: (int) steps 
		withMessage: (NSString*) message
{
	NSMutableDictionary* notificationInfo;

	notificationInfo = [NSMutableDictionary dictionary];
	[notificationInfo setObject: [NSNumber numberWithDouble: steps]
		forKey: @"ULAnalysisPluginTotalSteps"];
	[notificationInfo setObject: message
		forKey: @"ULAnalysisPluginProgressMessage"];
	[notificationInfo setObject: [NSNumber numberWithDouble: completedSteps]
		forKey: @"ULAnalysisPluginCompletedSteps"];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"ULAnalysisPluginDidCompleteStepNotification"
		object: self
		userInfo: notificationInfo];
}

- (NSArray*) _numberedResidues
{
	int i;
	id obj;
	NSMutableArray *residues = [NSMutableArray array];

	[[dataSource groupProperties]
		addColumnWithHeader: @"Residue Name"
		toArray: residues];
			
/*	for(i=0; i<(int)[residues count]; i++)
	{
		obj = [NSString stringWithFormat: @"%@%d",
			[residues objectAtIndex: i], i];
		[residues replaceObjectAtIndex: i withObject: obj];
	}*/	
	
	return residues;
}

//Default implementation
- (BOOL) checkInputs: (NSArray*) inputs error: (NSError**) error
{
	return YES;
}

- (NSDictionary*) pluginOptions: (NSArray*) input 
{
	NSMutableDictionary* mainMenu = [NSMutableDictionary newNodeMenu: NO];
	NSMutableDictionary* residueMenu = [NSMutableDictionary newLeafMenu];
	NSMutableDictionary* interactionsMenu = [NSMutableDictionary newLeafMenu];
	NSMutableDictionary* limitsMenu = [NSMutableDictionary newNodeMenu: NO];
	NSMutableDictionary* unitsMenu = [NSMutableDictionary newLeafMenu];
	NSMutableArray* interactions;
	NSArray *residues;
	
	dataSource = [input objectAtIndex: 0];
	residues = [self _numberedResidues];
	[residueMenu addMenuItem: @"All"];
	[residueMenu addMenuItems: residues]; 	
	[residueMenu setDefaultSelection: @"All"];
	[residueMenu setSelectionMenuType: @"Multiple"];	

	interactions = [[[dataSource availableInteractions]
				mutableCopy] autorelease];

	//FIXME: Remove Coloumb Electrostatic & VDW since
	//they cant be computed yet.
	
	[interactions removeObject: @"CoulombElectrostatic"];
	[interactions removeObject: @"TypeOneVDWInteraction"];
	[interactions removeObject: @"TypeTwoVDWInteraction"];

	[interactionsMenu addMenuItems: interactions];
	[interactionsMenu setDefaultSelections: interactions];
	[interactionsMenu setSelectionMenuType: @"Multiple"];	

	[limitsMenu addMenuItem: @"EnergyThreshold" withValue: @"1"];
	
	[unitsMenu addMenuItems: 
		[NSArray arrayWithObjects: 
			@"Simulation",
			@"KCal per mol",
			@"J per mol",
			nil]];
	[unitsMenu setDefaultSelection: @"KCal per mol"];

	[mainMenu addMenuItem: @"Units" withValue: unitsMenu];
	[mainMenu addMenuItem: @"Residues" withValue: residueMenu];
	[mainMenu addMenuItem: @"Interactions" withValue: interactionsMenu];
	[mainMenu addMenuItem: @"Limits" withValue: limitsMenu];
	
	return  mainMenu;
}

- (id) init
{
	if(self == [super init])
	{
		infoDict = [[NSBundle bundleForClass: [self class]]
				infoDictionary];
		[infoDict retain];	
		forceFields = [NSDictionary dictionaryWithObjectsAndKeys:
				[AdEnzymixForceField class], @"Enzymix", 
				[AdCharmmForceField class], @"Charmm27",
				[AdAmberForceField class], @"Amber", 
				nil];
		[forceFields retain];
		conversionFactors = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithDouble: 1.0], @"Simulation",
					[NSNumber numberWithDouble: STCAL], @"KCal per mol",
					[NSNumber numberWithDouble: STJMOL], @"J per mol",
					nil];
		[conversionFactors retain];		
	}

	return self;
}

- (void) dealloc
{
	[conversionFactors release];
	[infoDict release];
	[forceFields release];
	[super dealloc];
}	

- (NSArray*) _convertEnergies: (NSArray*) energies to: (NSString*) unit
{
	int i;
	double value, conversionFactor;
	NSMutableArray* convertedEnergies = [NSMutableArray array];

	if([unit isEqual: @"Simulation"])
		return energies;

	conversionFactor = [[conversionFactors objectForKey: unit]
				doubleValue];
	
	for(i=0; i<(int)[energies count]; i++)
	{
		value = [[energies objectAtIndex: i]
				doubleValue];
		value *= conversionFactor;
		[convertedEnergies addObject: 
			[NSNumber numberWithDouble: value]];
	}

	return convertedEnergies;
}

/**
Creates a matrix with the following columns
Atom Number, PDBName, Residue Number, Residue Name 
which has rows for each atom.
*/
- (AdMutableDataMatrix*) createResiduesMatrix
{
	int i;
	int index, residueNo, atomsInResidue, offset;
	NSMutableArray* atomIndexes, *residueNames, *residueIndexes;
	NSMutableArray* headers;
	NSEnumerator* residueEnum;
	NSString *residue;
	AdMutableDataMatrix* matrix;
	
	residueNo = atomsInResidue = offset = 0;
	headers = [NSMutableArray arrayWithObjects:
		   @"Index", @"PDBName", @"ResidueName", @"ResidueNumber", nil];	
	matrix = [AdMutableDataMatrix new];
	[matrix autorelease];
	
	elementProperties = [dataSource elementProperties];
	groupProperties = [dataSource groupProperties];

	//Create array for atom indexes
	atomIndexes = [NSMutableArray new];
	for(i=0; i<[elementProperties numberOfRows]; i++)
		[atomIndexes addObject: [NSNumber numberWithInt: i]];
		
	[matrix extendMatrixWithColumn: atomIndexes];
	[matrix extendMatrixWithColumn: [elementProperties columnWithHeader: @"PDBName"]];
	[atomIndexes release];
	
	residueNo = offset = 0;
	residueNames = [NSMutableArray new];
	residueIndexes = [NSMutableArray new];
	residueEnum = [allResidues objectEnumerator];
	while(residue = [residueEnum nextObject])
	{
		atomsInResidue = [[groupProperties elementAtRow: residueNo
					     ofColumnWithHeader: @"Atoms"]
				  intValue];
	
		for(index=offset; index < offset + atomsInResidue; index++)
		{
			[residueNames addObject: residue];
			[residueIndexes addObject: [NSNumber numberWithInt: residueNo]];
		}
		
		offset += atomsInResidue;
		residueNo++;
	}
	
	[matrix extendMatrixWithColumn: residueNames];
	[matrix extendMatrixWithColumn: residueIndexes];
	[matrix setColumnHeaders: headers];
	[residueNames release];
	[residueIndexes release];
	
	return matrix;
}

/**
Set up some variables for the atom contributions calculation
*/
- (void) _setUp: (NSDictionary*) opt
{
	NSMutableArray* headers;

	headers = [NSMutableArray arrayWithObjects:
			@"Index", @"PDBName", @"ForceFieldName", @"ResidueName", @"ResidueNumber", @"TotalEnergy", nil];
	[headers addObjectsFromArray:
		[opt valueForKeyPath: @"Interactions.Selection"]];	
	atomContributions = [[AdMutableDataMatrix alloc] 
				initWithNumberOfColumns: [headers count]
				columnHeaders: headers
				columnDataTypes: nil];
	[atomContributions setName: @"AtomContributions"];
	[atomContributions autorelease];
	elementProperties = [dataSource elementProperties];
	groupProperties = [dataSource groupProperties];

	//Variables for tracking the current residue
	allResidues = [self _numberedResidues];
	selectedResidues = [opt valueForKeyPath: @"Residues.Selection"];
	if([selectedResidues containsObject: @"All"])
		selectedResidues = allResidues;

	//Energy vars
	energyThreshold = [[opt valueForKeyPath: @"Limits.EnergyThreshold"]
				doubleValue];
	
	totalSteps = [selectedResidues count];
}

- (void) _atomContributions: (NSDictionary*) opt
{
	int index, residueNo, atomsInResidue, offset;
	int count;
	double totalEnergy;
	NSArray* energies;
	NSMutableArray* array = [NSMutableArray array];
	NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
	NSEnumerator* residueEnum;
	NSString *residue;

	residueNo = atomsInResidue = offset = count = 0;
	[self _setUp: opt];
	residueEnum = [allResidues objectEnumerator];
	while(residue = [residueEnum nextObject])
	{
		atomsInResidue = [[groupProperties elementAtRow: residueNo
					ofColumnWithHeader: @"Atoms"]
					intValue];
		if([selectedResidues containsObject: residue])
		{
			[self updateProgressToStep: count 
					ofTotalSteps:  totalSteps
					withMessage: residue];

			for(index=offset; index < offset + atomsInResidue; index++)
			{
				//Calculate atoms energies
				[indexSet addIndex: index];
				[forceField evaluateEnergiesUsingInteractionsInvolvingElements: indexSet];
				totalEnergy = [forceField totalEnergy];
				totalEnergy *= [[conversionFactors objectForKey: energyUnit] 
							doubleValue];

				if(fabs(totalEnergy) > energyThreshold)
				{
					energies = [forceField arrayOfEnergiesForTerms: 
								[opt valueForKeyPath: @"Interactions.Selection"] 
							notFoundMarker: @"None"];
					energies = [self _convertEnergies: energies to: energyUnit];

					//Create the row entry for the atom
					[array addObject: [NSNumber numberWithInt: index]];
					[array addObject: 
						[elementProperties elementAtRow: index
							ofColumnWithHeader: @"PDBName"]];
					[array addObject:
						[elementProperties elementAtRow: index 
							ofColumnWithHeader: @"ForceFieldName"]];
					[array addObject: residue];
					[array addObject: [NSNumber numberWithInt: residueNo]];
					[array addObject: [NSNumber numberWithDouble: totalEnergy]];
					[array addObjectsFromArray: energies];
					[atomContributions extendMatrixWithRow: array];
				}
				else if(isnan(totalEnergy))
				{
					[returnString appendFormat: 
						@"Error - energy for atom %d (%@, %@) evaluated to NAN\n",
						index, 
						residue,
						[elementProperties 
							elementAtRow: index
							ofColumnWithHeader: @"PDBName"]];
				}			

				//Update for next iteration
				[array removeAllObjects];
				[indexSet removeAllIndexes];
			}
			count++;
		}	

		offset += atomsInResidue;
		residueNo++;
	}
	
	[self updateProgressToStep: totalSteps
			ofTotalSteps:  totalSteps
			withMessage: @"Complete"];
}

- (void) _addAtomNames: (AdMutableDataMatrix*) matrix
{
	int i, j, numberOfColumns;
	NSMutableArray *array = [NSMutableArray new];
	NSString* name;
	
	numberOfColumns = (int)[matrix numberOfColumns];
	for(i=0; i<numberOfColumns; i++)
	{
		[matrix addColumn: i toArray: array];
		for(j=0; j < (int)[array count]; j++)
		{
			name = [elementProperties elementAtRow: 
					[[array objectAtIndex: j] intValue]
				ofColumnWithHeader: @"PDBName"];
			[array replaceObjectAtIndex: j
				withObject: name];
		}
		[matrix extendMatrixWithColumn: array];
		[matrix setHeaderOfColumn: [matrix numberOfColumns] -1
			to: [NSString stringWithFormat: @"PDB Name %d", i]];
		[array removeAllObjects];
	}
}

- (void) _addParameters: (AdMutableDataMatrix*) matrix interaction: (NSString*) interaction
{
	int i;
	NSMutableArray *array = [NSMutableArray new];
	id parameters;

	parameters = [dataSource parametersForInteraction: interaction];
	for(i=0; i<(int)[parameters numberOfColumns]; i++)
	{
		[parameters addColumn: i toArray: array];
		[matrix extendMatrixWithColumn: array];
		[array removeAllObjects];
		[matrix setHeaderOfColumn: [matrix numberOfColumns] -1
			to: [[parameters columnHeaders] objectAtIndex: i]];
	}
}

- (void) _addInteractionData: (AdDataSet*) dataSet
{
	NSEnumerator* interactionEnum;
	AdMutableDataMatrix* groups;
	id interaction;

	interactionEnum = [[dataSource availableInteractions] 
				objectEnumerator];
				
	while(interaction = [interactionEnum nextObject])
	{
		groups = [[dataSource groupsForInteraction: interaction] 
				mutableCopy];

		if(groups != nil)
		{
			[self _addAtomNames: groups];
			[self _addParameters: groups interaction: interaction];
			[dataSet addDataMatrix: groups];
		}	
	}
}

- (void) _addSolvationData: (AdDataSet*) dataSet
{
	int i, numberOfColumns;
	NSEnumerator* columnEnum;
	NSString* columnName;
	NSArray* array;
	AdPureNonbondedTerm* nonbondedTerm;
	AdSmoothedGBTerm* gbTerm;
	AdDataMatrix* solvationData;
	AdMutableDataMatrix *matrix;
	
	nonbondedTerm = [[AdPureNonbondedTerm alloc] 
				initWithSystem: system 
				cutoff: 30 
				updateInterval: 10 
				permittivity: 1
				nonbondedPairs: nil 
				externalForceMatrix: NULL];
	[nonbondedTerm evaluateEnergy];			
				
	gbTerm = [[AdSmoothedGBTerm alloc] 
			initWithSystem: system 
			nonbondedTerm: nonbondedTerm 
			smoothingLength: 0.3 
			solventPermittivity: 80 
			tensionCoefficient: 0.003];
	
	solvationData = [gbTerm selfEnergyData];
	
	matrix = [self createResiduesMatrix];
	columnEnum = [[solvationData columnHeaders] objectEnumerator];
	numberOfColumns = [matrix numberOfColumns];
	i = 0;
	while(columnName = [columnEnum nextObject])
	{
		//Convert everything except born radius and sasa
		if([columnName isEqual: @"Born Radius"] || [columnName isEqual: @"SASA"])
		{
			array = [solvationData columnWithHeader: columnName];
		}
		else
		{
			array = [self _convertEnergies: [solvationData columnWithHeader: columnName] 
					to: energyUnit];
		}
		
		[matrix extendMatrixWithColumn: array];
		[matrix setHeaderOfColumn: i + numberOfColumns 
			to: [solvationData headerForColumn: i]];	
		i++;	
	}
	
	[matrix setName: @"Solvation Data"];
	solvationData = [[matrix copy] autorelease];
	
	[dataSet addDataMatrix: solvationData];
	
	[gbTerm release];
	[nonbondedTerm release];
}

- (NSDictionary*) processInputs: (NSArray*) anArray userOptions: (NSDictionary*) opt 
{
	int i;
	NSString* type;
	NSMutableDictionary* resultsDict = [NSMutableDictionary dictionary];
	NSMutableArray* inactiveTerms = [NSMutableArray array];
	NSMutableArray* array;
	AdDataSet* dataSet;
	AdDataMatrix* properties;
	AdMutableDataMatrix* matrix;

	returnString = [NSMutableString new];
	dataSource = [anArray objectAtIndex: 0];
	dataSet = [[AdDataSet alloc] 
			initWithName: [dataSource name]
			inputReferences: nil
			dataGeneratorName: @"SystemAnalysis"
			dataGeneratorVersion: [infoDict objectForKey: @"PluginVersion"]];

	energyUnit = [[opt valueForKeyPath: @"Units.Selection"]
			objectAtIndex: 0];
	//Create a system
	system = [[AdSystem alloc]
			initWithDataSource: dataSource
			name: nil
			initialTemperature: 300
			seed: 10
			centre: nil
			removeTranslationalDOF: YES];
	type = [[dataSource allData] objectForKey: @"ForceField"];

	if(type == nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"System created with unknown force field"];
	
	forceField = [[[forceFields objectForKey: type] alloc]
			initWithSystem: system];
	
	//Deactivate the interactions that werent selected.
	[inactiveTerms addObjectsFromArray: [dataSource availableInteractions]];
	[inactiveTerms 	removeObjectsInArray: 
		[opt valueForKeyPath: @"Interactions.Selection"]];
	[forceField deactivateTermsWithNames: inactiveTerms];
		
	[self _atomContributions: opt];	

	[dataSet addDataMatrix: atomContributions];
	[dataSet setValue: energyUnit forMetadataKey: @"EnergyUnit"];
	[dataSet setValue: type forMetadataKey: @"ForceField"];
	[resultsDict setObject: [NSArray arrayWithObject: dataSet] 
		forKey: @"ULAnalysisPluginDataSets"];

	//Add properties matrix - but first extend with residue and 
	//number data.
	properties = [dataSource elementProperties];
	matrix = [AdMutableDataMatrix new];
	[matrix setName: @"Atom Properties"];
	
	array = [NSMutableArray new];
	for(i=0; i < [properties numberOfRows]; i++)
		[array addObject: [NSNumber numberWithInt: i]];
		
	[matrix extendMatrixWithColumn: array];
	[matrix setHeaderOfColumn: 0 to: @"Index"];
	[array release];
	
	for(i=0; i < [properties numberOfColumns]; i++)
	{
		[matrix extendMatrixWithColumn: [properties column: i]];
		[matrix setHeaderOfColumn: i + 1 to: [properties headerForColumn: i]];
	}
	[dataSet addDataMatrix: [[matrix copy] autorelease]];
	[matrix release];
	
	[self _addInteractionData:dataSet];
	[self _addSolvationData:dataSet];

	[forceField release];
	[system release];

	[returnString autorelease];		
	[returnString appendFormat:
		@"Complete - %d atoms analysed\n", 
		[atomContributions numberOfRows]];

	[resultsDict setObject: returnString
		forKey: @"ULAnalysisPluginString"];
	return resultsDict;	
}

@end

