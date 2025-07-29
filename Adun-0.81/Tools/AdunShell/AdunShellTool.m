/*
 Project: Adun
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Adapted from StepTalk Shell by Stefan Urbanek <urbanek@host.sk>
 This file is a minor modification of stshell_tool.m
 Adpated By: Michael Johnston
 
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

#import <Foundation/Foundation.h>
#import <StepTalk/StepTalk.h>
#import <AdunKernel/AdunController.h>
#import <ULFramework/ULDatabaseInterface.h>
#import <ULFramework/ULAnalysisManager.h>

@interface STShellTool:NSObject
{
	unsigned int currentArg;
	NSArray *arguments;
	NSString *environmentName;
	NSString *hostName;
	NSString *typeName;
	NSString *languageName;
	STConversation *conversation;	
}
- (int)parseArguments;
- (NSString *)nextArgument;
- (void)reuseArgument;
- (int)runShell;
- (void)printHelp;
@end

@implementation STShellTool

- (int)parseArguments
{
	NSString *arg;
	BOOL      isOption = NO;
	
	arguments = [[NSProcessInfo processInfo] arguments];
	
	[self nextArgument];
	
	while( (arg = [self nextArgument]) )
	{
		isOption = NO;
		if( [arg hasPrefix:@"--"] )
		{
			arg = [arg substringFromIndex:2];
			isOption = YES;
		}
		else if( [arg hasPrefix:@"-"] )
		{
			arg = [arg substringFromIndex:1];
			isOption = YES;
		}
		
		if ([@"help" hasPrefix:arg])
		{
			[self printHelp];
			return 1;
		}
		else if ([@"language" hasPrefix:arg])
		{
			RELEASE(languageName);
			languageName = [self nextArgument];
			if(!languageName)
			{
				[NSException raise:@"STShellToolException"
					    format:@"Language name expected"];
			}
		}
		else if ([@"environment" hasPrefix:arg])
		{
			RELEASE(environmentName);
			environmentName = [self nextArgument];
			if(!environmentName)
			{
				[NSException raise:@"STShellToolException"
					    format:@"Environment name expected"];
			}
		}
		else if ([@"host" hasPrefix:arg])
		{
			RELEASE(hostName);
			hostName = [self nextArgument];
			if(!hostName)
			{
				[NSException raise:@"STShellToolException"
					    format:@"Host name expected"];
			}
		}
		else if ([@"type" hasPrefix:arg])
		{
			RELEASE(typeName);
			typeName = [self nextArgument];
			if(!typeName)
			{
				[NSException raise:@"STShellToolException"
					    format:@"Environment description (type) name expected"];
			}
		}
		else if(!isOption)
		{
			break;
		}
	}
	
	if(arg)
	{
		[self reuseArgument];
	}
	
	return 0;
}

- (NSString *)nextArgument
{
	if(currentArg < [arguments count])
	{
		return [arguments objectAtIndex:currentArg++];
	}
	
	return nil;
}

- (void)reuseArgument
{
	currentArg--;
}
/* Method taken from stexec.m - look there for updates */
- (void)createConversation
{
	STEnvironmentDescription *desc;
	STEnvironment            *environment;
	
	if(environmentName)
	{
		/* user wants to connect to a distant environment */
		conversation = [[STRemoteConversation alloc]
				initWithEnvironmentName:environmentName
				host:hostName
				language:languageName];
		if(!conversation)
		{
			NSLog(@"Unable to connect to %@@%@", environmentName, hostName);
			return;
		}
	}
	else
	{
		/* User wants local temporary environment */
		if(!typeName || [typeName isEqualToString:@""])
		{
			environment = [STEnvironment environmentWithDefaultDescription];
		}
		else
		{
			desc = [STEnvironmentDescription descriptionWithName:typeName];
			environment = [STEnvironment environmentWithDescription:desc];
		}
		
		/* Register basic objects: Environment, Transcript */
		
		[environment setObject:environment forName:@"Environment"];
		[environment setObject: [ULAnalysisManager managerWithDefaultLocations] forName: @"PluginManager"];
		[environment setObject: [ULDatabaseInterface databaseInterface] forName: @"Database"];
		
		[environment includeFramework: @"AdunKernel"];
		[environment includeFramework: @"MolTalk"];
		[environment includeFramework: @"ULFramework"];
		
		[environment loadModule:@"SimpleTranscript"];
		[environment setCreatesUnknownObjects:YES];
		[environment setFullScriptingEnabled:YES];
	
		[[STResourceManager defaultManager] setSearchesInLoadedBundles: NO];	
		conversation = [[STConversation alloc] 
				initWithContext:environment
				language:languageName];
		[conversation interpretScript: @"Transcript := SimpleTranscript sharedTranscript"];	
	}
}

- (int)runShell
{	
	BOOL runInterpreter;
	int index;
	Class STShell;
	NSBundle* shellBundle;
	NSError* error = nil;
	NSString* templateName, *scriptName, *script;
	NSMutableDictionary* coreTemplate;
	id shell;
	
	[self parseArguments];
	
	if((templateName = [[NSUserDefaults standardUserDefaults] stringForKey: @"Template"]) != nil)
	{
		//Load the template, change the controller to AdunShell, write it out and run AdunCore
		coreTemplate = [NSMutableDictionary dictionaryWithContentsOfFile: templateName];
		
		if(coreTemplate == nil)
		{
			NSWarnLog(@"Counld not read specified template (%@)", coreTemplate);
			return 1;
		}
		
		[coreTemplate setValue: [NSDictionary dictionaryWithObject: @"AdunShell" forKey: @"Class"]
			forKeyPath:@"objectTemplates.controller"];
		templateName = 	[NSString stringWithFormat: @"%@.mod", templateName];
		[coreTemplate writeToFile: templateName atomically: NO];
		
		//Using NSTask causes strange things to happen in the launched process.
		//Something to do with it being interactive however no idea what
		//Using system works though.
		templateName = [NSString stringWithFormat: @"%@ -Template %@ -CreateLogFiles NO", 
				[[NSUserDefaults standardUserDefaults] stringForKey: @"AdunCorePath"],
				templateName];
		system([templateName cString]);				
	}
	else
	{
		shellBundle = AdLoadController(@"AdunShell", &error);
		if(error != nil)
		{
			//AdLoadController logs the error itself.
			return [error code];
		}
		
		STShell = [shellBundle classNamed: @"STShell"];
		
		[self createConversation];
		
		if(!languageName || [languageName isEqualToString:@""])
		{
			languageName = [[STLanguageManager defaultManager] defaultLanguage];
		}
		
		[conversation setLanguage:languageName];
		
		//Check if the -Script arguement was provided
		if((scriptName = [[NSUserDefaults standardUserDefaults] stringForKey: @"Script"]) != nil)
		{
			script = [NSString stringWithContentsOfFile: scriptName];
			if(script == nil)
			{
				NSWarnLog(@"Could not load script %@", scriptName);
			}
			else
			{
				//Pass all args after the script name to the script
				index = [arguments indexOfObject: scriptName] + 1;
				[[conversation context] setObject: 
					[arguments subarrayWithRange: NSMakeRange(index, [arguments count] - index)]
					forName: @"Args"];
				[conversation interpretScript: script];
			}
			
			//Register a default of NO for RunInterpreter.
			//This means the default behaviour on providing the Script argument
			//is not to enter the shell.
			[[NSUserDefaults standardUserDefaults] registerDefaults: 
				[NSDictionary dictionaryWithObject: 
						[NSNumber numberWithBool: NO] 
					forKey: @"RunInterpreter"]];
			[[NSUserDefaults standardUserDefaults] synchronize];		
		}
		
		//By default this is true.
		//However when running a script you might not want to enter the interpreter afterwards
		runInterpreter = [[NSUserDefaults standardUserDefaults] boolForKey: @"RunInterpreter"];
		if(runInterpreter)
		{
			shell = [[STShell alloc] initWithConversation:conversation];
			[shell setPrompt: @"AdunShell > "];
			[shell run];
		}
	
		NSDebugLog(@"Exiting Adun shell");
	}

	return 0;
}

- (void)printHelp
{
	NSProcessInfo *info = [NSProcessInfo processInfo];
	
	printf("%s - AdunShell shell\n"
	       "Usage: %s [options]\n\n"
	       "Options are:\n"
	       "    -help               this text\n"
	       "    -language lang      use language lang\n"
	       "    -environment env    use scripting environment with name env\n"
	       "    -host host          find environment on host\n"
	       "    -type desc          use environment description with name 'desc'\n",
	       [[info processName] cString],[[info processName] cString]
	       );
}

@end


int main(int argc, const char **argv)
{	
	int exitCode;
	NSString* adunCorePath;
	NSDictionary *dict;
	NSAutoreleasePool *pool;
	STShellTool   *tool;
	
	pool = [NSAutoreleasePool new];
	
#ifndef GNUSTEP
	adunCorePath = @"/usr/local/bin";
#else
	adunCorePath = [NSHomeDirectory() stringByAppendingPathComponent: @"GNUstep/Tools"];
#endif	
	
	dict = [NSDictionary dictionaryWithObjects: 
			[NSArray arrayWithObjects: 
				adunCorePath,
				[NSNumber numberWithBool: YES],
				nil]
			forKeys: 
			[NSArray arrayWithObjects:
				@"AdunCorePath",
				@"RunInterpreter",
				nil]];
				
	[[NSUserDefaults standardUserDefaults]
	 registerDefaults: dict];
	
	
	tool = [[STShellTool alloc] init];
	exitCode = [tool runShell];
	
	RELEASE(pool);
	
	return exitCode;
}
