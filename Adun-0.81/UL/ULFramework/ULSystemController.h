/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 14:10:36 +0200 by michael johnston

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

#ifndef _ULSYSTEMCONTROLLER_H_
#define _ULSYSTEMCONTROLLER_H_

#include <stdbool.h>
#include <Foundation/Foundation.h>
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULSystemBuilder.h"
#include "ULFramework/ULDatabaseInterface.h"

/**
ULSystemController is responsible for building and managing
systems (configuration + topology + userDefs) that will be used
for simulations. It contains a ULSystemBuilder and an AdDataSource instance.
The AdDataSource instance is the last one created with buildSystemWithOptions:
\note Consider merging this functionality into ULSystemBuilder directly

\ingroup classes

*/

@interface ULSystemController : NSObject
{
	id system;		//!< The current system	
	ULIOManager* ioManager;	//!< IO manager
	NSArray* buildSteps;
	id systemBuilder;	//!< The ULSystemBuilder instance
	id simulationDatabase;  //!< The simulation database
	id pluginList;
	id configurationFileAnalyser;
}

/**
Archives the current system object
*/
- (void) saveSystem;

/**
Builds a system according to the values in optionsDict, one of which
must be the path to a configuration file
\param optionsDict A modified variation of the dictionary returned with buildOptions
\param buildError A pointer to an unallocated NSError object. If an error occurs this will
storce the result*/
- (BOOL) buildSystemWithOptions: (NSDictionary*) optionsDict error: (NSError**) buildError;
/**
Resumes a build that was previously stopped due to the detection of an error
\return Returns YES if system was built succesfully. NO otherwise.
If there is no build on the pathway raises an NSInternalInconsistencyException
*/
- (BOOL) resumeBuild: (NSDictionary*) options error: (NSError**) buildError;
/**
Calls cancelBuild on the systemBuilder
*/
- (void) cancelBuild;
/**
Sets the system builders force field to \e forceFieldName
*/
- (void) setForceField: (NSString*) forceFieldName;
/**
Method used to save a system in another thread
**/
- (void) threadedSaveSystem: (id) param;
/**
Returns the build options dictionary for the molecule currently
on the build pathway
*/
- (NSMutableDictionary*) buildOptions;
/**
Returns the current preprocess plugins option dictionary for the currently active molecule
*/
- (NSMutableDictionary*) preprocessOptions;
/**
Calls remove molecule on the systemBuilder
*/
- (BOOL) removeMolecule;
/**
Returns the last built system
*/
- (AdDataSource*) system;
/**
Returns the system builder
*/
- (id) systemBuilder;

@end

#endif // _ULSYSTEMCONTROLLER_H_

