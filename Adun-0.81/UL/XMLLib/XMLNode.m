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

#include "XMLNode.h"

@implementation XMLNode

- (id) nodeForElementName: (NSString*) elementName children: (NSArray*) childArray attributes: (NSDictionary*) attributeDict
{	
	return [XMLNode elementWithName: elementName children: nil attributes: attributeDict];
}

+ (id) elementWithName: (NSString*) elementName children: (NSMutableArray*) child attributes: (NSDictionary*) attr
{
	id temp;

	temp = [self new];

	[temp takeValue: elementName forKey: @"Name"];
	[temp takeValue: attr forKey: @"Attributes"];

	return temp;	
}

- (id) init
{
	childCount = 0;
	children = [[NSMutableArray arrayWithCapacity:1] retain];
	return self;
}

- (NSString*) XMLStringWithOptions: (unsigned int) options
{
	NSLog(@"Warning method %@ not implemented yet", NSStringFromSelector(_cmd));
	return @"";
}

- (void) parser: (id) parser 
	didStartElement: (NSString *) elementName 
	namespaceURI: (NSString *) namespaceURI 
	qualifiedName: (NSString *) qualifiedName 
	attributes: (NSDictionary *) attributeDict
{	
	id Child;
	
	status = @"Open";

	//create child element
	
	Child = [self nodeForElementName: elementName children: nil attributes: attributeDict];
	[Child takeValue: self forKey: @"Parent"];
	[children addObject: Child];
	childCount++;
	[Child takeValue: [NSNumber numberWithInt: childCount - 1] 
		forKey: @"Index"];
	[Child takeValue: [NSNumber numberWithInt: level + 1] 
		forKey: @"Level"];
	[parser setDelegate: Child];
}

-(void) parser: (id) parser didEndElement: (NSString *)elementName namespaceURI:(NSString * )namespaceURI qualifiedName: (NSString *) qName
{
	status = @"Closed";
	[parser setDelegate: parent];
}

-(void) parser: (NSXMLParser *) parser foundCharacters: (NSString *) string
{
	string = [string stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(![string isEqual: @""])
		fieldValue = [string retain];
}

-(int) index
{
	return index;
}

-(int) level
{
	return level;
}

-(NSArray*) children
{
	return children;
}

- (id) childAtIndex: (int) childNo
{
	if(children == nil)
		return nil;
	else
		return [children objectAtIndex: childNo];
}

- (int) childCount
{
	return childCount;
}

- (id) nextNode
{
	//if we have any children return the first
	//else return a sibling
	//else return our parents sibling etc until we get something	
	//or nothing
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat: 
			@"Warning method %@ not implemented yet", NSStringFromSelector(_cmd)]];
	return nil;		
}

- (void) detach
{
	[NSException raise: NSInternalInconsistencyException
		format: [NSString stringWithFormat: 
			@"Warning method %@ not implemented yet", NSStringFromSelector(_cmd)]];
}

- (id) previousNode
{
	[NSException raise: NSInternalInconsistencyException 
		format: [NSString stringWithFormat: 
			@"Warning method %@ not implemented yet", NSStringFromSelector(_cmd)]];
	return nil;		
}

- (id) nextSibling
{
	if(index == ([parent childCount] - 1))
		return nil;

	return [[parent children] objectAtIndex: index + 1];
}

- (id) previousSibling
{
	if(index == 0)
		return nil;

	return [[parent children] objectAtIndex: index - 1];
}

- (id) parent
{
	return parent;
}

- (NSString*) name
{
	return name;
}

- (NSDictionary*) attributes
{
	return attributes;
}

- (NSString*) fieldValue
{
	return fieldValue;
}

/**
Children should not retain their parents (Thats a very philosophical statement ..)
*/

- (void) setParent: (id) par
{
	parent = par;
	[parent retain];
}

- (void) setAttributes: (NSDictionary*) attrib
{
	attributes = attrib;
	[attributes retain];
}	

- (void) setName: (NSString*) nodeName
{
	name = nodeName;
	[name retain];
}

- (void) setIndex: (int) childIndex
{
	index = childIndex;
}

- (void) setLevel: (int) nestingLevel
{
	level = nestingLevel;
}


@end
