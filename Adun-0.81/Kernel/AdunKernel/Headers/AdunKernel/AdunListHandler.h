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
#ifndef ADUN_LISTHANDLER_
#define ADUN_LISTHANDLER_

#include "Base/AdVector.h"
#include "Base/AdLinkedList.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunLinkedList.h"

/**
\ingroup Inter
AdListHandler is an abstract class that represents an object that creates and maintains a dynamic linked list of element pairs.
The elements are distributed throughout a volume of space and the pairs allowed in the list are restricted by a cutoff condition.
Since the positions of the elements can change the pairs meeting the condition can
also change. Calling the update() method of an AdListHandler subclass causes it to recalculate the list. 

The problem of finding all the pairs of elements that are seperated by less than a given distance is \f$O(n^{2})\f$ if
a brute search is used (assuming all pairs are allowed).
Since such lists are common in molecular simulations and must be updated relatively
frequently \f$O(n^{2})\f$ performance is not desirable. Hence there are various algorithms for speeding up the
update process and each subclass of AdListHandler encapsulates one of these.

AdListHandler instances can have a delegate who is notified when the list is updated or invalidated. Delegate objects must
conform to the AdListHandlerDelegate protocol.

AdListHandler subclasses should observe AdSystemContentsDidChangeNotification's from their system and use
the handlerDidHandleContentChange: method to notify their delegate. See the method documentation for more.

\b Requirements

The position of the elements is given by the matrix returned by AdSystem::coordinates. Each element is assigned an index 
corresponding to its row in this matrix (starting with 0).

Each element can have an associated NSIndexSet that contains the indexes of the elements it can be paired with. 
Only elements with higher indexes should be included since pairs with lower index elements should be taken 
into account in their index sets.
In practice AdListHandler objects require an array of these index sets. The first NSIndexSet in the array corresponds to the first
element in the coordinate matrix and so on. Hence if an element has no allowed pairs but higher elements do
an NSIndexSet still must be present in the array so the correct correspondance is maintained 

\todo Desired Functionality - ListHandlers should be able to create lists inside or outside the specified cutoff
\todo Desired Functionality - Possibly implement a method that returns a subset of the list matching a certain criteria?
Although this would have to be an array and then you would need to create different functions for lists or array
\todo Missing Functionality - Ability to specify no cutoff?

*/

@interface AdListHandler: NSObject 
/**
Returns a newly initialised AdListHandler instance that creates and manages a list of the
pairs of elements of \e aSystem that are separated by less than \e aDouble. The allowed pairs
are restricted to those specified by \e anArray.
\param aSystem An AdSystem or AdInteractionSystem object.
\param anArray An NSArray of NSIndexSets specifying the allowed pairs.
\param aDouble The cutoff. Cannot be less than 0. If it is it defaults to 12.
\todo Missing functionality - If allowedPairs is nil the object should assume all pairs are allowed. 
*/
- (id) initWithSystem: (id) aSystem allowedPairs: (NSArray*) anArray cutoff: (double) aDouble;
/**
Creates the list. Does nothing if it has been already called for the current system
and array of allowed pairs of it either of these is nil.

If the number of elements in the array returned by allowedPairs() is greater than the 
number of elements in system() an NSInternalInconsistencyException is raised. 
*/
- (void) createList;
/**
Updates the lists removing pairs who have moved outside the cutoff
and adding pairs that have moved inside. Has no effect if createList()
has not been called once with the current system and the current
array of allowed pairs. In this case the delegate does not receive an
handlerDidUpdateList: message.
*/
- (void) update;
/**
Returns the cutoff.
*/
- (double) cutoff;
/**
Sets the cutoff used to \e aValue. The list is not updated until
update() is called. If cutoff is less than 0 an NSInvalidArgumentException
is raised.
*/
- (void) setCutoff: (double) aValue;
/**
Sets the system to \e aSystem. The previous list is destroyed and a new
list must be created by calling createList(). The receivers delegate will
receive a handlerDidInvalidateList: message. 

The receiver observes AdSystemContentsDidChangeNotification from \e aSystem. 
On receiving such a notification the AdListHandler object invalidates its list and
sends a handlerDidInvalidateList: message to its delegate. createList() must be
called to recreate the list.
*/
- (void) setSystem: (id) aSystem;
/**
Returns the system.
\return An AdSystem or AdInteractionSystem instance.
*/
- (id) system;
/**
Sets the allowed pairs.  
The previous list is destroyed and a new list must be created by calling createList().
The receivers delegate will receive a handlerDidInvalidateList: message.
*/ 
- (void) setAllowedPairs: (NSArray*) anArray;
/**
Returns the array of allowed pairs
\return An NSArray of NSIndexSets.
*/
- (NSArray*) allowedPairs;
/**
Returns a pointer to the start of the linked list. This pointer may become
invalidated e.g. due to setSystem:() or setAllowedPairs:() being called. 
Hence the object using this list should also be the AdListHandler objects
delegate so it can recieve handlerDidInvalidateList: messages. If the list
has not been created this method will return a NULL pointer.
*/
- (NSValue*) pairList;
/**
Returns the number of objects in the linked list. Does not include the start and end elements.
*/
- (int) numberOfListElements;
/**
Sets the objects delegate to \e delegate. \e delegate
must conform to the AdListHandlerDelegate protocol. If not an NSInvalidArgumentException 
is raised. \e anObject  is not retained.
*/
- (void) setDelegate: (id) anObject;
/**
Returns the current delegate
*/
- (id) delegate;
@end

/**
\ingroup Protocols
Protocol containing methods that must
be implemented by objects wishing to act as 
delegates for AdListHandler objects.
*/
@protocol AdListHandlerDelegate
/**
Sent after the AdListHandler object updates its list.
*/
- (void) handlerDidUpdateList: (AdListHandler*) listHandler;
/**
Sent when the AdListHandler object destroys its list. Do not attempt
to recreate the list in this method as the internal state of the sender
is not known. It should only be used to ensure the invalidate pointer
is not used.
*/
- (void) handlerDidInvalidateList: (AdListHandler*) listHandler;
/**
Sent after the AdListHandler receives an AdSystemContentsDidChangeNotification
from its system and updates itself. This method should be used by the delegate 
instead of observing the AdSystemContentsDidChangeNotification 
itself to ensure that the handler is updated before the delegate performs its own updates.
i.e. The order in which the objects would recieve the notification is undefined.
This is especially important since the delegate will need to reset the allowed pairs
and recreate the list after a system contents change
*/
- (void) handlerDidHandleContentChange: (AdListHandler*) listHandler;
@end

#endif

