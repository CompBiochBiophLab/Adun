/* 
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 13:29:49 +0200 by michael johnston
   
   Application Controller

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
#ifndef _ULPASTEBOARD_
#define _ULPASTEBOARD_

#include <AppKit/AppKit.h>

/**
Methods that must be implemented by a class wishing to act as a data source for ULPasteboard.
Such objects are termed "owners" when they are the current pasteboard data source.
*/
@protocol ULPasteboardDataSource
/**
 An array of the available model object types or nil if no objects are available.
 */
- (NSArray*) availableTypes;
/**
 Returns the first available object of type \e type.
 */
- (id) objectForType: (NSString*) type;
/**
 Returns an array containing the objects of type \e type
 that are available.
 Depending on who the data source is objects directly accessing it through
 this method should check the number of selected items to avoid loading more than is necessary.
 */
- (NSArray*) objectsForType: (NSString*) type;
/**
 Returns the number of objects of type \e type that are 
 available
 */
- (int) countOfObjectsForType: (NSString*) type;
/**
This message will be sent to the object if it is currently the pasteboard owner and another
object has asked to take control of it.
Objects should never try to reacquire control of the pasteboard in this method.
*/
- (void) pasteboardChangedOwner: (id) pasteboard;
@end


/**
The UL Interface (view-controller) objects use ULPasteboard to exchange model 
objects between themselves. It is like NSPasteboard except customised to the
specific requirements of the program.

Specifically its use is to allow these objects to access data that is selected in the interface
without having to know exactly where the data was selected (e.g. analyser, browser, properties panel etc.)
 
At any time the pasteboard is either 'owned' by an object that implements
the ULPasteboardDataSource protocol or has no owner. 
In the later case none of the pasteboard methods return any data.
In the former case when an object acesses data through the pasteboard 
the pasteboard retrieves the data from its current owner and passes it back to the requester.

At any time an object that implements ULPasteboardDataSource can claim ownership of the pasteboard.
The previous owner is then sent a message (pasteboardChangedOwner:()) 
allowing it to perform actions before it gives up ownership.
Thus the pasteboard will change owners quite frequently when the program is running.

\note Update to handle both single and mulitple selection
\ingroup interface
*/

@interface ULPasteboard: NSObject
{
	id pasteboardOwner;
	int changeCount;
}
+ (id) appPasteboard;
/**
An array of the available model object types or
nil if no objects are available.
*/
- (NSArray*) availableTypes;
/**
Scans the the specified types in \e anArray
for one that is present returning the first
match or nil if no match is found.
*/
- (NSString*) availableTypeFromArray: (NSArray*) anArray;
/**
Returns the first available object of type \e type
*/
- (id) objectForType: (NSString*) type;
/**
Returns an array containing the objects of type \e type
that are available.
You should always check the number of objects selected using
countOfObjectsForType:() to avoid returning more than is necessary.
That is some pasteboard owners may be retrieving the data across
an internet connection or from disk for example.
*/
- (NSArray*) objectsForType: (NSString*) type;
/**
Returns the number of objects of type \e type that are 
available
*/
- (int) countOfObjectsForType: (NSString*) type;
/**
Sets the owner of the pasteboard
*/
- (void) setPasteboardOwner: (id) object;
/**
Change count is incremented by one every time a new
owner takes control of the pasteboard
*/
- (int) changeCount;
@end

#endif
