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


#include "MTResidueFactory.h"
#include "privateMTResidue.h"


static Class residueFactoryKlass = nil;

@implementation MTResidueFactory


+(id)createResidueWithNumber:(NSNumber*)resnr name:(NSString*)rname
{
	return [self newResidueWithNumber:[resnr intValue] subcode:' ' name: [rname cString]];
}

+(id)newResidueWithNumber:(int)resnr name:(char*)rname
{
	return [self newResidueWithNumber:resnr subcode:' ' name:rname];
}

+(id)newResidueWithNumber:(int)resnr subcode:(char)icode name:(char*)rname
{
	if (!residueFactoryKlass)
	{
		residueFactoryKlass = self;
	}
	MTResidue *res = [residueFactoryKlass newInstance];
	[res setName:[NSString stringWithCString:rname]];
	[res setNumber:[NSNumber numberWithInt:resnr]];
	[res setSubcode:icode];
	return res;
}

/*
 *   This method creates an instance of the target class and must be reimplemented in subclasses.
 */
+(id)newInstance
{
	return AUTORELEASE([MTResidue new]);
}


/*
 *   Sets the default factory class
 */
+(void)setDefaultResidueFactory:(Class)klass
{
#ifdef __APPLE__
	if (klass && [klass isSubclassOfClass:self])
#else
	if (klass && GSObjCIsKindOf(klass,self))
#endif
	{
		residueFactoryKlass = klass;
	} else {
		[NSException raise:@"unimplemented" format:@"class %@ does not inherit from ResidueFactory.",klass];
	}
}


@end

