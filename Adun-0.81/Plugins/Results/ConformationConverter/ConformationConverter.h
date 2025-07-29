/*
   Project: ConformationConverter

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-04 16:43:29 +0100 by michael johnston

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

#ifndef _CONFORMATIONCONVERTER_H_
#define _CONFORMATIONCONVERTER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunSimulationData.h>
#include <AdunKernel/AdunDataMatrix.h>
#include <AdunKernel/AdunKernel.h>
#include <ULFramework/ULAnalysisPlugin.h>
#include <ULFramework/ULMenuExtensions.h>
#include <ULFramework/ULFrameworkFunctions.h>
#include <MolTalk/MolTalk.h>

@interface ConformationConverter : NSObject <ULAnalysisPlugin>
{
	NSMutableDictionary* currentOptions;
	id simulation;
}

@end

#endif // _CONFORMATIONCONVERTER_H_

