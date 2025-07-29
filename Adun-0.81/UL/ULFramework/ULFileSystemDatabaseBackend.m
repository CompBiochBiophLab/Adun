/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-07-12 15:24:33 +0200 by michael johnston

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

#include "ULFramework/ULFileSystemDatabaseBackend.h"

NSString* ULDatabaseName=@"ULDatabaseName";
NSString* ULDatabaseClientName=@"ULDatabaseClientName";
NSString* ULDatabaseBackendClass=@"ULDatabaseBackendClass";
NSString* ULDatabaseUserName=@"ULDatabaseUserName";
NSString* ULSchemaName=@"ULSchemaName";
NSString* ULSchemaModeValue=@"ULSchemaModeValue";
NSString* ULSchemaOwner=@"ULSchemaOwner";

/**
Previous to Adun 0.73 there was a bug in ULFileSystemDatabaseBackend
where the database client name was set as the value for each objects
database metadata attribute instead of the actual database name.
This category adds a method to ULDatabaseIndex which causes an 
update of its internal index which contains the metadata for each object
to fix the problem.
*/
@interface ULDatabaseIndex (VersionUpdates)
- (void) _fixDatabaseName: (NSString*) name;
@end

/**
Category containing methods for locking/unlocking the
database indexes
*/

@interface ULFileSystemDatabaseBackend (ULIndexLocking)
/**
Calls _lockIndexInDir: passing the directory associated with \e class
*/
- (void) _lockIndexForClass: (NSString*) class;
/**
Calls _unlockIndexInDir: passing the directory associated with \e class
*/
- (void) _unlockIndexForClass: (NSString*) class;
/**
Locks the index in the directory at \e path. The index cannot be modified
by another ULFileSystemDatabaseBackend instance while the index
is locked. This method will return after achieving a lock. If it
cannot achieve a lock within the database timeout interval (10 secs) a
ULDatabaseTimeOutException is raised.
*/
- (void) _lockIndexInDir: (NSString*) path;
/**
Unlocks the the index in the directory at \e path. The index must have been 
previously locked using _lockIndexForClass: or _lockIndexInDir:.
*/
- (void) _unlockIndexInDir: (NSString*) path;
@end


@implementation ULFileSystemDatabaseBackend

-(void) _createIndex: (NSString*) indexName inDirectory: (NSString*) dir
{
	ULDatabaseIndex *tempIndex;

	if([[dir lastPathComponent] isEqual: @"Simulations"])
		tempIndex = [[ULDatabaseSimulationIndex alloc] 
			initWithDirectory: dir];
	else
		tempIndex = [[ULDatabaseIndex alloc] initWithDirectory: dir];
	
	[NSKeyedArchiver archiveRootObject: tempIndex toFile: 
		[dir stringByAppendingPathComponent: indexName]];
	[tempIndex release];
}

- (void) _saveIndex: (ULDatabaseIndex*) index ofClass: (NSString*) className
{
	id file;
	NSKeyedArchiver* archiver;
	NSMutableData* data = [NSMutableData data];

	if([className isEqual: @"AdDataSource"])
		file = [systemDir stringByAppendingPathComponent: @"SystemIndex"];
	else if([className isEqual: @"ULTemplate"])
		file = [optionsDir stringByAppendingPathComponent: @"OptionsIndex"];
	else if([className isEqual: @"AdDataSet"])
		file = [dataSetDir stringByAppendingPathComponent: @"DataSetIndex"];
	else if([className isEqual: @"AdSimulationData"])
		file = [simulationDir stringByAppendingPathComponent: @"SimulationIndex"];
	
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: index forKey: @"root"];
	[archiver finishEncoding];
	[data writeToFile: file atomically: NO];
	[archiver release];
}


- (id) _unarchiveIndexAtLocation: (NSString*) location error: (NSError**) error
{
	NSError* indexError;
	id object;	

	if((object = [NSKeyedUnarchiver unarchiveObjectWithFile: location]) == nil)
	{
		databaseState = ULDatabaseCorruptedState;
		indexError = AdCreateError(ULFrameworkErrorDomain,
				ULDatabaseCorruptedError,
				[NSString stringWithFormat: 
					@"Database at %@ corrupted!", databaseDir],
				[NSString stringWithFormat:
					@"The database index at %@ is missing.", location],
				@"Contact the developers for help");
		AdLogError(indexError);		
		if(error != NULL)
			*error = indexError;
	}

	return object;
}	

- (void) _updateIndexForClass: (NSString*) class
{
	NSString* name, *location;
	id index;

	//get the location
	location = [indexDirs objectForKey: class];
	name = [indexNames objectForKey: class];

	index = [self _unarchiveIndexAtLocation: 
			[location stringByAppendingPathComponent: name]
			error: NULL];
	[databaseIndexes setObject: index forKey: class];
}


- (ULDatabaseIndex*) _checkDirectory: (NSString*) path 
			withIndexName: (NSString*) indexName
			error: (NSError**) error
{
	BOOL isDir, exists;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	id index = nil;

	exists = YES;
	if(!([fileManager fileExistsAtPath: path isDirectory: &isDir] && isDir))
	{
		//This will set an error and return NO if it cant create the directory
		exists = [[NSFileManager defaultManager] 
				createDirectoryAtPath: path
				attributes: nil
				error: error];
		if(exists)
		{
			//If we cant create the index we'll detect this below
			[self _createIndex: indexName inDirectory: path];
			NSWarnLog(@"Database directory %@ was missing.", path);
			NSWarnLog(@"Created it and the corresponding index");
		}	
	}
	
	//Get the index if result is YES 
	//If its NO we already have the error set.
	//This method will set the error if the index doesnt exit.
	//We could try to recreate the index but for now we treat the
	//database as corrupted.
	if(exists)
	{
		//Aquire a lock on the index before attempting to unarchive it
		[self _lockIndexInDir: path];
		index =  [self _unarchiveIndexAtLocation: 
				[path stringByAppendingPathComponent: indexName]
				error: error];
		[self _unlockIndexInDir: path];
	}	

	return index;
}

- (BOOL) _checkDatabaseSubdirectories: (NSError**) error
{
	ULDatabaseIndex* systemIndex;
	ULDatabaseIndex* optionsIndex;
	ULDatabaseIndex* dataSetIndex;
	ULDatabaseIndex* simulationIndex;
	ULDatabaseIndex* index;
	NSEnumerator *indexEnum;

	systemDir = [[databaseDir stringByAppendingPathComponent: @"Systems"] retain];
	optionsDir = [[databaseDir stringByAppendingPathComponent: @"Options"] retain];
	dataSetDir = [[databaseDir stringByAppendingPathComponent: @"DataSets"] retain];
	simulationDir = [[databaseDir stringByAppendingPathComponent: @"Simulations"] retain];

	//Check each database subdir exists
	//If it does its index is returned
	//If error is set on return it means
	//1) The directory didnt exist and couldnt be created
	//2) The index didnt exist and couldnt be created
	//3) The index didnt exist. It was created but couldnt reindex the directory

	systemIndex = [self _checkDirectory: systemDir 
			withIndexName: @"SystemIndex"
			error: error];

	if(systemIndex == nil)
		return NO;
	else
		[systemIndex retain];

	optionsIndex = [self _checkDirectory: optionsDir 
			withIndexName: @"OptionsIndex"
			error: error];

	if(optionsIndex == nil)
		return NO;
	else	
		[optionsIndex retain];

	dataSetIndex = [self _checkDirectory: dataSetDir 
			withIndexName: @"DataSetIndex"
			error: error];

	if(dataSetIndex == nil)
		return NO;
	else	
		[dataSetIndex retain];

	simulationIndex = [self _checkDirectory: simulationDir 
				withIndexName: @"SimulationIndex"
				error: error];

	if(simulationIndex == nil)
		return NO;
	else	
		[simulationIndex retain];

	//Add the indexes to the correct arrays
	databaseIndexes = [NSMutableDictionary new];
	[databaseIndexes setObject: systemIndex forKey: @"AdDataSource"];
	[databaseIndexes setObject: optionsIndex forKey: @"ULTemplate"];
	[databaseIndexes setObject: dataSetIndex forKey: @"AdDataSet"];
	[databaseIndexes setObject: simulationIndex forKey: @"AdSimulationData"];
	
	//Set up other maps of class names to index names and locations
	indexDirs = [NSMutableDictionary new];
	[indexDirs setObject: systemDir forKey: @"AdDataSource"];
	[indexDirs setObject: optionsDir forKey: @"ULTemplate"];
	[indexDirs setObject: dataSetDir forKey: @"AdDataSet"];
	[indexDirs setObject: simulationDir forKey: @"AdSimulationData"];
	
	indexNames = [NSMutableDictionary new];
	[indexNames setObject: @"SystemIndex" forKey: @"AdDataSource"];
	[indexNames setObject: @"OptionsIndex" forKey: @"ULTemplate"];
	[indexNames setObject: @"DataSetIndex" forKey: @"AdDataSet"];
	[indexNames setObject: @"SimulationIndex" forKey: @"AdSimulationData"];

	/*
	 * Fix pre 0.8 indexes
	 * See the documentation for the VersionUpdates
	 * category of ULDatabaseIndex (at top of this file) 
	 * for more
	 */

	indexEnum = [databaseIndexes objectEnumerator];
	while((index = [indexEnum nextObject]))
		if([index version] < 0.8)
		{
			[index _fixDatabaseName: databaseDir]; 
			[index setVersion: 0.8];
		}

	return YES;	
}

- (void) _setWorkingEnvironment
{
	NSUserDefaults* userDefaults;

	//set an autosave timer
	userDefaults = [NSUserDefaults standardUserDefaults];
	
	if([userDefaults boolForKey: @"AutoUpdate"])
	{
		autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval: 
						[userDefaults floatForKey: @"AutoUpdateInterval"]
					target: self
					selector: @selector(autoUpdateIndexes:)
					userInfo: nil
					repeats: YES];	
	}
	
	if((userName = NSUserName()) == nil)
		userName = @"unknown";
		
	[userName retain];
	/*
	 * We have to add clientName because if two items have identical children 
	 * NSOutlineView cant distinguish between them.
	 * i.e. if client name is not present then contentInformation will be identical
	 * between different instances of this class.
	 * This is simply because an outline view can't contain.
	 * the same item - as returned by isEqual - twice.
	 * If two identical item, with different children are added, then it
	 * will display the children of one of them in both places.
	 * By adding the client name we can distinguish each element of the following
	 * array from the same element from another instance of this object.
	 * Extremely annoying ...
	 *
	 * A second problem - The content information should know what schema its from.
	 * Otherwise, if just given the information returned by contentTypeInformationForSchema:,
	 * you cant call any methods requiring the schema name - since you don't know it!
	 * This is what happens when using NSOutlineView where you have to make calls
	 * based on the information in one item.
	 * Here, since this class only currently supports one schema, we just add
	 * a key-value for it to the dictionary.
	 */
	contentInformation = [NSArray arrayWithObjects: 
				[NSDictionary dictionaryWithObjectsAndKeys:
					 @"AdDataSource", @"ULObjectClassName",
					 @"Systems", @"ULObjectDisplayName",
					 @"Local", ULSchemaName,
					 clientName, ULDatabaseClientName, nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					 @"ULTemplate", @"ULObjectClassName",
					 @"Templates", @"ULObjectDisplayName",
					 @"Local", ULSchemaName,
					 clientName, ULDatabaseClientName, nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					 @"AdDataSet", @"ULObjectClassName",
					 @"DataSets", @"ULObjectDisplayName",
					 @"Local", ULSchemaName,
					 clientName, ULDatabaseClientName, nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					 @"AdSimulationData", @"ULObjectClassName",
					 @"Simulations", @"ULObjectDisplayName",
					 @"Local", ULSchemaName,
					 clientName, ULDatabaseClientName, nil],
				nil];
	[contentInformation retain];	
}

- (BOOL) _checkConnectionAndPermissions: (NSError**) error
{
	BOOL readMode, writeMode, result;
	NSError* connectionError;
	NSMutableDictionary* info;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	result = YES;

	/*
	 * Check can we "connect".
	 * We can connect if the given database dir exists.
	 * Otherwise no.
	 */
	result = [fileManager directoryExistsAtPath: databaseDir
			error: error];

	//If we could connect proceed to check 
	//the schema permissions
	if(result)
	{
		connectionState = ULDatabaseClientConnected;
		//We'll change databaseState if we detect corruption
		databaseState = ULDatabaseNormalState;
		
		/*
		 * For the file system db this involves checking the 
		 * permissions of the database directory.
		 * We assume that the other directories have the 
		 * same permissions. This assumption is reinforced 
		 * since the classes managing the file system db never
		 * directly modify these (sub-direectory) permissions.
		 * 
		 * The read permission must be available to access the
		 * database in any way. If it isnt but write permissions 
		 * are it indicates that database has been corrupted by 
		 * an external agent. 	
		 */
	
		readMode = writeMode = NO;
		if([fileManager isReadableFileAtPath: databaseDir])
			readMode = YES;
		
		if([fileManager isWritableFileAtPath: databaseDir])
			writeMode = YES;
		
		if(writeMode && readMode)
		{
			schemaMode = ULSchemaUpdateMode;
			connectionState = ULDatabaseClientConnected;
		}	
		else if(readMode)
		{
			schemaMode = ULSchemaReadMode;
			connectionState = ULDatabaseClientConnected;
		}	
		else if(writeMode)
		{
			//This indicates an error
			connectionError = AdCreateError(ULFrameworkErrorDomain,
					ULDatabaseCorruptedError,
					@"Database corrupted",
					@"Database permissions have been modified by an external source",
					@"Database cannot have write only permissions");
			AdLogError(connectionError);		

			schemaMode = ULSchemaWriteMode;
			connectionState = ULDatabaseClientConnected;
			databaseState = ULDatabaseCorruptedState;
			result = NO;
		}	
		else
		{
			connectionState = ULDatabaseClientConnected;
			schemaMode = ULSchemaNoPermissionsMode;
		}	
	}
	else
	{
		connectionState = ULDatabaseClientNotConnected;
		schemaMode = ULSchemaUnknownMode;

		info = [NSMutableDictionary dictionary];
		[info setObject: @"Database Error"
			forKey: NSLocalizedDescriptionKey];
		[info setObject:@"Could not connect to the specified database"
			forKey: @"AdDetailedDescriptionKey"];	
		[info setObject:
			[NSString stringWithFormat: 
				@"Check a database exists at %@", databaseDir]
			forKey: @"NSRecoverySuggestionKey"];
			
		if(*error != nil)	
			[info setObject: *error
				forKey: NSUnderlyingErrorKey];
				
		connectionError = [NSError errorWithDomain: ULFrameworkErrorDomain
					code: ULDatabaseConnectionNotAvailableError
					userInfo: info];
		AdLogError(connectionError);			
		result = NO;
	}	

	if(result == NO && error != NULL)
		*error = connectionError;

	return result;
}

/**
Checks if the database operation \e operation which is either "Read" or "Write"
is possible. If not returns NO and \e error contains an NSError object detailing
why it isnt.
*/
- (BOOL) _checkOperation: (NSString*) operation error: (NSError**) error
{
	BOOL retval;
	NSString* string;
	NSError *operationError = nil;

	if([operation isEqual: @"Read"])
	{
		//We may need to use this message so create it now
		//for convenience
		string = @"Cannot perfrom read operation";
		if(connectionState != ULDatabaseClientConnected)
		{
			operationError = AdCreateError(ULFrameworkErrorDomain,
						ULDatabaseConnectionNotAvailableError,
						string,
						@"Client cannot connect to the database",
						@"Check the database read permissions");
			retval = NO;
		}
		else if(databaseState != ULDatabaseNormalState)
		{
			operationError = AdCreateError(ULFrameworkErrorDomain,
						ULDatabaseCorruptedError,
						string,
						@"The database has been corrupted",
						@"Check previous error log for details");
			retval = NO;
		}
		else
			retval = YES;

	}
	else if([operation isEqual: @"Write"])
	{
		//We may need to use this message so create it now
		//for convenience
		string = @"Cannot perfrom write operation";
		if(connectionState != ULDatabaseClientConnected)
		{
			operationError = AdCreateError(ULFrameworkErrorDomain,
						ULDatabaseConnectionNotAvailableError,
						string,
						@"Client cannot connect to the database",
						@"Check the database read permissions");
			retval = NO;
		}
		else if(databaseState != ULDatabaseNormalState)
		{
			operationError = AdCreateError(ULFrameworkErrorDomain,
						ULDatabaseCorruptedError,
						string,
						@"The database has been corrupted",
						@"Check previous error log for details");
			retval = NO;
		}
		else if(schemaMode != ULSchemaUpdateMode)
		{
			operationError = AdCreateError(ULFrameworkErrorDomain,
						ULSchemaWriteNoPermissionError,
						string,
						@"You do not have write permissions for this schema",
						@"The database owner must change permissions to allow writing");
			retval = NO;
		}
		else
			retval = YES;
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
			format: @"Unknown database operation %@", operation];
	}	

	if(operationError != nil && error != NULL)
	{
		AdLogError(operationError);
		*error = operationError;
	}	

	return retval;
}

- (id) init
{
	//Init with the standard db path
	return [self initWithDatabaseName: 
		[[ULIOManager appIOManager] databaseDir]
		error: NULL];
}

- (id) initWithDatabaseName: (NSString*) path 
	error: (NSError**) error
{
	return [self initWithDatabaseName: path
		clientName: [NSString stringWithFormat: @"%@@localhost", path]
		error: error];
}

- (id) initWithDatabaseName: (NSString*) path 
	clientName: (NSString*) name 
	error: (NSError**) error
{
	return [self initWithDatabaseName: path
		clientName: name
		host: nil
		user: nil
		password: nil
		error: error];
}

- (id) initWithDatabaseName: (NSString*) path 
	clientName: (NSString*) name
	host: (NSHost*) host
	user: (NSString*) user
	password: (NSString*) password
	error: (NSError**) error
{
	NSMutableDictionary* info;
	BOOL result;

	//Make these ivars equal to nil incase
	//we have to dealloc the object without setting them.
	contentInformation = nil;
	databaseIndexes = nil;
	userName = clientName = nil;
	databaseDir = systemDir = optionsDir = dataSetDir = simulationDir = nil;
	connectionState = ULDatabaseClientNotConnected;
	databaseState = ULDatabaseUnknownState;
	schemaMode = ULSchemaUnknownMode;

	if((self = [super init]))
	{
		internalError = nil;

		if(path == nil)
			databaseDir = [[ULIOManager appIOManager] 
					databaseDir];
		else
			databaseDir = path;

		[databaseDir retain];

		if(name != nil)
			clientName = name;
		else
			clientName = [NSString stringWithFormat: 
					@"%@@localhost", databaseDir];
		[clientName retain];

		//Check we can connect and that the permissions make sense
		result = [self _checkConnectionAndPermissions: &internalError];
		
		//Only check the subdirectories and set the working environment
		//If we are connected, theres no error and
		//we have permissions to read the database
		if(result && (schemaMode != ULSchemaNoPermissionsMode))
		{
			//Check the database structure
			//An error is always set if something goes wrong
			result = [self _checkDatabaseSubdirectories: &internalError];
			if(result)
			{
				[self _setWorkingEnvironment];
			}
			else
			{
				//Check the domain of the error.
				//If its ULFrameworkErrorDomain dont do anything.
				//If its not create a new error with the current 
				//one as an underlying error.
				//All errors comming from _checkDatabaseSubdirectories
				//are treated as corruption errors at the framework
				//level.

				if(![[internalError domain] 
					isEqual: ULFrameworkErrorDomain])
				{
					info = [NSMutableDictionary dictionary];
					[info setObject: 
						[NSString stringWithFormat: 
							@"Database at %@ corrupted!", 
							databaseDir]
						forKey: NSLocalizedDescriptionKey];
					[info setObject:	
						[NSString stringWithFormat:
							@"The database index at %@ is missing.", 
							path]
						forKey: @"AdDetailedDescriptionKey"];	
					[info setObject:
						@"Contact the developers for help"
						forKey: @"NSRecoverySuggestionKey"];
					[info setObject: internalError
						forKey: NSUnderlyingErrorKey];

					*error = [NSError errorWithDomain: ULFrameworkErrorDomain
							code: ULDatabaseCorruptedError
							userInfo: info];
					internalError = *error;
					databaseState = ULDatabaseCorruptedState;
					AdLogError(internalError);
				}
				else
					*error = internalError;
			}
		}
		else
		{
		 	*error = internalError;
		}

		if(internalError != nil)
			[internalError  retain];
	}

	return self;
}

- (void) dealloc
{
	[internalError release];
	[userName release];
	[contentInformation release];
	[clientName release];
	[autoUpdateTimer invalidate];
	[databaseDir release];
	[systemDir release];
	[optionsDir release];
	[dataSetDir release];
	[simulationDir release];
	[databaseIndexes release];
	[indexDirs release];
	[indexNames release];
	[super dealloc];
}

- (NSString*) databaseName
{
	return [[databaseDir retain] autorelease];
}	

- (NSString*) databaseIdentifer
{
	return [[databaseDir retain] autorelease];
}	

- (NSError*) databaseError
{
	return [[internalError retain] autorelease];
}

- (ULDatabaseClientConnectionState) connectionState
{
	return connectionState;
}	

- (NSDictionary*) properties
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		databaseDir, ULDatabaseName,
		clientName, ULDatabaseClientName, 
		NSStringFromClass([self class]), ULDatabaseBackendClass, nil];
}

- (NSString*) clientName
{
	return [[clientName retain] autorelease];
}

- (NSArray*) contentTypeInformationForSchema: (NSString*) schema
{
	if(databaseState == ULDatabaseCorruptedState
		|| connectionState == ULDatabaseClientNotConnected)
	{
		return nil;
	}

	//Currently this class only supports one schema called local.
	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	return [[contentInformation copy] autorelease];
}

- (ULSchemaMode) modeForSchema: (NSString*) schema
{
	return schemaMode;
}

- (BOOL) addObject: (id) object toSchema: (NSString*) schema error: (NSError**) error
{
	BOOL retval;
	NSString* class;
	id index;
	
	if(![self _checkOperation: @"Write" error: error])
		return NO;
	
	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];
	
	class = NSStringFromClass([object class]);
	
	if([indexNames objectForKey: class] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", class];

	//add database metadata to the object
	[object setValue: databaseDir 
		forMetadataKey: @"Database"
		inDomain: AdSystemMetadataDomain];
	[object setValue: @"Local" 
		forMetadataKey: @"Schema"
		inDomain: AdSystemMetadataDomain];
	//Set this database as the new location of this object.	
	[object setValue: [[clientName copy] autorelease] 
		forVolatileMetadataKey: ULDatabaseClientName];

	/*
	 * Writing to the database proceeds in five steps
	 * 1) Aquire a lock on the index
	 * 2) Update the index - Requires unarchiving the latest stored version
	 * 3) Get the index
	 * 4) Write to it
	 * 5) Save the index
	 * 6) Unlock it
	 * In this you always unarchive the most up-to-date version of the index.
	 */

	[self _lockIndexForClass: class]; 
	[self _updateIndexForClass: class];

	index = [databaseIndexes objectForKey: class];
	retval = [index addObject: object error: error];
	//FIXME: Check error return - Could indicate a disconnection/corruption event
	
	[self _saveIndex: index ofClass: class]; 
	[self _unlockIndexForClass: class];

	if(retval)
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
			object: object];

	return retval;
}

- (BOOL) objectInDatabase: (id) object error: (NSError**) error
{
	id index;
	NSString *class;
	
	if(![self _checkOperation: @"Read" error: error])
		return NO;

	class = NSStringFromClass([object class]);
	
	if([indexNames objectForKey: class] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", class];

	index = [databaseIndexes objectForKey: NSStringFromClass([object class])];
	return [index objectInIndex: object];
}

- (BOOL) updateMetadataForObject: (id) object inSchema: (NSString*) schema error: (NSError**) error
{
	BOOL retval;
	id index;
	NSString* class;
	
	if(![self _checkOperation: @"Write" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];
	
	class = NSStringFromClass([object class]);
	
	if([indexNames objectForKey: class] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", class];

	[self _lockIndexForClass: class]; 
	[self _updateIndexForClass: class];

	index = [databaseIndexes objectForKey: class];
	if(index != nil)
	{
		NS_DURING
		{
			retval = [index updateMetadataForObject: object 
					error: error];
		}
		NS_HANDLER
		{
			[self _unlockIndexForClass: class];
			[localException raise];
		}
		NS_ENDHANDLER
		
		[self _saveIndex: index ofClass: class]; 
		if(retval)
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
				object: object];
	}
	
	[self _unlockIndexForClass: class];

	return retval;
}

- (BOOL) updateOutputReferencesForObject: (id) object 
		inSchema: (NSString*) schema 
		error: (NSError**) error
{
	id index;
	NSString* class;
	
	if(![self _checkOperation: @"Write" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];
	
	class = NSStringFromClass([object class]);

	if([indexNames objectForKey: class] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", class];

	[self _lockIndexForClass: class]; 
	[self _updateIndexForClass: class];

	index = [databaseIndexes objectForKey: NSStringFromClass([object class])];
	if(index != nil)
	{
		NS_DURING
		{
			[index updateOutputReferencesForObject: object];
		}
		NS_HANDLER
		{
			[self _unlockIndexForClass: class];
			[localException raise];
		}
		NS_ENDHANDLER

		[self _saveIndex: index 
			ofClass: NSStringFromClass([object class])]; 
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
			object: object];
	}		

	[self _unlockIndexForClass: class];

	return YES;
}

- (BOOL) removeOutputReferenceToObjectWithID: (NSString*) identOne 
		fromObjectWithID: (NSString*) identTwo
		ofClass: (id) className 
		inSchema: (NSString*) schema
		error: (NSError**) error
{
	id index;

	if(![self _checkOperation: @"Write" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];
	
	[self _lockIndexForClass: className]; 
	[self _updateIndexForClass: className];

	index = [databaseIndexes objectForKey: className];

	if(index != nil)
	{
		NS_DURING
		{
			[index removeOutputReferenceToObjectWithId: identOne
				fromObjectWithId: identTwo];
		}
		NS_HANDLER
		{
			[self _unlockIndexForClass: className];
			[localException raise];
		}	
		NS_ENDHANDLER

		[self _saveIndex: index ofClass: className]; 
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
			object: nil];
	}	

	[self _unlockIndexForClass: className];
	
	return YES;
}

- (BOOL) removeObjectOfClass: (id) className 
		withID: (NSString*) ident 
		fromSchema: (NSString*) schema
		error: (NSError**) error
{
	BOOL retval;
	id index;

	if(![self _checkOperation: @"Write" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];
	
	[self _lockIndexForClass: className]; 
	[self _updateIndexForClass: className];

	index = [databaseIndexes objectForKey: className];
	if(index != nil)
	{
		NS_DURING
		{
			retval = [index removeObjectWithId: ident
					error: error];
		}
		NS_HANDLER
		{
			[self _unlockIndexForClass: className];
			[localException raise];
		}
		NS_ENDHANDLER

		[self _saveIndex: index ofClass: className]; 
		if(retval)
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
				object: nil];
	}	

	[self _unlockIndexForClass: className];

	return retval;
}

- (BOOL) removeObjectsOfClass: (id) className 
		withIDs: (NSArray*) idents
		fromSchema: (NSString*) schema
		error: (NSError**) error
{
	BOOL retval;
	id index; 
	
	if(![self _checkOperation: @"Write" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];

	[self _lockIndexForClass: className]; 
	[self _updateIndexForClass: className];

	index = [databaseIndexes objectForKey: className];
	if(index != nil)
	{
		NS_DURING
		{
			retval = [index removeObjectsWithIds: idents
					error: error];
		}
		NS_HANDLER
		{
			[self _unlockIndexForClass: className];
			[localException raise];
		}
		NS_ENDHANDLER

		[self _saveIndex: index ofClass: className]; 
		if(retval)
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
				object: nil];
	}	

	[self _unlockIndexForClass: className];

	return YES;
}

- (void) reindexAll
{
	NSWarnLog(@"Not implemented (%@)", NSStringFromSelector(_cmd));
}

- (id) unarchiveObjectWithID: (NSString*) ident 
	ofClass: (id) className
	fromSchema: (NSString*) schema
	error: (NSError**) error
{
	id index, object;

	if(![self _checkOperation: @"Read" error: error])
		return nil;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];

	//We dont need to lock the index since were not modifying it.
	//We assume there is no way, outside of querying the database
	//that the program can know an object has been added.
	index = [databaseIndexes objectForKey: className];
	if(index == nil)
		return nil;

	object = [index unarchiveObjectWithId: ident
			error: error]; 
	
	//add volatile metadata attribute "clientName" so we can identify later
	//which client the object belongs to
	if(object != nil)
		[object setValue: [[clientName copy] autorelease] 
			forVolatileMetadataKey: ULDatabaseClientName];

	return object;
}

//Deprecated - No longer necessary since the database
//state is saved on every write operation
- (void) saveIndexes
{
/*	NSEnumerator* indexEnum;
	id indexClass;

	indexEnum = [databaseIndexes keyEnumerator];
	while((indexClass = [indexEnum nextObject]))
		[self _saveIndex: [databaseIndexes objectForKey: indexClass]
			ofClass: indexClass];*/
}

- (void) saveDatabase
{
	[self saveIndexes];
}

- (void) autosaveIndexes: (id) info
{
	[self saveIndexes];
} 

- (void) updateIndexes
{
	NSEnumerator* indexEnum;
	id indexClass;

	if(connectionState == ULDatabaseClientNotConnected
		|| databaseState == ULDatabaseCorruptedState
		|| schemaMode == ULSchemaNoPermissionsMode)
	{
		return;
	}	

	indexEnum = [databaseIndexes keyEnumerator];
	while((indexClass = [indexEnum nextObject]))
	{
		[self _lockIndexForClass: indexClass]; 
		[self _updateIndexForClass: indexClass];
		[self _unlockIndexForClass: indexClass];
	}		
	
	[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseBackendDidModifyContentsNotification"
			object: self];
}

- (void) autoUpdateIndexes: (id) info
{
	[self updateIndexes];
}

- (NSArray*) metadataForObjectsOfClass: (id) className
		inSchema: (NSString*) schema;
{
	id index;
	
	if(![self _checkOperation: @"Read" error: NULL])
		return nil;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];
		
	index = [databaseIndexes objectForKey: className];
	
	return [index metadataForStoredObjects];
}

- (NSDictionary*) metadataForObjectWithID: (NSString*) ident 
			ofClass: (id) className
			inSchema: (NSString*) schema
			error: (NSError**) error
{
	id index;
	NSMutableDictionary* copy;
	NSDictionary* retval;
	
	if(![self _checkOperation: @"Read" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];

	index = [databaseIndexes objectForKey: className];
	retval = [index metadataForObjectWithID: ident];
	
	copy = [retval mutableCopy];
	[copy setValue: [self clientName] forKey: ULDatabaseClientName];
	retval = [[copy copy] autorelease];
	[copy release];
	
	return retval;
}

- (NSDictionary*) metadataForObjectAtIndex: (unsigned int) objectIndex 
			ofClass: (id) className
			inSchema: (NSString*) schema
{
	id index;
	NSMutableDictionary* copy;
	NSDictionary* retval;
	
	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			    format: @"Schema %@ is not valid", schema];
	
	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			    format: @"Invalid class %@", className];
	
	index = [databaseIndexes objectForKey: className];
	retval = [[index metadataForStoredObjects] objectAtIndex: objectIndex];
	
	copy = [retval mutableCopy];
	[copy setValue: [self clientName] forKey: ULDatabaseClientName];
	retval = [[copy copy] autorelease];
	[copy release];
	
	return retval;
}

- (NSArray*) outputReferencesForObjectWithID: (NSString*) ident 
		ofClass: (id) className 
		inSchema: (NSString*) schema
		error: (NSError**) error
{
	id index;
	
	if(![self _checkOperation: @"Read" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];

	index = [databaseIndexes objectForKey: className];
	return [index outputReferencesForObjectWithID: ident];
}

- (NSArray*) inputReferencesForObjectWithID: (NSString*) ident 
		ofClass: (id) className
		inSchema: (NSString*) schema
		error: (NSError**) error
{
	id index;
	
	if(![self _checkOperation: @"Read" error: error])
		return NO;

	if(![schema isEqual: @"Local"])
		[NSException raise: NSInvalidArgumentException
			format: @"Schema %@ is not valid", schema];

	if([indexNames objectForKey: className] == nil)
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid class %@", className];

	index = [databaseIndexes objectForKey: className];
	return [index inputReferencesForObjectWithID: ident];
}

- (NSArray*) schemaInformation
{
	if(connectionState == ULDatabaseClientNotConnected
		|| databaseState == ULDatabaseCorruptedState)
	{
		return nil;
	}	

	if(schemaMode == ULSchemaNoPermissionsMode)
		return [NSArray array];

	return [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys:
		@"Local", ULSchemaName,
		[NSNumber numberWithInt: schemaMode], ULSchemaModeValue, 
		userName, ULDatabaseUserName,
		[NSNumber numberWithBool: YES], ULSchemaOwner,
		clientName, ULDatabaseClientName, nil]];
}

- (NSString*) simulationDir
{
	return [[simulationDir retain] autorelease];
}

- (NSString*) templateDir
{
	return [[optionsDir retain] autorelease];
}

- (NSString*) systemDir
{
	return [[systemDir retain] autorelease];
}

- (NSString*) dataSetDir
{
	return [[dataSetDir retain] autorelease];
}

@end

/*
 * See definition for information on this category
 */
@implementation ULDatabaseIndex (VersionUpdates)

- (void) _fixDatabaseName: (NSString*) name
{
	NSString* currentDBName;
	NSEnumerator* indexEnum;
	id objectData;

	//For each index entry replace the value
	//of "Database" with name
	indexEnum = [index objectEnumerator];
	while((objectData = [indexEnum nextObject]))	
	{
		currentDBName = [objectData objectForKey: @"Database"];
		if(![currentDBName isEqual: name])	
			[objectData setObject: name forKey: @"Database"];
	}
}

@end


@implementation ULFileSystemDatabaseBackend (ULIndexLocking)

- (void) _lockIndexInDir: (NSString*) path
{
	BOOL retval;
	int attempts = 0;
	int waitTime = 1;
	int maxWaitTime = 10;
	int maxAttempts = 10;
	NSString* lockFile;
	NSDictionary* attributes;
	NSFileManager* fileManager = [NSFileManager defaultManager];

	//Check for lock file
	lockFile = [path stringByAppendingPathComponent: @"index.lock"];
	NSDebugLLog(@"ULFileSystemDatabaseBackend",
		@"Checking for lock file at %@", lockFile);
	
	while((attempts != maxAttempts) &&
		[fileManager fileExistsAtPath: lockFile])
	{
		//If it exists wait for a certain 
		//amount of time before retrying
		NSDebugLLog(@"ULFileSystemDatabaseBackend", 
			@"Lock file present - Waiting (attempt %d)", attempts);
		sleep(waitTime);
		attempts++;
	}

	//FIXME: Its possible that between now and the creation step
	//that any program, which was also waiting, beat us to the
	//lock creation. This may be very unlikely but needs to be
	//handled. At the moment we just raise a timeout exception.
	//However these should really be errors.

	if(attempts == maxAttempts)
	{
		NSWarnLog(@"Timed out. Unable to attain lock on %@", lockFile);
		[NSException raise: @"ULDatabaseTimeOutException"
			format: @"Unable to attain lock on %@. Timeout (%d secs)",
			lockFile,
			maxWaitTime];
	}		

	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLong: S_IWUSR | S_IWOTH | S_IRUSR | S_IROTH],
			@"NSFilePosixPermissions", nil];

	NSDebugLLog(@"ULFileSystemDatabaseBackend", @"Creating lock file");
	//Create it (with correct permissions)
	retval = [fileManager createFileAtPath: lockFile
			contents: nil
			attributes: attributes];
	if(!retval)
	{
		[NSException raise: @"ULDatabaseTimeOutException"	
			format: @"Unable to attain lock on %@. Timeout (%d secs)",
			lockFile,
			maxWaitTime];
	}

	NSDebugLLog(@"ULFileSystemDatabaseBackend", @"Done");	
}

- (void) _unlockIndexInDir: (NSString*) path
{
	//Delete lock file
	//There should be no modification of the lock file in the
	//short write period. Therefore there is no error checking yet.
	//It may be added later
	
	NSDebugLLog(@"ULFileSystemDatabaseBackend", 
		@"Unlocking index at %@", path);
	[[NSFileManager defaultManager]
		removeFileAtPath: 
			[path stringByAppendingPathComponent: @"index.lock"]
		handler: nil];	
	NSDebugLLog(@"ULFileSystemDatabaseBackend", 
		@"Done");	
}

- (void) _lockIndexForClass: (NSString*) class
{
	NSString* location;

	location = [indexDirs objectForKey: class];
	[self _lockIndexInDir: location];
}

- (void) _unlockIndexForClass: (NSString*) class
{
	NSString* location;

	location = [indexDirs objectForKey: class];
	[self _unlockIndexInDir: location];
}

@end
