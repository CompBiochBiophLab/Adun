/*
   Project: AdunServer

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-31 15:41:02 +0200 by michael johnston

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

#ifndef _ADSERVER_H_
#define _ADSERVER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdServerInterface.h>
#include <AdunKernel/AdCommandInterface.h>
#include "ULFramework/ULServerInterface.h"
#include "ULFramework/ULProcess.h"
#include "ULFramework/ULFileSystemDatabaseBackend.h"

/**
\ingroup server
\bug AdServer only creates its log file on startup. If its subsequently deleted it is not recreated.
AdServer is the main class of the AdServer daemon.
Remote processes, mainly Adun's GUI, can connect to and interact with an instance of this class.
The class allows the process that connects to it to
- Launch and interact with simulations on the remote host
- Use file system databases located on the remote host.

Feature that will be added 
- Create instances of Adun classes that live on the remote host.
- Send any local Adun object to ''live'' on the remote host.

\section Defaults

AdunServer reads the following defaults

- IsDistributed - If Yes the server will vend itself using socket ports so it can be accessed from remote hosts.
Otherwise message ports are used. Default is NO.
- PortNumber - The TCP port the server can be connected on. Defaults to 1079. Only has an affect if IsDistributed is YES.
- LogFile - The location for the servers log file. Defaults to $WORKING_DIR/AdunServer.log where $WORKINGDIR is
$HOME/adun on linux and $HOME/.adun on OSX.
- AdunCorePath - The location of the AdunCore executable the server will use to run simulations. 
**/

@interface AdServer : NSObject
{
	NSConnection* connection;
	NSMutableDictionary* processes;
	NSMutableDictionary* tasks;
	NSMutableDictionary* interfaces;
	NSMutableDictionary* state; //!< Dictionary of bools inidicating if the simulator is accepting requests
	NSMutableDictionary* processErrors;
	NSMutableArray* disconnectedProcesses; //!< Process whose controlling interface has closed
	NSMutableDictionary* storedMessages;	//!< Contains messages that were to be sent to disconnected processes
	ULFileSystemDatabaseBackend* defaultBackend;
	id adunCorePath;
}

/**
Called when an NSTaskDidTerminateNotification is posted
*/
- (void) kernelTermination: (NSNotification*) aNotification;
@end

@interface AdServer (RemoteSimulationManagement) <ULServerInterface>
@end

@interface AdServer (AdunCoreInterface) <AdServerInterface>
@end

/**
Category containing methods for interacting with a file-system database
on a remote host through the server.
Note: This in an initial testing implementation lacking advanced security.
*/
@interface AdServer (RemoteDataManagement)
/**
As backendForFileSystemDatabase:() using the database at the default path
registered with the server. If no database was registered this method returns nil.
*/
- (ULFileSystemDatabaseBackend*) backendForDefaultFileSystemDatabase;
/**
Returns a ULFileSystemDatabaseBackend object that provides access to a local
file-system database at \e path.
The operations available depend on the permissions given to the server process.

\note
At the moment this method only returns the default database registered with the server.
*/
- (ULFileSystemDatabaseBackend*) backendForFileSystemDatabase: (NSString*) path;
@end

#endif // _ADSERVER_H_

