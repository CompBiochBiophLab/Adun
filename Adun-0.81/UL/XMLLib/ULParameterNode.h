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

#ifndef _ULPARAMETERNODE_H_
#define _ULPARAMETERNODE_H_

#include <Foundation/Foundation.h>
#include "XMLNode.h"

/**
ULParameter node provides a new implementation of _nodeForElementName:children:attributes.
Instead of just returning an new XMLNode instance this method looks at the elementName and
returns one of the UL<name>node instances i.e. itself or a more specialised subclass. 
*/

@interface ULParameterNode : XMLNode
{

}

@end

#endif // _ULPARAMETERNODE_H_

