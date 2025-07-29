#
#  GNUmakefile
#
#  Copyright (C) 2000 Stefan Urbanek
#
#  This file is part of the StepTalk.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = StepTalk

StepTalk_OBJC_FILES = \
    GCCObjcRuntimeSupport.m \
    NSInvocation+additions.m \
    STActor.m \
    STBehaviourInfo.m \
    STBundleInfo.m \
    STClassInfo.m \
    STContext.m \
    STConversation.m \
    STRemoteConversation.m \
    STEngine.m \
    STEnvironment.m \
    STEnvironmentServer.m \
    STEnvironmentDescription.m \
    STExterns.m \
    STFileScript.m \
    STLanguageManager.m \
    STMethod.m \
    STObjCRuntime.m \
    STObjectReference.m  \
    STResourceManager.m \
    STScript.m \
    STScriptsManager.m \
    STScripting.m \
    STScriptObject.m \
    STSelector.m \
    STStructure.m \
    STUndefinedObject.m  \
    NSNumber+additions.m \
    NSObject+additions.m \
    StepTalkScriptingInfo.m \
    STRemoteConversation.m \

STEPTALK_HEADER_FILES = \
    ObjcRuntimeSupport.h \
    STActor.h \
    STBundleInfo.h \
    STCompat.h \
    STContext.h \
    STConversation.h \
    STRemoteConversation.h \
    STEngine.h \
    STEnvironment.h \
    STEnvironmentServer.h \
    STEnvironmentDescription.h \
    STExterns.h \
    STFileScript.h \
    STLanguageManager.h \
    STMethod.h \
    STObjCRuntime.h \
    STObjectReference.h  \
    STResourceManager.h \
    STScriptObject.h \
    STScript.h \
    STScriptsManager.h \
    STScripting.h  \
    STSelector.h \
    STUndefinedObject.h  \
    NSInvocation+additions.h \
    NSObject+additions.h 

StepTalk_HEADER_FILES = $(STEPTALK_HEADER_FILES) \
                            StepTalk.h


StepTalk_RESOURCE_FILES = ScriptingInfo.plist Environments

ADDITIONAL_CPPFLAGS += -pipe 
ADDITIONAL_OBJCFLAGS = -Wno-import -DSTEPTALK_VERSION=$(STEPTALK_VERSION)

DOCUMENT_NAME = StepTalk

GNUSTEP_INSTALLATION_DOMAIN=USER
StepTalk_DOC_INSTALL_DIR = Developer

StepTalk_HEADER_FILES_DIR = $(HEADER_DIR)
StepTalk_AGSDOC_FILES = StepTalk.gsdoc $(STEPTALK_HEADER_FILES)
StepTalk_AGSDOC_FLAGS = \
        -Up StepTalk \
        -Declared StepTalk \
        -DocumentationDirectory ../../Documentation/Reference

ifeq ($(GNUSTEP_TARGET_OS),mingw32)
    StepTalk_LIBRARIES_DEPEND_UPON += -lgnustep-base -lobjc
endif

ifeq ($(check),yes)
    ADDITIONAL_OBJCFLAGS += -Werror
endif


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/framework.make

ifeq ($(doc), yes)
    include $(GNUSTEP_MAKEFILES)/documentation.make
endif

-include GNUmakefile.postamble
