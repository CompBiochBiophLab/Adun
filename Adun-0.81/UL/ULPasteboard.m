#include "ULPasteboard.h"

static id appPasteboard;

@implementation ULPasteboard

+ (id) appPasteboard
{
	if(appPasteboard == nil)
		appPasteboard = [ULPasteboard new];
	
	return appPasteboard;
}

- (id) init
{
	if(appPasteboard != nil)
		return appPasteboard;

	if(self = [super init])
	{
		changeCount = 0;
		pasteboardOwner = nil;
		appPasteboard = self;
	}

	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (NSArray*) availableTypes
{
	id availableTypes;

	availableTypes = [pasteboardOwner availableTypes];
	if([availableTypes count] == 0)
		return nil;
	else
		return availableTypes;
}

- (NSString*) availableTypeFromArray: (NSArray*) anArray
{
	NSArray* availableTypes;
	NSEnumerator* arrayEnum;
	id type;

	availableTypes = [pasteboardOwner availableTypes];
	arrayEnum = [anArray objectEnumerator];
	while(type = [arrayEnum nextObject])
		if([availableTypes containsObject: type])
			return type;

	return nil;
}

- (NSArray*) objectsForType: (NSString*) type
{
	return [pasteboardOwner objectsForType: type];
}

- (id) objectForType: (NSString*) type
{
	return [pasteboardOwner objectForType: type];
}

- (int) countOfObjectsForType: (NSString*) type;
{
	return [pasteboardOwner countOfObjectsForType: type];
}

//the object who will supply the data
- (void) setPasteboardOwner: (id) object
{
	if(![object conformsToProtocol: @protocol(ULPasteboardDataSource)])
		[NSException raise: NSInvalidArgumentException
			format: @"Pasteboard owners must conform to ULPasteboadDataSource"];
			
	[pasteboardOwner pasteboardChangedOwner: self];
	pasteboardOwner = object;
	changeCount++;
}

- (id) pasteboardOwner
{
	return pasteboardOwner;
}	

- (int) changeCount
{
	return changeCount;
}

@end

