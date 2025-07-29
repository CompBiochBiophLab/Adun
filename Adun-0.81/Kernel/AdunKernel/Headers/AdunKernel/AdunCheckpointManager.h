/*
 Project: AdunCore
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
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
#ifndef _ADUNCHECKPOINTMANAGER_
#define _ADUNCHECKPOINTMANAGER_
#include <AdunKernel/AdunFileSystemSimulationStorage.h>
#include <AdunKernel/AdunSimulationData.h>
#include <AdunKernel/AdunTimer.h>
#include <AdunKernel/AdunConfigurationGenerator.h>

/**
Instances of AdCheckpointManager manage the collection of data at specified intervals from a configuration generation process
run by an AdConfigurationGenerator object.

Its primary attributes are

- a AdSimulationDataWriter object
- a AdConfigurationGenerator instance
- a set of intervals for when to collect different types of data
- the current checkpoint number

The first two are provided on initialisation.
An AdCheckpointManager instance essentially tells the AdSimulationDataWriter object when to collect and store data based 
on the iterations of the AdConfigurationGenerator object, and the intervals specified.

The objects checkpoint number is incremented each time it records any data for a given iteration of the 
configuration generator.
This is regardless of what was collected during the step - that is it can be energy and trajectory, or just energy etc.

On instantiation an AdCheckpointManager object collects all data at 500 step intervals.
Once an instance has been created the exact details can be changed through the objects interface.

\section Checkpoints, frames and production steps

Each checkpoint frame is associated with a production step. 
It correpsonds to the state of the systems at the end of the step.
Since the first production step is 0 any frame associated with it describes the systems when it has finished.
 
The state of a system before the production loop begins is given an production step of -1. 
Since this state is captured when an AdConfigurationGeneratorWillBeginProductionNotification 
is received one frame always corresponds to production step -1.

\section RollBack

AdCheckpointManager instances also provide the facility to return the configuration generator to its state
at any recorded step.
This is called \e rolling \e back the simulation.
Rolling back a simulation means deleting all data collected since the specified step.

Once rolled back the AdCheckpointManager instances state will be indistiguishable to what it was at the rolled-back-to step.
That is, if you had the instance at the step, and the rollbacked instance, there is no way to tell any difference.

\ingroup coreClasses
*/
@interface AdCheckpointManager: NSObject
{
	BOOL checkpointsTopology;
	BOOL checkpointsTrajectory;
	BOOL checkpointsEnergy;
	int energyInterval;
	int trajectoryInterval;
	int flushInterval;
	int productionBoundary;		//!< The frame corresponding to the beginning of the last production loop
	int stepForCurrentFrame;	//!< The production step corresponding to the currently open frame.
	NSMutableArray* productionCheckpoints;	
	AdSimulationDataWriter* dataWriter;
	AdConfigurationGenerator* configurationGenerator;
}
/**
Class method
As initWithConfigurationGenerator:simulationDataWriter: except returning an autoreleased object.
*/
+ (id) checkpointManagerForConfigurationGenerator: (AdConfigurationGenerator*) generator
		simulationDataWriter: (AdSimulationDataWriter*) writer;
/**
Designated initialiser.
Creates an new AdCheckpointManager instance that records data using \e writer based on the iterations of
\e generator.
\e writer should be intialised to record data from the same systems and force-fields as operated on by \e generator.
It readCheckpointDataFromWriter is YES then the receiver will initialise its checkpoint data using information
from \e writer. By default it is NO.

\e value is the last step completed by the AdConfigurationGenerator instance.
This number is used to define the step of the generation process which the first checkpoint corresponds to.
If this is a new generation process, that is AdConfigurationGenerator::production:() 
is used to start the process, this should be '-1'. (Since the first step of the generation process is step = 0).

Otherwise it should be the value of the last step completed by the generator.
Note: It is assumed the simulation data for this step is the last frame of data written to the store
*/			     
- (id) initWithConfigurationGenerator: (AdConfigurationGenerator*) generator
		lastGenerationStep: (int) value
		simulationDataWriter: (AdSimulationDataWriter*) writer;
/**
AS initWithConfigurationGenerator:lastGenerationStep:simulationDataWriter:
with the last step set to -1.
*/
- (id) initWithConfigurationGenerator: (AdConfigurationGenerator*) generator
		 simulationDataWriter: (AdSimulationDataWriter*) writer;		 
/**
Closes any currently open frame and flushes all data to the store
*/
- (void) synchronize;
/**
Turns on checkpointing of all data - this is done by default.
You can use this method as a convience restart mechanism if stop() is called.
Note however that \e all checkpointing is turned on regardless of what was being recorded before
stop() was called.
The receiver also starts observing relevant notifications from the configuration generator and systems.
*/
- (void) startCheckpointing;
/**
Stops checkpoint everything. No further data will be recorded until start() or
the individual checkpoints are turned back on e.g. via setCheckpointsEnergy() etc.
This has the effect of closing the current frame and flushing all data  (via synchronize()).
The receiver also stops observing relevant notifications from the configuration generator and systems.
*/
- (void) stopCheckpointing;
/**
Resets the receiver to checkpoint data at the specified intervals starting from the current step.
For example the configuration generator is at step 400 and the checkpoint manager is
collecting data every 500 steps.
Therefore the next checkpoint will be in 100 steps.
If this method is called at this time the next checkpoint will instead be 500 steps from 
the current configuration generator step i.e. step 900. 	
*/	
- (void) resetCheckpointIntervals; 
/**
Returns the number of checkpoints that the receiver has made
*/
- (unsigned int) numberOfCheckpoints;
/**
Returns the configuration step corresponding to the last written frame
*/
- (unsigned int) stepForCurrentFrame;
/**
Returns the checkpoint info for checkpoint \e number.
This is a dictionary with two keys 

- Step - The configuration generator step corresponding to checkpoint \e number
- Iteration - The frame number in the simulation data corresponding to checkpoint \e number.
*/
- (NSDictionary*) infoForCheckpoint: (unsigned int) number;
/**
 Returns information on the last time  a trajecory frame was recored before \e limit
 The keys in the returned dict are
 
 - Checkpoint - The checkpoint number
 - Step - The configuration generator step
 - Frame - The frame number
 
 Usually frame and checkpoint number will be the same but there are a number of situations where
 this will not be the case.
 */
- (NSDictionary*) infoForLastTrajectoryCheckpointBeforeStep: (int) limitStep;
/**
Returns YES if the receiver checkpoints the topology of the simulation, NO otherwise.
YES by default.
 */
- (BOOL) checkpointsTrajectory;
/**
 Returns YES if the receiver checkpoints the topology of the simulation, NO otherwise.
YES by default.
 */
- (BOOL) checkpointsTopology;
/**
 Returns YES if the receiver checkpoints the energy of the simulation, NO otherwise.
 YES by default.
 */
- (BOOL) checkpointsEnergy;	
/**
Set whether the receiver checkpoint the simulation topology.
*/
- (void) setCheckpointsTopology: (BOOL) value;
/**
 Set whether the receiver checkpoint the simulation trajectory.
 */
- (void) setCheckpointsTrajectory: (BOOL) value;
/**
 Set whether the receiver checkpoint the simulation energy.
 */
- (void) setCheckpointsEnergy: (BOOL) value;
/**
The interval at which the receiver flushes the simulation energies to the storage
*/
- (unsigned int) flushInterval;
/**
Sets the interval at which the receiver flushes the simulation energies to the storage to \e value
*/
- (void) setFlushInterval: (unsigned int) value;
/**
The interval at which the receiver checkpoints the simulation energies.
*/
- (unsigned int) energyCheckpointInterval;
/**
 The interval at which the receiver checkpoints the simulation trajectory.
 */
- (unsigned int) trajectoryCheckpointInterval;
/**
Sets the interval at which the receiver flushes the simulation energies to the storage to \e value
*/
- (void) setEnergyCheckpointInterval: (unsigned int) value;
/**
 Sets the interval at which the receiver flushes the simulation energies to the storage to \e value
 */
- (void) setTrajectoryCheckpointInterval: (unsigned int) value;
/**
Returns the AdSimulationDataWriter instance used by the receiver to write data
to the store
*/
- (AdSimulationDataWriter*) simulationDataWriter;
@end

/**
Category containing the roll back methods
\ingroup coreCategories
*/
@interface AdCheckpointManager (RollBackMethods)
/**
Rolls the simulation back to the last checkpoint.
*/
- (int) rollBackToLastCheckpoint;
/**
Rolls back to the last checkpoint before step
*/
- (int) rollBackToLastCheckpointBeforeStep: (int) limitStep;
@end

/**
Contains methods used internally by AdCheckpointManager instances
to handle the checkpointing process
*/
@interface AdCheckpointManager (PrivateInternals)
/**
 Opens a frame for the current configuration iteration if
 one is not already open. Closes any previous frame.
 */
- (void) openFrame;
/**
 Called when a system reloads its data so it can be checkpointed.
 */
- (void) handleSystemContentsChange: (NSNotification*) aNotification;
/**
Called when the configuration generator starts a new production loop
*/
- (void) handleProductionStart: (NSNotification*) aNotification;
/**
This method is called at each energyInterval step
*/
- (void) checkpointEnergy;
/**
 This method is called at each trajectoryInterval step
 */
- (void) checkpointTrajectory;
@end

#endif
