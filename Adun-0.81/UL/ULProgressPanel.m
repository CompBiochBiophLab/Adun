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

#include <AppKit/AppKit.h>
#include "ULProgressPanel.h"

@implementation ULProgressPanel

+ (id) progressPanelWithTitle: (NSString*) string1 
	message: (NSString*) string2 
	progressInfo: (NSString*) string3
{
	id object;

	object = [[ULProgressPanel alloc] 
			initWithTitle: string1 
			message: string2 
			progressInfo: string3];
	return [object autorelease];
}

- (id) init
{
	return [self initWithTitle: @"Progress" message: nil progressInfo: nil];
}

- (id) initWithTitle: (NSString*) string1 message: (NSString*) string2 progressInfo: (NSString*) string3
{
	if(self = [super init])
	{
		if([NSBundle loadNibNamed: @"ProgressPanel" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface for ULProgressPanel");
			return nil;
		}

		if(string1 != nil)
			[panel setTitle: string1];
		else
			[panel setTitle: @"Operation in Progress"];

		if(string2 != nil)
			[displayTitle setStringValue: string2];
		else
			[displayTitle setStringValue: @"Progress"];

		if(string3 != nil)
			[userInfo setStringValue: string3];
		else
			[userInfo setStringValue: @""];

		userInfoString = [[userInfo stringValue] retain];
		modalMode = YES;
		[progressBar setDoubleValue: 100.0];
		[displayTitle setFont: [NSFont systemFontOfSize: 14]];
		observingNotification = NO;
		
	}

	return self;
}

- (void) dealloc
{
	[userInfoString release];
	[super dealloc];
}

- (void) endPanel
{
	NSEvent* updateEvent;
	id window;

	[panel orderOut: self];

	//make sure we are in a modal session
	//and the panel is the modal window

	if((window = [NSApp modalWindow]) != nil)
		if(modalMode && [window isEqual: panel])
		{
			[NSApp stopModalWithCode: NSRunAbortedResponse];

			//there is a problem with abortModal that stops the
			//interface widgits from responding to events
			//However using anything else means the interface wont be
			//updated until the user does something - this can lead
			//to the application just hanging there. To prevent this
			//we have to simulate an event

			updateEvent = [NSEvent mouseEventWithType: NSMouseMoved
				location: NSMakePoint(0,0)
				modifierFlags: 0
				timestamp: 0
				windowNumber: 0
				context: [NSGraphicsContext currentContext]
				eventNumber: 1
				clickCount: 1
				pressure: 1.0];
			 
			[NSApp postEvent: updateEvent atStart: YES];
		}
	
	[panel close];
}

- (void) runProgressPanel: (BOOL) flag
{
	NSEvent* updateEvent;

	[panel center];
	if(flag)
	{
		modalMode = YES;
		[NSApp runModalForWindow: panel];
	}
	else
	{
		modalMode = NO;

		[progressBar setNeedsDisplay: YES];
		[userInfo setNeedsDisplay: YES];
		[displayTitle setNeedsDisplay: YES];
		[panel makeKeyAndOrderFront: self];
		[panel display];
		
		/*updateEvent = [NSEvent mouseEventWithType: NSMouseMoved
				location: NSMakePoint(0,0)
				modifierFlags: 0
				timestamp: 0
				windowNumber: 0
				context: [NSGraphicsContext currentContext]
				eventNumber: 1
				clickCount: 1
				pressure: 1.0];
			 
		[NSApp postEvent: updateEvent atStart: YES];*/

		[NSApp updateWindows];
		[progressBar display];
		[displayTitle display];
	}
}

- (void) setPanelTitle: (NSString*) string
{
	[panel setTitle: string];
}

- (void) setMessage: (NSString*) string
{
	[displayTitle setStringValue: string];
	[panel display];
}

-(void) setProgressInfo: (NSString*) string
{
	[userInfoString release];
	[userInfo setStringValue: string];
	userInfoString = [string retain];
	[panel display];
}

- (void) _incrementFromNotification: (NSNotification*) aNotification
{
	int currentStep, totalSteps;
	double percent;
	NSNumber* aNumber;
	NSString* infoString;

	aNumber = [[aNotification userInfo] objectForKey: @"ULProgressOperationCompletedSteps"];
	//Check for old key ULAnalysisPluginCompletedSteps
	if(aNumber == nil)
		aNumber = [[aNotification userInfo] objectForKey: @"ULAnalysisPluginCompletedSteps"];
		
	if(aNumber == nil)
	{
		NSWarnLog(@"Progess notification user info does not contain ULProgressOperationCompletedSteps");
		aNumber = 0;
	}		
	else
		currentStep = [aNumber intValue];

	aNumber = [[aNotification userInfo] objectForKey: @"ULProgressOperationTotalSteps"];
	//Check for old key ULAnalysisPluginTotalSteps
	if(aNumber == nil)
		aNumber = [[aNotification userInfo] objectForKey: @"ULAnalysisPluginTotalSteps"];
		
	if(aNumber == nil)
	{
		NSWarnLog(@"Progess notification user info does not contain ULProgressOperationTotalSteps");
		totalSteps=100;
	}		
	else
		totalSteps = [aNumber intValue];

	percent =  ((double)currentStep)/totalSteps*100;
	
	infoString = [[aNotification userInfo] objectForKey: @"ULProgressOperationInfoString"];
	if(infoString == nil)
		infoString = [NSString stringWithFormat: @"%@ %-4.0lf\%", userInfoString, percent];
	
	[userInfo setStringValue: infoString];
	[progressBar setDoubleValue: percent];
	[progressBar displayIfNeeded];
	[userInfo displayIfNeeded];
}

- (BOOL) updateStatusOnNotification: (NSString*) notificationName fromObject: (id) object
{
	if(!observingNotification)
	{
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(_incrementFromNotification:)
			name: notificationName
			object: object];
		observingNotification = YES;
		return YES;
	}
	else
	{
		NSWarnLog(@"Unable to observe notification - Already one registered");
		return NO;
	}
}

- (void) removeStatusNotification: (NSString*) notificationName fromObject: object
{
	[[NSNotificationCenter defaultCenter] removeObserver: self
		name: notificationName
		object: object];
	observingNotification = NO;
}

- (void) setProgressBarValue: (NSNumber*) value
{
	int number;

	number = [value doubleValue];

	if(number > [progressBar maxValue])
		number = [progressBar maxValue];
	else if(number < [progressBar minValue])
		number = [progressBar minValue];
	
	[progressBar setDoubleValue: number];
}

- (void) setIndeterminate: (BOOL) value
{
	[progressBar displayIfNeeded];
	[progressBar setDoubleValue: 100];
	[progressBar setIndeterminate: value];
	[progressBar displayIfNeeded];
}

- (void) orderFront
{
	[panel orderFront: self];
}

@end
