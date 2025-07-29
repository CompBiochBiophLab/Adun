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

#ifndef _ADSIMPLE_LIST_HANDLER_
#define _ADSIMPLE_LIST_HANDLER_

#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunInteractionSystem.h"

/**
\ingroup Inter
AdSimpleListHandler encapsulates the simplest algorithm for
creating the nonbonded list - a brute force search. 
Its is impratical for any moderately sized system (for both speed and memory reasons)
but is useful for checking the function of more complicated handlers.
AdSimpleListHandler instances maintain lists for the elements inside and outside the
cutoff and hence require a large amount of memory to handle big systems.

\todo Internal - The memory requirements can be reduced by using NSIndexSets to store the
interactions outside the cutoff.
*/

@interface AdSimpleListHandler: AdListHandler
{
	@private
	BOOL listCreated;
	ListElement* in_p;
	ListElement* out_p;
	ListElement* endin_p;
	ListElement* endout_p;
	double cutoff;
	int numberOfInteractions;
	AdMatrix *coordinates;
	NSArray* interactions;
	id memoryManager;
	id delegate;
	id system;
}
/**
\bug Can only be called once.
*/
- (void) createList;
@end

#endif
