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


#include "MTAtomFactory.h"
#include "MTAtom.h"


static Class atomFactoryKlass = nil;

@implementation MTAtomFactory




+(id)newAtomWithNumber:(unsigned int)serial name:(char*)aname X:(double)x Y:(double)y Z:(double)z B:(float)bfact
{
	if (!atomFactoryKlass)
	{
		atomFactoryKlass = self;
	}
	char laname[5];
	laname[0]='\0'; laname[1]='\0'; laname[2]='\0'; laname[3]='\0'; laname[4]='\0';
	int l = aname?strlen(aname):0;
	if (l > 4) l=4;
	int i;
	for (i=0; i<l; i++)
	{
		laname[i] = aname[i];
	}
	MTAtom *res = [atomFactoryKlass newInstance];
	[res setTemperature: bfact];
	[res setNumber: serial];
	[res setName: laname];
	[res setX:x Y:y Z:z];
	return res;
}

+(id)createAtomWithNumber:(NSNumber*)serial name:(NSString*)aname X:(NSNumber*)x Y:(NSNumber*)y Z:(NSNumber*)z B:(NSNumber*)bfact
{
	//printf(" #%@ '%@' (%@,%@,%@) @%@\n", serial, aname, x, y, z, bfact);
	return [self newAtomWithNumber: [serial intValue] name: (char*)[aname cString] X: [x doubleValue] Y: [y doubleValue] Z: [z doubleValue] B: [bfact floatValue]];
}


/*
 *   This method creates an instance of the target class and must be reimplemented in subclasses.
 */
+(id)newInstance
{
	return AUTORELEASE([MTAtom new]);
}


/*
 *   Sets the default factory class
 */
+(void)setDefaultAtomFactory:(Class)klass
{
#ifdef __APPLE__
	if (klass && [klass isSubclassOfClass:self])
#else
	if (klass && GSObjCIsKindOf(klass,self))
#endif
	{
		atomFactoryKlass = klass;
	} else {
		[NSException raise:@"unimplemented" format:@"class %@ does not inherit from MTAtomFactory.",klass];
	}
}


@end

