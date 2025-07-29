/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:13:34 +0200 by michael johnston

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

#ifndef _ULMOLECULECLASS_H_
#define _ULMOLECULECLASS_H_

#include <Foundation/Foundation.h>
#include "ULMolecularLibraryNode.h"
#include "ULMoleculeNode.h"

@interface ULMoleculeClassNode : ULMolecularLibraryNode
{

}

/**
Searchs through child molecule nodes for one whose name attribute matches moleculeName 
and returns it. Returns nil if it cant find a match. The name attribute is defined by
the MolecularLibrary you being searched. If the name is defined by another source e.g. pdb etc
the use findMoleculeWithExternalName:fromSource.
\param moleculeName The name of the molecule you are searching for
\return The matching molecule node 
\todo Add methods that search for and return multiple matches
*/
- (id) findMoleculeNodeWithName: (NSString*) moleculeName;
/**
Returns the className for this node. (its name attribute)
** Not Implemented **
*/
- (id) className;
/**
Searchs through child molecule modes for one who has an externaly defined name from \e source matching
\e moleculeName
\param moleculeName The name of a molecule
\param source The source where this name was defined
\return The matching molecule node
** Not Implemented **
*/
- (id) findMoleculeWithExternalName:(NSString*) moleculeName fromSource: (NSString*) source;
@end

#endif // _ULMOLECULECLASS_H_

