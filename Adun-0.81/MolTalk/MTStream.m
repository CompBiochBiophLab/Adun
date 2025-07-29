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

#include "MTStream.h"
#include "MTFileStream.h"


@implementation MTStream


/*
 *   is this stream still valid?
 */
-(BOOL)ok
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
	return NO;
}


/*
 *   close the stream and release any low level resources
 */
-(void)close
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
}


/* 
 *   writes data to the stream
 */
-(void)writeData:(NSData*)data
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
}


/* 
 *   writes string to the stream
 */
-(void)writeString:(NSString*)string
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
}


/* 
 *   writes C string to the stream
 */
-(void)writeCString:(const char*)string
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
}


/*
 *   read data from the stream (max length)
 */
-(NSData*)readLength:(unsigned int)len
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
	return nil;
}


/*
 *   read a line from the stream (max length)
 */
-(NSData*)readLineLength:(unsigned int)len
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
	return nil;
}


/*
 *   read a line from the stream (max length)
 */
-(NSString*)readStringLineLength:(unsigned int)len
{
	[NSException raise:@"unimplemented" format:@"class Stream is abstract."];
	return nil;
}


@end

