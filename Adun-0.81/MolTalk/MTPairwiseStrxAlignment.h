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


#ifndef PWSTRXALIGNMENT_H
#define PWSTRXALIGNMENT_H


#include <Foundation/Foundation.h>


@class MTChain;
@class MTStream;
@class MTMatrix53;

@interface MTPairwiseStrxAlignment : NSObject
{
        @private
	MTChain *chain1;
	MTChain *chain2;
	NSMutableArray *positions;
	BOOL calculated;
	MTMatrix53 *transformation;
	int f_gop, f_gep;
	Class substitutionMatrix;
}

-(NSString*)description;
/*
 *   readonly access
 */
-(MTChain*)chain1;
-(MTChain*)chain2;
-(MTMatrix53*)getTransformation;
-(NSArray*)alignmentPositions;
-(int)gop;
-(int)gep;

/* operations */
-(void)setGop:(int)p_gop;
-(void)setGep:(int)p_gep;
-(int)countPairs;
-(int)countUngappedPairs;
-(int)countPairsMaxDistance:(double)dist;
-(double)calculateRMSD;
-(void)optimize;
-(void)deriveStructuralAlignment; // from superimposition
-(void)globalSequenceInducedStructuralAlignment; // from sequence alignment
-(void)localSequenceInducedStructuralAlignment; // from sequence alignment

/* input/output */
-(void)toStreamAsTCoffee:(MTStream*)stream name1:(NSString*)name1 name2:(NSString*)name2;
-(void)fromStreamAsTCoffee:(MTStream*)stream;

/* creation */
+(MTPairwiseStrxAlignment*)alignmentBetweenChain:(MTChain*)chain1 andChain:(MTChain*)chain2;


@end

#endif /* PWSTRXALIGNMENT_H */

