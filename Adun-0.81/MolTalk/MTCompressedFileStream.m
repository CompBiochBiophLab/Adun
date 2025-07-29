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

#include "MTCompressedFileStream.h"
#include "MTString.h"


static NSString *pathToGZIP=nil;

@implementation MTCompressedFileStream


+(void)initialize	//@nodoc
{
	/* find out if we have gzip in our PATH */
	char buf[1024];
#ifdef WIN32
	FILE *p = popen("gzip --version","r");
#else
	FILE *p = popen("which gzip","r");
#endif
	int cread = fread(buf,1,1024,p);
	int result = pclose(p);
#ifndef WIN32
	if (result != 0 || cread<=0 || buf[0]=='w')
	{
		[NSException raise:@"Not Found" format:@"gzip is not in your PATH."];
	}
	buf[cread-1]='\0';
	pathToGZIP = RETAIN([NSString stringWithCString:buf]);
#else
	/* WIN32 */
	//printf("gzip returned: %s\n",buf);
	if (cread<=0 || buf[0]!='g')
	{
		[NSException raise:@"Not Found" format:@"gzip is not in your PATH."];
	}
	pathToGZIP = @"gzip";
#endif
}


-(id)init	//@nodoc
{
	[super init];
	return self;
}

-(void)dealloc	//@nodoc
{
	if (fstream)
	{
		pclose(fstream);
		fstream = NULL;
	}
#ifdef WIN32
	if (path)
	{
		RELEASE(path);
	}
#endif
	[super dealloc];
}


/*
 *   close this stream
 */
-(void)close
{
	if (fstream)
	{
#ifndef WIN32
		pclose(fstream);
#else
		fflush(fstream);
		rewind(fstream);
		/* copy everything from the temporary file to the target file */
		FILE *ftarget = fopen([[path stringByAppendingString:@"._0_"] cString],"w+b");
		if (ftarget)
		{
			char buffer[256];
			int len;
			len = fread(buffer,1,255,fstream);
			while (len > 0)
			{
				fwrite(buffer,1,len,ftarget);
				len = fread(buffer,1,255,fstream);
			}
			fclose(ftarget);
			fclose(fstream);
			/* gzip the target file */
			ftarget = popen([[NSString stringWithFormat:@"%@ -f \"%@\"",pathToGZIP,[path stringByAppendingString:@"._0_"]] cString], "r");
			len = fread(buffer,1,255,ftarget);
			pclose(ftarget);
			buffer[len]='\0';
			if (len > 0)
			{
				printf("gzip returned: %s\n",buffer);
			}
			/* now rename to the original file name */
			len = rename([[path stringByAppendingString:@"._0_.gz"]cString],[path cString]);
			if (len != 0)
			{
				fprintf(stderr, "Could not copy to output file %s. Reason: %s\n",[path cString],strerror(errno));
			}
		}
#endif
		fstream = NULL;
	}
}


/*
 *   returns TRUE if stream exists
 */
-(BOOL)ok
{
	return fstream != NULL;
}


#ifdef SAFEENV
+(id)streamSafeFromFile:(NSString*)t_path
{
	NSString *p_path = [NSString stringWithFormat: @"tempfiles/%@",[t_path lastPathComponent]];
	//printf("CompressedFileStream_streamSafeFromFile: %s\n",[p_path cString ]);
	return [self streamFromFile: p_path];
}
#endif

/*
 *   create stream in readonly mode
 */
+(id)streamFromFile:(NSString*)p_path
{
	MTCompressedFileStream *fs = [MTCompressedFileStream new];
	fs->fstream = popen([[NSString stringWithFormat:@"%@ -dcq \"%@\"",pathToGZIP,p_path] cString], "r");
	if (!fs->fstream)
	{
		NSLog(@"Cannot open stream to file: %@",p_path);
		return nil;
	}
	int n = fgetc(fs->fstream);
	if (n == EOF) {
		pclose(fs->fstream);
		return nil;
	}
	ungetc(n,fs->fstream);

	return AUTORELEASE(fs);
}


#ifdef SAFEENV
+(id)streamSafeToFile:(NSString*)t_path
{
	NSString *p_path = [NSString stringWithFormat: @"tempfiles/%@",[t_path lastPathComponent]];
	//printf("CompressedFileStream_streamSafeToFile: %s\n",[p_path cString]) ;
	return [self streamToFile: p_path];
}
#endif

/*
 *   create stream in writeonly mode
 */
+(id)streamToFile:(NSString*)p_path
{
	MTCompressedFileStream *fs = [MTCompressedFileStream new];
#ifndef WIN32
	fs->fstream = popen([[NSString stringWithFormat:@"%@ -c > \"%@\"",pathToGZIP,p_path] cString], "w");
	//printf("filestream: %d\n",fileno(fs->fstream));
#else
	fs->path = RETAIN(p_path);
	fs->fstream = tmpfile ();
#endif
	return AUTORELEASE(fs);
}


/*
 *   create stream in append mode
 */
+(id)streamAppendToFile:(NSString*)p_path
{
	/* does not make any sense */
	[NSException raise:@"Unsupported" format:@"cannot append to a compressed file."];
	return nil;
}



@end

