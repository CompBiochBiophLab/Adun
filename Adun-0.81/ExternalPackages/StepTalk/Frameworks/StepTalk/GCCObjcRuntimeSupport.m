/**
 GCCObjcRuntimeSupport
 Wrapper functions for accessing information in the standard GCC runtime.
 
 Copyright (c) 2009 Free Software Foundation
 
 Written by: Michael Johnston 
 Date: 2009
 
 This file is part of the StepTalk project.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
*/

#import "ObjcRuntimeSupport.h"

/**
Gets all the selectors for class and passes them to callback.
Callback prototype Callback(class, selector, userData).
The Callback is expected to return 0 if there is a problem with the data passed (specifically the userData).
In this case this method returns NO.
Otherwise it returns YES.
*/
BOOL PrivateIterateSelectors(Class class, VisitSelectorCallback callback, void* userData);

BOOL PrivateIterateSelectors(Class class, VisitSelectorCallback callback, void* userData)
{
	BOOL success = YES;
	struct objc_method_list *methods;
	SEL                      sel;
	int                      i;
		
	methods = class->methods;
	
	while(methods)
	{
		for(i = 0; i < methods->method_count; i++)
		{
			sel = methods->method_list[i].method_name;
			if(callback(class, sel, userData) == 0)
			{	
				success = NO;
			}
		}
		
		if(!success)
			break;
		else	
			methods = methods->method_next;
	}	
	
	return success;
}

/**
Iterates over every class, passes them to the callback function.
*/
void ObjcIterateClasses(VisitClassCallback callback, void* userData)
{
	Class           class;
	void           *state = NULL;
	
	while( (class = objc_next_class(&state)) )
	{
		callback(class, userData);
	}
}

/**
 Gets all the selectors for class and passes them to callback.
 If includeMeta is True also gets the superclasses selectors
 */
void ObjcIterateSelectors(Class clazz, BOOL includeMeta, VisitSelectorCallback callback, void* userData)
{
	BOOL retval;
	
	retval = PrivateIterateSelectors(clazz, callback, userData);
	if(includeMeta && retval)
	{
		PrivateIterateSelectors(ObjcClassGetMeta(clazz), callback, userData);
	}
}

const char* ObjcClassName(Class class)
{
	return class_get_class_name(class);
}

Class ObjcClassGetMeta(Class class)
{
	return class_get_meta_class(class);
}

SEL ObjcRegisterSel(const char* name, const char* types)
{
	return sel_register_typed_name(name, types);
}

const char* ObjcSelName(SEL selector)
{
	return sel_get_name(selector);
}

const char* ObjcSelGetType(SEL selector)
{
	return sel_get_type(selector);
}

int ObjcSizeOfType(const char* type)
{
	return objc_sizeof_type(type);
}

int ObjcAlignOfType(const char* type)
{
	return objc_alignof_type(type);
}

const char* ObjcSkipTypeSpec(const char* type)
{
	return objc_skip_typespec(type);
}

const char* ObjcSkipArgSpec(const char* type)
{
	return objc_skip_argspec(type);
}
