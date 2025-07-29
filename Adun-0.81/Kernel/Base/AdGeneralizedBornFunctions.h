/*
 Project: AdunBase
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
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

#ifndef GBFUNCTIONS
#define GBFUNCTIONS

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <Base/AdVector.h>
#include <Base/AdMatrix.h>
#include <Base/AdLinkedList.h>

/**
 These are the primitive functions used to calculate the GB radius using the GBSW method.
 \defgroup GBSWFunctions Smoothed GB Functions 
 \ingroup Functions
 */

/**
 These are the functions used to calculate the GB energy and its derivatives.
 
 \f[
 \Delta G^{elec}_{ab} = -\frac{1}{4\pi\epsilon_{0}} * \frac{\tau}{2} *
 \frac{ q_{a}q_{b} } { \sqrt{ r_{ab}^{2} + R_{a}R_{b} \exp(\frac{-r_{ab}^{2}}  {4R_{a}R_{b}})} }
 \f]
 
 Where \f$ R_{a}, R_{b} \f$ are the Born radii of the atoms a and b.
 Note that the case where \f$ a == b \f$ is allowed and gives the self-energy of atom \f$ a \f$.
 However this case is handled using special optimised functions.
 
 The derivative of this function with respect to the position of one of the atoms, \f$ \mathbf{r_{a}} \f$, is
 \f[
 \frac{ \Delta G^{elec}_{ab}} {d \mathbf{r_{a}}} = \frac{ \Delta G^{elec}_{ab}} {d r_{ab}} \frac{ d r_{ab}}{d \mathbf{r_{a}}}
 + \frac{ \Delta G^{elec}_{ab}} {d R_{a}} \frac{ d R_{a}}{d \mathbf{r_{a}}} 
 + \frac{ \Delta G^{elec}_{ab}} {d R_{b}} \frac{ d R_{b}}{d \mathbf{r_{a}}} 
 \f]
 
 This formula can be obtain using the chain rule for partial derivatives. 
 The second and third terms are due to the fact that the Born radius of an atom depends on the positions of \e all atoms in the solute. 
 Each full term is a force vector.
 
 In the function names GBE stands for Generalized Born Energy.
 AdGBESeparationDerivative() gives the force vector for first term for both atoms.
 AdGBEBornRadiusDerivative() gives the first factor in the second and third terms which is a scalar.
 
 If a == b then this gives the self energy of the atom
 \f[
 \Delta G^{elec}_{a} = -\frac{\tau}{2} \frac{1}{4\pi \epsilon_{0}} \frac{q^{2}_{a}}{R_{a}}
 \f]
 This is usually calculated during the calculation of the atoms born radius so no function is provided for it here.
 
 The derivative of this w.r.t. the position of the atom is simply
 \f[
 \frac{ \Delta G^{elec}_{a}} {d \mathbf{r_{a}}} = \frac{\tau}{2}\frac{q_{a}^{2}}{R_{a}^{2}} \frac{ d R_{a}}{d \mathbf{r_{a}}}
 \f]
 Hence only the derivative of the born radius of the atom is needed.
 If this is known then AdGBESelfDerivative() returns the force vector.
 
 \defgroup GBFunctions GB Functions 
 \ingroup GBSWFunctions
 @{
 */

/**
Sets an internal variable equal to tau*estConstant
*/
void AdSetGeneralizedBornVariables(double tau, double estConstant);

/**
Calculates the contribution of the interaction between the two atoms given by \e interaction to the total electrostatic component of the solvation energy, 
\f$ \Delta G^{elec}_{ab} \f$.
The energy is added to the value in \e est_pot.
*/
void AdGeneralizedBornEnergy(ListElement* interaction, 
				    double** coordinates,
				    double* radii, 
				    double* est_pot);
				    
/**
 This gives the derivate of the born energy with respect to the separation between the two atoms.
 \f[
\frac{ \Delta G^{elec}_{ab}} {d r_{ab}} \frac{ d r_{ab}}{d \mathbf{r_{a}}}	
 \f]
 
 The resulting forces on the two atoms are equal in magnitude and opposite in direction.
 The force vectors are accumulated into the corresponding rows of the matrix \e forces.
  
 \note This derivative only exists when the interaction is between two different atoms.
 
 */
void AdGBESeparationDerivative(ListElement* interaction, 
				     double** coordinates,
				     double** forces,
				     double* radii, 
				     double* est_pot);
				     
/**
 Calculated the magnitude of the derivative of the GB energy with respect to the separation of the atoms.
 On return \e forceMagnitude contains the result.
 */
void AdGBESeparationDerivativeMagnitude(ListElement* interaction, 
					      double** coordinates,
					      double* radii, 
					      double* forceMagnitude);
					      
/**
 Calculates derivative of the Born energy with respect to the born radii, \f$ R_{a}, R_{b} \f$ of the atoms.
 
\f[
\frac{ \Delta G^{elec}_{ab}} {d R_{a}}, \frac{ \Delta G^{elec}_{ab}} {d R_{b}}
\f]

 coefficient1 is the derivate w.r.t \f$ R_{a} \f$ and coefficient2 the derivative w.r.t. \f$ R_{b} \f$. 
 \note This function is only for derivatives of the Born energy between two atoms, \f$ \Delta G^{elec}_{ab} \f$. 
 The self energy derivative is handled by AdGBESelfDerivative()
 */
void AdGBEBornRadiusDerivative(ListElement* interaction, 
				      double** coordinates,
				      double* radii, 
				      double *coefficient1,
				      double *coefficient2);

/**
AS AdGBEBornRadiusDerivative but only calculating one of the two terms
*/
void AdGBEBornRadiusCoefficient(int atomOne, int atomTwo, double** coordinates, 
		double* bornRadii, double* charges, double* value);

/**
Returns the solvation force acting on the atom i.e. the derivative of the atoms self-energy.
Note the derivative of the atoms born radius w.r.t. itself must have been previously calculated.
*/				     
void AdGBESelfDerivative(unsigned int atomIndex, 
		double bornRadius, 
		double charge,
		Vector3D* radiusDerivative,  
		double** forces);																	     									     				     
/** \@}**/

#endif
