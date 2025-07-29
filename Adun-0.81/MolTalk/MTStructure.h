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


#ifndef MTSTRUCTURE_H
#define MTSTRUCTURE_H


#include <Foundation/Foundation.h>

typedef enum { Structure_XRay=100, Structure_NMR, Structure_TheoreticalModel, Structure_Other, Structure_Unknown } ExperimentType;

@class MTMatrix53;
@class MTChain;
@class MTStream;

/* 
 *   following the keys for predefined descriptors
 */
extern id MTSTRX_HEADER_key;
extern id MTSTRX_TITLE_key;
extern id MTSTRX_PDBCODE_key;
extern id MTSTRX_DATE_key;
extern id MTSTRX_REVDATE_key;
extern id MTSTRX_RESOLUTION_key;
extern id MTSTRX_EXPERIMENT_key;
extern id MTSTRX_KEYWORDS_key;


/*
 *   Class @MTStructure is the top class of the hierarchical mapping of PDB files to<br>
 *   object space.
 *   
 */
@interface MTStructure : NSObject
{
        @protected
	BOOL isStrict;
	NSMutableDictionary *hetnames;
	NSMutableDictionary *descriptors;
	
	NSMutableArray *chains;
        
        int currmodel;
        NSMutableArray *models;
}

/* readonly access */
-(NSString*)header;
-(NSString*)pdbcode;
-(NSString*)title;
-(NSArray*)keywords;
-(NSCalendarDate*)date;
-(NSCalendarDate*)revdate;
-(float)resolution;
-(ExperimentType)expdata;
-(NSString*)hetnameForKey:(NSString*)key;

/* descriptors */
-(id)getDescriptorForKey:(NSString*)key;
-(void)setDescriptor:(id)desc withKey:(NSString*)key;
-(NSArray*)allDescriptorKeys;

/* model context */
-(int)models;
-(int)currentModel;
-(void)switchToModel:(int)p_mnum;
-(int)addModel;
-(void)removeModel;

/* writes out the complete structure to a file in PDB format */
-(void)writePDBFile:(NSString*)fn;
-(void)writePDBToStream:(MTStream*)str;
/**
As writePDBToStream but only writes the ATOM part of the PDB
and as a model with number modelnr.
Useful when you want to write a large number of models to a stream
without having to add them all as models to the receiver
*/
-(void)writePDBToStream:(MTStream*)stream asModel: (int) modelnr;

/**
As writePDBFile but enabling polymorphism with property list objects.
In this case the paramter \e value has no effect currently.
*/
- (BOOL) writeToFile: (NSString*) filename atomically: (BOOL) value;

/* chain access */
-(MTChain*)getChain:(id)p_chain;
-(NSEnumerator*)allChains;
-(NSArray*)chains;

/* manipulations */
-(MTChain*)addChain:(MTChain*)p_chain;
-(void)removeChain:(MTChain*)p_chain;


@end


@class MTStream;
@class MTResidue;
@class MTChain;

@interface MTStructure (Private)

/*
 *   writes out the complete structure to a file in PDB format
 */
-(void)writePDBHeaderTo:(MTStream*)s;	//@nodoc
-(void)writePDBRemark:(int)remid to:(MTStream*)s;	//@nodoc
-(void)writePDBChain:(MTChain*)c to:(MTStream*)s fromSerial:(unsigned int*)ser;	//@nodoc
-(void)writePDBResidue:(MTResidue*)r inChain:(MTChain*)c to:(MTStream*)s fromSerial:(unsigned int*)ser;	//@nodoc
-(void)writePDBHeterogen:(MTResidue*)r inChain:(MTChain*)c to:(MTStream*)s fromSerial:(unsigned int*)ser;	//@nodoc
-(void)writePDBConectTo:(MTStream*)s;	//@nodoc
-(void)writePDBConectResidue:(MTResidue*)r to:(MTStream*)s;	//@nodoc

/*
 *   adds a new chain with the identifier c_chain
 */
-(MTChain*)mkChain:(NSNumber*)c_chain;	//@nodoc

/*
 *   write access to fields
 */
-(void)expdata:(int)expdata;	//@nodoc
-(void)resolution:(float)resolution;	//@nodoc
-(void)header:(NSString*)header;	//@nodoc
-(void)title:(NSString*)title;	//@nodoc
-(void)keywords:(NSString*)kw;	//@nodoc
-(void)date:(NSCalendarDate*)date;	//@nodoc
-(void)pdbcode:(NSString*)pdbcode;	//@nodoc
-(void)revdate:(NSCalendarDate*)revdate;	//@nodoc
-(void)hetname:(id)name forKey:(NSString*)key;	//@nodoc

@end

#endif /* MTSTRUCTURE_H */
 
