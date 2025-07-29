#include "AdunKernel/AdunForceFieldCollection.h"


@implementation AdForceFieldCollection

- (id) init
{
	return [self initWithForceFields: nil];
}

- (id) initWithForceFields: (NSArray*) anArray
{
	NSEnumerator* arrayEnum;
	id object;

	if((self = [super init]))
	{
		arrayEnum = [anArray objectEnumerator];
		while((object = [arrayEnum nextObject]))
			if(![object isKindOfClass: [AdForceField class]])
				[NSException raise: NSInvalidArgumentException
					format: @"Array can only contain AdForceField objects"];

		if(anArray != nil)
			forceFields = [anArray mutableCopy];
		else
			forceFields = [NSMutableArray new];
			
		activeForceFields = [NSMutableArray new];
		[activeForceFields addObjectsFromArray: forceFields];
		inactiveForceFields = [NSMutableArray new];
		systems = [forceFields valueForKey: @"system"];
		[systems retain];
	}

	return self;
}

- (void) dealloc
{
	[systems release];
	[forceFields release];
	[activeForceFields release];
	[inactiveForceFields release];
	[super dealloc];
}

- (void) addForceField: (AdForceField*) aForceField
{
	[forceFields addObject: aForceField];
	[activeForceFields addObject: aForceField];
	[systems release];
	systems = [forceFields valueForKey: @"system"];
	[systems retain];
}

- (void) removeForceField: (AdForceField*) aForceField
{
	[forceFields removeObject: aForceField];

	if([self isActive: aForceField])
		[activeForceFields removeObject: aForceField];
	else
		[inactiveForceFields removeObject: aForceField];

	[systems release];
	systems = [forceFields valueForKey: @"system"];
	[systems retain];
}

- (NSArray*) forceFields
{
	return [[forceFields copy] autorelease];
}

- (void) setForceFields: (NSArray*) anArray
{
	[forceFields release];
	forceFields = [anArray mutableCopy];
	[activeForceFields removeAllObjects];
	[activeForceFields addObjectsFromArray: forceFields];
}

- (void) evaluateForces
{
	NSDebugLLog(@"SimulationLoop", @"Calculating forces");
	[activeForceFields makeObjectsPerformSelector: @selector(evaluateForces)];
	NSDebugLLog(@"SimulationLoop", @"Force evaluation complete");
}

- (void) evaluateEnergies
{
	[activeForceFields makeObjectsPerformSelector: @selector(evaluateEnergies)];
}

/**
Returns the force fields in anArray operating on aSystem
*/
- (NSArray*) _forceFieldsForSystem: (id) aSystem fromArray: (NSArray*) forceFieldArray
{
	NSMutableArray* anArray;
	NSEnumerator* forceFieldEnum;
	AdForceField* forceField;

	forceFieldEnum = [forceFieldArray objectEnumerator];
	anArray = [NSMutableArray array];
	while((forceField = [forceFieldEnum nextObject]))
	{
		if([forceField system] == aSystem)
			[anArray addObject: forceField];
	}
	
	return anArray;
}

- (NSArray*) forceFieldsForSystem: (id) aSystem activityFlag: (AdForceFieldActivity) value
{
	switch(value)
	{
		case AdActiveForceFields:
			return [self _forceFieldsForSystem: aSystem
				fromArray: activeForceFields];
			break;
		case AdInactiveForceFields:
			return [self _forceFieldsForSystem: aSystem
				fromArray: inactiveForceFields];
			break;
		case AdAllForceFields:
			return [self _forceFieldsForSystem: aSystem
				fromArray: forceFields];
	}

	return nil;
}

- (NSArray*) forceFieldsForSystem: (id) aSystem
{
	return [self _forceFieldsForSystem: aSystem
		fromArray: forceFields];
}

- (NSArray*) forceFieldsForSystems: (NSArray*) systemArray
{
	NSMutableArray* array = [NSMutableArray new];
	NSArray* finalArray, *forceFieldArray;
	NSEnumerator* systemEnum;
	AdForceField* forceField;
	id system;
	
	systemEnum = [systemArray objectEnumerator];
	while(system = [systemEnum nextObject])
	{
		forceFieldArray = [self _forceFieldsForSystem: system
					fromArray: forceFields];
		[array addObjectsFromArray: forceFieldArray];
	}
	
	finalArray = [[array copy] autorelease];
	[array release];
	
	return finalArray;
}

- (NSArray*) systems
{
	return [[systems retain] autorelease];
}

- (void) activateForceField: (AdForceField*) aForceField
{
	if(![self isMember: aForceField])
		[NSException raise: NSInvalidArgumentException
			format: @"%@ is not a member of the force field collection"];

	if(![self isActive: aForceField])
	{
		[inactiveForceFields removeObject: aForceField];
		[activeForceFields addObject: aForceField];
	}	
}

- (void) deactivateForceField: (AdForceField*) aForceField;
{
	if(![self isMember: aForceField])
		[NSException raise: NSInvalidArgumentException
			format: @"%@ is not a member of the force field collection"];

	if([self isActive: aForceField])
	{
		[activeForceFields removeObject: aForceField];
		[inactiveForceFields addObject: aForceField];
	}	
}

- (BOOL) isActive: (AdForceField*) aForceField;
{
	if(![self isMember: aForceField])
		[NSException raise: NSInvalidArgumentException
			format: @"%@ is not a member of the force field collection"];

	return [activeForceFields containsObject: aForceField];	
}

- (BOOL) isMember: (AdForceField*) aForceField;
{
	return [forceFields containsObject: aForceField];
}

- (NSString*) description
{
	return [NSString stringWithFormat: @"Force-Field collection containing %d force-field(s)\n" 
			@"%d active, %d inactive", 
			[forceFields count], [activeForceFields count], [inactiveForceFields count]];
}

@end
