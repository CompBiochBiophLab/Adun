#include "ULFramework/ULFrameworkFunctions.h"
#include "ULFramework/PDBConfigurationBuilder.h"
#include <MolTalk/MolTalk.h>

static NSString* alphabet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz";

/**
mkChain is a private method of structure.
However its useful so to stop the compiler
complaining add the method as using a category
*/
@interface MTStructure (ChainCreation)
- (MTChain*) mkChain: (id) number;
@end

BOOL ULPDBNameRequiresPadding(NSString* aString)
{
	BOOL pad = NO;
	unichar initialCharacter;
	NSString *possibleID;
	NSCharacterSet* characterSet;
	//C dosent allow initialisation of global vars using functions 
	//So I have to declare this here
 	NSArray* noPadElemements = [[NSArray alloc] initWithObjects: 
					@"CU", @"CR",@"CO",@"OH",@"NI",@"SN",
					@"SE",@"MG",@"MN",@"ZN",@"PB", @"NA", nil];

	/*
	 * FIXME:
	 * Moltalk requires pdbName to be aligned properly
	 * i.e. with/without an initial blank space
	 * in order to deduce the element type of the atom.
	 * However we do not know the alignment. 
	 * The following problem arises - Do the first two letters
	 * of a name refer to 
	 * 1) An element - no pad
	 * 2) An element + a position label - one space pad.
	 * e.g. the most common possible errors
	 * 	"CA" (calcium) and " CA" (Alpha carbon)
	 * 	"HG" (mercury) and " HG" (Gamma Hydrogen)
	 * 	"CD" (cadmium) and " CD" (Delta carbon)
	 * 	"PB" (iron)    and " PB" (Beta phosphorous)
	 * note: alpha nitrogen is always just "N" so it can
	 * be confused with sodium (NA)
	 *
	 * Also an element with a single character identifier
	 * will not be identified if its not padded.
	 *
	 * In general
	 * if a name starts with a number - no pad
	 * If a name is four characters long - no pad
	 * If a name is one characeter long - pad
	 * If the name starts with 
	 * (CH, CR, CO, OH, NI, SN, SE, MG, MN, ZN, PB, NA) - no pad
	 * If the name starts with "CA", "HG", "CD" - pad
	 * Everything else - pad
	 */

	if([aString length] == 1)
		pad = YES;
	else if([aString length] == 4)
		pad = NO;
	else
	{
		possibleID = [aString substringToIndex: 2];
		initialCharacter = [aString characterAtIndex: 0];
		characterSet = [NSCharacterSet uppercaseLetterCharacterSet];   

		//Check if number
		if(![characterSet characterIsMember: initialCharacter])
			pad = NO;
		else if([noPadElemements containsObject: possibleID])
			pad = NO;
		else
			pad = YES;
	}

	[noPadElemements release];

	return pad;
}


id ULConvertDataSourceToPDBStructure2(id dataSource, AdDataMatrix* elementConfiguration)
{
	int startAtom, endAtom, residueCount, i;
	const char* name;
	MTStructure* structure = [MTStructureFactory newStructure];
	AdMatrix* coordinatesMatrix;
	AdDataMatrix* groupProperties, *elementProperties;
	NSEnumerator *residueEnum;
	NSNumber *currentChain;
	NSString* pdbName;
	NSArray *residue;
	NSAutoreleasePool* pool;
	id chain, newResidue, newAtom, number;
	
	if([elementConfiguration numberOfRows] != [dataSource numberOfElements])
		[NSException raise: NSInvalidArgumentException
			format: @"Data source and configuration matrix have different dimensions"];
	
	pool = [NSAutoreleasePool new];
	groupProperties = [dataSource groupProperties];
	residueEnum = [groupProperties rowEnumerator];
	elementProperties = [dataSource elementProperties];
	//C matrix for speed and memory issues
	coordinatesMatrix = [elementConfiguration cRepresentation];

	chain = nil;
	residueCount = startAtom = endAtom = 0;
	while((residue = [residueEnum nextObject]))
	{
		if(chain == nil)
		{
			currentChain = [residue objectAtIndex: 1];
			number = [NSNumber numberWithChar: 
					[alphabet characterAtIndex: [currentChain intValue]]];
			chain = [structure mkChain: number];
		}
		else if(![[residue objectAtIndex: 1] isEqualToNumber: currentChain])
		{
			currentChain = [residue objectAtIndex: 1];
			number = [NSNumber numberWithChar: 
					[alphabet characterAtIndex: [currentChain intValue]]];
			chain = [structure mkChain: number];
		}
			
		name = [[residue objectAtIndex: 0]
				cStringUsingEncoding: NSUTF8StringEncoding];
		newResidue = [MTResidueFactory newResidueWithNumber: residueCount
				name: (char*)name];
				
		//Add atoms to the residue		
		startAtom = endAtom;
		endAtom += [[residue objectAtIndex: 2] intValue]; 
	
		for(i=startAtom; i<endAtom; i++)
		{
			pdbName = [elementProperties elementAtRow: i
					ofColumnWithHeader: @"PDBName"];
		
			if(ULPDBNameRequiresPadding(pdbName))
				pdbName = [NSString stringWithFormat: @" %@", pdbName];

			name = [pdbName cStringUsingEncoding: NSUTF8StringEncoding];
			newAtom = [MTAtom atomWithNumber: i
					name: (char*)name
					X: coordinatesMatrix->matrix[i][0]
					Y: coordinatesMatrix->matrix[i][1]
					Z: coordinatesMatrix->matrix[i][2]
					B: 0.0];
			[newResidue addAtom: newAtom];
		}

		[chain addResidue: newResidue];
		residueCount++;
	}

	//Remove the force-field modifications e.g. the renaming of Histidines etc.
	if([[NSUserDefaults standardUserDefaults] boolForKey: @"CreateUnmodifiedPDBStructures"])
	{
		NSString* forceField;
		PDBStructureModifier* structureModifier;
	
		structureModifier = [[PDBStructureModifier new] autorelease];
		forceField = [dataSource valueForMetadataKey: @"ForceField"];
		if([forceField isEqual: @"Enzymix"])
		{
			[structureModifier removeEnzymixStructureModifications: structure];
		}
		else if([forceField isEqual: @"Charmm27"])
		{
			[structureModifier removeCharmmStructureModifications: structure];
		}
	}

	[[AdMemoryManager appMemoryManager] 
		freeMatrix: coordinatesMatrix];
	[pool release];
	
	return structure;
}

id ULConvertDataSourceToPDBStructure(id dataSource)
{
	return ULConvertDataSourceToPDBStructure2(dataSource, [dataSource elementConfiguration]); 
}

void ULWriteStructureToFile(id structure, NSString* file)
{
	MTFileStream* fileStream;
	
	fileStream = [MTFileStream streamToFile: file];
	[structure writePDBToStream: fileStream];
	[fileStream close];
}	

NSString* ULTimeRepresentationForNumber(int number)
{
	if(number == 0)
		return @"00";
	else if(number < 10)
		return [NSString stringWithFormat: @"0%d", number];
	else
		return [NSString stringWithFormat: @"%d", number];
}

NSString* ULConvertTimeIntervalToString(NSTimeInterval interval)
{
	NSString* hourSt, *minuteSt, *secondSt;
	int hour, minute, second;

	hour = (int)floor(interval/3600);
	interval -= hour*3600;
	minute = (int)floor(interval/60);
	interval -= minute*60;
	second = ceil(interval);
	hourSt = ULTimeRepresentationForNumber(hour);
	minuteSt = ULTimeRepresentationForNumber(minute);
	secondSt = ULTimeRepresentationForNumber(second);
	return [NSString stringWithFormat: @"%@:%@:%@", 
		hourSt, minuteSt, secondSt];
}

void ULSendProgressUpdateNotification(id object, NSString* notificationName, int completedSteps, int totalSteps, NSString* message) 
{
	NSMutableDictionary* notificationInfo;
	
	notificationInfo = [NSMutableDictionary new];
	[notificationInfo setObject: [NSNumber numberWithDouble: totalSteps]
			     forKey: @"ULProgressOperationTotalSteps"];
	[notificationInfo setObject: message
			     forKey: @"ULProgressOperationInfoString"];
	[notificationInfo setObject: [NSNumber numberWithDouble: completedSteps]
			     forKey: @"ULProgressOperationCompletedSteps"];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: notificationName
		object: object
		userInfo: notificationInfo];
	[notificationInfo release];
}

NSDictionary* ULAddDataToCoreTemplate(NSDictionary* coreTemplate,
		NSString* simulationName,
		NSDictionary* externalObjects,
		int energyInterval,
		int configurationInterval,
		int energyDump)
{
	NSDictionary* checkpoint, *metadata, *newTemplate;
	NSMutableDictionary *templateCopy;

	templateCopy = [coreTemplate mutableCopy];

	checkpoint = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt: energyInterval], @"energy",
			[NSNumber numberWithInt: configurationInterval], @"configuration",
			[NSNumber numberWithInt: energyDump], @"energyDump", nil];
	if(simulationName == nil)		
		simulationName = @"None";
	
	metadata = [NSDictionary dictionaryWithObject: simulationName
			forKey: @"simulationName"];
			
	[templateCopy setObject: checkpoint
		forKey: @"checkpoint"];
	[templateCopy setObject: metadata
		forKey: @"metadata"];
	if(externalObjects == nil)	
		externalObjects = [NSDictionary dictionary];

	[templateCopy setObject: externalObjects
		forKey: @"externalObjects"];

	newTemplate = [[templateCopy copy] autorelease];
	[templateCopy release];
	return newTemplate;
}

AdDataSource* ULCreateDataSourceFromSimulation(AdSimulationData* data, id system, int checkpoint)
{
	int frame, numberOfCheckpoints;
	NSString* systemName, *forceField;
	id memento, dataSource;

	numberOfCheckpoints = [data numberTrajectoryCheckpoints];
	systemName = [system systemName];

	if(checkpoint >= numberOfCheckpoints)
		[NSException raise: NSInvalidArgumentException
			format: @"Checkpoint %d out of range %d", checkpoint, numberOfCheckpoints];
	
	if(checkpoint < 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Checkpoint %d out of range %d", checkpoint, numberOfCheckpoints];
	//Extract
	memento = [data mementoForSystem: system
			inTrajectoryCheckpoint: checkpoint];
	//Handle data source topology changes.
	if([data numberTopologyCheckpoints] > 0)
	{
		//There was a change 
		frame = [data frameForTrajectoryCheckpoint: checkpoint];
		//We want to check the current frame aswell
		dataSource = [data lastRecordedDataSourceForSystem: system
				inRange: NSMakeRange(0,frame+1)];
		if(dataSource == nil)
			//There was no change up to this checkpoint
			dataSource = [system dataSource];
	}
	else
		dataSource = [system dataSource];
	
	//Take account of the force field used since it will be lost
	//during the mutable copying
	
	forceField = [dataSource valueForMetadataKey: @"ForceField"];

	/*
	 * We simply want to modify the dataSource coordinates
	 * However it may be immutable - if it is we have to
	 * make a mutable copy.
	 * Note: We should make AdunCore use mutable data sources
	 * by default
	 */
	if([dataSource isMemberOfClass: [AdDataSource class]])
		dataSource = [[dataSource mutableCopy] autorelease];

	[dataSource setElementConfiguration: 
		[memento dataMatrixWithName: @"Coordinates"]];

	//Can only save immutable objects to the database
	dataSource = [[dataSource copy] autorelease];
	[dataSource updateMetadata:
		[NSDictionary dictionaryWithObject: systemName
			forKey: @"Name"]
		inDomains: AdUserMetadataDomain];	
	
	//Create refs
	[dataSource addInputReferenceToObject: data];
	[dataSource setValue: forceField
		forMetadataKey: @"ForceField"
		inDomain: AdUserMetadataDomain];
	[data addOutputReferenceToObject: dataSource];

	return dataSource;
}

@implementation ULFunctionScriptingObject

- (id) structureFromDataSource: (id) dataSource
{
	return ULConvertDataSourceToPDBStructure(dataSource);
}

- (void) writeStructure: (id) structure toFile: (NSString*) file
{
	ULWriteStructureToFile(structure, file);
}

- (void) writeStructures: (NSArray*) anArray toFile: (NSString*) file
{
	MTFileStream* fileStream;
	NSEnumerator* structureEnum;
	id structure;

	structureEnum = [anArray objectEnumerator];
	fileStream = [MTFileStream streamToFile: file];
	//NOTE: Fixed a bug in writePDBToStream
	//where it was closing the stream unexpectedly
	//inside the method. This may not be fixed
	//in future MolTalk versions so it should be checked for.
	while((structure = [structureEnum nextObject]))
		[structure writePDBToStream: fileStream];

	[fileStream close];
}

- (NSDictionary*) addName: (NSString*) name 
		externalObjects: (NSDictionary*) aDict
		configurationInterval: (int) configurationInterval
		energyInterval: (int) energyInterval
		energyDump: (int) energyDump
		toCoreRepresentation: (NSDictionary*) coreRep
{
	return ULAddDataToCoreTemplate(coreRep,
		name,
		aDict,
		energyInterval,
		configurationInterval,
		energyDump);
}

- (AdDataSource*) createDataSourceFromCheckpoint: (int) checkpoint
			ofSystem: (id) system
			inSimulation: (AdSimulationData*) data
{
	return ULCreateDataSourceFromSimulation(data, system, checkpoint);
}

@end

//Contains extra convenience methods for AdDataSource
@implementation AdDataSource (MTStructureCreation)

- (MTStructure*) pdbStructure
{
	return ULConvertDataSourceToPDBStructure(self);
}

- (MTStructure*) pdbStructureWithCoordinates: (AdDataMatrix*) aMatrix
{
	return ULConvertDataSourceToPDBStructure2(self, aMatrix);
}

@end

//Contains extra convenience methods for AdContainerDataSource
@implementation AdContainerDataSource (MTStructureCreation)

- (MTStructure*) pdbStructure
{
	return ULConvertDataSourceToPDBStructure(self);
}

- (MTStructure*) pdbStructureWithCoordinates: (AdDataMatrix*) aMatrix
{
	return ULConvertDataSourceToPDBStructure2(self, aMatrix);
}

@end

//Contains extra convenience methods for MTStructure
@implementation MTStructure (ULExtensions)

- (void) writeToFile: (NSString*) filename
{
	ULWriteStructureToFile(self, filename);
}

@end


