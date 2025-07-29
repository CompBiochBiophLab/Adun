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
#include <float.h>
#include <time.h>

#include "MTMatrix.h"
#include "privateMTMatrix.h"
#include "MTMatrix53.h"

#undef DEBUG_COMPUTING_TIME

@implementation MTMatrix


-(id)init	//@nodoc
{
	[super init];
	transposed = NO;
	rows = 0;
	cols = 0;
	elements = NULL;
	return self;
}


-(void)dealloc	//@nodoc
{
	//NSLog(@"Matrix__dealloc");
	if (elements)
	{
		free(elements);
		elements = NULL;
	}
	[super dealloc];
}


/* see @method(Matrix,toString) */
-(NSString*)description
{
	return [self toString];
}


/*
 *   returns a string representing this matrix.<br>
 *   rows are put between '[' and ']', where each column is seperated by ','<br>
 *   all rows are put between '[' and ']'.<br>
 *   thus a 3x2 matrix becomes: [[0,1][2,9],[-1,0]]"
 */
-(NSString*)toString
{
	//NSString *res = [NSString stringWithFormat: @"Matrix %dx%d",[self rows],[self cols]];

	char sbuffer[512];
	char tbuf[10];
	int idx=0;
	NSString *res = nil;
	
	memset(sbuffer,0,512);
	sbuffer[idx]='['; idx++;
	int icol,irow;
	for (irow=0; irow<[self rows]; irow++)
	{
		sbuffer[idx]='['; idx++;
		for (icol=0; icol<[self cols]; icol++)
		{
			if (idx>=500)
			{
				break;
			}
			if (icol == 0)
			{
				snprintf(tbuf,10,"%4.5f",[self atRow: irow col: icol]);
			} else {
				snprintf(tbuf,10,",%4.5f",[self atRow: irow col: icol]);
			}
			int i=0;
			while ((i<10) && (tbuf[i]!='\0'))
			{
				sbuffer[idx] = tbuf[i];
				i++; idx++;
			}
		} // icol
		sbuffer[idx]=']'; idx++;
		if (idx>=500)
		{
			break;
		}
	} // irow
	sbuffer[idx]=']'; idx++;
	sbuffer[idx]='\0';
	res = [NSString stringWithCString: sbuffer];
	return res;
}


/*
 *   returns TRUE if the matix is transposed
 */
-(BOOL)isTransposed
{
	return transposed;
}


/*
 *   transpose the matrix
 */
-(id)transpose
{
	transposed = !transposed;
	return self;
}


/*
 *   returns the number of columns in the matrix
 */
-(int)cols
{
	if (transposed)
	{
		return rows;
	} else {
		return cols;
	}
}


/*
 *   returns the number of rows in the matrix
 */
-(int)rows
{
	if (transposed)
	{
		return cols;
	} else {
		return rows;
	}
}


/*
 *   get value at row/col
 */
-(double)atRow:(int)row col:(int)col
{
	int idx = [self calcIndexForRow: row col: col];
	return elements[idx];
}


/*
 *   set value at row/col
 */
-(id)atRow:(int)row col:(int)col value:(double)val
{
	int idx = [self calcIndexForRow: row col: col];
	elements[idx] = val;
	return self;
}


/*
 *   multiply two matrices and return new result matrix
 *   needs matrices: nxk and lxn
 */
-(id)x:(MTMatrix*)m2
{
	int row,col;
	row = [m2 rows];
	col = [m2 cols];
	if (row != [self cols])
	{
		NSLog(@"Matrix-x: needs a matrix with m2-rows=m1-cols");
		return nil;
	}
	MTMatrix *res = [MTMatrix matrixWithRows: [self rows] cols: col];
	int icol,irow;
	int irow2;
	double value;
	for (irow=0; irow<[self rows]; irow++)
	{
		for (icol=0; icol<col; icol++)
		{
			value = 0.0;
			for (irow2=0; irow2<row; irow2++)
			{
				value += [self atRow: irow col: irow2] * [m2 atRow: irow2 col: icol];
			}
			[res atRow: irow col: icol value: value];
		} /* icol */
	} /* irow */
	return res;
}


/*
 *   pairwise multiplies elements in the matrix and returns result
 */
-(id)mmultiply:(MTMatrix*)m2
{
	int row,col;
	row = [m2 rows];
	col = [m2 cols];
	if ((row != [self rows]) && (col != [self cols]))
	{
		NSLog(@"Matrix-mmultiply: needs a matrix with same rows and cols");
		return nil;
	}
	MTMatrix *res = [MTMatrix matrixWithRows: row cols: col];
	int icol,irow;
	for (irow=0; irow<row; irow++)
	{
		for (icol=0; icol<col; icol++)
		{
			[res atRow: irow col: icol value: ([self atRow: irow col: icol] * [m2 atRow: irow col: icol])];
		} /* icol */
	} /* irow */
	return res;
}


/*
 *   subtract a matrix from this and return new result matrix
 */
-(id)msubtract: (MTMatrix*)m2
{
	int row,col;
	row = [m2 rows];
	col = [m2 cols];
	if ((row != [self rows]) && (col != [self cols]))
	{
		NSLog(@"Matrix-msubtract: needs a matrix with same rows and cols");
		return nil;
	}
	MTMatrix *res = [MTMatrix matrixWithRows: row cols: col];
	int icol,irow;
	for (irow=0; irow<row; irow++)
	{
		for (icol=0; icol<col; icol++)
		{
			[res atRow: irow col: icol value: ([self atRow: irow col: icol] - [m2 atRow: irow col: icol])];
		} /* icol */
	} /* irow */
	return res;
}


/*
 *   add a matrix to this and return new result matrix
 */
-(id)madd: (MTMatrix*)m2
{
	int row,col;
	row = [m2 rows];
	col = [m2 cols];
	if ((row != [self rows]) && (col != [self cols]))
	{
		NSLog(@"Matrix-madd: needs a matrix with same rows and cols");
		return nil;
	}
	MTMatrix *res = [MTMatrix matrixWithRows: row cols: col];
	int icol,irow;
	for (irow=0; irow<row; irow++)
	{
		for (icol=0; icol<col; icol++)
		{
			[res atRow: irow col: icol value: ([self atRow: irow col: icol] + [m2 atRow: irow col: icol])];
		} /* icol */
	} /* irow */
	return res;
}


/*
 *   add a scalar to each element of this matrix
 *   this is done in place! thus overriding all previous values
 */
-(id)addScalar: (double)scal
{
	int icol,irow;
	for (irow=0; irow<[self rows]; irow++)
	{
		for (icol=0; icol<[self cols]; icol++)
		{
			[self atRow: irow col: icol value: ([self atRow: irow col: icol] + scal)];
		} /* icol */
	} /* irow */
	return self;
}


/*
 *   subtract a scalar from each element of this matrix
 *   this is done in place! thus overriding all previous values
 */
-(id)substractScalar: (double)scal
{
	return [self addScalar: -scal];
}


/*
 *   each element of this matrix is multiplied by the scalar
 *   this is done in place! thus overriding all previous values
 */
-(id)multiplyByScalar: (double)scal
{
	int icol,irow;
	for (irow=0; irow<[self rows]; irow++)
	{
		for (icol=0; icol<[self cols]; icol++)
		{
			[self atRow: irow col: icol value: ([self atRow: irow col: icol] * scal)];
		} /* icol */
	} /* irow */
	return self;
}


/*
 *   each element of this matrix is divided by the scalar
 *   this is done in place! thus overriding all previous values
 */
-(id)divideByScalar: (double)scal
{
	if (scal == 0.0)
	{
		NSLog(@"Matrix-divideByScalar: scalar is zero!");
		return self;
	}
	return [self multiplyByScalar: (1.0/scal)];
}


/*
 *   add a value to a cell
 */
-(id)atRow:(int)row col:(int)col add:(double)v
{
	double val = [self atRow: row col: col];
	[self atRow: row col: col value: (val+v)];
	return self;
}


/*
 *   subtract a value from a cell
 */
-(id)atRow:(int)row col:(int)col subtract:(double)v;
{
	return [self atRow:row col:col add: -v];
}


/*
 *   multiply cell with value
 */
-(id)atRow:(int)row col:(int)col multiplyBy:(double)v;
{
	double val = [self atRow: row col: col];
	[self atRow: row col: col value: (val*v)];
	return self;
}


/*
 *   divide a cell by value
 */
-(id)atRow:(int)row col:(int)col divideBy:(double)v;
{
	if (v == 0.0)
	{
		NSLog(@"Matrix-atRow:col:divideBy: scalar is zero!");
		return self;
	}
	return [self atRow:row col:col multiplyBy: (1.0/v)];
}


/*
 *   diagonalize a symmetric nxn matrix
 *   returns a matrix with the eigenvectors in rows: 1-n, eigenvalues in row 0
 */
-(MTMatrix*)jacobianDiagonalizeWithMaxError: (double)p_error
{
	BOOL running=YES;
	int allindex = [self rows];
	if ([self cols] != allindex)
	{
		NSLog(@"Jacobian diagonalization only works on square matrices.");
		return nil;
	}

	/* make copy of matrix */
	MTMatrix *result = nil;
	double **mat;
	double **eigen = allocatedoublematrix(allindex,allindex);
	double lastsum=1e200;
	int irow,icol;
	mat = [self cValues];
	for (irow=0; irow<allindex; irow++)
	{
		eigen[irow][irow] = 1.0;
	}

	int p,q;
	int i;
	double theta,c,g,h;
	double r;
	double s;
	double t;
	
	double t_sum;
	int iteration = 0;
	while (running)
	{
		iteration++;
		/* test for convergence */
		t_sum = 0.0;
		for (irow=1; irow<allindex; irow++)
		{
			for (icol=0; icol<irow; icol++)
			{
				t_sum += (mat[irow][icol] * mat[irow][icol]);
			}
		}
		//printf("iteration: %d  t_sum=%4.2e\n",iteration,t_sum);
		t_sum += t_sum;
		if (!finite(t_sum) || lastsum <= t_sum)
		{
			//printf("abort after iteration: %d  t_sum=%4.2e\n",iteration,t_sum);
			running = NO;
			break;
		}
		lastsum = t_sum;
		if (t_sum <= (p_error*p_error))
		{
			//printf("terminated after iteration: %d  t_sum=%4.2e\n",iteration,t_sum);
			running = NO;
			break;
		}
		for (p=0; p<(allindex-1); p++) /* all columns */
		{
			for (q=p+1; q<allindex; q++) /* all rows below column ( = lower triangle) */
			{
				//printf("p=%d q=%d\n",p,q);
				if ((mat[q][p] >= p_error)
				|| (mat[q][p] <= -p_error))
				{
					theta = (mat[q][q] - mat[p][p])/2.0/mat[q][p];
					//printf("theta: %4.2e\n",theta);
					if (!finite(theta) || theta==0.0)
					{
						t = 1.0; /* tan(phi) */
					} else {
						if (theta>0.0)
						{
							t = 1.0/(theta + sqrt(theta*theta+1.0));
						} else {
							t = 1.0/(theta - sqrt(theta*theta+1.0));
						}
					}
					c = 1.0/sqrt(1.0+t*t); /* cosine */
					s = c*t; /* sine */
					r = s/(1.0+c); /* = tan(phi/2) */
					mat[p][p] = mat[p][p] - t*mat[q][p];
					mat[q][q] = mat[q][q] + t*mat[q][p];
					mat[q][p] = 0.0; /* that's why we rotated the matrix */
					for (i=0; i<p; i++)
					{
						g = mat[q][i] + r*mat[p][i];
						h = mat[p][i] - r*mat[q][i];
						mat[p][i] = mat[p][i] - s*g;
						mat[q][i] = mat[q][i] + s*h;
					}
					for (i=p+1;i<q;i++)
					{
						g = mat[q][i] + r*mat[i][p];
						h = mat[i][p] - r*mat[q][i];
						mat[i][p] = mat[i][p] - s*g;
						mat[q][i] = mat[q][i] + s*h;
					}
					for (i=q+1; i<allindex; i++)
					{
						g = mat[i][q] + r*mat[i][p];
						h = mat[i][p] - r*mat[i][q];
						mat[i][p] = mat[i][p] - s*g;
						mat[i][q] = mat[i][q] + s*h;
					}
					for (i=0; i<allindex; i++)
					{
						g = eigen[i][q] + r*eigen[i][p];
						h = eigen[i][p] - r*eigen[i][q];
						eigen[i][p] = eigen[i][p] - s*g;
						eigen[i][q] = eigen[i][q] + s*h;
					}
				}
			}
		}
		/* debug output */
		/*
		for (irow=0; irow<allindex; irow++)
		{
			for (icol=0; icol<allindex; icol++)
			{
				printf("%4.2f ", mat[irow][icol]);
			}
			printf("\n");
		}
		*/
	} /* while running */

	/* debug */
	/*
	for (irow=0; irow<allindex; irow++)
	{
		for (icol=0; icol<allindex; icol++)
		{
			printf("%4.2f ", mat[irow][icol]);
		}
		printf("\n");
	}
	*/
	/* output */
	result = [MTMatrix matrixWithRows: (allindex+1) cols: allindex];
	for (irow=0; irow<allindex; irow++)
	{
		for (icol=0; icol<allindex; icol++)
		{
			[result atRow: (irow+1) col: icol value: eigen[irow][icol]]; /* eigenvectors */
		}
		[result atRow: 0 col: irow value: mat[irow][irow]]; /* eigenvalues */
	}
	
	/* release temps */
	for (irow=0; irow<allindex; irow++)
	{
		free(eigen[irow]);
		free(mat[irow]);
	}
	free(eigen);
	free(mat);

	return result;
}


/*
 *   return a row matrix with the center of mass coordinates in any dimension
 *   assuming that columns are dimensions and rows are repetitions
 */
-(MTMatrix*)centerOfMass
{
	MTMatrix *res = [MTMatrix matrixWithRows: 1 cols: [self cols]];
	int irow,icol;
	for (icol=0; icol<[self cols]; icol++)
	{ /* clear */
		[res atRow: 0 col: icol value: 0.0];
	}
	for (irow=0; irow<[self rows]; irow++)
	{
		for (icol=0; icol<[self cols]; icol++)
		{
			[res atRow: 0 col: icol add: [self atRow: irow col: icol]];
		}
	}
	for (icol=0; icol<[self cols]; icol++)
	{
		[res atRow: 0 col: icol divideBy: (double)[self rows]];
	}
	
	return res;
}


/*
 *   return a column as a new matrix
 */
-(id)matrixOfColumn:(int)thecol
{
	MTMatrix *res = [MTMatrix matrixWithRows: [self rows] cols: 1];
	int irow;
	for (irow=0; irow<[self rows]; irow++)
	{
		[res atRow: irow col: 0 value: [self atRow: irow col: thecol]];
	}
	return res;
}


/*
 *   returns the computed sum of all elements
 */
-(double)sum
{
	double res=0.0;
	int num = rows*cols;
	int i;
	for (i=0; i<num; i++)
	{
		res += elements[i];
	}
	return res;
}


/*
 *   square all elements in matrix
 */
-(id)square
{
	double val;
	int num = rows*cols;
	int i;
	for (i=0; i<num; i++)
	{
		val = elements[i];
		elements[i] = (val * val);
	}
	return self;
}


/*
 *   recreate matrix<br>
 *   Warning:!! this is destructive and creates an empty matrix
 */
-(id)setRows:(int)row cols:(int)col
{
	if (elements)
	{
		free(elements);
	}
	elements = (double*)calloc(row*col,sizeof(double));
	rows = row;
	cols = col;
	transposed = NO;
	return self;
}


/*
 *   copy to C array in good order
 */
-(void)linearizeTo:(double*)mat maxElements:(int)count
{
/* OpenGL asks for a matrix in column-major mode, thus m[col][row]
 * 
 *        a0  a4  a8  a12
 *  M = ( a1  a5  a9  a13 )
 *        a2  a6  a10 a14
 *        a3  a7  a11 a15 
 *
 * where a12,a13,a14 is the translation, a0-a10 the 3x3 rotation
 */
 
	int irow,icol;
	for (icol=0; icol<[self cols]; icol++)
	{
		for (irow=0; irow<[self rows]; irow++)
		{
			if (count-- < 0)
			{
				return;
			}
			*mat = [self atRow:irow col:icol];
			mat++;
		}
	}
}


/*
 *   initialize from string
 */
-(id)initFromString:(NSString*)str
{
	NSScanner *sc = [NSScanner scannerWithString: str];
	[sc  setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @"[] 	,"]];
	double val;
	int irow,icol;
	for (irow=0; irow<[self rows]; irow++)
	{
		for (icol=0; icol<[self cols]; icol++)
		{
			if (![sc scanDouble: &val])
			{
				NSLog(@"scan failed.");
				return nil;
			}
			[self atRow: irow col: icol value: val];
		} /* icol */
	} /* irow */
	return self;
}


/*
 *
 */
-(MTMatrix53*)alignTo:(MTMatrix*)m2
{
	if (!([self cols] == 3 && [m2 cols] == 3))
	{
		[NSException raise:@"unimplemented" format:@"Matrices must have cols = 3."];
	}
	if ([self rows] != [m2 rows])
	{
		[NSException raise:@"unimplemented" format:@"Matrices must have same number of rows."];
	}
#ifdef DEBUG_COMPUTING_TIME
	clock_t timebase1,timebase2;
	timebase1 = clock ();
#endif	

        CREATE_AUTORELEASE_POOL(pool);
                
	MTMatrix *com1 = [self centerOfMass];
	//NSLog(@"com1: %@",com1);
	MTMatrix *com2 = [m2 centerOfMass];
	//NSLog(@"com2: %@",com2);
	
	int irow;
	double o11,o12,o13;
	double o21,o22,o23;
	o11 = [com1 atRow: 0 col: 0];
	o12 = [com1 atRow: 0 col: 1];
	o13 = [com1 atRow: 0 col: 2];
	o21 = [com2 atRow: 0 col: 0];
	o22 = [com2 atRow: 0 col: 1];
	o23 = [com2 atRow: 0 col: 2];
	for (irow=0; irow<[self rows]; irow++)
	{ /* move to origin */
		[self atRow: irow col: 0 subtract: o11];
		[self atRow: irow col: 1 subtract: o12];
		[self atRow: irow col: 2 subtract: o13];
		[m2 atRow: irow col: 0 subtract: o21];
		[m2 atRow: irow col: 1 subtract: o22];
		[m2 atRow: irow col: 2 subtract: o23];
	}
	MTMatrix *subm = [m2 msubtract: self];
	//NSLog(@"subm: %@",subm);
	MTMatrix *subp = [self madd: m2];
	//NSLog(@"subp: %@",subp);
	MTMatrix *xm = [subm matrixOfColumn: 0];
	MTMatrix *ym = [subm matrixOfColumn: 1];
	MTMatrix *zm = [subm matrixOfColumn: 2];
	MTMatrix *xp = [subp matrixOfColumn: 0];
	MTMatrix *yp = [subp matrixOfColumn: 1];
	MTMatrix *zp = [subp matrixOfColumn: 2];

	MTMatrix *xmym = [xm mmultiply: ym];
	MTMatrix *xmyp = [xm mmultiply: yp];
	MTMatrix *xpym = [xp mmultiply: ym];
	MTMatrix *xpyp = [xp mmultiply: yp];
	MTMatrix *xmzm = [xm mmultiply: zm];
	MTMatrix *xmzp = [xm mmultiply: zp];
	MTMatrix *xpzm = [xp mmultiply: zm];
	MTMatrix *xpzp = [xp mmultiply: zp];
	MTMatrix *ymzm = [ym mmultiply: zm];
	MTMatrix *ymzp = [ym mmultiply: zp];
	MTMatrix *ypzm = [yp mmultiply: zm];
	MTMatrix *ypzp = [yp mmultiply: zp];
	MTMatrix *mdiag = [MTMatrix matrixWithRows: 4 cols: 4];
	
	double sumall;
	sumall = [[ypzm msubtract: ymzp] sum];
	[mdiag atRow: 0 col: 1 value: sumall];
	sumall = [[xmzp msubtract: xpzm] sum];
	[mdiag atRow: 0 col: 2 value: sumall];
	sumall = [[xpym msubtract: xmyp] sum];
	[mdiag atRow: 0 col: 3 value: sumall];
	sumall = [[ypzm msubtract: ymzp] sum];
	[mdiag atRow: 1 col: 0 value: sumall];
	sumall = [[xmym msubtract: xpyp] sum];
	[mdiag atRow: 1 col: 2 value: sumall];
	sumall = [[xmzm msubtract: xpzp] sum];
	[mdiag atRow: 1 col: 3 value: sumall];
	sumall = [[xmzp msubtract: xpzm] sum];
	[mdiag atRow: 2 col: 0 value: sumall];
	sumall = [[xmym msubtract: xpyp] sum];
	[mdiag atRow: 2 col: 1 value: sumall];
	sumall = [[ymzm msubtract: ypzp] sum];
	[mdiag atRow: 2 col: 3 value: sumall];
	sumall = [[xpym msubtract: xmyp] sum];
	[mdiag atRow: 3 col: 0 value: sumall];
	sumall = [[xmzm msubtract: xpzp] sum];
	[mdiag atRow: 3 col: 1 value: sumall];
	sumall = [[ymzm msubtract: ypzp] sum];
	[mdiag atRow: 3 col: 2 value: sumall];

	[xm square];
	[xp square];
	[ym square];
	[yp square];
	[zm square];
	[zp square];
	
	sumall = [[[xm madd: ym] madd: zm] sum];
	[mdiag atRow: 0 col: 0 value: sumall];
	sumall = [[[yp madd: zp] madd: xm] sum];
	[mdiag atRow: 1 col: 1 value: sumall];
	sumall = [[[xp madd: zp] madd: ym] sum];
	[mdiag atRow: 2 col: 2 value: sumall];
	sumall = [[[xp madd: yp] madd: zm] sum];
	[mdiag atRow: 3 col: 3 value: sumall];
	
	MTMatrix *eigen = [mdiag jacobianDiagonalizeWithMaxError: 1.0e-10];
	double q1=0.0,q2=0.0,q3=0.0,q4=0.0;
	double t_val;
	double vmax = FLT_MAX;
	for (irow=0; irow<[eigen cols]; irow++)
	{ /* find smallest eigenvalue and corresponding eigenvector */
		t_val = [eigen atRow: 0 col: irow];
		if (t_val < vmax)
		{
			q1 = [eigen atRow: 1 col: irow];
			q2 = [eigen atRow: 2 col: irow];
			q3 = [eigen atRow: 3 col: irow];
			q4 = [eigen atRow: 4 col: irow];
			vmax = t_val;
		}
	}
        
	//printf("minimum: %1.3f\neigenvalues/eigenvectors: %s\n",vmax,[[eigen description]cString]);
	
	/* return RT operator */
	MTMatrix53 *res = [MTMatrix53 new];
	/* enter rotation */
	[res atRow: 0 col: 0 value: (q1*q1 + q2*q2 - q3*q3 - q4*q4)];
	[res atRow: 0 col: 1 value: (2.0*(q2*q3 + q1*q4))];
	[res atRow: 0 col: 2 value: (2.0*(q2*q4 - q1*q3))];
	[res atRow: 1 col: 0 value: (2.0*(q2*q3 - q1*q4))];
	[res atRow: 1 col: 1 value: (q1*q1 - q2*q2 + q3*q3 - q4*q4)];
	[res atRow: 1 col: 2 value: (2.0*(q3*q4 + q1*q2))];
	[res atRow: 2 col: 0 value: (2.0*(q2*q4 + q1*q3))];
	[res atRow: 2 col: 1 value: (2.0*(q3*q4 - q1*q2))];
	[res atRow: 2 col: 2 value: (q1*q1 - q2*q2 - q3*q3 + q4*q4)];
	/* enter origin */
	[res atRow: 3 col: 0 value: [com1 atRow: 0 col: 0]];
	[res atRow: 3 col: 1 value: [com1 atRow: 0 col: 1]];
	[res atRow: 3 col: 2 value: [com1 atRow: 0 col: 2]];
	/* enter translation */
	[res atRow: 4 col: 0 value: [com2 atRow: 0 col: 0]];
	[res atRow: 4 col: 1 value: [com2 atRow: 0 col: 1]];
	[res atRow: 4 col: 2 value: [com2 atRow: 0 col: 2]];

	RELEASE(pool);
#ifdef DEBUG_COMPUTING_TIME
	timebase2 = clock ();
	printf("  time spent in Matrix_alignTo: %1.1f ms\n",((timebase2-timebase1)*1000.0f/CLOCKS_PER_SEC));
	timebase1 = timebase2;
#endif

	return AUTORELEASE(res);
}



/*
 *   create matrix
 */
+(MTMatrix*)matrixWithRows: (int)row cols:(int)col
{
	MTMatrix *res = [self new];
	[res setRows: row cols: col];
	return AUTORELEASE(res);
}



@end

