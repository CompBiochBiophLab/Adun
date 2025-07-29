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

#ifndef LINKED_LIST
#define LINKED_LIST

#include <stdio.h>
#include <stdlib.h>

//! \brief Element for the linked lists.
/**
ListElement is the structure used for linked lists in Adun. Its main use is
for holding information related to the common nonbonded interactions in molecular force fields,
i.e. lennard joned and coulomb, although it can be adapted for other uses.
The params member is used to hold the precomputed lennard jones parameters 
along with the product of the partial charges. 
The basic Adun force field functions for nonbonded interactions are tailored to use this structure which can result in 
up to a 20% increase in speed compared to storing the precomputed parameters 
in another memory area e.g. in a matrix of precomputed values.
\note May create a more general list element type for use in other circumstances.
\ingroup Types
**/

typedef struct el_t 
{	
	struct el_t *next;
        int bond[2];
	double params[3];	//!< Used for holding the two LJ parameters and the product of the partial charges.
	double length;
        struct el_t *previous;
	int8_t free;
	int pad[3];		//Pad the struct to 64 bytes.
}
ListElement;

/**
Under GCC some linked list functions are inlined automatically to increase speed.
Under other compilers this is not done. This is mainly for ICC since it produces
faster code than inlining would produce.
\defgroup Link Linked List
\ingroup Functions
@{
**/

#ifdef __GNUC__

/**
 Same as AdSafeLinkedListAdd but doesn't check if you've passed
 the last element.
 **/ 
extern inline int AdUnsafeLinkedListAdd(ListElement *list_el, ListElement *list_end, int index)
{
	//insert the element by pointing its previous and last members at the 
	//second last and last members repectively
	
	list_el->next = list_end;
	list_el->previous = list_end->previous;
	
	//now do the same for the next memeber of the second last element
	//and the previous member of the last element
	
	list_end->previous = list_el;
	list_el->previous->next = list_el; 
	
	return 1;	
}

/**
 Reinserts an element extracted with AdUnsafeLinkedListExtract
 Does not check that ListElement actually points to an element
 in a real list
 **/
extern inline int AdUnsafeLinkedListReinsert(ListElement* list_el)
{
	//reinsert the element 	
	
	list_el->next->previous = list_el;
	list_el->previous->next = list_el;
	
	return 1;	
}

/**
 The same as AdUnsafeLinkedListRemove except doesnt set the remove
 elements previous and next pointer to nil
 \param list_el Pointer to the list element to be removed
 \returns 0 if succeds. -1 if you tried to remove the first or last list elements.
 **/ 

extern inline int AdUnsafeLinkedListExtract(ListElement *list_el)
{
    	(list_el->previous)->next = list_el->next;
    	(list_el->next)->previous = list_el->previous;
	
	return 1;
}

/**
 Same as AdSafeLinkedListRemove() but doesn't check if the
 element is the first or last. Use with care.
 **/ 
extern inline int AdUnsafeLinkedListRemove(ListElement* list_el)
{
    	/*
	 Remove the element by pointing the previous elements next
	 member to the next element and vice versa. Then set
	 list_els members to point to null
	 */
	
    	(list_el->previous)->next = list_el->next;
    	(list_el->next)->previous = list_el->previous;
	
    	list_el->previous = NULL;
    	list_el->next = NULL;
	
	return 1;
}

/** Returns a pointer to the last element of the list.  **/
extern inline ListElement* AdLinkedListEnd(ListElement* list_el)
{
	//search through the list until list_el->next == NULL
	
	while(list_el->next != NULL)
	{
		list_el = list_el->next;
	}
	
	return list_el;	
}


/** Returns a pointer to the first element of the list **/
extern inline ListElement* AdLinkedListStart(ListElement* list_el)
{
 	//search through the list until list_el->previous == NULL
	
	while(list_el->previous != NULL)
	{
		list_el = list_el->previous;
	}
	
	return list_el;	     
}

/**
 Returns the number of elements in a linked list where \e listStart is
 the first full list element (the second element in the list).
 */
extern inline int AdLinkedListCount(ListElement* list_el)
{
	int count;
	
	count = 0;
	
	while(list_el->next != NULL)
	{
		list_el = list_el->next;
		count++;
	}
	
	return count;
}

#else

int AdUnsafeLinkedListAdd(ListElement*, ListElement*, int);
int AdUnsafeLinkedListReinsert(ListElement*);
int AdUnsafeLinkedListExtract(ListElement *list_el);
int AdUnsafeLinkedListRemove(ListElement*);
ListElement* AdLinkedListEnd(ListElement*);
ListElement* AdLinkedListStart(ListElement*);
int AdLinkedListCount(ListElement* list_el);

#endif

/**
 Creates a new linked list whose beginning is pointed to be liststart_p.
 liststart_p must already be pointing to an allocated ListElement strcuture.
 The function returns a pointer to the last element of the list
 **/
ListElement* AdLinkedListCreate(ListElement*);
/**
 Adds an elements to the linked list. If index is not specified element is added to the end.
 If list element passed to this function is not the last it will exit.
 \param list_el A pointer to the element to be added
 \param list_end A pointer to the end of the list
 \param index The index at which to insert the list. Currently not implemented
 \return 0 on success, -1 on failure
 **/	
int AdSafeLinkedListAdd(ListElement*, ListElement*, int);
/**
 Removes the element passed from the list. You CANNOT remove the first and last
 element (big trouble if you do)
 \param list_el Pointer to the list element to be removed
 \returns 0 if succeds. -1 if you tried to remove the first or last list elements.
 **/ 
int AdSafeLinkedListRemove(ListElement*);

/** \@}**/

#endif
