/*
   Project: UL

  Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-07-14 13:34:47 +0200 by michael johnston

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

#ifndef _ULINTERACTIONSBUILDER_H_
#define _ULINTERACTIONSBUILDER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <AdunKernel/AdunDataSet.h>
#include "ULFramework/ULDatabaseInterface.h"
#include "XMLLib/XMLLib.h"


/**
\ingroup classes
Class to generate the interaction lists from a system.
*/

@interface ULInteractionsBuilder : NSObject
{
	id parameterLibrary;	//!< An adun paramater library mapped into memory as an XML document tree	
	NSMutableString* buildString;
	NSMutableString* errorString;
	FILE* buildOutput;
	//Temporary conversion related ivars
	NSArray *unitsToConvert;
	NSDictionary* constantForUnit;
	NSString* forceField;
	id forceFieldInfo;
}

- (id) initForForceField: (NSString*) aString;
- (id) buildInteractionsForConfiguration: (id) configuration
	error: (NSError**) buildError
	userInfo: (NSString**) userInfo;

@end

#endif // _ULINTERACTIONSBUILDER_H_

