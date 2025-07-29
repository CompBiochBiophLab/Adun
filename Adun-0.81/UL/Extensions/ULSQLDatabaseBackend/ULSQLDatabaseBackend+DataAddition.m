/*
 Project: SQLBackend
 
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

@implementation ULSQLDatabaseBackend (DataAddition)

//FIXME: Just fixme
- (void) _additionThreadDidTerminate: (id) object
{
	NSLog(@"Posting - exception is %@", object);
	
	if(object == nil)
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULDatabaseBackendDidAddObjectNotification"
		 object: self];
	}		
	else if([[object name] isEqual: SQLConnectionException])
	{
		//broadcast a @"ULDatabaseBackendConnectionDidDieNotification"
		//This lets the DatabaseInterface take some action
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULDatabaseBackendConnectionDidDieNotification"
		 object: self];
	}
	else 
	{
		NSLog(@"Exception %@", [object reason]);
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULDatabaseBackendAdditionFailedNotification"
		 object: self];
		//create a ULGenericDatabaseException and raise it
		/*[NSException raise: @"ULGenericDatabaseException"
		 format: [object reason]];*/
	}
}

- (void) _addGenericDataForObject: (id) object toSchema: (NSString*) schema
{
	NSMutableData* data = [NSMutableData new];
	NSKeyedArchiver* archiver;
	NSMutableDictionary* dict;
	NSString* type, *tableName;
	
	//add the database name to object
	[[[object dataDictionary] objectForKey: @"General Data"] 
	 setObject: [dbClient database] forKey: @"Database"];
	[[[object dataDictionary] objectForKey: @"General Data"] 
	 setObject: schema forKey: @"Schema"];
	
	//Archive the object
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: object forKey: @"root"];
	[archiver finishEncoding];
	
	type = NSStringFromClass([object class]);
	dict = [self columnMapForClass: type];
	
	//Add values to the dictionary		
	[dict setObject: schema
		 forKey: @"Schema"];
	[dict setObject: [dbClient quote: [object identification]] 
		 forKey: @"Identification"];
	[dict setObject: [dbClient quote: [object name]] 
		 forKey: @"Name"];
	[dict setObject: [dbClient quote: [object creator]] 
		 forKey: @"Creator"];
	[dict setObject: [NSDate dateWithNaturalLanguageString: [object created]] 
		 forKey: @"Created"];
	[dict setObject: data 
		 forKey: @"Data"];
	
	//exectute the request	
	
	[dbClient execute: @"INSERT INTO \"{Schema}\".\"{Table}\" "
	 @"(\"{CodeCol}\", \"{NameCol}\", \"{CreatorCol}\", "
	 @"\"{CreatedCol}\", \"{DataCol}\") "
	 @"VALUES ( {Identification}, {Name}, {Creator}, {Created}, {Data}) "
		     with: dict];
	
	[data release];
}

- (void) _addInputOutputReferencesForObject: object inSchema: (NSString*) schema
{
	
	id inputRefs, classType, refsForClass, ref;
	id refSchema, refDatabase, dict;
	NSEnumerator* classEnum, *refEnum;
	
	//tableForClass keys are class names
	classEnum = [tableForClass keyEnumerator];
	while(classType = [classEnum nextObject])
	{
		refsForClass = [object inputReferencesForObjectsOfClass: classType];
		refEnum = [refsForClass objectEnumerator];
		//FIXME: Everything here assumes an AdDataSet 
		//with a AdSimulationData as input ref
		while(ref = [refEnum nextObject])
		{
			//check if this is a local or remote reference
			refSchema = [ref valueForKey: @"Schema"];
			NSLog(@"Ref schema is %@", refSchema);
			refDatabase = [ref valueForKey: @"Database"];
			NSLog(@"Ref database is %@", refDatabase);
			
			dict = [NSDictionary dictionaryWithObjectsAndKeys:
				schema, @"Schema",
				@"SimulationDerivedDataSets", @"Table",
				[ref objectForKey: @"Identification"], @"SimulationCode",
				[object identification], @"DataSetCode", nil];
			
			if([refDatabase isEqual: [dbClient database]]
			   && [refSchema isEqual: schema])
			{
				[dbClient execute: @"INSERT INTO \"{Schema}\".\"{Table}\" "
				 @"(\"DataSetCode\", \"SimulationCode\") "
				 @"VALUES ( \"{DataSetCode}\", \"{SimulationCode}\")"
					     with: dict];
			}
			else
			{
				//make an entry for the ref class in RemoteDataReferences
				//FIXME: Check if is already present 
				//FIXME: Add name 
				
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					@"RemoteDataReferences", @"Schema",
					@"Simulations", @"Table",
					[dbClient quote: [ref objectForKey: @"Identification"]],
					@"SimulationID",
					[dbClient quote: [ref objectForKey: @"DatabaseName"]],
					@"Database",
					[dbClient quote: [ref objectForKey: @"SchemaName"]],
					@"SchemaName",
					nil];	
				
				[dbClient execute: @"INSERT INTO \"{Schema}\".\"{Table}\" "
				 @"(\"SimulationID\", \"Database\",\"Schema\") "
				 @"VALUES ( {SimulationID}, {Database}, {SchemaName})"
					     with: dict];
				
				//add a ref in the correct table in the objects schema
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					schema, @"Schema",
					@"RemoteSimulationDerivedDataSets", @"Table",
					[dbClient quote: [ref objectForKey: @"Identification"]], 
					@"SimulationCode",
					[dbClient quote: [object identification]],
					@"DataSetCode", nil];
				
				[dbClient execute: @"INSERT INTO \"{Schema}\".\"{Table}\" "
				 @"(\"DataSetCode\", \"SimulationCode\") "
				 @"VALUES ( {DataSetCode}, {SimulationCode})"
					     with: dict];
			}
		}
	}	
}

- (void) _addAdDataSet: (id) infoDict 
{
	NSString* schema;
	id object;
	
	object = [infoDict objectForKey: @"Object"];
	schema = [infoDict objectForKey: @"Schema"];
	
	[dbClient begin];
	[self _addGenericDataForObject: object toSchema: schema];
	[dbClient commit];
	[dbClient begin];
	//[self _addkeyworddataforobject: object];
	/*	[self _addInputOutputReferencesForObject: object
	 inSchema: schema];*/
	[dbClient commit];
}

- (void) _addAdDataSource: (id) infoDict
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	NSString* schema;
	id object;
	
	object = [infoDict objectForKey: @"Object"];
	schema = [infoDict objectForKey: @"Schema"];
	
	[dbClient begin];
	
	[self _addGenericDataForObject: object
			      toSchema: schema];
	
	//system unique data
	
	[dict setObject: [dbClient quote: @"Enzymix"] forKey: @"ForceField"];
	[dict setObject: [NSNumber numberWithDouble: 0.52] forKey: @"ULVersion"];
	[dict setObject: [dbClient quote: [object identification]] 
		 forKey: @"Identification"];
	[dict setObject: @"Systems" forKey: @"Table"];
	[dict setObject: schema forKey: @"Schema"];
	
	[dbClient execute: @"UPDATE \"{Schema}\".\"{Table}\" "
	 @"SET \"ForceField\" = {ForceField}, \"ULVersion\" = {ULVersion} "
	 @"WHERE \"SystemCode\" = {Identification} "
		     with: dict];
	
	/*[self _addkeyworddataforobject: object];
	 [self _addinputoutputreferencesforobject: object];*/
	
	[dbClient commit];
}

- (void) _addTemplate: (id) infoDict 
{
	
}

- (void) _threadedAddObject: (id) dict
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	id object, objectType, selectorString;
	NSException* exception;
	SEL selector;
	
	//Want to ensure that the main thread gets to return
	//and enter the event loop before we start.
	//Otherwise ProgressPanels etc. displayed by the main
	//thread will appear to hang (especially when the addition is fast).
	sleep(1);
	
	exception = nil;
	NS_DURING
	{
		object = [dict objectForKey: @"Object"];
		objectType = NSStringFromClass([object class]);
		selectorString = [NSString stringWithFormat: @"_add%@:", objectType];
		selector = NSSelectorFromString(selectorString);
		[self performSelector: selector withObject: dict];
	}
	NS_HANDLER
	{
		exception = localException;
	}
	NS_ENDHANDLER
	
	[self performSelectorOnMainThread: @selector(_additionThreadDidTerminate:)
			       withObject: exception
			    waitUntilDone: NO];
	[pool release];
	[NSThread exit];
}

@end

//Category to handle addition and retrieval of simulations
//and the associated trajectory data. In general these
//operations are much more complicated for simulations compared
//to the other objects we store in the database.
@implementation ULSQLDatabaseBackend (AdSimulationDataExtensions)


//FIXME: must add template code here
- (void) _addRequiredSimulationData: (id) object toSchema: (NSString*) schema 
{
	NSMutableData* data = [NSMutableData new];
	NSData* restartData, *systemData;
	NSKeyedArchiver* archiver;
	NSMutableDictionary* dict;
	NSString* type, *tableName, *path;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	
	[[object metadata] setObject: [dbClient database] forKey: @"Database"];
	
	//Archive the AdSimulationData object
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: object forKey: @"root"];
	[archiver finishEncoding];
	
	//get the system and restart data
	
	path = [[object dataStorage] storagePath];
	restartData  = [fileManager contentsAtPath: 
			[path stringByAppendingPathComponent: @"restart.ad"]];
	systemData  = [fileManager contentsAtPath: 
		       [path stringByAppendingPathComponent: @"system.ad"]];
	
	type = NSStringFromClass([object class]);
	dict = [self columnMapForClass: type];
	[dict setObject: schema
		 forKey: @"Schema"];
	[dict setObject: [dbClient quote: [object identification]] 
		 forKey: @"Identification"];
	[dict setObject: [dbClient quote: [object name]] 
		 forKey: @"Name"];
	[dict setObject: [dbClient quote: [object creator]] 
		 forKey: @"Creator"];
	[dict setObject: [NSDate dateWithNaturalLanguageString: [object created]] 
		 forKey: @"Created"];
	[dict setObject: data 
		 forKey: @"Data"];
	
	//add Simulation Specific	
	[dict setObject: systemData
		 forKey: @"SystemData"];
	[dict setObject: restartData
		 forKey: @"RestartData"];
	
	[dbClient execute: @"INSERT INTO \"{Schema}\".\"{Table}\" "
	 @"(\"{CodeCol}\", \"{NameCol}\", \"{CreatorCol}\", "
	 @"\"{CreatedCol}\", \"{DataCol}\", "
	 @"\"SystemData\", \"RestartData\" )"	
	 @"VALUES ( {Identification}, {Name}, {Creator}, {Created}, {Data}," 
	 @" {SystemData}, {RestartData})"
		     with: dict];
	
	[data release];
}

//adapted from postgres example 
- (Oid) _importTrajectoryDataAtPath: (NSString*) path usingConnection: (PGconn*) conn
{
	Oid lobjId;
	int lobj_fd, tmp;
	char* buf;
	NSData* data;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	data = [fileManager contentsAtPath: 
		[path stringByAppendingPathComponent: @"trajectory.ad"]];
	
     	//create large object
	lobjId = lo_creat(conn, INV_READ | INV_WRITE);
	if (lobjId == 0)
		NSWarnLog(@"Can't create large object\n");
	
	lobj_fd = lo_open(conn, lobjId, INV_WRITE);
	
	//write the data to the large object
	
	buf = (char*)[data bytes];
	tmp = lo_write(conn, lobj_fd, buf, (int)[data length]);
	
	NSLog(@"Wrote %d bytes of data", tmp);
	if (tmp < (int)[data length])
		NSWarnLog(@"Error while writing large object\n");
	
	lo_close(conn, lobj_fd);
	
	return lobjId;
}

- (PGconn*) _createLargeObjectConnection
{
	PGconn *conn;
	NSString* database, *host;
	NSArray* temp;
	
	temp = [[dbClient database] componentsSeparatedByString: @"@"];
	database = [temp objectAtIndex: 0];	
	host = [temp objectAtIndex: 1];	
	
	conn = PQsetdbLogin([host UTF8String],
			    NULL,
			    NULL,
			    NULL,
			    [database UTF8String],
			    [[dbClient user] UTF8String],
			    [[dbClient password] UTF8String]);
	
	switch(PQstatus(conn))
	{
		case CONNECTION_OK:
			NSLog(@"Connected for large objects transaction");
			break;
		case CONNECTION_BAD:
			NSLog(@"Something bad happend");
			break;
		default:
			NSLog(@"What?");
	}
	
	return conn;
}

//We add the trajectory data using postgres large objects facility
//However this means we have to directly use libpgsql
- (void) _addTrajectoryData: (id) object toSchema: (NSString*) schema
{
	PGconn *conn;
	NSString *path;
	Oid largeObjectId;
	NSMutableDictionary* dict;
	NSString* type, *tableName;
	
	path = [[object dataStorage] storagePath];
	conn = [self _createLargeObjectConnection];
	
	PQexec(conn, "begin");
	//FIXME: Check if there is any trajectory data to add
	largeObjectId = [self _importTrajectoryDataAtPath: path 
					  usingConnection: conn];
	PQexec(conn, "end");
	PQfinish(conn);
	
	//add the large object reference to the simulation
	
	type = NSStringFromClass([object class]);
	dict = [self columnMapForClass: type];
	[dict setObject: schema
		 forKey: @"Schema"];
	[dict setObject: [dbClient quote: [object identification]] 
		 forKey: @"Identification"];
	[dict setObject: [NSNumber numberWithInt: largeObjectId]
		 forKey: @"LargeObjectID"];
	
	[dbClient execute: @"UPDATE \"{Schema}\".\"{Table}\" "
	 @"SET \"TrajectoryData\" = {LargeObjectID} WHERE  \"{CodeCol}\" = {Identification}"
		     with: dict];
	
	NSDebugMLLog(@"ULSQLDatabaseBackend", @"Finished large objects transaction");
}

//add energy
- (void) _addEnergyData: (id) object toSchema: (NSString*) schema
{
	NSData* energyData;
	NSMutableDictionary* dict;
	NSString* type, *tableName, *path;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	type = NSStringFromClass([object class]);
	tableName = [tableForClass objectForKey: type];
	dict = [self columnMapForClass: type];
	path = [[object dataStorage] storagePath];
	energyData  = [fileManager contentsAtPath: 
		       [path stringByAppendingPathComponent: @"energy.ad"]];
	
	type = NSStringFromClass([object class]);
	dict = [self columnMapForClass: type];
	[dict setObject: schema
		 forKey: @"Schema"];
	[dict setObject: [dbClient quote: [object identification]] 
		 forKey: @"Identification"];
	[dict setObject:  energyData
		 forKey: @"Data"];
	
	//exectute the request	
	
	[dbClient execute: @"UPDATE \"{Schema}\".\"{Table}\" "
	 @"SET \"EnergyData\" = {Data} WHERE  \"{CodeCol}\" = {Identification}"
		     with: dict];
}

- (void) _addAdSimulationData: (id) infoDict;
{
	NSString* schema;
	id object;
	
	object = [infoDict objectForKey: @"Object"];
	schema = [infoDict objectForKey: @"Schema"];
	
	[dbClient begin];
	
	[self _addRequiredSimulationData: object
				toSchema: schema];
	[self _addTrajectoryData: object
			toSchema: schema];
	[self _addEnergyData: object
		    toSchema: schema];
	
	//add keywords plus refs
	
	[dbClient commit];
}

- (void) _removeTrajectoryForSimulationWithID: (NSString*) ident
				     inSchema: (NSString*) schema
{
	PGconn* conn;
	id result, oid;
	NSMutableDictionary* dict;
	NSString *tableName;
	
	if(schema == nil)
		schema = @"PublicAdunObjects";
	
	dict = [self columnMapForClass: @"AdSimulationData"];
	[dict setObject: schema 
		 forKey: @"Schema"];
	[dict setObject: [dbClient quote: ident] 
		 forKey: @"Identification"];
	
	result = [dbClient query: @"SELECT \"TrajectoryData\" "
		  @"FROM \"{Schema}\".\"{Table}\" "	
		  @"WHERE \"{CodeCol}\" = {Identification}"
			    with: dict];
	
	oid = [[result objectAtIndex: 0] 
	       objectForKey: @"TrajectoryData"]; 
	if(![oid isKindOfClass: [NSNull class]]) 
	{	
		conn = [self _createLargeObjectConnection];
		PQexec(conn, "begin");
		lo_unlink(conn, [oid intValue]);
		PQexec(conn, "end");
	}	
	
	NSDebugMLLog(@"ULSQLDatabaseBackend", @"Removed trajectory data.");
	PQfinish(conn);
}

- (void) _exportLargeObject: (Oid) largeObjectID toPath: (NSString*) path
{
	int loFileDescriptor;
	int nbytes;
	char buf[1048576]; //A Megabyte
	PGconn *conn;
	NSMutableData *data;
	
	conn = [self _createLargeObjectConnection];
	PQexec(conn, "begin");
	loFileDescriptor = lo_open(conn, largeObjectID, INV_READ | INV_WRITE );
	if (loFileDescriptor < 0)
	{
		NSWarnLog(@"Can't open large object %d\n",
			  largeObjectID);
		return;	
	}
	
	data = [NSMutableData dataWithCapacity: 1048576];
	NSLog(@"Begin download");
	while ((nbytes = lo_read(conn, loFileDescriptor, buf, 1048576)) > 0)
		[data appendBytes: buf length: nbytes];
	NSLog(@"End download");
	
	[data writeToFile: path atomically: NO];
	lo_close(conn, loFileDescriptor);
	PQexec(conn, "end");
	PQfinish(conn);
	
	return;
}

- (void) _createDataStorageForSimulation: (id) object inSchema: (NSString*) schema
{
	int largeObjectID;
	NSString* dbCache;
	NSString* type, *tableName, *path, *className;
	NSMutableDictionary* dict;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	id dataStorage, results;
	NSData *energyData, *restartData, *systemData;
	
	//we need access to a temporary directory where we
	//can write the data.
	
	/*	dbCache = [[ULIOManager appIOManager] 
	 remoteDatabaseCacheDirectory];*/
	
	//FIXME: for testing
	
	dbCache = [[ULIOManager appIOManager]
		   temporaryDirectoryWithPrefix: @"SQL"];
	
	NSLog(@"DB cacbe is %@", dbCache);		
	
	path = [dbCache stringByAppendingPathComponent: 
		[NSString stringWithFormat: @"%@_Data",
		 [object identification]]];
	dataStorage = [[AdFileSystemSimulationStorage alloc]
		       initStorageForSimulationAtPath: path];
	[dataStorage autorelease];
	[dataStorage setIsTemporary: YES];
	
	//FIXME: For the moment we will download all the simulation 
	//data directly into the cache. However this will be very time
	//consuming in general due to the trajectory size. To overcome this a new class
	//ULSQLSimulationDataStorage will be created. This class will
	//allow on demand retrieval of trajectory information through the large object facility.
	//However to enable this AdSimulationData will have to be adapted to request
	//configuration frames from its dataStorage instead of unarchiving them
	//itself and hence AdFileSystemSimulationStorage should be updated aswell
	
	className = NSStringFromClass([object class]);
	dict = [self columnMapForClass: className];
	[dict setObject: schema 
		 forKey: @"Schema"];
	[dict setObject: [dbClient quote: [object identification]]
		 forKey: @"Identification"];
	
	NS_DURING
	{
		results = [dbClient query: @"SELECT \"EnergyData\", \"SystemData\", "
			   @"\"RestartData\", \"TrajectoryData\" " 
			   @"FROM  \"{Schema}\".\"{Table}\" "
			   @"WHERE \"{CodeCol}\" = {Identification} "
				     with: dict];
	}			
	NS_HANDLER
	{
		NSWarnLog(@"Database exception %@", localException);
		
		if([[localException name] isEqual: SQLConnectionException])
		{
			//broadcast a @"ULDatabaseBackendConnectionDidDieNotification"
			//This lets the DatabaseInterface take some action
			[[NSNotificationCenter defaultCenter]
			 postNotificationName: @"ULDatabaseBackendConnectionDidDieNotification"
			 object: self];
		}
	}
	NS_ENDHANDLER
	
	//write the data
	//FIXME: Should we write the data at all?
	//Maybe only if a "CacheData" default is set??
	
	energyData = [[results objectAtIndex: 0] 
		      objectForKey: @"EnergyData"];
	systemData = [[results objectAtIndex: 0] 
		      objectForKey: @"SystemData"];
	restartData = [[results objectAtIndex: 0] 
		       objectForKey: @"RestartData"];	
	largeObjectID = [[[results objectAtIndex: 0] 
			  objectForKey: @"TrajectoryData"] intValue];
	
	[energyData writeToFile: [path stringByAppendingPathComponent: @"energy.ad"]
		     atomically:NO];
	[systemData writeToFile: [path stringByAppendingPathComponent: @"restart.ad"]
		     atomically:NO];
	[restartData writeToFile: [path stringByAppendingPathComponent: @"system.ad"]
		      atomically:NO];
	
	//write the trajectory data
	[self _exportLargeObject: largeObjectID	
			  toPath: [path stringByAppendingPathComponent: @"trajectory.ad"]]; 
	[object setDataStorage: dataStorage];
}

@end
