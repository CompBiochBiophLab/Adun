/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston 

   Created: 2005-12-09 14:47:28 +0100 by michael johnston

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

#ifndef _ULANALYSISMANAGER_H_
#define _ULANALYSISMANAGER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataSet.h>
#include <AdunKernel/AdunSimulationData.h>
#include "ULFramework/ULAnalysisPlugin.h"
#include "ULFramework/ULDatabaseInterface.h"

/**
\ingroup classes
This class manages the analysis of a set of input object using a chosen plugin.
The available plugins that can be used are dependant on the types and number of input
objects. The results of analysis is usually a one or more AdDataSet instances.
*/

@interface ULAnalysisManager : NSObject
{
	@private
	id energies;
	id currentPlugin;
	NSString* currentPluginName;
	id results;				//!< The last analysis results
	NSMutableArray* outputObjectsReferences;	//!< Contains the objects that generated the current output set.
	NSArray* pluginDirs;			//!< Array of directories containing  analyis plugin bundles
	NSMutableArray* availablePlugins;	//!< Array of plugin bundle names
	NSMutableArray* inputObjects;		//!< Array of input objects
	NSMutableDictionary* objectsCountDict;	//!< Count of each type of input object
	NSMutableDictionary* pluginInfoDict;	//!< Contains information about the inputs needed by each plugin
}
/**
As new but returning an autoreleased object.
*/
+ (id) managerWithDefaultLocations;
/**
Returns an ULAnalysisManager instance which manages the plugins in $(APPLICATIONDIR)/Plugins/Analysis
along with the directory specified in the PluginDirectories default.
The value of $(APPLICATIONDIR) is that returned by ULIOManager::applicationDir()
and is platform dependant.
*/
- (id) init;
/**
Returns a ULAnalysisManager instance initialised to manage the plugins in a given directory.
 */
- (id) initWithLocation: (NSString*) aString;
/**
Designated initialiser. Returns a ULAnalysisManager instance initialised
to manage the plugins in the given directories.
*/
- (id) initWithLocations: (NSArray*) aString;

/**
Adds \e object to the analysis input. Does nothing if object
is nil
*/
- (void) addInputObject: (id) object;
/**
Removes \e object from the analysis input. Does nothing if
\e object is not among the inputs.
*/
- (void) removeInputObject: (id) object;
/**
Clears the analysis inputs
*/
- (void) removeAllInputObjects;
/**
Returns an array of containing the input objects.
If their are none the array will be empty
*/
- (NSArray*) inputObjects;
/** Return YES if the analysis manager contain any input objects.
No otherwise
*/
- (BOOL) containsInputObjects;
/**
Returns an array containing the name of plugins that can be applied
to the set of input objects i.e. the plugins who can take the current
input objects as their input
*/
- (NSArray*) pluginsForCurrentInputs;
/** 
Returns the number of input objects of \e class 
*/
- (int) countOfInputObjectsOfClass: (NSString*) className;
/** Returns the last array of data sets produced by applying a plugin to a set of inputs
*/
- (NSArray*) outputDataSets;
/**
Returns the analysis string (if any) which provides information on the last analysis 
performed
*/
- (NSString*) outputString;
/**
Returns the value of ULAnalysisPluginFiles from the results of the last analysis performed.
*/
- (NSArray*) outputFiles;
/**
Saves the output data set \e dataSet to the file system database adding all necessary
references. The object passed must be one of the data sets returned by the outputDataSets method.
The ability of this method to correctly assign output references
is not affected if input objects are removed or added before it is called i.e.
ULAnalysisManager remembers who generated \e dataSet.
*/
- (void) saveOutputDataSet: (AdDataSet*) dataSet;
/**
Applies the plugin \e name to the current input objects using \e options
and returns the plugin output (either nil or an array of AdDataSet objects)
If \e name is not in the array returned by pluginsForCurrentInputs an
NSInvalidArgumentException is raised.
If the data contained in the inputs cannot be processed by the plugin (as determined by
calling checkInputs:error: on it) this method returns nil and \e error points to
an NSError object explaining the reason for the failure.
The receiever retains references to the output and the input objects that
created it until the next call to this method unless clearOutput() is called
first.
\todo Change so returns void - use currentOutputObject to get results.
*/
- (id) applyPlugin: (NSString*) name withOptions: (NSMutableDictionary*) options error: (NSError**) error;
/**
Returns the options for plugin \e name. Note a plugin may have no options.
If \e name is not in the array returned by pluginsForCurrentInputs an
NSInvalidArgumentException is raised.
*/
- (id) optionsForPlugin: (NSString*) name;
/**
Causes the receiever to release references to any output object
it contains aswell as to the input objects that created it.
*/
- (void) clearOutput;
/**
Returns the current plugin object being used.
*/
- (id) currentPlugin;
/**
Loads the plugin \e pluginName - It becomed the current plugin.
Raises an NSInvalidArgumentException if no plugin called \e pluginName
can be found in the location being searched by the receiver.
Raise an NSInternalInconsistencyException if the loaded plugins principal
class does not conform to ULAnalysisPlugin.
*/
- (void) setCurrentPlugin: (NSString*) pluginName;
/**
Loads the plugin \e name if its not already loaded and returns its prinicpal class.
*/
- (Class) loadPlugin: (NSString*) name;
/**
Returns an array containing the names of all available plugins
*/
- (NSArray*) availablePlugins;
/**
Returns the the path to the directory containing pluginName or nil if it can't be found
*/
- (NSString*) locationOfPlugin: (NSString*) pluginName;
@end

#endif // _ULANALYSISMANAGER_H_

