/*
   Project: XMLLib

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-07 13:00:20 +0200 by michael johnston

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

#include "ULParameterTree.h"

@implementation ULParameterTree

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

- (NSMutableDictionary*) topologiesForClass: (NSString*) className
{
	NSMutableDictionary* classTopologies;
	id topologies, topology;
	NSEnumerator* topologyEnum, *classEnum;
	id class, holder;	
	BOOL foundClass;

	if(className == nil)
		className = @"generic";

	//get all topologies

	classTopologies = [NSMutableDictionary dictionaryWithCapacity:1];
	topologies = [[children objectAtIndex:0] children];
	topologyEnum = [topologies objectEnumerator];

	//go through each topology and find classes with name className

	foundClass = NO;

	while((topology = [topologyEnum nextObject]))
	{
		//loop over the classes

		classEnum  = [[topology children] objectEnumerator];
		while((class = [classEnum nextObject]))
		{
			if([[[class attributes] valueForKey:@"name"] isEqual: className])
			{
				//this condition should never be true. If the XML document
				//contained such an occurance it would be caught be a DTD
				//filter. However at the moment there is no DTD filter so
				//we check here.

				if(foundClass)
					[NSException raise: NSInternalInconsistencyException
						format: [NSString stringWithFormat: 
			@"Duplicate class type. The interaction class %@ is declared twice in the same interaction section - DTD violation"]];

				[classTopologies setObject: class forKey: [[topology attributes] valueForKey:@"name"]];
				foundClass = YES;
			}
			else if([[[class attributes] valueForKey:@"name"] isEqual: @"generic"])
			{
				//hold the generic class a use it if className is not found

				holder = class;
			}

		}

		//if no class was found do something!

		if(!foundClass)
		{
			NSLog(@"No class of type %@ found for topology %@.", className, 
				[[topology attributes] valueForKey:@"name"]);

			if(holder != nil)
			{	
				NSLog(@"Substituting generic class");
				[classTopologies setObject: holder forKey: [[topology attributes] valueForKey:@"name"]];
			}
			else
			{
				NSLog(@"No generic class found to use a substitute. Exiting");
				exit(1);
			}
		}

		foundClass = NO;
		holder = nil;
	}	

	return classTopologies;
}

@end
