/*
   Project: UL

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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
#ifndef _ULANALYSER_DATASETVIEW_
#define _ULANALYSER_DATASETVIEW_
#include <AppKit/AppKit.h>
#include <AdunKernel/AdunDataSet.h>
#include "ULFramework/ULIOManager.h"


/**
Controlls the part of the Analyser tool that
displays data sets.

\todo Use NSNumberFormatter for displaying data when it is fully implemented.
\ingroup interface
*/
@interface ULAnalyserDataSetView: NSObject
{
	double defaultWidth;
	AdDataSet* dataSet;
	NSTableView* resultsTable;		//!< The NSTableView that displays results
	id displayList;			//!< Popup button displaying the available tables
	NSArray* terms;			//!< The headers of the current table
	AdMutableDataMatrix* currentTable;	//!< The table in the data set that is currently being displayed
}
/**
Sets the current data set to \e aDataSet
*/
- (void) setDataSet: (AdDataSet*) aDataSet;
/**
Returns the current data set
*/
- (id) dataSet;
/**
The matrix of dataSet() being displayed.
*/
- (id) displayedMatrix;
/**
An array containing the column headers of displayedMatrix() in the
order they appear in the analyser.
*/
- (NSArray*) orderedColumnHeaders;
/**
Clears the view of all currently displayed data and
removes the current data set.
*/
- (void) clearDataSet;
/**
Loads the view with the data from the current data set.
The table displayed is the first returned from the data set.
Calls outputDataTableForGnuplot() for the displayed table.
*/
- (void) displayData;
/**
Sent by displayList when its selection changes
*/
- (void) selectedNewTableItem: (id) sender;
@end
#endif


