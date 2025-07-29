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
#ifndef _ADFORCEFIELD_TERM_
#define _ADFORCEFIELD_TERM_
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMatrixStructureCoder.h"

/**
\ingroup Protocols
This protocol defines the interface for objects that represent custom interactions. 
Such objects operate on a system i.e. an AdSystem or AdInteractionSystem
object, calculating the energy and/or force due to the interaction which they represent.

Objects conforming to this protocol can accumulate their forces into
an external ::AdMatrix structure instead of using an internal one. This feature
increases calculation speed (more efficent memory usage, less additions) at the 
cost of not always being able to retrieve the interactions contribution to the total force.

Objects conforming to this protocol can be added to AdForceField objects thus
extending the force field. AdForceField assumes such objects observe AdSystemContentsDidChangeNotification
from their systems if necessary and can update themselves on receiving such a notification.

\note
Objects that conform to AdForceFieldTerm do not have to calculate both forces and energies.
Though obviously they must at least calculate one or the other to be useful.
*/

@protocol AdForceFieldTerm 
/**
Initialises the object to operate on \e system
*/
- (id) initWithSystem: (id) system;
/**
Evaluates the forces due to the interaction term.
Has no effect if the object can't calculate forces.
*/
- (void) evaluateForces;
/**
Evalutes the energy of the interaction
The result is obtained using energy().
Has no effect if the object can't calculate the energy.
*/
- (void) evaluateEnergy;
/**
Returns the last calculated value for the energy.
Should return 0 if no energy has been calculated or
if the object cannot calculate the energy.
*/
- (double) energy;
/**
Returns the objects force matrix. If usesExternalForceMatrix()
returns YES then this matrix is not owned by the reciever.
Otherwise it is and will be deallocated when the reciever is released
or if setExternalForceMatrix:() is used.
Returns NULL if the object cannot calculate forces.
*/
- (AdMatrix*) forces;
/**
The object should accumulate forces into \e matrix 
instead of using an internal matrix.
The cumulative force on each system element is added to the corresponding row
in the matrix.
If the matrix does not have the correct dimensions
i.e. one row for each atom in the system, an exception is raised.
Has no effect if the object cannot calculate the forces.
Does nothing if \e matrix is NULL.
\note Its is up to the sender to handle the event that \e matrix is
deallocated.
*/
- (void) setExternalForceMatrix: (AdMatrix*) matrix;
/**
Returns YES if the object writes its forces to an external
matrix. NO otherwise.
*/
- (BOOL) usesExternalForceMatrix;
/**
Sets the system the object should be calculated on.
*/
- (void) setSystem: (id) system;
/**
Returns the system the object operates on.
*/
- (id) system;
/**
Returns YES if the object can calculate energy.
*/
- (BOOL) canEvaluateEnergy;
/**
Return YES if the object can calculate forces.
*/
- (BOOL) canEvaluateForces;
@end
#endif
