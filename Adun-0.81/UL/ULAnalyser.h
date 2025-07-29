/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

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
#ifndef _ULANALYSER_
#define _ULANALYSER_
#include <AppKit/AppKit.h>
#include <AdunKernel/AdunDataSet.h>
#include <AdunKernel/AdunSimulationData.h>
#include <AdunKernel/AdunMemoryManager.h>
#include <MolTalk/MolTalk.h>
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULAnalysisManager.h"
#include "ULAnalyserDataSetView.h"
#include "ViewController.h"
#include "ULProgressPanel.h"
#include "ULOutlineViewDelegate.h"
#include "ULPasteboard.h"

/**
Main class for data analysis
\todo Refactor Gnuplot interface to its own class
\todo Refactor DataSet opening and closing to a category or class
\todo Move all methods related to protocols to their own category
\ingroup interface
*/

@interface ULAnalyser: NSObject
{
	@private
	int checkCount;
	BOOL threadError;
	id pluginList;
	id optionsView;
	id resultsLog;
	id window;
	id analysisManager;
	id mainViewController;
	id currentOptions;
	NSDictionary* pluginResults;
	NSError* pluginError;
	id selectedDataSet;		//!< The data set currently being displayed
	id pluginDataSets;		//!< Array of data sets returned by the last plugin
	NSMutableArray* openDataSets;	//!< Contains data sets currently open for display
	id outlineDelegate;
	ULProgressPanel* progressPanel;
	NSString* selectedPlugin;
	NSDictionary* classMap;		//!< Maps class names to user readable names
	id dataSetList;			//!< List showing data sets returned by a plugin
	id loadedObjectsTable;		//!< Table showing the currently loaded objects
	id loadedObjects;		//!< Array holding the currently loaded objects
	id loadableTypes;		//!< The types of object ULAnalyser can load
	id selectedObjects;		//!< The loaded objects that have been selected
	id dataView;			//!< Object that controls the display of data sets
	id toolbar;
	id reloadItem;			//!< The reload button on the toolbar
	id tabView;
	NSImage* saveImage;
	NSImage* applyImage;
	NSImage* reloadImage;
	NSImage* closeImage;
	NSImage* exportImage;
	//gnuplot
	BOOL gnuplotRunning;
	int historyDepth;
	int currentHistoryPosition;
	NSRange commandRange;
	NSRange gnuplotPrompt;
	id gnuplotInterface;
	NSString* gnuplotDir;
	NSMutableAttributedString* promptString;
	NSFileHandle* gnuplotOutput;
	NSFileHandle* gnuplotError;
	NSTask* gnuplot;
	NSPipe* pipey;
	NSPipe* outPipe;
	NSMutableArray* history;
}
/**
Documentation forthcoming
*/
- (id) initWithModelViewController: (id) mVC;
/**
Documentation forthcoming
*/
- (void) open: (id) sender;
/**
Documentation forthcoming
*/
- (void) close: (id) sender;
/**
Documentation forthcoming
*/
- (void) analyse: (id) sender;
/**
Documentation forthcoming
*/
- (void) load: (id) sender;
/**
Documentation forthcoming
*/
- (void) display: (id) sender;
/**
Documentation forthcoming
*/
- (void) save: (id) sender;
/**
Documentation forthcoming
*/
- (void) remove: (id) sender;
/**
Documentation forthcoming
*/
- (void) logString: (NSString*) string;
@end


/**
 Contains methods for opening, selecting and closing
 the data sets displayed in the data set list. 
 This is the top-left pop-up list in the table display part of the Analyser window.
 */
@interface ULAnalyser (ULAnalyserDataSetOpening)
/**
 Calls opensDataSet:() on all the data sets in anArray.
 */
- (void) openDataSets: (NSArray*) anArray;
/**
 Opens \e aDataSet.
 This adds the data set name to the data set pop-up list and 
 starts write out of the necessary gnuplot files.
 If a data set with the same name is currently displayed (the selected data set) 
 it is closed and \e aDataSet replaces it.
 If that data set was currently selected then \e aDataSet is selected, otherwise its not
 */
- (void) openDataSet: (AdDataSet*) aDataSet;
/**
 Closes the selected data set (i.e. the data set currently selected in the data set list).
 See closeDataSet:() for more information.
 */
- (void) closeSelectedDataSet: (id) sender;
/**
 Closes \e aDataSet.
 This involves removing it from the data set list and removing the gnuplot files.
 Does nothing is \e aDataSet is not an opened data set.
 */
- (void) closeDataSet: (AdDataSet*) aDataSet;
/**
 Makes \e aDataSet the selected data set in the pop-up list.
 Does nothing if \e aDataSet is not in the data set list.
 Involves a call to dataSetDidChange:()
 */
- (void) selectDataSet: (AdDataSet*) aDataSet;
/**
 Closes all the data sets currently in the list and replaces them
 with the data sets in \e array.
 However if a data set in \e array is already opened it is not closed.
 If the data set selected before this method is called is in \e array it
 is still selected when the method returns.
 Otherwise the first data set in \e array is selected.
 If \e array is empty or nil this results in all sets being closed.
 */
- (void) setAvailableDataSets: (NSArray*) array;
/**
 Called when the user selects a new data set from the data set list or
 when selectDatatSet(): is called.
 This sets the currently selected data set as the data set of the data view
 (ULAnalyserDataSetView) and displays its data in the table.
 */
- (void) dataSetDidChange: (id) sender;
@end

/**
Category containing methods which handle the gnuplot interface.
\todo Change to class
\ingroup interface
*/
@interface ULAnalyser (ULAnalyserGnuplotExtensions)
/**
Documentation forthcoming
*/
- (void) setupGnuplotInterface;
/**
Documentation forthcoming
*/
- (void) gnuplotDealloc;
/**
Creates the files used by gnuplot for plotting the data in \e aDataSet.
*/
- (void) createGnuplotFilesForDataSet: (AdDataSet*) aDataSet;
/**
As createGnuplotFilesForDataSet:() but runs in a separate thread.
*/
- (void) threadedCreateGnuplotFilesForDataSet: (AdDataSet*) aDataSet;
/**
Removed the files created by a call to \e createGnuplotFilesForDataSet.
*/
- (void) removeGnuplotFilesForDataSet: (AdDataSet*) aDataSet;
/**
Calls removeGnuplotFilesForDataSet:() for each dataSet in anArray.
*/
- (void) removeGnuplotFilesForDataSets: (NSArray*) anArray;
/**
Updates the file for the matrix currently displayed by the receivers ULAnalyserDataSetView instance.
This messages is usually called as a result of a ULAnalyserDataSetViewColumnOrderDidChangeNotification.
*/
- (void) updateFileForDisplayedMatrix: (NSNotification*) aNotification;
@end

/**
 ULAnalyser category containing methods related to
 displaying plugin options and applying plugins to data.
\ingroup interface
*/
@interface ULAnalyser (ULAnalyserPluginExtensions)

/**
Documentation forthcoming
*/
- (void) pluginChanged: (id) sender;
/**
Documentation forthcoming
*/
- (void) displayOptionsForPlugin;
/**
Documentation forthcoming
*/
- (void) applyCurrentPlugin: (id) sender;
/**
Documentation forthcoming
*/
- (void) updateAvailablePlugins;
/**
Documentation forthcoming
*/
- (void) updatePluginOptions;
@end

/**
Contains ULAnalysers implementation of the ULPasteboardDataSource protocol.
\ingroup interface
*/
@interface ULAnalyser (PasteboardDataSource) <ULPasteboardDataSource>
@end

#endif
