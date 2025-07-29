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
#ifndef _ADDATASOURCE_
#define _ADDATASOURCE_

#include <math.h>	
#include <Foundation/Foundation.h>
#include "AdunKernel/AdDataSources.h"
#include "AdunKernel/AdIndexSetConversions.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunDataSet.h"
#include "AdunKernel/AdunDataMatrix.h"

/**
\ingroup Inter
AdDataSource (and its mutable subclass AdMutableDataSource) 
objects supply information on the configuration, 
interactions and properties of a set of elements to an AdSystem instance.
The interactions and properties are usually based on a force field.

Use AdDataSource when modification of the contained data must be prevented.

AdDataSource conforms to 
<A HREF="http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Protocols/NSCoding_Protocol/">
NSCoding
</A>
and supports both keyed and nonkeyed coding.
It also conforms to the 
<A HREF="http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Protocols/NSCopying_Protocol/">
NSCopying
</A>
and the
<A HREF="http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Protocols/NSMutableCopying_Protocol/">
NSMutableCopying
</A>
protocols.

\note The AdDataMatrix objects returned by AdDataSource instances are copies of
internal AdMutableDataMatrix objects.
Hence it is inadvisable to repeatedly call the methods that return AdDataMatrix objects
in tight loops.

\todo Extra Documentation - Expand element groups documentation. Affects AdSystemDataSource.
\todo Extra Methods - Group related methods. Affects AdSystemDataSource.
\todo Affected by Task - Units. 
Data sources should provide information on the units for distance, weight and time etc.
\todo Missing Functionality - Check model object metadata copying - specifically how it should interact if
AdModelObject supported NSCopying
\todo Missing Functionality - Add ability to specify index set arrays instead of interaction matrices on initialisation.
*/

@interface AdDataSource: AdModelObject <AdSystemDataSource>
{
	@protected	
	id memoryManager;
	AdMutableDataMatrix* elementProperties;
	AdMutableDataMatrix* elementConfiguration;
	AdMutableDataMatrix* groupProperties;
	NSMutableArray* interactions;
	NSMutableDictionary* interactionGroups;
	NSMutableDictionary* interactionParameters;
	NSMutableDictionary* categories;
	NSMutableArray* nonbondedPairs;
}
/**
As initWithElementProperties:configuration:interactions:groupProperties() passsing nil for \e interactions
and \e gProperties
*/
- (id) initWithElementProperties: (AdDataMatrix*) properties configuration: (AdDataMatrix*) configuration;

/**
Designated intialiser.
\param properties A matrix containing the properties of the elements e.g. names, charges etc.
\param configuration The configuration of the elements. 
\e properties and \e configuration must have the same number of rows. Row indexes are assumed to correspond
to element indexes e.g. The information in the first row of \e properties and \e configuration
must refer to the same element.
\param interactions A dictionary of dictionaries. The keys are
interaction names. The dictionary associated with each interaction name can
contain the following keys, Groups, Parameters, Category, Constraint. See
addInteraction:withGroups:parameters:constraint:toCategory() for more information.
If interactions is nil no interactions will be associated with the AdDataSource object.
\param gProperties Group properties associated with the data source.
*/
- (id) initWithElementProperties: (AdDataMatrix*) properties 
	configuration: (AdDataMatrix*) configuration
	interactions: (NSDictionary*) interactions
	groupProperties: (AdDataMatrix*) gProperties;
/**
Creates a new AdDataSource object initialised with the contents of
\e aDataSource.
*/
- (id) initWithDataSource: (AdDataSource*) aDataSource;
/**
List of pairs of atoms who dont appear together in any of the groups
already added.
\todo Not implemented.
\todo Add to AdSystemDataSource protocol when implemented here.
*/
- (NSIndexSet*) elementPairsNotInInteractionsOfCategory: (NSString*) aString;

@end

/*
Category for AdDataSource containing the implementations of the 
NSCoding*/

@interface AdDataSource (AdDataSourceCodingExtensions) <NSCoding>
@end

/**
\ingroup Inter
The AdMutableDataSource class declares the interface for data sources
whose contents and interactions can be modified. 

See AdDataSource class documentation for more information.
\todo Add index set related methods.
\todo Missing functionality - Its impossible to remove atoms by setting
new configuraiton and element properties matrices due to the constraint that
both must be the same size i.e. if you set a new coordinates matrix first
this will raise an exception because it doesnt match the size of the current
element properties matrix and vice versa
*/

@interface AdMutableDataSource: AdDataSource
{
}
/**
Adds an interaction called \e name to the list of interactions that can occur between the 
elements of the data source.
\e name is a string identifying a particular type of interaction e.g. HarmonicBond.
\e groups is a matrix of element indexes. 
The number of columns is equal to the number of elements required for the interaction to occur.
Each row is then a set of elements who interact in the named way.

\e parameters is a matrix of interaction parameters. If \e groups is nil then \e parameters must also be nil.
The headers of each column are the parameter names e.g. bond strength, equilibrium distance etc.
Each row contains the parameters necessary
to determine the strength of the interaction between the elements given by the same row in \e groups.
The parameters are usually group specific e.g. not derivable from properties of the individual elements in
the group.

If \e parameters is nil it is assumed all neccessary parameters are derivable from the properties of the
elements.
\e interactionCategory is a string that represents the "category" of the interaction e.g bonded, nonbonded etc.
This allows different interactions that have similar characteristics to be grouped together.
*/
- (void) addInteraction: (NSString*) name 
	withGroups: (AdDataMatrix*)  group
	parameters: (AdDataMatrix*) parameters
	constraint: (id) object
	toCategory: (NSString*) interactionCategory;
/**
Adds \e group with \e parameters to the group and parameter
matrices of \e interaction. Does nothing if \e group is nil
or there is no group matrix associated with \e interaction.
\param group An array of element indexes. The number of indexes must be the
same as the number of columns in \e interactions group matrix. 
\param parameters An NSDictionary containing the parameters corresponding to \e group.
The keys are the column headers for the parameter matrix of \e interaction. If all keys
are not present an NSInvalidArgumentException is raised. 
\param interaction The interaction that \e group and \e parameters are to be added to.
*/
- (void) addGroup: (NSArray*) group 
		withParameters: (NSDictionary*) parameters
		toInteraction: (NSString*) interaction;
/**
Adds an element with the given \e position and \e properties to
the data source. \e properites is a NSDictionary whose keys
are the column headers of the elementProperties() matrix. All keys
are required. The new entries are added to the end of the corresponding matrices.
\todo Not Implemented
*/
- (void) addElementWithPosition: (NSArray*) position
		properties: (NSDictionary*) aDict;
/**
Removes \e interaction from the data source. This includes group matrices,
parameters and constraints. 
Does nothing if no interaction called \e interaction exists.
*/
- (void) removeInteraction: (NSString*) interaction;	
/**
Removes row \e index from the group matrix of \e interaction. The correponding parameter entry
(if any) is also removed. Has no effect if \e group or \e interaction is nil.
Raises an NSInvalidArgumentException if no interaction called \e interaction exists.
*/
- (void) removeGroupAtIndex: (unsigned int) index ofInteraction: (NSString*) interaction;
/**
Removes all the entries in the group matrix of \e interaction that contain \e elementIndex.
If no element with \e elementIndex exists this method does nothing.
Raises an NSInvalidArgumentException if no interaction called \e interaction exists.
Does nothing if there is no group matrix associated with \e interaction.
\return Returns the number of interactions removed.
*/
- (int) removeAllGroupsOfInteraction: (NSString*) interaction 
		containingElementIndex: (unsigned int) elementIndex; 
/**
Removes the element identified by \e elementIndex from the data source. 
If \e elementIndex is outside the range of elements in the recevier an
NSRangeException is raised.
All interaction groups and corresponding parameters involving this atom are removed
via removeAllGroupsOfInteraction:containingElementIndex:()
Removing an element requires that the interaction groups, which are index
based, be updated. This is because the indexes of all elements
after \e elementIndex in the configuration matrix are reduced by
one after the removal.
For example there is a group (11, 12) indicating an interaction between elements
11 & 12. If element 10 is removed this group must be changed to (10,11).
\todo Remember to update group properties
*/
- (void) removeElement: (unsigned int) elementIndex;

/**
Removes the elements identified by the indexes in \e indexSet. Raises
an NSRangeException if any of the indexes it outside the range of elements
in the recevier - in this case no element are remove.
See removeElement:() for more.
*/
- (void) removeElements: (NSIndexSet*) indexSet;
/**
Changes the configuration of the elements to the 
coordinates in \e aMatrix. \e aMatrix must have one
entry for each atom.
*/
- (void) setElementConfiguration: (AdDataMatrix*) aMatrix;
/**
Changes the properties of the elements to those
defined by \e aMatrix. \e aMatrix must have one
entry for each atom.
*/
- (void) setElementProperties: (AdDataMatrix*) dataMatrix;
/**
Changes the value in row \e elementIndex of the column with header \e property
in the element property matrix to \e value. Raises an NSInvalidArgumentException
if no column called \e property exists or if \e elementIndex is greater than or
equal to numberOfElements().
*/
- (void) setProperty: (NSString*) property 
		ofElement: (unsigned int) elementIndex
		toValue: (id) value;
/**
Replaces the parameters at row \e index of the parameter matrix 
of \e interaction with the values in \e aDictionary. 
Has no effect is there are no parameters associated with \e interaction.

\param index The index of the row in the parameter matrix to be modified.
\param interaction The interaction  whose parameters are to be modified.
\param parameters An NSDictionary whose keys are column headers of the parameter matrix of \e interaction. 
The matrix is modified using AdMutableDataMatrix::setElementAtRow:ofColumnWithHeader:withValue:
where row is given by \e index, the column header by each key, and the value by the object associated with 
the key.
If any key is not a valid column header an NSInvalidArgumentException is raised. 
In this case no values are modified.
*/
- (void) setParametersAtIndex: (unsigned int) index
		ofInteraction: (NSString*) interaction	
		withValues: (NSDictionary*) aDictionary; 
/**
Temporary method name.
\todo Expand documentation
*/
- (void) setGroupProperties: (AdDataMatrix*) dataMatrix;
/**
Temporary method
*/
- (void) setNonbondedPairs: (NSMutableArray*) array;

@end

#endif

