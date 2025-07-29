/* Copyright 2003-2006  Alexander V. Diemand

    This file is part of MolTalk.

    MolTalk is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    MolTalk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with MolTalk; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 */
 
/* vim: set filetype=objc: */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


#include "MTFileStream.h"
#include "MTString.h"


@implementation MTFileStream


-(id)init	//@nodoc
{
	[super init];
	fstream = NULL;
	return self;
}

-(void)dealloc	//@nodoc
{
	if (fstream)
	{
		fflush(fstream);
		fclose(fstream);
		fstream = NULL;
	}
	[super dealloc];
}


/*
 *   returns TRUE if stream is not at the end
 */
-(BOOL)ok
{
	if (!fstream)
	{
		return NO;
	} else {
		return !feof(fstream);
	}
}


/*
 *   close this stream
 */
-(void)close
{
	if (fstream)
	{
		fflush(fstream);
		fclose(fstream);
		fstream = NULL;
	}
}


/*
 *   read a line from stream up to /len/ length
 */
-(char*)getsBuffer:(char*)buffer len:(int)len
{
	if (!fstream)
	{
		return NULL;
	}
	return fgets(buffer,len+1,fstream);
}


/*
 *   write /buffer/ to stream
 */
-(int)writeBuffer:(char*)buffer len:(int)len
{
	if (!fstream)
	{
		return 0;
	}
	return fwrite(buffer,1,len,fstream);
}


/*
 *   read into /buffer/ up to /len/ length
 */
-(int)readBuffer:(char*)buffer len:(int)len
{
	if (!fstream)
	{
		return 0;
	}
	return fread(buffer,1,len,fstream);
}


/*
 *   write data to stream
 */
-(void)writeData:(NSData*)data
{
	if (!fstream)
	{
		return;
	}
	unsigned int len = [data length];
	unsigned int written = 0;
	while (written < len)
	{
		written += [self writeBuffer:(char*)([data bytes]+written) len:(len-written)];
	}
}


/*
 *   write a string to the stream
 */
-(void)writeString:(NSString*)string
{
	[self writeData: [string data]];
}


/*
 *   write a C string (/const char * /) to the stream
 */
-(void)writeCString:(const char*)string
{
/*	unsigned int len=strlen(string);
	//[self writeData: [NSData dataWithBytes: string length: len]]; 
	[self writeBuffer:string len:len];*/
	if (!fstream)
	{
		return;
	}
	fprintf(fstream, "%s", string);
}


/*
 *   read data from stream up to /len/ length
 */
-(NSData*)readLength:(unsigned int)len
{
	if (!fstream)
	{
		return nil;
	}
	char *buffer = (char*)malloc(len);
	unsigned int bytesread = 0;
	while (bytesread < len)
	{
		bytesread += [self readBuffer:buffer len:len];
		if (![self ok])
		{
			break;
		}
	}
	return [NSData dataWithBytesNoCopy: buffer length: bytesread];
}


/*
 *   read line up to /len/ length
 */
-(NSData*)readLineLength:(unsigned int)len
{
	if (!fstream)
	{
		return nil;
	}
	char *buffer = (char*)malloc(len+3);
	buffer[len+2]='\0';
	if ([self getsBuffer:buffer len:(len+1)] != NULL)
	{
		unsigned int reallength;
		reallength = strlen(buffer);
		return [NSData dataWithBytesNoCopy: buffer length: reallength];
	}
	return nil;
}

- (void) flush
{
	fflush(fstream);
}

/*
 *   read line up to /len/ length and return in string
 */
-(NSString*)readStringLineLength:(unsigned int)len
{
	if (!fstream)
	{
		return nil;
	}
	char buffer[8194];
	if (len>8192)
	{
		len=8192;
	}
	buffer[len+2]='\0';
	if ([self getsBuffer:buffer len:(len+1)] != NULL)
	{
		return [NSString stringWithCString: buffer];
	}
	return nil;
}


#ifdef SAFEENV
+(id)streamSafeFromFile:(NSString*)t_path
{
	NSString *p_path = [NSString stringWithFormat: @"tempfiles/%@",[t_path lastPathComponent]];
        //printf("FileStream_streamSafeFromFile: %s\n",[t_path cString]);
	return [self streamFromFile: p_path];
}
#endif

/*
 *   create a stream from a file in readonly mode
 */
+(id)streamFromFile:(NSString*)path;
{
	MTFileStream *fs = [MTFileStream new];
        //printf("FileStream_streamFromFile: %s\n",[path cString]);
#ifdef WIN32
	fs->fstream = fopen([path cString], "rb");
#else
	fs->fstream = fopen([path cString], "r");
#endif
	return fs;
}


#ifdef SAFEENV
+(id)streamSafeToFile:(NSString*)t_path
{
	NSString *p_path = [NSString stringWithFormat: @"tempfiles/%@",[t_path lastPathComponent]];
        //printf("FileStream_streamSafeToFile: %s\n",[p_path cString]);
	return [self streamToFile: p_path];
}
#endif

/*
 *   create a stream from a file in writeonly mode
 */
+(id)streamToFile:(NSString*)path;
{
	MTFileStream *fs = [MTFileStream new];
        //printf("FileStream_streamToFile: %s\n",[path cString]);
#ifdef WIN32
	fs->fstream = fopen([path cString], "wb");
#else
	fs->fstream = fopen([path cString], "w");
#endif
	return [fs autorelease];
}


#ifdef SAFEENV
+(id)streamSafeAppendToFile:(NSString*)t_path
{
	NSString *p_path = [NSString stringWithFormat: @"tempfiles/%@",[t_path lastPathComponent]];
        //printf("FileStream_streamSafeAppendToFile: %s\n",[t_path cString]);
        return [self streamAppendToFile: p_path];
}
#endif

/*
 *   create a stream from a file in append mode
 */
+(id)streamAppendToFile:(NSString*)path;
{
	MTFileStream *fs = [MTFileStream new];
        //printf("FileStream_streamAppendToFile: %s\n",[path cString]);
#ifdef WIN32
	fs->fstream = fopen([path cString], "ab");
#else
	fs->fstream = fopen([path cString], "a");
#endif
	return fs;
}


/*
 *   return TRUE if the indicated file is compressed
 */
+(BOOL)isFileCompressed:(NSString*)filepath
{
	unsigned char buffer[6];
	buffer[0]='\0';buffer[1]='\0'; buffer[2]='\0';
	buffer[3]='\0';buffer[4]='\0'; buffer[5]='\0';
	FILE *t_file = fopen([filepath cString],"r");
	if (t_file)
	{
		fread(buffer,1,2,t_file);
		//printf("file compressed? %03d %03d\n",buffer[0],buffer[1]);
		fclose(t_file);
		if (buffer[0]==31 && buffer[1]==157)
		{	/* compress */
			return YES;
		}
		if (buffer[0]==31 && buffer[1]==139)
		{	/* gzip */
			return YES;
		}
	}
	return NO;
}


/*
 *   return TRUE if the indicated file is readable
 */
+(BOOL)checkFileStat:(NSString*)filepath
{
	struct stat fstatbuf;
	//printf ("FileStream_checkFileStat: %s\n",[filepath cString]);
	if (stat ([filepath cString], &fstatbuf) == 0)
	{
		if (!S_ISREG(fstatbuf.st_mode))
		{
			NSLog(@"file %@ is not a regular one.",filepath);
			return NO;
		}
#ifndef WIN32
		gid_t ourgid = getegid ();
		uid_t ouruid = geteuid ();
		if (fstatbuf.st_uid == ouruid && (fstatbuf.st_mode&S_IRUSR))
		{
			/* might have access ? */
			return YES;
		}
		if (fstatbuf.st_gid == ourgid && (fstatbuf.st_mode&S_IRGRP))
		{
			/* might have access ? */
			return YES;
		}
		if (fstatbuf.st_mode&S_IROTH)
		{
			/* might have access ? */
			return YES;
		}
#else
		/* under windoze we just claim to have access */
		/* this needs to be done at some later stage ... */
		return YES;
#endif
#ifdef DO_NOT_BE_SO_QUIET
	} else {
		NSLog(@"file %@ does not exist.",filepath);
#endif
	}
	return NO;
}


@end

