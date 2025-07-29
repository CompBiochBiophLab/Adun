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

#include "ULFramework/ULTemplate.h"

static NSMutableDictionary* templates;
static NSArray* propertyListObjects;

@interface ULTemplate (PrivateObjectAdditions)
- (void) _addObjectTemplate: (NSDictionary*) aDictionary 
		withName: (NSString*) stringOne 
		toSection: (NSString*) stringTwo;
- (NSString*) _sectionForClass: (NSString*) className;
/**
Updates the list of non-resolved references in the template.
Used when adding a template for the first time.
*/
- (void) _updateExternalReferencesWith: (NSDictionary*) aDictionary 
		name: (NSString*) name;
- (void) _updateAllExternalReferences;
- (NSString*) _nameForTemplate: (NSDictionary*) aDictionary;
@end

@implementation ULTemplate (PrivateObjectAdditions)

- (void) _updateExternalReferencesWith: (NSDictionary*) aDictionary name: (NSString*) name
{
	NSEnumerator* referenceKeysEnum, *contentsEnum;
	NSString* key;
	id value;

	//Check direct reference keys
	referenceKeysEnum = [[aDictionary referenceKeys] objectEnumerator];
	while((key = [referenceKeysEnum nextObject]))
	{
		value = [aDictionary valueForTemplateKey: key];
		if(value != nil && ![value isEqual: @""])
		{
			if([objectTemplates objectForKey: value] == nil)
			{
				if(![externalReferences containsObject: value])
				{
					[externalReferences addObject: value];
					[externalReferenceTypes setObject: 
						[aDictionary typesForKey: key]
						forKey: value];
				}		
			}
		}	
	}	

	//Check keys whose values are containers which contain references
	referenceKeysEnum = [[aDictionary referenceContainerKeys] objectEnumerator];
	while((key = [referenceKeysEnum nextObject]))
	{
		contentsEnum = [[aDictionary valueForTemplateKey: key] objectEnumerator];
		while((value = [contentsEnum nextObject]))
			if([objectTemplates objectForKey: value] == nil)
				if(![externalReferences containsObject: value])
				{
					[externalReferences addObject: value];
					[externalReferenceTypes setObject: 
						[aDictionary typesForKey: key]
						forKey: value];
				}		
	}

	/*
	 * Remove any external refernce to name
	 */
	if([externalReferences containsObject: name])
	{
		[externalReferences removeObject: name];
		[externalReferenceTypes removeObjectForKey: name];
	}	
}

- (void) _updateAllExternalReferences
{
	NSEnumerator* templateEnum;
	NSString* name;
	
	[externalReferences removeAllObjects];
	[externalReferenceTypes removeAllObjects];
	templateEnum = [objectTemplates keyEnumerator];
	while((name = [templateEnum nextObject]))
		[self _updateExternalReferencesWith: 
				[objectTemplates objectForKey: name]
			name: name];

}

- (NSString*) _sectionForClass: (NSString*) className
{
	BOOL found = NO;
	NSEnumerator* sectionEnum, *sectionTemplatesEnum;
	NSString* sectionName;
	NSDictionary* template, *sectionTemplates;

	sectionEnum = [sections keyEnumerator];
	while(!found &&  (sectionName = [sectionEnum nextObject]))
	{
		sectionTemplates = [templates objectForKey: sectionName];
		sectionTemplatesEnum = [sectionTemplates objectEnumerator];
		while((template = [sectionTemplatesEnum nextObject]))
			if([[template templateClass] isEqual: className])
			{
				found = YES;
				break;
			}
	}		

	if(!found)
	{
		//Every template should have an associated section
		//This indicates a programming error somewhere.
		[NSException raise: NSInternalInconsistencyException
			format: @"Unable to find category for class %@", className];
	}		

	return sectionName;
}

- (void) _addObjectTemplate: (NSDictionary*) aDictionary 
		withName: (NSString*) stringOne 
		toSection: (NSString*) stringTwo;
{
	int number;
	NSNumber* value;
	NSString* className;
	NSMutableDictionary* template;

	if(aDictionary == nil)
		return;

	if(![NSDictionary isValidTemplate: aDictionary])
	{
		[NSException raise: NSInvalidArgumentException
			format: @"Dictionary %@ is not a valid template", aDictionary];
		return;
	}	

	//Have to handle case of new configuration generator or controller
	if([stringOne isEqual: @"controller"] || [stringOne isEqual: @"configurationGenerator"])
	{
		template = [objectTemplates objectForKey: stringOne];
		if(template != nil)
			[classNumberTracker removeObjectForKey:
				[template objectForKey: className]];
	}

	template = [[aDictionary mutableCopy] autorelease];
	[objectTemplates setObject: template
		forKey:  stringOne];

	//FIXME: We could deprecate specification of sections
	//Get section name if none supplied
	className = [aDictionary templateClass];
	if(stringTwo == nil)
		stringTwo = [self _sectionForClass: className];
	
	[[sections objectForKey: stringTwo]
		setObject: template
		forKey: stringOne];
	
	//Update classNumberTracker
	
	value = [classNumberTracker objectForKey: className];
	if(value == nil)
		number = 1;
	else
		number = [value intValue] + 1;
		
	[classNumberTracker setObject: [NSNumber numberWithInt: number]
		forKey: className];

	[self _updateExternalReferencesWith: aDictionary name: stringOne];	
}	

- (NSString*) _nameForTemplate: (NSDictionary*) aDictionary
{
	int number;
	NSNumber* value;
	NSString* className, *name, *section, *displayName;

	className = [aDictionary templateClass];
	section = [self _sectionForClass: className];
	
	/*
	 * Handle the configuration generator and controller
	 */
	if([section isEqual: @"controller"])
		return @"controller";
	else if([NSClassFromString(className) 
			isSubclassOfClass: [AdConfigurationGenerator class]])
		return @"configurationGenerator";

	value = [classNumberTracker objectForKey: className];
	if(value == nil)
		number = 1;
	else
		number = [value intValue] + 1;
		
	displayName = [aDictionary displayName];	
	name = [NSString stringWithFormat: @"%@%@%d",
			[[displayName substringToIndex: 1] lowercaseString],
			[displayName substringFromIndex:1], 
			number];

	return name;	
}

@end

@implementation ULTemplate

+ (void) initialize
{
	static BOOL done = NO;
	BOOL isDir;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *controllerDirEnum;
	NSString *controllerName, *path, *controllerDir, *optionsFile;
	id options;
	NSBundle* bundle;
	NSString* templateFile;

	if(!done)
	{
		templateFile = [[[NSBundle bundleForClass: [self class]] resourcePath] 	
				stringByAppendingPathComponent: @"objectTemplates.plist"];
		templates = [NSMutableDictionary dictionaryWithContentsOfFile: templateFile];
		[templates retain];

		//Now read controller information
		[templates setObject: [NSMutableArray array] forKey: @"controller"];
		controllerDir = [[[ULIOManager appIOManager] applicationDir]
					stringByAppendingPathComponent: @"Plugins/Controllers"];
		controllerDirEnum = [[fileManager directoryContentsAtPath: controllerDir]
					objectEnumerator];
		while((controllerName = [controllerDirEnum nextObject]))
		{
			path = [controllerDir stringByAppendingPathComponent: controllerName];
			[fileManager fileExistsAtPath: path isDirectory: &isDir];
			if(isDir)
			{
				//retrieve the controller options dict
				bundle = [NSBundle bundleWithPath: path];
				optionsFile = [[bundle resourcePath] stringByAppendingPathComponent:
						@"controllerOptions.plist"];
				options = [NSDictionary dictionaryWithContentsOfFile: optionsFile];
				if(options == nil)
					NSWarnLog(@"Controller %@ contains no options file", controllerName);
				else
				{
					options = [[options mutableCopy] autorelease];
					[options setObject: controllerName
						forKey: @"Class"];
					[[templates objectForKey: @"controller"]
						addObject: options];
				}
			}	
		}	

		propertyListObjects = [NSArray arrayWithObjects:
					@"NSString",
					@"NSDictionary",
					@"NSArray",
					@"NSNumber",
					@"NSDate",
					nil];
		[propertyListObjects retain];			
		done = YES;
	}	
}

/**
Returns an array containing templates for all system components
*/
+ (NSArray*) systemObjectTemplates
{
	return [[[templates objectForKey: @"system"]
	    	copy] autorelease];
}

/**
Returns an array containing templates for all force field components
*/
+ (NSArray*) forceFieldObjectTemplates
{
	return [[[templates objectForKey: @"forceField"]
		copy] autorelease];
}

/**
Returns an array containing templates for all configuration generation components
*/
+ (NSArray*) configurationGenerationObjectTemplates
{
	return [[[templates objectForKey: @"configurationGeneration"]
		copy] autorelease];
}

/**
Returns an array containing templates for all available controllers
*/
+ (NSArray*) controllerTemplates
{
	return [[[templates objectForKey: @"controller"]
		copy] autorelease];
}

/**
Returns an array containing the templates for all available objects.
*/
+ (NSArray*) allObjectTemplates
{
	NSMutableArray* anArray = [NSMutableArray array];
	NSEnumerator* sectionEnum;
	id section;

	sectionEnum = [templates objectEnumerator];
	while((section = [sectionEnum nextObject]))
		[anArray addObjectsFromArray: section];

	return [[anArray copy] autorelease];	
}

/**
Returns an array containing templates for all miscellaneous components.
*/
+ (NSArray*) miscellaneousObjectTemplates
{
	return [[[templates objectForKey: @"miscellaneous"]
		copy] autorelease];
}

- (id) init
{
	return [self initWithObjectTemplates: nil];
}

/**
Initialises a new template with the core representation of a previous template
*/
- (id) initWithCoreRepresentation: (NSDictionary*) aDict
{
	NSMutableDictionary* newDict = [NSMutableDictionary dictionary];
	NSMutableDictionary* coreTemplates;
	NSEnumerator* coreEnum;
	NSString* key;
	NSDictionary* template;

	//First remove the collection entries
	coreTemplates = [[aDict objectForKey: @"objectTemplates"] mutableCopy];
	[coreTemplates autorelease];
	[coreTemplates removeObjectForKey: @"forceFieldCollection"];
	[coreTemplates removeObjectForKey: @"systemCollection"];

	coreEnum = [coreTemplates keyEnumerator];
	while((key = [coreEnum nextObject]))
	{	
		template = [NSDictionary templateFromCoreRepresentation: 
				[coreTemplates objectForKey: key]];
		[newDict setObject: template forKey: key];		
	}

	//Convert the core template to object templates
	return	[self initWithObjectTemplates: newDict];
}

- (id) initWithObjectTemplates: (NSDictionary*) aDict
{
	NSEnumerator* nameEnum;
	NSString* name;
	id template;

	if((self = [super init]))
	{
		objectTemplates = [NSMutableDictionary new];
		sections = [NSMutableDictionary new];
		[sections setObject: [NSMutableDictionary new]
			forKey: @"system"];
		[sections setObject: [NSMutableDictionary new]
			forKey: @"forceField"];
		[sections setObject: [NSMutableDictionary new]
			forKey: @"configurationGeneration"];
		[sections setObject: [NSMutableDictionary new]
			forKey: @"miscellaneous"];
		[sections setObject: [NSMutableDictionary new]
			forKey: @"controller"];
		classNumberTracker = [NSMutableDictionary new];
		externalReferenceTypes = [NSMutableDictionary new];
		externalReferences = [NSMutableArray new];

		NS_DURING
		{
			nameEnum = [aDict keyEnumerator];
			while((name = [nameEnum nextObject]))
			{
				template = [aDict objectForKey: name];
				[self _addObjectTemplate: template	
					withName: name
					toSection: nil];
			}		
		}
		NS_HANDLER
		{
			[self release];
			[localException raise];
		}
		NS_ENDHANDLER
	}

	return self;
}

- (void) dealloc
{
	[classNumberTracker release];
	[objectTemplates release];
	[sections release];
	[externalReferences release];
	[externalReferenceTypes release];
	[super dealloc];
}

/**
Returns a representation of the template as a dictionary which can be used
as the input to AdunCore.
*/
- (NSMutableDictionary*) coreRepresentation
{
	NSMutableDictionary* coreRepresentation;
	NSEnumerator* templateEnum;
	NSString* templateName, *className;
	NSDictionary* template;
	NSMutableDictionary *systemCollectionTemplate, *forceFieldCollectionTemplate;

	NSDebugLLog(@"ULTemplate", @"Creating core rep");
	/*
	 * Create an AdForceFieldCollection entry.
	 * Add all AdForceField subclasses
	 * Create an AdSystemCollection entry.
	 * Add all AdSystem and AdInteractionSystem classes
	 */

	forceFieldCollectionTemplate = [NSDictionary dictionaryWithObjectsAndKeys:
					@"AdForceFieldCollection", @"Class",
					[NSMutableArray array], @"forceFields", nil];
	systemCollectionTemplate = [NSDictionary dictionaryWithObjectsAndKeys:
					@"AdSystemCollection", @"Class",
					[NSMutableArray array], @"systems", nil];

	coreRepresentation = [NSMutableDictionary dictionary];
	[coreRepresentation setObject: forceFieldCollectionTemplate
		forKey: @"forceFieldCollection"];
	[coreRepresentation setObject: systemCollectionTemplate
		forKey: @"systemCollection"];
		
	templateEnum =  [objectTemplates keyEnumerator];
	while((templateName = [templateEnum nextObject]))
	{
		template = [objectTemplates objectForKey: templateName];
		className = [template templateClass];
		[coreRepresentation setObject: [template coreTemplateRepresentation]
			forKey: templateName];
			
		if([NSClassFromString(className) isSubclassOfClass: [AdForceField class]])
		{
			[[forceFieldCollectionTemplate objectForKey: @"forceFields"]
				addObject: templateName];
		}
		else if([className isEqual: @"AdSystem"] || 
			[className isEqual: @"AdInteractionSystem"])	
		{
			[[systemCollectionTemplate objectForKey: @"systems"]
				addObject: templateName];
		}		
	}

	//Hook the collections into the configuration generator
	if([coreRepresentation objectForKey: @"configurationGenerator"] != nil)
	{
		[coreRepresentation setValue: @"forceFieldCollection"
			forKeyPath: @"configurationGenerator.forceFields"];
		[coreRepresentation setValue: @"systemCollection"
			forKeyPath: @"configurationGenerator.systems"];
	}		
	
	NSDebugLLog(@"ULTemplate", @"Done");

	return [NSMutableDictionary dictionaryWithObject: coreRepresentation
		forKey: @"objectTemplates"];
}

/**
Returns a dictionary containing all the object templates the template contains
*/
- (NSDictionary*) objectTemplates
{
	return [[objectTemplates copy] autorelease];
}

- (NSDictionary*) objectTemplatesOfClass: (NSString*) className
{
	NSWarnLog(@"Not implemented - %@", NSStringFromSelector(_cmd));
	return nil;
}

/**
Returns a dictionary containing all the object templates assigned to a given section
*/
- (NSDictionary*) objectTemplatesInSection: (NSString*) aString
{
	return [[[sections objectForKey: aString]
		copy] autorelease];
}

/**
Returns the object template corresponding to name or nil if there is none.
*/
- (NSDictionary*) objectTemplateWithName: (NSString*) aString
{
	return [[[objectTemplates objectForKey: aString]
			copy] autorelease];
}

/**
Sets the value for the object template associated with \e name to those in \e aDictionary
*/
- (void) setValues: (NSDictionary*) aDictionary forObjectTemplateWithName: (NSString*) name
{
	id template;
	NSEnumerator* keyEnum;
	id key;

	template = [objectTemplates objectForKey: name];
	keyEnum = [aDictionary keyEnumerator];
	while((key = [keyEnum nextObject]))
		[template setValue: [aDictionary objectForKey: key]
			forTemplateKey: key];

	//Might be a better way 
	[self _updateAllExternalReferences];
}

/**
Returns the values for the object template associated with \e name
*/
- (NSDictionary*) valuesForObjectTemplateWithName: (NSString*) name
{
	id dict;
	
	dict = [objectTemplates objectForKey: name];
	return [dict valuesForTemplateKeys];
}

- (NSArray*) externalReferences
{
	return [[externalReferences copy] autorelease];
}

- (NSDictionary*) externalReferenceTypes
{	
	return [[externalReferenceTypes copy] autorelease];
}

- (BOOL) validateTemplate: (NSError**) error
{
	BOOL isValid=YES;
	NSEnumerator* objectTemplatesEnum;
	NSDictionary* objectTemplate;
	NSArray* names;

	objectTemplatesEnum = [objectTemplates objectEnumerator];
	names = [objectTemplates allKeys];
	while((objectTemplate = [objectTemplatesEnum nextObject]))
	{
		isValid = [objectTemplate validate: error];
		if(!isValid)
			break;
	}

	return isValid;
}

//Can change to use initWithObjectTemplates
- (id) copyWithZone: (NSZone*) aZone
{
	id object;
	
	if(![self isMemberOfClass: [ULTemplate class]])
		return [[ULTemplate allocWithZone: aZone]
			initWithCoreRepresentation: [self coreRepresentation]];

	if(aZone == NULL || aZone == NSDefaultMallocZone())
		return [self retain];
	else
	{
		object = [[ULTemplate allocWithZone: aZone]
				initWithCoreRepresentation: [self coreRepresentation]];
		//Add special flag to force copying of properties
		//Add AdPropertiesMetadataDomain itself does nothing
		[object copyMetadataInDomains: 
				AdSystemMetadataDomain | AdUserMetadataDomain | 1024
			fromObject: self];
		[object copyInputReferencesFromObject: self];	
		[object copyOutputReferencesFromObject: self];	
		return object;
	}	
}

- (id) mutableCopyWithZone: (NSZone*) aZone
{
	return [[ULMutableTemplate allocWithZone: aZone]
		initWithCoreRepresentation: [self coreRepresentation]];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	[super initWithCoder: decoder];

	if([decoder allowsKeyedCoding])
	{
		objectTemplates = [decoder decodeObjectForKey: @"ObjectTemplates"];
		sections = [decoder decodeObjectForKey: @"Sections"];
		classNumberTracker = [decoder decodeObjectForKey: @"NumberTracker"];
		externalReferences = [decoder decodeObjectForKey: @"ExternalReferences"];
		externalReferenceTypes = [decoder decodeObjectForKey: @"ExternalReferenceTypes"];
		[externalReferences retain];
		[externalReferenceTypes retain];
		[objectTemplates retain];
		[sections retain];
		[classNumberTracker retain];
	}
	else
	{
		NSWarnLog(@"%@ does not support non-keyed coding",
			[self class]);
		return nil;

	}

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeObject: objectTemplates 
			forKey: @"ObjectTemplates"];
		[encoder encodeObject: sections
			forKey: @"Sections"];
		[encoder encodeObject: classNumberTracker
			forKey: @"NumberTracker"];
		[encoder encodeObject: externalReferences
			forKey: @"ExternalReferences"];
		[encoder encodeObject: externalReferenceTypes
			forKey: @"ExternalReferenceTypes"];
	}
	else
		NSWarnLog(@"%@ does not support non-keyed coding",
			[self class]);
		
	[super encodeWithCoder: encoder];	
}

@end

@implementation ULMutableTemplate


/**
Adds an object template to the receiver and the given section.
This overrides the default section for the template.
An name is automatically generated for the new object.
*/
- (NSString*) addObjectTemplate: (NSDictionary*) aDictionary 
		toSection: (NSString*) stringTwo;
{
	NSString* name;

	name = [self _nameForTemplate: aDictionary];

	[self _addObjectTemplate: aDictionary
		withName: name 
		toSection: stringTwo];
	
	return name;	
}	

/**
Adds the template defined by \e aDictionary and generates a name
for it which is returned.
*/
- (NSString*) addObjectTemplate: (NSDictionary*) aDictionary
{
	return [self addObjectTemplate: aDictionary
			toSection: nil];
}

/**
Removes the object template associated with \e stringOne. 
\e stringOne can afterwards be associated with another template
*/
- (void) removeObjectTemplateWithName: (NSString*) stringOne 
{
	NSDictionary* template;
	NSString* section;

	template = [objectTemplates objectForKey: stringOne];
	[objectTemplates removeObjectForKey: stringOne];

	section = [self _sectionForClass: [template templateClass]];
	[[sections objectForKey: section] 
		removeObjectForKey: stringOne];

	[self _updateAllExternalReferences];
}

@end


@implementation NSDictionary (ULObjectTemplateExtensions)

/**
Checks if the provided dictionary is in the Adun template format
and is a template of a known object.
*/
+ (BOOL) isValidTemplate: (NSDictionary*) aDict;
{
	if([aDict objectForKey: @"Class"] == nil)
		return NO;

	if([NSDictionary templateForClass: [aDict objectForKey: @"Class"]] == nil)
		return NO;

	return YES;	
}		

/**
Returns the template for \e className
*/
+ (id) templateForClass: (NSString*) className
{
	BOOL foundTemplate = NO;
	NSEnumerator* templateEnum;
	NSData* propertyData;
	id template;
	
	templateEnum = [[ULTemplate allObjectTemplates]
			objectEnumerator];
	while((template = [templateEnum nextObject]))
		if([[template objectForKey: @"Class"] isEqual: className])
		{
			foundTemplate = YES;
			break;
		}	

	if(foundTemplate)
	{
		//Need to get a deep mutable copy
		propertyData = [NSPropertyListSerialization dataFromPropertyList: template
					format: NSPropertyListXMLFormat_v1_0
					errorDescription: NULL];
		template = [NSPropertyListSerialization propertyListFromData: propertyData
				mutabilityOption: NSPropertyListMutableContainers
				format: NULL
				errorDescription: NULL];
		return template;
	}	
	else
		return nil;
}

/**
Returns the template for \e displayName
*/
+ (id) templateForDisplayName: (NSString*) displayName 
{
	BOOL foundTemplate = NO;
	NSEnumerator* templateEnum;
	NSData* propertyData;
	id template;
	
	templateEnum = [[ULTemplate allObjectTemplates]
			objectEnumerator];
	while((template = [templateEnum nextObject]))
		if([[template objectForKey: @"DisplayName"] isEqual: displayName])
		{
			foundTemplate = YES;
			break;
		}	

	if(foundTemplate)
	{
		//Need to get a deep mutable copy
		//Use propery list serializations
		propertyData = [NSPropertyListSerialization dataFromPropertyList: template
					format: NSPropertyListXMLFormat_v1_0
					errorDescription: NULL];
		template = [NSPropertyListSerialization propertyListFromData: propertyData
				mutabilityOption: NSPropertyListMutableContainers
				format: NULL
				errorDescription: NULL];
		return template;
	}	
	else
		return nil;
}

+ (id) templateFromCoreRepresentation: (NSDictionary*) dict
{
	NSString* class, *key;
	NSMutableDictionary* template;
	NSEnumerator* templateKeyEnum;
	NSData* propertyData;
	id value;

	class = [dict objectForKey: @"Class"];
	template = [NSMutableDictionary templateForClass: class];
	if(template != nil)
	{
		propertyData = [NSPropertyListSerialization dataFromPropertyList: template
					format: NSPropertyListXMLFormat_v1_0
					errorDescription: NULL];
		template = [NSPropertyListSerialization propertyListFromData: propertyData
				mutabilityOption: NSPropertyListMutableContainers
				format: NULL
				errorDescription: NULL];
		templateKeyEnum = [[template templateKeys] objectEnumerator];
		while((key = [templateKeyEnum nextObject]))
		{
			value = [dict objectForKey: key];
			if([value isKindOfClass: [NSDictionary class]])
				value = [value allValues];
			
			if(value != nil)
				[template setValue: value
					forTemplateKey: key];

		}
	}


	return template;
}

//A simple key has a value directly associated with it
//i.e. there is no metadata.
- (BOOL) isSimpleKey: (NSString*) aKey
{
	id value;

	value = [self objectForKey: aKey];
	if([value isKindOfClass: [NSDictionary class]])
		return NO;
	
	return YES;
}

/**
Validates the current values for the template options.
Only validates options that correspond to property list objects.
*/
- (BOOL) validate: (NSError**) error
{
	BOOL isValid = YES;
	NSEnumerator* keyEnum, *typeEnum;
	NSArray* types;
	NSData* propertyData;
	id key, value, type;

	keyEnum = [[self templateKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
	{
		//Check if the value is simple
		if([self isSimpleKey: key])
			continue;
	
		value = [self valueForTemplateKey: key];
		if((value == nil || [value isEqual: @""]) && ![self isOptionalKey: key])
		{
			isValid = NO;
			NSWarnLog(@"No value supplied for key %@", key);
			if(error != NULL)
			{
				*error = AdCreateError(ULFrameworkErrorDomain,
						ULTemplateValidationError,
						@"Template invalid",
						[NSString stringWithFormat: 
							@"No value supplied for key %@ of component %@", 
							key, [self displayName]],
							@"Values must be assigned to all keys");
			}				
			break;
		}	
		
		if([self isPropertyListKey: key])
		{
			if([value isKindOfClass: [NSString class]])
			{
#ifdef NeXT_Foundation_LIBRARY			
				//Single length strings need to be quoted using Cocoa
				//or they aren't decoded properly - probably a bug
				if([value length] == 1)
					value = [NSString stringWithFormat: @"\"%@\"", value];
#endif
				propertyData = [value dataUsingEncoding: NSASCIIStringEncoding];
				value = [NSPropertyListSerialization propertyListFromData: propertyData
						mutabilityOption: NSPropertyListImmutable
						format: NULL
						errorDescription: NULL];
			}			
			types = [self typesForKey: key];
			isValid = NO;
			typeEnum = [types objectEnumerator];
			while((type = [typeEnum nextObject]))
			{
				if([value isKindOfClass: NSClassFromString(type)])
				{
					isValid = YES;
					break;
				}
				else if(([value isEqual: @""] || value == nil)
						&& [self isOptionalKey: key])
				{
					isValid = YES;
					break;
				}
			}	
	
			if(!isValid)
			{
				NSWarnLog(@"%@ is not a valid type for option %@",
					[value class],
					key);
				if(error != NULL)
				{
					*error = AdCreateError(ULFrameworkErrorDomain,
						ULTemplateValidationError,
						@"Template invalid",
						[NSString stringWithFormat: 
							@"%@ is not a valid type for option %@ (Component %@)",
							[value class], key, [self displayName]],
						[NSString stringWithFormat: 
							@"The allowed types are %@", types]);
				}			
			}		
		}
	}	

	return isValid;
}

/**
Returns an array containing the valid classes for \e aKey
*/
- (NSArray*) typesForKey: (NSString*) aKey
{
	id value = nil;

	if(![self isSimpleKey: aKey])
		value = [[self objectForKey: aKey]
				objectForKey: @"type"];

	return value;			
}

/**
Returns a sorted array of the template keys i.e. options values.
*/
- (NSArray*) templateKeys
{
	NSMutableArray* keys;

	keys = [[[self allKeys] mutableCopy] autorelease];
	[keys removeObject: @"Class"];
	[keys removeObject: @"DisplayName"];
	[keys removeObject: @"Description"];

	return [keys sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
}

/**
Returns YES if the class \e type can be used aassociated with \e aKey.
*/
- (BOOL) validateType: (NSString*) type forKey: (NSString*) aKey
{
	NSArray* types;

	types = [self typesForKey: aKey];
	if([types containsObject: type])
		return YES;
	else
		return NO;
}

/**
Returns a user friendly version of the templates class name.
Defaults to the class name if their is no display name
*/
- (NSString*) displayName
{
	NSString* name;

	name = [self objectForKey: @"DisplayName"];
	if(name == nil)
		name = [self objectForKey: @"Class"];

	return name;	
}

/**
Returns the name of the class associated with this template-
*/
- (NSString*) templateClass
{
	return [self valueForKey: @"Class"];
}

- (BOOL) isOptionalKey: (NSString*) aKey
{
	id type, value;
	
	type = [self objectForKey: aKey];
	if([type isKindOfClass: [NSDictionary class]])
	{
		value = [[self objectForKey: aKey]
				objectForKey: @"optional"];
		if(value == nil)
			return NO;
		else
			return [value boolValue];
	}		
	else
		return NO;
}

/**
Returns a short description of the object
*/
- (NSString*) templateDescription
{
	return [self objectForKey: @"Description"];
}

- (NSString*) descriptionForKey: (NSString*) key
{
	if([self isSimpleKey: key])
		return nil;
	else
		return [[self objectForKey: key]
			objectForKey: @"Description"];
	
}

- (id) valueForTemplateKey: (NSString*) aKey
{
	id value;
	
	//Check type for the key - i.e. is a simple value
	//or a metadata value
	if(![self isSimpleKey: aKey])
		value = [[self objectForKey: aKey]
			objectForKey: @"value"];
	else
		value = [self objectForKey: aKey];

	if(value == nil)
		value = @"";

	return value;	
}	

- (NSMutableDictionary*) valuesForTemplateKeys
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	NSEnumerator* keyEnum;
	id key;

	keyEnum = [[self templateKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
		[dict setObject: [self valueForTemplateKey: key]
			forKey: key];
	
	return dict;
}

/**
Returns yes if all the types associated with \e key
are property list objects.
*/
- (BOOL) isPropertyListKey: (NSString*) key
{
	BOOL isPropertyListKey = YES;
	NSArray* types;
	NSEnumerator* typeEnum;
	id type;

	types = [self typesForKey: key];	
	if(types != nil)
	{
		//Check they are all property list objects
		isPropertyListKey = YES;
		typeEnum = [types objectEnumerator];
		while((type = [typeEnum nextObject]))
			if(![propertyListObjects containsObject: type])
			{
				isPropertyListKey = NO;
				break;
			}	

	}

	return isPropertyListKey;
}

/**
All keys whose type is a property list object
*/
- (NSArray*) propertyListKeys 
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* keyEnum;
	NSString* key;
	
	keyEnum = [[self templateKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
		if([self isPropertyListKey: key])
			[array addObject: key];

	return [[array copy] autorelease];
}

/**
All keys whose type is not a property list object
*/
- (NSArray*) referenceKeys
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* keyEnum;
	NSString* key;
	
	keyEnum = [[self templateKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
		if(![self isPropertyListKey: key])
			[array addObject: key];

	return [[array copy] autorelease];
}

- (BOOL) _isReferenceContainerKey: (NSString*) key
{
	id value = nil;

	if(![self isSimpleKey: key])
		value = [[self objectForKey: key]
				objectForKey: @"isReferenceContainer"];
			
	if(value == nil)
		return NO;

	return [value boolValue];
}

/**
All keys whose values are containers which contain
non property list objects.
*/
- (NSArray*) referenceContainerKeys;
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* keyEnum;
	NSString* key;
	
	keyEnum = [[self templateKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
		if([self _isReferenceContainerKey: key])
			[array addObject: key];

	return [[array copy] autorelease];
}

/*
 * FIXME: Cheating when the templates key value
 * should be a dictionary. 
 * We have to do this because dictionaries are used 
 * in a special way to display the menus which 
 * prevents them being used like arrays.
 *
 * We overcome this in the following way -
 * If the template key value should be a dictionary
 * we add a key "isDictionary" to the key dict.
 *
 * The template keys' value is set to be an array and 
 * this is where we store the final dictionary values.
 *
 * When writing the core representation a dictionary is
 * created by atomatically generating keys and associating
 * them with the values in the array.
 * 
 * The string used for the keys can be specified by adding
 * a key "keyString" to the template. The keys will then be
 * called "keyString1", "keyString2" etc.
 */
- (NSMutableDictionary*) _createDictionaryWithValues: (NSArray*) values forKey: (NSString*) key
{
	int numberOfKeys, i;
	NSString* keyString;
	NSMutableArray* keyArray;
	NSDictionary* keyDict;

	keyDict = [self objectForKey: key]; 
	if(![values isKindOfClass: [NSArray class]])
		[NSException raise: NSInternalInconsistencyException
			format: @"Value for dictionary key %@ is not an array"
			, key];

	keyString = [keyDict objectForKey: @"keyString"];
	if(keyString == nil)
		keyString = @"key";

	numberOfKeys = [values count];
	keyArray = [NSMutableArray array];
	for(i=0; i<numberOfKeys; i++)
	{
		[keyArray addObject:
			[NSString stringWithFormat: @"%@%d",
			keyString, i]];
	}		

	return [NSMutableDictionary dictionaryWithObjects: values
			forKeys: keyArray];
}

/**
Returns a dictionary in the valid format for 
the Core template file.
*/
- (NSMutableDictionary*) coreTemplateRepresentation
{
	NSMutableDictionary* representation;
	NSEnumerator* keyEnum;
	id key, value;

	representation = [NSMutableDictionary dictionary];
	keyEnum = [[self templateKeys] objectEnumerator];
	while((key = [keyEnum nextObject]))
	{
		value = [self valueForTemplateKey: key];
		if(value == nil)
			value = @"";
		
		//Special case for dictionaries
		//See _createDictionaryWithValues:forKey: docs for more.
		if(![self isSimpleKey: key])
			if([[self objectForKey: key] objectForKey: @"isDictionary"] != nil)
				value = [self _createDictionaryWithValues: value 
						forKey: key];
		
		[representation setObject: value forKey: key];
	}	
	
	[representation setValue: [self templateClass]
		forKey: @"Class"];

	return representation;
}

@end

@implementation NSMutableDictionary (ULMutableObjectTemplateExtensions)
/**
Returns the template for \e className
*/
+ (id) templateForClass: (NSString*) className
{
	BOOL foundTemplate = NO;
	NSEnumerator* templateEnum;
	id template;
	
	templateEnum = [[ULTemplate allObjectTemplates]
			objectEnumerator];
	while((template = [templateEnum nextObject]))
		if([[template objectForKey: @"Class"] isEqual: className])
		{
			foundTemplate = YES;
			break;
		}	

	if(foundTemplate)
		return [[template mutableCopy] autorelease];
	else
		return nil;
}

- (void) setValue: (id) value forTemplateKey: (NSString*) aKey
{
	id type;
	NSData* propertyData;
	NSString* errorString;
	
	//Check type for the key - i.e. is a simple value
	//or a metadata value
	type = [self objectForKey: aKey];
	if([type isKindOfClass: [NSDictionary class]])
	{
		//value may be a string representation of 
		//a property list object. If so we have to convert
		//it
		if([self isPropertyListKey: aKey])
		{
			if([value isKindOfClass: [NSString class]])
			{
#ifdef NeXT_Foundation_LIBRARY			
				//Single length strings need to be quoted using Cocoa
				//or they aren't decoded properly - probably a bug
				if([value length] == 1)
					value = [NSString stringWithFormat: @"\"%@\"", value];
#endif					
				propertyData = [value dataUsingEncoding: NSASCIIStringEncoding];		
				value = [NSPropertyListSerialization propertyListFromData: propertyData
						mutabilityOption: NSPropertyListImmutable
						format: NULL
						errorDescription: &errorString];	
			}
		}	
		
		[[self valueForKey: aKey] 
			setValue: value forKey: @"value"];
	}		
	else
		[self setValue: value forKey: aKey];
}

@end
