include $(GNUSTEP_MAKEFILES)/common.make

#
# Bundle
#
VERSION = 0.1
PACKAGE_NAME = 
BUNDLE_NAME = AdunShell
EnergyConverter_PRINCIPAL_CLASS = AdunShell
BUNDLE_EXTENSION = 

#
# Libraries
#
AdunShell_LIBRARIES_DEPEND_UPON += -ladun_Base -lAdunKernel -lgsl -lgslcblas 
LDFLAGS += -lreadline -lncurses -lStepTalk

#
# Resource files
#
AdunShell_RESOURCE_FILES = Resources/controllerOptions.plist \
Info-gnustep.plist

#
# Header files
#
AdunShell_HEADER_FILES = \
AdunShell.h \
STShell.h \

#
# Class files
#
AdunShell_OBJC_FILES = \
AdunShell.m \
STShell.m \
STShell+output.m \

#
# Makefiles
#
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
