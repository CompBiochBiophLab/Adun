/*
   Project: AdunCore

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

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

#include "AdunKernel/AdunSimulationData.h"
#include "AdunKernel/AdunFileSystemSimulationStorage.h"
#include "AdunKernel/AdunMolecularMechanicsForceField.h"

@implementation AdSimulationData

- (void) _loadStateData: (NSData*) data;
{	
	NSDebugLLog(@"AdSimulationData", @"Load Energies...");	
	stateData = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	[stateData retain];
	NSDebugLLog(@"AdSimulationData", @"Finished");
	
	if(stateData == nil || [[stateData dataMatrices] count] == 0)
		NSWarnLog(@"Simulation %@ (%@) contains no energy data",
				[self name],
				[self identification]);
	else		
		//All systems have the same number of energy checkpoints
		numberEnergyCheckpoints = [[[stateData dataMatrices] 
						objectAtIndex: 0] numberOfRows];
}

- (void) _loadSystemCollection
{
	NSKeyedUnarchiver* unarchiver;
	NSData* data;

	data = [dataStorage systemData];
	unarchiver = [NSKeyedUnarchiver alloc];
	[unarchiver initForReadingWithData: data];
	systemCollection = [unarchiver decodeObjectForKey: @"SystemCollection"];
	[systemCollection retain];
	[unarchiver finishDecoding];
	[unarchiver release];
}

- (void) _loadFrames
{
	NSKeyedUnarchiver* unarchiver;
	NSData* data;

	data = [dataStorage frameData];
	if(data != nil && [data length] > 0)
	{
		unarchiver = [NSKeyedUnarchiver alloc];
		[unarchiver initForReadingWithData: data];
		frames = [unarchiver decodeObjectForKey: @"root"];
		[frames retain];
		[unarchiver finishDecoding];
		[unarchiver release];
	}	
	else
		NSWarnLog(@"No frame data present");
}

/**************

Creation

***************/

+ (id) simulationFromArchive: (NSString*) filename loadData: (BOOL) flag
{
	return [self simulationFromArchive: filename loadData: flag error: NULL];
}

+ (id) simulationFromArchive: (NSString*) filename loadData: (BOOL) flag error: (NSError**) error
{
	id object;
	AdFileSystemSimulationStorage *storage;
	
	object = [NSKeyedUnarchiver unarchiveObjectWithFile: filename];
	if(![object isKindOfClass: [self class]])
		[NSException raise: NSInvalidArgumentException
			    format: @"File %@ does not contain a valid AdSimulationData archive", filename];
	
	//If flag is YES, attempt to load the simulation data.
	//Assume its in the same directory and its name is filename_Data.		
	
	if(flag)
	{
		storage = [AdFileSystemSimulationStorage storageForSimulation: object 
								  inDirectory: [filename stringByDeletingLastPathComponent] 
									 mode: AdSimulationStorageReadMode 
									error: error];
		[object setDataStorage: storage];
		[object loadData];
	}
	
	return [object retain];
}

- (id) init
{
	return [self initWithName: nil];	
}

- (id) initWithName: (NSString*) aName 
{
	if((self = [super init]))
	{
		stateData = nil;
		systemCollection = nil;
		frames = nil;
		numberEnergyCheckpoints = 0;
		if(aName != nil)
			[self setValue: aName forMetadataKey: @"Name"];
	}		

	return self;
}

- (void) dealloc
{	
	[frames release];
	[dataStorage release];
	[stateData release];
	[systemCollection release];
	[super dealloc];
}

- (void) loadData
{
	NSException* exception;
	NSData *energyData;
	NSError* error;
	
	//check we have access to a data store
	if(dataStorage == nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"No data storage has been set."];
	
	//check the data store is accesible
	if(![dataStorage isAccessible])
	{
		NSWarnLog(@"Simulation data is not accesible raising exception");
		error = [dataStorage accessError];
		exception = [NSException exceptionWithName: NSInternalInconsistencyException
				reason: @"Unable to access data storage"
				userInfo:[error userInfo]];
		[exception raise];			
	}
	
	//Get rid of anything we loaded previously
	if(stateData != nil)
	{
		[stateData release];
		[systemCollection release];
		[frames release];
		stateData = nil;
		systemCollection = nil;
	}

	//Call update on the data store in case anything
	//has been written to it since it was initialised
	[dataStorage update];

	energyData = [dataStorage energyData];
	NSDebugLLog(@"AdSimulationData", 
			@"There are %d trajectory frames available",
			[dataStorage numberTrajectoryCheckpoints]);
	NSDebugLLog(@"AdSimulationData", 
		@"Read in %lf KB of energy data", 
		((double)[energyData length])/1024);

	[self _loadStateData: energyData];
	NSDebugLLog(@"AdSimulationData", @"Unarchiving system manager");
	[self _loadSystemCollection];
	NSDebugLLog(@"AdSimulationData", @"Unarchiving frame data");
	[self _loadFrames];
	NSDebugLLog(@"AdSimulationData", @"Complete");
		
	NSDebugLLog(@"AdSimulationData", @"Initialised AdSimulationData");
}

- (BOOL) checkDataStorageIdentification
{
	return checkDataStorageIdentification;
}

- (void) setCheckDataStorageIdentification: (BOOL) value
{
	checkDataStorageIdentification = value;
}

- (id) dataStorage
{
	return [[dataStorage retain] autorelease];
}

- (void) setDataStorage: (id) object
{
	double size;
	NSString* dataId;

	if(dataStorage != object)
	{
		[dataStorage release];
		dataStorage = [object retain];
	}	

	//Check if the data in the store corresponds
	//to the simulation data for this object
	//by checking its id
	if(checkDataStorageIdentification)
		if((dataId = [dataStorage identification]) != nil)
			if(dataId != identification)
			{
				NSWarnLog(@"Supplied data storage is not related to this object");
				return;
			}
	
	size = ((double)[dataStorage sizeOfStore])/(1024.0*1024.0);	
	[self setValue: [NSString stringWithFormat: @"%-5.2lf MB", size]
		forMetadataKey: @"Size"
		inDomain: AdSystemMetadataDomain];		
}

- (AdDataSet*) energies
{
	return [[stateData retain] autorelease];
}

- (AdSystemCollection*) systemCollection
{
	return [[systemCollection retain] autorelease];
}

- (AdDataMatrix*) frames	
{
	return [[frames retain] autorelease];
}

- (unsigned int) numberTrajectoryCheckpoints
{
	return [dataStorage numberTrajectoryCheckpoints];
}

- (unsigned int) numberTopologyCheckpoints
{
	return [dataStorage numberTopologyCheckpoints];
}

- (id) dataSourceForSystem: (id) system inTopologyCheckpoint: (unsigned int) number
{
	NSData* archive;
	NSKeyedUnarchiver* unarchiver;
	NSString* name;
	id dataSource;

	if(number >= [self numberTopologyCheckpoints])
		[NSException raise: NSInvalidArgumentException
			format: @"Requested checkpoint (%d) is greater than the number of available checkpoints (%d)",
				number, [self numberTopologyCheckpoints]];

	name = [system systemName];
	archive = [dataStorage topologyCheckpoint: number];
	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: archive];
	dataSource = [unarchiver decodeObjectForKey: name];
	[[dataSource retain] autorelease];
	[unarchiver finishDecoding];
	[unarchiver release];

	return dataSource;
}

- (id) mementoForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number
{
	NSData* archive;
	NSKeyedUnarchiver* unarchiver;
	NSString* name;
	id memento;

	if(number >= [self numberTrajectoryCheckpoints])
		[NSException raise: NSInvalidArgumentException
			format: @"Requested checkpoint (%d) is greater than the number of available checkpoints (%d)",
				number, [self numberTrajectoryCheckpoints]];

	name = [system systemName];
	archive = [dataStorage trajectoryCheckpoint: number];
	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: archive];
	memento = [unarchiver decodeObjectForKey: name];
	[[memento retain] autorelease];
	[unarchiver finishDecoding];
	[unarchiver release];

	return memento;
}

- (NSString*) description
{
	NSMutableString *string = [NSMutableString string];
	NSEnumerator* systemEnum;
	id system, energies;

	[string appendFormat: @"Name: %@ - ", [self name]];
	if(systemCollection == nil)
	{
		[string appendString: @"No data loaded\n"];
		return string;
	}	
	
	[string appendFormat: @"%d System(s):\n\n",
		[[systemCollection allSystems] count]];
	systemEnum = [[systemCollection allSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		[string appendFormat: @"%@\n", [system systemName]];
		[string appendFormat: @"\t%d Trajectory Frames\n",
			[self numberTrajectoryCheckpoints]];
		[string appendFormat: @"\t%d Topology Frames\n",
			[self numberTopologyCheckpoints]];
		energies = [stateData dataMatrixWithName: [system systemName]];
		if(energies != nil)
		{
			[string appendFormat: @"\t%d Energy Frames\n\n",
				[energies numberOfRows]];	
		}	
		else
			[string appendString: @"\tNo available energies\n"];
	}

	return string;
}

/**
Frame related methods - Wont work with pre 0.71 stores 
where the frame data wasn't encoded.
*/

- (unsigned int) numberOfFrames
{
	if(frames == nil)
		return 0;
	else
		return [frames numberOfRows];
}

/**
The first frame is 0.
Checkpoints are also numbered from 0.
*/
- (unsigned int) _frameForCheckpoint: (unsigned int) number inColumn: (NSString*) aString
{
	int i;
	unsigned int counter = -1; 	//Accounting for checkpoint offset
	NSMutableArray* array = [NSMutableArray new];

	[frames addColumnWithHeader: aString toArray: array];
	for(i=0; i<(int)[array count]; i++)
	{
		counter += [[array objectAtIndex: i] boolValue];
		if(counter == number)
			break;
	}		
	[array release];

	return i;
}

- (unsigned int) frameForTrajectoryCheckpoint: (unsigned int) number
{
	if(number >= [self numberTrajectoryCheckpoints])
		[NSException raise: NSInvalidArgumentException
			format: 
			@"Requested checkpoint index (%d) is greater than the number of available checkpoints (%d)",
			number, [self numberTrajectoryCheckpoints]];

	return [self _frameForCheckpoint: number inColumn: @"Trajectory"];
}

- (unsigned int) frameForEnergyCheckpoint: (unsigned int) number
{
	if(number >= numberEnergyCheckpoints)
		[NSException raise: NSInvalidArgumentException
			format:
			@"Requested checkpoint index (%d) is greater than the number of available checkpoints (%d)",
			number, numberEnergyCheckpoints];

	return [self _frameForCheckpoint: number inColumn: @"Energy"];
}

- (unsigned int) frameForTopologyCheckpoint: (unsigned int) number
{
	if(number >= [self numberTopologyCheckpoints])
		[NSException raise: NSInvalidArgumentException
			format:
			@"Requested checkpoint index (%d) is greater than the number of available checkpoints (%d)",
			number, [self numberTopologyCheckpoints]];

	return [self _frameForCheckpoint: number inColumn: @"Topology"];
}

- (NSArray*) dataRecordedInFrame: (unsigned int) number
{
	NSMutableArray* array = [NSMutableArray array];

	if(number >= [frames numberOfRows])
		[NSException raise: NSInvalidArgumentException
			format: 
			@"Requested frame index (%d) is greater than the number of available frames (%d)",
			number, [self numberOfFrames]];

	if([[frames elementAtRow: number ofColumnWithHeader: @"Trajectory"] boolValue])
		[array addObject: @"Trajectory"];
	if([[frames elementAtRow: number ofColumnWithHeader: @"Topology"] boolValue])
		[array addObject: @"Topology"];
	if([[frames elementAtRow: number ofColumnWithHeader: @"Energy"] boolValue])
		[array addObject: @"Energy"];

	return [[array copy] autorelease];
}

- (id) lastRecordedDataSourceForSystem: (id) system inRange: (NSRange) range
{
	BOOL value;
	int end, i;
	id dataSource;

	end = NSMaxRange(range);
	if(end > (int)[frames numberOfRows])
		[NSException raise: NSInvalidArgumentException
			format: @"Specfied range (%d,%d) falls outside the available frames %d",
			range.location, range.length, [frames numberOfRows]];
	
	NSDebugLLog(@"AdSimulationData", 
		@"Searching range %d-%d for data source", 
		range.location, end);
	dataSource = nil;
	for(i = ([self numberTopologyCheckpoints] - 1); i>=0; i++ )
	{
		value = [self frameForTopologyCheckpoint: i];
		if(NSLocationInRange(value, range))
		{
			NSDebugLLog(@"AdSimulationData", 
				@"Topology checkpoint %d is in the specfied range", i);
			//This checkpoint is in the range.
			//Now we must check it contains the required data.
			dataSource = [self dataSourceForSystem: system
					inTopologyCheckpoint: i];
			if(dataSource != nil)
			{
				NSDebugLLog(@"AdSimulationData", @"Found data source");
				break;
			}	

			NSDebugLLog(@"AdSimulationData", 
				@"Checkpoint does not contain data for system");	
		}
	}

	return dataSource;
}

/**
Deprecated
*/
- (unsigned int) numberOfFramesForSystem: (id) system
{
	return [self numberTrajectoryCheckpoints];
}

/**
Deprecated
*/
- (id) mementoForFrame: (unsigned int) frame ofSystem: (id) system
{
	return [self mementoForSystem: system 
			inTrajectoryCheckpoint: frame];
}

@end


@implementation AdSimulationDataWriter

- (void) _createStateMatrices
{
	NSArray* headers, *forceFieldArray;
	NSMutableArray* stateHeaders;
	NSEnumerator* systemEnum;
	AdMolecularMechanicsForceField* systemForceField;
	id system, stateMatrix;

	if(iterationHeader == nil)
		iterationHeader = [@"Iteration" retain];

	headers = [NSArray arrayWithObjects:
			iterationHeader,
			@"PotentialEnergy",
			@"KineticEnergy", 
			@"Temperature",
			@"TotalEnergy",
			nil];

	systemEnum = [[systemCollection allSystems] objectEnumerator];
	//Create an entry in stateData for each system
	while((system = [systemEnum nextObject]))
	{
		//FIXME: Supports only one force field per system
		forceFieldArray = [forceFieldCollection forceFieldsForSystem: system];
		if([forceFieldArray count] == 0)
		{
			NSWarnLog(@"No force fields operating on system %@", [system systemName]);
			NSWarnLog(@"Skipping");
			continue;
		}	
			
		systemForceField = [forceFieldArray objectAtIndex: 0];
		stateHeaders = [NSMutableArray arrayWithArray: headers];
		if([system isKindOfClass: [AdInteractionSystem class]])
		{
			[stateHeaders removeObject: @"KineticEnergy"];
			[stateHeaders removeObject: @"Temperature"];
		}	
		
		[stateHeaders addObjectsFromArray: [systemForceField allTerms]];		
		stateMatrix = [[AdMutableDataMatrix alloc]
					initWithNumberOfColumns: [stateHeaders count]
					columnHeaders: stateHeaders
					columnDataTypes: nil];
		[stateMatrix autorelease];			
		[(AdMutableDataMatrix*)stateMatrix setName: [system systemName]];	
		[stateData addDataMatrix: stateMatrix];
	}
}

- (id) init
{
	return [self initWithDataStorage: nil];
}

- (id) initWithDataStorage: (id) aDataStore
{
	return [self initWithDataStorage: aDataStore
		systems: nil
		forceFields: nil
		iterationHeader: nil];
}

- (id) initWithDataStorage: (id) aDataStore
	systems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	iterationHeader: (NSString*) aString
{
	NSArray* headers;
	AdDataMatrix* matrix;
	AdFileSystemSimulationStorage* tempStorage;	//!< Used for AdSimulationStorageAppendMode
	AdSimulationData* dataReader;
	AdSystemCollection* storedSystemCollection;	//!< Used fo AdSimulationStorageAppendMode

	if((self = [super init]))
	{
		if(aDataStore == nil)
			[NSException raise: NSInvalidArgumentException
				format: @"aDataStore cannot be nil"];
				
		frameOpen = NO;		
	
		//Depending on whether the store is in write or append
		//mode we have to initialise it in a different way
		if([aDataStore storageMode] == AdSimulationStorageWriteMode)
		{
			lastFrame = -1;
			systemCollection = nil;
			forceFieldCollection = nil;
			iterationHeader = [aString retain];
			iterationValue = nil;
			stateData = [[AdDataSet alloc] 
					initWithName: @"StateData"
					inputReferences: nil
					dataGenerator: [NSBundle mainBundle]];
			topologyData = [NSMutableDictionary new];
			energyData = [NSMutableDictionary new];
			//This is allocated on each trajectory checkpoint request
			trajectoryData = nil;
			dataStorage = [aDataStore retain];	
			headers = [NSArray arrayWithObjects: 
					@"Energy",
					@"Trajectory",
					@"Topology",
					nil];
			frames = [[AdMutableDataMatrix alloc]
					initWithNumberOfColumns: 3
					columnHeaders: headers
					columnDataTypes: nil];	
					
			[self setSystems: aSystemCollection];
			[self setForceFields: aForceFieldCollection];
		}
		else if([aDataStore storageMode] == AdSimulationStorageAppendMode)
		{
			//Since we are appending to an existing store we
			//have to make sure the state of this object
			//is as it would be just after the last frame was written.
		
			dataStorage = [aDataStore retain];
			topologyData = [NSMutableDictionary new];
			energyData = [NSMutableDictionary new];
			forceFieldCollection = nil;
			trajectoryData = nil;
			
			//Create a read-mode storage and an AdSimulationData instance
			//to read the stored data we require.
			tempStorage = [[AdFileSystemSimulationStorage alloc]
					initForReadingSimulationDataAtPath: [dataStorage storagePath]];
			dataReader = [AdSimulationData new];
			[dataReader setDataStorage: tempStorage];
			[dataReader loadData];
			
			storedSystemCollection = [dataReader systemCollection];
			stateData = [dataReader energies];
			frames = [[dataReader frames] mutableCopy];
			lastFrame = (int)[frames numberOfRows] - 1;
		
			[stateData retain];
			[dataReader release];
			[tempStorage release];
			
			//Read iteration header and value from state data
			//Assumes all systems checkpointed at same interval.
			matrix = [[stateData dataMatrices] objectAtIndex: 0];		
			iterationHeader = [[matrix columnHeaders] objectAtIndex: 0];
			//Iteration value is the value for the iteration column in the last opened frame.
			//This is usually the step the configuration generator was last at.
			iterationValue = [matrix elementAtRow: [matrix numberOfRows] - 1
						ofColumnWithHeader: iterationHeader];
			[iterationHeader retain];
			[iterationValue retain];
			
			//We can't use setSystemCollection: since this will trigger things we dont want.
			//We also can't use storedSystemCollection because the objects in it
			//may not be the same (that is they should have the same data but may not the same objects)
			//as those in aSystemCollection.
			//This will not overwrite the stored collection as we don't use setSystemCollection,
			//though since they contain the same data it wouldnt really matter
			//FIXME: This will need to be changed because there is no way to know if
			//aSystemCollectin and storedSystemCollection contain the same data.
			systemCollection = [aSystemCollection retain];
			
			//Similarly we can't use setForceFieldCollection: since this would trigger
			//creating the stateData ivar which we already have.
			//Therefore we set the explicitly here.
			forceFieldCollection = [aForceFieldCollection retain];
			
			NSDebugLLog(@"AdSimulationDataWriter", 
				@"Writing to append mode storage - Last frame %d, iteration header %@, last iteration value %@", 	
				lastFrame, iterationHeader, iterationValue);					
		}
		else
			[NSException raise: NSInternalInconsistencyException
				format: @"You can only write data to a store in AdSimulationStorageWriteMode or AdSimulationStorageAppendMode"];
		
	}

	return self;
}

- (void) dealloc
{
	[self synchToStore];
	[iterationValue release];
	[iterationHeader release];
	[topologyData release];
	[energyData release];
	[trajectoryData release];
	[stateData release];
	[dataStorage release];
	[frames release];
	[systemCollection release];
	[forceFieldCollection release];
	[super dealloc];
}

- (void) setSystems: (AdSystemCollection*) aSystemCollection
{
	NSMutableData* data;
	NSKeyedArchiver* archiver;

	if(systemCollection != nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"The system collection cannot be changed"];

	systemCollection = [aSystemCollection retain];		

	data = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: systemCollection forKey: @"SystemCollection"];
	[archiver finishEncoding];
	[archiver release];
	[dataStorage setSystemData: data];
	[data release];
	if(forceFieldCollection != nil)
		[self _createStateMatrices];
}

- (AdSystemCollection*) systems
{
	return [[systemCollection retain] autorelease];
}

- (void) updateSystems
{
	NSWarnLog(@"Method %@ not implemented", NSStringFromSelector(_cmd));
}

- (void) setForceFields: (AdForceFieldCollection*) aForceFieldCollection
{
	[forceFieldCollection release];
	forceFieldCollection = [aForceFieldCollection retain];
	if(systemCollection != nil)
		[self _createStateMatrices];
}

- (void) setIterationHeader: (NSString*) aString
{
	if(iterationHeader != nil)
	{
		NSWarnLog(@"State matrices have already been created.");
		return;
	}

	iterationHeader = [aString retain];
}

- (void) openFrame: (NSNumber*) value
{
	NSDebugLLog(@"AdSimulationDataWriter",
		@"Recieved open frame request");
	NSDebugLLog(@"AdSimulationDataWriter",
		@"Frame open? - %d", frameOpen);
	NSDebugLLog(@"AdSimulationDataWriter",
		@"Current iteration value %@", iterationValue);
	NSDebugLLog(@"AdSimulationDataWriter",
		@"Requested iteration value %@", value);

	if(frameOpen)
		return;

	if([value isEqual: iterationValue])
		return;

	NSDebugLLog(@"AdSimulationDataWriter", 
		@"Opening frame");

	frameOpen =YES;
	[iterationValue release];
	iterationValue = [value retain];
}

- (BOOL) isOpenFrame
{
	return frameOpen;
}

- (void) _addEnergyCheckpoint
{
	NSEnumerator* dataEnum;
	NSString* systemName;
	id state, stateMatrix;
	//For column addition
	int i, noRows;
	NSEnumerator* termEnum;
	NSArray* headers;
	NSMutableArray* newTerms, *column;
	NSString* term;

	dataEnum = [energyData keyEnumerator];
	while((systemName = [dataEnum nextObject]))
	{
		stateMatrix = [stateData dataMatrixWithName: 
				systemName];
		state = [energyData objectForKey: systemName];	
		
		/*
		 * We need to check that the number of energy terms returned
		 * for the system is the same as the number of terms in the matrix.
		 * They could differ if extra terms were added or removed to the force-field
		 * operating on the system since the last checkpoint.
		 *
		 * Two cases:
		 * 1. In the case of an extra term we must add an extra column to the matrix and
		 * fill the previous steps where the term didn't exist with 0's.
		 * 2. In the case where a term is removed we simply put a zero for its value
		 * until it appears again.
		 */
		
		if([[state allKeys] count] > [stateMatrix numberOfColumns])
		{
			//Find the new keys
			termEnum = [state keyEnumerator];
			headers = [stateMatrix columnHeaders];
			newTerms = [NSMutableArray array];
			while(term = [termEnum nextObject])
			{
				if(![headers containsObject: term])
					[newTerms addObject: term];
			}
			
			column = [NSMutableArray new];
			termEnum = [newTerms objectEnumerator];
			while(term = [termEnum nextObject])
			{
				//Create a column for this term
			
				noRows = [stateMatrix numberOfRows];
				for(i=0; i<noRows; i++)
					[column addObject: [NSNumber numberWithDouble: 0.0]];
					
				[stateMatrix extendMatrixWithColumn: column];
				[stateMatrix setHeaderOfColumn: [stateMatrix numberOfColumns] - 1 
					to: term];
				
				[column removeAllObjects];
			}
			
			[column release];
		}
		
		[stateMatrix extendMatrixWithColumnValues: state];
	 }		
}

- (void) closeFrame
{
	NSMutableData* data;
	NSMutableArray* checkpointed = [NSMutableArray new];
	NSKeyedArchiver* archiver;
	NSEnumerator* systemEnum;
	id systemName, topology;

	if(!frameOpen)
		return;

	//Write all the data
	frameOpen = NO;
	lastFrame++;
	
	NSDebugLLog(@"AdSimulationDataWriter",
		@"Closing frame %d", lastFrame);
	if(trajectoryCheckpoint)
	{
		[dataStorage addTrajectoryCheckpoint: trajectoryData];
		NSDebugLLog(@"AdSimulationDataWriter",
			@"Checkpointed %d bytes of trajectory data",
			[trajectoryData length]);
		[checkpointed addObject: [NSNumber numberWithInt: 1]];
		NSDebugLLog(@"AdSimulationDataWriter",
			    @"Done ");
	}
	else
		[checkpointed addObject: [NSNumber numberWithInt: 0]];

	if(energyCheckpoint)
	{
		
		if(forceFieldCollection == nil)
			[checkpointed addObject: [NSNumber numberWithBool: NO]];
		else
		{
			NSDebugLLog(@"AdSimulationDataWriter",
				    @"Checkpointing energies");
			[self _addEnergyCheckpoint];
			[checkpointed addObject: [NSNumber numberWithInt: 1]];
			[energyData removeAllObjects];
			NSDebugLLog(@"AdSimulationDataWriter",
				    @"Done ");
		}
	}
	else
		[checkpointed addObject: [NSNumber numberWithInt: 0]];

	if(topologyCheckpoint)
	{
		data = [NSMutableData new];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
		[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
		systemEnum = [topologyData keyEnumerator];
		while((systemName = [systemEnum nextObject]))
		{
			//We assume the data source has been synched
			//to the current configuration
			NSDebugLLog(@"AdSimulationDataWriter",
				@"Checkpointing topology of %@", systemName);
			topology = [topologyData objectForKey: systemName];
			[archiver encodeObject: topology
				forKey: systemName];
		}
		
		[archiver finishEncoding];
		[archiver release];
		[dataStorage addTopologyCheckpoint: data];
		NSDebugLLog(@"AdSimulationDataWriter",
			@"Checkpointed %d bytes of topology data", [data length]);
		[data release];
		[checkpointed addObject: [NSNumber numberWithInt: 1]];
		[topologyData removeAllObjects];
	}
	else
		[checkpointed addObject: [NSNumber numberWithInt: 0]];

	[frames extendMatrixWithRow: checkpointed];

	NSDebugLLog(@"AdSimulationDataWriter",
		    @"Cleaning up");

	//Set for next frame
	[checkpointed release];
	energyCheckpoint = NO;
	trajectoryCheckpoint = NO;
	topologyCheckpoint = NO;
	
	NSDebugLLog(@"AdSimulationDataWriter",
		    @"Frame closed");
}

- (int)  lastFrame
{
	return lastFrame;
}

/**
The first frame should indicate a checkpoint for everything
*/
- (unsigned int) _lastCheckpointInColumn: (NSString*) column
{	
	int i, numberOfRows;

	if(lastFrame == -1)
		return lastFrame;

	numberOfRows = [frames numberOfRows];
	for(i=numberOfRows-1; i>=0; i--)
		if([[frames elementAtRow: i ofColumnWithHeader: column] boolValue])
			break;
	
	return i;
}

- (unsigned int) lastEnergyCheckpoint
{
	return [self _lastCheckpointInColumn: @"Energy"];
}

- (unsigned int) lastTopologyCheckpoint
{
	return [self _lastCheckpointInColumn: @"Topology"];
}

- (unsigned int) lastTrajectoryCheckpoint
{
	return [self _lastCheckpointInColumn: @"Trajectory"];
}

- (NSNumber*) lastIterationNumber
{
	return [[iterationValue retain] autorelease];
}

- (void) addTopologyCheckpoint
{
	NSEnumerator* systemEnum;
	id system;

	//Clear previously collected data
	[topologyData removeAllObjects];

	//Add new checkpoints
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
		[self addTopologyCheckpointForSystem: system];
}

- (void) addTopologyCheckpointForSystem: (id) aSystem
{
	id topology;

	topologyCheckpoint = YES;
	topology = [[[aSystem dataSource] copy] autorelease];
	[topologyData setObject: topology
		forKey: [aSystem systemName]];
}

- (void) addTrajectoryCheckpoint
{
	NSKeyedArchiver* archiver;
	NSEnumerator* systemEnum;
	id system, state;
	
	trajectoryCheckpoint = YES;

	//Release previous trajectory checkpoint
	[trajectoryData release];
	
	//Checkpoint current trajectory
	
	trajectoryData = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] 
			initForWritingWithMutableData: trajectoryData];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	systemEnum = [[systemCollection fullSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		state = [system captureState];
		[archiver encodeObject: state 
			forKey: [system systemName]];
	}	

	[archiver finishEncoding];
	[archiver release];
}

- (void) addEnergyCheckpoint
{
	double potentialEnergy, totalEnergy, kineticEnergy;
	NSEnumerator* systemEnum;
	NSMutableArray* stateTerms = [NSMutableArray new];
	AdMolecularMechanicsForceField* systemForceField;
	id system, state;
	
	energyCheckpoint = YES;
	
	//Check that a forceFieldCollection is available before continuing
	if(forceFieldCollection == nil)
	{
		NSWarnLog(@"No force fields are provided - No energy data will be checkpointed");
		return;
	}	

	//Remove last energy checkpoint
	[energyData removeAllObjects];
		
	//Checkpoint new energies
	//Go through each system and add the relevant data to a dictionary of (TermName:TermValue pairs). 
	//Each dictionary is then added to energyData dictionary.
	//When the frame is close the arrays are added to the state matrix for each system (in closeFrame:)
	state = [NSMutableArray new];
	systemEnum = [[systemCollection allSystems] objectEnumerator];
	while((system = [systemEnum nextObject]))
	{
		//FIXME: Only one force field per system supported
		systemForceField = [[forceFieldCollection forceFieldsForSystem: system]
					objectAtIndex: 0];
		[state addObject: iterationValue];
		[stateTerms addObject: iterationHeader];
		
		potentialEnergy = [systemForceField totalEnergy];
		[state addObject:
			[NSNumber numberWithDouble: potentialEnergy]];
		[stateTerms addObject: @"PotentialEnergy"];	

		totalEnergy = potentialEnergy;
		if([system respondsToSelector: @selector(kineticEnergy)])
		{
			kineticEnergy =  [system kineticEnergy];
			totalEnergy += kineticEnergy;
			[state addObject:
				[NSNumber numberWithDouble: kineticEnergy]];
			[stateTerms addObject: @"KineticEnergy"];
				
			[state addObject:
				[NSNumber numberWithDouble: [system temperature]]];
			[stateTerms addObject: @"Temperature"];		
		}
				
		[state addObject:
			[NSNumber numberWithDouble: totalEnergy]];
		[stateTerms addObject: @"TotalEnergy"];	
			
		[state addObjectsFromArray: 
			[systemForceField allEnergies]];
		[stateTerms addObjectsFromArray: [systemForceField allTerms]];	
			
		NSDebugLLog(@"AdSimulationDataWriter", 
			@"State %@. State Terms %@", state, stateTerms);	
			
		//Add the array containing the checkpointed energies
		//to the energyData dictionary
		[energyData setObject: 
				[NSDictionary dictionaryWithObjects: state 
					forKeys: stateTerms]
			forKey: [system systemName]];
			
		[state removeAllObjects];
		[stateTerms removeAllObjects];	
	 }	
	 
	[stateTerms release];
	[state release];		
}

- (void) rollBackToFrame: (unsigned int) value
{
	BOOL wasCheckpointed;
	int start, i;
	int trajectory, energy, topology;
	NSRange energyRange;
	NSEnumerator* matrixEnum;
	NSIndexSet* indexSet;
	AdMutableDataMatrix* matrix;

	if(value > [frames numberOfRows])
		[NSException raise: NSRangeException
			format: @"(%@) %d is out of range %d",
			NSStringFromSelector(_cmd),
			value,
			[frames numberOfRows]];

	trajectory = energy = topology = 0;
	//From the frame after the requested frame to the
	//last recorded frame
	start = value + 1;
	for(i=start; i<lastFrame+1;i++)
	{
		wasCheckpointed = [[frames elementAtRow: i 
					ofColumnWithHeader: @"Trajectory"] 
			 		boolValue];

		if(wasCheckpointed)
			trajectory++;
			
		wasCheckpointed = [[frames elementAtRow: i
					ofColumnWithHeader: @"Energy"] 
			 		boolValue];

		if(wasCheckpointed)
			energy++;

		wasCheckpointed = [[frames elementAtRow: i 
					ofColumnWithHeader: @"Topology"] 
			 		boolValue];

		if(wasCheckpointed)
			topology++;
	}

	NSDebugLLog(@"AdSimulationDataWriter", @"Rolling back to frame %d", value);
	NSDebugLLog(@"AdSimulationDataWriter", @"Deleting %d trajectory checkpoints", trajectory);
	NSDebugLLog(@"AdSimulationDataWriter", @"Deleting %d energy checkpoints", energy);
	NSDebugLLog(@"AdSimulationDataWriter", @"Deleting %d topology checkpoints", topology);

	[dataStorage removeTrajectoryCheckpoints: trajectory];
	[dataStorage removeTopologyCheckpoints: topology];

	//Delete the energy frames
	matrixEnum = [[stateData dataMatrices] objectEnumerator];
	energyRange.length = energy;
	while((matrix = [matrixEnum nextObject]))
	{
		energyRange.location = [matrix numberOfRows] - energyRange.length;
		indexSet = [NSIndexSet indexSetWithIndexesInRange: energyRange];
		NSDebugLLog(@"AdSimulationDataWriter", 
			@"Removing %@ rows from matrix %@", indexSet, [matrix name]);
		[matrix removeRowsWithIndexes: indexSet];
	}	

	//Delete the frame information
	[frames removeRowsWithIndexes: 
		[NSIndexSet indexSetWithIndexesInRange: 
			NSMakeRange(start, lastFrame - start + 1)]];

	//Remove any data marked for checkpointing so far
	if(frameOpen)
	{
		energyCheckpoint = NO;
		trajectoryCheckpoint = NO;
		topologyCheckpoint = NO;
		[topologyData removeAllObjects];
		[energyData removeAllObjects];
		[trajectoryData release];
		trajectoryData = nil;
		frameOpen = NO;
	}

	lastFrame = value;
	[self synchToStore];
}

- (void) synchToStore
{
	NSKeyedArchiver* archiver;
	NSMutableData* data;
	
	NSDebugLLog(@"AdSimulationDataWriter", @"Synching to store");
	
	data = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: stateData forKey: @"root"];
	[archiver finishEncoding];
	[dataStorage setEnergyData: data];
	NSDebugLLog(@"AdSimulationDataWriter", @"Wrote %d bytes of energy data", [data length]);
	[archiver release];
	[data release];

	data = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: frames forKey: @"root"];
	[archiver finishEncoding];
	[dataStorage setFrameData: data];
	NSDebugLLog(@"AdSimulationDataWriter", @"Wrote %d bytes of frame data", [data length]);
	[archiver release];

	[dataStorage synchronizeStore];
	NSDebugLLog(@"AdSimulationDataWriter", @"Complete");
}

- (id) dataStorage
{
	return [[dataStorage retain] autorelease];
}

@end
