/*
 Project: AdunKernel
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
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
#include "AdunKernel/AdunSmoothedGBTerm.h"
//Necessary to include definition of interactionList.
//There should be a superclass for the nonbonded terms using the AdLinkedList and AdCellHandler.
#include "AdunKernel/AdunPureNonbondedTerm.h"

static NSDictionary* coefficients;

@implementation AdSmoothedGBTerm

+ (void) initialize
{
	NSString* path;

	path = [[[NSBundle bundleForClass: [self class]] resourcePath]
			stringByAppendingPathComponent: @"GBSWData"];
	coefficients = [NSDictionary dictionaryWithContentsOfFile: 
			[path stringByAppendingPathComponent: @"OptimisedCoefficients.plist"]];
	[coefficients retain];
	
	generalizedBornRadiiDict = [NSDictionary dictionaryWithContentsOfFile:
		[path stringByAppendingPathComponent: @"PBBornRadii.plist"]];
	[generalizedBornRadiiDict retain];	
}

- (void) _precomputeConstants
{
	tau = (1 - 1/solventPermittivity);
	piFactor = 1/(4*M_PI);
	integrationFactorOne = 1/integrationStartPoint;
	integrationFactorTwo = 0.25*pow(integrationFactorOne, 4);
}

- (id) initWithDictionary: (NSDictionary*) dict
{
	return [self initWithSystem: [dict objectForKey: @"system"]
		nonbondedTerm: [dict objectForKey: @"nonbondedTerm"]
		smoothingLength: [[dict objectForKey: @"smoothingLength"] doubleValue]
		solventPermittivity: [[dict objectForKey: @"solventPermittivity"] doubleValue]
		tensionCoefficient: 0.03];
}

- (id) initWithSystem: (id) aSystem 
	nonbondedTerm: (id) aTerm 
      smoothingLength: (double) length 
  solventPermittivity: (double) epsilonSol
   tensionCoefficient: (double) gamma
{  
	NSArray* array;
	NSString* coefficientKey;
	
	if(self = [super init])
	{ 	
		//Initialise some ivars
		integrationStartPoint = 0.5;	//Following Im et al.
		meshSize = 1.0;			//Better for identifying complete overlaps
		cutBuffer = 0.0;
		totalPairESTPotential = totalPairESTPotential = totalNonpolarPotential = 0;
		memoryManager = [AdMemoryManager appMemoryManager];
		
		//Set arguments
		system = [aSystem retain];
		nonbondedTerm = [aTerm retain];
		smoothingLength = fabs(length);
		solventPermittivity = fabs(epsilonSol);
		numberOfAtoms = [system numberOfElements];
		cutoff = [nonbondedTerm cutoff];
		
		//Forces
		forces = [memoryManager allocateMatrixWithRows: numberOfAtoms withColumns: 3];
		
		//Hard coded number of points to make their generation initialy easier.
		numberRadialPoints = 24;
		numberAngularPoints = 38;
		
		//Create a string from the supplied smoothing length. 
		//This is required to access the values in the coefficients dictionary.
		coefficientKey = [NSString stringWithFormat: @"%3.1f", smoothingLength];
		if([coefficients objectForKey: coefficientKey]  == nil)
		{
			//Default smoothingLength to 0.3
			NSWarnLog(@"Unsupported smoothing length %@ - Defaulting to 0.3", coefficientKey);
			smoothingLength = 0.3;
			coefficientKey = @"0.3";
		}
			
		array = [coefficients objectForKey: coefficientKey];
		coefficentOne = [[array objectAtIndex: 0] doubleValue];
		coefficentTwo = [[array objectAtIndex: 1] doubleValue];
		
		//Gamma
		if(gamma <=0)
			gamma = 0.03;
		
		//Convert to Sim units
		tensionCoefficient = gamma/STCAL;
		
		//Precompute some constants
		[self _precomputeConstants];
		//Initialise the radial and angular points, the integration point vectors 
		//and the radial and angular weight matrices.
		[self _initIntegrationVariables];
		//Setup born radius variables (matrix with born radii and CFA terms).
		[self _initBornRadiiVariables];
		//Create grid along with initial neighbourTable and numberNeighbours array
		[self _initLookupTableVariables];
		
		//First calculation of the born radii and sasa of the atoms.
		[self _calculateBornRadiiAndCFATerms];
		[self _calculateSASA];
		[self evaluateEnergy];
		
		//Set update
		[[AdMainLoopTimer mainLoopTimer] 
		 sendMessage: @selector(calculateBornRadii) 
		 toObject: self 
		 interval: 5 name: @"AdGBUpdate"];
		
		//Temporary		
		[[AdMainLoopTimer mainLoopTimer] 
		 sendMessage: @selector(logEnergies) 
		 toObject: self 
		 interval: 100 name: @"AdGBUpdate2"];	
		
		//Register for system contents change - will need to update Radii.
		[[NSNotificationCenter defaultCenter]
		 addObserver: self
		 selector: @selector(_handleSystemContentsChange:)
		 name: @"AdSystemContentsDidChangeNotification"
		 object: system];
	}	
	
	return self;
}

//Temporary
- (void) logEnergies
{
	NSLog(@"Solvation Energy: Screened Energy %-12.5lf Self Energy %-12.5lf Non-Polar Energy %-12lf SASA %-12lf", 
		    totalPairESTPotential*STCAL, totalSelfESTPotential*STCAL, totalNonpolarPotential*STCAL, totalSasa);	
}

- (void) dealloc
{
	[[AdMainLoopTimer mainLoopTimer] 
		removeMessageWithName: @"AdGBUpdate"];
	[[AdMainLoopTimer mainLoopTimer] 
		removeMessageWithName: @"AdGBUpdate2"];	
		
	[memoryManager freeMatrix: forces];
	[system release];
	[nonbondedTerm release];
	[self _cleanUpIntegrationVariables];
	[self _cleanUpLookupTableVariables];
	[self _cleanUpBornRadiiVariables];
	//NSRecycleZone(lookupZone);
	[super dealloc];
}

- (void) _handleSystemContentsChange: (NSNotification*) aNotification
{
	[self _cleanUpBornRadiiVariables];
	[self _initBornRadiiVariables];
	[self calculateBornRadii];
}

- (double) selfEnergy
{
	return totalSelfESTPotential;
}

- (double) nonPolarEnergy
{
	return totalSasa*tensionCoefficient;
}

- (double) screeningEnergy
{
	return totalPairESTPotential;
}

- (AdDataMatrix*) selfEnergyData
{
	int i;
	AdMutableDataMatrix* matrix;
	NSArray *headers;
	id array;
	
	matrix = [AdMutableDataMatrix matrixFromADMatrix: selfEnergy];

	//Extend the matrix with a column of the born radii.
	array = [NSArray arrayFromCDoubleArray: bornRadii ofLength: numberOfAtoms];
	[matrix extendMatrixWithColumn: array];
	
	//Extend with non-polar energy
	array = [NSMutableArray new];
	for(i=0; i<numberOfAtoms; i++)
		[array addObject: 
			[NSNumber numberWithDouble: atomSasas[i]*tensionCoefficient]];
	
	[matrix extendMatrixWithColumn: array];
	[array release];
	
	//Extend with Sasa's
	array = [NSArray arrayFromCDoubleArray: atomSasas ofLength: numberOfAtoms];
	[matrix extendMatrixWithColumn: array];
	
	//Set headers
	headers = [NSArray arrayWithObjects: @"Self Energy", 
			@"CFA Term", 
			@"Correction Term", 
			@"Born Radius", 
			@"Non-Polar Energy",
			@"SASA", nil];
			
	[matrix setColumnHeaders: headers];
	[matrix setName: @"Solvation Data"];
	return [[matrix copy] autorelease];		
}

- (void) calculateBornRadii
{
	struct tms start, end;

	NSDebugLLog(@"AdSmoothedGBTerm", @"Beginning update. Recalculating lookup table");
	[self updateLookupTable];
	NSDebugLLog(@"AdSmoothedGBTerm", @"Updating Born Radii and self energies");
	//FIXME: Possibly can combine this into Derivative calc
	[self _calculateBornRadiiAndCFATerms];
	NSDebugLLog(@"AdSmoothedGBTerm", @"Updateing SASA and non-polar energy");
	[self _calculateSASA];
	NSDebugLLog(@"AdSmoothedGBTerm", @"Done");
}

@end

@implementation AdSmoothedGBTerm (AdForceFieldTermMethods)

- (id) initWithSystem: (id) aSystem
{
	[NSException raise: NSInternalInconsistencyException
		format: @"This method cannot be called yet %@", NSStringFromSelector(_cmd)];
	return [self initWithSystem: aSystem 
		nonbondedTerm: nil 
		smoothingLength: 0.3 
		solventPermittivity: 80
		tensionCoefficient: 0.03];
}

/*
 * Calculate derivative of the pair energy for each pair.
 * This is quite complex and it broken into three parts.
 *
 * For atom a the total force is
 *
 * F_a = B + c*S_ga + d*C_ga
 * 
 * Here B is a vector and c and d are scalars.
 * S_ga is the derivative of the atoms born radius w.r.t itself.
 * This is called the self-gradient and c*S_ga is the the self-force.
 * C_ga is the derivative of the other atoms born radius w.r.t. this atom.
 * This is called the Cross gradient here and d*C_ga the cross-force.
 *
 * For atom b the total force is
 *
 * F_a = -B + d*S_gb + c*C_gb 
 *
 * Hence for each interaction an atom is involved in there is a term involving its self-gradient.
 * This value is already obtained when calculating the self-energy derivatives.
 * Therefore in the first loop below the force B and the cross-term forces are calculated.
 * The sums of the coefficents (c, d) of the self-force are also calculated.
 * Afterwards the self-forces are added to the total force.
 */

- (void) evaluateForces
{
	int i,j;
	int atomOne, atomTwo;
	double factor, charge, bornRadius, magnitude;
	double valueOne, valueTwo, separation;
	double** coordinates, *array;
	ListElement* list_p, *interactionList=NULL;
	
	AdSetDoubleMatrixWithValue(forces, 0.0);
	AdSetDoubleMatrixWithValue(selfGradients, 0.0);
	coordinates = [system coordinates]->matrix;
	
	//FIMXE: Check if the term responds to this on set.
	interactionList = [nonbondedTerm interactionList];
		
	totalPairESTPotential = 0;
	if(interactionList != NULL)
	{
		list_p = interactionList->next;
		while(list_p->next != NULL)
		{
			if(list_p->length < cutoff)
			{
				AdGBESeparationDerivative(list_p, coordinates, forces->matrix, 
							  bornRadii, &totalPairESTPotential);
			}
			
			list_p = list_p->next;
		}
	}
	
	//Now add the self terms for each atom.
	//The first term is the derivative of the atoms self-energy
	//The second term is the sum of self-force for each interaction
	//the atom was involved in.
	//This is the sum of the coefficents of the self-force mulitplied by the self-gradient.
		
	factor =  0.5*tau*PI4EP_R;
	for(i=0; i<numberOfAtoms; i++)
	{
		//Derivatives of the pairwise temrs w.r.t. the atoms born radius and its
		//position. d(delta G_{ab})/dRa * dRa/drb where b can be equal to a
		[self _calculateDerivativesWithRespectToAtom: i];
				
		//Derivative of the self energy
		array = selfGradients->matrix[i];
		charge = charges[i];
		bornRadius = bornRadii[i];
		//FIXME: Precalculate - 
		magnitude = factor*charge*charge/(bornRadius*bornRadius);
		
		for(j=0; j<3; j++)
		{
			//Force is negative of gradient
			forces->matrix[i][j] -= magnitude*array[j];
		}
	}
				
	NSDebugLLog(@"SimulationLoop", 
		@"Solvation Energy: Screened Energy %-12.5lf Self Energy %-12.5lf Non-Polar Energy %-12lf SASA %-12lf", 
		totalPairESTPotential*STCAL, totalSelfESTPotential*STCAL, totalNonpolarPotential*STCAL, totalSasa);		
}

- (void) evaluateEnergy
{
	double** coordinates;
	ListElement* list_p, *interactionList=NULL;

	totalPairESTPotential = 0;

	//The self-energy is calculated every time the born radii are updated.
	
	//FIXME: Move
	if([nonbondedTerm respondsToSelector: @selector(interactionList)])
		interactionList = [nonbondedTerm interactionList];
	else
	{
		NSWarnLog(@"GB - Nonbonded term does not provide a nonbonded interaction list.");
		NSWarnLog(@"Unable to compute pair est solvation energies");
	}
		
	//Calculate the pairwise energies. 
	//We iterate over the same nonbonded list as used by the solute nonbonded term.	
	
	coordinates = [system coordinates]->matrix;
	if(interactionList != NULL)
	{
		list_p = interactionList->next;
		while(list_p->next != NULL)
		{
			if(list_p->length < cutoff)
			{
				AdGeneralizedBornEnergy(list_p, 
							coordinates, 
							bornRadii, 
							&totalPairESTPotential);	
			}
				
			list_p = list_p->next;
		}
	}
	
	NSDebugLLog(@"AdSmoothedGBTerm",
		@"evaluateEnergy: Screened Energy %-12.5lf Self Energy %-12.5lf Non-Polar Energy %-12lf SASA %-12lf", 
		totalPairESTPotential*STCAL, totalSelfESTPotential*STCAL, totalNonpolarPotential*STCAL, totalSasa);	
}	

- (double) energy
{
	//FIXME allow returning of more than one energy value;
	return totalPairESTPotential + totalSelfESTPotential + totalNonpolarPotential;
}

- (AdMatrix*) forces
{
	return forces;
}

- (void) setExternalForceMatrix: (AdMatrix*) matrix
{
	//Empty
}

- (BOOL) usesExternalForceMatrix
{
	return NO;
}

- (void) setSystem: (id) system
{
	[NSException raise: NSInternalInconsistencyException
		format: @"setSystem method of AdSmoothedGBTerm not implemented and should not be called"];
}

- (id) system
{
	return [[system retain] autorelease];
}

- (BOOL) canEvaluateEnergy
{
	return YES;
}

- (BOOL) canEvaluateForces;
{
	return YES;
}

@end
