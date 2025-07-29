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


#ifndef MTATOMFACTORY_OH
#define MTATOMFACTORY_OH


#include <Foundation/Foundation.h>

/*
 *  This factory can instantiate objects of the class @MTAtom.
 *  If you want to create subclasses of @MTAtom, implement
 *  a subclass of @self and overwrite @method(MTAtomFactory,+newInstance).
 *  Then set it to be the new default factory class with @method(MTAtomFactory,+setDefaultAtomFactory:).
 *
 */
@interface MTAtomFactory : NSObject
{
}

+(id)newAtomWithNumber:(unsigned int)serial name:(char*)aname X:(double)x Y:(double)y Z:(double)z B:(float)bfact;
+(id)createAtomWithNumber:(NSNumber*)serial name:(NSString*)aname X:(NSNumber*)x Y:(NSNumber*)y Z:(NSNumber*)z B:(NSNumber*)bfact;


+(id)newInstance;

+(void)setDefaultAtomFactory:(Class)klass;

@end

#endif /* MTATOMFACTORY_OH */
 
