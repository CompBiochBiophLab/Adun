/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 13:40:24 +0200 by michael johnston

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

/**
\ingroup protocols
*/

#ifndef _ULMERGERDELEGATE_
#define _ULMERGERDELEGATE_

@protocol ULMergerDelegate <NSObject>

- (void) didBeginMolecule: (int) index;

- (void) didEndMolecule: (int) index;

/**
Initialises the merger delegate to merge frame with conf. frame and conf are not
retained as it is assumed they will be alive while at least until finalise is called.
The process of merging is currently assumed to destroy the topologyFrame. 
*/

- (void) initWithConfiguration: (NSDictionary*) conf topologyFrame: (NSDictionary*) frame;

/**
Sent to the delegate when ULMerger matches a topology and configuration atom in a certain molecule
\param confAtomIndex The index of the configuration atom matched
\param topAtomIndex The index of the topology atom matched
*/
- (void) matchedConfigurationAtom: (int) confAtomIndex toTopologyAtom: (int) topAtomIndex;
/**
Sent to the delegate when ULMerger cannot find a match for a topologyAtom
in the configuration molecule.
\param topIndex The index of the topology atom that couldnt be matched
*/
- (void) foundTopologyAtomNotInConfiguration: (int) topIndex;
/**
Sent to the delegate when it encounter a configuration molecule that has more
atoms than the corresponding topology molecule
\param confMoleculeIndex The index of the configuration molecule 
*/
- (void) foundMoleculeWithExtraAtoms: (int) confMoleculeIndex;
/**
Sent to the delegate when it finds more than one match for a given topology atom
\param confAtomIndexes The indexes of the configuration atoms that match the topology atom
*/
- (void) foundDuplicateConfigurationAtoms: (NSArray*) confAtomIndexes; 

/**
Finishes the merge and returns the final ULSystem instance
*/

- (id) finalise;
- (void) foundConfigurationAtomNotInTopology: (int) confIndex;

/**
A dictionary whose keys are the ids of residues which have extra atoms and values are arrays
of the extra atoms
*/
- (NSDictionary*) extraAtoms;
/**
A dictionary whose keys are the ids of residues which are missing atoms and values are arrays
of the missing atoms
*/
- (NSDictionary*) missingAtoms;

@end

#endif
