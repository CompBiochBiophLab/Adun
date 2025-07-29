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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#include "MTChain.h"
#include "privateMTChain.h"
#include "MTChainFactory.h"
#include "MTStructure.h"
#include "MTResidueFactory.h"
#include "MTResidue.h"
#include "privateMTResidue.h"
#include "MTCoordinates.h"
#include "MTMatrix.h"
#include "MTMatrix44.h"
#include "MTMatrix53.h"
#include "MTSelection.h"
#include "MTAtom.h"

#undef DEBUG_COMPUTING_TIME

#undef VERBOSE_TRACEBACK

/* max range of coordinates that are mapped to the hash */
//#define MAX_RANGE 640.0
#define MAX_RANGE 998.0		/*  -499.0 .. +499.0  */


@implementation MTChain


-(id)init    // @nodoc
{
	self = [super init];
	residues = RETAIN([NSMutableArray arrayWithCapacity: 100]);
	residueKeys = [NSMutableDictionary new] ;
	solvent = RETAIN([NSMutableArray arrayWithCapacity: 10]);
	solventKeys = [NSMutableDictionary new] ;
	heterogens = RETAIN([NSMutableArray arrayWithCapacity: 10]);
	heterogenKeys = [NSMutableDictionary new] ;
	residuehash = nil;
	return self;
}


-(void)dealloc    // @nodoc
{
	//printf("Chain_dealloc '%s'\n",[[self description]cString]);
	if (seqres)
	{	
		RELEASE(seqres);
	}
	if (residuehash)
	{
		[residuehash removeAllObjects];
		RELEASE(residuehash);
	}
	if (residueKeys)
	{
		[residueKeys removeAllObjects];
		RELEASE(residueKeys);
	}
	if (heterogenKeys)
	{
		[heterogenKeys removeAllObjects];
		RELEASE(heterogenKeys);
	}
	if (solventKeys)
	{
		[solventKeys removeAllObjects];
		RELEASE(solventKeys);
	}
	if (solvent)
	{
		NSEnumerator *e_res = [solvent objectEnumerator];
		id res;
		while ((res = [e_res nextObject]))
		{
			[res setChain:nil];
		}
		[solvent removeAllObjects];
		RELEASE(solvent);
	}
	if (heterogens)
	{
		NSEnumerator *e_res = [heterogens objectEnumerator];
		id res;
		while ((res = [e_res nextObject]))
		{
			[res setChain:nil];
		}
		[heterogens removeAllObjects];
		RELEASE(heterogens);
	}
	if (residues)
	{
		NSEnumerator *e_res = [residues objectEnumerator];
		id res;
		while ((res = [e_res nextObject]))
		{
			[res setChain:nil];
		}
		[residues removeAllObjects];
		RELEASE(residues);
	}
	/* release fields */
	if (source)
	{
		RELEASE(source);
	}
	if (compound)
	{
		RELEASE(compound);
	}
	if (eccode)
	{
		RELEASE(eccode);
	}
	[super dealloc];
}


/*
 *   apply transformation matrix to this chain
 */
-(id)transformBy:(MTMatrix53*)m
{
	MTResidue *res;
	//printf("chain-transformBy %@\n",self);
	NSEnumerator *e_res = [solvent objectEnumerator];
	while ((res = [e_res nextObject]))
	{
		[res transformBy: m];
	}
	e_res = [heterogens objectEnumerator];
	while ((res = [e_res nextObject]))
	{
		[res transformBy: m];
	}
	e_res = [residues objectEnumerator];
	while ((res = [e_res nextObject]))
	{
		[res transformBy: m];
	}

	return self;
}


/*
 *   apply translation to this chain
 */
-(id)translateBy:(MTCoordinates*)v
{
	MTResidue *res;
	NSEnumerator *e_res = [solvent objectEnumerator];
	while ((res = [e_res nextObject]))
	{
		[res translateBy: v];
	}
	e_res = [heterogens objectEnumerator];
	while ((res = [e_res nextObject]))
	{
		[res translateBy: v];
	}
	e_res = [residues objectEnumerator];
	while ((res = [e_res nextObject]))
	{
		[res translateBy: v];
	}

	return self;
}


/*
 *   apply rotation to this chain
 */
-(id)rotateBy:(MTMatrix44*)m
{
	MTMatrix53 *trafo = [MTMatrix53 matrixIdentity];
	int i,j;
	for (i=0; i<3; i++)
	{
		for (j=0; j<3; j++)
		{
			[trafo atRow: i col: j value: [m atRow: i col: j]];
		}
	}
	return [self transformBy: trafo];
}


/*
 *   return character code of this chain
 */
-(char)code
{
	return code;
}


/*
 *   return numerical character code of this chain
 */
-(NSNumber*)codeNumber
{
	return [NSNumber numberWithInt:(int)code];
}


/*
 *   return code of this chain as string
 */
-(NSString*)name
{
	char buffer[2];
	buffer[0]=code;
	buffer[1]='\0';
	return [NSString stringWithCString: buffer];
}


/* 
 *   see @method(Chain,-name)
 */
-(NSString*)description
{
	return [self name];
}


/*
 *   return source organism
 */
-(NSString*)source
{
	return source;
}


/*
 *   return compound name
 */
-(NSString*)compound
{
	return compound;
}


/*
 *   return E.C. code (if possible)
 */
-(NSString*)eccode
{
	return eccode;
}


/*
 *   give access to the @Structure we are part of
 */
-(MTStructure*)structure
{
	return strx;
}


/*
 *   return concatenation of the structure's code and this one's code
 */
-(NSString*)fullPDBCode
{
	if (strx)
	{
		return [NSString stringWithFormat:@"%@%c", [strx pdbcode], code];
	} else {
		return [NSString stringWithFormat:@"0000%c", code];
	}
}


/*
 *
 */
-(id)orderResidues
{
	[residues sortUsingSelector:@selector(compare:)];
	[heterogens sortUsingSelector:@selector(compare:)];
	[solvent sortUsingSelector:@selector(compare:)];
	return self;
}


/*
 *   return enumerator over all residues
 */
-(NSEnumerator*)allResidues
{
	return [residues objectEnumerator];
}


/*
 *   return enumerator over all hetero groups
 */
-(NSEnumerator*)allHeterogens
{
	return [heterogens objectEnumerator];
}


/*
 *   return enumerator over all solvent
 */
-(NSEnumerator*)allSolvent
{
	return [solvent objectEnumerator];
}

/*
 *   return enumerator over all residues
 */
-(NSArray*)residues
{
	return [[residues copy] autorelease];
}


/*
 *   return enumerator over all hetero groups
 */
-(NSArray*)heterogens
{
	return [[heterogens copy] autorelease];
}


/*
 *   return enumerator over all solvent
 */
-(NSArray*)solvent
{
	return [[solvent copy] autorelease];
}

/*
 *   count residues
 */
-(int)countResidues
{
	if (!residues)
	{
		return 0;
	}
	return [residues count];
}


/*
 *   count residues which are of the 20 standard amino acids
 */
-(int)countStandardAminoAcids
{
	NSEnumerator *resenum = [self allResidues];
	MTResidue *residue;
	int count=0;
	while ((residue = [resenum nextObject]))
	{
		if ([residue isStandardAminoAcid])
		{
			count++;
		}
	}
	return count;
}


/*
 *   count hetero groups
 */
-(int)countHeterogens
{
	return [heterogens count];
}


/*
 *   count solvent
 */
-(int)countSolvent
{
	return [solvent count];
}


/*
 *   find residue for key
 */
-(MTResidue*)getResidue:(NSString*)nr
{
	return [residueKeys objectForKey: nr];
}


/*
 *   find hetero for key
 */
-(MTResidue*)getHeterogen:(NSString*)nr
{
	return [heterogenKeys objectForKey: nr];
}


/*
 *   find solvent for key
 */
-(MTResidue*)getSolvent:(NSString*)nr
{
	return [solventKeys objectForKey: nr];
}


/*
 *   add residue 
 */
-(id)addResidue:(MTResidue*)res
{
	[residues addObject: res];
	[residueKeys setObject: res forKey: [res key]];
	[res setChain:self];
	return self;
}


/*
 *   add hetero group
 */
-(id)addHeterogen:(MTResidue*)het
{
	[heterogens addObject: het];
	[heterogenKeys setObject: het forKey: [het key]];
	[het setChain:self];
	return self;
}


/*
 *   add solvent
 */
-(id)addSolvent:(MTResidue*)sol
{
	[solvent addObject: sol];
	[solventKeys setObject: sol forKey: [sol key]];
	[sol setChain:self];
	return self;
}


/*
 *   remove residue (either real residue, or hetero group, or solvent)
 */
-(void)removeResidue:(MTResidue*)p_res
{
	NSString *p_num = [p_res key];
	/* drop all bonds from/to atoms of this residue */
	NSEnumerator *atoms = [p_res allAtoms];
	MTAtom *atm;
	while ((atm = [atoms nextObject]))
	{
		[atm dropAllBonds];
	}

	//NSLog(@"Chain_remove residue: %@ (%@)\n",p_num, [p_res class]);
	NSArray *keys = [heterogenKeys allKeysForObject:p_res];
	if (keys && ([keys count] > 0))
	{
		[heterogenKeys removeObjectsForKeys: keys];
		[heterogens removeObject: p_res];
		return;
	}
	keys = [solventKeys allKeysForObject:p_res];
	if (keys && ([keys count] > 0))
	{
		[solventKeys removeObjectsForKeys: keys];
		[solvent removeObject: p_res];
		return;
	}
	keys = [residueKeys allKeysForObject:p_res];
	if (keys && ([keys count] > 0))
	{
		[residueKeys removeObjectsForKeys:keys];
	}
	[residues removeObject:p_res];
}

  
/*
 *   return parsed SEQRES sequence
 */
-(NSString*)getSEQRES
{
	return seqres;
}


/*
 *   derive amino acid/nucleic acid sequence from coordinates. 
 *   wherever there is a gap in the mainchain and in the number of the residues,
 *   insert as many neutral elements 'X' as necessary.
 */
-(NSString*)getSequence
{
	NSString *res = nil;
	char buffer[8196];
	/* extract FASTA sequence */
	NSEnumerator *allresidues = [self allResidues];
	MTResidue *residue = nil;
	MTResidue *lastres = nil;
	int lastnumber=0;
	int diff;
	int seqpos = 0;
	float distanceCA;
	while (allresidues && (residue = [allresidues nextObject]))
	{
		[residue setSeqNum: -1];
		if ([residue isStandardAminoAcid] || [residue isNucleicAcid])
		{
			diff = [[residue number] intValue] - lastnumber - 1;
			if (diff<0)
			{
				diff = 0;
			}
			if (lastnumber>0 && diff>0)
			{
				if (lastres)
				{
					distanceCA = [residue distanceCATo:lastres];
				} else {
					distanceCA = 0.0f;
				}
				//printf("GAP last=%d diff=%d distance=%1.1f\n",lastnumber,diff,distanceCA);
				if (distanceCA > 4.5f)
				{
					// limit to 99 residues in insertion
					if (diff>99)
					{
						diff = 99;
					}
					while (diff>0)
					{
						/* write missing residues */
						buffer[seqpos]= 'X'; seqpos++; diff--;
					}
				}
			}
			buffer[seqpos]=(char)[[residue oneLetterCode] characterAtIndex:0];
			[residue setSeqNum:(seqpos+1)];
			lastnumber = [[residue number] intValue];
			lastres = residue;
			seqpos++;
		}
	}
	if (seqpos>0)
	{
		buffer[seqpos]='\0';
		res = [NSString stringWithCString: buffer];
	}
	return res;
}


/*
 *   derive sequence of present standard amino acids or nucleic acids
 */
-(NSString*)get3DSequence
{
	NSString *res = nil;
	char buffer[8196];
	/* extract FASTA sequence */
	NSEnumerator *allresidues = [self allResidues];
	MTResidue *residue = nil;
	int seqpos = 0;
	while (allresidues && (residue = [allresidues nextObject]))
	{
		if ([residue isStandardAminoAcid] || [residue isNucleicAcid])
		{
			buffer[seqpos]=(char)[[residue oneLetterCode] characterAtIndex:0];
			[residue setSeqNum:(seqpos+1)];
			seqpos++;
		}
	}
	if (seqpos>0)
	{
		buffer[seqpos]='\0';
		res = [NSString stringWithCString: buffer];
	}
	return res;
}


/*
 *   select all residues in both chains which are at most /maxdist/ separated, return in selections
 */
-(NSArray*)selectResiduesCloseTo:(MTChain*)other maxDistance:(float)maxdist
{
        NSMutableArray *residues1, *residues2;
	MTSelection *p_sel1 = [MTSelection selectionWithChain: self];
	MTSelection *p_sel2 = [MTSelection selectionWithChain: other];
	char *seq1, *seq2;
	int len1, len2;
	int dir, row, col, maxcol, maxrow;
	float score, maxscore;
	float *scorematrix;
	int *tbmatrix;
#ifdef DEBUG_COMPUTING_TIME
	clock_t timebase1,timebase2;
	timebase1 = clock ();
#endif	


        /* prepare sequence 1 and 2 */
        seq1 = (char*)[[self get3DSequence] cString];
        len1 = [self countStandardAminoAcids]+1;
        seq2 = (char*)[[other get3DSequence] cString];
        len2 = [other countStandardAminoAcids]+1;
        residues1 = [NSMutableArray arrayWithCapacity: len1-1 ];
        residues2 = [NSMutableArray arrayWithCapacity: len2-1 ];
        MTResidue *tres;
        NSEnumerator *resenum = [self allResidues];
        while ((tres = [resenum nextObject]))
        {
                if ([tres isStandardAminoAcid])
                {
                        [residues1 addObject: tres];
                }
        }
        resenum = [other allResidues];
        while ((tres = [resenum nextObject]))
        {
                if ([tres isStandardAminoAcid])
                {
                        [residues2 addObject: tres];
                }
        }

        scorematrix = (float*)calloc((len1)*(len2),sizeof(float));
        tbmatrix = (int*)calloc((len1)*(len2),sizeof(int));

        /* prepare scoring matrix */
        dir = 0;
        for (row=0; row<len2; row++)
        {
                for (col=0; col<len1; col++)
                {
                        scorematrix[dir] = 0.0f;
                        tbmatrix[dir] = 0;
                        dir++;
                }
        }
        maxrow=0; maxcol=0; // will hold row/col of highest value in matrix
        maxscore=0.0f; // maximum score
        dir=0; // direction of transition: -1==down, 1==right, 2==diagonal, 0==end of alignment

	float h1,h2,h3;
	MTResidue *res1;
	MTResidue *res2;
	MTAtom *calpha;
	double x1,y1,z1;
	BOOL hasAtom = NO;
	double tval;

#define MAXSCORE 6.0f

        for (col=1; col<len1; col++)
        {
		hasAtom = NO;
		res1 = [residues1 objectAtIndex: (col-1)];
		calpha = [res1 getCA];
		if (calpha)
		{
			x1 = [calpha x];
			y1 = [calpha y];
			z1 = [calpha z];
			hasAtom = YES;
		}
                for (row=1; row<len2; row++)
                {
			res2 = [residues2 objectAtIndex: (row-1)];
			calpha = nil;
			if (res2)
			{
				calpha = [res2 getCA];
			}
			score = -0.5f;
                        h1=0.0f;h2=0.0f;h3=0.0f;
			//score = maxdist - (float)[[residues1 objectAtIndex: (col-1)] distanceCATo: [residues2 objectAtIndex: (row-1)]];
			if (hasAtom && calpha)
			{
				tval =  x1 - [calpha x];
				score = tval * tval;
				tval =  y1 - [calpha y];
				score += tval * tval;
				tval =  z1 - [calpha z];
				score += tval * tval;
				score /= maxdist;
				score /= maxdist;
			}
			if (score > 1.0f)
			{
				score = -0.5f;		/* limit negative score */
			} else {
				score = MAXSCORE * (1.0f - score);
				//score = (score * score)*2.0f;
			}
			h1 = scorematrix[(row-1)*len1+(col-1)] + (float)score;
                        h2 = scorematrix[row*len1+(col-1)] - 0.1f ; // end of gap horizontal
                        h3 = scorematrix[(row-1)*len1+col] - 0.1f ; // end of gap vertical
                        score = h1;
                        dir = 0;
			if (h3>score)
			{
				score = h3;
				dir = -1; // vertical
			}
                        if (h2>score)
                        {
                                score = h2;
                                dir = 1; // horizontal
                        }
                        if (h1>=score)  // overwrite in case of same value
                        {
                                score = h1;
                                dir = 2;
                        }
			scorematrix[row*len1+col] = score;
			tbmatrix[row*len1+col] = dir;

                        // update maximum row/col
                        if (score >= maxscore)
                        {
                                maxscore = score;
                                maxrow = row; maxcol = col;
                        }
                } // all rows
        } // all columns

/*  T R A C E B A C K  */
        col=maxcol; row=maxrow;
        score = scorematrix[row*len1+col];
        dir = 2;
        while (score > 0)
        {
                if (dir == 2)
                {
#ifdef VERBOSE_TRACEBACK
			printf("%d/%d %s %s %1.2f\n",
				row, col,
				[[[residues1 objectAtIndex: (col-1)]key]cString],
				[[[residues2 objectAtIndex: (row-1)]key]cString],
				[[residues1 objectAtIndex: (col-1)] distanceCATo:[residues2 objectAtIndex: (row-1)]]);
#endif
                        [p_sel1 addResidue: [residues1 objectAtIndex: (col-1)]];
                        [p_sel2 addResidue: [residues2 objectAtIndex: (row-1)]];
                }
                dir = tbmatrix[row*len1+col];
                if (dir == 2)
                {
                        col--; row--;
                } else if (dir == -1) {
                        row--;
                } else if (dir == 1) {
                        col--;
                } else {
                        printf("error in traceback at row=%d, col=%d\n",row,col);
                        col--; row--;
                }
                score = scorematrix[row*len1+col];
        }
 
	free(scorematrix);
	free(tbmatrix);
#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in selectCloseTo: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif

	return [NSArray arrayWithObjects: p_sel1, p_sel2, nil];
}


/*
 *   computes the hash of all residues
 */
-(void)prepareResidueHash:(float)gridsize
{
	if (residuehash)
	{
		[residuehash removeAllObjects];
		RELEASE(residuehash);
	}
	hashingbits = (unsigned int)(log(MAX_RANGE / gridsize) / log(2.0) + 0.5);
	//printf("input: %1.1f  hashingbits: %d\n",gridsize,hashingbits);
	hash_value_offset = (MAX_RANGE / (double)(1UL << hashingbits))/2.0;
	//printf("resolution offset: %1.1f\n",hash_value_offset);

	if (hashingbits > 10 || hashingbits < 2)
	{
		NSLog(@"Chain_prepareResidueHash: gridsize is either too big or too small! Cannot compute residue hash.");
		return;
	}
	residuehash = RETAIN([NSMutableDictionary new]);
	MTResidue *t_res;
	MTAtom *t_atm;
	NSEnumerator *allres = [self allResidues];
	NSEnumerator *allatm;
	//NSNumber *hashvalue;
	//NSMutableArray *t_arr;
	while ((t_res = [allres nextObject]))
	{
		allatm = [t_res allAtoms];
		while ((t_atm = [allatm nextObject]))
		{
			[self enterHashAtom:(MTCoordinates*)t_atm for:t_res];
		}
	}
	allres = [self allHeterogens];
	while ((t_res = [allres nextObject]))
	{
		allatm = [t_res allAtoms];
		while ((t_atm = [allatm nextObject]))
		{
			[self enterHashAtom:(MTCoordinates*)t_atm for:t_res];
		}
	}
}


/*
 *   returns a list of residues which are close to the given coordinates<br>
 *   must compute the hash table first using: @method(Chain, -prepareResidueHash:)
 */
-(NSArray*)findResiduesCloseTo:(MTCoordinates*)p_coords
{
	NSNumber *hashvalue = [self mkCoordinatesHashX:[p_coords x] Y:[p_coords y] Z:[p_coords z]];
	NSArray *t_arr = [residuehash objectForKey: hashvalue];
	return t_arr;
}



-(NSNumber*)mkCoordinatesHashX:(double)p_x Y:(double)p_y Z:(double)p_z
{

// input:-320          0       +320
//          0         320       640
//          |----------|---------|
// output:  0          32        64 (6 bits) // (HASH_GRID_SIZE=10.0)
// output:  0          64       128 (7 bits) // (HASH_GRID_SIZE=5.0)
// output:  0         128       256 (8 bits) // (HASH_GRID_SIZE=2.5)
// output:  0         256       512 (9 bits) // (HASH_GRID_SIZE=1.25)
// output:  0         512      1024 (10 bits) // (HASH_GRID_SIZE=0.625)

// input:-499          0       +499
//          0         499       998
//          |----------|---------|
// output:  0          32        64 (6 bits) // (HASH_GRID_SIZE=15.6)
// output:  0          64       128 (7 bits) // (HASH_GRID_SIZE=7.8)
// output:  0         128       256 (8 bits) // (HASH_GRID_SIZE=3.9)
// output:  0         256       512 (9 bits) // (HASH_GRID_SIZE=1.95)
// output:  0         512      1024 (10 bits) // (HASH_GRID_SIZE=0.975)

	double x,y,z;
	unsigned long hashv;
	unsigned long mask = (1UL << hashingbits) - 1;
	double factor = (double)(1UL << hashingbits);
	x = (p_x+(MAX_RANGE/2.0)) / MAX_RANGE * factor;
	if (x<0.0) { x=0.0; printf("clipping -x\n"); }
	if (x>factor) { x=factor; printf("clipping +x\n"); }
	y = (p_y+(MAX_RANGE/2.0)) / MAX_RANGE * factor;
	if (y<0.0) { y=0.0; printf("clipping -y\n"); }
	if (y>factor) { y=factor; printf("clipping +y\n"); }
	z = (p_z+(MAX_RANGE/2.0)) / MAX_RANGE * factor;
	if (z<0.0) { z=0.0; printf("clipping -z\n"); }
	if (z>factor) { z=factor; printf("clipping +z\n"); }
	hashv = (unsigned long)(x+0.5) & mask;
	hashv |= ((unsigned long)(y+0.5) & mask)<<hashingbits;
	hashv |= (((unsigned long)(z+0.5) & mask)<<hashingbits)<<hashingbits;
	// hashv is now a 3 times HASHING_BITS number encoding coordinates
	//printf("mask:%lx factor:%1.1f hashv:%lx x:%1.1f y:%1.1f z:%1.1f -> x:%1.1f y:%1.1f z:%1.1f\n",mask,factor,hashv,p_x,p_y,p_z,x,y,z);
	return [NSNumber numberWithUnsignedLong:hashv];
}


-(MTChain*)deepCopy
{
	MTChain *newchain = RETAIN([MTChainFactory newChainWithCode: code]);
	MTResidue *prevres;
	MTResidue *t_res;
	MTResidue *newres;
	NSEnumerator *allres = [self allResidues];
	NSEnumerator *allatm;
	MTAtom *t_atm;
	MTAtom *newatm;
	while ((t_res = [allres nextObject]))
	{
		newres = [MTResidueFactory newResidueWithNumber: [[t_res number]intValue] subcode: [t_res subcode] name: [[t_res name]cString]];
		allatm = [t_res allAtoms];
		while ((t_atm = [allatm nextObject]))
		{
			newatm = [t_atm copy];
			[newres addAtom: newatm];
		}
		[newchain addResidue: newres];
	}
	allres = [self allHeterogens];
	while ((t_res = [allres nextObject]))
	{
		newres = [MTResidueFactory newResidueWithNumber: [[t_res number]intValue] subcode: [t_res subcode] name: [[t_res name]cString]];
		allatm = [t_res allAtoms];
		while ((t_atm = [allatm nextObject]))
		{
			newatm = [t_atm copy];
			[newres addAtom: newatm];
		}
		[newchain addHeterogen: newres];
	}

	/* remake bonding between hetero group atoms */
	NSEnumerator *allbonds;
	MTAtom *bonded;
	MTAtom *newbonded;
	allres = [self allHeterogens];
	while ((t_res = [allres nextObject]))
	{
		newres = [newchain getHeterogen: [t_res key]];
		allatm = [t_res allAtoms];
		while ((t_atm = [allatm nextObject]))
		{
			allbonds = [t_atm allBondedAtoms];
			while ((bonded = [allbonds nextObject]))
			{
				if ([[bonded number] intValue] > [[t_atm number] intValue])
				{
					newatm = [newres getAtomWithNumber: [t_atm number]];
					newbonded = [newres getAtomWithNumber: [bonded number]];
					if (newatm && newbonded)
					{
						[newatm bondTo: newbonded];
					}
				}
			}
		}
	}
	allres = [self allSolvent];
	while ((t_res = [allres nextObject]))
	{
		newres = [MTResidueFactory newResidueWithNumber: [[t_res number]intValue] subcode: [t_res subcode] name: [[t_res name]cString]];
		allatm = [t_res allAtoms];
		while ((t_atm = [allatm nextObject]))
		{
			newatm = [t_atm copy];
			[newres addAtom: newatm];
		}
		[newchain addSolvent: newres];
	}
	return newchain;
}

-(MTChain*)deepCopyCA
{
	MTChain *newchain = RETAIN([MTChainFactory newChainWithCode: code]);
	MTResidue *prevres;
	MTResidue *t_res;
	MTResidue *newres;
	NSEnumerator *allres = [self allResidues];
	MTAtom *t_atm;
	MTAtom *newatm;
	while ((t_res = [allres nextObject]))
	{
		newres = [MTResidueFactory newResidueWithNumber: [[t_res number]intValue] subcode: [t_res subcode] name: [[t_res name]cString]];
		t_atm = [t_res getCA];
		if (t_atm)
		{
			newatm = [t_atm copy];
			[newres addAtom: newatm];
		}
		[newchain addResidue: newres];
	}
	return newchain;
}

@end

