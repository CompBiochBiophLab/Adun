/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 14:11:56 +0200 by michael johnston

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

#include "ULFramework/ULProcess.h"

@implementation ULProcess

+ (id) processWithInputData: (NSDictionary*) aDict 
	simulationTemplate: (id) simulationTemplate
	additionalArguments: (NSArray*) anArray
	host: (NSString*) aName;
{
	id process;

	process = [[ULProcess alloc]
			initWithInputData: aDict 
			simulationTemplate: simulationTemplate
			additionalArguments: anArray
			host: aName];
			
	return [process autorelease];
}

- (id) initWithInputData: (NSDictionary*) aDict 
	simulationTemplate: (id) simulationTemplate
	additionalArguments: (NSArray*) anArray
	host: (NSString*) aName
{
	NSEnumerator* dataEnum;
	NSMutableDictionary* dataDict = [NSMutableDictionary dictionary];;
	id data;

	if((self = [super init]))
	{
		dataSets = nil;
		simulationData = nil;
		terminationError = nil;
		processIdentifier = -1;
		isFinished = NO;
		inputDataSent = NO;
		templateSent = NO;
		
		simulationArgs = [NSMutableArray arrayWithObjects: @"-RunMode", @"Server",
				  @"-CreateLogFiles", @"YES",
				  @"-ConnectToAdServer", @"YES",
				  @"-RunInteractive", @"YES",
				  nil];
		[simulationArgs retain];
		
		if(anArray != nil)
			[simulationArgs addObjectsFromArray: anArray];
		
		[self setValue: @"N/A" forMetadataKey: @"Length"];
		[self setValue: aName forMetadataKey: @"Host"];
		[self setValue: @"N/A" forMetadataKey: @"Started"];
		[self setValue: @"Waiting" forMetadataKey: @"Status"];
		[self setValue: [NSNumber numberWithInt: processIdentifier]
			forMetadataKey: @"Process Identifier"];
		[self setValue: [simulationTemplate 
				    valueForKeyPath: @"metadata.simulationName"]
		   forMetadataKey: @"Name"];	
		[self setValue: simulationArgs
			forMetadataKey: @"Arguments"];	

		inputData = [aDict retain];
		dataEnum = [inputData objectEnumerator];
		while((data = [dataEnum nextObject]))
			[dataDict setObject: [data identification] 
				forKey: [data name]];
		
		[self setValue: dataDict
			forMetadataKey: @"InputData"];
		//FIXME: Template name?
		simTemplate = [simulationTemplate retain];
	}

	return self;
}


- (void) dealloc
{
	[simulationArgs release];
	[dataSets release];
	[inputData release];
	[simTemplate release];
	[simulationData release];
	[terminationError release];

	[super dealloc];
}

- (NSArray*) arguments
{
	return [[simulationArgs copy] autorelease];
}

- (void) addArguments: (NSArray*) anArray
{
	if(anArray != nil)
	{
		[simulationArgs addObjectsFromArray: anArray];
		[self setValue: simulationArgs
			forMetadataKey: @"Arguments"];	
	}
}

- (int) processIdentifier
{
	return [[self valueForMetadataKey: @"Process Identifier"] intValue];
}

- (NSString*) processHost
{
	return [self valueForMetadataKey: @"Host"];
}

- (NSString*) processStatus
{
	return [self valueForMetadataKey: @"Status"];
}

- (NSDate*) started
{
	return [self valueForMetadataKey: @"Started"];
}

- (id) length
{
	return [self valueForMetadataKey: @"Length"];
}

- (NSArray*) controllerResults
{
	return [[dataSets retain] autorelease];
}

- (id) simulationData
{
	return [[simulationData retain] autorelease];
}

- (NSError*) terminationError
{
	return [[terminationError retain] autorelease];
}

- (BOOL) hasSentProcessData
{
	return (templateSent && inputDataSent);
}

- (BOOL) isFinished
{
	return isFinished;
}

- (void) waitUntilFinished
{
	while(!isFinished)
		[[NSRunLoop currentRunLoop] 
		 runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 5]];
	
}

/*
 * ULClientInterface Methods
*/

- (void) setStarted: (NSDate*) value
{
	[self setValue: value
	forMetadataKey: @"Started"];
}

- (void) setProcessStatus: (NSString*) value
{
	[self setValue: value forMetadataKey: @"Status"];
}

- (void) setProcessIdentifier: (int) number
{
	[self setValue: [NSNumber numberWithInt: number] 
		forMetadataKey: @"Process Identifier"];
}

- (void) setControllerResults: (NSArray*) results
{
	id dataSet;
	
	NSDebugLLog(@"ULProcess", 
		@"Recieved controller data %@", results);
	
	if(dataSet != results)
	{
		[dataSets release];
		dataSets = [results retain];
	}
}

- (void) setSimulationData: (AdSimulationData*) data
{
	NSString* dataDir;
	NSString* ident;
	AdFileSystemSimulationStorage* storage;

	if(simulationData != nil)
		[simulationData release];
	
	simulationData = [data retain];
	ident = [simulationData identification];

	//Retrieve the data ID and hence find where
	//the data is stored
	//FIXME: temp until program args are transfered here
	dataDir = [[[ULDatabaseInterface databaseInterface]
			primaryFileSystemBackend] simulationDir];

	//FIXME: Add error handling		
	storage = [AdFileSystemSimulationStorage 
			storageForSimulation: simulationData 
			inDirectory: dataDir 
			mode: AdSimulationStorageReadMode 
			error: NULL];
	[simulationData setDataStorage: storage];
}

- (bycopy NSDictionary*) simulationTemplate
{
	templateSent = YES;
	return [[simTemplate retain] autorelease];
}

- (bycopy NSDictionary*) inputData
{
	inputDataSent = YES;
	return [[inputData retain] autorelease];
}

- (void) processDidTerminate: (NSError*) error
{
	NSTimeInterval interval;
	NSString* length;
	NSMutableDictionary* userInfo;

	NSDebugLLog(@"ULProcess", @"Recieved termination message");
	
	isFinished = YES;
	[self setValue: @"Finished" forKey: @"processStatus"];

	interval = -1*[date timeIntervalSinceNow];
	length = ULConvertTimeIntervalToString(interval);
	[self setValue: length
		forMetadataKey: @"Length"];

	processIdentifier = -1;

	userInfo  = [NSMutableDictionary dictionary];
	[userInfo setObject: self forKey: @"ULTerminatedProcess"];
	terminationError = [error retain];
	if(error != nil)
		[userInfo setObject: error forKey: @"AdTerminationErrorKey"];

	NSDebugMLLog(@"ULProcess", @"Posting notification with dictionary %@", userInfo);

	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"ULProcessDidFinishNotification"
		object: self
		userInfo: userInfo];
}



- (id) initWithCoder: (NSCoder*) decoder
{
	if((self = [super initWithCoder: decoder]))
	{
		if([decoder allowsKeyedCoding])
		{
			inputData = [decoder decodeObjectForKey: @"InputData"];
			simTemplate = [decoder decodeObjectForKey: @"Template"];
			simulationData = [decoder decodeObjectForKey: @"SimulationData"];
			[simulationData retain];
			[inputData retain];
			[simTemplate retain];
		}		
	}
	
	return self;
}	

- (void) encodeWithCoder: (NSCoder*) encoder
{
	[super encodeWithCoder: encoder];
	
	if([encoder allowsKeyedCoding])
	{
		[encoder encodeObject: inputData
			forKey: @"InputData"];
		[encoder encodeObject: simTemplate
			forKey: @"Template"];
		if(simulationData != nil)
			[encoder encodeObject: simulationData
				forKey: @"SimulationData"];
	}
}

@end
