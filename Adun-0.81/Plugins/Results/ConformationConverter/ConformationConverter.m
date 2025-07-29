/*
   Project: ConformationConverter

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-04 16:43:29 +0100 by michael johnston

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
a  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include "ConformationConverter.h"
#include <AdunKernel/AdunFileSystemSimulationStorage.h>
#include <math.h>

@implementation ConformationConverter

- (void) _outputPDBForSystem: (id) system 
	withMemento: (id) memento
	toFileStream: (MTFileStream*) fileStream
{
	id structure;

	structure = ULConvertDataSourceToPDBStructure2(
			[system dataSource],
			[memento dataMatrixWithName: @"Coordinates"]);
	[structure writePDBToStream: fileStream];
}

- (void) _outputXYZForSystem: (id) system 
	withMemento: (id) memento
	toFileStream: (FILE*) outFile
{
	int i, numberOfRows;
	NSArray* atoms;
	NSArray* row;
	AdMatrix* coordinates;
	id atom;

	coordinates = [[memento dataMatrixWithName: @"Coordinates"]
				cRepresentation];
	numberOfRows = coordinates->no_rows;
	atoms = [system elementTypes];

	GSPrintf(outFile, @"%d\n", numberOfRows);
	GSPrintf(outFile, @"Energy:\n");
	for(i=0; i<numberOfRows; i++)
	{
		atom = [atoms objectAtIndex: i];
		GSPrintf(outFile, @"%-12@%-12.3lf%-12.3lf%-12.3lf\n", 
				atom, 
				coordinates->matrix[i][0],
				coordinates->matrix[i][1],
				coordinates->matrix[i][2]);
	} 

	[[AdMemoryManager appMemoryManager] 
		freeMatrix: coordinates];
}

- (id) init
{
	return self;
}

//Default implementation
- (BOOL) checkInputs: (NSArray*) inputs error: (NSError**) error
{
	return YES;
}

- (NSDictionary*) pluginOptions: (NSArray*) inputs
{
	NSMutableDictionary* options, *systemMenu, *formatMenu, *frameMenu;
	NSEnumerator* systemEnum;
	AdSimulationData* data;
	id system, systems;

	data = [inputs objectAtIndex: 0];
	systems = [[data systemCollection] fullSystems];

	options = [NSMutableDictionary newNodeMenu: NO];
	
	//Systems Menu
	systemMenu = [NSMutableDictionary newLeafMenu];
	[systemMenu setSelectionMenuType: @"Multiple"];
	[options addMenuItem: @"Systems" 
		withValue: systemMenu];
	systemEnum = [systems objectEnumerator];
	while(system = [systemEnum nextObject])
		[systemMenu addMenuItem: [system systemName]];

	//Format Menu
	formatMenu = [NSMutableDictionary newLeafMenu];
	[formatMenu addMenuItems: 
		[NSArray arrayWithObjects: 
			@"pdb",
			@"xyz",
			nil]];
	[formatMenu setDefaultSelection: @"pdb"];		
	[options addMenuItem: @"Format" 
		withValue: formatMenu];

	//Frames menu
	frameMenu = [NSMutableDictionary newNodeMenu: NO];
	[frameMenu addMenuItem: @"Start"
		withValue: [NSNumber numberWithInt: 0]];
	//FIXME: May have different number of frames per system	
	[frameMenu addMenuItem: @"Length"
		withValue: [NSNumber numberWithInt:
		[data numberOfFramesForSystem: system]]];
	[frameMenu addMenuItem: @"Stepsize"
		withValue: [NSNumber numberWithInt: 1]];
	[options addMenuItem: @"Frames"
		withValue: frameMenu];
	
	return  options;
}	

- (NSDictionary*) processInputs: (NSArray*) inputs userOptions: (NSDictionary*) options; 
{
	int i, step;
	int startFrame, endFrame, totalFrames, output;
	FILE* outFile;
	id systemNames, systemName, format, memento;
	id system;
	NSString* filename;
	NSEnumerator* systemNamesEnum;
	NSMutableString* returnString;
	NSMutableDictionary* notificationDict;
	NSAutoreleasePool* pool;
	MTFileStream* fileStream;

	currentOptions = [[options mutableCopy] autorelease];
	simulation = [inputs objectAtIndex: 0];

	//Set up the return string
	returnString = [NSMutableString stringWithCapacity: 1];
	[returnString appendFormat:
		 @"Output conformations for simulation at %@\n\n", 
		 [[simulation dataStorage] storagePath]];
	
	//Selected Systems
	systemNames = [[currentOptions valueForMenuItem: @"Systems"] 
			selectedItems];
	systemNamesEnum = [systemNames objectEnumerator];
	NSDebugLLog(@"ConformationConverter", 
		@"Selected systemNames %@. Simulation %@", 
		systemNames, simulation);

	//Format
	format = [[[currentOptions valueForMenuItem: @"Format"] 
			selectedItems] objectAtIndex: 0];
	NSDebugLLog(@"ConformationConverter", 
		@"Format %@", format);

	//Frames
	startFrame = [[currentOptions valueForKeyPath: @"Frames.Start"] intValue];
	endFrame = startFrame + [[currentOptions valueForKeyPath: @"Frames.Length"] 
					intValue];
	step = [[currentOptions valueForKeyPath: @"Frames.Stepsize"] 
			intValue];
	
	totalFrames = [systemNames count]*(endFrame - startFrame);
	totalFrames = lround((double)totalFrames/(double)step);		

	notificationDict = [NSMutableDictionary dictionary];	
	[notificationDict setObject: [NSNumber numberWithInt: totalFrames]
		forKey: @"ULAnalysisPluginTotalSteps"];
	NSDebugLLog(@"ConformationConverter", 
		@"Start Frame %d. End Frame %d", startFrame, endFrame);

	output = 0;
	while(systemName = [systemNamesEnum nextObject])
	{
		NSDebugLLog(@"ConformationConverter", 
			@"System %@", systemName);
		NSDebugLLog(@"ConformationConverter", 
			@"Beginning");
		system = [[simulation systemCollection] 
				systemWithName: systemName];
		if([simulation numberOfFramesForSystem: system] != 0)
		{
			filename = [NSString stringWithFormat: 
					@"%@.%@", systemName, format];
			filename = [[[simulation dataStorage] storagePath] 
					stringByAppendingPathComponent: filename];
			[returnString appendFormat:
				 @"\tSubsystem %@ - File %@\n", systemName, filename];

			if([format isEqual: @"pdb"])
				fileStream = [MTFileStream streamToFile: 
						filename];
			else
				outFile = fopen([filename cString], "w");

			pool = [NSAutoreleasePool new];
			for(i=startFrame; i< endFrame; i = i+step)
			{
				NSDebugLLog(@"ConformationConverter", 
					@"Retrieving frame %d", i);
				memento = [simulation mementoForFrame: i 
						ofSystem: system];
				NSDebugLLog(@"ConformationConverter", 
					@"Outputting frame %d", i);
				if([format isEqual: @"pdb"])
					[self _outputPDBForSystem: system 
						withMemento: memento
						toFileStream: fileStream];
				else
					[self _outputXYZForSystem: system 
						withMemento: memento
						toFileStream: outFile];

				NSDebugLLog(@"ConformationConverter", @"Complete");
				output++;
				if(output%10 == 0)
				{
					[notificationDict setObject: 
						[NSNumber numberWithInt: output]
						forKey: @"ULAnalysisPluginCompletedSteps"];
					[[NSNotificationCenter defaultCenter] 
						postNotificationName:
						@"ULAnalysisPluginDidCompleteStepNotification"
						object: nil
						userInfo: notificationDict];
					[pool release];	
					pool = [NSAutoreleasePool new];
				}
			}
			[pool release];

			if([format isEqual:@"pdb"])
				[fileStream close];
			else
				fclose(outFile);
		}
		else
		{
			NSWarnLog(@"\tNo dynamics for %@\n", systemName);
			[returnString appendFormat: @"No dynamics for %@\n", systemName];
		}

 	}

	[returnString appendString: @"\nComplete\n"];
	
	return [NSDictionary dictionaryWithObject: returnString
		 forKey: @"ULAnalysisPluginString"];
}

@end
