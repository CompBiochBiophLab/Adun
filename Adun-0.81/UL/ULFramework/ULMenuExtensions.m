/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston 

   Created: 2005-12-09 14:47:28 +0100 by michael johnston

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
#include "ULFramework/ULMenuExtensions.h"

@implementation NSMutableDictionary (ULMenuExtensions)

+ (id) newLeafMenu
{
	NSMutableDictionary* dictionary;
	
	dictionary = [NSMutableDictionary new];
	
	[dictionary setObject: [NSMutableArray array]
		forKey: @"Selection"];
	[dictionary setObject: @"Single"
		forKey: @"Type"];
	[dictionary setObject: [NSMutableArray array]
		forKey: @"Items"];
	
	return [dictionary autorelease];
}

+ (id) newNodeMenu: (BOOL) flag
{
	NSMutableDictionary* dictionary;

	dictionary = [NSMutableDictionary new];

	if(flag)
	{
		[dictionary setObject: [NSMutableArray array]
			forKey: @"Selection"];
		[dictionary setObject: @"Single"
			forKey: @"Type"];
	}

	return [dictionary autorelease];
}

- (BOOL) isNodeMenu
{
	if([self objectForKey: @"Items"] != nil)
		return NO;
	else
		return YES;
}

- (void) setSelectionMenuType: (NSString*) type
{
	if([self objectForKey: @"Type"] == nil)
	{
		NSWarnLog(@"Not a selection menu");
		return;
	}	

	[self setObject: type forKey: @"Type"];
}

- (NSString*) selectionMenuType
{
	return [self objectForKey: @"Type"];
}

- (NSArray*) selectedItems
{
	return [self objectForKey: @"Selection"];
}

- (void) setDefaultSelection: (NSString*) name
{
	if([self isNodeMenu])
	{	
		if([self objectForKey: name] == nil)
			return;
	}
	else
	{
		if(![[self objectForKey:@"Items"] 
			containsObject: name])
			return;
	}		

	[[self objectForKey: @"Selection"] 
		addObject: name];	
}

- (void) setDefaultSelections: (NSArray*) anArray
{
	BOOL nameError = NO;
	NSEnumerator* arrayEnum;
	NSString* aString;
		
	arrayEnum = [anArray objectEnumerator];	
	while((aString = [arrayEnum nextObject]))
	{
		if([self isNodeMenu])
		{	
			if(![[self objectForKey: aString] isKindOfClass: [NSDictionary class]])
				nameError = YES;
		}
		else
		{
			if(![[self objectForKey:@"Items"] 
				containsObject: aString])
				nameError = YES;
		}	

		if(nameError)
			break;
	}

	if(!nameError)
		[[self objectForKey: @"Selection"]
			addObjectsFromArray: anArray];
}

- (void) addMenuItem: (NSString*) aString
{
	if([self isNodeMenu])
	{
		NSWarnLog(@"This method is only for use with leaf menus");
		return;
	}	

	[[self objectForKey: @"Items"] 
		addObject: aString];
}

- (void) addMenuItems: (NSArray*) anArray
{	
	if([self isNodeMenu])
	{
		NSWarnLog(@"This method is only for use with leaf menus");
		return;
	}	

	[[self objectForKey: @"Items"] 
		addObjectsFromArray: anArray];
}

- (NSArray*) menuItems
{
	NSArray* items;
	NSMutableArray* temp;

	if([self isNodeMenu])
		items = [self allKeys];
	else	
		items = [self objectForKey: @"Items"];
	
	if([items containsObject: @"Selection"])
	{
		temp = [items mutableCopy];
		[temp removeObject: @"Selection"];
		[temp removeObject: @"Type"];
		items = [NSArray arrayWithArray: temp];
		[temp release];
	}

	return items;
}

- (void) addMenuItem: (NSString*) aString withValue: (id) value
{
	if(![self isNodeMenu])
	{
		NSWarnLog(@"This method is only for use with node menus");
		return;
	}	

	[self setObject: value forKey: aString];
}

- (void) removeMenuItem: (NSString*) aString
{
	NSMutableArray* items;

	if(![self isNodeMenu])
	{
		items = [self objectForKey: @"Items"];
		if([items containsObject: aString])
			[items removeObject: aString];
	}	
	else
		[self removeObjectForKey: aString];
}

- (id) valueForMenuItem: (NSString*) string
{
	if(![self isNodeMenu])
	{
		NSWarnLog(@"This method is only for use with node menus");
		return nil;
	}	

	return [self objectForKey: string];
}

- (void) selectMenuItem: (NSString*) string
{
	if([self isNodeMenu])
	{
		NSWarnLog(@"This method is only for use with leaf menus");
		return;
	}	
	
	if(![[self menuItems] containsObject: string])
	{
		[NSException raise: NSInvalidArgumentException 
			format: @"Selection menu contains no entry %@", string];
	}
	else
	{
		if([[self selectionMenuType] isEqual: @"Single"])
			[[self objectForKey: @"Selection"] removeAllObjects];
		
		[[self objectForKey: @"Selection"] addObject: string];
	}
}

- (void) deselectMenuItem: (NSString*) string
{
	if([self isNodeMenu])
	{
		NSWarnLog(@"This method is only for use with leaf menus");
		return;
	}	
	
	if(![[self menuItems] containsObject: string])
	{
		[NSException raise: NSInvalidArgumentException 
			    format: @"Selection menu contains no entry %@", string];
	}
	else
	{
		if([[self objectForKey: @"Selection"] containsObject: string])
			[[self objectForKey: @"Selection"] removeObject: string];
		else
			NSWarnLog(@"Cannot deselect %@ - Not selected!", string);
	}
}

@end

