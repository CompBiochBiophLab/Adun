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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface STTranscript: NSObject
{
	NSWindow   *window;
	id textView;
}
/**
Returns the shared transcript instance.
*/
+ (id) sharedTranscript;
/**
Prints \e anObject to the transcript
*/
- (void) show:(id)anObject;
/**
As show:() but adding a newline after \e anObject.
*/
- (void) showLine:(id)anObject;
/**
As showLine:() but adding a id stamp before \e anObject is printed.
The id stamp consists of \e ident plus the current time.
*/
- (void) showLine: (id) anObject withIDStamp: (NSString*) ident; 
/**
As showLine:() but printing the \e errorText in red
*/
- (void) showError:(NSString *)errorText;
/**
As showLine:() but printing \e aString in bold face.
*/
- (void) showSystemInformation: (NSString*) systemText;
/**
Returns a reference to the transcipt window
*/
- (NSWindow*) window;
@end
