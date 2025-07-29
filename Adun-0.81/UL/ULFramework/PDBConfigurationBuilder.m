/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-24 15:03:58 +0200 by michael johnston

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed ithe hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#include "PDBConfigurationBuilder.h"
#include "ULFramework/ULMenuExtensions.h"

@implementation PDBConfigurationBuilder

- (id) _structureObjectForPDB: (NSString*) path
{
	id outputPath, molStruct;

	outputPath = [[NSUserDefaults standardUserDefaults] stringForKey: @"BuildOutput"]; 
	buildOutput = fopen([outputPath cString], "a");

	if(![[NSFileManager defaultManager] fileExistsAtPath: path])
	{	
		GSPrintf(buildOutput, @"File does not exist!\n");
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat: 
			@"Specified file (%@) does not exist", path]];
	}
	
	GSPrintf(buildOutput, @"The pdb file is %@\n\n", path);

	NS_DURING
	{	
		//Ignore REMARK since some programs add data here that breaks the pdb format
		//Ignore COMPND and SOURCE - For some reason the MOL_ID entry in these sections
		//causes MolTalk to create a phantom extra chain (only for the first model however).
		molStruct = [MTStructureFactory newStructureFromPDBFile: path
				options: 256 + 16 + 32];
	}
	NS_HANDLER
	{
		[NSException raise: @"ULBuildException" 
			format: @"Unable to create structure object"];
	}
	NS_ENDHANDLER

	fclose(buildOutput);

	return molStruct;
}

/*
Takes an array of amino acid atom names and the residue they
are from. This method replaces any old style names in the
array with the correct version. It returns YES if any replacements
were made, NO otherwise.
note: The old new mapping only will affect certain hydrogens so
it would  be more efficent to just do this on them. 
However we could expand this to deal with other pdb naming errors
involving other naming systems e.g. using IUPAC. This
would be complicated however due to nonunique lables (see below)
*/

- (void) _correctAminoAcidAtomNames: (NSMutableArray*) atomNames
	forResidue: (NSString*) residue
{
	BOOL oldNames = NO;
	int i, numberOfAtoms;
	NSString* currentAtom, *newName;
	NSArray* newNames;
	NSDictionary* nameMapForResidue;

	/*
	 We need to avoid cases where be the same ID exists in both
	 old and new forms but refers to different atoms.
	 Therefore if any atom is old we assume they all are.
	*/
	
	//nameMap maps oldPDBName->newPDBName
	nameMapForResidue = [nameMap objectForKey: residue];

	//if we cant id the residue just return - 
	//we only deal with the 20 standard A.As
	if(nameMap == nil)
		return;

	newNames = [nameMapForResidue allValues];
	numberOfAtoms = [atomNames count];
	for(i=0; i<numberOfAtoms; i++)
	{
		currentAtom = [atomNames objectAtIndex: i];
		if(![newNames containsObject: currentAtom])
		{
			oldNames =YES;
			break;
		}
	}
	
	if(oldNames)
		for(i=0; i<numberOfAtoms; i++)
		{
			currentAtom = [atomNames objectAtIndex: i];
			newName = [nameMapForResidue objectForKey: currentAtom];
			if(newName != nil)
				[atomNames replaceObjectAtIndex: i
					withObject: newName];
		}
}

/*
This method takes a list of amino acids atoms & residues and a mapping
of atoms to residues. It checks if the names are correct and returns
an array of the atom names with the corrections.
*/

- (id) _verifyAminoAcidAtomNames: (NSMutableArray*) atomNames
	forResidues: (NSMutableArray*) residues
	atomsPerResidue: (NSMutableArray*) atomsPerResidue
{
	int startAtom, endAtom, i;
	NSRange residueRange;
	NSString* currentResidue;
	NSMutableArray* residueAtoms, *newAtomNames;

	[buildString appendString: @"\t\tChecking hydrogen naming and correcting if neccessary\n"];
	
	newAtomNames = [NSMutableArray array];
	startAtom = endAtom = 0;
	for(i=0; i<[residues count]; i++)
	{
		currentResidue = [residues objectAtIndex: i];
		endAtom =  [[atomsPerResidue objectAtIndex: i] intValue];
		residueRange = NSMakeRange(startAtom, endAtom);
		residueAtoms = [[atomNames subarrayWithRange: residueRange]
					mutableCopy];
	
		[self _correctAminoAcidAtomNames: residueAtoms
			forResidue: currentResidue];
		
		[newAtomNames addObjectsFromArray: residueAtoms];
		startAtom += endAtom;
	}

	return newAtomNames;
}

- (id) _processChain: (id) chain 
	section: (NSString*) section 
	selection: (NSArray*) selection
	atomMatrix: (AdMutableDataMatrix*) matrix
{
	id residue, residueName, residueDescription, atom;
	NSEnumerator* residueEnum, *atomEnum;
	NSMutableArray *atomsPerResidue, *sequence, *atomNames, *coordinateArray;
	NSMutableDictionary* result;

	atomNames = [NSMutableArray array];
	atomsPerResidue = [NSMutableArray array];
	sequence = [NSMutableArray array];
	result = [NSMutableDictionary dictionary];
	coordinateArray = [NSMutableArray array];
	
	if([section isEqual: @"Residues"])
		residueEnum = [chain allResidues];
	else if([section isEqual: @"Heterogens"])
		residueEnum = [chain allHeterogens];
	else if([section isEqual: @"Solvent"])
		residueEnum = [chain allSolvent];
	else
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat:
		 	@"Invalid chain section %@", section]];

	NSDebugLLog(@"PDBConfigurationBuilder",
			 @"\tProcess chain section %@ with selection %@", section, selection);

	if(selection == nil)
	{
		NSDebugLLog(@"PDBConfigurationBuilder", 
				@"\tSelection is nil. Adding all available residues");
		[buildString appendString: @"\t\tAdding all available residues\n"];

		while((residue = [residueEnum nextObject]))
		{
			[atomsPerResidue addObject: [NSNumber numberWithInt: 
				[[[residue allAtoms] allObjects] count]]];
			[sequence addObject:
				[[residue name] stringByTrimmingCharactersInSet: 
					[NSCharacterSet whitespaceCharacterSet]]];
			atomEnum = [residue allAtoms];
			while((atom = [atomEnum nextObject]))
			{
				[atomNames addObject: [atom name]];
				[coordinateArray addObject: 
					[NSNumber numberWithDouble: [atom x]]];
				[coordinateArray addObject: 
					[NSNumber numberWithDouble: [atom y]]];
				[coordinateArray addObject: 
					[NSNumber numberWithDouble: [atom z]]];
				[matrix extendMatrixWithRow: coordinateArray];
				[coordinateArray removeAllObjects];
			}
		}
	}	
	else
	{
		[buildString appendString: @"\t\tSearching for selected residues\n"];
		
		while((residue = [residueEnum nextObject]))
		{
			residueName = [residue name];
			residueDescription = [residue description];
			NSDebugLLog(@"PDBConfigurationBuilder",
				@"\tChecking residue %@", residueDescription);
			if([selection containsObject: residueDescription])
			{	
				NSDebugLLog(@"PDBConfigurationBuilder",
					@"\t\tAdding %@", residueDescription);
				[buildString appendFormat: @"\t\tAdding %@\n", residueDescription];

				[atomsPerResidue addObject: [NSNumber numberWithInt: 
					[[[residue allAtoms] allObjects] count]]];
				[sequence addObject:
					[[residue name] stringByTrimmingCharactersInSet: 
						[NSCharacterSet whitespaceCharacterSet]]];
				atomEnum = [residue allAtoms];
				while((atom = [atomEnum nextObject]))
				{
					[atomNames addObject: [atom name]];
					[coordinateArray addObject: 
						[NSNumber numberWithDouble: [atom x]]];
					[coordinateArray addObject: 
						[NSNumber numberWithDouble: [atom y]]];
					[coordinateArray addObject: 
						[NSNumber numberWithDouble: [atom z]]];
					[matrix extendMatrixWithRow: coordinateArray];
					[coordinateArray removeAllObjects];
				}
			 }
		}
	}	
	
	NSDebugLLog(@"PDBConfigurationBuilder",
			@"\tSection processed:\nSequence %@\nAtoms %@\nAtoms per Residue %@",
			sequence, atomNames, atomsPerResidue);
	[buildString appendFormat: @"\t%d residues\n\t%d atoms\n",
			[sequence count], [atomNames count]];

	
	//It we are dealing with amino acids (residues)
	//replace atomNames with the checked array returned
	//by _verifyAtomNames:forResidues:atomsPerResidue
	if([section isEqual: @"Residues"])
		atomNames = [self _verifyAminoAcidAtomNames: atomNames 
			forResidues: sequence
			atomsPerResidue: atomsPerResidue];

	[result setObject: sequence forKey: @"Sequence"];
	[result setObject: atomNames forKey: @"AtomNames"];
	[result setObject: atomsPerResidue forKey: @"AtomsPerResidue"];

	return result;
}

- (id) _configurationObjectFromPDBStructure: (NSDictionary*) options
{
	int i;
	NSEnumerator *chainEnum;
	NSMutableArray *atomNames, *sequences, *sequence, *atomsPerResidue;
	NSDictionary* result;
	NSString* name;
	id chain, selectedSections, selectedChainOptions;
	NSMutableArray* selectedChains;
	id configuration, matrix;

	selectedChains = [options valueForKey: @"Selection"];

	if([selectedChains count] == 0)
		[NSException raise: @"ULBuildException"
			format: @"No chains were selected"];

	//Cant just print the description since it isnt human readable on mac.
	[buildString appendFormat: @"Selected Chains - %@\n\n", 
		[selectedChains componentsJoinedByString: @", "]];
	
	chainEnum = [structure allChains];
	atomNames = [NSMutableArray array];
	atomsPerResidue = [NSMutableArray array];
	sequences = [NSMutableArray array];
	matrix = [[AdMutableDataMatrix new] autorelease];

	i = 1;
	while((chain = [chainEnum nextObject]))
	{
		//the chain names in the options selections are in the
		//form "Chain $CHAINCODE" - 

		name = [chain name];
		name = [name stringByTrimmingCharactersInSet: 
				[NSCharacterSet whitespaceCharacterSet]];
		if(name == nil || [name isEqual: @""])
			name = [NSString stringWithFormat: @"Chain %d", i];
		else
			name = [NSString stringWithFormat: @"Chain %@", name];

		NSDebugLLog(@"PDBConfigurationBuilder", @"Chain Name = %@", name);

		//check if this chain was selected

		if([selectedChains containsObject: name])
		{	
			[buildString appendFormat: @"Processing %@\n", name];

			selectedChainOptions = [options valueForKey: name];
			selectedSections = [selectedChainOptions
						valueForKey: @"Selection"];
			sequence = [NSMutableArray array];	
			GSPrintf(buildOutput, @"Chain %@ containing %d residues\n", 
						[chain name], [chain countResidues]);
			GSPrintf(buildOutput, @"The sequence is: %@\n\n", [chain get3DSequence]);	
			
			//check residues

			if([selectedSections containsObject: @"Residues"])
			{
				[buildString appendString: @"\tResidues Selected\n"];
				result = [self _processChain: chain 
						section: @"Residues" 
						selection: nil
						atomMatrix: matrix];
				[sequence addObjectsFromArray:
					[result objectForKey: @"Sequence"]];		
				[atomsPerResidue addObjectsFromArray:
					[result objectForKey: @"AtomsPerResidue"]];
				[atomNames addObjectsFromArray:
					[result objectForKey: @"AtomNames"]];
			}

			//check heterogens
			
			if([selectedSections containsObject: @"Heterogens"])
			{	
				[buildString appendString: @"\tHeterogens Selected\n"];
				result = [self _processChain: chain 
						section: @"Heterogens" 
						selection: [selectedChainOptions 
							 valueForKeyPath: @"Heterogens.Selection"]
						atomMatrix: matrix];
				[sequence addObjectsFromArray:
					[result objectForKey: @"Sequence"]];		
				[atomsPerResidue addObjectsFromArray:
					[result objectForKey: @"AtomsPerResidue"]];
				[atomNames addObjectsFromArray:
					[result objectForKey: @"AtomNames"]];
			}	

			//check solvent
			
			if([selectedSections containsObject: @"Solvent"])
			{
				[buildString appendString: @"\tSolvent Selected\n"];
				result = [self _processChain: chain 
						section: @"Solvent" 
						selection: [selectedChainOptions
							 valueForKeyPath: @"Solvent.Selection"]
						atomMatrix: matrix];
				[sequence addObjectsFromArray:
					[result objectForKey: @"Sequence"]];		
				[atomsPerResidue addObjectsFromArray:
					[result objectForKey: @"AtomsPerResidue"]];
				[atomNames addObjectsFromArray:
					[result objectForKey: @"AtomNames"]];
			}	

			if([sequence count] != 0)
				[sequences addObject: sequence];
			
			[buildString appendFormat: @"Completed %@\n\n", name];
		}
		else
			NSDebugLLog(@"PDBConfigurationBuilder", @"%@ was not selected", name);

		i++;
	}

	if([sequences count] == 0)
		[NSException raise: @"ULBuildException"
			format: @"No residues were selected in any chain"];

	NSDebugLLog(@"PDBConfigurationBuilder", @"\nProcess pdb - Building configuration");

	configuration = [NSMutableDictionary dictionaryWithCapacity:1];
	[configuration setObject: matrix forKey: @"Coordinates"];
	[configuration setObject: atomNames forKey: @"AtomNames"];
	[configuration setObject: sequences forKey: @"Sequences"];
	[configuration setObject: atomsPerResidue forKey: @"AtomsPerResidue"];
	if([structure pdbcode] != nil)
		[configuration setObject: [structure pdbcode] forKey: @"SystemName"];
	else
		[configuration setObject: @"None" forKey: @"SystemName"];

	return configuration;
}

/***************

Public Methods

****************/

- (id) init
{
	return [self initWithMoleculeAtPath: nil];
}

- (id) initWithMoleculeAtPath: (NSString*) path
{
	NSString* pathExtension;
	NSString* nameMapFile;
	NSString* temp;

	NSDebugLLog(@"PDBConfigurationBuilder", 
			@"Initialising configuration builder - path is %@", path);

	if((self = [super init]))
	{
		ioManager = [ULIOManager appIOManager];
		if(path != nil)
		{
			pathExtension = [[moleculePath pathExtension] lowercaseString];
			if([[moleculePath pathExtension] isEqual: @"pdb"])
				structure = [self _structureObjectForPDB: path];
			else
				return nil;

			if(structure == nil)
				return nil;

			moleculePath = [path retain];
			[structure retain];
		} 
		else
		{
			moleculePath = nil;
			structure = nil;
		}	

		pluginName =  nil;

		//load pdb name map
		
		nameMapFile = [[[NSBundle bundleForClass: [self class]] resourcePath]
				 stringByAppendingPathComponent: @"pdbNameMap.plist"];	
		nameMap = [NSDictionary dictionaryWithContentsOfFile: nameMapFile];
		[nameMap retain];
		availablePlugins = nil;		
	}		
		
	return self;
}

- (void) dealloc
{
	[availablePlugins release];
	[super dealloc];
}

- (NSMutableDictionary*) buildOptions
{
	int i;
	id chain, name, residue;
	NSMutableDictionary* mainOptions;
	NSString* optionsFile;
	NSEnumerator* chainEnum, *enumerator;
	NSMutableArray* chainSelection, *nameArray ;
	NSMutableDictionary* chainOptions;

	if(structure == nil)
		return nil;

	optionsFile = [[[NSBundle bundleForClass: [self class]]
			 resourcePath]
			 stringByAppendingPathComponent: @"pdbBuilderOptions.plist"];	

	//The options file contains the structure for one chain

	mainOptions = [NSMutableDictionary dictionaryWithContentsOfFile: optionsFile];
	[mainOptions removeObjectForKey: @"ChainA"];

	chainEnum = [structure allChains];
	chainSelection = [NSMutableArray array];
	i = 1;
	while((chain = [chainEnum nextObject]))
	{
		chainOptions = [NSMutableDictionary dictionaryWithContentsOfFile: optionsFile];
		chainOptions = [chainOptions valueForKey: @"ChainA"];
	
		NSDebugLLog(@"PDBConfigurationBuilder", @"Chain options %@", chainOptions);
	
		if([chain countResidues] == 0)
		{	
			[chainOptions removeObjectForKey: @"Residues"];	
			[[chainOptions objectForKey: @"Selection"] removeAllObjects];
		}		

		if([chain countSolvent] != 0)
		{
			nameArray = [NSMutableArray array];
			enumerator = [chain allSolvent];
			while((residue = [enumerator nextObject]))
				[nameArray addObject: [residue description]];

			[chainOptions setValue: nameArray
					forKeyPath: @"Solvent.Choices"];
		}
		else
			[chainOptions removeObjectForKey: @"Solvent"];			
		
		if([chain countHeterogens] != 0)
		{
			nameArray = [NSMutableArray array];
			enumerator = [chain allHeterogens];
			while((residue = [enumerator nextObject]))
				[nameArray addObject: [residue description]];

			[chainOptions setValue: nameArray 
				forKeyPath: @"Heterogens.Choices"];
		}
		else
			[chainOptions removeObjectForKey: @"Heterogens"];			

		name = [chain name];
		name = [name stringByTrimmingCharactersInSet: 
				[NSCharacterSet whitespaceCharacterSet]];
		if(name == nil || [name isEqual: @""])
			name = [NSString stringWithFormat: @"Chain %d", i];
		else
			name = [NSString stringWithFormat: @"Chain %@", name];

		//check that there was a least something in this chain
		//since sometimes libmoltalk invents phantom chains
		if([chainOptions count] > 2)
		{
			[chainSelection addObject: name];
			[mainOptions setObject: chainOptions 
				forKey: name];
		}

		i++;
	}

	//The options display code cant handle muliple default selections.
	//So if we add all the chains here only the first one will appear to be selected
	//in the initial display but they all will be selected when building
	//To avoid this we only select the first one for the moment

	[[mainOptions objectForKey: @"Selection"] addObject: 
		[chainSelection objectAtIndex: 0]];

	return mainOptions;
}

- (id) buildConfiguration: (NSDictionary*) options 
		error: (NSError**) buildError
		userInfo: (NSString**) buildInfo
{
	id configuration, outputPath;
	
	[buildString release];
	buildString = [[NSMutableString stringWithCapacity: 1] retain];
	if(buildInfo != NULL)
		*buildInfo = buildString; 	

	NSDebugLLog(@"PDBConfigurationBuilder", @"Options are %@\n", options);
	NSDebugLLog(@"PDBConfigurationBuilder",  @"Structure object %@", structure);
	
	outputPath = [[NSUserDefaults standardUserDefaults] stringForKey: @"BuildOutput"]; 
	buildOutput = fopen([outputPath cString], "a");

	[buildString appendFormat: @"\nConfiguration File: %@\n", moleculePath];
	configuration = [self _configurationObjectFromPDBStructure: options];

	fclose(buildOutput);
	
	NSDebugLLog(@"PDBConfigurationBuilder", @"%@", configuration);
	NSDebugLLog(@"PDBConfigurationBuilder", @"Printing matrix");
	NSDebugLLog(@"PDBConfigurationBuilder", @"No rows %d", 
		[[configuration objectForKey: @"Coordinates"] numberOfRows]);

	NSDebugLLog(@"PDBConfigurationBuilder", @"Complete");
	[buildString appendString: @"Completed configuration build\n"];

	return configuration;	
}

- (void) setCurrentMolecule: (NSString*) path
{
	NSDebugLLog(@"PDBConfigurationBuilder", @"Path %@", path);
	
	if(path ==  nil)
		[self removeCurrentMolecule];
	else if([[[path pathExtension] lowercaseString] isEqual: @"pdb"])
	{
		//\note change this to structureForCurrentMolecule
		NSDebugLLog(@"PDBConfigurationBuilder", @"Creating stucture for %@", path);
		[structure release];
		structure = [self _structureObjectForPDB: path];
		[structure retain];
		NSDebugLLog(@"PDBConfigurationBuilder", @"Structure created successfully");
		[moleculePath release];
		moleculePath = [path retain]; 
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: [NSString stringWithFormat:
			 @"File at %@ does not have a valid extension", path]];

}

- (void) removeCurrentMolecule
{
	[moleculePath release];
	[structure release];
	moleculePath = nil;
	structure = nil;
}

- (void) writeStructureToFile: (NSString*) path
{
	MTFileStream* fileStream;

	fileStream = [MTFileStream streamToFile: path];
	[structure writePDBToStream: fileStream];
	[fileStream close];
}

- (NSString*) currentMoleculePath
{
	return moleculePath;
}

@end


@implementation PDBConfigurationBuilder (PluginExtensions)

- (void) _findConfigurationPluginsForStructureType:(Class) structureType
{
	BOOL isDir;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSEnumerator *pluginDirEnum;
	NSString *contentObject, *inputObject, *path, *pluginDir;
	NSDictionary *infoDict;
	NSArray* inputInfo;
	NSBundle* bundle;

	//scan the analysis plugins directory and get all the bundle names

	pluginDir = [[ioManager valueForKey: @"applicationDir"]
			stringByAppendingPathComponent: @"Plugins/Configurations"];
	NSDebugLLog(@"PDBConfigurationBuilder", @"Plugin dir %@", pluginDir);		
	availablePlugins = [NSMutableArray new];
	pluginDirEnum = [[fileManager directoryContentsAtPath: pluginDir]
				objectEnumerator];
	while((contentObject = [pluginDirEnum nextObject]))
	{
		NSDebugLLog(@"PDBConfigurationBuilder", @"Content object %@", contentObject);
		path = [pluginDir stringByAppendingPathComponent: contentObject];
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
			infoDict = [NSDictionary dictionaryWithContentsOfFile:
					[path stringByAppendingPathComponent: @"Contents/Resources/Info-gnustep.plist"]];
#endif			
			//inputInfo is an array of dictionaries
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
				//Configuration plugins accept only one input
				if([inputInfo count] != 1)
					NSWarnLog(@"(%@) Configuration plugins can only take one input",
						contentObject);
				else
				{
					//Check the plugins input object matches structureType
					inputObject = [[inputInfo objectAtIndex: 0] 
							objectForKey: @"ULInputObject"];
					if([inputObject isEqual: NSStringFromClass(structureType)])
					{
#ifndef GNUSTEP
						//If we're running on Mac the plugins will have a .bundle
						//extension which we have to remove. 
						contentObject = [contentObject stringByDeletingPathExtension];
#endif						
						[availablePlugins addObject: contentObject];		
					}
					else
						NSWarnLog(@"Required input for plugin %@ (%@) not of the correct type",
							contentObject, inputObject);
				}
			}	
		}	
	}		

	NSDebugLLog(@"PDBConfigurationBuilder", @"Available plugins %@", availablePlugins);
}

- (void) _loadPlugin: (NSString*) name
{	
	//search for the requested plugin in the standard location
	//$(APPLICATIONDIR)/Plugins/Configuration/
	
	NSString* pluginDir;
	NSBundle *pluginBundle;
	Class pluginClass;
	
	if([name isEqual: @"PDBStructureModifier"])
	{
		plugin = [PDBStructureModifier new];
		return;
	}

	pluginDir = [[ioManager applicationDir]
			stringByAppendingPathComponent: @"Plugins/Configurations"];

	NSDebugLLog(@"PDBConfigurationBuilder", @"Plugin dir is %@. Plugin Name is %@", pluginDir, name);

	//add check to see if bundle actually exists
#ifndef GNUSTEP
	name = [name stringByAppendingPathExtension: @"bundle"];
#endif
	pluginBundle = [NSBundle bundleWithPath: 
			[pluginDir stringByAppendingPathComponent: 
			name]];
	if(pluginBundle == nil)
		[NSException raise: NSInvalidArgumentException format: @"Specified plugin does not exist"];	

	NSDebugLLog(@"PDBConfigurationBuilder", @"Plugin Bundle is %@", pluginBundle);
	NSDebugLLog(@"PDBConfigurationBuilder", 
			@"Dynamicaly Loading Plugin from Directory: %@.\n\n", [pluginBundle bundlePath]);

	if((pluginClass = [pluginBundle principalClass]))
	{ 
		NSDebugLLog(@"PDBConfigurationBuilder", 
				@"Found plugin principal class %@.\n", [pluginClass description]);
		plugin = [pluginClass new];

		if(![plugin conformsToProtocol:@protocol(ULConfigurationPlugin)])
			[NSException raise: NSInternalInconsistencyException 
				format: 
				@"Specified plugins (%@) principal class does not conform to ULPDBConfigurationBuilder", 
				[pluginClass description]];	
	}
	else
		[NSException raise: NSInternalInconsistencyException 
			format: @"Specified plugin has no principal class"];

	NSDebugLLog(@"PDBConfigurationBuilder", @"Loaded plugin\n");
}

- (void) applyPlugin: (NSDictionary*) options
{
	id newStructure;
	id newOptions;

	newOptions = [[options mutableCopy] autorelease];
	if(plugin != nil && structure != nil)
	{
		NSDebugLLog(@"PDBConfigurationBuilder", @"Calling plugin %@", plugin);
		newStructure = [plugin manipulateStructure: structure 
				userOptions: newOptions];
		if(![newStructure isKindOfClass: [MTStructure class]])
			[NSException raise: NSInternalInconsistencyException
				format: @"Plugin %@ did not return an object of the correct class (%@)",
				pluginName, [newStructure class]];

		[structure release];
		structure = [newStructure retain];
	}
}

- (void) loadPlugin: (NSString*) name
{
	NSDebugLLog(@"PDBConfigurationBuilder", @"Plugin name is %@", name);

	if(![[self availablePlugins] containsObject: name])
	{
		NSWarnLog(@"No plugin called %@ available", name);
	}
	else
	{
		[self _loadPlugin: name];
		[pluginName release];
		pluginName = [name retain];
	}
}

- (NSString*) currentPlugin
{
	return pluginName;
}

- (NSMutableDictionary*) optionsForPlugin
{
	return [plugin optionsForStructure: structure];
}

- (NSArray*) availablePlugins
{
	//No plugins available if theres no structure
	if(structure == nil)
		return nil;

	if(availablePlugins == nil)
	{
		[self _findConfigurationPluginsForStructureType: [MTStructure class]];
		//Add PDBStructureModifier
		[availablePlugins addObject: @"PDBStructureModifier"];
	}

	return [[availablePlugins copy] autorelease];	
}

- (NSString*) pluginOutputString
{
	return [plugin outputString];
}

@end

@implementation PDBStructureModifier

- (id) init
{
	if(self = [super init])
	{
		outputString = [NSMutableString new];
	}
	
	return self;
}

- (void) dealloc
{
	[outputString release];
	[super dealloc];
}


- (NSMutableDictionary*) optionsForStructure: (id) structure
{
	NSMutableDictionary* mainMenu = [NSMutableDictionary newLeafMenu];

	[mainMenu addMenuItem: @"Enzymix"];
	[mainMenu addMenuItem: @"Charmm"];
	[mainMenu setSelectionMenuType: @"Single"];
	[mainMenu setDefaultSelection: @"Charmm"];
	
	return mainMenu;
}

- (id) manipulateStructure: (id) structure userOptions: (NSMutableDictionary*) options
{
	NSString* forceField;

	forceField = [[options selectedItems] objectAtIndex: 0];
	if([forceField isEqual: @"Enzymix"])
	{
		[self modifyStructureForEnzymix: structure];
	}
	else if([forceField isEqual: @"Charmm"])
	{
		[self modifyStructureForCharmm: structure];
	}
	else
	{
		[outputString setString: @""];
		[outputString appendString: @"No modifications necessary to structure\n"];
	}
	
	return [[structure retain] autorelease];
}

- (NSString*) outputString
{
	return [[outputString copy] autorelease];
}

- (void) modifyStructureForEnzymix: (MTStructure*) aStructure
{
	NSEnumerator* chainEnum, *residueEnum;
	MTChain* chain;
	MTResidue* residue;
	MTAtom* atom;
	
	[outputString setString: @""];
	[outputString appendString: @"Modifing structure for Enzymix\n\n"];
	
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		residueEnum = [chain allResidues];
		while(residue = [residueEnum nextObject])
		{
			if([[residue name] isEqual: @"HIS"])
			{
				atom = [residue getAtomWithName: @"HE2"];
				if(atom != nil)
				{
					[outputString appendFormat: @"\tRenaming HIS %@ in chain %c to HIE\n", 
						   [residue number], [chain code]];
					[residue setName: @"HIE"];
				}
			}
		}
	}
	
	[outputString appendString: @"\nDone\n"];
}

- (void) removeEnzymixStructureModifications: (MTStructure*) aStructure
{
	NSEnumerator* chainEnum, *residueEnum;
	MTChain* chain;
	MTResidue* residue;
	MTAtom* atom;
	
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		residueEnum = [chain allResidues];
		while(residue = [residueEnum nextObject])
		{
			if([[residue name] isEqual: @"HIE"])
			{
				NSDebugLog(@"ModifyStructure", 
					   @"Renaming HIE %@ in chain %c to HIS", 
					   [residue number], [chain code]);
				[residue setName: @"HIS"];
			}
		}
	}
}

- (void) _renumberHeterogensAndSolvent: (MTStructure*) aStructure
{
	int residueNumber, lastResidueNo, firstNonResidueNo;
	NSArray* solventResidues, *heterogenResidues;
	NSMutableArray *array = [NSMutableArray new];
	NSEnumerator* chainEnum, *residueEnum;
	MTChain* chain;
	MTResidue* lastResidue, *residue;

	//Check if the heterogens and solvent in each chain need renumbering
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		lastResidue = [[chain residues] lastObject];
		if(lastResidue == nil)
			continue;
		
		//Make an array containing all solvent and heterogen
		//residues in numerical order	
		solventResidues = [chain solvent];
		heterogenResidues = [chain heterogens];
		
		if(solventResidues != nil)
			[array addObjectsFromArray: solventResidues];
		
		if(heterogenResidues != nil)
			[array addObjectsFromArray: heterogenResidues];
		
		[array sortUsingSelector: @selector(compare:)];
		
		if([array count] == 0)
		{
			continue;
		}
	
		//check if the first solvent/heterogen number if less than or 
		//equal to the last residue in the chain
		lastResidueNo = [[lastResidue number] intValue];
		firstNonResidueNo = [[[array objectAtIndex: 0] number] intValue];
		if(lastResidueNo >= firstNonResidueNo)
		{		
			residueEnum = [array objectEnumerator];
			residueNumber = [[lastResidue number] intValue] + 1;
			while(residue = [residueEnum nextObject])
			{
				[residue setNumber: [NSNumber numberWithInt: residueNumber]];
				residueNumber++;
			}			
		}
		
		[array removeAllObjects];
	}
	
	[array release];								
}

/** 
 * Charmm requires the last residue in a chain to be called CTERM and the first NTERM
 * We have to 
 * 1. Create the residue
 * 2. Move the atoms from the old residue to the new one
 * 3. Renumber the residues if necessary 
 */
- (void) _addCharmmTermini: (MTStructure*) aStructure
{	
	BOOL isModified = NO;
	int residueNumber;
	NSNumber* terminalNumber;
	NSString* atomName;
	NSArray* atomNames;
	NSMutableArray* atoms = [NSMutableArray array], *missingAtoms = [NSMutableArray array];
	NSEnumerator* chainEnum, *residueEnum, *atomEnum, *atomNameEnum;
	MTChain* chain;
	MTResidue* residue, *firstResidue, *terminal;
	MTAtom* atom;
	
	[outputString appendString: @"\n"];
	
	atomNames = [NSArray arrayWithObjects: @"N", @"H1", @"H2", @"H3", @"CA", @"HA", nil];
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		//Get the first residue - if nil is returned there
		//are no residues in this chain.
		if([[[chain allResidues] allObjects] count] == 0)
			continue;
			
		firstResidue = [[[chain allResidues] allObjects] objectAtIndex: 0];
		if(firstResidue == nil)
			continue;
			
		//If its already NTER skip
		if([[firstResidue name] isEqual: @"NTER"])
		{
			[outputString appendString: @"NTER already present"];
			continue;
		}
		
		//Set it has the required atoms
		atomNameEnum = [atomNames objectEnumerator];
		while(atomName = [atomNameEnum nextObject])
		{
			atom = [firstResidue getAtomWithName: atomName];
			if(atom != nil)
				[atoms addObject: atom];
			else
				[missingAtoms addObject: atomName];
		}
		
		if([atoms count] != 6)
		{
			//Set some warning a continue
			[outputString appendFormat: 
				@"Unable to add NTER to chain %c. Required atoms missing (%@)\n", 
				[chain code], [missingAtoms componentsJoinedByString: @", "]];
			
			[atoms removeAllObjects];
			[missingAtoms removeAllObjects];	
			continue;
		}
		
		//Create the NTER residue
		[outputString appendFormat: @"Creating NTERM residue necessary for Charmm in chain %c\n", [chain code]];
		
		residueNumber = [[firstResidue number] intValue];
		if(residueNumber == 0)
		{
			terminalNumber = [NSNumber numberWithInt: 0];
			//Renumber all residues
			residueEnum = [chain allResidues];
			while(residue = [residueEnum nextObject])
			{
				residueNumber = [[residue number] intValue];
				[residue setNumber: [NSNumber numberWithInt: residueNumber + 1]];
			}
		}
		else
			terminalNumber = [NSNumber numberWithInt: residueNumber - 1];

		terminal = [MTResidueFactory createResidueWithNumber: terminalNumber name: @"NTER"];		
		
		//Add the atoms to the new residue and remove from the old
		atomEnum = [atoms objectEnumerator];
		while(atom = [atomEnum nextObject])
		{
			[terminal addAtom: atom];
			[firstResidue removeAtom: atom];
		}
		
		//Add residue to the chain
		[chain addResidue: terminal];
		[chain orderResidues];
		[atoms removeAllObjects];
		
		[outputString appendFormat: 
		 @"Moved atoms (N, H1, H2, H3, CA, HA) of residue %@ (%@) in chain %c to %@ residue\n",
		 [firstResidue number], [firstResidue name], [chain code], [terminal name]];
		 
		isModified = YES;		
	}
	
	[outputString appendString: @"\n"];
	
	atomNames = [NSArray arrayWithObjects: @"C", @"OXT", @"O", nil];
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		//Get the last residue - if nil is returned there
		//are no residues in this chain.
		residue = [[[chain allResidues] allObjects] lastObject];
		if(residue == nil)
			continue;
		
		if([[residue name] isEqual: @"CTER"])
		{
			[outputString appendString: @"CTER already present"];
			continue;
		}
		
		//Set it has the required atoms C, O and OXT
		atomNameEnum = [atomNames objectEnumerator];
		while(atomName = [atomNameEnum nextObject])
		{
			atom = [residue getAtomWithName: atomName];
			if(atom != nil)
				[atoms addObject: atom];
			else
				[missingAtoms addObject: atomName];
		}
		
		if([atoms count] != 3)
		{
			//Set some warning a continue
			[outputString appendFormat: 
				@"Unable to add CTER to chain %c. Required atoms missing %@\n", 
				[chain code], [missingAtoms componentsJoinedByString: @", "]];
				
			[missingAtoms removeAllObjects];	
			continue;
		}
		
		//Create the CTERM residue
		[outputString appendFormat: @"Creating CTERM residue necessary for Charmm in chain %c\n", [chain code]];

		residueNumber = [[residue number] intValue];
		terminalNumber = [NSNumber numberWithInt: residueNumber + 1];
		terminal = [MTResidueFactory createResidueWithNumber: terminalNumber name: @"CTER"];
		
		//Add the atoms to the new residue and remove from the old
		atomEnum = [atoms objectEnumerator];
		while(atom = [atomEnum nextObject])
		{
			[terminal addAtom: atom];
			[residue removeAtom: atom];
		}
		
		//Add residue to the chain
		[chain addResidue: terminal];
		[chain orderResidues];
		[atoms removeAllObjects];
		[missingAtoms removeAllObjects];
		
		[outputString appendFormat: 
			@"Moved atoms (C, O, OXT) of residue %d (%@) in chain %c to %@ residue\n",
			residueNumber, [residue name], [chain code], [terminal name]];	
			
		isModified = YES;
	}
	
	if(isModified)
	{
		[self _renumberHeterogensAndSolvent: aStructure];
	}
}

- (void) modifyStructureForCharmm: (MTStructure*) aStructure
{
	NSEnumerator* chainEnum, *residueEnum;
	MTChain* chain;
	MTResidue* residue;
	MTAtom* atom;
	
	[outputString setString: @""];
	[outputString appendString: @"Modifing structure for Charmm\n\n"];
	
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		residueEnum = [chain allResidues];
		while(residue = [residueEnum nextObject])
		{
			if([[residue name] isEqual: @"HIS"])
			{
				//If it contains HE2 rename to HSE.
				//If it doesnt rename to HSD regardless of
				//whether HD1 is preent or not.
				atom = [residue getAtomWithName: @"HE2"];
				if(atom != nil)
				{
					[outputString appendFormat: @"Renaming HIS %@ in chain %c to HSE\n", 
						   [residue number], [chain code]];
					[residue setName: @"HSE"];
				}
				else
				{
					[outputString appendFormat: @"Renaming HIS %@ in chain %c to HSD\n", 
						   [residue number], [chain code]];
					[residue setName: @"HSD"];
				}
			}
		}
	}
	
	[self _addCharmmTermini: aStructure];
	
	[outputString appendString: @"\nDone\n"];
}

- (void) removeCharmmStructureModifications: (MTStructure*) aStructure
{
	NSString* residueName;
	NSEnumerator* chainEnum, *residueEnum;
	MTChain* chain;
	MTResidue* residue;
	MTAtom* atom;
	
	chainEnum = [aStructure allChains];
	while(chain = [chainEnum nextObject])
	{
		residueEnum = [chain allResidues];
		while(residue = [residueEnum nextObject])
		{
			residueName = [residue name];
			if([residueName isEqual: @"HSD"] || [residueName isEqual: @"HSE"])
			{
				NSDebugLog(@"ModifyStructure", 
					   @"Renaming %@ %d in chain %c to HIS", 
					   residueName, [chain code]);
				[residue setName: @"HIS"];
			}
		}
	}
}

@end




