/*
   Project: AdunServer

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-31 15:42:00 +0200 by michael johnston

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

#ifndef _ULSERVERINTERFACE_
#define _ULSERVERINTERFACE_

/**
This is an extension of the Kernel protocol AdCommandInterface. Each method has been expanded to allow
the UserLand to specify the process it wants the command sent to through an additional arguement \e process.
Otherwise the methods behave in exactly the same way as described in AdCommandInterface - see the documentation
there for more information.
\ingroup protocols
*/

@protocol ULServerCommandInterface
/**
As AdCommandInterface's execute:error: with the addition of - 
\process The process the message is to be sent to
*/
- (bycopy id) execute: (NSDictionary*) commandDict error: (out NSError**) errorResult process: (id) process;
/**
As AdCommandInterface's optionsForCommand: with the addition of - 
\process The process the message is to be sent to
*/
- (NSMutableDictionary*) optionsForCommand: (NSString*) command process: (id) process;
/**
As AdCommandInterface's validCommands with the addition of - 
\process The process the message is to be sent to
*/
- (NSArray*) validCommandsForProcess: (id) process;
@end

/**
\ingroup server
Contains messages that can be sent from UL to an AdServer instance.
*/
@protocol ULServerInterface <NSObject, ULServerCommandInterface>
/**
Description forthcoming.
*/
- (oneway void) haltProcess: (id) process;
/**
Description forthcoming.
*/
- (oneway void) terminateProcess: (id) process;
/**
Description forthcoming.
*/
- (oneway void) restartProcess: (id) process;
/**
Description forthcoming.
*/
- (NSError*) startSimulation: (id) process;
/**
Informs the server the \e process, which is represented in the
server by an NSDistantObject, is about to become unavailable. 
This causes the server to store any messages that would otherwise
be sent to \e process until it reconnects.
*/
- (void) processWillDisconnect: (id) process;
/**
Reconnects a previously disconnected process, sending it any messages
that were sent during the time it was disconnected.
The process is identified by its unique id. If the process was never disonnected this
method has no effect.
If the server cant reconnect the process - e.g. it was shutdown in the intervening
period, this method returns NO. Otherwise it returns YES.
*/
- (BOOL) reconnectProcess: (id) process;
@end

#endif
