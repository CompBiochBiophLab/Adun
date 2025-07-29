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

#include "MTSelection.h"
#include "privateMTSelection.h"
#include "MTMatrix53.h"
#include "MTResidue.h"
#include "MTChain.h"


/*  s e t  t o  g e t  memory allocation debugging */
#undef MEMDEBUG


@implementation MTSelection


-(id)init	//@nodoc
{
	[super init];
	chain = nil;
	selection = RETAIN([NSMutableArray new]);
	return self;
}


-(void)dealloc	//@nodoc
{
	//printf("Selection_dealloc\n");
	[selection removeAllObjects];
	RELEASE(selection);
	if (chain) 
	{
		RELEASE(chain);
	}
	[super dealloc];
}


/*
 *   returns the number of residues in selection
 */
-(unsigned long)count
{
	return [selection count];
}


/*
 *   return string, which describes this selection
 */
-(NSString*)description
{
	NSString *res = [NSString stringWithFormat: @"Selection of '%@' with %d residues",chain, [self count]];
	return res;
}


/*
 *   give access to selection
 */
-(NSMutableArray*)getSelection
{
	return selection;
}


/*
 *   return an enumerator over the selected residues
 */
-(NSEnumerator*)selectedResidues
{
	return [selection objectEnumerator];
}


/*
 *   test a residue in selection
 */
-(BOOL)containsResidue: (MTResidue*)r
{
	return [selection containsObject: r];
}


/*
 *   include residue in selection
 */
-(id)addResidue: (MTResidue*)r
{
	[selection addObject: r];
	//NSLog(@"Selection-addResidue: %@",r);
	return self;
}


/*
 *   remove a residue from this selection
 */
-(id)removeResidue: (MTResidue*)r
{
	[selection removeObjectIdenticalTo: r];
	return self;
}


/*
 *   exclude other selection from this one (same chain!)
 */
-(id)difference:(MTSelection*)sel2
{
	if (sel2->chain != chain)
	{
		return self;
	}
	int ct = [sel2->selection count];
	int i;
	MTResidue *res;
	for (i=0; i<ct; i++)
	{
		res = [sel2->selection objectAtIndex:i];
		if ([selection containsObject:res])
		{
			[self removeResidue:res];
		}
	}
	return self;
}


/*
 *   include other selection into this one (same chain!)
 */
-(id)union:(MTSelection*)sel2
{
	if (sel2->chain != chain)
	{
		return self;
	}
	int ct = [sel2->selection count];
	int i;
	MTResidue *res;
	for (i=0; i<ct; i++)
	{
		res = [sel2->selection objectAtIndex:i];
		if (![selection containsObject:res])
		{
			[self addResidue:res];
		}
	}
	return self;
}


/*
 *   structurally align two selections (must be 2 different chains)
 *   size of selections must match
 */
-(MTMatrix53*)alignTo: (MTSelection*)sel2
{
	/* sel2 is the stationary structure, this structure (chain) is being transformed */
	
	if ([sel2 count] != [self count])
	{
		NSLog(@"Selection-alignTo: both selections must be of the same size (%d != %d).",[self count],[sel2 count]);
		return nil;
	}

        /* test for CA coordinates of selected residues */
        MTResidue *res1;
        MTResidue *res2;
        int idx;
        int counter = [self count];
        for (idx = 0; idx < counter; idx++)
        {
                res1 = [selection objectAtIndex:idx];
                res2 = [sel2->selection objectAtIndex:idx];
                if (!([res1 getCA] && [res2 getCA]))
                {
                        [selection removeObjectAtIndex: idx];
                        [sel2->selection removeObjectAtIndex: idx];
                        counter--;
                        idx--;
                }
        }
        

#ifdef MEMDEBUG
	GSDebugAllocationActive(YES);
	NSLog(@"allocated objects on entering method\n%s",GSDebugAllocationList(NO));
#endif

	MTMatrix *m1 = [self matrixWithCACoords];
	MTMatrix *m2 = [sel2 matrixWithCACoords];

	return [m1 alignTo: m2];
}


/*
 *   create a selection for a chain
 */
+(MTSelection*)selectionWithChain: (MTChain*)ch
{
	MTSelection *res = [MTSelection new];
	res->chain = RETAIN(ch);
	return AUTORELEASE(res);
}

@end

