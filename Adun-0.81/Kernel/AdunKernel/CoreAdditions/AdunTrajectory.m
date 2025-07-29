/*
 Project: Adun
 
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

#include <AdunKernel/AdunTrajectory.h>
#include <AdunKernel/AdunFileSystemSimulationStorage.h>
#include <AdunKernel/AdunMolecularMechanicsForceField.h>

@interface AdTrajectory (DataLoadingMethods)
/**
 Accesses the instances data store and extracts the simulation data.
 */
- (void) loadData;
/**
 Sets the data storage object the instance will use to access the simulation
 data.
 */
- (void) setDataStorage: (id) object;
@end

@implementation AdTrajectory (DataLoadingMethods)

- (void) _loadStateData: (NSData*) data;
{	
	NSDebugLLog(@"AdTrajectory", @"Load Energies...");	
	stateData = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	[stateData retain];
	NSDebugLLog(@"AdTrajectory", @"Finished");
	
	if(stateData == nil || [[stateData dataMatrices] count] == 0)
		NSWarnLog(@"Directory %@ contains no energy data",
			  [self dataPath]);
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
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
		frames = [unarchiver decodeObjectForKey: @"root"];
		[frames retain];
		[unarchiver finishDecoding];
		[unarchiver release];
	}	
	else
		NSWarnLog(@"No frame data present");
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
	NSDebugLLog(@"AdTrajectory", 
		    @"There are %d trajectory frames available",
		    [dataStorage numberTrajectoryCheckpoints]);
	NSDebugLLog(@"AdTrajectory", 
		    @"Read in %lf KB of energy data", 
		    ((double)[energyData length])/1024);
	
	[self _loadStateData: energyData];
	NSDebugLLog(@"AdTrajectory", @"Unarchiving system manager");
	[self _loadSystemCollection];
	NSDebugLLog(@"AdTrajectory", @"Unarchiving frame data");
	[self _loadFrames];
	NSDebugLLog(@"AdTrajectory", @"Complete");
	
	NSDebugLLog(@"AdTrajectory", @"Initialised AdTrajectory");
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
}

@end

@implementation AdTrajectory

+ (id) trajectoryFromLocation: (NSString*) directory
{
	return [self trajectoryFromLocation: directory error: NULL];
}

+ (id) trajectoryFromLocation: (NSString*) directory error: (NSError**) error
{		
	return [[[self alloc] initWithLocation: directory error: error] autorelease];
}

- (id) init
{
	return [self initWithLocation: nil error: NULL];	
}

- (id) initWithLocation: (NSString*) path error: (NSError**) error
{
	AdFileSystemSimulationStorage* storage;

	if((self = [super init]))
	{
		stateData = nil;
		systemCollection = nil;
		frames = nil;
		numberEnergyCheckpoints = 0;
		if(path != nil)
		{
			storage = [[AdFileSystemSimulationStorage alloc]
					initForReadingSimulationDataAtPath: path
					error: error];	
			if([storage isAccessible])
			{		
				[self setDataStorage: storage];
				[self loadData];
			}
		}
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

- (BOOL) compareCheckpointsForSystem: (id) aSystem inTrajectory: (AdTrajectory*) aTrajectory toSystem: (id) ourSystem range: (NSRange) range
{
	BOOL retval = NO;
	int i;
	AdMatrix* matrixOne, *matrixTwo;
	
	if(NSMaxRange(range) > [self numberTrajectoryCheckpoints]) 
		[NSException raise: NSInvalidArgumentException
			format: @"Specified range exceeds number of available trajectory checkpoints in receiver"];
			
	if(NSMaxRange(range) > [aTrajectory numberTrajectoryCheckpoints]) 
		[NSException raise: NSInvalidArgumentException
			    format: @"Specified range exceeds number of available trajectory checkpoints in provided trajectory"];
			    
	matrixOne = [[self coordinatesForSystem: ourSystem
			inTrajectoryCheckpoint: range.location] cRepresentation];	
	matrixTwo = [[self coordinatesForSystem: aSystem 
			inTrajectoryCheckpoint: range.location] cRepresentation];
			
	if(!AdCheckDoubleMatrixDimensions(matrixOne, matrixTwo))
	{															
		[NSException raise: NSInvalidArgumentException
			format: @"Cannot compare trajectories of specified systems. Different number of elements"];
	}
	
	for(i=range.location; i<NSMaxRange(range); i++)
	{
		[self coordinatesForSystem: ourSystem inTrajectoryCheckpoint: i usingBuffer: matrixOne];
		[aTrajectory coordinatesForSystem: aSystem inTrajectoryCheckpoint: i usingBuffer: matrixTwo]; 
		if(!AdCompareDoubleMatrices(matrixOne, matrixTwo, 1E-12))
		{	
			retval = NO;
			NSWarnLog(@"Detected differences between frame %d", i);
			break;
		}
	}
	
	[[AdMemoryManager appMemoryManager] freeMatrix: matrixOne];
	[[AdMemoryManager appMemoryManager] freeMatrix: matrixTwo];
	
	return retval;
}

- (id) dataStorage
{
	return [[dataStorage retain] autorelease];
}

//deprecated
- (NSString*) dataPath
{
	return [dataStorage storagePath];
}

- (NSString*) location
{
	return [dataStorage storagePath];
}

- (void) update
{
	[self loadData];
}

- (double) size
{
	return ((double)[dataStorage sizeOfStore])/(1024.0*1024.0);	
}

- (AdDataSet*) energies
{
	return [[stateData retain] autorelease];
}

- (AdSystemCollection*) systemCollection
{
	return [[systemCollection retain] autorelease];
}

- (NSArray*) systems
{
	return [systemCollection allSystems];
}

- (AdDataSet*) frames	
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

- (AdDataMatrix*) coordinatesForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number
{
	id memento;

	memento = [self mementoForSystem: system inTrajectoryCheckpoint: number];
	[system returnToState: memento];
	return [system valueForKey: @"coordinates"];
}

- (void) coordinatesForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number usingBuffer: (AdMatrix*) buffer
{
	id memento;

	memento = [self mementoForSystem: system inTrajectoryCheckpoint: number];
	[system returnToState: memento];
	AdCopyAdMatrixToAdMatrix([system coordinates], buffer);
}

- (NSString*) description
{
	NSMutableString *string = [NSMutableString string];
	NSEnumerator* systemEnum;
	id system, energies;
		
	if(systemCollection == nil)
	{
		[string appendString: @"AdTrajectory - No data loaded\n"];
		return string;
	}	
	
	[string appendFormat: @"AdTrajectory - location %@ - ", [self dataPath]];
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
	
	NSDebugLLog(@"AdTrajectory", 
		    @"Searching range %d-%d for data source", 
		    range.location, end);
	dataSource = nil;
	for(i = ([self numberTopologyCheckpoints] - 1); i>=0; i++ )
	{
		value = [self frameForTopologyCheckpoint: i];
		if(NSLocationInRange(value, range))
		{
			NSDebugLLog(@"AdTrajectory", 
				    @"Topology checkpoint %d is in the specfied range", i);
			//This checkpoint is in the range.
			//Now we must check it contains the required data.
			dataSource = [self dataSourceForSystem: system
					  inTopologyCheckpoint: i];
			if(dataSource != nil)
			{
				NSDebugLLog(@"AdTrajectory", @"Found data source");
				break;
			}	
			
			NSDebugLLog(@"AdTrajectory", 
				    @"Checkpoint does not contain data for system");	
		}
	}
	
	return dataSource;
}

@end

/**
For the moment these methods are private since AdMutableTrajectory
does not properly handle them being called twice.
*/
@interface AdMutableTrajectory (PrivateDataSetting)
/**
 Sets the system collection whose data will be recorded.
 */
- (void) setSystems: (AdSystemCollection*) aSystemCollection;
/**
 Sets the force fields used to track the systems state.
 */
- (void) setForceFields: (AdForceFieldCollection*) aForceFieldCollection;
@end


@implementation AdMutableTrajectory

+ (id) trajectoryFromLocation: (NSString*) directory
{
	return [self trajectoryFromLocation: directory error: NULL];
}

+ (id) trajectoryFromLocation: (NSString*) directory error: (NSError**) error
{		
	return [[[self alloc] initWithLocation: directory error: error] autorelease];
}

- (id) init
{
	return [self initWithLocation: nil error: NULL];
}

- (id) initWithLocation: (NSString*) path error: (NSError**) error
{
	return [self initWithLocation: path
			      systems: nil
			  forceFields: nil
		      iterationHeader: nil
		      error: error];
}

- (id) initWithLocation: (id) path
		systems: (AdSystemCollection*) aSystemCollection
	    forceFields: (AdForceFieldCollection*) aForceFieldCollection
	iterationHeader: (NSString*) aString
		  error: (NSError**) error
{
	AdSimulationStorageMode mode;
	NSArray* headers;
	AdDataMatrix* matrix;
	AdFileSystemSimulationStorage* tempStorage;	//!< Used for AdSimulationStorageAppendMode
	AdTrajectory* dataReader;
	AdSystemCollection* storedSystemCollection;	//!< Used fo AdSimulationStorageAppendMode
	
	if((self = [super init]))
	{
		frameOpen = NO;		
				
		//Check if the store exists 
		if(![AdFileSystemSimulationStorage storageExistsAtLocation: path])
		{
			mode = AdSimulationStorageWriteMode;
			//We have to create the store now - check that we've been provided
			//with the required data
			if(aSystemCollection == nil || aForceFieldCollection == nil)
				[NSException raise: NSInvalidArgumentException
					format: @"System collection and force-field collection are required when creating a new trajectory"];
		}
		else
		{
			mode = AdSimulationStorageAppendMode;
		}
				
		dataStorage = [[AdFileSystemSimulationStorage alloc]
			       initSimulationStorageAtPath: path 
			       mode: mode 
			       error: error];
	
		//Create a trajectory reader.
		//We will pass all reading messages to it
		trajectoryReader = [AdTrajectory trajectoryFromLocation: path error: NULL];
		[trajectoryReader retain];
		needsUpdate = NO;
			
		//Depending on whether we are writing or appending 
		//we have to initialise the object in a different way
		if([dataStorage storageMode] == AdSimulationStorageWriteMode)
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
			dataStorage = [dataStorage retain];	
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
		else if([dataStorage storageMode] == AdSimulationStorageAppendMode)
		{
			//Since we are appending to an existing store we
			//have to make sure the state of this object
			//is as it would be just after the last frame was written.
			
			dataStorage = [dataStorage retain];
			topologyData = [NSMutableDictionary new];
			energyData = [NSMutableDictionary new];
			forceFieldCollection = nil;
			trajectoryData = nil;
			
			storedSystemCollection = [trajectoryReader systemCollection];
			stateData = [trajectoryReader energies];
			frames = [[trajectoryReader frames] mutableCopy];
			lastFrame = (int)[frames numberOfRows] - 1;
			
			[stateData retain];
			
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
			
			NSDebugLLog(@"AdMutableTrajectory", 
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
	[trajectoryReader release];
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

- (NSMethodSignature*) methodSignatureForSelector: (SEL) aSelector
{
	NSMethodSignature* signature;
	
	//First check does this class implement the method, then check the reader, otherwise default
	if([self respondsToSelector: aSelector])
	{
		signature = [super methodSignatureForSelector: aSelector];
	}
	else if([trajectoryReader respondsToSelector: aSelector])
	{
		signature = [trajectoryReader methodSignatureForSelector: aSelector];
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
	
	if([trajectoryReader respondsToSelector: selector])
	{
		//Check if data has been written since the last read query
		if(needsUpdate == YES)
		{
			//Write out energy & frame data & refresh reader
			[self synchToStore];
			[trajectoryReader update];
		}
	
		[anInvocation invokeWithTarget: trajectoryReader];
	}
	else
	{
		[self doesNotRecognizeSelector: selector];
	}
}

- (NSString*) description
{
	return [[trajectoryReader description] 
			stringByReplacingString: @"AdTrajectory" 
			withString: @"AdMutableTrajectory"];
}

- (id) dataStorage
{
	return [[dataStorage retain] autorelease];
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
	NSDebugLLog(@"AdMutableTrajectory",
		    @"Recieved open frame request");
	NSDebugLLog(@"AdMutableTrajectory",
		    @"Frame open? - %d", frameOpen);
	NSDebugLLog(@"AdMutableTrajectory",
		    @"Current iteration value %@", iterationValue);
	NSDebugLLog(@"AdMutableTrajectory",
		    @"Requested iteration value %@", value);
	
	if(frameOpen)
		return;
	
	if([value isEqual: iterationValue])
		return;
	
	NSDebugLLog(@"AdMutableTrajectory", 
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
	
	NSDebugLLog(@"AdMutableTrajectory",
		    @"Closing frame %d", lastFrame);
	if(trajectoryCheckpoint)
	{
		[dataStorage addTrajectoryCheckpoint: trajectoryData];
		NSDebugLLog(@"AdMutableTrajectory",
			    @"Checkpointed %d bytes of trajectory data",
			    [trajectoryData length]);
		[checkpointed addObject: [NSNumber numberWithInt: 1]];
	}
	else
		[checkpointed addObject: [NSNumber numberWithInt: 0]];
	
	if(energyCheckpoint)
	{
		if(forceFieldCollection == nil)
			[checkpointed addObject: [NSNumber numberWithBool: NO]];
		else
		{
			[self _addEnergyCheckpoint];
			[checkpointed addObject: [NSNumber numberWithInt: 1]];
			[energyData removeAllObjects];
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
			NSDebugLLog(@"AdMutableTrajectory",
				    @"Checkpointing topology of %@", systemName);
			topology = [topologyData objectForKey: systemName];
			[archiver encodeObject: topology
					forKey: systemName];
		}
		
		[archiver finishEncoding];
		[archiver release];
		[dataStorage addTopologyCheckpoint: data];
		NSDebugLLog(@"AdMutableTrajectory",
			    @"Checkpointed %d bytes of topology data", [data length]);
		[data release];
		[checkpointed addObject: [NSNumber numberWithInt: 1]];
		[topologyData removeAllObjects];
	}
	else
		[checkpointed addObject: [NSNumber numberWithInt: 0]];
	
	[frames extendMatrixWithRow: checkpointed];
	
	//Set for next frame
	[checkpointed release];
	energyCheckpoint = NO;
	trajectoryCheckpoint = NO;
	topologyCheckpoint = NO;
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

//FIXME: Move to trajectory Reader
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
			 
	needsUpdate = YES;		 
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
	
	needsUpdate = YES;
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
		
		NSDebugLLog(@"AdMutableTrajectory", 
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
	needsUpdate = YES;		
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
	
	NSDebugLLog(@"AdMutableTrajectory", @"Rolling back to frame %d", value);
	NSDebugLLog(@"AdMutableTrajectory", @"Deleting %d trajectory checkpoints", trajectory);
	NSDebugLLog(@"AdMutableTrajectory", @"Deleting %d energy checkpoints", energy);
	NSDebugLLog(@"AdMutableTrajectory", @"Deleting %d topology checkpoints", topology);
	
	[dataStorage removeTrajectoryCheckpoints: trajectory];
	[dataStorage removeTopologyCheckpoints: topology];
	
	//Delete the energy frames
	matrixEnum = [[stateData dataMatrices] objectEnumerator];
	energyRange.length = energy;
	while((matrix = [matrixEnum nextObject]))
	{
		energyRange.location = [matrix numberOfRows] - energyRange.length;
		indexSet = [NSIndexSet indexSetWithIndexesInRange: energyRange];
		NSDebugLLog(@"AdMutableTrajectory", 
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
	
	NSDebugLLog(@"AdMutableTrajectory", @"Synching to store");
	
	data = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: stateData forKey: @"root"];
	[archiver finishEncoding];
	[dataStorage setEnergyData: data];
	NSDebugLLog(@"AdMutableTrajectory", @"Wrote %d bytes of energy data", [data length]);
	[archiver release];
	[data release];
	
	data = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: frames forKey: @"root"];
	[archiver finishEncoding];
	[dataStorage setFrameData: data];
	NSDebugLLog(@"AdMutableTrajectory", @"Wrote %d bytes of frame data", [data length]);
	[archiver release];
	
	[dataStorage synchronizeStore];
	NSDebugLLog(@"AdMutableTrajectory", @"Complete");
}

@end 

@implementation AdMutableTrajectory (PrivateDataSetting)

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

- (void) setForceFields: (AdForceFieldCollection*) aForceFieldCollection
{
	[forceFieldCollection release];
	forceFieldCollection = [aForceFieldCollection retain];
	if(systemCollection != nil)
		[self _createStateMatrices];
}

@end
