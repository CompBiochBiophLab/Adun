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
 
 
#ifndef MTPRIVATERESIDUE_H
#define MTPRIVATERESIDUE_H


#include <Foundation/Foundation.h>

#include "MTResidue.h"

@class MTChain;

@interface MTResidue (Private)

-(void)setName:(NSString*)p_name;	//@nodoc
-(void)setModName:(NSString*)p_name;	//@nodoc
-(void)setModDesc:(NSString*)p_desc;	//@nodoc
-(void)setNumber:(NSNumber*)p_number;	//@nodoc
-(void)setSubcode:(char)p_subcode;	//@nodoc
-(void)setSeqNum:(int)p_seqnum;		//@nodoc
-(void)setSegid:(NSString*)p_segid;	//@nodoc

-(void)setChain:(MTChain*)p_chain;	//@nodoc
-(void)verifyAtomConnectivity;	//@nodoc

-(MTResidue*)nextAminoAcid;   //@nodoc
-(MTResidue*)nextNucleicAcid; //@nodoc
-(MTResidue*)previousAminoAcid;   //@nodoc
-(MTResidue*)previousNucleicAcid; //@nodoc

-(void)computeCB;


@end

#endif /* MTPRIVATERESIDUE_H */
 
