/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-15 16:52:34 +0200 by michael johnston

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

#ifndef _ULSIMPLEMERGERDELEGATE_H_
#define _ULSIMPLEMERGERDELEGATE_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataMatrix.h>
#include "ULFramework/ULMergerDelegate.h"

/**
\ingroup classes
*/

@interface ULSimpleMergerDelegate : NSObject <ULMergerDelegate>
{
	int numberOfResidues;
	int currentResidueIndex;
	NSMutableArray* indexes; 
	NSMutableArray* missingAtoms; //!< Indexes of the atoms of the current molecule which are not in the configuration
	NSMutableArray* unidentifiedAtoms; //!< Indexes of the atoms in the configuration which are not in the topology
	NSMutableIndexSet* totalMissingAtoms; //!Indexs of all the missing atoms
	NSMutableDictionary *missingAtomsDict; //!< Dictionary of residues and their missing atoms
	NSMutableDictionary *extraAtomsDict; //!< Dictionary of residues and their extra atoms
	id configuration;
	id topologyFrame;
	id bondedAtomsList;
	FILE* buildOutput;
}

@end

#endif // _ULSIMPLEMERGERDELEGATE_H_

