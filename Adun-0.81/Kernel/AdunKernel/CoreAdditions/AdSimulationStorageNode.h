/*
 *  AdSimulationStorageNode.h
 *  Adun
 *
 *  Created by Michael Johnston on 17/11/2008.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */
#include "Foundation/Foundation.h"
#include "AdunKernel/AdunModelObject.h"
#include "AdunKernel/AdunTrajectory.h"
#include "AdunKernel/AdunSystemCollection.h"
#include "AdunKernel/AdunForceFieldCollection.h"

/**
 AdSimulationData instances represent the output of an Adun simulation (more generally, a set of AdTrajectory objects).
 Each instance is associated with a specific file system directory (essentially the simulation output "file")
 where the simulation data is written and stored - The directory is specified on instantiation.
 
 AdSimulationData provides methods for creating the output directory, accessing it, and adding to its contents.
 Each run of AdunCore has an associated AdSimulationData instance which is used to store the data generated during the program. 
 However AdSimulationData instances can also be created programatically if desired.
 
 \section archiving Archiving
 
 Like any AdModelObject, AdSimulationData instances can be "unarchived" at a later time using the unarchiveFromFile: method of AdModelObject. 
 Note in this case "File" will be a directory path (see below).
 However to archive AdSimulationData objects do not directly use NSKeyedArchiver (e.g. via archiveRootObject:toFile:()).
 Doing so will only archive the simulations metadata as the simulation data is in other files in the data directory.
 Instead use the instances archive() method. 
 This ensures that the object is written to the correct location (the path returned by dataPath()) with the correct name.
 The path returned by dataPath() is also what is passed to unarchiveFromFile:() to recreate the object
 
 \section trajectories Trajectories
 
 AdSimulationData objects contain at least one, and up to any number, of AdTrajectory (or AdMutableTrajectory) objects.
 These can be added as AdTrajectory or AdMutableTrajectory objects.
 The methods for accessing these object are very similar to those of NSArray except using 'trajectory' instead of 'object'
 e.g. trajectoryAtIndex:() instead of objectAtIndex:().
 AdSimulationData instances consider AdMutableTrajectory and AdTrajectory objects that access the same location identical.
 (That is AdTrajectory::location returns the same directory). 
 Unlike NSArray, AdSimulationData cannot contain duplicates of AdTrajectory objects (as determined by the above criteria).
 
 On unarchiving an AdSimulationData instance the trajectories are unarchived as AdTrajectory objects by default (i.e. immutable).
 However using the trajectoryAtIndex:mutability: a mutable version of any trajectory can be obtained.
 Since AdSimulationData determines similarity of AdTrajectory object using the value AdTrajectory::location, methods 
 like indexOfTrajectory:() will return the same value regardless of the mutablity of the passed trajectory.
 
 Each trajectory in the receiver has an associated name providing dictionary like access to them.
 
 \section active Active Trajectory
 
 AdSimulationData is polymorphic to many of the methods of AdTrajectory.
 The trajectory accessed via these methods is called the \e active \e trajectory and is the first by default.
 This can be changed using the switchToTrajectory:() method.
 */ 
@interface AdSimulationDataNode: AdModelObject <NSCoding>
{
	BOOL combinesData;
	NSMutableArray* trajectories;
	NSMutableArray* trajectoryNames;
	NSString* dataPath;
	NSFileManager* fileManager;
	AdTrajectory* activeTrajectory;
}
/**
Class method. As initWithName:location: returning an autoreleased object
*/
+ (id) simulationDataWithName: (NSString*) name location: (NSString*) path;
/**
 As initWithName:location:useIdentification passing NO for identification.
 */
- (id) initWithName: (NSString*) name location: (NSString*) path;
/**
 Creates a new AdSimulationData instance called \e name in the directory given by \e path.
 The name of the created directory depends on the useIdentification: flag.
 If this is NO it will be name.adsim, if YES it will be the objects unique ID appended by adsim.
 
 If a directory already exists with this name an NSInvalidArgumentException is raised.
 If you wish to access a previously created data directory use unarchiveFromFile:() passing
 the path to the simulation data directory.
 */
- (id) initWithName: (NSString*) name location: (NSString*) path useIdentification: (BOOL) value;
/**
 Returns the directory containing the data directory the receiver represents.
 */
- (NSString*) location;
/**
Returns the path to the data directory the receiver represetns
*/
- (NSString*) dataPath;
/**
 Saves the current state of the simulation data to the simulation directory.
 This method causes AdMutableTrajectory::synchToStore: to be called on any AdMutableTrajectory objects
 contained by the receiver.
 \note You should always use this method to archive an AdSimulationData instance.
 */
- (void) archive;
/**
 Returns the number of trajectories contained in the receiver.
 */
- (unsigned int) count;
/**
 Returns an NSArray object containing all the trajectories in the receiver.
 */
- (NSArray*) trajectories;
/**
 Returns the trajectory called \e name. 
 If no trajectory called \e name exists in the receiver this method returns nil.
 */
- (id) trajectoryWithName: (NSString*) key;
/**
 Returns the trajectory at \e index.
 Raises an NSRangeException if \e index is beyond the range of the receiver.
 */
- (id) trajectoryAtIndex: (unsigned int) index;
/**
 As addTrajectoryForSystems:withForceFields:name: passing 'Trajectory%d' for \e name where \e %d is the index of the
 trajectory in the receiver.
 */
- (id) addTrajectoryForSystems: (AdSystemCollection*) systems withForceFields: (AdForceFieldCollection*) forceFields;
/**
 Creates a new AdMutableTrajectory object for \e systems and \e forceFields. 
 The name of the trajectory is given by \e name.
 */
- (void) addTrajectoryForSystems: (AdSystemCollection*) systems withForceFields: (AdForceFieldCollection*) forceFields name: (NSString*) name;
/**
 Makes the trajectory at \e index the active trajectory (see class documentation).
 Raises an NSRangeException if \e index is beyond the range of the receiver.
 */
- (void) switchToTrajectory: (unsigned int) index;
/**
 Makes the first object in the receiver the active trajectory.
 */
- (void) switchToFirst;
/**
 Returns the index of \e aTrajectory in the receiver.
 This is determined by comparing the location of \e aTrajecotry to that
 accessed by each AdTrajectory object contained in the receiver (i.e. the return value of AdTrajectory::location).
 Thus the object at the returned index may be of a different mutability than \e aTrajectory.
 Returns NSNotFound if no simulation accessing the same location is in the receiver.
 */
- (unsigned int) indexOfTrajectory: (AdTrajectory*) aTrajectory;
@end
