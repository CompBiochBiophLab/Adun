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

#ifndef _ULFILESYSTEM_DATABASEBACKEND_H_
#define _ULFILESYSTEM_DATABASEBACKEND_H_

#include <sys/types.h>
#include <sys/stat.h>
#include <Foundation/Foundation.h>
#include <AdunKernel/AdunFileSystemSimulationStorage.h>
#include "ULFramework/ULFrameworkDefinitions.h"
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULDatabaseIndex.h"
#include "ULFramework/ULDatabaseSimulationIndex.h"

/**

A ULDatabaseBackendDidModifyContentsNotification is sent on each
successful write operation.

\ingroup classes
\todo implement reindexAll
\todo connection/disconnection checking
*/

@interface ULFileSystemDatabaseBackend : NSObject
{
	ULDatabaseState databaseState;
	ULDatabaseClientConnectionState connectionState;
	ULSchemaMode schemaMode;
	NSError* internalError;
	NSMutableDictionary* databaseIndexes;
	NSMutableDictionary* indexNames;
	NSMutableDictionary* indexDirs;
	NSString* databaseDir;
	NSString* systemDir;
	NSString* optionsDir;
	NSString* dataSetDir;
	NSString* simulationDir;
	NSTimer* autoUpdateTimer;
	NSString* clientName;
	NSString* userName;
	NSMutableArray* contentInformation;
}

/**
As initWithDatabaseName:clientName:error:() passing \e path @ localhost
for \e name.
*/
- (id) initWithDatabaseName: (NSString*) path error: (NSError**) error;
/**
As initWithDatabaseName:clientName:host:user:password:error:() passing
nil for host, user, password & error.
*/
- (id) initWithDatabaseName: (NSString*)  path
	clientName: (NSString*) name 
	error: (NSError**) error;
/**
Initialises a new ULFileSystemDatabaseBackend instance
for accessing the database at \e path. 
\param path The full path to a Adun file system database directory.
If path is nil it defaults to the application default database.
If path cannot be accessed \e error contains an NSError object detailing the problem. 
\param name An NSString that will be associated with the returned object
\e name should be unique. If \e name is nil it defaults to <em> path @ localhost </em>.
\param host An NSHost object detailing the host the database is located on - it defaults to localhost.
\param user The user to connect to the database as
\param password The password to use to connect to the database

\note At this point \e host, \e user and \e password are ignored. They may be used
later to allow ftp access to a file system DB.
\note If any subdirectory of the database is missing it is created if possible.
If it cant be created an error is set.
\note The possible errors are
- ULDatabaseConnectionNotAvailableError 
	- Cant find any database at path
- ULDatabaseCorruptedError 
	- One of the databases indexes has been deleted
	- A database index cannot be read even though the database directory has read permissions
	- The database directory is write only
*/
- (id) initWithDatabaseName: (NSString*) path 
	clientName: (NSString*) name
	host: (NSHost*) host
	user: (NSString*) user
	password: (NSString*) password
	error: (NSError**) error;
/**
Returns the database properties.
The possible dictionary keys are 

- ULDatabaseBackendClass - The class of the reciever 
- ULDatabaseName	 - The full path to the database
- ULDatabaseClientName   - The name associated with the connection to the db.
- ULDatabaseIdenfifier   - Equivalent to ULDatabaseName in this case. 
- ULDatabaseHost
- ULDatabaseUser
- ULDatabasePassword

\note The first four are always returned
*/
- (NSDictionary*) properties;
/**
Returns a string the uniquely specifies the database.
The format of the string depends on the backend in question.
In this case its simply the databaseName();
*/
- (NSString*) databaseIdentifer;
/**
Returns the name of the database
*/
- (NSString*) databaseName;
/**
If there is something wrong with the backend this
method returns an NSError object detailing the problem.
*/
- (NSError*) databaseError;
/**
Returns the connection state of the client. With some backends
you can try to reconnect at a later stage - this feature is not
implemented here however.
*/
- (ULDatabaseClientConnectionState) connectionState;
/**
Returns the mode for \e schema - see ULSchemaMode for possible values
*/
- (ULSchemaMode) modeForSchema: (NSString*) schema;
/**
Returns YES if the object is in the database, No otherwise.
Returns NO and sets \e error if the database is not accessible or corrupted.
If \e object is not one of the classes that can be managed by the database
an NSInvalidArgumentException is raised.
*/
- (BOOL) objectInDatabase: (id) object error: (NSError**) error;
/**
Adds the object to the database. Returns YES on success, NO otherwise.
\e error is set if the database is not accessible, is corrupted or
the client does not have write permissions to \e schema.
Raises an NSInvalidArgumentException if \e schema is not a valid
database schema or \e object is not one of the classes that can
be added to the database.
These exceptions will only be raised if the client is connected and the
database is not corrupted.
*/
- (BOOL) addObject: (id) object
	 toSchema: (NSString*) schema
	 error: (NSError**) error;
/**
Removes \e object from the database managed by the receiver.
If successful returns YES otherwise returns NO. 
\e error is set if the database is not accessible, is corrupted or
the client does not have write permissions to \e schema.
Raises an NSInvalidArgumentException if no object with \e identification
is in the database, if \e schema is not a valid
database schema or \e className is not a valid database class.
These exceptions will only be raised if the client is connected and the
database is not corrupted.
*/
- (BOOL) removeObjectOfClass: (id) className 
		withID: (NSString*) ident
		fromSchema: (NSString*) schema
		error: (NSError**) error;
/**
Removes the objects with the identifications contained in the array \e idents from the
database managed by the receiver.
If any object cannot be removed this method exits immediately
returns NO and error contains a description of the problem that caused the removal to halt. 
The objects corresponding to identifications after the one that caused the
error are not removed. 
All the objects in \e idents must be contained in the database - If not an NSInvalidArgumentException
is raised. In this case nothing is removed.
*/
- (BOOL) removeObjectsOfClass: (id) className 
		withIDs: (NSArray*) idents
		fromSchema: (NSString*) schema
		error: (NSError**) error;
/**
Unarchives and returns the object identified by \e id from the database 
accessed by the receiver.
Returns nil and sets \e error if the database is not accessible or is corrupted.
Raises an NSInvalidArgumentException if no object with identification \e id 
is in the index, if \e schema is not a valid
database schema or \e className is not a valid database class.
*/
- (id) unarchiveObjectWithID: (NSString*) ident 
	ofClass: (id) className
	fromSchema: (NSString*) schema
	error: (NSError**) error;
/**
Returns an array containing one dictionary for each object of class \e className in
the database accessed by the receiver. The dictionary is equivalent
to the one returned by AdModelObject::allMetadata() for that object.
\e className must be one of the four classes that can be managed by the database
if not an NSInvalidArgumentException is raised.
Also raises an NSInvalidArgumentException if \e schema is invalid.
*/
- (NSArray*) metadataForObjectsOfClass: (id) className
		inSchema: (NSString*) schema;
/**
Returns information on the contents of \e schema. This is an array of dictionaries
one for each of the four classes that can be managed be \e schema. The dictionary
keys are

- ULObjectClassName - The name of the class
- ULObjectDisplayName - A user readable version of the class name
- ULDatabaseClientName - The name of the database client used to acces the schema.

Returns nil if the database if not accessible or corrupted.
Raises an NSInvalidArgumentException if \e schema is not a valid
database schema. These exceptions will only be raised if the database
is connected and not corrupted.
\note The ULDatabaseClientName key is added in order to work around
a bug in NSOutlineView - See the source code for more.
*/
- (NSArray*) contentTypeInformationForSchema: (NSString*) schema;
/**
Returns the dictionary returned by AdModelObject::allMetadata()
for the object with id \e ident. 
This includes the volatile metdata key ULDatabaseClientName added by the client.

Returns nil if no object with id \e ident is in the database managed by the receiver.
\e error is set if the database is not accessible or is corrupted.
Raises an NSInvalidArgumentException if \e className is not one of the
classes that can be managed by the receiver or if \e schema is invalid.
*/
- (NSDictionary*) metadataForObjectWithID: (NSString*) ident 
			ofClass: (id) className
			inSchema: (NSString*) schema
			error: (NSError**) error;
/**
 Returns the metadata dictionary at \e objectIndex of the array retrned by metadataForObjectsOfClass:inSchema:().
 This includes the volatile metdata key ULDatabaseClientName added by the client.
 
 Raises an NSInvalidArgumentException if \e className is not one of the
 classes that can be managed by the receiver or if \e schema is invalid.
 Raises an NSRangeException if \e objectIndex is greater than or equal to 
 the number of metadata dictionaries available for objects of \e className.
 */						
- (NSDictionary*) metadataForObjectAtIndex: (unsigned int) objectIndex 
				   ofClass: (id) className
				  inSchema: (NSString*) schema;
/**
Returns the dictionary returned by AdModelObject::outputReferences()
for the object with id \e ident. Returns nil if no object with
id \e ident is in the database managed by the receiver.
\e error is set if the database is not accessible or is corrupted.
Raises an NSInvalidArgumentException if \e className is not one of the
classes that can be managed by the receiver or if \e schema is invalid.
*/
- (NSArray*) outputReferencesForObjectWithID: (NSString*) ident
		ofClass: (id) className 
		inSchema: (NSString*) schema
		error: (NSError**) error;
/**
Returns the dictionary returned by AdModelObject::inputReferences()
for the object with id \e ident. Returns nil if no object with
id \e ident is in the database managed by the receiver.
\e error is set if the database is not accessible or is corrupted.
Raises an NSInvalidArgumentException if \e className is not one of the
classes that can be managed by the receiver or if \e schema is invalid.
*/
- (NSArray*) inputReferencesForObjectWithID: (NSString*) ident 
		ofClass: (id) className
		inSchema: (NSString*) schema
		error: (NSError**) error;
/**
Updates the metadata stored in the reciever for \e object. 
Raises an NSInvalidArgumentException if \e object is not in the database 
, if \e schema is not a vaild database schema or if \e className 
is not one of the classes that can be managed by the receiver.
Returns YES if the update is successful NO otherwise. On returning
NO \e error contains an NSError object explaining the problem.
*/
- (BOOL) updateMetadataForObject: (id) object
		inSchema: (NSString*) schema
		error: (NSError**) error;
/**
Updates the output references stored in the reciever for \e object. 
Raises an NSInvalidArgumentException if \e object is not in the database 
, if \e schema is not a vaild database schema or if \e className 
is not one of the classes that can be managed by the receiver.
Returns YES if the update is successful NO otherwise. On returning
NO \e error contains an NSError object explaining the problem.
*/
- (BOOL) updateOutputReferencesForObject: (id) object
		inSchema: (NSString*) schema
		error: (NSError**) error;
/**
Description forthcomming
*/
- (BOOL) removeOutputReferenceToObjectWithID: (NSString*) identOne 
		fromObjectWithID: (NSString*) identTwo
		ofClass: (id) className 
		inSchema: (NSString*) schema
		error: (NSError**) error;
/**
Description forthcomming
*/
- (NSString*) clientName;
/**
Returns an array containing information on the schemas in the database.
Each element of the array is a dictionary correpsonding to a schema.
The dictionary contains the following keys -
- ULSchemaName
- ULSchemaModeValue
- ULSchemaOwner
- ULDatabaseUserName
- ULDatabaseClientName

Returns nil if the client is not connected to the database, the database
is corrupted. Only schema which the owner has permissions to read are returned.
\todo Currently assumes the current user is the schemas owner which is not valid.
*/
- (NSArray*) schemaInformation;
/**
Description forthcomming
*/
- (NSString*) simulationDir;
/**
Description forthcomming
*/
- (NSString*) templateDir;
/**
Description forthcomming
*/
- (NSString*) systemDir;
/**
Description forthcomming
*/
- (NSString*) dataSetDir;
/**
Not sure if this is still needed
*/
- (void) reindexAll;
/**
Description forthcomming
*/
- (void) autoUpdateIndexes: (id) info;
/**
Description forthcomming
*/
- (void) updateIndexes;
/**
Deprecated
*/
- (void) saveIndexes;
/**
Deprecated
*/
- (void) saveDatabase;
/**
Deprecated
*/
- (void) autosaveIndexes: (id) info;

@end

#endif 

