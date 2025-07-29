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

#include "ULIOManager.h"
#include "ULDatabaseInterface.h"

static id ioManager;

@implementation ULIOManager

+ (id) appIOManager
{
	//check if we have already created the manager

	if(ioManager != nil)
	{
		return ioManager;
	}
	else
	{
		ioManager = [self new];
		return ioManager;
	}
}

/**
Usually only called when the application first starts up
*/

- (void) _importQuickStartFiles
{
	NSString* path, *file;
	NSArray* contents;
	NSEnumerator* contentsEnum;
	ULDatabaseInterface* interface = [ULDatabaseInterface databaseInterface];
	id object;
	
	path = [[NSBundle mainBundle] resourcePath];
	path = [path stringByAppendingPathComponent: @"QuickStartFiles"];
	
	contents = [fileManager directoryContentsAtPath: path];
	contentsEnum = [contents objectEnumerator];
	while(file = [contentsEnum nextObject])
	{
		file = [path stringByAppendingPathComponent: file];
		object = [NSKeyedUnarchiver unarchiveObjectWithFile: file];
		[interface addObjectToFileSystemDatabase: object];
	}
}

- (void) _createApplicationDirectories
{
	id tempObj;	
	
	if(![fileManager createDirectoryAtPath: applicationDir attributes: nil])
		[NSException raise: NSInternalInconsistencyException 
			format: @"Unable to create working directory!"];
	
	//Move database subdirectory creation to ULFileSystemDatabaseBackend
	[fileManager createDirectoryAtPath: databaseDir 
		attributes: nil];
	[fileManager createDirectoryAtPath: userPluginsDir 
		attributes: nil];
	[fileManager createDirectoryAtPath: 
			[userPluginsDir stringByAppendingPathComponent: @"Configurations"]
		 attributes: nil];
	[fileManager createDirectoryAtPath: 
			[userPluginsDir stringByAppendingPathComponent: @"Analysis"]
		 attributes: nil];
	[fileManager createDirectoryAtPath: 
			[userPluginsDir stringByAppendingPathComponent: @"Controllers"]
		 attributes: nil];

	//create the default host list
	tempObj = [NSMutableArray arrayWithCapacity:1];
	[tempObj addObject: [[NSHost currentHost] name]];
	[tempObj writeToFile: [applicationDir stringByAppendingPathComponent: @"AdunHosts.plist"]
		atomically: NO];
		
	//First start up - Copy in quick start files
	
	[self _importQuickStartFiles];	
}

- (id) init
{
	BOOL isDir;

	//create filemanager instance

	if((self = [super init]))
	{
		fileManager = [NSFileManager defaultManager];
		userHome = NSHomeDirectory();
		processInfo = [NSProcessInfo processInfo];

		currentDir = [fileManager currentDirectoryPath];
		[currentDir retain];

#ifdef GNUSTEP
		applicationDir = [userHome stringByAppendingPathComponent: @"adun"];
#else		
		applicationDir = [userHome stringByAppendingPathComponent: @".adun"];
#endif		
		databaseDir = [applicationDir stringByAppendingPathComponent: @"Database"];
		userPluginsDir = [applicationDir stringByAppendingPathComponent: @"Plugins"];
		controllerOutputDir = [applicationDir stringByAppendingPathComponent: @"ControllerOutput"];
		pluginOutputDir = [applicationDir stringByAppendingPathComponent: @"PluginOutput"];
		
		//Register a default download dir
		[[NSUserDefaults standardUserDefaults] registerDefaults:
			[NSDictionary dictionaryWithObjectsAndKeys: 
				[applicationDir stringByAppendingPathComponent: @"Downloads"],
				@"DownloadDirectory", nil]];
						
		
		downloadDir = [[NSUserDefaults standardUserDefaults] stringForKey: @"DownloadDirectory"];

		[downloadDir retain];
		[applicationDir retain];
		[databaseDir retain];
		[userPluginsDir retain];
		[controllerOutputDir retain];
		[pluginOutputDir retain];

		NSDebugLLog(@"ULIOManager", @"Current Dir: %@\n", currentDir);
		NSDebugLLog(@"ULIOManager", @"App Dir: %@\n", applicationDir);

		//check if adun directory exists and create it if it doesnt
		if(!([fileManager fileExistsAtPath: applicationDir isDirectory: &isDir] && isDir))
			[self _createApplicationDirectories];

		//Create controller output directory
		if(!([fileManager fileExistsAtPath: controllerOutputDir isDirectory: &isDir] && isDir))
			[fileManager createDirectoryAtPath: controllerOutputDir 
				attributes: nil];
				
		//Create plugin output directory
		if(!([fileManager fileExistsAtPath: pluginOutputDir isDirectory: &isDir] && isDir))
			[fileManager createDirectoryAtPath: pluginOutputDir 
				attributes: nil];
	
		//Create download output directory
		if(!([fileManager fileExistsAtPath: downloadDir isDirectory: &isDir] && isDir))
			[fileManager createDirectoryAtPath: downloadDir 
				attributes: nil];
	}

	return self;
}

- (void) dealloc
{
	[downloadDir release];
	[pluginOutputDir release];
	[currentDir release];
	[applicationDir release];
	[databaseDir release];
	[userPluginsDir release];
	[controllerOutputDir release];
	[super dealloc];
}

- (NSString*) applicationDir
{
	return [[applicationDir retain] autorelease];
}

- (NSString*) databaseDir
{
	return [[databaseDir retain] autorelease];
}

- (NSString*) controllerOutputDir
{
	return [[controllerOutputDir retain] autorelease];
}

- (NSString*) defaultPluginOutputDir
{
	return [[pluginOutputDir retain] autorelease];
}

- (NSString*) downloadDir
{
	return [[downloadDir retain] autorelease];
}

- (NSArray*) configurationPlugins
{
	return [[NSFileManager defaultManager] directoryContentsAtPath: 
			[userPluginsDir stringByAppendingPathComponent: @"Configurations"]];
}

- (NSMutableArray*) adunHosts
{
	return [NSMutableArray arrayWithContentsOfFile:
		[applicationDir stringByAppendingPathComponent: @"AdunHosts.plist"]];
}

- (BOOL) writeObject: (id) object toFile: (NSString*) filename error: (NSError**) error
{
	BOOL isDir;
	NSString* dir, *reason;
	NSMutableDictionary* userInfo;
	id temp, name;

	userInfo = [NSMutableDictionary dictionary];
	
	//check object

	if(![object respondsToSelector: @selector(writeToFile:atomically:)])
	{
		reason = @"Object invalid - must respond to writeToFile:atomically:";
		[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: @"ULErrorDomain"
				code: 1
				userInfo: userInfo];
		return NO;
	}

	//check file
	name = 	[[filename lastPathComponent] stringByTrimmingCharactersInSet: 
						[NSCharacterSet whitespaceCharacterSet]];
						
	NSDebugLLog(@"Export", @"Name of file is %@", name);
	if([name isEqual: @""])
	{
		reason = @"Filename invalid - Must contain characters other than whitespace";
		[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: @"ULErrorDomain"
				code: 1
				userInfo: userInfo];
		return NO;
	}

	temp = [[filename pathComponents] mutableCopy];
	[temp removeLastObject];
	dir = [NSString pathWithComponents: temp];

	NSDebugLLog(@"Export", @"Exporting to dir %@", dir);
	
	
	if(![fileManager fileExistsAtPath: dir isDirectory: &isDir])
	{
		reason = [NSString stringWithFormat: @"The specfied directory (%@) does not exist", dir];
		[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: @"ULErrorDomain"
				code: 1
				userInfo: userInfo];
		return NO;
	}
	
	if(!isDir)
	{
		reason = [NSString stringWithFormat: @"%@ is not a directory", dir];
		[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: @"ULErrorDomain"
				code: 1
				userInfo: userInfo];
		return NO;
	}

	if(![fileManager isWritableFileAtPath: dir])
	{
		reason = [NSString stringWithFormat: @"Specified directory (%@) is not writable", dir];
		[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: @"ULErrorDomain"
				code: 1
				userInfo: userInfo];
		return NO;
	}


	if([fileManager fileExistsAtPath: filename])
		if(![fileManager isWritableFileAtPath:filename]) 
		{
			reason = @"Cannot overwrite file - write protected";
			[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain: @"ULErrorDomain"
					code: 1
					userInfo: userInfo];
			return NO;
		}

	if(![object writeToFile: filename atomically: NO])
	{
		reason = @"Unable to export file - Reason unknown";
		[userInfo setObject: reason forKey: NSLocalizedDescriptionKey];
		*error = [NSError errorWithDomain: @"ULErrorDomain"
				code: 1
				userInfo: userInfo];
		return NO;
	}

	return YES;
}


@end


@implementation ULIOManager (ULTemporaryFileExtensions)


- (NSString*) temporaryDirectoryWithPrefix: (NSString*) prefix
{
	NSString* uniqueString = [processInfo globallyUniqueString];
	NSString* tempDir;

	if(prefix == nil)
		prefix = @"";

	tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:
			[NSString stringWithFormat: @"%@_%@", prefix, uniqueString]];

	NSDebugLLog(@"ULIOManager", @"Generated temp dir name %@", tempDir);

	//create the directory - raise an exception if we cant since 
	//this is a critical error. We should always be able to create
	//a temporary directory

	if(![fileManager createDirectoryAtPath: tempDir attributes: nil])
		[NSException raise: NSInternalInconsistencyException
			format: @"Unable to create temporary directory!"];

	return tempDir;
}

@end


@implementation NSFileManager (ULExtensions)
/**
Check directory sets an error if a file is in the way of the directory.
It returns NO if the directory does not exist
*/
- (BOOL) directoryExistsAtPath: (NSString*) path error: (NSError**) error
{
	BOOL isDir;

	if([self fileExistsAtPath: path isDirectory: &isDir])
	{
		if(!isDir)
		{
			*error = AdCreateError(NSCocoaErrorDomain,
				4,
				[NSString stringWithFormat: 
				@"A non-directory file exists at %@", path],
				@"The required directory cannot be created as the file is in the way.",
				@"Move or remove the file");

			return NO;
		}

		return YES;
	}

	return NO;
}

- (BOOL) createDirectoryAtPath: (NSString*) path 
		attributes: (NSDictionary*) attributes 
		error: (NSError**) error

{
	NSMutableArray* components;
	NSString* containingDir;

	//Peform expansion if necessary
	path = [path stringByExpandingTildeInPath];

	//try to create the directory
	if(![self createDirectoryAtPath: path 
		 attributes: attributes])
	{

		//Failed to create dir
		//Check if this is because the containing directory does not exist
		//or because or permission problems

		components = [[path pathComponents] mutableCopy];
		[components autorelease];
		[components removeLastObject];
		containingDir = [components componentsJoinedByString: @"/"];

		if(![self directoryExistsAtPath: path error: error])
		{
			if(!error)
			{
				*error = AdCreateError(NSCocoaErrorDomain,
				514,
				[NSString stringWithFormat: 
				@"Unable to create directory %@", path],
				@"The containing directory does not exist",
				@"Create the containing directory");
			}
				
			
		}
		else
		{
			*error = AdCreateError(NSCocoaErrorDomain,
				513,
				[NSString stringWithFormat: 
				@"Unable to create missing directory %@", path],
				@"Containing directory is not writable",
				@"Change the permissions of the containing directory to allow file creation");
		}		

		return NO;
	}
	
	return YES;
}

@end
