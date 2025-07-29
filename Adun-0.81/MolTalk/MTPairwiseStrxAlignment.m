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

#include "MTPairwiseStrxAlignment.h"
#include "MTPairwiseSequenceAlignment.h"
#include "MTAlPos.h"
#include "MTSubstitutionMatrix.h"
#include "MTStructure.h"
#include "MTChain.h"
#include "MTResidue.h"
#include "MTSelection.h"
#include "MTMatrix.h"
#include "MTMatrix53.h"
#include "MTStream.h"

#include "blosum45.h"
#include "blosum62.h"
#include "blosum80.h"

#undef DEBUG_COMPUTING_TIME
#undef VERBOSE_TRACEBACK
#undef DEBUG_OPTIMISATION

#define GAPOPENINGPENALTY 10 
#define GAPEXTENDPENALTY 1
#define MAXDIST 6.0
#define SIGNIFDISTTHRESHOLD 5.0

#define OPTIMIZE_SELECTION_DISTANCE 5.5f



@implementation MTPairwiseStrxAlignment


-(id)init	//@nodoc
{
	[super init];
	chain1 = nil;
	chain2 = nil;
	positions = nil;
	calculated = NO;
	f_gop = GAPOPENINGPENALTY;
	f_gep = GAPEXTENDPENALTY;
	//substitutionMatrix = [MTSubstitutionMatrixBlosum45 class];
	substitutionMatrix = [MTSubstitutionMatrixBlosum62 class];
	return self;
}


-(void)dealloc	//@nodoc
{
	if (positions)
	{
		RELEASE(positions);
	}
	if (chain1)
	{
		RELEASE(chain1);
	}	
	if (chain2)
	{
		RELEASE(chain2);
	}
	if (transformation)
	{
		RELEASE(transformation);
	}
	[super dealloc];
}


-(NSString*)description
{
	return @"MTPairwiseStrxAlignment";
}


-(MTChain*)chain1;
{
	return chain1;
}


-(MTChain*)chain2
{
	return chain2;
}


-(int)gop
{
	return f_gop;
}


-(int)gep
{
	return f_gep;
}


-(void)setGep:(int)p_gep
{
	f_gep = p_gep;
}


-(void)setGop:(int)p_gop
{
	f_gop = p_gop;
}


-(int)countPairs
{
	if (!calculated)
	{
		NSLog(@"MTPairwiseStrxAlignment needs to be calculated first.");
		return -1;
	}
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	return count;
}


-(int)countUngappedPairs
{
	if (!calculated)
	{
		NSLog(@"MTPairwiseStrxAlignment needs to be calculated first.");
		return -1;
	}
	int count = 0;
	int j;
	int i=[positions count];
	MTAlPos *alpos;
	for (j=1; j<=i; j++)
	{
		alpos = [positions objectAtIndex: (i-j)];
		if (![alpos isGapped])
		{
			count++;
		}
	}
	return count;
}


-(MTMatrix53*)getTransformation
{
	return transformation;
}
		

-(double)calculateRMSD
{
	if (!calculated)
	{
		NSLog(@"MTPairwiseStrxAlignment needs to be calculated first.");
		return -1.0;
	}
	double deviation = 0.0;
	double tdist;
	int count = 0;
	int i=[positions count];
	int j;
	MTAlPos *alpos;
	for (j=1; j<=i; j++)
	{
		alpos = [positions objectAtIndex: (i-j)];
		if (![alpos isGapped])
		{
			tdist = [alpos distance];
			deviation += (tdist * tdist);
			count++;
		}
	}
	if (count==0)
	{
		return -1.0;
	}
	return sqrt(deviation / count);
}


/*
 *    after an initial superposition has been calculated, try to improve it by selecting residue pairs
 *    having at most 3.5 A distance and recalculate transformation.
 */

#define MAXIMUM_ERROR_DIFFERENCE 1.0e-7
#define MAXIMUM_TRAFO_VALUE 1.0e-6
#define MAXIMUM_NUMBER_OPTIMISATIONS 25

-(void)optimize
{
#ifdef DEBUG_COMPUTING_TIME
	clock_t timebase1,timebase2;
	timebase1 = clock ();
#endif	

	MTSelection *matching1;
	MTSelection *matching2;
	NSArray *t_arr;
	int nowaligned=0;
	int maxaligned=0;
	int counter=1;
	float seldist = OPTIMIZE_SELECTION_DISTANCE; /* ranges from OPTIMIZ... to 3.5 decreasing by 0.25 each round */
	t_arr = [chain1 selectResiduesCloseTo: chain2 maxDistance: seldist];
	matching1 = [t_arr objectAtIndex: 0];
	matching2 = [t_arr objectAtIndex: 1];
	nowaligned = [matching1 count];
	MTMatrix53 *rtop;
	double sumerr, preverr,t;
	sumerr = 1.0;
	preverr = 9.0;
	while (matching1 && (counter <= MAXIMUM_NUMBER_OPTIMISATIONS))
	{
		if (sumerr < MAXIMUM_TRAFO_VALUE) { break; } 
/*
		if (((preverr - sumerr)*(preverr - sumerr)) < MAXIMUM_ERROR_DIFFERENCE))
		{
			break;
		}
*/
		maxaligned = nowaligned;
#ifdef DEBUG_OPTIMISATION
		printf("DEBUG            %d (%1.2e) we have %d aligned residues\n",counter,sumerr,nowaligned);
#endif
		rtop = [matching2 alignTo: matching1];
#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in alignTo: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif
		[chain2 transformBy: rtop];
		t_arr = [chain1 selectResiduesCloseTo: chain2 maxDistance: seldist];
		matching1 = [t_arr objectAtIndex: 0];
		matching2 = [t_arr objectAtIndex: 1];
		nowaligned = [matching1 count];
		counter++;
		if (seldist > 3.5f) seldist -= 0.25f;
		preverr = sumerr;
		sumerr  = ([rtop atRow:0 col:0]-1.0)*([rtop atRow:0 col:0]-1.0);
		sumerr += [rtop atRow:0 col:1]*[rtop atRow:0 col:1];
		sumerr += [rtop atRow:0 col:2]*[rtop atRow:0 col:2];
		sumerr += [rtop atRow:1 col:0]*[rtop atRow:1 col:0];
		sumerr += ([rtop atRow:1 col:1]-1.0)*([rtop atRow:1 col:1]-1.0);
		sumerr += [rtop atRow:1 col:2]*[rtop atRow:1 col:2];
		sumerr += [rtop atRow:2 col:0]*[rtop atRow:2 col:0];
		sumerr += [rtop atRow:2 col:1]*[rtop atRow:2 col:1];
		sumerr += ([rtop atRow:2 col:2]-1.0)*([rtop atRow:2 col:2]-1.0);
		t = [rtop atRow:3 col:0]-[rtop atRow:4 col:0];
		sumerr += t*t;
		t = [rtop atRow:3 col:1]-[rtop atRow:4 col:1];
		sumerr += t*t;
		t = [rtop atRow:3 col:2]-[rtop atRow:4 col:2];
		sumerr += t*t;
	}

#ifdef DEBUG_OPTIMISATION
	printf("DEBUG at the end we have Err=%1.2e (%d aligned residues) after %d runs\n",sumerr,nowaligned,counter);
#endif
}


-(NSArray*)alignmentPositions
{
	if (!calculated)
	{
		NSLog(@"MTPairwiseStrxAlignment needs to be calculated first.");
		return nil;
	}
	return positions;
}


-(int)countPairsMaxDistance:(double)dist
{
	if (!calculated)
	{
		NSLog(@"MTPairwiseStrxAlignment needs to be calculated first.");
		return -1;
	}
	int count = 0;
	int i=[positions count];
	int j;
	MTAlPos *alpos;
	double actdist;
	for (j=1; j<=i; j++)
	{
		alpos = [positions objectAtIndex: (i-j)];
		actdist = [alpos distance];
		if (actdist >= 0.0 && actdist <= dist)
		{
			count++;
		}
	}
	
	return count;
}


/*
 *   output derived structural alignment from computed superposition as a T-Coffee library.
 */
-(void)toStreamAsTCoffee:(MTStream*)stream name1:(NSString*)name1 name2:(NSString*)name2
{
	if (!calculated)
	{
		NSLog(@"MTPairwiseStrxAlignment needs to be calculated first.");
		return;
	}

	int countA = 1;
	int countB = 1;
	int i=[positions count];
	int j;
	MTAlPos *alpos;
	double actdist;
	MTResidue *res1, *res2;
	if (![stream ok])
	{
		return;
	}
	/* write header */
	[stream writeString:@"! T-COFFEE_LIB_FORMAT_01\n"];
	[stream writeString:@"2\n"];
	/* clean up sequence of chain1 */
	NSMutableDictionary *chaindict1 = [NSMutableDictionary new];
	NSEnumerator *enumerator = [chain1 allResidues];
	NSNumber *resnum,*resnum2;
	while (enumerator && (res1 = [enumerator nextObject]))
	{
		if ([res1 isStandardAminoAcid])
		{
			resnum = [res1 number];
			[chaindict1 setObject:[NSNumber numberWithInt:countA] forKey:resnum];
			countA++;
		}
	}
	/* clean up sequence of chain2 */
	NSMutableDictionary *chaindict2 = [NSMutableDictionary new];
	enumerator = [chain2 allResidues];
	while (enumerator && (res2 = [enumerator nextObject]))
	{
		if ([res2 isStandardAminoAcid])
		{
			resnum2 = [res2 number];
			[chaindict2 setObject:[NSNumber numberWithInt:countB] forKey:resnum2];
			countB++;
		}
	}
	NSString *sequence = [chain1 get3DSequence]; // without 'X'
	[stream writeString:[NSString stringWithFormat:@"%@%d %d %@\n",[[chain1 structure] pdbcode],[chain1 code],[sequence length],sequence]];
	sequence = [chain2 get3DSequence]; // without 'X'
	[stream writeString:[NSString stringWithFormat:@"%@%d %d %@\n",[[chain2 structure] pdbcode],[chain2 code],[sequence length],sequence]];
	[stream writeString:@"#1 2\n"]; // as always the case
	
	int score;
	for (j=1; j<=i; j++)
	{
		alpos = [positions objectAtIndex: (i-j)];
		if (![alpos isGapped])
		{
			res1 = [alpos res1];
			res2 = [alpos res2];
			actdist = [alpos distance];
			if (actdist <= MAXDIST)
			{
				score = (int)floor((MAXDIST-actdist)*100.0f/MAXDIST+0.5f);
			} else {
				score = 1;
			}
			resnum = [chaindict1 objectForKey: [res1 number]];
			resnum2 = [chaindict2 objectForKey: [res2 number]];
			[stream writeString:[NSString stringWithFormat:@"%@ %@ %d\n",resnum,resnum2,score]];
		}
	}
	AUTORELEASE(chaindict1);
	AUTORELEASE(chaindict2);
	[stream writeString:@"! SEQ_1_TO_N\n"];
}


/*
 *   input a pairwise sequence alignment from a stream and interpret as a T-Coffee library.<br>
 *   the library indicates the selection of residues pairs which will be included in the calculation of the transformation
 */
-(void)fromStreamAsTCoffee:(MTStream*)stream
{
	int nseqs;
	NSString *sname1, *sname2;
	int len1, len2;
	NSString *seq1, *seq2;
	MTSelection *sel1, *sel2;
	
	CREATE_AUTORELEASE_POOL(pool);
	
	/* get number of sequences */
	NSString *ln = [stream readStringLineLength: 10]; // should do it
	nseqs = [ln intValue];
	if (nseqs!=2)
	{
		NSLog(@"MTPairwiseStrxAlignment_fromStreamAsTCoffee: requires input file with 2 sequences (%d).",nseqs);
		RELEASE(pool);
		return;
	}
	
	/* read first sequence */
	ln = [stream readStringLineLength: 8192]; // might have a lot of them
	NSScanner *scanner = [NSScanner scannerWithString:ln];
	[scanner scanUpToString:@" " intoString:&sname1];
	[scanner scanInt:&len1];
	[scanner scanUpToString:@"\n" intoString:&seq1];
	if ([sname1 length] != 7)
	{
		sname1 = [[sname1 stringByAppendingString:@"     "] substringToIndex:7];
	}
	
	/* read second sequence */
	ln = [stream readStringLineLength: 8192]; // might have a lot of them
	scanner = [NSScanner scannerWithString:ln];
	[scanner scanUpToString:@" " intoString:&sname2];
	[scanner scanInt:&len2];
	[scanner scanUpToString:@"\n" intoString:&seq2];
	if ([sname2 length] != 7)
	{
		sname2 = [[sname2 stringByAppendingString:@"     "] substringToIndex:7];
	}	
	
	//printf("found: %d sequences\n%@ (%d) ...\n%@ (%d) ...\n",nseqs,sname1,len1,sname2,len2);
	
	/* check whether we are concerned at all */
	/* is sequence1 really our chain1? */
	NSString *t_chainid = [[NSString stringWithFormat:@"%@%d      ",[[chain1 structure] pdbcode],[chain1 code]] substringToIndex:7];
	if (![t_chainid isEqualToString: sname1])
	{
		NSLog(@"sequence1:%@ is not the same as chain1:%@",sname1,t_chainid);
		RELEASE(pool);
		return;
	}
	/* is sequence2 really our chain2? */
	t_chainid = [[NSString stringWithFormat:@"%@%d      ",[[chain2 structure]pdbcode],[chain2 code]] substringToIndex:7];
	if (![t_chainid isEqualToString: sname2])
	{
		NSLog(@"sequence2:%@ is not the same as chain2:%@",sname2,t_chainid);
		RELEASE(pool);
		return;
	}

	/* map sequences to residues */
	int start1, start2;
	NSString *realseq = [chain1 get3DSequence];
	NSRange range = [realseq rangeOfString:seq1];
	//printf("found subsequence from %d to %d\n",range.location,range.location+range.length);
	if (range.length != len1)
	{
		NSLog(@"could not find sequence 1:\n%@\nin chain 1:\n%@\n",seq1,realseq);
		RELEASE(pool);
		return;
	}
	start1 = range.location;
	
	realseq = [chain2 get3DSequence];
	range = [realseq rangeOfString:seq2];
	//printf("found subsequence from %d to %d\n",range.location,range.location+range.length);
	if (range.length != len2)
	{
		NSLog(@"could not find sequence 2:\n%@\nin chain 2:\n%@\n",seq2,realseq);
		RELEASE(pool);
		return;
	}
	start2 = range.location;
	
	/* make selection */
	sel1 = [MTSelection selectionWithChain: chain1];
	sel2 = [MTSelection selectionWithChain: chain2];
	NSArray *allresidues1 = [[chain1 allResidues] allObjects];
	NSArray *allresidues2 = [[chain2 allResidues] allObjects];
	MTResidue *residue;
	int nres1=0,nres2=0;
	int ct1,ct2;
	ct1 = [allresidues1 count]; ct2 = [allresidues2 count];
	while (start1+nres1 < ct1 && start2+nres2 < ct2)
	{
		/* skip comments */
		ln = [stream readStringLineLength: 80];
		if (![stream ok])
		{
			break;
		}
		if ([ln hasPrefix:@"!"])
		{
			continue;
		}
		if ([ln hasPrefix:@"#"])
		{
			/* we assume that everything is correct ;-) !!! */
			continue;
		}
		scanner = [NSScanner scannerWithString:ln];
		[scanner scanInt: &nres1];
		[scanner scanInt: &nres2];
		
		residue = [allresidues1 objectAtIndex:nres1-1+start1];
		//printf ("res1: %@ at %d\n",residue,(nres1-1+start1));

		while (start1+nres1 < ct1 && residue && ([[residue oneLetterCode] characterAtIndex:0] != [seq1 characterAtIndex:nres1-1]))
		{
			printf ("gap in sequence 1");
			start1++;
			residue = nil;
			if (start1+nres1 < ct1)
			{
				residue = [allresidues1 objectAtIndex:nres1-1+start1];
			}
		}
		if (residue)
		{
			[sel1 addResidue:residue];
		} else {
			NSLog(@"residue %c in sequence 1 at %d not found.",[seq1 characterAtIndex:nres1-1],nres1);
			RELEASE(pool);
			return;
		}
		residue = [allresidues2 objectAtIndex:nres2-1+start2];
		//printf ("res2: %@ at %d\n",residue,(nres2-1+start2));
		while (start2+nres2 < ct2 && residue && ([[residue oneLetterCode] characterAtIndex:0] != [seq2 characterAtIndex:nres2-1]))
		{
			start2++;
			printf ("gap in sequence 2");
			residue = nil;
			if (start2+nres2 < ct2)
			{
				residue = [allresidues2 objectAtIndex:nres2-1+start2];
			}
		}
		if (residue)
		{
			[sel2 addResidue:residue];
		} else {
			NSLog(@"residue (%c) in sequence 2 at %d not found.",[seq2 characterAtIndex:nres2-1],nres2);
			RELEASE(pool);
			return;
		}
	}

	/* superimpose the two chains given the two selections */
	if (transformation)
	{
		RELEASE(transformation);
	}
	transformation = RETAIN([sel2 alignTo: sel1]);
	
	//printf ("strxal: have RT (%@)\n",transformation);
	
	RELEASE(pool);
}


/*
 *   compute the global (Needleman-Wunsch) alignment between the two @class(MTChain), derive the structural alignment based on the pairwise assignment
 */
-(void)globalSequenceInducedStructuralAlignment
{
	CREATE_AUTORELEASE_POOL(pool);

	MTSelection *sel1, *sel2;
	MTPairwiseSequenceAlignment *pseqal = [MTPairwiseSequenceAlignment alignmentBetweenChain: chain1 andChain: chain2];
	[pseqal computeGlobalAlignment];
	//printf("aligned positions = %d\n\n",[pseqal countUngappedPairs]);
	sel1 = [pseqal getSelection1];
	sel2 = [pseqal getSelection2];
	//NSLog(@"selection 1 = %@",[sel1 description]);
	//NSLog(@"selection 2 = %@",[sel2 description]);

#ifdef VERY_OLD_CODE_IN_USE
	float *scorematrix;
	float *hinsert, *vinsert;
	int *tbmatrix;
	const char *seq1, *seq2;
	int len1, len2;
	int row,col,i,j,dir;
	float score, h1,h2,h3,tval;
	NSMutableArray *residues1, *residues2;

#ifdef DEBUG_COMPUTING_TIME
	clock_t timebase1,timebase2;
	timebase1 = clock ();
#endif	

	if (positions)
	{
		[positions removeAllObjects]; 
		RELEASE(positions); // get rid of old MTAlPos(itions)
	}
	
	/* prepare sequence 1 and 2 */
	seq1 = [[chain1 get3DSequence] cString];
	len1 = [chain1 countStandardAminoAcids]+1;
	seq2 = [[chain2 get3DSequence] cString];
	len2 = [chain2 countStandardAminoAcids]+1;
	residues1 = [NSMutableArray arrayWithCapacity: len1-1 ];
	residues2 = [NSMutableArray arrayWithCapacity: len2-1 ];
	MTResidue *tres;
	NSEnumerator *resenum = [chain1 allResidues];
	while ((tres = [resenum nextObject]))
	{
		if ([tres isStandardAminoAcid])
		{
			[residues1 addObject: tres];
		}
	}
	resenum = [chain2 allResidues];
	while ((tres = [resenum nextObject]))
	{
		if ([tres isStandardAminoAcid])
		{
			[residues2 addObject: tres];
		}
	}
	if ([residues1 count] != (len1 - 1))
	{
		NSLog(@"Not the same number of residues found in chain1 as in 3D sequence.");
		return;
	}
	if ([residues2 count] != (len2 - 1))
	{
		NSLog(@"Not the same number of residues found in chain2 as in 3D sequence.");
		return;
	}

	scorematrix = (float*)calloc((len1)*(len2),sizeof(float));
	vinsert = (float*)calloc((len1)*(len2),sizeof(float));
	hinsert = (float*)calloc((len1)*(len2),sizeof(float));
	tbmatrix = (int*)calloc((len1)*(len2),sizeof(int));	
	
	if (! (scorematrix && vinsert && hinsert && tbmatrix))
	{
		NSLog(@"failed to allocate scoring matrix.");
		RELEASE(pool);
		return;
	}

	/* prepare scoring matrix */
	dir = 0;
	for (row=0; row<len2; row++)
	{
		for (col=0; col<len1; col++)
		{
			scorematrix[dir] = 0.0f;
			vinsert[dir] = 0.0f;
			hinsert[dir] = 0.0f;
			tbmatrix[dir] = 0;
			dir++;
		}
	}
	for (col=1; col<len1; col++)
	{
		scorematrix[col] = (float)(-f_gop * col);
	}
	dir = len1;
	for (row=1; row<len2; row++)
	{
		scorematrix[dir] = (float)(-f_gop * row);
		dir += len1;
	}
	i=0; j=0; // will hold row/col of highest value in matrix
	score=0.0f; // maximum score
	dir=0; // direction of transition: -1==down, 1==right, 2==diagonal, 0==end of alignment
	for (col=1; col<len1; col++)
	{
		for (row=1; row<len2; row++)
		{
			h1=0.0f;h2=0.0f;h3=0.0f;
			score = [substitutionMatrix exchangeScoreBetween: seq1[col-1] and: seq2[row-1] ];
			//printf("%@ - %@ d:%2.2f h1=%2.2f\n",here,there,dist,h1);
			h1 = scorematrix[(row-1)*len1+(col-1)] + score; // diagonal element
			h2 = hinsert[(row-1)*len1+(col-1)] + score; // end of gap horizontal
			h3 = vinsert[(row-1)*len1+(col-1)] + score; // end of gap vertical
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
			if (h1>=score)	// overwrite in case of same value
			{
				score = h1;
				dir = 2;
			}
			scorematrix[(row)*len1+(col)] = score; // save maximum value in matrix
			tbmatrix[(row)*len1+(col)] = dir; // save traceback direction
			
			// update insertion matrices
			score = scorematrix[(row)*len1+(col-1)] - f_gop;
			tval = hinsert[(row)*len1+(col-1)] - f_gep;
			hinsert[(row)*len1+(col)] = (score>tval?score:tval);
			score = scorematrix[(row-1)*len1+(col)] - f_gop;
			tval = vinsert[(row-1)*len1+(col)] - f_gep;
			vinsert[(row)*len1+(col)] = (score>tval?score:tval);
		} // all rows
	} // all columns

#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in forward : %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif

	/* find maximum in last i=col/j=row */
	i=0; 
	j=(len2-1)*len1; // start of last row
	score=0.0f;
	for (col=0; col<len1; col++)
	{
		tval = scorematrix[j+col];
		if (tval > score)
		{
			score = tval; i = col;
		}
	}
	j=-1;
	for (row=0; row<len2; row++)
	{
		tval = scorematrix[(row+1)*len1-1];  // last col
		if (tval > score)
		{
			score = tval; j = row; i = -1;
		}
	}
	//printf("maximum: %1.1f at i=%d j=%d\n",score,i,j);

	/* write score matrix to file */
/* * * * * * * * * * * * * * * * * *
	FILE *outfile = fopen("t_scores.csv","w");
	if (outfile)
	{
		fprintf(outfile,".    ");
		for (col=1; col<len1; col++)
		{
			fprintf(outfile,"   %c  ",seq1[col-1]);
		}
		fprintf(outfile,"\n");
		for (row=0; row<len2; row++)
		{
			if (row > 0) fprintf(outfile,"%c ",seq2[row-1]);
			else fprintf(outfile,"   ");
			for (col=0; col<len1; col++)
			{
				fprintf(outfile,"% 3.1f ",scorematrix[row*len1+col]);
			}
			fprintf(outfile,"\n");
		}
		fclose(outfile);
	}
	outfile = fopen("t_tb.csv","w");
	if (outfile)
	{
		fprintf(outfile,".     ");
		for (col=1; col<len1; col++)
		{
			fprintf(outfile,"  %c ",seq1[col-1]);
		}
		fprintf(outfile,"\n");
		for (row=0; row<len2; row++)
		{
			if (row > 0) fprintf(outfile,"%c ",seq2[row-1]);
			else fprintf(outfile,"  ");
			for (col=0; col<len1; col++)
			{
				fprintf(outfile,"% 3d ",tbmatrix[row*len1+col]);
			}
			fprintf(outfile,"\n");
		}
		fclose(outfile);
	}
* * * * * * * * * * * * * * * * * */


/*  T R A C E B A C K  */
	sel1 = [MTSelection selectionWithChain: chain1];
	sel2 = [MTSelection selectionWithChain: chain2];

	if (i >= 0) /* maximum in col i of last row */
	{
#ifdef VERBOSE_TRACEBACK
		for (dir = len1-1; dir > i; dir--)
		{
			printf("%c  -\n",seq1[dir-1]);
		}
#endif
		j = len2-1;
	} else if (j >= 0) { /* maximum in row j of last column */ 
#ifdef VERBOSE_TRACEBACK
		for (dir = len2-1; dir > j; dir--)
		{
			printf("-  %c  %1.1f\n",seq2[dir-1]);
		}
#endif
		i = len1-1;
	}
	dir = 2; // last match
	while (i>0 && j>0)
	{
#ifdef VERBOSE_TRACEBACK
		score = scorematrix[j*len1+i];
#endif
		if (dir == 2)
		{
#ifdef VERBOSE_TRACEBACK
			printf("%c  %c  %1.1f\n",seq1[i-1],seq2[j-1],score);
#endif
			[sel1 addResidue: [residues1 objectAtIndex: (i-1)]];
			[sel2 addResidue: [residues2 objectAtIndex: (j-1)]];
#ifdef VERBOSE_TRACEBACK
		} else if (dir == -1) { // gap in seq1 
			printf("-  %c\n",seq2[j-1]);
		} else if (dir == 1) { // gap in seq2 
			printf("%c  -\n",seq1[i-1]);
		} else {
			printf("?  ?  %1.1f\n",score);
#endif
		}
		dir = tbmatrix[j*len1+i];
		if (dir == 2)
		{
			j--; i--;
		} else if (dir == -1) {
			j--;
		} else if (dir == 1) {
			i--;
		} else {
			printf("error in traceback at i=%d, j=%d\n",i,j);
			j--; i--;
		}
	}
#ifdef VERBOSE_TRACEBACK
	while (i>1)
	{
		i--;
		score = scorematrix[i];
		printf("%c  - \n",seq1[i-1]);
	}
	while (j>1)
	{
		j--;
		score = scorematrix[j*len1];
		printf("-  %c\n",seq2[j-1]);
	}
#endif

#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in traceback: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif
	free (hinsert);
	free (vinsert);
	free (scorematrix);
	free (tbmatrix);

#endif /* VERY_OLD_CODE_IN_USE */

	/* superimpose the two chains given the two selections */
	if (transformation)
	{
		RELEASE(transformation);
	}
	transformation = RETAIN([sel2 alignTo: sel1]);

	RELEASE(pool);
}


/*
 *   compute the local (Smith-Waterman) alignment between the two @class(MTChain), derive the structural alignment based on the pairwise assignment
 */
-(void)localSequenceInducedStructuralAlignment
{
	CREATE_AUTORELEASE_POOL(pool);

	MTSelection *sel1, *sel2;
	MTPairwiseSequenceAlignment *pseqal = [MTPairwiseSequenceAlignment alignmentBetweenChain: chain1 andChain: chain2];
	[pseqal computeLocalAlignment];
	sel1 = [pseqal getSelection1];
	sel2 = [pseqal getSelection2];

#ifdef VERY_OLD_CODE_IN_USE
	float *scorematrix;
	float *hinsert, *vinsert;
	int *tbmatrix;
	const char *seq1, *seq2;
	int len1, len2;
	int row,col,i,j,dir;
	int maxrow, maxcol;
	float score, h1,h2,h3,tval, maxscore;
	NSMutableArray *residues1, *residues2;

	if (positions)
	{
		[positions removeAllObjects]; 
		RELEASE(positions); // get rid of old MTAlPos(itions)
	}
	
	/* prepare sequence 1 and 2 */
	seq1 = [[chain1 get3DSequence] cString];
	len1 = [chain1 countStandardAminoAcids]+1;
	seq2 = [[chain2 get3DSequence] cString];
	len2 = [chain2 countStandardAminoAcids]+1;
	residues1 = [NSMutableArray arrayWithCapacity: len1-1 ];
	residues2 = [NSMutableArray arrayWithCapacity: len2-1 ];
	MTResidue *tres;
	NSEnumerator *resenum = [chain1 allResidues];
	while ((tres = [resenum nextObject]))
	{
		if ([tres isStandardAminoAcid])
		{
			[residues1 addObject: tres];
		}
	}
	resenum = [chain2 allResidues];
	while ((tres = [resenum nextObject]))
	{
		if ([tres isStandardAminoAcid])
		{
			[residues2 addObject: tres];
		}
	}
	if ([residues1 count] != (len1 - 1))
	{
		NSLog(@"Not the same number of residues found in chain1 as in 3D sequence.");
		return;
	}
	if ([residues2 count] != (len2 - 1))
	{
		NSLog(@"Not the same number of residues found in chain2 as in 3D sequence.");
		return;
	}

	scorematrix = (float*)calloc((len1)*(len2),sizeof(float));
	vinsert = (float*)calloc((len1)*(len2),sizeof(float));
	hinsert = (float*)calloc((len1)*(len2),sizeof(float));
	tbmatrix = (int*)calloc((len1)*(len2),sizeof(int));	
	
	if (! (scorematrix && vinsert && hinsert && tbmatrix))
	{
		NSLog(@"failed to allocate scoring matrix.");
		RELEASE(pool);
		return;
	}

	/* prepare scoring matrix */
	dir = 0;
	for (row=0; row<len2; row++)
	{
		for (col=0; col<len1; col++)
		{
			scorematrix[dir] = 0.0f;
			vinsert[dir] = 0.0f;
			hinsert[dir] = 0.0f;
			tbmatrix[dir] = 0;
			dir++;
		}
	}
	maxrow=0; maxcol=0; // will hold row/col of highest value in matrix
	maxscore=0.0f; // maximum score
	dir=0; // direction of transition: -1==down, 1==right, 2==diagonal, 0==end of alignment
	for (col=1; col<len1; col++)
	{
		for (row=1; row<len2; row++)
		{
			h1=0.0f;h2=0.0f;h3=0.0f;
			score = [substitutionMatrix exchangeScoreBetween: seq1[col-1] and: seq2[row-1] ];
			//printf("%@ - %@ d:%2.2f h1=%2.2f\n",here,there,dist,h1);
			h1 = scorematrix[(row-1)*len1+(col-1)] + score; // diagonal element
			h2 = hinsert[(row-1)*len1+(col-1)] + score; // end of gap horizontal
			h3 = vinsert[(row-1)*len1+(col-1)] + score; // end of gap vertical
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
			if (h1>=score)	// overwrite in case of same value
			{
				score = h1;
				dir = 2;
			}
			scorematrix[(row)*len1+(col)] = score; // save maximum value in matrix
			tbmatrix[(row)*len1+(col)] = dir; // save traceback direction
			
			// update maximum row/col
			if (score >= maxscore)
			{
				maxscore = score;
				maxrow = row; maxcol = col;
			}

			// update insertion matrices
			score = scorematrix[(row)*len1+(col-1)] - f_gop;
			tval = hinsert[(row)*len1+(col-1)] - f_gep;
			hinsert[(row)*len1+(col)] = (score>tval?score:tval);
			score = scorematrix[(row-1)*len1+(col)] - f_gop;
			tval = vinsert[(row-1)*len1+(col)] - f_gep;
			vinsert[(row)*len1+(col)] = (score>tval?score:tval);
		} // all rows
	} // all columns

	//printf("maximum: %1.1f at i=%d j=%d\n",maxscore,maxcol,maxrow);

	/* write score matrix to file */
/* * * * * * * * * * * * * * * * * *
	FILE *outfile = fopen("t_scores.csv","w");
	if (outfile)
	{
		fprintf(outfile,".    ");
		for (col=1; col<len1; col++)
		{
			fprintf(outfile,"   %c  ",seq1[col-1]);
		}
		fprintf(outfile,"\n");
		for (row=0; row<len2; row++)
		{
			if (row > 0) fprintf(outfile,"%c ",seq2[row-1]);
			else fprintf(outfile,"   ");
			for (col=0; col<len1; col++)
			{
				fprintf(outfile,"% 3.1f ",scorematrix[row*len1+col]);
			}
			fprintf(outfile,"\n");
		}
		fclose(outfile);
	}
	outfile = fopen("t_tb.csv","w");
	if (outfile)
	{
		fprintf(outfile,".     ");
		for (col=1; col<len1; col++)
		{
			fprintf(outfile,"  %c ",seq1[col-1]);
		}
		fprintf(outfile,"\n");
		for (row=0; row<len2; row++)
		{
			if (row > 0) fprintf(outfile,"%c ",seq2[row-1]);
			else fprintf(outfile,"  ");
			for (col=0; col<len1; col++)
			{
				fprintf(outfile,"% 3d ",tbmatrix[row*len1+col]);
			}
			fprintf(outfile,"\n");
		}
		fclose(outfile);
	}
* * * * * * * * * * * * * * * * * */


/*  T R A C E B A C K  */
	sel1 = [MTSelection selectionWithChain: chain1];
	sel2 = [MTSelection selectionWithChain: chain2];

	i=maxcol; j=maxrow;
	score = scorematrix[j*len1+i];
	dir = 2;
	while (score > 0)
	{
		if (dir == 2)
		{
#ifdef VERBOSE_TRACEBACK
			printf("%c  %c  %1.1f\n",seq1[i-1],seq2[j-1],score);
#endif
			[sel1 addResidue: [residues1 objectAtIndex: (i-1)]];
			[sel2 addResidue: [residues2 objectAtIndex: (j-1)]];
#ifdef VERBOSE_TRACEBACK
		} else if (dir == -1) { // gap in seq1 
			printf("-  %c\n",seq2[j-1]);
		} else if (dir == 1) { // gap in seq2 
			printf("%c  -\n",seq1[i-1]);
		} else {
			printf("?  ?  %1.1f\n",score);
#endif
		}
		dir = tbmatrix[j*len1+i];
		if (dir == 2)
		{
			j--; i--;
		} else if (dir == -1) {
			j--;
		} else if (dir == 1) {
			i--;
		} else {
			printf("error in traceback at i=%d, j=%d\n",i,j);
			j--; i--;
		}
		score = scorematrix[j*len1+i];
	}

	free (hinsert);
	free (vinsert);
	free (scorematrix);
	free (tbmatrix);
#endif /* VERY_OLD_CODE_IN_USE */

	/* superimpose the two chains given the two selections */
	if (transformation)
	{
		RELEASE(transformation);
	}
	transformation = RETAIN([sel2 alignTo: sel1]);

	RELEASE(pool);
}

/*
 *   given a superpositions of the @class(MTChain), derive the structural alignment using dynamic programming
 */
-(void)deriveStructuralAlignment
{
	CREATE_AUTORELEASE_POOL(pool);

#ifdef DEBUG_COMPUTING_TIME
	clock_t timebase1,timebase2;
#endif

	int *scorematrix;
	int *hinsert, *vinsert;
	int *tbmatrix;
	NSMutableArray *seq1;
	NSMutableArray *seq2;
	MTResidue *here, *there;
	float dist;
	int col,row,i,j;
	int h1=0,h2=0,h3=0;
	int ttval,tval;

#ifdef DEBUG_COMPUTING_TIME
	timebase1 = clock ();
#endif	
	if (positions)
	{
		[positions removeAllObjects]; 
		RELEASE(positions); // get rid of old MTAlPos(itions)
	}
	seq1 = [NSMutableArray arrayWithCapacity:[chain1 countStandardAminoAcids]];
	seq2 = [NSMutableArray arrayWithCapacity:[chain2 countStandardAminoAcids]];	
	
	/* prepare sequence 1 and 2 */
	NSEnumerator *residues1 = [chain1 allResidues];
	while (residues1 && (here = [residues1 nextObject]))
	{
		if ([here isStandardAminoAcid])
		{
			[seq1 addObject: here];
		}
	}
	NSEnumerator *residues2 = [chain2 allResidues];
	while (residues2 && (there = [residues2 nextObject]))
	{
		if ([there isStandardAminoAcid])
		{
			[seq2 addObject: there];
		}
	}
	
	int score;
	int len1 = [seq1 count];
	int len2 = [seq2 count];
	
	scorematrix = (int*)calloc((len1+1)*(len2+1),sizeof(int));
	vinsert = (int*)calloc((len1+1)*(len2+1),sizeof(int));
	hinsert = (int*)calloc((len1+1)*(len2+1),sizeof(int));
	tbmatrix = (int*)calloc((len1+1)*(len2+1),sizeof(int));	
	
	if (! (scorematrix && vinsert && hinsert && tbmatrix))
	{
		NSLog(@"failed to allocate scoring matrix.");
		RELEASE(pool);
		return;
	}
	
#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in allocation: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif

	i=0; j=0; // will hold row/col of highest value in matrix
	score=0; // maximum score
	int dir; // direction of transition: -1==down, 1==right, 2==diagonal, 0==end of alignment
	for (col=0; col<len1; col++)
	{
		here = [seq1 objectAtIndex: col];
		for (row=0; row<len2; row++)
		{
			there = [seq2 objectAtIndex: row];
			dist = (float)[here distanceCATo: there];

			h1=0;h2=0;h3=0;
			if (dist <= MAXDIST)
			{
				tval = (int)floor((MAXDIST-dist)*1.0+0.5);
			} else {
				tval = (int)floor((MAXDIST-dist)*6.0+0.5);
			}
			//printf("%@ - %@ d:%2.2f h1=%2.2f\n",here,there,dist,h1);
			h1 = scorematrix[(row)*len1+(col)] + tval; // diagonal element
			h2 = hinsert[(row)*len1+(col)] + tval; // end of gap horizontal
			h3 = vinsert[(row)*len1+(col)] + tval; // end of gap vertical
			tval = 0;
			dir = 0;
			if (h3>tval)
			{
				tval = h3;
				dir = -1; // vertical
			}
			if (h2>tval)
			{
				tval = h2;
				dir = 1; // horizontal
			}
			if (h1>=tval)	// overwrite in case of same value
			{
				tval = h1;
				dir = 2;
			}
			scorematrix[(row+1)*len1+(col+1)] = tval; // save maximum value in matrix
			tbmatrix[(row+1)*len1+(col+1)] = dir; // save traceback direction
			/* save maximum score */
			if (tval>score)
			{
				i=row; j=col;
				score=tval;
			}
			
			/* update insertion matrices */
			tval = scorematrix[(row+1)*len1+(col)] - f_gop;
			ttval = hinsert[(row+1)*len1+(col)] - f_gep;
			hinsert[(row+1)*len1+(col+1)] = (tval>ttval?tval:ttval);
			tval = scorematrix[(row)*len1+(col+1)] - f_gop;
			ttval = vinsert[(row)*len1+(col+1)] - f_gep;
			vinsert[(row+1)*len1+(col+1)] = (tval>ttval?tval:ttval);
			
		} /* all rows */
	} /* all columns */
	row=i; col=j; // position on maximum end of alignment
#ifdef DEBUG
	printf ("maximum value:%d in row:%d col:%d\n",score,row,col);
#endif

#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in matrix calc: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif	
	
	/* write score matrix to file */
/* * * * * * * * * * * * * * * * * *
	//printf ("writing scores\n");

	FILE *outfile = fopen("t_scores.csv","w");
	if (outfile)
	{
		fprintf(outfile,". ");
		for (i=0; i<len1; i++)
		{
			fprintf(outfile,"   %c  ",[[[seq1 objectAtIndex:i] oneLetterCode] characterAtIndex:0]);
		}
		fprintf(outfile,"\n");
		for (j=0; j<len2; j++)
		{
			fprintf(outfile,"%c ",[[[seq2 objectAtIndex:j] oneLetterCode] characterAtIndex:0]);
			for (i=0; i<len1; i++)
			{
				fprintf(outfile,"% 3d ",scorematrix[(j+1)*len1+(i+1)]);
			}
			fprintf(outfile,"\n");
		}
		fclose(outfile);
	}
	outfile = fopen("t_tb.csv","w");
	if (outfile)
	{
		fprintf(outfile,". ");
		for (i=0; i<len1; i++)
		{
			fprintf(outfile,"   %c  ",[[[seq1 objectAtIndex:i] oneLetterCode] characterAtIndex:0]);
		}
		fprintf(outfile,"\n");
		for (j=0; j<len2; j++)
		{
			fprintf(outfile,"%c ",[[[seq2 objectAtIndex:j] oneLetterCode] characterAtIndex:0]);
			for (i=0; i<len1; i++)
			{
				fprintf(outfile,"% 3d ",tbmatrix[(j+1)*len1+(i+1)]);
			}
			fprintf(outfile,"\n");
		}
		fclose(outfile);
	}
* * * * * * * * * * * * * * * * * */
		
	/* trace back */
	positions = RETAIN([NSMutableArray arrayWithCapacity:len1]);
	i=0; // counter
	MTAlPos *alpos;
	tval = scorematrix[(row+1)*len1+(col+1)];

	while (tval > 0 && col >= 0 && row >= 0)
	{
		dir = tbmatrix[(row+1)*len1+(col+1)]; // direction of traceback
		//printf("col=%d row=%d dir=%d tval=%d\n",col,row,dir,tval);
		/* follow maximal transition */
		if (dir==-1) {
			alpos = [MTAlPos alposWithRes1:nil res2:[seq2 objectAtIndex:row]];
			[alpos designify];
			row--;
		} else if (dir==1) {
			alpos = [MTAlPos alposWithRes1:[seq1 objectAtIndex:col] res2:nil];
			[alpos designify];
			col--;
		} else if (dir==2) {
			alpos = [MTAlPos alposWithRes1:[seq1 objectAtIndex:col] res2:[seq2 objectAtIndex:row]];
			col--;row--;
		} else {
			alpos = nil;
			printf("wrong traceback. row=%d col=%d\n",row,col);
		}
		if (alpos)
		{
			[positions addObject: alpos];
		}
		tval = scorematrix[(row+1)*len1+(col+1)];
	}
	
#ifdef DEBUG
	i=[positions count];	
	for (j=1; j<=i; j++)
	{
		alpos = [positions objectAtIndex: (i-j)];
		if ([alpos distance] > SIGNIFDISTTHRESHOLD)
		{
			[alpos designify];
		}
		NSLog(@"%03d %@\n",j,alpos);
	}
#endif 
	
#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in traceback: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif
	
	calculated = YES;
	
	free (hinsert);
	free (vinsert);
	free (scorematrix);
	free (tbmatrix);
	
	RELEASE(pool);

#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in cleanup: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif	
}


+(MTPairwiseStrxAlignment*)alignmentBetweenChain:(MTChain*)p_chain1 andChain:(MTChain*)p_chain2
{
	if (p_chain1 == nil || p_chain2 == nil)
	{
		return nil;
	}
	MTPairwiseStrxAlignment *res = [MTPairwiseStrxAlignment new];
	res->chain1 = RETAIN(p_chain1);
	res->chain2 = RETAIN(p_chain2);
	
	return AUTORELEASE(res);
}


@end

