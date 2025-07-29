/*
   Project: AdunServer

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-31 15:41:02 +0200 by michael johnston

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

#ifndef _ADSERVER_COMMAND_INTERFACE_
#define _ADSERVER_COMMAND_INTERFACE_
#include <Foundation/Foundation.h>

/**
This is an extension of the Kernel protocol AdCommandInterface. Each method has been expanded to allow
the UserLand to specify the process it wants the command sent to through an additional arguement \e process.
Otherwise the methods behave in exactly the same way as described in AdCommandInterface - see the documentation
there for more information.
\ingroup Protocols
*/

@protocol AdServerCommandInterface
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

#endif

