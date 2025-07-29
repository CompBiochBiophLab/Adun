/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-06 13:57:43 +0200 by michael johnston

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

#ifndef _XMLDOCUMENTTREE_H_
#define _XMLDOCUMENTTREE_H_

#include <Foundation/Foundation.h>
#include "XMLNode.h"

/**
\defgroup ffml FFML Library
This library consisits of two main classes: XMLDocumentTree, which creates a document tree,
and XMLNode, representing an abitrary node in an XML document. XMLNode adopts a very similar
interface to Cocoas NSXMLNode. As of this moment (06/05) the new NSXML Cocoa classes have
not been ported to GNUStep. 

The main differences are (as far as I can see) first that Cocoa models attributes as nodes i.e.
distinguising them from elements which is not done here (attributes are NSDictionaries
associated with each node). Secondly XMLNode adopts the delegate interface of NSXMLParser
allowing quick generation of the tree through dynamic delegation. In Cocoa it seems that the two are separate and
you have to write your own class to generate the tree from the NSXMLParser output.

The other classes are subclasses of XMLNode which provide extra functionality for nodes associated
with FFML.

\note This library will undergo a radical overhaul soon.

\ingroup sub
*/ 

/**
Contains a document tree of an XML file. Elements
of the tree can be referenced using the node name and
a key path.
\todo change name back to XMLDocumentTree
*/

@interface XMLDocumentRoot : XMLNode
{
}

/** 
Returns an XMLDocumentRoot containing the XML file
given by pathToFile
\param pathToFile The path to an xml file
\return An XMLDocumentRoot instance giving access to the XML file
\todo maybe this should just return the root object of the tree. Or perhaps make this the root document as well??
*/

- (id) documentTreeForXMLFile: (NSString*) pathToFile;

@end

#endif // _XMLDOCUMENTTREE_H_

