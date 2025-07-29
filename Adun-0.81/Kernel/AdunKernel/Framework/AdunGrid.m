/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunGrid.h"
//FIXME: Coupling AdGrid to a specific delegate class.
//There may be a better way around this.
//See indexOfGridPointNearestToPoint: for more info,
#include "AdunKernel/AdunCuboidBox.h"

/**
Convenience function used during searching for the grid point nearest a point.
Indexes can be assigned to a point if it lies within half a tick spacing of the
maximum and minumum grid points on a given axis.
However some points will be greater than this distance away but still within the defined
search cutoff.
In this case this function determines if the point is within the cutoff and returns the
correct index for it.
\param grid The matrix of grid points
\param numberGridPoints The number of grid points.
\param axis The axis being searched 0 = x aixs, 1 = yaxis, 2 = zaxis
\param axisTicks The number of ticks on that axis
\param assignedIndex The index assigned to the point by the standard search. This is
normally the index of the tick on the given axis that is nearest the point.
However in this case the assignedIndex will be <0 or >= axisTicks.
\param position The position of the point
\param relativePosition The position of the point relative to the furthest grid point from the
origin in the -,-,- quadrant.
\param searchCutoff The cutoff distance.
*/
inline int AdCheckIndex(double** grid, int gridPoints, int axis, int axisTicks,  int assignedIndex, 
			Vector3D* position, Vector3D* relativePosition,  double searchCutoff);

@implementation AdGrid

- (void) _translateBy: (Vector3D*) translationVector
{
	int i, k;

	for(i=0; i<gridPoints;i++)
		for(k=0; k<3; k++)
			grid->matrix[i][k] += translationVector->vector[k];
}

- (void) _trimGridToCavity
{
	int i,j;
	int cavityPoints;
	int* cavityArray;
	AdMatrix* newGrid;

	cavityArray = (int*)malloc(gridPoints*sizeof(int));
	for(cavityPoints=0, i=0; i<gridPoints; i++)
		if([cavity isPointInCavity: grid->matrix[i]])
		{
			cavityArray[cavityPoints] = i;
			cavityPoints++;
		}

	NSDebugLLog(@"AdGrid", @"There are %d points in the cavity", cavityPoints);

	newGrid = [memoryManager allocateMatrixWithRows: cavityPoints withColumns: 3];
	for(i=0; i<cavityPoints; i++)
		for(j=0; j<3; j++)
			newGrid->matrix[i][j] = grid->matrix[cavityArray[i]][j];

	free(cavityArray);
	[memoryManager freeMatrix: grid];
	grid = newGrid;
	gridPoints = cavityPoints;
}

- (void)  _createGrid
{
	int i, j, k, count;
	Vector3D originOffset[3];
	Vector3D* centre;

	for(gridPoints = 1, i=0; i<3; i++)
		gridPoints *= ticksPerAxis[i]; 
	
	NSDebugLLog(@"AdGrid", @"Number of grid points is %d.\n", gridPoints);

	//first we create the grid in the (+,+,+) sector. Then we move it so its
	//centred on the origin
		
	grid = [memoryManager allocateMatrixWithRows: gridPoints
				withColumns: 3];

	NSDebugLLog(@"AdGrid", @"Allocating grid points");

	count = 0;
	for(i=0; i < ticksPerAxis[0]; i++)
		for(j=0; j< ticksPerAxis[1]; j++)
			for(k=0; k < ticksPerAxis[2]; k++)
			{
				grid->matrix[count][0] = i*[[gridSpacing objectAtIndex:0] doubleValue];
				grid->matrix[count][1] = j*[[gridSpacing objectAtIndex:1] doubleValue];
				grid->matrix[count][2] = k*[[gridSpacing objectAtIndex:2] doubleValue];
				count++;
			}

	NSDebugLLog(@"AdGrid", @"Moving grid to origin");
	
	//move to origin	

	for(i=0; i< 3; i++)
		originOffset->vector[i] = -1*((ticksPerAxis[i]-1)*[[gridSpacing objectAtIndex:i] doubleValue])/2;

	[self _translateBy: originOffset];

	//now translate everything to the cavity center
	
	centre = [cavity cavityCentre];
	cavityCentre.vector[0] = centre->vector[0];
	cavityCentre.vector[1] = centre->vector[1];
	cavityCentre.vector[2] = centre->vector[2];

	NSDebugLLog(@"AdGrid", @"Moving grid to cavity center");
	[self _translateBy: &cavityCentre];

	//trim the grid by removing points not in the cavity

	NSDebugLLog(@"AdGrid", @"Trimming grid to cavity");
	[self _trimGridToCavity];
	
	//Create the minimum point for use in searching
	minPoint[0] = grid->matrix[0][0] - 0.5/xSpacingR;
	minPoint[1] = grid->matrix[0][1] - 0.5/ySpacingR;
	minPoint[2] = grid->matrix[0][2] - 0.5/zSpacingR;
}

/********************

Object Creation

**********************/

- (void) _cavityInitialisation
{
	int axisLength, i;
	NSEnumerator* extremeEnum;
	id extreme;

 	cavityExtremes = [cavity cavityExtremes];

	NSDebugLLog(@"AdGrid", @"Cavity Extremes %@", cavityExtremes);

	extremeEnum = [cavityExtremes objectEnumerator];
	i = 0;
	while((extreme = [extremeEnum nextObject]))
	{
		axisLength = [[extreme objectAtIndex: 0] intValue] - [[extreme objectAtIndex: 1] intValue];
		ticksPerAxis[i] = ceil(axisLength/[[gridSpacing objectAtIndex: i] doubleValue]);
		NSDebugLLog(@"AdGrid", @"There are %d ticks on axis %d", ticksPerAxis[i], i);
		i++;
	}

	xTicks = ticksPerAxis[0];
	yTicks = ticksPerAxis[1];
	zTicks = ticksPerAxis[2];

	NSDebugLLog(@"AdGrid", @"%@ %@", gridSpacing, cavityExtremes);
}

//Specialised initialisers

+ (id) gridWithDensity: (double) density cavity: (id) aCavity
{
	id gridObject;

	gridObject = [[AdGrid alloc] initWithDensity: density
			cavity: aCavity];

	return [gridObject autorelease];
}

+ (id) gridWithDivisions: (NSArray*) divisions cavity: (id) aCavity 
{
	id gridObject;

	gridObject = [[AdGrid alloc] initWithDivisions: divisions
			cavity: aCavity];

	return [gridObject autorelease];
}

+ (id) gridWithSpacing: (NSArray*) spacing cavity: (id) aCavity
{
	id gridObject;

	gridObject = [[AdGrid alloc] initWithSpacing: spacing
			cavity: aCavity];

	return [gridObject autorelease];
}

- (id) initWithDensity: (double) density cavity: (id) cavity 
{
	NSWarnLog(@"Method %@ not implemented", NSStringFromSelector(_cmd));
	return nil;
}

- (id) initWithDivisions: (NSArray*) divisions cavity: (id) cavity
{
	NSWarnLog(@"Method %@ not implemented", NSStringFromSelector(_cmd));
	return nil;
}

- (id) init
{
	return [self initWithSpacing: 
		[NSArray arrayWithObjects: 
			[NSNumber numberWithInt: 1],
			[NSNumber numberWithInt: 1],
			[NSNumber numberWithInt: 1],
			nil]];
}

- (id) initWithSpacing: (NSArray*) spacing
{
	return [self initWithSpacing: spacing
		cavity: nil];
}

- (id) initWithSpacing: (NSArray*) spacing cavity: aCavity
{
	if((self = [super init]))
	{
		memoryManager = [AdMemoryManager appMemoryManager];
		grid = NULL;

		//Set up default spacing if none was provided
		if(spacing == nil)
			spacing = [NSArray arrayWithObjects: 
					[NSNumber numberWithInt: 1],
					[NSNumber numberWithInt: 1],
					[NSNumber numberWithInt: 1],
					nil];
			
		gridSpacing = [spacing copy];
		//Extract the spacing from the array for quick access.
		xSpacingR = 1/[[gridSpacing objectAtIndex: 0] doubleValue];
		ySpacingR = 1/[[gridSpacing objectAtIndex: 1] doubleValue];
		zSpacingR = 1/[[gridSpacing objectAtIndex: 2] doubleValue];
		
		//Default search cutoff
		[self setSearchCutoff: 1.5];

		if(aCavity != nil)
			[self setCavity: aCavity];
	}

	return self;
}

- (id) initWithDictionary: (NSDictionary*) dict
{
	return [self initWithSpacing: [dict objectForKey: @"spacing"]
		cavity: [dict objectForKey: @"cavity"]];
}

- (void) dealloc
{
	[gridSpacing release];
	[memoryManager freeMatrix: grid];
	[super dealloc];
}

/*******************

Public Methods

********************/

- (void) cavityDidMove
{
	int i;
	Vector3D translation, *newCentre;	

	if(grid == NULL)
		return;

	newCentre = [cavity cavityCentre];
	for(i=0; i<3; i++)
	{
		translation.vector[i] = newCentre->vector[i] - cavityCentre.vector[i];
		cavityCentre.vector[i] = newCentre->vector[i];
	}

	[self _translateBy: &translation];
	
	//Create the minimum point for use in searching
	minPoint[0] = grid->matrix[0][0] - 0.5/xSpacingR;
	minPoint[1] = grid->matrix[0][1] - 0.5/ySpacingR;
	minPoint[2] = grid->matrix[0][2] - 0.5/zSpacingR;
}

- (void) resetCavity
{
	if(cavity == nil)
		return;

	//free the last grid
	if(grid != NULL)
		[memoryManager freeMatrix: grid];

	[self _cavityInitialisation];
	[self _createGrid];
}

//Setting the cavity. The cavity is an object that conforms to the
//AdGridDelegate protocol. It is not retained. 

- (void) setCavity: (id) anObject
{
	if([anObject conformsToProtocol: @protocol(AdGridDelegate)])
		cavity = anObject;
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Delegate does not conform to AdGridDelegate protocol"];

	//free the last grid
	
	if(grid != NULL)
		[memoryManager freeMatrix: grid];

	[self _cavityInitialisation];
	[self _createGrid];
}


/*************

Accessors

**************/

//The grids delegate object

- (id) cavity
{
	return cavity;
}

- (AdMatrix*) grid
{
	return grid;
}

- (NSArray*) spacing
{
	return [[gridSpacing copy] autorelease];
}

- (void) setSpacing: (NSArray*) anArray
{
	if([anArray count] != 3)
	{
		NSWarnLog(@"Incorrect number of elements in array");
		return;
	}
	
	[gridSpacing release];
	gridSpacing = [anArray copy];
	
	//Extract the spacing from the array for quick access.
	xSpacingR = 1/[[gridSpacing objectAtIndex: 0] doubleValue];
	ySpacingR = 1/[[gridSpacing objectAtIndex: 1] doubleValue];
	zSpacingR = 1/[[gridSpacing objectAtIndex: 2] doubleValue];
	
	//Free the last grid and recreate
	[self resetCavity];
}

- (NSArray*) divisions
{
	return [NSArray arrayFromCIntArray: ticksPerAxis ofLength: 3];
}

- (int) numberOfPoints
{
	return grid->no_rows;
}

/*
Standard search for closest point. Works with all grid shapes
*/
- (int) _standardGridSearch: (Vector3D*) point
{
	int i;
	BOOL foundX, foundY;
	double dx, dy, dz;

	foundX = foundY = NO;
	dx = 1/xSpacingR*0.5;
	dy = 1/ySpacingR*0.5;
	dz = 1/zSpacingR*0.5;
	
	for(i=0; i<gridPoints; i++)
	{
		if(!foundX)
			if(fabs(grid->matrix[i][0] - point->vector[0]) < dx)
				foundX = YES;
		
		if(foundX && !foundY)
			if(fabs(grid->matrix[i][1] - point->vector[1]) < dy)
				foundY = YES;
		
		if(foundY && foundX)
			if(fabs(grid->matrix[i][2] - point->vector[2]) < dz)
				break;
	}
	
	//The point may not be within dx,dy,dz of any grid point
	//FIXME: Add searchCutoff
	if(i == gridPoints)
		i  =  -1;
	
	return i;	
}

- (int) indexOfGridPointNearestToPoint: (Vector3D*) point
{
	BOOL check = YES;
	int index;
	Vector3D relativePos;
	double xIndex, yIndex, zIndex;
	double* holder;	
		
	/*if([cavity isMemberOfClass: [AdCuboidBox class]])
	{*/
		//Optimised search for cuboid box
		//This couples AdGrid to an the type of class of a delegate
		//which is quite against the spirit of delegates.
		//However this type of box is very efficent to search.
		//Adding a method to AdGridDelegate e.g. isCuboid 
		//to identify this type of box seemes redundant since I think this is the only 
		//possible type .... 
		//Possibly move search to cavity?!
		
		//Get the position relative to the -x_max, -y_max, -z_max grid point i.e. the first
		holder = point->vector;
		
		relativePos.vector[0] = holder[0] - minPoint[0];
		relativePos.vector[1] = holder[1] - minPoint[1];
		relativePos.vector[2] = holder[2] - minPoint[2];
		
		//Find the neareset tick to the point in each direction
		//Note this identifies the tick within spacing/2 of the point.
		//i.e. upto spacing/2 outside the grid area.
		
		xIndex = floor(relativePos.vector[0]*xSpacingR);
		yIndex = floor(relativePos.vector[1]*ySpacingR);
		zIndex = floor(relativePos.vector[2]*zSpacingR);
		
		//Check it within bounds
		if((xIndex >= xTicks) || (xIndex < 0))
		{
			xIndex = AdCheckIndex(grid->matrix, gridPoints, 0, xTicks, 
					xIndex, point, &relativePos, searchCutoff);
			if(xIndex == -1)
			{
				index = -1;
				check = NO;
			}
		}
		
		if(check)
		{
			//Check it within bounds
			if((yIndex >= yTicks) || (yIndex < 0))
			{
				yIndex = AdCheckIndex(grid->matrix, gridPoints, 1, yTicks, 
						yIndex, point, &relativePos, searchCutoff);
				if(yIndex == -1)
				{
					index = -1;
					check = NO;
				}
			}
		}
		
		if(check)
		{
			if((zIndex >= zTicks) || (zIndex < 0))
			{
				zIndex = AdCheckIndex(grid->matrix, gridPoints, 2, zTicks, 
						     zIndex, point, &relativePos, searchCutoff);
				if(zIndex == -1)
				{
					index = -1;
					check = NO;	
				}
			}	
		}
	
		if(check)
		{
			//The index of the point at offset (+x, +y, +z) from the first point
			//is ticksPerAxis[2]*ticksPerAxis[1]*x + ticksPerAxis[2]*y + z.
			index = zTicks*yTicks*xIndex + zTicks*yIndex + zIndex;
		}
	/*}
	else
		index = [self _standardGridSearch: point];*/

	return index;
}

//FIXME: Likely combine with above.
//This is just temporary.
- (int) indexOfGridPointNearestToPoint: (Vector3D*) point indexes: (int*) array
{
	BOOL check = YES;
	int index;
	Vector3D relativePos;
	double xIndex, yIndex, zIndex;
	double* holder;	
		
	//Get the position relative to the -x_max, -y_max, -z_max grid point i.e. the first
	holder = point->vector;
	
	relativePos.vector[0] = holder[0] - minPoint[0];
	relativePos.vector[1] = holder[1] - minPoint[1];
	relativePos.vector[2] = holder[2] - minPoint[2];
	
	xIndex = floor(relativePos.vector[0]*xSpacingR);
	//Check it within bounds
	if((xIndex >= xTicks) || (xIndex < 0))
	{
		xIndex = AdCheckIndex(grid->matrix, gridPoints, 0, xTicks, 
				      xIndex, point, &relativePos, searchCutoff);
		if(xIndex == -1)
		{
			index = -1;
			check = NO;
		}
	}
	
	if(check)
	{
		yIndex = floor(relativePos.vector[1]*ySpacingR);
		//Check it within bounds
		if((yIndex >= yTicks) || (yIndex < 0))
		{
			yIndex = AdCheckIndex(grid->matrix, gridPoints, 1, yTicks, 
					      yIndex, point, &relativePos, searchCutoff);
			if(yIndex == -1)
			{
				index = -1;
				check = NO;
			}
		}
	}
	
	if(check)
	{
		zIndex = floor(relativePos.vector[2]*zSpacingR);
		if((zIndex >= zTicks) || (zIndex < 0))
		{
			zIndex = AdCheckIndex(grid->matrix, gridPoints, 2, zTicks, 
					      zIndex, point, &relativePos, searchCutoff);
			if(zIndex == -1)
			{
				index = -1;
				check = NO;	
			}
		}	
	}
	
	if(check)
	{
		//The index of the point at offset (+x, +y, +z) from the first point
		//is ticksPerAxis[2]*ticksPerAxis[1]*x + ticksPerAxis[2]*y + z.
		index = zTicks*yTicks*xIndex + zTicks*yIndex + zIndex;
		array[0] = xIndex;
		array[1] = yIndex;
		array[2] = zIndex;
	}
	
	return index;
}

- (double) searchCutoff
{
	return searchCutoff;
}

- (void) setSearchCutoff: (double) value
{
	if(value < 0)
		return;

	searchCutoff = value;
}

/****************

Coding

*****************/

- (id) initWithCoder: (NSCoder*) decoder
{
	int i;
	AdDataMatrix* matrix;
	Vector3D* centre;

	if([decoder allowsKeyedCoding])
	{	
		memoryManager = [AdMemoryManager appMemoryManager];
		matrix = [decoder decodeObjectForKey: @"Grid"];
		cavity = [decoder decodeObjectForKey: @"Cavity"];
		gridSpacing = [[decoder decodeObjectForKey: @"GridSpacing"] retain];

		grid = [matrix cRepresentation];
		gridPoints = grid->no_rows;
		
		//Extract the spacing from the array for quick access.
		xSpacingR = [[gridSpacing objectAtIndex: 0] doubleValue];
		ySpacingR = [[gridSpacing objectAtIndex: 1] doubleValue];
		zSpacingR = [[gridSpacing objectAtIndex: 2] doubleValue];

		//recalculate ticksPerAxis and cavityExtremes
		[self _cavityInitialisation];
		
		centre = [cavity cavityCentre];
		for(i=0; i<3; i++)
			cavityCentre.vector[i] = centre->vector[i];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	AdDataMatrix* matrix;

	if([encoder allowsKeyedCoding])
	{
		matrix = [AdDataMatrix matrixFromADMatrix: grid];
		[encoder encodeObject: matrix forKey: @"Grid"];
		[encoder encodeConditionalObject: cavity forKey: @"Cavity"];
		[encoder encodeObject: gridSpacing forKey: @"GridSpacing"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}

@end

inline int AdCheckIndex(double** grid, int numberGridPoints, int axis, int axisTicks,  int assignedIndex, 
			Vector3D* position, Vector3D* relativePosition,  double searchCutoff)
{
	int index;
	double distance;

	if(assignedIndex < 0)
		distance = fabs(relativePosition->vector[axis]);
	else
		distance = position->vector[axis] - grid[numberGridPoints -1][axis];
	
	if(distance < searchCutoff)
		index = (assignedIndex < 0) ? 0 : axisTicks - 1;
	else
		index = -1;
		
	return index;	
}
