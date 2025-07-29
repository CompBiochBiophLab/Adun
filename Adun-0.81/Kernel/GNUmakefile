
include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME=AdunCore

ifeq ($(parallel), yes)
export MP_CC=gcc
export OBJECT_MODE=64
export MP_IMPL=lam
export openmpi=yes
export KERNEL_COMPILER := $(MPI_PATH)mpicc $(MPICC_FLAGS)
else
export KERNEL_COMPILER ?= gcc
endif

export debug=no
export ADUN_LIBRARY_COMPILER ?= gcc
export GSL_LIB_DIR ?= /usr/local/lib
export GSL_INCLUDE_DIR ?= /usr/local/include

CC = $(KERNEL_COMPILER)
ifeq ($(ADUN_LIBRARY_COMPILER), icc)
	AdunCore_TOOL_LIBS =   -lAdunKernel -ladun_base -lgsl -lgslcblas -lfl -limf -lsvml -lm -ladun_base 
else
	AdunCore_TOOL_LIBS = -lAdunKernel -ladun_base  -lgsl -lgslcblas 
endif

GNUSTEP_INSTALLATION_DOMAIN=USER
AdunCore_HAS_RESOURCE_BUNDLE=yes
AdunCore_INCLUDE_DIRS = -IAdunKernel/Headers -I$(GSL_INCLUDE_DIR)

SUBPROJECTS = \
Base \
AdunKernel \

AdunCore_RESOURCE_FILES = \

AdunCore_OBJC_FILES = \
main.m 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble

