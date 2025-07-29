/*
   Project: PDBInfo

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

#include "PDBInfo.h"
#include <MolTalk/MTResidue.h>

@implementation PDBInfo

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
	return [NSDictionary dictionary];
}

- (NSDictionary*) processInputs: (NSArray*) inputs userOptions: (NSDictionary*) options 
{
	int i, nonStandard;
	id chains; 
	NSMutableString* info;
	NSString *expType;
	NSEnumerator* residueEnum, *chainEnum;
	MTChain* chain;
	MTResidue* residue;
	MTStructure *structure;

	structure = [inputs objectAtIndex: 0];
	if(![structure isKindOfClass: [MTStructure class]])
		[NSException raise: NSInvalidArgumentException
			format: @"CAlphaDistance cannot process %@ objects", 
			NSStringFromClass([structure class])];

	info = [NSMutableString stringWithCapacity: 1];
	[info appendString: @"General Information\n\n"];
	[info appendFormat: @"PDB Code: %@. Title: %@\n\n", [structure pdbcode], [structure title]];
	[info appendFormat: @"Header: %@\n\n", [structure header]];
	[info appendFormat: @"Keywords: %@\n\n", [[structure keywords] componentsJoinedByString: @" "]];

	i = [structure expdata];
	switch(i)
	{
		case 100:
			expType = @"X-Ray";
			break;	
		case 101:
			expType = @"NMR";
			break;
		case 102:
			expType = @"Theoretical Model";
			break;
		case 103:
			expType = @"Other";
			break;
		case 104:
			expType = @"Unknown";
			break;
	}
	[info appendFormat: @"Experiment Type: %@\n", expType];

	[info appendFormat: @"Resolution: %f\n", [structure resolution]];
	[info appendString: @"\nChains\n\n"];

	chains = [[structure allChains] allObjects];
	chainEnum = [structure allChains];	

	[info appendFormat: @"There are %d chains\n", [chains count]];
	while(chain = [chainEnum nextObject])
	{
		[info appendFormat: @"\nChain %c. Description: %@\n\n", [chain code], [chain description]];
		[info appendFormat: @"Sequence: %@\n\n", [chain getSequence]];
		[info appendFormat: @"Number of residues: %d\n", [chain countResidues]];
		[info appendFormat: @"Number of heterogens: %d\n", [chain countHeterogens]];
		[info appendFormat: @"Number of solvent molecules: %d\n", [chain countSolvent]];
		[info appendFormat: @"Number of standard amino acids: %d\n", [chain countStandardAminoAcids]];
		
		//Check non-standard amino acids and flag
		nonStandard = [chain countResidues] -  [chain countStandardAminoAcids];
		if(nonStandard != 0)
		{
			[info appendFormat: @"\nDetected %d non-standard amino acids:\n", nonStandard];
			residueEnum = [chain allResidues];
			while(residue = [residueEnum nextObject])
			{
				if(![residue isStandardAminoAcid])
					[info appendFormat: @"\tResidue %@ - %@\n", [residue number], [residue name]];
			}
		}
	}


	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			info, @"ULAnalysisPluginString", nil];
}


@end
