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
#include "AdunKernel/AdunSCAAS.h"

#define RADIAL_FORCE_CONSTANT 20*BOND_FACTOR
#define GAMMA 0.0085
#define FULL_GAMMA 0.061
#define POLARISATION_FORCE_CONSTANT 6.9*BOND_FACTOR

@implementation AdSCAAS

/**
Retrieves the masses and charges of the solvent atoms
and creates C arrays for them
*/

-(void) _getMassesAndCharges
{
	int i;
	NSArray *massArray, *chargeArray;

	massArray = [system elementMasses];
	solventMasses = [memoryManager allocateArrayOfSize: 	
				[massArray count]*sizeof(double)];
	for(i=0; i<(int)[massArray count]; i++)
		solventMasses[i] = [[massArray objectAtIndex: i]
					doubleValue];
					
	chargeArray = [[system elementProperties] 	
				columnWithHeader: @"PartialCharge"];
	if(chargeArray == nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"Required solute element property PartialCharge not present"];

	solventCharges = [memoryManager allocateArrayOfSize: 	
				[chargeArray count]*sizeof(double)];
	for(i=0; i<(int)[chargeArray count]; i++)
		solventCharges[i] = [[chargeArray objectAtIndex: i] doubleValue];
}

/**
This returns the COM of the molecule with respect to the centre
of the solvent sphere
**/

- (void) _putCOMOfMolecule: (int*) molecule in: (Vector3D*) centre
{
	int i, j, k;
	int atom;
	double** coordinates;

	coordinates = [system coordinates]->matrix;

	//find centre of mass
	
	for(i=0; i<3; i++)
		centre->vector[i] = 0;

	for(j=0; j<atoms_per_molecule; j++)
	{
		atom = molecule[j];
		for(k=0; k<3; k++)
			centre->vector[k] += coordinates[atom][k]*solventMasses[atom];
	}

	for(i=0; i<3; i++)
		centre->vector[i] = centre->vector[i]/solvent_mass;

	for(i=0; i<3; i++)
		centre->vector[i] -= cavityCentre->vector[i];	

	Ad3DVectorLength(centre);
}

- (double) _calculatePolarisationAngleOf: (int*)molecule 
		withCenterOfMass: (Vector3D*) CoM 
		dipoleVector: (Vector3D*) dipole;
{
	int i,j;
	double angle;	
	double** coordinates;

	coordinates = [system coordinates]->matrix;
	for(i=0; i<3; i++)
		dipole->vector[i] = 0;
	//Dipole is Sigma (q_i * r_i)
	//This loop first calculates the x then the y and finally the z
	//component of the dipole vector.
	for(i=0; i<3; i++)
		for(j=0; j<atoms_per_molecule; j++)
			dipole->vector[i] += solventCharges[molecule[j]]*coordinates[molecule[j]][i];

	angle = Ad3DDotProduct(dipole, CoM);
	Ad3DVectorLength(dipole);
	angle = acos(angle/(dipole->length*CoM->length));

	return angle;	
}

- (void) _initRandomForceGenerator
{
	twister = gsl_rng_alloc(gsl_rng_mt19937);

	/**\note Im not sure if there should be a three in this...
	If the center of mass has three degrees of freedom (which it should)*/

	/**\note The SCAAS paper is slightly ambiguous as to the form of the 
	random force. The paper uses y' for the adjusted friction constant
	(GAMMA here for the radial force) and yº for the real friction constant. 
	It then uses both A'y and Aºy for the random force. It seems logical to
	assume that A'y is calculated used y' however the paper says <(A'y)²> should
	be set using eq.6 which is the formula for Aºy. We are going to assume that
	this means use eq.6 substituting y' for yº **/
	
	variance = 2*KB*3*GAMMA;	
}

- (void) _cleanUpSystem
{
	[memoryManager freeMatrix: forceMatrix];
	[memoryManager freeIntMatrix: solventIndexMatrix];
	[memoryManager freeArray: solventMasses];
	[memoryManager freeArray: solventCharges];
	free(radial_distance);
	gsl_rng_free(twister);
}

- (void) _calculateSoluteCharge
{
	int i;
	NSArray* soluteCharges;
	NSEnumerator* containedSystemsEnum;
	id containedSystem;

	//find the charge of the solute(s)

	solute_charge = 0.0;
	isChargedSolute = NO;
	containedSystemsEnum = [containedSystems objectEnumerator];
	while((containedSystem = [containedSystemsEnum nextObject]))
	{
		soluteCharges = [[containedSystem elementProperties] 	
					columnWithHeader: @"PartialCharge"];
		if(soluteCharges == nil)
			[NSException raise: NSInternalInconsistencyException
				format: @"Required solute element property PartialCharge not present"];

		for(i=0; i<(int)[soluteCharges count]; i++)
			solute_charge += [[soluteCharges objectAtIndex: i] doubleValue];

	}	

	GSPrintf(stderr, @"The solute charge is %f\n", solute_charge);
	if(fabs(solute_charge) > 0.001)	
	{
		isChargedSolute = YES;
		GSPrintf(stderr, @"Charged Solute\n");
	}
}

-(void) _initialisationForSystem
{
	int i, j;
	
	//retrieve and calculate the neccessary data for performing SCAAS

	no_solvent_atoms = [system numberOfElements];
	forceMatrix = [memoryManager allocateMatrixWithRows: no_solvent_atoms
			withColumns: 3];
	cavityCentre = [[[system dataSource] cavity] cavityCentre];
	
	/*
	 * Retrieve the atom masses and partial charges from the system 
	 * and create C arrays for them.
	 */
	[self _getMassesAndCharges];
	
	//the number of solvent molecules that had to be ommitted due to the solute
	occlusion_factor = [[system dataSource] numberOccludedMolecules];
	atoms_per_molecule = [[system dataSource] atomsPerMolecule] ;
	
	//the formula for calculating the equilibrium radial distance for each surface
	//atom can be written as ((alpha*j + beta)*solvent_mass)^1/3
	//\note incorporate the solvent mass here

	alpha = 3/(M_PI*4*solvent_density);
	beta = alpha*(occlusion_factor - 1);

	no_solvent_molecules = no_solvent_atoms/atoms_per_molecule;

	//create a matrix of rows = no solvent molecules and columns = atoms per molecule 

	solventIndexMatrix = [memoryManager allocateIntMatrixWithRows: no_solvent_molecules 
				withColumns: atoms_per_molecule];

	for(i=0; i < no_solvent_molecules; i++)
		for(j=0; j< atoms_per_molecule; j++)
			solventIndexMatrix->matrix[i][j] = atoms_per_molecule*i + j;

	//create an array to hold the radial distance of each molecule
	//and the positon of its centre of mass.
	//we only create the radial array here since we decide which atoms are
	//in the surface region based on this. We will need to create a
	//polarization array for the surface molecules each time we update them.
  	//(Since we dont know how many molecules are in the surface region and
	//we dont want to keep calculating them all every step)
	
	radial_distance = (Vector3D*)malloc(no_solvent_molecules*sizeof(Vector3D)); 

	//Find the mass of one molecule
	
	for(solvent_mass =0, i=0; i< atoms_per_molecule; i++)
		solvent_mass += solventMasses[i];
		
	[self _initRandomForceGenerator];
}

-(void) _handleSystemContentsChange: (NSNotification*) aNotification
{
	AdSystem* changedSystem;

	changedSystem = [aNotification object];

	NSDebugLLog(@"AdSCAAS", @"Received an AdSystemContentsDidChangeNotification");
	if(changedSystem == system)
	{
		NSDebugLLog(@"AdSCAAS", @"SCAAS system has changed");
		NSDebugLLog(@"AdSCAAS", @"Reinitialising");
		[self _cleanUpSystem];
		[self _initialisationForSystem];
	}
	else if([containedSystems containsObject: system])
	{
		NSDebugLLog(@"AdSCAAS", @"Contained system has changed");
		NSDebugLLog(@"AdSCAAS", @"Updating solute charge");
		[self _calculateSoluteCharge];
	}	
}

/**************

Object Creation

****************/

+ (id) alloc
{
	AdSCAAS* object;

	//Need to set twister = NULL since it seems
	//that gsl_rng_free can't handle a junk pointer and will
	//cause the program to crash
	//This will happen if this class is allocated and released
	//without being initialised.
	//FIXME: Make twister a class variable to avoid this?
	
	object = [super alloc];
	object->twister = NULL;
	
	return object;
}

- (id) init
{
	return [self initWithSystem: nil];
}

- (id) initWithSystem: (AdSystem*) containerSystem
{
	return [self initWithSystem: containerSystem
		containedSystems: nil];
}

- (id) initWithSystem: (AdSystem*) containerSystem
	containedSystems: (NSArray*) systems 
{
	return [self initWithSystem: containerSystem
		containedSystems: systems
		boundaryDepth: 1.5
		targetTemperature: 300.0];
}

- (id) initWithSystem: (AdSystem*) containerSystem
	containedSystems: (NSArray*) systems 
	boundaryDepth: (double) depth 
	targetTemperature: (double) temp 
{

	if((self = [super init]))
	{
		sphereRadius = inner_sphere = 0;
		containedSystems = nil;
		memoryManager = [AdMemoryManager appMemoryManager];
		twister = NULL;

		if(depth <= 0)
		{
			NSWarnLog(@"Boundary depth cannot be less than 0. Defaulting to 1");
			surface_region = 1;
		}
		else
			surface_region = depth;

		[self setSystem: containerSystem];
		[self setContainedSystems: systems];
		[self setTargetTemperature: temp];
	}
	
	return self;	
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];
	[containedSystems release];
	[system release];
	[memoryManager freeMatrix: forceMatrix];
	[memoryManager freeIntMatrix: solventIndexMatrix];
	[memoryManager freeArray: solventMasses];
	[memoryManager freeArray: solventCharges];
	free(radial_distance);
	if(twister != NULL)
		gsl_rng_free(twister);
		
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];
	NSEnumerator* systemEnum;
	id sys;
	
	[description appendFormat: 
		@"%@. System: %@. Target temperature: %5.2lf. Sphere radius: %6.2lf. Boundary depth: %4.2lf\n",
		NSStringFromClass([self class]), [system systemName], targetTemperature, sphereRadius, surface_region];
	if([containedSystems count] > 0)
	{	
		[description appendString: @"\tContained systems: "];
		systemEnum = [containedSystems objectEnumerator];
		while((sys = [systemEnum nextObject]))
			[description appendFormat: @"%@, ", [sys systemName]];
			
		[description appendFormat: @"\n\tSolute charge: %8.4lf\n", solute_charge];	
	}
		
	return description;	
}

/************************

SCAAS methods

**************************/

- (void) _setupSCAAS
{
	int i, j;
	int molecule;
	
	//calculate the radial distance of each molecule	

	for(i=0; i<no_solvent_molecules; i++)
		[self _putCOMOfMolecule: solventIndexMatrix->matrix[i] in: &radial_distance[i]];

	//how many molecules are inside the surface region?

	for(no_surface_molecules = 0, i=0; i < no_solvent_molecules; i++)
		if(radial_distance[i].length > inner_sphere)
			no_surface_molecules++;

	inside_count = no_solvent_molecules - no_surface_molecules;

	//copy the indices of the surface molecules to an array and sort them based
	//on their radial distance
	
	radial_sorter = (Sort*)malloc(no_surface_molecules*sizeof(Sort)); 

	for(i=0, j=0; i<no_solvent_molecules; i++)
		if(radial_distance[i].length > inner_sphere)
		{
			radial_sorter[j].index = i;
			radial_sorter[j].property = radial_distance[i].length;
			j++;
		}

	qsort(radial_sorter, no_surface_molecules, sizeof(Sort), comparison_pt); 
	
	//create an array to hold the polarization angles and dipole vectors

	polarisation_angles = (double*)malloc(no_surface_molecules*sizeof(double));
	dipoles = (Vector3D*)malloc(no_surface_molecules*sizeof(Vector3D));

	//use radial sorter to find surface molecule indexes
	//this way  polarisation_angles[i] will refer to the molecule radial_sorter[i].index

	for(i=0; i<no_surface_molecules;i++)
	{
		molecule = radial_sorter[i].index;
		polarisation_angles[i] = [self _calculatePolarisationAngleOf: solventIndexMatrix->matrix[molecule]
						withCenterOfMass: &radial_distance[molecule]
						dipoleVector: &dipoles[i]];
	}

	//sort the array

	polarisation_sorter = (Sort*)malloc(no_surface_molecules*sizeof(Sort)); 
	for(i=0; i<no_surface_molecules; i++)
	{
		polarisation_sorter[i].index = i;
		polarisation_sorter[i].property = polarisation_angles[i];
	}

	qsort(polarisation_sorter, no_surface_molecules, sizeof(Sort), comparison_pt);
}	

- (void) _applyRadialConstraint
{
	int i, j, k, molecule_count;
	int molecule_no, atom_no;
	double** velocities, **forces;
	double total_force, constraintDistance, randomMagnitude; 
	Vector3D ran_force;
	Vector3D unit_vector; 		//for holding the unit_vector in the direction of the force

	//dereference the matrix pointers

	velocities = [system velocities]->matrix;
	forces = forceMatrix->matrix;

	//calculate the radial constraint force on each atom of each molecule

	for(i = 0, molecule_count=inside_count; i < no_surface_molecules; i++, molecule_count++)
	{
		/*
		 * For each molecule we need to calculate the force on each
		 * of its constituent atoms
		 * Each of these forces is in the same direction as the total force.
		 * First calculate the total force on the centre of mass of the
		 * molecule and then assign it to the consituent atoms.
		 * The total force acts along the position vector of the centre of mass
		 * in the opposite direction.
		 */

		//There are no_surface_molecules in radial_sorter. Well go through them from start to finish

		molecule_no = radial_sorter[i].index;
		AdGet3DUnitVector(&radial_distance[molecule_no], &unit_vector);

		constraintDistance =  cbrt((alpha*molecule_count + beta)*solvent_mass);

		//multiply by -1 to change direction
		total_force = -1*RADIAL_FORCE_CONSTANT*(radial_sorter[i].property - constraintDistance);

		for(j = 0; j < atoms_per_molecule; j++)
		{
			//which atom are we at 

			atom_no = solventIndexMatrix->matrix[molecule_no][j];

			//unit vector should be the unit vector in the direction of the centre of
			//mass - so we multiply the total force by -1 above.
			
			for(k=0; k<3; k++)
				forces[atom_no][k] += total_force*unit_vector.vector[k];

			//generate a value for the random force
			sigma = sqrt(solventMasses[atom_no]*variance*targetTemperature);
			randomMagnitude = gsl_ran_gaussian(twister, sigma);
			AdGetRandom3DUnitVector(&ran_force, twister);
			
			for(k=0; k < 3; k++)
				ran_force.vector[k] = randomMagnitude*ran_force.vector[k];
			
			//apply the random force
			for(k=0; k<3; k++)
				forces[atom_no][k] += ran_force.vector[k];
		}

		for(j = 0; j < atoms_per_molecule; j++)
		{
			atom_no = solventIndexMatrix->matrix[molecule_no][j];
			for(k=0; k<3; k++)
				forces[atom_no][k] -= velocities[atom_no][k]*GAMMA*solventMasses[atom_no];
		}
	}
}

-(void) _applyPolarisationConstraint
{
	int i, j, k;
	int molecule, index, atom;
	double constraint_angle, cos_constraint, cos_actual, actual_angle;
	double langevin;
	double force_mag, factor, A, B;
	double** velocities, **forces, **coordinates;
	Vector3D force;
	Vector3D *Dipole, *Center;

	velocities = [system velocities]->matrix;
	forces = forceMatrix->matrix;
	coordinates = [system coordinates]->matrix;
	
	for(i=0; i<no_surface_molecules; i++)
	{
		//the index into the polarisation_angle array and the dipole array
		
		index = polarisation_sorter[i].index;

		//the index into the molecule matrix
		
		molecule = radial_sorter[index].index;

		Dipole = &dipoles[index];
		Center = &radial_distance[molecule];

		cos_constraint = 1 + (1 - 2*(i + 1))/(double)no_surface_molecules;
		constraint_angle = acos(cos_constraint);
		
		//if the soluted is charged we need to shift the constraint angles
	
		if(isChargedSolute)
		{
			langevin = Dipole->length*solute_charge;
			langevin /= (Center->length*Center->length)*(1 + Center->length)*KBT;
			langevin = 1/tanh(langevin) - 1/langevin;
			constraint_angle = constraint_angle - 3*langevin*sin(constraint_angle)/2;
		}

		actual_angle = polarisation_angles[index];
		cos_actual = cos(actual_angle);
		force_mag = -1*POLARISATION_FORCE_CONSTANT*(actual_angle - constraint_angle);
		
		factor = -1/(sqrt(1 - cos_actual*cos_actual))*1/(Dipole->length*Center->length);

		for(j=0; j<atoms_per_molecule; j++)
		{
			atom = solventIndexMatrix->matrix[molecule][j];
			
			A = solventMasses[atom]/solvent_mass - 
				solventCharges[atom]*cos_actual*Center->length/Dipole->length;
			B = solventCharges[atom] - 
				solventMasses[atom]*cos_actual*Dipole->length/(Center->length * solvent_mass);

			for(k=0; k<3; k++)
			{
				force.vector[k] = force_mag*factor*(A*Dipole->vector[k] + B*Center->vector[k]);
				forces[atom][k] += force.vector[k];
			}
		}
	}
}


- (void) _clearForceMatrix
{
	int i,j;

	for(i=0; i<forceMatrix->no_rows; i++)
		for(j=0; j<3; j++)
			forceMatrix->matrix[i][j] = 0;
}

/**************************

Public Methods

***************************/

//For the moment we will do the polarization and radial
//constraints seperatly though later we can probably combine
//the frictional and random parts of both in one loop

- (void) evaluateForces
{
	NSDebugLLog(@"AdSCAAS", @"Setting Up SCAAS");
	[self _setupSCAAS];
	NSDebugLLog(@"AdSCAAS", @"Applying radial constraint");
	[self _clearForceMatrix];
	[self _applyRadialConstraint];
	NSDebugLLog(@"AdSCAAS", @"Applying polarisation constraint");
	[self _applyPolarisationConstraint];
	free(radial_sorter);
	free(polarisation_angles);
	free(polarisation_sorter);
	free(dipoles);
}

- (void) evaluateEnergy
{
	NSDebugLLog(@"AdSCAAS", @"This object cannot calculate energy"); 
}

- (double) energy
{
	return 0;
}

- (AdMatrix*) forces
{
	return forceMatrix;
}

- (BOOL) canEvaluateEnergy
{
	return NO;
}

- (BOOL) canEvaluateForces
{
	return YES;
}

- (void) setExternalForceMatrix: (AdMatrix*) matrix
{
	NSWarnLog(@"Not implemented");
}

- (BOOL) usesExternalForceMatrix
{
	return NO;
}

- (void) setSystem: (id) object
{
	AdSphericalBox* containerCavity;

	if(system != nil)
	{
		[[NSNotificationCenter defaultCenter]
			removeObserver: self
			name: @"AdSystemContentsDidChangeNotification"
			object: system];
		[self _cleanUpSystem];
		[system release];
		[containedSystems release];
		containedSystems = nil;
	}	
	
	if(object != nil)
	{
		if(![[object dataSource] isKindOfClass: [AdContainerDataSource class]])	
		{
			NSWarnLog(@"AdSCAAS can only operate on a container system");
			[NSException raise: NSInvalidArgumentException
				format: @"AdSCAAS can only operate on a container system"];
		}

		containerCavity = [[object dataSource] cavity];
		if(![containerCavity isKindOfClass: [AdSphericalBox class]])
		{
			NSWarnLog(@"AdSCAAS can only operate on a spherical container");
			[NSException raise: NSInvalidArgumentException
				format: @"AdSCAAS can only operate on a spherical container"];
		}
			
		sphereRadius = [containerCavity radius];	
		inner_sphere = sphereRadius - surface_region;
		solvent_density = [[object dataSource] density];
		system = [object retain];
		
		[self _initialisationForSystem];
		comparison_pt = AdIndexSorter;
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleSystemContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: system];
	}
	else 
		system = nil;
}

- (id) system
{
	return [[system retain] autorelease];
}

- (void) setContainedSystems: (NSArray*) anArray
{
	NSEnumerator* containedSystemsEnum;
	AdSystem* containedSystem;
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	
	if(containedSystems == nil)
		return;
	
	containedSystemsEnum = [containedSystems objectEnumerator];
	while((containedSystem = [containedSystemsEnum nextObject]))
		[notificationCenter removeObserver: self
			name: @"AdSystemContentsDidChangeNotification"
			object: system];

	[containedSystems release];
	containedSystems = [anArray retain];
	
	containedSystemsEnum = [containedSystems objectEnumerator];
	while((containedSystem = [containedSystemsEnum nextObject]))
		[notificationCenter addObserver: self
			selector: @selector(_handleSystemContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: system];
	
	[self _calculateSoluteCharge];
}

- (NSArray*) containedSystems
{
	return [[containedSystems retain] autorelease];
}

- (void) setTargetTemperature: (double) value
{
	if(value < 0)
	{
		NSWarnLog(@"Target temperature cannot be less than 0. Defaulting to 0");
		targetTemperature =0;
	}
	else
		targetTemperature = value;
	
	KBT = targetTemperature*KB;
}

- (double) targetTemperature
{
	return targetTemperature;
}

- (void) setBoundaryDepth: (double) value
{
	if(value <= 0)
	{
		NSWarnLog(@"Boundary depth cannot be less than 0. Defaulting to 1");
		surface_region = 1;
	}
	else
		surface_region = value;

	//Recalculate the size of the inner sphere
	if(system != nil)
		inner_sphere = sphereRadius - surface_region;
}

- (double) boundaryDepth
{
	return surface_region;
}

@end
