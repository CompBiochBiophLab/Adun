/*
   Project: UL

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-06-09 13:40:49 +0200 by michael johnston

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

#ifndef _ULMERGER_H_
#define _ULMERGER_H_

#include <Foundation/Foundation.h>
#include "ULMergerDelegate.h"

/**
\ingroup classes
\note Rewrite this class to intialise properly
*/


@interface ULMerger : NSObject
{
	id delegate;
	FILE* buildOutput;
	NSMutableString* buildString;
}

-(id) mergeTopologyFrame: (NSDictionary*) conf 
	withConfiguration: (NSDictionary*) frame
	error: (NSError**) buildError
	userInfo: (NSString**) buildInfo;

@end

#endif // _ULMERGER_H_

