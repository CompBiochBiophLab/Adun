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

#include "MTResidue.h"
#include "MTResidueFactory.h"
#include "privateMTResidue.h"
#include "MTChain.h"
#include "MTAtom.h"
#include "MTMatrix44.h"


@implementation MTResidue

static NSDictionary *translate3LetterTo1Letter=nil;

static Class residueKlass = nil;


+(void)initialize	//@nodoc
{
	if (residueKlass == nil)
	{
		residueKlass = [MTResidue class];
	}
	if (self == residueKlass)
	{
		if (!translate3LetterTo1Letter)
		{
			translate3LetterTo1Letter = [NSDictionary dictionaryWithObjectsAndKeys:
				@"A",@"ALA", @"R",@"ARG", @"N",@"ASN", @"D",@"ASP", @"C",@"CYS",
				@"E",@"GLU", @"Q",@"GLN", @"G",@"GLY", @"H",@"HIS", @"I",@"ILE",
				@"L",@"LEU", @"K",@"LYS", @"M",@"MET", @"F",@"PHE", @"P",@"PRO",
				@"S",@"SER", @"T",@"THR", @"W",@"TRP", @"Y",@"TYR", @"V",@"VAL", 
				@"M",@"MSE",
				@"A",@"  A", @"A",@" +A", @"C",@"  C", @"C",@" +C",
				@"G",@"  G", @"G",@" +G", @"T",@"  T", @"T",@" +T", 
				@"U",@"  U", @"U",@" +U", nil];
			RETAIN(translate3LetterTo1Letter);
		}
	}
}


-(id)init	//@nodoc
{
	self = [super init];
	atomarr = RETAIN([NSMutableArray arrayWithCapacity:12]);
	name = nil;
	//number = [NSNumber numberWithInt: -1 ];
	number = nil;
	subcode = 32; /* per default */
	verified = NO;
	modname = nil;
	moddesc = nil;
	segid = nil;
	seqnum = -1;
	return self;
}


-(void)dealloc	//@nodoc
{
	//printf("Residue_dealloc %@\n",self);
	if (name)
	{
		RELEASE(name);
	}
	if (number)
	{
		RELEASE(number);
	}
	if (atomarr)
	{
		int i;
		for (i=0; i<[atomarr count]; i++)
		{
			[[atomarr objectAtIndex:i] dropAllBonds];
		}
		[atomarr removeAllObjects];
		RELEASE(atomarr);
	}
	[super dealloc];
}


/*
 *
 */
-(id)copy
{
	MTResidue *newres = [MTResidueFactory newResidueWithNumber: [number intValue] subcode: subcode name: [name cString]];
	NSEnumerator *allatm = [self allAtoms];
	MTAtom *t_atm;
	MTAtom *newatm;
	while ((t_atm = [allatm nextObject]))
	{
		newatm = [t_atm copy];
		[newres addAtom: newatm];
	}

	return newres;
}


/*
 *
 */
-(NSComparisonResult)compare: (id)other
{
	Class klass = [other class];

	if (self == other)
		return NSOrderedSame;
#ifdef __APPLE__
	if (klass && [klass isSubclassOfClass: residueKlass])
#else
	if (klass && GSObjCIsKindOf(klass,residueKlass))
#endif
	{
		int num1,num2;
		num1 = [[self number]intValue];
		num2 = [[other number]intValue];
		if (num1 >= num2)
			return NSOrderedDescending;
		if (num1 < num2)
			return NSOrderedAscending;

		/* now, same number */
		if ([self subcode] >= [other subcode])
			return NSOrderedDescending;
	}
	[NSException raise:@"Residue_compare:" format:@"Cannot compare "];
}


/*
 *   return this residue's number
 */
-(NSNumber*)number
{
	return number;
}


-(int)sequenceNumber
{
	return seqnum;
}


/*
 *   return this residue's subcode
 */
-(char)subcode
{
	return subcode;
}


/*
 *   return this residue's name
 */
-(NSString*)name
{
	return name;
}

- (void) setName: (NSString*) aString
{
	[name release];
	name = [aString retain];
}

/*
 *   return this residue's name (modified, original standard form)
 */
-(NSString*)modname
{
	if (modname)
	{
		return modname;
	} else {
		return name;
	}
}


/*
 *   return description of modification of this residue
 */
-(NSString*)moddescription
{
	return moddesc;
}


/*
 *   return segment identifier
 */
-(NSString*)segid
{
	return segid;
}


/*
 *   returns a key for this residue (=concatenation of number and subcode)
 */
-(NSString*)key
{
	NSString *str;
	if (subcode==32)
	{
		str=[NSString stringWithFormat: @"%@",number];
	} else {
		str=[NSString stringWithFormat: @"%@%c",number,subcode];
	}
	return str;
}


/*
 *   returns a string describing this residue (=concatenation of name and number)
 */
-(NSString*)description
{
	NSString *str;
	if (subcode==32)
	{
		str=[NSString stringWithFormat: @"%@%@",name,number];
	} else {
		str=[NSString stringWithFormat: @"%@%@%c",name,number,subcode];
	}
	return str;
}


/*
 *   return the one letter code for this type of residue
 */
-(NSString*)oneLetterCode
{
        NSString *res;
	if ([self isModified])
	{
		res = [translate3LetterTo1Letter objectForKey: modname];
	} else {
		res = [translate3LetterTo1Letter objectForKey: name];
	}
        if (!res)
        {
            res = @"X";
        }
        return res;
}


-(MTResidue*)previousResidue
{
        if ([self isStandardAminoAcid])
        {
                return [self previousAminoAcid];
        }
        if ([self isNucleicAcid])
        {
                return [self previousNucleicAcid];
        }
        return nil;
}


/*
 *   follow backbone connectivity and find next residue at carboxyl end
 */
-(MTResidue*)nextResidue
{
        if ([self isStandardAminoAcid])
        {
                return [self nextAminoAcid];
        }
        if ([self isNucleicAcid])
        {
                return [self nextNucleicAcid];
        }
        return nil;
}


/*
 *   return the chain this residue belongs to
 */
-(MTChain*)chain
{
	return chain;
}


/*
 *   return YES if this residue is one of the "known" nucleic acids
 */
-(BOOL)isNucleicAcid
{
	if ([name isEqualToString:@"  A"] ||
	    [name isEqualToString:@"  T"] ||
	    [name isEqualToString:@"  C"] ||
	    [name isEqualToString:@"  G"] ||
	    [name isEqualToString:@"  U"] ||
	    [name isEqualToString:@"  I"] ||
	    [name isEqualToString:@" +A"] ||
	    [name isEqualToString:@" +T"] ||
	    [name isEqualToString:@" +C"] ||
	    [name isEqualToString:@" +G"] ||
	    [name isEqualToString:@" +U"] ||
	    [name isEqualToString:@" +I"])
	{
		return YES;
	} else if ([self isModified] && ([modname isEqualToString:@"  A"] ||
	    [modname isEqualToString:@"  T"] ||
	    [modname isEqualToString:@"  C"] ||
	    [modname isEqualToString:@"  G"] ||
	    [modname isEqualToString:@"  U"] ||
	    [modname isEqualToString:@"  I"] ||
	    [modname isEqualToString:@" +A"] ||
	    [modname isEqualToString:@" +T"] ||
	    [modname isEqualToString:@" +C"] ||
	    [modname isEqualToString:@" +G"] ||
	    [modname isEqualToString:@" +U"] ||
	    [modname isEqualToString:@" +I"]))
	{
        	return YES;
        } else {
		return NO;
	}
}


/*
 *   return YES if this residue is one of the 20 standard amino acids
 */
-(BOOL)isStandardAminoAcid
{
	NSString *one;
        if ([self isNucleicAcid])
        {
                return NO;
        }
	if ([self isModified])
	{
		one = [translate3LetterTo1Letter objectForKey: modname];
	} else {
		one = [translate3LetterTo1Letter objectForKey: name];
	}
	if (one)
	{
		return YES;
	} else {
		return NO;
	}
}


/*
 *   return YES if this residue has all (backbone + sidechain) atoms present
 */
-(BOOL)haveAtomsPresent
{
	if (!verified)
	{
		[NSException raise:@"Unsupported" format:@"this residue has not yet been verified."];
		return NO;
	} else {
		return atomsComplete;
	}
}


/*
 *   returns YES if this residue is a modified one 
 */
-(BOOL)isModified
{
	return modname != nil;
}


/*
 *   calculate and return distance of this residue's CA atom to the reference's CA atom
 */
-(double)distanceCATo:(MTResidue*)r2
{
	MTAtom *ca1 = [self getCA];
	MTAtom *ca2 = [r2 getCA];
	double dist = -1.0;
	if (ca1 && ca2)
	{
		dist = [ca1 distanceTo: ca2];
	}
	return dist;
}


/*
 *   add atom to this residue
 */
-(id)addAtom:(MTAtom*)atom
{
	[atomarr addObject: atom];
	if ([[atom name] isEqualToString:@"CA"])
	{
		/* cache Calpha atoms */
		t_ca = atom;
	}
	return self;
}


/*
 *   remove atom from this residue
 */
-(id)removeAtom:(MTAtom*)atom
{
	if (atom == t_ca)
	{
		t_ca = nil;
	}
	[atomarr removeObjectIdenticalTo: atom];
	return self;
}


/*
 *   return a named atom in this residue
 */
-(MTAtom*)getAtomWithName: (NSString*)p_name
{
	int i;
	MTAtom *t_atm;
	for (i=0; i<[atomarr count]; i++)
	{
		t_atm = [atomarr objectAtIndex:i];
		if ([p_name isEqualToString:[t_atm name]])
		{
			return t_atm;
		}
	}
	return nil;
}


/*
 *   return an atom in this residue with the given number
 */
-(MTAtom*)getAtomWithNumber:(NSNumber*)p_number
{
	int i;
	MTAtom *t_atm;
	for (i=0; i<[atomarr count]; i++)
	{
		t_atm = [atomarr objectAtIndex:i];
		if ([p_number isEqualToNumber:[t_atm number]])
		{
			return t_atm;
		}
	}
	return nil;
}


-(MTAtom*)getAtomWithInt:(unsigned int)p_number
{
	return [self getAtomWithNumber: [NSNumber numberWithInt:p_number]];
}


/*
 *   return atom with name @"CA"
 */
-(MTAtom*)getCA
{
	return t_ca;
}


/*
 *   return enumerator over all atoms
 */
-(NSEnumerator*)allAtoms
{
	return [atomarr objectEnumerator];
}

-(NSArray*)atoms
{
	return [[atomarr copy] autorelease];
}\
/*
 *   transform this residue by the given matrix
 */
-(id)transformBy: (MTMatrix53*)m
{
	//printf("Residue-transformBy %@\n",self);
	NSEnumerator *e_atoms = [self allAtoms];
	id atom;
	while ((atom = [e_atoms nextObject]))
	{
		[atom transformBy: m];
	}
	return self;
}


/*
 *   rotate this residue by the given matrix
 */
-(id)rotateBy: (MTMatrix44*)m
{
	NSEnumerator *e_atoms = [self allAtoms];
	id atom;
	while ((atom = [e_atoms nextObject]))
	{
		[atom rotateBy: m];
	}
	return self;
}


/*
 *   translate this residue by the given vector
 */
-(id)translateBy: (MTCoordinates*)v
{
	//printf("Residue-transformBy %@\n",self);
	NSEnumerator *e_atoms = [self allAtoms];
	id atom;
	while ((atom = [e_atoms nextObject]))
	{
		[atom translateBy: v];
	}
	return self;
}


/*
 *   mutate this residue's side-chain to the one of the other
 */
-(id)mutateTo: (MTResidue*)p_res
{
	MTCoordinates *P11 = [self getCA];
	MTCoordinates *P12 = [self getAtomWithName: @"N"];
	MTCoordinates *P13 = [self getAtomWithName: @"C"];

	MTCoordinates *P21 = [p_res getCA];
	MTCoordinates *P22 = [p_res getAtomWithName: @"N"];
	MTCoordinates *P23 = [p_res getAtomWithName: @"C"];

	if (! (P11 && P12 && P13 && P21 && P22 && P23))
	{
		//[NSException raise:@"Residue_mutateTo:" format:@"Missing atoms."];
		fprintf(stderr, "Residue_mutateTo: missing atoms. Abort.\n");
		return nil;
	}
	
	/* define a plane (N-CA-C); move CA to origin */
	MTCoordinates *vP11 = [P11 copy]; [vP11 scaleByScalar: -1.0];
	MTCoordinates *vP12 = [P12 copy]; [vP12 add: vP11];
	MTCoordinates *vP13 = [P13 copy]; [vP13 add: vP11];

	/* define a plane (N-CA-C); move CA to origin */
	MTCoordinates *vP21 = [P21 copy]; [vP21 scaleByScalar: -1.0];
	MTCoordinates *vP22 = [P22 copy]; [vP22 add: vP21];
	MTCoordinates *vP23 = [P23 copy]; [vP23 add: vP21];

	MTCoordinates *tr1 = [vP21 copy];	// move to origin
	MTCoordinates *tr2 = [P11 copy];	// move from origin

	MTVector *N1 = [vP12 vectorProductBy: vP13];
	[N1 normalize];
	MTVector *N2 = [vP22 vectorProductBy: vP23];
	[N2 normalize];
	MTCoordinates *cN1 = [MTCoordinates coordsFromVector: N1];
	MTCoordinates *cN2 = [MTCoordinates coordsFromVector: N2];
	MTMatrix44 *rot1 = [cN1 alignToZaxis];	// compute rotation
	MTMatrix44 *rot2 = [cN2 alignToZaxis];
	MTCoordinates *cP12 = [vP12 copy];
	MTCoordinates *cP22 = [vP22 copy];
	[cP12 rotateBy: rot1];			// apply rotation
	[cP22 rotateBy: rot2];

	/* now both normal vectors are aligned to the Z-axis -> vectors in XY-plane */
	//double phi = [cP12 angleBetween: cP22];
	MTCoordinates *axisY = [MTCoordinates coordsWithX: 0.0 Y: 1.0 Z: 0.0];
	double phi1 = [cP12 angleBetween: axisY];
	double phi2 = [cP22 angleBetween: axisY];
	MTMatrix44 *rotZ = [MTMatrix44 rotationZ: (phi1 - phi2)];
	//MTMatrix44 *rotZ = [MTMatrix44 rotationZ: phi];
	//printf(" rotation angle phi = %1.2f (%1.2f, %1.2f)\n", phi, phi1, phi2);
	//printf(" rotation Z: %@\n", [rotZ description]);

	[rot1 transpose]; 	// inverse rotation

	/* combine rotations into single one
	 * to be applied on the atoms in first residue such that
	 * they will move to ourselfs.
	 */
	//MTMatrix44 *allrot = [rot2 x: rotZ];
	//allrot = [allrot x: rot1];
	
	/* remove all but backbone atoms */
	int l = [atomarr count];
	int i;
	MTAtom *atm;
	NSString *anm;
	//printf("   max atoms = %d\n", l);
	for (i=0; i<l; i++)
	{
		atm = [atomarr objectAtIndex: i];
		anm = [atm name];
		if (! ([anm isEqualToString: @"C"] || 
		       [anm isEqualToString: @"O"] || 
		       [anm isEqualToString: @"CA"] || 
		       [anm isEqualToString: @"N"]))
		{
			//printf("  remove atom: '%@' (%d)\n", anm,i);
			[self removeAtom: atm];
			i--; l--;
		};
	}

	/* then add all but backbone atoms from other residue */
	MTResidue *res2 = [p_res copy];
	l = [res2->atomarr count];
	[res2 translateBy: tr1];		// to origin
	//[atm rotateBy: allrot];
	[res2 rotateBy: rot2];		// on  Z-axis
	[res2 rotateBy: rotZ];		// adjust rotation around Z axis
	[res2 rotateBy: rot1];		// from Z-axis to orientation 1
	[res2 translateBy: tr2];		// to location 1
	for (i=0; i<l; i++)
	{
		atm = [res2->atomarr objectAtIndex: i];
		anm = [atm name];
		if (! ([anm isEqualToString: @"C"] || 
		       [anm isEqualToString: @"O"] || 
		       [anm isEqualToString: @"CA"] || 
		       [anm isEqualToString: @"N"]))
		{
			//printf("  add atom: '%@' (%d)\n", anm,i);
			[self addAtom: atm];
		};
	}

	[self setName: [p_res name]];

	return self;
}



/*
 *   convenience function to compute a residue's key from its number and subcode
 */
+(NSString*)computeKeyFromInt:(int)p_number subcode:(char)p_subcode
{
	NSString *res;
	if (p_subcode==32)
	{
		res = [NSString stringWithFormat:@"%d",p_number];
	} else {
		res = [NSString stringWithFormat:@"%d%c",p_number,p_subcode];
	}
	return res;
}


/*
 *   convenience function to translate 3-letter codes to 1-letter
 */
+(NSString*)translate3LetterTo1LetterCode: (NSString*)c3letter
{
	return [translate3LetterTo1Letter objectForKey: c3letter];
}

@end

