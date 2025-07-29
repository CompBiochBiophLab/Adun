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
#include "AdunKernel/AdunCuboidBox.h"

#define DEFAULT_NEIGHBOUR_BUFFER_SIZE 10

/**
Fills the \e lower and \e higher arrays with the max and minimum indexes within \e range of those
in \e indexes. This function primarily makes checks the results aren't less than 0 or greater
than the number of available ticks
*/
void AdGetIndexCheckBounds(int* indexes, int* ticksPerAxis, int range, int* lower, int *higher);

void AdGetIndexCheckBounds(int* indexes, int* ticksPerAxis, int range, int* lower, int *higher)
{
	int i;

	//Get possible extreme values for x,y,z indexes
	for(i=0; i<3; i++)
	{
		lower[i] = indexes[i] - range;
		higher[i] = indexes[i] + range;
	}

	//Check none goes beyond the possible range
	for(i=0; i<3; i++)
		if(lower[i] < 0)
			lower[i] = 0;
	
	for(i = 0; i<3; i++)
		if(higher[i] >= ticksPerAxis[i])
			higher[i] = ticksPerAxis[i]  - 1;
}

/**
Checks if an atom is a neighbour of \e gridPoint returning YES if this is true.
Also checks if the atom overlaps the gridPoint. If this is true \e overlap is YES on return
and NO otherwise
FIXME: Could precompute squared variables.
*/
inline BOOL AdCheckGridPoint(double* atomPostion, double* gridPoint, double gridCut, double overlapCut, double meshSize, BOOL* overlap);

inline BOOL AdCheckGridPoint(double* atomPostion, double* gridPoint, double gridCut, double overlapCut, double meshSize, BOOL* overlap)
{
	BOOL retval = NO;
	int i;
	double gridCutSq;
	double* components;
	Vector3D vector;

	*overlap = NO;

	components = vector.vector;
	//Get components of vector from atom to grid point
	components[0] = gridPoint[0] - atomPostion[0];
	if(fabs(components[0]) > gridCut)
		return retval;
	
	components[1] = gridPoint[1] - atomPostion[1] ;		
	if(fabs(components[1]) > gridCut)
		return retval;
	
	components[2] = gridPoint[2] - atomPostion[2];	
	if(fabs(components[2]) > gridCut)
		return retval;
	
	//Check the length
	gridCutSq = gridCut*gridCut;
	Ad3DVectorLengthSquared(&vector);
	if(vector.length <= gridCutSq)
	{	
		retval = YES;
		//Get the vector from the atom to the furthest corner
		//of the cube around it.
		for(i=0; i<3;i++)
		{
			if(components[i] < 0)
				components[i] -= 0.5*meshSize;
			else
				components[i] += 0.5*meshSize;
		}
		
		Ad3DVectorLength(&vector);
		if(vector.length < overlapCut)
			*overlap = YES;
	}
	
	return retval;	
}

/**
Adds \e atomIndex to the list of neighbours of gridIndex, increasing the stored number of neighbours and 
handling any necessary memeory reallocations.
*/
inline void AdAddNeighbour(unsigned int atomIndex, unsigned int gridIndex, int** neighbourTable, IntArrayStruct* numberNeighbours);

inline void AdAddNeighbour(unsigned int atomIndex, unsigned int gridIndex, int** neighbourTable, IntArrayStruct* numberNeighbours)
{
	int length;
	int* indexes;

	indexes = neighbourTable[gridIndex];
	length = numberNeighbours->array[gridIndex];
	
	//Check is reallocation needed.
	if(length >= DEFAULT_NEIGHBOUR_BUFFER_SIZE)
	{
		indexes = realloc(indexes, (length + 1)*sizeof(int));
		//indexes = NSZoneRealloc(lookupZone, indexes, (length + 1)*sizeof(int));
		neighbourTable[gridIndex] = indexes;
	}
		
	indexes[length] = atomIndex;
	length++;
	numberNeighbours->array[gridIndex] = length;
}

/**
Methods for setting up the integrations points and weights
*/
@implementation AdSmoothedGBTerm (IntegrationMethods)

/**
Creates the integrationPoint matrix of vectors and the
radial and angular weight matrices.
*/
- (void) _initIntegrationVariables
{
	int i, j;
	double radialDistance;
	double* weightsBuffer, *pointsBuffer;
	Vector3D* vector;
	
	//Create matrices
	//One coordinate plus wieght
	radialInfo = [memoryManager allocateMatrixWithRows: numberRadialPoints withColumns: 2];
	//3 coordinates plus weight
	angularInfo = [memoryManager allocateMatrixWithRows: numberAngularPoints withColumns: 4];

	//Create a matrix of Vector3D structs to hold the position vectors of each integration point.
	integrationPoints = AdAllocate3DVectorMatrix(numberRadialPoints, numberAngularPoints);     
	    
	//Generate the angular points - the number of angular points can only be certain values.
	//The angular points are all unit vectors
	
	AdGenerateLebedevGrid(angularInfo); 
	//Scale the weights so they add up to 4PI.
	//This is the integral over the sphere of sin(theta)dtheta dphi which is the 
	//angular part of the CFA integral. FIXME: Check validity of this
	for(i=0; i < angularInfo->no_rows; i++)
		angularInfo->matrix[i][3] *= 4*M_PI;
	
	//Generate the first set of radial points
	weightsBuffer = malloc(5*sizeof(double));
	pointsBuffer =  malloc(5*sizeof(double));
	
	//5 points up to 1 angstrom
	AdGenerateGaussLegendrePoints(integrationStartPoint, 1, 5, pointsBuffer, weightsBuffer);
	for(i=0; i<5; i++)
	{	
		radialInfo->matrix[i][0] = pointsBuffer[i];
		radialInfo->matrix[i][1] = weightsBuffer[i];
	}
	
	weightsBuffer = realloc(weightsBuffer, 19*sizeof(double));
	pointsBuffer = realloc(pointsBuffer, 19*sizeof(double));

	//19 points to 20 angstroms
	AdGenerateGaussLegendrePoints(1, 20, 19, pointsBuffer, weightsBuffer);
	for(i=5; i<numberRadialPoints; i++)
	{	
		radialInfo->matrix[i][0] = pointsBuffer[i-5];
		radialInfo->matrix[i][1] = weightsBuffer[i-5];
	}
	free(pointsBuffer);
	free(weightsBuffer);
		
	double scaledDistance;		
					
	//Calculate the integration points
	for(i=0; i<numberRadialPoints; i++)
	{
		radialDistance = radialInfo->matrix[i][0];
		//The radial weight of each point is the same
		for(j=0; j<numberAngularPoints; j++)
		{
			scaledDistance = radialDistance;
					
			vector = &integrationPoints[i][j];
			//Place the angular point information into the vector struct
			vector->vector[0] = scaledDistance*angularInfo->matrix[j][0];
			vector->vector[1] = scaledDistance*angularInfo->matrix[j][1];
			vector->vector[2] = scaledDistance*angularInfo->matrix[j][2];
			
			vector->length = scaledDistance;
		}
	}	
}

- (void) _cleanUpIntegrationVariables
{
	[memoryManager freeMatrix: radialInfo];
	[memoryManager freeMatrix: angularInfo];
	AdFree3DVectorMatrix(integrationPoints);
}

@end 

/**
Methods for creating and updating the lookup table
*/
@implementation AdSmoothedGBTerm (LookupTableMethods)


- (void) _freeNeighbourTable
{
	int i, numberGridPoints;
	
	if(neighbourTable == NULL)
		return;
	
	numberGridPoints = [soluteGrid numberOfPoints];

	//Release last lookup table
	for(i=0; i<numberGridPoints; i++)
	{
		if(neighbourTable[i] != NULL)	
		{	
			//NSZoneFree(lookupZone, neighbourTable[i]);
			free(neighbourTable[i]);
		}
	}
	
	//NSZoneFree(lookupZone, neighbourTable);
	free(neighbourTable);
}

/**
Creates lookup table ...
*/
- (BOOL) _createLookupTable
{
	BOOL overlap, retval;
	int counter = 0;
	int i, xIndex, yIndex, zIndex, closestPoint;
	int range, length;
	int gridIndex, atomIndex, numberGridPoints;
	int *array, ticksPerAxis[3]; 
	int indexes[3], lower[3], higher[3];
	double gridCut, gridCutSquared, overlapCut;
	double* atomPosition, *pointPosition;
	double **cMatrix, **gMatrix;
	NSArray* divisions;
	Vector3D vector;
	
	//Free last table
	NSDebugLLog(@"AdSmoothedGBTerm" ,@"Freeing lookup table");
	[self _freeNeighbourTable];
	NSDebugLLog(@"AdSmoothedGBTerm" ,@"Done");
	
	//Create new table
	numberGridPoints = [soluteGrid numberOfPoints];
	//neighbourTable = NSZoneMalloc(lookupZone, numberGridPoints*sizeof(int*));
	neighbourTable =  malloc(numberGridPoints*sizeof(int*));
	for(i=0; i<numberGridPoints; i++)
	{
		neighbourTable[i] = calloc(10, sizeof(int));
		//neighbourTable[i] = NSZoneCalloc(lookupZone, 10, sizeof(int));
		numberNeighbours.array[i] = 0;
	}
		
	//Set up some vars	
	cMatrix = [system coordinates]->matrix;
	gMatrix = [soluteGrid grid]->matrix;
	memset(overlapBuffer, 0, numberGridPoints*sizeof(uint_fast8_t));
	
	//Get ticks per axis
	divisions = [soluteGrid divisions];
	for(i=0; i<3; i++)
		ticksPerAxis[i] = [[divisions objectAtIndex: i] intValue];
	
	retval = YES;
	for(i=0; i<numberOfAtoms; i++)
	{
		atomPosition = cMatrix[i];
		
		//Temp
		vector.vector[0] = atomPosition[0];
		vector.vector[1] = atomPosition[1];
		vector.vector[2] = atomPosition[2];
		
		//Check if the grid point exists.
		gridIndex = [soluteGrid indexOfGridPointNearestToPoint: &vector 
				indexes: indexes];
		if(gridIndex == -1)
		{
			retval = NO;
			break;
		}
			
		gridCut = gridCutMatrix->matrix[i][0];
		overlapCut = pbRadii[i] - smoothingLength;
		pointPosition = gMatrix[gridIndex];
		
		///The atom should always be a neighbour of its nearest grid point. 
		if(AdCheckGridPoint(atomPosition, pointPosition, gridCut, overlapCut, meshSize, &overlap))
		{
			AdAddNeighbour(i, gridIndex, neighbourTable, &numberNeighbours);
			if(overlap)
			{
				overlapBuffer[gridIndex] = 1;
				counter++;
			}
		}
		else
		{
			NSWarnLog(@"Error - Atom %d is not a neighbour of its nearest grid point", i);
			retval = NO;
			break;
		}
		
		//This point could be a neighbour of grid points a maximum of gridCut + meshSize/2 away  
		//in each direction.
		//We need to check each of these.
		range = ceil((gridCut + sqrt(3)*meshSize)/meshSize);
		
		AdGetIndexCheckBounds(indexes, ticksPerAxis, range, lower, higher);		
		
		//Check these grid points
		closestPoint = gridIndex;
		for(xIndex = lower[0]; xIndex < higher[0]; xIndex++)
		{
			for(yIndex = lower[1]; yIndex < higher[1]; yIndex++)
			{
				for(zIndex = lower[2]; zIndex < higher[2]; zIndex++)
				{
					gridIndex = ticksPerAxis[2]*ticksPerAxis[1]*xIndex + ticksPerAxis[2]*yIndex + zIndex;
					pointPosition = gMatrix[gridIndex];
					
					//Skip the main point
					if(gridIndex == closestPoint)
						continue;
					
					if(AdCheckGridPoint(atomPosition, pointPosition, gridCut, overlapCut, meshSize, &overlap))
					{
						//FIXME - Double checking
						AdAddNeighbour(i, gridIndex, neighbourTable, &numberNeighbours);
						if(overlap)
						{
							overlapBuffer[gridIndex] = 1;
							counter++;
						}
					}
				}
			}
		}
	}
	
	//trim the neighbour table and find grid points with no neighbours.
	for(i=0; i<numberGridPoints; i++)
	{
		//realloc
		array = neighbourTable[i];
		length = numberNeighbours.array[i];
		if(length == 0)
		{
			//NSZoneFree(lookupZone, array);
			free(array);
			neighbourTable[i] = NULL;
		}
		else
		{
			//neighbourTable[i] = NSZoneRealloc(lookupZone, array, length*sizeof(int));
			neighbourTable[i] = realloc(array, length*sizeof(int));		
		}
	}
	
	return retval;
}

- (void) _createGrid
{
	double xDim, yDim, zDim;
	NSNumber *number;
	NSArray* spacing, *extremes, *axisExtremes;
	NSArray *centre;

	if(soluteGrid != nil)
		[soluteGrid release];

	number = [NSNumber numberWithDouble: meshSize];
	spacing = [NSArray arrayWithObjects: number, number, number, nil];
	
	//Get the extremes of the solute
	cavity = [[AdMoleculeCavity alloc] initWithSystem: system factor: 1.5];
	extremes = [cavity cavityExtremes];
	centre = [cavity centre];
	[cavity release];
	
	//Use the extremes to create a cuboid cavity
	axisExtremes = [extremes objectAtIndex: 0];
	xDim = [[axisExtremes objectAtIndex: 0] doubleValue] - [[axisExtremes objectAtIndex: 1] doubleValue];
	axisExtremes = [extremes objectAtIndex: 1];
	yDim = [[axisExtremes objectAtIndex: 0] doubleValue] - [[axisExtremes objectAtIndex: 1] doubleValue];							
	axisExtremes = [extremes objectAtIndex: 2];
	zDim = [[axisExtremes objectAtIndex: 0] doubleValue] - [[axisExtremes objectAtIndex: 1] doubleValue];
	
	cavity = [[AdCuboidBox alloc] 
			initWithCavityCentre: centre
			xDimension: xDim 
			yDimension: yDim 
			zDimension: zDim];
	soluteGrid = [[AdGrid alloc] initWithSpacing: spacing cavity: cavity];
	
	//Create function pointer to indexOfGridPointNearestToPoint:
	gridSelector = @selector(indexOfGridPointNearestToPoint:);	
	getIndex = (int (*)(id, SEL, Vector3D*))[soluteGrid methodForSelector: gridSelector];
}

- (void) _initLookupTableVariables
{
	int i;
	double value, searchCutoff = 0;
	
	//Create the lookup grid
	[self _createGrid];
	
	//lookupZone = NSCreateZone(numberOfAtoms*numberOfAtoms, numberOfAtoms, 1);	
	
	//Array holding the number of atoms associated with each grid point
	numberNeighbours.array = [memoryManager allocateArrayOfSize: sizeof(int)*[soluteGrid numberOfPoints]];
	numberNeighbours.length = [soluteGrid numberOfPoints];
	
	//Array holding gridCut for each atom.
	gridCutMatrix = [memoryManager allocateMatrixWithRows: numberOfAtoms withColumns:2];
	for(i=0; i<numberOfAtoms;i++)
	{
		value = pbRadii[i] + smoothingLength + sqrt(3)*0.5*meshSize + cutBuffer;
		if(value > searchCutoff)
			searchCutoff = value;
			
		gridCutMatrix->matrix[i][0] = value;
		gridCutMatrix->matrix[i][1] = value*value;
	}

	//Allocate the buffer for tracking which grid points are overlapped.
	//overlapBuffer = NSZoneCalloc(lookupZone, [soluteGrid numberOfPoints], sizeof(uint_fast8_t));
	overlapBuffer = calloc([soluteGrid numberOfPoints], sizeof(uint_fast8_t));
		
	//Create the lookup table.
	neighbourTable = NULL;	
	[self _createLookupTable];
	
	//Set the search cutoff distance.
	//Do this after look-up table creation as during it
	//we want the searchCutoff to be its default value
	//of meshSize/2 so atoms not covered by the grid can be id.
	[soluteGrid setSearchCutoff: searchCutoff];	
	
	//Find the first radial point after the cutoff
	radialEnd = 0;
	for(i=0; i<radialInfo->no_rows;i++)
	{
		if(radialInfo->matrix[i][0] > cutoff)
		{
			radialEnd = i;
			break;
		}
	}	
}

- (void) _cleanUpLookupTableVariables
{
	[self _freeNeighbourTable];	
	[soluteGrid release];
	[cavity release];
	//NSZoneFree(lookupZone, overlapBuffer);
	free(overlapBuffer);
	[memoryManager freeMatrix: gridCutMatrix];
	[memoryManager freeArray: numberNeighbours.array]; 
	
	soluteGrid = nil;
	cavity = nil;
}

- (void) updateLookupTable
{
	BOOL value;
	
	value = [self _createLookupTable];
	//Check if all atoms were allocated to grid points
	//FIXME: Possible change way to detecting need for grid change.
	if(!value)
	{
		NSWarnLog(@"Rebuilding grid");
		[self _cleanUpLookupTableVariables];
		[self _initLookupTableVariables];
	}	
}

@end
