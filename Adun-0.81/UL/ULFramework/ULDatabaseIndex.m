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

#include "ULFramework/ULDatabaseIndex.h"


int dataSort(id data1, id data2, void *context)
{
	data1 = [data1 objectForKey: @"Name"];
	data2 = [data2 objectForKey: @"Name"];

        return [data1 compare: data2 options: NSCaseInsensitiveSearch];
}

@implementation ULDatabaseIndex

- (id) initWithDirectory: (NSString*) dir
{
	if((self = [super init]))
	{
		index = [NSMutableDictionary  dictionaryWithCapacity: 1];
		[index retain];
		databaseDir = [dir retain];
		lastNumber = 0;
		version = 0.7;
		objectInputReferences = [NSMutableDictionary new];
		objectOutputReferences = [NSMutableDictionary new];
	}	

	return self;
}

- (void) dealloc
{
	if(indexArray != nil)
		[indexArray release];

	[index release];
	[databaseDir release];
	[objectInputReferences release];
	[objectOutputReferences release];
	[super dealloc];
}

- (BOOL) updateMetadataForObject: (id) object error: (NSError**) error
{
	BOOL retval = YES;
	BOOL newKey = NO;
	NSError *updateError;
	NSEnumerator * keyEnum;
	NSKeyedArchiver* archiver;
	NSMutableData* data;
	id metadata, newMetadata, key;
	NSString* ident;

	//search for the metadata dict for this object
	metadata = [index objectForKey: [object identification]];

	if(metadata == nil)
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat: 
			@"Database - Object %@ not present. Cannot update metadata", [object description]]];

	ident = [object identification];
	newMetadata = [object allMetadata];

	/*
	 * If new metadata keys were added we have to save the object
	 * This is because:
	 * 1) The currently archived version of the object doesnt have them
	 * 2) updateMetadata, which is called the next time its unarchived, will
	 * only update the old keys not set the new ones.
	 * 3) We cant re-add them on unarchiving since we dont know their domain.
	 */

	//Check if any new keys are present 
	//Do this by checking if each key in newMetadata is in metadata
	keyEnum = [newMetadata keyEnumerator];
	while((key = [keyEnum nextObject]))
		if([metadata objectForKey: key] == nil)
		{
			newKey = YES;
			break;
		}
	
	if(newKey)
	{
		NSDebugLog(@"ULDatabaseIndex",
			@"Detected new metadata key - saving object");
		data = [NSMutableData new];
		archiver = [[NSKeyedArchiver alloc] 
				initForWritingWithMutableData: data];
		[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
		[archiver encodeObject: object forKey: @"root"];
		[archiver finishEncoding];

		NSDebugLLog(@"ULDatabaseIndex", @"Saving to file %@", 
			[databaseDir stringByAppendingPathComponent: ident]);

		retval = [data writeToFile: [databaseDir stringByAppendingPathComponent: ident]
				atomically: NO];

		[archiver release];
		[data release];
	}

	//This will be NO if we attempted to update the object and the
	//attempt failed.
	if(retval)
	{
		[index setObject: [[newMetadata mutableCopy] autorelease]
			forKey: ident];
		[[index objectForKey: ident] 
			setObject: ident 
			forKey: @"Identification"];
		[[index objectForKey: ident] 
			setObject: NSStringFromClass([object class]) 
			forKey: @"Class"];
		[indexArray release];
		indexArray = [[index allValues]
				sortedArrayUsingFunction: dataSort 
				context: NULL];
		indexArray = [indexArray retain];
	}
	else
	{
		updateError = AdCreateError(NSCocoaErrorDomain,
				0,
				@"Unable to write to directory",
				[NSString stringWithFormat: 
					@"Cannot write object data to directory %@", databaseDir],
				@"You may not have permissions to write to this directory");
		AdLogError(updateError);
		if(error != NULL)
			*error = updateError;
	}

	return retval;
}

- (void) updateOutputReferencesForObject: (id) object
{
	NSString* ident;

	//check the object is actually in the index

	ident = [object identification];
	if([index objectForKey: ident] == nil)
		[NSException raise: NSInternalInconsistencyException
			format: @"Object (%@) is not present in the database index. Cannot add output references.",
			[object allMetadata]];

	[objectOutputReferences setObject: [object outputReferences] 
		forKey: ident];
}

- (BOOL) indexContainsObjectWithId: (NSString*) ident
{
	if([index objectForKey: ident] != nil)
		return YES;
	else
		return NO;
}

- (BOOL) objectInIndex: (id) object
{
	id ident;

	ident = [object identification];
	return [self indexContainsObjectWithId: ident];
}

- (BOOL) addObject: (id) object error: (NSError**) error
{
	BOOL retval;
	NSError *addError;
	NSMutableDictionary* metadata;
	NSMutableData* data = [NSMutableData new];
	NSKeyedArchiver* archiver;
	id ident;

	//First save the object to the database
	NSDebugLLog(@"ULDatabaseIndex", @"Saving %@ to database in %@", object, databaseDir);
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: object forKey: @"root"];
	[archiver finishEncoding];

	ident = [object identification];
	NSDebugLLog(@"ULDatabaseIndex", 
		@"Object Ident is %@", ident);

	NSDebugLLog(@"ULDatabaseIndex", @"Saving to file %@", 
		[databaseDir stringByAppendingPathComponent: ident]);

	retval = [data writeToFile: [databaseDir stringByAppendingPathComponent: ident]
			atomically: NO];

	[archiver release];
	[data release];

	if(retval)
	{
		//Extract metadata to index	
		NSDebugLLog(@"ULDatabaseIndex", 
			@"Extracting object metadata to index");
		metadata = [[[object allMetadata] mutableCopy] autorelease];
		NSDebugLLog(@"ULDatabaseIndex", 
			@"Metdata is %@", metadata);

		//FIXME: I think the next step is redundant
		[index setObject: metadata
			forKey: ident];
		//Add the objects identification to its metadata 
		//so other objects can access it
		[[index objectForKey: ident]
			setObject: ident 
			forKey: @"Identification"];
		
		//Add the objects class to the metadata
		[[index objectForKey: ident] 
			setObject: NSStringFromClass([object class]) 
			forKey: @"Class"];

		[indexArray release];
		indexArray = [[index allValues]
				sortedArrayUsingFunction: dataSort 
				context: NULL];
		[indexArray retain];		

		[objectInputReferences setObject: [object inputReferences] 
			forKey: ident];
		[objectOutputReferences setObject: [object outputReferences]
			forKey: ident];
	}	
	else
	{
		addError = AdCreateError(NSCocoaErrorDomain,
				0,
				@"Unable to write to directory",
				[NSString stringWithFormat: 
					@"Cannot write object data to directory %@", databaseDir],
				@"You may not have permissions to write to this directory");
		AdLogError(addError);
		if(error != NULL)
			*error = addError;
	}			

	return retval;
}

- (BOOL) removeObjectWithId: (id) ident error: (NSError**) error
{
	BOOL retval = NO;
	NSError *removeError;
	NSString* filePath;
	NSFileManager* fileManager;
	id object;

	object = [index objectForKey: ident];

	if(object != nil)
	{
		filePath = [databaseDir stringByAppendingPathComponent:
				[object valueForKey: @"Identification"]];

		NSDebugLLog(@"ULDatabaseIndex", @"Removing object (%@) and file %@", 
				object, 
				filePath);

		fileManager = [NSFileManager defaultManager];	
		if([fileManager fileExistsAtPath: filePath])
		{
			if([fileManager isDeletableFileAtPath: filePath])
			{
				[fileManager removeFileAtPath: filePath
					handler: nil];

				//remove object from index

				[index removeObjectForKey: ident]; 
				NSDebugMLLog(@"ULDatabaseIndex", @"Index is %@",
					index);
				[indexArray release];
				indexArray = [[index allValues]
						sortedArrayUsingFunction: dataSort 
						context: NULL];
				indexArray = [indexArray retain];

				//remove related input and output references
				[objectOutputReferences removeObjectForKey: ident];
				[objectInputReferences removeObjectForKey: ident];
				retval = YES;
			}
			else
			{
				NSWarnLog(@"Failed to remove object from database");
				removeError = AdCreateError(NSCocoaErrorDomain,
						0,
						@"Unable to remove object",
						[NSString stringWithFormat: 
							@"Cannot delete file %@", filePath],
						@"You may not have permissions to write to this directory");
				AdLogError(removeError);
				if(error != NULL)
					*error = removeError;
			}
		}	
		else
		{
			//The object is missing but the metadata is in the index.
			//In this case just log an error and continue.
			[index removeObjectForKey: ident];
			NSDebugMLLog(@"ULDatabaseIndex", @"Index is	%@", index);
			[indexArray release];
			indexArray = [[index allValues]
					sortedArrayUsingFunction: dataSort 
					context: NULL];
			indexArray = [indexArray retain];
			NSWarnLog(@"Object file was not present in the database");
			NSWarnLog(@"However object metadata was in the index");
			NSWarnLog(@"Possibly due to direct deletion of file from database");
			retval = YES;
		}
	}
	else
	{
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat: 
			@"Object with ident %@ not present in index.",
			ident]];
	}

	return retval;
}

- (BOOL) removeObjectsWithIds: (NSArray*) idents error: (NSError**) error
{
	BOOL retval;
	NSEnumerator* idEnum;
	id ident;
	
	//Check all are present
	idEnum = [idents objectEnumerator];
	while((ident = [idEnum nextObject]))
		if(![self indexContainsObjectWithId: ident])
			[NSException raise: NSInvalidArgumentException
				format: [NSString stringWithFormat: 
				@"Object with ident %@ not present in index.",
				ident]];

	idEnum = [idents objectEnumerator];
	while((ident = [idEnum nextObject]))
		if(!(retval = [self removeObjectWithId: ident error: error]))
			break;
	
	return retval;
}

//We simply remove the reference from the indexes lists of output
//references for that object. The objects internal output references
//will be synched to the new values the next time its unarchived.
- (void) removeOutputReferenceToObjectWithId: (NSString*) identOne
		fromObjectWithId: (NSString*) identTwo
{
	int position, i;
	NSString* ident;
	NSMutableArray* outputReferences;
	NSDictionary* reference;

	if(![self indexContainsObjectWithId: identTwo])
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat: 
			@"Object with ident %@ not present in index.",
			ident]];
		
	outputReferences = [[objectOutputReferences objectForKey: identTwo] 
				mutableCopy];

	for(position = NSNotFound, i=0; i<(int)[outputReferences count]; i++)	
	{
		reference = [outputReferences objectAtIndex: i];
		ident = [reference objectForKey: @"Identification"];
		if([ident isEqual: identOne])
		{
			position = i;
			break;
		}	
	}

	if(position == NSNotFound)
		return;
	
	[outputReferences removeObjectAtIndex: position];

	//Set the array with a nonmutable copy of outputReferences
	[objectOutputReferences setObject: 
			[NSArray arrayWithArray: outputReferences]
		forKey: identTwo];

	[outputReferences release];
}	

- (id) unarchiveObjectWithId: (NSString*) ident error: (NSError**) error
{
	NSString* temp;
	NSError *unarchiveError;
	NSDictionary* indexMetadata;
	NSEnumerator* outputReferenceEnum;
	id object, reference;
	
	if(![self indexContainsObjectWithId: ident])
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat: 
			@"Object with ident %@ not present in index.",
			ident]];

	temp = [databaseDir stringByAppendingPathComponent: ident];
	object = [NSKeyedUnarchiver unarchiveObjectWithFile: temp];

	if(object != nil)
	{
		//sync object metadata with current index metadata
		indexMetadata = [index objectForKey: ident];
		[object updateMetadata: indexMetadata];

		//Have to synch the object output references
		[object removeAllOutputReferences];
		outputReferenceEnum = [[objectOutputReferences objectForKey: 
					[object identification]] objectEnumerator];
		while((reference = [outputReferenceEnum nextObject]))
			[object addOutputReferenceToObjectWithID:
					[reference objectForKey: @"Identification"]
				ofType: [reference objectForKey: @"Class"]];
	}
	else 	
	{
		unarchiveError = AdCreateError(NSCocoaErrorDomain,
					0,
					@"Unable to retrieve object",
					[NSString stringWithFormat: 
						@"Cannot unarchive file %@", temp],
					@"You may not have permissions to write to this directory");	
		AdLogError(unarchiveError);
		if(error != NULL)
			*error = unarchiveError;
	}

	return object;
}

- (NSArray*) metadataForStoredObjects
{
	return [[indexArray retain] autorelease];
}

- (NSDictionary*) metadataForObjectWithID: (NSString*) ident
{
	return [index objectForKey: ident];
}

- (NSArray*) outputReferencesForObjectWithID: (NSString*) ident
{
	return [objectOutputReferences objectForKey: ident];
}

- (NSArray*) inputReferencesForObjectWithID: (NSString*) ident
{
	return [objectInputReferences objectForKey: ident];
}

- (void) reindexAll
{
	NSWarnLog(@"Not implemented %@", NSStringFromSelector(_cmd));
}

- (double) version
{
	return version;
}

- (void) setVersion: (double) number
{
	version = number;
}

//Returns the actual index - use with care
- (id) index
{
	return index;
}

/******************

NSCoding

******************/

/**
Updates v1.3 objects
*/

- (void) _updateVersion
{
	NSString* dbName;
	id object;
	NSEnumerator* indexEnum;

	//assuming here that the index is always part of the local filesystem db
	//which is valid at the moment
	if((dbName = NSUserName()) == nil)
			dbName = @"unknown";
		
	dbName = [NSString stringWithFormat: @"%@@localhost", dbName];

	//create new ivars	

	objectInputReferences = [NSMutableDictionary new];
	objectOutputReferences = [NSMutableDictionary new];

	//update entries without the key "database"
	indexEnum = [index objectEnumerator];
	while((object = [indexEnum nextObject]))
		if([object objectForKey: @"Database"] == nil)
			[object setObject: dbName forKey: @"Database"];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	id lastSaveDate, date;

	if([decoder allowsKeyedCoding])
	{
		//If version doesn't exist it will be set to 0.0
		version = [decoder decodeDoubleForKey: @"Version"];
			
		index = [[decoder decodeObjectForKey: @"Index"] retain];
		databaseDir = [[decoder decodeObjectForKey: @"DatabaseDir"] retain];
		lastSaveDate = [decoder decodeObjectForKey: @"SavedDate"];
		date = [NSCalendarDate calendarDate];
		if([lastSaveDate dayOfYear] == [date dayOfYear])
		{
			if([lastSaveDate yearOfCommonEra] == [date yearOfCommonEra])
				lastNumber = [decoder decodeIntForKey: @"LastIndex"];
		}		
		else
			lastNumber = 0;	

		//handle update to new version of ULDatabaseIndex - (version 1.2 - 1.3+)
		if([decoder decodeObjectForKey: @"objectInputReferences"] != nil)
		{
			objectInputReferences = [decoder decodeObjectForKey: @"objectInputReferences"];
			objectOutputReferences = [decoder decodeObjectForKey: @"objectOutputReferences"];
			[objectInputReferences retain];
			[objectOutputReferences retain];
		}
		else
			[self _updateVersion];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Database does not support non-keyed coding"];
	
	indexArray = [[index allValues]
			sortedArrayUsingFunction: dataSort 
			context: NULL];
	[indexArray retain];		
	NSDebugLLog(@"ULDatabaseIndex",
		@"Last Saved %@. Todays date %@. Last Index %d", 
		lastSaveDate, date, lastNumber);

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeDouble: version forKey: @"Version"];
		[encoder encodeInt: lastNumber forKey: @"LastIndex"];
		[encoder encodeObject: [NSCalendarDate calendarDate] forKey: @"SavedDate"];
		[encoder encodeObject: index forKey: @"Index"];
		[encoder encodeObject: databaseDir forKey: @"DatabaseDir"];
		[encoder encodeObject: objectInputReferences 
			forKey: @"objectInputReferences"];
		[encoder encodeObject: objectOutputReferences 
			forKey: @"objectOutputReferences"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Database does not support non-keyed coding"];
}

@end
