#ifndef _ADUN_SPHERICAL_BOX_
#define _ADUN_SPHERICAL_BOX_

#include "Base/AdVector.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunGrid.h"

/**
\ingroup Inter
AdSpherical box objects define a spherical volume.
They conform to the AdGridDelegate protocol and are for use with AdGrid.
*/

@interface AdSphericalBox: NSObject <AdGridDelegate, NSCoding>
{	
	@private
	id environment;
	double sphereRadius;		//!< the radius of the sphere
	double sphereVolume;		//!< the volume of the sphere
	Vector3D sphereCentre;		//!< centre of the sphere as Vector3D
	NSArray* centre;		//!< centre of sphere as NSArray
	NSArray* sphereExtremes;
}
/**
As initWithRadius:() with a radius of 10.
*/
- (id) init;
/**
As initWithCavityCentre:radius:() passing nil for the centre.
*/
- (id) initWithRadius: (double) rad;
/**
Initialises a new AdSphericalBox instance. 
\param centre The position of the centre of the sphere (arbitrary units). An array of three NSNumbers.
\param radius The radius of the sphere (arbitrary units). Must be greater than 0.
*/
- (id) initWithCavityCentre: (NSArray*) centre
	radius: (double) radius;
/**
Sets the cavity centre to be the point defined by \e array
\param array An array of doubles defining the center of the cavity.
If \e array does not have three elements the center is set to the origin.
If the object has been set as the delegate of an AdGrid instance you need
to call AdGrid::cavityDidMove to update it after using this method.
*/
- (void) setCavityCentre: (NSArray*) array;
/**
Returns the sphere radius.
*/
- (double) radius;
/**
Sets the sphere radius to \e value. \e value must be
greater than zero. If not an NSInvalidArgumentException is
raised.
*/
- (void) setRadius: (double) value;
@end

#endif
