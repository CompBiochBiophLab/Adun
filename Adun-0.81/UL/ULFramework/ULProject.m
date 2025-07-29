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
#include "ULFramework/ULProject.h"

NSString* ULProjectIdentification = @"ULProjectIdentification";

@implementation ULProject

/**
Returns YES if \e aReference contains the four required keys
AdObjectClass, AdObjectIdentification, Schema and Database
*/
- (BOOL) _isValidReference: (NSDictionary*) aReference
{
	BOOL isValid = YES;

	if([aReference objectForKey: AdObjectClass] == nil)
		isValid = NO;
	else if([aReference objectForKey: AdObjectIdentification] == nil)
		isValid = NO;
	else if([aReference objectForKey: @"Database"] == nil)
		isValid = NO;
	else if([aReference objectForKey: @"Schema"] == nil)
		isValid = NO;
		
	return isValid;	
}

//Checks if ref1 is equal to ref2 by checking if they have the same 
//values for the four reference keys.
//Assumes both ref1 and ref2 are valid reference dictionaries 
//i.e. as determined by isValidReference:
- (BOOL) _compareReference: (NSDictionary*) ref1 toReference: (NSDictionary*) ref2
{
	BOOL isEqual;
	NSEnumerator* keyEnum;
	NSString* key;
	
	keyEnum = [ref1 keyEnumerator];
	while(key = [keyEnum nextObject])
	{
		//Skip ULProjectIdentification
		if([key isEqual: ULProjectIdentification])
			continue;
		
		if(![[ref1 objectForKey: key] isEqual: [ref2 objectForKey: key]])
			isEqual = NO;
	}
	
	return isEqual;
}

//Checks if there is a reference equal if \e aReference in the receiver
//and if so returns it. Returns nil otherwise.
//Comparisons are made using _compareReference:toReference:
- (NSDictionary*) _referenceEqualToReference: (NSDictionary*) aReference
{
	NSEnumerator* referenceEnum;
	NSDictionary* reference, *foundReference = nil;
	
	referenceEnum = [references objectEnumerator];
	while(reference = [referenceEnum nextObject])
		if([self _compareReference: aReference toReference: reference])
		{
			foundReference = reference;
			break;
		}
			
	return foundReference;
}

- (id) init
{
	if(self = [super init])
	{
		isRootProject = YES;
		classReferences = [NSMutableDictionary new];
		references = [NSMutableArray new];
		projectContainer = nil;
		
		[classReferences setObject: [NSMutableArray array] forKey: @"AdDataSet"];
		[classReferences setObject: [NSMutableArray array] forKey: @"AdSimulationData"];
		[classReferences setObject: [NSMutableArray array] forKey: @"AdDataSource"];
		[classReferences setObject: [NSMutableArray array] forKey: @"ULTemplate"];
		[classReferences setObject: [NSMutableArray array] forKey: @"ULProject"];
	}
	
	return self;
}

- (NSString*) description
{
	int count;
	NSMutableString* string, *description;
	NSEnumerator* classEnum;
	NSString* class;
	
	string = [NSMutableString new];
	
	if([references count] == 0)
		[string appendFormat: @"Project %@ - Contains no references\n", [self name]];
	else
	{	
		[string appendFormat: @"Project %@:\n", [self name]];
		classEnum = [classReferences keyEnumerator];	
		while(class = [classEnum nextObject])
		{
			count = [[classReferences objectForKey: class] count];
			if(count != 0)
				[string appendFormat: @"\t%@ - %d references\n", 
					class, count];
		}
	}
	
	description = [string copy];
	[string release];
	
	return description;
}

- (void) dealloc
{
	[classReferences release];
	[references release];
	[super dealloc];
}

/*
Removes \e aReference from the receiver.
If \e aReference does not exist this method does nothing
*/
- (void) removeReference: (NSDictionary*) aReference
{
	NSDictionary* reference;

	if(![self _isValidReference: aReference])
		return;
	
	//See if there is a reference equal to this one
	//using _referenceEqualToReference:
	//We use this its easiest to use the actual reference
	//object thats stored in the removal process
	reference = [self _referenceEqualToReference: aReference];
	if(reference != nil)
	{
		[references removeObject: reference];
		[[classReferences objectForKey: [reference objectForKey: @"AdObjectClass"]]
				    removeObject: reference];
	}
	
}

/*
Adds \e aReference to the project.
 If \e aReference is identical to a reference already in the 
 project this method does nothing.
 If \e aReference does not contain keys of the correct type and number 
 - AdObjectIdentification, AdObjectClass, Database, Schema -
 it is not added.
 */
- (void) addReference: (NSDictionary*) aReference
{
	NSMutableDictionary* refCopy;

	if(![self _isValidReference: aReference])
		return;

	if(![self containsReference:aReference])
	{
		//Add the ULProjectIdentification key
		refCopy = [aReference mutableCopy];
		[refCopy setValue: [self identification] 
			forKey: ULProjectIdentification];
		aReference = [[refCopy copy] autorelease];
		[refCopy release];
		
		//Add to ivars
		[references addObject: aReference];
		[[classReferences objectForKey: [aReference objectForKey: AdObjectClass]]
			addObject: aReference];
	}
}

/*
Returns YES if a reference equal to \e aReference is in the dictionary.
 */
- (BOOL) containsReference: (NSDictionary*) aReference
{
	BOOL containsReference = NO;
	NSEnumerator* referenceEnum;
	NSDictionary* reference;
	
	referenceEnum = [references objectEnumerator];
	while(reference = [referenceEnum nextObject])
		if([self _compareReference: aReference toReference: reference])
		{
			containsReference = YES;
			break;
		}
		
	return containsReference;	
}

/*
Adds a reference to \e anObject which must be stored in a database.
 If its not this method raise an NSInvalidArgumentException.
 Note a reference is only considered to exist if all four properties are
 the same - equality by AdObjectIdentification is not sufficent.
 */
- (void) addReferenceToObject: (AdModelObject*) anObject
{
	if([[anObject database] isEqual: @"None"])
		[NSException raise: NSInvalidArgumentException 
			format: @"Object %@ has not been stored in a database", anObject];

	NSMutableDictionary* refDict = [NSMutableDictionary new];
	
	[refDict setObject: [anObject identification] 
		forKey: AdObjectIdentification];
	[refDict setObject: NSStringFromClass([anObject class]) 
		forKey: AdObjectClass];
	[refDict setObject: [anObject database] 
		forKey: @"Database"];
	[refDict setObject: [anObject schema]
		forKey: @"Schema"];
	
	[self addReference: refDict];
	[refDict release];		
}

/*
Removes a reference to \e anObject.
 If no reference to \e anObject exists this method does nothing.
 Note a reference is only considered to exist if all four properties are
 the same - equality by AdObjectIdentification is not sufficent.
 */
- (void) removeReferenceToObject: (AdModelObject*) anObject
{
	NSMutableDictionary* refDict = [NSMutableDictionary new];
	
	[refDict setObject: [anObject identification] 
		    forKey: AdObjectIdentification];
	[refDict setObject: NSStringFromClass([anObject class]) 
		    forKey: AdObjectClass];
	[refDict setObject: [anObject database] 
		    forKey: @"Database"];
	[refDict setObject: [anObject schema]
		    forKey: @"Schema"];
	
	[self removeReference: refDict];
	[refDict release];
}

/*
Returns YES if the receiver contains a reference to object.NO otherwise.
Note a reference is only considered to exist if all four properties are
the same - equality by AdObjectIdentification is not sufficent.
*/
- (BOOL) containsReferenceToObject: (AdModelObject*) anObject
{
	BOOL retval;
	NSMutableDictionary* refDict = [NSMutableDictionary new];
	
	[refDict setObject: [anObject identification] 
		    forKey: AdObjectIdentification];
	[refDict setObject: NSStringFromClass([anObject class]) 
		    forKey: AdObjectClass];
	[refDict setObject: [anObject database] 
		    forKey: @"Database"];
	[refDict setObject: [anObject schema]
		    forKey: @"Schema"];
	
	retval = [self containsReference: refDict];
	[refDict release];
	
	return retval;	
}

/*
Returns an array containing all the references
 */
- (NSArray*) references
{
	return [[references copy] autorelease];
}

/*
Returns the \e index'th reference in the project.
Raises an NSRangeException if \e index is beyond the range of the receiver.
 */
- (NSDictionary*) referenceAtIndex: (unsigned int) index
{
	return [references objectAtIndex: index];
}

/*
Returns all references to objects of \e className.
\e className must be a subclass of AdModelObject.
The method returns an empty array if there are no objects of \e className.
It returns nil if \e className is not a subclass of AdModelObject.
*/
- (NSArray*) referencesForClass: (NSString*) className
{
	Class classType;

	classType = NSClassFromString(className);
	if([classType isSubclassOfClass: [AdModelObject class]])
		return [[[classReferences objectForKey: className] copy] autorelease];
	
	return nil;		
}

/*
Returns the number of references in the receiver
 */
- (unsigned int) count
{
	return [references count];
}

/*
Sets if this project is contained by other projects.
*/
- (void) setRootProject: (BOOL) value
{
	if((projectContainer != nil) && (value == YES))
		[NSException raise: NSInvalidArgumentException
			format: @"Project is contained by another (%@) - cannot be a root project",
			projectContainer];
	
	isRootProject = value;
}

/*
Returns YES if this is a root project, no otherwise
*/
- (BOOL) isRootProject
{
	return isRootProject;
}

/*
Returns the number of references to objects of \e className.
Raises an NSInvalidArgumentException if \e className is not a subclass of
AdModelObject.
*/
- (unsigned int) countForClass: (NSString*) className
{
	Class classType;
	
	classType = NSClassFromString(className);
	if([classType isSubclassOfClass: [AdModelObject class]])
		return [[classReferences objectForKey: className] count];
	
	[NSException raise:NSInvalidArgumentException 
		format: @"Specified class %@ is not a descendant of AdModelObject", className];
}


- (id) initWithCoder: (NSCoder*) decoder
{
	NSEnumerator* referenceEnum;
	NSDictionary* reference;

	self = [super initWithCoder: decoder];
	if([decoder allowsKeyedCoding])
	{
		projectContainer = [decoder decodeObjectForKey: @"ProjectContainer"];
		isRootProject = [decoder decodeBoolForKey: @"IsRootProject"];
		references = [decoder decodeObjectForKey: @"References"];
		[references retain];
		
		//Rebuild classReferences
		classReferences = [NSMutableDictionary new];
		[classReferences setObject: [NSMutableArray array] forKey: @"AdDataSet"];
		[classReferences setObject: [NSMutableArray array] forKey: @"AdSimulationData"];
		[classReferences setObject: [NSMutableArray array] forKey: @"AdDataSource"];
		[classReferences setObject: [NSMutableArray array] forKey: @"ULTemplate"];
		[classReferences setObject: [NSMutableArray array] forKey: @"ULProject"];
		
		referenceEnum = [references objectEnumerator];
		while(reference = [referenceEnum nextObject])
		{
			[[classReferences objectForKey: [reference objectForKey: AdObjectClass]]
				addObject: reference];
		}
	}
	else
		NSLog(@"ULProject does not support non-keyed coding");

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeObject: references forKey: @"References"];
		[encoder encodeBool: isRootProject forKey: @"IsRootProject"]; 
		
		if(projectContainer != nil)
			[encoder encodeConditionalObject: projectContainer 
				forKey: @"ProjectContainer"];
		
		[super encodeWithCoder: encoder];
	}
	else
		NSLog(@"ULProject does not support non-keyed coding");
}

@end
