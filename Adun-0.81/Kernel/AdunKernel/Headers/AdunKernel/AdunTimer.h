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
#ifndef _ADUNTIMER_
#define _ADUNTIMER_
#include <Foundation/Foundation.h>
#include "AdunKernel/AdunDefinitions.h"

/**
\ingroup Inter
AdTimer objects are a type of \e timer. 
A \e timer waits until a specified interval has elapsed and then fires a specified message to a specified target.
AdTimer instances can contain multiple messages with different intervals. 
The interval is defined as a number of calls to the objects increment() method.
Each message has an independant counter that is incremented when AdTimer::increment is called. 
When the counter matches the desired interval the message is fired.
Each message is repeated by default i.e. Once a message is fired the counter is reset.
Each messages counter can be reset using the AdTimer::resetCounterForMessageWithName: method.

AdTimer objects hold weak references to the message targets. 

\todo Change to use NSInvocation for messages. 
*/

@interface AdTimer: NSObject 
{
	NSMutableDictionary* scheduledEvents; 
}

/**
Adds a message to the timer.
\param message The selector for the message
\param obj The target
\param interval The interval between each message
\param name The name to be associated with the message. If a message with the same name already exists the
new message replaces it
*/
- (void) sendMessage: (SEL) message toObject: (id) obj interval: (int) interval name: (NSString*) name;
/**
Removes the message called \e name
Does nothing if no message called \e name exists.
*/
- (void) removeMessageWithName: (NSString*) name;
/**
Removes all messages
*/
- (void) removeAll;
/**
Increments the timer
*/
- (void) increment;
/** 
Resets the counter for every message
*/
- (void) resetAll;
/**
Resets the counter for message called \e name
*/
- (void) resetCounterForMessageWithName: (NSString*) name;
/**
Resets the interval for the message called \e name to \e value. The 
associated scounter is not reset.
*/
-(void) resetIntervalForMessageWithName: (NSString*) name to: (unsigned int) value;
@end

/**
\ingroup Inter
AdMainLoopTimer is a singleton class representing an AdTimer instance that sits inside the
main configuration generation loop of a simulation application.
You can access it through the mainLoopTimer() class method.
*/
@interface AdMainLoopTimer: AdTimer
{
}
/**
Returns the shared AdMainLoopTimer instance for the application.
*/
+ (id) mainLoopTimer;
@end

#endif
