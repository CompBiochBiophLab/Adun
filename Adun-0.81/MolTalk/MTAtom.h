/* Copyright 2003-2006  Alexander V. Diemand

    This file is part of MolTalk.

    MolTalk is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    MolTalk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with MolTalk; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
 */
 
/* vim: set filetype=objc: */


#ifndef MTATOM_H
#define MTATOM_H


#include <Foundation/Foundation.h>

#include "MTCoordinates.h"

enum element_id { 
	ELEMENT_ID_Unknown = 0,
	ELEMENT_ID_H  =  1,
	ELEMENT_ID_He =  2,

	ELEMENT_ID_Li =  3,
	ELEMENT_ID_Be =  4,
	ELEMENT_ID_B  =  5,
	ELEMENT_ID_C  =  6,
	ELEMENT_ID_N  =  7,
	ELEMENT_ID_O  =  8,
	ELEMENT_ID_F  =  9,

	ELEMENT_ID_Ne = 10,
	ELEMENT_ID_Na = 11,
	ELEMENT_ID_Mg = 12,
	ELEMENT_ID_Al = 13,
	ELEMENT_ID_Si = 14,
	ELEMENT_ID_P  = 15,
	ELEMENT_ID_S  = 16,
	ELEMENT_ID_Cl = 17,
	ELEMENT_ID_Ar = 18,

	ELEMENT_ID_K  = 19,
	ELEMENT_ID_Ca = 20,
	ELEMENT_ID_Sc = 21,
	ELEMENT_ID_Ti = 22,
	ELEMENT_ID_V  = 23,
	ELEMENT_ID_Cr = 24,
	ELEMENT_ID_Mn = 25,
	ELEMENT_ID_Fe = 26,
	ELEMENT_ID_Co = 27,
	ELEMENT_ID_Ni = 28,
	ELEMENT_ID_Cu = 29,
	ELEMENT_ID_Zn = 30,
	ELEMENT_ID_Ga = 31,
	ELEMENT_ID_Ge = 32,
	ELEMENT_ID_As = 33,
	ELEMENT_ID_Se = 34,
	ELEMENT_ID_Br = 35,
	ELEMENT_ID_Kr = 36,

	ELEMENT_ID_Rb = 37,
	ELEMENT_ID_Sr = 38,
	ELEMENT_ID_Y  = 39,
	ELEMENT_ID_Zr = 40,
	ELEMENT_ID_Nb = 41,
	ELEMENT_ID_Mo = 42,
	ELEMENT_ID_Tc = 43,
	ELEMENT_ID_Ru = 44,
	ELEMENT_ID_Rh = 45,
	ELEMENT_ID_Pd = 46,
	ELEMENT_ID_Ag = 47,
	ELEMENT_ID_Cd = 48,
	ELEMENT_ID_In = 49,
	ELEMENT_ID_Sn = 50,
	ELEMENT_ID_Sb = 51,
	ELEMENT_ID_Te = 52,
	ELEMENT_ID_I  = 53,
	ELEMENT_ID_Xe = 54,

	ELEMENT_ID_Cs = 55,
	ELEMENT_ID_Ba = 56,
	ELEMENT_ID_Lu = 71,
	ELEMENT_ID_Hf = 72,
	ELEMENT_ID_Ta = 73,
	ELEMENT_ID_W  = 74,
	ELEMENT_ID_Re = 75,
	ELEMENT_ID_Os = 76,
	ELEMENT_ID_Ir = 77,
	ELEMENT_ID_Pt = 78,
	ELEMENT_ID_Au = 79,
	ELEMENT_ID_Hg = 80,
	ELEMENT_ID_Tl = 81,
	ELEMENT_ID_Pb = 82,
	ELEMENT_ID_Bi = 83,
	ELEMENT_ID_Po = 84,
	ELEMENT_ID_At = 85,
	ELEMENT_ID_Rn = 86
};



/*
 *   @MTAtom represents the atomic element in a @MTStructure
 *
 */
@interface MTAtom : MTCoordinates
{
        @protected
	unsigned int number;
	NSString *name;
	float temperature;
	NSMutableArray *bonds;
	enum element_id element;
	signed char charge;
}

/*
 *   readonly access
 */
-(NSNumber*)number;
-(NSString*)name;
-(enum element_id)element;
-(float)temperature;
-(int)charge;
-(NSString*)elementName;


/*
 *   bonding
 */
-(void)bondTo:(MTAtom*)atm2;
-(NSEnumerator*)allBondedAtoms;
-(void)dropBondTo:(MTAtom*)atm2;
-(void)dropAllBonds;

/*
 *   setters
 */
-(id)setName: (char*)name;
-(id)setTemperature: (float)temperature;
-(id)setNumber: (int)serial;
-(id)setCharge: (int)chrg;
-(id)setElement: (enum element_id)eid;
-(id)setElementWithName: (char*)ename;

/*
 *   creation
 */
+(MTAtom*)atomWithNumber:(unsigned int)num name:(char*)nm X:(double)x Y:(double)y Z:(double)z B:(float)b;
-(id)copy;


@end

#endif /* MTATOM_H */

