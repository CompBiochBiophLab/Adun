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


#ifndef MTSTRUCTUREFACTORY_H
#define MTSTRUCTUREFACTORY_H


#include <Foundation/Foundation.h>


#define PDBPARSER_ALL_NMRMODELS 1L
#define PDBPARSER_IGNORE_SIDECHAINS 2L
#define PDBPARSER_IGNORE_HETEROATOMS 4L
#define PDBPARSER_IGNORE_SOLVENT 8L
#define PDBPARSER_IGNORE_COMPOUND 16L
#define PDBPARSER_IGNORE_SOURCE 32L
#define PDBPARSER_IGNORE_KEYWORDS 64L
#define PDBPARSER_IGNORE_EXPDTA 128L
#define PDBPARSER_IGNORE_REMARK 256L
#define PDBPARSER_IGNORE_REVDAT 512L
#define PDBPARSER_DONT_VERIFYCONNECTIVITY 1024L
#define PDBPARSER_IGNORE_SEQRES 2048L 
#define PDBPARSER_ALL_ALTERNATE_ATOMS 4096L
#define PDBPARSER_IGNORE_HYDROGENS 8192L
#define PDBPARSER_ALL_REMARKS 16384L



@class MTStructure;

/*
 *   This factory can instantiate objects of the class @MTStructure. 
 *   If you want to create subclasses of @MTStructure, implement a subclass of @MTStructureFactory and
 *   overwrite @method(MTStructureFactory,+newInstance). Then set it to be the new default factory class 
 *   with @method(MTStructureFactory,+setDefaultStructureFactory:).
 *   <p>
 *   options that will be passed to the parser:<br>
 *   |PDBPARSER_ALL_NMRMODELS|=1 <br>
 *   |PDBPARSER_IGNORE_SIDECHAINS|=2 <br>
 *   |PDBPARSER_IGNORE_HETEROATOMS|=4 <br>
 *   |PDBPARSER_IGNORE_SOLVENT|=8 <br>
 *   |PDBPARSER_IGNORE_COMPOUND|=16 <br>
 *   |PDBPARSER_IGNORE_SOURCE|=32 <br>
 *   |PDBPARSER_IGNORE_KEYWORDS|=64 <br>
 *   |PDBPARSER_IGNORE_EXPDTA|=128 <br>
 *   |PDBPARSER_IGNORE_REMARK|=256 <br>
 *   |PDBPARSER_IGNORE_REVDAT|=512 <br>
 *   |PDBPARSER_DONT_VERIFYCONNECTIVITY|=1024 <br>
 *   |PDBPARSER_IGNORE_SEQRES|=2048 <br>
 *   |PDBPARSER_ALL_ALTERNATE_ATOMS|=4096 <br>
 *   |PDBPARSER_IGNORE_HYDROGENS|=8192 <br>
 *   |PDBPARSER_ALL_REMARKS|=16384 <br>
 *
 */
@interface MTStructureFactory : NSObject

/* creation */
+(id)newStructureFromPDBFile:(NSString*)fn;
+(id)newStructureFromPDBFile:(NSString*)fn options:(long)opts;
+(id)newStructureFromPDBDirectory:(NSString*)code;
+(id)newStructureFromPDBDirectory:(NSString*)code options:(long)opts;
+(id)newStructure;

/* internally used */
+(id)newInstance;

/* control instantiation */
+(void)setDefaultStructureFactory:(Class)klass;

@end

#endif /* MTSTRUCTUREFACTORY_H */
 
