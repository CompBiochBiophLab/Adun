#include "AdunKernel/AdunSphericalBox.h"

@implementation AdSphericalBox

- (void) _initialiseDependants
{
	id obj;

	sphereVolume = 4*M_PI*pow(sphereRadius, 3)/3;
	
	obj = [NSArray arrayWithObjects:
			[NSNumber numberWithDouble: sphereRadius], 	
			[NSNumber numberWithDouble: -sphereRadius],
			nil]; 	

	[sphereExtremes release];
	sphereExtremes = [NSArray arrayWithObjects: obj, [obj copy], [obj copy], nil];
	[sphereExtremes retain];

	NSDebugLLog(@"SphericalBox", @"SphereVolume %lf. SphereExtremes %@.",
				 sphereVolume, sphereExtremes);
}

- (id) init
{
	return [self initWithRadius: 10.0];
}

- (id) initWithRadius: (double) rad
{
	return [self initWithCavityCentre: nil
		radius: rad];
}

- (id) initWithCavityCentre: (NSArray*) array
	radius: (double) rad
{
	if((self = [super init]))
	{
		if(rad <= 0)
			[NSException raise: NSInvalidArgumentException
				format: @"Radius must be greater than 0"];
		sphereRadius = rad;	
		sphereExtremes = nil;
		
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
		sphereCentre = Ad3DVectorFromNSArray(centre);
		
		[self _initialiseDependants];
	}

	return self;
}

- (void) dealloc
{
	[centre release];
	[sphereExtremes release];
	[super dealloc];
}

- (NSString*) description
{
	NSMutableString* description = [NSMutableString string];

	[description appendFormat: @"%@. Radius: %8.3lf. Centre: (%8.3lf, %8.3lf %8.3lf)\n",
		NSStringFromClass([self class]), sphereRadius,
		sphereCentre.vector[0], sphereCentre.vector[1], sphereCentre.vector[2]];
		
	return description;	
}

- (double) cavityVolume
{
	return sphereVolume;
}

- (BOOL) isPointInCavity: (double*) point
{
	int j;
	Vector3D seperation;
	
	//return yes if its in the sphere otherwise no

	for(j=0; j<3; j++)
		seperation.vector[j] = point[j] - sphereCentre.vector[j];

	Ad3DVectorLength(&seperation);

	if(seperation.length < sphereRadius)
		return YES;
	
	return NO;
}

- (Vector3D*) cavityCentre
{
	return &sphereCentre;
}

- (void) setCavityCentre: (NSArray*) array
{
	Vector3D newCentre;

	newCentre = Ad3DVectorFromNSArray(array);
	[centre release];
	centre = [array retain];
	sphereCentre = newCentre;
}

- (NSArray*) cavityExtremes
{
	return sphereExtremes;
}

- (double) radius
{
	return sphereRadius;
}

- (void) setRadius: (double) value
{
	if(value <= 0)
		[NSException raise: NSInvalidArgumentException
			format: @"Sphere radius must be greater than 0"];
			
	sphereRadius = 	value;	
	[self _initialiseDependants];
}

- (id) initWithCoder: (NSCoder*) decoder
{
	if([decoder allowsKeyedCoding])
	{
		centre = [decoder decodeObjectForKey: @"Centre"];
		sphereRadius = [decoder decodeDoubleForKey: @"SphereRadius"];
		[centre retain];
		
		sphereCentre = Ad3DVectorFromNSArray(centre);
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
		[encoder encodeDouble: sphereRadius forKey: @"SphereRadius"];
		[encoder encodeObject: centre forKey: @"Centre"];
	}
	else
		[NSException raise: NSInvalidArgumentException
			format: @"%@ class does not support non keyed coding", [self class]];
}


@end
