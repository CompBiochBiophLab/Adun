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
#include <unistd.h>

#include "MTStructureFactory.h"
#include "privateMTStructure.h"
#include "MTPDBParser.h"
#include "MTFileStream.h"


static Class structureFactoryKlass = nil;


@implementation MTStructureFactory



/*
 *   reads and parses a file in PDB format and returns the resulting object of type: @Structure
 */
+(id)newStructureFromPDBFile:(NSString*)fn
{
	return [self newStructureFromPDBFile:fn options:0L];
}


/*
 *   reads and parses a file in PDB format and returns the resulting object of type: @MTStructure<br>
 *   accepts a combination of options to pass to the parser.
 */
+(id)newStructureFromPDBFile:(NSString*)fn options:(long)opts
{
	NSString *t_fn = fn;
	while (YES)
	{
		if ([MTFileStream checkFileStat:t_fn])
		{
			break;
		}
		t_fn = [NSString stringWithFormat:@"./tempfiles/%@.pdb",fn];
		if ([MTFileStream checkFileStat:t_fn])
		{
			break;
		}
		t_fn = [NSString stringWithFormat:@"./tempfiles/%@",fn];
		if ([MTFileStream checkFileStat:t_fn])
		{
			break;
		}
		t_fn = [NSString stringWithFormat:@"%@.pdb",fn];
		if ([MTFileStream checkFileStat:t_fn])
		{
			break;
		}

		[NSException raise:@"Unsupported" format:@"File does not exist or we don't have the rights for reading it. file=%@",fn];
		return nil;
	}
	if ([MTFileStream isFileCompressed:t_fn])
	{
		return [MTPDBParser parseStructureFromPDBFile:t_fn compressed:YES options:opts];
	} else {
		return [MTPDBParser parseStructureFromPDBFile:t_fn compressed:NO options:opts];
	}
}


/*
 *   reads and parses a file in PDB format from the PDB mirroring directory structure<br>
 *   and returns the resulting object of type: @MTStructure
 */
+(id)newStructureFromPDBDirectory:(NSString*)code
{
	return [self newStructureFromPDBDirectory:code options:0L];
}

/*
 *   reads and parses a file in PDB format from the PDB mirroring directory structure<br>
 *   and returns the resulting object of type: @MTStructure<br>
 *   accepts a combination of options to pass to the parser.
 */
+(id)newStructureFromPDBDirectory:(NSString*)code options:(long)opts
{
	char *pdbdir = getenv("PDBDIR");
	if (!pdbdir)
	{
		[NSException raise:@"Unsupported" format:@"Cannot determine root path of PDB directory (environment variable: PDBDIR)"];
		return nil;
	}
	if ([code length] != 4)
	{
		NSLog(@"PDB codes are exactly 4 letters long. Abort.");
		return nil;
	}
	char *s_code = (char*)[code cString];
	NSString *fname = [NSString stringWithFormat:@"%s/%c%c/%c%c%c%c.pdb",pdbdir,s_code[1],s_code[2],s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/pdb%c%c%c%c.ent",pdbdir,s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/pdb%c%c%c%c.ent.Z",pdbdir,s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/%c%c/pdb%c%c%c%c.ent",pdbdir,s_code[1],s_code[2],s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/%c%c/pdb%c%c%c%c.ent.Z",pdbdir,s_code[1],s_code[2],s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	if (s_code[1]>=65 && s_code[1]<=90) s_code[1] += 32;	// lower case
	if (s_code[2]>=65 && s_code[2]<=90) s_code[2] += 32;	// lower case
	if (s_code[3]>=65 && s_code[3]<=90) s_code[3] += 32;	// lower case
	fname = [NSString stringWithFormat:@"%s/%c%c/%c%c%c%c.pdb",pdbdir,s_code[1],s_code[2],s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/pdb%c%c%c%c.ent",pdbdir,s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/pdb%c%c%c%c.ent.Z",pdbdir,s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/%c%c/pdb%c%c%c%c.ent",pdbdir,s_code[1],s_code[2],s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}
	fname = [NSString stringWithFormat:@"%s/%c%c/pdb%c%c%c%c.ent.Z",pdbdir,s_code[1],s_code[2],s_code[0],s_code[1],s_code[2],s_code[3]];
	if ([MTFileStream checkFileStat:fname])
	{
		return [self newStructureFromPDBFile:fname options:opts];
	}

	[NSException raise:@"Unsupported" format:@"Cannot load structure with code:%@",code];
	return nil;
}


/*
 *   creates a new instance of type @MTStructure, calls @method(MTStructureFactory,+newInstance)
 */
+(id)newStructure
{
	if (!structureFactoryKlass)
	{
		structureFactoryKlass = self;
	}
	return [structureFactoryKlass newInstance];
}


/*
 *   internally used to create the instance of the correct type.<br>
 *   This method should be overidden in subclasses wich create subclasses of class @MTStructure.
 */
+(id)newInstance
{
	return AUTORELEASE([MTStructure new]);
}


/*
 *   sets the class which will create instances. Per default set to @MTStructureFactory.
 */
+(void)setDefaultStructureFactory:(Class)klass
{
#ifdef __APPLE__
	if (klass && [klass isSubclassOfClass:self])
#else
	if (klass && GSObjCIsKindOf(klass,self))
#endif
	{
		structureFactoryKlass = klass;
	} else {
		[NSException raise:@"unimplemented" format:@"class %@ does not inherit from StructureFactory.",klass];
	}
}


@end

