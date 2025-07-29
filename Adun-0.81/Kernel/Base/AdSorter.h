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

#ifndef SORTER
#define SORTER

/**
Structure used with IndexSorter
\ingroup Types
**/

typedef struct
{
	int index;
	double property;
}
Sort;

/**
\defgroup Sort Sorting
\ingroup Functions
@{
*/
int AdIndexSorter(const void* el_one, const void* el_two);
int AdAscendingIntSort(const void* numberOne, const void* numberTwo);

/** \@}**/

#endif
