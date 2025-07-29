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
 
#include "ULFramework/ULServerManager.h"
#include "ULFramework/ULIOManager.h"
#include "ULFramework/ULServerInterface.h"

ULServerManager* serverManager = nil;

@interface ULServerManager (ConnectionMethods)
/**
Connects to the server on \e hostname returning the NSConnection object.
If a connection could not be made returns nil and \e error contains an NSError object
if it was not NULL.
If the connection 
*/
- (NSConnection*) _connectToServerOnHost: (NSString*) hostname error: (NSError**) error;
/**
Received when a connection dies for a reason other than a call to _removeConnectionToHost:()
(or one of the disconnectFromServer- methods).
All information pertaining to the connection is removed (by a call to _removeConnectionToHost:()).
A reconnection attempt is then made. If this fails an ULUnexpectedDisconnectionFromServerNotification is posted.
If it succeeds an ULDidReconnectToServerNotification is posted.
*/
- (void) _handleConnectionDidDie: (NSNotification*) aNotification;
/**
Checks if the connection to \e hostname is still valid. 
If \e hostname isn't in the knownHosts array an NSInvalidArgumentException is raised.
If no connection to the host exists the method returns nil.
Otherwise the method checks the validitiy of the connection.
If the connection is invalid the method tries to reconnect. On failure the method returns nil and \e error contains information on what happend.
Otherwise returns a valid NSConnection object.
*/
- (NSConnection*) _checkConnectionToHost: (NSString*) hostname error: (NSError**) error;
/**
Adds \e connection to the known connections managed by the receiver.
The receiver registers for NSConnectionDidDieNotifications for the connection and adds it to the connections ivar.
It also adds the AdServer proxy to the servers ivar, the host to the connectedHosts ivar.

If \e hostname isn't in the knownHosts array an NSInvalidArgumentException is raised.
If a connection to hostname already exists this method does nothing.
*/
- (void) _addConnection: (NSConnection*) connection toHost: (NSString*) hostname;
/**
Removes the connection to \e hostname.
The reciever stops observing NSConnectionDidDieNotification from \e connection.
Then the method sends a ULRemoteObjectWillBecomeInvalidNotification for each remote object being served by the connection.
\e connection is then removed from the connections ivar, the server proxy is removed from the server ivar and
the hostname removed from the connected hosts ivar.
The connection is invalidated - note this will not trigger _handleConnectionDidDie being called.

If \e hostname isn't in the knownHosts array an NSInvalidArgumentException is raised.
If no connection exists this method does nothing.
*/
- (void) _removeConnectionToHost: (NSString*) hostname;
@end

@implementation ULServerManager (ConnectionMethods)

- (void) _handleConnectionDidDie: (NSNotification*) aNotification
{
	NSConnection* connection;
	NSString* host;
	NSError* error;
	NSMutableDictionary* errorInfo;
	NSMutableDictionary* userInfo;
	
	//Get the host
	host = [[connections allKeysForObject: [aNotification object]] 
		objectAtIndex: 0];
	
	/*
	 * First remove the old connection
	 * Then try to reconnect to the host.
	 * If we add the new one.
	 * If not we post a ULDisconnectedFromServerNotification.
	 */
	
	//This will invalidate the connection - possible loop avoided
	//since this method will not be called if invalidate was used.
	[self _removeConnectionToHost: host];     
	
	//Try to reconnect
	connection = [self _checkConnectionToHost: host error: &error];
	
	if(connection != nil)
	{	
		[self _addConnection: connection toHost: host];
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULDidReconnectToServerNotification" 
			object: self 
			userInfo: nil];
	}
	else
	{	
		NSWarnLog(@"Detected server death");     
		userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject: error forKey: @"ULDisconnectionErrorKey"];
		[userInfo setObject: host forKey: @"ULDisconnectedHostKey"];
		
		[[NSNotificationCenter defaultCenter]
			postNotificationName: @"ULUnexpectedDisconnectionFromServerNotification"
			object: self
			userInfo: userInfo];
	}
}

- (NSConnection*) _connectToServerOnHost: (NSString*) hostname error: (NSError**) error
{
	NSConnection* connection;

	if((connection = [connections objectForKey: hostname]) == nil)
	{
		if([hostname isEqual: [[NSHost currentHost] name]])
		{
			//if we're trying to connect to the local host first try to connect to
			//AdunServer through message ports then socket ports
			
			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
									    host: nil];
			
			if(connection == nil)
				connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
										    host: hostname 
									 usingNameServer: [NSSocketPortNameServer sharedInstance]]; 
		}	
		else
		{
			//if we're not trying to connect to the local host their must be
			//an AdunServer using NSSocketPorts on the remote machine
			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
									    host: hostname 
								 usingNameServer: [NSSocketPortNameServer sharedInstance]]; 
			NSDebugLLog(@"ULServerManager", 
				    @"Connected to host %@ hostname using connection %@", 
				    hostname, connection);
		}
		
		if(connection == nil && error != NULL)
		{
			*error = AdCreateError(ULFrameworkErrorDomain, 
					ULServerConnectionError, 
					@"Unable to connect to server", 
					[NSString stringWithFormat: @"Host - %@", hostname],
					@"Check if an AdunServer is running on the host.\n"
					"If the host is remote check the server port is accessible");
		}		
		
		NSDebugLLog(@"ULServerManager", 
			    @"Connection statistics %@", [connection statistics]);
	}	
	
	return connection;
}

- (NSConnection*) _checkConnectionToHost: (NSString*) hostname error: (NSError**) error
{
	NSPort* port;
	NSConnection* connection;

	if(![knownHosts containsObject: hostname])
	{
		[NSException raise: NSInvalidArgumentException
			    format: @"Cannot close connection to unkown host %@", hostname];
	}
	
	//Check if a connection exists
	if(![connectedHosts containsObject: hostname])
	{
		return nil;
	}
	
	//Get the connection
	connection = [connections objectForKey: hostname];
	
	//Check the connection is still valid 
	if(![connection isValid])
	{
		//try to reconnect
		port = [connection sendPort];
		
		if([port isMemberOfClass: [NSMessagePort class]])
		{
			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
									    host: hostname 
								 usingNameServer: [NSMessagePortNameServer sharedInstance]]; 
			
		}
		else
		{
			connection =  [NSConnection connectionWithRegisteredName: @"AdunServer" 
									    host: hostname 
								 usingNameServer: [NSSocketPortNameServer sharedInstance]];
		}
			 
		if(connection == nil && error != NULL)
		{
			*error = AdCreateError(ULFrameworkErrorDomain,
					ULServerConnectionError, 
					@"Error attempt connection",
					[NSString stringWithFormat: @"Could not restabilish connection to host %@", hostname],
					@"The host may be down");
		}
	}
	
	return connection;	
}

- (void) _addConnection: (NSConnection*) connection toHost: (NSString*) hostname
{
	if(![knownHosts containsObject: hostname])
	{
		[NSException raise: NSInvalidArgumentException
			    format: @"Cannot add a connection to unknown host %@", hostname];
	}
	
	//Check if a connection exists
	if([connectedHosts containsObject: hostname])
	{
		NSWarnLog(@"Trying to add a connection to a host already connected to.");
		return;
	}

	//Set ivars
	[connections setObject: connection forKey: hostname];
	[connectedHosts addObject: hostname];
	[servers setObject: [connection rootProxy] forKey: hostname];
	
	//register for notifications
	[[NSNotificationCenter defaultCenter] 
		addObserver: self
		selector: @selector(_handleConnectionsDidDie:)
		name: NSConnectionDidDieNotification
		object: connection];
		
	NSLog(@"Connected to host %@", hostname);	
}

/*
Invalidates the connection but _handleConnectionDidDie will not be called
*/
- (void) _removeConnectionToHost: (NSString*) hostname
{
	NSEnumerator* proxyEnum;
	NSConnection* connection;
	id server, proxy;

	if(![knownHosts containsObject: hostname])
	{
		[NSException raise: NSInvalidArgumentException
			    format: @"Cannot remove a connection to unknown host %@", hostname];
	}	

	//Check if a connection exists
	if(![connectedHosts containsObject: hostname])
	{
		NSWarnLog(@"Trying to remove a connection that doesn't exist.");
		return;
	}

	connection = [connections objectForKey: hostname];
	
	//Stop observing NSConnectionDidDieNotification from this connection
	//This also stops _handleConnectionsDidDie being called when we invalidate the connection below.
	[[NSNotificationCenter defaultCenter]
		removeObserver: self 
		name: NSConnectionDidDieNotification 
		object: connection];
	
	//Broadcast ULRemoteObjectWillBecomeInvalidNotification for every
	//remote object served by the connection.
	proxyEnum = [[connection remoteObjects] objectEnumerator];
	while(proxy = [proxyEnum nextObject])
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: @"ULRemoteObjectWillBecomeInvalidNotification" 
		 object: proxy];
	}
	
	//Get the server so we can logout
	server = [servers objectForKey: hostname];
	//FIXME: Implement
	//[server logout];
	
	//FIXME: Hopefully this will not have an adverse affects
	//if the connection is already invalidated.
	if([connection isValid])
		[connection invalidate];

	[servers removeObjectForKey: hostname];
	[connections removeObjectForKey: hostname];
	[connectedHosts removeObject: hostname];
	
	NSLog(@"Disconnected from host %@", hostname);	
}

@end

@implementation ULServerManager

+ (id) appServerManager
{
	if(serverManager == nil)
		serverManager = [ULServerManager new];
	
	return [[serverManager retain] autorelease];	
}

- (id) init
{
	NSString* hostsFile, *host;
	NSEnumerator* hostsEnum;
	NSConnection* connection;
	NSError* connectionError;

	if(serverManager != nil)
		return [serverManager retain];
				
	if(self = [super init])
	{	
		hostsFile = [[[ULIOManager appIOManager] applicationDir] 
				stringByAppendingPathComponent: @"AdunHosts.plist"];
		knownHosts = [NSMutableArray arrayWithContentsOfFile: hostsFile];
		[knownHosts retain];
		
		connections = [NSMutableDictionary new];
		connectedHosts = [NSMutableArray new];
		connectionErrors = [NSMutableDictionary new];
		servers = [NSMutableDictionary new];
		
		hostsEnum = [knownHosts objectEnumerator];
		while(host = [hostsEnum nextObject])
		{
			if((connection = [self _connectToServerOnHost: host error: &connectionError]) == nil)
			{
				[connectionErrors setObject: connectionError
					forKey: host];
				connectionError = nil;	
			}
			else
			{
				[self _addConnection: connection toHost: host];
			}
		}
		
		serverManager = self;
	}
	
	return self;
}

- (void) dealloc
{
	NSEnumerator* connectedHostsEnum;
	NSString* host;

	//Logout from all servers
	connectedHostsEnum = [connectedHosts objectEnumerator];
	while(host = [connectedHostsEnum nextObject])
		[self _removeConnectionToHost: host];
	
	[servers release];	
	[connections release];	
	[connectionErrors release];
	[connectedHosts release];
	[knownHosts release];
	[super dealloc];
}

- (BOOL) checkForServerOnHost: (NSString*) host
{
	NSPort* port;
	
	port = nil;
	if([host isEqual: [[NSHost currentHost] name]])
		port = [[NSMessagePortNameServer sharedInstance]
			portForName: @"AdunServer"];
	
	if(port == nil)
#ifdef GNUSTEP	
		port = [[NSSocketPortNameServer sharedInstance]
			portForName: @"AdunServer" 
			onHost: host];
#else
	port = [[NSSocketPortNameServer sharedInstance]
		portForName: @"AdunServer" 
		host: host];
#endif			     
	
	if(port == nil)
		return NO;
	
	return YES;
}

- (NSDictionary*) connectionErrors
{
	return [[connectionErrors copy] autorelease];
}

- (NSArray*) connectedHosts
{
	return [[connectedHosts copy] autorelease];
}

- (NSArray*) allServers
{
	return [servers allValues];
}

- (NSArray*) knownHosts
{
	return [[knownHosts copy] autorelease];
}

- (void) addHost: (NSString*) hostname
{
	NSWarnLog(@"Method %@ not implemented", NSStringFromSelector(_cmd));
}

- (void) addHost: (NSString*) hostname persistant: (BOOL) persistant connectNow: (BOOL) connectNow
{
	NSWarnLog(@"Method %@ not implemented", NSStringFromSelector(_cmd));
}
 
- (id) serverOnHost: (NSString*) hostname
{
	NSConnection* connection;
	NSError* error;

	if(![knownHosts containsObject: hostname])
	{
		[NSException raise: NSInvalidArgumentException
			    format: @"Cannot close connection to unkown host %@", hostname];
	}
	
	//Check if we are connected
	if(![connectedHosts containsObject: hostname])
	{
		//If not connect now
		connection = [self _connectToServerOnHost: hostname error: &error];
		if(connection != nil)
			[self _addConnection: connection toHost: hostname];
		else
			[connectionErrors setObject: error forKey: hostname];
	}
	else
	{
		connection = [connections objectForKey: hostname];
	}
			
	return [connection rootProxy];		
}

- (void) disconnectFromServerOnHost: (NSString*) hostname
{
	[self _removeConnectionToHost: hostname];
}

- (void) disconnectFromServer: (id) server
{
	NSString* hostname;
	NSConnection* connection;
	
	if(![server conformsToProtocol: @protocol(ULServerInterface)])
		[NSException raise: NSInvalidArgumentException
			format: @"Supplied object %@ is not a proxy to an AdServer instance"];
	
	connection = [server connectionForProxy];
	hostname = [[connections allKeysForObject: connection] objectAtIndex: 0];
	[self disconnectFromServerOnHost: hostname];
}

- (void) checkPortTimeoutException: (NSException*) exception
{
	NSEnumerator* connectionEnum;
	NSConnection* connection;
	NSPort* sendPort;

	//The timeout can be due to 
	//A. Connection problems
	//B. Server crash
	//To find which we have to check all the ports of all the remote connections
	//If we find a failed socket port we trigger an NSConnectionDidDieNotification
	
	connectionEnum = [connections objectEnumerator];
	while(connection = [connectionEnum nextObject])
	{
		sendPort = [connection receivePort];
		if([sendPort isMemberOfClass: [NSSocketPort class]])
		{
			//The connection will be invalidated during handling of the notification
			if(![sendPort isValid])
				[[NSNotificationCenter defaultCenter] 
					postNotificationName: NSConnectionDidDieNotification
					object: connection];
		}
	}
}


@end 

