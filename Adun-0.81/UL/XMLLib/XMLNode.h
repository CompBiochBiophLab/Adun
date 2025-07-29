/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-06 13:57:55 +0200 by michael johnston

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

#ifndef _XMLNODE_H_
#define _XMLNODE_H_

#include <Foundation/Foundation.h>

/**
An instance of XMLNode represents a node in an XML file.
*/

@interface XMLNode : NSObject
{
	NSMutableArray* children;
	NSDictionary* attributes;
	id parent;
	NSString* name;
	NSString* status;
	NSString* fieldValue;
	int childCount;
	int index;
	int level;
}

/**
Delegate method for NSXMLParser. When NSXML parser encounters the start of an XML tag it sends this
message to whoever is its delegate at the time.
\param parser The NSXML parser instance that sent the message
\param elementName The name of the element whose start tag was encountered
\param namespaceURI the namespaceURI of this element (not implemented)
\param qualifiedName The full path name of the element (I think. Also not implemented)
\param attributeDict The attributes of the tag
*/
- (void) parser: (id) parser didStartElement: (NSString *) elementName namespaceURI: (NSString *) namespaceURI qualifiedName: (NSString *) qualifiedName attributes: (NSDictionary *) attributeDict;

 /**
Delegate method for NSXMLParser. When NSXML parser encounters the end of an XML tag it sends this
message to whoever is its delegate at the time.
\param parser The NSXML parser instance that sent the message
\param elementName The name of the element whose end tag was encountered
\param namespaceURI the namespaceURI of this element (not implemented)
\param qName The full path name of the element (I think. Also not implemented)
*/
-(void) parser: (id) parser didEndElement: (NSString *)elementName namespaceURI:(NSString * )namespaceURI qualifiedName: (NSString *) qName;

/**
Delegate method for NSXMLParser. When NSXML parser encounters any CDATA it sends this 
message to whoever is its delegate at the time.
\param parser The NSXML parser instance that sent the message
\param string A string containing the characters that were found.
*/

-(void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string;

/**
Returns an XMLNode object with the specified tag name, attributes, and children. Specify nil in the children and attributes parameters if there are no attributes 
or children to add to this node object.
\param elementName The name of the XML element
\param chidren An NSMutableArray of child nodes (each of whoms parents must be this node)
\param attributes An NSDictionary containing node attributes
\return An initialised XMLNode instance
*/

+ (id) elementWithName: (NSString*) elementName children: (NSMutableArray*) children attributes: (NSDictionary*) attributes;

/**
Returns the index of this node which identifies its poistion relative to its siblings. The first child has an index of 0
*/
- (int) index;

/**
Returns the nesting level of the receiver within the tree hierarchy. The root element of a document has a nesting level of one.
*/
- (int) level;

/**
Returns the XML element name of the receiver i.e. the element type
*/
-(NSString*) name;

/**
Returns the recievers fieldValue or nil if it has none
*/
- (NSString*) fieldValue;

/**
Returns the child node of the receiver at the specified index. If the receiver has no children, this method returns nil.
 If index is out of bounds, an exception is raised.
*/
 - (id) childAtIndex: (int) childNo;

/**
Returns the number of child nodes the receiver has. 
For performance reasons, use this method instead of getting the count from the array returned by children
 (for example, [[thisNode children] count]).
\note cache the number of childre
*/
- (int) childCount;

/**
Returns an immutable array containing the child nodes of the receiver.
*/
- (NSArray*) children;

/**
Returns the next XMLNode object in document order. You use this method to walk forward through the tree structure representing an XML document or
document section. (Use previousNode to traverse the tree in the opposite direction.) 
Document order is the natural order that XML constructs appear in markup text.
If you send this message to the last node in the tree, nil is returned. XMLNode bypasses namespace and attribute nodes when 
it traverses a tree in document order.
*/
- (id) nextNode;

/**
Returns the next XMLNode object that is a sibling node to the receiver. This object will have an index value that is one more than the receiver’s.
If there are no more subsequent siblings (that is, other child nodes of the receiver’s parent) the method returns nil.
*/
- (id) nextSibling;

/**
Returns the parent node of the receiver. Document nodes and standalone nodes (that is, the root of a detached branch of a tree) have no parent,
and sending this message to them returns nil. A one-to-one relationship does not always exists between a parent and its children; 
although a namespace or attribute node cannot be a child, it still has a parent element.
*/
- (id) parent;

/**
Returns the previous XMLNode object in document order. You use this method to walk backward through the tree structure representing an 
XML document or document section. (Use nextNode to traverse the tree in the opposite direction.) Document order is the natural order that XML
constructs appear in markup text. If you send this message to the first node in the tree (that is, the root element), 
nil is returned. 
** Not Implemented **
*/
- (id) previousNode;

/**
Returns the previous NSXMLNode object that is a sibling node to the receiver. This object will have an index value that is one less 
than the receivers. If there are no more previous siblings (that is, other child nodes of the receiver’s parent) the method returns nil
** Not Implemented **
*/
- (id) previousSibling;

/**
Detaches the receiver from its parent node. Once the node object is detached, you can add it as a child node of another parent.
** Not Implemented **
*/
- (void) detach;

/**
Returns the recievers attributes
*/
- (NSDictionary*) attributes;

/**
Returns a new initialised node for elementName. XMLNode instances use this method to create their children. In this case
it returns a new XMLNode instance. Subclasses of XMLNode can override this method so when they create their children something other
than an XMLNode instance will be returned. This method avoids having to directly name a class when creating a new child.
*/

- (id) nodeForElementName: (NSString*) elementName children: (NSArray*) childArray attributes: (NSDictionary*) attributeDict;

@end

#endif // _XMLNODE_H_

