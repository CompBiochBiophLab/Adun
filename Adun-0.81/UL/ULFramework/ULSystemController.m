/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 14:10:36 +0200 by michael johnston

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

#include "ULFramework/ULSystemController.h"

@implementation ULSystemController

- (id) init
{
	if((self = [super init]))
	{
		ioManager = [ULIOManager appIOManager];
		simulationDatabase = [ULDatabaseInterface databaseInterface];
		system = nil;
		buildSteps = [NSArray arrayWithObjects:
				@"Configuration",
				@"Topology",
				@"Merge",
				@"Interactions",
				nil];	
		[buildSteps retain];
		//Create a default system builder for pdbs
		systemBuilder = [[ULSystemBuilder alloc] initWithFileType: @"pdb" 
				forceField: nil];
	}	

	NSDebugLLog(@"ULSystemController", @"System Controller intialised");

	return self;
}

- (void) dealloc
{
	[system release];
	[systemBuilder release];
	[buildSteps release];
	[configurationFileAnalyser release];
	[super dealloc];
}

- (void) setForceField: (NSString*) forceFieldName
{
	[systemBuilder setForceField: forceFieldName];
}

- (id) systemBuilder 
{
	return [[systemBuilder retain] autorelease];
}

- (void) setBuildMolecule: (NSString*) path
{
	[systemBuilder setBuildMolecule: path];
}

- (NSMutableDictionary*) buildOptions
{
	return [systemBuilder buildOptions];
}

- (NSMutableDictionary*) preprocessOptions
{
	return [systemBuilder preprocessOptions];
}

- (BOOL) removeMolecule
{
	return [systemBuilder removeMolecule];
}

- (NSString*) _buildPart: (NSString*) part 
	options: (NSDictionary*) optionsDict 
	error: (NSError**) buildError
{
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];	
	NSString* buildInfo; 
	NSDictionary* userInfo = nil;

	NS_DURING
	{
		buildInfo = nil; 
		[systemBuilder buildPart: part
			options: optionsDict
			error: buildError
			userInfo: &buildInfo];
		[notificationCenter postNotificationName: @"ULSystemBuildSectionCompleted" 
			object: part
			userInfo: [NSDictionary dictionaryWithObject: buildInfo 
					forKey: @"ULBuildSectionUserInfoKey"]];
	}
	NS_HANDLER
	{
		if(buildInfo != nil)
			userInfo = [NSDictionary dictionaryWithObject: buildInfo
					forKey: @"ULBuildSectionUserInfoKey"]; 
	
		[notificationCenter postNotificationName: @"ULSystemBuildDidAbortNotification"
			object: [systemBuilder valueForKey:@"buildPosition"]
			userInfo: userInfo];
		[localException raise];
	}
	NS_ENDHANDLER

	return [systemBuilder valueForKey: @"buildPosition"];
}

- (void) _finaliseBuild
{
	FILE* file_p;
	id buildOutput;
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];	

	buildOutput = [[NSUserDefaults standardUserDefaults] 
			stringForKey: @"BuildOutput"];
	
	if(system != nil)
		[system release];

	system = [[systemBuilder valueForKey:@"system"] retain]; 
	file_p = fopen([buildOutput cString], "a"); 
	GSPrintf(file_p, @"\nBuild complete\n"); 
	fclose(file_p);

	[notificationCenter postNotificationName: @"ULSystemBuildCompletedNotification"
		object: buildOutput];
}

- (BOOL) buildSystemWithOptions: (NSDictionary*) optionsDict error: (NSError**) buildError
{
	BOOL retval;
	NSString* buildOutput, *buildOutputDir;
	id buildStep;
	FILE* file_p;
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];	
	NSEnumerator* buildEnum = [buildSteps objectEnumerator];

	//check where we will output the build information

	buildOutput = [[NSUserDefaults standardUserDefaults] 
			stringForKey: @"BuildOutput"];
	buildOutputDir = [buildOutput stringByDeletingLastPathComponent];

	if(![[NSFileManager defaultManager] isWritableFileAtPath: buildOutputDir])
	{
		NSWarnLog(@"Cannot write to specified build output directory %@",
			buildOutputDir);
		buildOutput  = [[[NSUserDefaults standardUserDefaults] 
				volatileDomainForName: NSRegistrationDomain]
				valueForKey: @"BuildOutput"];
		[[NSUserDefaults standardUserDefaults] setObject: buildOutput 
			forKey: @"BuildOutput"];
		NSWarnLog(@"Writing build output to default file at %@",  buildOutput);
	}

	file_p = fopen([buildOutput cString], "w");
	GSPrintf(file_p, @"Beginning build\n\n");
	fclose(file_p);
	
	//build
	NS_DURING
	{
		[notificationCenter postNotificationName: @"ULSystemBuildWillStart" 
			object: nil];		
		retval = YES;
		while((buildStep = [buildEnum nextObject]))
		{
			[self _buildPart: buildStep 
				options: optionsDict 
				error: buildError];

			if(*buildError != nil)
			{
				retval = NO;
				break;
			}
		}
		
		if(retval == YES)
			[self _finaliseBuild];
	}
	NS_HANDLER
	{
		file_p = fopen([buildOutput cString], "a");
		GSPrintf(file_p, @"Build failed - cancelling\n");
		fclose(file_p);
		[systemBuilder cancelBuild];
		[localException raise];
	}
	NS_ENDHANDLER	

	return retval;
}

- (BOOL) resumeBuild: (NSDictionary*) options error: (NSError**) buildError
{
	NSString *buildPosition; 

	buildPosition = [systemBuilder buildPosition];
	if([buildPosition isEqual: @"Configuration"])
		[NSException raise: NSInternalInconsistencyException
			format: @"Cannot resume - No build was started"];
	else
	{
		while(![buildPosition isEqual: @"Complete"])
		{
			[self _buildPart: buildPosition 
				options: options
				error: buildError];

			if(*buildError != nil)
				return NO;
		
			buildPosition = [systemBuilder buildPosition];
		}
	}	

	[self _finaliseBuild];

	return YES;
}

- (void) cancelBuild
{
	[systemBuilder cancelBuild];
}

- (void) threadedSaveSystem: (id) param
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[simulationDatabase addObjectToFileSystemDatabase: system];
	[pool release];
	[NSThread exit];
}

- (void) saveSystem
{
	NSDebugLLog(@"ULSystemController", @"Saving system %@ to database",system);

	[NSThread detachNewThreadSelector: @selector(threadedSaveSystem:)
		toTarget:self
		withObject: nil];

	[[NSNotificationCenter defaultCenter] 
		postNotificationName: @"ULSystemDidChangeNotification"
		object: [system valueForKey:@"name"]];
}

- (AdDataSource*) system
{
	return [[system retain] autorelease];
}

@end
