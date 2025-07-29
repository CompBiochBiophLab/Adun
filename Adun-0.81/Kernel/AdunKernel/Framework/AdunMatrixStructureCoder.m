/*
 Project: AdunKernel
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Author: Michael Johnston
 
 Created: 11/07/2008 by michael johnston
 
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
#include "AdunKernel/AdunMatrixStructureCoder.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdunSystem.h"

//Class vars 
NSString* AdMatrixPointerTypeEncoding;
NSString* GSLMatrixPointerTypeEncoding;
BOOL isInitialized = NO;

@implementation AdMatrixStructureCoder

//This is a hack 
//For some reason on 64 bit structure type encodings of methods
//Have extra characters after the supposedly final brace
- (NSString*) _gnustep64Fix: (NSString*) encoding
{
	NSRange range;
	
	//Check if AdMatrix encoding string is a substring of encoding.
	//If it we return AdMatrix encoding
	range = [AdMatrixPointerTypeEncoding rangeOfString: encoding];

	if(range.location == 0)
		return AdMatrixPointerTypeEncoding;

	//Same for GSL
	range = [GSLMatrixPointerTypeEncoding rangeOfString: encoding];	
	if(range.location == 0)
		return GSLMatrixPointerTypeEncoding;

	return encoding;			
}

+ (void) initialize
{
	if(!isInitialized)
	{
		AdMatrixPointerTypeEncoding = [NSString stringWithCString: @encode(AdMatrix*) 
								 encoding: NSUTF8StringEncoding];
		GSLMatrixPointerTypeEncoding = [NSString stringWithCString: @encode(gsl_matrix*) 
								  encoding: NSUTF8StringEncoding];
		[AdMatrixPointerTypeEncoding retain];
		[GSLMatrixPointerTypeEncoding retain];					   
		isInitialized = YES;	
	}
}

//Checks if the key is an AdMatrix or gsl_matrix struct and the value is
//an AdDataMatrix. If so this method takes over the key-value coding
//otherwise passes on to the standard mechanism
- (void) setValue: (id) value forKey: (NSString*) key
{
	NSString* setKey, *type, *startCharacter;
	NSMethodSignature* signature;
	NSInvocation* invocation;
	AdMatrix* adMatrix;
	gsl_matrix* gslMatrix;

	if([key isEqual: @""] || key == NULL)
	{
		return [super setValue: value forKey: key];
	}

	//Create setter key
	startCharacter = [key substringToIndex: 1];
	startCharacter = [startCharacter capitalizedString];
	
	if([key length] > 1)
	{
		setKey = [NSString stringWithFormat: @"%@%@", 
			  startCharacter, [key substringFromIndex: 1]];
	}
	else
	{
		//Unlikely but just in case
		setKey = startCharacter;
	}

	setKey = [@"set" stringByAppendingString: setKey];
	setKey = [setKey stringByAppendingString: @":"];
	NSDebugLLog(@"AdMatrixStructureCoder", @"Set key is %@", setKey);
	
	//FIXME: Check all key possibilities
	signature = [self methodSignatureForSelector: NSSelectorFromString(setKey)];
	if(signature == nil)
	{
		[super setValue: value forKey: key];
	}
	else
	{
		//Key type
		//First two args are _cmd and self
		type = [[NSString alloc] 
			initWithCString: [signature getArgumentTypeAtIndex: 2] 
			encoding: NSUTF8StringEncoding];
		
#ifdef GNUSTEP
		type = [self _gnustep64Fix: type];
#endif		
		NSDebugLLog(@"AdMatrixStructureCoder", @"Key type encoding - %@. Checking aginst %@ and %@",
			type, AdMatrixPointerTypeEncoding, GSLMatrixPointerTypeEncoding);
		
		if([type isEqual: AdMatrixPointerTypeEncoding] 
			&& [value isKindOfClass: [AdDataMatrix class]])
		{
			NSDebugLLog(@"AdMatrixStructureCoder", @"AdMatrix key");
			adMatrix = [value cRepresentation];
			
			//Create and send invocation 
			invocation = [NSInvocation invocationWithMethodSignature: signature];
			[invocation setTarget: self];
			[invocation setSelector: NSSelectorFromString(setKey)];
			[invocation setArgument: &adMatrix atIndex: 2];
			[invocation invoke];
			
			[[AdMemoryManager appMemoryManager] freeMatrix: adMatrix];
		}
		else if([type isEqual: GSLMatrixPointerTypeEncoding] 
				&& [value isKindOfClass: [AdDataMatrix class]])
		{
			NSDebugLLog(@"AdMatrixStructureCoder", @"GSLMatrix key");
			gslMatrix = AdGSLMatrixFromAdDataMatrix(value);
			
			//Create and send invocation 
			invocation = [NSInvocation invocationWithMethodSignature: signature];
			[invocation setTarget: self];
			[invocation setSelector: NSSelectorFromString(setKey)];
			[invocation setArgument: &gslMatrix atIndex: 2];
			[invocation invoke];
			  
			gsl_matrix_free(gslMatrix); 
		}
		else
		{
			NSDebugLLog(@"AdMatrixStructureCoder", @"Normal key");
			[super setValue: value forKey: key]; 
		}
	}
}

- (id) valueForKey: (NSString*) key
{
	NSMethodSignature* signature;
	NSString* type;
	id value;
	
	NSDebugLLog(@"AdMatrixStructureCoder", @"Request for key %@", key);
	NSDebugLLog(@"AdMatrixStructureCoder", @"Receiver class - %@", [self class]);
	NSDebugLLog(@"AdMatrixStructureCoder", @"Object type code - %s", @encode(AdSystem));
	
	//FIXME: Check all key possibilities
	signature = [self methodSignatureForSelector: NSSelectorFromString(key)];
	if(signature == nil)
		return [super valueForKey: key];
	
	//Return type
	NSDebugLLog(@"AdMatrixStructureCoder", @"C string return type %s", [signature methodReturnType]);
	type = [[NSString alloc] 
		initWithCString: [signature methodReturnType] 
		encoding: NSUTF8StringEncoding];
	
	NSDebugLLog(@"AdMatrixStructureCoder", @"Key type encoding - %@. Checking aginst %@ and %@",
		    type, AdMatrixPointerTypeEncoding, GSLMatrixPointerTypeEncoding);
		    	
	if([type isEqual: AdMatrixPointerTypeEncoding])
	{
		NSDebugLLog(@"AdMatrixStructureCoder", @"AdMatrix key");
		value = [AdDataMatrix matrixFromADMatrix: 
			 (AdMatrix*)[self performSelector: NSSelectorFromString(key)]];
	}
	else if([type isEqual: GSLMatrixPointerTypeEncoding])
	{
		NSDebugLLog(@"AdMatrixStructureCoder", @"GSLMatrix key");
		value = [AdDataMatrix matrixFromGSLMatrix:
			 (gsl_matrix*)[self performSelector: NSSelectorFromString(key)]];
	}
	else
	{
		NSDebugLLog(@"AdMatrixStructureCoder", @"Normal key");
		value = [super valueForKey: key]; 
	}
	
	NSDebugLLog(@"AdMatrixStructureCoder", @"Value is %@", value);
	[type release];
	
	return [[value retain] autorelease];
}

@end
