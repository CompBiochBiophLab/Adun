/*
   Project: UL

   Copyright (C) 2006 Free Software Foundation

   Author: Michael

   Created: 2006-07-05 16:09:03 +0200 by michael

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

#include "ULSQLDatabaseBackend.h"

@interface ULSQLDatabaseBackend (TableManagement)
/**
 Creates an array for each table containing the column names
 */
- (void) _createTableArrays;
/**
Returns a map of generic column names to specific column names for the given class
*/
- (NSMutableDictionary*) columnMapForClass: (NSString*) className;
@end

@implementation ULSQLDatabaseBackend

- (id) initWithClientName: (NSString*) name
		database: (NSString*) databaseName
		serverType: (NSString*) serverType 
		user: (NSString*) databaseUser
		password: (NSString*) password
		host: (NSHost*) host
{
	
	NSString* sqlClientDatabaseName;
	NSMutableDictionary* configurationDict, *sqlClients;
	
	if(self = [super init])
	{
		//retrieve the known sqlclients from 
		//the defaults (default name SQLClientReferences) 
		//so we can add the new configuration. If the default 
		//does not exist we create it.
	
		sqlClients = [[[NSUserDefaults standardUserDefaults]
			objectForKey: @"SQLClientReferences"] mutableCopy];
		if(sqlClients != nil)	
			[sqlClients autorelease];
		else
			sqlClients = [NSMutableDictionary dictionary];

		if(databaseName == nil)
			databaseName = @"Adun";
			
		if(databaseUser == nil)
			databaseUser = @"Adun";

		if(serverType == nil)
			serverType = @"Postgres";

		if(password == nil)
			password = @"";

		if(host == nil)
			host = [NSHost hostWithName: @"localhost"];
		
		if(name == nil)
			name = [NSString stringWithFormat: @"%@@%@",
					databaseUser, 
					[host name]];

		clientName = [name retain];
		
		//sqlclient database name has the format
		//databaseName@hostname
		
		sqlClientDatabaseName = [NSString stringWithFormat: @"%@@%@", 
						databaseName,
						[host name]];

		NSDebugLLog(@"ULSQLDatabaseBackend",
			@"The clients name is %@", 
			clientName);
		NSDebugLLog(@"ULSQLDatabaseBackend",
			@"Database name is %@", 
			sqlClientDatabaseName);				

		//create configuration dictionary for the new client

		configurationDict = [NSDictionary dictionaryWithObjectsAndKeys:
					sqlClientDatabaseName, @"Database", 
					databaseUser, @"User", 
					password, @"Password", 
					serverType, @"ServerType", 
					nil];
				
		//add the client information to the sqlClients dictionary
		[sqlClients setObject: configurationDict
			forKey: clientName];
		//update the defaults	
		[[NSUserDefaults standardUserDefaults] registerDefaults:
			[NSDictionary dictionaryWithObjectsAndKeys:
				sqlClients, @"SQLClientReferences", nil]];

		//By passing nil here we automatically cause SQLClient
		//to access the SQLClientReferences default
		dbClient= [[SQLClient alloc] 
			initWithConfiguration: nil 
			name: clientName];

		NSDebugLLog(@"ULSQLDatabaseBackend", 
			@"Attempting connection ... Result %d", 
			[dbClient connect]);

		tableForClass = [NSDictionary dictionaryWithObjects: 
			[NSArray arrayWithObjects: @"DataSets",
				@"Simulations",
				@"Systems", 
				@"Templates",
				nil]
			forKeys: [NSArray arrayWithObjects: 
				@"AdDataSet", 
				@"AdSimulationData",
				@"AdDataSource", 
				@"ULOptions",
				nil]];
		[tableForClass retain];		
		
		availableTypes = [NSArray arrayWithObjects: 
					[NSDictionary dictionaryWithObjectsAndKeys:
						 @"AdDataSet", @"ULObjectClassName",
						 @"DataSets", @"ULObjectDisplayName",
						 [dbClient database], @"ULDatabaseName",nil], 
					[NSDictionary dictionaryWithObjectsAndKeys:
						 @"AdDataSource", @"ULObjectClassName",
						 @"Systems", @"ULObjectDisplayName",
						 [dbClient database], @"ULDatabaseName",nil], 
					[NSDictionary dictionaryWithObjectsAndKeys:
						 @"AdSimulationData", @"ULObjectClassName",
						 @"Simulations", @"ULObjectDisplayName",
						 [dbClient database], @"ULDatabaseName",nil],

					nil];
		[availableTypes retain];

		[self _createTableArrays];
	}	

	return self;
}

- (void) dealloc
{
	[dbClient release];
	[indexArray release];
	[availableTypes release];
	[columnNames release];
	[tableForClass release];
	[genericColumns release];
	[clientName release];
	[super dealloc];
}

- (void) disconnectClient
{
	if(dbClient == nil)
		return;
	
	[dbClient disconnect];

	NSDebugLLog(@"ULSQLDatabaseBackend", 
		@"Checking disconnection - Are we connected %d", 
		[dbClient connected]);
}

- (void) addObject: (id) object toSchema: (NSString*) schema
{
	NSDictionary* dict;

	if(schema == nil)
		schema = @"PublicAdunObjects";

	dict = [NSDictionary dictionaryWithObjectsAndKeys:
			object, @"Object",
			schema, @"Schema",
			nil];

	[NSThread detachNewThreadSelector: @selector(_threadedAddObject:)
		toTarget: self
		withObject: dict];
}

/**************

Metadata

*****************/

- (id) metadataForObjectWithId: (NSString*) ident 
		ofClass: (id) className
		inSchema: (NSString*) schema
{
	id result;
	NSMutableDictionary* dict, *metadata;
	NSString* tableName;
	
	if(schema == nil)
		schema = @"PublicAdunObjects";
	
	dict = [self columnMapForClass: className];
	[dict setObject: [dbClient quote: ident] forKey: @"Identification"];
	[dict setObject: schema forKey: @"Schema"];

	NS_DURING
	{
		result = [dbClient query: @"SELECT \"{NameCol}\", \"{CreatorCol}\", \"{CreatedCol}\" " 
				@"FROM  \"{Schema}\".\"{Table}\" "
				@"WHERE \"{CodeCol}\" = {Identification} "
				with: dict];
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: SQLConnectionException])
		{
			//broadcast a @"ULDatabaseBackendConnectionDidDieNotification"
			//This lets the DatabaseInterface take some action
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendConnectionDidDieNotification"
				object: self];

			//Now raise an exception	
			[NSException raise: @"ULDatabaseConnectionException"
				format: @"Database connection error. Client %@", clientName];
		}
		else 
		{
			//create a ULGenericDatabaseException and raise it
			[NSException raise: @"ULGenericDatabaseException"
				format: [localException reason]];
		}
	}
	NS_ENDHANDLER
		
	NSLog(@"Retrieving Metadata");	
	metadata = [NSMutableDictionary dictionaryWithObjects: [result objectAtIndex: 0]
			forKeys: [NSArray arrayWithObjects:
					@"Name",
					@"Creator", 
					@"Created", 
					nil]];
	NSLog(@"Retrieved");	
	[metadata setObject: [dbClient database] forKey: @"Database"];	
	[metadata setObject: className forKey: @"Class"];	
	
	return metadata;
}

- (void) _updateAdDataSetMetadata: (id) infoDict
{
	NSMutableDictionary* dict;
	NSString* type, *schema;
	id object;

	type = NSStringFromClass([object class]);
	dict = [self columnMapForClass: type];
	
	[dict setObject: schema 
		forKey: @"Schema"];
	[dict setObject: [dbClient quote: [object name]] 
		forKey: @"Name"];
	[dict setObject: [dbClient quote: [object identification]] 
		forKey: @"Identification"];
		
	//exectute the request	

	[dbClient execute: @"UPDATE \"{Schema}\".\"{Table}\" "
		@"SET \"{NameCol}\" = {Name} WHERE  \"{CodeCol}\" = {Identification}"
		with: dict];
}

//FIXME: This only supports updating AdDataSets
- (void) updateMetadataForObject: (id) object
	inSchema: (NSString*) schema
{
	id objectType, selectorString;
	SEL selector;
	NSDictionary* dict;

	if(schema == nil)
		schema = @"PublicAdunObjects";

	dict = [NSDictionary dictionaryWithObjectsAndKeys:
			object, @"Object",
			schema, @"Schema",
			nil];
	/*
	 * When updating metadata only the metadata columns in the database
	 * are changed not the archived object. This means we dont have to keep
	 * rearchiving and transmitting possibly very large amounts of data for
	 * something like a name change. However the metadata in the archived object
	 * will obviously become out of synch we that stored in the table columns.
	 *
	 * To remedy this we update the archived objects metadata each time its is
	 * retrieved from the database with the newer values from the table.
	 * This in turn means that the only time the actual archived values
	 * will change is when the object is moved to another database.
	 */
			
	objectType = NSStringFromClass([object class]);
	selectorString = [NSString stringWithFormat: @"_update%@Metadata:", objectType];
	selector = NSSelectorFromString(selectorString);
	[self performSelector: selector withObject: dict];
	[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDatabaseInterfaceDidUpdateMetadataNotification"
			object: object];
}

- (id) unarchiveObjectWithID: (NSString*) ident 
	ofClass: (id) className 
	fromSchema: (NSString*) schema
{
	id object, result, metadata;
	NSData* data;
	NSKeyedUnarchiver* unarchiver;
	NSMutableDictionary* dict;
	NSString* tableName;
	
	if(schema == nil)
		schema = @"PublicAdunObjects";

	dict = [self columnMapForClass: className];
	[dict setObject: schema forKey: @"Schema"];
	[dict setObject: [dbClient quote: ident] forKey: @"Identification"];

	NS_DURING
	{
		result = [dbClient query: @"SELECT \"{DataCol}\" "
				@"FROM \"{Schema}\".\"{Table}\" "
				@"WHERE \"{CodeCol}\" = {Identification}"
				with: dict];
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: SQLConnectionException])
		{
			//broadcast a @"ULDatabaseBackendConnectionDidDieNotification"
			//This lets the DatabaseInterface take some action
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendConnectionDidDieNotification"
				object: self];

			//Now raise an exception	
			[NSException raise: @"ULDatabaseConnectionException"
				format: @"Database connection error. Client %@", clientName];
		}
		else 
		{
			//create a ULGenericDatabaseException and raise it
			[NSException raise: @"ULGenericDatabaseException"
				format: [localException reason]];
		}
	}
	NS_ENDHANDLER

	data = [[result objectAtIndex:0] objectForKey: [dict objectForKey: @"DataCol"]]; 
	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];
	object = [unarchiver decodeObjectForKey: @"root"];
	[[object retain] autorelease];
	[unarchiver finishDecoding];
	[unarchiver release];

	//Since an object isnt rearchived when its metadata changes (to
	//avoid many large transactions) we have to resynch each time it
	//is unarchived

	NSDebugMLLog(@"ULSQLDatabaseBackend", @"Object metadata %@", 
		[object metadata]);
	
	metadata =  [self metadataForObjectWithId: ident 
			ofClass: className
			inSchema: schema];
	[object updateMetadata: metadata];

	NSDebugMLog(@"ULSQLDatabaseBackend", @"Updated metadata %@", 
			[object metadata]);

	//add volatile metadata attribute "clientName" so we can identify later
	//which client the object belongs to
	[object setValue: [[clientName copy] autorelease] 
		forVolatileMetadataKey: @"DatabaseClient"];
	
	//if the object is a AdSimulationData we have to download the simulation
	//data and create a dataStorage object for it.

	if([object isKindOfClass: [AdSimulationData class]])
		[self _createDataStorageForSimulation: object
			inSchema: schema];
	
	return object;
}

- (void) removeObjectOfClass: (id) className 
		withID: (NSString*) ident
		fromSchema: (NSString*) schema
{
	NSMutableDictionary* dict;
	NSString* tableName;
	
	NSDebugMLLog(@"ULSQLDatabaseBackend", @"Removing %@ %@", ident, className);
	
	if(schema == nil)
		schema = @"PublicAdunObjects";

	dict = [self columnMapForClass: className];
	[dict setObject: [dbClient quote: ident] 
		forKey: @"Identification"];
	[dict setObject: schema 
		forKey: @"Schema"];
	
	NS_DURING
	{	
		[dbClient begin];
		if([className isEqual: @"AdSimulationData"])
			[self _removeTrajectoryForSimulationWithID: ident
				inSchema: schema];
	
		[dbClient execute: @"DELETE FROM \"{Schema}\".\"{Table}\" "
				@"WHERE \"{CodeCol}\" = {Identification}"
			with: dict];
		[dbClient commit];	
	}
	NS_HANDLER
	{
		[dbClient rollback];
		if([[localException name] isEqual: SQLConnectionException])
		{
			//broadcast a @"ULDatabaseBackendConnectionDidDieNotification"
			//This lets the DatabaseInterface take some action
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendConnectionDidDieNotification"
				object: self];

			//Now raise an exception	
			[NSException raise: @"ULDatabaseConnectionException"
				format: @"Database connection error. Client %@", clientName];
		}
		else 
		{
			//create a ULGenericDatabaseException and raise it
			[NSException raise: @"ULGenericDatabaseException"
				format: [localException reason]];
		}
	}
	NS_ENDHANDLER
}

- (void) removeObjectsOfType: (id) type withIDs: (NSArray*) idents
{
	NSWarnLog(@"Not implemented");
}

//Note: create the index once when the connection is establised
//Then just work with it. i.e. every time an object is added or
//removed update the local index.
//Note - Have to deal with objects removed by other people while
//connected.

- (NSArray*) availableObjectsOfClass: (id) className
		inSchema: (NSString*) schema
{
	id result;
	id entry;
	NSMutableDictionary* dict, *metadata;
	NSEnumerator* resultEnum;
	NSString* tableName;
	
	//cache available types
	if(indexArray ==  nil)
		[indexArray release];	
	
	if(schema == nil)
		schema = @"PublicAdunObjects";

	dict = [self columnMapForClass: className];
	[dict setObject: schema forKey: @"Schema"];

	NS_DURING
	{
		result = [dbClient query: @"SELECT \"{NameCol}\", \"{CreatorCol}\", "
				@"\"{CreatedCol}\", \"{CodeCol}\" " 
				@"FROM  \"{Schema}\".\"{Table}\" "
				with: dict];
		
		//convert the results into a dictionary format

		indexArray = [NSMutableArray new];
		resultEnum = [result objectEnumerator];
		while(entry = [resultEnum nextObject])
		{
			metadata = [NSMutableDictionary dictionaryWithObjects: entry
					forKeys: [NSArray arrayWithObjects:
							@"Name",
							@"Creator", 
							@"Created", 
							@"Identification",
							nil]];
			[metadata setObject: [dbClient database] forKey: @"Database"];	
			[metadata setObject: className forKey: @"Class"];	
			[indexArray addObject: metadata];
		}	
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: SQLConnectionException])
		{
			//broadcast a @"ULDatabaseBackendConnectionDidDieNotification"
			//This lets the DatabaseInterface take some action
			[[NSNotificationCenter defaultCenter]
				postNotificationName: @"ULDatabaseBackendConnectionDidDieNotification"
				object: self];
		}

		indexArray = nil;
	}
	NS_ENDHANDLER

	return indexArray;		
}

- (NSArray*) inputReferencesForObjectWithID: (NSString*) ident 
			ofClass: (id) className
			inSchema: (NSString*) schema
{
	return nil;
}

- (NSArray*) contentTypeInformationForSchema: (NSString*) schema
{
	return availableTypes;
}

- (NSArray*) schemaInformation
{
	id result;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	[dict setObject: [dbClient quote: [dbClient user]] 
		forKey: @"User"];

	//we can use the current query to get rid of pg_% schemas and 
	//the informatio schema. Or we can add Adun schemas to the
	//search path and use the commented out line instead
	result = [dbClient query: @"SELECT nspname FROM  pg_namespace WHERE "
			@"has_schema_privilege({User}, nspname, 'usage')"
			//@" AND nspname = ANY (current_schemas(true)) "
			@" AND ((nspname NOT LIKE 'pg_%') AND (nspname NOT LIKE 'info%')) "
			with: dict];
	
	NSLog(@"Results is %@", result);		
	return [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys:
			@"PublicAdunObjects", @"ULSchemaName",
			@"Usage", @"ULSchemaPrivileges", 
			[dbClient user], @"ULDatabaseUserName",
			[NSNumber numberWithBool: NO], @"ULSchemaOwner",
			[dbClient name], @"ULDatabaseClientName", nil]];
	
	//return result;
}

- (void) saveDatabase
{
	//does nothing
}

@end

@implementation ULSQLDatabaseBackend (TableManagement)

/**
 Creates an array for each table containing the column names
 */
- (void) _createTableArrays
{
	NSArray* dataSetColumnNames, *systemColumnNames;
	NSArray* templateColumnNames, *simulationColumnNames;
	
	genericColumns = [NSArray arrayWithObjects: 
			  @"CodeCol",
			  @"NameCol",
			  @"CreatorCol",
			  @"CreatedCol", 
			  @"DataCol",
			  nil];
	
	[genericColumns retain];
	
	dataSetColumnNames = [NSArray arrayWithObjects: 
			      @"DataSetCode",
			      @"DataSetName",
			      @"DataSetCreator",
			      @"DataSetCreationDate", 
			      @"DataSetData",
			      nil];
	
	systemColumnNames = [NSArray arrayWithObjects: 
			     @"SystemCode",
			     @"SystemName",
			     @"SystemCreator",
			     @"SystemCreationDate", 
			     @"SystemData",
			     nil];
	
	templateColumnNames = [NSArray arrayWithObjects: 
			       @"TemplateCode",
			       @"TemplateName",
			       @"TemplateCreator",
			       @"TemplateCreationDate", 
			       @"TemplateData",
			       nil];
	
	simulationColumnNames = [NSArray arrayWithObjects: 
				 @"SimulationCode",
				 @"SimulationName",
				 @"SimulationCreator",
				 @"SimulationCreationDate", 
				 @"SimulationData",
				 nil];
	
	columnNames = [NSMutableDictionary new];
	[columnNames setObject: dataSetColumnNames
			forKey: @"DataSets"];
	[columnNames setObject: systemColumnNames 
			forKey: @"Systems"];
	[columnNames setObject: simulationColumnNames
			forKey: @"Simulations"];
	[columnNames setObject: templateColumnNames
			forKey: @"Templates"];
}

//Returns a map of generic column names to specific 
//column names for the given class
- (NSMutableDictionary*) columnMapForClass: (NSString*) className
{
	NSMutableDictionary* dict;
	NSString* tableName;
	
	tableName = [tableForClass objectForKey: className];
	dict = [NSMutableDictionary dictionaryWithObjects:
		[columnNames objectForKey: tableName]
						  forKeys: genericColumns];
	[dict setObject: tableName forKey: @"Table"];
	
	return dict;
}

@end
