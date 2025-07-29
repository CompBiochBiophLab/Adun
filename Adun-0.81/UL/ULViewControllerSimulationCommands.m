#include "ULViewControllerSimulationCommands.h"

@implementation ViewController (SimulationCommands)

- (void) halt: (id) sender
{
	int row;
	id process;


	NS_DURING
	{
		process = [[activeDelegate objectsForType: @"ULProcess"]
				objectAtIndex: 0];
		[processManager haltProcess: process];
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
}
	NS_ENDHANDLER
}

- (void) restart: (id) sender
{
	int row;
	id process;

	NS_DURING
	{
		process = [[activeDelegate objectsForType: @"ULProcess"]
				objectAtIndex: 0];
		[processManager restartProcess: process];
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
	}
	NS_ENDHANDLER
}

- (void) terminateProcess: (id) sender
{
	int row;
	id process;

	NS_DURING
	{
		process = [[activeDelegate objectsForType: @"ULProcess"]
				objectAtIndex: 0];
		[processManager terminateProcess: process];
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
	}
	NS_ENDHANDLER
}

- (void) start: (id) sender
{
	int row;
	id process;
	NSString* simulationHost;

	NS_DURING
	{
		process = [[activeDelegate objectsForType: @"ULProcess"]
				objectAtIndex: 0];
		[processManager startProcess: process];
	}
	NS_HANDLER
	{
		if([[localException name] isEqual: @"ULCouldNotConnectToServerException"])
		{
			simulationHost = [[localException userInfo] objectForKey: @"host"];

			if([simulationHost isEqual: [[NSHost currentHost] name]])
				[self startAdunServer];
			else
				NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
		}	
	
		NSWarnLog(@"%@ %@", [localException reason], [localException userInfo]);
	}
	NS_ENDHANDLER
}

- (void) execute: (id) sender
{
	int row;
	NSString *alertTitle, *name;
	NSMutableArray* strings;
	NSError* error;
	NSMutableDictionary* commandDict = [NSMutableDictionary dictionaryWithCapacity: 1];
	id result, process;

	error = nil;
	result = nil;
	NS_DURING
	{
		//We change the buttons title into camelCase to 
		//create command name
		strings = [[[sender title] componentsSeparatedByString: @" "] 
				mutableCopy];
		name = [[strings objectAtIndex: 0] lowercaseString];
		[strings removeObjectAtIndex: 0];
		[strings insertObject: name atIndex: 0];
		name = [strings componentsJoinedByString: @""];
		
		[commandDict setObject: name
			forKey: @"command"];
		process = [[activeDelegate objectsForType: @"ULProcess"]
				objectAtIndex: 0];
		result = [processManager execute: commandDict 
		 		error: &error 
				process: process];
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
		NSWarnLog(@"Local exception user info %@. Reason %@", [localException userInfo],
				[localException reason]);
	}	
	NS_ENDHANDLER

	//display the error if there is one
	//\todo expand the options available here
		
	if(error != nil)
	{
		alertTitle = [NSString stringWithFormat: @"Alert: %@", [error domain]];
		NSRunAlertPanel(alertTitle,
			 [[error userInfo] objectForKey: NSLocalizedDescriptionKey], 
			@"Dismiss", 
			nil, 
			nil);
	}

	if(result != nil)
		[self logString: [NSString stringWithFormat: @"%@:\n%@\n",
					[sender title], 
					[result valueForKey:@"stringDescription"]] 
			newline: YES
			forProcess: process];
}

@end
