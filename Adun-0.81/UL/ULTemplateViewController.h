/* 
   Project: UL

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2006-06-01 10:15:49 +0200 by michael johnston
   
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
#ifndef _ULTEMPLATEVIEWCONTROLLER_
#define _ULTEMPLATEVIEWCONTROLLER_

#include <AppKit/AppKit.h>
#include <AdunKernel/AdunModelObject.h>
#include <ULFramework/ULTemplate.h>
#include <ULFramework/ULMenuExtensions.h>
#include <ULFramework/ULDatabaseInterface.h>
#include "ULPasteboard.h"
#include "ULOutlineViewDelegate.h"
#include "ULPropertiesPanel.h"
#include "ULOutlineViewAdditions.h"

/**
\ingroup interface
Controls template building interface.
*/

@interface ULTemplateViewController : NSObject
{
	id interactionsTableDelegate;	//!< Delegate and data source for interaction table
	NSDictionary* sectionDescriptions;
	NSDictionary* viewToTemplateSectionMap; //!< Maps interface section names to ULTemplate section names
	NSMutableDictionary* displayNames;
	NSMutableDictionary* sections;
	ULOutlineViewDelegate* outlineDelegate;
	ULMutableTemplate* simulationTemplate;
	id propertyViewController;
	//Window Elements
	id templateWindow;
	id componentTable;
	id componentDescriptionField;
	id sectionDescriptionField;
	id popUpList;
	id tabView;
	id currentTemplateView;		//!< The view currently being used to display the template
	id templateView;
	id templateDisplayView; 	//!< Used when displaying a saved template
}
/**
Description forthcoming
*/
+ (id) templateViewController;
/**
Description forthcoming
*/
- (void) open: (id) sender;
/**
Description forthcoming
*/
- (void) display: (id) sender;
/**
Description forthcoming
*/
- (void) displayTemplate: (id) aTemplate;
/**
Description forthcoming
*/
- (void) save: (id)sender;
/**
Description forthcoming
*/
- (void) validate: (id) sender;
/**
Description forthcoming
*/
- (void) addComponent: (id) sender;
/**
Description forthcoming
*/
- (void) removeComponent: (id) sender;
/**
Description forthcoming
*/
- (void) changeSection: (id) sender;
/**
Description forthcoming
*/
- (void) editAsNew: (id) sender;
@end

#endif
