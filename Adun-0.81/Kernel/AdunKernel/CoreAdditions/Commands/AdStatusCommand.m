/*
   Project: Adun

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
#include "Commands/AdStatusCommand.h"

@implementation AdCore (AdStatusCommand)

- (id) status: (NSDictionary*) options
{
	int currentStep;
	int numberOfSteps, stepsRemaining;
	double elapsedTime, percentageComplete;
	id estimatedFinish, value;
	NSMutableDictionary* status = [NSMutableDictionary dictionaryWithCapacity: 1];
	NSMutableString* stringDescription;
	NSEnumerator* statusEnum;
	NSDateFormatter* formatter;

	[commandResults removeObjectForKey: @"status"];

	if(configurationGenerator == nil)
	{
		[self setErrorForCommand: @"status"
			description: @"Configuration generator has not been created"];
		return [NSNumber numberWithBool: NO];
	}	
	
	if(date == nil)
	{
		[self setErrorForCommand: @"status"
			description: @"Generation loop has not begun"];
		return [NSNumber numberWithBool: NO];
	}

	formatter = [[NSDateFormatter alloc] 
			initWithDateFormat: @"%H:%M %d/%m"
			allowNaturalLanguage: NO];
		      
	elapsedTime = -1*[date timeIntervalSinceNow];
	currentStep = [configurationGenerator currentStep];
	numberOfSteps = [configurationGenerator numberOfSteps];
	stepsRemaining = numberOfSteps - currentStep;
	percentageComplete = (double)currentStep/numberOfSteps;
	estimatedFinish = [date addTimeInterval: (elapsedTime/currentStep)*stepsRemaining + elapsedTime];

	[status setObject: [NSNumber numberWithInt: currentStep] 
		forKey: @"currentStep"];
	[status setObject: [NSNumber numberWithInt: numberOfSteps] 
		forKey: @"numberOfSteps"];
	[status setObject: [NSNumber numberWithInt: stepsRemaining] 
		forKey: @"stepsRemaining"];
	[status setObject: [NSString stringWithFormat: @"%5.2lf", percentageComplete*100] 
		forKey: @"percentageComplete"];
	[status setObject: [NSString stringWithFormat: @"%-7.4lf", elapsedTime/currentStep] forKey: @"timePerStep"];
	[status setObject: [formatter stringForObjectValue: date] 
		forKey: @"startDate"];
	[status setObject: [formatter stringForObjectValue: estimatedFinish]
		forKey: @"estimatedCompletionDate"];

	stringDescription = [NSMutableString stringWithCapacity: 1];
	statusEnum = [status keyEnumerator];
	while((value = [statusEnum nextObject]))
		[stringDescription appendFormat: @"%@ - %@\n", value, [status objectForKey: value]];
	
	[status setObject: stringDescription forKey: @"stringDescription"];

	[commandErrors removeObjectForKey: @"status"];
	[commandResults setObject: status forKey: @"status"];

	return status;
}

- (NSMutableDictionary*) statusOptions;
{
	return nil;
}

- (NSError*) statusError;
{
	return [commandErrors objectForKey: @"status"];
}

@end

