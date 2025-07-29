/*
   Project: UL

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

#include <AppKit/AppKit.h>
#include "ULPreferences.h"

static NSString* coreDomainName;
static NSString* ulDomainName;

@implementation ULPreferences

+ (void) initialize
{
#ifdef GNUSTEP
	coreDomainName = @"AdunCore";
	ulDomainName = @"UL";
#else
	//Could change
	coreDomainName = @"AdunCore";
	ulDomainName = @"com.cbbl.Adun.UL";
#endif

	[coreDomainName retain];
	[ulDomainName retain];
}

- (id) initWithModelViewController: (id) object
{
	NSDictionary* domain;

	if(self = [super init])
	{
		if([NSBundle loadNibNamed: @"Preferences" owner: self] == NO)
		{
			NSWarnLog(@"Problem loading interface");
			return nil;
		}

		defaults = [NSUserDefaults standardUserDefaults];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(updateDefaults:)
			name: NSUserDefaultsDidChangeNotification
			object: nil];
		viewController = object;

		ulDict = [NSMutableDictionary new];
		coreDict = [NSMutableDictionary new];
		[ulDict setObject: ulPDBDirectory forKey:@"PDBDirectory"];
		//FIXME: theme is included here while no system wide GNUstep prefs application	
		//is available by default
		[ulDict setObject: ulTheme forKey:@"GSAppKitUserBundles"];
		[ulDict setObject: ulDebugLevels forKey:@"DebugLevels"];
		[ulDict setObject: ulGnuplotPath forKey:@"GnuplotPath"];
		[coreDict setObject: coreDebugLevels forKey:@"DebugLevels"];
		[coreDict setObject: coreTraceMemory forKey:@"TraceMemory"];
		[coreDict setObject: coreOutputMemoryStatistics forKey:@"OutputMemoryStatistics"];
		[coreDict setObject: coreRedirectOutput forKey:@"RedirectOutput"];
		[coreDict setObject: coreMinimisation forKey:@"InitialMinimisation"];
		
		//Update the interface with the current values in the database
		[self updateDefaults: nil];
		
		//Check that AdunCore persistent domain exists
		domain = [defaults persistentDomainForName: coreDomainName];
		if(domain == nil)
		{
			domain = [NSDictionary dictionary];
			[defaults setPersistentDomain: domain forName: coreDomainName];
		}	

		//Some defaults may not have been set yet.
		//If they weren't, and they are represented by buttons in the interface
		//then updateDefaults: will have set them to NO.
		//However their default value may be YES - Therefore we have to make
		//sure the displayed value reflects the real behaviour.
		[self setValue: [NSNumber numberWithBool: YES]
			forKey: @"RedirectOutput"
			inPersistentDomainForName: coreDomainName];
		[self setValue: [NSNumber numberWithBool: YES]
			forKey: @"InitialMinimisation"
			inPersistentDomainForName: coreDomainName];
			
			
	}

	return self;
}

- (void) awakeFromNib
{
	[sectionList removeAllItems];
	[sectionList addItemWithTitle: @"UL"];
	[sectionList addItemWithTitle: @"Kernel"];
	[sectionList selectItemWithTitle: @"UL"];
}

- (void) sectionDidChange: (id) sender
{
	int index;
	
	index = [sectionList indexOfSelectedItem];
	[preferencesTabView selectTabViewItemAtIndex: index];
	//GNUstep bug - Need to force pop up button
	//to display new name
	[sectionList setNeedsDisplay: YES];
	[sectionList selectItemAtIndex: index];
}

- (void) dealloc
{
	[super dealloc];
}

- (void) showPreferences: (id) sender
{
	[preferencesWindow center];
	[preferencesWindow makeKeyAndOrderFront: self];
}

- (void) _setButton: (id) button forDefault: (NSString*) string inDomain: (NSDictionary*) domain
{
	if([[domain objectForKey: string] boolValue])
		[button setState: NSOnState];
	else
		[button setState: NSOffState];
}

- (void) updateDefaults: (id) sender
{
	id coreDomain, globalDomain;
	
	globalDomain = [defaults persistentDomainForName: @"NSGlobalDomain"];
	coreDomain = [defaults persistentDomainForName: coreDomainName];

	[ulGnuplotPath setStringValue: [defaults objectForKey: @"GnuplotPath"]];
	[ulPDBDirectory setStringValue: [defaults objectForKey: @"PDBDirectory"]];
#ifdef GNUSTEP	
	[ulDebugLevels setStringValue: 
		[[defaults arrayForKey: @"DebugLevels"] componentsJoinedByString: @", "]];
	[coreDebugLevels setStringValue:
		[[coreDomain objectForKey: @"DebugLevels"] componentsJoinedByString: @", "]];		
	[ulTheme setStringValue:
		[[globalDomain objectForKey: @"GSAppKitUserBundles"] componentsJoinedByString: @", "]];
#endif		

	[self _setButton: coreTraceMemory
		 forDefault: @"TraceMemory"
		 inDomain: coreDomain];	
	[self _setButton: coreRedirectOutput 
		forDefault: @"RedirectOutput" 
		inDomain: coreDomain];	
	[self _setButton: coreOutputMemoryStatistics
		forDefault: @"OutputMemoryStatistics" 
		inDomain: coreDomain];	
	[self _setButton: coreMinimisation
		forDefault: @"InitialMinimisation" 
		inDomain: coreDomain];	

	[defaults synchronize];
}

- (NSArray*) _convertStringToArray: (NSString*) string
{
	id array, value, processedArray;
	NSEnumerator* valueEnum;

	array = [string componentsSeparatedByString: @","];
	if([array count] == 1)
	{
		//check if the values are separated by whitespace
		array = [string componentsSeparatedByString: @" "];
	}		

	processedArray = [NSMutableArray arrayWithCapacity: 1];
	valueEnum = [array objectEnumerator];
	while(value = [valueEnum nextObject])
		[processedArray addObject: [value stringByTrimmingCharactersInSet: 
			[NSCharacterSet whitespaceCharacterSet]]];

	return processedArray;
}

- (void) setValue: (id) value forKey: (NSString*) key inPersistentDomainForName: (NSString*) name
{
	NSMutableDictionary* domain;

	domain = [[defaults persistentDomainForName: name] mutableCopy];
	[domain setObject: value forKey: key];
	[defaults setPersistentDomain: domain forName: name];
	[domain release];
}

- (void) setDefault: (id) sender
{
	NSString* defaultName, *domainName;
	id defaultValue;

	if([[ulDict allKeysForObject: sender] count] > 0)
	{
		defaultName =  [[ulDict allKeysForObject: sender] objectAtIndex: 0];
		domainName = ulDomainName;
	}
	else if([[coreDict allKeysForObject: sender] count] > 0)
	{
		defaultName =  [[coreDict allKeysForObject: sender] objectAtIndex: 0];
		domainName = coreDomainName;
	}
	else
		[NSException raise: NSInternalInconsistencyException
			format: @"Unknown preferences input object"];
		
	//process the senders value
	if([defaultName isEqual: @"DebugLevels"])
		defaultValue = [self _convertStringToArray: [sender stringValue]];
	else if([defaultName isEqual: @"GSAppKitUserBundles"])
		defaultValue = [self _convertStringToArray: [sender stringValue]];
	else if([sender isKindOfClass: [NSButton class]])
	{
		if([sender state] == NSOnState)
			defaultValue = [NSNumber numberWithBool: YES];
		else	
			defaultValue = [NSNumber numberWithBool: NO];
	}
	else
		defaultValue = [sender stringValue];
	
	//Set the default 
	if([defaultName isEqual: @"GSAppKitUserBundles"])
	{
		[self setValue: defaultValue 
			forKey: defaultName 
			inPersistentDomainForName: @"NSGlobalDomain"];
	}
	else
	{
		[self setValue: defaultValue 
			forKey: defaultName 
			inPersistentDomainForName: domainName];
	}

	[defaults synchronize];
}


@end
