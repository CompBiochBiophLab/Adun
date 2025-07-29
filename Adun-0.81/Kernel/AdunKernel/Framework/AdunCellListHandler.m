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
#include "AdunKernel/AdunCellListHandler.h"

/*
Category containing methods for creating and
destroying the cell space
*/
@interface AdCellListHandler (CellMaintainence)
- (void) initialiseCells;
- (void) clearCellMatrices;
@end

@implementation AdCellListHandler

/**********************************

Cell Assignment 

***********************************/

//allocates the required coordinate matrices

- (void) _initialisationForCoordinates
{
	atomCells = [memoryManager allocateIntMatrixWithRows: coordinates->no_rows 
			withColumns: 3];
	cellNumber = [memoryManager allocateArrayOfSize: 
			coordinates->no_rows*sizeof(int)];
}

//allocates the required interaction arrays

- (void) _initialisationForInteractions
{
	int i;

	updateCheckInteractions = [memoryManager allocateArrayOfSize:
					[interactions count]*sizeof(IntArrayStruct)];
	for(i = 0; i<(int)[interactions count]; i++)
		updateCheckInteractions[i].array = NULL;
}

//frees the coordinate related matrices

- (void) _clearCoordinateMatrices
{
	[memoryManager freeIntMatrix: atomCells];
	[memoryManager freeArray: cellNumber];
}	

/**
Creates a matrix which holds the contents of each cell.
Initially space to hold (numberAtoms/numberCells) atoms 
is allocated for each cell.
Note: Should just realloc the array associated with each cell
to the base size and set its contents to 0.
*/
- (void) _initContentsArrays
{
	int i;

	if(cellContentsMatrix == NULL)
	{	
		NSDebugLLog(@"AdCellListHandler", 
			@"Allocating cellContentsMatrix (%@)", 
			NSStringFromClass([self class]));
		cellContentsMatrix = [memoryManager allocateArrayOfSize:
					numberOfCells*sizeof(IntArrayStruct)];
	}	
	else
	{
		for(i=0; i< numberOfCells; i++)
			free(cellContentsMatrix[i].array);
	}		
				
	baseSize = (int)ceil(((double)coordinates->no_rows)/(double)numberOfCells);
	for(i=0; i<numberOfCells; i++)
	{	
		cellContentsMatrix[i].array = (int*)malloc(baseSize*sizeof(int));
		cellContentsMatrix[i].length = 0;
	}
}

/*
 * For each atom assign it an x,y,z z cell index which tells you the cell its in.
 * For more information on the process see _updateCellIndexes:
 */
- (BOOL) _assignCellIndexes 
{
	BOOL assignmentSuccess = YES;
	int i, j;
	IntArrayStruct* cellContentsArray;

	//this exception is generic since we dont want it to be caught with the one below

	if(coordinates == NULL)
		[NSException raise: NSGenericException 
			format: @"No atom coordinates set. Cannot build interaction list"];

	/*
	 * Recreate the cell contents matrix.
	 * This step is probably inefficent. 
	 * Must be a better way to update the cell contents
	 */
	[self _initContentsArrays];

	NSDebugLLog(@"AdCellListHandler", @"Assigning atoms to cells");

	//find the cell coordinates and cell number for each atom
	//add that atom to atomsInCell array

	for(i=0; i<coordinates->no_rows; i++)
	{
		for(j=0; j<3; j++)
			atomCells->matrix[i][j] = (int)floor((coordinates->matrix[i][j] - minSpaceBoundry.vector[j])/cellSize);
		
		cellNumber[i] = (cellsPerAxis[2]*cellsPerAxis[1])*atomCells->matrix[i][0];
		cellNumber[i] += cellsPerAxis[2]*atomCells->matrix[i][1]; 
		cellNumber[i] += atomCells->matrix[i][2];

		cellContentsArray = &cellContentsMatrix[cellNumber[i]];
		if(cellNumber[i] > numberOfCells || cellNumber[i] < 0)
		{
			assignmentSuccess = NO;
			break;
		}	

		if(cellContentsArray->length >= baseSize)
			cellContentsArray->array = realloc(cellContentsArray->array, (cellContentsArray->length + 1)*sizeof(int));
		
		cellContentsArray->array[cellContentsArray->length] = i;
		cellContentsArray->length++; 
	}

	//Trim the cell contents arrays where necessary
	//We have to do this regardless of whether the entire assignment 
	//process succeded or not
	for(i=0; i<numberOfCells; i++)
		cellContentsMatrix[i].array = realloc(cellContentsMatrix[i].array, cellContentsMatrix[i].length*sizeof(int));

	NSDebugLLog(@"AdCellListHandler", @"Complete");

	return assignmentSuccess;
}	

- (BOOL) _updateCellIndexes 
{
	BOOL updateSuccess = YES;
	int i,j,k;
	int number;
	int *new;
	IntArrayStruct* cellContentsArray;

	//this exception is generic since we dont want it to be caught with the one below

	if(coordinates == NULL)
		[NSException raise: NSGenericException 
			format: @"No atom coordinates set. Cannot build interaction list"];

	for(i=0; i<coordinates->no_rows; i++)
	{
		/*
		  Calculate what cell this atom is now in. 
		  Specfically we are calculating how many "cell blocks" it is away 
		  from the origin position in each direction.

		  Although we have broken the space occupied by the atoms into
		  cells it is likely that atoms will move out of this space. 
		  When this happens the number of cell blocks the atom is away along
		  one or more axis will either be greater than the current number of cells
		  we have created in that direction or it will be a negative number.

		  We check if this has happened in the following loop 
		  by comparing the cell index assigned to the number of cells there are
		  in that direction. If it is greater or equal we have to extend the cell
		  space to encompass all the atoms again. (Remember the first cell in
		  each direction has index 0 following the C convention for arrays).

		  We must do the same thing if the index < 0
		*/

		for(j=0; j<3; j++)
		{
			atomCells->matrix[i][j] = (int)floor((coordinates->matrix[i][j] - minSpaceBoundry.vector[j])/cellSize);
			if(atomCells->matrix[i][j] >= cellsPerAxis[j] || atomCells->matrix[i][j] < 0)
				updateSuccess = NO;
		}

		if(!updateSuccess)
			break;

		/*
		  Calculate the index of the cell this atom is in.
		  The cells are assigned indexes (single numbers) by counting first
		  along the z axis followed by the y axis and finally the x axis 
		  e.g. with two cell per axis the assignment order is
		  0,0,0 -> 0,0,1 -> 0,1,0 -> 0,1,1 -> 1,0,0 -> 1,0,1, -> 1,1,0 -> 1,1,1
		  The first cell will be given the index '0', the last '7'
		*/

		number = (cellsPerAxis[2]*cellsPerAxis[1])*atomCells->matrix[i][0];
		number += cellsPerAxis[2]*atomCells->matrix[i][1]; 
		number += atomCells->matrix[i][2];

		if(number != cellNumber[i])
		{
			//remove from old array 
			//\note - make these functions
			cellContentsArray = &cellContentsMatrix[cellNumber[i]];
			new = malloc((cellContentsArray->length - 1)*sizeof(int));
			
			for(k = 0, j=0; k< cellContentsArray->length; k++)
				if(cellContentsArray->array[k] != i)
				{
					new[j] = cellContentsArray->array[k];
					j++;
				}	

			cellContentsArray->length = cellContentsArray->length -1;
			free(cellContentsArray->array);
			cellContentsArray->array = new;
			
			if(j != cellContentsArray->length)
				NSWarnLog(@"Warning %d %d", j, cellContentsArray->length);

			//add to new array
			
			cellContentsArray = &cellContentsMatrix[number];
			new = malloc((cellContentsArray->length + 1)*sizeof(int));
			for(k = 0, j=0 ; k < cellContentsArray->length; k++)
			{
				if(cellContentsArray->array[k] > i && j == k)
				{
					new[j] = i;
					j++;
				}

				new[j] = cellContentsArray->array[k];
				j++;
			}		

			if(j == k)
				new[j] = i;
			
			cellContentsArray->length++;
			free(cellContentsArray->array);
			cellContentsArray->array = new;

			cellNumber[i] = number;
		}
	}

	return updateSuccess;
}	

/**********************

Create List Elements

**********************/

- (void) _clearListDependants
{
	int i;
	
	if(updateCheckInteractions != NULL)
		for(i=0; i< (int)[interactions count]; i++)
			free(updateCheckInteractions[i].array);
}	

- (BOOL) _checkInteractionBetweenAtomOne: (int) atomOne atomTwo: (int) atomTwo
{
	int l;
	ListElement* el_p;
	Vector3D seperation;

	for(l = 0; l < 3; l++)
		seperation.vector[l] = coordinates->matrix[atomOne][l] - coordinates->matrix[atomTwo][l];

	Ad3DVectorLengthSquared(&seperation);

	if(seperation.length < cutoff_sq)
	{
		el_p = 	getElement(nonbondedList, @selector(getNewListElement));
		el_p->bond[0] = atomOne;
		el_p->bond[1] = atomTwo;
		el_p->length = 0;
		return YES;
	}
		
	return NO;
}

//Called when the systems contents change. We re-aquire coordinates
//and invalidate the current list.
- (void) _handleSystemContentsChange: (NSNotification*) aNotification
{

	//Note: It is not safe to call description (i.e print ourselves)
	//Until the reloading has been done - there is an update call in description.
	NSDebugLLog(@"AdCellListHandler", 
		@"Received contents change notification from %@",
		[system systemName]);

	//Deallocated all current cell and coordinate related ivars.
	[self clearCellMatrices];
	[self _clearCoordinateMatrices];
	[self _clearListDependants];
	[interactions release];
	interactions = nil;
	
	if(updateCheckInteractions != NULL)
		free(updateCheckInteractions);

	//Dealloc the list
	[nonbondedList release];
	nonbondedList = nil;

	//Update state ivars.
	listCreated = NO;
	cellsInitialised = NO;

	//Load new coordinates and initialise neccessary ivars.
	coordinates = [system coordinates];
	[self _initialisationForCoordinates];

	[delegate handlerDidHandleContentChange: self];
	
	NSDebugLLog(@"AdCellListHandler", @"Handled reload - %@",self);
}

/***********************************

Public Methods 

************************************/

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];

	/* 
	 * Peform an update to be sure the reported number of interactions
	 * is corrects for the set cutoff and nonbonded pairs.
	 * This will have no effect if the list hasnt been created yet
	*/
	
	description = [NSMutableString stringWithString: @"List handler type: Cell. "];
	if(system != nil && listCreated)
	{
		[self update];
		[description appendFormat: @"System: %@. Cutoff: %5.2lf. Number interactions: %d\n",
			[system systemName], cutoff, [nonbondedList listCount]];
		[description appendFormat: @"\tSpace dimensions: (%10.5lf, %10.5lf, %10.5lf)\n",	
			cellSpaceDimensions.vector[0], cellSpaceDimensions.vector[1], cellSpaceDimensions.vector[2]];
		[description appendFormat: @"\tCells per axis: (%d, %d, %d)\n",
			cellsPerAxis[0], cellsPerAxis[1], cellsPerAxis[2]];		
	}
	else
		[description appendString: @"No system set\n"];
		
	return description;	
}

- (void) createList
{
	int i,j;
	int atomIndex, cell, holder;
	int check, nocheck;
	int* inter;
	uint_fast8_t *bin; 
	int (*interact)(id, SEL, int*, int, NSRangePointer);
	ListElement* el_p;
	IntArrayStruct *checkInteractions, *cellContentsBuffer;
	IntArrayStruct interactionBuffer, neighbourCells, nocheckBuffer;
	NSEnumerator* interactionsEnum;
	NSMutableIndexSet *interaction;

	//If a list already exists do nothing. listCreated is only set
	//to NO if a new system of array of allowed pairs is set.
	if(listCreated)
		return;

	//Check if we have a system and interactions
	if(system ==  nil || interactions == nil)
		return;

	//Check if system and allowed pairs are compatible
	if((int)[interactions count] >= coordinates->no_rows)
		[NSException raise: NSInternalInconsistencyException
			format: @"Allowed pairs array implies more elements then are present in system."];

	//If the cell matrices havent been created create them now
	if(!cellsInitialised)
		[self initialiseCells];

	NSDebugLLog(@"AdCellListHandler", @"Building Interaction List (%@).", NSStringFromClass([self class]));

	//create a new list and deref getNewListElement
	nonbondedList = [AdLinkedList new];
	getElement = (ListElement* (*)(id, SEL))[nonbondedList methodForSelector:@selector(getNewListElement)];

	//The coordinates of the elements may not be accomadated by the current
	//cell space. We have to catch this eventuality and act accordingly.
	if(![self _assignCellIndexes])
	{
		NSDebugLLog(@"AdCellListHandler", @"The coordinates space has changed. Recalculating the cell space");
		[self clearCellMatrices];
		[self initialiseCells];
		[self _assignCellIndexes];
	}
	
	interactionBuffer.array = (int*)malloc(coordinates->no_rows*sizeof(int));
	nocheckBuffer.array = (int*)malloc(coordinates->no_rows*sizeof(int));
	inter = interactionBuffer.array;
	bin = (uint_fast8_t*)calloc(coordinates->no_rows,sizeof(uint_fast8_t));

	atomIndex = 0;
	interactionsEnum = [interactions objectEnumerator];

	NSDebugLLog(@"AdCellListHandler",
		@"There are %d interactions for system %@", [interactions count], [system systemName]);
	while((interaction = [interactionsEnum nextObject]))
	{
		if(([interaction count] == 0))
		{
			atomIndex++;
			continue;
		}	
		
		//load this atoms interactions into a buffer

		interact = (int (*)(id, SEL, int*, int, NSRangePointer))[interaction methodForSelector: 
					@selector(getIndexes:maxCount:inIndexRange:)];
		interactionBuffer.length = interact(interaction, 
							@selector(getIndexes:maxCount:inIndexRange:), 
							interactionBuffer.array, 
							coordinates->no_rows,
							NULL);
		
		for(i=0; i<interactionBuffer.length; i++)
			bin[interactionBuffer.array[i]] = 1;
		
		//get the atoms in the current cell

		cellContentsBuffer = &cellContentsMatrix[cellNumber[atomIndex]];
		for(nocheck=0, i = 0; i<cellContentsBuffer->length; i++)
		{
			holder = cellContentsBuffer->array[i];
			if(bin[holder])
			{
				nocheckBuffer.array[nocheck] = holder;
				nocheck++;
			}
		}

		//load the neighbourcell contents into a buffer
		
		neighbourCells = cellNeighbourMatrix[cellNumber[atomIndex]];
		for(check=0, i=0; i<neighbourCells.length; i++)
		{
			cell = neighbourCells.array[i];
			cellContentsBuffer = &cellContentsMatrix[neighbourCells.array[i]];
			if(cellContentsBuffer->length != 0)
				for(j=0; j < cellContentsBuffer->length; j++)
				{
					holder = cellContentsBuffer->array[j];
					if(bin[holder])
					{
						inter[check] = holder;
						check++;
					}
				}
		}

		checkInteractions = &updateCheckInteractions[atomIndex];
		checkInteractions->array = malloc((check+nocheck)*sizeof(int));
		checkInteractions->length = 0;

		for(j=0; j<check; j++)
			if([self _checkInteractionBetweenAtomOne: atomIndex atomTwo: inter[j]])
			{
				checkInteractions->array[checkInteractions->length] = inter[j];
				checkInteractions->length++;
			}					

		for(i=0;i<nocheck; i++)
		{	
			el_p = 	getElement(nonbondedList, @selector(getNewListElement));
			el_p->bond[0] = atomIndex;
			el_p->bond[1] = nocheckBuffer.array[i];
			el_p->length = 0;
			checkInteractions->array[checkInteractions->length] = nocheckBuffer.array[i];
			checkInteractions->length++;
		}
		
		checkInteractions->array = realloc(checkInteractions->array, checkInteractions->length*sizeof(int));
		memset(bin, 0, coordinates->no_rows*sizeof(uint_fast8_t));
		atomIndex++;
	}

	NSDebugLLog(@"AdCellListHandler",
		@"System %@ - %d nonbonded interactions.\n",
		[system systemName], [nonbondedList listCount]);
	free(interactionBuffer.array);
	free(nocheckBuffer.array);
	free(bin);
	listCreated = YES;
}	

/*******************************

Update and related functions

********************************/

- (void) _updateListRemovingTo: (IntArrayStruct*) removedInteractions
{
	int atomOne, atomTwo;
	ListElement* holder, *list_p;

	list_p = [nonbondedList listStart]->next;
	while(list_p->next != NULL)
	{	
		if(list_p->length > cutoff)
		{
			holder = list_p;
			list_p = list_p->next;

			atomOne = holder->bond[0];
			atomTwo = holder->bond[1];
			
			if(removedInteractions[atomOne].length >= updateCheckInteractions[atomOne].length)
				removedInteractions[atomOne].array = realloc(removedInteractions[atomOne].array, 
						(removedInteractions[atomOne].length + 1)*sizeof(int));
							
			removedInteractions[atomOne].array[removedInteractions[atomOne].length] = atomTwo;	
			removedInteractions[atomOne].length++;

			[nonbondedList freeListElement: holder];
		}	
		else
			list_p = list_p->next;
	}	
	
	NSDebugLLog(@"AdCellListHandler", @"Removal complete. Now %d pairs", [nonbondedList listCount]);
}

/*
The update algorithm
1) Update all the cells contents
2) Remove all interactions beyond the cutoff from the list
3) Add any interactions that are now within the cutoff to the list
*/

- (void) update
{
	int i, j, k, cell, numberOfInteractionSets;;
	int atomTwo;
	double holder;
	IntArrayStruct currentInteractions, neighbourCells, *checkInteractions, newInteractions;
	IntArrayStruct *cellContentsBuffer, *removedInteractions, *removed;
	uint_fast8_t *cellBin;
	NSMutableIndexSet* interaction;
	Vector3D separation;
	BOOL (*interact)(id, SEL, int);	
	id (*fetch)(id, SEL, int);
	SEL selector, selector2;

	//Update does nothing if the createList hasnt
	//been called with the current system and pairs.

	if(!listCreated)
		return;

	NSDebugLLog(@"AdCellListHandler", @"  ");
	NSDebugLLog(@"AdCellListHandler", 
		@"Updating Lists for system %@ - Currently %d pairs", 
		[system systemName],
		[nonbondedList listCount]);
	
	/*
         * Step 1. Update cell contents
         */

	if(![self _updateCellIndexes])
	{
		NSDebugLLog(@"AdCellListHandler",
			 @"The coordinates space has changed. Recalculating the cell space");
		[self clearCellMatrices];
		[self initialiseCells];
		[self _assignCellIndexes];
	}


	/*
         * Setup for next steps.
	 * This is done after step 1 since there is a chance an
	 * exception due to an exploding simulation will be raised there.
	 * We dont want to leak the memory we are about to allocate.
	 */

	//FIXME: We can preallocate alot of these arrays and simply clear them
	//after each update.
	numberOfInteractionSets = [interactions count];
	cellBin = [memoryManager allocateArrayOfSize: sizeof(uint_fast8_t)*coordinates->no_rows];
	currentInteractions.array = [memoryManager allocateArrayOfSize: coordinates->no_rows*sizeof(int)];
	removedInteractions = [memoryManager allocateArrayOfSize: 
				numberOfInteractionSets*sizeof(IntArrayStruct)];
	
	for(i=0; i<numberOfInteractionSets; i++)
	{
		removedInteractions[i].array = malloc(updateCheckInteractions[i].length*sizeof(int));
		removedInteractions[i].length = 0;
	}
	
	selector = @selector(containsIndex:);
	selector2 = @selector(objectAtIndex:);

	//we cache this method call since will be using it alot
	fetch = (id (*)(id, SEL, int))[interactions 
			methodForSelector: @selector(objectAtIndex:)];
	
	/*
     	 * Step 2. Remove interactions greater than cutoff from list
 	 */
	
	[self _updateListRemovingTo: removedInteractions];
	
	/*
	   Step 3. Add new interactions.
	   This is the most complicated step since -
	   A) We dont want to check the same interactions that were
	      checked in step 2 i.e. those that are still in the list
	      and those we removed.
	   B) We dont want to check more atoms than we have to.

	   We check interactions atom by atom starting with the first.
	  
	   Holder is the farthest distance an atom can be from the
	   center of a cell while still include part of that cell within
	   its cutoff radius.
	*/

	holder = cutoff + diagonal;
	for(k=0; k< numberOfInteractionSets; k++)
	{	
		interaction = fetch(interactions, selector2, k);
		if([interaction count] == 0)
		{
			removed = &removedInteractions[k];
			free(removed->array);
			continue;
		}	

		currentInteractions.length = 0;
		interact = (BOOL (*)(id, SEL, int))[interaction methodForSelector: selector];
		
		/*
		  Load the possible interactions into a buffer called currentInteractions.
		  This is all other atoms in this atoms cell plus all atoms in neigbouring 
		  cells (aslong as part of the neighbouring cell is within the cutoff). 

		  A part of a neighbouring cell is within the cutoff distance of the
		  atom in question if the distance from the atom to the center of the
		  neighbouring cell is less than the distance defined by the variable holder.
		*/

		//get the atoms in the current cell
		cellContentsBuffer = &cellContentsMatrix[cellNumber[k]];
		for(i = 0; i<cellContentsBuffer->length; i++)
			if(cellContentsBuffer->array[i] > k)
			{
				currentInteractions.array[currentInteractions.length] = cellContentsBuffer->array[i];
				currentInteractions.length++;
			}

		//load the neighbourcell contents 
		neighbourCells = cellNeighbourMatrix[cellNumber[k]];
		for(i=0; i<neighbourCells.length; i++)
		{
			cell = neighbourCells.array[i];
			cellContentsBuffer = &cellContentsMatrix[cell];
			if(cellContentsBuffer->length != 0 && 
				cellContentsBuffer->array[cellContentsBuffer->length-1] > k)
			{
				for(j=0; j<3; j++)
					separation.vector[j] = cellCenterMatrix->matrix[cell][j] -
								 coordinates->matrix[k][j];
				
				Ad3DVectorLength(&separation);
				//If the separation is less than holder than some of this
				//cells atoms could be within the cutoff

				if(separation.length < holder) 
					for(j=0; j < cellContentsBuffer->length; j++)
						if(cellContentsBuffer->array[j] > k)
						{
							currentInteractions.array[currentInteractions.length] = 
									cellContentsBuffer->array[j];
							currentInteractions.length++;
						}
			}
		}

		/*
		  As mentioned above we dont want to check any interactions that were 
		  in the list when we began updating since these were delt with in step 2.
		  updateCheckInteractions is an array with one entry for each atom
		  except for the last (the kth entry is for atom k etc).
		  Each entry is another array that contains the indexes of all the atoms that 
		  the atom was interacting with in the last list i.e. the ones we dont want to check. 

		  In order to avoid these use a "bin" (called here cellBin). This is an array
		  with one element for every atom. The element is set to 1 if the interaction
		  was in the last list and is zero otherwise.
		*/

		//Set the relevant bin elements to 1
		checkInteractions = &updateCheckInteractions[k];
		for(i=0; i<checkInteractions->length; i++)
			cellBin[checkInteractions->array[i]] = 1;

		/*
		  Now we go through all the possible interactions we added to the buffer above
		  (currentInteractions) and check if they are within the cutoff.
		  We skip those whose element has been set to one in the bin (cellBin) and 
		  any who arent in this atoms interaction list.
		*/

		newInteractions.length = 0;
		newInteractions.array = malloc(coordinates->no_rows*sizeof(int));
		for(i=0; i< currentInteractions.length; i++)
		{
			atomTwo = currentInteractions.array[i];
			if(cellBin[atomTwo] != 1)
				if(interact(interaction, selector, atomTwo) == YES)
					if([self _checkInteractionBetweenAtomOne: k atomTwo: atomTwo])
					{
						newInteractions.array[newInteractions.length] = atomTwo;
						newInteractions.length++;
					}
		}

		/*
 		  Finally we want to create a new updateCheckInteraction entry for this
		  atom. Therefore we need to set to 0 the bin elements of 
		  all the atoms that we removed in step 2. 

		  removedInteractions is an array with one entry for each atom.
		  Each entry is an array containing the indexes of the atoms we removed
		  in step 2. 	
		  
		  After this the only elements in the bin set to one are those
		  that remained in the list after step 2. These combined with the ones
 		  we added above (in newInteractions) are what we want.
		*/

		removed = &removedInteractions[k];
		for(i=0; i<removed->length; i++)
			cellBin[removed->array[i]] = 0;

		//add the interactions still in the list to newInteractions

		for(i=0; i<checkInteractions->length; i++)	
			if(cellBin[checkInteractions->array[i]] == 1)
			{
				newInteractions.array[newInteractions.length] = checkInteractions->array[i];
				newInteractions.length++;
			}				

		newInteractions.array = realloc(newInteractions.array, newInteractions.length*sizeof(int));
		free(checkInteractions->array);
		free(removed->array);
		checkInteractions->array = newInteractions.array;
		checkInteractions->length = newInteractions.length;
		memset(cellBin, 0, sizeof(uint_fast8_t)*coordinates->no_rows);
	}
	NSDebugLLog(@"AdCellListHandler", 
		@"(%@) Update complete. Now %d pairs", 
		[system systemName],
		[nonbondedList listCount]);

	[memoryManager freeArray: cellBin];
	[memoryManager freeArray: currentInteractions.array];
	[memoryManager freeArray: removedInteractions];

	[delegate handlerDidUpdateList: self];
}

/*********************************

Object Creation and Maintenance Methods 

**********************************/

- (void) _initialiseDependants
{
	cutoff_sq = cutoff*cutoff;
	cellSize = cutoff/2;
	//The distance from a cell corner to the centre
	diagonal = 0.5*sqrt(3)*cellSize;
}

- (id) initWithSystem: (id) aSystem	
	allowedPairs: (NSArray*) anArray
	cutoff: (double) valueOne
{
	return [self initWithSystem: aSystem
		allowedPairs: anArray
		cutoff: valueOne
		maximumSpaceSize: 1000.0];
}

- (id) initWithSystem: (id) aSystem	
	allowedPairs: (NSArray*) anArray 
	cutoff: (double) valueOne
	maximumSpaceSize: (double) valueTwo
{
	if((self = [super init]))
	{
		memoryManager = [AdMemoryManager appMemoryManager];
		updateCheckInteractions = NULL;
		nonbondedList = nil;
		listCreated = NO; 
		cellsInitialised = NO; //Indicates if we've created the cell space
		[self setSystem: aSystem];
		[self setAllowedPairs: anArray];
	
		if(valueTwo <= 0)
			maxSpaceSize = 1000;
		else
			maxSpaceSize = valueTwo;

		if(valueOne < 0)
			cutoff = 12;
		else
			cutoff = valueOne;

		[self _initialiseDependants];
	}

	return self;
}

- (void) dealloc
{
	[self _clearListDependants];
	free(updateCheckInteractions);
	[self _clearCoordinateMatrices];

	if(cellsInitialised)
		[self clearCellMatrices];

	[nonbondedList release];
	[system release];
	[interactions release];
	[super dealloc];
}

/*******************

Accessors

*********************/

- (void) setSystem: (id) aSystem
{
	BOOL invalidatedList = NO;

	if(system != nil)
	{
		[[NSNotificationCenter defaultCenter]
			removeObserver: self];
		//Deallocate all current cell and coordinate related ivars.
		[self clearCellMatrices];
		[self _clearCoordinateMatrices];
		[self _clearListDependants];

		//Dealloc the list
		[nonbondedList release];
		nonbondedList = nil;
		[system release];

		//Update state ivars.
		listCreated = NO;
		cellsInitialised = NO;
		invalidatedList = YES;
	}	

	system = [aSystem retain];
	if(system != nil)
	{	
		//Load new coordinates and initialise neccessary ivars.
		coordinates = [system coordinates];
		[self _initialisationForCoordinates];
		//Register for AdSystemContentsDidChangeNotification
		[[NSNotificationCenter defaultCenter]
			addObserver: self
			selector: @selector(_handleSystemContentsChange:)
			name: @"AdSystemContentsDidChangeNotification"
			object: system];
	}	

	//If we invalidated the linked list notify our delegate
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

	if(interactions != nil)
	{
		//Release previous interactions and deallocated the list
		[interactions release];
		[self _clearListDependants];
		if(updateCheckInteractions != NULL)
			free(updateCheckInteractions);
		[nonbondedList release];
		invalidatedList = YES;
	}	

	interactions = [anArray retain];	
	[self _initialisationForInteractions];
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
	[self _initialiseDependants];
	
	//If the list has been created and the cutoff is changed
	//then the cell space has to be recreated.
	if(listCreated)
	{
		[self clearCellMatrices];
		[self initialiseCells];
		[self _assignCellIndexes];
	}
}

- (double) cutoff
{
	return cutoff;
}

- (NSValue*) pairList
{
	if(nonbondedList == nil)
		return [NSValue valueWithPointer: NULL];

	return [NSValue valueWithPointer: [nonbondedList listStart]];
}

- (int) numberOfListElements
{
	return [nonbondedList listCount];
}

/*
 * Delgate
 */

- (void) setDelegate: (id) anObject;
{
	if(![anObject conformsToProtocol: @protocol(AdListHandlerDelegate)])
		[NSException raise: NSInvalidArgumentException
			format: @"Object does not conform to AdListHandlerDelegate protocol"];

	delegate = anObject;		
}

- (id) delegate
{
	return [[delegate retain] autorelease];
}

@end


/*
Preliminary refactoring of cell related methods to a category. 
These methods allocate the following arrays and matrices:
cellsPerAxis
cellCenterMatrix
cellIndexMatrix
cellNeighbourMatrix
cellContentsMatrix
*/

@implementation AdCellListHandler (CellMaintainence)

/*
Locates the boundaries of the rectangular box that encloses all the atoms. 
We then extend them so we can fit an integer number of cells in each 
direction.  (The cell size is half the cutoff chosen).
Finally we add some padding by extending each boundary by half the cell size 
- Effectivly adding one extra cell in each direction.

To handle exploding simulations we check against the user defined max
space size. If the cell space would be greater in any direction than
this number we raise an exception.
*/

- (void) _locateCellSpaceBoundries
{
	int i;
	double* coordinateArray;
	double xdiff, ydiff, zdiff;
	NSError* error;
	NSException* exception;

	coordinateArray = [memoryManager allocateArrayOfSize: coordinates->no_rows*sizeof(double)];

	NSDebugLLog(@"AdCellListHandler", @"Finding the space extremes");
	
	//the mininum and maximum x coordinates	

	for(i=0; i<coordinates->no_rows; i++)
		coordinateArray[i] = coordinates->matrix[i][0];

	minSpaceBoundry.vector[0] = coordinateArray[AdDoubleArrayMin(coordinateArray, coordinates->no_rows)];
	maxSpaceBoundry.vector[0] = coordinateArray[AdDoubleArrayMax(coordinateArray, coordinates->no_rows)];

	//the mininum and maximum y coordinates	

	for(i=0; i<coordinates->no_rows; i++)
		coordinateArray[i] = coordinates->matrix[i][1];

	minSpaceBoundry.vector[1] = coordinateArray[AdDoubleArrayMin(coordinateArray, coordinates->no_rows)];
	maxSpaceBoundry.vector[1] = coordinateArray[AdDoubleArrayMax(coordinateArray, coordinates->no_rows)];
	
	//the mininum and maximum z coordinates	

	for(i=0; i<coordinates->no_rows; i++)
		coordinateArray[i] = coordinates->matrix[i][2];

	minSpaceBoundry.vector[2] = coordinateArray[AdDoubleArrayMin(coordinateArray, coordinates->no_rows)];
	maxSpaceBoundry.vector[2] = coordinateArray[AdDoubleArrayMax(coordinateArray, coordinates->no_rows)];

	free(coordinateArray);

	NSDebugLLog(@"AdCellListHandler", @"Minimum: %-10.3lf %-10.3lf %-10.3lf", 
			minSpaceBoundry.vector[0], minSpaceBoundry.vector[1], minSpaceBoundry.vector[2]);
	NSDebugLLog(@"AdCellListHandler", @"Maximim: %-10.3lf %-10.3lf %-10.3lf", 
			maxSpaceBoundry.vector[0], maxSpaceBoundry.vector[1], maxSpaceBoundry.vector[2]);

	//Add one cell padding around the space to limit rebuilding
	//Half a cell on each side

	minSpaceBoundry.vector[0] -= cellSize/2;
	minSpaceBoundry.vector[1] -= cellSize/2;
	minSpaceBoundry.vector[2] -= cellSize/2;
	maxSpaceBoundry.vector[0] += cellSize/2;
	maxSpaceBoundry.vector[1] += cellSize/2;
	maxSpaceBoundry.vector[2] += cellSize/2;
	
	//find how many cells are needed in each direction
	
	cellSpaceDimensions.vector[0] = maxSpaceBoundry.vector[0] - minSpaceBoundry.vector[0];
	cellSpaceDimensions.vector[1] = maxSpaceBoundry.vector[1] - minSpaceBoundry.vector[1];
	cellSpaceDimensions.vector[2] = maxSpaceBoundry.vector[2] - minSpaceBoundry.vector[2];

	//if by chance any of the cellSpaceDimensions == 0, put it equal to one
	//this will happen if the molecule lies entirely in an axis plane.

	for(i=0; i<3; i++)
		if(cellSpaceDimensions.vector[i] == 0)
			cellSpaceDimensions.vector[i] = 1;

	cellsPerAxis = [memoryManager allocateArrayOfSize: 3*sizeof(int)];
	cellsPerAxis[0] = (int)ceil(cellSpaceDimensions.vector[0]/cellSize);
	cellsPerAxis[1] = (int)ceil(cellSpaceDimensions.vector[1]/cellSize);
	cellsPerAxis[2] = (int)ceil(cellSpaceDimensions.vector[2]/cellSize);

	NSDebugLLog(@"AdCellListHandler", @"Cells per axis: %d %d %d", 
			cellsPerAxis[0], 
			cellsPerAxis[1],
			cellsPerAxis[2]);

	//calculate how much we need to move each boundary to accomadate the necessary cells

	xdiff = cellsPerAxis[0]*cellSize - cellSpaceDimensions.vector[0];
	ydiff = cellsPerAxis[1]*cellSize - cellSpaceDimensions.vector[1];
	zdiff = cellsPerAxis[2]*cellSize - cellSpaceDimensions.vector[2];

	//increase each boundary by half the difference 

	minSpaceBoundry.vector[0] -= xdiff/2;
	minSpaceBoundry.vector[1] -= ydiff/2;
	minSpaceBoundry.vector[2] -= zdiff/2;
	maxSpaceBoundry.vector[0] += xdiff/2;
	maxSpaceBoundry.vector[1] += ydiff/2;
	maxSpaceBoundry.vector[2] += zdiff/2;
	
	NSDebugLLog(@"AdCellListHandler", @"Recalculated  space extremes");
	NSDebugLLog(@"AdCellListHandler", @"Minimum: %-10.3lf %-10.3lf %-10.3lf", 
			minSpaceBoundry.vector[0], minSpaceBoundry.vector[1], minSpaceBoundry.vector[2]);
	NSDebugLLog(@"AdCellListHandler", @"Maximim: %-10.3lf %-10.3lf %-10.3lf", 
			maxSpaceBoundry.vector[0], maxSpaceBoundry.vector[1], maxSpaceBoundry.vector[2]);

	//recalculate the cellSpaceDimensions
	//check that none of the cellSpaceDimensions are greater the maxSpaceSize

	for(i=0; i<3; i++)
	{
		cellSpaceDimensions.vector[i] = cellsPerAxis[i]*cellSize;
		if(cellSpaceDimensions.vector[i] > maxSpaceSize)
		{
			//Make sure nothing tries to iterate later
			//over cells that arent there.
			numberOfCells = 0;
			error = AdCreateError(AdunKernelErrorDomain,
					AdKernelSimulationSpaceError,
					@"Simulation exceeded cell space",
					@"This indicates an exploding simulation.",
					@"Try minimising a previous checkpoint and restarting the calculation");
			exception = [NSException exceptionWithName: NSInternalInconsistencyException
					reason: [NSString stringWithFormat: 
						@"Coordinate space has exceeded size restriction (%lf, %lf)",
			 	 		maxSpaceSize, cellSpaceDimensions.vector[i]]
					userInfo: [NSDictionary dictionaryWithObject: error
							forKey: @"AdKnownExceptionError"]];
			[exception raise];				
		}		 
	}

	NSDebugLLog(@"AdCellListHandler", @"The cell space dimensions are %lf, %lf, %lf", 
			cellSpaceDimensions.vector[0],
		 	cellSpaceDimensions.vector[1], 
			cellSpaceDimensions.vector[2]);
}

//we first need to divide the space into a series of cells
//with defined centers and corresponding indexes (0,0,0) (0,0,1) etc.

- (void) _createCellMatrices
{
	int i,j,k;
	int xIndex, yIndex, zIndex, currentCell, number;
	IntArrayStruct* cellNeighbours;

	for(numberOfCells=1, i=0; i<3; i++)
		numberOfCells *= cellsPerAxis[i]; 

	NSDebugLLog(@"AdCellListHandler", @"Creating the cell matrices. There are %d cells", numberOfCells);
	
	cellCenterMatrix = [memoryManager allocateMatrixWithRows: numberOfCells withColumns: 3];
	cellIndexMatrix = [memoryManager allocateMatrixWithRows: numberOfCells withColumns: 3];

	//find center of cell (0,0,0) (the origin cell)
	originCellCenter.vector[0] = minSpaceBoundry.vector[0] + cellSize/2;
	originCellCenter.vector[1] = minSpaceBoundry.vector[1] + cellSize/2;
	originCellCenter.vector[2] = minSpaceBoundry.vector[2] + cellSize/2;
	
	NSDebugLLog(@"AdCellListHandler", @"The origin cell center is %lf, %lf, %lf", 
			originCellCenter.vector[0], originCellCenter.vector[1], originCellCenter.vector[2]);

	//the cell order is (x,y,z) - assign cell indexes in this order
	for(currentCell=0, i=0; i<cellsPerAxis[0];i++)
		for(j=0; j<cellsPerAxis[1];j++)
			for(k=0; k<cellsPerAxis[2];k++)
			{
				cellIndexMatrix->matrix[currentCell][0] = i;
				cellIndexMatrix->matrix[currentCell][1] = j;
				cellIndexMatrix->matrix[currentCell][2] = k;
				currentCell++;
			}
	
	//use the cellIndexMatrix to assign coordinates to the cell centers
	for(i=0; i<numberOfCells; i++)
		for(j=0; j<3; j++)
			cellCenterMatrix->matrix[i][j] = originCellCenter.vector[j] + cellIndexMatrix->matrix[i][j]*cellSize;

	//create the cell neighbour array
	cellNeighbourMatrix = [memoryManager allocateArrayOfSize: numberOfCells*sizeof(IntArrayStruct)];
	for(currentCell = 0; currentCell < numberOfCells; currentCell++)
	{
		cellNeighbours = &cellNeighbourMatrix[currentCell];
		cellNeighbours->array = [memoryManager allocateArrayOfSize: 80*sizeof(int)];
		cellNeighbours->length = 0;

		xIndex = (int)cellIndexMatrix->matrix[currentCell][0];
		yIndex = (int)cellIndexMatrix->matrix[currentCell][1];
		zIndex = (int)cellIndexMatrix->matrix[currentCell][2];

		for(i= xIndex - 2; i <= xIndex + 2; i++)
			if(i >= 0 && i < cellsPerAxis[0])
				for(j = yIndex -2; j<= yIndex + 2; j++)
					if(j >= 0 && j < cellsPerAxis[1])
						for(k = zIndex -2; k <= zIndex + 2; k++)
							if(k>=0 && k < cellsPerAxis[2])
							{
								number =  (cellsPerAxis[2]*cellsPerAxis[1])*i + cellsPerAxis[2]*j + k;
								if(number != currentCell && number < numberOfCells)
								{
									//check if reallocing is needed
									if(cellNeighbourMatrix[currentCell].length >= 80)
										cellNeighbours->array = realloc(cellNeighbours->array,
												 (cellNeighbours->length + 1)*sizeof(int));
									cellNeighbours->array[cellNeighbours->length] = number;
									cellNeighbours->length++;
		
								}
							}

		//trim the memory to the neccessary size
		cellNeighbours->array = realloc(cellNeighbours->array, (cellNeighbours->length)*sizeof(int));
	}	

	//Initialise CellContents array
	cellContentsMatrix = [memoryManager allocateArrayOfSize: numberOfCells*sizeof(IntArrayStruct)];
	baseSize = (int)ceil(((double)coordinates->no_rows)/(double)numberOfCells);

	for(i=0; i<numberOfCells; i++)
	{	
		cellContentsMatrix[i].array = (int*)malloc(baseSize*sizeof(int));
		cellContentsMatrix[i].length = 0;
	}
}

- (void) initialiseCells
{
	NSDebugLLog(@"AdCellListHandler", @"Initialising cell space");
	NSDebugLLog(@"AdCellListHandler", @"Locating space boundaries");
	[self _locateCellSpaceBoundries];
	NSDebugLLog(@"AdCellListHandler", @"Creating cell Matrices");
	[self _createCellMatrices];
	cellsInitialised = YES;
	NSDebugLLog(@"AdCellListHandler", @"Complete");
}

/**
Deallocates the matrices containing the coordinates of the cell
centers and the cell indexes.
*/
- (void) clearCellMatrices
{
	int i;

	NSDebugLLog(@"AdCellListHandler", @"Freeing cell matrices");
	
	[memoryManager freeMatrix: cellCenterMatrix];
	[memoryManager freeMatrix: cellIndexMatrix];
	
	for(i=0; i<numberOfCells;i++)
	{
		[memoryManager freeArray: cellNeighbourMatrix[i].array];
		[memoryManager freeArray: cellContentsMatrix[i].array];
	}
	[memoryManager freeArray: cellNeighbourMatrix];
	[memoryManager freeArray: cellContentsMatrix];
	[memoryManager freeArray: cellsPerAxis];
	
	cellCenterMatrix = NULL;
	cellIndexMatrix = NULL;
	cellNeighbourMatrix = NULL;
	cellContentsMatrix = NULL;
	cellsPerAxis = NULL;
	
	cellsInitialised = NO;
	
	NSDebugLLog(@"AdCellListHandler", @"Complete");
}

@end
