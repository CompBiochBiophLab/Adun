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

#include "ULFramework/ULDatabaseSimulationIndex.h"

@implementation ULDatabaseSimulationIndex

- (BOOL) addObject: (id) object error: (NSError**) error
{
	int retval = YES;
	NSError *addError;
	NSString* ident;
	NSString* storagePath, *destinationPath, *linkPath;

	//add the AdSimulationData as normal.If this fails exit
	if(![super addObject: object error: error])
		return NO;

	ident = [object identification];

	//check where the simulation data storage is - if its not in the
	//simulation directory copy it there 

	storagePath = [[object dataStorage] storagePath];
	if(![[storagePath stringByDeletingLastPathComponent] isEqual:
		databaseDir])
	{
		destinationPath =  [databaseDir stringByAppendingPathComponent: 
					[NSString stringWithFormat: @"%@_Data", ident]];

		retval = [[NSFileManager defaultManager]
				copyPath: storagePath
				toPath: destinationPath
				handler: nil];
		if(retval)
		{
			storagePath = destinationPath;
			linkPath = [databaseDir stringByAppendingPathComponent: [object name]];

			if(![[NSFileManager defaultManager] createSymbolicLinkAtPath: linkPath
				pathContent: storagePath])
			{
				NSWarnLog(@"Failed to create link when moving simulation storage");
				linkPath = @"None";
			}

			[object setValue: linkPath forMetadataKey: @"DataLink"];
		}
		else	
		{
			NSWarnLog(@"Unable to copy downloaded data into file system database");
			addError = AdCreateError(NSCocoaErrorDomain,
					0,
					@"Unable to copy data - Transaction aborted",
					[NSString stringWithFormat: 
						@"Could not copy simulation data from %@ to %@",
						storagePath, destinationPath],
					@"Check permissions on data being imported.");
			if(error != NULL)
				*error = addError;
		}
	}
	
	//Add the location of the simulation data directory to
	//the index metadata if we succeded in adding it.
	if(retval)
		[[index objectForKey: ident] 
			setObject: storagePath
			forKey: @"SimulationDataPath"];

	[indexArray release];
	indexArray = [[index allValues]
			sortedArrayUsingFunction: dataSort 
			context: NULL];
	[indexArray retain];	

	if(!retval)
		[self removeObjectWithId: ident error: NULL];	

	return retval;
}

- (BOOL) removeObjectWithId: (id) ident error: (NSError**) error
{
	BOOL retval = YES;
	NSError *removeError;
	NSString* filePath, *link;
	NSFileManager* fileManager;
	id object;

	//First remove the simulation data
	//If the simulation data is not present we dont do anything
	//as this could because this method is being called to roll
	//back a failed addition (see addObject:error: above).
	object = [index objectForKey: ident];
	if(object != nil)
	{
		filePath = [object objectForKey: @"SimulationDataPath"];
		if(filePath == nil)
		{
			//This is a programming error - It should never happen
			[NSException raise: NSInternalInconsistencyException
				format: @"SimulationDataPath value not present as it should be"];
		}
		else
		{	
			fileManager = [NSFileManager defaultManager];	
		
			NSDebugLLog(@"ULDatabaseSimulationIndex",
				@"Removing data directory at %@", 
					filePath);

			if([fileManager fileExistsAtPath: filePath])
			{
				if([fileManager isDeletableFileAtPath: filePath])
				{
					[fileManager removeFileAtPath: filePath
						handler: nil];
				}
				else
				{
					NSWarnLog(@"Failed to remove data directory");
					retval = NO;		
					removeError = AdCreateError(
						 NSCocoaErrorDomain,
						 0,
						 @"Cannot remove directory",
						 [NSString stringWithFormat: 
						 @"Unable to remove simulation data directory at %@",
							filePath],
						 @"You may not have permissions to write to this directory");

					if(error != NULL)
						*error = removeError;
				}
			}	
			else
				NSWarnLog(@"Data %@ not present at expected path %@", filePath);
			

			//Remove the link
			link = [databaseDir stringByAppendingPathComponent: [object objectForKey:@"Name"]];
			if(link == nil)
			{
				NSWarnLog(@"No link present to directory %@", filePath);
			}	
			else
			{
				//These are minor error - just log and ignore
				if([filePath isEqual:
					[fileManager pathContentOfSymbolicLinkAtPath: link]])
				{
					retval = [fileManager removeFileAtPath:	link handler: nil];
					if(!retval)
						NSWarnLog(@"Unable to remove link %@", link);
				}
				else
				{
					NSWarnLog(@"%@ is not a valid link to directory %@. Links to ", 
						link,
						filePath,
						[fileManager pathContentOfSymbolicLinkAtPath: link]);
				}		
			}
		}	
	}

	//If all the previous steps passed without incident
	//continue and remove the object file.
	if(retval)
		return [super removeObjectWithId: ident error: error];
	else
		return retval;
}

- (id) unarchiveObjectWithId: (NSString*) ident error: (NSError**) error
{
	id object, dataStorage;
	NSString* storagePath; 

	//unarchive the object as normal
	//If this method returns nil we abort
	//the rest of the procedure.
	object = [super unarchiveObjectWithId: ident error: error];
	if(object == nil)
		return object;
	
	//create a dataStorage object so the object can
	//access its data. We saved the path under the
	//key "SimulationDataPath" in the index.

	storagePath = [[index objectForKey: ident]
			objectForKey: @"SimulationDataPath"];
	NSDebugMLLog(@"ULDatabaseIndex", @"Storage path is %@", storagePath);		
	dataStorage = [[AdFileSystemSimulationStorage alloc]
			initForReadingSimulationDataAtPath: storagePath];
	[dataStorage autorelease];
	[object setDataStorage: dataStorage];
	
	if(![dataStorage isAccessible] && error != NULL)
		*error = [dataStorage accessError];

	return object;
}

- (BOOL) updateMetadataForObject: (id) object error: (NSError**) error
{
	BOOL success = YES;
	NSError *linkError = nil;
	NSString* ident, *newName, *oldName, *link;
	NSString* dataDirectory;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString* storagePath;
	
	//Before updating metadata retrieve the old name and store it
	//We may have to change a link
	oldName = [[index objectForKey: [object identification]]
			objectForKey: @"Name"];
	//On OSX oldName becomes invalid after the call to super below
	//unless we do the following
	[[oldName retain] autorelease];		

	if(!(success = [super updateMetadataForObject: object error: error]))
		return success;

	ident = [object identification];
	storagePath = [[object dataStorage] storagePath];
	//FIXME: See addObject for problem with next two lines.
	[[index objectForKey: ident] setObject: storagePath
		forKey: @"SimulationDataPath"];

	//Update link name if any	
	//Only notify the user if we cannot create a new link
	newName = [object name];
	if(![newName isEqual: oldName])
	{
		dataDirectory = [[object dataStorage] storagePath];
		NSDebugLLog(@"ULDatabaseIndex", @"Simulation name change detected. Updating link name if possible");
		
		//Check if old link exists
		link = [databaseDir stringByAppendingPathComponent: oldName];
		if(link == nil)
		{
			NSWarnLog(@"No link present to directory %@", dataDirectory);
		}	
		else
		{
			//Old link exists.
			//Check if it points to the correct directory. If so delete it.
			if(![dataDirectory isEqual:
				[fileManager pathContentOfSymbolicLinkAtPath: link]])
			{
				NSWarnLog(@"Link does not point to correct directory %@", link);
			}
			else
			{	success = [fileManager removeFileAtPath:link handler: nil];
				if(!success)
					NSWarnLog(@"Unable to remove link %@", link);
			}		
		}

		//We want to proceed with the new link creation even if
		//we had problems with the old one.
		success = YES;	

		//Create new link with new name overriding any previous links with the same name
		link = [databaseDir stringByAppendingPathComponent: newName];
		NSDebugLLog(@"ULDatabaseIndex", @"Attempting to creating new link %@", link);
		if([fileManager fileExistsAtPath: link])
		{
			NSDebugLLog(@"ULDatabaseIndex", @"Detected link present with same name");
			success = [fileManager
					removeFileAtPath: link 
					handler: nil];
			if(!success)
			{
				NSWarnLog(@"Unable to remove link - %@", link);
				linkError = AdCreateError(
						NSCocoaErrorDomain,
						0,
						@"Unable to remove link",
						@"Cannot remove existing link to previous simulation data",
						@"Check link permissions");
			}			
		}		

		//It is likely that the problem causing this error
		//will have already been detected when creating the simulation
		//object file.
		if(![fileManager createSymbolicLinkAtPath: link
			pathContent: dataDirectory])
		{
			success = NO;
			NSWarnLog(@"Failed to create link to simulation data directory %@", 
				dataDirectory);
			linkError = AdCreateError(
					NSCocoaErrorDomain,
					0,
					@"Failed to create link",
					[NSString stringWithFormat: 
						@"Cannot create link to directory %@", dataDirectory],
					@"You may not have permissions to write to this directory");
		}	
	}

	if(linkError != nil && error != NULL)
		*error = linkError;

	return success;
}

@end
