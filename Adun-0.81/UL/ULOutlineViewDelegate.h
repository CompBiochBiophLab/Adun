/*
   Project: UL

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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
#ifndef _ULOUTLINEVIEWDELEGATE_
#define _ULOUTLINEVIEWDELEGATE_
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "ULFramework/ULFrameworkDefinitions.h"

/**
Preliminary implementation.
\todo Put options/properties dependant functionality into subclasses
\todo Update to use ULMenuExtensions methods
\ingroup interface
*/

@interface ULOutlineViewDelegate: NSObject
{
	BOOL valueEditing;
	BOOL isProperties;
	id wrappedOptions;
	NSString* outlineColumnIdentifier;
}	
/**
Documentation forthcoming
*/
- (id) initWithProperties: (id) properties allowEditing: (BOOL) value;
/**
Documentation forthcoming
*/
- (id) initWithOptions: (id) options;
/**
Documentation forthcoming
*/
- (id) initWithOptions: (id) options outlineColumnIdentifier: (NSString*) aString;
@end

#endif
