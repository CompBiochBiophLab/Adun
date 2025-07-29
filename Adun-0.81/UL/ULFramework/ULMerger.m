/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 13:40:49 +0200 by michael johnston

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

#include "ULMerger.h"
#include <AdunKernel/AdFrameworkFunctions.h>

int residueSort(id num1, id num2, void *context);

int residueSort(id num1, id num2, void *context)
{
	int retval;
	int value;
	NSScanner* scanner;
	
	//Unfortunatly NSNumericSearch is not implemented yet
	//in gnustep.
	//The residue could have a 1 or 3 letter residue
	//name. Have to find which. 
	scanner = [[NSScanner alloc] initWithString: num1];
	[scanner setCharactersToBeSkipped: [NSCharacterSet letterCharacterSet]];
	if(![scanner scanInt: &value])
	{
		NSWarnLog(@"Unable to scan residue number from %@", num1);
		value = 0;
	}
	[scanner release];
	num1 = [[NSNumber alloc] initWithInt: value];
	
	scanner = [[NSScanner alloc] initWithString: num2];
	[scanner setCharactersToBeSkipped: [NSCharacterSet letterCharacterSet]];
	if(![scanner scanInt: &value])
	{
		NSWarnLog(@"Unable to scan residue number from %@", num1);
		value = 0;
	}
	[scanner release];
	num2 = [[NSNumber alloc] initWithInt: value];
	
        retval = [num1 compare: num2];
	[num1 release];
	[num2 release];
	
	return retval;
}

@implementation ULMerger

+ (void) initialize
{
	NSDictionary *defaults = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
					forKey: @"VerboseBuildOutput"];
					
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];				
}

- (void) _checkErrors: (NSError**) buildError
{
	NSMutableString* errorString = [NSMutableString stringWithCapacity: 1];
	NSDictionary* missingAtoms, *extraAtoms;
	NSMutableDictionary *userInfo;
	NSArray* residues;
	NSEnumerator *residueEnum, *atomEnum;
	NSString* suggestionString;
	id residue, atom;

	missingAtoms = [delegate missingAtoms];
	extraAtoms = [delegate extraAtoms];

	if([missingAtoms count] != 0)
	{
		[errorString appendFormat: @"%d residues are missing atoms\n\n", [missingAtoms count]];
		residues = [[missingAtoms allKeys]
				 sortedArrayUsingFunction: residueSort context: NULL];
		residueEnum = [residues objectEnumerator];
		while((residue = [residueEnum nextObject]))
		{
			[errorString appendFormat: @"Residue %@ is missing atoms\n", residue];
			atomEnum = [[missingAtoms objectForKey: residue] objectEnumerator];
			while((atom = [atomEnum nextObject]))
				[errorString appendFormat: @"%@ ", atom];
			[errorString appendFormat: @"\n\n"];
		}
	}

	if([extraAtoms count] != 0)
	{
		[errorString appendFormat: @"%d residues have unidentified atoms\n\n", [extraAtoms count]];
		
		if(([[NSUserDefaults standardUserDefaults] boolForKey: @"VerboseBuildOutput"]) || ([extraAtoms count] <= 2))
		{
			residues = [[extraAtoms allKeys]
				    sortedArrayUsingFunction: residueSort context: NULL];
			residueEnum = [residues objectEnumerator];
			while((residue = [residueEnum nextObject]))
			{
				atomEnum = [[extraAtoms objectForKey: residue] objectEnumerator];
				[errorString appendFormat: @"Residue %@ contains unidentified atoms\n", residue];
				while((atom = [atomEnum nextObject]))
					[errorString appendFormat: @"%@ ", atom];
				[errorString appendFormat: @"\n\n"];
			}
		}
	}

	if([errorString length] != 0)
	{
		suggestionString = @"For missing hydrogens we suggest you use the \
AddHydrogens plugin (cbbl.imim.es/Adun/downloads/plugins/) to add them.\n\
Missing heavy atoms could lead to critical errors and a\
simulation should not usually be attempted without them.\n\
Extra/Unidentified atoms must be look at on a per case basis.\n\
Some possible source of this error are naming problems\
in the pdb or the topology section of the force field used.\n";
	
		userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject: @"Errors while merging pdb configuration with expected topology."
			forKey: NSLocalizedDescriptionKey];
		[userInfo setObject: errorString
			forKey: @"ULBuildErrorDetailedDesciptionKey"];
		[userInfo setObject: suggestionString
			forKey: @"ULBuildErrorRecoverySuggestionKey"];

		*buildError = [NSError errorWithDomain: @"ULBuildErrorDomain"
					code: 3
					userInfo: userInfo];
	}
}

- (id) mergeTopologyFrame: (NSDictionary*) frame 
	withConfiguration: (NSDictionary*) conf
	error: (NSError**) buildError
	userInfo: (NSString**) buildInfo
{
	int i, confLocation, frameLocation, resIndex;
	id frameResidue, confResidue, atom, path;
	NSError* error=nil;
	NSMutableArray* confAPR, *frameAPR;
	NSMutableArray* confAtomList, *frameAtomList, *indexes;
	NSEnumerator* atomEnum;
	NSRange confResidueRange, frameResidueRange; 

	path = [[NSUserDefaults standardUserDefaults] stringForKey: @"BuildOutput"];
	buildOutput = fopen([path cString], "a");
	[buildString release];
	buildString = [[NSMutableString string] retain];
	if(buildInfo != NULL)
		*buildInfo = buildString;

	[delegate initWithConfiguration: conf topologyFrame: frame];

	confAPR = [conf valueForKey:@"AtomsPerResidue"];
	frameAPR = [frame valueForKey:@"AtomsPerResidue"];
	frameAtomList = [frame valueForKey:@"AtomNames"];
	confAtomList = [conf valueForKey:@"AtomNames"];
	indexes = [NSMutableArray arrayWithCapacity:1];

	[buildString appendString: @"\nBegining merge of expected topology and configuration from the \
coordinates file.\n"];
	[buildString appendFormat: @"Expecting %d atoms based on topology.\nThere are %d atoms in the molecule file.\n",
			[frameAtomList count], [confAtomList count]];
	if([frameAtomList count] > [confAtomList count])
		[buildString appendFormat: @"The configuration is missing atoms. There will be errors.\n"];
	else if([frameAtomList count] == [confAtomList count])
		[buildString appendFormat: @"Number of atoms match. Looking good ...\n"];
	
	GSPrintf(buildOutput, @"PDB Atoms per molecule %@\n\n", confAPR);
	GSPrintf(buildOutput, @"Library Atoms per molecule %@\n\n", frameAPR);

	frameLocation = confLocation = 0;
	for(i=0; i<[frameAPR count]; i++)
	{
		[delegate didBeginMolecule: i];
		
		confResidueRange.location = confLocation;
		confResidueRange.length = [[confAPR objectAtIndex:i] intValue];	
		frameResidueRange.location = frameLocation;
		frameResidueRange.length = [[frameAPR objectAtIndex:i] intValue];	

		frameResidue = [frameAtomList subarrayWithRange: frameResidueRange];
		confResidue = [confAtomList subarrayWithRange: confResidueRange];

		GSPrintf(buildOutput, @"\nResidue %d. %@\n", i, [[frame valueForKey:@"ResidueList"] objectAtIndex: i]);
		GSPrintf(buildOutput, @"There are %d Library Atoms\n", [frameResidue count]);
		GSPrintf(buildOutput, @"Library Atoms %@\n", frameResidue);
		GSPrintf(buildOutput, @"There are %d PDB Atoms\n", [confResidue count]);
		GSPrintf(buildOutput, @"PDB Atoms %@\n", confResidue);

		atomEnum = [frameResidue objectEnumerator];
		while((atom = [atomEnum nextObject]))
		{
			if(![confResidue containsObject: atom])
			{
				[delegate foundTopologyAtomNotInConfiguration: 
					[frameResidue indexOfObject: atom] + frameLocation];
			}
			else
			{
				resIndex = [confResidue indexOfObject: atom];
				[delegate matchedConfigurationAtom: confLocation + resIndex
					toTopologyAtom: frameLocation + [frameResidue indexOfObject: atom]];
			}
		}

		atomEnum = [confResidue objectEnumerator];
		while((atom = [atomEnum nextObject]))
		{
			if(![frameResidue containsObject: atom])
			{
				[delegate foundConfigurationAtomNotInTopology: 
					[confResidue indexOfObject: atom] + confLocation];
			}
		}
		
		fflush(buildOutput);

		[delegate didEndMolecule: i];
		
		confLocation += [confResidue count];
		frameLocation += [frameResidue count];
	}

	fclose(buildOutput);

	[buildString appendString: @"\nMerge completed\n"];
	[self _checkErrors: &error];
	if(buildError != NULL)
	{
		if(error != nil)
			AdLogError(error);
		*buildError = error;
	}	

	return [delegate finalise];
}

- (void) setDelegate: (id) del
{
	delegate = del;
}


@end
