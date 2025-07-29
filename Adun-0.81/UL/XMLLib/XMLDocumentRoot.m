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

#include "XMLDocumentRoot.h"

@implementation XMLDocumentRoot

- (id) init
{
	[super init];
	level = 0;
	return self;
}

- (id) documentTreeForXMLFile: (NSString*) pathToFile
{
	NSXMLParser* xmlParser;
	NSURL* xmlURL;

	[self init];

	//create XML parser

	xmlURL = [NSURL fileURLWithPath: pathToFile];

	NSLog(@"NSURL contains %@\n", [xmlURL absoluteString]);

	xmlParser = [[NSXMLParser alloc] initWithContentsOfURL: xmlURL];
	[xmlParser setDelegate: self];

	//parse the XFlat file

	[xmlParser parse];

  	return self;
}

@end
