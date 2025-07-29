#include <Base/AdBaseFunctions.h>

double AdCalculateKineticEnergy(DoubleMatrix* velocities, double* masses)
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

