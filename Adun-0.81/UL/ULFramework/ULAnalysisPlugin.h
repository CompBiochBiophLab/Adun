/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-11 13:13:35 +0100 by michael johnston

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

#ifndef _ULANALYSISPLUGIN_H_
#define _ULANALYSISPLUGIN_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataSet.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <AdunKernel/AdunSimulationData.h>

/**
\ingroup protocols
When processing results a results plugin can (and should) notify the user of its 
progress by posting ULAnalysisPluginDidCompleteStepNotification's at various intervals.
The notification object must be nil.
The userInfo dictionary of the notification must contain the following keys.
ULAnalysisPluginTotalSteps - The total number of steps the plugin will perform
ULAnalysisPluginCompletedSteps - The number of completed steps (out of total steps).

By convention the first step should be 0.

The dictionary can also contain the optional key:

ULAnalysisPluginProgressMessage - An string with some information about the next step
to be performed.
*/
@protocol ULAnalysisPlugin
/**
Checks that the objects in \e inputs can be used with the plugin. 
The object types are checked atomatically before being passed to this method
so it should only concern itself with checking if the contents of those types
is valid. The level of checking implemented is left to the plugin creator to
decide. The simplest implementation of this message is just to return YES. 
If this method returns NO for any reason, on return \e error should point to
an NSError object describing the reason for the failed check.
*/
- (BOOL) checkInputs: (NSArray*) inputs error: (NSError**) error;
/**
Returns the available options for the plugin given the input objects in \e inputs. 
\note The NSDictionary will be replaced by a more powerful ULOptionsMenu object
\return An NSDictionary in the adun options format.
*/
- (NSDictionary*) pluginOptions: (NSArray*) inputs;
/**
The return value must be an NSDictionary with any of the following keys :

ULAnalysisPluginString
ULAnalysisPluginDataSets
ULAnalysisPluginFiles

ULAnalysisPluginString is a string describing necessary information about
the results of the plugin. This string will be displayed in the Results Log
in the analyse window.

ULAnalysisPluginDataSets must be an array of AdDataSet objects. 
The \e title attribute of each AdDataMatrix in each data set should be set to a description of the table. 
The descriptions will appear in the display pop-up in the results view. 
The \e columnTitles attribute of each AdDataMatrix should be set to descibe the
values in each column. See AdDataMatrix and AdDataSet for more information.

ULAnalysisPluginFiles must be an array of dictionaries. Each dictionary must contain two
keys -
ULAnalysisPluginFileContents - An object which responds to writeToFile:atomically:
ULAnalysisPluginFileDescription - A description of the file.
For each dictionary the analyser will display a save panel with the given description allowing
the user to choose where to save the file. 
*/
- (NSDictionary*) processInputs: (NSArray*) inputs userOptions: (NSDictionary*) options; 
@end

#endif // _ULANALYSISPLUGIN_H_

