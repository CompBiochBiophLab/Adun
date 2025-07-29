/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-07-15 11:25:33 +0200 by michael johnston

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#ifndef _ADINDEXSETCONVERSIONS_H_
#define _ADINDEXSETCONVERSIONS_H_

#include <Foundation/Foundation.h>
#include "AdunKernel/AdunDataMatrix.h"

/**
Category adding useful methods to NSIndexSet.
Also adds NSCoding functionality to NSIndexSet.
\ingroup Inter
*/
@interface NSIndexSet (AdIndexSetConversions)
/**
Documentation forthcomming
*/
- (NSRange*) indexSetToRangeArrayOfLength: (int*) length;
/**
Documentation forthcomming
*/
+ (id) indexSetFromRangeArray: (NSRange*) rangeArray ofLength: (int) length;
/**
Documentation forthcomming
*/
- (int) numberOfRanges;
/**
Converts an array of indexes to an index set. All elements
in array must respond to intValue. If not an NSInvalidArgumentException
is raised.
*/
+ (id) indexSetFromArray: (NSArray*) array;
@end

#endif // _ADINDEXSETCONVERSIONS_H_

