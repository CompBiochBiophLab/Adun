/*
   Project: ResultsConverter

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-15 12:12:31 +0100 by michael johnston

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

#include "ResultsConverter.h"
#include <AdunKernel/AdunFileSystemSimulationStorage.h>

//There is probably a better a way of doing this but were
//stuck with this one for the moment.

NSString* options = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
<!DOCTYPE plist PUBLIC \"-//GNUstep//DTD plist 0.9//EN\" \"http://www.gnustep.org/plist-0_9.xml\"> \
<plist version=\"0.9\"> \
<dict> \
<key>Info</key> \
<dict> \
<key>RequiredArgs</key> \
<array> \
<string>Trajectory</string> \
</array> \
<key>OptionalArgs</key> \
<array> \
<string>Subsystems</string> \
</array> \
<key>OptionDefaults</key> \
<array> \
<string>All</string> \
</array> \
</dict> \
<key>Energy</key> \
<dict> \
<key>RequiredArgs</key> \
<array> \
<string>Trajectory</string> \
<string>Output</string> \
</array> \
<key>OptionalArgs</key> \
<array> \
<string>Subsystems</string> \
<string>Start</string> \
<string>Length</string> \
<string>Stepsize</string> \
<string>Terms</string> \
<string>Unit</string> \
</array> \
<key>OptionDefaults</key> \
<array> \
<string>All</string> \
<string>0</string> \
<string>0</string> \
<string>1</string> \
<string>All</string> \
<string>KCalMol</string> \
</array> \
</dict> \
<key>Configuration</key> \
<dict> \
<key>RequiredArgs</key> \
<array> \
<string>Trajectory</string> \
</array> \
<key>OptionalArgs</key> \
<array> \
<string>Subsystems</string> \
<string>Start</string> \
<string>Length</string> \
<string>Stepsize</string> \
</array> \
<key>OptionDefaults</key> \
<array> \
<string>All</string> \
<string>1</string> \
<string>0</string> \
<string>1</string> \
</array> \
</dict> \
</dict> \
</plist>";


@implementation ResultsConverter

- (void) _printInfo: (AdSimulationData*) resultsObject
{
	GSPrintf(stdout, @"Data description:\n\n");
	GSPrintf(stdout, @"%@\n", [resultsObject description]);
}

- (void) _printHelp
{
	GSPrintf(stderr, @"\nUsage: ResultsConverter [mode=modevalue] [options]\n");
	GSPrintf(stderr, @"All Options must be specified as option=value pairs\n\n");
	GSPrintf(stderr, @"Options common to all modes.\n");
	GSPrintf(stderr, @"  Required:\n");
	GSPrintf(stderr, @"\tTrajectory            A valid adun simulation output directory.\n"); 
	GSPrintf(stderr, @"  Optional:\n");
	GSPrintf(stderr, @"\tSubsystems            A comma seperated list of subsystems. Defaults to all\n\n");

	GSPrintf(stderr, @"Info specific options (Mode=Info):\n");
	GSPrintf(stderr, @"  Required:\n");
	GSPrintf(stderr, @"\tNone\n");	
	GSPrintf(stderr, @"  Optional:\n");
	GSPrintf(stderr, @"\tNone\n\n");	
	
	GSPrintf(stderr, @"Energy options (Mode=Energy):\n");
	GSPrintf(stderr, @"  Required:\n");
	GSPrintf(stderr, @"\tOutput                Output file name\n"); 
	GSPrintf(stderr, @"  Optional:\n");
	GSPrintf(stderr, @"\tTerms                 A comma seperated list of energy terms. Defaults to all\n");
	GSPrintf(stderr, @"\tUnit                  KCalMol|JouleMol|Simulation. Defaults to KCalMol\n");
	GSPrintf(stderr, @"\tStart                 The initial frame\n");
	GSPrintf(stderr, @"\tLength                The number of frames\n");
	GSPrintf(stderr, @"\tStepsize              The stepsize. Defaults to 1\n\n");

	GSPrintf(stderr, @"Configuration options (Mode=Configuration):\n");
	GSPrintf(stderr, @"  Required:\n");
	GSPrintf(stderr, @"\tNone\n");
	GSPrintf(stderr, @"  Optional:\n");
	GSPrintf(stderr, @"\tStart                 The initial frame\n");
	GSPrintf(stderr, @"\tLength                The number of frames\n");
	GSPrintf(stderr, @"\tStepsize              The stepsize. Defaults to 1\n\n");
}	

- (void) _processArguements
{
	int i, j;
	NSMutableArray* arguments;
	NSDictionary* defaults;
	NSEnumerator *enumerator;
	NSString* mode;
	id arg, array, invalidArgs, optionalArgs, commandLineArgs;	

	[NSUserDefaults standardUserDefaults];
	processedArgs = [NSMutableDictionary dictionary];
	arguments = [[[NSProcessInfo processInfo] arguments] mutableCopy];
	[arguments autorelease];
	invalidArgs = [NSMutableArray array];

	//remove the first object - program name
	
	[arguments removeObjectAtIndex: 0];

	//check if the arguments all have valid format argname=value(s)

	NSDebugLLog(@"Arguments", @"Checking arguments format");

	enumerator = [arguments objectEnumerator];		
	while(arg = [enumerator nextObject])
	{
		array = [arg componentsSeparatedByString: @"="];
		if([array count] == 2)
			[processedArgs setObject: [array objectAtIndex: 1]
				forKey: [array objectAtIndex: 0]];
		else
			[invalidArgs addObject: array];
	}

	if([invalidArgs count] != 0)
	{
		GSPrintf(stderr, 
		@"\nError - The format of some options is invalid. Options must be in Option=Value pairs:\n");

		for(i=0; i< [invalidArgs count]; i++)
			GSPrintf(stderr, @"%@\n", [invalidArgs objectAtIndex: i]);
		[self _printHelp];
		exit(1);
	}	

	commandLineArgs = [[processedArgs allKeys] mutableCopy];

	//check Mode is present and valid
	
	NSDebugLLog(@"Arguments", @"Checking for mode presence");

	if((mode = [processedArgs objectForKey: @"Mode"]) == nil)
	{
		GSPrintf(stderr, @"\nMode must be specified.\n");
		[self _printHelp];
		exit(1);
	}
	
	if((validOptions = [validOptions objectForKey: mode]) == nil)	
	{
		GSPrintf(stderr, @"\nInvalid value for mode (%@).\n", mode);
		[self _printHelp];
		exit(1);
	}

	[commandLineArgs removeObject: @"Mode"];

	//check required args are present
	NSDebugLLog(@"Arguments", @"Checking for required args");
	
	enumerator = [[validOptions objectForKey: @"RequiredArgs"] objectEnumerator];
	while(arg = [enumerator nextObject])
		if([processedArgs objectForKey: arg] == nil)
		{
			GSPrintf(stderr, @"\nRequired arguement - %@ - not present\n", arg);
			[self _printHelp];
			exit(1);
		}

	[commandLineArgs removeObjectsInArray: [validOptions objectForKey: @"RequiredArgs"]];
	
	//check each of the remaining options are in the optionalArgs list
	
	NSDebugLLog(@"Arguments", @"Checking for optional args");
	
	[invalidArgs removeAllObjects];
	enumerator = [commandLineArgs objectEnumerator];
	optionalArgs = [validOptions valueForKey:@"OptionalArgs"];
	while(arg = [enumerator nextObject])
		if(![optionalArgs containsObject: arg] && ![arg isEqual: @"--GNU-Debug"])
			[invalidArgs addObject: arg];

	if([invalidArgs count] != 0)
	{
		GSPrintf(stderr, @"Detected %d unknown argument(s)\n", [invalidArgs count]);
		for(i=0; i< [invalidArgs count]; i++)
			GSPrintf(stderr, @"%@\n", [invalidArgs objectAtIndex: i]);
		[self _printHelp];
		exit(1);
	}

	//check which options were not given - insert these and give them default values
	
	NSDebugLLog(@"Arguments", @"Applying default values for missing args");

	enumerator = [[validOptions valueForKey:@"OptionalArgs"] objectEnumerator];
	defaults = [NSDictionary dictionaryWithObjects: [validOptions objectForKey: @"OptionDefaults"]
			forKeys: [validOptions objectForKey:@"OptionalArgs"]];
	while(arg = [enumerator nextObject])
		if([processedArgs objectForKey: arg] == nil)
			[processedArgs setObject: [defaults valueForKey: arg]
				forKey: arg];
	
	NSDebugLLog(@"Arguments", @"Complete.");
}

- (void) _validateArgs
{	
	int i, j;
	NSMutableArray* arguments;
	NSEnumerator *enumerator, *dataMatrixEnum;
	NSError* error;
	AdDataSet* dataSet;
	AdDataMatrix* matrix;
	id arg , value;	
	id subsystems, array;

	enumerator = [processedArgs keyEnumerator];
	while(arg = [enumerator nextObject])
	{
		//catch "All" values
		value = [processedArgs valueForKey: arg];
		
		if([value isEqual: @"All"])
		{
			if([arg isEqual: @"Subsystems"])
			{
				value = [[[results systemCollection] allSystems]
						valueForKey: @"systemName"];
			}	
			else if([arg isEqual: @"Terms"])
			{
				dataSet = [results energies];
				dataMatrixEnum = [[dataSet dataMatrices] objectEnumerator];
				value = [NSMutableArray array];
				while(matrix = [dataMatrixEnum nextObject]) 
				{
					array = [matrix columnHeaders];
					[value removeObjectsInArray: array];
					[value addObjectsFromArray: array];
				}
			}
			else
				[NSException raise: NSInvalidArgumentException
					format: @"Option %@ cannot be set to All", arg];
		}
		else
			if(![self validateValue: &value forKey: arg error:  &error])
				[NSException raise: NSInvalidArgumentException
					format: @"Invalid format for arguement %@", arg];

		[processedArgs setObject: value forKey: arg];
	}
}

- (Class) _loadBundle: (NSString*) pluginName fromDir: (NSString*) pluginDir 
{
	NSBundle *pluginBundle;
	NSString *pluginPath;
	NSString *temp;
	Class pluginClass;

	NSDebugLLog(@"ResultsConverter", 
		@"Plugin dir is %@. Plugin Name is %@", 
		pluginDir, pluginName);

	//add check to see if bundle actually exists

	pluginBundle = [NSBundle bundleWithPath: 
				[pluginDir stringByAppendingPathComponent: 
				pluginName]];
	if(pluginBundle == nil)
		[NSException raise: NSInvalidArgumentException 
			format: @"Specified plugin does not exist"];	

	NSDebugLLog(@"ResultsConverter", @"Plugin Bundle is %@", pluginBundle);
	NSDebugLLog(@"ResultsConverter", 
		@"Dynamicaly Loading Plugin from Directory: %@.\n\n", 
		[pluginBundle bundlePath]);

	if(pluginClass = [pluginBundle principalClass])
	{
		NSDebugLLog(@"ResultsConverter", 
			@"Found plugin (plugin=%@).\n", 
			[pluginClass description]);
	}
	else
		[NSException raise: NSInternalInconsistencyException
			 format: @"Specified plugin has no principal class"];

	NSDebugLLog(@"ResultsConverter", @"Loaded plugin\n");

	return pluginClass;
}

- (void) _loadConverterBundle
{
	NSString* pluginDir;
	Class pluginClass;
	NSString* energyConverter, *conformationConverter;

#ifdef GNUSTEP
	pluginDir = [NSHomeDirectory() stringByAppendingPathComponent: @"adun/Plugins/Analysis"];
	energyConverter = @"EnergyConverter";
	conformationConverter = @"ConformationConverter";
#else	
	pluginDir = [NSHomeDirectory() stringByAppendingPathComponent: @".adun/Plugins/Analysis"];
	energyConverter = @"EnergyConverter.bundle";
	conformationConverter = @"ConformationConverter.bundle";
#endif	
	if([[processedArgs valueForKey:@"Mode"] isEqual:@"Energy"])
		pluginClass = [self _loadBundle: energyConverter fromDir: pluginDir];		
	else if([[processedArgs valueForKey:@"Mode"] isEqual:@"Configuration"])
		pluginClass = [self _loadBundle: conformationConverter fromDir: pluginDir];		
	else
		[NSException raise: @"NSInvalidArgumentException"
			format: @"Unknown mode %@", [processedArgs valueForKey:@"Mode"]];

	plugin = [pluginClass new];

	if(![plugin conformsToProtocol:@protocol(ULAnalysisPlugin)])
	{
		[NSException raise: NSInternalInconsistencyException 
			format: @"Specified plugins (%@) principal class does not conform to\
 ULAnalysisPlugin protocol", [pluginClass description]];
	}
}

- (void) _outputDataSets: (NSArray*) dataSets
{
	int i;
	NSString *outputDir;
	NSEnumerator* tableEnum, *dataSetEnum;
	NSString* format, *holder;
	id table, dataSet;

	outputDir = [[NSFileManager defaultManager] currentDirectoryPath]; 
	dataSetEnum = [dataSets objectEnumerator];
	if([dataSets count] > 0)
	{
		i = 0;
		while(dataSet = [dataSetEnum nextObject])
		{
			tableEnum = [[dataSet dataMatrices] objectEnumerator];
			while(table = [tableEnum nextObject])
			{	
				holder = [NSString stringWithFormat: @"%@.%@", 
						[table name],
						[processedArgs objectForKey: @"Output"]];
				holder = [outputDir stringByAppendingPathComponent: holder];		
				[table writeMatrixToFile: holder];
				i++;	
			}	
		}
	}
}

- (id) init
{
	NSString* path;
	NSData* data;

	if(self = [super init])
	{
#ifdef GNUSTEP	
		path = 	[[[NSBundle mainBundle] bundlePath] 
			stringByAppendingPathComponent: @"converterOptions.plist"];
		validOptions = [NSMutableDictionary dictionaryWithContentsOfFile: path]; 
		[validOptions retain];
		NSDebugLLog(@"ResultsConverter", @"Valid Options are %@ (from %@)", validOptions, path);
#else
		//New test implementation
		data = [options dataUsingEncoding: NSUnicodeStringEncoding];
		validOptions = [NSPropertyListSerialization propertyListFromData: data 
				mutabilityOption: NSPropertyListMutableContainers 
				format: NULL
				errorDescription: nil];
		[validOptions retain];
#endif		
	}
	
	return self;
}

- (void) dealloc
{
	[validOptions release];
	[super dealloc];
}

- (void) main
{
	int i;
	FILE* file_p;
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	NSEnumerator *subsystemEnum;
	NSArray *resultsTables;
	id subsystems, subsystem, dict, options;
	id output, storage;
	NSError* error;

	GSPrintf(stderr, @"Processing Arguments\n");

	[self _processArguements];

	//create the results object and set the options

	GSPrintf(stderr, @"Accessing Results\n");
	
	results = [[AdSimulationData new] autorelease];
	storage = [[AdFileSystemSimulationStorage alloc] 
			initForReadingSimulationDataAtPath: 
			 [processedArgs valueForKey: @"Trajectory"]];

	if(![storage isAccessible])
	{		
		error = [storage accessError];
		NSLog(@"Error - %@", [[error userInfo] objectForKey: NSLocalizedDescriptionKey]);
		exit(1);
	}
	[results setDataStorage: storage];
	[results loadData];
	
	NSDebugLLog(@"ResultsConverter", 
		@"Results class %@.", 
		NSStringFromClass([results class]));

	GSPrintf(stderr, @"Validating Arguments against Results\n");
	
	[self _validateArgs];

	NSDebugLLog(@"ResultsConverter",
		 @"Processed and Validated Args\n%@",
		processedArgs); 

	//convert 

	if(![[processedArgs valueForKey:@"Mode"] isEqual: @"Info"])
	{
		[self _loadConverterBundle];
		options = [plugin pluginOptions: [NSArray arrayWithObject: results]];

		NSDebugLLog(@"ResultsConverter", @"Converter plugin options %@", options);
		[options setValue: [processedArgs valueForKey: @"Subsystems"]
			 forKeyPath: @"Systems.Selection"];
		[options setValue: [processedArgs valueForKey: @"Start"]
			 forKeyPath: @"Frames.Start"];
		[options setValue: [processedArgs valueForKey: @"Length"] 
			forKeyPath: @"Frames.Length"];
		[options setValue: [processedArgs valueForKey: @"Stepsize"] 
			forKeyPath: @"Frames.Stepsize"];

		if([processedArgs objectForKey: @"Unit"] != nil)
			[options setValue: [processedArgs valueForKey: @"Unit"] 
				forKey: @"EnergyUnit"]; 

		if([[processedArgs valueForKey:@"Mode"] isEqual: @"Energy"])
		{
			subsystemEnum = [[options valueForKey: @"Systems"] keyEnumerator];
			while(subsystem = [subsystemEnum nextObject])
				if(! ([subsystem isEqual: @"Selection"] || [subsystem isEqual:@"Type"]))
				{
					dict = [options valueForKeyPath: 
							[NSString stringWithFormat: 
								@"Systems.%@", subsystem]];
					[dict setObject: [processedArgs valueForKey: @"Terms"] 
						forKey: @"Selection"];
				}
		}
		else if([[processedArgs valueForKey:@"Mode"] isEqual: @"Configuration"])
			[options setValue: [NSArray arrayWithObject: @"pdb"]
				forKeyPath: @"Format.Selection"];

		GSPrintf(stderr, @"Performing Conversion\n");

		output = [plugin processInputs: [NSArray arrayWithObject: results]
				 userOptions: options]; 

		if(output != nil)
		{
			resultsTables = [output objectForKey: @"ULAnalysisPluginDataSets"];
			if(resultsTables != nil)
				[self _outputDataSets: resultsTables];
		}
	}
	else
		[self _printInfo: results];

	GSPrintf(stderr, @"Complete\n");
}

/*******
Arg Validation
*****/

- (BOOL) validateTerms: (id*) terms error: (NSError**) error
{
	if([*terms isKindOfClass: [NSArray class]])
		return YES;
	else if([*terms isKindOfClass: [NSString class]])
	{
		*terms = [*terms componentsSeparatedByString: @","];
		return YES;
	}
	else
		return NO;
}

- (BOOL) validateSubsystems: (id*) subsystems error: (NSError**) error
{
	if([*subsystems isKindOfClass: [NSArray class]])
		return YES;
	else if([*subsystems isKindOfClass: [NSString class]])
	{
		*subsystems = [*subsystems componentsSeparatedByString: @","];
		return YES;
	}
	else
		return NO;
}


@end
