/**

   Project: ULApplicationScripting

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

   Author: Stefan Urbanek
   Modified for Adun by: Michael Johnston 

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


#include "STTranscript.h"
#include <ULFramework/ULFrameworkDefinitions.h>

static STTranscript *sharedTranscript;
static NSDictionary  *errorTextAttributes;
static NSDictionary  *normalTextAttributes;
static NSDictionary  *systemTextAttributes;

@implementation STTranscript

+ (void) initialize
{
	errorTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSColor redColor], NSForegroundColorAttributeName,
				[NSFont userFontOfSize: 12], NSFontAttributeName,
				nil];

	normalTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSColor blackColor], NSForegroundColorAttributeName,
				[NSFont userFontOfSize: 12], NSFontAttributeName,
				nil];
	
	systemTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSColor blackColor], NSForegroundColorAttributeName,
				[NSFont boldSystemFontOfSize: 12], NSFontAttributeName,
				nil];
	sharedTranscript = nil;				
}

+ (id) sharedTranscript
{
	if(!sharedTranscript)
		sharedTranscript = [STTranscript new];

	return [[sharedTranscript retain] autorelease];
}

- (id) init
{
	if(sharedTranscript != nil)
		return [sharedTranscript retain];

	if((self = [super init]))
	{
		[window setTitle:@"Scripting Transcript"];
		[window setFrameUsingName:@"STTranscriptWindow"];
		[window setFrameAutosaveName:@"STTranscriptWindow"];				
	}	 
    	
	return self;
}

- (void) awakeFromNib
{
#ifndef GNUSTEP
	//NSTextView API is different on Cocoa
	//Specifically replaceCharactersInRange:withAttributedString:
	//isnt a method. However its a method of NSTextStorage so
	//on Cocoa we have textView refer to the container.
	textView = [textView textStorage];
#endif
}

- (void) show:(id)anObject
{
	NSString *string;
	NSAttributedString* attributedString;

	if( [anObject isKindOfClass:[NSString class]] )
	{
		string = anObject;
	}
	else if ([anObject isKindOfClass: [NSNumber class]])
	{
		string = [anObject stringValue];
	}
	else
	{
		string = [anObject description];
	}

	attributedString = [[NSAttributedString alloc]
				initWithString: string
				attributes: normalTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0)
		withAttributedString: attributedString];
	[attributedString release];	
}

- (void) showLine:(id)anObject
{
	NSAttributedString* attributedString;

	attributedString = [[NSAttributedString alloc]
				initWithString: @"\n"
				attributes: normalTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0) 
		withAttributedString: attributedString];
	[attributedString release];	

	[self show:anObject];
}

- (void) showLine: (id) anObject withIDStamp: (NSString*) ident 
{
	NSString* stamp;
	NSDateFormatter* formatter;
	
	formatter = [[NSDateFormatter alloc] 
			initWithDateFormat: @"%H:%M:%S %d/%m"
			allowNaturalLanguage: NO];

	stamp = [NSString stringWithFormat: @"%@\t%@ :", 
			ident, 
			[formatter stringForObjectValue: [NSDate date]]];
	[formatter release];

	anObject = [NSString stringWithFormat: @"%@\t%@", stamp, anObject];
	[self showLine: anObject];
}

- (NSWindow *)window
{
	return window;
}

- (void) showError:(NSString *)errorText
{
	NSAttributedString *aString;

	aString = [[NSAttributedString alloc]
			initWithString:@"\n"
			attributes: normalTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0)
		withAttributedString: aString];

	RELEASE(aString);

	aString = [[NSAttributedString alloc] 
			initWithString: errorText
			attributes: errorTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0)
		withAttributedString: aString];

	RELEASE(aString);
}

- (void) showSystemInformation: (NSString*) systemText
{
	NSAttributedString *aString;

	aString = [[NSAttributedString alloc]
			initWithString: @"\n"
			attributes: normalTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0)
		withAttributedString: aString];

	RELEASE(aString);

	aString = [[NSAttributedString alloc] 
			initWithString: systemText
			attributes: systemTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0)
		withAttributedString: aString];

	RELEASE(aString);

	aString = [[NSAttributedString alloc]
			initWithString: @"\n"
			attributes: normalTextAttributes];
	[textView replaceCharactersInRange: NSMakeRange(0,0)
		withAttributedString: aString];

	RELEASE(aString);
}

@end
