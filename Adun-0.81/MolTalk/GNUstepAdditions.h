/*
 Project: Adun
 
 Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa
 
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

#ifndef GNUSTEP_ADDITIONS
#define GNUSTEP_ADDITIONS

//This file add includes neccessary when
//building moltalk on OSX. They add the defintions
//of a number of functions and macros belonging to 
//the gnustep base additions library and hence not
//present when using Cocoa. The includes are wrapped
//in an ifndef since they aren't needed when compiling
//under gnustep. 

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#endif
