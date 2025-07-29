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
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdDataSources.h"

@implementation AdSystem

/*
 * Object Creation and Maintainence
*/

+ (id) systemWithDataSource: (id) aDataSource
{
	return [[[self alloc] initWithDataSource: aDataSource] autorelease];
}

- (id) initWithDictionary: (NSDictionary*) aDict
{
	return [self initWithDataSource: [aDict objectForKey: @"dataSource"]
		name: [aDict objectForKey: @"name"]
		initialTemperature: [[aDict objectForKey: @"initialTemperature"] doubleValue]
		seed: [[aDict objectForKey: @"seed"] intValue]
		centre: [aDict objectForKey: @"centre"]
		removeTranslationalDOF: 
		[[aDict objectForKey: @"removeTranslationalDOF"] boolValue]];
}

- (id) initWithDataSource: (id) aDataSource
{
	return [self initWithDataSource: aDataSource
		name: nil
		initialTemperature: 300
		seed: 1
		centre: nil
		removeTranslationalDOF: YES];
}

- (id) initWithDataSource: (id) aDataSource
	name: (NSString*) name
	initialTemperature: (double) temperature
	seed: (int) rngSeed
	centre: (NSArray*) point
	removeTranslationalDOF: (BOOL) value
{
	if((self = [super init]))
	{
		if(aDataSource == nil)
			  [NSException raise: NSInvalidArgumentException
			  	format: @"A data source must be supplied for the system"];

		//Check if conforms to the AdSystemDataSource protocol
		if(![aDataSource conformsToProtocol: @protocol(AdSystemDataSource)])
			  [NSException raise: NSInvalidArgumentException
			  	format: @"Data source must conform to AdSystemDataSource"];

		
		mementoMask = 0;
		mementoMask = mementoMask | AdSystemCoordinatesMemento;
		systemName = nil;
		
		dataSource = [aDataSource retain];
		if(name == nil)
			systemName = [dataSource valueForKey: @"systemName"];
		else
			systemName = [NSString stringWithString: name];

		[systemName retain];

		dynamics = [[AdDynamics alloc] 
				initWithDataSource: dataSource
				targetTemperature: temperature
				seed: rngSeed
				removeTranslationalDOF: value];

		seed = rngSeed;
		targetTemperature = temperature;
		interactionSystemPointers = [NSMutableArray new];
		if(point != nil)
			[self setCentre: point];
	}

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];
	[interactionSystemPointers release];	
	[dynamics release];
	[dataSource release];
	[systemName release];
	[super dealloc];
}

/*
 * Configuration manipulation
 */

- (void) removeTranslationalDegreesOfFreedom
{
	[dynamics removeTranslationalDOF];
}

- (void) moveCentreOfMassToOrigin
{
	[dynamics moveCentreOfMassToOrigin];
}

- (NSArray*) centre;
{
	int i;
	Vector3D com;
	NSMutableArray* array = [NSMutableArray new];
	
	com = [dynamics centreOfMass];
	for(i=0; i<3; i++)
		[array addObject: 
			[NSNumber numberWithDouble: com.vector[i]]];

	return array;		
}

- (void) setCentre: (NSArray*) point;
{
	int i;
	double p[3];

	for(i=0; i<3; i++)
		p[i] = [[point objectAtIndex: i] doubleValue];

	[self centreOnPoint: p];
}

- (void) centreOnPoint: (double*) point
{
	[dynamics centreOnPoint: point];
}

- (void) centreOnElement: (unsigned int) index
{
	[dynamics centreOnElement: index];
}

- (Vector3D) centreAsVector
{
	return [dynamics centreOfMass];
}

- (AdMatrix*) coordinates
{
	return [dynamics coordinates];
}

- (void) setCoordinates: (AdMatrix*) matrix
{
	int i;

	[dynamics setCoordinates: matrix];
	
	for(i=0; i<(int)[interactionSystemPointers count]; i++)
		[(id)[[interactionSystemPointers objectAtIndex: i] pointerValue] 
			systemDidUpdateCoordinates: self];
}

- (AdMatrix*) velocities
{
	return [dynamics velocities];
}

- (void) setVelocities: (AdMatrix*) matrix
{
	[dynamics setVelocities: matrix];
}

- (void) reinitialiseVelocities
{
	[dynamics reinitialiseVelocities];
}	

- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction;
{
	return [dataSource groupsForInteraction: interaction];
}

- (AdDataMatrix*) parametersForInteraction: (NSString*) interaction;
{
	return [dataSource parametersForInteraction: interaction];
}

- (NSArray*) indexSetArrayForCategory: (NSString*) category 
{
	return [dataSource indexSetArrayForCategory: category];
}

- (NSArray*) availableInteractions
{
	return [dataSource availableInteractions];
}

/*
 * AdMemento
 */

- (int) captureMask
{
	return mementoMask;
}

- (void) setCaptureMask: (int) mask
{
	mementoMask = mask;
}

- (void) returnToState: (id) stateMemento;
{
	int captureMask;
	AdMatrix* matrixStruct;
	AdDataMatrix* matrix;

	//check if this memento is valid for this object.
	
	if(![[stateMemento name] isEqual: @"AdSystemMemento"])
		[NSException raise: NSInvalidArgumentException
			format: @"Memento is not of correct type"];

	captureMask = [[stateMemento valueForMetadataKey: @"MementoMask"]
			intValue];

	if((captureMask & AdSystemCoordinatesMemento))
	{
		//Check if the matrix contains the 
		//correct number of elements

		matrix = [stateMemento dataMatrixWithName: @"Coordinates"];
		if([matrix numberOfRows] != [self numberOfElements])
			[NSException raise: NSInternalInconsistencyException
				format: @"Coordinates provided by memento not of correct dimension"];

		matrixStruct = [matrix cRepresentation];
		[self setCoordinates: matrixStruct];		
		[[AdMemoryManager appMemoryManager]
			freeMatrix: matrixStruct];
	}
	
	if((captureMask & AdSystemVelocitiesMemento))
	{
		matrix = [stateMemento dataMatrixWithName: @"Velocities"];
		if([matrix numberOfRows] != [self numberOfElements])
			[NSException raise: NSInternalInconsistencyException
				format: @"Velocities provided by memento not of correct dimension"];

		matrixStruct = [matrix cRepresentation];
		[self setVelocities: matrixStruct];		
		[[AdMemoryManager appMemoryManager]
			freeMatrix: matrixStruct];
	}
}

- (id) captureState;
{
	AdDataSet* mementoData;
	AdDataMatrix* matrix;

	mementoData = [[AdDataSet alloc] 
			initWithName: @"AdSystemMemento"];
	[mementoData setValue: [NSNumber numberWithInt: mementoMask]
		forMetadataKey: @"MementoMask"];
	
	if((mementoMask & AdSystemCoordinatesMemento))
	{
		matrix = [[AdDataMatrix alloc]
				initWithADMatrix: [dynamics coordinates] 
				columnHeaders: nil
				name: @"Coordinates"];
		[matrix autorelease];
		[mementoData addDataMatrix: matrix];
	}
	
	if((mementoMask & AdSystemVelocitiesMemento))
	{
		matrix = [[AdDataMatrix alloc]
				initWithADMatrix: [dynamics velocities]
				columnHeaders: nil
				name: @"Velocities"];
		[matrix autorelease];
		[mementoData addDataMatrix: matrix];
	}

	return [mementoData autorelease];
}

- (BOOL) validateMemento: (id) aMemento
{
	return YES;
}

/*
 * Accessors
 */

- (void) reloadData
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];

	//See class documentation note on reloading.
	[dynamics release];
	dynamics = [[AdDynamics alloc]
			initWithDataSource: dataSource
			targetTemperature: targetTemperature
			seed: seed
			removeTranslationalDOF: YES];

	NSDebugLLog(@"AdSystem", @"%@ - Reloading data", systemName);
	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"AdSystemContentsDidChangeNotification"
		object: self];
	
	[pool release];
}		

- (id) dataSource
{
	return dataSource;
}

- (void) setDataSource: (id) anObject
{
	if(![anObject conformsToProtocol: @protocol(AdSystemDataSource)])
		  [NSException raise: NSInvalidArgumentException
			format: @"Data source must conform to AdSystemDataSoure"];

	[dataSource release];
	dataSource = [anObject retain];
}

- (void) updateDataSourceConfiguration
{
	[dataSource setElementConfiguration: 
		[AdDataMatrix matrixFromADMatrix: [self coordinates]]];
}

- (AdDataMatrix*) elementProperties
{
	return [dataSource elementProperties];
}

- (NSArray*) elementTypes
{
	return [dynamics elementTypes];
}

- (NSArray*) elementMasses
{
	return [dynamics elementMasses];
}

- (NSString*) systemName
{
	return systemName;
}

- (double) kineticEnergy
{
	return [dynamics kineticEnergy];
}

- (double) temperature
{
	return [dynamics temperature];
}

- (unsigned int) degreesOfFreedom
{
	return [dynamics degreesOfFreedom];
}

- (unsigned int) numberOfElements
{
	return [dataSource numberOfElements];
}	

- (void) registerInteractionSystem: (AdInteractionSystem*) anInteractionSystem
{
	NSValue* pointer;

	pointer = [NSValue valueWithPointer: anInteractionSystem];
	//Avoid adding same system twice
	if(![interactionSystemPointers containsObject: pointer])
		[interactionSystemPointers addObject: pointer];

}

- (void) removeInteractionSystem: (AdInteractionSystem*) anInteractionSystem
{
	NSValue* pointer;
	
	pointer = [NSValue valueWithPointer: anInteractionSystem];
	//Avoid adding same system twice
	if([interactionSystemPointers containsObject: pointer])
		[interactionSystemPointers removeObject: pointer];
}

- (NSArray*) interactionSystems
{
	NSMutableArray* anArray = [NSMutableArray array];
	NSEnumerator* pointerEnum;
	id pointer;
	
	pointerEnum = [interactionSystemPointers objectEnumerator];
	while((pointer = [pointerEnum nextObject]))
		[anArray addObject: 
			(AdInteractionSystem*)[pointer pointerValue]];

	return anArray;		
}

//AdMatrixModification

- (BOOL) allowsDirectModificationOfMatrix: (AdMatrix*) matrix;
{
	return [dynamics allowsDirectModificationOfMatrix: matrix]; 
}

- (BOOL) matrixIsAvailableForModification: (AdMatrix*) matrix;
{
	return [dynamics matrixIsAvailableForModification: matrix];
}

- (void) object: (id) object willBeginWritingToMatrix: (AdMatrix*) matrix;
{
	[dynamics object: object willBeginWritingToMatrix: matrix];
}

- (void) object: (id) object didFinishWritingToMatrix: (AdMatrix*) matrix;
{
	int i;

	//If the direct write was to coordinates update any interaction
	//systems before relinquishing the lock (in AdDynamics)
	if(matrix == [dynamics coordinates])
	{
		for(i=0; i<(int)[interactionSystemPointers count]; i++)
			[(id)[[interactionSystemPointers objectAtIndex: i] pointerValue] 
				systemDidUpdateCoordinates: self];
	}

	[dynamics object: object didFinishWritingToMatrix: matrix];
}

/*
 * NSCoding 
 */

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Encode", @"Encoding %@", [self description]);
		[encoder encodeObject: dynamics forKey: @"Dynamics"];
		[encoder encodeObject: systemName forKey: @"SystemName"];
		[encoder encodeObject: dataSource forKey: @"DataSource"];
		[encoder encodeInt: mementoMask forKey: @"MementoMask"];
		NSDebugLLog(@"Encode", @"Complete %@", [self description]);
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	if([decoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Decode", @"Decoding %@", [self description]);
		systemName = [decoder decodeObjectForKey: @"SystemName"];
		dataSource = [decoder decodeObjectForKey: @"DataSource"];
		dynamics = [decoder decodeObjectForKey: @"Dynamics"];
		mementoMask = [decoder decodeIntForKey: @"MementoMask"];

		[dynamics retain];
		[dataSource retain];
		[systemName retain];
	
		seed = [dynamics seed];
		targetTemperature = [dynamics targetTemperature];
		interactionSystemPointers = [NSMutableArray new];

		NSDebugLLog(@"Decode", @"Complete %@", [self description]);
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];


	return self;
}

- (NSString*) description
{
	Vector3D centre;
	NSMutableString* description;
	
	centre = [dynamics centreOfMass];
	description = [NSMutableString stringWithString:@""];
	[description appendFormat:
		@"Name: %@\nDataSource: %@\n", [self systemName], [dataSource name]];
	[description appendFormat: @"Degrees of Freedom: %d\n", [self degreesOfFreedom]];
	[description appendFormat: @"Temperature: %10.2lf Kelvin\n", [self temperature]];
	[description appendFormat: @"Kinetic Energy: %12.5lf Sim Units\n", [self kineticEnergy]];
	[description appendFormat: @"Centre: (%8.3lf, %8.3lf, %8.3lf)\n", 
		centre.vector[0], centre.vector[1], centre.vector[2]];

	return description;
}

@end
