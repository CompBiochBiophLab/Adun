/*
 Project: Adun
 
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
#ifndef _ULURLDOWNLOAD_
#define _ULURLDOWNLOAD_ 
#include <Foundation/Foundation.h>
#include "ULFramework/ULFrameworkDefinitions.h"
#include "ULFramework/ULIOManager.h"
#include <sys/times.h>

extern NSString* ULURLDownloadDidEndNotification;
extern NSString* ULURLDownloadStatusNotification;

/**
\ingroup classes
Handles all aspects of downloading an URL asynchronously or synchronously.
Can store the downloaded data in an NSData object (using NSURLConnection)
or to a file (using NSURLDownload and only asynchronously in this case).
In both cases the ULURLDownload instance acts as a delegate implementing the default framework
download policy.

The object is first initialised by providing it with the URL to download from.
The download is begun by calling either beginDownload(), performSynchronousDownload(), or beginDownloadToFile:overwrite()
depending where you want the downloaded data to be stored and if it is to be synchronous or not.

Can optionally send notifications indicating the progress of the download process.
The notification is called ULURLDownloadStatusNotification.
The information in the notification is in a format understood by ULProgressPanel.
The default timeout interval for an URL download can be set through the URLTimeoutInterval
user default.
Always sends an ULURLDownloadDidEndNotification on ending of the download 
whether its sucessful or not.
\todo Implement authentification delegate methods.
\todo Implement methods to set redirect behaviour.
\todo Add cancelDownload method
\todo Change so data sent in notification on download amounts changes to MBs when this would be better.
*/
@interface ULURLDownload : NSObject 
{
	BOOL sendNotifications;
	BOOL downloadStarted;
	BOOL downloadFinished;
	BOOL overwriteFlag;
	int expectedLength;
	int bytesReceived;
	double rate;
	NSDate* startDate;
	NSTimeInterval timeoutLength;
	NSURLRequestCachePolicy cachePolicy;
	NSMutableData* receivedData;
	NSURL* downloadURL;
	NSURLRequest* urlRequest;
	NSError* downloadError;
	NSString* destinationFilename;
	NSString* downloadDir;
	NSNotificationCenter* notificationCentre;
	id urlConnection;	//May be an NSURLConnection OR NSURLDownload instance
}
/**
Returns an autoreleased ULURLDownload instance ready to retrieve data from \e theURL
*/
+ (id) downloadFromURL: (NSURL*) theUrl;
/**
As initWithURL:sendNotifications:() with \e flag set to YES
*/
- (id) initWithURL: (NSURL*) theURL;
/**
As initWithURL:cachePolicy:timeoutInterval:sendNotifications:()
with \e cacheStoragePolicy set to NSURLRequestUseProtocolCachePolicy and
\e timeInterval set to the default value (see class docs).
*/
- (id) initWithURL: (NSURL*) theURL sendNotifications: (BOOL) flag;
/**
Returns a new ULURLDownload instance for retrieving the data from \e theURL.
\e cacheStoragePolicy indicates how the downloaded data is cached - see NSURLRequest for more.
\e timeoutInterval indicates how long to wait before canceling the download.
\e sendNotifications indicates whether or not the receiver should send notification on the
progress of the download.
*/
- (id) initWithURL: (NSURL*) theURL 
       cachePolicy: (NSURLRequestCachePolicy) cacheStoragePolicy 
   timeoutInterval: (NSTimeInterval) timeInterval 
 sendNotifications: (BOOL) flag;
/**
The URL being downloaded from.
*/
- (NSURL*) URL;
/**
If there was an error during the download this returns an error object detailing the cause.
*/
- (NSError*) downloadError;
/**
Starts a download process storing the retrieved data in memory.
This method returns immediatly. If the return value is YES then the download has begun in the background.
If NO then a connection could not be made to the URL.
When the download has finished the data can be accessed through the receivedData() method.
*/
- (BOOL) beginDownload;
/**
Starts a download process storing the retreived data in the specified file.
If \e filename is not an absolute path then the file is stored in framework download directory 
(see ULIOManager::downloadDir).
If \e filename is nil then it the suggested filename provided by the url response is used.
In this case the file will be stored in the download directory.
This method returns immediatly. 
If the return value is YES then the download has begun in the background.
If NO then a connection could not be made to the URL.
*/
- (BOOL) beginDownloadToFile: (NSString*) filename overwrite: (BOOL) flag;
/**
Performs a synchronous download from the provided URL i.e. this method does not return
until the download is finished.
Thus no notifications will be sent during this process.
On success returns an NSData object containing the downloaded data.
On failure returns nil and downloadError() returns an NSError object detailing the reason
*/
- (NSData*) performSynchronousDownload;
/**
Returns YES if the download has finished, NO otherwise.
*/
- (BOOL) downloadFinished;
/**
Returns the data downloaded from the URL if beginDownload() was used.
Otherwise returns nil.
*/
- (NSData*) receivedData;
/**
Returns the number of bytes downloaded.
If the downloaded has not finished this is the number of bytes download so far.
Can be used for either an in-memory (beginDownload()) or to file (beginDownloadToFile:overwrite:())
operation.
*/
- (int) downloadedDataSize;
/**
Returns the filename for the downloaded data. 
The filename will be an absolute path.
If this is a file download then the returned string is the filename supplied by the user.
(see beginDownloadToFile:overwrite: for more on this.)
If the download was in memory this is the suggested filename given by the url response,
anchored at the ULIOManager::downloadDir().
Check NSURLResponse for more information.
*/
- (NSString*) filename;
/**
If a download is in progress this is the estimated rate in KB/s.
Otherwise its the rate for the last completed download.
If no download has completed this is 0.
If a download failed its the rate before it failed.
*/
- (double) downloadRate;
/**
Sets an URL to download from
*/
- (void) setURL: (NSURL*) theURL;
/**
Sets the timeout interval
*/
- (void) setTimeoutInterval: (NSTimeInterval) timeInterval;
@end

/**
Defines a convience method for downloading pdb files.
\ingroup classes
*/
@interface ULURLDownload (PDBDownloadingAdditions)
/**
Sets up a ULURLDownload object to download the pdb
given by \e pdbID from the pdb databank in uncompressed
pdb flat-file format.
*/
+ (id) downloadForPDB: (NSString*) pdbID;
@end

#endif

