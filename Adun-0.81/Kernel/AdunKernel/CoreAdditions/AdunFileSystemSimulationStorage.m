#include "AdunKernel/AdunFileSystemSimulationStorage.h"

/**
This category contains methods for updating a pre 0.74 simulation data
directory to enable caching of its trajectory data. Caching provides
a substantial apparent increase in the speed of accessing a simulations data.
It also overcomes memory problems when trying to access mulitple very large simulations
concurrently.
*/
@interface AdFileSystemSimulationStorage (TrajectoryCachingUpdates)
/**
Creates a matrix with one entry for each trajectory frame. The matrix has
two columns, size and offset. The first is the size in bytes of the trajectory
frame. The second is the offset in the trajectory archive where it begins.
*/
- (AdDataMatrix*) createTrajectoryInformationMatrix;
@end

@implementation AdFileSystemSimulationStorage (TrajectoryCachingUpdates)

- (AdDataMatrix*) createTrajectoryInformationMatrix
{
	int i;
	int bytesLength, location;
	unsigned char* bytes;
	NSMutableArray *row = [NSMutableArray new];
	AdMutableDataMatrix* informationMatrix;
	NSData *trajectoryData;
	NSString* lastTag;
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	informationMatrix = [[AdMutableDataMatrix alloc]
				initWithNumberOfColumns: 2
				columnHeaders: [NSArray arrayWithObjects: @"Size", @"Offset", nil]
				columnDataTypes: [NSArray arrayWithObjects: @"int", @"int", nil]];
	
	if(![fileManager fileExistsAtPath: trajectoryPath])
		return nil;
	
	trajectoryData = [fileManager contentsAtPath: trajectoryPath];
	bytesLength = 0;
	location = 0;
	bytes = (unsigned char*)[trajectoryData bytes];
	
	NSDebugLLog(@"AdFileSystemSimulationStorage", 
		@"Processing Trajectory - there is %d bytes of data.",
		[trajectoryData length]);
		
	/*
	 * Check for corrupted/no data
	 */
	if([trajectoryData length] < 7)
	{
		//If there is more than 7 bytes of data
		//it can be handled normally. However
		//less than seven will cause a segmentation
		//fault on checking if the last archive
		//is complete. Therefore we have to handle
		//this case here.
		
		NSWarnLog(@"Only %d bytes in archive",
			  [trajectoryData length]);
		NSWarnLog(@"Either an error occured during the simulation which generated this data or no coordinate data was collected");
		//If there was some corrupted data in the file delete it
		//trajectoryHandle is always created before this method is called.
		if([trajectoryData length] != 0)
			[trajectoryHandle truncateFileAtOffset: 0];
			
		numberTopologyCheckpoints = 0;
		[pool release];
		
		//Return the empty informationMatrix.
		[NSKeyedArchiver archiveRootObject: informationMatrix 
			toFile: trajectoryInfoPath];	
					
		return [informationMatrix autorelease];
	}	
	
	for(i = 0; i< (int)[trajectoryData length] - 1; i++)
		if(bytes[i] == '<' && bytes[i+1] == '?')
			if(i != 0)
			{
				bytesLength = i - location;
				[row addObject: [NSNumber numberWithInt: bytesLength]];
				[row addObject: [NSNumber numberWithInt: location]];
				[informationMatrix extendMatrixWithRow: row];
				NSDebugLLog(@"AdFileSystemSimulationStorage", @"Archive at %d. Size %d",
					    location, bytesLength);
				location = i;
				[row removeAllObjects];
			}
				
	//check the last archive is complete
	//i.e. it has a closing </plist> tag
	bytesLength = i - location + 1;
	lastTag = [[NSString alloc] 
			initWithBytes: &bytes[i - 7] 
			length: 8 
			encoding: NSUTF8StringEncoding];
	[lastTag autorelease];
	
	if([lastTag isEqual: @"</plist>"])
	{
		[row addObject: [NSNumber numberWithInt: bytesLength]];
		[row addObject: [NSNumber numberWithInt: location]];
		[informationMatrix extendMatrixWithRow: row];
		NSDebugLLog(@"AdFileSystemSimulationStorage", 
			    @"Archive at %d. Size %d", 
			    location, 
			    bytesLength);
	}
	else
		NSWarnLog(@"The last configuration frame is not complete.");

	[NSKeyedArchiver archiveRootObject: informationMatrix toFile: trajectoryInfoPath];
	[row release];
	[pool release];
	
	return [informationMatrix autorelease];
}

@end

/**
Checks the storage at path.
Returns True if it exists and is a valid storage.
Otherwise returns flase an \e error contains an error describing the problem
*/
BOOL AdCheckStorage(NSString* storagePath, NSError** error);

BOOL AdCheckStorage(NSString* storagePath, NSError** error)
{
	BOOL isDirectory;
	NSError* accessError = nil;
	NSString* systemPath;
	NSFileManager* fileManager;
	
	fileManager = [NSFileManager defaultManager];
	systemPath = [storagePath stringByAppendingPathComponent: @"system.ad"];
	
	if(![fileManager fileExistsAtPath: storagePath isDirectory: &isDirectory])
		accessError = AdCreateError(AdunCoreErrorDomain,
					    AdCoreSimulationDataStorageError,
					    @"Unable to access data store",
					    [NSString stringWithFormat: 
					     @"Data storage directory %@ does not exist",
					     storagePath],
					    @"Check the provided path is correct");
	
	//check its a results dir
	if(!isDirectory)
		accessError = AdCreateError(AdunCoreErrorDomain,
					    AdCoreSimulationDataStorageError,
					    @"Unable to access data store",
					    [NSString stringWithFormat: 
					     @"Specified storage %@ is not a directory",
					     storagePath],
					    @"Check the provided path is correct");
	
	//check it contains the required files
	if(![fileManager isReadableFileAtPath: systemPath])
		accessError = AdCreateError(AdunCoreErrorDomain,
					    AdCoreSimulationDataStorageError,
					    @"Unable to access data store",
					    [NSString stringWithFormat: 
					     @"Simulation data at %@ is not readable or not present",
					     storagePath],
					    @"Check the provided path is correct");
	
	if(accessError != nil)				
	{
		*error = accessError;				
		return NO;
	}
	else
		 return YES;	
}

@implementation AdFileSystemSimulationStorage

+ (void) initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
		[NSDictionary dictionaryWithObject: [NSNumber numberWithInt: 100]
			forKey: @"CacheLimit"]];
}

- (NSData*) _loadTrajectoryFrame: (int) frameNumber
{
	unsigned int index;
	unsigned long frameSize, frameStart;
	NSNumber* number;
	NSData* data;

	if(frameNumber > numberTrajectoryCheckpoints)
		return nil;

	//Check if the frame is in cache
	number = [[NSNumber alloc] initWithInt: frameNumber];
	if([cacheFrames containsObject: number])
	{
		index = [cacheFrames indexOfObject: number];
		data = [trajectoryCache objectAtIndex: index];
	}
	else
	{
		//Load frame
		frameStart = [[trajectoryInfo elementAtRow: frameNumber
				       ofColumnWithHeader: @"Offset"] longValue];
		frameSize = [[trajectoryInfo elementAtRow: frameNumber
				      ofColumnWithHeader: @"Size"] longValue];
		[trajectoryHandle seekToFileOffset: frameStart];
		data = [trajectoryHandle readDataOfLength:frameSize];
		[trajectoryCache insertObject: data atIndex: 0];
		[cacheFrames insertObject: [NSNumber numberWithInt: frameNumber]
				  atIndex: 0];
		
		if([cacheFrames count] > cacheLimit)
		{
			[trajectoryCache removeLastObject];
			[cacheFrames removeLastObject];
		}
	}
	
	[number release];
	return data;
}

- (void) _loadTrajectoryInfo
{
	//Check if the trajectory information archive exists -
	//if it doesnt we create it.
	
	if(![fileManager fileExistsAtPath: trajectoryInfoPath])
		trajectoryInfo = [self createTrajectoryInformationMatrix];
	else
		trajectoryInfo = [NSKeyedUnarchiver unarchiveObjectWithFile: trajectoryInfoPath];
	
	//In pre 0.13.1 versions of the framework trajectoryInfo was sometimes archived as an
	//immutable matrix. However in order to implement AdSimulationStorageAppendMode
	//and AdSimulationStorageUpdateMode it must be always be mutable.
	if(![trajectoryInfo isKindOfClass: [AdMutableDataMatrix class]])
		trajectoryInfo = [[trajectoryInfo mutableCopy] autorelease];
	
	[trajectoryInfo retain];
	numberTrajectoryCheckpoints = [trajectoryInfo numberOfRows];
}

- (void) _countTopologyCheckpoints
{
	int lastIndex = -1;
	int index;
	NSRange numberRange;
	NSEnumerator* directoryEnum;
	NSString *file;

	//Dont get caught is some other directory is somehow in the storage.
	//i.e. by using enumeratorAtPath:
	directoryEnum = [[fileManager directoryContentsAtPath: storagePath]
				objectEnumerator];
	while((file = [directoryEnum nextObject]))
	{
		if([file length] > 8)
			if([[file substringToIndex: 8] isEqual: @"topology"])
			{
				//Range of the number specifying the index
				numberRange = NSMakeRange(8, ([file length] - 11));
				index = [[file substringWithRange: numberRange] intValue];
				if(index > lastIndex)
					lastIndex = index;
			}
	}

	//Accounting for 0 offset
	numberTopologyCheckpoints = lastIndex + 1;
	NSDebugLLog(@"AdFileSystemSimulationStorage", 
		@"There are %d topology checkpoints",
		numberTopologyCheckpoints);
}

- (void) _checkStorage
{
	BOOL isDirectory;

	fileManager = [NSFileManager defaultManager];
	
	if(accessError != nil)
	{
		[accessError release];
		accessError = nil;
	}	
	
	isAccessible = AdCheckStorage(storagePath, &accessError);
	
	if(accessError != nil)
		[accessError retain];
}

+ (BOOL) storageExistsAtLocation: (NSString*) location
{
	return AdCheckStorage(location, NULL);
}

+ (id) storageForSimulation: (AdSimulationData*) simulation
		inDirectory: (NSString*) directory
		       mode: (AdSimulationStorageMode) mode
		      error: (NSError**) error
{		      
	AdSimulationData* data;
	
	data = [[AdFileSystemSimulationStorage alloc]
		initStorageForSimulation: simulation
		inDirectory: directory
		mode: mode
		error: error];
	return [data autorelease];	
}

- (id) init
{
	return [self initSimulationStorageAtPath: nil 
		mode: AdSimulationStorageReadMode 
		error: NULL];
}

- (id) initForReadingSimulationDataAtPath: (NSString*) path error: (NSError**) anError;
{
	return [self initSimulationStorageAtPath: path 
			mode: AdSimulationStorageReadMode 
			error: anError];
}

- (id) initForReadingSimulationDataAtPath: (NSString*) path
{
	return [self initForReadingSimulationDataAtPath: path
			error: NULL];
}

- (id) initStorageForSimulation: (AdSimulationData*) simulation
		    inDirectory: (NSString*) directory
			   mode: (AdSimulationStorageMode) mode
			  error: (NSError**) error
{			  
	NSString* path;
	
	path = [[simulation identification] stringByAppendingString: @"_Data"];
	if(directory != nil)
		path = [directory stringByAppendingPathComponent: path];
		
	return [self initSimulationStorageAtPath: path
		mode: mode
		error: error];
}
- (id) initSimulationStorageAtPath: (NSString*) path 
	mode: (AdSimulationStorageMode) mode 
	error: (NSError**) anError
{
	BOOL isDirectory;

	if((self = [super init]))
	{
		fileManager = [NSFileManager defaultManager];

		isAccessible = YES;
		isTemporary = NO;

		storageMode = mode;
		accessError = nil;
		dataError = nil;
		trajectoryInfo = nil;
		numberTrajectoryCheckpoints = 0;
		numberTopologyCheckpoints = 0;
		storagePath = [path retain];
		trajectoryPath = [storagePath stringByAppendingPathComponent: @"trajectory.ad"];
		trajectoryInfoPath = [storagePath stringByAppendingPathComponent: @"trajectoryInformation.ad"];
		energyPath = [storagePath stringByAppendingPathComponent: @"energy.ad"];
		systemPath = [storagePath stringByAppendingPathComponent: @"system.ad"];
		cacheLimit = [[NSUserDefaults standardUserDefaults]
				integerForKey: @"CacheLimit"];
		
		if(storageMode == AdSimulationStorageUpdateMode)
		{
			[NSException raise: NSInvalidArgumentException
				format: @"AdSimulationStorageUpdateMode not supported yet"];
		}		
		else if(storageMode == AdSimulationStorageWriteMode)
		{
			//Check the store exists if not create it
			//If we fail we will catch it below in checkStorage
			if(![fileManager fileExistsAtPath: storagePath isDirectory: &isDirectory])
			{
				[fileManager createDirectoryAtPath: storagePath
					attributes: nil];
				[fileManager createFileAtPath: trajectoryPath
					contents: nil
					attributes: nil];
				[fileManager createFileAtPath: energyPath
					contents: nil
					attributes: nil];
				[fileManager createFileAtPath: systemPath
					contents: nil
					attributes: nil];
				[fileManager createFileAtPath: trajectoryInfoPath
						     contents: nil
						   attributes: nil];
				[fileManager createFileAtPath: 
					[storagePath stringByAppendingPathComponent: @"frames.ad"]
					contents: nil
					attributes: nil];
			}
			else
				[NSException raise: NSInvalidArgumentException
					format: @"Store already exists"];
		}

		trajectoryCache = [NSMutableArray new];
		cacheFrames = [NSMutableArray new];
		trajectoryHandle = nil;
		energyHandle = nil;
	
		[trajectoryInfoPath retain];
		[trajectoryPath retain];
		[energyPath retain];
		[systemPath retain];
				
		//Check the storage	
		[self _checkStorage];

		if([self isAccessible])
		{
			if(storageMode == AdSimulationStorageWriteMode)
			{
				//Set up the streams if we are not in read mode
				trajectoryHandle = [NSFileHandle fileHandleForUpdatingAtPath: trajectoryPath];
				[trajectoryHandle retain];
				[trajectoryHandle seekToEndOfFile];
				energyHandle = [NSFileHandle fileHandleForWritingAtPath: energyPath ];
				[energyHandle retain];
				trajectoryInfo = [[AdMutableDataMatrix alloc]
							initWithNumberOfColumns: 2
							columnHeaders: [NSArray arrayWithObjects: @"Size", @"Offset", nil]
							columnDataTypes: [NSArray arrayWithObjects: @"int", @"int", nil]];
				[NSKeyedArchiver archiveRootObject: trajectoryInfo 
					toFile: trajectoryInfoPath];			
			}
			else if(storageMode == AdSimulationStorageAppendMode)
			{	
				trajectoryHandle = [NSFileHandle fileHandleForUpdatingAtPath: trajectoryPath];
				[trajectoryHandle retain];
				[trajectoryHandle seekToEndOfFile];
				energyHandle = [NSFileHandle fileHandleForUpdatingAtPath: energyPath ];
				[energyHandle retain];
				[self _loadTrajectoryInfo];
				[self _countTopologyCheckpoints];
			}
			else
			{
				trajectoryHandle = [NSFileHandle fileHandleForReadingAtPath: trajectoryPath];
				[trajectoryHandle retain];
				[self _loadTrajectoryInfo];
				[self _countTopologyCheckpoints];
			}	
		}	
	}
		
	if(anError != NULL)
		*anError = accessError;
	
	return self;
}

- (void) dealloc
{
	if(isTemporary)
		if(![self destroyStoredData])
			NSWarnLog(@"Could not destory temporary storage at %@",
					storagePath);

	[trajectoryHandle closeFile];
	[energyHandle closeFile];
	[trajectoryHandle release];
	[energyHandle release];
	[trajectoryPath release];
	[trajectoryInfoPath release];
	[energyPath release];
	[systemPath release];
	[storagePath release];
	[accessError release];
	[trajectoryCache release];
	[cacheFrames release];
	[trajectoryInfo release];
	[dataError release];
	[super dealloc];
}

- (unsigned long long) sizeOfStore
{ 
	unsigned long long size;
	NSEnumerator* directoryEnum;
	NSString* path, *file;
	NSDictionary* attributes;

	//Dont get caught if some other directory is somehow in the storage.
	//i.e. by using enumeratorAtPath:
	directoryEnum = [[fileManager directoryContentsAtPath: storagePath]
				objectEnumerator];
	size = 0;			
	while((file = [directoryEnum nextObject]))
	{
		path = [storagePath stringByAppendingPathComponent: file];
		attributes = [fileManager fileAttributesAtPath: path
				traverseLink: NO];
		if([[attributes objectForKey: NSFileType] 
			isEqual: NSFileTypeRegular])
		{
			size += [[attributes objectForKey: NSFileSize] longLongValue];
		}	
	}

	return size;
}

- (BOOL) destroyStoredData
{
	int retVal;

	if(isAccessible)
	{
		retVal = [fileManager removeFileAtPath: storagePath
				handler: nil];
		//If its deleted set accessError and isAccessible
		//using _checkStorage
		if(retVal)
			[self _checkStorage];
	}
	else
		retVal = NO;
		
	return retVal;
}

- (NSString*) identification
{
	NSString* path;

	if(storageMode & AdSimulationStorageWriteMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Data store in write only mode"];

	path = [storagePath stringByAppendingPathComponent: @"id.ad"];
	if(![fileManager fileExistsAtPath: path])
		return nil;

 	return [NSString stringWithContentsOfFile: path];
}	

- (NSData*) trajectoryCheckpoint: (int) number
{
	if(storageMode & AdSimulationStorageWriteMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Data store in write only mode"];

	return [self _loadTrajectoryFrame: number];
}

- (NSData*) topologyCheckpoint: (int) number
{
	NSString* path;

	if(storageMode & AdSimulationStorageWriteMode)
		[NSException raise: NSInternalInconsistencyException
			    format: @"Data store in write only mode"];

	if(number >= numberTopologyCheckpoints)
		[NSException raise: NSRangeException
			format: @"Topology - Index %d is out of range %d", 
			number, numberTopologyCheckpoints];

	path = [storagePath stringByAppendingPathComponent:
		[NSString stringWithFormat: @"topology%d.ad", number]];
	return [fileManager contentsAtPath: path];
}

- (NSData*) energyData
{
	if(storageMode & AdSimulationStorageWriteMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Data store in write only mode"];
	
	if(![fileManager fileExistsAtPath: energyPath])
		return nil;

 	return [fileManager contentsAtPath: energyPath];
}

- (NSData*) frameData
{
	NSString* path;

	NSDebugLLog(@"AdFileSystemSimulationStorage", @"Loading frame data");
	if((storageMode == AdSimulationStorageWriteMode) || (storageMode == AdSimulationStorageAppendMode))
		[NSException raise: NSInternalInconsistencyException
			format: @"Data store in write only mode"];

	path = [storagePath stringByAppendingPathComponent: @"frames.ad"];
	if(![fileManager fileExistsAtPath: path])
		return nil;

 	return [fileManager contentsAtPath: path];
}


- (NSData*) systemData
{
	if(storageMode & AdSimulationStorageWriteMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Data store in write only mode"];

	if(![fileManager fileExistsAtPath: systemPath])
		[NSException raise: NSInternalInconsistencyException
			format: @"System data missing"];

 	return [fileManager contentsAtPath: systemPath];
}

- (BOOL) isAccessible
{
	[self _checkStorage];
	return isAccessible;
}

- (NSError*) accessError
{
	return accessError;
}

- (NSError*) dataError
{
	return dataError;
}	

- (NSString*) storagePath
{
	return [[storagePath retain] autorelease];
}

- (BOOL) isTemporary
{
	return isTemporary;
}

- (void) setIsTemporary: (BOOL) value
{
	isTemporary = value;
}

- (unsigned int) numberTrajectoryCheckpoints
{
	return numberTrajectoryCheckpoints;
}

- (unsigned int) numberTopologyCheckpoints
{
	return numberTopologyCheckpoints;
}

/**
Returns the storage mode.
*/
- (AdSimulationStorageMode) storageMode
{
	return storageMode;
}

- (void) addTrajectoryCheckpoint: (NSData*) data
{
	NSArray *row;

	if(storageMode == AdSimulationStorageReadMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot write to a data store in AdSimulationStorageReadMode"];
	
	row = [[NSArray alloc] initWithObjects: 
			[NSNumber numberWithInt: [data length]],
			[NSNumber numberWithInt: [trajectoryHandle offsetInFile]],
			nil];
	[trajectoryHandle writeData: data];
	[trajectoryInfo extendMatrixWithRow: row];
	[row release];
	
	numberTrajectoryCheckpoints++;
	NSDebugLLog(@"AdFileSystemSimulationStorage",
		@"Added %d bytes of trajectory data to store (%d)", 
		[data length], numberTrajectoryCheckpoints);
}

- (void) removeTrajectoryCheckpoints: (int) number;
{
	int i, start, size, truncateSize;

	if(storageMode == AdSimulationStorageReadMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot write to a data store in AdSimulationStorageReadMode"];

	if(number > numberTrajectoryCheckpoints)
		[NSException raise: NSRangeException
			format: @"(%@) %d is greater than number of available checkpoints",
			NSStringFromSelector(_cmd),
			number,
			numberTrajectoryCheckpoints];

	start = numberTrajectoryCheckpoints - number;
	for(truncateSize = 0, i=start; i<numberTrajectoryCheckpoints; i++)
		truncateSize += [[trajectoryInfo elementAtRow: start ofColumnWithHeader: @"Size"] intValue];

	NSDebugLLog(@"AdFileSystemSimulationStorage",
		@"Removing %d checkpoints from %d", number, numberTrajectoryCheckpoints);
	[trajectoryHandle synchronizeFile];
	size = [trajectoryHandle offsetInFile];
	NSDebugLLog(@"AdFileSystemSimulationStorage",
		@"Corresponds to %d bytes from trajectory of size %d", truncateSize, size);
	[trajectoryHandle truncateFileAtOffset: (size - truncateSize)];
	[trajectoryInfo removeRowsInRange:
		NSMakeRange([trajectoryInfo numberOfRows] - number, number)];
	[trajectoryHandle synchronizeFile];
	[NSKeyedArchiver archiveRootObject: trajectoryInfo toFile: trajectoryInfoPath];

	numberTrajectoryCheckpoints -= number;		

	NSDebugLLog(@"AdFileSystemSimulationStorage",
		@"Number of checkpoints %d - Data sizes stored %d",
		numberTrajectoryCheckpoints, 
		[dataPerCheckpoint count]);
}

/**
Writes \e data to the storage as energy data.
Any previous energy data is overwritten.
Raises an exception if the mode is AdSimulationStorageReadMode
*/
- (void) setEnergyData: (NSData*) data
{
	if(storageMode == AdSimulationStorageReadMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot write to a data store in AdSimulationStorageReadMode"];

	[energyHandle truncateFileAtOffset: 0];
	[energyHandle writeData: data];
	[energyHandle synchronizeFile];
}

- (void) setSystemData: (NSData*) data
{
	NSFileHandle* handle;

	if(storageMode == AdSimulationStorageReadMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot write to a data store in AdSimulationStorageReadMode"];

	handle = [NSFileHandle fileHandleForWritingAtPath: systemPath];
	//Remove any previous data
	[handle truncateFileAtOffset:0];
	[handle writeData: data];
	[handle closeFile];
}

- (void) setFrameData: (NSData*) data
{
	NSFileHandle* handle;

	if(storageMode == AdSimulationStorageReadMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot write to a data store in AdSimulationStorageReadMode"];

	handle = [NSFileHandle fileHandleForWritingAtPath: 
			[storagePath stringByAppendingPathComponent: @"frames.ad"]];
	//Remove any previous data
	[handle truncateFileAtOffset:0];
	[handle writeData: data];
	[handle synchronizeFile];
	[handle closeFile];
}

/**
Adds \e data to the stored topology data.
Raises an exception if the mode is AdSimulationStorageReadMode
*/
- (void) addTopologyCheckpoint: (NSData*) data
{
	NSString* file, *path;

	if(storageMode == AdSimulationStorageReadMode)
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot write to a data store in AdSimulationStorageReadMode"];

	//In fine C tradition the 1st checkpoint has index 0
	file = [NSString stringWithFormat: @"topology%d.ad",
			numberTopologyCheckpoints];
	path =[storagePath stringByAppendingPathComponent: file];
	[fileManager createFileAtPath: path
		contents: data
		attributes: nil];
	numberTopologyCheckpoints++;
	NSDebugLLog(@"AdFileSystemSimulationStorage", 
		@"Now %d topology checkpoints", 
		numberTrajectoryCheckpoints);
}

- (void) removeTopologyCheckpoints: (int) number
{
	int i, newCount;
	NSString* path;

	if(number > numberTopologyCheckpoints)
		[NSException raise: NSInvalidArgumentException
			format: @"(%@) %d is greater than number of available checkpoints",
			NSStringFromSelector(_cmd),
			number,
			numberTopologyCheckpoints];

	newCount = numberTopologyCheckpoints - number;
	NSDebugLLog(@"AdunFileSystemSimulationStorage",
		@"Removing %d checkpoints of %d - %d",
		number, numberTopologyCheckpoints, newCount);
	for(i=newCount; i<numberTopologyCheckpoints; i++)
	{
		path = [storagePath stringByAppendingPathComponent: 
				[NSString stringWithFormat: @"topology%d.ad", i]];
		[fileManager removeFileAtPath: path
			handler: nil];
	}
	numberTopologyCheckpoints = newCount;
}

- (void) synchronizeStore
{
	[NSKeyedArchiver archiveRootObject: trajectoryInfo 
		toFile: trajectoryInfoPath];
	NSDebugLLog(@"AdFileSystemSimulationStorage", @"Synching trajectory");	
	[trajectoryHandle synchronizeFile];
	NSDebugLLog(@"AdFileSystemSimulationStorage", @"Synching energy");
	[energyHandle synchronizeFile];
}

- (void) update
{
	if((storageMode == AdSimulationStorageWriteMode) || (storageMode == AdSimulationStorageAppendMode))
		return;
	
	[trajectoryInfo release];
	trajectoryInfo = [NSKeyedUnarchiver unarchiveObjectWithFile: trajectoryInfoPath];
	[trajectoryInfo retain];
	numberTrajectoryCheckpoints = [trajectoryInfo numberOfRows];		
}

@end
