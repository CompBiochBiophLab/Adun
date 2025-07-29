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
#ifndef _ADCORE_COMMAND_
#define _ADCORE_COMMAND_
#include <Foundation/Foundation.h>
/**
Defined the methods for interface
with AdCores commands
\ingroup coreProtocols
*/

@protocol AdCoreCommand
/**
Returns the default options dictionary for \e command.
Returns nil if command has no options or is not valid.
*/
- (NSMutableDictionary*) optionsForCommand: (NSString*) name;
/**
Returns the NSError object corresponding to the last time \e command
was executed. If there was no error or \e command does not exist returns nil
*/
- (NSError*) errorForCommand: (NSString*) name; 
/**
Returns an array containing the names of the commands the core
responds to
**/
- (NSArray*) validCommands;
/**
Returns YES if command is a validCommand. NO otherwise
*/
- (BOOL) validateCommand: (NSString*) name;
/**
Creates an error object with domain AdCoreCommandErrorDomain and localized description
description for command \e name which can then be retrieved with errorForCommand:
*/
- (void) setErrorForCommand: (NSString*) name description: (NSString*) description;
@end

#endif

