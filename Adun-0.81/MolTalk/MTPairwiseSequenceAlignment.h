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


#ifndef MTPWSEQALIGNMENT_OH
#define MTPWSEQALIGNMENT_OH


#include <Foundation/Foundation.h>

@class MTResidue;
@class MTChain;
@class MTSelection;
@class MTStream;

@interface MTPairwiseSequenceAlignment : NSObject
{
        @private
	MTChain *chain1;
	MTChain *chain2;
	NSMutableArray *positions;
	BOOL computed;
	int f_gop, f_gep;
	Class substitutionMatrix;
}

-(NSString*)description;

/*
 *   readonly access
 */
-(MTChain*)chain1;
-(MTChain*)chain2;

-(NSString*)getSequence1;
-(NSString*)getSequence2;

-(MTSelection*)getSelection1;
-(MTSelection*)getSelection2;

-(NSArray*)alignmentPositions;

-(int)gop;
-(int)gep;

/* operations */

-(void)setSubstitutionMatrix: (Class)p_substm;
-(void)setGop:(int)p_gop;
-(void)setGep:(int)p_gep;

-(int)countPairs;
-(int)countIdenticalPairs;
-(int)countUngappedPairs;

-(void)computeGlobalAlignment;
-(void)computeLocalAlignment;

/* input/output */
//-(void)fromStreamAsFASTA:(Stream*)stream;
-(id)writeFastaToStream: (MTStream*)str;

/* creation */
+(MTPairwiseSequenceAlignment*)alignmentBetweenChain:(MTChain*)chain1 andChain:(MTChain*)chain2;


@end

#endif /* MTPWSEQALIGNMENT_OH */

