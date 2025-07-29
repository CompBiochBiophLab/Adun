/*
 *  AdQuadratureFunctions.c
 *  Adun
 *
 *  Created by Michael Johnston on 13/03/2008.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "AdQuadratureFunctions.h"
#include <gsl/gsl_poly.h>
#include <gsl/gsl_sf_legendre.h>
#include <gsl/gsl_sort.h>
#include <stdlib.h>

/**
Function for generating 14 point Lebedev grid
*/
void AdGenerateLebedev14PointGrid(AdMatrix* buffer);

/**
Function for generating 38 point Lebedev grid.
The values for weights and other constants used were published in
the original lebedev papaer.
The weights of all the points sum to 1.
*/
void AdGenerateLebedev38PointGrid(AdMatrix* buffer);

/**
Generates 6 points with octhaedral symmetry, each with weight \e weight.
The points are given by all the possible permutation of (a,0,0) (where a can be positive or negative).
a is 1.0.
That is all points which are equal to (1,0,0) under octahedral symmetry.
Places the points in \e buffer, starting from \e index.
\e buffer must contain enough rows to hold all the points (this is not checked).
Returns the number of points added.
*/
int AdGenerateTypeOneOctehedralPoints(double weight, AdMatrix* buffer, int index);

/**
Generates 8 points with octhaedral symmetry, each with weight \e weight.
The points are given by all the possible permutations of (a,a,a) (where a can be positive or negative).
That is all points which are equal to (a,a,a) under octahedral symmetry.
a is 1/sqrt(3) e.g. (a,a,a) (-a,a,a) (a,-a,-a) etc....
Places the points in \e buffer, starting from \e index.
\e buffer must contain enough rows to hold all the points (this is not checked).
Returns the number of points added.
 */
int AdGenerateTypeThreeOctehedralPoints(double weight, AdMatrix* buffer, int index);


/**
Generates 24 points with octhaedral symmetry, each with weight \e v.
The points are given by all possible permutations of (a,b,0) (where a and b can be positive or negative).
That is all points which are equal to (a,b,0) under octahedral symmetry.
The value of \e a depends on the overall size of the lebedev grid being generated.
b is sqrt(1 - a*a).
Places the points in \e buffer, starting from \e index.
\e buffer must contain enough rows to hold all the points (this is not checked).
Returns the number of points added.
*/
int AdGenerateTypeFiveOctehedralPoints(double a, double v, AdMatrix* buffer, int index);

//Converted from C++ code from http://www.alglib.net/specialfunctions/polynomials/legendre.php
void AdGetLegendreCoefficients(unsigned int numberCoefficients, double*  coefficientsBuffer)
{
	int i, order;
	
	order = numberCoefficients - 1;
	for(i=0; i < order; i++)
		coefficientsBuffer[i] = 0;
		
	coefficientsBuffer[order] = 1;
	
	for(i = 1; i <= order; i++)
		coefficientsBuffer[order] = coefficientsBuffer[order]*(order+i)/2/i;
	
	for(i = 0; i <= order/2 - 1; i++)
		coefficientsBuffer[order-2*(i+1)] = -coefficientsBuffer[order-2*i]*(order-2*i)*(order - 2*i - 1)/2/(i+1)/(2*(order-i)-1);
}

double AdWeightForGaussLegendrePoint(double point, int order)
{
	double polyValue;
	
	//Taken from mathworld Legendre-Gauss page equation 14.
	polyValue = gsl_sf_legendre_Pl(order + 1, point);
	return 2*(1 - point*point)/((order + 1)*(order + 1)*polyValue*polyValue);
}

void AdGenerateGaussLegendrePoints(double start, double end, unsigned int points, double* pointsBuffer, double* weightsBuffer)
{
	unsigned int i, count;
	double halfDifference, halfSum;
	double* legendreCoefficients, *roots;
	gsl_poly_complex_workspace *workspace;

	//Get the coefficents for the lengendre polynomial of order \e points
	//A polynomial of order n has n+1 coefficents.
	legendreCoefficients = malloc((points+1)*sizeof(double));
	AdGetLegendreCoefficients(points+1, legendreCoefficients);
		
	//Get the roots
	workspace = gsl_poly_complex_workspace_alloc(points+1);
	//A nth order polynomial has n roots (possible complex)
	roots = malloc(points*2*sizeof(double));
	gsl_poly_complex_solve(legendreCoefficients, points+1, workspace, roots);
	
	//Load the roots into the pointsBuffer - Legendre polynomials only have real roots.
	//Calculate the weights as well
	for(count=0, i=0; i<points; i++)
		pointsBuffer[i] = roots[i*2];
	
	//Sort the points
	gsl_sort(pointsBuffer, 1, points);
	
	for(count=0, i=0; i<points; i++)
		weightsBuffer[i] = AdWeightForGaussLegendrePoint(pointsBuffer[i], points);	
	
	//The points are on the interval 0,1 - change to start - end
	halfDifference = 0.5*(end - start);
	halfSum = 0.5*(end + start);
	for(count=0, i=0; i<points; i++)
	{
		pointsBuffer[i] =  halfDifference*pointsBuffer[i] + halfSum;
		weightsBuffer[i] = weightsBuffer[i]*halfDifference;
	}
	
	free(roots);
	free(legendreCoefficients);
	gsl_poly_complex_workspace_free(workspace);
}


int AdGenerateLebedevGrid(AdMatrix* buffer)
{
	int errorValue = 0;
	int numberOfPoints;
	
	numberOfPoints = buffer->no_rows;
	
	//Only supports 14 or 38 points at the moment
	switch(numberOfPoints)
	{
		case 14:
			AdGenerateLebedev14PointGrid(buffer);
			break;
		case 38:
			AdGenerateLebedev38PointGrid(buffer);
			break;
		default:
			errorValue = 1;
	}
	
	return errorValue;
}

void AdGenerateLebedev14PointGrid(AdMatrix* buffer)
{
	double weight;
	
	//Generate six points
	weight = 0.6666666666666667E-1;
	AdGenerateTypeOneOctehedralPoints(weight, buffer, 0);
	
	//Generate 8 points
	weight = 0.7500000000000000E-1;
	AdGenerateTypeThreeOctehedralPoints(weight, buffer, 6); 
}

void AdGenerateLebedev38PointGrid(AdMatrix* buffer)
{
	double weight, a;

	//weight for 6 points
	weight = 0.9523809523809524E-2;
	//Generate 6 points
	AdGenerateTypeOneOctehedralPoints(weight, buffer, 0);

	//Weight for 8 points
	weight = 0.3214285714285714E-1;
	//Generate 8 points
	AdGenerateTypeThreeOctehedralPoints(weight, buffer, 6);
	
	//Generate 24 points
	a= 0.4597008433809831E+0;
	//Weight for 24 point grid.
	weight = 0.2857142857142857E-1;
	AdGenerateTypeFiveOctehedralPoints(a, weight, buffer, 14);
}

int AdGenerateTypeOneOctehedralPoints(double weight, AdMatrix* buffer, int index)
{
	int i;
	double a;
	
	a = 1.0;

	buffer->matrix[index][0] = a;
	buffer->matrix[index][1] = 0.0;
	buffer->matrix[index][2] = 0.0;
	buffer->matrix[index][3] = weight;
	
	i = 1;
	buffer->matrix[index+i][0] = -a;
	buffer->matrix[index+i][1] = 0.0;
	buffer->matrix[index+i][2] = 0.0;
	buffer->matrix[index+i][3] = weight;
	
	i = 2;
	buffer->matrix[index+i][0] = 0.0;
	buffer->matrix[index+i][1] = a;
	buffer->matrix[index+i][2] = 0.0;
	buffer->matrix[index+i][3] = weight;
	
	i = 3;
	buffer->matrix[index+i][0] = 0.0;
	buffer->matrix[index+i][1] = -a;
	buffer->matrix[index+i][2] = 0.0;
	buffer->matrix[index+i][3] = weight;
	
	i = 4;
	buffer->matrix[index+i][0] = 0.0;
	buffer->matrix[index+i][1] = 0.0;
	buffer->matrix[index+i][2] = a;
	buffer->matrix[index+i][3] = weight;
	
	i = 5;
	buffer->matrix[index+i][0] = 0.0;
	buffer->matrix[index+i][1] = 0.0;
	buffer->matrix[index+i][2] = -a;
	buffer->matrix[index+i][3] = weight;
	
	return 6;
}

int AdGenerateTypeThreeOctehedralPoints(double weight, AdMatrix* buffer, int index)
{
	int i;
	double a;

	a = 1/sqrt(3);
	
	buffer->matrix[index][0] = a;
	buffer->matrix[index][1] = a;
	buffer->matrix[index][2] = a;
	buffer->matrix[index][3] = weight;
	
	i = 1;
	buffer->matrix[index+i][0] = -a;
	buffer->matrix[index+i][1] = a;
	buffer->matrix[index+i][2] = a;
	buffer->matrix[index+i][3] = weight;

	i = 2;
	buffer->matrix[index+i][0] = a;
	buffer->matrix[index+i][1] = -a;
	buffer->matrix[index+i][2] = a;
	buffer->matrix[index+i][3] = weight;
	
	i = 3;
	buffer->matrix[index+i][0] = -a;
	buffer->matrix[index+i][1] = -a;
	buffer->matrix[index+i][2] = a;
	buffer->matrix[index+i][3] = weight;
	
	i = 4;
	buffer->matrix[index+i][0] = a;
	buffer->matrix[index+i][1] = a;
	buffer->matrix[index+i][2] = -a;
	buffer->matrix[index+i][3] = weight;

	i = 5;
	buffer->matrix[index+i][0] = -a;
	buffer->matrix[index+i][1] = a;
	buffer->matrix[index+i][2] = -a;
	buffer->matrix[index+i][3] = weight;
	
	i = 6;
	buffer->matrix[index+i][0] = a;
	buffer->matrix[index+i][1] = -a;
	buffer->matrix[index+i][2] = -a;
	buffer->matrix[index+i][3] = weight;
	
	i = 7;
	buffer->matrix[index+i][0] = -a;
	buffer->matrix[index+i][1] = -a;
	buffer->matrix[index+i][2] = -a;
	buffer->matrix[index+i][3] = weight;
	
	return 8;
}


int AdGenerateTypeFiveOctehedralPoints(double a, double v, AdMatrix* buffer, int index)
{
	double b;

	b = sqrt(1 - a*a); 

	//The last point in the Fortran version is the first
	//point here to save a lot of renumbering.
	buffer->matrix[index][0] =  0.0;
	buffer->matrix[index][1] = -b;
	buffer->matrix[index][2] = -a;
	buffer->matrix[index][3] =  v;
	
	buffer->matrix[index+1][0] =  a;
	buffer->matrix[index+1][1] =  b;
	buffer->matrix[index+1][2] =  0.0;
	buffer->matrix[index+1][3] =  v;
	
	buffer->matrix[index+2][0] = -a;
	buffer->matrix[index+2][1] =  b;
	buffer->matrix[index+2][2] =  0.0;
	buffer->matrix[index+2][3] =  v;
	
	buffer->matrix[index+3][0] =  a;
	buffer->matrix[index+3][1] = -b;
	buffer->matrix[index+3][2] =  0.0;
	buffer->matrix[index+3][3] =  v;
	
	buffer->matrix[index+4][0] = -a;
	buffer->matrix[index+4][1] = -b;
	buffer->matrix[index+4][2] =  0.0;
	buffer->matrix[index+4][3] =  v;
	
	buffer->matrix[index+5][0] =  b;
	buffer->matrix[index+5][1] =  a;
	buffer->matrix[index+5][2] =  0.0;
	buffer->matrix[index+5][3] =  v;
	
	buffer->matrix[index+6][0] = -b;
	buffer->matrix[index+6][1] =  a;
	buffer->matrix[index+6][2] =  0.0;
	buffer->matrix[index+6][3] =  v;
	
	buffer->matrix[index+7][0] =  b;
	buffer->matrix[index+7][1] = -a;
	buffer->matrix[index+7][2] =  0.0;
	buffer->matrix[index+7][3] =  v;
	
	buffer->matrix[index+8][0] = -b;
	buffer->matrix[index+8][1] = -a;
	buffer->matrix[index+8][2] =  0.0;
	buffer->matrix[index+8][3] =  v;
	
	buffer->matrix[index+9][0] =  a;
	buffer->matrix[index+9][1] =  0.0;
	buffer->matrix[index+9][2] =  b;
	buffer->matrix[index+9][3] =  v;
	
	buffer->matrix[index+10][0] = -a;
	buffer->matrix[index+10][1] =  0.0;
	buffer->matrix[index+10][2] =  b;
	buffer->matrix[index+10][3] =  v;
	
	buffer->matrix[index+11][0] =  a;
	buffer->matrix[index+11][1] =  0.0;
	buffer->matrix[index+11][2] = -b;
	buffer->matrix[index+11][3] =  v;
	
	buffer->matrix[index+12][0] = -a;
	buffer->matrix[index+12][1] =  0.0;
	buffer->matrix[index+12][2] = -b;
	buffer->matrix[index+12][3] =  v;
	
	buffer->matrix[index+13][0] =  b;
	buffer->matrix[index+13][1] =  0.0;
	buffer->matrix[index+13][2] =  a;
	buffer->matrix[index+13][3] =  v;
	
	buffer->matrix[index+14][0] = -b;
	buffer->matrix[index+14][1] =  0.0;
	buffer->matrix[index+14][2] =  a;
	buffer->matrix[index+14][3] =  v;
	
	buffer->matrix[index+15][0] =  b;
	buffer->matrix[index+15][1] =  0.0;
	buffer->matrix[index+15][2] = -a;
	buffer->matrix[index+15][3] =  v;
	
	buffer->matrix[index+16][0] = -b;
	buffer->matrix[index+16][1] =  0.0;
	buffer->matrix[index+16][2] = -a;
	buffer->matrix[index+16][3] =  v;
	
	buffer->matrix[index+17][0] =  0.0;
	buffer->matrix[index+17][1] =  a;
	buffer->matrix[index+17][2] =  b;
	buffer->matrix[index+17][3] =  v;
	
	buffer->matrix[index+18][0] =  0.0;
	buffer->matrix[index+18][1] = -a;
	buffer->matrix[index+18][2] =  b;
	buffer->matrix[index+18][3] =  v;
	
	buffer->matrix[index+19][0] =  0.0;
	buffer->matrix[index+19][1] =  a;
	buffer->matrix[index+19][2] = -b;
	buffer->matrix[index+19][3] =  v;
	
	buffer->matrix[index+20][0] =  0.0;
	buffer->matrix[index+20][1] = -a;
	buffer->matrix[index+20][2] = -b;
	buffer->matrix[index+20][3] =  v;
	
	buffer->matrix[index+21][0] =  0.0;
	buffer->matrix[index+21][1] =  b;
	buffer->matrix[index+21][2] =  a;
	buffer->matrix[index+21][3] =  v;
	
	buffer->matrix[index+22][0] =  0.0;
	buffer->matrix[index+22][1] = -b;
	buffer->matrix[index+22][2] =  a;
	buffer->matrix[index+22][3] =  v;
	
	buffer->matrix[index+23][0] =  0.0;
	buffer->matrix[index+23][1] =  b;
	buffer->matrix[index+23][2] = -a;
	buffer->matrix[index+23][3] =  v;
	
	return 24;
}

