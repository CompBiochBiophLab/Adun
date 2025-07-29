/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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

#include "AdunKernel/AdunLinkedList.h"

@implementation AdLinkedList

- (id) init
{
	return [self initWithBlocksize: 524288];
}

- (id) initWithBlocksize: (int) size
{
	if((self = [super init]))
	{
		block_count = 0;
		block_no = 0;
		current_block_no = 0;
		current_block = blocks[0];
		BLOCKSIZE = size;
		freeElementsCount = 0;
		//Since the allocated blocks are never released
		//until the object is deallocated we set can free to 0.
		listZone = NSCreateZone(BLOCKSIZE, BLOCKSIZE, 0);

		freeElements = [NSMutableArray new];

		getElement = (id (*)(id, SEL))[freeElements 
				methodForSelector:@selector(lastObject)];
		removeElement = (void (*)(id, SEL))[freeElements
				methodForSelector:@selector(removeLastObject)];
		addElement = (void (*)(id, SEL, id))[freeElements 
				methodForSelector:@selector(addObject:)];

		linkedList = (ListElement*)malloc(sizeof(ListElement));
		linkedListEnd = AdLinkedListCreate(linkedList);
		listCount = 0;
	}

	return self;
}

- (void) dealloc
{
	int i;

	[freeElements release];

	//free all allocated blocks
	//this frees all linked list elements
	//except for the first and last

	for(i=0; i<block_no; i++)
		NSZoneFree(listZone, blocks[i]);
	
	NSRecycleZone(listZone);

	//No real need for this
	block_count = 0;
	current_block_no = 0;
	current_block = blocks[0];

	//free start and end of list

	free(linkedList);
	free(linkedListEnd);
	[super dealloc];
}

/*******************************

Interaction List Memory Management 

********************************/

- (ListElement*) _createNewListBlock
{
	ListElement* listPointer;

	if(block_no == 50)
	{
		NSLog(@"Not Enough space in block array for a new block!!");
		exit(1);
	}

	block_no++;
	NSDebugLLog(@"AdLinkedList", @"Creating New Block - There are now %d blocks", block_no);
	
	//NOTE: Testing use of a zone
	listPointer = NSZoneMalloc(listZone, BLOCKSIZE*sizeof(ListElement));
	if(listPointer == NULL)
		[NSException raise: NSInvalidArgumentException
			format: @"Attempt to allocate 0 sized list block"];

	blocks[block_no-1] = listPointer;

	return blocks[block_no-1];
}

- (void) _reinsertElement: (ListElement*) list_p
{
	BOOL firstElement, lastElement;
	int i, block, index, stopIndex;
	int currentBlock, startIndex;
	ListElement* element, *previousElement, *nextElement;

	NSDebugLLog(@"AdLinkedList2", 
		@"Current block %d. Number of blocks %d. Number free elements %d", 
		current_block_no, block_no, freeElementsCount);

	//find block and index in block
	index = block = currentBlock = 0;
	previousElement = nextElement = NULL;
	firstElement = lastElement = NO;
	for(i=0; i<block_no; i++)
	{
		if(list_p >= blocks[i] && list_p <= &(blocks[i][BLOCKSIZE -1]))
		{
			//The index in the current block
			block = i;
			index = list_p - blocks[i];
			if(&blocks[i][index] != list_p)
				NSWarnLog(@"Method failure");
			break;
		}
	}
	NSDebugLLog(@"AdLinkedList2", 
		@"Element at index %d in block %d", 
		index, block);

	/*
	 * Catch when there are no elements allocated after the element being inserted. 
	 * In this case there wont be any next element and we must use
	 * linkedListEnd.
	 */
	 
	//search for next free block element - watching for block changes
	startIndex = index + 1;
	for(currentBlock = block; currentBlock < block_no; currentBlock++)
	{
		//We have to make sure we dont go past the end of
		//the allocated elements!
		if(currentBlock == (block_no - 1))
			stopIndex = block_count;
		else
			stopIndex = BLOCKSIZE;
	
		for(i=startIndex; i<stopIndex; i++)
		{
			element = &blocks[currentBlock][i];
			if(element->free == 0)
			{
				nextElement = element;
				//To break out of top loop
				currentBlock = block_no;
				break;
			}
		}	
		startIndex = 0;
	}

	//Check if we found an allocated element
	//after the one we are inserting.
	
	if(nextElement == NULL)
		nextElement = linkedListEnd;
	
	NSDebugLLog(@"AdLinkedList2", 
		@"Found next used element at index %d, block %d",
		i, block); 
	
	/*
	 * Catch when the element being inserted is the very first element
	 * i.e. first element in the first block.
	 * In this case there wont be any previous element and we must 
	 * use the start of the list.
	 */
	//search for previous address - watching for block changes
	startIndex = index - 1;
	for(currentBlock = block; currentBlock >= 0 ; currentBlock--)
	{
		for(i=startIndex; i>=0; i--)
		{
			element = &blocks[currentBlock][i];
			if(element->free == 0)
			{
				previousElement = element;
				currentBlock = -1;
				break;
			}
		}	
		startIndex = BLOCKSIZE - 1;
	}

	//Check if we found a previous element to the
	//element we are inserting
	if(previousElement == NULL)
		previousElement = linkedList;
	
	NSDebugLLog(@"AdLinkedList2", 
		@"Found previous used element at index %d, block %d"
		, i, block); 

	//Reinsert
	nextElement->previous = list_p;	
	list_p->next = nextElement;
	previousElement->next = list_p;
	list_p->previous = previousElement;
}

//This method returns newly created listelement structures that are
//retreived from previously malloced blocks of memory.
//If there are no free blocks a new block is assigned and ListElements 
//are returned from it

- (ListElement*) getNewListElement
{
	ListElement* el_p;

	listCount++;
	if(block_no == 0)
	{	
		//if there are no blocks make one
		
		current_block = [self _createNewListBlock];
		block_count = 0;
		el_p = &current_block[block_count];
		block_count++;
		AdUnsafeLinkedListAdd(el_p, linkedListEnd, 0);
	}
	else if(freeElementsCount > 0)
	{
		//else return the last previously freed element
		
		el_p = 	[getElement(freeElements, @selector(getNewListElement)) pointerValue];
		removeElement(freeElements, @selector(removeLastObject));

		//Reinsert the element between the two nearest elements
		//in memory that are in the list.
		
		[self _reinsertElement: el_p];
	
		//return the last element in freeElements array
		//and then decrement the boundary

		freeElementsCount--;
	}			
	else if(block_count != BLOCKSIZE)
	{
		//else return memory from the current block
		el_p = &current_block[block_count];
		block_count++;
		AdUnsafeLinkedListAdd(el_p, linkedListEnd, 0);
	}
	else if(current_block_no+1 != block_no)
	{
		//else move to the next available block
		//FIXME: I dont think this condition is ever true.
			
		current_block_no++;
		current_block = blocks[current_block_no];
		block_count = 0;
		el_p = &current_block[block_count];
		block_count++;
		AdUnsafeLinkedListAdd(el_p, linkedListEnd, 0);
	}	
	else
	{
		//else create a new block
		current_block = [self _createNewListBlock];
		block_count = 0;
		el_p = &current_block[block_count];
		current_block_no++;
		block_count++;
		AdUnsafeLinkedListAdd(el_p, linkedListEnd, 0);
	}

	el_p->free=0;

	return el_p;
}

- (void) freeListElement: (ListElement*) list_p
{
	
	//Remove the element from the linked list. 
	//Wipe its data and add its address
	//to the freed element list. We can then return
	//from this list first when an element structure
	//is requested to avoid thrasing memory

	list_p->bond[0] = 0;
	list_p->bond[1] = 0;
	list_p->length = 0;
	list_p->free = 1;

	AdUnsafeLinkedListExtract(list_p);
	list_p->next = NULL;
	list_p->next = NULL;
	addElement(freeElements, 
		@selector(addObject), 
		[NSValue valueWithPointer:list_p]);

	freeElementsCount++;
	listCount--;
}

- (ListElement*) listStart
{
	return linkedList;
}

- (ListElement*) listEnd
{
	return linkedListEnd;
}

- (int) listCount
{
	return listCount;
}

- (void) stats
{
	NSLog(@"Freed elements count is %d.", freeElementsCount);
	NSLog(@"Count from array %d", [freeElements count]);
	NSLog(@"Number of elements in the list %d", listCount);
}

@end

