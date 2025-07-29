/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-23 11:06:55 +0200 by michael johnston

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
#include "AdunKernel/AdunSimpleListHandler.h"

@implementation AdSimpleListHandler


/***************

Initialisation

****************/

- (id) initWithSystem: (id) aSystem	
	allowedPairs: (NSArray*) anArray 
	cutoff: (double) valueOne
{
	if((self = [super init]))
	{
		in_p = NULL;
		listCreated = NO;
		[self setCutoff: valueOne];
		[self setSystem: aSystem];
		[self setAllowedPairs: anArray];
	}

	return self;
}

- (void) _freeLists
{
	ListElement* list_p, *holder;
	
	//if in_p is initalised a list exists

	if(in_p != NULL)
	{
		list_p = in_p;
		while(list_p->next != NULL)	
		{		
			holder = list_p->next;
			free(list_p);
			list_p= holder;
		}
		free(list_p);	
		in_p = NULL;
		list_p = out_p;
		while(list_p->next != NULL)	
		{		
			holder = list_p->next;
			free(list_p);
			list_p= holder;
		}
		free(list_p);
		out_p = NULL;
	}
}	

- (void) dealloc
{
	[self _freeLists];
	[interactions release];
	[[NSNotificationCenter defaultCenter]
			removeObserver: self];
	[system release];
	[super dealloc];
}

//Called when the systems contents change. We re-aquire coordinates
//and invalidate the current list.
- (void) _handleSystemContentsChange: (NSNotification*) aNotification
{
	//Dealloc the list
	[self _freeLists];

	//Update state ivars.
	listCreated = NO;

	coordinates = [system coordinates];
	[delegate handlerDidHandleContentChange: self];
}


/*****************

Main methods

*****************/

- (void) createList
{
	int i, j, k;
	int incount, outcount;
	int retVal, noAtoms;
	unsigned int* indexBuffer;
	NSIndexSet* indexSet;
	NSRange indexRange;
	ListElement *list_p;
	Vector3D seperation_s;
	
	if(listCreated)
		return;

	//Check if we have a system and interactions
	if(system ==  nil || interactions == nil)
		return;

	//Check if system and allowed pairs are compatible
	if((int)[interactions count] >= coordinates->no_rows)
		[NSException raise: NSInternalInconsistencyException
			format: @"Allowed pairs array implies more elements then are present in system."];

	//create two empty lists
	
	in_p =  (ListElement*)malloc(sizeof(ListElement));
	out_p = (ListElement*)malloc(sizeof(ListElement));
	endin_p = AdLinkedListCreate(in_p);
	endout_p = AdLinkedListCreate(out_p);
	indexBuffer = malloc(100*sizeof(int));
	noAtoms = [interactions count];	

	incount = outcount = 0;
	for(i=0; i < noAtoms; i++)
	{	
		indexSet = [interactions objectAtIndex: i];
		if([indexSet firstIndex] != NSNotFound)
		{
			indexRange.location = [indexSet firstIndex];
			indexRange.length = [indexSet lastIndex] - indexRange.location + 1;
			do
			{	
				retVal = [indexSet getIndexes: indexBuffer maxCount: 100 inIndexRange: &indexRange];
				for(k=0; k<retVal; k++)
				{
					//calculate distance	
					for(j=0; j<3; j++)
						seperation_s.vector[j] = coordinates->matrix[i][j] -
									 coordinates->matrix[indexBuffer[k]][j];

					//calculate the length of the seperation vector
					Ad3DVectorLength(&seperation_s);
					
					if(seperation_s.length < cutoff)
					{
						//add to inside list;
						list_p = (ListElement*)malloc(sizeof(ListElement));
						list_p->bond[0] = i;
						list_p->bond[1] = indexBuffer[k];
						list_p->length = seperation_s.length;
						AdSafeLinkedListAdd(list_p, endin_p, 0);
						incount++;
					}
					else
					{
						//add to outside list
						list_p = (ListElement*)malloc(sizeof(ListElement));
						list_p->bond[0] = i;
						list_p->bond[1] = indexBuffer[k];
						AdSafeLinkedListAdd(list_p, endout_p, 0);
						outcount++;			
					}
				}
			}
			while(retVal == 100); 
		}
	}	
		
	free(indexBuffer);
	numberOfInteractions = AdLinkedListCount(in_p) - 1;
	listCreated = YES;
	
	GSPrintf(stderr, @"Number of nonbonded interactions inside cuttoff = %d.\n", incount);
	GSPrintf(stderr, @"Number of nonbonded interactions outside cuttoff = %d.\n", outcount);
}

- (void) update
{
	int j;
	ListElement *holder, *list_p;
	Vector3D seperation_s;
	
	if(!listCreated)
		return;
	
	list_p = out_p->next;
	while(list_p->next != NULL)
	{
		//calculate seperation of current bond
		
		for(j=0; j<3; j++)
			seperation_s.vector[j] = coordinates->matrix[list_p->bond[0]][j] - coordinates->matrix[list_p->bond[1]][j];

		//calculate the length of the seperation vector

		Ad3DVectorLength(&seperation_s);

		if(seperation_s.length < cutoff)
		{
			//hold the address of the next element
			
			holder = list_p;
			list_p = list_p->next;
			
			//remove the current element from the list
			
			AdUnsafeLinkedListRemove(holder);
			holder->length = seperation_s.length;
			AdUnsafeLinkedListAdd(holder, endin_p, 0);
		}
		else
			list_p = list_p->next;
	}

	//check through the inside list for any interactions that are now outside the cutoff
	//move to the first real element of inside

	list_p = in_p->next;
	
	while(list_p->length > 0 && list_p->next != NULL )
	{
		if(list_p->length > cutoff)
		{
			//hold the address of the next element
			
			holder = list_p;
			list_p = list_p->next;
			
			//remove the current element from the list
			
			AdUnsafeLinkedListRemove(holder);
			AdUnsafeLinkedListAdd(holder, endout_p, 0);
		}
		else
		{
			list_p = list_p->next;
		}
	}

	numberOfInteractions = AdLinkedListCount(in_p) - 1;

	NSLog(@"Updated list - There are %d interactions", numberOfInteractions);

	[delegate handlerDidUpdateList: self];
}

/*
 * Delgate
 */

- (void) setDelegate: (id) anObject;
{
	if(![anObject conformsToProtocol: @protocol(AdListHandlerDelegate)])
		[NSException raise: NSInvalidArgumentException
			format: @"Object does not conform to AdListHandlerDelegate"];

	delegate = anObject;		
}

- (id) delegate
{
	return [[delegate retain] autorelease];
}

/*******************

Accessors

*********************/

- (void) setSystem: (id) aSystem
{
	BOOL invalidatedList = NO;

	//Free lists if they exist
	if(in_p != NULL)
	{
		[self _freeLists];
		invalidatedList = YES;
	}

	//Clean up related to previous system
	if(system != nil)
	{
		[[NSNotificationCenter defaultCenter]
			removeObserver: self];
		[system release];	
		coordinates = NULL;
	}	

	system = [aSystem retain];
	if(system != nil)
	{
		coordinates = [aSystem coordinates];
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleSystemContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: system];
	}

	listCreated = NO;
	if(invalidatedList)
		[delegate handlerDidInvalidateList: self];
}

- (id) system
{
	return [[system retain] autorelease];
}

- (void) setAllowedPairs: (NSArray*) anArray
{
	BOOL invalidatedList = NO;

	//Free lists if they exist
	if(in_p != NULL)
	{
		[self _freeLists];
		invalidatedList = YES;
	}

	[interactions release];
	interactions = [anArray retain];
	listCreated = NO;
	if(invalidatedList)
		[delegate handlerDidInvalidateList: self];
}

- (NSArray*) allowedPairs
{
	return [[interactions copy] autorelease];
}

- (void) setCutoff: (double) aValue
{
	if(cutoff < 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Cutoff must be greater than 0"];

	cutoff = aValue;
}

- (double) cutoff
{
	return cutoff;
}

- (NSValue*) pairList
{
	return [NSValue valueWithPointer: in_p];
}

- (int) numberOfListElements
{
	return numberOfInteractions;
}

@end
