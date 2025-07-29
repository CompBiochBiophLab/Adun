/* 
   Project: UL

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
#ifndef _ULSCRIPTMANAGER_
#define _ULSCRIPTMANAGER_

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <ULFramework/ULFramework.h>
#include <StepTalk/STEnvironment.h>
#include <StepTalk/STConversation.h>
#include <StepTalk/STScriptsManager.h>
#include <StepTalk/STFileScript.h>
#include "STTranscript.h"

@interface ULScriptManager: NSObject
{
	NSMutableDictionary* connections;
	NSMutableArray* runningThreads;
	NSMutableArray* selectedThreads;
	NSTimer* autoUpdateTimer;
	STEnvironment *environment;
	STScriptsManager *manager;
	STTranscript* transcript;
	id window;
	id scriptList;
	id argField;
	id threadButton;
	id threadTable;
	id drawer;
}
/**
Exectutes the script identified by \e aString in the application
main thread. The script may use application kit classes.
\param aString The name of the script to be run.
\param args An array of strings that will be set as the
scripts arguments. 
\param  error A pointer to an NSError object. Upon return
if there was an error, \e error will contain an NSError object detailing
the problem. 
*/
- (void) runScriptWithName: (NSString*) aString arguments: (NSArray*) args error: (NSError**) error;
/**
Launches the script chosen in the interface either threaded or non-threaded
depending on the users choice.
*/
- (void) launch: (id) sender;
/**
Opens the script manager window
*/
- (void) open: (id) sender;
/**
Closes the script manager window
*/
- (void) close: (id) sender;
/**
Opens the transcript window
*/
- (void) showTranscript: (id) sender;
/**
Runs an NSAlertPanel with the contents of \e error.
\e errors userInfo dictionary should contain the following
keys 

- NSLocalizedDescriptionKey 
- AdDetailedDescriptionKey 
- NSRecoverySuggestionKey.

If \e error is nil this method does nothing.
*/
- (void) logScriptError: (NSError*) error;
@end


/**
Category containing methods for running scripts in a separate thread.
Adapted from AdController(AdControllerThreadingExtensions).
*/
@interface ULScriptManager (ULScriptManagerThreadingExtensions)
/**
Exectutes the script identified by \e aString in a separate thread. 
The script should \e not use application kit classes as the application kit
is not thread safe.
\param aString The name of the script to be run.
\param args An array of strings that will be set as the
scripts arguments. 
*/
- (void) runThreadedScriptWithName: (NSString*) aString arguments: (NSArray*) args;
/**
Sent by a thread running a script when its finished.
\e terminationDict contains at least one key: "ThreadId" which
is the id assigned to the thread. If the script run in the thread
exited with an error then \e terminationDict should contain
a key "TerminationError" whose value is an NSError object 
describing the error.
*/
- (void) scriptFinished: (NSDictionary*) terminationDict;
/**
Stops a script which is running in a separate thread.
Should only be called on the thread.
*/
- (oneway void) stopScript;
/**
Stops the selected thread in the running thread
table.
*/
- (void) stopThreadedScript: (id) sender;
@end

#endif
