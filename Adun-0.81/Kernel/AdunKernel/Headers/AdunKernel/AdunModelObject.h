/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2006-06-26 17:34:11 +0200 by michael johnston

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

#ifndef _ADMODELOBJECT_H_
#define _ADMODELOBJECT_H_

#include <Foundation/Foundation.h>
#include "AdunKernel/AdunDefinitions.h"

/**
\ingroup frameworkTypes
AdMetadataDomain defines the different domains that can be
assigned to the metadata keys of an AdModelObject instance.
See the \ref meta "Metadata" section of the AdModelObject class documentation
for more.
*/ 
typedef enum
{
	AdNoMetadataDomain = 1,		/**< The metadata has no domain associated with it*/
	AdSystemMetadataDomain = 2,	/**< Metadata created and editable by the program */
	AdUserMetadataDomain = 4,	/**< Metadata created and editable by users */	
	AdPropertiesMetadataDomain = 8,	/**< Uneditable metadata created by the object on instantiation**/
}
AdMetadataDomain;

/**
\ingroup Inter
Superclass for objects that can be stored to a database.
AdModelObject gives metadata and input/output reference management
abilities to its subclasses aswell as a globally unique identification 
assigned on initialisation. AdModelObject conforms to the NSCoding
protocol and supports both keyed and non-keyed coding.

\section meta Metadata

AdModelObject allows two types of metadata to be associated with an object,
peristent and volatile. Persistent metadata is stored and retrieved when
an object is archived/unarchived while volatile metadata only exists 
when an object is in memory i.e. it is discarded when the object is archived.
An example of persistent metadata is the database where the object is stored while
an example of volatile metadata is the client that was used to retrieve the object.

Persistent metadata can be assigned to three different domains - AdPropertiesMetadataDomain,
AdSystemMetadataDomain and AdUserMetadataDomain. 
These domains are defined by #AdMetadataDomain.
Properties domain metadata is created when the object is instantiated and is immutable.
System domain metadata is assigned by the program and should not be changed by users. 
User domain metadata is anything that the user can create or edit. A metadata key must be unique
across all domains.

Subclasses of AdModelObject automatically have the following metadata keys. The values corresponding
to the keys in AdSystemMetadataDomain and AdUserMetadataDomain are initially set to "None".

- Properties Domain
	- AdObjectIdentification
		- A globally unique id generated on initialisation.
	- AdObjectCreationDate
		- A formatted string specifying the date and time at which the object was initialised 
	- AdObjectCreator.
		- The person, as indentified by NSFullUserName, who created the object i.e. who was running
		the program
	- AdObjectClass
		- The objects class as a string.
- System Domain
	- Database
		- The database in which the object is stored
	- Schema
		- The schema of the database in which the object is stored
- User Domain
	- Name
		- The objects non-unique user defined name
	- Keywords
		- An array of string associated with the object

Metadata can be accessed through the systemMetadata(), userMetadata(), properties() and allMetadata() methods.
In addition the convenience methods 

- created() 
- creator() 
- identification() 
- name() 
- keywords() 
- database() 
- schema() 

return the values associated with the above quantities.

\note 
created() returns an NSDate object rather than the formatted string found in the properties dictionary.

\section Copying

AdModelObject descendants which conform to NSCopying and/or NSMutableCopying hold to the follow conventions 
- Immutable copies copy all references, properties and metadata
- Mutable copies do not copy any metadata or references

If you want mutable copies to have the same metadata or references you must explicitly do so yourself.
The methods copyMetadataInDomains:fromObject:(), copyInputReferencesFromObject:() and 
copyOutputReferencesFromObject:() provide easy ways to do so.

\todo ExtraFunctionality - Implement isEqual: to return YES if two AdModelObject subclass instances
have the same unique ID.
\note Here "Database" refers to enough information to uniquely specify the database. i.e. not just the
database name.
This is usually equal to the value returned by e.g. ULFileSystemDatabaseBackend::databaseIdentifier
*/
@interface AdModelObject : NSObject <NSCoding>
{
	@protected
	NSDate* date;
	NSMutableDictionary* properties; 	//!< Stuff you cant change
	NSMutableDictionary* userMetadata; 	//!< Stuff you can change
	NSMutableDictionary* systemMetadata;
	NSMutableDictionary* inputReferences;
	NSMutableDictionary* outputReferences;
	NSMutableDictionary* volatileMetadata;
	NSString* identification;
}
/**
Archives the object to \e directory. The resulting
file has the same name as the objects identification.
*/
- (BOOL) archiveToDirectory: (NSString*) path;
/**
Unarchives a previously archived model object from \e file
*/
+ (id) unarchiveFromFile: (NSString*) file;
/**
Returns the unique string identifier for this object
*/
- (NSString*) identification;
/**
Returns the creator of this object (as determined by the username)
*/
- (id) creator;
/**
Returns the date this object was created
*/
- (id) created;
/**
Returns the (non-unique) name associated with the object.
*/
- (NSString*) name;
/**
Returns an array of strings, each representing a keyword, associated with this object.
*/
- (id) keywords;
/**
Returns the name of the database the object is stored in i.e. was unarchived from.
This should be include enough information to specify its location e.g databaseName@host.
*/
- (NSString*) database;
/**
Returns the name of the schema in the database that the object is stored in (or nil if 
none)
*/
- (NSString*) schema;
/** 
Returns the objects properties dictionary. The dictionary keys are described \ref meta "here"
*/
- (NSDictionary*) properties;
/**
Returns a dictionary containing the system metadata keys and values.
*/
- (NSDictionary*) systemMetadata;
/**
Returns a dictionary containing the user metadata keys and values.
*/
- (NSDictionary*) userMetadata;
/**
Returns a dictionary containing properties, system and user metadata. 
Note: volatile metadata is not included.
*/
- (NSDictionary*) allMetadata;
/**
Returns the value for the metadata key \e aString or nil
if the key doesnt exist.
*/
- (id) valueForMetadataKey: (NSString*) aString;
/**
Sets the value for the metadata key \e aString to \e value.
The metadata key is created if it doesnt exist with domain AdSystemMetadataDomain.
Does nothing if the key is in AdPropertiesMetadataDomain.
*/
- (void) setValue: (id) value forMetadataKey: (NSString*) aString;
/**
Sets the value for the metadata key \e aString to \e value.
The metadata key is created if it doesnt exist. The domain can be any value defined by #AdMetadataDomain
however in the case of AdNoMetadataDomain and AdPropertiesMetadataDomain this method does nothing.
If \e aDomain is not one of these an NSInvalidArgumentException is raised.
\note
Key's are unique across both domains i.e. you cant have the
same key in both domains. An attempt to add an already existing key to another domain results
in an NSInternalInconsistencyException being raised.
*/
- (void) setValue: (id) value forMetadataKey: (NSString*) aString inDomain: (AdMetadataDomain) aDomain;
/**
Removed the metadata key \e aString from the object. Does nothing
if the key doesnt exist. If the key is in AdPropertiesMetadataDomain this
method does nothing.
*/
- (void) removeMetadataKey: (NSString*) aString;
/**
Returns the domain associated with \e aString. Return nil if
the key does not exist.
*/
- (AdMetadataDomain) domainForMetadataKey: (NSString*) aString;
/**
Sets the domain for \e aKey to \e aDomain. Domain can be any value defined by AdMetadataDomain
however passing AdNoMetadataDomain and AdPropertiesMetadataDomain will have no effect.
If its not an NSInvalidArgumentException is raised.
If \e aKey does not exist this method has no effect.
*/
- (void) setDomain: (AdMetadataDomain) aDomain forMetadataKey: (NSString*) aKey;
/**
As updateMetadata:inDomains:() passing a bitwise or of the valid domains for \e domainMask.
*/
- (void) updateMetadata: (NSDictionary*) values;
/**
Updates the objects persistent metadata in the domains defined by \e domainMask
with the values in \e values. \e domainMask is a bitwise or of valid domains.
\e values is a dictionary whose keys are metdata names. 
The objects associated with each key are the new metadata values. Keys which do
not refer to current metadata keys are ignored.
Note value in AdPropertiesMetadataDomain cannot be changed however specifying it
in the domainMask will not raise an exception.
*/
- (void) updateMetadata: (NSDictionary*) values inDomains: (int) domainMask;
/**
Returns the value for the volatile metadata key \e aString or nil
if the key doesnt exist.
*/
- (id) valueForVolatileMetadataKey: (NSString*) aString;
/**
Sets the value for the volatile metadata key \e aString to \e value.
The metadata key is created if it doesnt exist
*/
- (void) setValue: (id) value forVolatileMetadataKey: (NSString*) aString;
/**
Removed the volatile metadata key \e aString from the object. Does nothing
if the key doesnt exist.
*/
- (void) removeVolatileMetadataKey: (NSString*) aString;
/**
As inputReferences() but only including dictionaries whose value for 
the key Class is equal to \e className
*/
- (NSArray*) inputReferencesToObjectsOfClass: (NSString*) className;
/**
Returns an array of dictionaries, one for each object that
the receiver was created using. Each dictionary has two keys

- Identification - The id of the object
- Class - Its class 
*/
- (NSArray*) inputReferences;
/**
Adds an input reference for the object \e obj. If \e obj does not respond to identification() this method
raises an NSInvalidArgumentException
*/
- (void) addInputReferenceToObject: (id) obj;
/**
Adds the ID given by \e ident to the list of object ids of type \e type that generated this model object
*/
- (void) addInputReferenceToObjectWithID: (NSString*) ident 
		ofType: (NSString*) type;
/**
Removes the input reference for the object \e obj. If \e obj does not respond to identification() this method
raises an NSInvalidArgumentException. If no reference to \e obj exists this method does nothing.
*/
- (void) removeInputReferenceToObject: (id) obj;
/**
Removes the ID given by \e aString from the list of object ids of type \e type that generated this
model object.
*/
- (void) removeInputReferenceToObjectWithID: (NSString*) ident ofType: (NSString*) type;
/**
As outputReferences() but only including dictionaries whose value for 
the key Class is equal to \e className
*/
- (NSArray*) outputReferencesToObjectsOfClass: (NSString*) className;
/**
Returns an array of dictionaries, one for each object that
was created using the receiver. Each dictionary has two keys

- Identification - The id of the object
- Class - Its class 
*/
- (NSArray*) outputReferences;
/**
Adds an output reference for the object \e obj. If \e obj does not respond to identification() this method
raises an NSInvalidArgumentException
*/
- (void) addOutputReferenceToObject: (id) obj;
/**
Adds the ID given by \e aString to the list of object ids of type \e type that were 
generated by this model object.
*/
- (void) addOutputReferenceToObjectWithID: (NSString*) ident 
		ofType: (NSString*) type;
/**
Removes the output reference for the object \e obj. If \e obj does not respond to identification() this method
raises an NSInvalidArgumentException. If no reference to \e obj exists this method does nothing.
*/
- (void) removeOutputReferenceToObject: (id) obj;
/**
Removes the ID given by \e aString from the list of object ids of type \e type that were
generated by this model object. \e type can be nil but the method will take longer to execute.
*/
- (void) removeOutputReferenceToObjectWithID: (NSString*) ident ofType: (NSString*) type ;
/**
As AdModelObject::removeOutputReferenceToObjectWithID:ofType:() with a nil value for \e type
*/
- (void) removeOutputReferenceToObjectWithID: (NSString*) ident;
/**
Removes all output references stored in the receiver
*/
- (void) removeAllOutputReferences;
/**
Copies the metadata in the domains given by \e domainMask of \e object to
the receiver. Pass AdPropertiesMetadataDomain as part of the mask has no effect.
Only AdSystemMetadataDomain and AdUserMetadataDomain can be copied.
*/
- (void) copyMetadataInDomains: (int) domainMask fromObject: (id) object;
/**
Adds \e objects input references to the receiver.
*/
- (void) copyInputReferencesFromObject: (id) object;
/**
Adds \e objects output references to the receiver.
*/
- (void) copyOutputReferencesFromObject: (id) object;
/**
\note Deprecated. Use addOutputReferenceToObjectWithID:ofType:()
*/
- (void) addOutputReferenceToObjectWithID: (NSString*) ident 
		name: (NSString*) objectName
		ofType: (NSString*) type
		inSchema: (NSString*) schema
		ofDatabase: (NSString*) databaseName;
/**
\note Deprecated. Use addInputReferenceToObjectWithID:ofType:()
*/
- (void) addInputReferenceToObjectWithID: (NSString*) ident 
		name: (NSString*) objectName
		ofType: (NSString*) type
		inSchema: (NSString*) schema
		ofDatabase: (NSString*) databaseName;
@end

@interface AdModelObject (OldMetadataMethods)
/**
Returns a dictionary with two keys \e "General" and \e "Metadata" each of which
is also a dictionary. 
\note Deprecated
*/
- (NSMutableDictionary*) dataDictionary;
/**
Returns a dictionary containing the persisten metadata name:value pairs. This is the same dictionary obtained
through the key \e "Metatdata" of the dictionary returned by dataDictionary().
\note Deprecated - use allMetadata instead.
*/
- (NSMutableDictionary*) metadata;
/**
Returns a dictionary containing the user & system metadata keys along with the properties keys.
\note volatile metadata is not included.
\note Deprecated - Properties and metadata should be treated distinctly
*/
- (NSMutableDictionary*) allData;

@end


//Declarations of Property dict keys.
//Access object properties in the object properties dictionary.
extern NSString* AdObjectIdentification;
extern NSString* AdObjectCreator;
extern NSString* AdObjectCreationDate;
extern NSString* AdObjectClass;


#endif // _ADMODELOBJECT_H_

