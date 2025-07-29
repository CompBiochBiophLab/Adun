/*
   Project: Adun

   Copyright (C) 2005, 2006  Michael Johnston & Jordi Villá-Freixa

   Authors: Michael Johnston
   Adapted from code by Ignacio Fdez. Galván

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
#include "AdunKernel/AdunMoleculeCavity.h"
#include "AdunKernel/AdunSystem.h"

@implementation AdMoleculeCavity

- (double) _calculateVDWRadiiForAtom: (int) index
{
	double radius, value1, value2;

	if([vdwType isEqual: @"A"])
	{
		value1 = [[vdwParameters elementAtRow: index
				ofColumnWithHeader: @"VDW A"]
				doubleValue];

		value2 = [[vdwParameters elementAtRow: index
				ofColumnWithHeader: @"VDW B"]
				doubleValue];
		if(value2 == 0)
			radius = 1.5;
		else	
			radius = 0.5*pow((value1/value2), 1.0/3.0);
	}
	else if([vdwType isEqual: @"B"])
	{
		value1 = [[vdwParameters elementAtRow: index
				ofColumnWithHeader: @"VDW Separation"]
				doubleValue];
		radius = value1/pow(2, 1.0/6.0);
	}
	else 
		radius = 1.5;

	return radius;
}

- (void) _calculateCavityExtremes
{
	int i, j;
	double radius, a, b;
	double min[3], max[3];
	NSArray* axisExtremes;

	// Find the extremes of the "cavity"

	if(moleculeConfiguration == nil || vdwParameters == nil)
		return;

	for (i=0; i<moleculeCoordinates->no_rows; i++)
	{
		if(vdwParameters == nil)
			radius = 3*factor;
		else	
			radius = factor*[self _calculateVDWRadiiForAtom: i];
		
		for (j=0; j<3; j++)
		{
			a = moleculeCoordinates->matrix[i][j] - radius;
			b = a+2*radius;
			if (a < min[j] || i == 0) min[j] = a;
			if (b > max[j] || i == 0) max[j] = b;
		}
	}

	[cavityExtremes removeAllObjects];
	for(i=0; i<3; i++)
	{
		axisExtremes = [NSArray arrayWithObjects: 
					[NSNumber numberWithDouble: max[i]],
					[NSNumber numberWithDouble: min[i]],
					nil];
		[cavityExtremes addObject: axisExtremes];
		cavityCentre.vector[i] = (max[i] - min[i])/2 + min[i];
	}
}

- (id) init
{
	return [self initWithVdwType: @"A"];
}

- (id) initWithVdwType: (NSString*) type
{
	return [self initWithVdwType: type
		factor: 1.0];
}

- (id) initWithVdwType: (NSString*) string
	factor: (double) factorValue
{
	return [self initWithConfiguration: nil
		vdwParameters: nil
		vdwType: string
		factor: factorValue];
}

- (id) initWithSystem: (id) system factor: (double) factorValue 
{
	AdDataMatrix* configuration, *elementProperties;
	AdMutableDataMatrix *table;
	NSArray* headers;
	NSString* type;

	configuration = [AdDataMatrix matrixFromADMatrix: [system coordinates]];
	elementProperties = [system elementProperties];
	table = [AdMutableDataMatrix new];
	[table autorelease];

	headers = [elementProperties columnHeaders];
	if([headers containsObject: @"VDW A"] && [headers containsObject: @"VDW B"])
	{
		type = @"A";
		[table extendMatrixWithColumn: 
			[elementProperties columnWithHeader: @"VDW A"]];
		[table extendMatrixWithColumn: 
			[elementProperties columnWithHeader: @"VDW B"]];
		[table setColumnHeaders: [NSArray arrayWithObjects: 
			@"VDW A",
			@"VDW B", nil]];
	}
	else if([headers containsObject: @"VDW Separation"] && 
		[headers containsObject: @"VDW WellDepth"])
	{
		type = @"B";
		[table extendMatrixWithColumn: 
			[elementProperties columnWithHeader: @"VDW Separation"]];
		[table extendMatrixWithColumn: 
			[elementProperties columnWithHeader: @"VDW WellDepth"]];
		[table setColumnHeaders: [NSArray arrayWithObjects: 
			@"VDW Separation",
			@"VDW WellDepth", nil]];
	}
	else
	{
		table = nil;
		type = nil;
	}

	return [self initWithConfiguration: configuration
			vdwParameters: table
			vdwType: type
			factor: factorValue];
}

- (id) initWithConfiguration: (AdDataMatrix*) matrix 
		vdwParameters: (AdDataMatrix*) table
		vdwType: (NSString*) string
		factor: (double) factorValue	
{
	if(self == [super init])
	{
		if(table != nil && matrix != nil)
			if([matrix numberOfRows] != [table numberOfRows])
				[NSException raise: NSInvalidArgumentException
					format:
					@"Configuration and parameter matrices must have the same number of rows"];

		if(table != nil)
			vdwParameters = [table copy]; 
		else
			vdwParameters = nil;

		if(matrix != nil)
			moleculeConfiguration = [matrix copy];
		else
			moleculeConfiguration = nil;

		vdwType = [string retain];
		factor = factorValue;
		
		if(moleculeConfiguration != nil)
		{
			cavityExtremes = [NSMutableArray new];
			moleculeCoordinates = [matrix cRepresentation];
			if(vdwParameters != nil)
				[self _calculateCavityExtremes];
		}	
		else
		{
			//default values
			cavityCentre.vector[0] = 0;
			cavityCentre.vector[1] = 0;
			cavityCentre.vector[2] = 0;
			cavityExtremes = [NSMutableArray arrayWithObjects: 
						[NSNumber numberWithDouble: 0.0],
						[NSNumber numberWithDouble: 0.0],
						[NSNumber numberWithDouble: 0.0],
						nil];
			[cavityExtremes retain];			
		}	
	}
	
	return self;
}

- (void) dealloc
{
	[moleculeConfiguration release];
	[vdwType release];
	[cavityExtremes release];
	[vdwParameters release];
	[[AdMemoryManager appMemoryManager]
		freeMatrix: moleculeCoordinates];
	[super dealloc];
}

- (AdDataMatrix*) vdwParameters
{
	return [[vdwParameters retain] autorelease];
}

- (void) setVdwParameters: (AdDataMatrix*) table
{
	if(moleculeConfiguration != nil)
		if([moleculeConfiguration numberOfRows] != [table numberOfRows])
			[NSException raise: NSInvalidArgumentException
				format: @"%@ - Incorrect number of rows in table"];

	if(vdwParameters != nil)
		[vdwParameters release];
	
	vdwParameters = [table copy];
	[self _calculateCavityExtremes];
}

- (NSString*) vdwType
{
	return [[vdwType retain] autorelease];
}

- (void) setVdwType: (NSString*) type
{
	if(![type isEqual: @"A"] && ![type isEqual: @"B"])
		[NSException raise: NSInvalidArgumentException
			format: @"%@ - Invalid value passed for vdw type",
			NSStringFromSelector(_cmd)];

	
	if(vdwType != nil)
		[vdwType release];

	vdwType = [type retain];
	[self _calculateCavityExtremes];
}

- (AdDataMatrix*) configuration
{
	return [[moleculeConfiguration retain]
		autorelease];
}

- (void) setConfiguration: (AdDataMatrix*) aMatrix
{
	if(vdwParameters != nil)
		if([aMatrix numberOfRows] != [vdwParameters numberOfRows])
			[NSException raise: NSInvalidArgumentException
				format: @"%@ - Incorrect number of rows in table"];

	if(moleculeConfiguration != nil)
		[moleculeConfiguration release];

	moleculeConfiguration = [aMatrix copy];
	[[AdMemoryManager appMemoryManager]
		freeMatrix: moleculeCoordinates];
	moleculeCoordinates = [aMatrix cRepresentation];	
	[self _calculateCavityExtremes];
}

- (double) factor
{
	return factor;
}

- (void) setFactor: (double) value
{
	factor = value;
	[self _calculateCavityExtremes];
}

- (double) cavityVolume
{
	return -1;
}

- (BOOL) isPointInCavity: (double*) point
{
	int j;
	double radius;
	Vector3D dist;

	if(moleculeConfiguration == nil)
		return NO;

	for (j=0; j<moleculeCoordinates->no_rows; j++)
	{
		radius = factor*[self _calculateVDWRadiiForAtom: j];
		dist.vector[0] = moleculeCoordinates->matrix[j][0] - point[0];
		dist.vector[1] = moleculeCoordinates->matrix[j][1] - point[1];
		dist.vector[2] = moleculeCoordinates->matrix[j][2] - point[2];
		Ad3DVectorLengthSquared(&dist);
		if(dist.length <= radius*radius)
			return YES;
	}

	return NO;
}

- (Vector3D*) cavityCentre
{
	return &cavityCentre;
}

- (NSArray*) centre
{
	return [NSArray arrayWithObjects: 
		[NSNumber numberWithDouble: cavityCentre.vector[0]],
		[NSNumber numberWithDouble: cavityCentre.vector[1]],
		[NSNumber numberWithDouble: cavityCentre.vector[2]],
		nil];
}

- (NSArray*) cavityExtremes
{
	return [[cavityExtremes retain] autorelease];
}

@end
