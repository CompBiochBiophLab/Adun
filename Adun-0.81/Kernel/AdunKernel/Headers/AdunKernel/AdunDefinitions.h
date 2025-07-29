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
//! \file
//! \brief Header file containing definitions. These constants define the untis used in the simulation 

/*
The basic simulation units are
  - Time : femtoseconds
  - Length : angstroms \f$ \AA \f$
  - Mass : Atomic Mass Unit \f$ Da \f$
  - Charge : Electron Charge Units \f$ e \f$
  - Energy : \f$ Da\AA^{2}.fs^{-2} \f$
  - Temperature : Kelvin
*/		 

#ifndef _ADUN_DEFINITIONS
#define _ADUN_DEFINITIONS

//Extra includes neccessary to use 
//gnustep base additions on OSX 
#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif
#include <fenv.h>
#include <Base/AdMatrix.h>
#include <Foundation/Foundation.h>

/**
\ingroup frameConstants 
Conversion factor for \f$ Da\AA^{2}.fs^{-2} \f$ (simulation energy unit) to \f$kcal.mol^{-1}\f$
*/
#define STCAL 2390.05735688

/**
\ingroup frameConstants
Conversion factor for \f$kcal.mol^{-1}\f$ to simulation units for energy
*/

#define BOND_FACTOR 4.184E-4 

/**
\ingroup frameConstants
Simulation energy to \f$ J.mol^{-1}\f$ (accurate to nine significant digits)
*/
#define STJMOL 1E7

/**
\ingroup frameConstants
Boltzmanns constant in simulation units
*/
#define KB 8.3144726887E-7

/**
\ingroup frameConstants
Reciprocal of Boltzmanns constant in simulation units
*/
#define KB_1 1202722.09368

/**
\ingroup frameConstants
Conversion factor for degrees to radians
*/
#define DEG_2_RAD M_PI/180

/**
\ingroup frameConstants
Conversion factor for \f$ ms^{-1} \f$ to \f$ \AA fs^{-1} \f$
*/
#define MS_2_AFS 0.00001

/**
\ingroup frameConstants
Value of sigma for finite difference functions
*/
#define AdFiniteDifferenceSigma 0.000001

/**
\ingroup frameConstants
\f$4\pi\f$ times the permitivity of free space in \f$ \frac {eu^{2}fd{2}}{amu.\AA^{3}} \f$
*/
#define EPSILON 7.19758673876

/**
\ingroup frameConstants
The reciprocal of epsilon
*/
#define PI4EP_R 0.1389354566

/**
\ingroup frameConstants
Conversion factor for \f$ kg.m^{-3} \f$ to \f$ amu.\AA^{-3} \f$
*/
#define DENSITY_FACTOR 6.02214151134E-4

/**
\ingroup frameConstants
 Conversion factor for Debye to eA
*/
#define FROMDEBYE 0.208194346224

/**
\ingroup frameConstants
The framework error domain.
*/
#define AdunKernelErrorDomain  @"AdunKernel.ErrorDomain"

/**
\ingroup frameConstants
GSL error domain.
 */
#define GSLErrorDomain  @"GNUScientificLibrary.ErrorDomain"

/**
\ingroup frameConstants
Conversion factor for Hartress to Simulation Energy
*/
#define FROMHARTREE 0.262549962955 

/**
\ingroup frameConstants
Bitwise OR of all supported floating point exceptions
*/
int AdFloatingPointExceptionMask;

/**
\ingroup frameConstants
The standard bonded interaction
*/
#define HarmonicBond @"HarmonicBond"

/**
\ingroup frameConstants
The standard angle interaction
*/
#define HarmonicAngle @"HarmonicAngle"

/**
\ingroup frameConstants
The standard torsion interaction
*/
#define FourierTorsion @"FourierTorsions"

/**
\ingroup frameConstants
The standard electrostatic interaction
*/
#define CoulombElectrostatic @"CoulombElectrostatic"

/**
\ingroup frameConstants
\todo Rename to LennardJones
Pure arithmetic vdw interaction (Enzymix, gromos)
*/
#define TypeOneVDWInteraction  @"TypeOneVDWInteraction"


/**
\ingroup frameConstants
\todo Rename to LennardJones
Pure arithmetic vdw interaction (Enzymix, gromos)
Geometric plus arithmetic vdw interactions (CHARMM, AMBER)
*/

#define TypeTwoVDWInteraction  @"TypeTwoVDWInteraction"

//nonbonded parameter types

//! \brief Parameters for TypeOneVDWInteraction

#define TypeOneVDWParameters  @"TypeOneVDWParameters"

//! \brief Parameters for TypeTwoVDWInteraction

#define TypeTwoVDWParameters  @"TypeTwoVDWParameters"

//! \brief Partial charges per atom

#define PartialCharges  @"PartialCharges"


/**
The error codes for #AdunKernel.ErrorDomain.
\todo Complete
\ingroup frameworkTypes
*/
typedef enum
{
	AdKernelUnknownError, /**< Cause of error unknown */
	AdKernelArrayAllocationError,	/**< Attempted to allocate an array that would exhaust virtual memory */
	AdKernelFloatingPointError,	/**< Detected an IEEE floating point exception */
	AdKernelSimulationSpaceError,	/**< Most likely due to an exploding simulation */
	AdKernelEnergyCalculationError, /**< Something went wrong calculating an energy or force */
}
AdKernelErrorCodes;

/**
Contains a string that can be used to divide section of
i.e. a log file.
*/
extern NSString* divider;

#endif
