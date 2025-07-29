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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>


#include "MTAtom.h"
#include "MTAtomFactory.h"
#include "MTCoordinates.h"
#include "MTMatrix53.h"

static char inferElementFromAtomName (char *name);

static char *atom_element_names[] = {
	" ", "H", "He", "Li", "Be", "B", "C", "N", "O", "F", "Ne", "Na", "Mg", "Al", "Si", "P", "S", "Cl", "Ar", "K", "Ca", "Sc", "Ti", "V", "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn", "Ga", "Ge", "As", "Se", "Br", "Kr", "Rb", "Sr", "Y", "Zr", "Nb", "Mo", "Tc", "Ru", "Rh", "Pd", "Ag", "Cd", "In", "Sn", "Sb", "Te", "I", "Xe", "Cs", "Ba", 
	"57","58","59","60","61","62","63","64","65","66","67","68","69","70",
	"Lu", "Hf", "Ta", "W", "Re", "Os", "Ir", "Pt", "Au", "Hg", "Tl", "Pb", "Bi", "Po", "At", "Rn", NULL 
};



@implementation MTAtom


-(id)init	//@nodoc
{
    self = [super init];
    bonds=nil;
    name=nil;
    number=0;
    temperature=0.0f;
    element=ELEMENT_ID_Unknown;
    charge=(signed char)0;
    return self;
}


-(void)dealloc	//@nodoc
{
	//NSLog(@"Atom__dealloc");
        [self dropAllBonds];
	if (name != nil)
	{
    		RELEASE(name);
	}
	[super dealloc];
}


/*
 *   returns atom's serial number
 */
-(NSNumber*)number
{
	return [NSNumber numberWithInt: number];
}


/*
 *   returns atom's name
 */
-(NSString*)name
{
	return name;
}


/*
 *   returns string of atom's number, name and coordinates
 */
-(NSString*)description
{
	return [NSString stringWithFormat:@"Atom:%d %@",number,name];
}


/*
 *   return element id of atom
 */
-(enum element_id)element
{
	return element;
}


/*
 *   return element name of atom
 */
-(NSString*)elementName
{
	if (element < 0)
	{
		return @" ";
	} else {
		return [NSString stringWithCString:(atom_element_names[element])];
	}
}


/*
 *   returns the atom's assigned temperature factor
 */
-(float)temperature
{
	return temperature;
}


/*
 *
 */
-(int)charge
{
	return (int)charge;
}


/*
 *   add bond from atm2 to this atom
 */
-(void)bondTo:(MTAtom*)atm2
{
	if (!bonds)
	{
                bonds = RETAIN([NSMutableArray new]);
	}
        if ([bonds containsObject: atm2])
	{ /* dont add twice */
		return;
	}
        [bonds addObject: atm2];
        [atm2 bondTo: self];
}


/*
 *   returns enumerator over all bonded atoms
 */
-(NSEnumerator*)allBondedAtoms
{
	if (!bonds)
	{
		return nil;
	}
        return [bonds objectEnumerator];
}


/*
 *   remove a bond from atm2 to this atom
 */
-(void)dropBondTo:(MTAtom*)atm2
{
        if ([bonds containsObject: atm2])
	{
                [bonds removeObject: atm2];
		[atm2 dropBondTo: self];
	}
}


/*
 *   remove all bonds from this atom
 */
-(void)dropAllBonds
{
	if (bonds) {
                int idx, count;
                count = [bonds count];
		MTAtom *atm2;
		for (idx=0; idx<count; idx++)
		{
                        atm2 = [bonds objectAtIndex: idx];
			[self dropBondTo: atm2];
                        idx--; count--;
		}
		RELEASE(bonds);
		bonds = nil;
	}
}


/*
 *   set serial number to the new one
 */
-(id)setNumber: (int)serial
{
	number = serial;
	return self;
}


/*
 *   set the charge of the atom
 */
-(id)setCharge: (int)chrg
{
	charge = (signed char)chrg;
	//printf("Atom_setCharge: %d:%d\n",(int)chrg,(int)charge);
	return self;
}


/*
 *   set the temperature of the atom
 */
-(id)setTemperature: (float)p_temperature
{
	temperature = p_temperature;
	return self;
}

/*
 *   set the name of the atom
 */
-(id)setName: (char*)p_name
{
	if (element==ELEMENT_ID_Unknown)
	{
		[self setElement: inferElementFromAtomName (p_name)];
	};
	/* pad name */
	unsigned int len=strlen(p_name);
	unsigned int i=0;
	while (p_name[i]==' ')
	{
		i++;
		if (i>=(len-1))
		{
			break;
		}
	}
	unsigned int j=len-1;
	while (p_name[j] == ' ')
	{
		j--;
		if (j==i)
		{
			break;
		}
	}
	p_name[j+1]='\0';
	p_name += i;
	if (name)
	{
		RELEASE(name);
	}
	name = RETAIN([NSString stringWithCString: p_name]);

	return self;
}
	

/*
 *   set the element id of the atom
 */
-(id)setElement: (enum element_id)p_element
{
	element = p_element;
	return self;
}
-(id)setElementWithName: (char*)p_element
{
	char *ename;
	int idx=0;
	if (!p_element)
	{
		return self;
	}
	int len = strlen(p_element);
	if (len>2)
	{
		return self;
	}
	/* make second character lowercase */
	if (len==2 && p_element[1]<=90 && p_element[1]>=65)
	{
		p_element[1]=p_element[1]+32;
	}
	while ((ename = atom_element_names[idx])) 
	{
		if (ename[0]==p_element[0] && ename[1]==p_element[1])
		{
			return [self setElement:idx];
		}
		idx++;
	}
	NSLog(@"Unknown element name: %s",p_element);
	return self;
}


/*
 *   make copy of an atom
 */
-(id)copy
{
	MTAtom *atom = [[self class] new];
	[atom setX:[self x] Y:[self y] Z:[self z]];
	atom->number = number;
	atom->temperature = temperature;
	atom->charge = charge;
	atom->element = element;
	atom->name = RETAIN(name);
	return AUTORELEASE(atom);
}


/*
 *   creation of an atom with number, name and explicitly setting coordinates
 */
+(MTAtom*)atomWithNumber:(unsigned int)num name:(char*)nm X:(double)x Y:(double)y Z:(double)z B:(float)b
{
	MTAtom *atom = [MTAtomFactory newInstance];
	[atom setX:x Y:y Z:z];
	atom->temperature = b;
	[atom setNumber: num];
	
	/* before any clean up we do the element inference from the name */
	/* name = Element[2chars,right justified],remoteness[1char],branch#[1digit] */
	[atom setElement: inferElementFromAtomName (nm)];
	

	/* pad name */
	/*
	unsigned int len=strlen(nm);
	unsigned int i=0;
	while (nm[i]==' ')
	{
		i++;
		if (i>=(len-1))
		{
			break;
		}
	}
	unsigned int j=len-1;
	while (nm[j] == ' ')
	{
		j--;
		if (j==i)
		{
			break;
		}
	}
	nm[j+1]='\0';
	nm += i;
	atom->name = RETAIN([NSString stringWithCString: nm]);
	*/
	[atom setName: nm];
	
	//printf("Atom_atomWithNumber:%d name:%s X:%1.1f Y:%1.1f Z:%1.1f\n",num,nm,x,y,z);
	return atom;
}


char inferElementFromAtomName (char *name)
{
	switch (name[0])
	{
	case 'C':
		switch (name[1])
		{
		case 'U':
			return ELEMENT_ID_Cu;
		case 'D':
			return ELEMENT_ID_Cd;
		case 'A':
			return ELEMENT_ID_Ca;
		case 'O':
			return ELEMENT_ID_Co;
		case 'R':
			return ELEMENT_ID_Cr;
		}
		break;
	case 'O':
		if (name[1]=='H')
			return ELEMENT_ID_O;
		break;
	case 'N':
		if (name[1]=='I')
			return ELEMENT_ID_Ni;
		if (name[1]=='A')
			return ELEMENT_ID_Na;
		break;
	case 'P':
		if (name[1]=='B')
			return ELEMENT_ID_Pb;
		break;
	case 'S':
		if (name[1]=='N')
			return ELEMENT_ID_Sn;
		if (name[1]=='E')
			return ELEMENT_ID_Se;
		break;
	case 'M':
		if (name[1]=='G')
			return ELEMENT_ID_Mg;
		if (name[1]=='N')
			return ELEMENT_ID_Mn;
		break;
	case 'H':
		if (name[1]=='G')
			return ELEMENT_ID_Hg;
		return ELEMENT_ID_H;
		break;
	case 'Z':
		if (name[1]=='N')
			return ELEMENT_ID_Zn;
		break;
	case ' ':
		switch (name[1])
		{
		case 'H':
			return ELEMENT_ID_H;
		case 'O':
			return ELEMENT_ID_O;
		case 'C':
			return ELEMENT_ID_C;
		case 'N':
			return ELEMENT_ID_N;
		case 'P':
			return ELEMENT_ID_P;
		case 'F':
			return ELEMENT_ID_F;
		case 'K':
			return ELEMENT_ID_K;
		case 'S':
			return ELEMENT_ID_S;
		}
		break;
	default:
		if (name[1] == 'H')
			return ELEMENT_ID_H;
	}
	return ELEMENT_ID_Unknown;
}

@end

