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
#include "AdunKernel/AdunMemoryManager.h"

static id memoryManager;

#define MEM_CON 1048576

@implementation AdMemoryManager

+ (void) initialize
{
	memoryManager = nil;
}

+ (id) appMemoryManager
{
	if(memoryManager == nil)
		memoryManager = [AdMemoryManager new];

	return memoryManager;
}

- (id) init
{
	if(memoryManager != nil)
		return memoryManager;

	if((self = [super init]))
	{
		MEMORY_STATS=[[NSUserDefaults standardUserDefaults]
				boolForKey: @"OutputMemoryStatistics"];
		memoryManager = self;
		matrixZone = NSCreateZone(1024*1024, 1024, 1); 
	}	

	return self;
}

- (void) dealloc
{
	memoryManager = nil;
	NSRecycleZone(matrixZone);
	[super dealloc];
}

- (void*) allocateArrayOfSize: (int) size
{
	void* array;
	NSError* error;
	NSMutableDictionary* errorDict;

#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"Before Array Alloc - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", 
			(float)mem_struct.arena/(float)MEM_CON,
		 	(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			(float)mem_struct.fordblks/(float)MEM_CON); 
	}
#endif	

	/*
	 * The return value of malloc(0) is implementation dependant
	 * It can return NULL in which case it is indistinguisable from
	 * the results of mallocing an array that will exhaust virtual memory.
	 * We want to avoid this since we dont want malloc(0) to trigger the
	 * array == NULL error below. 
	 * malloc(0) can also return a special pointer. This is problematic
	 * since we dont know what this special pointer is and attempting
	 * to free it later could cause a segmentation fault. Hence if
	 * malloc(0) is attempted with immediatly return NULL. In this
	 * way when freeing an array or matrix that was created using 0 
	 * we can recognise and handle it. 
 	 * 
	 * Unfortunatly something is trying to use the NULL pointer
	 * returned here and causing the program to crash. Until this
	 * is corrected we cant use this method.
	 */

	/*if(size == 0)
	{
		NSWarnLog(@"Attempting to allocate a zero size array");
		return NULL;
	}
	else*/
	array = malloc(size);
	
	if(array == NULL)
	{
		NSWarnLog(@"Attempt to allocate array of size %d will exhaust virtual memory!\n", size);
		
		errorDict = [NSMutableDictionary dictionary];
		[errorDict setObject: [NSString stringWithFormat: 
			@"Simulator attempted to allocate an array that would have exhausted virtual memory (size %d bytes).\n"
				, size]
			forKey: NSLocalizedDescriptionKey];
		[errorDict setObject: @"This is probably a symptom of the simulation exploding due to excessive forces.\n"
			forKey: @"AdDetailedDescriptionKey"];
		[errorDict setObject: @"You may need to relax the system before performing a full simulation.\nSee the User Guide for\
 details on how to do this (diana.imim.es/Adun).\n"
			forKey: @"NSRecoverySuggestionKey"];
		[errorDict setObject: NSInternalInconsistencyException
			forKey: NSUnderlyingErrorKey];

		error = [NSError errorWithDomain: AdunKernelErrorDomain
				code: 1
				userInfo: errorDict];

		[[NSException exceptionWithName: NSInternalInconsistencyException
			reason: [NSString stringWithFormat:
			@"Attempted to allocate an array that would have exhausted virtual memory (size %d bytes).", size]
			userInfo: [NSDictionary dictionaryWithObject: error
					forKey: @"AdKnownExceptionError"]] 
			raise];
	}
	
	memset(array, 0, size);
	
#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"After Array Alloc (%d) - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", size, 
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			(float)mem_struct.fordblks/(float)MEM_CON); 
	}
#endif	


	return array;
}

- (AdMatrix*) allocateMatrixWithRows: (int) no_rows withColumns: (int) no_columns
{
	int i, j;
	double *array;
	AdMatrix *matrix;

#ifdef GNUSTEP
	if(MEMORY_STATS==YES)
	{
		matrixStats = NSZoneStats(matrixZone);
		NSLog(@"Before matrix allocation");
		NSLog(@"Zone size: %lf MB. Chunks used : %lf MB. Bytes Used %lf MB. Chunks Free %lf. Bytes Free %lf", 
			(float)matrixStats.bytes_total/(float)MEM_CON, 
			(float)matrixStats.chunks_used/(float)MEM_CON, 
			(float)matrixStats.bytes_used/(float)MEM_CON, 
			(float)matrixStats.chunks_free/(float)MEM_CON, 
			(float)matrixStats.bytes_free/(float)MEM_CON);
	}
#endif	


	matrix = NSZoneMalloc(matrixZone, sizeof(AdMatrix));
	matrix->no_rows = no_rows;
	matrix->no_columns = no_columns;

	//We use a special zone for AdMatrix allocation
	//The NSZone functions will raise an NSMallocException if we
	//try to exhaust virtual memory
	array = NSZoneCalloc(matrixZone, no_rows*no_columns, sizeof(double));	
	matrix->matrix = NSZoneCalloc(matrixZone, no_rows, sizeof(double*));
	if(array == NULL)
		NSWarnLog(@"Attempted to allocate a 0 size array");

	for(i=0, j=0; i < no_rows; i++, j = j + no_columns)
			matrix->matrix[i] = array + j;

#ifdef GNUSTEP
	if(MEMORY_STATS==YES)
	{
		matrixStats = NSZoneStats(matrixZone);
		NSLog(@"After matrix allocation\n");
		NSLog(@"Zone size: %lf MB. Chunks used : %lf MB. Bytes Used %lf MB. Chunks Free %lf. Bytes Free %lf\n", 
			(float)matrixStats.bytes_total/(float)MEM_CON, 
			(float)matrixStats.chunks_used/(float)MEM_CON, 
			(float)matrixStats.bytes_used/(float)MEM_CON, 
			(float)matrixStats.chunks_free/(float)MEM_CON, 
			(float)matrixStats.bytes_free/(float)MEM_CON);
	}
#endif	

	return matrix;
}

- (IntMatrix*) allocateIntMatrixWithRows: (int) no_rows withColumns: (int) no_columns
{
	int i, j;
	int *array;
	IntMatrix *matrix;

#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"Before Matrix Alloc - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", 
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			mem_struct.fordblks); 
	}
#endif	

	matrix = (IntMatrix*)malloc(sizeof(IntMatrix));
	matrix->no_rows = no_rows;
	matrix->no_columns = no_columns;
	array = (int*)[self allocateArrayOfSize: no_rows*no_columns*sizeof(int)];
	matrix->matrix = (int**)[self allocateArrayOfSize: no_rows*sizeof(int*)];
	for(i=0, j=0; i < no_rows; i++, j = j + no_columns)
			matrix->matrix[i] = array + j;

#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"After Matrix Alloc - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", 
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			mem_struct.fordblks); 
	}
#endif	

	return matrix;
}

- (void) freeArray: (void*)array
{	
#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"Before Array Free - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", 
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			(float)mem_struct.fordblks/(float)MEM_CON); 
	}
#endif	

	free(array);

#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"After Array Free  - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf",  
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			(float)mem_struct.fordblks/(float)MEM_CON); 
	}
#endif	
}

/** Do not use this method to free matrices not allocated by one of the
above methods **/

- (void) freeDoubleMatrix: (double**) matrix withRows: (int) no_rows 
{
	//matrices are allocated as arrays
	//with another array of indexes
	
	free(matrix[0]); 	//frees the number array	
	free(matrix);		//frees the index array	

#ifdef GNUSTEP
	if(MEMORY_STATS==YES)
	{
		matrixStats = NSZoneStats(matrixZone);
		NSLog(@"After matrix free");
		NSLog(@"Zone size: %lf MB. Chunks used : %lf MB. Bytes Used %lf MB. Chunks Free %lf. Bytes Free %lf\n", 
			(float)matrixStats.bytes_total/(float)MEM_CON, 
			(float)matrixStats.chunks_used/(float)MEM_CON, 
			(float)matrixStats.bytes_used/(float)MEM_CON, 
			(float)matrixStats.chunks_free/(float)MEM_CON, 
			(float)matrixStats.bytes_free/(float)MEM_CON);
	}
#endif	

}

- (void) freeMatrix: (AdMatrix*) matrix 
{
	if(matrix == NULL)
		return;

	//matrices are allocated as arrays
	//with another array of indexes
#ifdef GNUSTEP
	if(MEMORY_STATS==YES)
	{

		matrixStats = NSZoneStats(matrixZone);
		NSLog(@"Before matrix free\n");
		NSLog(@"Zone size: %lf MB. Chunks used : %lf MB. Bytes Used %lf MB. Chunks Free %lf. Bytes Free %lf\n", 
			(float)matrixStats.bytes_total/(float)MEM_CON, 
			(float)matrixStats.chunks_used/(float)MEM_CON, 
			(float)matrixStats.bytes_used/(float)MEM_CON, 
			(float)matrixStats.chunks_free/(float)MEM_CON, 
			(float)matrixStats.bytes_free/(float)MEM_CON);
	}
#endif	

	if(matrix->no_rows != 0)
	{
		NSZoneFree(matrixZone, matrix->matrix[0]);
		NSZoneFree(matrixZone, matrix->matrix);
	}
	NSZoneFree(matrixZone, matrix);
	
#ifdef GNUSTEP
	if(MEMORY_STATS==YES)
	{

		matrixStats = NSZoneStats(matrixZone);
		NSLog(@"After matrix free");
		NSLog(@"Zone size: %lf MB. Chunks used : %lf MB. Bytes Used %lf MB. Chunks Free %lf. Bytes Free %lf", 
			(float)matrixStats.bytes_total/(float)MEM_CON, 
			(float)matrixStats.chunks_used/(float)MEM_CON, 
			(float)matrixStats.bytes_used/(float)MEM_CON, 
			(float)matrixStats.chunks_free/(float)MEM_CON, 
			(float)matrixStats.bytes_free/(float)MEM_CON);
	}
#endif	
}

- (void) freeIntMatrix: (IntMatrix*) matrix 
{
#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"Before Matrix free - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", 
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			mem_struct.fordblks); 
	}
#endif	

	if(matrix->no_rows != 0)
	{
		free(matrix->matrix[0]); 
		free(matrix->matrix);	
	}
	free(matrix);
	
#ifndef __FREEBSD__
	if(MEMORY_STATS==YES)
	{
		mem_struct = mallinfo();
		NSLog(@"After Matrix free - Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf", 
			(float)mem_struct.arena/(float)MEM_CON, 
			(float)mem_struct.hblkhd/(float)MEM_CON, 
			(float)mem_struct.uordblks/(float)MEM_CON, 
			mem_struct.fordblks); 
	}
#endif	
}

@end


