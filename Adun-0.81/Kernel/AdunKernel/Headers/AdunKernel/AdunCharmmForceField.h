/*
   Project: Adun

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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
#ifndef ADCHARMM_FORCE_FIELD
#define ADCHARMM_FORCE_FIELD

#include "AdunKernel/AdunMolecularMechanicsForceField.h"
/** 
AdMolecularMechanicsForceField subclass representing the Charmm force field -

\f[ U(r)  = \sum_{Bonds} \frac{k_{i}}{2}(x - x_{i})^{2} + \sum_{Angles} \frac{k_{i}}{2}(\theta - \theta_{i})^{2}
+ \sum_{Torsions} k_{i}(1 + cos(n\theta - \phi)) + \sum_{Improper} \frac{k_{i}}{2}(\theta - \theta_{i})^{2}
+ \sum_{Nonbonded} \left [
\frac{1}{4 \pi \epsilon} \frac{q_{i}q_{j}}{r_{ij}} +
\sqrt{\epsilon_{i}\epsilon_{j}} \left \{ \left( \frac{0.5(r_{i}^{*} + r_{j}^{*})}{r_{ij}} \right)^{12}
-  2 \left( \frac{0.5(r_{i}^{*} + r_{j}^{*})}{r_{ij}} \right)^{6} \right \}
\right ]

\f]

The following list details the names of the terms along with the associated information
that must be provided by the system object that the AdCharmmForceField instance operates on.

- HarmonicBond - Groups and parameters (Separation & Constant)
- HarmonicAngle - Groups and parameters (Angle & Constant)
- FourierTorsion - Groups and parameters (Constant, Periodicity  & Phase)
- HarmonicImproperTorsion - Groups and parameters (Angle & Constant)
- Lennard Jones A - See AdNonbondedTerm for more.
- ColumbElectrostatic - See AdNonbondedTerm for more.

AdCharmmForceField objects use an appropriate AdNonbondedTerm subclass instance to calculate the forces
and energies due to the nonbonded terms i.e. the combined Lennard-Jones and ColoumbElectrostatic interactions,
which must be supplied separately.

\ingroup Inter
**/

@interface AdCharmmForceField: AdMolecularMechanicsForceField
{
	BOOL interaction14;
	BOOL ureyBradley;
	int noList_14;
	double i14vdw_pot;
	double i14est_pot;
	double ub_pot;
	double epsilon_rp;
	double relativePermittivity;
	AdMatrix *ub;
	ListElement *list_14, *list_p;
}
/**
\todo Not implemented
*/
- (void) evaluateEnergiesUsingInteractionsInvolvingElements: (NSIndexSet*) elementIndexes;
/**
\todo Not implemented
*/
- (void) evaluateForcesDueToElements: (NSIndexSet*) elementIndexes;
@end

#endif

