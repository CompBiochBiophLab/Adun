
include $(GNUSTEP_MAKEFILES)/common.make

#Special rules for parallel build (make parallel=yes) when using openmpi.
#mpicc automatically adds libraries to the link line but when compiling
#the subprojects we have to remove them.
#This is because the subprojects are partialy linked and adding these libraries
#both here and where the full linking is done, causes many errors.
#Setting the variable OMPI_LIBS overrides the openmpi link flags
#However due to the nature of make only for this part of the build
#This may also be necessary for other mpi dists but this unknown at the moment.
ifeq ($(openmpi), yes)
export OMPI_LIBS = 
endif

export KERNEL_COMPILER ?= gcc
CC = $(KERNEL_COMPILER)
SUBPROJECT_NAME = Framework
Framework_OBJCFLAGS =  -W -O3 -fconstant-string-class=NSConstantString
Framework_INCLUDE_DIRS += -I/usr/local/include -I../ -I../../ -I../Headers -I$(GSL_INCLUDE_DIR)

Framework_OBJC_FILES = \
AdFrameworkFunctions.m \
AdIndexSetConversions.m \
AdunTimer.m \
AdunModelObject.m \
AdunMatrixStructureCoder.m \
AdunDataMatrix.m \
AdunDataSet.m \
AdunDataSource.m \
AdunContainerDataSource.m \
AdunElementSelection.m \
AdunGrid.m \
AdunSphericalBox.m \
AdunEllipsoidBox.m \
AdunCuboidBox.m \
AdunMoleculeCavity.m \
AdunCellListHandler.m \
AdunSimpleListHandler.m \
AdunLinkedList.m \
AdunListHandler.m\
AdunDynamics.m \
AdunInteractionSystem.m \
AdunSystem.m \
AdunSystemCollection.m \
AdunHarmonicConstraintTerm.m \
AdunSCAAS.m \
AdunNonbondedTerm.m \
AdunPureNonbondedTerm.m \
AdunGRFNonbondedTerm.m \
AdunShiftedNonbondedTerm.m \
AdunMultithreadedNonbondedTerm.m \
AdunSmoothedGBTerm.m \
AdGBSWTermIntegrationMethods.m \
AdGBSWTermBornRadiiMethods.m \
AdunForceField.m \
AdunMolecularMechanicsForceField.m \
AdunEnzymixForceField.m \
AdunAmberForceField.m \
AdunCharmmForceField.m \
AdunForceFieldCollection.m \
AdunConfigurationGenerator.m \
AdunSimulator.m \
AdunMinimiser.m \
AdunBerendsenThermostat.m \
AdunLangevinThermostat.m \
AdunMemoryManager.m \


include $(GNUSTEP_MAKEFILES)/subproject.make

