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
#include <locale.h>

#include "MTStructure.h"
#include "privateMTStructure.h"
#include "MTChain.h"
#include "privateMTChain.h"
#include "MTResidue.h"
#include "MTAtom.h"
#include "MTFileStream.h"
#include "MTString.h"


#undef MEMDEBUG


id MTSTRX_HEADER_key = nil;
id MTSTRX_TITLE_key = nil;
id MTSTRX_PDBCODE_key = nil;
id MTSTRX_DATE_key = nil;
id MTSTRX_REVDATE_key = nil;
id MTSTRX_RESOLUTION_key = nil;
id MTSTRX_EXPERIMENT_key = nil;
id MTSTRX_KEYWORDS_key = nil;


static NSComparisonResult mySortChainArray (id one, id two, void *cntxt);


@implementation MTStructure

+(void)initialize     //@nodoc
{
	MTSTRX_HEADER_key = RETAIN([NSString stringWithCString: "HEADER"]);
	MTSTRX_TITLE_key = RETAIN([NSString stringWithCString: "TITLE"]);
	MTSTRX_PDBCODE_key = RETAIN([NSString stringWithCString: "PDBCODE"]);
	MTSTRX_DATE_key = RETAIN([NSString stringWithCString: "DATE"]);
	MTSTRX_REVDATE_key = RETAIN([NSString stringWithCString: "REVDATE"]);
	MTSTRX_RESOLUTION_key = RETAIN([NSString stringWithCString: "RESOLUTION"]);
	MTSTRX_EXPERIMENT_key = RETAIN([NSString stringWithCString: "EXPERIMENT"]);
	MTSTRX_KEYWORDS_key = RETAIN([NSString stringWithCString: "KEYWORDS"]);
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:
		[NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
			forKey: @"StrictPDBWriting"]];
}


-(id)init    // @nodoc
{
	self = [super init];
	descriptors = [NSMutableDictionary new];
	[self setDescriptor: [NSNumber numberWithFloat: -1.0f] withKey: MTSTRX_RESOLUTION_key];
	[self setDescriptor: [NSNumber numberWithInt: Structure_Unknown] withKey: MTSTRX_EXPERIMENT_key];
	models = [NSMutableArray new];
        chains = [NSMutableArray array];
        [models addObject: chains];
        currmodel = [models count];
	hetnames = nil;
	
	isStrict = [[NSUserDefaults standardUserDefaults] boolForKey: @"StrictPDBWriting"];
	
	return self;
}


-(void)dealloc    // @nodoc
{
	//printf("Structure_dealloc %s\n",[[self description] cString]);
	if (models) 
	{
		[models removeAllObjects];
		RELEASE(models);
	}
	if (hetnames)
	{
		[hetnames removeAllObjects];
		RELEASE(hetnames);
	}
	if (descriptors)
	{
		[descriptors removeAllObjects];
		RELEASE(descriptors);
	}
	[super dealloc];
}


/*
 *   the structure keeps a dictionary of descriptors which 
 *   can be accessed through their key
 */
-(id)getDescriptorForKey:(NSString*)key
{
	if (key)
	{
		return [descriptors objectForKey: key];
	} else {
		return nil;
	}
}

-(void)setDescriptor:(id)desc withKey:(NSString*)key
{
	if (key && desc)
	{
		[descriptors setObject: desc forKey: key];
	}
}

-(NSArray*)allDescriptorKeys
{
	return [descriptors allKeys];
}


/*
 *   returns the number of models in this structure
 */
-(int)models
{
        return [models count];
}

/*
 *   returns the number of the currently active model
 */
-(int)currentModel;
{
        return currmodel;
}

/*
 *   switches context to the indicated model
 */
-(void)switchToModel:(int)p_mnum;
{
        if (p_mnum <= [self models])
        {
                currmodel = p_mnum;
                chains = [models objectAtIndex: (currmodel-1)];  // switch context
        } else {
                [NSException raise:@"error" format:@"Structure does not contain such a model: %d.",p_mnum];
        }
}

/*
 *   adds a new model, makes it the active context and returns its number
 */
-(int)addModel;
{
        chains = [NSMutableArray array];  // create new context
        [models addObject: chains];     // add it to the list of models
        currmodel = [self models];      // set it active
        return currmodel;
}

/*
 *   removes the currently active model
 */
-(void)removeModel
{
        if ([self models] == 1)
        {
                return;     // there is at least one model
        }
        [chains removeAllObjects];
        [models removeObjectAtIndex: (currmodel-1)];
        currmodel = [self models];
        chains = [models objectAtIndex: (currmodel-1)];
}


/*
 *   returns the header of the structure (|/HEADER/| entry, without date and code)
 */
-(NSString*)header
{
	return [self getDescriptorForKey: MTSTRX_HEADER_key];
}


/*
 *   returns the 4 character PDB code
 */
-(NSString*)pdbcode
{
	return [self getDescriptorForKey: MTSTRX_PDBCODE_key];
}


/*
 *   returns the title of the structure (|/TITLE/| entry)
 */
-(NSString*)title
{
	return [self getDescriptorForKey: MTSTRX_TITLE_key];
}


/*
 *   returns the list of keywords of the structure (|/KEYWDS/| entry)
 */
-(NSArray*)keywords
{
	return [self getDescriptorForKey: MTSTRX_KEYWORDS_key];
}


/*
 *   returns the date of deposition of the structure (from |/HEADER/| entry)
 */
-(NSCalendarDate*)date
{
	return [self getDescriptorForKey: MTSTRX_DATE_key];
}


/*
 *   returns the date of the last revision of the structure (|/REVDAT/| entries)
 */
-(NSCalendarDate*)revdate
{
	return [self getDescriptorForKey: MTSTRX_REVDATE_key];
}


/*
 *   returns the resolution of the structure determination (if applicable)
 */
-(float)resolution
{
	id t_res = [self getDescriptorForKey: MTSTRX_RESOLUTION_key];
	if (t_res)
	{
		if ([t_res isKindOfClass: [NSNumber class]])
		{
			return [t_res floatValue];
		}
	}
	return -1.0f;
}


/*
 *   returns the type of the structure determination method<br>
 *   |Structure_XRay|=100 <br>
 *   |Structure_NMR|=101 <br>
 *   |Structure_TheoreticalModel|=102 <br>
 *   |Structure_Other|=103 <br>
 *   |Structure_Unknown|=104
 */
-(ExperimentType)expdata
{
	id t_res = [self getDescriptorForKey: MTSTRX_EXPERIMENT_key];
	if (t_res)
	{
		if ([t_res isKindOfClass: [NSNumber class]])
		{
			return [t_res intValue];
		}
	}
	return Structure_Unknown;
}


/*
 *   return the description of a hetero group (|/HETNAM/| entries)
 */
-(NSString*)hetnameForKey:(NSString*)key
{
	if (hetnames)
	{
		return [hetnames objectForKey:key];
	}
	return nil;
}


/*
 *   add a chain to this structure
 */
-(MTChain *)addChain:(MTChain*)p_chain
{
        MTChain *chain = [self getChain:[p_chain codeNumber]];
        if (chain == nil)
        {
                [chains addObject: p_chain];
                [p_chain setStructure:self];
		return p_chain;
        }
	return nil;
}


/*
 *   remove a chain from this structure
 */
-(void)removeChain:(MTChain*)p_chain
{
	[chains removeObject:p_chain];
}


/*
 *   write this structure to a file in PDB format
 */
 
- (BOOL) writeToFile: (NSString*) filename atomically: (BOOL) value
{ 
	[self writePDBFile: filename];
	//temporary
	return YES;
}
 
-(void)writePDBFile:(NSString*)p_fn
{
	NSString *fn;
#ifdef SAFEENV
	fn = [NSString stringWithFormat: @"tempfiles/%@",[p_fn lastPathComponent]];
#else
	fn = p_fn;
#endif
	MTFileStream *fout = [MTFileStream streamToFile: fn];
	if (![fout ok])
	{
		NSLog(@"error: cannot open file %@",fn);
		return;
	}
	[self writePDBToStream: fout];
	[fout close];
}


-(void)writePDBToStream:(MTStream*)stream
{
	if (![stream ok])
	{
		NSLog(@"error: cannot write to stream");
		return;
	}
	CREATE_AUTORELEASE_POOL(pool);

#ifdef MEMDEBUG
	GSDebugAllocationActive(YES);
#endif

	
	/* set number printing locale format to POSIX */
	setlocale(LC_NUMERIC, "C");
	
	[self writePDBHeaderTo: stream];

	char buffer[82];
        NSArray *t_chains;
        NSEnumerator *e_chain;
        MTChain *chain;
        int modelnr;
        int modelcount = [models count];
	unsigned int serial = 1;
        for (modelnr = 1; modelnr <= modelcount; modelnr++)
        {
		CREATE_AUTORELEASE_POOL(poolinner);
                if (modelcount > 1)
                {
                        // structure contains more than one model
                        memset(buffer,32,80);
                        snprintf(buffer,80,"MODEL      % 3d", modelnr);
                        buffer[14]=' '; buffer[80]='\n'; buffer[81]='\0';
                        [stream writeCString: buffer];
                }
                serial = 1; // restart atom serial number
                t_chains = [[models objectAtIndex: (modelnr-1)] sortedArrayUsingFunction: (&mySortChainArray) context: self];
                e_chain = [t_chains objectEnumerator];
                while ((chain = [e_chain nextObject]))
                {
			[chain orderResidues];
                        [self writePDBChain: chain to: stream fromSerial: &serial];
                }
                if (modelcount > 1)
                {
                        // structure contains more than one model
                        memset(buffer,32,80);
                        snprintf(buffer,80,"ENDMDL");
                        buffer[6]=' '; buffer[80]='\n'; buffer[81]='\0';
                        [stream writeCString: buffer];
                }
#ifdef MEMDEBUG
		NSLog(@"change of allocated objects\n%s",GSDebugAllocationList(YES));
		NSLog(@"allocated objects on exiting script\n%s",GSDebugAllocationList(NO));
#endif
		RELEASE(poolinner);
        }
	
	[self writePDBConectTo: stream];
	memset(buffer,32,80);
	buffer[81]='\0';
	buffer[80]='\n';
	buffer[0]='E';buffer[1]='N';buffer[2]='D';
	[stream writeCString: buffer];
	RELEASE(pool);
}

-(void)writePDBToStream:(MTStream*)stream asModel: (int) modelnr
{
	if (![stream ok])
	{
		NSLog(@"error: cannot write to stream");
		return;
	}
	CREATE_AUTORELEASE_POOL(pool);
	
	/* set number printing locale format to POSIX */
	setlocale(LC_NUMERIC, "C");
	
	int charsWritten;
	char buffer[82];
        NSArray *t_chains;
        NSEnumerator *e_chain;
        MTChain *chain;
	unsigned int serial = 1;
       
	CREATE_AUTORELEASE_POOL(poolinner);
              
	memset(buffer,32,82);
	charsWritten = snprintf(buffer,80,"MODEL      %3d", modelnr);
	//Remove /0 added by snprintf
	buffer[charsWritten]=' ';
	buffer[80]='\n'; buffer[81]='\0';
	NSLog(@"%s", buffer);
	[stream writeCString: buffer];
	
	serial = 1; // restart atom serial number
	t_chains = [[models objectAtIndex: [self currentModel] - 1] sortedArrayUsingFunction: (&mySortChainArray) context: self];
	e_chain = [t_chains objectEnumerator];
	while ((chain = [e_chain nextObject]))
	{
		[chain orderResidues];
		[self writePDBChain: chain to: stream fromSerial: &serial];
	}
               
	memset(buffer,32,80);
	snprintf(buffer,80,"ENDMDL");
	buffer[6]=' '; buffer[80]='\n'; buffer[81]='\0';
	[stream writeCString: buffer];

	RELEASE(pool);
}

/*
 *   access chain by its code
 */
-(MTChain*)getChain:(id)p_chain
{
	char t_code;
	int i=0;
	MTChain *t_chain;
	
	if([p_chain respondsToSelector:@selector(characterAtIndex:)])
	{
		t_code = [p_chain characterAtIndex: 0];
	}
	else
	{
		t_code = [p_chain charValue];
	}
	
	while (i < [chains count])
	{
		t_chain = [chains objectAtIndex:i];
		if ([t_chain code]==t_code)
		{
			return t_chain;
		}
		i++;
	}
	return nil;
}


/*
 *   returns an enumerator over all chains of this structure
 */
-(NSEnumerator*)allChains
{
	return [chains objectEnumerator];
}


/*
 *   returns an array containing all the chains in this structure.
 */
-(NSArray*)chains
{
	return [[chains copy] autorelease];
}


NSComparisonResult mySortChainArray (id one, id two, void *cntxt)
{
	Class klass = [MTChain class];
	if ([one isKindOfClass:klass] && [two isKindOfClass:klass])
	{
		int code1 = [(MTChain*)one code];
		int code2 = [(MTChain*)two code];
		/* chain with " " (empty identifier) comes last */
		if (code1 == code2)
			return NSOrderedSame;
		if (code1 == 32)
			return NSOrderedDescending;
		if (code2 == 32)
			return NSOrderedAscending;
		if (code1 < code2)
			return NSOrderedAscending;
		return NSOrderedDescending;
	}
	return [one compare: two];

}


@end


