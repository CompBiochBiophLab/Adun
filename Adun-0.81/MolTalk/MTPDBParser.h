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


#ifndef MTPDBPARSER_H
#define MTPDBPARSER_H


#include <Foundation/Foundation.h>


@class MTStructure;
@class MTAtom;


@interface MTPDBParser : NSObject	//@nodoc
{
        @private
	long options;
	
	NSMutableDictionary *parserSelectors;
	MTStructure *strx;
	NSNumber *molid;
	NSString *pdbcode;
	NSCalendarDate *date;
	NSString *header;
	NSString *title;
	NSString *keywords;
	float resolution;
	int expdata;
	int lastrevnr;
	NSCalendarDate *lastrevdate;

	NSMutableDictionary *relation_chain_seqres;
	NSMutableDictionary *relation_chain_molid;
	NSMutableDictionary *relation_molid_eccode;
	NSMutableDictionary *relation_molid_compound;
	NSMutableDictionary *relation_molid_source;
	NSMutableDictionary *relation_residue_modres;
	BOOL SrcOldStyle;
	BOOL CmpndOldStyle;
	BOOL newfileformat;
	int modelnr;
	BOOL haveModel1;

	NSMutableDictionary *temporaryatoms;
	MTAtom *lastcarboxyl;
	MTAtom *last3prime;
	char lastalternatesite;
	
	//Additions
	BOOL isStrict;

}

-(id)initWithOptions:(long)p_opts;

/*
 *   reads and initializes a parser from a file in PDB format
 *   returns the structure
 */
+(MTStructure*)parseStructureFromPDBFile:(NSString*)fn compressed:(BOOL)compr options:(long)options;


@end

#endif /* MTPDBPARSER_H */

