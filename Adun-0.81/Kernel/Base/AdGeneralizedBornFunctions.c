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

#include "AdGeneralizedBornFunctions.h"

static double electrostaticConstant;


void AdSetGeneralizedBornVariables(double tau, double estConstant)
{
	electrostaticConstant = 0.5*estConstant*tau;
}

void AdGeneralizedBornEnergy(ListElement* interaction, 
					    double** coordinates,
					    double* radii, 
					    double* est_pot)
{					    
	int atomOne, atomTwo;
	double exponent, squaredSeparation, chargeProduct;
	double radiusOne, radiusTwo, numerator;
	Vector3D separation_s;
	
	atomOne = interaction->bond[0];
	atomTwo = interaction->bond[1];
	chargeProduct = interaction->params[2];
	
	//calculate seperation vector (r1 - r2)
	*(separation_s.vector + 0) = coordinates[atomOne][0] - coordinates[atomTwo][0];
	*(separation_s.vector + 1) = coordinates[atomOne][1] - coordinates[atomTwo][1];
	*(separation_s.vector + 2) = coordinates[atomOne][2] - coordinates[atomTwo][2];
	
	//calculate the interatomic distance
	Ad3DVectorLength(&separation_s);
	
	radiusOne = radii[atomOne];
	radiusTwo = radii[atomTwo];
	
	squaredSeparation = separation_s.length*separation_s.length;
	numerator =  -electrostaticConstant*chargeProduct;
	exponent = exp(-squaredSeparation/(4*radiusOne*radiusTwo));
	
	*est_pot += numerator/sqrt(squaredSeparation + radiusOne*radiusTwo*exponent);
}

/*
Returns the magnitude of the derivative of the GB energy with respect to the separation of the atoms.
*/
inline void AdGBESeparationDerivativeMagnitude(ListElement* interaction, 
				     double** coordinates,
				     double* radii, 
				     double* forceMagnitude)
{	
	int atomOne, atomTwo;
	double exponent, squaredSeparation, chargeProduct;
	double radiusOne, radiusTwo;
	double numerator, denominator, preFactor;
	Vector3D separation_s;
			     
	atomOne = interaction->bond[0];
	atomTwo = interaction->bond[1];
	chargeProduct = interaction->params[2];
	
	//calculate seperation vector (r1 - r2)
	*(separation_s.vector + 0) = coordinates[atomOne][0] - coordinates[atomTwo][0];
	*(separation_s.vector + 1) = coordinates[atomOne][1] - coordinates[atomTwo][1];
	*(separation_s.vector + 2) = coordinates[atomOne][2] - coordinates[atomTwo][2];
		
	//Use the current length given by the interaction struct
	separation_s.length = interaction->length;
		
	radiusOne = radii[atomOne];
	radiusTwo = radii[atomTwo];
	
	squaredSeparation = separation_s.length*separation_s.length;
	preFactor =  -0.5*electrostaticConstant*chargeProduct;
	
	//The value of the exponent in the derivative
	exponent = squaredSeparation/(4*radiusOne*radiusTwo);
	exponent = exp(-exponent);
	
	numerator = preFactor*exponent;
	denominator = pow((squaredSeparation + exponent), 1.5);
	
	*forceMagnitude = numerator/denominator;	
}


/*
This gives the derivate of the born energy with respect to the separation between the two atoms.
The resulting forces on the two atoms are equal in magnitude and opposite in direction.
The force vectors are accumulated into the corresponding rows of the matrix \e forces.

\param cutoff If the separation is greater than cutoff the calculation is aborted.
This parameter is an optimisation device which ensures that only
interactions within a certain distance are evaluated while keeping the calculations to a minimum.

\param flag Another optimisation device. If \e flag is zero the distance between the two
atoms is calculated as normal. Otherwise the value of the length memeber of the \e interaction
structure is used. This saves calculating length when it has been previously calculated for 
\e interaction as part of a standard coloumb/LJ calculation.

\note Due to the use of \e cutoff this function does not used
AdGBSeparationDerivativeMagnitude() to calculate the magnitude.
This is because, if a cutoff is set, the calculation can be stoped
before most of the calculations in AdGBSeparationDerivativeMagnitude() would 
be performed.
*/
void AdGBESeparationDerivative(ListElement* interaction, 
				    double** coordinates,
				    double** forces,
				    double* radii, 
				    double* est_pot)
{				    	
	int atomOne, atomTwo;
	double exponent, squaredSeparation, chargeProduct;
	double radiusOne, radiusTwo;
	double numerator, denominator, forceMagnitude, preFactor;
	Vector3D separation_s;
	
	atomOne = interaction->bond[0];
	atomTwo = interaction->bond[1];
	chargeProduct = interaction->params[2];
	
	//calculate seperation vector (r2 - r1)
	//This is the vector from atom one to atom two
	*(separation_s.vector + 0) = coordinates[atomTwo][0] - coordinates[atomOne][0];
	*(separation_s.vector + 1) = coordinates[atomTwo][1] - coordinates[atomOne][1];
	*(separation_s.vector + 2) = coordinates[atomTwo][2] - coordinates[atomOne][2];
	
	separation_s.length = interaction->length;
	
	//Calculate dG/d|r|
	//where |r| is the separation length.
	//In the following a factor of |r| is not included.
	//Since it cancels when dG/d|r| is multiplied by d|r|/dr.
	
	radiusOne = radii[atomOne];
	radiusTwo = radii[atomTwo];
	
	squaredSeparation = separation_s.length*separation_s.length;

	//The value of the exponent in the derivative
	exponent = squaredSeparation/(4*radiusOne*radiusTwo);
	preFactor =  0.5*electrostaticConstant*chargeProduct;
	exponent = exp(-exponent);
	denominator = sqrt(squaredSeparation + radiusOne*radiusTwo*exponent);
	
	numerator = preFactor*(4 - exponent);
	
	*est_pot += -2*preFactor/denominator;
	
	denominator = pow(denominator, 3);
	
	//The force is the negative of the gradient.
	//Multiply the above by minus 1 here.
	forceMagnitude = -1*numerator/denominator;

	//Finally the derivative of the separation
	//The derivative of the vector (r2 - r1) w.r.t. atomOne
	//is -1*(r2 - r1)/|r2 - r1|
	//The factor |r2 - r1| cancels with a factor in the derivative
	//of dG/d|r|. 
	//Therefore we dont calculate the unit vector.
	
	//The overall effect is as follows for (+,-)
	//The derivatives of the separation vector w.r.t each atoms position point
	//away from each other.
	//dG/d|r| is negative so this switches the vectors so they point towards each other.
	//Multiplied by the -1 for the force, becomes overall repulsion again.
	//That is for (+,-) pair the screening force opposes the attractive coulomb force.
	//The screening potential becomes lower as the forces separate.
	//The coulomb potential becomes lower (more negative) as the forces approach.
	
	*(separation_s.vector + 0) *= forceMagnitude;
	*(separation_s.vector + 1) *= forceMagnitude;
	*(separation_s.vector + 2) *= forceMagnitude;
	
	forces[atomOne][0] -= *(separation_s.vector + 0);
	forces[atomOne][1] -= *(separation_s.vector + 1);
	forces[atomOne][2] -= *(separation_s.vector + 2);
	
	forces[atomTwo][0] += *(separation_s.vector + 0);
	forces[atomTwo][1] += *(separation_s.vector + 1);
	forces[atomTwo][2] += *(separation_s.vector + 2);
}

/*
Calculates derivative of the Born energy with respect to the born radii, R_a & R_b of the atoms.
On return the 2-element array \e results contains the derivatives.
The first element is the derivate w.r.t R_a and the second the derivative w.r.t. R_b. 
*/

void AdGBEBornRadiusDerivative(ListElement* interaction, 
				     double** coordinates,
				     double* radii,
				     double *coefficient1,
				     double *coefficient2)
{				     
	
	int atomOne, atomTwo;
	double exponent, squaredSeparation, chargeProduct;
	double radiusOne, radiusTwo;
	double numerator, denominator, forceMagnitude, preFactor, f;
	Vector3D separation_s;
	
	atomOne = interaction->bond[0];
	atomTwo = interaction->bond[1];
	chargeProduct = interaction->params[2];
	
	//calculate seperation vector (r1 - r2)
	*(separation_s.vector + 0) = coordinates[atomOne][0] - coordinates[atomTwo][0];
	*(separation_s.vector + 1) = coordinates[atomOne][1] - coordinates[atomTwo][1];
	*(separation_s.vector + 2) = coordinates[atomOne][2] - coordinates[atomTwo][2];
		
	//Use the current length given by the interaction struct
	separation_s.length = interaction->length;
	
	radiusOne = radii[atomOne];
	radiusTwo = radii[atomTwo];
	
	squaredSeparation = separation_s.length*separation_s.length;
	preFactor =  electrostaticConstant*chargeProduct;
	
	//The value of the exponent in the derivative
	exponent = squaredSeparation/(4*radiusOne*radiusTwo);
	exponent = exp(-exponent);
	
	numerator = preFactor*exponent;
	denominator = pow((squaredSeparation + exponent), 1.5);
	f = numerator/denominator;
	
	//The first atom term
	*coefficient1 = f*(radiusTwo + squaredSeparation/(4*radiusOne));
	//The second atom term
	*coefficient2 = f*(radiusOne + squaredSeparation/(4*radiusTwo));
}

void AdGBEBornRadiusCoefficient(int atomOne, int atomTwo, double** coordinates, double* radii, double* charges, double* value)
{				     
	double exponent, squaredSeparation, chargeProduct;
	double radiusOne, radiusTwo;
	double numerator, denominator, forceMagnitude, preFactor, f;
	Vector3D separation_s;
	
	chargeProduct = charges[atomOne]*charges[atomTwo];
	
	//calculate seperation vector (r1 - r2)
	*(separation_s.vector + 0) = coordinates[atomOne][0] - coordinates[atomTwo][0];
	*(separation_s.vector + 1) = coordinates[atomOne][1] - coordinates[atomTwo][1];
	*(separation_s.vector + 2) = coordinates[atomOne][2] - coordinates[atomTwo][2];
	
	Ad3DVectorLengthSquared(&separation_s);
	squaredSeparation = separation_s.length;
	
	radiusOne = radii[atomOne];
	radiusTwo = radii[atomTwo];
	
	preFactor =  electrostaticConstant*chargeProduct;
	
	//The value of the exponent in the derivative
	exponent = squaredSeparation/(4*radiusOne*radiusTwo);
	exponent = exp(-exponent);
	
	numerator = preFactor*exponent;
	denominator = sqrt(squaredSeparation + exponent);
	denominator = denominator*denominator*denominator;
	f = numerator/denominator;
	
	//The first atom term
	*value = f*(radiusTwo + squaredSeparation/(4*radiusOne));
}

/*
 Returns the solvation force acting on the atom i.e. the derivative of the atoms self-energy.
 Note the derivative of the atoms born radius w.r.t. itself must have been previously calculated.
 */				     
void AdGBESelfDerivative(unsigned int atomIndex, 
					  double bornRadius, 
					  double charge, 
					  Vector3D* radiusDerivative,  
					  double** forces)
{
	double factor;
	
	factor = electrostaticConstant*charge*charge/(bornRadius*bornRadius);
	
	//Update the forces
	forces[atomIndex][0] += factor*radiusDerivative->vector[0];	
	forces[atomIndex][1] += factor*radiusDerivative->vector[1];
	forces[atomIndex][2] += factor*radiusDerivative->vector[2];
}

