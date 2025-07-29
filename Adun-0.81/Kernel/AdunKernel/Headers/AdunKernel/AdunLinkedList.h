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
#ifndef ADLINKEDLIST_H
#define ADLINKEDLIST_H

#define _GNU_SOURCE

#include <stdlib.h>
#include <Foundation/Foundation.h>
#include "Base/AdLinkedList.h"
#include "AdunKernel/AdunDefinitions.h"

/**
\ingroup Inter
Class providing high performance linked list managment for
pairwise nonbonded interaction lists. The order of the elements
in the list managed by instances of AdLinkedList is undetermined i.e.
new elements are not always added to the end. This is not important
for nonbonded interaction lists but may be in other situations. 
However the lists high performance is enabled by this fact.

The structure used for the list elements (::ListElement)
is tailored for these interactions i.e. a pair of atoms
plus the distance between them. It also includes space for 3 parameters.
These are usually the two precomputed LJ parameters and the product of the 
partial charges. 

\note Expand on high performance feature.
*/

@interface AdLinkedList: NSObject
{
	@private
	int listCount;
	ListElement* linkedList;
	ListElement* linkedListEnd;
	//memory
	int BLOCKSIZE;
	int block_count;	//the current location in the current block
	int block_no;		//the current number of blocks
	int current_block_no; 	//the number of the current block
	int freeElementsCount;
	ListElement* blocks[50];	//array containing the current blocks
	ListElement* current_block;	//the current block
	NSMutableArray* freeElements;	//array of pointers to freed elements
	id (*getElement)(id, SEL);
	void (*removeElement)(id, SEL);
	void (*addElement)(id, SEL, id);
	NSZone* listZone;
}
/**
Initialises a new AdLinkedList instance. 
The first and last elements of the list are created and the initial
list contains only these two elements. 

The object returns new list elements from contiguous
arrays containing \e size ::ListElement structures which it creates on demand.
Each time more than \e size elements are added to the list a
new array is allocated. The default value is 524288.

The first and last elements of the list do not belong to one
of these arrays.
*/
- (id) initWithBlocksize: (int) size;
/**
Adds a new element to the list and returns it. 
The position of the element in the list is undetermined.*/
- (ListElement*) getNewListElement;
/**
Removes the list element pointed to by \e list_p from
the list.
*/
- (void) freeListElement: (ListElement*) list_p;
/**
Returns the start of the list.
*/
- (ListElement*) listStart;
/**
Returns the end of the list
*/
- (ListElement*) listEnd;
/**
Returns the current number of elements in the list.
*/
- (int) listCount;
@end

#endif 
