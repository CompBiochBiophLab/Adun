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

#include "Commands/AdEndSimulationCommand.h"

@implementation AdCore (AdEndSimulationCommand)

- (id) endSimulation: (NSDictionary*) options
{
	//Call endSimulation on the controller. This must cause
	//the controllers main loop to exit
	//and everything to terminate gracefully
	
	GSPrintf(stderr, @"Recieved end simulation command. Implementing\n");
	[controller stopSimulation: self];
	GSPrintf(stderr, @"Simulation stopped. Begining core clean up.\n");

	return nil;
}

- (NSMutableDictionary*) endSimulationOptions
{
	return nil;
}

- (NSError*) endSimulationError
{
	return [commandErrors objectForKey: @"endSimulation"];
}

@end

