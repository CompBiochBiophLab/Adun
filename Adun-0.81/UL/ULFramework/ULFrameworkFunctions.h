#ifndef _ULFRAMEWORK_FUNCTIONS_
#define _ULFRAMEWORK_FUNCTIONS_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataSource.h>
#include <AdunKernel/AdunContainerDataSource.h>
#include <AdunKernel/AdunSimulationData.h>
#include <MolTalk/MTStructure.h>
/**
\ingroup functions
@{
**/

/**
Checks if \e name, which is a pdb id should be padded
to give the correct alignment for the atom name field in a pdb.
\note The following atoms will always be misaligned 
Calcium, Mercury, Iron, Cadmium. (CA, HG, PB, CD). This is
because they cannot be distinguished from 
Alpha Carbon, Delta Carbon, Gamma Hydrogen & Beta Phosphorous
and the latter always take precedence.
*/
BOOL ULPDBNameRequiresPadding(NSString* aString);
/**
Converts the data source to a moltalk structure object
\note Assumes the data source represents a molecule.
*/
id ULConvertDataSourceToPDBStructure(id dataSource);
/**
As ULConvertDataSourceToPDBStructure but uses \e elementConfiguration 
instead of the data sources configuration.
Raises an NSInvalidArgumentException if \e elementConfiguration does not
have the same number of row as elements in \e dataSource
*/
id ULConvertDataSourceToPDBStructure2(id dataSource, AdDataMatrix* elementConfiguration);
/**
Writes \e structure to \e file.
*/
void ULWriteStructureToFile(id structure, NSString* file);
/**
Converts \e number into a string suitable for use in a
standard time string eg. 12:24:09. 0 is converted to
"00" and numbers less than 10 to "0x". Other numbers
are left as they are.
*/
NSString* ULTimeRepresentationForNumber(int number);
/**
Converts a time interval in seconds to a string with format
"Hours:Minutes:Seconds". Sub second values are not converted.
*/
NSString* ULConvertTimeIntervalToString(NSTimeInterval interval);
/*
Adds the required extra data to the dictionary returned
by ULTemplate::coreRepresentation returning the result. 
This data is required for the dictionary to be used as the input to a simulation.
If \e simulationName is nil it is set to "None".
If \e externalObject is nil an empty externalObjects section
is added.
*/
NSDictionary* ULAddDataToCoreTemplate(NSDictionary* coreTemplate,
	NSString* simulationName,
	NSDictionary* externalObject,
	int energyInterval,
	int configurationInterval,
	int energyDump);
/**
Post an notification of type \e notificationName from \e object whose user info dictionary
contains keys which are understood by ULProgressPanel.
i.e. if a ULProgressPanel is set to observe \e notification from \e object then
it will update its graphical state based in the information in the info dictionary.
\param object The object whose sending the notification.
\param notificationName The name of the notification to send.
\param completedSteps The number of steps completed so far.
\param The total number of steps.
\param The message to display
*/	
void ULSendProgressUpdateNotification(id object, 
	NSString* notificationName, 
	int completedSteps, 
	int totalSteps, 
	NSString* message); 

/**
Returns a new data source creating using the coordinates of \e system at \e checkpoint
of the simulation represented by \e data along with the data source of \e system at that point
i.e. topology and composition changes during the simulation are taken into account.
The input and output references for the new data source are created and a copy of the
ForceField metadata key of \e systems data source is added.
Raises an NSInvalidArgumentException if \e checkpoint is greater than the number of trajectory
checkpoints or less than 0.
Raises an NSInvalidArgumentException if \e system is not one of the systems in \e data.
Does nothing is \e data or \e system are nil.
\todo The check that \e system is in \e data is not implemented. Need to add containsSystem:
method to AdSystemCollection.
*/
AdDataSource* ULCreateDataSourceFromSimulation(AdSimulationData* data, id system, int checkpoint);
/** \@}**/

/**
\ingroup classes
Object wrapping framework functions so they
can be used from a scripting envrionment.
*/
@interface ULFunctionScriptingObject: NSObject
- (id) structureFromDataSource: (id) dataSource;
- (void) writeStructure: (id) structure toFile: (NSString*) file;
- (void) writeStructures: (NSArray*) anArray toFile: (NSString*) file;
- (AdDataSource*) createDataSourceFromCheckpoint: (int) checkpoint
			ofSystem: (id) system
			inSimulation: (AdSimulationData*) data;
- (NSDictionary*) addName: (NSString*) name 
		externalObjects: (NSDictionary*) aDict
		configurationInterval: (int) configurationInterval
		energyInterval: (int) energyInterval
		energyDump: (int) energyDump
		toCoreRepresentation: (NSDictionary*) coreRep;
@end

/**
Category which adds methods for converting AdDataSource instances 
into MTStructure objects.
*/
@interface AdDataSource (MTStructureCreation)
- (MTStructure*) pdbStructure;
- (MTStructure*) pdbStructureWithCoordinates: (AdDataMatrix*) aMatrix;
@end

/**
 Category which adds methods for converting AdContainerDataSource instances 
 into MTStructure objects.
 */
@interface AdContainerDataSource (MTStructureCreation)
- (MTStructure*) pdbStructure;
- (MTStructure*) pdbStructureWithCoordinates: (AdDataMatrix*) aMatrix;
@end


/**
Category which adds somce convenience methods to MTStructure
 */
@interface MTStructure (ULExtensions)
- (void) writeToFile: (NSString*) filename;
@end

#endif
