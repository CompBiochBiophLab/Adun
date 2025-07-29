/*
   Project: AsepMD

   Copyright (C) 2005, 2006 Ignacio Fdez. Galván, Michael Johnston & Jordi Villá-Freixa

   Authors: Ignacio Fdez. Galván, Michael Johnston

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

#ifndef _ADUN_MOLECULE_CAVITY_
#define _ADUN_MOLECULE_CAVITY_
#include <Foundation/Foundation.h>
#include <Base/AdMatrix.h>
#include <Base/AdVector.h>
#include "AdunKernel/AdunMemoryManager.h"
#include "AdunKernel/AdunDataMatrix.h"
#include "AdunKernel/AdGridDelegate.h"

/**
\ingroup Inter
AdGridDelegate that defines a cavity
determined by the vdw surface of a molecule. The surface is calculated from the
lennard jones parameters of the atoms. However since there are two forms for the
lennard jones interaction that are used in the AdunKernel library, two sets of parameters are possible.
The first form is
\f[
U(r_{ij}) = \frac{A_{i}A{j}}{r_{ij}^{12}} - \frac{B_{i}B{j}}{r_{ij}^{6}}
\f]

Here the parameters are called  "VDW A" and "VDW B". The second form is

\f[
U(r_{ij}) = \sqrt{\epsilon_{i}\epsilon_{j}} \left \{ \left( \frac{0.5(r_{i}^{*} + r_{j}^{*})}{r_{ij}} \right)^{12}
-  2* \left( \frac{0.5(r_{i}^{*} + r_{j}^{*})}{r_{ij}} \right)^{6} \right \}
\f]
In this formula \f$ \epsilon \f$ is called "Well Depth" and \f$r^{*} \f$ the "Equilibrium Separation".
However Charmm supplies \f$ 0.5*(r_{i}^{*} \f$. 
This is equal to half the equilibrium separation for the atoms interaction with an atom of the same type.

The VDW radii of each atom, called \f$ \sigma \f$, is determined from these parameters as follows. 
In the first case from \f$ A_{i} \f$ and \f$ B_{i} \f$
 \f[
\sigma_{i} =  0.5 * \left ( \frac{A_{i}}{B_{i}} \right )^{\frac{1}{3}}
\f]
in the second case given the equilibrium separation \f$ r_{i}^{*} \f$ for atom i the relationship is,
\f[
\sigma_{i} = \frac {r_{i}^{*}}{2^{\frac{1}{6}}}
\f]

\todo Documentation Update - Check LJ formula name and parameters names are consistent across the framework.
*/

@interface AdMoleculeCavity: NSObject <AdGridDelegate>
{
	@private
	double factor;
	Vector3D cavityCentre;
	AdDataMatrix* vdwParameters;
	NSString* vdwType;
	NSMutableArray* cavityExtremes;
	AdMatrix* moleculeCoordinates; //!< Internal representation of the coordinates
	AdDataMatrix* moleculeConfiguration;
}
/**
As initWithVdwType:() with \e type set to "A".
*/
- (id) init;
/**
As initWithVdwType:factor:() with an factory of 1.0
*/
- (id) initWithVdwType: (NSString*) type;
/**
As initWithConfiguration:vdwParameters:vdwType:factor() passing nil
for the configuration and parameters.
*/
- (id) initWithVdwType: (NSString*) string
	factor: (double) factorValue;
/**
As initWithConfiguration:vdwParameters:vdwType:factor extracting
the configuration, vdw parameters and vdw type from \e aSystem.
*/
- (id) initWithSystem: (id) system factor: (double) factorValue;
/**
Returns a cavity defined by the vdw surface of a molecule. The surface is determined from the
atoms lennard jones parameters. There are two forms of the lennard jones interaction, called here A and B,
(see class description)
which use different parameters. For type "A" the parameters are "VDW A" and "VDW B". 
For type "B" the parameters are "Well Depth" and "Equilibrium Separation". You must indicate the type of the parameters
when intialising the object.

\e matrix and  \e table must both have the same  number or rows. If not an NSInvalidArgumentException is raised.
If either \e matrix or \e table are nil the cavity centre is set to 0,0,0 and the cavity extremes to 1,1,1 until
both are set. isPointInCavity:() will return NO until both are set.

\param matrix A data matrix containing the molecules configuration. The returned object uses a copy
of this matrix so if it is mutable any changes will not be reflected by the cavity. You must use 
setConfiguration:() passing the new configuration to change the cavity.
\param table Data matrix containing the lennard jones parameters for each atom in \e matrix. The headers of the
table columns must indicate their contents. 
\param string String describing the lennard jones formula to use ("A" or "B"). The parameters in \e table (or more
specifically the column headers) must be compatible with the formula chosen.
\param factorValue Extends the cavity boundaries by factor times
*/
- (id) initWithConfiguration: (AdDataMatrix*) matrix 
	vdwParameters: (AdDataMatrix*) table
	vdwType: (NSString*) string
	factor: (double) factorValue;
/**
Returns the parameters matrix. This will be a copy of the original
matrix passed to the object.
*/
- (AdDataMatrix*) vdwParameters;
/**
Sets the vdw parameters to be used. If the molecule configuration has
been set \e table must have the same number of rows. If not an NSInvalidArgumentException
is raised. Calling this method recalculate the cavity centre and extremes
*/
- (void) setVdwParameters: (AdDataMatrix*) table;
/**
Returns the vdw type.
*/
- (NSString*) vdwType;
/**
Sets the vdw type to be used.
Calling this method recalculates the cavity centre and extremes.
*/
- (void) setVdwType: (NSString*) type;
/**
Returns the configuration matrix. This will be a copy of the original matrix
passed to the object.
*/
- (AdDataMatrix*) configuration;
/**
Sets the molecule configuration. If the vdw parameters have
been set \e matrix must have the same number of rows. If not an NSInvalidArgumentException
is raised. Calling this method recalculates the cavity centre and extremes
*/
- (void) setConfiguration: (AdDataMatrix*) aMatrix;
/**
Returns the cavity factor.
*/
- (double) factor;
/**
Sets the cavity factor to \e value. 
Calling this method recalculates the cavity centre and extremes.
*/
- (void) setFactor: (double) value;
/**
 Returns the cavity centre as an NSArray
 */
- (NSArray*) centre;
@end

#endif
