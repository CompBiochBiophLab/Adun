/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:14:15 +0200 by michael johnston

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

#ifndef _ULCONNECTIVITYNODE_H_
#define _ULCONNECTIVITYNODE_H_

#include <Foundation/Foundation.h>
#include "ULMolecularLibraryNode.h"
#include <stdbool.h>

@interface ULConnectivityNode : ULMolecularLibraryNode
{
	AdMutableDataMatrix* connectivityMatrix;
}

/**
Returns the connectivityMatrix as a AdDataMatrix. The indices in the matrix
correspond to the index attributes of the atom elements in the molecule.
i.e. the first atom in the molecule has index one
*/
- (AdDataMatrix*) connectivityMatrix;
/**
Returns the connectivityMatrix as a AdDataMatrix. The indices in the matrix
are offset from their original values by adding \e offset to them.
(Useful when the molecule is part of a larger structure)
*/
- (AdDataMatrix*) connectivityMatrixWithOffset: (int) offset;

@end

#endif // _ULCONNECTIVITYNODE_H_

