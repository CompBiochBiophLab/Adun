/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

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
#ifndef _ADUNMEMORYMANAGER_
#define _ADUNMEMORYMANAGER_

#include <stdlib.h>
#ifndef __FREEBSD__
#include <malloc.h>
#endif
#include "AdunKernel/AdunDefinitions.h"

/*!
\ingroup Inter
AdMemoryManager provides memory allocation functionality to the framework. 
It creates ::AdMatrix and ::IntMatrix structures aswell as C arrays.
AdMemoryManager must be used to free any structures it creates via
its free methods. 

AdMemoryManager is a singleton. Only one instance of it exists per simulation.
Use appMemoryManager() to return the simulations AdMemoryManager instance.

\b Defaults:

An applications AdMemoryManager instance will output statistics on
each allocation/deallocation if a default called OutputMemoryStatistics 
exists in the applications default domain and it is set to YES.

Before and after each event the values  (in MB's) returned by the libc function mallinfo() 
for arena, hblks, uordblks and fordbblks are written to stderr.
*/

@interface AdMemoryManager: NSObject 
{
	@private
#ifndef __FREEBSD__	
	struct mallinfo mem_struct;
#endif	
#ifdef GNUSTEP
	struct NSZoneStats matrixStats;
#endif	
	BOOL MEMORY_STATS;
	NSZone* matrixZone;
}

/**
Returns the shared memory manager for the application. 
**/
+ (id) appMemoryManager;
/** Allocates an array of size \e size
The elements of the array are set to 0
\param size the size of the array in bytes **/
- (void*) allocateArrayOfSize: (int) size;
/** Frees an array allocated with allocateArrayOfSize: 
\param array A pointer to the first element of the array to be freed i.e. array[0]**/
- (void) freeArray: (void*)array;
/** Frees an ::AdMatrix allocated with AdMemoryManager::allocateMatrixWithRows:withColumns
\param matrix a pointer to the ::AdMatrix struct
*/
- (void) freeMatrix: (AdMatrix*) matrix; 
/** Frees an ::Intmatrix allocated with AdMemoryManager::allocateIntMatrixWithRows:withColumns
\param matrix a pointer to the ::IntMatrix struct
*/
- (void) freeIntMatrix: (IntMatrix*) matrix; 
/**Allocates an ::AdMatrix with the requseted dimensions
\param no_rows The number of rows in the matrix
\param no_columns The number of columns in the matrix
\return A pointer to a ::AdMatrix struct which contain a reference to the allocated memory area
The matrix contents are initialised to 0.
*/
- (AdMatrix*) allocateMatrixWithRows: (int) no_rows withColumns: (int) no_columns;
/**Allocates an ::IntMatrix with the requseted dimensions. The
\param no_rows The number of rows in the matrix
\param no_columns The number of columns in the matrix
\return A pointer to an ::IntMatrix struct which contain a reference to the allocated memory area
The matrix contents are initialised to 0.
*/
- (IntMatrix*) allocateIntMatrixWithRows: (int) no_rows withColumns: (int) no_columns;
@end

#endif
