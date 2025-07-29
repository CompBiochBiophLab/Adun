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

#ifndef _ADSIMULATIONDATA_H_
#define _ADSIMULATIONDATA_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDefinitions.h>
#include <AdunKernel/AdunModelObject.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <AdunKernel/AdunDataSet.h>
#include <AdunKernel/AdunSystem.h>
#include <AdunKernel/AdunSystemCollection.h>
#include <AdunKernel/AdunForceFieldCollection.h>
#include <AdunKernel/AdunInteractionSystem.h>

/**
\ingroup coreClasses
Class representing AdunCore's simulation output and the metadata associated with it.
However since the location of the output data is volatile AdSimulationData objects 
require an AdFileSystemSimulationStorage instance (or an object polymorphic to it),
to access it (see setDataStorage:()).

AdSimulationData conforms to NSCoding but only supports keyed coding.

\section contents AdSimulationData Contents

An AdSimulationData instance contains a collection of systems and
information collected about them during the course of a simulation.
The collected information is divided into frames - each frame usually
corresponding to an iteration of the simulator main loop - and
all information within a frame is related. 
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

\section creation AdSimulationData Creation

When AdunCore is run an AdSimulationData instance is created to represent its data. 
Independantly the core creates a storage location for the simulation data
associating the AdSimulationData instances unique id with it (see AdModelObject documentation for more).
The AdSimulationData instance accesses this data store through an AdFileSystemSimulationStorage
object which the core provides.
\section access Accessing Simulation Data When a Simulation has Ended.

The simulation output directory created by AdunCore contains the archived
AdSimulationData instance and a directory containing the simulation data.
The name of the file containing the archived AdSimulationData instance is the same
as its unique ID. The name of the directory containing the simulation data
is this name postfixed by "_Data".

To access the data perform the following steps -

- Unarchive the AdSimulationData instance
- Create an AdFileSystemSimulationStorage object initialising it with the path
to the simulation data directory
- Use the AdSimulationData instances setDataStorage:() method to give it access to
the data.
- Call loadData() to unarchive the data in the directory.

You can then access the simulation data through the AdSimulationData objects methods.

\section orphan Orphaned Data

When this object is set the AdSimulationData instance checks if the id associated with the store is the same
as its own (as long as checkDataStorageIdentification() is YES).

\note frames and checkpoints are numbered from 0 e.g. The number of the last trajectory checkpoint is one less
than the number of trajectory checkpoints.

\todo Proper integration with AdModelObject
\todo Update handling of accessError and implementing handling of dataError.
If any of these errors exist we should set the description to indicate them (not raise an exception).
Also requires update of methods to handle the case that there was an error.
*/

@interface AdSimulationData: AdModelObject
{
	BOOL checkDataStorageIdentification;
	unsigned int numberEnergyCheckpoints;
	AdDataSet* stateData;
	id systemCollection;
	id dataStorage;
	id frames;
}
/**
Convenience method for recreating a simulation data object from an archive.
\e filename is the loaction of the archive - if the archive does not contain an AdSimulationData
object an NSInvalidArgumentException is raised.
If \e flag is YES the method attempts to access the simulations data storage directory.
The location of the directory is assumed to be in the same directory as \e filename. 
The name of the data directory is determined based on the assumptions described
by AdFileSystemSimulationStorage::storageForSimulation:inDirectory:mode:error:.
\e error is a pointer to an \e error object. 
If not NULL this will contain an NSError object on return if there was a problem accessing the data store.
*/
+ (id) simulationFromArchive: (NSString*) filename loadData: (BOOL) flag error: (NSError**) error;
/**
As simulationFromArchive:loadData:error: passing NULL for \e error
*/
+ (id) simulationFromArchive: (NSString*) filename loadData: (BOOL) flag;
/**
As initWithName:() but with name set to "Unknown".
*/
- (id) init;
/**
Designated initialiser.
Returns an newly initialised AdSimulationData instance called \e name
*/
- (id) initWithName: (NSString*) name; 
/**
Accesses the instances data store and extracts the simulation data.
*/
- (void) loadData;
/**
Returns the data storage instance used by the object to access the 
simulation data.
*/
- (id) dataStorage;
/**
Sets the data storage object the instance will use to access the simulation
data.
*/
- (void) setDataStorage: (id) object;
/**
Returns a data set containing the energies recorded for each system 
during the simulation
*/
- (AdDataSet*) energies;
/**
Returns the AdSystemCollection instance which contains all the AdSystems
objects which made up the simulation.
*/
- (AdSystemCollection*) systemCollection;
/**
Returns a data matrix containing information on what was recorded
in each frame.
*/
- (AdDataMatrix*) frames;
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
Returns the number of trajectory checkpoints available.
*/
- (unsigned int) numberTrajectoryCheckpoints;
/**
Returns the number of topology checkpoints available.
*/
- (unsigned int) numberTopologyCheckpoints;
/**
Returns the total number of frames recorded. 
\note for pre 0.71 simulation data this method returns 0
*/
- (unsigned int) numberOfFrames;
/**
Returns the frame when the \e number'th topology checkpoint was recorded.
If no such checkpoint exists  an NSInvalidArgumentException is raised.
\note for pre 0.71 simulation data this method returns 0
*/
- (unsigned int) frameForTopologyCheckpoint: (unsigned int) number;
/**
Returns the frame when the \e number'th energy checkpoint was recorded.
If no such checkpoint exists  an NSInvalidArgumentException is raised.
\note for pre 0.71 simulation data this method returns 0
*/
- (unsigned int) frameForEnergyCheckpoint: (unsigned int) number;
/**
Returns the frame when the \e number'th trajectory checkpoint was recorded.
If no such checkpoint exists  an NSInvalidArgumentException is raised.
\note for pre 0.71 simulation data this method returns 0
*/
- (unsigned int) frameForTrajectoryCheckpoint: (unsigned int) number;
/**
Returns the most recent data source recorded for \e system in the
range of frames specified by \e aRange
\note for pre 0.71 simulation data this method returns nil
*/
- (id) lastRecordedDataSourceForSystem: (id) system inRange: (NSRange) aRange;
/**
Returns an array describing what data was recorded in frame \e frame
The array can contain the following entries - "Trajectory", "Topology", "Energy"
\note for pre 0.71 simulation data this method returns nil
*/
- (NSArray*) dataRecordedInFrame: (unsigned int) frame;
/**
\note Deprecated
Returns the memento for \e frame of \e system.
Use mementoForSystem:inTrajectoryFrame:() instead
*/
- (id) mementoForFrame: (unsigned int) frame ofSystem: (id) system;
/**
\note Deprecated
Returns the number of snapshots acquired for \e system.
Use numberTrajectoryCheckpoints() instead.
*/
- (unsigned int) numberOfFramesForSystem: (id) system;

@end

//Typedef for object still using ULSimulation
@interface ULSimulation: AdSimulationData
{
}
@end


/**
\ingroup coreClasses
AdSimulationDataWriter writes information on the state of a set of systems in an AdSystemCollection object to a data store.
Since the state of the systems changes frequently during a simulation the AdSimulationData
writer is usually used to record the state of the systems at different times.

It works in conjuction with AdSimulationData which can read this data. The data store
must be provided on initialisation and must be in AdSimulationStorageWriteMode.
(The ability to update data using AdSimulationStorageUpdateMode will be 
implemented in the future).

It can also be provided with an AdForceFieldCollection instance, containing AdForceField
objects operating on the systems, so energy information is also recored.

\section Frames

Data is written to the simulation storage in \e frames.
To start recording data a frame must first be opened by calling openFrame:().
While a frame is open different types of data can be recorded (or \e checkpointed).
These types of data are -

- an energy checkpoint - using addEnergyCheckpoint()
- a trajectory checkpoint - using addTrajectoryCheckpoint()
- a topology checkpoint - using addTopologyCheckpoint()

Note: only one of each type of checkpoint can be added to a frame.
Adding the same type of data twice in a frame (by calling one of the add* methods more than once) 
means the old data is overwritten.

A call to closeFrame() finishes the write. 

Note that to save on IO energy data is not actually written to the store unless synchToStore() is called.

\section Iteration Header

Usually the state of the systems stored in a frame is associated with a particular step of
a configuration generation process (or some other iterative process).
This step value can be recorded with the corresponding frame by passing it as the parameter to openFrame:().
This value does not have to be the actual step of the process but could be an associated value.
For example it could be the simulation 'time' corresponding to the frame, that is the simulator step times the
time per step.

The IterationHeader is a string defining what this number is - 'Time', 'Iteration' or some other value.

\section Notes

\note Care is required when creating topology checkpoints that the
stored topology corresponds to the related configuration (if any)
stored in the same frame.
\todo Maybe record iteration values, i.e. configuration generator step values, with frame data?
\todo Currently only can record system related information - should be able to record information on the
state of other parts of the simulator ...
*/
@interface AdSimulationDataWriter: NSObject
{
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
	id dataStorage;
}
/**
As initWithDataStorage:systems:forceFields: passing
nil for \e aSystemCollection and \e aForceFieldCollection.
*/
- (id) initWithDataStorage: (id) aDataStore;
/**
Designated initialiser.
Initialises a new simulation storage object which tracks
the state of \e aSystemCollection writing the collected data to \e aDataStore.
The first column of each state matrix will be titled \e iterationHeader. If this
is nil it defaults to "Iteration".
\e aDataStore must be AdSimulationStorageWriteMode - if not an NSInternalInconsistencyException
is raised. \e aDataStore cannot be nil - if it is an NSInvalidArgumentException is raised.
\e aForceFieldCollection is an AdForceFieldCollection
instance containing force fields who are operating on the systems. This must be
provided if you wish energy information to be collected. 
*/
- (id) initWithDataStorage: (id) aDataStore
	systems: (AdSystemCollection*) aSystemCollection
	forceFields: (AdForceFieldCollection*) aForceFieldCollection
	iterationHeader: (NSString*) aString;
/**
Sets the system collection whose data will be recorded.
*/
- (void) setSystems: (AdSystemCollection*) aSystemCollection;
/**
Returns the system collection whose data is being recorded
*/
- (AdSystemCollection*) systems;
/**
Sets the force fields used to track the systems state.
*/
- (void) setForceFields: (AdForceFieldCollection*) aForceFieldCollection;
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
