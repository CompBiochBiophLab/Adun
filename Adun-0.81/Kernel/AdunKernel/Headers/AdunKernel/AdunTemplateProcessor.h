/*
   Project: Adun

   Copyright (C) 2005-2007 Michael Johnston & Jordi Villa-Freixa

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
#ifndef _ADUN_TEMPLATE_PROCESSOR_
#define _ADUN_TEMPLATE_PROCESSOR_
#include <Foundation/Foundation.h>
#include "AdunKernel/AdunKernel.h"
#include "AdunKernel/AdunIOManager.h"
#include "AdunKernel/AdController.h"
#include "AdunKernel/AdunController.h"
#include "AdunKernel/AdCoreAdditions.h"

/**
\ingroup coreClasses
AdTemplateProcessor instances validate & process the information
in an AdunCore template file and hence "create" a simulator. 
After processing a template  references to the main parts of 
the simulator must be retrieved and retained by another object since
the created objects will be released by the AdTemplateProcessor object
on the next call to processTemplate:() or setTemplate:().

\note Before using setTemplate:() the template must be validated using validateTemplate:error:(). 
*/
@interface AdTemplateProcessor: NSObject
{
	NSDictionary* template;
	NSDictionary* objectTemplates; 		//The templateObjects section of template.
	NSMutableDictionary* buildDict; 	//All the creating objects are placed here
	NSMutableDictionary* externalObjects;	//The external object are also found here.
	NSError* processingError;
}
/**
Designated initialiser.
Returns a new AdTemplateProcessor instance 
*/
- (id) init;
/**
Sets the template to use to \e template. This removes all build
information associated with the last template. You should call
validateTemplate:error:() first to validate \e aTemplate.
*/
- (void) setTemplate: (NSDictionary*) aTemplate;
/**
Validates \e object for use as a template. Returns YES if
\e object is a valid template. NO if its not. If its not
\e error contains an NSError object (created using AdKnownExceptionError())
detailing why the validation failed.
See the NSKeyValueCoding protocol for more on validation.
*/
- (BOOL) validateTemplate: (id*) object error: (NSError**) error;
/**
Returns the current template.
*/
- (NSDictionary*) template;
/**
Processes the current template. This removes any information
associated with the processing of the last template. 
Returns YES on success. Otherwise returns NO and error contains
an NSError object describing the reason for failure.
*/
- (BOOL) processTemplate: (NSError**) error;
/**
Returns the AdConfigurationGenerator object for the last processed template.
*/
- (AdConfigurationGenerator*) configurationGenerator;
/**
Returns the controller object for the last processed template.
*/
- (id) controller;
/**
Returns a NSDictionary containing all the external objects loaded for the last
template. The keys are the name associated with each object in the template.
*/
- (NSDictionary*) externalObjects;
/**
Sets the external objects to be used when building the template.
An object associated with a given name in \e dict overrides any
object associated with the same name specified
in the externalObjects section of the template
*/
- (void) setExternalObjects: (NSDictionary*) dict;
/**
Returns a dictionary containing all the objects created during the
last template process.
The keys of the dictionary correspond to the object names given in the template
*/
- (NSDictionary*) createdObjects;
@end

#endif
