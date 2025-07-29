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
#include "AdunKernel/AdunNonbondedTerm.h"

@class AdShiftedNonbondedTerm;
@class AdPureNonbondedTerm;
@class AdGRFNonbondedTerm;

@implementation AdNonbondedTerm

- (id) initWithSystem: (id) system
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
	return nil;
}

- (id) initWithSystem: (id) aSystem 
	cutoff: (double) aDouble
	updateInterval: (unsigned int) anInt
	nonbondedPairs: (NSArray*) nonbondedPairs
	externalForceMatrix: (AdMatrix*) matrix
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
	return nil;
}

- (void) clearForces;
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateForces;
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateLennardJonesForces
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateElectrostaticForces
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateLennardJonesEnergy
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateElectrostaticEnergy
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) evaluateEnergy;
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) handlerDidUpdateList: (id) handler
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (double) electrostaticEnergy
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (double) lennardJonesEnergy
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (double) energy
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (NSString*) lennardJonesType
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (double) permittivity
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) setPermittivity: (double) aDouble
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (double) cutoff
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) setCutoff: (double) aDouble
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (unsigned int) updateInterval
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) setUpdateInterval: (unsigned int) anInt
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) setExternalForceMatrix: (AdMatrix*) matrix
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (AdMatrix*) forces
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (BOOL) usesExternalForceMatrix
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) setSystem: (id) anObject
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (id) system
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (BOOL) canEvaluateEnergy
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (BOOL) canEvaluateForces
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (void) setNonbondedPairs: (NSArray*) nonbondedPairs
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

- (NSArray*) nonbondedPairs
{
	NSLog(@"Method (%@) not implemented", NSStringFromSelector(_cmd));
}

@end
