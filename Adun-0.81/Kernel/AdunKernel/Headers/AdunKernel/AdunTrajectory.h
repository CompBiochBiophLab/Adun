/*
 Project:  AdunCore
 
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

#ifndef _AdTrajectory_H_
#define _AdTrajectory_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDefinitions.h>
#include <AdunKernel/AdunModelObject.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <AdunKernel/AdunDataSet.h>
#include <AdunKernel/AdunSystem.h>
#include <AdunKernel/AdunSystemCollection.h>
#include <AdunKernel/AdunForceFieldCollection.h>
#include <AdunKernel/AdunInteractionSystem.h>
#include <AdunKernel/AdunFileSystemSimulationStorage.h>

/**
 \ingroup coreClasses
 Class representing the output of a configuration generation process, for example a simulation. 
 Its main attributes are
 
 - An AdSystemCollection object containing the systems that were simulated.
 - The set of configurations recorded for each system.
 - A set of AdDataMatrix objects containing the energies of the configurations - one for each system.
 - One or more AdDataSource objects representing topology changes that occured. 
 
 More information on these attributes can be found in the \ref contents section.
 
 AdTrajectory obtains its data from a *.traj directory created previously by an AdMutableTrajectory instance. 
 The location of the directory must be provided on creation.
 An instance of AdTrajectory is immutable: that is its data is established when it's created and you cannot modify it using the instance afterward. 
 Using the AdTrajectory subclass AdMutableTrajectory you can add or delete data from the trajectory.
 
 Note that the contents of the *.traj directory could change indirectly because an AdMutableTrajectory instance is working on it.
 The refresh() method provides a means to refresh the data provided by the receiver to handle this case.
  
 \section contents AdTrajectory Contents
 
 An AdTrajectory instance contains a collection of systems and information collected about them during the course of a simulation.
 The collected information is divided into frames - each frame usually corresponding to an iteration of the simulator main loop
 - and all information within a frame is related. 
 The information collected is divided into three types
 
 - Dynamic (Trajectory)
 - Topological
 - Energetic
 
 It is important to note that all of the above may not be collected at each frame.
 Also each quantity may only be recorded for a subset of the systems.
 
 The trajectory data is stored as AdSystem dynamic information in each frame is a set of memento objects - one for
 each system whose state was recorded at that frame.
 The energy data consists of a AdDataSet instance with one AdDataMatrix for
 each system whose name is the name of the corresponding system. Each row
 of a data matrix corresponds to a frame where the energies of that system were recorded.
 The topology data is one or more AdDataSource instances reflecting the topolgy of the
 system at that frame. Since the topology usually doesnt change often this data is only
 recorded at the moment a change takes place.
*/

@interface AdTrajectory: NSObject
{
	BOOL checkDataStorageIdentification;
	unsigned int numberEnergyCheckpoints;
	AdDataSet* stateData;
	id systemCollection;
	id dataStorage;
	id frames;
}
+ (id) trajectoryFromLocation: (NSString*) location;
+ (id) trajectoryFromLocation: (NSString*) location error: (NSError**) error;
/**
Designate initialiser.
Returns an AdTrajectory object for reading the trajectory data at \e path.
*/
- (id) initWithLocation: (NSString*) path error: (NSError**) error;
/**
Returns the location of the data the receiver is acessing.
*/
- (NSString*) location;
/**
Returns the underlying AdFileSystemSimulationStorage instance used by the receiver.
*/
- (id) dataStorage;
/**
 Returns a data set containing the energies recorded for each system 
 during the simulation
 */
- (AdDataSet*) energies;
/**
 Returns the AdSystemCollection instance which contains all the AdSystems
 objects which made up the trajectory.
 */
- (AdSystemCollection*) systemCollection;
/**
Convenience method - equivalent to [[trajectory systemCollection] allSystems]
*/
- (NSArray*) systems;
/**
 Returns a data set containing information on what was recorded
 in each frame.
 */
- (AdDataSet*) frames;
/**
 Returns the memento for \e system stored in the \e number'th trajectory checkpoint
 or nil if there is none. 
 If no such checkpoint exists  an NSInvalidArgumentException is raised.
 */
- (id) mementoForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number;
/**
 Returns the data source for \e system stored in the \e number'th topology checkpoint
 or nil if there is none.
 If no such checkpoint exists  an NSInvalidArgumentException is raised.
 */
- (id) dataSourceForSystem: (id) system inTopologyCheckpoint: (unsigned int) number;
/**
Returns the coordinates for \e system in trajectory checkpoint \e number as an AdDataMatrix instance.
*/
- (AdDataMatrix*) coordinatesForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number;
/**
Retreives the coordinates for \e system in trajectory checkpoint \e number and places them in \e buffer.
\e buffer must be the correct size. This is not checked by this method so be careful of segmentation faults.
*/
- (void) coordinatesForSystem: (id) system inTrajectoryCheckpoint: (unsigned int) number usingBuffer: (AdMatrix*) buffer;
/**
Compares the checkpoints of the system \e ourSystem in the receiver to those of \e aSystem
in \e aTrajectory. The range of frames to be compared are specified using \e range.

This method is only useful if both systems represent the same molecule.
For two frames to be equal the difference between the coordinates of the atoms must be
less than 1E-12.

If the systems do not have the same number of atoms an NSInvalidArgumentException is raised.
If the specified range exceeds the number of frames in the receiver or in aTrajectory an
NSInvalidArgumentException is raised.
*/
- (BOOL) compareCheckpointsForSystem: (id) aSystem 
		inTrajectory: (AdTrajectory*) aTrajectory 
		toSystem: (id) ourSystem 
		range: (NSRange) range;
/**
 Returns the number of trajectory checkpoints available.
 */
- (unsigned int) numberTrajectoryCheckpoints;
/**
 Returns the number of topology checkpoints available.
 */
- (unsigned int) numberTopologyCheckpoints;
/**
 Returns the total number of frames recorded. 
 */
- (unsigned int) numberOfFrames;
/**
 Returns the frame when the \e number'th topology checkpoint was recorded.
 If no such checkpoint exists  an NSInvalidArgumentException is raised.
 */
- (unsigned int) frameForTopologyCheckpoint: (unsigned int) number;
/**
 Returns the frame when the \e number'th energy checkpoint was recorded.
 If no such checkpoint exists  an NSInvalidArgumentException is raised.
 */
- (unsigned int) frameForEnergyCheckpoint: (unsigned int) number;
/**
 Returns the frame when the \e number'th trajectory checkpoint was recorded.
 If no such checkpoint exists  an NSInvalidArgumentException is raised.
 */
- (unsigned int) frameForTrajectoryCheckpoint: (unsigned int) number;
/**
 Returns the most recent data source recorded for \e system in the
 range of frames specified by \e aRange
 */
- (id) lastRecordedDataSourceForSystem: (id) system inRange: (NSRange) aRange;
/**
 Returns an array describing what data was recorded in frame \e frame
 The array can contain the following entries - "Trajectory", "Topology", "Energy"
*/
- (NSArray*) dataRecordedInFrame: (unsigned int) frame;
/**
Force the receiver to re-read the trajectory data
*/
- (void) update;
/**
 Deprecated: use location() instead.
*/
- (NSString*) dataPath;
@end


@interface AdMutableTrajectory: NSObject
{
	BOOL needsUpdate;
	BOOL frameOpen;
	BOOL trajectoryCheckpoint;
	BOOL topologyCheckpoint;
	BOOL energyCheckpoint;
	int lastFrame;
	NSMutableData* trajectoryData;		//!< The current trajectory checkpoint data
	NSMutableDictionary* energyData;	//!< The current energy checkpoint data
	NSString* iterationHeader;
	NSNumber* iterationValue;
	NSMutableDictionary* topologyData; //!< The current topology checkpoint data
	AdForceFieldCollection* forceFieldCollection;
	AdSystemCollection* systemCollection;
	AdDataSet* stateData;
	AdMutableDataMatrix* frames;
	AdTrajectory* trajectoryReader;
	id dataStorage;
}
+ (id) trajectoryFromLocation: (NSString*) location;
+ (id) trajectoryFromLocation: (NSString*) location error: (NSError**) error;
/**
Forthcoming
 */
- (id) initWithLocation: (NSString*) path error: (NSError**) error;
/**
 Designated initialiser.
 Initialises a AdTrajectory object which can write
 the state of \e aSystemCollection to \e location. */
- (id) initWithLocation: (id) aDataStore
		   systems: (AdSystemCollection*) aSystemCollection
	       forceFields: (AdForceFieldCollection*) aForceFieldCollection
	   iterationHeader: (NSString*) aString
	   error: (NSError**) error;
/**
 On addition of a new system to the collection this method must be called
 so the reciever can prepare to collect the new energy data.
 \todo Not implemented
 */
- (void) updateSystems;
/**
 Sets the title of the iteration column in the state matrices
 e.g. Time. Defaults to @"Iteration"
 */
- (void) setIterationHeader: (NSString*) iterationHeader;
/**
 Opens a new frame for writing. Increments the frame count.
 \e iterationNumber will be used as the value for the column 
 defined by \e iterationHeader in the state matrices for any energy
 checkpoints.
 */
- (void) openFrame: (NSNumber*) iterationNumber;
/**
 Returns YES if a frame is currently open for writing. NO otherwise.
 */
- (BOOL) isOpenFrame;
/**
 Closes the current frame for writing.
 */
- (void) closeFrame;
/**
 Returns the number of the last opened frame.
 Returns -1 if no frame has been opened.
 */
- (int)  lastFrame;
/**
 Returns the frame that contains the last energy checkpoint
 */
- (unsigned int) lastEnergyCheckpoint;
/**
 Returns the frame that contains the last trajectory checkpoint
 */
- (unsigned int) lastTrajectoryCheckpoint;
/**
 Returns the frame that contains the last topology checkpoint
 */
- (unsigned int) lastTopologyCheckpoint;
/**
 Returns the iteration number supplied for the last frame.
 */
- (NSNumber*) lastIterationNumber;
/**
 Adds a checkpoint of the topology of all the systems in 
 the system collection.
 */
- (void) addTopologyCheckpoint;
/**
 Adds a checkpoint of the topology of \e system.
 */
- (void) addTopologyCheckpointForSystem: (id) aSystem;
/**
 Adds a checkpoint of the state of all the systems in the
 system collection. What exactly is stored depends on the
 value of each systems capture mask (see AdSystem::captureMask())
 */
- (void) addTrajectoryCheckpoint;
/**
 Adds a row detailing the current energies to each systems
 state matrix.
 */
- (void) addEnergyCheckpoint;
/**
 Deletes all information stored since frame \e value.
 Raises an NSRangeException if \e value is greater than
 the number of frames.
 */
- (void) rollBackToFrame: (unsigned int) value;
/**
 Writes all data held in memory to the store.
 */
- (void) synchToStore;
/**
 Returns the data storage instance used by the object to access the 
 simulation data.
 */
- (id) dataStorage;
@end

#endif
