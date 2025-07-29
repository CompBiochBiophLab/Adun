/*
   Project: EnergyConverter

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-04 16:42:49 +0100 by michael johnston

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

#ifndef _ENERGYCONVERTER_H_
#define _ENERGYCONVERTER_H_

#include <Foundation/Foundation.h>
#include <AdunKernel/AdunKernel.h>
#include <AdunKernel/AdunSimulationData.h>
#include <ULFramework/ULAnalysisPlugin.h>
#include <ULFramework/ULMenuExtensions.h>

@interface EnergyConverter : NSObject <ULAnalysisPlugin>
{
	NSDictionary* infoDict;
	NSDictionary* conversionFactors;
	NSMutableString* resultsString;
	NSMutableDictionary* pluginOptions;
}

@end

#endif // _ENERGYCONVERTER_H_

