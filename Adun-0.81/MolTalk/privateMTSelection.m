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

#include "privateMTSelection.h"
#include "MTSelection.h"
#include "MTChain.h"
#include "MTResidue.h"
#include "MTAtom.h"
#include "MTMatrix.h"


@implementation MTSelection (Private)


-(MTMatrix*)matrixWithCACoords	//@nodoc
{
	MTMatrix *mat = [MTMatrix matrixWithRows: [self count] cols: 3];
	NSEnumerator *e_res = [selection objectEnumerator];
	MTResidue *res;
	MTAtom *atm;
	int counter=0;
	while ((res = [e_res nextObject]))
	{
		atm = [res getCA];
		if (atm)
		{
			[mat atRow: counter col: 0 value: [atm x]];
			[mat atRow: counter col: 1 value: [atm y]];
			[mat atRow: counter col: 2 value: [atm z]];
			counter++;
		} else {
			NSLog(@"Residue %@ does not have coordinates for CA!",res);
		}
	}
	if (counter != [self count])
	{
		NSLog(@"Selection-matrixWithCACoords: was not able to find all atoms.");
		return nil;
	}
	return mat;
}


@end


