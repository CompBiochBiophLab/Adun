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


#ifndef MTSELECTION_H
#define MTSELECTION_H
 
 
#include <Foundation/Foundation.h>

@class MTMatrix53;
@class MTResidue;
@class MTChain;

@interface MTSelection : NSObject
{
        @protected
	MTChain *chain;
	NSMutableArray *selection;
}

/* access */
-(unsigned long)count;
-(NSString*)description;
-(NSMutableArray*)getSelection;
-(NSEnumerator*)selectedResidues;

/* operations */
-(BOOL)containsResidue: (MTResidue*)r;
-(id)addResidue: (MTResidue*)r;
-(id)removeResidue: (MTResidue*)r;
-(id)difference:(MTSelection*)sel2;
-(id)union:(MTSelection*)sel2;

/* structural alignment of two selections */
-(MTMatrix53*)alignTo: (MTSelection*)sel2;

/* creation */
+(MTSelection*)selectionWithChain: (MTChain*)c;

@end

#endif /* MTSELECTION_H */
 
