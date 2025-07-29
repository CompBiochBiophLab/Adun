/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-06 12:17:25 +0200 by michael johnston

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

#ifndef _ULTOPOLOGYFRAMEBUILDER_H_
#define _ULTOPOLOGYFRAMEBUILDER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataMatrix.h>
#include "XMLLib/XMLLib.h"

/**
ULTopologyFrameBuilder builds the expected topology of a molecule
based on a molecule id or sequence of molecule-ids e.g. a macromolecule.
\note Have to add error handling for when the residue library we are using
doesnt include a residue found in the sequence
\ingroup classes
*/


@interface ULTopologyFrameBuilder : NSObject
{
	id topologyLibrary;	//!< An adun topology library mapped into memory as an XML document tree
	NSMutableString* buildString;
	NSString* forceField;
}

/**
Returns a new ULTopologyFrameBuilder instance that builds topology using the forceField
called \e aString
\param forceField The name of the force field to use
\return A new ULTopologyFrameBuilder instance
*/

- (id) initForForceField: (NSString*) aString;

/**
Build and returns the topology for the system described by \e sequence. The system can be
a mixture of macromolecules, molecules and indivdual atoms.
\param sequence The sequence of molecule id's that describe the system.
\param option A dictionary of options for the build
\return The topology of the molecule
*/
- (id) buildTopologyForSystem: (NSArray*) sequence 
		withOptions: (NSDictionary*) options
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo;

@end

#endif // _ULTOPOLOGYFRAMEBUILDER_H_

