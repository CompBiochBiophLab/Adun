/*
 Project: Adun
 
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

#ifndef QUADRATUREFUNCTIONS
#define QUADRATUREFUNCTIONS

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <Base/AdVector.h>
#include <Base/AdMatrix.h>

/**
Functions for generating integration points using different quadratures.
\defgroup QuadratureFunctions Quadrature
\ingroup Functions
@{
*/

/**
Returns the coeffiecents for the legendre polynomial of order (numberCoefficients - 1).
The coefficients are placed in \e coefficientsBuffer which must have storage for \e numberCoefficients.
*/
void AdGetLegendreCoefficients(unsigned int numberCoefficients, double*  coefficientsBuffer);

/**
Returns the weight for \e point which was generated from a legendre polynomial of order \e order.
*/
double AdWeightForGaussLegendrePoint(double point, int order);

/**
Generates \e points coordinates and weights by gauss-legendre quadrature for evaluating an integral over the range \e start - \e end.
*/
void AdGenerateGaussLegendrePoints(double start, double end, unsigned int points, double* pointsBuffer, double* weightsBuffer);

/**
The Lebedev quadrature returns the optimal coordinates for integrating a function over a sphere using \e n points.
For example if \e n is 14 this function returns a grid containing the 14 optimally placed spherical points for integrating
the function.
However the Lebedev quadrature is limited in that it can only generate grids with defined numbers of points 

- 6, 14, 26, 38, 50 etc.

Strictly each grid is optimal for a polynomial of certain order. 
However at the moment I cannot make sense of the rules presented in the Fortan documentation.

The function generates a lebedev grid of size, buffer->no_rows. 
At the moment only 14 point and 38 point grids are supported.
If \e size is not 14 or 38 this method returns an error code of 1.
Otherwise return 0.

*/
int AdGenerateLebedevGrid(AdMatrix* buffer);

/** \@}**/

#endif

