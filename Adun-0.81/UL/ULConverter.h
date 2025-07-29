/* 
   Project: UL

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
#ifndef _ULCONVERTER_
#define _ULCONVERTER_
#include <AppKit/AppKit.h>
#include "AdunKernel/AdunSimulationData.h"
#include "ULFramework/ULDatabaseInterface.h"
#include "ULInterfaceFunctions.h"
#include "ULPasteboard.h"

/**
Interface object for converting between AdModelObject
instances where possible.
\ingroup interface
*/
@interface ULConverter: NSObject
{
	id frameNumberField;
	id systemNameField;
	id simulationDetailsView;
	id systemsField;
	id tabView;
	id window;
	id simulationData;
	id databaseInterface;
	id selectedSystem;
	id systemCollection;
	id totalFramesField;
	id convertButton;
}
/**
Opens the converter
*/
- (void) open: (id) sender;
/**
Opens the converter to work on 
the data currently on the application pasteboard
*/
- (void) convert: (id) sender;
/**
Performs a conversion based on the interface values
and saves the result to the database.
*/
- (void) performConversion: (id) sender;
/**
Closes the window
*/
- (void) close: (id) sender;
@end

#endif
