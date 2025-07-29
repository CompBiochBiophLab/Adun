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
#ifndef _ADSYSTEM_DATASOURCE_
#define _ADSYSTEM_DATASOURCE_
#include <Foundation/Foundation.h>
#include "AdunKernel/AdunDataMatrix.h"

/**
\ingroup Protocols
AdSystem objects obtain static data about the collection of elements they represent i.e. interactions,
aswell as the elements initial configuration from a data source object.
The AdSystemDataSource protocol defines methods that the system invokes as necessary to retrieve this information.

\todo Refactor - Define a clear and consistent vocabulary. Currently meaning of "group" and "interaction"
are ambiguous.
\todo Extra Documentation - Describing groups and parameters, index array etc.
*/

@protocol AdSystemDataSource
/**
Returns the name that will be used by the system
*/
- (NSString*) systemName;
/**
Returns the number of elements.
*/
- (unsigned int) numberOfElements;
/**
Returns the properties matrix. The property matrix
must include at least two columns, with the headers "Mass" and "ForceFieldName",
containing respectively the mass of each element and its associated force field type.
\todo Since Mass and ForceFieldName are required there should be specific methods from each
\todo Change ForceFieldName to ElementType
\todo Mass may not have to be present e.g. if velocities/temperature is not used.
*/
- (AdDataMatrix*) elementProperties;
/**
Returns an NSIndexSet containing the indexes of the elements whose value for property
\e aString (which is a header in the data source elementProperties matrix) is one of
the values in \e anArray.
*/
- (NSIndexSet*) indexesOfElementsWithValues: (NSArray*) anArray forProperty: (NSString*) aString;
/**
Returns the configuration of the elements.
*/
- (AdDataMatrix*) elementConfiguration;
/**
Returns the group properties
\todo Extra Documentation - Need to expand on what group properties are and their role.
*/
- (AdDataMatrix*) groupProperties;
/**
Returns an AdDataMatrix whose entries are \e interaction groups
containing the \e elementIndex.
If there is no group matrix and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised.
If no element with \e elementIndex exists an NSInvalidArgumentException is
raised.
*/
- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction
			containingElement: (int) elementIndex;
/**
Returns an array containing the names of the available interactions.
*/
- (NSArray*) availableInteractions;
/**
Returns the group matrix for the interaction \e interaction.
If there is no group matrix and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised.
*/
- (AdDataMatrix*) groupsForInteraction: (NSString*) interaction;
/**
Returns the constraint associated with \e interaction
*/
- (id) constraintForInteraction: (NSString*) interaction;
/**
Returns the parameters matrix for the interaction \e interaction.
If there are no parameters and the interaction exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised.
*/
- (AdDataMatrix*) parametersForInteraction: (NSString*) interaction;
/**
Returns the interactions in \e category. If category doesnt exist this
method returns nil
*/
- (NSArray*) interactionsForCategory: (NSString*) category;
/**
Returns the category of \e interactions. If a category was not specified for
\e interaction "None" is returned. If the interaction doesnt exist this method
returns nil
*/
- (NSString*) categoryForInteraction: (NSString*) interaction;
/**
Returns the index set array for \e category.
If there is no index set array and the category exists this method returns
nil. Otherwise an NSInvalidArgumentException is raised.
\todo Partial Implmentation - At the moment this will just return
the index set array associated with the nonbonded interactions in a
molecular mechanics force field.
*/
- (NSArray*) indexSetArrayForCategory: (NSString*) category;
@end

#endif
