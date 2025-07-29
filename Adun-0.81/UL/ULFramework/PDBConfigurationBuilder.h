/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-24 15:03:58 +0200 by michael johnston

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

#ifndef _PDBCONFIGURATIONBUILDER_H_
#define _PDBCONFIGURATIONBUILDER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <MolTalk/MolTalk.h>
#include "ULFramework/ULConfigurationBuilder.h"
#include "ULFramework/ULIOManager.h"

/** 
ULConfigurationBuilder subclass for PDB files
\ingroup classes
*/

@interface PDBConfigurationBuilder: NSObject <ULConfigurationBuilding>
{
	FILE* buildOutput;
	id ioManager;
	id plugin;
	id structure;
	NSMutableString* buildString;
	NSString* pluginName;
	NSString* moleculePath;
	NSDictionary* nameMap; 	  //!< dictionary mapping old pdb names to new
	NSMutableArray* availablePlugins;
}
/**
Returns an instance initialised with the molecule at path.
Return nil if file not found or invalid. If path
is nil returns a default configuration builder instance
*/
- (id) initWithMoleculeAtPath: (NSString*) path;
@end

/**
The PDBConfigurationBuilder builder objects can load third party plugins which
can modify the structure the instance is working on before it builds it configuration.
The list of plugins installed is returned by the availablePlugins() method.

In addition to these third party plugins PDBConfigurationBuilder has an internal
plugin called PDBStructureModifier.

See PDBConfigurationBuilder class docs for option information.
*/
@interface PDBConfigurationBuilder (PluginExtensions) <ULConfigurationPreprocessing>
@end

/**
A configuration plugin for modifiying structure so they are compatible with
a certain force-field or removing those modifications
*/
@interface PDBStructureModifier: NSObject <ULConfigurationPlugin>
{
	NSMutableString* outputString;
}
/**
\e options is a dictionary returned by optionsForStructure:()
You must set the selection to either Charmm or Enzymix by doing e.g.
[options selectMenuItem: @"Charmm"]

This method is primarily used to process options set by the user via a GUI.
Use the other methods of the class if you wish to modify a structure programmatically.
*/
- (id) manipulateStructure: (id) structure userOptions: (NSMutableDictionary*) options;
/**
 Modifies the structure to make it compatible with ENZYMIX force fields.
 Histidine residues can have a hyrdrogen attached either to the ND1 or NE2 nitrogens but not both.
 If the H is attached to ND1 (called HD1) Enymix labels this residue HIS.
 If it is attached to NE2 it is called HE2 and the reidues is called HIE by Enzymix.
 This function renames any histidines of the later type to HIE.
 If the type can't be determined, i.e. neither HD1 or HE2 is present the residue is not renamed.
 */
- (void) modifyStructureForEnzymix: (MTStructure*) aStructure;
/**
 Removes renaming modification added by modifyStructureForEnzymix:()
 Does nothing if no such modifications were detected.
 */
- (void) removeEnzymixStructureModifications: (MTStructure*) aStructure;
/**
 Modifies the structure to make it compatible with CHARMM force field.
 Histidine residues with HD1 are renamed HSD and those with HE2 are renamed HSE.
 If the type can't be determined, i.e. neither HD1 or HE2 is present the residue is renamed HSD
 since it must be one or the other in order for the residue to be identified.
 See modifyStructureForEnzymix:() for more on histidine renaming.
 */
- (void) modifyStructureForCharmm: (MTStructure*) aStructure;
/**
 Removes renaming modification added by modifyStructureForCharmm:()
 Does nothing if no such modifications were detected.
 */
- (void) removeCharmmStructureModifications: (MTStructure*) aStructure;
@end

#endif // _PDBCONFIGURATIONBUILDER_H_

