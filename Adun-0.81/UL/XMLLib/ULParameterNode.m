/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-07 12:51:17 +0200 by michael johnston

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

#include "ULParameterNode.h"
#include "ULTopologyNode.h"
#include "ULClassNode.h"
#include "ULInteractionNode.h"

@implementation ULParameterNode

- (id) nodeForElementName: (NSString*) elementName children: (NSArray*) childArray attributes: (NSDictionary*) attributeDict
{	

	if([elementName isEqual: @"topology"])
	{
		return [ULTopologyNode elementWithName: elementName children: nil attributes: attributeDict];
	}
	else if([elementName isEqual: @"class"])
	{
		return [ULClassNode elementWithName: elementName children: nil attributes: attributeDict];
	}
	else if([elementName isEqual: @"interaction"])
	{
		return [ULInteractionNode elementWithName: elementName children: nil attributes: attributeDict];
	}
	else 
	{
		return [ULParameterNode elementWithName: elementName children: nil attributes: attributeDict];
	}
}

@end
