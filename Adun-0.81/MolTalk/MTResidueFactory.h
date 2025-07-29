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


#ifndef MTRESIDUEFACTORY_H
#define MTRESIDUEFACTORY_H


#include <Foundation/Foundation.h>

@class MTResidue;

/*
 *  This factory can instantiate objects of the class @MTResidue.
 *  If you want to create subclasses of @MTResidue, implement
 *  a subclass of @self and overwrite @method(MTResidueFactory,+newInstance).
 *  Then set it to be the new default factory class with @method(MTResidueFactory,+setDefaultResidueFactory:).
 *
 */
@interface MTResidueFactory : NSObject
{
}


+(id)createResidueWithNumber:(NSNumber*)resnr name:(NSString*)rname;
+(id)newResidueWithNumber:(int)resnr name:(const char*)name;
+(id)newResidueWithNumber:(int)resnr subcode:(char)icode name:(const char*)name;


+(id)newInstance;

+(void)setDefaultResidueFactory:(Class)klass;

@end

#endif /* MTRESIDUEFACTORY_H */
 
