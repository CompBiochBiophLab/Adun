/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

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
#include "AdunKernel/AdunSystemCollection.h"
#include "AdunKernel/AdDataSources.h"

@implementation AdSystemCollection

- (id) initWithSystems: (NSArray*) anArray 
{
	NSEnumerator* arrayEnum, *systemsEnum;
	id object, system;

	if((self = [super init]))
	{		
		//check that the contents of arrayOne are AdSystems
		arrayEnum = [anArray objectEnumerator];
		while((object = [arrayEnum nextObject]))
			if(![object isKindOfClass: [AdSystem class]] && 
				![object isKindOfClass: [AdInteractionSystem class]])
				[NSException raise: NSInvalidArgumentException
					format: @"Collection can only contain AdSystem and AdInteractionSystem instances."];
		
		systems = [NSMutableArray new];
		if(anArray != nil)
			[systems addObjectsFromArray: anArray];

		fullSystems = [NSMutableArray new];
		interactionSystems = [NSMutableArray new];
		containerSystems = [NSMutableArray new];

		systemsEnum = [systems objectEnumerator];
		while((system = [systemsEnum nextObject]))
		{
			if([system isKindOfClass: [AdSystem class]])
			{
				[fullSystems addObject: system];
				if([[system dataSource] isKindOfClass: [AdContainerDataSource class]])
					[containerSystems addObject: system];
			}
			else
			{
				[interactionSystems addObject: system];
			
			}
		}	
	}

	return self;
}

- (id) init
{
	return [self initWithSystems: nil];
}

- (void) dealloc
{
	[systems release];
	[interactionSystems release];
	[fullSystems release];
	[containerSystems release];
	[super dealloc];
}

- (void) removeSystem: (id) aSystem
{
	if(![systems containsObject: aSystem])
		return;
	
	[systems removeObject: aSystem];
	
	if([aSystem isKindOfClass: [AdSystem class]]) 
	{
		[fullSystems removeObject: aSystem];
		if([[aSystem dataSource] isKindOfClass: [AdContainerDataSource class]])
			[containerSystems removeObject: aSystem];

	}
	else if([aSystem isKindOfClass: [AdInteractionSystem class]])
	{
		[interactionSystems removeObject: aSystem];
	}
}

- (void) addSystem: (id) aSystem 
{
	if([systems containsObject: aSystem])
		return;
	
	if([aSystem isKindOfClass: [AdSystem class]]) 
	{
		[systems addObject: aSystem];
		[fullSystems addObject: aSystem];
		if([[aSystem dataSource] isKindOfClass: [AdContainerDataSource class]])
			[containerSystems addObject: aSystem];

	}
	else if([aSystem isKindOfClass: [AdInteractionSystem class]])
	{
		[systems addObject: aSystem];
		[interactionSystems addObject: aSystem];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Collection can only contain AdSystem and AdInteractionSystem instances."];
}

- (void) setSystems: (NSArray*) anArray
{
	NSEnumerator* systemEnum;
	NSArray* tempHolder;
	id object;
	
	//In case something goes wrong
	tempHolder = [NSArray arrayWithArray: systems];
	[systems removeAllObjects];
	systemEnum = [anArray objectEnumerator];
	while((object = [systemEnum nextObject]))
	{
		NS_DURING 
		{
			[self addSystem: object];
		}
		NS_HANDLER
		{
			//reset state
			[systems removeAllObjects];
			[systems addObjectsFromArray: tempHolder];
			[localException raise];
		}
		NS_ENDHANDLER
	}	
}

/*
 * Coding 
 */

- (void) encodeWithCoder: (NSCoder*) encoder
{
	if([encoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Encode", @"Encoding %@", [self description]);
		[encoder encodeObject: systems forKey: @"Systems"];
		NSDebugLLog(@"Encode", @"Complete %@", [self description]);
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	NSEnumerator* systemEnum;
	id system;

	if([decoder allowsKeyedCoding])
	{
		systems = [decoder decodeObjectForKey: @"Systems"];
		[systems retain];
		fullSystems = [NSMutableArray new];
		interactionSystems = [NSMutableArray new];
		containerSystems = [NSMutableArray new];

		systemEnum = [systems objectEnumerator];
		while((system = [systemEnum nextObject]))
		{
			if([system isKindOfClass: [AdSystem class]]) 
			{
				[fullSystems addObject: system];
				if([[system dataSource] isKindOfClass: [AdContainerDataSource class]])
					[containerSystems addObject: system];

			}
			else if([system isKindOfClass: [AdInteractionSystem class]])
				[interactionSystems addObject: system];
		}	
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];

	return self;
}

/*
 * Accessors
 */

- (NSArray*) fullSystems
{
	return [[fullSystems copy] autorelease];
}

- (NSArray*) interactionSystems
{
	return [[interactionSystems copy] autorelease];
}	

- (NSArray*) allSystems
{
	return [[systems copy] autorelease];
}

- (NSArray*) containerSystems;
{
	return [[containerSystems copy] autorelease];
}

- (id) systemWithName: (NSString*) aString 
{
	BOOL foundSystem = NO;
	NSEnumerator* systemEnum;
	id system;
	
	systemEnum = [systems objectEnumerator];
	while((system = [systemEnum nextObject]))
		if([[system systemName] isEqual: aString])
		{	
			foundSystem = YES;
			break;
		}	

	if(foundSystem)
		return system;
	else
		return nil;
}

- (NSArray*) interactionSystemsInvolvingSystem: (AdSystem*) aSystem;
{
	NSEnumerator* interactionSystemsEnum;
	NSMutableArray* array = [NSMutableArray array];
	id interactionSystem;

	interactionSystemsEnum = [interactionSystems objectEnumerator];
	while((interactionSystem = [interactionSystemsEnum nextObject]))
		if([[interactionSystem systems] containsObject: aSystem])
			[array addObject: interactionSystem];

	return array;
}

- (NSString*) description
{
	return [NSString stringWithFormat: @"System collection containing %d system(s)\n%d full system(s), %d interaction system(s)",
			[systems count], [fullSystems count], [interactionSystems count]];
}

@end
