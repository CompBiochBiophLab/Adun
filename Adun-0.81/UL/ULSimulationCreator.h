/* 
   Project: UL

   Copyright (C) 2007 Michael Johnston & Jordi Villa-Freixa

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

#ifndef _ULSIMULATIONCREATOR_
#define _ULSIMULATIONCREATOR_

#include <AppKit/AppKit.h>
#include "ULPasteboard.h"
#include "ULFramework/ULProcessManager.h"
#include "ULFramework/ULTemplate.h"
#include "ULTemplateViewController.h"
#include <AdunKernel/AdunDataSource.h>

/**
\ingroup interface
Description forthcoming
*/
@interface ULSimulationCreator: NSObject
{
	id host;
	ULPasteboard* pasteboard;
	ULProcessManager* processManager;
	ULTemplate* simulationTemplate;
	NSMutableDictionary* inputData;
	NSDictionary* inputTypeDisplayNames;
	NSArray* inputDataTypes;
	//Interface elements
	id sectionList;
	id selectHostButton;
	id tabView;
	id templateField;
	id simulationNameField;
	id window;
	id externalDataTable;
	id energyField;
	id configurationField;
	id energyDumpField;
}
/**
Description forthcoming
*/
- (void) closeWindow: (id) sender;
/**
Description forthcoming
*/
- (void) createProcess: (id) sender;
/**
Description forthcoming
*/
- (void) createSimulation: (id) sender;
/**
Description forthcoming
*/
- (void) load: (id) sender;
//- (void) sectionDidChange: (id) sender;
/**
Description forthcoming
*/
- (void) displayTemplate: (id) sender;
@end

#endif
