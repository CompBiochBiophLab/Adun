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

#include "ULFramework/ULDatabaseInterface.h"

static id databaseInterface;

@implementation ULDatabaseInterface

+ (id) databaseInterface
{
	//check if we have already created the databaseInterface
	if(databaseInterface != nil)
		return databaseInterface;
	else
	{
		databaseInterface = [self new];
		return [[databaseInterface retain] autorelease];
	}
}

- (BOOL) _isAvailableSQLDatabaseBackend
{
	NSBundle *sqlBackendBundle;
	
	//check if the AdunSQLDatabase bundle is available
	sqlBackendBundle = [NSBundle bundleWithPath: 
				[NSHomeDirectory() stringByAppendingPathComponent:
				@"GNUstep/Library/Bundles/ULSQLDatabaseBackend.bundle"]];
	if(sqlBackendBundle == nil)
		return NO;
	else
		return YES;
}

- (void) _loadSQLDatabaseBackend
{
	NSBundle *sqlBackendBundle;

	sqlBackendBundle = [NSBundle bundleWithPath: 
				[NSHomeDirectory() stringByAppendingPathComponent:
				@"GNUstep/Library/Bundles/ULSQLDatabaseBackend.bundle"]];


	if((ULSQLDatabaseBackend = [sqlBackendBundle principalClass]))
		NSDebugLLog(@"ULDatabaseInterface", @"Found SQL backend bundle.\n");
	else
		[NSException raise: NSInternalInconsistencyException 
			format: @"Specified plugin has no principal class"];
}

- (void) _initBackends
{
	NSString* resourcePath, *clientClassName;
	NSEnumerator* configurationEnum;
	NSError *error = nil;
	Class clientClass;
	id configuration;
	
	resourcePath = [[ULIOManager appIOManager] applicationDir];
	configurationFile = [resourcePath stringByAppendingPathComponent: 
					@"clientConfigurations.plist"];
	[configurationFile retain];				
	//read in stored client configurations and check
	clientConfigurations = [NSMutableArray arrayWithContentsOfFile:
				configurationFile];
	if(clientConfigurations == nil)
		clientConfigurations = [NSMutableArray new];

	[clientConfigurations retain];
	backendErrors = [NSMutableArray new];

	configurationEnum = [clientConfigurations objectEnumerator];
	while((configuration = [configurationEnum nextObject]))
	{
		//FIXME: Add handling of encoded passwords
		clientClassName = [configuration objectForKey: ULDatabaseBackendClass];

		//Check if class is available
		if((clientClass = NSClassFromString(clientClassName)) == nil)
		{
			NSWarnLog(@"Class %@ not available", clientClassName);
			NSWarnLog(@"Cannot initialise backend %@", configuration);
			continue;
		}	

		backend = [[clientClass alloc]
				initWithDatabaseName: [configuration objectForKey: ULDatabaseName]
				clientName: [configuration objectForKey: ULDatabaseClientName]
				host: [configuration objectForKey: @"ULDatabaseHost"]
				user: [configuration objectForKey: @"ULDatabaseUser"]
				password: nil
				error: &error];
		if(error == nil)
		{
			[backends setObject: backend
				forKey: [backend clientName]];
			[availableClients addObject: [backend clientName]];	
		}
		else
			[backendErrors setObject: error 
				forKey:[backend clientName]];

		error = nil;
	}
}

- (id) init
{
	id userName;

	if(databaseInterface != nil)
		return [databaseInterface retain];

	if((self = [super init]))
	{
		backends = [NSMutableDictionary new];

		//Set up the default backend
		userName = NSUserName();
		if(userName == nil)
			userName = @"Unknown";

		fileSystemBackend = [[ULFileSystemDatabaseBackend alloc]
					initWithDatabaseName: [[ULIOManager appIOManager] databaseDir]
					clientName: [NSString stringWithFormat: @"%@@localhost", userName]
					host: [NSHost hostWithName: @"localhost"]
					user: nil
					password:nil
					error: NULL];

		[backends setObject: fileSystemBackend 
			forKey: [fileSystemBackend clientName]];
		availableClients = [NSMutableArray new];
		[availableClients addObject: [fileSystemBackend clientName]];
		databaseInterface = self;

		if([self _isAvailableSQLDatabaseBackend])
		{
			NSWarnLog(@"SQLDatabase Bundle Available");
			[self _loadSQLDatabaseBackend];
		}
		else
		{
			NSWarnLog(@"AdunSQLDatabase bundle not available.");
			NSWarnLog(@"SQL backend support disabled");
		}	

		//Initialise all stored backends	
		[self _initBackends];

		//register for the various notification from the backends
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(_handleBackendNotification:)
			name: @"ULDatabaseBackendDidModifyContentsNotification"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(_handleBackendNotification:)
			name: @"ULDatabaseBackendConnectionDidDieNotification"
			object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(_handleBackendNotification:)
			name: @"ULDatabaseBackendDidReconnectNotification"
			object: nil];
	}

	return self;
}

- (void) dealloc
{
	[backendErrors release];
	[configurationFile release];
	[clientConfigurations release];
	[fileSystemBackend release];
	[backends release];
	[availableClients release];
	databaseInterface = nil;
	[super dealloc];
}

- (void) _handleBackendNotification: (NSNotification*) aNotification
{
	NSError* error;

	if([[aNotification name] isEqual: @"ULDatabaseBackendDidModifyContentsNotification"])
	{
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseInterfaceDidModifyContentsNotification"
			object: self];
	}
	else if([[aNotification name] isEqual: @"ULDatabaseBackendDidReconnectNotification"])
	{
		//Remove any errors about the backend unless they are corruption related
		backend = [aNotification object];
		error = [backendErrors objectForKey: [backend clientName]];
		if([error code] != ULDatabaseCorruptedError)
			[backendErrors removeObjectForKey: [backend clientName]];

		//Forward the notification - specifyting the client that reconnected
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseInterfaceDidReconnectNotification"
			object: self];
	}
	else if([[aNotification name] isEqual: @"ULDatabaseBackendConnectionDidDieNotification"])
	{
		//Get the error and add it to backend errors
		backend = [aNotification object];
		[backendErrors setObject: [backend databaseError]
			forKey: [backend clientName]];

		//Forward the notification - specifyting the client that disconnected
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseInterfaceConnectionDidDieNotification"
			object: self];
	}
}			

- (NSDictionary*) backendErrors
{
	return [[backendErrors copy] autorelease];
}

- (BOOL) addBackend: (id) object
{
	NSString* clientName;

	//Check name is unique
	//FIXME: Should create a protocol for the backend methods
	clientName = [object clientName];

	if(![availableClients containsObject: clientName])
	{
		[backends setObject: object
			forKey: clientName];
		[availableClients addObject: clientName];
		[clientConfigurations addObject: [object properties]];
		[clientConfigurations writeToFile: configurationFile 
			atomically: NO];
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseInterfaceDidAddBackendNotification"
			object: self];
		
		return YES;
	}

	return NO;
}

- (void) removeBackendForClient: (NSString*) clientName
{
	NSString* aString;
	NSEnumerator* configurationEnum;
	id configuration;

	if([clientName isEqual: [fileSystemBackend clientName]])
	{
		[NSException raise: NSInvalidArgumentException
			format: @"You cannot remove the primary filesystem database"];
	}

	backend = [self backendForClient: clientName];
	if(backend != nil)
	{
		[backends removeObjectForKey: clientName];
		[availableClients removeObject: clientName];
		configurationEnum = [clientConfigurations objectEnumerator];
		while((configuration = [configurationEnum nextObject]))
		{
			aString = [configuration objectForKey: ULDatabaseClientName];
			if([aString isEqual: clientName])
				break;
		}	

		[clientConfigurations removeObject: configuration];
		[clientConfigurations writeToFile: configurationFile 
			atomically: NO];
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseInterfaceDidRemoveBackendNotification"
			object: self];
	}
}

- (ULFileSystemDatabaseBackend*) primaryFileSystemBackend
{
	return fileSystemBackend;
}

- (id) backendForClient: (NSString*) clientName
{
	return [backends objectForKey: clientName];
}

- (ULDatabaseClientConnectionState) connectionStateForClient: (NSString*) clientName
{
	backend = [self backendForClient: clientName];
	return [backend connectionState];
}

- (BOOL) addObject: (id) object 
		toSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend addObject: object 
		toSchema: schema
		error: error];
}

- (BOOL) addObjectToFileSystemDatabase: (id) object
{
	return [fileSystemBackend addObject: object 
		toSchema: @"Local"
		error: NULL];
}

- (BOOL) objectInFileSystemDatabase: (id) object
{
	return [fileSystemBackend objectInDatabase: object
		error: NULL];
}

- (BOOL) updateMetadataForObject: (id) object 
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend updateMetadataForObject: object 
		inSchema: schema
		error: error];
}

- (BOOL) updateOutputReferencesForObject: (id) object
		error: (NSError**) error
{
	ULSchemaMode mode;
	NSEnumerator* clientEnum;
	NSArray* clients;
	id client;

	client = [object valueForVolatileMetadataKey: ULDatabaseClientName];
	if(client == nil)
	{
		//If the object has no DatabaseClient attribute it means it was archived
		//since the last time it was retrieved from its database.
		//Attempt to find a client for the object
		clients = [self clientsForDatabase: [object valueForMetadataKey: @"Database"]];
		if([clients count] == 0)
			[NSException raise: NSInternalInconsistencyException
				    format: @"Cannot find a client connected to the objects database. Cannot update output refereneces"];
		
		//find a client which allows writing to the objects schema
		clientEnum = [clients objectEnumerator];
		while((client = [clientEnum nextObject]))
		{
			backend = [self backendForClient: client];
			mode = [backend modeForSchema: [object valueForMetadataKey: @"Schema"]];
			if((mode == ULSchemaUpdateMode) || (mode == ULSchemaWriteMode))
			{
				[object setValue: client
					forVolatileMetadataKey: ULDatabaseClientName];
				break;
			}
			else
				client = nil;
		}
	}
	
	//If client is still nil we were unable to find a client for the object.
	if(client == nil)
		[NSException raise: NSInternalInconsistencyException
			    format: @"Cannot find a  writable client connected to the objects database. Cannot update output refereneces"];

	backend = [self backendForClient: client];
	return [backend updateOutputReferencesForObject: object
		inSchema: [object valueForMetadataKey: @"Schema"]
		error: error];
}

- (BOOL) removeObjectOfClass: (NSString*) className 
		withID: (NSString*) ident
		fromSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend removeObjectOfClass: className 
		withID: ident 
		fromSchema: schema
		error: error];
}

- (BOOL) removeObjectsOfClass: (NSString*) className 	
		withIDs: (NSArray*) idents
		fromSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend removeObjectsOfClass: className 
		withIDs: idents 
		fromSchema: schema
		error: error];
}

- (id) unarchiveObjectWithID: (NSString*) ident 
	ofClass: (NSString*) className 
	fromSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend unarchiveObjectWithID: ident 
		ofClass: className 
		fromSchema: schema
		error: error];
}

- (NSArray*) metadataForObjectsOfClass: (NSString*) className
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName
{
	id retval;

	backend = [self backendForClient: clientName];
	retval = [backend metadataForObjectsOfClass: className inSchema: schema];
	
	return retval;
}

- (NSDictionary*) metadataForObjectAtIndex: (unsigned int) objectIndex
		ofClass: (NSString*) className
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName
{
	id retval;
	
	backend = [self backendForClient: clientName];
	retval = [backend metadataForObjectAtIndex: objectIndex
			ofClass: className 
			inSchema: schema];
			
	return retval;
}

- (NSArray*) contentTypeInformationForSchema: (NSString*) schema
		ofClient: (NSString*) clientName
{
	backend = [self backendForClient: clientName];
	return [backend contentTypeInformationForSchema: schema];
}

- (id) metadataForObjectWithID: (NSString*) ident 
	ofClass: (NSString*)  className
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend metadataForObjectWithID: ident 
			ofClass: className
			inSchema: schema
			error: error];
}

- (id) outputReferencesForObjectWithID: (NSString*) ident 
	ofClass: (NSString*) className
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend outputReferencesForObjectWithID: ident 
		ofClass: className
		inSchema: schema
		error: error];
}

- (id) inputReferencesForObjectWithID: (NSString*) ident 
	ofClass: (NSString*)  className
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error
{
	backend = [self backendForClient: clientName];
	return [backend inputReferencesForObjectWithID: 
		ident ofClass: className
		inSchema: schema
		error: error];
}

- (BOOL) removeOutputReferencesToObjectWithID: ident
		ofClass: (NSString*) className
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error
{
	NSError* internalError = nil;
	NSString* client, *refSchema, *refIdent;
	NSArray* inputReferences, *dataArray;
	NSEnumerator *inputReferencesEnum, *dataEnum;
	id inputReference, objectData;

	//The arguments input references are the objects we are looking for.
	inputReferences = [self inputReferencesForObjectWithID: ident
				ofClass: className
				inSchema: schema
				ofClient: clientName 
				error: &internalError];
	if(internalError != nil)
	{
		*error = internalError;
		return NO;
	}
	else if(inputReferences == nil)
		return YES;

	inputReferencesEnum = [inputReferences objectEnumerator];
	while((inputReference = [inputReferencesEnum nextObject]))
	{
		//Find all objects with this id
		refIdent = [inputReference objectForKey: AdObjectIdentification];
		dataArray = [self findObjectsWithID: refIdent
				ofClass: [inputReference objectForKey: AdObjectClass]];	
		dataEnum = [dataArray objectEnumerator];		
		while((objectData = [dataEnum nextObject]))
		{
			client = [objectData objectForKey: ULDatabaseClientName];
			backend = [self backendForClient: client];
			refSchema = [objectData objectForKey: @"Schema"];
			
			if([backend modeForSchema: refSchema] != ULSchemaUpdateMode)
				continue;

			//FIXME: Difficult to handle multiple errors 
			//For now we assume if the client is available and writable
			//there wont be any. However just in case we will log them.
			[backend removeOutputReferenceToObjectWithID: ident
				fromObjectWithID: [objectData objectForKey: AdObjectIdentification]
				ofClass: [objectData objectForKey: AdObjectClass]
				inSchema: refSchema 	
				error: &internalError];
			if(internalError != nil)
			{
				AdLogError(internalError);
				internalError = nil;
			}	
		}
	}	

	return YES;
}

- (NSArray*) availableClients
{
	return [[availableClients copy] autorelease];
}

- (NSArray*) clientsForDatabase: (NSString*) string
{
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator* clientEnum;
	id clientName;

	clientEnum = [availableClients objectEnumerator];
	while((clientName = [clientEnum nextObject]))
	{
		backend = [self backendForClient: clientName];
		if([[backend databaseIdentifer] isEqual: string])
			[array addObject: clientName];
	}		

	return [[array copy] autorelease];		
}

- (NSArray*) schemaInformationForClient: (NSString*) clientName
{
	backend = [self backendForClient: clientName];
	return [backend schemaInformation];
}

- (ULSchemaMode) modeForSchema: (NSString*) schema ofClient: (NSString*) clientName
{
	backend = [self backendForClient: clientName];
	return [backend modeForSchema: schema];
}

- (void) saveDatabase
{
	//This method is no longer needed since the database
	//state is always saved after each modification.
	//i.e. saving the database will not add any new information
	/*NSEnumerator* backendsEnum = [backends objectEnumerator];

	while(backend = [backendsEnum nextObject])
		[backend saveDatabase];*/
}

- (void) updateDatabase
{
	NSEnumerator* backendsEnum = [backends objectEnumerator];

	while((backend = [backendsEnum nextObject]))
		[backend updateDatabase];
}

@end


@implementation ULDatabaseInterface (ULFinder)

- (NSArray*) findObjectsWithID: (NSString*) ident ofClass: (NSString*) className
{
	ULSchemaMode schemaMode;
	NSString* schemaName;
	NSMutableArray* array = [NSMutableArray array];
	NSDictionary* schemaInfo, *data;
	NSEnumerator* clientEnum, *schemaEnum;
	id clientName;

	clientEnum = [availableClients objectEnumerator];
	while((clientName = [clientEnum nextObject]))
	{
		backend = [backends objectForKey: clientName];
		schemaEnum = [[backend schemaInformation] 
				objectEnumerator];
		while((schemaInfo = [schemaEnum nextObject]))
		{
			schemaMode = [[schemaInfo objectForKey: ULSchemaModeValue] intValue];
			schemaName = [schemaInfo objectForKey: ULSchemaName];
			if(schemaMode != ULSchemaNoPermissionsMode)
			{
				data = [backend metadataForObjectWithID: ident
					ofClass: className
					inSchema: schemaName
					error: NULL];
				if(data	!= nil)
					[array addObject: data];
			}
		}	
	}

	return array;
}

@end

