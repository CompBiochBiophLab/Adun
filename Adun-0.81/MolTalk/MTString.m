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

#include "MTString.h"


@implementation NSString (ClippedString)


/*
 *   remove spaces at the beginning and the end of the text
 */ 
-(NSString*)clip
{
	char *nm = (char*)[self cString];
	unsigned int len = strlen(nm);
	unsigned int i=0;
	while (nm[i] == ' ')
	{
		i++;
		if (i>=(len-1))
		{
			break;
		}
	}
	unsigned int j=len-1;
	while (nm[j] == ' ')
	{
		j--;
		if (j==i)
		{
			break;
		}
	}
	nm[j+1]='\0';
	return [NSString stringWithCString: (nm+i)];
}


/*
 *   remove spaces at the beginning of the text, keep right part
 */
-(NSString*)clipleft
{
	char *nm = (char*)[self cString];
	unsigned int len = strlen(nm);
	unsigned int i=0;
	while (nm[i] == ' ')
	{
		i++;
		if (i>=(len-1))
		{
			break;
		}
	}
	return [NSString stringWithCString: (nm+i)];
}


/*
 *   remove spaces at the end of the text, keep left part
 */
-(NSString*)clipright
{
	char *nm = (char*)[self cString];
	unsigned int j=strlen(nm)-1;
	while (nm[j] == ' ')
	{
		j--;
		if (j==0)
		{
			break;
		}
	}
	nm[j+1]='\0';
	return [NSString stringWithCString: nm];
}


/* 
 *   abbreviation for [string dataUsingEncoding: [NSString defaultCStringEncoding]]
 */
-(NSData*)data
{
	return [self dataUsingEncoding: [NSString defaultCStringEncoding]];
}


/*
 *   quote all single strokes
 */
-(NSString*)quoted
{
	NSRange range;
	range = [self rangeOfString: @"'"];
	if (range.length>0)
	{
		NSString *res=@"";
		NSString *str=self;
		//NSString *str1;
		//NSString *str2;
		while (range.length>0)
		{
			res = [[res stringByAppendingString: [str substringToIndex: range.location]] stringByAppendingString: @"\\'"];
			str = [str substringFromIndex: range.location+1];
			range = [str rangeOfString: @"'"];
		}
		res = [res stringByAppendingString: str];
		return res;
	} else {
		return self;
	}
}


+(NSString*)stringFromCharArray: (NSArray*)p_arr
{
	NSString *res;
	char *buffer;
	int len;
	int i;
	id obj;
	Class klass;
	if (! p_arr)
	{
		return nil;
	}

	len = [p_arr count];
	buffer = (char*)malloc(len*sizeof(char)+1);
	for (i=0; i<len; i++)
	{
		obj = [p_arr objectAtIndex: i];
		klass = [obj class];
#ifdef __APPLE__
		if ([klass isSubclassOfClass:[NSNumber class]])
#else
		if (klass && GSObjCIsKindOf(klass,[NSNumber class]))
#endif
		{
			buffer[i] = [obj charValue];
		} else {
			buffer[i] = '\0';
		}
	}
	buffer[len] = '\0';

	res = [NSString stringWithFormat:@"%s", buffer]; 
	free(buffer);

	return res;
}


@end
