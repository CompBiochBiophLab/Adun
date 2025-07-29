include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = CoreCommands
CoreCommands_OBJCFLAGS =  -W -O3 -fconstant-string-class=NSConstantString -std=gnu89
CoreCommands_INCLUDE_DIRS = -I/usr/local/include -I../../../ -I../../Headers/ -I../ -I$(GSL_INCLUDE_DIR)

CoreCommands_OBJC_FILES = \
AdStatusCommand.m \
AdEndSimulationCommand.m

CoreCommands_HEADER_FILES = \
AdStatusCommand.h \
AdEndSimulationCommand.h


include $(GNUSTEP_MAKEFILES)/subproject.make
