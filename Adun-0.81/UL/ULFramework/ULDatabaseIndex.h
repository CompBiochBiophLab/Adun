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

#ifndef _ULDATABASEINDEX_H_
#define _ULDATABASEINDEX_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunModelObject.h>
#include <AdunKernel/AdFrameworkFunctions.h>

/**
Index for use with file based database.
\ingroup classes
\todo Currently the index data returned by metadataForObjectWithID: and
availableObjects is the actual internal data - hence changes to it affect
changes to the index itself - These must be changed to return immutable data.
At the moment it is very hard to untangle who adds what, when and what actually
gets archived etc.
*/

@interface ULDatabaseIndex : NSObject
{
	int lastNumber;
	double version;
	NSMutableDictionary* index;
	NSArray* indexArray; 	//!< An array of the current metadatas
	NSString* databaseDir;
	NSMutableDictionary* objectInputReferences;
	NSMutableDictionary* objectOutputReferences;

}

- (id) initWithDirectory: (NSString*) dir;
/**
Adds the object to the database directory managed by the receiver.
Returns NO if the object could not be added YES otherwise. If NO
is returned then \e error contains an NSError object explaining the problem.
*/
- (BOOL) addObject: (id) object error: (NSError**) error;
/**
Returns YES if \e object is stored in the database directory managed
by the receiver
*/
- (BOOL) objectInIndex: (id) object;
/**
Returns YES if an object with identification \e ident is stored in the database directory managed
by the receiver
*/
- (BOOL) indexContainsObjectWithId: (NSString*) ident;
/**
Removes \e object from the database directory managed by the receiver.
If successful returns YES otherwise return NO. If NO is returned 
\e error contains an NSError object explaining the problem.
Raises an NSInvalidArgumentException if no object with \e identification
is in the index.
*/
- (BOOL) removeObjectWithId: (id) identification error: (NSError**) error;
/**
Removes the objects with the identifications contained in the array \e idents from the
database directory managed by the receiver using removeObjectWithId:error:.
If any call to removeObjectsWithId:error fails this method immediately 
returns NO and error contains a description of the problem that caused the removal to halt. 
The objects corresponding to identifications after the one that caused the
error are not removed. 
All the objects in \e idents must be contained in the database - If not an NSInvalidArgumentException
is raised. In this case nothing is removed.
*/
- (BOOL) removeObjectsWithIds: (NSArray*) idents error: (NSError**) error;
/**
Unarchives and returns the object identified by \e id from the database 
directory managed by the receiver. Raises an NSInvalidArgumentException 
if no object with identification \e id is in the index. Returns nil if the
object could not be unarchived and \e error contains an NSError object
explaining the problem.
*/
- (id) unarchiveObjectWithId: (NSString*) id error: (NSError**) error;
/**
Updates the metadata stored in the reciever for \e object. Raises
an NSInvalidArgumentException if \e object is not in the database managed by 
the reciever. Returns YES if the update is successful NO otherwise. On returning
NO \e error contains an NSError object explaining the problem.
*/
- (BOOL) updateMetadataForObject: (id) object error: (NSError**) error;
/**
Updates the output references stored in the reciever for \e object.
Raises an NSInvalidArgumentException if \e object is not in the database managed by 
the reciever. Otherwise this method cannot fail as it does not involve a
write to the receivers directory.
*/
- (void) updateOutputReferencesForObject: (id) object;
/**
Removes any output references to \e identOne from \e identTwo. 
Raises an NSInvalidArgumentException if no object with identification
\e identTwo is present in the database directory managed by the receiver.
*/
- (void) removeOutputReferenceToObjectWithId: (NSString*) identOne 
		fromObjectWithId: (NSString*) identTwo;
/**
 Not implemented
*/
- (void) reindexAll;
/**
Returns an array containing one dictionary for each object in the
database directory managed by the receiver. The dictionary is equivalent
to the one returned by AdModelObject::allMetadata() for that object.
*/
- (NSArray*) metadataForStoredObjects;
/**
Returns the dictionary returned by AdModelObject::allMetadata()
for the object with id \e ident. Returns nil if no object with
id \e ident is in the database managed by the receiver.
*/
- (NSDictionary*) metadataForObjectWithID: (NSString*) ident;
/**
Returns the dictionary returned by AdModelObject::outputReferences()
for the object with id \e ident. Returns nil if no object with
id \e ident is in the database managed by the receiver.
*/
- (NSArray*) outputReferencesForObjectWithID: (NSString*) ident;
/**
Returns the dictionary returned by AdModelObject::inputReferences()
for the object with id \e ident. Returns nil if no object with
id \e ident is in the database managed by the receiver.
*/
- (NSArray*) inputReferencesForObjectWithID: (NSString*) ident;
/**
Description forthcomming
*/
- (double) version;
/**
Description forthcomming
*/
- (void) setVersion: (double) number;
@end

//Function used by index classes to sort the availableObjects array by object name.
int dataSort(id data1, id data2, void *context);
#endif // _ULSIMULATIONDATABASE.M_H_

