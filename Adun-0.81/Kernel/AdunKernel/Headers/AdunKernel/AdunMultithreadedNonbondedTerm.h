/*
   Project: AdunKernel

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

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
#ifndef _ADMULTITHREADED_TERM
#define _ADMULTITHREADED_TERM
#include "AdunKernel/AdunNonbondedTerm.h"

/**
\ingroup Inter
Enables multithreading of a nonbonded term object.
\todo Test implementation
*/
@interface AdMultithreadedNonbondedTerm: AdNonbondedTerm
{
	int numberOfProcessors;
	id mainTerm;
	id threadedTerms;
	id allTerms;
	id dividedPairs;
	AdMatrix* forces;
	id threadManager;
}
/**
Returns a new AdMultithreadedNonbondedTerm instance that
can be used to do threaded calculation with \e nonbondedTerm
*/
- (id) initWithTerm: (AdNonbondedTerm*) nonbondedTerm;
@end

#endif
