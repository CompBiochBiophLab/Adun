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


#ifndef MTPRIVATECHAIN_H
#define MTPRIVATECHAIN_H


#include <Foundation/Foundation.h>

#include "MTChain.h"

@class MTStructure;
@class MTResidue;
@class MTCoordinates;

@interface MTChain (Private)

-(void)setStructure:(MTStructure*)p_strx;	//@nodoc
-(void)setCode:(char)p_code;	//@nodoc
-(void)setSource:(NSString*)p_src;	//@nodoc
-(void)setCompound:(NSString*)p_cmpnd;	//@nodoc
-(void)setECCode:(NSString*)p_ecc;	//@nodoc
-(void)setSeqres:(NSString*)p_seqres;	//@nodoc

-(void)enterHashAtom:(MTCoordinates*)atm for:(MTResidue*)res;	//@nodoc
-(void)enterHashValue:(NSNumber*)hashvalue for:(MTResidue*)res;	//@nodoc

-(id)rotate: (double)angle aroundAxisFrom: (MTCoordinates*)p_P1 to: (MTCoordinates*)p_P2;


@end

#endif /* MTPRIVATECHAIN_H */
 
