/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-12-09 14:47:28 +0100 by michael johnston

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

#include "ULFramework/ULAnalysisManager.h"

@implementation ULAnalysisManager

//Note requires the .bundle extension to be present on Mac.
- (BOOL) _plugin: (NSString*) pluginName inDirectory: (NSString*) dir
{
	NSArray* directoryContents;
	
	directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath: dir];
	return [directoryContents containsObject: pluginName];
}

- (Class) loadBundle: (NSString*) pluginName fromDir: (NSString*) dir 
{
	NSBundle *pluginBundle;
	Class pluginClass;
	NSString* path;

#ifndef GNUSTEP
	pluginName = [pluginName stringByAppendingPathExtension: @"bundle"];
#endif

	NSDebugLLog(@"ULAnalysisManager", @"Plugin dir is %@. Plugin Name is %@", 
		dir, 
		pluginName);

	//add check to see if bundle actually exists
	path = [dir stringByAppendingPathComponent: 
		pluginName];
	pluginBundle = [NSBundle bundleWithPath: path];
	if(pluginBundle == nil)
		[NSException raise: NSInvalidArgumentException format: @"Specified plugin does not exist"];	

	NSDebugLLog(@"ULAnalysisManager", @"Plugin Bundle is %@", pluginBundle);
	NSDebugLLog(@"ULAnalysisManager", 
		@"Dynamicaly Loading Plugin (if neccessary) from Directory: %@.\n\n",
		[pluginBundle bundlePath]);

	if((pluginClass = [pluginBundle principalClass]))
		NSDebugLLog(@"ULAnalysisManager", @"Found plugin (plugin=%@).\n",
			 [pluginClass description]);
	else
		[NSException raise: NSInternalInconsistencyException 
			format: @"Specified plugin has no principal class"];

	NSDebugLLog(@"ULAnalysisManager", @"Loaded plugin\n");

	return pluginClass;
}
 
//Adds the plugins in dir to the available plugins list
//Only adds them if they are not present in a previous dir
- (NSArray*) _addPluginsInDirectory: (NSString*) dir
{
	BOOL isDir;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *pluginDirEnum, *pluginEnum;
	NSString *contentObject, *path, *pluginName, *pluginOutputDir, *resourceFilename;
	NSDictionary *infoDict;
	NSArray* inputInfo;
	NSBundle* bundle;

	//Scan the analysis plugins directory and get all the bundle names
	pluginDirEnum = [[fileManager directoryContentsAtPath: dir]
			 objectEnumerator];

	while((contentObject = [pluginDirEnum nextObject]))
	{
		//Only check the object if its not already present
		if([availablePlugins containsObject: [contentObject stringByDeletingPathExtension]])
		{
			continue;
		}
		
		path = [dir stringByAppendingPathComponent: contentObject];
		[fileManager fileExistsAtPath: path isDirectory: &isDir];
		if(isDir)
		{
			//retrieve the info dict
			bundle = [NSBundle bundleWithPath: path];
#ifdef GNUSTEP			
			infoDict = [bundle infoDictionary];
#else
			//With Cocoa we need to retrieve the gnustep info-dict to access the plugin.
			//Later will have the option of putting the information in either one
			//The GNUstep info dict has the same name as the Cocoa but without the -
			//e.g. SystemAnalysis-Info.plist -> SystemAnalysisInfo.plist
			resourceFilename = [NSString stringWithFormat: @"Contents/Resources/%@Info.plist",
						NSStringFromClass([bundle principalClass])];
			infoDict = [NSDictionary dictionaryWithContentsOfFile:
					[path stringByAppendingPathComponent: resourceFilename]];
#endif
			inputInfo = [infoDict objectForKey: @"ULAnalysisPluginInputInformation"];
			if(infoDict == nil)
			{
				NSWarnLog(@"Plugin %@ contains no Info.plist", contentObject);
			}	
			else if(inputInfo == nil)
			{
				NSWarnLog(@"%@ plugin Info.plist contains no input object information"
					  ,contentObject);
			}
			else
			{
#ifndef GNUSTEP
				//If we're running on Mac the plugins will have a .bundle
				//extension which we have to remove. 
				contentObject = [contentObject stringByDeletingPathExtension];
#endif				
				
				[availablePlugins addObject: contentObject];
				[pluginInfoDict setObject: inputInfo forKey: contentObject];
			}		
		}	
	}		
	
}

- (void) _findAvailablePlugins
{
	NSEnumerator *pluginDirEnum, *pluginEnum;
	NSString *pluginName, *pluginOutputDir, *directory;
	NSMutableDictionary* defaults;

	availablePlugins = [NSMutableArray new];
	pluginInfoDict = [NSMutableDictionary new];
	pluginDirEnum = [pluginDirs objectEnumerator];
	while((directory = [pluginDirEnum nextObject]))
	{
		NSDebugLLog(@"ULAnalysisManager", @"Searching directory %@", directory);
		[self _addPluginsInDirectory: directory];
	}		

	//For each plugin set the default plugin output directory as the
	//location of their output directory default.
	pluginOutputDir = [[ULIOManager appIOManager] defaultPluginOutputDir];
	defaults = [NSMutableDictionary dictionary];
	pluginEnum = [availablePlugins objectEnumerator];
	while((pluginName = [pluginEnum nextObject]))
		[defaults setObject: pluginOutputDir
			forKey: [NSString stringWithFormat: @"%@OutputDir", pluginName]];
			
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];		

	NSDebugLLog(@"ULAnalysisManager", @"Available plugins %@", availablePlugins);
	NSDebugLLog(@"ULAnalysisManager", @"Plugin information %@", pluginInfoDict);
}

+ (void) initialize
{
	[[NSUserDefaults standardUserDefaults] 
		registerDefaults: [NSDictionary dictionaryWithObject: [NSArray array] 
					forKey: @"PluginDirectories"]];
}

+ (id) managerWithDefaultLocations
{	
	return [[ULAnalysisManager new] autorelease];
}

- (id) init
{
	NSString* mainDir, *builtinDir;
	NSMutableArray* directories;

	mainDir = [[[ULIOManager appIOManager] applicationDir]
				stringByAppendingPathComponent: @"Plugins/Analysis"];
	builtinDir =  [[[NSBundle mainBundle] builtInPlugInsPath] 
			stringByAppendingPathComponent: @"Analysis"];			
	directories = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"PluginDirectories"] mutableCopy];
	directories = [directories autorelease];
	[directories insertObject: builtinDir atIndex: 0];
	[directories insertObject: mainDir atIndex: 1];
	
	return [self initWithLocations: directories];
}

- (id) initWithLocation: (NSString*) aString
{
	return [self initWithLocations: [NSArray arrayWithObject: aString]];
}

- (id) initWithLocations: (NSArray*) anArray
{
	if((self = [super init]))
	{
		currentPluginName = nil;
		results = nil;
		pluginDirs = anArray;
		[pluginDirs retain];
		inputObjects = [NSMutableArray new];
		objectsCountDict = [NSMutableDictionary new];
		outputObjectsReferences = [NSMutableArray new];
		//Locate what plugins are available along with their input requirements.
		[self _findAvailablePlugins];
		//Set the default error handler for gsl.
		gsl_set_error_handler(&AdGSLErrorHandler);
	}

	return self;
}

- (void) dealloc
{
	[results release];
	[outputObjectsReferences release];
	[availablePlugins release];
	[pluginInfoDict release];
	[pluginDirs release];
	[inputObjects release];
	[objectsCountDict release];
	[currentPluginName release];
	[currentPlugin release];
	[super dealloc];
}

/**
All input objects used are retained until the next called to this method
unless clearOutputs are called
*/
- (id) applyPlugin: (NSString*) name withOptions: (NSMutableDictionary*) options error: (NSError**) error
{
	NSEnumerator *inputObjectsEnum, *dataSetsEnum;
	id dataSet, inputObject;
	NSArray* dataSets;
	NSError* internalError;
	
	[self setCurrentPlugin: name];
	[results release];
	[outputObjectsReferences removeAllObjects];
	
	//Ask the plugin if the data in the inputs is valid
	if(![currentPlugin checkInputs: inputObjects error: &internalError])
	{
		if(error != NULL && internalError != nil)
			*error = internalError;
		
		return [NSDictionary dictionary];
	}

	NS_DURING
	{
		results = [currentPlugin processInputs: inputObjects
				userOptions: options];
		[results retain];		
		dataSets = [results objectForKey: @"ULAnalysisPluginDataSets"];

		//Add the plugin options to each returned datasets metadata	
		dataSetsEnum = [dataSets objectEnumerator];
		while((dataSet = [dataSetsEnum nextObject]))
			[dataSet setValue: options 
				forMetadataKey: @"dataGeneratorOptions"
				inDomain: AdSystemMetadataDomain];
				 
		//set input references 
		//note: output references cant be added until the object is saved 
		//to a database.
		inputObjectsEnum = [inputObjects objectEnumerator];
		while((inputObject = [inputObjectsEnum nextObject]))
		{
			//FIXME: Unable to add input references for moltalk structures.
			if([inputObject isKindOfClass: [AdModelObject class]])
			{
				//loop over every data set returned
				dataSetsEnum = [dataSets objectEnumerator];
				while((dataSet = [dataSetsEnum nextObject]))
				{
					[dataSet addInputReferenceToObject: inputObject];
					NSDebugMLLog(@"ULAnalysisManager", @"Data set input references %@", 
						[dataSet inputReferences]);
				}	
			}
		}	

		//Keep track of the objects that generated these data sets.
		[outputObjectsReferences  addObjectsFromArray: inputObjects];
	}
	NS_HANDLER
	{
		results  = nil;
		NSWarnLog(@"Results analysis failed due to an exception");
		NSWarnLog(@"%@ %@ %@", [localException name], 
			[localException reason], 
			[localException userInfo]);
		[localException raise];
	}
	NS_ENDHANDLER

	NSDebugLLog(@"ULAnalysisManager", @"Completed analysis. Returning %@", results);

	return results;
}

- (void) clearOutput
{
	[results release];
	results = nil;
	[outputObjectsReferences removeAllObjects];
}

- (void) saveOutputDataSet: (AdDataSet*) dataSet 
{
	NSError* saveError = nil;
	NSArray* dataSets;
	NSEnumerator* inputsEnum;
	id input;

	//check this object is one of the current output objects

	dataSets = [results objectForKey: @"ULAnalysisPluginDataSets"];
	if(![dataSets containsObject: dataSet])
		[NSException raise: NSInvalidArgumentException
			format: @"Dataset is not among the current outputs"];

	[[ULDatabaseInterface databaseInterface]
		addObjectToFileSystemDatabase: dataSet];

	//Go through all the objects that created this dataSet and 
	//add an output reference to each
	inputsEnum = [outputObjectsReferences objectEnumerator];
	while((input = [inputsEnum nextObject]))
	{
		if([input isKindOfClass: [AdModelObject class]])
		{
			[input addOutputReferenceToObject: dataSet];
			[[ULDatabaseInterface databaseInterface]
				updateOutputReferencesForObject: input
				error: &saveError];
			//FIXME: Handle errors here
			if(saveError != nil)
				AdLogError(saveError);
		}		
	}
}

- (id) optionsForPlugin: (NSString*) name
{
	[self setCurrentPlugin: name];	
	return [currentPlugin pluginOptions: inputObjects];
}

- (void) addInputObject: (id) object
{
	NSNumber* objectsCount;
	NSString* type;

	[inputObjects addObject: object];
	type = NSStringFromClass([object class]);
	if((objectsCount = [objectsCountDict objectForKey: type]) != nil)
	{	
		objectsCount = [NSNumber numberWithInt: 
				[objectsCount intValue] +1];
		[objectsCountDict setValue: objectsCount forKey: type];
	}
	else
		[objectsCountDict setValue: [NSNumber numberWithInt: 1]	
			forKey: type];
}

- (void) removeInputObject: (id) object
{
	NSNumber* objectsCount;
	NSString* type;

	if(![inputObjects containsObject: object])
		return

	[inputObjects removeObject: object];
	type = NSStringFromClass([object class]);
	objectsCount = [objectsCountDict objectForKey: type];
	if([objectsCount intValue] == 1)
		[objectsCountDict removeObjectForKey: type];
	else
	{	
		objectsCount = [NSNumber numberWithInt: 
				[objectsCount intValue] -1];
		[objectsCountDict setValue: objectsCount forKey: type];
	}
}

- (void) removeAllInputObjects
{
	[inputObjects removeAllObjects];
	[objectsCountDict removeAllObjects];
}

- (NSArray*) inputObjects
{
	return [[inputObjects copy] autorelease];
}

- (BOOL) containsInputObjects
{
	if([inputObjects count] != 0)
		return YES;
	else
		return NO;
}

- (int) countOfInputObjectsOfClass: (NSString*) className
{
	NSNumber* count;

	count = [objectsCountDict objectForKey: className];
	if(count != nil)
		return [count intValue];
	else
		return 0;
}

- (BOOL) _pluginCanProcessCurrentInputs: (NSString*) pluginName
{
	NSNumber* number, *minimumNumber, *maximumNumber;
	NSArray* pluginInputs;
	NSMutableArray *inputTypes;
	NSEnumerator *inputsEnum;
	id input, inputType;

	pluginInputs = [pluginInfoDict objectForKey: pluginName];

	//Create an array containing the input types which are present
	//We will check this against the types the plugin can handle.
	//The plugin must be able to accept all these types

	inputTypes = [NSMutableArray array];
	inputsEnum = [objectsCountDict keyEnumerator];
	while((input = [inputsEnum nextObject]))
		if([[objectsCountDict objectForKey: input] intValue] >0)
			[inputTypes addObject: input];

	NSDebugLLog(@"ULAnalysisManager", @"Available input types %@", inputTypes);		
	
	//Check that all the plugins requirements are present.
	//When we find that a required  plugin input is present 
	//we remove it from the inputTypes array.
	//At the end if there are any entries left in inputTypes
	//it means the plugin cant process them and we have to return NO.
	
	inputsEnum = [pluginInputs objectEnumerator];
	while((input = [inputsEnum nextObject]))
	{
		//check if the input type exists
		inputType = [input objectForKey: @"ULInputObject"];
		number = [objectsCountDict objectForKey: inputType];
		NSDebugLLog(@"ULAnalysisManager", @"Checking for input objects of type %@", inputType);
		minimumNumber = [input objectForKey: @"ULInputObjectMinimumNumber"];
		maximumNumber = [input objectForKey: @"ULInputObjectMaximumNumber"];

		if(minimumNumber == nil)
		{
			NSWarnLog(@"ULInputObjectMinimumNumber key missing from plugin input information");
			return NO;
		}

		if(maximumNumber == nil)
		{
			NSWarnLog(@"ULInputObjectMaximumNumber key missing from plugin input information");
			return NO;
		}

		
		NSDebugLLog(@"ULAnalysisManager", @"Mininum required number %@ maximum number %@", 
			minimumNumber, 
			maximumNumber);
		
		//if there are no inputs of this type check if its optional
		//if its required return NO
		if(number == nil)
		{
			NSDebugLLog(@"ULAnalysisManager", 
				@"No inputs of this type! Checking if optional");
			if([minimumNumber intValue] != 0)
			{
				NSDebugLLog(@"ULAnalysisManager", 
					@"Required type - plugin cant process current inputs");
				return NO;
			}
				
			NSDebugLLog(@"ULAnalysisManager", 
				@"Input optional - continuing");	
		}		
		else
		{
			//check if its greater than or equal to the minimum number

			if(!([number intValue] <= [maximumNumber intValue] && 
				[number intValue] >= [minimumNumber intValue]))
			{
				NSDebugLLog(@"ULAnalysisManager", 
					@"The number of inputs of type %@ (%@) is incorrect", 
					inputType, 
					number);
				return NO;
			}
			else
					//remove this object from the inputTypes array
				[inputTypes removeObject: inputType];
		}
	}	

	if([inputTypes count] != 0)
		return NO;
		
	return YES;
}

- (NSArray*) pluginsForCurrentInputs
{
	NSEnumerator *pluginEnum;
	NSMutableArray *array = [NSMutableArray array];
	NSString *plugin;

	if([inputObjects count] != 0)
	{
		//_pluginCanProcessCurrentInputs checks if the types
		//of objects in inputs are compatible with the information 
		//provided by the plugins Info.plist.
		pluginEnum = [availablePlugins objectEnumerator];
		while((plugin = [pluginEnum nextObject]))
			if([self _pluginCanProcessCurrentInputs: plugin])
				[array addObject: plugin];
	}			

	return array;
}

- (NSArray*) outputDataSets 
{ 
	return [results objectForKey: @"ULAnalysisPluginDataSets"];
}

- (NSString*) outputString 
{ 
	return [results objectForKey: @"ULAnalysisPluginString"];
}

- (NSArray*) outputFiles
{
	return [results objectForKey: @"ULAnalysisPluginFiles"];
}

- (NSArray*) availablePlugins
{
	return [[availablePlugins copy] autorelease];
}

- (NSString*) locationOfPlugin: (NSString*) pluginName
{
	NSEnumerator* pluginDirEnum;
	NSString* directory, *result = nil;
	
#ifndef GNUSTEP
	pluginName = [pluginName stringByAppendingPathExtension: @"bundle"];
#endif	
	pluginDirEnum = [pluginDirs objectEnumerator];
	while(directory = [pluginDirEnum nextObject])
	{
		if([self _plugin: pluginName inDirectory: directory])
		{
			NSDebugLLog(@"ULAnalysisManager", @"Found %@ in %@", pluginName, directory);
			result = directory;
			break;
		}
	}
	
	return result;
}

- (id) currentPlugin
{
	return [[currentPlugin retain] autorelease];
}

- (void) setCurrentPlugin: (NSString*) name
{
	Class pluginClass;
	NSString* directory;
	id holder;
	
	//check if this is the current plugin
	
	if(![name isEqual: currentPluginName])
	{
		//get the principal class of the plugin		
		directory = [self locationOfPlugin: name];
		pluginClass = [self loadBundle: name fromDir: directory];	
		if(pluginClass == nil)
			[NSException raise: NSInvalidArgumentException
				    format: @"Cannot load plugin %@ - Doesnt exist",
			 name];
		
		holder = [pluginClass new];
		[currentPlugin release];
		currentPlugin = holder;
		[currentPluginName release];
	
		currentPluginName = [name retain];
		
		if(![currentPlugin conformsToProtocol:@protocol(ULAnalysisPlugin)])
		{
			[currentPlugin release];
			[currentPluginName release];
			currentPluginName = nil;
			currentPlugin = nil;
			NSWarnLog(@"Plugin doesnt not conform to ULAnalysisPlugin protocol");
			[NSException raise: NSInternalInconsistencyException 
				    format: @"Specified plugins (%@) principal class does not conform to ULAnalysisPlugin protocol", 
			 [pluginClass description]];
		}
	}
}

- (Class) loadPlugin: (NSString*) name
{
	NSString* directory;
			
	directory = [self locationOfPlugin: name];
	return [self loadBundle: name fromDir: directory];		
}

@end
