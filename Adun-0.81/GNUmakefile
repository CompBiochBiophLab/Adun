
include $(GNUSTEP_MAKEFILES)/common.make 

GNUSTEP_INSTALLATION_DOMAIN=USER
export ADUN_SOURCE_DIR=$(CURDIR)

external ?= yes

ifeq ($(external), yes)
SUBPROJECTS =  ExternalPackages/ Kernel/ MolTalk/ UL/
else
SUBPROJECTS =  Kernel/ MolTalk/ UL/
endif

#Rpm

PACKAGE_NAME=Adun
PACKAGE_VERSION=0.81

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble

