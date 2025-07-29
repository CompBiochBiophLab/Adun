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

#import "ULFramework/ULURLDownload.h"
#include <unistd.h>

NSString* ULURLDownloadDidEndNotification = @"ULURLDownloadDidEndNotification";
NSString* ULURLDownloadStatusNotification = @"ULURLDownloadStatusNotification";

//Delegate methods for downloads to memory
@interface ULURLDownload (NSURLConnectionDelegateMethods)
@end

//Delegate methods for downloads to files
@interface ULURLDownload (NSURLDownloadDelegateMethods)
@end

static int defaultTimeout;

@implementation ULURLDownload

+ (void) initialize
{
	//Register a default value for URLTimeoutInterval
	[[NSUserDefaults standardUserDefaults] registerDefaults: 
		[NSDictionary dictionaryWithObject: [NSNumber numberWithInt: 60] 
			forKey: @"URLTimeoutInterval"]];
	//Get the value specified for URLTimeoutInterval (may have been overridden by user)		
	defaultTimeout = [[NSUserDefaults standardUserDefaults] integerForKey: @"URLTimeoutInterval"];
}

+ (id) downloadFromURL: (NSURL*) theURL
{
	return [[[self alloc] initWithURL: theURL] autorelease];
}

- (id) initWithURL: (NSURL*) theURL
{
	return [self initWithURL: theURL sendNotifications: YES];
}

- (id) initWithURL: (NSURL*) theURL sendNotifications: (BOOL) flag
{ 
	return [self initWithURL: theURL
		cachePolicy: NSURLRequestUseProtocolCachePolicy
		timeoutInterval: defaultTimeout
		sendNotifications: flag];
}

- (id) initWithURL: (NSURL*) theURL 
	cachePolicy: (NSURLRequestCachePolicy) cacheStoragePolicy 
	timeoutInterval: (NSTimeInterval) timeInterval 
	sendNotifications: (BOOL) flag
{
	if((self = [super init]))
	{
		downloadError = nil;
		urlConnection = nil;
		receivedData = nil;
		startDate = nil;
		overwriteFlag = YES;
		expectedLength = -1;
		bytesReceived = 0;
		downloadURL = [theURL retain];
		timeoutLength = timeInterval;
		sendNotifications = flag;
		cachePolicy = cacheStoragePolicy;
		downloadDir = [[ULIOManager appIOManager] downloadDir];
		notificationCentre = [NSNotificationCenter defaultCenter];
		urlRequest = [[NSURLRequest alloc] 
				initWithURL: downloadURL 
				cachePolicy: cachePolicy 
				timeoutInterval: timeoutLength];
	}
	
	return self;
}

- (void) dealloc
{
	[startDate release];
	[destinationFilename release];
	[downloadError release];
	[urlConnection release];
	[urlRequest release];
	[downloadURL release];
	[receivedData release];
	[super dealloc];
}

- (NSURL*) URL
{
	return [[downloadURL retain] autorelease];
}

//For a in memory download (using NSURLConnection) returns the 
//suggested filename provided by the URL response.
//For a file downloaded will return the complete path to the target file.
//In the case of a in memory download or if no file was specified for a
//file download this method will return nil until a suggested filename
//has been obtained.
- (NSString*) filename
{
	return [[destinationFilename retain] autorelease];
}

- (NSError*) downloadError
{
	return [[downloadError retain] autorelease];
}

- (BOOL) beginDownload
{
	//Check a download isnt already running
	if(downloadStarted == YES)
		return YES;

	//Clear from last download
	if(downloadError != nil)
		[downloadError release];
	
	[receivedData release];
	[urlConnection release];
	[destinationFilename release];
	[startDate release];
	
	//Setup for new download
	destinationFilename = nil;
	rate = 0.0;
	expectedLength = -1;
	bytesReceived = 0;
	receivedData = [NSMutableData new];
	startDate = [[NSDate date] retain];
	urlConnection = [[NSURLConnection alloc] 
				initWithRequest: urlRequest delegate: self];
	if(urlConnection == nil)
		return NO;
	
	downloadFinished = NO;
	downloadStarted = YES;
	return YES;
}

- (BOOL) beginDownloadToFile: (NSString*) filename overwrite: (BOOL) flag
{ 
	//Check a download isnt already running
	if(downloadStarted == YES)
		return YES;
	
	//Clear from last download
	if(downloadError != nil)
		[downloadError release];
	
	[receivedData release];
	[urlConnection release];
	[destinationFilename release];
	[startDate release];
	
	//Setup for file download
	if(filename != nil)
	{
		if(![filename isAbsolutePath])
		{
			//Strip any path information
			filename = [filename lastPathComponent];
			filename = [downloadDir stringByAppendingPathComponent: filename];	
		}
		destinationFilename = [filename retain];	
	}
	else
		destinationFilename = nil;
		
	receivedData = nil;
	overwriteFlag = flag;
	rate = 0.0;
	expectedLength = -1;
	bytesReceived = 0;
	startDate = [[NSDate date] retain];
	urlConnection = [[NSURLDownload alloc] 
				initWithRequest: urlRequest delegate: self];
							
	if(urlConnection == nil)
		return NO;
	
	downloadFinished = NO;
	downloadStarted = YES;
	return YES;
}

- (NSData*) performSynchronousDownload
{
	NSData* data;
	
	//Check a download isnt already running
	if(downloadStarted == YES)
		return nil;
	
	//Clear from last download
	if(downloadError != nil)
	{
		[downloadError release];
		downloadError = nil;
	}
	
	[receivedData release];
	[urlConnection release];
	[destinationFilename release];
	[startDate release];
	
	//Setup for new download
	destinationFilename = nil;
	rate = 0.0;
	expectedLength = -1;
	bytesReceived = 0;
	
	startDate = [[NSDate date] retain];
	data = [NSURLConnection sendSynchronousRequest: urlRequest 
				     returningResponse: NULL 
						 error: &downloadError];
	[self downloadRate];		
	receivedData = [data copy];;		
	
	downloadFinished = YES;
	downloadStarted = NO;
	
	return data;
}

- (BOOL) downloadFinished
{
	return downloadFinished;
}

//Returns a copy of receivedData. 
//This will be nil if the URL contents were downloaded to a file.
- (NSData*) receivedData
{
	return [[receivedData copy] autorelease];
}

- (int) downloadedDataSize
{
	return bytesReceived;
}

- (void) cancel
{
	if(!downloadFinished && (urlConnection != nil))
	{
		[urlConnection cancel];
		[receivedData release];
		[destinationFilename release];
		destinationFilename = nil;
		receivedData = nil;
		downloadFinished = YES;
		downloadStarted = NO;
		expectedLength = -1;
		bytesReceived = 0;
	}
}

- (NSString*) description
{
	if(downloadURL == nil)
		return @"No URL specified for download";

	if(downloadFinished && downloadError == nil && receivedData != nil)	
		return [NSString stringWithFormat:
			@"Completed downloaded from %@. Data received %d bytes. Rate %.1lf KB/s",
			downloadURL, bytesReceived, [self downloadRate]];

	if(downloadFinished && downloadError != nil)	
		return [NSString stringWithFormat:
			@"Attempted download from %@. There was an error %@",
			downloadURL, downloadError];	

	if(!downloadStarted)
		return [NSString stringWithFormat:
			@"Preparing to download from %@.", downloadURL];
			
	if(downloadStarted && !downloadFinished)
		return [NSString stringWithFormat:
			@"Downloading from %@. Data received %d bytes. Expected %d.  Rate %.1lf KB/s",
			downloadURL, bytesReceived, expectedLength, [self downloadRate]];
			
	return @"URLDownload - Unknown status";		
}

- (double) downloadRate
{
	NSTimeInterval timeInterval;
	
	if(downloadFinished == NO)
	{	
		timeInterval = [[NSDate date] timeIntervalSinceDate: startDate];
		rate = bytesReceived/(timeInterval*1024.0);
	}
		
	return rate;	
}

//Retain the new URL and create a new URL request.
- (void) setURL: (NSURL*) theURL
{
	if(downloadStarted)
		return;
	
	[downloadURL release];
	downloadURL = [theURL retain];	
	
	//Create new request
	[urlRequest release];
	urlRequest = [[NSURLRequest alloc] 
			initWithURL: downloadURL 
			cachePolicy: cachePolicy 
			timeoutInterval: timeoutLength];
}

- (void) setTimeoutInterval: (NSTimeInterval) timeInterval
{
	if(downloadStarted)
		return;
	
	timeoutLength = timeInterval;
}

@end

//Category containing methods for downloads to files
@implementation ULURLDownload (NSURLDownloadDelegateMethods)

//Here we set the download filename if one was supplied
//If not we use the suggested filename and save it to the downloadDir
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{	
	if(destinationFilename == nil)
	{
		destinationFilename = [downloadDir stringByAppendingPathComponent: filename];
		[destinationFilename retain];
	}

	[download setDestination: destinationFilename allowOverwrite: overwriteFlag];
}

//Received when the download connects to the server.
//Get the expected size (in bytes) of the download
//Can be received more than once - need to reset length each time
-(void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	NSDebugLLog(@"ULURLDownload", @"%@", [self description]);

	expectedLength = [response expectedContentLength];
	bytesReceived = 0.0;
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
			object: self
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt: expectedLength],
					@"ULProgressOperationTotalSteps",
					[NSNumber numberWithInt: 0],
					@"ULProgressOperationCompletedSteps", 
					[NSString stringWithFormat: @"Beginning download - Expecting %.1lf KB",
						expectedLength/1024.0],
					@"ULProgressOperationInfoString", nil]];
	}
}

//Notifies when a chunk of data has been downloaded.
//Update the bytesReceived ivar.
- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(int)length
{
	NSDebugLLog(@"ULURLDownload", @"%@", [self description]);
	bytesReceived += length;
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
			object: self
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt: expectedLength],
					@"ULProgressOperationTotalSteps",
					[NSNumber numberWithInt: bytesReceived],
					@"ULProgressOperationCompletedSteps",
					[NSString stringWithFormat: @"Downloading - %.1lf of %.1lf KB at %.1lf KB/s",
						bytesReceived/1024.0,
						expectedLength/1024.0,
						[self downloadRate]],
					@"ULProgressOperationInfoString", nil]];	
	}
}

//Sent when a download fails
//Clean up the download, print an error message and send ULURLDownloadDidEndNotification
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[destinationFilename release];
	destinationFilename = nil;
	downloadFinished = YES;
	downloadStarted = NO;
	downloadError = [error retain];
	
	NSLog(@"%@", [self description]);	

	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
			object: self
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt: expectedLength],
					@"ULProgressOperationTotalSteps",
					[NSNumber numberWithInt: expectedLength],
					@"ULProgressOperationCompletedSteps",
					[NSString stringWithFormat: @"Error - Download Failed - %lf KB received",
						bytesReceived/1024.0],
					@"ULProgressOperationInfoString", nil]];		
	}
	
	[notificationCentre postNotificationName: ULURLDownloadDidEndNotification
		object: self];
}

//Received when the download completes writing to the file.
//Clean up and sen ULURLDownloadDidEndNotification
-(void)downloadDidFinish:(NSURLDownload *)download
{
	downloadFinished = YES;
	downloadStarted = NO;
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
			object: self
			userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt: expectedLength],
					@"ULProgressOperationTotalSteps",
					[NSNumber numberWithInt: expectedLength],
					@"ULProgressOperationCompletedSteps",
					[NSString stringWithFormat: @"Download Complete - %.2lf KB at %.1lf KB/s",
						bytesReceived/1024.0,
						[self downloadRate]],
					@"ULProgressOperationInfoString", nil]];
	}
	
	[notificationCentre
		postNotificationName: ULURLDownloadDidEndNotification
		object: self];
		
	NSDebugLLog(@"ULURLDownload@", @"%@", [self description]);		
}

@end

//Category containing delegate methods for NSURLConnection (in memory downloads)
@implementation ULURLDownload (NSURLConnectionDelegateMethods)

//Received when the connection connects to the URL.
//Can be received multiple times - each time receivedData must be emptied
//and bytesReceived reset.
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSDebugLLog(@"ULURLDownload", @"%@", [self description]);
	
	[receivedData setLength: 0];
	destinationFilename = [[response suggestedFilename] retain];
	expectedLength = [response expectedContentLength];
	bytesReceived = 0.0;
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
						  object: self
						userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: expectedLength],
							@"ULProgressOperationTotalSteps",
							[NSNumber numberWithInt: 0],
							@"ULProgressOperationCompletedSteps", 
							[NSString stringWithFormat: @"Beginning download - Expecting %.1lf KB",
								expectedLength/1024.0],
							@"ULProgressOperationInfoString", nil]];
	}
}

//Receive when the connection receives a chunk of data.
//Add this to the receivedData ivar and update bytesReceived.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSDebugLLog(@"ULURLDownload", @"%@", [self description]);
	[receivedData appendData: data];
	bytesReceived = [receivedData length];
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
						  object: self
						userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: expectedLength],
							@"ULProgressOperationTotalSteps",
							[NSNumber numberWithInt: bytesReceived],
							@"ULProgressOperationCompletedSteps",
							[NSString stringWithFormat: @"Downloading - %.1lf of %.1lf KB at %.1lf KB/s",
								bytesReceived/1024.0,
								expectedLength/1024.0,
								[self downloadRate]],
							@"ULProgressOperationInfoString", nil]];	
	}
}

//Received when the connection fails for some reason.
//Retain error, clean up, log error and send ULURLDownloadDidEndNotification
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[receivedData release];
	[destinationFilename release];
	destinationFilename = nil;
	receivedData = nil;
	downloadFinished = YES;
	downloadStarted = NO;
	downloadError = [error retain];
	
	NSLog(@"%@", [self description]);	
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
						  object: self
						userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: expectedLength],
							@"ULProgressOperationTotalSteps",
							[NSNumber numberWithInt: expectedLength],
							@"ULProgressOperationCompletedSteps",
							[NSString stringWithFormat: @"Error - Download Failed",
								bytesReceived/1024.0],
							@"ULProgressOperationInfoString", nil]];		
	}

	[notificationCentre postNotificationName: ULURLDownloadDidEndNotification
					  object: self];
}

//Received when all data has been retrieved from the URL.
//Clean up the download and send ULURLDownloadDidEndNotification
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	downloadFinished = YES;
	downloadStarted = NO;
	
	if(sendNotifications)
	{
		[notificationCentre postNotificationName: ULURLDownloadStatusNotification
						  object: self
						userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt: expectedLength],
							@"ULProgressOperationTotalSteps",
							[NSNumber numberWithInt: expectedLength],
							@"ULProgressOperationCompletedSteps",
							[NSString stringWithFormat: @"Download Complete - %.2lf KB at %.1lf KB/s",
								bytesReceived/1024.0,
								[self downloadRate]],
							@"ULProgressOperationInfoString", nil]];
	}
	
	[notificationCentre
		postNotificationName: ULURLDownloadDidEndNotification
			      object: self];
	
	NSDebugLLog(@"ULURLDownload@", @"%@", [self description]);		
}

@end

@implementation ULURLDownload (PDBDownloadingAdditions)

+ (id) downloadForPDB: (NSString*) pdbID
{
	NSURL* theURL;
	NSString* path;
	//Create the URL
	//http:// www.rcsb.org/pdb/download/downloadFile.do?fileFormat=pdb&compression=NO&structureId=XXXX
	
	path = [@"/pdb/download/downloadFile.do?fileFormat=pdb&compression=NO&structureId=" 
			stringByAppendingString: pdbID];
	theURL = [[NSURL alloc] initWithScheme: @"http" host: @"www.rcsb.org" path: path];
	[theURL autorelease];
	
	return [self downloadFromURL: theURL];
}

@end
