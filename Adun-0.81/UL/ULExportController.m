/* 
   Project: UL

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

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
#include "ULExportController.h"
#include <AdunKernel/AdunFileSystemSimulationStorage.h>
#include <MolTalk/MolTalk.h>

id sharedExportController = nil;

/**
Category containing method wrappers around ULFramework functions
*/
@interface ULExportController (PrivateExportWrappers)
- (id) exportDataSetAsCSV: (id) anObject toFile: (NSString*) filename;
- (id) exportDataSourceAsPDB: (id) anObject toFile: (NSString*) filename;
- (id) exportTemplateAsPropertyList: (id) template toFile: (NSString*) fileName;
@end

@implementation ULExportController

+ (id) sharedExportController
{
	if(sharedExportController == nil)
		sharedExportController = [self new];

	return sharedExportController;
}

- (id) init
{
	if(sharedExportController != nil)
		return sharedExportController;

	if(self = [super init])
	{
		if([NSBundle loadNibNamed: @"CreateAttributePanel" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}
	
		attributeDataSet = nil;
		exportPanel = [ULExportPanel exportPanel];
		pasteboard = [ULPasteboard appPasteboard];
		sharedExportController = self;
		knownFormats = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSArray arrayWithObjects: 
					@"pdb",
					@"binary archive",
					nil],
				@"AdDataSource",
				[NSArray arrayWithObjects: 
					@"csv",
					@"binary archive",
					nil],
				@"AdDataSet",
				[NSArray arrayWithObject: @"binary archive"],
				@"AdSimulationData",
				[NSArray arrayWithObjects: 
					@"AdunCore template",
					@"binary archive",
					nil],
				@"ULTemplate", nil];
		[knownFormats retain];		
		displayStrings = [NSDictionary dictionaryWithObjectsAndKeys:
				@"System", @"AdDataSource",
				@"Simulation", @"AdSimulationData",
				@"DataSet", @"AdDataSet",
				@"Template", @"ULTemplate", nil];
		[displayStrings retain];	
		exportMethods = [NSMutableDictionary new];
		[exportMethods setObject: 
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSStringFromSelector(@selector(exportDataSetAsCSV:toFile:)),
				@"csv", nil]	
			forKey: @"AdDataSet"];	
		[exportMethods setObject: 
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSStringFromSelector(@selector(exportDataSourceAsPDB:toFile:)),
				@"pdb", nil]	
			forKey: @"AdDataSource"];	
		[exportMethods setObject: 
			[NSDictionary dictionaryWithObjectsAndKeys:
				NSStringFromSelector(@selector(exportTemplateAsPropertyList:toFile:)),
				@"AdunCore template", nil]	
			forKey: @"ULTemplate"];	

	}

	return self;
}

- (void) dealloc
{
	[knownFormats release];
	[displayStrings release];
	[exportMethods release];
	[super dealloc];
}

- (void) _exportObjectAsBinaryArchive: (id) anObject toFile: (NSString*) filename
{
	BOOL retVal;
	int selectedRow;
	NSError *error;
	NSMutableData *data;
	NSKeyedArchiver* archiver;
	NSString* storagePath, *destinationPath;

	//If its a simulation we also have to export the simulation
	//data directory. This involves copying the directory to the
	//chosen location. 	
	//FIXME: We should define path extensions for the different types 
	//of adun objects.
	
	if([anObject isKindOfClass: [AdSimulationData class]])
	{
		storagePath = [[anObject dataStorage] storagePath];
		destinationPath =  [filename stringByAppendingString: @"_Data"];
		retVal = [[NSFileManager defaultManager]
				copyPath: storagePath
				toPath: destinationPath
				handler: nil];

		if(!retVal)
		{
			//Abort
			NSRunAlertPanel(@"Error",
				@"Unable to extract simulation data - Aborting",
				@"Dismiss", 
				nil,
				nil);

			return;
		}	
	}
	data = [NSMutableData new];
	archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	[archiver setOutputFormat: NSPropertyListXMLFormat_v1_0];
	[archiver encodeObject: anObject forKey: @"root"];
	[archiver finishEncoding];
	[archiver release];
	
	retVal = [[ULIOManager appIOManager]
			writeObject: data 
			toFile: filename 
			error: &error];

	[data release];
	if(!retVal)
	{
		NSRunAlertPanel(@"Error",
			[[error userInfo] objectForKey:NSLocalizedDescriptionKey],
			@"Dismiss", 
			nil,
			nil);
	}
}

- (void) export: (id) sender
{
	int result, index;
	id exportObject; //the actual unarchived object
	id savePanel;
	NSString* filename, *format, *type, *extension;

	//Get the type of the object to be exported
	
	type = [[pasteboard availableTypes] objectAtIndex: 0];
	[exportPanel setObjectType: [displayStrings objectForKey: type]];
	[exportPanel setChoices: [knownFormats objectForKey: type]];
	result = [exportPanel runModal];
	format = [exportPanel choice];

	if(result == NSOKButton)
	{
		savePanel = [NSSavePanel savePanel];	
		if([[exportPanel choice] isEqual: @"pdb"])
			[savePanel setRequiredFileType: @"pdb"];
			
		[savePanel setTitle: @"Export Data"];
		result = [savePanel runModal];
		filename = [savePanel filename];

		if(result == NSOKButton)
		{
			//Take any extension off filename 
			//This just makes it easier to work with it later
			extension = [filename pathExtension];
			exportObject = [pasteboard objectForType: type];
			[self exportObject: exportObject 
				toFile: filename
				format: format];
		}		
	}			
}

/*
As exportObject:toFile:format: except using ULExportType enum values to define the type
instead of a string.
Raises an NSInvalidArgumentException is type is invalid.
*/
- (void) exportObject: (id) anObject toFile: (NSString*) filename as: (ULExportType) type
{
	NSString* format;
	
	switch((int)type)
	{
		case ULBinaryArchiveExportType:
			format = @"binary archive";
			break;
		case ULPDBExportType:
			format = @"pdb";
			break;
		case ULCSVExportType:
			format = @"csv";
			break;
		case ULAdunCoreTemplateExportType:
			format = @"AdunCore template";
			break;
		default:
			[NSException raise: NSInvalidArgumentException
				format: @"Type id %d unknown - cannot export object", type];
	}
	
	[self exportObject: anObject toFile: filename format: format];
}

- (void) exportObject: (id) anObject toFile: (NSString*) filename format: (NSString*) format 
{
	SEL selector;
	NSString* selectorString;
	
	if([format isEqual: @"binary archive"])
		[self _exportObjectAsBinaryArchive: anObject toFile: filename];
	else
	{
		selectorString = [[exportMethods objectForKey: 
						NSStringFromClass([anObject class])]
					objectForKey: format];
		[self performSelector: NSSelectorFromString(selectorString)
			withObject: anObject
			withObject: filename];		
	}
}

/*
 Returns yes if the objects of class \e className can be exported as \e type.
 The valid values for type are given by the ULExportType enum.
 If \e type is not one of the above then an NSInvalidArgumentException is raised.
 */
- (BOOL) canExportObjectofClass: (NSString*) className  as: (ULExportType) type
{
	BOOL retval = NO;

	//everything can be exported as a binary archive
	if(type == ULBinaryArchiveExportType)
		return YES;

	if(type == ULPDBExportType)
	{
		if([className isEqual: @"AdDataSource"])
			retval = YES;
	}
	else if(type == ULCSVExportType)
	{
		if([className isEqual: @"AdDataSet"])
			retval = YES;
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"Invalid export type - (%d)", type];
	
	return retval;
}

/*
 Returns yes if the current object on the pasteboard can be exported as \e type.
 If there is no object, or more than one object, on the pasteboard this method returns NO.
 The valid values for type are given by the ULExportType enum.
 If \e type is not one of the above then an NSInvalidArgumentException is raised.
 If there is no object on the pasteboard this method returns NO.
 */
- (BOOL) canExportCurrentPasteboardObjectAs: (ULExportType) type
{	
	BOOL retval = NO;
	NSString* className;
	NSArray* availableTypes;	
		
	availableTypes = [pasteboard availableTypes];
	if([availableTypes count] == 1)
	{
		className = [availableTypes objectAtIndex: 0];
		retval = [self canExportObjectofClass: className as: type];
	}

	return retval;
}

/*
 Exports the current pasteboard object as \e type. 
 Runs an NSSavePanel to prompt for the file name.
 Raises NSInvalidArgumentException if the current pasteboard object cannot be
 export as type.
 */
- (void) exportCurrentPasteboardObjectAs: (ULExportType) type
{
	int result;
	NSString* className, *filename, *extension;
	NSArray* availableTypes;
	NSSavePanel* savePanel;
	id exportObject;
	
	availableTypes = [pasteboard availableTypes];
	if([availableTypes count] == 1)
	{
		className = [availableTypes objectAtIndex: 0];
		if([self canExportObjectofClass: className as: type])
		{	
			//Run panel to get the filename
			savePanel = [NSSavePanel savePanel];	
			if([[exportPanel choice] isEqual: @"pdb"])
				[savePanel setRequiredFileType: @"pdb"];
			
			[savePanel setTitle: @"Export Data"];
			[savePanel setDirectory: nil];
			result = [savePanel runModal];
			filename = [savePanel filename];
			
			if(result == NSOKButton)
			{
				//Take any extension off filename 
				//This just makes it easier to work with it later
				extension = [filename pathExtension];
				exportObject = [pasteboard objectForType: className];
				[self exportObject: exportObject 
					    toFile: filename
					    as: type];
			}		
		}			
		else
			[NSException raise: NSInvalidArgumentException
				format: @"Cannot export objects of class %@ as type %d", 
					className, type];
	}
}

@end

@implementation ULExportController (PrivateExportWrappers)

- (id) exportDataSetAsCSV: (id) dataSet toFile: (NSString*) filename
{
	int i;
	NSArray* dataMatrices;
	AdDataMatrix* matrix;
	id name, cvsString;

	dataMatrices = [dataSet dataMatrices];
	//Remove any path extension specified so we can add the filenumber.
	filename = [filename stringByDeletingPathExtension];
	for(i=0; i<(int)[dataMatrices count];i++)
	{
		name = [NSString stringWithFormat: @"%@%d.csv", filename, i+1];
		matrix = [dataMatrices objectAtIndex: i];
		cvsString = [matrix stringRepresentation];
		[cvsString writeToFile: name atomically: NO];
	}

	return nil;
}

- (id) exportDataSourceAsPDB: (id) dataSource toFile: (NSString*) filename
{
	id structure;
	MTFileStream* fileStream;

 	structure = ULConvertDataSourceToPDBStructure(dataSource);		
	fileStream = [MTFileStream streamToFile: 
			[NSString stringWithFormat: @"%@", filename]];
	[structure writePDBToStream: fileStream];
	[fileStream close];

	return nil;
}

- (id) exportTemplateAsPropertyList: (id) template toFile: (NSString*) filename
{
	[[template coreRepresentation] writeToFile: filename
		atomically: NO];

	return nil;	
}

@end


@implementation ULExportController (ChimeraAttributeFileCreation)

- (void) _saveAttributeFile: (NSMutableString*) string
{
	int result;
	NSSavePanel* savePanel;
	NSString* filename;
	NSError* error = nil;
	
	savePanel = [NSSavePanel savePanel];	
	[savePanel setTitle: @"Save Attribute File"];
	result = [savePanel runModal];
	filename = [savePanel filename];
	
	if(result == NSOKButton)
	{
	
//Gnustep base pre 0.16	
#if defined GNUSTEP && GS_API_VERSION(0, 011600) 
		[string writeToFile: filename 
			 atomically: NO];
#else
		[string writeToFile: filename 
			 atomically: NO 
			   encoding: NSUTF8StringEncoding 
			      error: &error];
		
		if(error != nil)
			ULRunErrorPanel(error);	  
#endif		
	
	}		
}

- (void) openAttributeWindow: (id) sender
{
	NSArray* matrixNames, *headers;

	//Get rid of old data
	if(attributeDataSet != nil)
		[attributeDataSet release];
		
	[matrixList removeAllItems];
	[attributeColumnList removeAllItems];
	[residueColumnList removeAllItems];
	[atomColumnList removeAllItems];
	
	//Get data
	attributeDataSet = [pasteboard objectForType: @"AdDataSet"];
	[attributeDataSet retain];
	
	//Populate lists
	matrixNames = [[attributeDataSet dataMatrices] valueForKey: @"name"];
	[matrixList addItemsWithTitles: matrixNames];
	
	//Default choose first matrix
	headers = [[[attributeDataSet dataMatrices] objectAtIndex: 0] columnHeaders];
	[residueColumnList addItemsWithTitles: headers];
	[atomColumnList addItemsWithTitles: headers];
	[attributeColumnList addItemsWithTitles: headers];
	
	//A defaults number scheme for the recipient
	[residueColumnList addItemWithTitle: @"Numbered"];
	
	[attributeWindow center];
	[attributeWindow makeKeyAndOrderFront: self];
}

- (void) changedMatrixSelection: (id) sender
{
	NSString* matrixName;
	NSArray* headers;

	[attributeColumnList removeAllItems];
	[residueColumnList removeAllItems];
	[atomColumnList removeAllItems];
	
	matrixName = [matrixList titleOfSelectedItem];
	headers = [[attributeDataSet dataMatrixWithName: matrixName] 
			columnHeaders];
			
	[residueColumnList addItemsWithTitles: headers];
	[atomColumnList addItemsWithTitles: headers];
	[attributeColumnList addItemsWithTitles: headers];
	
	[residueColumnList addItemWithTitle: @"Numbered"];
	
	[attributeWindow display];
}

- (void) createAttributeFile: (id) sender
{
	BOOL valid, useAtoms=NO;
	int i;
	NSRange numRange;
	NSMutableString* string = [NSMutableString new];
	NSString* name, *matrixName, *residueColName, *atomColName, *version;
	NSArray* attributeColumn,  *atomColumn;
	NSEnumerator* attributeEnum;
	AdDataMatrix* matrix;
	id attribute, residueColumn;
	
	matrixName = [matrixList titleOfSelectedItem];
	
#ifdef GNUSTEP
	version = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"ApplicationVersion"],
#else

	version = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"],
#endif
	[string appendFormat: 
		@"#Chimera attribute file created by Adun %@ on %@\n", version, [NSDate date]];

	[string appendFormat: @"#Created using matrix %@ of data set %@\n", 
		matrixName, [attributeDataSet name]];

	name = [nameField stringValue];
	name = [name lowercaseString];
	
	valid = NO;
	while(!valid && ([name length] > 1))
	{
		if([[name substringToIndex:1] isEqual: @"_"])
		{
			name = [name substringFromIndex: 1];
			valid = NO;
		}
		else
			valid = YES;	
		
		numRange = [name rangeOfCharacterFromSet: 
				[NSCharacterSet decimalDigitCharacterSet]];
		if(numRange.location == 0)
		{
			valid = NO;
			name = [name substringFromIndex: 1];
		}
		else
			valid = YES;
	}
	
	[string appendFormat: @"attribute: %@\n", name];
	[string appendFormat: @"match mode: %@\n", [relationshipList titleOfSelectedItem]];
	
	//We need the residue column no matter what.
	residueColName = [residueColumnList titleOfSelectedItem];
	
	//Find the exact recipient
	if([atomButton state])
	{
		useAtoms = YES;
		[string appendString: @"recipient: atoms\n"];
		atomColName = [atomColumnList titleOfSelectedItem];
	}
	else
		[string appendString: @"recipient: residues\n"];
	
	matrix = [attributeDataSet dataMatrixWithName: matrixName];
	attributeColumn = [matrix columnWithHeader: 
				[attributeColumnList titleOfSelectedItem]];
				
	if([residueColName isEqual: @"Numbered"])	
	{		
		residueColumn = [NSMutableArray array];
		for(i=0; i<[attributeColumn count]; i++)
			[residueColumn addObject: [NSNumber numberWithInt: i]];
		
	}	
	else
		residueColumn = [matrix columnWithHeader: residueColName];
	
	if(!useAtoms)
	{
		for(i=0; i<[residueColumn count]; i++)
		{
			[string appendFormat: @"\t:%@\t%@\n", 
				[residueColumn objectAtIndex: i],
				[attributeColumn objectAtIndex: i]];
		}
	}
	else
	{
		atomColumn =  [matrix columnWithHeader: 
			       [atomColumnList titleOfSelectedItem]];

		for(i=0; i<[residueColumn count]; i++)
		{
			[string appendFormat: @"\t:%@@%@\t%@\n", 
			 [residueColumn objectAtIndex: i],
			 [atomColumn objectAtIndex: i],
			 [attributeColumn objectAtIndex: i]];
		}		
	}
	
	[string appendFormat: @"\n"];
	[attributeWindow close];
	[self _saveAttributeFile: string];
	
	[string release];
}

- (BOOL) validateCreateAttribute: (id) sender
{
	if([pasteboard countOfObjectsForType: @"AdDataSet"] == 0)
		return NO;
	
	return YES;		
}

@end



