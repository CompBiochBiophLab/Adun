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


#include "MTSubstitutionMatrix.h"

#include "blosum45.h"
#include "blosum62.h"
#include "blosum80.h"


@implementation MTSubstitutionMatrix

+(float)exchangeScoreBetween: (char)ch1 and: (char)ch2
{
	if (ch1 == ch2)
		return 1.0f;
	else
		return -1.0f;
}

@end


@implementation MTSubstitutionMatrixBlosum45 //@nodoc

+(float)exchangeScoreBetween: (char)ch1 and: (char)ch2  //@nodoc
{
	signed char c1,c2;
	c1 = ch1 - 65; // A = 0
	c2 = ch2 - 65; // A = 0
	if (c1 < 0 || c2 < 0 || c1 > 25 || c2 > 25)
	{
		NSLog(@"cannot determine substitution score between chars %c(%d) and %c(%d)!",ch1,c1,ch2,c2);
		return -99999.0f;
	}
	return substitutionMatrixBlosum45[c1*26+c2];
}

@end


@implementation MTSubstitutionMatrixBlosum62 //@nodoc

+(float)exchangeScoreBetween: (char)ch1 and: (char)ch2  //@nodoc
{
	signed char c1,c2;
	c1 = ch1 - 65; // A = 0
	c2 = ch2 - 65; // A = 0
	if (c1 < 0 || c2 < 0 || c1 > 25 || c2 > 25)
	{
		NSLog(@"cannot determine substitution score between chars %c(%d) and %c(%d)!",ch1,c1,ch2,c2);
		return -99999.0f;
	}
	return substitutionMatrixBlosum62[c1*26+c2];
}

@end


@implementation MTSubstitutionMatrixBlosum80 //@nodoc

+(float)exchangeScoreBetween: (char)ch1 and: (char)ch2  //@nodoc
{
	signed char c1,c2;
	c1 = ch1 - 65; // A = 0
	c2 = ch2 - 65; // A = 0
	if (c1 < 0 || c2 < 0 || c1 > 25 || c2 > 25)
	{
		NSLog(@"cannot determine substitution score between chars %c(%d) and %c(%d)!",ch1,c1,ch2,c2);
		return -99999.0f;
	}
	return substitutionMatrixBlosum80[c1*26+c2];
}

@end

