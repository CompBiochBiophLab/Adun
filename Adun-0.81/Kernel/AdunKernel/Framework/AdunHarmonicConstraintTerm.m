/*
 Project: AdunKernel
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Author: Michael Johnston
 
 Created: 11/07/2008 by michael johnston
 
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
#include <AdunKernel/AdunHarmonicConstraintTerm.h>
#include <Base/AdVector.h>

@implementation AdHarmonicConstraintTerm

/**
 Initialises the object to operate on \e system
 */
- (id) initWithSystem: (id) system
{
	NSIndexSet* indexSet;

	indexSet = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [system numberOfElements])];
	return [self initWithSystem: system 
		forceConstant: 1000/STCAL 
		constrainingElements: indexSet];
}

- (id) initWithSystem: (id) system
	forceConstant: (double) forceConstant
	contrainingElementsMatchingSelectionString: (NSString*) selectionString
{
	[NSException raise: NSInternalInconsistencyException
		format: @"Method %@ not implemented", NSStringFromSelector(_cmd)];
}

- (id) initWithSystem: (id) system
	forceConstant: (double) aDouble
	constrainingElementsWithValue: (id) selectionValue
	forProperty: (NSString*) property 
{	
	int i;
	NSArray* properties;
	NSEnumerator* propertiesEnum;
	NSMutableIndexSet* indexSet;
	id value;

	properties = [[system elementProperties] columnWithHeader: property];
	if(properties == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Property %@ does not exist", property];

	indexSet = [NSMutableIndexSet indexSet];
	propertiesEnum = [properties objectEnumerator];
	while(i=0, value = [propertiesEnum nextObject])
	{
		if([value isEqual: selectionValue])
			[indexSet addIndex: i];
		i++;	
	}
	
	return [self initWithSystem: system
		forceConstant: aDouble 
		constrainingElements: indexSet];
}

- (id) initWithSystem: (id) system
	forceConstant: (double) aDouble
	cavity: (id) cavity
	constraintType: (AdCavityConstraintType) constraintType
{	
	int i;
	AdMatrix* coordinates;
	NSMutableIndexSet* indexSet;
	
	coordinates = [system coordinates];
	indexSet = [NSMutableIndexSet indexSet];
	
	if(constraintType == AdCavityInternalConstraint)
	{
		for(i=0; i<coordinates->no_rows; i++)
		{
			if([cavity isPointInCavity: coordinates->matrix[i]])
				[indexSet addIndex: i];
		}
	}
	else if(constraintType == AdCavityExternalConstraint)
	{
		for(i=0; i<coordinates->no_rows; i++)
		{
			if(![cavity isPointInCavity: coordinates->matrix[i]])
				[indexSet addIndex: i];
		}
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
			    format: @"Invalid constraint type specifier provided"];
	}
	
	return [self initWithSystem: system 
		      forceConstant: aDouble 
	       constrainingElements: indexSet];	
}

- (id) initWithSystem: (id) system
	forceConstant: (double) aDouble
	container: (AdContainerDataSource*) container
	constraintType: (AdCavityConstraintType) constraintType
{	
	id cavity;

	//Get all elements in the cavity
	cavity = [container cavity];
	[self initWithSystem: system 
		forceConstant: aDouble 
		cavity: cavity
		constraintType: constraintType];
}

/**
 Designated initialiser
 */
- (id) initWithSystem: (id) system 
	forceConstant: (double) aDouble
 constrainingElements: (NSIndexSet*) indexSet
{
	if(self = [super init])
	{
		memoryManager = [AdMemoryManager appMemoryManager];
		forceConstant = aDouble;
		elementIndexes = [indexSet copy]; 
		//This will create a AdMatrix which is a copy of the 
		//systems coordinates matrix
		originalCoordinates = [[system valueForKey: @"coordinates"] cRepresentation];
		forceMatrix = [memoryManager allocateMatrixWithRows: originalCoordinates->no_rows 
				withColumns: originalCoordinates->no_columns];
		constrainedSystem = [system retain];		
	}
	
	return self;
}

- (void) dealloc
{
	[elementIndexes release];
	[constrainedSystem release];
	[super dealloc];
	[memoryManager freeMatrix: originalCoordinates];
	[memoryManager freeMatrix: forceMatrix];
}

- (void) evaluateForces
{
	int index, i, j;
	double forceMagnitude, rLength;
	Vector3D difference;
	AdMatrix* newCoordinates;

	AdSetDoubleMatrixWithValue(forceMatrix, 0.0);

	newCoordinates = [constrainedSystem coordinates];
	index = [elementIndexes firstIndex];
	
	energy = 0;
	while(index != NSNotFound)
	{
		//Vector from Original to New position
		for(i=0; i<3; i++)
			difference.vector[i] = newCoordinates->matrix[index][i] - originalCoordinates->matrix[index][i];
			
		Ad3DVectorLength(&difference);
		
		forceMagnitude = -1*forceConstant*difference.length;
		
		//Force on the atom is towards original position
		rLength = 1/difference.length;
		for(j=0;j<3;j++)
			forceMatrix->matrix[index][i] = forceMagnitude*difference.vector[i]*rLength;
		
		energy += -1*difference.length*forceMagnitude*0.5; 
		index = [elementIndexes indexGreaterThanIndex: index];
	}
}

- (void) evaluateEnergy
{
	int index, i;
	Vector3D difference;
	AdMatrix* newCoordinates;
	
	energy = 0;
	newCoordinates = [constrainedSystem coordinates];
	index = [elementIndexes firstIndex];
	
	while(index != NSNotFound)
	{
		for(i=0; i<3; i++)
			difference.vector[i] = newCoordinates->matrix[index][i] - originalCoordinates->matrix[index][i];
		
		Ad3DVectorLength(&difference);	
		
		energy += difference.length*difference.length*forceConstant*0.5; 
		index = [elementIndexes indexGreaterThanIndex: index];
	}
}

- (double) energy
{
	return energy;
}

- (AdMatrix*) forces
{
	return forceMatrix;
}

- (void) setExternalForceMatrix: (AdMatrix*) matrix
{
	NSWarnLog(@"AdHarmonicConstraint does not use external matrices");	
}

- (BOOL) usesExternalForceMatrix
{
	return NO;
}

- (id) system
{
	return [[constrainedSystem retain] autorelease];
}

- (void) setSystem: (id) system
{
	NSWarnLog(@"AdHarmonicConstraint term method setSystem: is not implemented");
}

- (BOOL) canEvaluateEnergy
{
	return YES;
}

- (BOOL) canEvaluateForces
{
	return YES;
}

@end
