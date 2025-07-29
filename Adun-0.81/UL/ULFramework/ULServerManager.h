/*
 Project: Adun
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
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
#ifndef _ULSERVERMANAGER_
#define _ULSERVERMANAGER_
#include <Foundation/Foundation.h>
#include <AdunKernel/AdunKernel.h>
#include "ULFramework/ULFrameworkDefinitions.h"

/**
Manages connections to AdunServer daemons.

\section failures Handling Failures

On a server becoming disconnected ULRemoteObjectWillBecomeInvalidNotification's will be broadcast
for every remote object vended by the server.
The notification object will be the remote object about to be invalidated.
Any object obtaining remote objects via this class should register for this notification.

There are two types of disconnection events - deliberate disconnections and errors.
On identifiying a connection error a reconnection attempt will be made after ULRemoteObjectWillBecomeInvalidNotifications
are posted for all previously vended objects.
On a succesful reconnection attempt ULServerManager will post a ULDidReconnectToServerNotification with
the notification being the server that was reconnected to.
This gives objects a chance to reaquire new references to remote objects.

\subsection timeouts Timeouts

Another type of failure is due to timeouts - when a message fails to be sent or a reply is not received.
These can be due to simply a busy network or due to a remote server crash.
Either way NSPortTimeOutputExceptions will be raised so objects using remote objects should prepare to handle them.
They should also check using checkTimeoutException:() to check the reason for the exception.
*/
@interface ULServerManager: NSObject
{
	NSMutableArray* knownHosts;	//An array of the hosts known to have servers
	NSMutableArray* connectedHosts;	//An array of the hosts that have been connected to
	NSMutableDictionary* connections;	//Keys: Hostnames Objects: NSConnection to the host
	NSMutableDictionary* connectionErrors;	//Keys: Hostnames Objects: NSError objects describing connection errors to the host
	NSMutableDictionary* servers;		//Keys: Hostnames Objects: AdServer proxies from each host
}
/**
Returns the default server manager
*/
+ (id) appServerManager;
/**
Returns an dictionary whose keys are hostnames the receiver could not connect to and whose values are error
object describing the reason for the problem.
*/
- (NSDictionary*) connectionErrors;
/**
Returns an array of the sucessfully contacted hosts
*/
- (NSArray*) connectedHosts;
/**
Returns an array containing all the servers
*/
- (NSArray*) allServers;
/**
Returns an array containing the names of all the hosts that the receiver tries to connect to.
*/
- (NSArray*) knownHosts;
/**
Permantely adds a host to the known hosts.
The receiver immediately tries to connect to the host
*/
- (void) addHost: (NSString*) hostname;
/**
Adds a host to the known hosts.
If \e persistant is YES the host is permantely added to the known hosts list.
If \e connectNow is YES the receiver immediately attempts to connect to the host.
*/
- (void) addHost: (NSString*) hostname persistant: (BOOL) persistant connectNow: (BOOL) connectNow;
/**
Returns the proxy for the AdunServer running on hostname or nil if the host could not be connected to.
If a connection was not previously established a connection attempt is made.
Raises an ULUnknownHostException if \e hostname is not a known host.
*/
- (id) serverOnHost: (NSString*) hostname;
/**
Closes the connection to the host vending \e server.
Posts an ULInvalidatedServerConnectionNotification 
*/
- (void) disconnectFromServer: (id) server;
/**
Closes the connection to the server on host \e hostname.
Raises an ULUnknownHostException if \e hostname is not a known host.
*/
- (void) disconnectFromServerOnHost: (NSString*) hostname;
/**
Checks if a server is runing on \e hostname.
*/
- (BOOL) checkForServerOnHost: (NSString*) hostname;
@end

#endif

