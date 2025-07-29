/*
   Project: SystemAnalysis

   Copyright (C) 2007 Free Software Foundation

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

#ifndef _SYSTEMANALYSIS_H_
#define _SYSTEMANALYSIS_H_

#include <Foundation/Foundation.h>
#include <ULFramework/ULAnalysisPlugin.h>
#include <ULFramework/ULIOManager.h>
#include <ULFramework/ULMenuExtensions.h>
#include <ULFramework/ULFrameworkFunctions.h>
#include <AdunKernel/AdunKernel.h>
#include <Base/AdMatrix.h>

@interface SystemAnalysis : NSObject <ULAnalysisPlugin>
{
	AdMutableDataSource* dataSource;
	NSDictionary* infoDict;
	NSMutableDictionary* forceFields;
	NSDictionary* conversionFactors;
	AdSystem* system;
	AdForceField* forceField;
	NSMutableString* returnString;
	//AtomContributions
	int totalSteps;
	double energyThreshold;
	NSString* energyUnit;
	AdMutableDataMatrix* atomContributions;
	AdDataMatrix* elementProperties;
	AdDataMatrix* groupProperties;
	NSArray* allResidues;
	NSArray* selectedResidues;
}

@end

#endif // _SYSTEMANALYSIS_H_

