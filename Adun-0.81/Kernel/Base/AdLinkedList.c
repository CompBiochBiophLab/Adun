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

#include <Base/AdLinkedList.h>
 
 
ListElement* AdLinkedListCreate(ListElement* liststart_p)
{
	ListElement *listend_p;
	 
	listend_p = (ListElement*)malloc(sizeof(ListElement));
	
	liststart_p->next = listend_p;
	liststart_p->previous = NULL;
	listend_p->previous = liststart_p;
	listend_p->next = NULL;
	 
	 return listend_p;
 }
 
int AdSafeLinkedListAdd(ListElement *list_el, ListElement *list_end, int index)
{
     	//check if we were passed the last element of the list
     
     	if(list_end->next != NULL)
	{
	    printf("This is not the last element of the list\n");
	    return -1;
	}

	return AdUnsafeLinkedListAdd(list_el, list_end, index);	
}

int AdUnsafeLinkedListAdd(ListElement *list_el, ListElement *list_end, int index)
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

int AdUnsafeLinkedListReinsert(ListElement *list_el)
{
	//reinsert the element 	

	list_el->next->previous = list_el;
	list_el->previous->next = list_el;
	
	return 1;	
}

int AdSafeLinkedListRemove(ListElement *list_el)
{
   	//check if this is the first or last element
    
    	if(list_el->next == NULL || list_el->previous == NULL)
	{
		printf("You may be removing the first or last element!!\n");
		return -1;
	}
	
	return AdUnsafeLinkedListRemove(list_el);
}     

int AdUnsafeLinkedListRemove(ListElement *list_el)
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

int AdUnsafeLinkedListExtract(ListElement *list_el)
{
    	(list_el->previous)->next = list_el->next;
    	(list_el->next)->previous = list_el->previous;
    
	return 1;
}     

ListElement* AdLinkedListEnd(ListElement *list_el)
{
	//search through the list until list_el->next == NULL
	
	while(list_el->next != NULL)
	{
		list_el = list_el->next;
	}

	return list_el;	
}
     
 
ListElement* AdLinkedListStart(ListElement *list_el)
{
 	//search through the list until list_el->previous == NULL
	
	while(list_el->previous != NULL)
	{
		list_el = list_el->previous;
	}

	return list_el;	     
}

int AdLinkedListCount(ListElement *list_el)
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
