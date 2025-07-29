/*
   Project: UL

   Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa

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

#include "ULAnalyser.h"

/*
 * Extensions to ULAnalyser to
 * enable gnuplot integration.
 */

@implementation ULAnalyser (ULAnalyserGnuplotExtensions)

- (void) gnuplotDealloc
{
	[pipey release];
	[outPipe release];
	[gnuplotOutput release];
	[gnuplotError release];
	[gnuplotDir release];
	[gnuplot terminate];
	[gnuplot release];
	[history release];
	[promptString release];
	[[NSNotificationCenter defaultCenter]
		removeObserver: self];
}

/**
Wrapper around gnuplot launch with error handling.
Returns the location at which to put the prompt in the
interface
*/
- (int) _launchGnuplot
{
	NSRange endRange;
	NSMutableString *errorString;

	NS_DURING
	{
		[gnuplot launch];
		gnuplotRunning = YES;
		endRange.location = 0;
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: @"NSInvalidArgumentException"])
		{
			errorString = [NSMutableString string];
			[errorString appendFormat: 
				@"Unable to launch gnuplot from %@\n", [gnuplot launchPath]];
			NSWarnLog(@"%@", errorString);	
			[errorString appendString:
				@"Either gnuplot is not installed or the exectuable is in another location\n"];
			[errorString appendString:
				@"If the latter specify the directory containing the exectutable using"];
			[errorString appendString:
				@" the preferences panel (Info->Preferences)\n"];
			[errorString appendString:
				@"Or execute,\n\n\t'defaults write UL GnuplotPath $PATH_TO_GNUPLOT'\n\n"];
			[errorString appendString: @"on the command line\n"];	

			endRange.location = 0;
			endRange.length = 0;
			[gnuplotInterface replaceCharactersInRange:endRange 
				withString:errorString];
			endRange.location = [[gnuplotInterface textStorage] length];	
			
			//Indicate that gnuplot failed to launch
			gnuplotRunning = NO;
		}
		else
			[localException raise];
	}
	NS_ENDHANDLER

	return endRange.location;
}

- (void) _setupGnuplotDirectory
{
	NSFileManager* fileManager;
	NSEnumerator* gnuplotDirEnum;
	NSString* contentObject, *path;
	NSError* error = nil;

	//Create gnuplot directory if it doesnt exist
	fileManager = [NSFileManager defaultManager];
	gnuplotDir = [[[ULIOManager appIOManager] applicationDir]
			stringByAppendingPathComponent: @".gnuplot"];
	[gnuplotDir retain];		
	if(![fileManager directoryExistsAtPath: gnuplotDir error: &error])
	{
		if(error != nil)
			ULRunErrorPanel(error);
		else
			[fileManager createDirectoryAtPath: gnuplotDir
				attributes: nil
				error: NULL];
	}
	
	//Remove any files in the gnuplot directory	
	gnuplotDirEnum = [[fileManager directoryContentsAtPath: gnuplotDir]
				objectEnumerator];
	while((contentObject = [gnuplotDirEnum nextObject]))
	{
		path = [gnuplotDir stringByAppendingPathComponent: contentObject];
		[fileManager removeFileAtPath: path handler: NULL];
	}
	
	//Register for ULAnalyserDataSetViewColumnOrderDidChangeNotification
	//so we can update the relevant file.
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(updateFileForDisplayedMatrix:)
		name: @"ULAnalyserDataSetViewColumnOrderDidChangeNotification"
		object: nil];
}

- (void) setupGnuplotInterface
{
	BOOL isDir;
	NSRange endRange;
	NSString* launchPath;
	NSMutableString *errorString;
	NSFileManager* fileManager;
	ULIOManager* ioManager = [ULIOManager appIOManager];

	//Create and/or clear the gnuplot directory
	//if necessary.
	[self _setupGnuplotDirectory];

	history = [NSMutableArray new];
	historyDepth = 100;
	currentHistoryPosition = 0;

	gnuplotRunning = NO;
	[gnuplotInterface setDelegate: self];
	pipey =  [NSPipe new]; 
	outPipe = [NSPipe new];
	gnuplotOutput =  [[pipey fileHandleForWriting] retain]; 
	gnuplotError = [[outPipe fileHandleForReading] retain];
	gnuplot = [NSTask new];
	launchPath = [[NSUserDefaults standardUserDefaults]
			stringForKey: @"GnuplotPath"];
	
	//Check the path specifies a file and not a directory
	[[NSFileManager defaultManager]
		fileExistsAtPath: launchPath
		isDirectory: &isDir];

	//If it is a directory print an error message and return
	//without attempting to launch gnuplot
	if(isDir)
	{
		errorString = [NSMutableString string];
		[errorString appendFormat: @"Specified path %@ refers to a directory\n",
			launchPath];
		[errorString appendFormat: @"Path must be the full path to the executable\n",
			launchPath];
			
		endRange.location = 0;
		endRange.length = 0;
		[gnuplotInterface replaceCharactersInRange:endRange 
			withString:errorString];
		endRange.location = [[gnuplotInterface textStorage] length];	
	}
	else
	{
		[gnuplot setLaunchPath: launchPath];
		[gnuplot setCurrentDirectoryPath: gnuplotDir];
		[gnuplot setStandardInput: pipey];
		[gnuplot setStandardError: outPipe];

		/*
		 * Attempt to launch gnuplot.
		 * If this fails output a message to the gnuplot terminal
		 * The terminal will continue to accept input but nothing
		 * will actuall work
		 */

		endRange.location = [self _launchGnuplot];
	}	

	promptString = [[NSMutableAttributedString alloc] 
				initWithString: @"gnuplot> "];
	[promptString addAttribute: NSForegroundColorAttributeName
		value: [NSColor blueColor]
		range: NSMakeRange(0, [promptString length] - 1)];


	endRange.length = 0;
	[[gnuplotInterface textStorage] 
		replaceCharactersInRange: endRange 
		withAttributedString: promptString];
	gnuplotPrompt.location = endRange.location;
	gnuplotPrompt.length = [[gnuplotInterface textStorage] length] - endRange.location;
}

/******************

Gnuplot History

*******************/

- (void) _addStringToHistory: (NSString*) string
{
	[history addObject: string];

	if([history count] == historyDepth)
		[history removeObjectAtIndex: 0];

	currentHistoryPosition = [history count];
}

- (NSString*) _previousStringFromHistory
{
	id string;

	NS_DURING
	{
		currentHistoryPosition--;
		string = [history objectAtIndex: currentHistoryPosition];
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: NSRangeException])
		{
			if([history count] != 0)
			{
				currentHistoryPosition = 0;
				string = [history objectAtIndex: currentHistoryPosition];
			}
			else
				string = @"";
		}
	}
	NS_ENDHANDLER
	
	return string;
}

- (NSString*) _nextStringFromHistory
{
	id string;

	NS_DURING
	{
		currentHistoryPosition++;
		string = [history objectAtIndex: currentHistoryPosition];
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: NSRangeException])
		{
			currentHistoryPosition = [history count];
			string = @"";
		}
	}
	NS_ENDHANDLER
	
	return string;
}

/**
 * Methods for handling the text files containing the data displayed in the
 * data table in the interface. These files are what gnuplot uses to plot the data.
 */

- (void) writeMatrixString: (NSDictionary*) dict
{
	NSFileHandle* fileHandle;
	NSData* data;

	data = [[dict objectForKey: @"String"] 
			dataUsingEncoding: NSASCIIStringEncoding];
	[data writeToFile: [dict objectForKey: @"Filename"] atomically: NO];
}

/*
Outputs \e aMatrix which is in \e aDataSet to a file called dataSetName.matrixName in the gnuplot
directory. The columns in the matrix are output in the order defined by \e columnHeaders. This is an
array of the column headers (NSStrings) of \e aMatrix in the desired order.
Raises an NSInternalInconsistencyException of \e aMatrix is not in \e aDataSet. 
Raises an NSInvalidArgumentException if any of the headers in \e columnHeaders is not a header of
a column of \e aMatrix.
*/
- (void) _outputFileForMatrix: (AdDataMatrix*) aMatrix 
	inDataSet: (AdDataSet*) aDataSet 
	columnOrder: (NSArray*) columnHeaders
{
	int i, j, numberOfColumns;
	int* index;
	NSEnumerator* rowEnum;
	NSString *fileName;
	NSMutableString* string;
	id row;
	
	//Create the path to the matrix file
	fileName = [NSString stringWithFormat: @"%@.%@",
			[aDataSet name], [aMatrix name]];
	fileName = [gnuplotDir stringByAppendingPathComponent: fileName];	
	
	numberOfColumns = [columnHeaders count];
	
	//Get the column index order
	index = (int*)malloc(numberOfColumns*sizeof(int));
	for(i=0; i<numberOfColumns; i++)
		index[i] = [aMatrix indexOfColumnWithHeader: 
				[columnHeaders objectAtIndex: i]];
	
	//Write the data
	string = [NSMutableString new];
	rowEnum = [aMatrix rowEnumerator];
	while(row = [rowEnum nextObject])
	{
		for(j=0; j<numberOfColumns; j++)
			[string appendFormat: @"%-@ ", [row objectAtIndex: index[j]]];
					
		[string appendFormat: @"\n"];
	}
	
	[self writeMatrixString: 
		[NSDictionary dictionaryWithObjectsAndKeys:
			fileName, @"Filename",
			string, @"String", nil]];
		
	[string release];
	free(index);
}

- (void) _outputFileForMatrix: (AdDataMatrix*) aMatrix inDataSet: (AdDataSet*) aDataSet
{
	[self _outputFileForMatrix: aMatrix
		inDataSet: aDataSet
		columnOrder: [aMatrix columnHeaders]];
}

- (void) updateFileForDisplayedMatrix: (NSNotification*) aNotification
{
	[self _outputFileForMatrix: [dataView displayedMatrix]		
		inDataSet: [dataView dataSet]
		columnOrder: [dataView orderedColumnHeaders]];
}

- (void) createGnuplotFilesForDataSet: (AdDataSet*) aDataSet
{
	NSEnumerator* matrixEnum;
	AdDataMatrix* matrix;
	
	matrixEnum = [[aDataSet dataMatrices] objectEnumerator];
	while(matrix = [matrixEnum nextObject])
		[self _outputFileForMatrix: matrix
			inDataSet: aDataSet];
}

- (void) threadedCreateGnuplotFilesForDataSet: (AdDataSet*) aDataSet
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];

	[self createGnuplotFilesForDataSet: aDataSet];

	[pool release];
	[NSThread exit];
}


//Removing files

- (void) _removeFileForMatrix: (AdDataMatrix*) aMatrix inDataSet: (AdDataSet*) aDataSet
{
	NSFileManager* fileManager;
	NSString* fileName;
	
	fileManager = [NSFileManager defaultManager];
	fileName = [NSString stringWithFormat: @"%@.%@",
		[aDataSet name], [aMatrix name]];
	fileName = [gnuplotDir stringByAppendingPathComponent: fileName];		
	[fileManager removeFileAtPath: fileName 
		handler: NULL];		
}

- (void) removeGnuplotFilesForDataSet: (AdDataSet*) aDataSet
{
	NSEnumerator* matrixEnum;
	AdDataMatrix* matrix;
	
	matrixEnum = [[aDataSet dataMatrices] objectEnumerator];
	while(matrix = [matrixEnum nextObject])
		[self _removeFileForMatrix: matrix
			inDataSet: aDataSet];	
}

- (void) removeGnuplotFilesForDataSets: (NSArray*) anArray
{
	NSEnumerator* arrayEnum;
	id dataSet;
	
	arrayEnum = [anArray objectEnumerator];
	while(dataSet = [arrayEnum nextObject])
		[self removeGnuplotFilesForDataSet: dataSet];
}

/********************

Gnuplot TextView Delegate Methods 

********************/

/**
Sent by the gnuplot text view when the user causes an event in the view 
e.g. hits return, presses the up arrow etc.
This method acts on the following events

- newline - send data to gnuplot.
- moveUp - get previous gnuplot statement from history
- moveDown - get next gnuplot statement from history
*/
- (BOOL) textView: (NSTextView*) aTextView doCommandBySelector:(SEL)aSelector
{
	NSRange endRange;
	NSString* string, *errorString, *currentMatrixName;
	NSData* data;

	if([NSStringFromSelector(aSelector) isEqual: @"insertNewline:"])
	{
		commandRange.length = [[aTextView textStorage] length] - commandRange.location;
		string = [[[aTextView textStorage] attributedSubstringFromRange: commandRange] string];
		[self _addStringToHistory: string];
		string = [NSString stringWithFormat: @"%@\n", string];
		
		//Replace instance of the 'CurrentTable' with the name currently displayed matrix.
		if([string rangeOfString: @"CurrentTable"].location != NSNotFound)
		{
			currentMatrixName = [NSString stringWithFormat: @"%@.%@",
					     [[dataView dataSet] name], [[dataView displayedMatrix] name]];
			string = [string stringByReplacingString: @"CurrentTable" 
					withString: currentMatrixName];			
		}

		data  = [string dataUsingEncoding: NSASCIIStringEncoding];
		//Only write the data if gnuplot is running 
		if(gnuplotRunning)
			[gnuplotOutput writeData: data];

		endRange.location = [[aTextView textStorage] length];
		endRange.length = 0;
		[aTextView replaceCharactersInRange:endRange withString:
			[NSString stringWithFormat: @"\n", string]];

		endRange.location = [[aTextView textStorage] length];
		gnuplotPrompt.location = endRange.location;
		endRange.length = 0;
		[[aTextView textStorage] 
			replaceCharactersInRange:endRange 
			withAttributedString: promptString];
		gnuplotPrompt.length = [[aTextView textStorage] length] - gnuplotPrompt.location;
		//make sure the cursor appears after the ">"
		endRange.location = [[aTextView textStorage] length];
		[aTextView setSelectedRange: endRange];
		[aTextView scrollRangeToVisible: endRange];
		commandRange.location = [[aTextView textStorage] length];
		return YES;
	}
	else if([NSStringFromSelector(aSelector) isEqual: @"moveUp:"])
	{
		string = [self _previousStringFromHistory];
		commandRange.length = [[aTextView textStorage] length] - commandRange.location;
		[aTextView replaceCharactersInRange:commandRange withString: string];
		
		//Scroll so the end of command is visible
		endRange.location = [[aTextView textStorage] length];
		endRange.length = 0;
		[aTextView scrollRangeToVisible: endRange];
		
		return YES;
	}	
	else if([NSStringFromSelector(aSelector) isEqual: @"moveDown:"])
	{
		string = [self _nextStringFromHistory];
		commandRange.length = [[aTextView textStorage] length] - commandRange.location;
		[aTextView replaceCharactersInRange:commandRange withString: string];
		
		//Scroll so the end of command is visible
		endRange.location = [[aTextView textStorage] length];
		endRange.length = 0;
		[aTextView scrollRangeToVisible: endRange];
		
		return YES;
	}

	return NO;
}

- (BOOL) textView: (NSTextView*) aTextView
	shouldChangeTextInRange:  (NSRange) range
	replacementString: (NSString*) string
{
	NSRange intersectionRange;
	intersectionRange = NSIntersectionRange(range, gnuplotPrompt);
	
	if(intersectionRange.length == 0)
		return YES;
	else
		return NO;
}

@end

