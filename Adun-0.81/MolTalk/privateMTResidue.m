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

#include "privateMTResidue.h"
#include "MTResidue.h"
#include "MTChain.h"
#include "MTAtom.h"
#include "MTAtomFactory.h"


static NSMutableDictionary *atomConnectivity = nil;

@implementation MTResidue (Private)


-(void)setName:(NSString*)p_name	//@nodoc
{
	RETAIN(p_name);
	if (name)
	{
		RELEASE(name);
	}
	name = p_name;
}


-(void)setModName:(NSString*)p_name	//@nodoc
{
	if (p_name)
	{
		RETAIN(p_name);
	}
	if (modname)
	{
		RELEASE(modname);
	}
	modname = p_name;
}


-(void)setModDesc:(NSString*)p_desc	//@nodoc
{
	if (p_desc)
	{
		RETAIN(p_desc);
	}
	if (moddesc)
	{
		RELEASE(moddesc);
	}
	moddesc = p_desc;
}


-(void)setNumber:(NSNumber*)p_number	//@nodoc
{
	RETAIN(p_number);
	if (number)
	{
		RELEASE(number);
	}
	number = p_number;
}


-(void)setSeqNum:(int)p_seqnum		//@nodoc
{
	seqnum = p_seqnum;
}


-(void)setSegid:(NSString*)p_segid	//@nodoc
{
	RETAIN(p_segid);
	if (segid)
	{
		RELEASE(segid);
	}
	segid = p_segid;
}


-(void)setSubcode:(char)p_subcode	//@nodoc
{
	subcode = p_subcode;
}


-(void)setChain:(MTChain *)p_chain	//@nodoc
{
	chain = p_chain;
}


-(void)verifyAtomConnectivity	//@nodoc
{
	if (!atomConnectivity)
	{
	/* have to set up the dictionary with the connectivity tables per residue type */
		atomConnectivity = RETAIN([NSMutableDictionary new]);
		/* ALA */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",nil] forKey:@"ALA"];
		/* ARG */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD",@"NE",@"CZ",@"NH1",@"NH2",nil] forKey:@"ARG"];
		/* ASN */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"OD1",@"ND2",nil] forKey:@"ASN"];
		/* ASP */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"OD1",@"OD2",nil] forKey:@"ASP"];
		/* CYS */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"SG",nil] forKey:@"CYS"];
		/* GLN */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD",@"OE1",@"NE2",nil] forKey:@"GLN"];
		/* GLU */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD",@"OE1",@"OE2",nil] forKey:@"GLU"];
		/* GLY */
		//[atomConnectivity setObject:[NSArray arrayWithObjects:nil] forKey:@"GLY"];
		/* HIS */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"ND1",@"CD2",@"CE1",@"NE2",nil] forKey:@"HIS"];
		/* ILE */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG1",@"CG2",@"CD1",nil] forKey:@"ILE"];
		/* LEU */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD1",@"CD2",nil] forKey:@"LEU"];
		/* LYS */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD",@"CE",@"NZ",nil] forKey:@"LYS"];
		/* MET */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"SD",@"CE",nil] forKey:@"MET"];
		/* MSE */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"SE",@"CE",nil] forKey:@"MSE"];
		/* PHE */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD1",@"CD2",@"CE1",@"CE2",@"CZ",nil] forKey:@"PHE"];
		/* PRO */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD",nil] forKey:@"PRO"];
		/* SER */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"OG",nil] forKey:@"SER"];
		/* THR */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"OG1",@"CG2",nil] forKey:@"THR"];
		/* TRP */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD1",@"CD2",@"NE1",@"CE2",@"CE3",@"CZ2",@"CZ3",@"CH2",nil] forKey:@"TRP"];
		/* TYR */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG",@"CD1",@"CD2",@"CE1",@"CE2",@"CZ",@"OH",nil] forKey:@"TYR"];
		/* VAL */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"CB",@"CG1",@"CG2",nil] forKey:@"VAL"];
		/* A */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"O5*",@"C4*",@"O4*",@"C3*",@"C2*",@"C1*",@"N1",@"C2",@"N3",@"C4",@"C5",@"C6",@"N6",@"N7",@"C8",@"N9",nil] forKey:@"  A"];
		/* G */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"O5*",@"C4*",@"O4*",@"C3*",@"C2*",@"C1*",@"N1",@"C2",@"N2",@"N3",@"C4",@"C5",@"C6",@"O6",@"N7",@"C8",@"N9",nil] forKey:@"  G"];
		/* T */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"O5*",@"C4*",@"O4*",@"C3*",@"C2*",@"C1*",@"N1",@"C2",@"O2",@"N3",@"C4",@"O4",@"C5",@"C5M",@"C6",nil] forKey:@"  T"];
		/* C */
		[atomConnectivity setObject: [NSArray arrayWithObjects:@"O5*",@"C4*",@"O4*",@"C3*",@"C2*",@"C1*",@"N1",@"C2",@"O2",@"N3",@"C4",@"N4",@"C5",@"C6",nil] forKey:@"  C"];
		/* U */
		[atomConnectivity setObject:[NSArray arrayWithObjects:@"O5*",@"C4*",@"O4*",@"C3*",@"C2*",@"C1*",@"N1",@"C2",@"O2",@"N3",@"C4",@"O4",@"C5",@"C6",nil] forKey:@"  U"];
	}
	
	verified = YES;
	NSArray *connections = [atomConnectivity objectForKey: name];
	if (connections)
	{
		/* test for backbone */
		atomsComplete = YES;
		if (![self getAtomWithName:@"N"])
		{
			atomsComplete = NO;
			return;
		}
		if (![self getAtomWithName:@"CA"])
		{
			atomsComplete = NO;
			return;
		}
		if (![self getAtomWithName:@"C"])
		{
			atomsComplete = NO;
			return;
		}
		if (![self getAtomWithName:@"O"])
		{
			atomsComplete = NO;
			return;
		}
		/* test for sidechain */
		atomsComplete = YES;
		/* go through all (alternative) namings */
		NSEnumerator *atomenum = [connections objectEnumerator];
		NSString *atmname;
		while ((atmname = [atomenum nextObject]))
		{
			if ([self getAtomWithName: atmname] == nil)
			{
				atomsComplete = NO;
				break;
			}
		}
		if (atomsComplete)
		{
			/* only have to match one of the possible namings */
			return;
		}
		//fprintf (stderr,"Residue %s is not complete, missing atoms.\n",[[self description] cString]);
	} else {
		//fprintf (stderr,"unknown residue type: %s setting atomsComplete to YES.\n",[name cString]);
		atomsComplete = YES;
	}
}


/*
 *   follow backbone connectivity and find previous residue at amino end
 */
-(MTResidue*)previousAminoAcid    //@nodoc
{
        MTAtom *natom;
        MTAtom *atm2;
        MTAtom *catom;
        natom = [self getAtomWithName: @"N"];
        if (!natom) return nil;
        NSEnumerator *aenum = [natom allBondedAtoms];
        catom = nil;
        while ((atm2 = [aenum nextObject]))
        {
                if ([[atm2 name] isEqualToString: @"C"])
                {
                        if ([atm2 distanceTo: natom] <= 3.0)
                        {
                                catom = atm2;
                                break;
                        }
                }
        }
        if (catom)
        {
                NSEnumerator *renum = [[self chain] allResidues];
                MTResidue *t_res;
                while ((t_res = [renum nextObject]))
                {
                        aenum = [t_res allAtoms];
                        while ((atm2 = [aenum nextObject]))
                        {
                                if (atm2 == catom)
                                {
                                        return t_res;
                                }
                        }
                }
        }
        return nil;
}


/*
 *   follow backbone connectivity and find previous residue at carboxyl end
 */
-(MTResidue*)nextAminoAcid    //@nodoc
{
        MTAtom *natom;
        MTAtom *atm2;
        MTAtom *catom;
        catom = [self getAtomWithName: @"C"];
        if (!catom) return nil;
        NSEnumerator *aenum = [catom allBondedAtoms];
        natom = nil;
        while ((atm2 = [aenum nextObject]))
        {
                if ([[atm2 name] isEqualToString: @"N"])
                {
                        if ([atm2 distanceTo: catom] <= 3.0)
                        {
                                natom = atm2;
                                break;
                        }
                }
        }
        if (natom)
        {
                NSEnumerator *renum = [[self chain] allResidues];
                MTResidue *t_res;
                while ((t_res = [renum nextObject]))
                {
                        aenum = [t_res allAtoms];
                        while ((atm2 = [aenum nextObject]))
                        {
                                if (atm2 == natom)
                                {
                                        return t_res;
                                }
                        }
                }
        }
        return nil;
}


-(MTResidue*)previousNucleicAcid    //@nodoc
{
        return nil;
}


-(MTResidue*)nextNucleicAcid    //@nodoc
{
        return nil;
}


-(void)computeCB
{
	// assumption: angle(N,CA,CB) and angle(C,CA,CB) are both 109.5 deg
	// length of CA-CB is 1.53 Angstroms (GROMOS parameterisation)
	//
	// Therefore, we can compute a point P in the plane (N, CA, C) with 
	// angle (P, CA, C) is 0.5 * angle(N,CA,C).
	// P-CA defines one axis, the normal N-CA x CA-C the second. The 
	// third is N1 x N2. Rotation of a point in the plane (N, CA, C) 
	// around N3 through CA gives CB.

	// first, remove CB 
	MTAtom *cb = [self getAtomWithName: @"CB"];
	if (cb)
	{
		[self removeAtom: cb];
	}
	MTAtom *pA = [self getAtomWithName: @"N"];
	MTAtom *pB = [self getCA];
	MTAtom *pC = [self getAtomWithName: @"C"];

	double len = 1.530;  // default bond length CA-CB
	double phi = 109.5;  // default angle(C,CA,CB) = angle(N,CA,CB)

	MTCoordinates *v1 = [pB differenceTo: pA];
	MTCoordinates *v2 = [pB differenceTo: pC];
	MTVector *N = [v1 vectorProductBy: v2];
	[N normalize];
	[v1 normalize]; [v1 scaleByScalar: len]; // A'
	[v2 normalize]; [v2 scaleByScalar: len]; // C'
	MTCoordinates *Apr = [MTCoordinates coordsFromVector: pB];
	[Apr add: v1];
	MTCoordinates *Cpr = [MTCoordinates coordsFromVector: pB];
	[Cpr add: v2];

	v1 = [Apr differenceTo: Cpr];
	double u = [v1 length] / 2.0;
	[v1 normalize]; [v1 scaleByScalar: u];
	MTCoordinates *pP = [Apr copy];
	[pP add: v1];
	MTCoordinates *vproj = [pP differenceTo: pB];
	double v = [vproj length];
	[vproj normalize];

	double s = sin(phi * M_PI / 180.0) * len / sin ((180.0 - phi) / 2.0 * M_PI / 180.0);
	double m = sqrt(s * s - u * u);
	double cose = ((v * v) + (len * len) - (m * m)) / 2.0 / len / v;
	double angleE = acos(cose);
	double angleD = M_PI - angleE;
	double w = cos(angleD) * len;
	double h = sin(angleD) * len;
	[vproj scaleByScalar: w];
	MTCoordinates *pQ = [MTCoordinates coordsFromVector: pB];
	[pQ add: vproj];  // base point
	[N scaleByScalar: h];
	MTCoordinates *pD = [pQ copy];
	[pD add: N];  // CB

	MTAtom *newCB = [MTAtomFactory newAtomWithNumber: 111 name: " CB" X: [pD atDim: 0] Y: [pD atDim: 1] Z: [pD atDim: 2] B: 19.9];
	[self addAtom: newCB];
	
}

@end

