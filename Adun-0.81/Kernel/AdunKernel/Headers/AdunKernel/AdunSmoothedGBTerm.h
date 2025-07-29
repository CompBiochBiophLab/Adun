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
#ifndef ADSMOOTHED_GBTERM
#define ADSMOOTHED_GBTERM

#include "Base/AdMatrix.h"
#include "Base/AdVector.h"
#include "Base/AdLinkedList.h"
#include "Base/AdGeneralizedBornFunctions.h"
#include "Base/AdVolumeFunctions.h"
#include "Base/AdQuadratureFunctions.h"
#include "AdunKernel/AdunMoleculeCavity.h"
#include "AdunKernel/AdunGrid.h"
#include "AdunKernel/AdForceFieldTerm.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunNonbondedTerm.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdunNonbondedTerm.h"
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdunCellListHandler.h"
#include "AdunKernel/AdunCuboidBox.h"

/**
Class which calculates the solvation energy and derivatives - polar and non-polar - of a system.
Used the GB with smoothing function method developed by Im, Lee and Brooks (J.Comp.Chem 24, 1694)
It requires knowledge of the nonbonded term object calculating the colomb energy
for optimal performance through use of the same nonbonded list.

\todo Possible factor out the integration point and solute grid parts to other classes.
\note At the moment the nonbonded term provided is expected to return a linked list of ListElement
structures containing the nonbonded pairs.
\ingroup Inter
\todo Size of Cavity used to define lookup table seems to be affecting result slightly even 
though it should not be.
*/
@interface AdSmoothedGBTerm: NSObject
{
	int numberOfAtoms;		//!< The number of atoms in the system
	double coefficentOne;		//!< Empirical coefficent a_0
	double coefficentTwo;		//!< Empriccal coefficent a_1	
	double smoothingLength;		//!< The smoothing length
	double integrationStartPoint;	//!< Arbitrary start point for the integration
	double solventPermittivity;
	double tensionCoefficient;
	double cutBuffer;		//!< Value used so the lookup table doesn't have update every step
	double meshSize;		//!< The size of the mesh of the grid used with the lookup table.
	double cutoff;
	id nonbondedTerm;		//!< The nonbonded term calculating the coulomb interactions
	id system;			//!< The system were working on
	AdMemoryManager* memoryManager;
	
	//Energy and force variables
	double totalSelfESTPotential;	//!< Stores the total self electrostatic energy of all the charges
	double totalPairESTPotential;	//!< Stores the total pairwise electrostatic energy of all the
	double totalNonpolarPotential;	//!< Stores the total non-polar contribution to the solvation energy
	double totalSasa;			//!< Stores the total solvent accessible surface.
	AdMatrix* forces;		//!< Stores the derivative of the solvation energy w.r.t. each atom.
	
	//Born Radius
	int radialEnd;			//!< The index of the first radial point after the cutoff
	double*	charges;		//!< Array containing the atom charges
	double* pbRadii;		//!< Array containing the modified pb born radius for each atom
	double* bornRadii;		//!< Array containing born radii
	double* atomSasas;		//!< Array containing the sasa of each atom.
	AdMatrix* selfEnergy;		//!< Matrix self-energy, and CFA terms for each atom.
	AdMatrix* selfGradients;	//!< Matrix containing the derivative of each atoms Born radius w.r.t. its position.
	AdMatrix* crossGradients;	//!< Holds the derivatives of an atoms born radius w.r.t each atom it interacts with
	Vector3D* vectorArray;		//!< Holder array
	
	//SoluteGrid
	int** neighbourTable;		//!< Each int array contains the indexes of atoms near a specific grid point
	IntArrayStruct numberNeighbours;	//!< Holds the number of neighbours for each grid point
	AdMatrix* gridCutMatrix;	//!< Holds the cutoff point and its square for each atom
	AdGrid* soluteGrid;		//!< A cartesian grid in a volume defined by the solute vdw radius + delta R.
	AdCuboidBox* cavity;		//!< The cavity object defining the volume where the grid exists.
	uint_fast8_t *overlapBuffer;	//!< Used to check if the grid needs to be rebuilt
	int (*getIndex)(id,SEL,Vector3D*);
	SEL gridSelector;
	NSZone* lookupZone;
	
	//Integration Points
	int numberRadialPoints;
	int numberAngularPoints;
	AdMatrix* radialInfo;	//The radial distances of each integration ''shell'' and the integration weight
	AdMatrix* angularInfo;	//The angles of the points in each shell and their integration weights
	Vector3D** integrationPoints;	//!< A matrix of vectors giving the position of each integration point.
	
	//Precomputed Constants
	float integrationFactorOne;	//!< 1/integrationStartPoint
	float integrationFactorTwo;	//!< 1/pow(integrationStartPoint, 2)
	float tau;			//!< (1/epsilon_solu - 1/epsilon_solv)
	float piFactor;			//!< 1/(4*pi)
}
/**
Method used when creating via the template manager.
May be temporary.
*/
- (id) initWithDictionary: (NSDictionary*) dict;
/**
Note smoothing length here is corresponds to w in Im et al. i.e. half their smoothing length.
This may change.
The tension coefficient value must be in KCal.mol.
\todo Units. Its more convienient ot have the tension coefficent in KCal.mol for external use.
However from an internal perspective it should really be in simulation units.
One solution is to create initialisers that take args in different units but before adopting this
approach other possibilities need to be checked.
*/
- (id) initWithSystem: (id) system 
	nonbondedTerm: (id) term 
	smoothingLength: (double) length 
	solventPermittivity: (double) epsilonSol
	tensionCoefficient: (double) gamma;
/**
Calculates the born-radii and SASA of each atom.
Internally this also involves a recalculation of the integration
look-up table
*/	
- (void) calculateBornRadii;
/**
Returns the last calculated screening energy
*/
- (double) screeningEnergy;
/**
Returns the last calculated self energy
*/
- (double) selfEnergy;
/**
Returns a matrix containing data on the self-energies.
There is one row for each atom and the data in each row corresponds to the atom
in the same row of the systems elementProperties() matrix.
The columns of the matrix are (in order)
Self Energy, CFA Term, Correction Term, Born Radius, Non-Polar Energy and SASA.
The energy columns are in Sim units.
*/
- (AdDataMatrix*) selfEnergyData;
/**
Returns the last calculate non-polar energy
*/
- (double) nonPolarEnergy;
@end
 
@interface AdSmoothedGBTerm (AdForceFieldTermMethods) <AdForceFieldTerm>
@end 
 
/*
 * Categories
 */ 
 
/**
 Methods for setting up the integrations points and weights
 */
@interface AdSmoothedGBTerm (IntegrationMethods)
- (void) _initIntegrationVariables;
- (void) _cleanUpIntegrationVariables;
@end

/**
 Methods for creating and updating the lookup table
 */
@interface AdSmoothedGBTerm (LookupTableMethods)
/**
 Recalculate the lookup table
 */
- (BOOL) _createLookupTable;
- (void) _createGrid;
- (void) _initLookupTableVariables;
- (void) updateLookupTable;
- (void) _cleanUpLookupTableVariables;
- (void) _freeNeighbourTable;
@end

/**
 Category containing methods for calculating the born radius, the self-electrostatic solvation energy,
 (and the necessary coloumb field approximation terms) for each atom.
 */
@interface AdSmoothedGBTerm (BornRadiusMethods)
- (void) _initBornRadiiVariables;
- (void) _cleanUpBornRadiiVariables;
- (void) _calculateBornRadiusAndCFATermsForAtom: (int) atomIndex;
- (void) _calculateBornRadiiAndCFATerms;
@end

/**
 Contains methods for calculating the non-polar energy term and its
 derivative
 */		
@interface AdSmoothedGBTerm (BornNonPolarMethods)
- (double) _calculateSASAForAtom: (int) atomIndex;
- (void) _calculateSASA;
@end 
 
/**		 
 Category containing methods for calculating the derivative of an atoms Born radius
 with respect to other atoms.
 */
@interface AdSmoothedGBTerm (BornRadiusDerivative)
/**
 Evaluated The derivative of the born radius of \e atomOne w.r.t it own position 
 and also the position of all other atoms it interacts with electrostatically.
 
 This is highly involved as it depends on the derivative of the volume exclusion function
 at each integration point. Further more the deriviative is different depending on whether the
 atoms are the same or different.
 
 NOTE: If the charge on \e atomOne is zero, the gradient is set to zero, even though it may not be.
 This is because the gradient is only used in force calculations where, if this charge is zero,
 there is no force.
 Therefore, for optimisation, their is no point in calculating the gradient, in these cases.
 */
- (void) _calculateDerivativesWithRespectToAtom:(int) mainAtom;
@end
 
//Contains optimised atomic radii from Nina et al.
NSDictionary* generalizedBornRadiiDict; 
 
#endif

