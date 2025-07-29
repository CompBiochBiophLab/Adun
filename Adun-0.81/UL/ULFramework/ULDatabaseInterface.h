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

#ifndef _ULDATABASEINTERFACE_H_
#define _ULDATABASEINTERFACE_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataSet.h>
#include "ULFramework/ULFrameworkDefinitions.h"
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULFileSystemDatabaseBackend.h"

/**
\ingroup classes
ULDatabaseInterface is a singleton which provides a unified interface to a
number of database backends.
The individual backends add, remove and retrieve data from a given database as a given user.
The object which handles the connection to the database is called a "client". 
Hence each backend object has an associated "client" instance which it uses to interact with the database.
The client instance is identified by a name which also serves to identify the corresponding backend.
The client name must be a unique string (in the context of the set of 
backends handled by the ULDatabaseInterface instance). 

A client can also be thought of as a specific instance of a database. 
Two clients can be connected to the same database but they may not be able to perform the
same actions on it. Hence we could write methods like "addObject:toDatabase:usingClient"
howver since by specifying a client you already determine a database this is shortend
to "addObject:toClient:".

\section Terminology

- client - The object which connects to the database. Different database types require different clients.
- backend - Object which manages a client, using it to add and remove data from a database. Different backed classes
correspond to different client types.
- clientName - A string associated with a client. Since a client is uniquely associated with a backend this name also
serves to identify a specific backend.
- databaseName - The name of the database
- databaseIdentifer - A string which uniquely identifies a database e.g. its name and where it is. The exact
form of the identifier depends on the backend. "database" is sometimes used interchangably with "databaseIdentifer".

\section exceptions Exceptions & Errors

Exceptions are raised in the following circumstances

- Invalid client specified
- Invalid schema specified
- Invalid class specified
- Invalid object id specified.

These are consider avoidable programmatic errors since the correct information is readily available.

Errors result when attempting database operations in the following situations

- Not connected to the database
- Database corrupted
- User does not have correct permissions.

Users can have either read/write/update permissions to the schema. Without read permissions
the following methods will return an error.

- unarchiveObjectWithID:ofClass:fromSchema:ofClient:error:()
- metadataForObjectWithID:ofClass:inSchema:ofClient:error:()
- inputReferencesForObjectWithID:ofClass:inSchema:ofClient:error:()
- outputReferencesForObjectWithID:ofClass:inSchema:ofClient:error:()

Without write permission these methods return an error

- addObject:toSchema:ofClient:error:()
- removeObjectOfClass:withID:fromSchema:ofClient:error:()
- removeObjectsOfClass:withIDs:fromSchema:ofClient:error:()
- updateMetadataForObject:inSchema:ofClient:error:()
- updateOutputReferencesForObject:error:()
- removeOutputReferencesToObjectWithID:ofClass:inSchema:ofClient:error:()

You can check the permissions of a schema using modeForSchema:ofClient:

\section Notifications

ULDatabaseInterface sends notifications in a number of situtations. Notifications are sent
on add/remove/update operations so an object which monitors the database's state
can react to them e.g. the database browser in the interface.

- ULDatabaseInterfaceDidModifyContentsNotification - Sent on a successful add/remove/update operation.
- ULDatabaseInterfaceConnectionDidDieNotification - Sent on detection of a disconnection event.
- ULDatabaseInterfaceDidReconnectNotification - Sent on successful reconnection to a previously disconneted 
- ULDatabaseInterfaceDidAddBackendNotification - Sent when a backend is added to the interface
- ULDatabaseInterfaceDidRemoveBackendNotification - Sent when a backend is removed from the interface
database.

\todo Add handling of corruption notifications
*/

@interface ULDatabaseInterface : NSObject
{
	NSString* configurationFile;
	NSMutableArray* clientConfigurations;
	NSMutableDictionary* backendErrors;
	NSMutableDictionary* backends;	
	NSMutableArray* availableClients;
	ULFileSystemDatabaseBackend* fileSystemBackend;
	Class ULSQLDatabaseBackend;
	id backend;
}
/**
Returns the applications databaseInterface object
*/
+ (id) databaseInterface;
/**
Returns an NSDictionary containing error objects describing 
problems with the backends. If there are no problems the dictionary
is empty. Otherwise the keys are client names and the values 
error objects describing the problems.
*/
- (NSDictionary*) backendErrors;
/**
Adds the backend \e object to the backends handled by the receiver.
The clientName associated with the backend (as returned by 
e.g. ULFileSystemDatabaseBackend::clientName()) must not be in use by another
backend allready handled by the reciever i.e. not in the array returned by availableClients().
If it is this method returns NO. Otherwise the backend is added and this method returns YES.
The configuration of the backend is saved by the receiver and when ULDatabaseInterface
is next initialised the backend is automatically recreated and added to the availableClients.
Posts an ULDatabaseInterfaceDidAddBackendNotification on success.
*/
- (BOOL) addBackend: (id) object;
/**
Removes the backend associated with \e clientName. However
\e clientName cannot be the name associated with the primary file system
backend. If it is an NSInvalidArgumentException is raised. If no
backend is associated with \e clientName this method does nothing.
Posts an ULDatabaseInterfaceDidRemoveBackendNotification on success.
*/
- (void) removeBackendForClient: (NSString*) clientName;
/**
Returns the object which uses the connection \e clientName
*/
- (id) backendForClient: (NSString*) clientName;
/**
Returns the connection state of \e clientName
*/
- (ULDatabaseClientConnectionState) connectionStateForClient: (NSString*) clientName;
/**
Returns True if \e object is in the primary file system
database.
\note Will be deprecated.
*/
- (BOOL) objectInFileSystemDatabase: (id) object;
/**
Adds \e object to \e schema of the database identified
by \e clientname.
*/
- (BOOL) addObject: (id) object 
		toSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error;
/**
Adds \object to the primary file system database.
*/
- (BOOL) addObjectToFileSystemDatabase: (id) object;
/**
Removes an object of class \e className, which is uniquely identified by \e ident
from \e schema of \e clientName.
*/
- (BOOL) removeObjectOfClass: (NSString*) className 
		withID: (NSString*) ident 
		fromSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error;
/**
Calls removeObjectOfClass:withID:fromSchema:ofClient: for each
id in \e idents.
*/
- (BOOL) removeObjectsOfClass: (NSString*) className 
		withIDs: (NSArray*) idents
		fromSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error;
/**
Unarchives the object of class \e className, whose identification is
\e ident from the given \e schema of \e clientName.
Returns nil if the object doenst exist.
*/
- (id) unarchiveObjectWithID: (NSString*) ident 
	ofClass: (NSString*) className 
	fromSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error;
/**
Returns an array containing information on the objects of
class \e className that are contained in \e schema of \e clientName.
The information for each object is the dictionary returned by
metadataForObjectWithID:ofClass:inSchema:ofClient:error().
If \e clientName is not connected to the database or does not
have permission to read \e schema this method returns an empty array.
*/
- (NSArray*) metadataForObjectsOfClass: (NSString*) className 
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName;
/**
Returns copy of the dictionary returned by the object identified by \e idents AdModelObject::allData()
method with an additional key "Class".
*/
- (id) metadataForObjectWithID: (NSString*) ident 
	ofClass: (NSString*) className 
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error;
/**
 Returns a copy of the metadata dictionary of the object at index \e objectIndex
 of the array that would be returned by metadataForObjectsOfClass:inSchema:ofClient:
 for the specified \e className, \e schema and \e clientName.
 This dictionary has an additional key ULDatabaseClientName.
 */
- (NSDictionary*) metadataForObjectAtIndex: (unsigned int) objectIndex 
	ofClass: (NSString*) className 
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName;
/**
The schema and clientName args are redundant here since they
are available through \e object
*/
- (BOOL) updateMetadataForObject: (id) object 
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error;
/**
Description forthcomming
*/
- (BOOL) updateOutputReferencesForObject: (id) object		
		error: (NSError**) error;
/**
Description forthcomming
*/
- (id) outputReferencesForObjectWithID: (NSString*) ident 
	ofClass: (NSString*) className 
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error;
/**
Description forthcomming
*/
- (id) inputReferencesForObjectWithID: (NSString*) ident 
	ofClass: (NSString*) className 
	inSchema: (NSString*) schema
	ofClient: (NSString*) clientName
	error: (NSError**) error;
/**
Removes all output references to objects with id \e ident.
\e className , \e schema and \e client are required in order to retrieve 
the objects input references from one of its instances.
Note that a reference is global - i.e. all output references containing this
id are removed if possible. Objects in an unwritable schema are not updated.
\note Currently errors are only reported if the input references cannot be
retrieved. Other errors are ignored.
*/
- (BOOL) removeOutputReferencesToObjectWithID: ident
		ofClass: (NSString*) className
		inSchema: (NSString*) schema
		ofClient: (NSString*) clientName
		error: (NSError**) error;
/**
Description forthcomming
*/
- (ULSchemaMode) modeForSchema: (NSString*) schema ofClient: (NSString*) clientName;		
/**
Returns an array of dictionaries. Each dictionary contains information
on a specific type of data contained in \e schema. Each dictionary has two
keys ULObjectDisplayName & ULObjectClassName. The value of the latter is
a AdModelObject descendant class name. The former is the display name associated
with this class.
*/
- (NSArray*) contentTypeInformationForSchema: (NSString*) schema
		ofClient: (NSString*) clientName;
/**
Returns an array containing the names of all the available clients.
*/
- (NSArray*) availableClients;
/**
Returns an array containing the names of all the schemas contained
in the database associated with \e clientName.
*/
- (NSArray*) schemaInformationForClient: (NSString*) clientName;
/**
Returns an array containing the names of the clients that access the database identified by
\e string. Databases are identified by comparing \e string to the return value of 
ULFileSystemDatabaseBackend::databaseIdentifer(). If no clients are found
that access \e string this method returns an empty array.
*/
- (NSArray*) clientsForDatabase: (NSString*) string;
/**
Returns the backend managing the applications primary file system
database.
*/
- (ULFileSystemDatabaseBackend*) primaryFileSystemBackend;
@end

/**
Category containing preliminary database searching methods.
Will be moved to seperate object
*/
@interface ULDatabaseInterface (ULFinder)
/**
Searches for objects with idenfication \e ident and class \e className
in all the schemas of all the currently connected clients.
Returns an array containing information on the objects found
The information for each object is the dictionary returned by
metadataForObjectWithID:ofClass:inSchema:ofClient:error().
*/
- (NSArray*) findObjectsWithID: (NSString*) ident ofClass: (NSString*) className;
@end
#endif 

