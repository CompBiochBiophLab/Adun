/*
   Project: AdunCore

   Copyright (C) 2005-2007 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunTemplateProcessor.h"

/**
Although it responds to intValue NSString does not
respond to unsignedIntValue. This is a problem when 
using strings to set number properties. This category
 adds an unsignedIntValue value method to NSString
which simple returns the intValue value cast to an 
unsigned integer.
*/

@interface NSString (AdStringExtensions)
- (unsigned int) unsignedIntValue;
@end

@implementation NSString (AdStringExtensions)

- (unsigned int) unsignedIntValue
{
	return [self intValue];
}

@end

/*
 * Contains the methods used to create objects from the templates in the adun template file.
 */
@interface AdTemplateProcessor (ObjectCreationExtensions)
- (id) instantiateObjectWithTemplate: (NSDictionary*) objectTemplate associateName: (NSString*) name;
@end

@implementation AdTemplateProcessor

/*
 * Loading the controller specified in the template
 */

- (void) _validateController: (NSString*) controllerName fromTemplate: (id*) templatePointer
{
	NSString* controllerDir;
	NSBundle *controllerBundle;
	NSMutableDictionary* templateCopy;
	Class controllerClass; 

	NSDebugLLog(@"AdTemplateProcessor", @"Validating controller %@", controllerName);
	controllerDir = [[AdIOManager appIOManager] controllerDirectory];
	
#ifdef GNUSTEP	
	NSDebugLLog(@"AdTemplateProcessor",
		@"Dynamicaly loading controller from directory: %@",
		 [controllerDir stringByAppendingPathComponent: controllerName]);
	controllerBundle = [NSBundle bundleWithPath: 
				[controllerDir stringByAppendingPathComponent: controllerName]];
#else				
	controllerName = [controllerName stringByAppendingPathExtension: @"bundle"];
	NSDebugLLog(@"AdTemplateProcessor",
		    @"Dynamicaly loading controller from directory: %@",
		    [controllerDir stringByAppendingPathComponent: controllerName]);
	controllerBundle = [NSBundle bundleWithPath: 
			    [controllerDir stringByAppendingPathComponent: controllerName]];
	controllerName = [controllerName stringByDeletingPathExtension];
#endif			    
	
	if(controllerBundle == nil)
	{
		NSWarnLog(@"Specified controller bundle not found. Replacing with AdController.");
		/*
		 * We create a new template with a different controller.
		 * To do this we  have to create a mutable copy of the template,
		 * modify it and finally return a non-mutable copy.
		 */
		templateCopy = [[*templatePointer mutableCopy] autorelease];
		[templateCopy setValue: 
			[NSDictionary dictionaryWithObject: @"AdController" forKey: @"Class"]
			forKey: @"objectTemplates.controller"];
		templateCopy = [[templateCopy copy] autorelease];
		templatePointer = &templateCopy;	
		return;
	}
	
	NSDebugLLog(@"AdTemplateProcessor", @"Searching for main class");
	if((controllerClass = [controllerBundle principalClass]) != nil)
	{ 
		NSDebugLLog(@"AdTemplateProcessor", @"Found main class = %@.", 
			NSStringFromClass(controllerClass));

		NSDebugLLog(@"AdTemplateProcessor", 
			@"Testing if controller class conforms to AdController protocol.");
		if([controllerClass  conformsToProtocol:@protocol(AdController)])
			NSDebugLLog(@"AdTemplateProcessor", @"Controller class validated."); 
		else
		{
			NSWarnLog(@"Specified controller does not implement Adcontroller protocol!");
			NSWarnLog(@"Replacing with AdController");
			templateCopy = [[*templatePointer mutableCopy] autorelease];
			[templateCopy setValue: 
				[NSDictionary dictionaryWithObject: @"AdController" forKey: @"Class"]
				forKey: @"objectTemplates.controller"];
			templateCopy = [[templateCopy copy] autorelease];
			templatePointer = &templateCopy;	
		}

		if(![NSStringFromClass(controllerClass) isEqual: controllerName])
		{
			NSWarnLog(@"Controller name (%@) and principal class name (%@) do not match",
				controllerName, NSStringFromClass(controllerClass));
			NSWarnLog(@"Replacing controller name with principal class name in template");	
			[objectTemplates setValue: NSStringFromClass(controllerClass)
				forKeyPath: @"controller.Class"];
		}			
	}
	else
	{
		NSWarnLog(@"Controller bundle contains no principal class. Replacing with AdController.");
		templateCopy = [[*templatePointer mutableCopy] autorelease];
		[templateCopy setValue: 
			[NSDictionary dictionaryWithObject: @"AdController" forKey: @"Class"]
			forKey: @"objectTemplates.controller"];
		templateCopy = [[templateCopy copy] autorelease];
		templatePointer = &templateCopy;	
	}
}

/**
Loads any objects declared in the external objects section
of the template. If the name associated with a object is already present in the
externalObjects dictionary i.e. it was set via setExternalObjects:
then it is not loaded.
*/
- (BOOL) _instantiateExternalObjects: (NSError**) error
{
	NSDictionary* externalObjectFiles;
	NSEnumerator* objectNameEnum;
	NSString* objectName, *fileName;
	NSData* data;
	id object;

	NSDebugLLog(@"AdTemplateProcessor", 
		@"Instantiating external objects");
	externalObjectFiles = [template objectForKey: @"externalObjects"];
	if(externalObjectFiles == nil)
	{
		NSWarnLog(@"No external object files specified in template");
		return YES;
	}	
		
	objectNameEnum = [externalObjectFiles keyEnumerator];
	while((objectName = [objectNameEnum nextObject]))
	{
		//Check if an object with objectName already exists
		//in externalObjects. If so skip...
		if([externalObjects objectForKey: objectName] != nil)
			continue;
	
		fileName = [externalObjectFiles objectForKey: objectName];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Processing object %@ from file %@", objectName, fileName);
			
		//The exception raised by NSKeyedUnarchiver if it can't understand
		//data archive format is caught since the data may represent a plist
		//which must be unarchived with NSPropertyListSerialization (at least on cocoa) 
		data = [NSData dataWithContentsOfFile: fileName];
			
		NS_DURING
		{
			object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			if(object == nil)
				[NSException raise: NSInvalidArgumentException
					    format: @"Data not a valid archive"];
		}
		NS_HANDLER
		{		
			NSWarnLog(@"Detected possible plist external object - attempting to decode");
			object = [NSPropertyListSerialization propertyListFromData: data 
								  mutabilityOption: NSPropertyListMutableContainers 
									    format: NULL 
								  errorDescription: NULL];		
		}
		NS_ENDHANDLER	
		
		//If object is nil give up.
		if(object == nil)
		{
			*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreTemplateProcessingError,
				@"Error processing template",
				[NSString stringWithFormat:
					@"Unable to retrieve external object from specified file %@", 
					fileName],
				@"Check the specified file exists and contains a valid object");	
		
			return NO;
		}
		[externalObjects setObject: object forKey: objectName];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Object succesfully processed");
	}
	//Add all external objects to buildDict
	[buildDict addEntriesFromDictionary: externalObjects];	

	NSDebugLLog(@"AdTemplateProcessor", 
		@"External objects processing complete.");

	return YES;	
}

- (id) init
{

	if((self = [super init]))
	{
		template = nil;
		processingError = nil;
	}

	return self;
}

- (void) dealloc
{
	[template release];
	[buildDict release];
	[externalObjects release];
	[processingError release];
	[super dealloc];
}

- (void) setTemplate: (NSDictionary*) aTemplate
{	
	[externalObjects release];
	[buildDict release];
	[template release];
	template = [aTemplate retain];
	objectTemplates = [aTemplate objectForKey: @"objectTemplates"];
	externalObjects = [NSMutableDictionary new];
	buildDict = [NSMutableDictionary new];
}

- (void) setExternalObjects: (NSDictionary*) dict
{
	[externalObjects addEntriesFromDictionary: dict];
}

- (NSDictionary*) template
{
	return [[template retain] autorelease];
}

- (BOOL) validateTemplate: (id*) objectPointer error: (NSError**) error
{
	id testTemplate;
	NSMutableArray* allKeys;
	NSArray *allClasses;
	NSEnumerator* keyEnum, *classEnum;
	NSMutableDictionary* templatesCopy;
	id key, className;

	//Deference the pointer to make things easier below
	testTemplate = *objectPointer;

	NSDebugLLog(@"AdTemplateProcessor",
		@"Begining validation");

	if(testTemplate == nil)
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreInvalidTemplateError,
				@"Passed nil for template",
				nil,
				nil);

		return NO;
	}	

	if(![testTemplate isKindOfClass: [NSDictionary class]])
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreInvalidTemplateError,
				@"Invalid class for template",
				[NSString stringWithFormat: 
					@"The template must be a dictionary. It is a %@", [testTemplate class]],
				@"Check template documentation for how to create a correct template.");	
		return NO;
	}	

	/*
	 * Checks -
	 * 1) If running from command line and no controller specified that an 
		external objects sections is present
	 * 2) templateObjects section is present
	 * 3) All keys are NSStrings.
	 * 4) configurationGenerator key is present if no controller specified
	 * 5) controller key is present
	 * 6) controller key refers to a real loadable controller
	 * 7) All Class keys refer to loaded classes
	 */
	
	if([[AdIOManager appIOManager] runMode] == AdCoreCommandLineRunMode)
	{
		if([testTemplate valueForKey: @"externalObjects"] == nil && 
			![testTemplate valueForKeyPath: @"objectTemplates.controller"])
		{
			*error = AdCreateError(AdunCoreErrorDomain,
					AdCoreInvalidTemplateError,
					@"Invalid template.",
					@"The template must contain an externalObject section .",
					@"Check template documentation for how to create a correct template.");
			return NO;
		}
	}	

	if([testTemplate valueForKey: @"objectTemplates"] == nil)
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreInvalidTemplateError,
				@"Invalid template.",
				@"The template must contain an objectTemplates section.",
				@"Check template documentation for how to create a correct template.");
		return NO;
	}
	
	allKeys = [NSMutableArray array];
	if(![testTemplate objectForKey: @"externalObjects"] == nil)
		[allKeys addObjectsFromArray: [[testTemplate objectForKey: @"externalObjects"] allKeys]];

	[allKeys addObjectsFromArray: [[testTemplate objectForKey: @"objectTemplates"] allKeys]];
	keyEnum = [allKeys objectEnumerator];
	while((key = [keyEnum nextObject]))
	{
		if(![key isKindOfClass: [NSString class]])
		{
			*error = AdCreateError(AdunCoreErrorDomain,
					       AdCoreInvalidTemplateError,
					       @"Invalid template.",
					       @"Non-string object used for template key.",
					       @"Check the template keys and specifications for property list objects.");
			return NO;
		}
	}
	
	if(![allKeys containsObject: @"configurationGenerator"] && ![allKeys containsObject: @"controller"])
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreInvalidTemplateError,
				@"Invalid template",
				@"Each template must contain a configuration generator.",
				@"Add a configuration generator entry to the template.");
		return NO;
	}
	else if(![allKeys containsObject: @"configurationGenerator"])
	{	
		NSWarnLog(@"No configuration generator specified - assuming controller will handle this");
	}

	//Checking controller key is present and the controller exists.
	if(![allKeys containsObject: @"controller"])
	{
		//If its not present create one
		NSWarnLog(@"Controller specification missing from template");
		NSWarnLog(@"Inserting default entry");
		templatesCopy = [[testTemplate mutableCopy] autorelease];
		[[templatesCopy objectForKey: @"objectTemplates"]
			setObject: [NSDictionary dictionaryWithObject: @"AdController" forKey: @"Class"]
			forKey: @"controller"];
		*objectPointer = [[templatesCopy copy] autorelease];	
		testTemplate = *objectPointer;
	}	
	else
	{
		//If the controller is not valid _validateController:fromTemplate:
		//will return a new template with a modified value.
		//Note we must pass the original pointer not the address of the deferenced variable
		//created above.
		[self _validateController: 
			[testTemplate valueForKeyPath: @"objectTemplates.controller.Class"]
			fromTemplate: objectPointer];

		//Defreferece objectPointer again since it may have
		//been modified during controller validation
		testTemplate = *objectPointer;
	}	
			
	//Get the class attribute of every entry in objectTemplates
	//except the controller and check it refers to a real class

	NSDebugLLog(@"AdTemplateProcessor", 
		@"Checking all templates refer to real classes");
	
	templatesCopy = [[[testTemplate objectForKey: @"objectTemplates"]
				mutableCopy] autorelease];
	[templatesCopy removeObjectForKey: @"controller"];
	allClasses = [[templatesCopy allValues] valueForKey: @"Class"];
	
	classEnum = [allClasses objectEnumerator];
	while((className = [classEnum nextObject]))
	{
		if([className isKindOfClass: [NSString class]])
		{
			if(NSClassFromString(className) == nil)
			{
				*error = AdCreateError(AdunCoreErrorDomain,
					AdCoreInvalidTemplateError,
					@"Invalid template", 
					[NSString stringWithFormat: @"Class %@ does not exist", className],
					@"Check specified classes are spelt correctly and are part of the AdunKernel framework or\
 an external objects bundle.");
				return NO;
			}
		}
		else
		{	
			//The "Class" key is missing
			if([className isKindOfClass: [NSNull class]])
			{
				*error = AdCreateError(AdunCoreErrorDomain,
						AdCoreInvalidTemplateError,
						@"Invlalid template.",
						@"One of the template objects is missing the 'Class' key",
						@"Check that each template object contains the key 'Class' (with capital C)");
			}
			else
			{
				*error = AdCreateError(AdunCoreErrorDomain,
						AdCoreInvalidTemplateError,
						@"Invalid termplate.",
						[NSString stringWithFormat: @"Invalid object used for class name - %@", className],
						@"All class names must be strings.");
			}	

			return NO;
		}
	}	


	NSDebugLLog(@"AdTemplateProcessor",
		@"Template succesfully validated");

	return YES;
}

- (BOOL) processTemplate: (NSError**) error
{
	NSEnumerator* objectTemplateEnum;
	id objectName;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	objectTemplateEnum = [objectTemplates keyEnumerator];
	if(![self _instantiateExternalObjects: error])
		return NO;
	
	//FIXME - May be none.
	//Check there are at least some external objects
	if([externalObjects count] == 0)
	{
		*error = AdCreateError(AdunCoreErrorDomain,
				AdCoreInvalidTemplateError,
				@"No external objects provided.",
				@"The externalObjects template section was empty and no data was provided from another source.",
				@"If running from the command line you must specify the simulation data to use.");
		return NO;		
	}
	
	NSDebugLLog(@"AdTemplateProcessor", 
		@"Creating template objects\n");

	/*
	 * When a processing error is detected an error object is created
	 * and assigned to the processingError ivar.
	 * An exception is then raised which we catch here.
	 * An exception is used since the following loop can result in
	 * deeply recursive calls to instantiateObjectWithTemplate:associateName:
	 */
	[processingError release];
	processingError = nil;
	NS_DURING
	{
		//Go through the object templates and create everything.
		while((objectName = [objectTemplateEnum nextObject]))
		{
			//Only build an object if we have not already done so 
			//due to a recursive call to instantiateObjectWithTemplate:associateName:
			if([buildDict objectForKey: objectName] == nil)
				[self instantiateObjectWithTemplate: 
					[objectTemplates objectForKey: objectName]
					associateName: objectName];
		}
	}	
	NS_HANDLER
	{
		//If processing error has not been set then this exception
		//was caused by some unknown programmatic error.
		if(processingError == nil)
		{
			NSWarnLog(@"Unexpected exception raised during template processing");
			NSWarnLog(@"Reraising ..");
			[localException raise];
		}
		else
		{
			NSWarnLog(@"Errors during processing");
			GSPrintf(stdout, @"There were errors while processing the template.\n");
			GSPrintf(stdout, @"See the error log for more information.\n");
		}
	}
	NS_ENDHANDLER
	
	NSDebugLLog(@"AdTemplateProcessor", 
		@"Template processed");

	[pool release];	
	if(processingError != nil)
	{
		*error = processingError;
		return NO;
	}
	else
		return YES;
}

- (NSDictionary*) createdObjects
{
	return [[buildDict copy] autorelease];
}

- (AdConfigurationGenerator*) configurationGenerator
{
	return [buildDict objectForKey: @"configurationGenerator"];
}

- (id) controller
{
	return [buildDict objectForKey: @"controller"];
}

- (NSDictionary*) externalObjects
{
	return [[externalObjects copy] autorelease];
}

@end

@implementation AdTemplateProcessor (ObjectCreationExtensions)

/* This method takes a name from the template and:
 * A) Checks if we have already created an object with this name
 *  	If so we return this object
 * B) Checks if there is an object waiting to be created with this name
 *	If so we instantiate it and return the result (using instantiateObjectWithTemplate:associateName:)
 * C) Otherwise we use the string
 */

- (id) _resolveTemplateString: (NSString*) aString
{
	id keyObject;
	NSDictionary* newTemplate;

	keyObject = aString;
	if([buildDict objectForKey: keyObject] != nil)
	{
		keyObject = [buildDict objectForKey: keyObject];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Found previously built object %@", keyObject);
	}	
	else if([objectTemplates objectForKey: keyObject] != nil)
	{	
		newTemplate = [objectTemplates objectForKey: keyObject];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Require un-instantiated object. Recursively creating it now.");
		keyObject = [self instantiateObjectWithTemplate: newTemplate 
				associateName: aString];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Created new object - %@", keyObject);
	}

	return keyObject;
}

/*
 * This method checks the contents of container for 
 * 1) Strings - If there are any the are resolved using _resolveTemplateString.
 * 2) Other containers - Recursively call this method.
 *	
 * It returns the container with all its contents resolved.
 */
- (id) _resolveContainerEntries: (id) container
{
	int i;
	NSEnumerator* anEnum;
	id newContainer, keyObject, key;

	newContainer = nil;
	if([container isKindOfClass: [NSDictionary class]])
	{
		NSDebugLLog(@"AdTemplateProcessor",
			@"Container is a dictionary");
		newContainer = [NSMutableDictionary dictionary];
		anEnum = [container keyEnumerator];
		while((key = [anEnum nextObject]))
		{	
			keyObject = [container objectForKey: key];
			if([keyObject isKindOfClass: [NSString class]])
			{
				NSDebugLLog(@"AdTemplateProcessor",
					@"Found string in container - resolving");
				keyObject = [self _resolveTemplateString: keyObject];
			}	
			else if([keyObject isKindOfClass: [NSDictionary class]] 
				|| [keyObject isKindOfClass: [NSArray class]])
			{
				//recurse
				NSDebugLLog(@"AdTemplateProcessor",
					@"Found another container in container  - resolving contents");
				keyObject = [self _resolveContainerEntries: keyObject];	
			}	
			[newContainer setObject: keyObject forKey: key];
		}
	}
	else if([container isKindOfClass: [NSArray class]])
	{
		NSDebugLLog(@"AdTemplateProcessor",
			@"Container is an array");
		newContainer = [NSMutableArray array];
		for(i=0; i<(int)[container count]; i++)
		{	
			keyObject = [container objectAtIndex: i];
			if([keyObject isKindOfClass: [NSString class]])
			{
				NSDebugLLog(@"AdTemplateProcessor",
					@"Found string in container - resolving");
				keyObject = [self _resolveTemplateString: keyObject];
			}	
			else if([keyObject isKindOfClass: [NSDictionary class]] 
				|| [keyObject isKindOfClass: [NSArray class]])
			{
				//recurse
				NSDebugLLog(@"AdTemplateProcessor",
					@"Found another container in container  - resolving contents");
				keyObject = [self _resolveContainerEntries: keyObject];	
			}	
			[newContainer addObject: keyObject];
		}
	}

	return [[newContainer copy] autorelease];
}

/**
Instantiates the object defined by \e objectTemplate and adds it to buildDict as \e name.
If the objectTemplate contains strings they are resolved using _resolveTemplateString.
(Note: _resolveTemplateString may recursively call this method).
If the objectTemplate contains other property list objects (arrays or dictionaries) their
contents are resolved using _resolveContainerEntries.
*/
- (id) instantiateObjectWithTemplate: (NSDictionary*) objectTemplate associateName: (NSString*) name
{
	Class class;
	NSMutableArray* keys;
	NSEnumerator* keyEnum;
	NSMutableDictionary *properties;
	id object, keyObject, key;

	/*
	 * objectTemplate is a dictionary containing a class name and
	 * a list of key:object pairs. Each key is a property of instances
	 * of the class and the associated object is the value to be used for the property.
	 */

	NSDebugLLog(@"AdTemplateProcessor", @"\n");
	NSDebugLLog(@"AdTemplateProcessor",
		@"Instantiating object using template %@", objectTemplate);

	//We check that class exists during validation. This is a backup check.
	class = NSClassFromString([objectTemplate objectForKey: @"Class"]);
	if(class == nil)
	{
		NSWarnLog(@"No class called %@ exists", [objectTemplate objectForKey: @"Class"]);
		processingError = AdCreateError(AdunCoreErrorDomain,
					AdCoreTemplateProcessingError,
					@"Error processing template",
					[NSString stringWithFormat:
						@"Unknown class %@ in template", 
						[objectTemplate objectForKey: @"Class"]],
					@"Check that the provided class names are valid.");	
		[processingError retain];
		[NSException raise: @"AdTemplateProcessingException"
			format: @"Error while processing template"];
	}	
	
	NSDebugLLog(@"AdTemplateProcessor",
		@"Instantiating object of class %@", NSStringFromClass(class));
	/*	
	 * Just allocate the class at this moment.
	 * Its autoreleased so we don't have to worry about it if
	 * something happens between now and when its added to
	 * the build dict.
	 * However this is dangerous as during the objects init method
	 * autorelease could be called on this object - for example
	 * if it was replacing itself with another object - leading
	 * to a crash when the autorelase pool is emptied.
	 * Hence this object is only used to access the validation methods
	 * afterwards its replaced.
	 */	
	object = [[class alloc] autorelease];
	keys = [[[objectTemplate allKeys] mutableCopy] autorelease];
	[keys removeObject: @"Class"];

	NSDebugLLog(@"AdTemplateProcessor", 
		@"Supplied properties %@", keys);

	keyEnum = [keys objectEnumerator];

	/*
	 * Initialising the new object with the supplied properties.
	 * For each key in the objectTemplate we retrieve the associated keyObject.
	 * Then we -
	 *
	 * 1) Check if it is a NSString. If it is 
	 *	Pass it to _resolveTemplateString and use the result.
	 *
	 * 2) Otherwise its a NSPropertyList object. However if its an array or dictionary
	 * 	we have to checks its values to resolve any strings in it aswell.
	 */
	properties = [NSMutableDictionary dictionary]; 
	while((key = [keyEnum nextObject]))
	{
		keyObject = [objectTemplate objectForKey: key];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Key %@. Key object %@. Class %@", 
			key, keyObject, NSStringFromClass([keyObject class])); 
		if([keyObject isKindOfClass: [NSString class]])
		{
			NSDebugLLog(@"AdTemplateProcessor", 
				@"Key object is a string - Resolving"); 
			keyObject = [self _resolveTemplateString: keyObject];
		}	
		else if([keyObject isKindOfClass: [NSDictionary class]] 
			|| [keyObject isKindOfClass: [NSArray class]])
		{
			NSDebugLLog(@"AdTemplateProcessor", 
				@"Key object is a container - Resolving contents"); 
			keyObject = [self _resolveContainerEntries: keyObject];	
		}	

		NSDebugLLog(@"AdTemplateProcessor", 
			@"Validating key object");
		//Validate
		if([object validateValue: &keyObject forKey: key error: NULL])
		{
			NSDebugLLog(@"AdTemplateProcessor", 
				@"Validation succesful - Adding to properies dictionary");
			[properties setObject: keyObject forKey: key];
		}	
		else
		{
			processingError = AdCreateError(AdunCoreErrorDomain,
					AdCoreTemplateProcessingError,
					@"Error processing template",
					[NSString stringWithFormat:
						@"Validation failed for key %@ of object %@ - provided value %@", 
						key,
						object,
						keyObject],
					@"Check that the provided value matches the requirements for the key.");	
			[processingError retain];
			[NSException raise: @"AdTemplateProcessingException"
				format: @"Error while processing template"];
		}	
	}

	NSDebugLLog(@"AdTemplateProcessor",
		@"Setting %@ with values %@", object, properties);
	/*
	 * There are two methods for initialising the object
	 * 1) Use initWithDictionary: if the object implements it.
	 * 2) Otherwise use key-value coding i.e. setValuesForKeysWithDictionary:
	 */
	if([object respondsToSelector: @selector(initWithDictionary:)])
	{
		NSDebugLLog(@"AdTemplateProcessor",
			@"Initialising %@ using initWithDictionary", object);
		object = [[class alloc] initWithDictionary: properties];
	}
	else
	{
		NSDebugLLog(@"AdTemplateProcessor",
			@"Initialising %@ using init", object);
		object = [[class new] autorelease];
		NSDebugLLog(@"AdTemplateProcessor", 
			@"Setting properties via key value coding");

		//Catch key-value coding exceptions.
		NS_DURING
		{
			[object setValuesForKeysWithDictionary: properties];
		}
		NS_HANDLER
		{
			//FIXME: Add special handling for NSInvalidArgumentExceptions
			//As these will be called by template errors.
			processingError = AdCreateError(AdunCoreErrorDomain,
					AdCoreTemplateProcessingError,
					[NSString stringWithFormat:
						@"Exception while creating object %@", 
						object],
					[NSString stringWithFormat:
						@"Name %@. Reason %@. UserInfo %@",  
						[localException name],
						[localException reason],
						[localException userInfo]],
					@"This could be a template formatting error.");	
			[processingError retain];
			object = nil;	
			[localException raise];		
		}
		NS_ENDHANDLER
	}	
	NSDebugLLog(@"AdTemplateProcessor", @"Object initialised");

	/*
	 * Add the newly created object to build dict using name
	 * so it can be accessed by other objects that require it.
	 */
	NSDebugLLog(@"AdTemplateProcessor", 
		@"Adding to build dictionary");
	[buildDict setObject: object forKey: name];

	
	NSDebugLLog(@"AdTemplateProcessor", 
		@"Object %@ processed\n", object);
	fflush(stdout);
	
	return object;
}

@end

