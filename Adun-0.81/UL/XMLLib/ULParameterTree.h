/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-07 13:00:20 +0200 by michael johnston

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

#ifndef _ULPARAMETERTREE_H_
#define _ULPARAMETERTREE_H_

#include <Foundation/Foundation.h>
#include "ULParameterNode.h"
#include <stdbool.h>

/**
Creates and contains a document tree of a ULParameter xml file
**/

@interface ULParameterTree : ULParameterNode
{

}

/**
Returns an NSArray of ULClassNodes, one for each topology type,
whose name is equal to className e.g. Lipids, NucleicAcids, Generic.
If for any topology type a class with className doesnt exist then
the generic class, if it exists, is substituted. If this doesnt exist
an error is raised (not implemented yet. Instead we just exit)
*/

- (NSMutableDictionary*) topologiesForClass: (NSString*) className;

@end

#endif // _ULPARAMETERTREE_H_

