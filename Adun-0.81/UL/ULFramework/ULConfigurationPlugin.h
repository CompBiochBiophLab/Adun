/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-02 14:23:15 +0200 by michael johnston

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

#ifndef _ULCONFIGURATION_PLUGIN_
#define _ULCONFIGURATION_PLUGIN_

/**
This protocol defines the interface general configuration manipulation plugins
must provide
\ingroup protocols
*/

@protocol ULConfigurationPlugin 
- (NSMutableDictionary*) optionsForStructure: (id) structure;
- (id) manipulateStructure: (id) structure userOptions: (NSMutableDictionary*) options;
- (NSString*) outputString;
@end

#endif
