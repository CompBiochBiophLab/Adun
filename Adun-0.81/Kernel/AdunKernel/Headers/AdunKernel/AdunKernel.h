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
#ifndef _ADUN_FRAMEWORK_
#define _ADUN_FRAMEWORK_

#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdDataSources.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdServerInterface.h"
#include "AdunKernel/AdIndexSetConversions.h"
#include "AdunKernel/AdMemento.h"
#include "AdunKernel/AdunTimer.h"
#include "AdunKernel/AdunModelObject.h"
#include "AdunKernel/AdunMatrixStructureCoder.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdunDataSet.h"
#include "AdunKernel/AdunDataSource.h"
#include "AdunKernel/AdunContainerDataSource.h"
#include "AdunKernel/AdunGrid.h"
#include "AdunKernel/AdunSphericalBox.h"
#include "AdunKernel/AdunEllipsoidBox.h"
#include "AdunKernel/AdunMoleculeCavity.h"
#include "AdunKernel/AdunCellListHandler.h"
#include "AdunKernel/AdunSimpleListHandler.h"
#include "AdunKernel/AdunLinkedList.h"
#include "AdunKernel/AdunListHandler.h"
#include "AdunKernel/AdunInteractionSystem.h"
#include "AdunKernel/AdunSystem.h"
#include "AdunKernel/AdunSystemCollection.h"
#include "AdunKernel/AdForceFieldTerm.h"
#include "AdunKernel/AdunSCAAS.h"
#include "AdunKernel/AdunNonbondedTerm.h"
#include "AdunKernel/AdunPureNonbondedTerm.h"
#include "AdunKernel/AdunGRFNonbondedTerm.h"
#include "AdunKernel/AdunSmoothedGBTerm.h"
#include "AdunKernel/AdunShiftedNonbondedTerm.h"
#include "AdunKernel/AdunForceField.h"
#include "AdunKernel/AdunEnzymixForceField.h"
#include "AdunKernel/AdunAmberForceField.h"
#include "AdunKernel/AdunCharmmForceField.h"
#include "AdunKernel/AdunForceFieldCollection.h"
#include "AdunKernel/AdunConfigurationGenerator.h"
#include "AdunKernel/AdunSimulator.h"
#include "AdunKernel/AdunMinimiser.h"
#include "AdunKernel/AdunLangevinThermostat.h"
#include "AdunKernel/AdunBerendsenThermostat.h"
#include "AdunKernel/AdunMemoryManager.h"

/**
\defgroup frameConstants Constants
\ingroup Frame
\todo Update constant names.
*/

/**
\defgroup frameworkTypes Data Types
\ingroup Frame
*/

/**
\defgroup Inter Classes
\ingroup Frame
**/

/**
\defgroup Protocols Protocols
\ingroup Frame
*/

/**
\defgroup Frame AdunKernel Framework
\ingroup Kernel

The AdunKernel Framework defines a collection of classes for use in building simulation applications.
It is designed with these goals in mind.

- To enable rapid development and implementation of different simulation algorithms and protocols by providing well defined 
conventions and a rigourous structure.
- To be independant of a particular force field or system type.
- To provide enhanced mechanisms for handling scientific simulation related data
	- Platform independant storage/retrieval
	- Data uniqueness
	- Metadata
	- Recording data usage.

The framework provides -

- Classes representing various types of simulation data - trajectories, collections of elements, sets of tabular data etc.
- Classes representing the core parts of a simulator 
- Collection classes which enable multiple instances of certain classes  e.g. AdForceField, to be combined 
- Classes representing common simulation structures e.g. dynamic lists, cartesian grids etc.

In addition a number of framework classes can be extended through the use of delegates. 
The framework defines uniform interfaces (protocols) for such delegate objects e.g.
force field terms (AdForceFieldTerm), cavities (AdGridDelegate) etc., and also provides a number of 
classes which implement these interfaces.
More such classes will be added to the Framework as it grows. The \ref classes section gives an overview of all the classes.

Several paradigms are employed to introduce consistency across the framework. For example -

- Delegation is used across class hierarchies to enable customisation.
- A small set of easily interconvertible structures is used for transmitting data between objects.
- AdMemoryManager provides a consistent interface for allocation/deallocation of C arrays and AdMatrix structs. 
- AdMainLoopTimer enables messages to be sent to objects during a configuration generation process.

These paradigms enable more efficent coding by reusing the same mechanisms with various objects. Since it is built on
the GNUstep Foundation Framework many of the paradigms introduced there are also present here e.g. object ownership,
object archiving, copying etc.

\section classes AdunKernel Framework Classes 

The framework classes can be divided into a small number of groups based on 
related functionality. What follows is a description of each group and the classes
they contain.

\subsection store Data Storage

- AdModelObject
	- AdDataSet
	- AdDataSource
		- AdMutableDataSource
- AdDataMatrix
	- AdMutableDataMatrix

<em> Description forthcoming </em>

\subsection ff Force Fields 

- AdForceFieldCollection
- AdForceField
	- AdMolecularMechanicsForceField
		- AdAmberForceField
		- AdCharmmForceField
		- AdEnzymixForceField
- AdForceFieldTerm
	- AdSCAAS
	- AdNonbondedTerm
		- AdPureNonbondedTerm
		- AdShiftedNonbondedTerm
		- AdGRFNonbondedTerm

<em> Description forthcoming </em>

\subsection sys Systems

- AdContainerDataSource
- AdSystem
- AdInteractionSystem
- AdSystemCollection

<em> Description forthcoming </em>

\subsection generate Configuration Generation

- AdConfigurationGenerator
	- AdSimulator
	- AdMinimiser
- AdSimulatorComponent
	- AdBerendsenThermostat
	- AdLangevinThermostat

<em> Description forthcoming </em>

\subsection grid Grids  

- AdGrid
- AdGridDelegate
	- AdSphericalBox
	- AdEllipsoidBox
	- AdMoleculeCavity

<em> Description forthcoming </em>

\subsection list Dynamic Lists 

- AdLinkedList
- AdListHandler
	- AdSimpleListHandler
	- AdCellListHandler

<em> Description forthcoming </em>

\subsection infra Infrastructure

- AdMemoryManager
- AdTimer
	- AdMainLoopTimer

<em> Description forthcoming </em>

\subsection Known Exceptions

Since simulations can fail due to a varity of reasons that are not under the programmers control e.g. numerical instability
due to user input, yet are hard to handle via standard error handling, the AdunKernel framework
uses the idea of known exceptions. A known exception is one that is caused by a common simulation error. When
one of these is detected an exception is raised whose userinfo dictionary contains the key "AdKnownExceptionError"
whose value is an NSError describing the reason for the failure. The error can then be extracted and used
in a normal error handling procedure.

\todo Improve error handling implementation - Error codes etc.
**/

/**
\defgroup plugins Plugins
**/

/**
\defgroup controllers Controllers
\ingroup plugins
*/





#endif
