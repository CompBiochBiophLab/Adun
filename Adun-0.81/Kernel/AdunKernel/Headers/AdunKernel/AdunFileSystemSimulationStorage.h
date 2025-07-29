/*
   Project: AdunCore

   Copyright (C) 200/ Michael Johnston & Jordi Villa-Freixa

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
   License along with this library; if not, write to the 
   Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
#ifndef _ADFILESYSTEM_SIMULATIONSTORAGE_
#define _ADFILESYSTEM_SIMULATIONSTORAGE_
#include <Foundation/Foundation.h>
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdCoreAdditions.h"
#include "AdunKernel/AdunSimulationData.h"

/**
\ingroup coreDataTypes
The available read/write modes for AdFileSystemSimulationStorage objects
The enum values are defined so (mode & AdSimulationStorageAppendMode), 
(mode & AdSimulationStorageReadMode) and (mode & AdSimulationStorageWriteMode) 
are all true when mode is AdSimulationStorageUpdateMode.
*/
typedef enum
{
	AdSimulationStorageWriteMode = 1, /**<  Creates a new store for writing */
	AdSimulationStorageReadMode = 2, /**< Allows reading of the data stored */
	AdSimulationStorageAppendMode = 5, /**< Allows writing to an already existing store */
	AdSimulationStorageUpdateMode = 6, /**< Allows reading and writing to a new or already existing store */
}
AdSimulationStorageMode;

/**
\ingroup coreClasses
Class for managing reading/writing of simulation data on the file system.

Modes - see AdSimulationStorageMode

\todo Expand documentation
\todo Implement AdSimulationStorageUpdateMode
With the implementation of on demand read access to the
frames the previous obstacles to implementing this are no
longer present.
*/

@interface AdFileSystemSimulationStorage: NSObject 
{
	AdSimulationStorageMode storageMode;
	BOOL isAccessible;
	BOOL isTemporary;
	NSFileManager* fileManager;
	NSString* storagePath;
	NSError* accessError;
	NSError* dataError;
	NSString* trajectoryPath;
	NSString* trajectoryInfoPath;
	NSString* energyPath;
	NSString* systemPath;
	NSFileHandle* energyHandle;
	NSFileHandle* trajectoryHandle;
	int cacheLimit;				//Number of frames to be kept in the cache
	int numberTrajectoryCheckpoints;	//Number of trajectory checkpoints in the store
	int numberTopologyCheckpoints;		//Number of topology checkpoints in the store
	NSMutableArray* dataPerCheckpoint;	//Size of each trajectory checkpoint
	id trajectoryInfo;		
	NSMutableArray* trajectoryCache;
	NSMutableArray* cacheFrames;
}
/**
Class method for checking if a valid store exists at location
(which is a path to a directory)
*/
+ (BOOL) storageExistsAtLocation: (NSString*) location;
/**
As initStorageForSimulation:inDirectory:mode:error: except
returns an autoreleased object.
*/
+ (id) storageForSimulation: (AdSimulationData*) simulation
		inDirectory: (NSString*) directory
		mode: (AdSimulationStorageMode) mode
		error: (NSError**) error;
/**
As initSimulationStorageAtPath:mode:error: where the containing directory
of \e path is given by \e directory and the simulation directory
by  AdSimulationData::identification() appened with "_Data".
If \e directory is nil then the path is relative to the current directory.	
*/
- (id) initStorageForSimulation: (AdSimulationData*) simulation
		inDirectory: (NSString*) directory
		mode: (AdSimulationStorageMode) mode
		error: (NSError**) error;
/**
Designated initialiser.
Creates a AdFileSystemSimulationStorage instance for accessing the simulation data
at path. \e mode specfies the mode of access i.e. read, write, read+write. If the
mode is write then the data store is created if it doesnt exist already.
If the stored data cannot be accessed or created upon return anError points
to an NSError object describing the problem.
*/
- (id) initSimulationStorageAtPath: (NSString*) path 
	mode: (AdSimulationStorageMode) mode 
	error: (NSError**) anError;
/**
Creates a AdFileSystemSimulationStorage instance that
provides read only access to the simulation data at path \e path which is stored in the file system.
See initSimulationStorageAtPath:mode:error:() for more.
*/
- (id) initForReadingSimulationDataAtPath: (NSString*) path error: (NSError**) anError;
/**
As initForReadingSimulationDataAtPath:error: with \e anError equal to NULL
*/
- (id) initForReadingSimulationDataAtPath: (NSString*) path;
/**
Returns the unique-id associated with the simulation data
Returns nil if no id can be found. Raises an NSInternalInconsistencyException
if the data store is in AdSimulationStorageWriteMode mode.
*/
- (NSString*) identification;
/**
Returns the amount of data in the store in bytes.
*/
- (unsigned long long) sizeOfStore;
/**
Returns the \e number'th trajectory checkpoint 
Raises an NSRangeException if no such checkpoint exists.
Raises an NSInternalInconsistencyException if 
if the data store is in AdSimulationStorageWriteMode mode.
*/
- (NSData*) trajectoryCheckpoint: (int) number;
/**
Returns the \e number'th topology checkpoint 
Returns nil if no such checkpoint exists.
Raises an NSRangeException if no such checkpoint exists.
Raises an NSInternalInconsistencyException if 
if the data store is in AdSimulationStorageWriteMode mode.
*/
- (NSData*) topologyCheckpoint: (int) number;
/**
Returns the number of trajectoryCheckpoints in the store
\note This is only partially implemented. In read mode this
returns the total number of checkpoints however in write
mode this only returns the number of frames written.
\todo If we implement caching this method will no longer
work. Have to replace
*/
 - (unsigned int) numberTrajectoryCheckpoints;
/**
Returns the number of topologyCheckpoints in the store
*/
 - (unsigned int) numberTopologyCheckpoints;
/**
Returns the energy data for the simulation or
nil if there is none
*/
- (NSData*) energyData;
/**
Returns the system data for the simulation or
nil if there is none.
Raises an NSInternalInconsistencyException if 
if the data store is in AdSimulationStorageWriteMode mode
or if there is no system data present. Note this would 
imply that isAccessible() returns NO and that an accessError()
returns an NSError object.
*/
- (NSData*) systemData;
/**
Returns the frame data for the simulation of
nil if there is none.
Raises an NSInternalInconsistencyException if 
if the data store is in AdSimulationStorageWriteMode mode.
*/
- (NSData*) frameData;
/**
Updates the stores state to reflect any changes
since it was initialised. This method mainly checks to
see if any new trajectory frames have been written.
Only useful with a store in AdSimulationStorageReadMode - does
nothing if the store is in AdSimulationStorageWriteMode.
*/
- (void) update;
/**
Returns YES if the data  is accesible.
NO otherwise. i.e. if the dataStorage
was removed for some reason.
*/
- (BOOL) isAccessible;
/**
Returns an NSError object describing the reason
why the data store cannot be accessed.
*/
- (NSError*) accessError;
/**
If there is any problem with the data in the data store this method
return an NSError object describing it otherwise it returns nil.
This differs from problems leading to an access error since it deals
mainly with corrupted data.
\todo
Expand docs on access & data errors
\note Currently an data error will only be detected after loadData has
been called. In the future errors will be detected on instantiation.
*/
- (NSError*) dataError;
/**
Returns the path to the location where the
data is stored.
*/
- (NSString*) storagePath;
/**
Deletes the stored data. Immediately sets isAccesible to NO
If the data is not accesible returns NO. If the data cannot be
deleted because it is write protected it will also return NO however in this case 
isAccesible will still return YES.
*/
- (BOOL) destroyStoredData;
/**
Sets weather the object should destroy the stored data when
it is released. Value is NO by default.
*/
- (void) setIsTemporary: (BOOL) value;
/**
Returns YES if the object will destroy the stored data when
it is released, NO otherwise.
*/
- (BOOL) isTemporary;
/**
Returns the storage mode.
*/
- (AdSimulationStorageMode) storageMode;
/**
Adds a frame to the stored trajectory.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
*/
- (void) addTrajectoryCheckpoint: (NSData*) data;
/**
Removes the last \e number frames from the stored trajectory.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
Raises an NSRangeException if \e number is greater than the
number of available checkpoints.
*/
- (void) removeTrajectoryCheckpoints: (int) number;
/**
Writes \e data to the storage as energy data.
Any previous energy data is overwritten.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
*/
- (void) setEnergyData: (NSData*) data;
/**
Writes \e data to the storage as frame data.
Any previous frame data is overwritten.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
*/
- (void) setFrameData: (NSData*) data;
/**
Write \e data to the storage as system data.
Any previous system data is overwritten.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
*/
- (void) setSystemData: (NSData*) data;
/**
Adds \e data to the stored topology data.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
*/
- (void) addTopologyCheckpoint: (NSData*) data;
/**
Removes the last \e number frames from the stored topologies.
Raises an NSInternalInconsistencyException exception if the mode is AdSimulationStorageReadMode.
Raises an NSRangeException if \e number is greater than the
number of available checkpoints.
*/
- (void) removeTopologyCheckpoints: (int) number;
/**
Ensures all data is written to the store.
*/
- (void) synchronizeStore;
@end

#endif
