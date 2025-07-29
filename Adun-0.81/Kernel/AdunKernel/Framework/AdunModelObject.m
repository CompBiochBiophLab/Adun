/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-07-08 16:34:11 +0200 by michael johnston

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

#include "AdunKernel/AdunModelObject.h"

//FIXME: Actual definitions of the first two will change
//FIXME: Variable name and value should be the same to avoid confusion
//However if you are going to present the keys to the user e.g.
//using Aduns properties panel, then they should be human readable.
NSString* AdObjectIdentification = @"Identification";
NSString* AdObjectCreator = @"Creator";
NSString* AdObjectCreationDate = @"Created";
NSString* AdObjectClass = @"Class";

//Possible add methods "outputRepresentations"
//and "representationForType" so model objects can advertise
//how they can be output
@implementation AdModelObject

+ (id) unarchiveFromFile: (NSString*) file
{ 
	return [NSKeyedUnarchiver unarchiveObjectWithFile: file];
}

- (id) init
{
	NSDateFormatter* dateFormatter;

	if((self =  [super init]))
	{
		date = [NSDate date];
		[date retain];
		dateFormatter = [[NSDateFormatter alloc] 
					initWithDateFormat: @"%H:%M %d/%m/%Y"
					allowNaturalLanguage: NO];

		//generate a unique id for this object
		identification = [NSString stringWithFormat: @"%@",
					[[NSProcessInfo processInfo] 
						globallyUniqueString]];
		[identification retain];

		properties = [NSMutableDictionary dictionary];
		[properties setObject: [dateFormatter stringForObjectValue: date]
				forKey: AdObjectCreationDate];
		[properties setObject: NSFullUserName() 
			forKey: AdObjectCreator];
		[properties setObject: identification
			forKey: AdObjectIdentification];
		[properties setObject: NSStringFromClass([self class])
			forKey: AdObjectClass];
		
		userMetadata = [NSMutableDictionary dictionary];
		[userMetadata setObject: @"None" forKey: @"Name"];
		[userMetadata setObject: @"None" forKey: @"Keywords"];
		
		systemMetadata = [NSMutableDictionary dictionary];
		[systemMetadata setObject: @"None" forKey: @"Database"];
		[systemMetadata setObject: @"None" forKey: @"Schema"];

		volatileMetadata = [NSMutableDictionary new];
		inputReferences = [NSMutableDictionary new];
		outputReferences = [NSMutableDictionary new];

		[properties retain];
		[systemMetadata retain];
		[userMetadata retain];
		[dateFormatter release];
	}	

	return self;
}

- (void) dealloc
{
	[properties release];
	[systemMetadata release];
	[userMetadata release];
	[volatileMetadata release];
	[identification release];
	[date release];
	[inputReferences release];
	[outputReferences release];

	[super dealloc];
}

- (BOOL) archiveToDirectory: (NSString*) path
{
	BOOL retval;
	NSKeyedArchiver* archiver;
	NSMutableData* data = [NSMutableData new];

	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: self forKey: @"root"];
	[archiver finishEncoding];	
	
	retval = [data writeToFile: [path stringByAppendingPathComponent: identification]
			atomically: NO];
		
	[data release];
	[archiver release];	
		
	return retval;	
}

- (NSString*) identification
{
	return identification;
}

- (NSString*) name
{
	return [userMetadata objectForKey: @"Name"];
}

- (id) creator
{
	return [properties objectForKey: AdObjectCreator];
}

- (id) created
{
	return [properties objectForKey: AdObjectCreationDate];
}

- (NSDate*) creationDate
{
	return date;
}

- (id) keywords
{
	return [userMetadata objectForKey: @"Keywords"];
}

- (NSString*) database
{
	return [systemMetadata objectForKey: @"Database"];
}

- (NSString*) schema
{
	return [systemMetadata objectForKey: @"Schema"];
}

- (NSArray*) inputReferencesToObjectsOfClass: (NSString*) className
{
	return [[inputReferences objectForKey: className] allValues];
}

//FIXME: Trying to find the best way of returning the input 
//refs. Better as an array for use with an outline view, but
//we also need to store them by class etc.
- (NSArray*) inputReferences
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* typeEnum = [inputReferences objectEnumerator];
	id types;

	while((types = [typeEnum nextObject]))
		[array addObjectsFromArray: [types allValues]];

	return array;	
}

- (void) addInputReferenceToObject: (id) obj
{
	if([obj respondsToSelector: @selector(identification)])
	{
		[self addInputReferenceToObjectWithID: [obj identification]
			ofType: NSStringFromClass([obj class])];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Object (%@) does not respond to identification.", 
			[obj description]];

}

- (void) addInputReferenceToObjectWithID: (NSString*) ident 
		ofType: (NSString*) type 
{
	NSMutableDictionary* refs;
	NSDictionary* dict;
	
	if(ident != nil && type != nil)
	{
		dict = [NSDictionary dictionaryWithObjectsAndKeys:
			ident, @"Identification",
			type, @"Class", nil];
		refs = [inputReferences objectForKey: type];
		if(refs == nil)
		{
			refs = [NSMutableDictionary dictionary];
			[inputReferences setObject: refs forKey: type];
		}
		[refs setObject: dict forKey: ident];
	}	
}

/**
Deprecated
*/
- (void) addInputReferenceToObjectWithID: (NSString*) ident 
		name: (NSString*) objectName
		ofType: (NSString*) type 
		inSchema: (NSString*) schema
		ofDatabase: (NSString*) databaseName
{
	[self addInputReferenceToObjectWithID: ident
		ofType: type];
}

- (void) removeInputReferenceToObject: (id) obj
{
	if([obj respondsToSelector: @selector(identification)])
	{
		[self removeInputReferenceToObjectWithID: [obj identification]
			ofType: NSStringFromClass([obj class])];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Object (%@) does not respond to identification.", 
			[obj description]];
}

- (void) removeInputReferenceToObjectWithID: (NSString*) ident 
		ofType: (NSString*) type 
{
	NSMutableDictionary* refs;
	
	if(ident != nil && type != nil)
	{
		refs = [inputReferences objectForKey: type];
		if(refs != nil)
			[refs removeObjectForKey: ident];
	}	
}

- (NSArray*) outputReferencesToObjectsOfClass: (NSString*) className
{
	return [[outputReferences objectForKey: className] allValues];
}

- (NSArray*) outputReferences
{
	NSMutableArray* array = [NSMutableArray array];
	NSEnumerator* typeEnum = [outputReferences objectEnumerator];
	id types;

	while((types = [typeEnum nextObject]))
		[array addObjectsFromArray: [types allValues]];

	return array;	
}

- (void) addOutputReferenceToObject: (id) obj
{
	if([obj respondsToSelector: @selector(identification)])
	{
		[self addOutputReferenceToObjectWithID: [obj identification]
			ofType: NSStringFromClass([obj class])];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Object (%@) does not respond to identification.", 
			[obj description]];

}

- (void) addOutputReferenceToObjectWithID: (NSString*) ident
		ofType: (NSString*) type 
{
	NSMutableDictionary* refs;
	NSDictionary* dict;
	
	if(ident != nil && type != nil)
	{
		dict = [NSDictionary dictionaryWithObjectsAndKeys:
			ident, @"Identification",
			type, @"Class",
			nil];
		refs = [outputReferences objectForKey: type];
		if(refs == nil)
		{
			refs = [NSMutableDictionary dictionary];
			[outputReferences setObject: refs forKey: type];
		}
		[refs setObject: dict forKey: ident];
	}	
}

/**
Deprecated
*/
- (void) addOutputReferenceToObjectWithID: (NSString*) ident
		name: (NSString*) objectName
		ofType: (NSString*) type 
		inSchema: (NSString*) schema
		ofDatabase: (NSString*) databaseName
{
	[self addOutputReferenceToObjectWithID: ident
		ofType: type];
}

- (void) removeOutputReferenceToObject: (id) obj
{
	if([obj respondsToSelector: @selector(identification)])
	{
		[self removeOutputReferenceToObjectWithID: [obj identification]
			ofType: NSStringFromClass([obj class])];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Object (%@) does not respond to identification.", 
			[obj description]];
}

- (void) removeAllOutputReferences
{
	[outputReferences removeAllObjects];
}

- (void) removeOutputReferenceToObjectWithID: (NSString*) ident ofType: (NSString*) type 
{
	NSEnumerator* refsEnum;
	NSMutableDictionary* refs, *ref;
	
	if(ident != nil && type != nil)
	{
		refs = [outputReferences objectForKey: type];
		if(refs != nil)
			[refs removeObjectForKey: ident];
	}	
	else if(ident != nil)
	{
		//We have to find where the reference is stored
		//i.e. what type of object does ident refer to.
		refsEnum = [outputReferences objectEnumerator];
		while((refs = [refsEnum nextObject]))
			if((ref = [refs objectForKey: ident]) != nil)
				type = [ref objectForKey: @"Class"];

		if(type != nil)
		{
			refs = [outputReferences objectForKey: type];
			[refs removeObjectForKey: ident];
		}	
	}
}

- (void) removeOutputReferenceToObjectWithID: (NSString*) ident
{
	if(ident != nil)
		[self removeOutputReferenceToObjectWithID: ident
			ofType: nil];
}

/*******
NSCoding Methods
********/

- (void) _decodeOldArchive: (NSCoder*) decoder
{
	NSMutableDictionary* dataDict, *generaldata, *metadata;
	
	dataDict = [decoder decodeObjectForKey: @"DataDictionary"];
	identification = [[decoder decodeObjectForKey: @"Identification"] retain];
	inputReferences = [[decoder decodeObjectForKey: @"inputReferences"] retain];
	outputReferences = [[decoder decodeObjectForKey: @"outputReferences"] retain];
	generaldata = [dataDict objectForKey: @"General Data"];
	metadata = [dataDict objectForKey: @"Metadata"];

	//Create systemMetadata, userMetadata and properties from dataDict
	//userMetadata - Name & Keywords
	//properties - Identification, creation data and creator
	//systemMetadata - Everything else
	
	properties = [NSMutableDictionary new];
	systemMetadata = [NSMutableDictionary new];
	userMetadata = [NSMutableDictionary new];

	[userMetadata setObject: [metadata objectForKey: @"Name"]
		forKey: @"Name"];
	[userMetadata setObject: [metadata objectForKey: @"Keywords"]
		forKey: @"Keywords"];
	[metadata removeObjectForKey: @"Name"];	
	[metadata removeObjectForKey: @"Keywords"];

	[properties setObject: identification
		forKey: AdObjectIdentification];
	[properties setObject: [generaldata objectForKey: AdObjectCreator]
		forKey: AdObjectCreator];
	[properties setObject: [generaldata objectForKey: AdObjectCreationDate]
		forKey: AdObjectCreationDate];
	[properties setObject: NSStringFromClass([self class])
		forKey: AdObjectClass];
	[generaldata removeObjectForKey: AdObjectIdentification];
	[generaldata removeObjectForKey: AdObjectCreator];
	[generaldata removeObjectForKey: AdObjectCreationDate];

	[systemMetadata addEntriesFromDictionary: generaldata];
	[systemMetadata addEntriesFromDictionary: metadata];

	//Due to a bug the data ivar was not encoded
	//in the old verions. The date still exists as a formatted string
	//but it is impossible to recreate the exact date with this since
	//it doesnt contain Year information.
	
	date = nil;
}	

- (id) initWithCoder: (NSCoder*) decoder
{
	NSString* version;

	if([decoder allowsKeyedCoding])
	{
		version = [decoder decodeObjectForKey: @"version"];
		if(version == nil)
			[self _decodeOldArchive: decoder];
		else
		{
			identification = [decoder decodeObjectForKey: @"identification"]; 
			properties = [decoder decodeObjectForKey: @"properties"]; 
			userMetadata = [decoder decodeObjectForKey: @"userMetadata"]; 
			systemMetadata = [decoder decodeObjectForKey: @"systemMetadata"]; 
			inputReferences = [decoder decodeObjectForKey: @"inputReferences"]; 
			outputReferences = [decoder decodeObjectForKey: @"outputReferences"]; 
			
			//There is an incompatibility with NSDate between Cocoa and certain
			//versions of GNUstep - present in 1.13.1, not in 1.14.
			//In some situations this causes an exception to be raised on decoding date.
			//In others nil is returned  - I'm not entirely sure which versions 
			//cause which behaviour.
			//Note - the year wasn't recorded previous to version 1.21 of this class.
			//So for data created with GNUstep 1.13.1 or before AND Adun 0.8.1 or before 
			//the year will be incorrect when it is imported on a mac.
			//FIXME - Theres is still a problem with this - the data encoding in 
			//some gnustep versions causes cocoa to crash if you try to decode the
			//date - unsure of the versions or reason. 
			//Only using on GNUSTEP
			
#ifdef GNUSTEP		
			//Check for exceptions - not sure if this every actually happens on gnustep...
			NS_DURING
			{
				date = [decoder decodeObjectForKey: @"date"]; 
			}
			NS_HANDLER
			{
				date = nil;
			}
			NS_ENDHANDLER
#else				
			//On cocoa don't unarchive the date yet since it might cause a crash.
			//Have to find out how to distinguish cocoa and gnustep archives.
			date = nil;	
#endif						
			//If date is nil, create one using the formatted date string.
			if(date == nil)
				date = [NSDate dateWithNaturalLanguageString: 
					[properties objectForKey: AdObjectCreationDate]];
			
			[identification retain];
			[date retain];
			[properties retain];
			[userMetadata retain];
			[systemMetadata retain];
			[inputReferences retain];
			[outputReferences retain];
		}	
	}
	else
	{
		identification = [[decoder decodeObject] retain];
		date = [[decoder decodeObject] retain];
		properties = [[decoder decodeObject] retain];
		userMetadata = [[decoder decodeObject] retain];
		systemMetadata = [[decoder decodeObject] retain];
		inputReferences = [[decoder decodeObject] retain];
		outputReferences = [[decoder decodeObject] retain];
	}

	volatileMetadata = [NSMutableDictionary new];
	
	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeObject: identification forKey: @"identification"];
		[encoder encodeObject: date forKey: @"date"];
		[encoder encodeObject: properties forKey: @"properties"];
		[encoder encodeObject: userMetadata forKey: @"userMetadata"];
		[encoder encodeObject: systemMetadata forKey: @"systemMetadata"];
		[encoder encodeObject: inputReferences forKey: @"inputReferences"];
		[encoder encodeObject: outputReferences forKey: @"outputReferences"];
		[encoder encodeObject: @"1.7" forKey: @"version"];
	}
	else
	{
		[encoder encodeObject: identification];
		[encoder encodeObject: date];
		[encoder encodeObject: properties]; 
		[encoder encodeObject: userMetadata];
		[encoder encodeObject: systemMetadata];
		[encoder encodeObject: inputReferences];
		[encoder encodeObject: outputReferences];
	}
}

- (NSDictionary*) properties
{
	return [[properties copy] autorelease];
}

- (NSDictionary*) userMetadata
{
	return [[userMetadata copy] autorelease];
}

- (NSDictionary*) systemMetadata
{
	return [[systemMetadata copy] autorelease];
}

- (NSDictionary*) allMetadata
{
	NSMutableDictionary* allData;

	allData = [NSMutableDictionary dictionary];
	[allData addEntriesFromDictionary: userMetadata];
	[allData addEntriesFromDictionary: systemMetadata];
	[allData addEntriesFromDictionary: properties];
	return [[allData copy] autorelease];
}

- (AdMetadataDomain) domainForMetadataKey: (NSString*) aString
{
	AdMetadataDomain domain;

	if([userMetadata objectForKey: aString] != nil)
		domain = AdUserMetadataDomain;
	else if([systemMetadata objectForKey: aString] != nil)
		domain = AdSystemMetadataDomain;
	else if([properties objectForKey: aString] != nil)
		domain = AdPropertiesMetadataDomain;
	else
		domain = AdNoMetadataDomain;

	return domain;
}

- (void) setDomain: (AdMetadataDomain) aDomain forMetadataKey: (NSString*) aKey
{
	AdMetadataDomain domain;
	id value;

	domain = [self domainForMetadataKey: aKey];
	/**
	 * Do nothing if 
	 * 1) aDomain is the same as the current domain
	 * 2) The key doesnt exist.
	 * 3) domain or aDomain is AdNoMetadataDomain
	 * 4) domain or aDomain is AdPropertiesMetadataDomain
	 * 5) If the domain is not valid raise an exception
	 */
	if(domain == aDomain)
		return;
	else if(domain == AdNoMetadataDomain || aDomain == AdNoMetadataDomain)
		return;
	else if(domain == AdPropertiesMetadataDomain || aDomain == AdPropertiesMetadataDomain)
		return;
	else if(domain != AdSystemMetadataDomain 
		&& domain != AdUserMetadataDomain)
	{	
		[NSException raise: NSInvalidArgumentException
			format: @"Unknown metadata domain %d", aDomain];
	}		

	value = [self valueForMetadataKey: aKey];
	[self removeMetadataKey: aKey];
	[self setValue: value 
		forMetadataKey: aKey 
		inDomain: aDomain];
}

- (id) valueForMetadataKey: (NSString*) aString
{
	AdMetadataDomain domain;
	id value = nil;

	domain = [self domainForMetadataKey: aString];
	//domainForMetadataKey will return AdNoMetadataDomain
	//if the key has never been added. In this case we do nothing.
	if(domain == AdSystemMetadataDomain)
		value = [systemMetadata objectForKey: aString];
	else if(domain == AdUserMetadataDomain)
		value = [userMetadata objectForKey: aString];
	else if(domain == AdPropertiesMetadataDomain)
		value = [properties objectForKey: aString];
	
	return value;
}

- (void) setValue: (id) value forMetadataKey: (NSString*) aString
{
	AdMetadataDomain domain;

	domain = [self domainForMetadataKey: aString];
	//domainForMetadataKey will return AdNoMetadataDomain
	//if the key has never been added. In this case we default
	//to AdSystemMetadataDomain
	if(domain == AdNoMetadataDomain)
		domain = AdSystemMetadataDomain;
	else if(domain == AdPropertiesMetadataDomain)
	{
		NSWarnLog(@"Trying to modify the value of an object property - %@, %@",
			value,
			aString);
		return;
	}	
				
	[self setValue: value 
		forMetadataKey: aString 
		inDomain: domain];
}

- (void) setValue: (id) value 
	forMetadataKey: (NSString*) aString 
	inDomain: (AdMetadataDomain) aDomain
{
	AdMetadataDomain domain;

	//Check if this key already exists
	//If it does then aDomain must be the same as domain.
	domain = [self domainForMetadataKey: aString];
	if(domain != AdNoMetadataDomain)
		if(aDomain != domain)
			[NSException raise: NSInternalInconsistencyException
				format: @"Attempting to add an already existing key to another domain"];

	//If the domain is AdNoMetadataDomain or AdPropertiesMetadataDomain we do nothing.
	if(aDomain == AdUserMetadataDomain)
		[userMetadata setObject: value forKey: aString];
	else if(aDomain == AdSystemMetadataDomain)
		[systemMetadata setObject: value forKey: aString];
	else if(aDomain == AdPropertiesMetadataDomain)
	{
		NSWarnLog(@"Trying to modify the value of an object property - %@, %@",
			value,
			aString);
		return;
	}	
	else if(aDomain != AdNoMetadataDomain)
		[NSException raise: NSInvalidArgumentException
			format: @"Unknown metadata domain %d", aDomain];
}	

- (void) removeMetadataKey: (NSString*) aString
{
	AdMetadataDomain domain;

	domain = [self domainForMetadataKey: aString];
	//domainForMetadataKey will return AdNoMetadataDomain
	//if the key has never been added. In this case we do nothing.
	if(domain == AdSystemMetadataDomain)
		[systemMetadata removeObjectForKey: aString];
	else if(domain == AdUserMetadataDomain)
		[userMetadata removeObjectForKey: aString];
	else if(domain == AdPropertiesMetadataDomain)
	{
		NSWarnLog(@"Trying to remove object property - %@",
			aString);
		return;
	}	
}

- (id) valueForVolatileMetadataKey: (NSString*) aString
{
	return [volatileMetadata objectForKey: aString];
}

- (void) setValue: (id) value forVolatileMetadataKey: (NSString*) aString;
{
	[volatileMetadata setObject: value forKey: aString];
}

- (void) removeVolatileMetadataKey: (NSString*) aString;
{
	[volatileMetadata removeObjectForKey: aString];
}

- (NSDictionary*) volatileMetadata
{
	return [[volatileMetadata copy] autorelease];
}

- (void) updateMetadata: (NSDictionary*) values
{
	int mask = 0;

	mask = AdSystemMetadataDomain | AdUserMetadataDomain;
	[self updateMetadata: values
		inDomains: mask];
}

- (void) updateMetadata: (NSDictionary*) values inDomains: (int) domainMask
{
	NSMutableDictionary* valuesCopy;
	NSEnumerator* keyEnum;
	id key;

	//Remove any property keys in values
	valuesCopy = [values mutableCopy];
	[valuesCopy removeObjectsForKeys: 
		[NSArray arrayWithObjects: 
			AdObjectIdentification,
			AdObjectCreator,
			AdObjectCreationDate, nil]];
	
	//Remove AdPropertiesMetadataDomain and AdNoMetadataDomain if they are set
	if(domainMask & AdPropertiesMetadataDomain)
		domainMask = domainMask^AdPropertiesMetadataDomain;  
	if(domainMask & AdNoMetadataDomain)
		domainMask = domainMask^AdNoMetadataDomain;  
	
	keyEnum = [valuesCopy keyEnumerator];
	while((key = [keyEnum nextObject]))
	{
		if(domainMask & [self domainForMetadataKey: key])
		{
			[self setValue: [valuesCopy objectForKey: key]
				forMetadataKey: key];
		}		
	}		

	[valuesCopy release];
}

- (void) copyMetadataInDomains: (int) domainMask fromObject: (id) object
{
	NSDictionary* metadata;
	NSEnumerator* metadataEnum;
	NSDateFormatter* dateFormatter;
	id key;

	if(domainMask & AdUserMetadataDomain)
	{
		metadata = [object userMetadata];
		metadataEnum = [metadata keyEnumerator];
		while((key = [metadataEnum nextObject]))
			[self setValue: [metadata objectForKey: key]
				forMetadataKey: key
				inDomain: AdUserMetadataDomain];
	}			

	if(domainMask & AdUserMetadataDomain)
	{
		metadata = [object systemMetadata];
		metadataEnum = [metadata keyEnumerator];
		while((key = [metadataEnum nextObject]))
			[self setValue: [metadata objectForKey: key]
				forMetadataKey: key
				inDomain: AdSystemMetadataDomain];
	}	

	//This flag forces copying of properties (except class) - It should only be
	//used internally by AdModelObject class to produces exact copies
	//of themselves - It is not documented.
	//Using AdPropertiesMetadataDomain does nothing.
	if(domainMask & 1024)
	{
		dateFormatter = [[NSDateFormatter alloc] 
					initWithDateFormat: @"%H:%M %d/%m"
					allowNaturalLanguage: NO];
		[identification release];
		[date release];
		identification = [[object identification] retain];
		date = [[object created] retain];
		[properties setObject: [dateFormatter stringForObjectValue: date]
				forKey: AdObjectCreationDate];
		[properties setObject: [object creator]
			forKey: AdObjectCreator];
		[properties setObject: identification
			forKey: AdObjectIdentification];
			
		[dateFormatter release];	
	}
}

- (void) copyInputReferencesFromObject: (id) object
{
	NSEnumerator* referenceEnum;
	id ref;

	referenceEnum	= [[object inputReferences] objectEnumerator];
	while((ref = [referenceEnum nextObject]))
		[self addInputReferenceToObjectWithID: 
			[ref objectForKey: @"Identification"]
			ofType: [ref objectForKey: @"Class"]];
}

- (void) copyOutputReferencesFromObject: (id) object
{
	NSEnumerator* referenceEnum;
	id ref;

	referenceEnum	= [[object outputReferences] objectEnumerator];
	while((ref = [referenceEnum nextObject]))
		[self addOutputReferenceToObjectWithID: 
			[ref objectForKey: @"Identification"]
			ofType: [ref objectForKey: @"Class"]];
}

#ifndef GNUSTEP

//GNUstep and cocoa differ slightly in the implementation
//of replacementObjectForPortCoder:
//Under GNUstep when an object is being sent bycopy the NSObject
//implementation of this method automatically returns a copy.
//Under cocoa the NSObject implementation always returns a proxy -
//It must be overridden by classes that want to return copies which
//is what is done here.

- (id) replacementObjectForPortCoder: (NSPortCoder*) encoder
{
	if ([encoder isBycopy]) 
		return self;
		
	return [super replacementObjectForPortCoder:encoder];
}

#endif

@end

/*
Category containing deprecated AdModelObject methods.
These methods still work, as much as possible, before they
were deprecated. However their are unavoidable differences due
to fixing of encapsulation issues.
*/
@implementation AdModelObject (OldMetadataMethods)

- (NSMutableDictionary*) metadata
{
	return [[[self allMetadata] mutableCopy] autorelease];
}

- (NSMutableDictionary*) dataDictionary
{
	NSMutableDictionary* dataDict = [NSMutableDictionary dictionary];
	NSMutableDictionary* generaldata;
	NSMutableDictionary* metadata;

	metadata = [NSMutableDictionary dictionary];
	[metadata addEntriesFromDictionary: [self userMetadata]];
	[metadata addEntriesFromDictionary: [self systemMetadata]];

	generaldata = [[self properties] mutableCopy];
	[generaldata autorelease];

	[generaldata setObject: [metadata objectForKey: @"Database"]
		forKey: @"Database"];
	[generaldata setObject: [metadata objectForKey: @"Schema"]
		forKey: @"Schema"];
	[metadata removeObjectForKey: @"Database"];
	[metadata removeObjectForKey: @"Schema"];
	[dataDict setObject: metadata forKey: @"Metadata"];
	[dataDict setObject: generaldata forKey: @"General Data"];

	return dataDict;
}

- (NSMutableDictionary*) allData
{
	id allData;

	allData = [self allMetadata];
	allData = [[allData mutableCopy] autorelease];
	[allData addEntriesFromDictionary: properties];
	return allData;
}

@end	
