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


#ifndef MTCHAIN_H
#define MTCHAIN_H

 
#include <Foundation/Foundation.h>


@class MTCoordinates;
@class MTResidue;
@class MTMatrix53;
@class MTMatrix44;
@class MTMatrix;
@class MTSelection;
@class MTStructure;

@interface MTChain : NSObject
{
        @protected
	NSString *source;
	NSString *compound;
	NSString *eccode;
	
	NSString *seqres;

	char code;
	MTStructure *strx;

	NSMutableDictionary *solventKeys;
	NSMutableArray *solvent;
	NSMutableDictionary *heterogenKeys;
	NSMutableArray *heterogens;
	NSMutableDictionary *residueKeys;
	NSMutableArray *residues;

	NSMutableDictionary *residuehash;
	unsigned int hashingbits;
	double hash_value_offset;
}

/*
 *   naming
 */
-(char)code;
-(NSNumber*)codeNumber;
-(NSString*)name;
-(NSString*)description;
-(NSString*)fullPDBCode;

/* 
 *   readonly access
 */
-(NSString*)source;
-(NSString*)compound;
-(NSString*)eccode;

/*
 *   reference to parent structure
 */
-(MTStructure*)structure;

-(id)orderResidues;

/*
 *   transform all residues/atoms in this chain by the given matrix
 */
-(id)transformBy:(MTMatrix53*)m;
-(id)translateBy:(MTCoordinates*)v;
-(id)rotateBy:(MTMatrix44*)r;


/*
 *   enumerator over residues, heterogens, solvent, respectively
 */
-(NSEnumerator*)allResidues;
-(NSEnumerator*)allHeterogens;
-(NSEnumerator*)allSolvent;

/*
 * Array of residues, heterogens, solvent respectively.
 */
-(NSArray*)residues;
-(NSArray*)heterogens;
-(NSArray*)solvent;
 
/*
 *   count of residues, heterogens, solvent, respectively
 */
-(int)countResidues;
-(int)countStandardAminoAcids;
-(int)countHeterogens;
-(int)countSolvent;

/*
 *   access a residue, heterogen, solvent, respectively, for the given 
 *   identifying number (eventually, plus an insertion code, single character)
 */
-(MTResidue*)getResidue:(NSString*)nr;
-(MTResidue*)getHeterogen:(NSString*)nr;
-(MTResidue*)getSolvent:(NSString*)nr;

/*
 *   add a residue, heterogen, solvent, respectively, to this chain
 */
-(id)addResidue:(MTResidue*)res;
-(id)addHeterogen:(MTResidue*)het;
-(id)addSolvent:(MTResidue*)sol;

/*
 *   remove a residue
 */
-(void)removeResidue:(MTResidue*)p_res;

/* 
 *   derive amino acid sequence
 */
-(NSString*)getSEQRES;
-(NSString*)getSequence;
-(NSString*)get3DSequence;

/*
 *   geometric hash of all residues in this Chain
 */
-(void)prepareResidueHash:(float)binwidth;
-(NSArray*)findResiduesCloseTo:(MTCoordinates*)p_coords;
-(NSNumber*)mkCoordinatesHashX:(double)x Y:(double)y Z:(double)z; // compute hash key value

/* complex utilities */
-(MTChain*)deepCopy;
-(MTChain*)deepCopyCA;
-(NSArray*)selectResiduesCloseTo:(MTChain*)other maxDistance:(float)maxdist;

@end



#endif /* MTChain_H */
 
