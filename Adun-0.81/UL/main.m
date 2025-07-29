/* 
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-23 13:29:49 +0200 by michael johnston

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

/**
\defgroup ul UserLand

Userland provides the topology generation, results processing and simulation managment functionality 
of the Adun Simulator aswell as its graphical frontend. It is designed according to the Model-View-Controller (MVC)
pattern. There are four layers in the UL implementation of this pattern.
\li \c view	The grapical frontend. 
\li \c view-controllers	Classes that respond to and manipulate the gui. This 
\li \c model-controllers Classes that manipulate the model
\li \c model 	The classes representing the core data of the program. Some of these are found in the AdunKernel library.

Communciation occurs between adjacent layers e.g. view <-> view-controllers -> model-controllers -> model

The Interface module contains all the view-controller classes while the model-controller classes along with some model classes 
are part of the ULFramework library. The majority of the model classes come from the AdunKernel library. The FFML Library is used by
ULFramework to parse force field files. 
**/

/**
\defgroup interface Interface
\ingroup ul
**/

/*
ULFramework and subgroupings
*/

/**
\defgroup ulframework ULFramework Library
\ingroup ul
**/

/**
\defgroup classes Classes
\ingroup ulframework
*/

/**
\defgroup functions Functions
\ingroup ulframework
*/

/**
\defgroup protocols Protocols
\ingroup ulframework
*/

#include <AppKit/AppKit.h>

int 
main(int argc, const char *argv[])
{
	return NSApplicationMain (argc, argv);
}

