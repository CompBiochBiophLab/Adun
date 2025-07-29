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

/************** OPTIMISATION ***************************/
 
//NB. These three variables are defined here for optmisation reasons.
//They are used only by AdPrivateVEF().
//This is half smoothing length in the terminology of Im et at.
static double w; 
static double smoothingConstantA;
static double smoothingConstantB;

/**
 This is the same as AdVolumeExclusionFunction2() reimplemented here so
 it can be inlined as it is called very frequently
 */
inline double AdPrivateVEF(Vector3D* r, AdMatrix* coordinates, 
			   int* neighbourIndexes, int numberNeighbours, double* radii,
			   IntArrayStruct* contributingAtoms);	
			   
			   
/*****************  END OPT ******************************/			   

/*
 *
 * Functions
 *
 */
			   
inline BOOL AdGBSWInitialiseVariables(double charge, double radius, 
				      double correctionEnergy, double tau, 
				      double *factor1, double* factor2);
						      			      
/**
Calculate the position derivatives of all atoms that could have a gradient at \e integrationPoint
 \e neighbours is an array containing the indexes of these atoms.
 */
inline void AdGBSWCalculatePositionDerivatives(AdMatrix* coordinates, double* pbRadii,  Vector3D* integrationPoint,  
				double exclusionValue, Vector3D* vectorArray, 
				IntArrayStruct* calculatedGradients, bool* interactingAtoms);

inline void AdGBSWUpdateGradient(Vector3D* vector, double angularWeight, 
				double radialWeight, double f3, double* gradient);	
inline void AdGBSWUpdateCrossGradients(IntArrayStruct* calculatedGradients, Vector3D* vectorArray, 
					double angularWeight, double radialWeight, 
					double f3, AdMatrix* gradientArray);

/*
 *
 * Categories
 *
 */

/**
Category containing methods for calculating the born radius, the self-electrostatic solvation energy,
(and the necessary coloumb field approximation terms) for each atom.
*/
@implementation AdSmoothedGBTerm (BornRadiusMethods)

- (BOOL) _getOptimisedRadiusForAtom: (NSString*) atom inResidue: (NSString*) residue radius: (double*) value
{
	BOOL foundRadius = NO;
	NSRange range;
	NSString* wildCardOne, *wildCardTwo, *radius;
	NSDictionary* genericData, *residueData;

	//If the atom name starts with a number get rid of it
	range = [atom rangeOfCharacterFromSet: [NSCharacterSet decimalDigitCharacterSet]];
	if(range.location != NSNotFound)
		if(range.location == 0)
			atom = [atom substringFromIndex: 1];	
	
	genericData = [generalizedBornRadiiDict objectForKey: @"Generic"];
	residueData = [generalizedBornRadiiDict objectForKey: residue];
	
	//Main wildCards are of the form "AA*"
	if([atom length] >= 2)
	{
		wildCardOne = [atom substringWithRange: NSMakeRange(0,2)];
		wildCardOne = [wildCardOne stringByAppendingString: @"*"];
	}
	else
		wildCardOne = @"";

	//There are a few however that are "A*" - mainly hydorgens
	wildCardTwo = [atom substringWithRange: NSMakeRange(0,1)];
	wildCardTwo = [wildCardTwo stringByAppendingString: @"*"];
	
	//Get radius 
	//	1 - Match first on full name in residue
	//	2 - If no matches against wild cards in reisude
	//	3 - Match against generic
	//	4 - Match wildCardTwo against generic - Hydrogen

	if((radius = [residueData objectForKey: atom]) != nil)
	{
		foundRadius = YES;
	}
	else if((radius = [residueData objectForKey: wildCardOne]) != nil)	
	{
		foundRadius = YES;
	}
	else if((radius = [residueData objectForKey: wildCardTwo]) != nil)
	{	 
		foundRadius = YES;
	}
	else if((radius = [genericData objectForKey: atom]) != nil)
	{
		foundRadius = YES;
	}
	else if((radius = [genericData objectForKey: wildCardTwo]) != nil)
	{
		foundRadius = YES;
	}
	
	if(radius != nil)
		*value = [radius doubleValue];
	
	return foundRadius;
}

- (void) _calculateOptimisedAtomicRadii: (NSString*) type
{
	unsigned int i, count;
	int start, atomCount;
	double value, paramOne, paramTwo, scalingFactor;
	NSRange range;
	AdDataMatrix* residueInfo;
	NSArray *residueNames, *atomsPerResidue, *atomNames;
	NSArray *paramsOne, *paramsTwo=NULL;
	NSString *residue, *atom;
	NSEnumerator *residueEnum;

	//Using Nina et al use the optimised solvent radii
	//and the formula s(R_0 + w) to generated optimised radii for each atom.
	
	residueInfo = [[system dataSource] groupProperties];
	residueNames = [residueInfo columnWithHeader: @"Residue Name"];
	atomsPerResidue = [residueInfo columnWithHeader: @"Atoms"];
	atomNames = [[[system dataSource] elementProperties] 
				columnWithHeader: @"PDBName"];
		
	//Get vdw parameters so the vdw radii can be calculated if no optimised
	//radius is found.						
	if([type isEqual: @"A"])
	{
		paramsOne = [[system elementProperties] columnWithHeader: @"VDW A"];
		paramsTwo = [[system elementProperties] columnWithHeader: @"VDW B"];
	}
	else
		paramsOne = [[system elementProperties] columnWithHeader: @"VDW Separation"];
	
	//FIXME: Read in scaling factors.
	//The below is the factor for smoothing length 0.3
	scalingFactor = 0.952;
		
	//Do the search
	count = start = 0;
	residueEnum = [residueNames objectEnumerator];
	while(residue = [residueEnum nextObject])
	{
		atomCount = [[atomsPerResidue objectAtIndex: count] intValue];
		range = NSMakeRange(start, atomCount);
		
		for(i=range.location; i<NSMaxRange(range); i++)
		{
			atom = [atomNames objectAtIndex: i];
			if(![self _getOptimisedRadiusForAtom: atom inResidue: residue radius: &value])
			{
				NSLog(@"Can't find optimised radii for %@ in residue %@", atom, residue);
				paramOne = [[paramsOne objectAtIndex: i] doubleValue];
				if([type isEqual: @"A"])
					paramTwo = [[paramsTwo objectAtIndex: i] doubleValue];
				else
					paramTwo = 0.0;
				
				value = AdCalculateVDWRadii(paramOne, paramTwo, type);
				pbRadii[i] = value;
				NSLog(@"\tDefaulting to %-10.5lf", value);
			}
			else
			{
				pbRadii[i] = scalingFactor*(value + smoothingLength);
			}
				
		}
		
		count++;
		start += range.length;
	}
}

- (void) _initBornRadiiVariables
{
	int i;
	double* paramsOne, *paramsTwo;
	NSString* type = nil;
	NSArray* headers;
	
	//Initialise the smoothing value that will be used with the GB volume functions
	AdInitialiseGBSmoothingVariables(smoothingLength);
	
	//Static copies of the variables set by the above function.
	//This is an optimisation - These variables are for use with AdPrivateVEF().
	w = smoothingLength;
	smoothingConstantA = 3/(4*smoothingLength);
	smoothingConstantB = 1/(4*pow(smoothingLength, 3));
	
	//Initialise the constants used by the GB force and energy functions
	AdSetGeneralizedBornVariables(tau, PI4EP_R);
	
	bornRadii = [memoryManager allocateArrayOfSize: [system numberOfElements]*sizeof(double)];
	atomSasas = [memoryManager allocateArrayOfSize: [system numberOfElements]*sizeof(double)];
	selfEnergy = [memoryManager allocateMatrixWithRows: [system numberOfElements] withColumns: 3];
	charges = [[[system elementProperties] columnWithHeader: @"PartialCharge"] cDoubleRepresentation];
	selfGradients = [memoryManager allocateMatrixWithRows: numberOfAtoms withColumns: 3];
	crossGradients = [memoryManager allocateMatrixWithRows: numberOfAtoms withColumns: 3];
	vectorArray = malloc(numberOfAtoms*sizeof(Vector3D));
	
	//Get the PBBornRadii
	pbRadii = [memoryManager allocateArrayOfSize: numberOfAtoms*sizeof(double)];
	
	headers = [[system elementProperties] columnHeaders];
	if([headers containsObject: @"VDW A"])
	{
		type = @"A";
	}
	else if([headers containsObject: @"VDW Separation"])
	{
		type = @"B";
	}

	if(type == nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"No VdW parameters available for system %@", [system name]];

	[self _calculateOptimisedAtomicRadii: type];
}	

- (void) _cleanUpBornRadiiVariables
{
	free(charges);
	free(vectorArray);
	[memoryManager freeMatrix: selfGradients];
	[memoryManager freeMatrix: crossGradients];
	[memoryManager freeMatrix: selfEnergy];
	[memoryManager freeArray: pbRadii];
	[memoryManager freeArray: bornRadii];
	[memoryManager freeArray: atomSasas];
}

- (void) _calculateBornRadiusAndCFATermsForAtom: (int) atomIndex
{
	int i;
	int radialStart, radialPoint, angularPoint;
	int gridPointIndex;	//!< The index of the grid point to be used to define the atoms used in the integration.
	double radialWeight, angularWeight;
	double holder,valueOne, valueTwo; //< For holding precalculated values
	double firstSum, secondSum; //!< The values of the integrals
	double charge, preFactor, maxLowerBound;
	double volumeFunctionValue, radialDistance;
	double* position;
	AdMatrix* coordinates;
	Vector3D integrationPoint, absPoint, *pointsArray;
	
	//Get reference to atom position
	coordinates = [system coordinates];
	position = coordinates->matrix[atomIndex];
		
	firstSum = secondSum = 0;
	
	//We can skip all points the main atom completely overlaps.
	//The volume exclusion function is 0 there and so is the gradient.
	maxLowerBound = pbRadii[atomIndex] - smoothingLength - 0.01;
	
	//Find the first radial point after maxLowerBound
	radialStart = 0;
	for(i=0; i<radialInfo->no_rows;i++)
	{
		if(radialInfo->matrix[i][0] > maxLowerBound)
		{
			radialStart = i;
			break;
		}
	}
	
	//The points below maxLowerBound can be calculated quickly
	//since the atom overlaps all the relevant grid points and
	//the volume function is always 1.
	for(radialPoint = 0; radialPoint < radialStart; radialPoint++)
	{
		holder = 4*M_PI;
		
		radialDistance = radialInfo->matrix[radialPoint][0];
		radialWeight = radialInfo->matrix[radialPoint][1];
		
		valueOne = radialDistance*radialDistance;
		valueTwo = valueOne*valueOne*radialDistance;
		
		firstSum += radialWeight*holder/valueOne;
		secondSum +=  radialWeight*holder/valueTwo;
		
		holder = 0;
	}
	
	//Now do the points outside max lower bound
	for(radialPoint = radialStart; radialPoint < numberRadialPoints; radialPoint++)
	{ 
		radialDistance = radialInfo->matrix[radialPoint][0];
		radialWeight = radialInfo->matrix[radialPoint][1];
		pointsArray = integrationPoints[radialPoint];
		
		for(angularPoint = 0; angularPoint < numberAngularPoints; angularPoint++)
		{
			//Get the vector giving the integration point relative to the atom
			//we are calculating the Born radius for
			integrationPoint = pointsArray[angularPoint];
			
			//Get the weights for the radial and angular point we are using
			angularWeight = angularInfo->matrix[angularPoint][3];

			//Get the absolute position of this point (relative to the origin)
			absPoint.vector[0] = position[0] + integrationPoint.vector[0];
			absPoint.vector[1] = position[1] + integrationPoint.vector[1];
			absPoint.vector[2] = position[2] + integrationPoint.vector[2];
			
			//Find the nearest grid point to this point
			gridPointIndex = getIndex(soluteGrid, gridSelector, &absPoint);
		
			//Get the value of the volume function
			//If no atoms overlap the point the volume function is 0.
			//In this case nothing is added to holder so we can continue
			//If any atom completely overlaps the point the volume function is 1.
			if(gridPointIndex != -1)
			{
				if(overlapBuffer[gridPointIndex] == 1)
				{	
					volumeFunctionValue = 1;
				}
				else
				{
					volumeFunctionValue = AdVolumeFunction(&absPoint, 
									       coordinates, 
									       neighbourTable[gridPointIndex],
									       numberNeighbours.array[gridPointIndex],
									       pbRadii);
				}
			
				holder += angularWeight*volumeFunctionValue;
			}
		}
		
		//This is the separation distance to the power of 2 and 5 respectively 
		valueOne = radialDistance*radialDistance;
		valueTwo = valueOne*valueOne*radialDistance;
		
		firstSum += radialWeight*holder/valueOne;
		secondSum +=  radialWeight*holder/valueTwo;
		
		holder = 0;
	}
	
	charge = charges[atomIndex];
	preFactor = -0.5*PI4EP_R*tau*charge*charge;		
	
	valueOne = integrationFactorOne - piFactor*firstSum;
	valueTwo = pow(integrationFactorTwo - piFactor*secondSum, 0.25);
		
	//The Born Radius
	bornRadii[atomIndex] = 1/(coefficentOne*valueOne + coefficentTwo*valueTwo);
	//The CFA term
	selfEnergy->matrix[atomIndex][1] = preFactor*valueOne;
	//The CFA correction Term
	selfEnergy->matrix[atomIndex][2] = preFactor*valueTwo;
	//The self energy
	selfEnergy->matrix[atomIndex][0] = coefficentOne*selfEnergy->matrix[atomIndex][1] + 
						coefficentTwo*selfEnergy->matrix[atomIndex][2];	
}

- (void) _calculateBornRadiiAndCFATerms
{
	int i;

	totalSelfESTPotential = 0;
	for(i=0; i<numberOfAtoms; i++)
	{
		[self _calculateBornRadiusAndCFATermsForAtom: i];
		totalSelfESTPotential += selfEnergy->matrix[i][0];
	}
}

@end


/**
Contains methods for calculating the non-polar energy term and its
derivative
*/		
@implementation AdSmoothedGBTerm (BornNonPolarMethods)

- (double) _calculateSASAForAtom: (int) atomIndex
{
	int i;
	int radialPoint, angularPoint, gridPointIndex;
	double radialWeight, angularWeight;
	double volumeExclusionValue, atomSASA, radius;
	double* position, *weightsBuffer, *pointsBuffer;
	AdMatrix* coordinates;
	Vector3D integrationPoint, absPoint, gradient;
	
	//Generate the first set of radial points
	weightsBuffer = malloc(3*sizeof(double));
	pointsBuffer =  malloc(3*sizeof(double));
	
	//5 points up to 1 angstrom
	AdGenerateGaussLegendrePoints(pbRadii[atomIndex] - 0.1, 
		pbRadii[atomIndex] + 0.1, 3, pointsBuffer, weightsBuffer);
	
	//Get reference to atom position
	coordinates = [system coordinates];
	position = coordinates->matrix[atomIndex];

	atomSASA = 0;
	for(radialPoint = 0; radialPoint < 3; radialPoint++)
	{ 
		radius = pointsBuffer[radialPoint];
		radialWeight = weightsBuffer[radialPoint];
		
		for(angularPoint = 0; angularPoint < numberAngularPoints; angularPoint++)
		{
			//Get the vector giving the integration point relative to the atom
			//we are calculating the Born radius for
			for(i=0; i<3; i++)
				integrationPoint.vector[i] = angularInfo->matrix[angularPoint][i]*radius;
			integrationPoint.length = radius;
			
			//Get the weight
			angularWeight = angularInfo->matrix[angularPoint][3];
			
			//Get the gradient of the atomic volume exclusion function at the integration point 
			//i.e. The gradient at the point just due to this atom.
			AdAtomicVolumeExclusionFunctionGradient(&integrationPoint, 
				pbRadii[atomIndex], 
				&gradient);			
			
			//if the gradient isn't zero then calculate the volume exclusion function
			//not including the contribution of the current atom
			//NOTE AdAtomicVolumeExclusionFunctionGradient does not actually calculate
			//this value - it only sets it to 0 if it is zero and to one otherwise.
			//If the magnitude is required it must be calculated explicitly.
			if(gradient.length != 0)
			{
				//Get the absolute position of this point (relative to the origin)
				absPoint.vector[0] = position[0] + integrationPoint.vector[0];
				absPoint.vector[1] = position[1] + integrationPoint.vector[1];
				absPoint.vector[2] = position[2] + integrationPoint.vector[2];
				
				gridPointIndex = getIndex(soluteGrid, gridSelector, &absPoint);
				
				//FIMXE: Is this necessary?
				if(gridPointIndex == -1)
				{	
					//if its outside then the volumeExclusionFunction is 1.
					volumeExclusionValue = 1;
				}
				else
				{
					
					volumeExclusionValue = AdVolumeExclusionFunction(&absPoint, 
									coordinates, 
									neighbourTable[gridPointIndex],
									numberNeighbours.array[gridPointIndex],
									pbRadii);
									
					//Remove the contribution of the current atom
					//The denominator can't be zero if its gradient isn't 0 so no need to be worried about DIV0
					//If the volumeExclusionValue is 0 then their is no contribution to the atomSASA from
					//this point.
					if(volumeExclusionValue != 0)
					{
						volumeExclusionValue /= AdAtomicVolumeExclusionFunction(integrationPoint.length,
													pbRadii[atomIndex]);
						Ad3DVectorLength(&gradient);
						//FIXME: Reduce multiplies
						atomSASA += radialWeight*angularWeight*volumeExclusionValue*gradient.length*radius*radius;
					}
				}
			}
		}
	}	

	free(pointsBuffer);
	free(weightsBuffer);

	return atomSASA;
}

- (void) _calculateSASA
{
	int i;
	
	AdInitialiseGBSmoothingVariables(0.1);
	
	for(totalSasa=0, i=0; i<numberOfAtoms; i++)
	{
		atomSasas[i] = [self _calculateSASAForAtom: i];
		totalSasa += atomSasas[i];
	}
		
	AdInitialiseGBSmoothingVariables(smoothingLength);
	totalNonpolarPotential = totalSasa*tensionCoefficient;	
}

@end

/*		 
Category containing methods for calculating the derivative of an atoms Born radius
with respect to other atoms.
*/
		 
@implementation AdSmoothedGBTerm (BornRadiusDerivative)

/*
The derivative of the born radius of \e atomOne w.r.t the position of another \e atomTwo.
\e atomTwo can be equal to \e atomOne.

This is highly involved as it depends on the derivative of the volume exclusion function
at each integration point. Further more the deriviative is different depending on whether the
atoms are the same or different.

However the derivative is non-zero only at integration points around atom one that fall within
the smoothing region of atomTwo.
 
NOTE: If the charge on \e atomOne is zero, the gradient is set to zero, even though it may not be.
This is because the gradient is only used in force calculations where, if this charge is zero,
there is no force.
Therefore, for optimisation, their is no point in calculating the gradient, in these cases.

The self gradient points in the direction of greatest increase of the B.R. of the atom.

\note Due to the numerical nature of the integration its entirely possible that
\e atomTwo will not overlap any of the integration points of \e atomOne and thus
the derivative will be zero (there are only 38 points at each radial distance.)
This is more likely to occur the further \e atomTwo is from \e atomOne.
*/
		
- (void) _calculateDerivativesWithRespectToAtom:(int) mainAtom 
{
	BOOL retval;
	int i, radialPoint, angularPoint, radialStart;
	int gridPointIndex, numberOfNeighbours, index;
	int* neighbourIndexes;
	double f1, f2, f3;	//!< Precomputed factors
	double radialWeight, angularWeight, distance, squaredDistance, exclusionValue;
	double maxLowerBound;
	double *mainAtomPosition, *selfGradient;
	AdMatrix* coordinates;
	Vector3D absPoint, integrationPoint, selfVector;
	Vector3D *pointArray;
	IntArrayStruct calculatedGradients;
	bool* interactingAtoms;
	
	//This return NO if the atom charge is 0 - see above.
	retval = AdGBSWInitialiseVariables(charges[mainAtom], 
			bornRadii[mainAtom], selfEnergy->matrix[mainAtom][2], 
			tau, &f1, &f2);
			
	Ad3DVectorInit(&selfVector);
					
	if(!retval)
		return;

	coordinates = [system coordinates];
	mainAtomPosition = coordinates->matrix[mainAtom];
	selfGradient = selfGradients->matrix[mainAtom];
	
	//We can skip all points the main atom completely overlaps.
	//The volume exclusion function is 0 there and so is the gradient.
	maxLowerBound = pbRadii[mainAtom] - smoothingLength - 0.01;
	
	//Find the first radial point after maxLowerBound
	//FIXME: Precompute
	radialStart = 0;
	for(i=0; i<radialInfo->no_rows;i++)
	{
		if(radialInfo->matrix[i][0] > maxLowerBound)
		{
			radialStart = i;
			break;
		}
	}
			
	//Array for holding indexes of atoms who have a gradient
	//FIMXE: Preallocate
	calculatedGradients.array = malloc(numberOfAtoms*sizeof(int));
	calculatedGradients.length = 0;
	interactingAtoms = calloc(numberOfAtoms, sizeof(bool));
	
	//AdSetDoubleMatrixWithValue(crossGradients, 0.0);
	memset(crossGradients->matrix[0], 0.0, numberOfAtoms*3*sizeof(double));
	
	/*
	 * Iterate over all the integration points around the atom whose
	 * Born radius we are performing the derivative w.r.t. (mainAtom)
	 * At each point we have to calculate the derivative of the volume function.
	 * w.r.t. the position of all the atoms mainAtom interacts with AND
	 * the self-derivative.
	 */
	 
	for(radialPoint = radialStart; radialPoint < radialEnd; radialPoint++)
	{
		distance = radialInfo->matrix[radialPoint][0];
		radialWeight = radialInfo->matrix[radialPoint][1];
		pointArray = integrationPoints[radialPoint];
	
		//The messy factor you have to multiply for each radial shell.
		squaredDistance = distance*distance;
		f3 = (1/squaredDistance)*(coefficentOne - 0.25*f2*coefficentTwo/(squaredDistance*distance));
		
		for(angularPoint = 0; angularPoint < numberAngularPoints; angularPoint++)
		{
			//Get the vector giving the integration point relative to the atom
			//whose Born radius we are peforming the derivative of.
			integrationPoint = pointArray[angularPoint];
			
			//Get the absolute position of this point (relative to the origin)
			absPoint.vector[0] = mainAtomPosition[0] + integrationPoint.vector[0];
			absPoint.vector[1] = mainAtomPosition[1] + integrationPoint.vector[1];
			absPoint.vector[2] = mainAtomPosition[2] + integrationPoint.vector[2];
			
			//Find the nearest grid point to this point
			gridPointIndex = getIndex(soluteGrid, gridSelector, &absPoint);
			
			//Get the derivatives.
			//All derivatives depend on the value of the volume exclusion function (VEF) at the
			//integration point. If it is 0, i.e. the integration point is overlapped by
			//an atom, then any gradient is 0, so we can skip these points.
			//
			//Furthermore all gradients depend on the derivatives of AVEFs at the point.
			//If the VEF is 1 then all AVEF's are 1 and hence all their derivatives are 0.
			//Thus we can skip points whose VEF is 1 as well.
			if(gridPointIndex < 0)
			{	
				//If the point is completly outside the grid then the 
				//volume exclusion function is 1.
				//Hence its derivative is zero and we can skip it
				continue;
			}
			
			numberOfNeighbours = numberNeighbours.array[gridPointIndex];
			
			//If theres no neighbours then all gradients are 0.
			if(numberOfNeighbours == 0)
				continue;
			
			//Check if this point is overlapped by any atoms
			//It is is the VEF is 0 and there is no gradient.
			if(overlapBuffer[gridPointIndex] == 1)
				continue;
			
			neighbourIndexes = neighbourTable[gridPointIndex];
			
			//The position derivative of an atom at a point involves the total 
			//exclusion value at that point.
			//If the exclusion value is zero all gradients are zero so calculate it first.
			//If the exclusion value is 1 all gradients are also zero.
			//Usally this means the point has no neighbours but not always.
			//i.e. it could be just outside the boundary of some neighbours
			//The indexes of the points who contributed are place in calculatedGradients
			exclusionValue = AdPrivateVEF(&absPoint, 
						      coordinates, 
						      neighbourIndexes, 
						      numberOfNeighbours, 
						      pbRadii,
						      &calculatedGradients);
			
			if(exclusionValue == 0 || exclusionValue >= 1)	
				continue;
			
			angularWeight = angularInfo->matrix[angularPoint][3];
			
			//Cross derivatives
			//FIXME: Possibly calculating a number of terms twice.
			//That is the atomic exclusion value of the atoms at absPoint.
			
			//Calculate the Position derivatives of every atom that could have
			//a derivative at the point (the points neighbours) AND also 
			//interact with mainAtom but ARE NOT the mainAtom!
			AdGBSWCalculatePositionDerivatives(coordinates, pbRadii, &absPoint, 
							   exclusionValue, vectorArray, 
							   &calculatedGradients, interactingAtoms);
			
			//Update all the gradient vectors - This also clear all the vectors in vectorAray
			AdGBSWUpdateCrossGradients(&calculatedGradients, vectorArray, 
						   angularWeight, radialWeight, f3, crossGradients);				
			
			
			//The self derivative at the point
			AdVolumeFunctionAtomDerivative(mainAtom, &absPoint, coordinates, 
						       &calculatedGradients, exclusionValue, 
						       pbRadii, &selfVector);	
			
			//Also clears selfVector
			AdGBSWUpdateGradient(&selfVector, angularWeight, radialWeight, 
					     f3, selfGradient);
			
			calculatedGradients.length = 0;				
		}
	}
	
	//Multiply the selfGradient by the first factor
	selfGradient[0] *= f1;
	selfGradient[1] *= f1;
	selfGradient[2] *= f1;
	
	//Finally multiply all the entries in the gradient matrix
	//who the derivative was performed w.r.t by the first factor

	double selfCoefficient, value;
	
	interactingAtoms[mainAtom] = 0;
	
	for(selfCoefficient = 0, i=0; i<numberOfAtoms; i++)
	{
		if(interactingAtoms[i])
		{
			//Get the born radius derivative - dG/dRa*dRa/drb
			//FIXME: This could be precalcualted but there are storage problems.
			AdGBEBornRadiusCoefficient(mainAtom , i, coordinates->matrix, bornRadii, charges, &value);
			selfCoefficient += value;
			value *= f1;
			forces->matrix[i][0] -= value*crossGradients->matrix[i][0];
			forces->matrix[i][1] -= value*crossGradients->matrix[i][1];
			forces->matrix[i][2] -= value*crossGradients->matrix[i][2];
		}
	}

	//Same for self gradient
	//Force is negative of gradient.
	//For each (+,-) pair this force acts to increase the B.R.
	forces->matrix[mainAtom][0] -= selfGradient[0]*selfCoefficient;
	forces->matrix[mainAtom][1] -= selfGradient[1]*selfCoefficient;
	forces->matrix[mainAtom][2] -= selfGradient[2]*selfCoefficient;
		
	free(calculatedGradients.array);
	free(interactingAtoms);
}

@end

inline BOOL AdGBSWInitialiseVariables(double charge, 
		double radius, 
		double correctionEnergy, 
		double tau, 
		double *factor1, 
		double* factor2)
{
	//Precalculated factors - PI4EP_R factor is required since the self energy
	//was multiplied by it above to so it would be in sim units.
	*factor1 = radius*radius/(4*M_PI);
	*factor2 = 0.5*tau*PI4EP_R*charge*charge/correctionEnergy;
	if(fabs(charge) > 1E-10)
		return YES;
		
	return NO;	
}

/**
Atoms is an array of atoms whose derivative is to be calculaed at \e integrationPoint.
\e neighbours is an array containing the atoms who are close to that point.
*/
inline void AdGBSWCalculatePositionDerivatives(AdMatrix* coordinates, double* pbRadii, 
		Vector3D* integrationPoint, double exclusionValue, 
		Vector3D* vectorArray, IntArrayStruct* calculatedGradients, bool* interactingAtoms)
{
	int i, atomIndex, numberNeighbours;
		
	//Only the atoms in calculatedGradients can have a gradient
	numberNeighbours = calculatedGradients->length;
	for(i=0; i<numberNeighbours; i++)
	{
		atomIndex = calculatedGradients->array[i];
		
		//Only the derivatives of atoms the main atom interacts with electrostatically
		//are required. At points close to the atom some atoms may overlap the point
		//but are bonded to the main atom so their derivative shouldn't be calculated.
		//Check for this. Also don't calculate anything for the main atom.
		//Get the atoms index
		
		/*if(checkArray[atomIndex] == 0)
			continue;*/
	
		//The derivative of the volume function at the integration point w.r.t the atom,
		//where the integration point, r, is not a function of the atoms position.
		//The deriviate is put into vectorArray[i].
		AdVolumeFunctionPositionDerivative(atomIndex, integrationPoint, coordinates, 
						exclusionValue, pbRadii, (vectorArray + atomIndex));
		interactingAtoms[atomIndex] = true;				
	}
}

inline void AdGBSWUpdateGradient(Vector3D* vector, double angularWeight, 
		double radialWeight, double f3, double* gradient)
{
	double value;

	//If the vector length is not zero add it.
	if(vector->length > 1E-10)
	{
		//The vector contribution of this integration point.
		value = radialWeight*angularWeight*f3;				
		Ad3DVectorScalarMultiply(vector, value);
		
		//Add to the total.
		gradient[0] += vector->vector[0];
		gradient[1] += vector->vector[1];
		gradient[2] += vector->vector[2];
		
		//Clear it
		Ad3DVectorInit(vector);
	}
}

inline void AdGBSWUpdateCrossGradients(IntArrayStruct* calculatedGradients, Vector3D* vectorArray, 
		double angularWeight, double radialWeight, double f3, AdMatrix* gradients)
{
	int i, index, updateNumber;
	int *atomArray;
	double value;
	double* gradient, *array;
	Vector3D* vector;	

	updateNumber = calculatedGradients->length;
	
	if(updateNumber == 0)
		return;
	
	value = radialWeight*angularWeight*f3;
	atomArray = calculatedGradients->array;
	
	for(i=0; i<updateNumber; i++)
	{
		index = atomArray[i];
		vector =  vectorArray + index;
		gradient = gradients->matrix[index];
	
		//The vector contribution of this integration point.				
		Ad3DVectorScalarMultiply(vector, value);
		
		//Add to the total.
		array = vector->vector;
		gradient[0] += array[0];
		gradient[1] += array[1];
		gradient[2] += array[2];
		
		//Clear it
		Ad3DVectorInit(vector);
	}
}

/**
This is the same as AdVolumeExclusionFunction2() reimplemented here so
it can be inlined as it is called very frequently
*/
inline double AdPrivateVEF(Vector3D* r, AdMatrix* coordinates, 
				int* neighbourIndexes, int numberNeighbours, double* radii,
				 IntArrayStruct* contributingAtoms)
{
	int i, j, index, count;
	double smoothingBoundary, checkVal;
	double** matrix;
	Vector3D separation;	
	//Variables for manually inlined AdAtomicVolumeExclusionFunctionNew()
	double lower, upper, difference;
	double volumeExclusionValue, length, radius;
	double* atomPosition, *pointPosition;
	
	if(numberNeighbours == 0)
		return 1.0;
	
	matrix = coordinates->matrix;
	pointPosition = r->vector;

	for(count = 0, volumeExclusionValue = 1, i=0; i<numberNeighbours; i++)
	{
		index = neighbourIndexes[i];
		
		/******* Manual Inline ************/
		
		atomPosition = matrix[index];
		radius = radii[index];
		
		separation.vector[0] = pointPosition[0] - atomPosition[0];
		separation.vector[1] = pointPosition[1] - atomPosition[1];
		separation.vector[2] = pointPosition[2] - atomPosition[2];
				
		upper = radius + w;
		if((AdCartesianDistanceVectorCheck(&separation, upper)) == 0)
		{
			volumeExclusionValue *= 1;
		}
		else
		{	
			lower = radius - w;
			if((AdCartesianDistanceVectorCheck(&separation, 0.5*lower)) == 1)
			{
				volumeExclusionValue = 0;
				i = numberNeighbours;
				count = 0;
			}
			else
			{
				Ad3DVectorLengthSquared(&separation);
				length = separation.length;
				if(length > upper*upper)
				{
					volumeExclusionValue *= 1;
				}
				else if(length < lower*lower)
				{
					volumeExclusionValue = 0;
					i = numberNeighbours;
					count = 0;
				}
				else
				{	
					length = sqrt(length);
					separation.length = length;
					difference = length - radius;
					volumeExclusionValue *= (0.5 + difference*(smoothingConstantA - 
										 smoothingConstantB*difference*difference));
					contributingAtoms->array[count] = index;
					count++;					 
				}
			}
		}
		
		/***********************/
	}
	
	contributingAtoms->length  = count;
	
	return volumeExclusionValue;
}


