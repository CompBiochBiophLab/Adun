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
#include "ULInterfaceFunctions.h"

void ULRunErrorPanel(NSError* error)
{
	NSDictionary* userInfo;
	NSString *recoverySuggestion, *detailedDescription, *localizedDescription, *string;

	userInfo = [error userInfo];

	//Have to combine AdDetailedDescriptionKey and NSRecoverySuggestionKey 
	//if they are both present

	detailedDescription = [userInfo objectForKey: @"AdDetailedDescriptionKey"];
	recoverySuggestion = [userInfo objectForKey: @"NSRecoverySuggestionKey"];
	string = @"No further details available";
	if(detailedDescription == nil && recoverySuggestion != nil)
		string = recoverySuggestion;
	else if(recoverySuggestion == nil && detailedDescription != nil)
		string = detailedDescription;
	else if(recoverySuggestion != nil && detailedDescription != nil)	
		string = [NSString stringWithFormat: @"%@\n%@", 
				detailedDescription,
				recoverySuggestion];

	//Check for NSLocalizedDescriptionKey 
	//In some rare case NSLocalizedDescription is used instead.
	localizedDescription = [userInfo objectForKey: NSLocalizedDescriptionKey]; 
	if(localizedDescription == nil)
		localizedDescription = [userInfo objectForKey: @"NSLocalizedDescription"];
		
	//If its still nil - add something
	if(localizedDescription == nil)
		localizedDescription = @"Localized description missing";
	
	NSRunAlertPanel(
		localizedDescription,
		string,
		@"Dismiss",
		nil, nil);
}
