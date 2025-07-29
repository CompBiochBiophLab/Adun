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
#ifndef _ADUN_CORE_ADDITIONS_
#define _ADUN_CORE_ADDITIONS_

/**
\defgroup core AdunCore Program
\ingroup Kernel

	*/

/**
\defgroup coreClasses Classes
The AdunCore classes provide program functionality but are compiled as part of the AdunKernel framework for convience. 
\ingroup core
*/

/**
\defgroup coreProtocols Protocols
\ingroup core
*/

/**
\defgroup coreDataTypes DataTypes
\ingroup core
*/

/**
\defgroup coreConstants Constants
\ingroup core
*/

/**
\ingroup coreConstants
The error domain for the AdunCore program. 
See AdCoreErrorCodes for the error codes that can come from this domain. 
\note An error with this domain is associated with termination of the program.
*/
#define AdunCoreErrorDomain @"AdunCore.ErrorDomain"

/**
\ingroup coreDataTypes
Defines the error codes for the AdunCoreErrorDomain. Errors from this domain cause the program to exit and
hence the code of the error will also be the termination code of the program.
An AdCoreControllerError or AdCoreTemplateProcessingError can be due to an underlying AdKernelError or
an exception from a AdunKernel framework object.
*/
typedef enum
{
	AdCoreUnexpectedExceptionError = 0, 	/**< An exception rose to the top level of the program */
	AdCoreControllerError = 1, 	/**< Controller exited for some reason */
	AdCoreFatalCommandError = 2, 	/**< A core command raised an exception */
	AdCoreConnectionError = 3,	 /**< Unable to connect to server in server run mode*/
	AdCoreDirectoryStructureError = 4, 	/**< Program directory structure corrupted and unfixable*/
	AdCoreLogFileError = 5,		/**< Unable to create program log files*/
	AdCoreArgumentsError = 6,	/**< Invalid program arguments*/
	AdCoreInvalidTemplateError = 7,		/**< Invalid template */
	AdCoreTemplateProcessingError = 8,	/**< Template could not be processed for some reason. */
	AdCoreCommandError = 9,		/**< An error associated with execution of a command*/
	AdCoreSimulationDataStorageError = 10,		/**< An error associated with accessing simulation data*/
	AdCoreParallelEnvironmentError = 11,	/**< Something went wrong when setting up a parallel run*/
	AdCoreRestartError = 12		/**< Could not restart a simulation */
}
AdCoreErrorCodes;

#endif
