#include "AdunKernel/AdunEllipsoidBox.h"

@implementation AdEllipsoidBox

- (void) _initialiseDependants
{
	id obj1, obj2, obj3;

	ellipsoidVolume = 4*M_PI*axisALength*axisBLength*axisCLength/3;
	
	obj1 = [NSArray arrayWithObjects:
			[NSNumber numberWithDouble: axisALength], 	
			[NSNumber numberWithDouble: -axisALength],
			nil]; 	
	obj2 = [NSArray arrayWithObjects:
			[NSNumber numberWithDouble: axisBLength], 	
			[NSNumber numberWithDouble: -axisBLength],
			nil]; 	
	obj3 = [NSArray arrayWithObjects:
			[NSNumber numberWithDouble: axisCLength],
			[NSNumber numberWithDouble: -axisCLength],
			nil]; 	

	[ellipsoidExtremes release];
	ellipsoidExtremes = [NSArray arrayWithObjects: obj1, obj2, obj3, nil];
	[ellipsoidExtremes retain];

	NSDebugLLog(@"AdEllipsoidBox", @"Ellispoid Volume %lf. Elipsoid Extremes %@.",
				 ellipsoidVolume, ellipsoidExtremes);
}

- (id) init
{
	return [self initWithALength: 10.0
		bLength: 10.0
		cLength: 10.0];
}		

- (id) initWithALength: (double) l1
	bLength: (double) l2
	cLength: (double) l3;
{
	return [self initWithCavityCentre: nil
		aLength: l1
		bLength: l2
		cLength: l3];
}

- (id) initWithCavityCentre: (NSArray*) array
	aLength: (double) l1
	bLength: (double) l2
	cLength: (double) l3;
{
	if((self = [super init]))
	{
		if(l1 <= 0)
			[NSException raise: NSInvalidArgumentException
				format: @"A axis length must be greater than 0"];
		else if(l2 <= 0)
			[NSException raise: NSInvalidArgumentException
				format: @"B axis length must be greater than 0"];
		else if(l3 <= 0)
			[NSException raise: NSInvalidArgumentException
				format: @"C axis length must be greater than 0"];
				
		axisALength = l1;
		axisBLength = l2;
		axisCLength = l3;
		ellipsoidExtremes = nil;
		
		if(array == nil)
		{
			centre = [NSMutableArray arrayWithObjects:
					 [NSNumber numberWithDouble: 0.0],
					 [NSNumber numberWithDouble: 0.0],
					 [NSNumber numberWithDouble: 0.0],
					 nil];
		}
		else
			centre = array;

		[centre retain];
		ellipsoidCentre = Ad3DVectorFromNSArray(centre);
		
		[self _initialiseDependants];
	}

	return self;
}

- (void) dealloc
{
	[centre release];
	[ellipsoidExtremes release];
	[super dealloc];
}

- (double) cavityVolume
{
	return ellipsoidVolume;
}

- (BOOL) isPointInCavity: (double*) point
{
	int j;
	double check;
	Vector3D separation;
	
	//return yes if its in the ellipsoid otherwise no

	for(j=0; j<3; j++)
		separation.vector[j] = point[j] - ellipsoidCentre.vector[j];

	check = pow(separation.vector[0], 2)/(axisALength*axisALength);
	check += pow(separation.vector[1], 2)/(axisBLength*axisBLength);
	check += pow(separation.vector[2], 2)/(axisCLength*axisCLength);

	if(check <= 1)
		return YES;
	
	return NO;
}

- (Vector3D*) cavityCentre
{
	return &ellipsoidCentre;
}

- (void) setCavityCentre: (NSArray*) array
{
	Vector3D newCentre;

	newCentre = Ad3DVectorFromNSArray(array);
	[centre release];
	centre = [array retain];
	ellipsoidCentre = newCentre;
}

- (NSArray*) cavityExtremes
{
	return ellipsoidExtremes;
}

- (double) aLength
{
	return axisALength;
}

- (void) setALength: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Ellipsoid axis must be greater than 0"];

	axisALength = value;
	[self _initialiseDependants];
}

- (double) bLength
{

	return axisBLength;
}

- (void) setBLength: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Ellipsoid axis must be greater than 0"];

	axisBLength = value;
	[self _initialiseDependants];
}

- (double) cLength
{
	return axisCLength;
}

- (void) setCLength: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Ellipsoid axis must be greater than 0"];

	axisCLength = value;
	[self _initialiseDependants];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	if([decoder allowsKeyedCoding])
	{
		centre = [decoder decodeObjectForKey: @"Centre"];
		axisALength = [decoder decodeDoubleForKey: @"AxisALength"];
		axisBLength = [decoder decodeDoubleForKey: @"AxisBLength"];
		axisCLength = [decoder decodeDoubleForKey: @"AxisCLength"];
		[centre retain];
		
		ellipsoidCentre = Ad3DVectorFromNSArray(centre);
		[self _initialiseDependants];
	}
	else
		[NSException raise: NSInvalidArgumentException 
			format: @"%@ does not support non keyed coding", [self classDescription]];

	return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{

	if([encoder allowsKeyedCoding])
	{
		NSDebugLLog(@"Encode", @"Encoding %@", [self description]);
		[encoder encodeDouble: axisALength forKey: @"AxisALength"];
		[encoder encodeDouble: axisBLength forKey: @"AxisBLength"];
		[encoder encodeDouble: axisCLength forKey: @"AxisCLength"];
		[encoder encodeObject: centre forKey: @"Centre"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}


@end
