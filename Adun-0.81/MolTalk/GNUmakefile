# Copyright 2003-2006  Alexander V. Diemand
#
#    This file is part of MolTalk.
#
#    MolTalk is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    MolTalk is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with MolTalk; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 


ARCH1=$(shell uname -s)
ARCH2=$(shell uname -m)

ARCH=$(ARCH1)_$(ARCH2)

include Version

# load GNUstep stuff
include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = MolTalk
PACKAGE_NAME = MolTalk
MolTalk_HAS_RESOURCE_BUNDLE = YES;

#
# Public headers (will be installed)
#
MolTalk_HEADERS =  \
MolTalk.h \
MTAtom.h \
MTAlPos.h \
MTChain.h \
MTCoordinates.h \
MTResidue.h \
MTSelection.h \
MTStructure.h \
MTString.h \
MTStream.h \
MTFileStream.h \
MTCompressedFileStream.h \
MTMatrix53.h \
MTMatrix44.h \
MTMatrix.h \
MTVector.h \
MTPairwiseStrxAlignment.h \
MTPairwiseSequenceAlignment.h \
MTSubstitutionMatrix.h \
MTStructureFactory.h \
MTChainFactory.h \
MTResidueFactory.h \
MTAtomFactory.h \
MTQuaternion.h 

#
# Header files
#
MolTalk_HEADER_FILES =  \
MolTalk.h \
MTAtom.h \
MTAlPos.h \
MTChain.h \
MTCoordinates.h \
MTResidue.h \
MTSelection.h \
MTStructure.h \
MTString.h \
MTStream.h \
MTFileStream.h \
MTCompressedFileStream.h \
MTMatrix53.h \
MTMatrix44.h \
MTMatrix.h \
MTVector.h \
MTPairwiseStrxAlignment.h \
MTPairwiseSequenceAlignment.h \
MTSubstitutionMatrix.h \
MTStructureFactory.h \
MTChainFactory.h \
MTResidueFactory.h \
MTAtomFactory.h \
MTQuaternion.h 

#
# Class files
#
MolTalk_OBJC_FILES = \
MTAtom.m \
MTAlPos.m \
MTChain.m \
privateMTChain.m \
MTCoordinates.m \
MTResidue.m \
privateMTResidue.m \
MTSelection.m \
privateMTSelection.m \
MTStructure.m \
privateMTStructure.m \
MTString.m \
MTStream.m \
MTFileStream.m \
MTCompressedFileStream.m \
MTMatrix53.m \
MTMatrix44.m \
MTMatrix.m \
privateMTMatrix.m \
MTVector.m \
MTPDBParser.m \
MTPairwiseStrxAlignment.m \
MTPairwiseSequenceAlignment.m \
MTSubstitutionMatrix.m \
MTStructureFactory.m \
MTChainFactory.m \
MTResidueFactory.m \
NSScanner+additions.m \
MTAtomFactory.m \
MTQuaternion.m 

MolTalk_RESOURCE_FILES = \
Resources/ScriptingInfo.plist \

$(FRAMEWORK_NAME)_C_FILES = \
MolTalk.c 

$(FRAMEWORK_NAME)_DLL_DEF = libMolTalk.def

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/framework.make
-include GNUmakefile.postamble

