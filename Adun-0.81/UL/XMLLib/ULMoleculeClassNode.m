/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 15:13:34 +0200 by michael johnston

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

#include "ULMoleculeClassNode.h"

@implementation ULMoleculeClassNode

- (id) findMoleculeNodeWithName: (NSString*) moleculeName
{
	NSEnumerator* moleculeEnum;
	id molecule;

	moleculeEnum = [children objectEnumerator];

	while((molecule = [moleculeEnum nextObject]))
		if([[molecule moleculeName] isEqual: moleculeName])
			return molecule;

	return nil;	
}

- (id) findMoleculeWithExternalName:(NSString*) moleculeName fromSource: (NSString*) source;
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat: 
			@"Warning method %@ not implemented yet", NSStringFromSelector(_cmd)]];
	//Required to supress compiler warning about reaching end of non-void function.		
	return nil;		
}

- (id) className
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat: 
			@"Warning method %@ not implemented yet", NSStringFromSelector(_cmd)]];
	return nil;		
}

@end
