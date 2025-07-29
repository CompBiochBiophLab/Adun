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

#ifndef _ULSQLDATABASEBACKEND_H_
#define _ULSQLDATABASEBACKEND_H_

#include <Foundation/Foundation.h>
#include <SQLClient/SQLClient.h>
#include <AdunKernel/AdunKernel.h>
#include <AdunKernel/AdunDataSet.h>
#include <AdunKernel/AdunSimulationData.h>
#include <ULFramework/ULIOManager.h>
#include <libpq-fe.h>
#include <libpq/libpq-fs.h>

/**
Represents a connection to a sql database as a given user. This object provides
methods for addition, retrieval, and querying of the data in the various schemas in the database.
However the ability to perform operations depends on the privileges the given user
has on those schemas. 
On any connection failure a ULDatabaseBackendConnectionDidDieNotification is posted. 
Depending on the method connection failures may also result in a ULDatabaseConnectionException 
being raised after the nofication has been sent.
*/

@interface ULSQLDatabaseBackend: NSObject
{
	NSString* clientName;
	NSArray* genericColumns;
	NSDictionary* tableForClass;
	NSMutableDictionary* columnNames;
	NSMutableArray* availableTypes;
	NSMutableArray* indexArray;
	SQLClient* dbClient;
}
/**
Initialises the client object with name \e name which represents a connection
to the database \databaseName running on serverType
\e type on host \e host as user \e databaseUser. The users password is given by \e password.
\param databaseName The name of the database. If nil defaults to Adun.
\param databaseType he type of database server the database resides on. 
Defaults to postgresql.
\param databaseUser The user to connect as. If nil defaults to Adun.
\param password The password for the given user. If nil none password is sent.
This method raises an NSInternalInconsistencyException if no connection can be made
\param host NSHost object for the host the server containing the database is running on.
\todo Describe infoDict of Exception
*/
- (id) initWithClientName: (NSString*) name
	database: (NSString*) databaseName 
	serverType: (NSString*) serverType 
	user: (NSString*) databaseUser
	password: (NSString*) password
	host: (NSHost*) host;
/**
Closes the connection for \e clientName. 
If \clientName does not exist this method does nothing.
*/
- (void) disconnectClient;
/**
Adds \e object to \e schema. The addition operation is performed in a seperate thread.
If the operation was succesful a ULDatabaseBackendDidAddObjectNotification is posted
The object is the backend and there is no user info dictionary.
Otherwise a ULDatabaseBackendAdditionFailedNotification is posted. In this case the object
is also the backend but it contains a userInfo dictionary with one key - ULDatabaseBackendException
whose value is the exception object related to the failure.
*/
- (void) addObject: (id) object
	 toSchema: (NSString*) schema;
/**
Retrieves the object identified by the \e ident and \e schema arguments from
the client. On success the object is returned. On a connection failure
a ULDatabaseConnectionException is raised. 
Any other failure to retrive the object causes a ULGenericDatabaseException to be raised.
*/
- (id) unarchiveObjectWithID: (NSString*) ident 
	ofClass: (id) className
	fromSchema: (NSString*) schema;
/**
Removes the object identified by the \e ident and \e schema arguments from
the client. On a connection failure a ULDatabaseConnectionException is raised.
Any other failure to remove the object causes a ULGenericDatabaseException to be raised.
*/
- (void) removeObjectOfClass: (id) className 
		withID: (NSString*) ident
		fromSchema: (NSString*) schema;
/**
Returns a list of the available objects of \e className in \e schema  of the client. 
If no information is available (for whatever reason) nil is returned.
*/
- (NSArray*) availableObjectsOfClass: (id) className
		inSchema: (NSString*) schema;
/**
Returns an array of dictionaries. Each dictionary supplies information
on the contents i.e. available data, in \e schema. The key:value pairs are

- ULObjectClassName - The name of the Adun class associated with the content
- ULObjectTableName - The name of the table this data is stored in.
- ULObjectDisplayName - User friendly translation of the class name.
- ULDatabaseName - The database this content information comes from.
- ULSchemaName - The name of the schema.

*/
- (NSArray*) contentTypeInformationForSchema: (NSString*) schema;
/**Returns an array of dictionaries, one for each Adun schema in the
database. Each dictionary contains the following key:value pairs

- ULSchemaName - The name of the schema
- ULDatabaseClientName - The name used to identify this object
- ULDatabaseUserName - The name of the user associated with this object.
- ULSchemaPrivileges - An array of the privileges the user has on the schema
- ULSchemaOwner - Bool value indicating wheather this user owns the schema or not.

This information can be used to determine the outcome of
other methods called on this object instead of calling them and handling
exceptions/notifications if the operation cannot be performed.
*/
- (NSArray*) schemaInformation;
- (NSArray*) inputReferencesForObjectWithID: (NSString*) ident 
			ofClass: (id) className
			inSchema: (NSString*) schema;
- (void) saveDatabase;
- (NSMutableDictionary*) columnMapForClass: (NSString*) className;
@end

/**
 Contains methods for adding a model object, except AdSimulationData, to a database.
 Only one method, _threadedAddObject: is used by methods outside this category.
 All others are internal.
 */
@interface ULSQLDatabaseBackend (DataAddition)
- (void) _threadedAddObject: (id) dict;
@end

/**
Contains methods for handling simulation data stoped in the database.
*/
@interface ULSQLDatabaseBackend (AdSimulationDataExtensions)
- (void) _addAdSimulationData: (NSDictionary*) dict;
- (void) _removeTrajectoryForSimulationWithID: (NSString*) ident
				     inSchema: (NSString*) schema;
- (void) _createDataStorageForSimulation: (id) object inSchema: (NSString*) schema;
@end

#endif // _SQLBACKEND_H_

