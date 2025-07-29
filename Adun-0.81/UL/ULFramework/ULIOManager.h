/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 15:46:27 +0200 by michael johnston

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

#ifndef _ULIOMANAGER_H_
#define _ULIOMANAGER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunKernel.h>
#include <ULFramework/ULDatabaseIndex.h>

/**
Singleton Class for handling input and output for ULFramework
\ingroup classes
*/

@interface ULIOManager : NSObject
{
	NSFileManager* fileManager; 	//!< The NSFileManager instance for the process
	NSString* currentDir;		//!< Current Directory
	NSString* userHome;		//!< Current users home directory
	NSString* adunPath;		//!< Path to the .adun directory 
	NSString* kernelDir;		//!< Path to the kernel source directory
	NSString* applicationDir;	//!< Path to the user adun directory
	NSString* userPluginsDir;	//!< Path to the users plugin directory
	NSString* databaseDir;		//!< Path to the database directory
	NSString* controllerOutputDir; 	//!< Path to where controllers can write output
	NSString* pluginOutputDir;	//!< Default location where plugins can write output
	NSString* downloadDir;		//!< Where download files will be stored by default
	NSProcessInfo* processInfo;	//!< Information on the current process environment
}

/**
Returns the ULIOManager instance for the process
*/

+ (id) appIOManager;
- (NSArray*) configurationPlugins;
/**
Returns an array with the contents of the AdunHost.plist file
*/
- (NSMutableArray*) adunHosts;
/**
The location of the adun (linux) or .adun (Mac) directories.
Usuallly e.g. $HOME/adun.
*/
- (NSString*) applicationDir;
/**
Returns the default database dir.
*/
- (NSString*) databaseDir;
/**
Returns the directory for storing downloaded files.
Can be set by the user through the DownloadDirectory default.
*/
- (NSString*) downloadDir;
/**
Returns the name of the directory where (non-data) controller
output is written. The output of a controller is contained in a
subdirectory of this directory
*/
- (NSString*) controllerOutputDir;
/**
Default directory where plugins can write their output. Plugins
shouldnt access this value directly. Instead they should retrieve the
value of the default "$NAMEOutputDir" where $NAME is the plugin name. 
The registered value of this default is always the location returned
by this method. However users can override it to specify their own 
output locations.
*/
- (NSString*) defaultPluginOutputDir;
/**
Writes \e object to the specified file. If the object cannot be written this method
returns NO and \e error is set describing the reasons for failure. On success YES
is returned. Note \e object must respond to writeToFile:atomically:.
*/
- (BOOL) writeObject: (id) object toFile: (NSString*) filename error: (NSError**) error;
@end


@interface ULIOManager (ULTemporaryFileExtensions)

/**
Creates and returns the path to a unique temporary directory.
The directory is created with the default attributes. 
If the directory cant be created this method raises an NSInternalInconsistencyException
since being unable to create temp dirs is a critical error.
*/
- (NSString*) temporaryDirectoryWithPrefix: (NSString*) prefix;
@end

/**
Extensions to NSFileManager containing convenience
methods for checking and creating directories
\ingroup classes
*/
@interface NSFileManager (ULAdditions)
/**
Checks if a directory exists at \e path. Returns yes if it does no otherwise.
If \e path refers to a non-directory file \e error is set.
*/
- (BOOL) directoryExistsAtPath: (NSString*) path error: (NSError**) error;
/**
Creates a directory at \e path returning YES on sucess, NO otherwise. 
If a directory already exists at the path this message returns NO and no error is set.
Otherwise iIf NO is returned \e error is set with an NSError object explaining the reason for
the failure. This can be one of three things.

- A file already exists at the given path 
- The containing directory does not exist (NSFileNoSuchFileError)
- The user has no write permissions in the containing directory (NSWriteNoPermissionError)
*/
- (BOOL) createDirectoryAtPath: (NSString*) path 
		attributes: (NSDictionary*) attributes 
		error: (NSError**) error;
@end

#endif // _ULIOMANAGER_H_

