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

#ifndef _ULTEMPLATE_
#define _ULTEMPLATE_
#include <Foundation/Foundation.h>
#include <AdunKernel/AdunKernel.h>
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULFrameworkDefinitions.h"

/**
\ingroup classes
ULTemplate instances represent a certain configuration of the AdunCore simulator.
In this case "configuration" is analogous to a UML state diagram of a simulation process. 
Hence "configuration" only refers to the objects that make up the simulator and their 
relationships - object attribute values are not considered when deciding
template equality. ULTemplates objects also contain some general input options for
simulations process e.g. checkpointing, metadata etc.

At any time the current state of the template can be retrieved
as a property list object which can be used as the input to a AdunCore simulation run.
ULTemplate instances are immutable - their configuration is
set on initialisation and cannot be changed afterwards. The ULMutableTemplate 
subclass allows configuration editing.

\section temp Template Sections

There are three main parts in a simulation process - system, force field & configuration generator -
and each of these parts can contain many components. In addition to these known sections a template
instance can containing specifications for an arbitrary number of other objects if desired.


Notes: ULTemplate class contains information on the objects that can be added to the template
along with how they are categorised. Controllers read dynamically on startup. Knows restrictions
on object composition i,e, type restrictions. Kept in a file a read on call to inititialize. 
Automatically adds systems to an AdSystemCollection and forcefields to an AdForceField collection.
Knows about simulator components and custom force field terms.
*/
@interface ULTemplate: AdModelObject <NSCopying, NSMutableCopying, NSCoding>
{
	NSMutableDictionary* objectTemplates;
	NSMutableDictionary* sections;
	NSMutableDictionary* classNumberTracker;
	NSMutableDictionary* externalReferenceTypes;
	NSMutableArray* externalReferences;
}
/**
Returns an array containing templates for all system components
*/
+ (NSArray*) systemObjectTemplates;
/**
Returns an array containing templates for all force field components
*/
+ (NSArray*) forceFieldObjectTemplates;
/**
Returns an array containing templates for all configuration generation components
*/
+ (NSArray*) configurationGenerationObjectTemplates;
/**
Returns an array containing templates for all available controllers
*/
+ (NSArray*) controllerTemplates;
/**
Returns an array containing the templates for all available objects.
*/
+ (NSArray*) allObjectTemplates;
/**
Returns an array containing templates for all miscellaneous components.
*/
+ (NSArray*) miscellaneousObjectTemplates;
/**
Initialises a new ULTemplate instance using the templates and names
in \e templates.
Designated initialiser.
*/
- (id) initWithObjectTemplates: (NSDictionary*) templates;
/**
Initialises a new template with the dictionary representation of a previous template
*/
- (id) initWithCoreRepresentation: (NSDictionary*) aDict;
/**
Returns a representation of the template as a dictionary which can be used
as the input to AdunCore.
*/
- (NSMutableDictionary*) coreRepresentation;
/**
Returns a dictionary containing all the object templates the template contains
*/
- (NSDictionary*) objectTemplates;
/**
Returns a dictionary containing all the object templates assigned to a given section
*/
- (NSDictionary*) objectTemplatesInSection: (NSString*) aString;
/**
Returns the object template corresponding to name or nil if there is none.
*/
- (NSDictionary*) objectTemplateWithName: (NSString*) aString;
/**
Returns all the object templates of a given class
*/
- (NSDictionary*) objectTemplatesOfClass: (NSString*) className;
/**
Returns the external references. An external reference is a when a value
for a template option, whose type is not a property list object , 
does not refer to the any other template in the receiver.
*/
- (NSArray*) externalReferences;
/**
Returns a dictionary containing name:type pairs for the current external references.
*/
- (NSDictionary*) externalReferenceTypes;
/**
Sets the value for the object template associated with \e name to those in \e aDictionary
*/
- (void) setValues: (NSDictionary*) aDictionary forObjectTemplateWithName: (NSString*) name;
/**
Returns the values for the object template associated with \e name
*/
- (NSDictionary*) valuesForObjectTemplateWithName: (NSString*) name;
/**
Validates the template.
*/
- (BOOL) validateTemplate: (NSError**) error;
@end


/**
Mutable subclass of ULTemplate. ULMutableTemplate instances allow
editing of their configuration.
\ingroup classes
*/
@interface ULMutableTemplate: ULTemplate
{
}
/**
Adds an object template to the receiver and the given section.
This overrides the default section for the template.
An name is automatically generated for the new object.
*/
- (NSString*) addObjectTemplate: (NSDictionary*) aDictionary 
		toSection: (NSString*) stringTwo; 
/**
Adds the template defined by \e aDictionary and generates a name
for it which is returned.
*/
- (NSString*) addObjectTemplate: (NSDictionary*) aDictionary;
/**
Removes the object template associated with \e stringOne. 
\e stringOne can afterwards be associated with another template
*/
- (void) removeObjectTemplateWithName: (NSString*) aString;
@end

/**
Extension to NSDictionary so it can be used to represent an
object template as used by AdunCore. 
Like an ordinary dictionary an object template has keys and values.
However the type of object that can be associated with a specific key 
is restricted and is defined by the class the template represents.
Only property list objects can be associated directly to a template key.
Other objects must be associated by reference e.g. by assigning a
string value to them and using this string value as the corresponding key-value.
\ingroup classes
*/
@interface NSDictionary (ULObjectTemplateExtensions)
/**
Checks if the provided dictionary is in the Adun template format
and is a template of a known object.
*/
+ (BOOL) isValidTemplate: (NSDictionary*) aDict;
/**
Returns the template for \e className
*/
+ (id) templateForClass: (NSString*) className;
/**
Returns the template with \e displayName
*/
+ (id) templateForDisplayName: (NSString*) displayName;
/**
Creates a template from a dictionary previously 
returned by coreTemplateRepresentation().
*/
+ (id) templateFromCoreRepresentation: (NSDictionary*) dict;
/**
Validates the current values for the template options.
Only validates options that correspond to property list objects.
*/
- (BOOL) validate: (NSError**) error;
/**
Returns an array containing the valid classes for \e aKey
*/
- (NSArray*) typesForKey: (NSString*) aKey;
/**
Returns YES if the class \e type can be used aassociated with \e aKey.
*/
- (BOOL) validateType: (NSString*) type forKey: (NSString*) aKey;
/**
Returns a user friendly version of the templates class name.
*/
- (NSString*) displayName;
/**
Returns the name of the class associated with this template-
*/
- (NSString*) templateClass;
/**
Returns a sorted array of the template keys i.e. options values.
*/
- (NSArray*) templateKeys;
/**
Returns a short description of the object
*/
- (NSString*) templateDescription;
/**
Returns a short description of the template key
*/
- (NSString*) descriptionForKey: (NSString*) key;
/**
Returns the value for \e aKey
*/
- (id) valueForTemplateKey: (NSString*) aKey;
/**
Returns a dictionary of templateKey:value pairs
*/
- (NSMutableDictionary*) valuesForTemplateKeys;
/**
Returns a dictionary in the valid format for 
the Core template file.
*/
- (NSMutableDictionary*) coreTemplateRepresentation;
/**
Returns yes if all the types associated with \e key
are property list objects.
*/
- (BOOL) isPropertyListKey: (NSString*) key;
/**
Returns NO is key must be given a value.
*/
- (BOOL) isOptionalKey: (NSString*) aKey;
/**
All keys whose type is a property list object
*/
- (NSArray*) propertyListKeys;
/**
All keys whose type is not a property list object
*/
- (NSArray*) referenceKeys;
/**
All keys whose values are containers which contain
non property list objects.
*/
- (NSArray*) referenceContainerKeys;
/**
A simple key has a value directly associated with it
i.e. there is no metadata.
*/
- (BOOL) isSimpleKey: (NSString*) aKey;
@end

@interface NSMutableDictionary (ULMutableObjectTemplateExtensions)
/**
Sets the value for \e aKey to \e value
*/
- (void) setValue: (id) value forTemplateKey: (NSString*) aKey;
@end


#endif
