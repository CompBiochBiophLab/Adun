
include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libadun_base
libadun_base_HEADER_FILES_INSTALL_DIR = /Base
libadun_base_INCLUDE_DIRS = -I../

CC = $(ADUN_LIBRARY_COMPILER)
ifeq ($(CC), gcc)
	libadun_base_CFLAGS = -W -static -O3
else
	libadun_base_CFLAGS = -Wbrief -xP -ip -static -O3 -mtune=pentium4 -c99 
endif

libadun_base_C_FILES = \
AdHarmonicBond.c \
AdEnzymixBond.c \
AdEnzymixAngle.c \
AdHarmonicAngle.c \
AdFourierTorsion.c \
AdHarmonicImproperTorsion.c \
AdCoulombAndLennardJonesA.c \
AdCoulombAndLennardJonesB.c \
AdLinkedList.c \
AdMatrix.c \
AdGeneralizedBornFunctions.c \
AdQuaternion.c \
AdQuadratureFunctions.c \
AdSorter.c \
AdVector.c \
AdVolumeFunctions.c \
AdBaseFunctions.c

libadun_base_HEADER_FILES = \
AdForceFieldFunctions.h \
AdGeneralizedBornFunctions.h \
AdMatrix.h \
AdQuaternion.h \
AdSorter.h \
AdVector.h \
AdQuadratureFunctions.h \
AdVolumeFunctions.h \
AdBaseFunctions.h \
AdLinkedList.h 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

