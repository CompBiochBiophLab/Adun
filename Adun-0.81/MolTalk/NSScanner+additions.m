/* Copyright 2005-2006  Alexander V. Diemand

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

#include "NSScanner+additions.h"


@implementation NSScanner (MolTalkAdditions)


/*
 *   scans an integer
 */ 
-(NSNumber*)scanInt
{
	int ival;
	if ([self scanInt: &ival])
	{
		return [NSNumber numberWithInt: ival];
	}
	return nil;
}


/*
 *   scans a real
 */ 
-(NSNumber*)scanReal
{
	double fval;
	if ([self scanDouble: &fval])
	{
		return [NSNumber numberWithDouble: fval];
	}
	return nil;
}


/*
 *   scans a string
 */
-(NSString*)scanStringUpto:(NSString*)endl
{
	NSString *sval;
	if ([self scanUpToString: endl intoString: &sval])
	{
		return sval;
	}
	return nil;
}


@end
