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


#include "MTChainFactory.h"
#include "privateMTChain.h"


static Class chainFactoryKlass = nil;

@implementation MTChainFactory


/*
 *   helper
 */
+(id)newChainWithCode:(char)code
{
	if (!chainFactoryKlass)
	{
		chainFactoryKlass = self;
	}
	MTChain *res = [chainFactoryKlass newInstance];
	[res setCode:code];
	return res;
}


/*
 *   create instance of target class
 */
+(id)newInstance
{
	return AUTORELEASE([MTChain new]);
}


/*
 *   set class which can instantiate target class
 */
+(void)setDefaultChainFactory:(Class)klass
{
#ifdef __APPLE__
	if (klass && [klass isSubclassOfClass:self])
#else
	if (klass && GSObjCIsKindOf(klass,self))
#endif
	{
		chainFactoryKlass = klass;
	} else {
		[NSException raise:@"unimplemented" format:@"class %@ does not inherit from ChainFactory.",klass];
	}
}


@end

