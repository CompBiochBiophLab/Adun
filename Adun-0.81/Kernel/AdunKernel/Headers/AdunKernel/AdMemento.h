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
#ifndef AD_MEMENTO
#define AD_MEMENTO
#include <Foundation/Foundation.h>

/**
The AdMemento protocol defines an interface for objects, whose state changes, to provide the ability
to recreate themselves in a previous or later state. 
\ingroup Protocols
*/

@protocol AdMemento
/**
Returns the current capture mask used by the object.
*/
- (int) captureMask;
/**
Sets the mask that dictates what information the object will include in a memento.
The available options depend on the particular object implementing the protocol.
\e mask is a bitwise OR of the options.
*/
- (void) setCaptureMask: (int) mask;
/**
Returns the reciever to the state encapsulated by stateMemento.
*/
- (void) returnToState: (id) stateMemento;
/**
Returns an object that encapsulates the current state of the object.
The type of the object can vary from class to class.
*/
- (id) captureState;
/** 
Returns YES if the \e memento can be used with
the object. NO otherwise.
*/
- (BOOL) validateMemento: (id) memento;
@end

#endif
