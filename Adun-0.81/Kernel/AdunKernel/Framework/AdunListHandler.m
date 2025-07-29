/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

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
#include "AdunKernel/AdunListHandler.h"

@implementation AdListHandler

- (id) initWithSystem: (id) aSystem allowedPairs: (NSArray*) anArray cutoff: (double) aDouble
{
	return self;
}

- (void) createList
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (void) update
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (void) setCutoff: (double) aValue
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (double) cutoff
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
	return 0;	
}

- (void) setAllowedPairs: (NSArray*) anArray
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (NSArray*) allowedPairs
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
	return nil;	
}

- (NSValue*) pairList
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
	return nil;	
}

- (int) numberOfListElements
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
	return -1;	
}

- (void) setDelegate: (id) delegate
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (id) delegate
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
	return nil;	
}

- (void) setSystem: (id) aSystem
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (id) system
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
	return nil;	
}

@end

