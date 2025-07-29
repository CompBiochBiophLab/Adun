#ifndef _ADUN_ELLIPSOID_BOX
#define _ADUN_ELLIPSOID_BOX_

#include "Base/AdVector.h"
#include "AdunKernel/AdFrameworkFunctions.h"
#include "AdunKernel/AdGridDelegate.h"
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunGrid.h"

/**
\ingroup Inter
AdEllipsoidBox instances define a ellipsoid shaped cavity.

The cavity is defined by the 3 semi-aixs lengths a, b & c,
using the formula 
\f$ \frac{x^{2}}{a^{2}} + \frac{y^{2}}{b^{2}} + \frac{z^{2}}{c^{2}} = 1 \f$
which gives the cavity surface.

If the lengths of two axes of an ellipsoid are the same, the cavity is called a spheroid
(depending on whether c<a or c>a, an oblate spheroid or prolate spheroid, respectively), 
and if all three are the same, it is a sphere. 
*/

@interface AdEllipsoidBox: NSObject <AdGridDelegate, NSCoding>
{	
	@private
	id environment;
	double axisALength;
	double axisBLength;
	double axisCLength;
	double ellipsoidVolume;		//!< the volume of the ellipsoid
	Vector3D ellipsoidCentre;	//!< centre of the ellipsoid as Vector3D
	NSArray* centre;		//!< centre of ellipsoid as NSArray
	NSArray* ellipsoidExtremes;
}
/**
As initWithALength:bLength:cLength:()
with all axis length set to 10.
*/
- (id) init;
/**
As initWithCentre:aLength:bLength:cLength:()
passing nil for \e array.
*/
- (id) initWithALength: (double) l1
	bLength: (double) l2
	cLength: (double) l3;
/**
Returns a initialised AdEllipsoidBox instance.
\param array An array of doubles defining the center of the cavity.
If nil defaults to 0,0,0
\param l1 The ellipsoids x semi-axis length.
\param l2 The ellipsoids y semi-axis length.
\param l3 The ellipsoids z semi-axis length.
*/
- (id) initWithCavityCentre: (NSArray*) array
	aLength: (double) l1
	bLength: (double) l2
	cLength: (double) l3;
/**
Sets the cavity centre to be the point defined by \e array
\param array An array of doubles defining the center of the cavity.
If \e array does not have three elements the center is set to the origin.
If the object has been set as the delegate of an AdGrid instance you need
to call AdGrid::cavityDidMove to update it after using this method.
*/
- (void) setCavityCentre: (NSArray*) array;
/**
Returns the length of the semi-axis in the x direction
*/
- (double) aLength;
/**
Set the length of the semi-axis in the x direction
*/
- (void) setALength: (double) value;
/**
Returns the length of the semi-axis in the y direction
*/
- (double) bLength;
/**
Set the length of the semi-axis in the y direction
*/
- (void) setBLength: (double) value;
/**
Returns the length of the semi-axis in the z direction
*/
- (double) cLength;
/**
Set the length of the semi-axis in the z direction
*/
- (void) setCLength: (double) value;
@end

#endif
