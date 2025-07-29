/*
 Project: AdunKernel
 
 Copyright (C) 2008 Michael Johnston & Jordi Villa-Freixa
 
 Author: Michael Johnston
 
 Created: 11/07/2008 by michael johnston
 
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

#ifndef _ADMATRIXSTRUCTURECODER_H_
#define _ADMATRIXSTRUCTURECODER_H_

#include <gsl/gsl_matrix.h>
#include <Foundation/Foundation.h>
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunMemoryManager.h"

/**
 Classes who want to have properties which are AdMatrix or gsl_matrix structures can inherit from this class.
 This class gives the ability to use key-value coding with such properties using AdDataMatrix instances. 
 That is instead of having to wrap these structure in NSValue objects AdDataMatrix objects can be sent and returned.
 This is importance in scripting since structures can't be created at all in such environments.
 
 
 For example an object has a property called \e coordinates which is an AdMatrix structure.
 It has a getter method, "coordinates" and a setter method "setCoordinates:".
 If you inherit from this class this method can be called using
 
 \code
 
 matrix = [AdDataMatrix new];
 
 //put some stuff in matrix
 
 [object setValue: matrix forKey: @"coordinates"];
 
 \endcode
 
 similarly
 
 \code
 
 matrix = [object valueForKey: @"coordinates"] 
 
 \endcode
 
 returns an AdDataMatrix object.
 
 Essentially it adds AdMatrix and gsl_matrix as supported structures in key-value coding.
 \ingroup Inter
 */
@interface AdMatrixStructureCoder: NSObject
@end

#endif
