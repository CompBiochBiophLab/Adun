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

#include "AdunKernel/AdunCuboidBox.h"

@implementation AdCuboidBox

- (void) _initialiseDependants
{
	cuboidVolume = xDim*yDim*zDim;
	 	
	[cuboidExtremes release];
	cuboidExtremes = [NSArray arrayWithObjects: 
				[NSArray arrayWithObjects: 
					[NSNumber numberWithDouble: xDim/2],
					[NSNumber numberWithDouble: -xDim/2], nil],
				[NSArray arrayWithObjects: 
					[NSNumber numberWithDouble: yDim/2],
					[NSNumber numberWithDouble: -yDim/2], nil],
				[NSArray arrayWithObjects: 
					[NSNumber numberWithDouble: zDim/2],
					[NSNumber numberWithDouble: -zDim/2], nil],nil];		
	[cuboidExtremes retain];
	
	NSDebugLLog(@"AdCuboidBox", @"Cuboid Volume %lf. Cuboid Extremes %@.",
		    cuboidVolume, cuboidExtremes);
}

- (id) init
{
	return [self initWithCavityCentre: nil xDimension: 20 yDimension: 20 zDimension: 20];
}

- (id) initWithCavityCentre: (NSArray*) array
	xDimension: (double) dim1 
	yDimension: (double) dim2 
	zDimension: (double) dim3

{
	if((self = [super init]))
	{
		if((dim1 <= 0) || (dim2 <=0 )|| (dim3 <= 0))
		{
			[NSException raise: NSInvalidArgumentException
				    format: @"Radius must be greater than 0"];
		}
			
		xDim = dim1;
		yDim = dim2;
		zDim = dim3;	
		cuboidExtremes = nil;
		
		if(array == nil)
		{
			centre = [NSMutableArray arrayWithObjects:
				  [NSNumber numberWithDouble: 0.0],
				  [NSNumber numberWithDouble: 0.0],
				  [NSNumber numberWithDouble: 0.0],
				  nil];
		}
		else
			centre = array;
		
		[centre retain];
		cuboidCentre = Ad3DVectorFromNSArray(centre);
		
		[self _initialiseDependants];
	}
	
	return self;
}

- (void) dealloc
{
	[centre release];
	[cuboidExtremes release];
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];
	
	[description appendFormat: @"%@. X-Dimension: %8.3lf. Y-Dimension %lf Z-Dimension %lf Centre: (%8.3lf, %8.3lf %8.3lf)\n",
	 NSStringFromClass([self class]), xDim, yDim, zDim,
	 cuboidCentre.vector[0], cuboidCentre.vector[1], cuboidCentre.vector[2]];
	
	return description;	
}

- (double) cavityVolume
{
	return cuboidVolume;
}

- (BOOL) isPointInCavity: (double*) point
{
	int j;
	Vector3D seperation;
	
	//return yes if its in the sphere otherwise no
	
	for(j=0; j<3; j++)
		seperation.vector[j] = point[j] - cuboidCentre.vector[j];
	if(fabs(seperation.vector[0]) > xDim/2)
		return NO;
	
	if(fabs(seperation.vector[1]) > yDim/2)
		return NO;
		
	if(fabs(seperation.vector[2]) > zDim/2)
		return NO;					
	
	return YES;
}

- (NSArray*) dimensions
{
	return [NSArray arrayWithObjects:
		[NSNumber numberWithDouble: xDim],
		[NSNumber numberWithDouble: yDim],
		[NSNumber numberWithDouble: zDim], nil];
		
}

- (Vector3D*) cavityCentre
{
	return &cuboidCentre;
}

- (NSArray*) centre
{
	return [[centre retain] autorelease];
}

- (void) setCavityCentre: (NSArray*) array
{
	Vector3D newCentre;
	
	newCentre = Ad3DVectorFromNSArray(array);
	[centre release];
	centre = [array retain];
	cuboidCentre = newCentre;
}

- (NSArray*) cavityExtremes
{
	return cuboidExtremes;
}

- (void) setXDimension: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			    format: @"X dimension must be greater than 0"];
	
	xDim = value;	
	[self _initialiseDependants];
}

- (void) setYDimension: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			    format: @"Y dimension must be greater than 0"];
	
	yDim = value;	
	[self _initialiseDependants];
}

- (void) setZDimension: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			    format: @"Z dimension must be greater than 0"];
	
	zDim = value;	
	[self _initialiseDependants];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	if([decoder allowsKeyedCoding])
	{
		centre = [decoder decodeObjectForKey: @"Centre"];
		xDim = [decoder decodeDoubleForKey: @"XDimension"];
		yDim = [decoder decodeDoubleForKey: @"YDimension"];
		zDim = [decoder decodeDoubleForKey: @"ZDimension"];

		[centre retain];
		
		cuboidCentre = Ad3DVectorFromNSArray(centre);
		[self _initialiseDependants];
	}
	else
		[NSException raise: NSInvalidArgumentException 
			    format: @"%@ does not support non keyed coding", [self classDescription]];
	
	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	
	if([encoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Encode", @"Encoding %@", [self description]);
		[encoder encodeDouble: xDim forKey: @"XDimension"];
		[encoder encodeDouble: yDim forKey: @"YDimension"];
		[encoder encodeDouble: zDim forKey: @"ZDimension"];
		[encoder encodeObject: centre forKey: @"Centre"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			    format: @"%@ class does not support non keyed coding", [self class]];
}


@end

