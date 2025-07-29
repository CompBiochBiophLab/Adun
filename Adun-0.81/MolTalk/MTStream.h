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


#ifndef MTSTREAM_H
#define MTSTREAM_H

#include <Foundation/Foundation.h>
#ifndef GNUSTEP
#include "GNUstepAdditions.h"
#endif

/*
 *   Class @MTStream is an abstract class which defines the interface
 *   subclasses should implement.
 *
 */
@interface MTStream : NSObject
{
}


/* test */
-(BOOL)ok;

/* operation */
-(void)close;

/* write access */
-(void)writeData:(NSData*)data;
-(void)writeString:(NSString*)string;
-(void)writeCString:(const char*)string;

/* read access */
-(NSData*)readLength:(unsigned int)len;
-(NSData*)readLineLength:(unsigned int)len;
-(NSString*)readStringLineLength:(unsigned int)len;


@end

#endif /* MTSTREAM_H */
 
