/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-24 12:05:53 +0200 by michael johnston

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

#ifndef _ULCONFIGURATIONBUILDER_H_
#define _ULCONFIGURATIONBUILDER_H_

#include <Foundation/Foundation.h>
#include "ULFramework/ULConfigurationPlugin.h"

/**
ULConfiguration builder is the front end to a class cluster for building the configuration
related part of a molecular simulation system. The different subclasses correspond to
different configuration file types. 

ULConfiguration builder are usually associated with a molecule which they can convert into
the internally used format through buildConfiguration. They can also load plugins which they
can use to manipulate the molecule before building the configuration. The internal representation
of the molecule is subclass dependant so different plugins are needed for different file types.

\ingroup classes
*/

@interface ULConfigurationBuilder : NSObject
/**
Returns a ULConfigurationBuilder subclass which depends on the type of the file at molecule path
\param A vaild path to a molecule configuration file
\return a ULConfigurationBuilder subclass instance
Returns nil if file not found
*/
+ (id)  builderForMoleculeAtPath: (NSString*) moleculePath ; 

/**
Returns the ULConfigurationBuilder subclass for \e fileType
\param A vaild file type
\return a ULConfigurationBuilder subclass instance
Returns nil if fileType is not valid
\note Only "pdb" is supported at the moment
*/
+ (id)  builderForFileType: (NSString*) fileType; 

/**
Returns an instance initialised with the molecule at path.
Return nil if file not found or invalid. If path
is nil returns a default configuration builder instance
*/
- (id) initWithMoleculeAtPath: (NSString*) path;
@end

/**
Protocol containing methods necessary for configuration
building
*/

@protocol ULConfigurationBuilding
/**
Returns a dictionary (in the Adun options dict format) giving the build
options for the current molecule. If no molecule has been set this method
returns nil. This dictionary should be edited to reflect the option choices
for the build and the result used as the options parameter in 
buildConfiguration:error:userInfo:
*/
- (NSMutableDictionary*) buildOptions;
/**
Build the configuration of the current molecule based on options.
Return nil if no molecule has been set. 
\param options The options for the build. The options dictionary should be based on the
one returned by buildOptions.
\param buildError A pointer to an NSError where an error during the build will be stored
\param buildInfo A pointer to a string where information on the build will be stored
\return the configuration build result
\todo decide on what exactly should be returned!
*/
- (id) buildConfiguration: (NSDictionary*) options 
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo;
/**
Returns the path of the current molecule or nil if none
has been set
*/
- (NSString*) currentMoleculePath;
/**
Set the current molecule to that at path. Raises an NSInvalidArgumentException
if path does not refer to a valid molecule file. If path is nil has the
same effect as removeCurrentMolecule: 
*/
- (void) setCurrentMolecule: (NSString*) path;
/**
Removes the currentMolecule. If there is no currentMolecule does nothing
*/
- (void) removeCurrentMolecule;
/**
Writes the current structure held by the object to the file
at \e path
*/
- (void) writeStructureToFile: (NSString*) path;
@end


/**
Protocol containing methods neccessary for preprocessing
molecules
*/

@protocol ULConfigurationPreprocessing
/**
Applies the currently loaded plugin to the current molecule. Does nothing
if no plugin has been loaded. This method may change the molecule state.
*/
- (void) applyPlugin: (NSDictionary*) options;
/**
Returns the options for the current plugin. 
*/
- (NSMutableDictionary*) optionsForPlugin;
/**
Loads and sets the current configuration manipulation plugin to \e name.
If \e name cant be found or loaded this method raised an NSInvalidArgumentException.
Also raises an NSInvalidArgumentException if the plugin associated with \e name
is not of the correct type i.e. if not a plugin for the concrete subclass
*/
- (void) loadPlugin: (NSString*) name;
/**
Returns the name of the current plugin
*/
- (NSString*) currentPlugin;
/**
Returns a list of the availablePlugins for
preprocessing structures
*/
- (NSArray*) availablePlugins;
/**
Returns the output string describing the last preprocessing step applied
*/
- (NSString*) pluginOutputString;

@end

#endif // _ULCONFIGURATIONBUILDER_H_

