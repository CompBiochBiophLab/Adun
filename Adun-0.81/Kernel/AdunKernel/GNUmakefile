
include $(GNUSTEP_MAKEFILES)/common.make

#There are two possible targets - the standard framework and a unit test version.
ifeq ($(test), yes)
BUNDLE_NAME = FrameworkTest
ADDITIONAL_LDFLAGS = -lUnitKit -lgnustep-base -lgsl -lgslcblas 
FrameworkTest_SUBPROJECTS = Tests/ Commands/ 
else
VERSION = 0.13
FRAMEWORK_NAME =AdunKernel 
AdunKernel_LIB_DIRS = -L../Base/$(GNUSTEP_OBJ_DIR) -L$(GSL_LIB_DIR) 
AdunKernel_LIBRARIES_DEPEND_UPON = -ladun_base -lgnustep-base -lgsl -lgslcblas
endif

export KERNEL_COMPILER ?= gcc
CC = $(KERNEL_COMPILER)
GNUSTEP_INSTALLATION_DOMAIN = USER

#Standard Flags
AdunKernel_OBJCFLAGS =  -W -O3 -fconstant-string-class=NSConstantString -std=gnu89
AdunKernel_INCLUDE_DIRS = -I$(GSL_INCLUDE_DIR) -I./Headers -I. 
AdunKernel_SUBPROJECTS = Framework/ CoreAdditions/
AdunKernel_HEADER_FILES_DIR = Headers/AdunKernel

#Testing flags
FrameworkTest_OBJCFLAGS =  -W -O3 -fconstant-string-class=NSConstantString 
FrameworkTest_INCLUDE_DIRS = -I$(GSL_INCLUDE_DIR) -I./Headers -I. 

AdunKernel_RESOURCE_FILES = \
Resources/ScriptingInfo.plist \
Resources/GBSWData/ 

AdunKernel_HEADER_FILES = \
AdFrameworkFunctions.h \
AdunDefinitions.h \
AdDataSources.h\
AdGridDelegate.h \
AdServerInterface.h \
AdIndexSetConversions.h \
AdMemento.h \
AdMatrixModification.h \
AdunTimer.h \
AdunModelObject.h \
AdunMatrixStructureCoder.h \
AdunDataMatrix.h \
AdunDataSet.h \
AdunDataSource.h \
AdunContainerDataSource.h \
AdunElementSelection.h \
AdunGrid.h \
AdunSphericalBox.h \
AdunEllipsoidBox.h \
AdunCuboidBox.h \
AdunMoleculeCavity.h \
AdunCellListHandler.h \
AdunSimpleListHandler.h \
AdunLinkedList.h \
AdunListHandler.h \
AdunDynamics.h \
AdunInteractionSystem.h \
AdunSystem.h \
AdunSystemCollection.h \
AdForceFieldTerm.h \
AdunHarmonicConstraintTerm.h \
AdunSCAAS.h \
AdunNonbondedTerm.h \
AdunPureNonbondedTerm.h \
AdunGRFNonbondedTerm.h \
AdunShiftedNonbondedTerm.h \
AdunMultithreadedNonbondedTerm.h \
AdunSmoothedGBTerm.h \
AdunForceField.h \
AdunMolecularMechanicsForceField.h \
AdunEnzymixForceField.h \
AdunAmberForceField.h \
AdunCharmmForceField.h \
AdunForceFieldCollection.h \
AdunConfigurationGenerator.h \
AdunSimulator.h \
AdunLangevinThermostat.h \
AdunBerendsenThermostat.h \
AdunMinimiser.h \
AdunMemoryManager.h \
AdCoreCommand.h \
AdCoreAdditions.h \
AdCommandInterface.h \
AdController.h \
AdunIOManager.h \
AdunSimulationData.h \
AdunTrajectory.h \
AdunFileSystemSimulationStorage.h \
AdunController.h \
AdunTemplateProcessor.h \
AdunCheckpointManager.h \
AdunCore.h \
AdunKernel.h

FrameworkTest_OBJC_FILES += $(AdunKernel_OBJC_FILES)

-include GNUmakefile.preamble
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
-include GNUmakefile.postamble

