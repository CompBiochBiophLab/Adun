#ifndef _ADBASEFUNCTIONS_
#define _ADBASEFUNCTIONS_

#include <Base/AdMatrix.h>

#ifdef __GNUC__

/**
Calculates the kinetic energy of a set of particles.
\param velocities A DoubleMatrix with one row for each particle. Each row has three elements
which are the particles velocity.
\param masses An array of doubles. The length is assumed to be the same as the number of rows in \e velocities.
Each element of \e masses must be the mass of the particle in the corresponding row in velcocities.
*/
extern inline double AdCalculateKineticEnergy(DoubleMatrix* velocities, double* masses)
{
	register int i, j;
	double *vhold;
	double **matrix;
	double en, enhold;
	
	matrix = velocities->matrix;
	for(en =0, i=0; i<velocities->no_rows; i++)
	{	
		vhold = matrix[i];
		for(enhold = 0,j=0; j< 3; j++)
			enhold += *(vhold + j)* *(vhold + j);
		
		en += enhold*masses[i];
	}
	en = en*0.5;
	
	return en;
}

#else

double AdCalculateKineticEnergy(DoubleMatrix* velocities, double* masses);

#endif

#endif
