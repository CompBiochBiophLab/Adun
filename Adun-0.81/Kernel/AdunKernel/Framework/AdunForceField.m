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
#include "AdunKernel/AdunForceField.h"

@implementation AdForceField

- (id) initWithSystem: (id) system
{
	return self;
}

- (void) evaluateForces
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) evaluateForcesDueToElements: (NSIndexSet*) elementIndexes
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (AdMatrix*) forces
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) clearForces
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (double) totalEnergy
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) evaluateEnergies
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) evaluateEnergiesUsingInteractionsInvolvingElements: (NSIndexSet*) elementIndexes
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (id) system
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) setSystem: (id) object
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (NSArray*) arrayOfEnergiesForTerms: (NSArray*) terms notFoundMarker: (id) anObject
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (NSDictionary*) dictionaryOfEnergiesForTerms: (NSArray*) array
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (id) availableTerms
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (NSArray*) activatedTerms
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (NSArray*) deactivatedTerms
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) addCustomTerm: (id) object withName: (NSString*) name
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) addCustomTerms: (NSDictionary*) aDict
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) removeCustomTermWithName: (NSString*) name
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) deactivateTerm: (NSString*) termName
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) deactivateTermsWithNames: (NSArray*) names
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) activateTerm: (NSString*) termName
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (void) activateTermsWithNames: (NSArray*) names
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

- (AdMatrix*) accelerations
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat:
		@"(%@) %@ is an abstract method. You need to use a concrete subclass of this class", 
		NSStringFromClass([self class]), NSStringFromSelector(_cmd)]];
}

@end


