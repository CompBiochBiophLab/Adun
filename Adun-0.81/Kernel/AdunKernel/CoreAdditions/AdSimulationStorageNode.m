/*
 Project: AdunCore
 
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
 License along with this library; if not, write to the 
 Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
 */
#include "AdunKernel/AdSimulationStorageNode.h"
#include "AdunKernel/AdunFileSystemSimulationStorage.h"

/**
This simple class acts as a delegate when unarchiving AdSimulationData objects.
It allows the current location of the data directory on the file system to be provided
to the instance as it decodes itself.
*/
@interface AdSimulationDataUnarchiverDelegate: NSObject
{
	BOOL decodingPath;
	NSString* location;
}
/**
Creates a new instance that will provide an AdSimulationData instance being decoded
from the simulation data directory at location with that location.
*/
- (id) initWithPath: (NSString*) path;
/**
Sent by the unarchiver each time an object is decoded.
This allows the receiver to replace the object.
*/
- (id) unarchiver: (NSKeyedUnarchiver*) unarchiver didDecodeObject: (id) object;
/**
AdSimulationData instances being decoded send this message just before the decode their
dataPath ivar. The key for this is @"DataPath".
*/
- (id) unarchiver: (NSKeyedUnarchiver*) unarchiver willDecodeObjectForKey: (NSString*) key;
@end

@implementation AdSimulationDataUnarchiverDelegate 

- (id) initWithPath: (NSString*) path
{
	if(self = [super init])
	{
		decodingPath = NO;
		location = [path retain];
	}
	
	return self;
}

- (void) dealloc
{
	[location release];
	[super dealloc];
}

- (id) unarchiver: (NSKeyedUnarchiver*) unarchiver willDecodeObjectForKey: (NSString*) key
{
	if([key isEqual: @"DataPath"])
	{
		decodingPath = YES;
	}
}

- (id) unarchiver: (NSKeyedUnarchiver*) unarchiver didDecodeObject: (id) object
{
	if(decodingPath)
	{
		//If the dataPath encoding by the simulation data instance
		//is not the same as the current location replace it.
		
		NSDebugLLog(@"AdSimulationData", @"Data path is %@. Current location is %@", location, object);
		
		if(![location isEqual: [object objectAtIndex: 0]])
		{
			object = [[NSArray arrayWithObject: location] retain];
		}
		
		decodingPath = NO;	
	}

	return object;
}

@end

@implementation AdSimulationDataNode

+ (id) unarchiveFromFile: (NSString*) filename
{
	BOOL isDir;
	NSFileManager* fileManager;
	NSKeyedUnarchiver* unarchiver;
	NSString* directory;
	NSData* data;
	AdSimulationDataUnarchiverDelegate* delegate;
	id simulationData;

	fileManager = [NSFileManager defaultManager];

	directory = filename;
	directory = [directory stringByStandardizingPath];
	if(![directory isAbsolutePath])
	{
		directory = [[fileManager currentDirectoryPath] 
				stringByAppendingPathComponent: directory];
	}
	
	filename = [filename stringByAppendingPathComponent: @"objectData"];

	if([fileManager fileExistsAtPath: directory isDirectory: &isDir] && isDir)
	{
		if([fileManager fileExistsAtPath: filename])
		{
			//We need to explicitly create the unarchiver in order to set the delegate.
			data = [NSData dataWithContentsOfFile: filename];			
			unarchiver = [[NSKeyedUnarchiver alloc]	initForReadingWithData: data];	

			//Set the delegate
			delegate = [[AdSimulationDataUnarchiverDelegate alloc] 
						initWithPath: directory];
			[unarchiver setDelegate: delegate];	
			simulationData = [unarchiver decodeObjectForKey: @"root"];
			[[simulationData retain] autorelease];
			
			//Clean up
			[unarchiver finishDecoding];
			[unarchiver release];
			[delegate release];
		}
		else
		{
			NSWarnLog(@"Supplied directory %@ not a simulation data directory or corrupted", filename);
			NSWarnLog(@"Missing objectData file");
			simulationData = nil;
		}
	}
	else
	{
		NSWarnLog(@"Supplied location %@ is not a directory", filename);
		simulationData = nil;
	}
	
	return simulationData;
}

+ (id) simulationDataWithName: (NSString*) name location: (NSString*) path
{
	return [[[self alloc] initWithName: name location: path] autorelease];
}

- (id) initWithName: (NSString*) name location: (NSString*) path
{
	return [self initWithName: name location: path useIdentification: NO];
}

- (id) initWithName: (NSString*) name location: (NSString*) path useIdentification: (BOOL) value;
{
	BOOL isDir;

	if(self = [super init])
	{
		combinesData = NO;
		activeTrajectory = nil;
		trajectoryNames = [NSMutableArray new];
		trajectories = [NSMutableArray new];
		fileManager = [NSFileManager defaultManager];
	
		if(value)
		{
			dataPath = [path stringByAppendingPathComponent: [self identification]];
		}
		else
		{
			dataPath = [path stringByAppendingPathComponent: name];
			dataPath = [dataPath stringByAppendingPathExtension: @"ads"];
		}
	
		if([fileManager fileExistsAtPath: dataPath isDirectory: &isDir])
		{
			[self release];
			
			if(isDir)
			{
				return [[self class] unarchiveFromFile: path];
			}
			else
			{
				[NSException raise: NSInvalidArgumentException
					format: @"Location %@ must correspond to a directory", dataPath];
			}
			
		}
		else
		{	
			dataPath = [dataPath stringByResolvingSymlinksInPath];
			//Check if its absolute now
			if(![dataPath isAbsolutePath])
			{
				dataPath = [[fileManager currentDirectoryPath] 
					     stringByAppendingPathComponent: dataPath];
			}
			
			
			[fileManager createDirectoryAtPath: dataPath attributes: nil];	
		}
		
		[dataPath retain];
		[self setValue: name forMetadataKey: @"Name"];
		[self archive];
	}
	
	return self;
}

- (void) dealloc
{
	[dataPath release];
	[trajectories release];
	[trajectoryNames release];
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* string;
	NSString* description;
	
	string = [NSMutableString new];
	[string appendFormat: @"Simulation data %@ at %@. Contains %d trajectories.", 
		[self name], [self dataPath], [trajectories count]];
		
	description = [[string copy] autorelease];
	[string release];
	
	return description;
}

- (NSMethodSignature*) methodSignatureForSelector: (SEL) aSelector
{
	NSMethodSignature* signature;
	
	//First check does this class implement the method, then check the reader, otherwise default
	if([self respondsToSelector: aSelector])
	{
		signature = [super methodSignatureForSelector: aSelector];
	}
	else if([activeTrajectory respondsToSelector: aSelector] && (activeTrajectory != nil))
	{
		signature = [activeTrajectory methodSignatureForSelector: aSelector];
	}
	else if([AdMutableTrajectory instancesRespondToSelector: aSelector]
			   || [AdTrajectory instancesRespondToSelector: aSelector] )
	{
		//Have to test both cases above because AdMutableTrajectory is not 
		//actually a subclass of AdTrajectory
		[NSException raise: NSObjectNotAvailableException
			    format: @"The receiver has contains no trajectories to foward this message to"];
	}
	else 
	{
		signature = [super methodSignatureForSelector: aSelector];
	}
	
	return signature;
}

- (void) forwardInvocation: (NSInvocation*) anInvocation
{
	SEL selector;
	
	selector = [anInvocation selector];
	
	if([activeTrajectory respondsToSelector: selector] && activeTrajectory != nil)
	{
		[anInvocation invokeWithTarget: activeTrajectory];
	}
	else if([AdMutableTrajectory instancesRespondToSelector: selector]
		|| [AdTrajectory instancesRespondToSelector: selector] )
	{
		//Have to test both cases above because AdMutableTrajectory is not 
		//actually a subclass of AdTrajectory
		[NSException raise: NSObjectNotAvailableException
			format: @"The receiver has contains no trajectories to foward this message to"];
		
	}
	else
	{
		[self doesNotRecognizeSelector: selector];
	}
}

- (unsigned int) count
{
	return [trajectories count];
}

- (NSString*) location
{
	return [dataPath stringByDeletingLastPathComponent];
}

- (NSString*) dataPath
{
	return [[dataPath retain] autorelease];
}

- (NSArray*) trajectories
{
	return [[trajectories copy] autorelease];
}

- (id) trajectoryWithName: (NSString*) key
{
	int index;
	
	index = [trajectoryNames indexOfObject: key];
	return [trajectories objectAtIndex: index];	
}

- (id) trajectoryAtIndex: (unsigned int) index
{
	return [trajectories objectAtIndex: index];
}

- (unsigned int) indexOfTrajectory: (AdTrajectory*) object
{
	unsigned int index=NSNotFound, i=0;
	NSEnumerator* trajectoryEnum;
	AdTrajectory* trajectory;
	
	trajectoryEnum = [trajectories objectEnumerator];
	while((trajectory = [trajectoryEnum nextObject]))
	{
		if([[trajectory location] isEqual: [object location]])
		{ 
			index = i;
		}
		i++;
	}
	
	return index;
}

- (id) addTrajectoryForSystems: (AdSystemCollection*) systems withForceFields: (AdForceFieldCollection*) forceFields
{
	NSString* name;
	
	name = [NSString stringWithFormat: @"Trajectory%d", [trajectories count]];
	[self addTrajectoryForSystems: systems withForceFields: forceFields name: name];
}

- (void) addTrajectoryForSystems: (AdSystemCollection*) systems withForceFields: (AdForceFieldCollection*) forceFields name: (NSString*) name
{
	NSString* location;
	AdTrajectory* trajectory;
	NSError* error = nil;
	
	location = [dataPath stringByAppendingPathComponent: name];
	trajectory = [[AdMutableTrajectory alloc] 
			initWithLocation: location
			systems: systems 
			forceFields: forceFields 
			iterationHeader: @"Time"
			error: &error];	
				
	if(error != nil)
	{			
		AdLogError(error);
		[NSException raise: NSInternalInconsistencyException
			format: @"Unable to create trajectory. See error file for more information"];
	}
	
	//Update the stored data with the new information
	[self archive];		
}

- (void) switchToTrajectory: (unsigned int) index
{
	activeTrajectory = [trajectories objectAtIndex: index];
	combinesData = NO;
}

- (void) switchToFirst
{
	activeTrajectory = [trajectories objectAtIndex: 0];
	combinesData = NO;
}

//Archiving, Unarchiving etc.

- (void) archive
{
	double size;
	NSKeyedArchiver* archiver;
	NSMutableData* data = [NSMutableData new];
	NSEnumerator* trajectoryEnum;
	AdTrajectory* trajectory;

	//Update size information
	trajectoryEnum = [trajectories objectEnumerator];
	size = 0;
	while((trajectory = [trajectoryEnum nextObject]))
	{
		size += ((double)[[trajectory dataStorage] sizeOfStore])/(1024.0*1024.0);	
	}
	
	[self setValue: [NSString stringWithFormat: @"%-5.2lf MB", size]
		forMetadataKey: @"Size"
		inDomain: AdSystemMetadataDomain];
	
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: self forKey: @"root"];
	[archiver finishEncoding];
	
	[data writeToFile: [dataPath stringByAppendingPathComponent: @"objectData"] 
		atomically: NO];
	[data release];	
}

- (id) initWithCoder: (NSCoder*) decoder
{	
	NSEnumerator* nameEnum;
	NSString* name, *activeName, *location;
	AdTrajectory* trajectory;
	NSError* error = nil;
	
	if([decoder allowsKeyedCoding])
	{
		//First check if the decoder has an AdSimulationDataUnarchiverDelegate 
		//instance as its delegate.
		if(![[(NSKeyedUnarchiver*)decoder delegate] isKindOfClass: [AdSimulationDataUnarchiverDelegate class]])
		{
			[self release];
			[NSException raise: NSInternalInconsistencyException
				    format: @"You must provide an AdSimulationDataUnarchiverDelegate"
					" when decoding an AdSimulationData instance"];
		}
				
		[super initWithCoder: decoder];
	
		fileManager = [NSFileManager defaultManager];
		combinesData = [decoder decodeBoolForKey: @"CombinesData"];
		trajectoryNames = [decoder decodeObjectForKey: @"TrajectoryNames"];
		activeName = [decoder decodeObjectForKey: @"ActiveTrajectoryName"];

		//Notify the delegate we are about to decode "DataPath"
		//This allows it to subsititue it if it has changed i.e. the simulation
		//data directory was moved.
		[[(NSKeyedUnarchiver*)decoder delegate] 
			unarchiver: (NSKeyedUnarchiver*)decoder 
			willDecodeObjectForKey: @"DataPath"];
			
		dataPath = [[decoder decodeObjectForKey: @"DataPath"] objectAtIndex: 0];
		
		[trajectoryNames retain];
		[dataPath retain];
		
		//Access all the trajectories
		trajectories = [NSMutableArray new];
		nameEnum = [trajectoryNames objectEnumerator];
		while((name = [nameEnum nextObject]))
		{
			location = [dataPath stringByAppendingPathComponent: name];
			trajectory = [AdMutableTrajectory trajectoryFromLocation: location 
					error: &error];
			if(error != nil)
			{	
				trajectory = nil;
				NSWarnLog(@"Unable to access trajectory %@. Reason follows - ", name);
				AdLogError(error);
			}
			else
			{
				[trajectories addObject: trajectory];
			}
			
			if([name isEqual: activeName])
			{
				activeTrajectory = trajectory;
			}
		}
		
		if(activeTrajectory == nil && [trajectories count] != 0)
		{
			activeTrajectory = [trajectories objectAtIndex: 0];
		}
	}
	else
	{
		NSWarnLog(@"AdSimulationData only supports keyed coding");
	}
	
	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	NSEnumerator* trajectoryEnum;
	id trajectory;

	if([encoder allowsKeyedCoding])
	{
		[encoder encodeBool: combinesData forKey: @"CombinesData"];
		[encoder encodeObject: trajectoryNames forKey: @"TrajectoryNames"];
		[encoder encodeObject: [[activeTrajectory dataPath] lastPathComponent] 
			forKey: @"ActiveTrajectoryName"];
			
		//Encoding as an array to workaround Cocoa NSKeyedUnarchiver bug.
		//On decoding NSStrings the unarchiver doesn't send unarchiver:didDecodeObject: messages.	
		[encoder encodeObject: [NSArray arrayWithObject: dataPath] forKey: @"DataPath"];
		[encoder encodeObject: @"Michael" forKey: @"Test"];
		
		//Ensure all trajectories have written out their data.
		trajectoryEnum = [trajectories objectEnumerator];
		while((trajectory = [trajectoryEnum nextObject]))
		{
			if([trajectory respondsToSelector: @selector(synchToStore)])
				[trajectory synchToStore];
		}
		
		[super encodeWithCoder: encoder];
	}
	else
	{
		NSWarnLog(@"AdSimulationData only supports keyed coding");
		[NSException raise: NSInvalidArgumentException
			format: @"Cannot encode AdSimulationData instances with a non-keyed coder"];
	}
}
	
@end

/**
@implementation AdSimulationDataNode (CombinedAccess)

 - (BOOL) combinesData
 {
 return combinesData;
 }
 
- (void) setCombinesData
{
 combinesData = YES;
 activeTrajectory = nil;
}

- (AdDataSet*) combinedEnergies
{
	return [[combinedEnergies retain] autorelease];
}

- (AdSystemCollection*) combinedCollection
{
	return [[combinedCollection retain] autorelease];
}

- (NSArray*) combinedSystems
{
	return [combinedCollection allSystems];
}

- (AdDataSet*) combinedFrames
{
	return [[combinedFrames retain] autorelease];
}

- (id) mementoForSystem: (id) system inCombinedTrajectoryCheckpoint: (unsigned int) number
{
	
}

- (id) dataSourceForSystem: (id) system inCombinedTopologyCheckpoint: (unsigned int) number
{
	
}

- (AdDataMatrix*) coordinatesForSystem: (id) system inCombinedTrajectoryCheckpoint: (unsigned int) number
{
	
}

- (void) coordinatesForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number usingBuffer: (AdMatrix*) buffer
{
	
}

-(unsigned int) numberCombinedTrajectoryCheckpoints
{
	
}

- (unsigned int) numberCombinedTopologyCheckpoints;

- (unsigned int) numberOfCombinedFrames
{
	
}

- (unsigned int) frameForCombinedTopologyCheckpoint: (unsigned int) number
{
	
}

- (unsigned int) frameForCombinedEnergyCheckpoint: (unsigned int) number
{
	
}

- (unsigned int) frameForCombinedTrajectoryCheckpoint: (unsigned int) number
{
	
}

- (id) lastRecordedDataSourceForSystem: (id) system inCombinedRange: (NSRange) aRange
{
	
}

- (NSArray*) dataRecordedInCombinedFrame: (unsigned int) frame;
{
	
}	    

@end*/



