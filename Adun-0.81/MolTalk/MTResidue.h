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


#ifndef MTRESIDUE_OH
#define MTRESIDUE_OH
 
 
#include <Foundation/Foundation.h>
#ifndef GNUSTEP
#include "GNUstepAdditions.h"
#endif

@class MTAtom;
@class MTMatrix53;
@class MTMatrix44;
@class MTChain;
@class MTCoordinates;


/*
 *   Groups of @Atom are assembled in a @Residue.
 *
 */
@interface MTResidue : NSObject
{
        @protected
	NSString *name;
	NSNumber *number;
	char subcode;
	NSMutableArray *atomarr;
	MTAtom *t_ca;
	MTChain *chain;
	BOOL verified;
	BOOL atomsComplete;
	NSString *modname; // our name as a modified residue
	NSString *moddesc; // description of modification
	NSString *segid;   // segment identifier
	int seqnum;
}

/* readonly access */
-(NSNumber*)number;
-(char)subcode;
-(NSString*)name;
-(void)setName: (NSString*) name;
-(NSString*)key;
-(NSString*)description;
-(NSString*)oneLetterCode;
-(NSString*)modname;
-(NSString*)moddescription;
-(int)sequenceNumber;

-(NSString*)segid;

-(NSComparisonResult)compare: (id)other;

/* follow backbone connectivity */
-(MTResidue*)nextResidue; // at carboxyl group or 3prime
-(MTResidue*)previousResidue;  // at amino group or 5prime

-(MTChain*)chain;

/* tests */
-(BOOL)isStandardAminoAcid;
-(BOOL)isNucleicAcid;
-(BOOL)haveAtomsPresent;
-(BOOL)isModified;

-(double)distanceCATo:(MTResidue*)r2;

/* atoms */
-(id)addAtom:(MTAtom*)atom;
-(id)removeAtom:(MTAtom*)atom;
-(MTAtom*)getCA;
-(MTAtom*)getAtomWithName:(NSString*)name;
-(MTAtom*)getAtomWithNumber:(NSNumber*)number;
-(MTAtom*)getAtomWithInt:(unsigned int)number;
-(NSEnumerator*)allAtoms;
-(NSArray*)atoms;

/* manipulation */
-(id)transformBy: (MTMatrix53*)m;
-(id)rotateBy: (MTMatrix44*)m;
-(id)translateBy:(MTCoordinates*)v;
-(id)mutateTo: (MTResidue*)p_other;

-(id)copy;

/* utility */
+(NSString*)computeKeyFromInt:(int)num subcode:(char)sc;
+(NSString*)translate3LetterTo1LetterCode: (NSString*)c3letter;

@end

#endif /* MTRESIDUE_H */

