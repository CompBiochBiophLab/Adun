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
#include "AdunKernel/AdunTimer.h"

@implementation AdTimer

- (id) init
{
	if((self = [super init]))
		scheduledEvents = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	return self;
}

- (void) dealloc
{
	[scheduledEvents release];
	[super dealloc];
}

- (void) sendMessage: (SEL) message toObject: (id) obj interval: (int) interval name: (NSString*) name
{
	NSMutableDictionary* scheduledEvent;

	scheduledEvent = [NSMutableDictionary dictionaryWithObjects: 
					[NSArray arrayWithObjects: 
						NSStringFromSelector(message), 
						[NSValue valueWithPointer: obj], 
						[NSNumber numberWithInt: interval], 
						[NSNumber numberWithInt: 0],
						nil]
				forKeys: 
					[NSArray arrayWithObjects: 
						@"Message", 
						@"Object", 
						@"Interval", 
						@"Counter",
						nil]];

	NSDebugLLog(@"AdTimer", @"Adding event %@ to %@", scheduledEvent, obj);
	[scheduledEvents setObject: scheduledEvent forKey: name];
	NSDebugLLog(@"AdTimer", @"%@ Current events %@", self, scheduledEvents);
}

- (void) removeMessageWithName: (NSString*) name
{
	NSDebugLog(@"AdTimer", @"Removing message %@", name);
	[scheduledEvents removeObjectForKey: name];
}

- (void) removeAll
{
	[scheduledEvents removeAllObjects];
}

- (void) increment
{
	NSEnumerator* eventEnumerator;
	id scheduledEvent;
	int counter;
	NSString* selectorString;

	//we have to protect against the case where the message is emptyPool
	eventEnumerator = [[scheduledEvents objectEnumerator] retain];
	while((scheduledEvent = [eventEnumerator nextObject]))
	{
		NSDebugLLog(@"AdTimer", @"Event %@", scheduledEvent);
		counter = [[scheduledEvent valueForKey: @"Counter"] intValue];
		counter++;
		if([[scheduledEvent valueForKey: @"Interval"] intValue] == counter)
		{
			NSDebugLLog(@"AdTimer", @"Firing");
			selectorString = [scheduledEvent valueForKey: @"Message"];
			[(id)[[scheduledEvent valueForKey: @"Object"] pointerValue]
				performSelector: NSSelectorFromString(selectorString)];
			[scheduledEvent setObject: [NSNumber numberWithInt: 0] forKey: @"Counter"];
		}
		else
			[scheduledEvent setObject: [NSNumber numberWithInt: counter] forKey: @"Counter"];
	}
	[eventEnumerator release];
}

- (void) resetAll
{
	NSEnumerator* eventEnumerator;
	id scheduledEvent;

	eventEnumerator = [scheduledEvents objectEnumerator];
	while((scheduledEvent = [eventEnumerator nextObject]))
		[scheduledEvent setObject: [NSNumber numberWithInt: 0] forKey: @"Counter"]; 
}

- (void) resetCounterForMessageWithName: (NSString*) name
{
	id event;

	event = [scheduledEvents objectForKey: name];
	[event setObject: [NSNumber numberWithInt: 0] forKey: @"Counter"]; 
}

-(void) resetIntervalForMessageWithName: (NSString*) name to: (unsigned int) value
{
	id event;

	event = [scheduledEvents objectForKey: name];
	[event setObject: [NSNumber numberWithInt: value] forKey: @"Interval"]; 
}

@end

static AdMainLoopTimer* mainLoopTimer;

@implementation AdMainLoopTimer

+ (void) initialize
{
	mainLoopTimer = nil;
}

+ (id) mainLoopTimer
{
	if(mainLoopTimer == nil)
		return [AdMainLoopTimer new];

	return mainLoopTimer;

}

- (id) init
{
	if(mainLoopTimer != nil)
		return mainLoopTimer;

	if(self == [super init])
		mainLoopTimer = self;	

	return self;
}

@end
