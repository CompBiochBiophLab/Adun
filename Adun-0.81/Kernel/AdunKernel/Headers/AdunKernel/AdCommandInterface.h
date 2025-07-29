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
#ifndef _ADCOMMAND_INTERFACE_
#define _ADCOMMAND_INTERFACE_
#include <Foundation/Foundation.h>

/**
Defines the methods available for remotely interacting with the simulator.

\note AdCommandInterface inherits NSObjects protocols because otherwise
its impossible to get any information from the vended interface.
i.e. AdunCore sends an interface to AdunServer which is a NSProtocolChecker
with AdCommandInterface as the protocol. This limits the messages that
can be sent to those listed below eliminating all others - even basic
ones like description etc. Thus constant exceptions are raised if
you try to print an array containing the NSProtocolChecker instance etc.
The inheritance of the NSObject protocol can be removed one everthing is
deemed stable.

\ingroup coreProtocols
*/

@protocol AdCommandInterface <NSObject>
/**
Executes the command defined by commandDict.
\param commandDict A dictionary defining the command to be exectuted. If must contain two keys -
- \e Command  The name of the command
- \e Options  The options dictionary for the command as returned by optionsForCommand:().
If the command or options are invalid an NSInvalidArgumentException is raised.
\param errorResult A pointer to an uninitialised NSError object. If the command
fails (for reasons other than invalid arguments) the NSError object contains information about the cause.
Otherwise errorResult is nil.
\return The return value is determined by the command being exectuted and will be
nil if the command returns no result.
*/
- (bycopy id) execute: (in NSDictionary*) commandDict error: (out NSError**) errorResult;
/**
Returns a dictionary containing the options for \e command.
\param command The name of the command.
\return A NSMutableDictionary whose keys are \e commands arguments. The object associated with
each key is the arguments default value.
*/
- (NSMutableDictionary*) optionsForCommand: (NSString*) command;
/**
Returns the available commands.
*/
- (NSArray*) validCommands;
@end

#endif

