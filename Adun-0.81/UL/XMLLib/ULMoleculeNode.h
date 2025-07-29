/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:13:59 +0200 by michael johnston

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

#ifndef _ULMOLECULENODE_H_
#define _ULMOLECULENODE_H_

#include <stdbool.h>
#include <Foundation/Foundation.h>
#include "ULMolecularLibraryNode.h"

/**
Keys:

\li \c NumberOfAtoms

*/

@interface ULMoleculeNode : ULMolecularLibraryNode
{
	bool isMonomer;
	bool monomerCheck;
	NSMutableArray* bondedAtomsList;
}

/**
Returns trues if this molecule is a monomer, false otherwise
*/
- (bool) isMonomer;

/**
Returns an array of the library defined atom name for the atoms in the molecule
*/
- (NSArray*) atomNames;

/**
Returns an array of the names defined by the external source \source for the atoms
\param source The source that defined the names
*/
- (NSArray*) atomNamesFromExternalSource: (NSString*) source;

/**
Calls connectivityMatrix: on its child ULConnectivityNode and returns the result
*/
-(AdDataMatrix*) connectivityMatrix;
/**
Calls connectivityMatrixWithOffset: on its child ULConnectivityNode and returns the result
*/
-(AdDataMatrix*) connectivityMatrixWithOffset: (int) offset;

-(NSMutableArray*) bondedAtomsListWithOffset: (int) offset;
-(NSMutableArray*) bondedAtomsList;

/**
The name of the molecule
*/
- (NSString*) moleculeName;

- (int) connectionForDirection: (NSString*) direction;

/** 
Returns an array containing the partial charges for the atoms in the molecule
*/
- (NSArray*) partialCharges;

@end
#endif // _ULMOLECULENODE_H_

