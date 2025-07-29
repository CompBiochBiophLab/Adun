/*
   Project: AdunShell

   Copyright (C) 2008 Michael Johnston
   Author:  Michael Johnston

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
#include "AdunShell.h"
#include <StepTalk/StepTalk.h>
#include "STShell.h"

@implementation AdunShell

- (id) initWithDictionary: (NSDictionary*) dictionary
{
	//Designated initialiser
	return self;
}

- (void) dealloc
{
	[super dealloc];	
}

/***
AdController Methods
***/

- (void) coreWillStartSimulation: (AdCore*) anObject
{
	//Call AdControllers implementation
	//This sets up the core and configurationGenerator ivars.
	[super coreWillStartSimulation: anObject];
}

- (void) runSimulation
{
	//Create conversation
	STEnvironmentDescription *desc;
	STEnvironment	*environment;
	STConversation	*conversation;	
	STShell* shell;
	NSString* languageName;
	
	environment = [STEnvironment environmentWithDefaultDescription];
	languageName = [[STLanguageManager defaultManager] defaultLanguage];
	
	/* Register basic objects: Environment, Transcript */
	[environment setObject:environment forName:@"Environment"];
	[environment setObject:core forName: @"Core"];
	[environment setObject:[core checkpointManager] forName: @"CheckpointManager"];
	[environment setObject: configurationGenerator forName: @"Simulator"];
	[environment setObject: [configurationGenerator forceFields] forName: @"ForceFields"];
	[environment setObject: [configurationGenerator systems] forName: @"Systems"];
	[environment setObject: [NSNumber numberWithDouble: STCAL] forName: @"ConversionConstant"];
	
	[environment includeFramework: @"AdunKernel"];
	[environment includeFramework: @"MolTalk"];
	[environment includeFramework: @"ULFramework"];
	
	[environment loadModule:@"SimpleTranscript"];
	[environment setCreatesUnknownObjects:YES];
	
	/* FIXME: make this an option */
	[environment setFullScriptingEnabled:YES];
	
	conversation = [[STConversation alloc] 
				initWithContext:environment
				language:languageName];
	[conversation interpretScript: @"Transcript := SimpleTranscript sharedTranscript"];			
				
	shell = [[STShell alloc] initWithConversation:conversation];
	GSPrintf(stdout, @"\nInitially available objects:\n\tEnvironment - The shell environment.\n"
		@"\tSimulator - The configuration generation object.\n\tSystems - The collection of systems being simulated.\n"
		@"\tForceFields - The collection of force-fields operating on the systems.\n"
		@"\tCheckpointManager - Object controlling the automatic collection of data.\n"
		@"\tTranscript - Object for displaying detailed strings (like a 'print' command')\n\n"
		@"\nTo print a list of an objects methods use 'methodNames' e.g. ForceFields methodNames\n\n");
	[shell setPrompt: @"AdunShell > "];
	[environment setObject: shell forName: @"Shell"];			

	[shell run];
	
}

- (id) simulationResults
{
	//Return any data sets containing the controller results
	NSLog(@"Nothing to return");
	return nil;
}

- (void) cleanUp
{
	NSLog(@"Finished!");
	//Do clean up tasks
}

- (NSString*) description
{
	return @"AdunShell - Interactive shell for the AdunCore program";
}

@end
