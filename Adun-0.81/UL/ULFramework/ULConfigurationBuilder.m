/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-05-24 12:05:53 +0200 by michael johnston

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

#include "ULFramework/ULConfigurationBuilder.h"
#include "ULFramework/PDBConfigurationBuilder.h"

@implementation ULConfigurationBuilder

+ (id)  builderForMoleculeAtPath: (NSString*) moleculePath 
{
	NSString* pathExtension;

	pathExtension = [[moleculePath pathExtension] lowercaseString];

	if([[moleculePath pathExtension] isEqual: @"pdb"])
		return [[[PDBConfigurationBuilder alloc] 
				initWithMoleculeAtPath: moleculePath]
				autorelease];

	return nil;
}

+ (id)  builderForFileType: (NSString*) fileType 
{
	if([[fileType lowercaseString] isEqual: @"pdb"])
		return [[[PDBConfigurationBuilder alloc]
			init] autorelease];

	return nil;
}

- (id) buildConfiguration: (NSDictionary*) options
	error: (NSError**) buildError
	userInfo: (NSString**) buildInfo
{
	NSWarnLog(@"This is an abstract method (%@)", NSStringFromSelector(_cmd));
	return nil;
}

- (id) init
{
	return [self initWithMoleculeAtPath: nil];
}

- (id) initWithMoleculeAtPath: (NSString*) path
{
	[self release];
	if([[path pathExtension] isEqual: @"pdb"])
		return [[PDBConfigurationBuilder alloc] 
				initWithMoleculeAtPath: path];

	//Default
	return [[PDBConfigurationBuilder alloc] 
			initWithMoleculeAtPath: nil];
}

@end
