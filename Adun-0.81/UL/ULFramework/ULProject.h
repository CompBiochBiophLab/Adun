/*
 Project: Adun
 
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
#ifndef _ULPROJECT_
#define _ULPROJECT_ 
#include <Foundation/Foundation.h>
#include <AdunKernel/AdunKernel.h>
#include "ULFramework/ULFrameworkDefinitions.h"

extern NSString* ULProjectIdentification;

/**
\ingroup classes
Contains references to an unlimited number of model objects that are stored in databases.
Each reference is a dictionary containing the following keys

- AdObjectIdentification
- AdObjectClass
- Database
- Schema 
- ULProjectIdentification.

Therefore the reference is specific to a certain logical location (Database.Schema).
If the object is moved from the location by any means then the reference will become invalid and have to be changed.
The references are unique in the sense that only one reference to a specific object in a specific location can be in the project.
However two copies of the same object can be added if they reside in different locations.

\note Although ULProject is a subclass of AdModelObject it does not support non-keyed coding.
\note ULProjectIdentification is a special key and not used for comparison purposes in the methods below.

*/
@interface ULProject: AdModelObject 
{
	BOOL isRootProject;
	NSMutableArray* references;
	NSMutableDictionary* classReferences;
	ULProject* projectContainer;
}
/**
Removes \e aReference from the receiver.
If \e aReference does not exist this method does nothing
*/
- (void) removeReference: (NSDictionary*) aReference;
/**
Adds \e aReference to the project.
If \e aReference is identical to a reference already in the 
project this method does nothing.
If \e aReference does not contain keys of the correct type and number 
- AdObjectIdentification, AdObjectClass, Database, Schema -
it is not added.

\note This identical to the metadata dict returned by ULDatabaseInterface etc.
*/
- (void) addReference: (NSDictionary*) aReference;
/**
Returns YES if a reference equal to \e aReference is in the dictionary.
To be equal it must have the same values for the four reference keys.
*/
- (BOOL) containsReference: (NSDictionary*) aReference;
/**
Adds a reference to \e anObject which must be stored in a database.
If its not this method raise an NSInvalidArgumentException.
Note a reference is only considered to exist if all four properties are
the same - equality by AdObjectIdentification is not sufficent.
*/
- (void) addReferenceToObject: (AdModelObject*) anObject;
/**
Removes a reference to \e anObject.
If no reference to \e anObject exists this method does nothing.
Note a reference is only considered to exist if all four properties are
the same - equality by AdObjectIdentification is not sufficent.
*/
- (void) removeReferenceToObject: (AdModelObject*) anObject;
/**
Returns YES if the receiver contains a reference to object.
NO otherwise.
Note a reference is only considered to exist if all four properties are
the same - equality by AdObjectIdentification is not sufficent.
*/
- (BOOL) containsReferenceToObject: (AdModelObject*) anObject;
/**
Returns an array containing all the references
*/
- (NSArray*) references;
/**
Returns the \e index'th reference in the project.
Raises an NSInvalidArgumentException if \e index is beyond the range of the
receiver.
*/
- (NSDictionary*) referenceAtIndex: (unsigned int) index;
/**
Returns all references to objects of \e className.
\e className must be a subclass of AdModelObject.
The method returns an empty array if there are no objects of \e className.
It returns nil if \e className is not a subclass of AdModelObject.
*/
- (NSArray*) referencesForClass: (NSString*) className;
/**
Returns the number of references in the receiver
*/
- (unsigned int) count;
/**
Returns the number of references to objects of \e className.
Raises an NSInvalidArgumentException if \e className is not a subclass of
AdModelObject.
*/
- (unsigned int) countForClass: (NSString*) className;
/**
Sets if this project is contained by other projects.
 */
- (void) setRootProject: (BOOL) value;
/**
Returns YES if this is a root project, no otherwise.
 */
- (BOOL) isRootProject;

@end

#endif
