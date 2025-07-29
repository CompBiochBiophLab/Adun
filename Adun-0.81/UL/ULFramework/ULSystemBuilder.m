/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 18:32:14 +0200 by michael johnston

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

#include "ULSystemBuilder.h"

@implementation ULSystemBuilder

+ (void)initialize
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	id debugLevels;

#ifdef GNUSTEP	
	[defaults setObject: [NSHomeDirectory() stringByAppendingPathComponent: @"adun/buildOutput"]
		     forKey: @"BuildOutput"];
#else	
	[defaults setObject: [NSHomeDirectory() stringByAppendingPathComponent: @".adun/buildOutput"]
		     forKey: @"BuildOutput"];
#endif		     	
	[defaults setObject: @"Charmm27" forKey: @"DefaultForceField"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) _buildConfiguration: (NSDictionary*) options
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	if([buildPosition isEqual: @"Configuration"])
	{
		configuration = [configurationBuilder buildConfiguration: options
					error: buildError
					userInfo: buildInfo];
		if(configuration == nil)
			[NSException raise: NSInternalInconsistencyException
				format: @"Cannot build configuration - No build molecule has been set"];			
		[configuration retain];
		[buildPosition release];
		buildPosition = [@"TopologyFrame" retain];
	}
	else
	{
		NSWarnLog(@"There is currently a build on the build pathway at position %@.", buildPosition);
		NSWarnLog(@" You must finish or cancel this build before you can call this method");
	}
}

- (void) _buildTopologyFrame: (NSDictionary*) options
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	if([buildPosition isEqual: @"TopologyFrame"])
	{
		topologyFrame = [topologyFrameBuilder buildTopologyForSystem:
					[configuration valueForKey: @"Sequences"]
				withOptions: options
				error: buildError
				userInfo: buildInfo];
		[topologyFrame retain];
		NSDebugLLog(@"ULSystemBuilder", @"Topology Frame %@", topologyFrame);
		[buildPosition release];
		buildPosition = [@"Merge" retain]; 
	}
	else
	{
		NSWarnLog(@"There is currently a build on the build pathway at position %@.", buildPosition);
		NSWarnLog(@" You must finish or cancel this build before you can call this method");
	}
}

- (void) _buildMerge: (NSDictionary*) options
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	id mergedConf;

	if([buildPosition isEqual: @"Merge"])
	{
		mergedConf = [merger mergeTopologyFrame: topologyFrame 
				withConfiguration: configuration
				error: buildError
				userInfo: buildInfo];
		[configuration release];
		configuration = [mergedConf retain];
		[buildPosition release];
		buildPosition = [@"Interactions" retain]; 
		NSDebugLLog(@"ULSystemBuilder", @"Merged configuration is %@", mergedConf);
	}
	else
	{
		NSWarnLog(@"There is currently a build on the build pathway at position %@.", buildPosition);
		NSWarnLog(@" You must finish or cancel this build before you can call this method");
	}
}

- (void) _buildInteractions: (NSDictionary*) options
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	if([buildPosition isEqual: @"Interactions"])
	{
		system = [interactionsBuilder buildInteractionsForConfiguration: configuration
			error: buildError
			userInfo: buildInfo];
		[system retain];
		//FIXME: If we just use forceField here it doesnt get encoded
		//for an unknown reason. Therefore we have to create a new
		//string.
		[system setValue: [NSString stringWithString: forceField] 
			forMetadataKey: @"ForceField"
			inDomain: AdSystemMetadataDomain];
		[buildPosition release];
		buildPosition = [@"Complete" retain]; 
	}
	else
	{
		NSWarnLog(@"There is currently a build on the build pathway at position %@.", buildPosition);
		NSWarnLog(@" You must finish or cancel this build before you can call this method");
	}
}

/**************

Public Methods

***************/

- (id) initWithFileType: (NSString*) stringOne forceField: (NSString*) stringTwo 
{
	if((self = [super init]))
	{
		internalError = nil;
		internalString = nil;
		configurationBuilder = nil;
		topologyFrameBuilder = nil;
		merger = nil;
		mergerDelegate = nil;
		system = nil;
		availableForceFields = nil;
		knownFileTypes = [NSArray arrayWithObjects: 
					@"pdb", nil];
		[knownFileTypes retain];			
		[self availableForceFields];
		mergerDelegate = [ULSimpleMergerDelegate new];

		if(stringOne != nil)
			[self setFileType: stringOne];
		else
			[self setFileType: @"pdb"];

		if(stringTwo != nil)
			[self setForceField: stringTwo];
		else
		{
			//Read default 
			stringTwo = [[NSUserDefaults standardUserDefaults] 
					objectForKey: @"DefaultForceField"];
			if(stringTwo == nil)
				stringTwo = @"Enzymix";

			[self setForceField: stringTwo];	
		}

		buildPosition = [@"Configuration" retain];
	}	

	return self;
}

- (void) dealloc
{
	[internalError release];
	[internalString release];
	[buildPosition release];
	[configurationBuilder release];
	[topologyFrameBuilder release];
	[merger release];
	[interactionsBuilder release];
	[mergerDelegate release];
	[system release];
	[fileType release];
	[forceField release];
	[availableForceFields release];
	[super dealloc];
}

- (NSArray*) availableForceFields
{
	NSString* path;

	if(availableForceFields == nil)
	{
		path = [[NSBundle bundleForClass: [self class]]
			resourcePath];
		path = [path stringByAppendingPathComponent: 
			@"ForceFields/ForceFields.plist"];
		availableForceFields = [NSArray
					arrayWithContentsOfFile: path];
		[availableForceFields retain];			
	}

	return [[availableForceFields retain] autorelease];
}


- (void) setBuildMolecule: (NSString*) path
{
	[configurationBuilder setCurrentMolecule: path];
}

- (NSString*) buildMolecule
{
	return [configurationBuilder currentMoleculePath];
}

- (NSMutableDictionary*) buildOptions
{
	return [configurationBuilder buildOptions];
}

- (NSError*) buildError
{
	return [[internalError retain] autorelease];
}

- (NSString*) userInfo
{
	return [[internalString retain] autorelease];

}

-(void) buildPart: (NSString*) partName 
	options: (NSDictionary*) optionsDict
	error: (NSError**) buildError
	userInfo: (NSString**) buildInfo
{
	NSException* exception = nil;

	[internalError release];
	[internalString release];
	internalError = nil;
	internalString = nil;

	NSDebugLLog(@"ULSystemBuilder", @"Building part %@", partName);	
	
	//We have to catch any exceptions while building a part so
	//we can make sure buildError and buildInfo are set and their
	//internal equivalents are retained. 
	//This means that even when an exception is raised any errors set
	//or info added to the buildString will be available.
	
	NS_DURING
	{
		if([partName isEqual: @"Configuration"])
		{
			if(system != nil)
			{
				NSWarnLog(@"There is a unclaimed completed build on the pathway!");
				[NSException raise: NSInternalInconsistencyException
					    format: @"There is a unclaimed completed build on the pathway!"];
			}
			
			[self _buildConfiguration: optionsDict
					    error: &internalError
					 userInfo: &internalString];
		}
		else if([partName isEqual: @"Topology"])
		{
			[self _buildTopologyFrame: optionsDict
					    error: &internalError 
					 userInfo: &internalString];
		}
		else if([partName isEqual: @"Merge"])
		{
			[self _buildMerge: optionsDict
				    error: &internalError 
				 userInfo: &internalString];
		}
		else if([partName isEqual: @"Interactions"])
		{
			[self _buildInteractions: optionsDict
					   error: &internalError 
					userInfo: &internalString];
		}
	}
	NS_HANDLER
	{	
		exception = localException;
	}
	NS_ENDHANDLER
	
	//Retain internal error vars & set pointers
	//We do this even if an exception was raised,
	//to prevent problems with subsequent calls to this method.
	if(internalError != nil)
		[internalError retain];

	if(internalString != nil)
		[internalString retain];

	if(buildError != NULL)
		*buildError = internalError;

	if(buildInfo != NULL)
		*buildInfo = internalString;
		
	if(exception != nil)
		[exception raise];
}

- (AdDataSource*) system
{
	id completedBuild;

	if([buildPosition isEqual: @"Complete"])
	{
		completedBuild = [system autorelease];
		[topologyFrame release];
		[configuration release];
		[buildPosition release];
		buildPosition = [@"Configuration" retain];
		system = nil;
		topologyFrame = nil;
		configuration = nil;
		return completedBuild;
	}
	else
	{
		NSWarnLog(@"There is currently a build on the build pathway at position %@.", buildPosition);
		NSWarnLog(@" You must finish or cancel this build before you can call this method");
		return nil;
	}
}

- (void) cancelBuild
{
	//release everything

	if(![buildPosition isEqual: @"Configuration"])	
	{
		[system release];
		[topologyFrame release];
		[configuration release];
		[buildPosition release];
		system = nil;
		topologyFrame = nil;
		configuration = nil;
		buildPosition = [@"Configuration" retain];
	}
	else
	{
		NSWarnLog(@"There is no build on the pathway");
	}
}

- (BOOL) removeMolecule
{
	if([buildPosition isEqual: @"Configuration"])	
	{
		[configurationBuilder removeCurrentMolecule];
		return YES;
	}
	
	return NO;
}

- (NSString*) fileType
{
	return [[fileType retain] autorelease];
}

- (NSString*) forceField
{
	return [[forceField retain] autorelease];
}

- (void) setFileType: (NSString*) aString
{
	id holder;

	if(![knownFileTypes containsObject: aString])
	{
		NSWarnLog(@"Unknown file type %@", aString);
		return;
	}	

	holder = configurationBuilder;	
	configurationBuilder = [[ULConfigurationBuilder builderForFileType: aString]
					retain];
	[holder release];	
	[fileType release];
	fileType = [aString retain];
}

- (void) setForceField: (NSString*) aString
{
	id holder;

	if([aString isEqual: forceField])
		return;

	if(![availableForceFields containsObject: aString])
	{
		NSWarnLog(@"Invalid choice for force field %@\n", aString);
		return;
	}

	[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULSystemBuilderWillBeginInitialisationNotification" 
		 object: @"Creating Residue Library Document Tree"];
	
	holder = topologyFrameBuilder;
	topologyFrameBuilder = [[ULTopologyFrameBuilder alloc] 
				 initForForceField: aString]; 
	[holder release];

	[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULSystemBuilderCompletedInitialisationStepNotification" 
		 object: nil];

	[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULSystemBuilderWillBeginInitialisationStepNotification" 
		 object: @"Creating Parameter Library Document Tree"];

	[merger release];
	merger = [ULMerger new];
	[merger setDelegate: mergerDelegate];
	
	holder = interactionsBuilder;
	interactionsBuilder = [[ULInteractionsBuilder alloc] 
				initForForceField: aString];
	[holder release];			
				
	[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULSystemBuilderCompletedInitialisationStepNotification" 
		 object: @"Complete"];

	[forceField release];
	forceField = [aString retain];
}

- (void) writeStructureToFile: (NSString*) path
{
	[configurationBuilder writeStructureToFile: path];
}

- (NSArray*) knownFileTypes
{
	return [[knownFileTypes retain] autorelease];
}

- (NSString*) buildPosition
{
	return buildPosition;
}

- (NSArray*) availablePreprocessPlugins
{
	return [configurationBuilder availablePlugins];
}

- (NSMutableDictionary*) preprocessOptions
{
	return [configurationBuilder optionsForPlugin];
}

- (void) loadPreprocessPlugin: (NSString*) aString
{
	[configurationBuilder loadPlugin: aString];
}

- (void) applyPreprocessPlugin: (NSDictionary*) options
{
	[configurationBuilder applyPlugin: options];
}

- (NSString*) preprocessOutputString;
{
	return [configurationBuilder pluginOutputString];
}

@end
