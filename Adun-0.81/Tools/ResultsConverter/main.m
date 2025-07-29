/*
   Project: ResultsConverter

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-04 16:42:10 +0100 by michael johnston

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
#include "ResultsConverter.h"

int
main(int argc, const char *argv[])
{
	id pool;
	id converter;
	NSMutableDictionary* defaults;
	NSMutableSet* debugLevels;

 	pool = [[NSAutoreleasePool alloc] init];
	defaults = [NSMutableDictionary dictionary];
	debugLevels = [[NSProcessInfo processInfo] debugSet];
	[debugLevels addObjectsFromArray: [[NSUserDefaults standardUserDefaults] 
		objectForKey: @"DebugLevels"]];	
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	[[NSUserDefaults standardUserDefaults] synchronize];

	converter = [[ResultsConverter alloc] init];
	[converter main];
	[converter release];
	[pool release];

	return 0;
}


