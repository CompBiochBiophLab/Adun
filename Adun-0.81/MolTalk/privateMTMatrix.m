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


#include "privateMTMatrix.h"

@implementation MTMatrix (Private)

-(int)calcIndexForRow:(int)row col:(int)col	//@nodoc
{
	int res;
	if ((row < 0) || (col < 0) || (row > [self rows]) || (col > [self cols]))
	{
		NSLog(@"Matrix-calcIndexForRow: wrong row/col number: %d/%d",row,col);
		return -1;
	}
	if ([self isTransposed])
	{
		res = ([self cols] * col + row);
	} else {
		res = ([self cols] * row + col);
	}
	//printf("idx = %d\n",res);
	return res;
}


-(double**)cValues	//@nodoc
{
	double **res;
	res = allocatedoublematrix([self rows],[self cols]);
	int irow,icol;
	for (irow=0;irow<[self rows];irow++)
	{
		for (icol=0;icol<[self cols];icol++)
		{
			res[irow][icol] = [self atRow: irow col: icol];
		}
	}
	return res;
}


@end


double** allocatedoublematrix (int rows, int cols)
{
	double **res;
	res = (double**)calloc(rows,sizeof(double*));
	int i;
	for (i=0; i<rows; i++)
	{
		res[i] = (double*)calloc(cols,sizeof(double));
	}
	return res;
}
