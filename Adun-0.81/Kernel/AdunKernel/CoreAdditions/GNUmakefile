
include $(GNUSTEP_MAKEFILES)/common.make

#See Framework/GNUmakefile for more on why this is required
ifeq ($(openmpi), yes)
export OMPI_LIBS = 
endif

ifeq ($(parallel), yes)
	ADDITIONAL_CPPFLAGS += -DPARALLEL
endif	

SUBPROJECT_NAME = CoreAdditions
CoreAdditions_SUBPROJECTS = Commands
CoreAdditions_OBJCFLAGS =  -W -O3 -fconstant-string-class=NSConstantString -std=gnu89
CoreAdditions_INCLUDE_DIRS = -I/usr/local/include -I../ -I../../ -I../Headers -I$(GSL_INCLUDE_DIR)

export KERNEL_COMPILER ?= gcc
CC = $(KERNEL_COMPILER)

CoreAdditions_OBJC_FILES = \
AdunTemplateProcessor.m \
AdunController.m \
AdunIOManager.m \
AdunFileSystemSimulationStorage.m \
AdunSimulationData.m \
AdunTrajectory.m \
AdunCheckpointManager.m \
AdunCore.m \

include $(GNUSTEP_MAKEFILES)/subproject.make
