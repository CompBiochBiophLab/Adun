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
#ifndef ADCELL_LISTHANDLER
#define ADCELL_LISTHANDLER

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <time.h>
#include "Base/AdVector.h"
#include "Base/AdSorter.h"
#include "Base/AdLinkedList.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunInteractionSystem.h"

/**
\ingroup Inter
AdListHandler subclass that uses a cell based method for creating
and updating its list.

AdCellListHandler instances partition the space occupied by the elements
into cells. Each cell is a cube of side \f$ \frac {r_{cutoff}}{2} \f$. The elements contained in each
cell are recalculated every time update() is called. 

By partioning the space in this way AdCellListHandler instances do not have
to check the entire space when updating - only elements in cells whose centers are
less than 
\f$
r_{cutoff}(1 + \frac{1}{2\sqrt{2}} )
\f$
away from each element need to be checked.
\todo Refactor - Calculate maximum space size internally if its not provided.
**/
@interface AdCellListHandler: AdListHandler
{
	@private
	BOOL cellsInitialised;
	BOOL listCreated;
	int numberOfCells;
	int baseSize;		//The initial size of each array in cellContentsMatrix
	int* cellsPerAxis;
	int* cellNumber;	//An array containing the number of the cell each atom is in
	double cellSize;
	double cutoff;
	double maxSpaceSize;
	double cutoff_sq;
	double cellCut;
	double inCut;
	double diagonal;	
	AdMatrix* coordinates;
	AdMatrix* cellCenterMatrix;	//A matrix of the coordinates of the centers of each cell
	AdMatrix* cellIndexMatrix;	//A matrix of the indexes of each cell
	IntMatrix* atomCells;		//A matrix of the indexes of the cell each atom is in.
	Vector3D originCellCenter;	//The coordinates of the center of cell (0,0,0)
	Vector3D minSpaceBoundry;	//The (-,-,-) extremity of the cell space
	Vector3D maxSpaceBoundry;	//The (+,+,+) extremity of the cell space
	Vector3D cellSpaceDimensions;	//The dimension of the cell space
	IntArrayStruct* cellNeighbourMatrix;	
	IntArrayStruct* cellContentsMatrix;	
	IntArrayStruct* updateCheckInteractions; //The interactions that are to be checked in each update step
	AdLinkedList* nonbondedList;
	ListElement* (*getElement)(id, SEL);
	NSArray* interactions;
	AdMemoryManager* memoryManager;
	id delegate;
	id system;
}
/**
Designated initialiser.
\param aSystem An AdSystem or AdInteractionSystem object. 
\param anArray An NSArray of NSIndexSets. See the requirements section of the AdListHandler class documentation for more.
\param valueOne The list cutoff (arbitrary units). If it is less than 0 it defaults to 12.
\param valueTwo Defines the maximum size of the cell space along each axis. If at any time this distance must
be exceeded (along any axis) in order to accomadate all the elements then an NSInternalInconsistencyException
is raised. If \e valueTwo is less than or equal to 0 it defaults to 1000. This parameter main use is in
detecting exploding simulations.
*/
- (id) initWithSystem: (id) aSystem
	allowedPairs: (NSArray*) anArray
	cutoff: (double) valueOne
	maximumSpaceSize: (double) valueTwo;
/**
As initWithCoordinates:allowedPairs:cutoff:maximumSpaceSize: with
maximumSpaceSize set to 1000.
*/
- (id) initWithSystem: (id) aSystem	
	allowedPairs: (NSArray*) anArray 
	cutoff: (double) valueOne;
@end



#endif 

