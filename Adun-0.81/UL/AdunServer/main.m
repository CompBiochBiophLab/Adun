/*
   Project: AdunServer

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-31 15:40:39 +0200 by michael johnston

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
#include <AdServer.h>

int
main(int argc, const char *argv[])
{
	id pool = [[NSAutoreleasePool alloc] init];
	id server;
	NSString* adunCorePath;
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	
#ifndef GNUSTEP	
	adunCorePath = @"/usr/local/bin";
	[defaults setObject: adunCorePath forKey: @"AdunCorePath"];
	[defaults setObject: [NSHomeDirectory() stringByAppendingPathComponent: @".adun/AdunServer.log"]
		     forKey: @"LogFile"];
#else
	adunCorePath = [NSHomeDirectory() stringByAppendingPathComponent: @"GNUstep/Tools"];
	[defaults setObject: adunCorePath forKey: @"AdunCorePath"];
	[defaults setObject: [NSHomeDirectory() stringByAppendingPathComponent: @"adun/AdunServer.log"]
		forKey: @"LogFile"];
#endif 
	[defaults setObject: [NSNumber numberWithBool: YES]
		forKey: @"RedirectOutput"];
	[defaults setObject: [NSNumber numberWithInt: 1079]
		forKey: @"PortNumber"];
	[defaults setObject: [NSNumber numberWithBool: NO]
		forKey: @"IsDistributed"];
	[defaults setObject: [[ULIOManager appIOManager] databaseDir]
		forKey: @"DefaultDatabase"];

	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
	[[NSUserDefaults standardUserDefaults] synchronize];

	//create the server 
	server = [AdServer new];
	
	//wait for some communication
	[[NSRunLoop currentRunLoop] run];

  	// The end...
	[pool release];

  	return 0;
}

