/*
   Project: CAlphaDistance

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-08-01 16:17:23 +0200 by michael johnston

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
#include "CAlphaDistance.h"
#include <ULFramework/ULMenuExtensions.h>
#include <MolTalk/MTStructure.h>

@implementation CAlphaDistance

- (void) updateProgressToStep: (int) completedSteps 
		ofTotalSteps: (int) totalSteps 
		withMessage: (NSString*) message
{
	NSMutableDictionary *notificationInfo = [NSMutableDictionary dictionary];

	[notificationInfo setObject: [NSNumber numberWithDouble: totalSteps]
		forKey: @"ULAnalysisPluginTotalSteps"];
	[notificationInfo setObject: message
		forKey: @"ULAnalysisPluginProgressMessage"];
	[notificationInfo setObject: [NSNumber numberWithDouble: completedSteps]
		forKey: @"ULAnalysisPluginCompletedSteps"];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"ULAnalysisPluginDidCompleteStepNotification"
		object: self
		userInfo: notificationInfo];
}

- (id) init
{
	if(self == [super init])
	{
		infoDict = [[NSBundle bundleForClass: [self class]]
				infoDictionary];
		[infoDict retain];		
	}

	return self;
}

//Default implementation
- (BOOL) checkInputs: (NSArray*) inputs error: (NSError**) error
{
	return YES;
}

- (NSDictionary*) pluginOptions: (NSArray*) inputs 
{
	NSMutableDictionary* mainMenu = [NSMutableDictionary newNodeMenu: NO];
	NSMutableDictionary* xAxis = [NSMutableDictionary newLeafMenu];
	NSMutableDictionary* yAxis = [NSMutableDictionary newLeafMenu];
	NSMutableDictionary* yRange = [NSMutableDictionary newNodeMenu: NO];
	NSMutableDictionary* xRange = [NSMutableDictionary newNodeMenu: NO];
	NSEnumerator* chainEnum;
	MTStructure* structure;
	MTChain* chain, *firstChain = nil;

	structure = [inputs objectAtIndex: 0];
	chainEnum = [structure allChains];
	
	[xAxis setSelectionMenuType: @"Single"];
	[yAxis setSelectionMenuType: @"Single"];
	
	while((chain = [chainEnum nextObject]))
	{
		if([chain countResidues] != 0)
		{
			if(firstChain == nil)
				firstChain = chain;
				
			[xAxis addMenuItem: [chain name]];
			[yAxis addMenuItem: [chain name]];
		}
	}
	
	if([[xAxis menuItems] count] > 1)
	{
		[xAxis addMenuItem: @"All"];
		[yAxis addMenuItem: @"All"];
	}
	
	[xAxis setDefaultSelection: [firstChain name]];
	[yAxis setDefaultSelection: [firstChain name]];
	
	[xRange addMenuItem: @"Start" withValue: @"0"];
	[xRange addMenuItem: @"Length"
		withValue: [NSNumber numberWithInt: [firstChain countResidues]]];
	
	[yRange addMenuItem: @"Start" withValue: @"0"];
	[yRange addMenuItem: @"Length"
		  withValue: [NSNumber numberWithInt: [firstChain countResidues]]];
		  	
	[mainMenu addMenuItem: @"X Chains" withValue: xAxis];
	[mainMenu addMenuItem: @"X Range" withValue: xRange];
	[mainMenu addMenuItem: @"Y Chains" withValue: yAxis];
	[mainMenu addMenuItem: @"Y Range" withValue: yRange];

	return mainMenu;
}

- (NSArray*) _residuesFromSelection: (NSArray*) selectedChains structure: (MTStructure*) aStructure
{
	NSString *selectedChain;
	NSEnumerator* chainEnum;
	NSMutableArray* residues = [NSMutableArray array];
	MTChain* chain;
	
	chainEnum = [aStructure allChains];

	if([selectedChains containsObject: @"All"])
	{
		while((chain = [chainEnum nextObject]))
			[residues addObjectsFromArray: [[chain allResidues] allObjects]];
	}
	else
	{
		selectedChain = [selectedChains objectAtIndex:0];
		while((chain = [chainEnum nextObject]))
		{
			if([[chain name] isEqual: selectedChain])
			{
				[residues addObjectsFromArray: [[chain allResidues] allObjects]];
				break;
			}
		}
	}
	
	return residues;
}

- (NSDictionary*) processInputs: (NSArray*) inputs userOptions: (NSDictionary*) options 
{	
	int i, j;
	double distance;
	NSRange xRange, yRange;
	NSArray* xResidues, *yResidues;
	NSMutableArray *standardHeaders, *threeDHeaders, *standardRow;
	NSString* string;
	AdMutableDataMatrix* threeDMatrix, *standardMatrix;
	AdDataSet* dataSet;
	id structure;

	structure = [inputs objectAtIndex: 0];
	if(![structure isKindOfClass: [MTStructure class]])
		[NSException raise: NSInvalidArgumentException
			format: @"CAlphaDistance cannot process %@ objects", 
			NSStringFromClass([structure class])];
	
	//Create xResidues and xRang
	xResidues = [self _residuesFromSelection: [options valueForKeyPath: @"X Chains.Selection"]
			structure: structure];
	xRange.location = [[options valueForKeyPath: @"X Range.Start"] intValue];
	xRange.length = [[options valueForKeyPath: @"X Range.Length"] intValue];
	
	if(NSMaxRange(xRange) > [xResidues count])
	{
		[NSException raise: NSInvalidArgumentException
			format: @"Specified X range (%@) incompatible with number of selected residues (%d)",
			NSStringFromRange(xRange), [xResidues count]];
	}
	
	//Create yResidues and yRange
	yResidues = [self _residuesFromSelection: [options valueForKeyPath: @"Y Chains.Selection"]
			structure: structure];
	yRange.location = [[options valueForKeyPath: @"Y Range.Start"] intValue];
	yRange.length = [[options valueForKeyPath: @"Y Range.Length"] intValue];
	
	if(NSMaxRange(yRange) > [yResidues count])
	{
		 [NSException raise: NSInvalidArgumentException
			     format: @"Specified Y range (%@) incompatible with number of selected residues (%d)",
		  NSStringFromRange(yRange), [yResidues count]];		  
	}
	
	//create the data matrix for holding the standard representation
	standardMatrix = [[AdMutableDataMatrix alloc] 
				initWithNumberOfColumns: [yResidues count]
				columnHeaders: nil
				columnDataTypes: nil];
	[standardMatrix setName: @"Distance"];
	[standardMatrix autorelease];
	
	standardHeaders = [NSMutableArray array];
	for(i=0; i<[yResidues count]; i++)
	{
		string = [NSString stringWithFormat: @"%@%@ ",
				[[yResidues objectAtIndex: i] name], 
				[[yResidues objectAtIndex: i] number]];
		[standardHeaders addObject: string];
	}	
	[standardMatrix setColumnHeaders: standardHeaders];

	//create the matrix for holding the grid representation
	threeDMatrix = [[AdMutableDataMatrix alloc] 
			initWithNumberOfColumns: 3
			columnHeaders: nil
			columnDataTypes: nil];
	[threeDMatrix autorelease];
	[threeDMatrix setName: @"Grid"];
	threeDHeaders = [NSArray arrayWithObjects: 
			@"Residue One",
			@"Residue Two", 
			@"Distance", nil];
	[threeDMatrix setColumnHeaders: threeDHeaders];		

	standardRow = [NSMutableArray array];
	for(i=xRange.location; i<NSMaxRange(xRange); i++)
	{
		for(j=yRange.location; j<NSMaxRange(yRange); j++)
		{
			distance = [[xResidues objectAtIndex: i] distanceCATo: [yResidues objectAtIndex: j]];
			[standardRow addObject:
				[NSNumber numberWithDouble: distance]];
			[threeDMatrix extendMatrixWithRow: 
				[NSArray arrayWithObjects:
					[NSNumber numberWithInt: i],
					[NSNumber numberWithInt: j],
					[NSNumber numberWithDouble: distance],
					nil]];
		} 
		[standardMatrix extendMatrixWithRow: standardRow];
		[standardRow removeAllObjects];
	}

	//create the data set
	dataSet = [[AdDataSet alloc] initWithName: @"DataSet"
			inputReferences: nil
			dataGeneratorName: @"CAlphaDistance"
			dataGeneratorVersion: [infoDict objectForKey: @"PluginVersion"]];
	[dataSet autorelease];
	[dataSet addDataMatrix: threeDMatrix];
	[dataSet addDataMatrix: standardMatrix];

	[self updateProgressToStep: 90
		ofTotalSteps: 100
		withMessage:  @"Complete"];

	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSMutableArray arrayWithObject: dataSet], @"ULAnalysisPluginDataSets",
			@"Complete", @"ULAnalysisPluginString", nil];
}

@end
