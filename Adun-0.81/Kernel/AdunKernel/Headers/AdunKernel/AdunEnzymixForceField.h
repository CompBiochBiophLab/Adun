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
#ifndef ADENZYMIX_FORCE_FIELD
#define AdENZYMIX_FORCE_FIELD

#include "AdunKernel/AdunMolecularMechanicsForceField.h"

/** 
AdMolecularMechanicsForceField subclass representing the enzymix force field -

\f[ U(r)  = \sum_{Bonds} k_{i}(x - x_{i})^{2} + \sum_{Angles} k_{i}(\theta - \theta_{i})^{2}
+ \sum_{Torsions} k_{i}(1 + cos(n\theta - \phi)) + \sum_{Improper} k_{i}(\theta - \theta_{i})^{2}
+ \sum_{Nonbonded} \left [ \frac{1}{4 \pi \epsilon} \frac{q_{i}q_{j}}{r_{ij}} +
\frac{A_{i}A{j}}{r_{ij}^{12}} - \frac{B_{i}B{j}}{r_{ij}^{6}} \right ]

\f]

The following list details the names of the terms along with the associated information
that must be provided by the system object that the AdEnzymixForceField instance operates on.

- HarmonicBond - Groups and parameters (Separation & Constant)
- HarmonicAngle - Groups and parameters (Angle & Constant)
- FourierTorsion - Groups and parameters (Constant, Periodicity  & Phase)
- HarmonicImproperTorsion - Groups and parameters (Angle & Constant)
- Lennard Jones A - See AdNonbondedTerm for more.
- ColumbElectrostatic - See AdNonbondedTerm for more.

AdEnzymixForceField objects use an appropriate AdNonbondedTerm subclass instance to calculate the forces
and energies due to the nonbonded terms i.e. the combined Lennard-Jones and ColoumbElectrostatic interactions,
which must be supplied separately.

\ingroup Inter
**/


@interface AdEnzymixForceField: AdMolecularMechanicsForceField
{	

}
/**
\todo Not implemented
*/
- (void) evaluateForcesDueToElements: (NSIndexSet*) elementIndexes;
@end

#endif

