/*
 Project: Adun
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Author: Michael Johnston
 
 Created: 2008-07-23 by michael johnston
 
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
#ifndef _ADELEMENTSELECTION_
#define _ADELEMENTSELECTION_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunDefinitions.h>
#include <AdunKernel/AdunDataSource.h>

/**
\ingroup Inter
An object that represents a generalisation of a chimera atom-type selection string.
In Aduns case these strings can be used to specify elements in a AdDataSource instance.

Usage is simple 

- First set the selection string using setSelectionString()
- Subsequent calls to matchingElementsInDataSource:(), passing a valid data source,
will return the indexes of all the elements in the data source that match the specifier.

\section syntax String Syntax

What follows is a preliminary explanation.

Selections strings have the form

:GroupProperty.Subproperty @ ElementPropery.Subproperty2

for example this can be

:ResidueName.ChainID @ PDBName

That is the ':' symbol denotes the first category and the '@' the second category.

A selection string is made up of one or more selection specifiers for one or more of the categories.
When processing a selection first all the entries that match the first category specifier are chosen,
the the first subcategory etc.

For example if the categories are as specified above then

:12-13.A @ CA,N

Selects residues 12-13 in chain A, then selects the CA and N in those residues.

:[ (specifier1),(specifier2) ..].[((specifier1),(specifier1),...]@[(specifier1),(specifier2)],...

*/
@interface AdElementSelection : NSObject 
{
	NSString* groupCategory; //!< The column of the group properties matrix that string specifiers will be matched against
	NSString* elementCategory; //!< The column of the element properties matrix that string specifiers will be matched against
	NSString* selectionString;	
	NSMutableDictionary *specifierDict; //!< Contains information parsed from the current selection string
}
/**
Returns a selection object which parses and applies chimera type specifier strings
*/
+ (id) biomolecularSelectionWithString: (NSString*) aString;
/**
Designated initialiser.
Description forthcoming.
*/
- (id) initWithSelectionCategories: (NSDictionary*) categories selectionString: (NSString*) aString;
/**
Returns an index set containing the indexes of all the rows of \e aDataSource's
AdDataSource::elementProperties() matrix, and hence all the elements in the data source,
that match the selection string.
*/
- (NSIndexSet*) matchingElementsInDataSource: (AdDataSource*) aDataSource;
/**
 Returns an index set containing the indexes of all the rows of \e aDataSource's
 AdDataSource::groupProperties() matrix, and hence all the groups in the data source,
 that match the 'group' part of the selection string.
 */
- (NSIndexSet*) matchingGroupsInDataSource: (AdDataSource*) aDataSource;
/**
Sets the selection string to \e aString.
*/
- (void) setSelectionString: (NSString*) aString;
/**
Returns the current selection string.
*/
- (NSString*) selectionString;
@end

@interface NSString (AdElementSelectionExtensions)
/**
Returns an NSRange whose location is the index of the first character in characterSet 
in the receiver and whose location is the number of subsequent characters also in \e characterSet
*/
- (NSRange) rangeOfCharactersFromSet: (NSCharacterSet*) characterSet;
@end


#endif
