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


#ifndef MTFILESTREAM_H
#define MTFILESTREAM_H


#include <Foundation/Foundation.h>

#include "MTStream.h"


@interface MTFileStream : MTStream
{
	@protected
	FILE *fstream;
}

/* read/write */
-(char*)getsBuffer:(char*)buffer len:(int)len;
-(int)writeBuffer:(char*)buffer len:(int)len;
-(int)readBuffer:(char*)buffer len:(int)len;

/* file information */
+(BOOL)isFileCompressed:(NSString*)path;
+(BOOL)checkFileStat:(NSString*)path;


/* creation */
#ifdef SAFEENV
+(id)streamSafeFromFile:(NSString*)path;
+(id)streamSafeToFile:(NSString*)path;
+(id)streamSafeAppendToFile:(NSString*)path;
#endif

+(id)streamFromFile:(NSString*)path;
+(id)streamToFile:(NSString*)path;
+(id)streamAppendToFile:(NSString*)path;

@end

#endif /* MTFILESTREAM_H */

