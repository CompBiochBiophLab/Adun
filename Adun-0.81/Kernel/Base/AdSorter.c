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

#include "Base/AdSorter.h"

/*
This function sorts an array of indexes based on the
value of that index in another array 
e.g. if you have an array of values but you dont want
to sort the array itself you can use this method**/

int AdIndexSorter(const void* el_one, const void* el_two)
{
	Sort eone, etwo;
	
	//shouldnt really have to do this cast but its not compiling if i dont....
	//for some reason you cant just cast the void* to a Sorter*... wierd C....

	eone = *((Sort*)el_one);
	etwo = *((Sort*)el_two);

	return (eone.property > etwo.property)?1:-1;
}

int AdAscendingIntSort(const void* numberOne, const void* numberTwo)
{
	return (*(int*)numberTwo > *(int*)numberOne) ? -1 : 1;
}
