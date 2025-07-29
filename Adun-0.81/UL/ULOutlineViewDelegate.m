/*
   Project: UL

   Copyright (C) 2006 Michael Johnston & Jordi Villa-Freixa

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

#include "ULOutlineViewDelegate.h"


@class ULSelectionWrapper;
@class ULNodeWrapper;
@class ULOptionsLeaf;

/**
Base class used to display
an Adun options dictionary, as created using ULMenuExtensions,
in an NSOutlineView.
*/
@interface ULOutlineViewWrapper: NSObject
{
	int noChildren;
	NSMutableArray* children;
	id parent;
	id identifier;
	id wrappedObject;
	BOOL isExpandable;
	id value;
}

- (id) initWithObject: (id) object parent: (id) parent identifier: (id) aName;
- (int) numberChildren;
- (id) parent;
- (id) identifier;
- (id) childAtIndex: (int) index;
- (id) value;
- (id) wrappedObject;
- (void) childWasSelected: (id) child;

@end


@implementation ULOutlineViewWrapper

+ (id) wrapperForObject: (id) object parent: (id) par identifier: (id) aName
{
	NSDebugLLog(@"ULOutlineViewDelegate", @"Wrapper for object %@ with id %@", object, aName);

	if([object isKindOfClass: [NSDictionary class]])
	{
		if([object objectForKey: @"Selection"] != nil)
		{
			return [[[ULSelectionWrapper alloc] 
				initWithObject: object
				parent: par
				identifier: aName] autorelease];
		}
		else
		{
			 return [[[ULNodeWrapper alloc] 
				initWithObject: object 
				parent: par
				identifier: aName] autorelease];
		}
	}
	else
		return [[[ULOptionsLeaf alloc] 
				initWithObject: object 
				parent: par
				identifier: aName] autorelease];
}

- (id) initWithObject: (id) object parent: (id) parent identifier: (id) aName;
{
	return self;
}

- (int) numberChildren 
{ 
	return noChildren; 
}

- (id) parent 
{ 
	return parent; 
}

- (id) identifier 
{ 
	return identifier; 
}

- (id) childAtIndex: (int) index 
{ 
	return [children objectAtIndex: index]; 
}

- (BOOL) isExpandable 
{ 
	return isExpandable; 
}

- (id) value 
{ 
	return value;
}

- (void) setValue: (id) aValue
{
	[value release];
	value = aValue;
	[value retain];
}

- (id) wrappedObject 
{ 
	return wrappedObject;
}

- (void) childWasSelected: (id) child
{
	//does nothing
}

- (void) dealloc
{
	[children release];
	[parent release];
	[identifier release];
	[value release];
	[super dealloc];
}

@end

/**
ULNodeWrapper wraps  non-selection NSDictionaries
of an Adun options file
*/

@interface ULNodeWrapper: ULOutlineViewWrapper
- (void) setValue: (id) aValue forChild: (id) child;
- (NSString*) childForIdentifier: (NSString*)anId;
@end

@implementation ULNodeWrapper

- (void) _setChildren
{
	id anEnum, key;
	NSArray* array;
	
	noChildren = [wrappedObject count];
	array = [wrappedObject allKeys];
	array = [array sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	anEnum = [array objectEnumerator];
	while(key = [anEnum nextObject])
	{
		[children addObject: 
			[ULOutlineViewWrapper wrapperForObject: [wrappedObject valueForKey: key] 
				parent: self
				identifier: key]];
	}

}

- (id) initWithObject: (id) object parent: (id) par identifier: (id) aName
{
	children = [NSMutableArray new];
	isExpandable = YES;
	value = @"";
	wrappedObject = object;
	parent = [par retain];
	identifier = [aName retain];
	[value retain];
	[self _setChildren];	

	return self;
}

- (void) setValue: (id) aValue forChild: (id) child
{
	NSString* key;

	if(![child isKindOfClass: [NSDictionary class]])
	{
		key = [child identifier];
		[wrappedObject setValue: aValue forKey: key];
		[child setValue: aValue];
	}
}

- (NSString*) childForIdentifier: (NSString*) anId
{
	NSEnumerator* childEnum;
	id child;

	childEnum = [children objectEnumerator];
	while(child = [childEnum nextObject])
		if([[child identifier] isEqual: anId])
			return child;

	return nil;
}

- (void) dealloc
{
	[super dealloc];
}

@end

/**
ULSelectionWrapper wraps  selection NSDictionaries
of an Adun options file. These are dictionaries that contain
the key @"Selection" and @"Type"
*/

@interface ULSelectionWrapper: ULNodeWrapper
{
	BOOL isMultiple;
}
- (void) setValue: (id) aValue forChild: (id) child;
- (BOOL) isMultiple;
@end

@implementation ULSelectionWrapper

- (id) _setChildrenForArray
{
	int i;
	id anEnum, key;
	id object, selectedValue, choiceArray;
	NSArray* defaultSelection, *array;
	NSEnumerator* selectionEnum;

	defaultSelection = nil;
	
	//the keys are not in a defined order
	//therefore find the choice array first
	//then deal with the default selection
	array = [wrappedObject allKeys];
	array = [array sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	anEnum = [array objectEnumerator];
	while(key = [anEnum nextObject])
		if(![key isEqual: @"Selection"] && ![key isEqual: @"Type"])
			choiceArray = [wrappedObject valueForKey: key];
			for(i=0; i<[choiceArray count]; i++)
				[children addObject: 
					[ULOutlineViewWrapper wrapperForObject: @""
						parent: self
						identifier: [choiceArray objectAtIndex: i]]];
			
	
	anEnum = [wrappedObject keyEnumerator];
	while(key = [anEnum nextObject])
	{
		if([key isEqual: @"Selection"])
		{
			object = [wrappedObject valueForKey: @"Selection"];
			NSDebugLLog(@"ULOutlineViewDelegate", @"Selection value is %@", object);
			if(![object isKindOfClass: [NSArray class]])
				[NSException raise: NSInternalInconsistencyException
					format: @"Invalid structure for options selection object. Must be an array"];
			if(![object count] == 0)
			{
				//check the selection(s) is/are in the array 
				
				selectionEnum = [object objectEnumerator];
				while(selectedValue = [selectionEnum nextObject])
				{
					if(![choiceArray containsObject: selectedValue])
					{
						[NSException raise: NSInternalInconsistencyException
							format: [NSString stringWithFormat:
							 @"Selected value %@ is not in object", selectedValue]];
					}
					else
					{		
						defaultSelection = object;
					}
				}	
			}
		}
		else if([key isEqual: @"Type"])
			if([[wrappedObject valueForKey: @"Type"] isEqual: @"Single"])
				isMultiple = NO;
	}

	return defaultSelection;
}

- (id) _setChildrenForDictionary
{
	id anEnum, key;
	id object, selectedValue;
	NSArray* defaultSelection, *array;
	NSEnumerator* selectionEnum;

	defaultSelection = nil;
	array = [wrappedObject allKeys];
	array = [array sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	anEnum = [array objectEnumerator];
	while(key = [anEnum nextObject])
	{
		if(![key isEqual: @"Selection"] && ![key isEqual: @"Type"])
		{
			object = [wrappedObject valueForKey: key];
			[children addObject: 
				[ULOutlineViewWrapper wrapperForObject: object 
					parent: self
					identifier: key]];
		}
		else if([key isEqual: @"Selection"])
		{
			object = [wrappedObject valueForKey: @"Selection"];
			NSDebugLLog(@"ULOutlineViewDelegate", @"Selection value is %@", object);
			if(![object isKindOfClass: [NSArray class]])
				[NSException raise: NSInternalInconsistencyException
					format: @"Invalid structure for options selection object. Must be an array"];
			if(![object count] == 0)
			{
				//check the selection(s) is/are in the dictionary
				
				selectionEnum = [object objectEnumerator];
				while(selectedValue = [selectionEnum nextObject])
					if([wrappedObject objectForKey: selectedValue] == nil)
					{
						[NSException raise: NSInternalInconsistencyException
							format: [NSString stringWithFormat:
							 @"Selected value %@ is not in object", selectedValue]];
					}
					else
					{		
						//FIXME: no support for multiple selections!
						defaultSelection = object;
					}
			}
		}
		else if([key isEqual: @"Type"])
			if([[wrappedObject valueForKey: @"Type"] isEqual: @"Single"])
				isMultiple = NO;
	}
	
	return defaultSelection;
}

- (void) _setChildren
{
	id anEnum, key;
	id object, optionsType;
	id defaultSelection;

	//first check is it an array or dictionary based selection
	//array based options can only contain 3 object (Type, Selection, and the array)

	if([wrappedObject count] <= 3)
	{
		anEnum = [wrappedObject keyEnumerator];
		while(key = [anEnum nextObject])
			if(![key isEqual: @"Selection"] && ![key isEqual: @"Type"])
			{
				object = [wrappedObject valueForKey: key];
				if([object isKindOfClass: [NSArray class]])
					optionsType = @"Array";
				else
					optionsType = @"Dict";
			}
	}
	else
		optionsType = @"Dict";

	NSDebugLLog(@"ULOutlineViewDelegate", @"Selection type is %@", optionsType);

	if([optionsType isEqual:  @"Dict"])
		defaultSelection = [self _setChildrenForDictionary];
	else
		defaultSelection = [self _setChildrenForArray];
	
	noChildren = [children count];
	if(defaultSelection != nil)
	{
		anEnum = [children objectEnumerator];
		while(object = [anEnum nextObject])
			if([defaultSelection containsObject: [object identifier]])
				[object setValue: @"Selected"];
	}
}

- (id) initWithObject: (id) object parent: (id) par identifier: (id) aName
{
	if(self = [super init])
	{
		children = [NSMutableArray new];
		isExpandable = YES;
		value = @"";
		wrappedObject = object;
		parent = [par retain];
		identifier = [aName retain];
		[value retain];
		isMultiple = YES;
		[self _setChildren];
	}	

	return self;
}

- (void) childWasSelected: (id) child
{
	id key;
	id previousSelection;

	NSDebugLLog(@"ULOutlineViewDelegate",
		@"Child %@ with value %@ was selected", child, [child value]);

	key = [child identifier];

	if([[child value] isEqual: @"Selected"])
	{
		NSDebugLLog(@"ULOutlineViewDelegate", 
			@"Child is Yes - Changing to no and removing from %@",
				 [[wrappedObject valueForKey: @"Selection"] description]);
		[child setValue: @""];
		[[wrappedObject valueForKey:@"Selection"] removeObject: key];
		NSDebugLLog(@"ULOptionsViewControlle", @"Selection is now %@",
				 [[wrappedObject valueForKey: @"Selection"] description]);
	}
	else
	{
		NSDebugLLog(@"ULOutlineViewDelegate", 
			@"Child is NO - Changing to Yes and adding to selection %@", 
				[[wrappedObject valueForKey: @"Selection"] description]);
		[child setValue: @"Selected"];
		if(!isMultiple)	
		{	
			//catch when nothing has been selected
			NS_DURING	
			{
				previousSelection = [self childForIdentifier: 
							[[wrappedObject valueForKey:@"Selection"] 
								objectAtIndex: 0]];
				[previousSelection setValue: @""];
				[[wrappedObject valueForKey:@"Selection"] removeAllObjects];
			}
			NS_HANDLER
			{
				if(![[localException name] isEqual: NSRangeException])
					[localException raise];
			}
			NS_ENDHANDLER
		}
		[[wrappedObject valueForKey:@"Selection"] addObject: [child identifier]];
		NSDebugLLog(@"ULOutlineViewDelegate", @"Selection is now %@", 
				[[wrappedObject valueForKey: @"Selection"] description]);
	}		
}

- (void) setValue: (id) aValue forChild: (id) child
{

}

- (void) dealloc
{
	[super dealloc];
}

- (BOOL) isMultiple
{
	return isMultiple;
}

@end

/**
ULOptionsLeaf wraps the final key:value option
pairs in an Adun options file i.e. where value
is a NSString. They are also used to display
the selection state of the elements of an ULSelectionWrapper
(YES, NO)
*/

@interface ULOptionsLeaf: ULOutlineViewWrapper
@end

@implementation ULOptionsLeaf

- (id) initWithObject: (id) object parent: (id) par identifier: (id) aName
{
	noChildren = 0;
	value = object;
	parent = [par retain];
	identifier = [aName retain];
	[value retain];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

@end

/******

The Main Class

*******/

@implementation ULOutlineViewDelegate

- (id) initWithProperties: (id) properties allowEditing: (BOOL) value
{
	if(self = [super init])
	{
		wrappedOptions = [ULOutlineViewWrapper 
					wrapperForObject: properties
					parent: nil
					identifier: @"root"];
		valueEditing = value;
		isProperties = YES;
		[wrappedOptions retain];
		outlineColumnIdentifier = @"Options";
		[outlineColumnIdentifier retain];	
	}

	return self;
}

- (id) initWithOptions: (id) options
{
	return [self initWithOptions: options
			outlineColumnIdentifier: @"Options"];
}

- (id) initWithOptions: (id) options outlineColumnIdentifier: (NSString*) aString
{
	if(self = [super init])
	{
		wrappedOptions = [ULOutlineViewWrapper 
					wrapperForObject: options
					parent: nil
					identifier: @"root"];
		valueEditing = YES;
		isProperties = NO;
		[wrappedOptions retain];
		if(aString == nil)
			outlineColumnIdentifier = @"Options";
		else
			outlineColumnIdentifier = aString;

		[outlineColumnIdentifier retain];	
	}

	
	return self;
}

- (void) dealloc
{
	[wrappedOptions release];
	[outlineColumnIdentifier release];
	[super dealloc];
}

/*************

OutlineView Data Source Methods

*************/

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return (item == nil) ? [wrappedOptions numberChildren] : [item numberChildren];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	return (item == nil) ? [wrappedOptions childAtIndex: index] : [item childAtIndex: index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return (item == nil) ? YES :  [item isExpandable]; 
}

- (id)outlineView:(NSOutlineView *)outlineView 
	objectValueForTableColumn:(NSTableColumn *)tableColumn 
	byItem:(id)item
{
	if([[tableColumn identifier] isEqual:outlineColumnIdentifier])
	{
		return (item == nil) ? [wrappedOptions identifier] : [item identifier];
	}
	else
	{	
		//Return the item - the outline view will use its description.
#ifdef GNUSTEP
		return [item value];
#else	
		//Cocoa has multiline descriptions which can't be properly displayed
		//by the outline view. The "\n" have to removed from the description string.
		item = [[[item value] description] stringByReplacingString: @"\n" withString: @""];
		item = [item stringByReplacingString: @" " withString: @""];
		return [item stringByReplacingString: @"," withString: @", "];
#endif		
	}
}

- (void)outlineView:(NSOutlineView *)outlineView 
		setObjectValue:(id)object 
		forTableColumn:(NSTableColumn *)tableColumn 
		byItem:(id)item
{
	NSDebugLLog(@"ULOutlineViewDelegate", @"Object is %@. Item is %@", object, item);

	if(![item isExpandable])
		[[item parent] setValue: object forChild: item];
}

/***********

OutlineView Delegate Methods

************/

- (void) outlineViewSelectionDidChange: (NSNotification*) aNotification
{
	int selectedRow, i;
	id item, parent;
	id outlineView;

	if(isProperties)
		return;

	outlineView = [aNotification object];
	selectedRow = [outlineView selectedRow];
	if(selectedRow != -1)
	{
		item = [outlineView itemAtRow: [outlineView selectedRow]];
		parent = [item parent];
		NSDebugLLog(@"ULOutlineViewDelegate", @"Selection changed to %@ (%@). Parent %@",
				item, [item identifier], parent);
		[parent childWasSelected: item];
		//If this is a selection menu item we have to update the selection
		if([parent isKindOfClass: [ULSelectionWrapper class]])
		{
#ifdef GNUSTEP
			//This is the original code which works on gnustep
			//for single selection. i.e. when one child is selected the
			//other is deselected. However looking at the code now Im not
			//sure how this is possible! 
			//Possibly reloadItem calls reloadData or Im missing something.
			//However it definitely doesnt work on cocoa.
			//We will keep this however since if reloadItem: on gnustep does
			//involve calling reloadData then using the cocoa code there will
			//result in reloadData being called multiple redundant times.
			[outlineView reloadItem: item];
#else
			if([parent isMultiple])
				[outlineView reloadItem: item];
			else	
			{
				//Have to reload all children to ensure the previously selected
				//item appears deselected in the view
				for(i=0; i<[(ULOutlineViewWrapper*)parent numberChildren]; i++)
					[outlineView reloadItem:
						[parent childAtIndex: i]];
			}
#endif		
		}
	}	
}

- (BOOL) outlineView: (NSOutlineView*) outlineView shouldExpandItem: (id) item
{
	return YES;
}

- (BOOL) outlineView: (NSOutlineView*) outlineView 
		shouldEditTableColumn: (NSTableColumn*) tableColumn 
		item: (id) item
{
	//dont allow editing of the outline column

	if([[tableColumn identifier] isEqual: outlineColumnIdentifier])
		return NO;

	if(![item isExpandable] && isProperties)
	{
		if(valueEditing && [[(ULOutlineViewWrapper*)[item parent] identifier] isEqual: @"User Metadata"])
			return YES;
		else
			return NO;
	}	
	else if(![item isExpandable] && valueEditing)
		return YES;
	else
		return NO;
}

@end
