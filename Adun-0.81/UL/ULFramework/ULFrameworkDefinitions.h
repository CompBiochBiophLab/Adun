/* 
   Project: ULFramework

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
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _ULFRAMEWORK_DEFINITIONS_
#define _ULFRAMEWORK_DEFINITIONS_

//Extra includes neccessary to use 
//gnustep base additions on OSX 
#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

/*
 * Contains constant & type defintions for ULFramework
 */
 
/**
\defgroup ulConstants Constants
\ingroup ulFramework
Constants in ULFramework
**/
 
/**
\defgroup ulDataTypes DataTypes
\ingroup ulFramework
Structures & Enums defined by ULFramework
**/ 
 
/**
\ingroup ulConstants
The error domain for ULFramework 
*/
#define ULFrameworkErrorDomain @"ULFramework.ErrorDomain"

/**
\ingroup ulDataTypes
Error codes for the ULFrameworkErrorDomain.
*/
typedef enum 
{
	//Database error codes
	ULDatabaseConnectionNotAvailableError,	//!< Backend unable to connect to a database
	ULDatabaseConnectionNotAllowedError,	//!< Database refused backend connection
	ULDatabaseCorruptedError,		//!< Database is corrupted and unusable.
	ULSchemaWriteNoPermissionError,		//!< Backend cannot write to a schema due to permissions
	ULSchemaReadNoPermissionError,		//!< Backend cannot read a schema due to permissions
	//Other codes
	ULTemplateValidationError,		//!< Template failed validation
	ULServerConnectionError,		//!< Could not connect to an AdunServer instance.
	ULFrameworkUnknownError			//!< Generic framework error code
}
ULFrameworkErrorCodes;

/**
\ingroup ulDataTypes
The connection states for a backend client
*/
typedef enum
{
	ULDatabaseClientConnected,	//!< The backend is connected to the database
	ULDatabaseClientNotConnected	//!< The backend isnt connected to the database
}
ULDatabaseClientConnectionState;

/**
\ingroup ulDataTypes
The various read/write modes a client can have for a certain schema.
*/
typedef enum
{
	ULSchemaUnknownMode,
	ULSchemaNoPermissionsMode,
	ULSchemaReadMode,
	ULSchemaWriteMode,
	ULSchemaUpdateMode
}
ULSchemaMode;

/**
\ingroup ulDataTypes
The state of the database
*/
typedef enum
{
	ULDatabaseNormalState,
	ULDatabaseCorruptedState,
	ULDatabaseUnknownState,
}
ULDatabaseState;

/**
 \ingroup ulDataTypes
 Defines the different data types ULExportController knows how to 
 export Adun data as.
 */
typedef enum
{
	ULBinaryArchiveExportType  = 0,
	ULPDBExportType = 1, 
	ULCSVExportType = 2,
	ULAdunCoreTemplateExportType = 3,
}
ULExportType;

//FIXME: Need to create a group here and link these docs back to the ULFileSystemDatabaseBackend.
//Actually should create a backend protocol and detail them there.

/**
The name of a database. For a file system database this is the complete path to the database.
*/
extern NSString* ULDatabaseName;
/**
The name associated with the backend/client. Used to identify one client from another. 
*/
extern NSString* ULDatabaseClientName;
/**
The class for a given database backend object
*/
extern NSString* ULDatabaseBackendClass;
/**
The name of the user accessing the database.
*/
extern NSString* ULDatabaseUserName;
/**
The name of a database schema
*/
extern NSString* ULSchemaName;
/**
Accesses the mode of a database schema.
*/
extern NSString* ULSchemaModeValue;
/**
The ownser of a database schema.
*/
extern NSString* ULSchemaOwner;

#endif
