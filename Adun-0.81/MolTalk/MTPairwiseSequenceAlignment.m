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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#include "MTPairwiseSequenceAlignment.h"
#include "MTAlPos.h"
#include "MTSubstitutionMatrix.h"
#include "MTStructure.h"
#include "MTChain.h"
#include "MTResidue.h"
#include "MTSelection.h"
#include "MTStream.h"

#undef DEBUG_COMPUTING_TIME
#undef VERBOSE_TRACEBACK

#define GAPOPENINGPENALTY 10 
#define GAPEXTENDPENALTY 1


@implementation MTPairwiseSequenceAlignment


-(id)init	//@nodoc
{
	[super init];
	chain1 = nil;
	chain2 = nil;
	positions = nil;
	computed = NO;
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
	[super dealloc];
}


-(NSString*)description
{
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	NSMutableString *msg = [NSMutableString string];
	int i;
	MTAlPos *alpos;
	for (i=count-1; i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		[msg appendString: [alpos description]];
		[msg appendString: @"\n"];
	}
	return msg;
}


-(NSString*)getSequence1
{
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	NSMutableString *msg = [NSMutableString string];
	int i;
	MTAlPos *alpos;
	for (i=count-1; i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		if ([alpos res1])
		{
			[msg appendString: [[alpos res1] oneLetterCode]];
		} else {
			[msg appendString: @"-"];
		}
	}
	return msg;
}


-(NSString*)getSequence2
{
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	NSMutableString *msg = [NSMutableString string];
	int i;
	MTAlPos *alpos;
	for (i=count-1; i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		if ([alpos res2])
		{
			[msg appendString: [[alpos res2] oneLetterCode]];
		} else {
			[msg appendString: @"-"];
		}
	}
	return msg;
}


-(MTChain*)chain1;
{
	return chain1;
}


-(MTChain*)chain2
{
	return chain2;
}


-(void)setSubstitutionMatrix: (Class)p_substm
{
	if ([p_substm isSubclassOfClass: [MTSubstitutionMatrix class]])
	{
		substitutionMatrix = p_substm;
	} else {
		[NSException raise:@"Unsupported" format:@"The indicated class(%@) is not a subclass of MTSubstitutionMatrix.", [p_substm description]];
	}
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
	if (!computed)
	{
		NSLog(@"MTPairwiseSequenceAlignment needs to be computed first.");
		return -1;
	}
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	return count;
}


-(int)countIdenticalPairs
{
	if (!computed)
	{
		NSLog(@"MTPairwiseSequenceAlignment needs to be computed first.");
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
			if ([[[alpos res1]oneLetterCode] isEqualToString: [[alpos res2]oneLetterCode]])
			{
				count++;
			}
		}
	}
	return count;
}


-(int)countUngappedPairs
{
	if (!computed)
	{
		NSLog(@"MTPairwiseSequenceAlignment needs to be computed first.");
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


-(MTSelection*)getSelection1
{
	if (!computed)
	{
		[NSException raise:@"Unsupported" format:@"The alignment must first be computed."];
	}
	MTSelection *sel = [MTSelection selectionWithChain: chain1];
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	int i;
	MTAlPos *alpos;
	for (i=count-1; i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		if (![alpos isGapped])
		{
			[sel addResidue: [alpos res1]];
		}
	}
	return sel;
}


-(MTSelection*)getSelection2
{
	if (!computed)
	{
		[NSException raise:@"Unsupported" format:@"The alignment must first be computed."];
	}
	MTSelection *sel = [MTSelection selectionWithChain: chain2];
	int count=0;
	if (positions)
	{
		count = [positions count];
	}
	int i;
	MTAlPos *alpos;
	for (i=count-1; i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		if (![alpos isGapped])
		{
			[sel addResidue: [alpos res2]];
		}
	}
	return sel;
}


-(NSArray*)alignmentPositions
{
	if (!computed)
	{
		NSLog(@"MTPairwiseSequenceAlignment needs to be computed first.");
		return nil;
	}
	return positions;
}



/*
 *   compute the global (Needleman-Wunsch) alignment between the two @class(MTChain), derive the structural alignment based on the pairwise assignment
 */
-(void)computeGlobalAlignment
{
	MTAlPos *alpos;
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

	CREATE_AUTORELEASE_POOL(pool);

	if (positions)
	{
		[positions removeAllObjects]; 
		RELEASE(positions); // get rid of old MTAlPos(itions)
		positions = nil;
	}
	positions = RETAIN([NSMutableArray arrayWithCapacity: 200]);
	
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

	if (i >= 0) /* maximum in col i of last row */
	{
		for (dir = len1-1; dir > i; dir--)
		{
			alpos = [MTAlPos alposWithRes1: [residues1 objectAtIndex: (dir-1)] res2: nil];
			[positions addObject: alpos];
#ifdef VERBOSE_TRACEBACK
			printf("%c  -\n",seq1[dir-1]);
#endif
		}
		j = len2-1;
	} else if (j >= 0) { /* maximum in row j of last column */ 
		for (dir = len2-1; dir > j; dir--)
		{
			alpos = [MTAlPos alposWithRes1: nil res2: [residues2 objectAtIndex: (dir-1)]];
			[positions addObject: alpos];
#ifdef VERBOSE_TRACEBACK
			printf("-  %c  %1.1f\n",seq2[dir-1]);
#endif
		}
		i = len1-1;
	}
	dir = 2; // last match
	while ((i>0) && (j>0))
	{
#ifdef VERBOSE_TRACEBACK
		score = scorematrix[j*len1+i];
#endif
		if (dir == 2)
		{
#ifdef VERBOSE_TRACEBACK
			printf("%c  %c  %1.1f\n",seq1[i-1],seq2[j-1],score);
#endif
			alpos = [MTAlPos alposWithRes1: [residues1 objectAtIndex: (i-1)] res2: [residues2 objectAtIndex: (j-1)]];
		} else if (dir == -1) { // gap in seq1 
#ifdef VERBOSE_TRACEBACK
			printf("-  %c\n",seq2[j-1]);
#endif
			alpos = [MTAlPos alposWithRes1: nil res2: [residues2 objectAtIndex: (j-1)]];
		} else if (dir == 1) { // gap in seq2 
#ifdef VERBOSE_TRACEBACK
			printf("%c  -\n",seq1[i-1]);
#endif
			alpos = [MTAlPos alposWithRes1: [residues1 objectAtIndex: (i-1)] res2: nil];
		} else {
#ifdef VERBOSE_TRACEBACK
			printf("?  ?  %1.1f\n",score);
#endif
			alpos = nil;
		}
		if (alpos)
		{
			[positions addObject: alpos];
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
	while (i>1)
	{
		i--;
#ifdef VERBOSE_TRACEBACK
		score = scorematrix[i];
		printf("%c  - \n",seq1[i-1]);
#endif
		alpos = [MTAlPos alposWithRes1: [residues1 objectAtIndex: (i-1)] res2: nil];
		[positions addObject: alpos];
	}
	while (j>1)
	{
		j--;
#ifdef VERBOSE_TRACEBACK
		score = scorematrix[j*len1];
		printf("-  %c\n",seq2[j-1]);
#endif
		alpos = [MTAlPos alposWithRes1: nil res2: [residues2 objectAtIndex: (j-1)]];
		[positions addObject: alpos];
	}

#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in traceback: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif
	free (hinsert);
	free (vinsert);
	free (scorematrix);
	free (tbmatrix);

	computed = YES;

	RELEASE(pool);
}


/*
 *   compute the local (Smith-Waterman) alignment between the two @class(MTChain), derive the structural alignment based on the pairwise assignment
 */
-(void)computeLocalAlignment
{
	MTAlPos *alpos;
	float *scorematrix;
	float *hinsert, *vinsert;
	int *tbmatrix;
	const char *seq1, *seq2;
	int len1, len2;
	int row,col,i,j,dir;
	int maxrow, maxcol;
	float score, h1,h2,h3,tval, maxscore;
	NSMutableArray *residues1, *residues2;

	CREATE_AUTORELEASE_POOL(pool);

	if (positions)
	{
		[positions removeAllObjects]; 
		RELEASE(positions); // get rid of old MTAlPos(itions)
		positions = nil;
	}
	positions = RETAIN([NSMutableArray arrayWithCapacity: 200]);
	
	
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
			alpos = [MTAlPos alposWithRes1: [residues1 objectAtIndex: (i-1)] res2: [residues2 objectAtIndex: (j-1)]];
		} else if (dir == -1) { // gap in seq1 
#ifdef VERBOSE_TRACEBACK
			printf("-  %c\n",seq2[j-1]);
#endif
			alpos = [MTAlPos alposWithRes1: nil res2: [residues2 objectAtIndex: (j-1)]];
		} else if (dir == 1) { // gap in seq2 
#ifdef VERBOSE_TRACEBACK
			printf("%c  -\n",seq1[i-1]);
#endif
			alpos = [MTAlPos alposWithRes1: [residues1 objectAtIndex: (i-1)] res2: nil];
		} else {
#ifdef VERBOSE_TRACEBACK
			printf("?  ?  %1.1f\n",score);
#endif
			alpos = nil;
		}
		if (alpos)
		{
			[positions addObject: alpos];
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

	computed = YES;

	RELEASE(pool);
}


-(id)writeFastaToStream: (MTStream*)str
{
	if (!positions)
	{
		return self;
	}

	int linecounter = 0;
	int len = [positions count];
	int i;
	int aacount = 0;

	MTResidue *res;
	MTChain *ch;
	MTStructure *strx;
	MTAlPos *alpos;

	/* write first sequence */
	aacount = 0;
	for (i=(len-1); i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		res = [alpos res1];
		if ((aacount == 0) && res)
		{
			/* first residue found -> write sequence title */
			ch = [res chain];
			strx = [ch structure];
		}
		if (res)
		{
			aacount++;
		}
	}
	if (strx && ch)
	{
		[str writeString: [NSString stringWithFormat:@">%@ %c/#%d (%d)\n",[strx pdbcode],[ch code],[ch code],aacount]];
	} else {
		NSLog(@"PairwiseSequenceAlignment_writeFastaToStream: cannot access structure and chain");
		return self;
	}
	for (i=(len-1); i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		res = [alpos res1];
		if (res)
		{
			[str writeString: [res oneLetterCode]];
		} else {
			[str writeString: @"-"];
		}
		linecounter++;
		if (linecounter > 60)
		{
			[str writeString: @"\n"];
			linecounter = 0;
		}
	}
	[str writeString: @"\n"];

	strx = nil;
	ch = nil;
	linecounter = 0;
	aacount = 0;
	/* write second sequence */
	for (i=(len-1); i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		res = [alpos res2];
		if ((aacount == 0) && res)
		{
			/* first residue found -> write sequence title */
			ch = [res chain];
			strx = [ch structure];
		}
		if (res)
		{
			aacount++;
		}
	}
	if (strx && ch)
	{
		[str writeString: [NSString stringWithFormat:@">%@ %c/#%d (%d)\n",[strx pdbcode],[ch code],[ch code],aacount]];
	} else {
		NSLog(@"PairwiseSequenceAlignment_writeFastaToStream: cannot access structure and chain");
		return self;
	}
	for (i=(len-1); i>=0; i--)
	{
		alpos = [positions objectAtIndex: i];
		res = [alpos res2];
		if (res)
		{
			[str writeString: [res oneLetterCode]];
		} else {
			[str writeString: @"-"];
		}
		linecounter++;
		if (linecounter > 60)
		{
			[str writeString: @"\n"];
			linecounter = 0;
		}
	}
	[str writeString: @"\n"];

	return self;
}


+(MTPairwiseSequenceAlignment*)alignmentBetweenChain:(MTChain*)p_chain1 andChain:(MTChain*)p_chain2
{
	if (p_chain1 == nil || p_chain2 == nil)
	{
		return nil;
	}
	MTPairwiseSequenceAlignment *res = [MTPairwiseSequenceAlignment new];
	res->chain1 = RETAIN(p_chain1);
	res->chain2 = RETAIN(p_chain2);
	
	return AUTORELEASE(res);
}


@end

