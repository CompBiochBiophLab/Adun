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

#include "privateMTStructure.h"
#include "MTChain.h"
#include "privateMTChain.h"
#include "MTChainFactory.h"
#include "MTResidue.h"
#include "MTAtom.h"
#include "MTStream.h"
#include "MTString.h"
#include "MTMatrix53.h"
#include "MTMatrix44.h"


static NSString *mkTextDate (NSCalendarDate *caldate);



@implementation MTStructure (Private)


-(void)writePDBHeaderTo:(MTStream *)strout        //@nodoc
{
        char buffer[82];
        int i,counter;
        char end_of_line[] = { 10, 0 };
        NSRange range;
        NSString *pdbcode = [self getDescriptorForKey: MTSTRX_PDBCODE_key];

        /* HEADER */
        id date = [self getDescriptorForKey: MTSTRX_DATE_key];
        NSString *t_date;
        if (date)
        {
                t_date = mkTextDate (date);
        } else {
		//t_date = @"01-Jan-65";
		t_date = mkTextDate ([NSCalendarDate calendarDate]);
        }
        NSString *header = [self getDescriptorForKey: MTSTRX_HEADER_key];
        if (header)
        {
                snprintf(buffer,51,"HEADER    %s                                         ",[header cString]);
        } else {
                snprintf(buffer,51,"HEADER    none                                     ");
        }
        snprintf(buffer+50,10,"%s          ",[t_date cString]);
        if (pdbcode)
        {
                snprintf(buffer+59,12,"   %s         ",[pdbcode cString]);
        } else {
                snprintf(buffer+59,12,"   1UNK      ");
        }
        buffer[70]='\0';
        [strout writeCString: buffer];
        [strout writeCString: end_of_line];

        /* TITLE */
        NSString *title = [self getDescriptorForKey: MTSTRX_TITLE_key];
        i = title?[title length]:0;
        if (i>0)
        {
                if (i <= 60)
                {
                        [strout writeString: @"TITLE     "];
                        [strout writeString: title];
                        i = 60-i;
                        buffer[i+1]='\0';
                        for (; i>=0; i--)
                        {
                                sprintf(buffer+i," ");
                        }
                        [strout writeCString: buffer];
                        [strout writeCString: end_of_line];
                } else {
                        counter = 2;
                        range.location = 0;
                        range.length = 60;
                        [strout writeString: @"TITLE     "];
                        [strout writeString: [title substringWithRange: range]];
                        [strout writeCString: end_of_line];
                        i -= 60;
                        range.location += 60;
                        while (i > 0)
                        {
                                memset(buffer,32,80);
                                [strout writeString: @"TITLE   "];
                                if (i<60)
                                {
                                        range.length = i;
                                }
                                snprintf(buffer,63,"% 2d%s                                                               ",counter,[[title substringWithRange:range]cString]);
                                buffer[62]='\0';
                                [strout writeCString: buffer];
                                i -= range.length;
                                [strout writeCString: end_of_line];
                                range.location += 60;
                                counter++;
                        }
                }
        }


        /* COMPND */

        /* SOURCE */

        /* EXPDTA */
        NSNumber *expdta = [self getDescriptorForKey: MTSTRX_EXPERIMENT_key];
        if (expdta)
        {
                switch ([expdta intValue])
                {
                        case 100:
                                [strout writeString: @"EXPDTA    X-RAY DIFFRACTION                                           "];
                                [strout writeCString: end_of_line];
                                break;
                        case 101:
                                snprintf(buffer,71,"EXPDTA    NMR, %d STRUCTURES                                          ",[self models]);
                                [strout writeCString: buffer];
                                [strout writeCString: end_of_line];
                                break;
                        case 102:
                                [strout writeString: @"EXPDTA    THEORETICAL MODEL                                           "];
                                [strout writeCString: end_of_line];
                                break;
                        default:
                                [strout writeString: @"EXPDTA    UNKNOWN                                                     "];
                                [strout writeCString: end_of_line];
                                break;
                }
        } else {
                [strout writeString: @"EXPDTA    UNKNOWN                                                     "];
                [strout writeCString: end_of_line];
        }



        /* REMARK 2: resolution */
        [strout writeString: @"REMARK   2                                                            "];
        [strout writeCString: end_of_line];
        if (expdta && [expdta intValue] == 100)
        {
                float resolution = [self resolution];
                if (resolution > 0.1)
                {
                        snprintf(buffer,71,"REMARK   2 RESOLUTION. %1.2f ANGSTROMS.                                  ",resolution);
                        [strout writeCString: buffer];
                        [strout writeCString: end_of_line];
                } else {
                        [strout writeString: @"REMARK   2 RESOLUTION. NOT APPLICABLE.                               "];
                        [strout writeCString: end_of_line];
                }
        } else {
                [strout writeString: @"REMARK   2 RESOLUTION. NOT APPLICABLE.                               "];
                [strout writeCString: end_of_line];
        }

        /* REMARK 4: acceptance of PDB file format V 2.2/1996 */
        [strout writeString: @"REMARK   4                                                            "];
        [strout writeCString: end_of_line];
        if (pdbcode)
        {
                [strout writeString: [NSString stringWithFormat:@"REMARK   4 %@ COMPLIES WITH FORMAT V. 2.2, 16-DEC-1996              ",[self pdbcode]]];
        } else {
                [strout writeCString: "REMARK   4 1UNK COMPLIES WITH FORMAT V. 2.2, 16-DEC-1996              "];
        }
        
        [strout writeCString: end_of_line];


        /* all other REMARKs */
        for (i=5; i<999; i++)
        {
                [self writePDBRemark: i to: strout];
        }


        
        /* write MODRES entries for all modified residues */
        char tbuffer[128];
        MTChain *chain;
        MTResidue *residue;
        NSEnumerator *e_res;
        NSEnumerator *e_chain = [self allChains];
        while ((chain = [e_chain nextObject]))
        {
                e_res = [chain allResidues];
                while ((residue = [e_res nextObject]))
                {
                        if ([residue isModified])
                        {
                                memset(buffer,32,80);
                                buffer[81]='\0';
                                buffer[80]='\n';
                                buffer[0]='M';buffer[1]='O';buffer[2]='D';buffer[3]='R';buffer[4]='E';buffer[5]='S';
                                buffer[16] = [chain code]; /* chain identifier */
                                [[self pdbcode] getCString: tbuffer maxLength: 5];
                                /* pdb code */
                                buffer[7]=tbuffer[0];buffer[8]=tbuffer[1];buffer[9]=tbuffer[2];buffer[10]=tbuffer[3];
                                /* residue name */
                                [[residue name] getCString: tbuffer maxLength: 4];
                                buffer[12]=tbuffer[0];buffer[13]=tbuffer[1];buffer[14]=tbuffer[2];
                                /* residue number */
                                snprintf(tbuffer, 10, "% 4u    ", [[residue number] intValue]);
                                for (i=0;i<4;i++)
                                {
                                        buffer[18+i]=tbuffer[i];
                                }
                                buffer[22]=[residue subcode];
                                /* residue modname */
                                [[residue modname] getCString: tbuffer maxLength: 4];
                                buffer[24]=tbuffer[0];buffer[25]=tbuffer[1];buffer[26]=tbuffer[2];
                                /* modification description */
                                [[residue moddescription] getCString: tbuffer maxLength: 42];
                                for (i=0; (i<[[residue moddescription]length] && i<41); i++)
                                {
                                        buffer[29+i]=tbuffer[i];
                                }
                                [strout writeCString: buffer];
                        }
                }
        }

        /* CRYST1 */
        id element = [self getDescriptorForKey: @"UNITVECTOR"];
        if (element)
        {
                memset(buffer,32,80);
                buffer[81]='\0';
                buffer[80]='\n';
                buffer[0]='C';buffer[1]='R';buffer[2]='Y';buffer[3]='S';buffer[4]='T';buffer[5]='1';
                sprintf(buffer+6,"%9.3f  ",[element atDim:0]);
                sprintf(buffer+15,"%9.3f  ",[element atDim:1]);
                sprintf(buffer+24,"%9.3f  ",[element atDim:2]);
                element = [self getDescriptorForKey: @"UNITANGLES"];
                if (element)
                {
                        sprintf(buffer+33,"%7.2f  ",[element atDim:0]);
                        sprintf(buffer+40,"%7.2f  ",[element atDim:1]);
                        sprintf(buffer+47,"%7.2f  ",[element atDim:2]);
                }
                element = [self getDescriptorForKey: @"SPACEGROUP"];
                if (element)
                {
                        sprintf(buffer+55,"%s          ",[element cString]);
                }
                element = [self getDescriptorForKey: @"ZVALUE"];
                if (element)
                {
                        sprintf(buffer+66,"%4d",[element intValue]);
                }
                [strout writeCString: buffer];
                [strout writeCString: end_of_line];
        } else {
                [strout writeString: @"CRYST1    1.000    1.000    1.000  90.00  90.00  90.00 P 1           1 "];
                [strout writeCString: end_of_line];
        }

        /* ORIGX */

        /* SCALE */
        MTMatrix44 *mat = [self getDescriptorForKey: @"SCALEMATRIX"];
        if (mat)
        {
                memset(buffer,32,80);
                buffer[81]='\0';
                buffer[80]='\n';
                buffer[0]='S';buffer[1]='C';buffer[2]='A';buffer[3]='L';buffer[4]='E';buffer[5]='1';
                sprintf(buffer+10,"%10.6f",[mat atRow: 0 col: 0]);
                sprintf(buffer+20,"%10.6f",[mat atRow: 1 col: 0]);
                sprintf(buffer+30,"%10.6f     ",[mat atRow: 2 col: 0]);
                sprintf(buffer+45,"%10.5f",[mat atRow: 3 col: 0]);
                [strout writeCString: buffer];
                [strout writeCString: end_of_line];
                memset(buffer,32,80);
                buffer[81]='\0';
                buffer[80]='\n';
                buffer[0]='S';buffer[1]='C';buffer[2]='A';buffer[3]='L';buffer[4]='E';buffer[5]='2';
                sprintf(buffer+10,"%10.6f",[mat atRow: 0 col: 1]);
                sprintf(buffer+20,"%10.6f",[mat atRow: 1 col: 1]);
                sprintf(buffer+30,"%10.6f     ",[mat atRow: 2 col: 1]);
                sprintf(buffer+45,"%10.5f",[mat atRow: 3 col: 1]);
                [strout writeCString: buffer];
                [strout writeCString: end_of_line];
                memset(buffer,32,80);
                buffer[81]='\0';
                buffer[80]='\n';
                buffer[0]='S';buffer[1]='C';buffer[2]='A';buffer[3]='L';buffer[4]='E';buffer[5]='3';
                sprintf(buffer+10,"%10.6f",[mat atRow: 0 col: 2]);
                sprintf(buffer+20,"%10.6f",[mat atRow: 1 col: 2]);
                sprintf(buffer+30,"%10.6f     ",[mat atRow: 2 col: 2]);
                sprintf(buffer+45,"%10.5f",[mat atRow: 3 col: 2]);
                [strout writeCString: buffer];
                [strout writeCString: end_of_line];
        }
}


-(void)writePDBRemark:(int)remid to:(MTStream*)strout        //@nodoc
{
        char end_of_line[] = { 10, 0 };
        NSString *key = [NSString stringWithFormat:@"REMARK %3d",remid];
        //printf(" checking for: %@\n", key);

        NSString *remark = [self getDescriptorForKey: key];
        if (remark)
        {
                char *nexts;
                char *input = (char*)[remark cString];
                int len, wide;

                len = strlen (input);

                // first line is empty
                [strout writeString: key];
                [strout writeString: @"                                                                    \n"];
                // parse line by line
                while (len > 0)
                {
                        nexts = strchr (input, 10); // find next end-of-line
                        if (nexts)
                        {
                                wide = (nexts - input);
                        } else {
                                wide = len;         // everything
                        }
                        if (wide > (71-12))
                        {
                                wide = 71-12;
                        }
                        input[wide] = '\0';
                        //printf("%@ (%d) %s\n", key, wide, input);
                        [strout writeString: key];
                        [strout writeCString: " "];
                        [strout writeCString: input];
                        [strout writeCString: end_of_line];
                        len -= wide+1;
                        input += wide+1;
                }
        }
}


-(void)writePDBConectTo:(MTStream*)strout        //@nodoc
{

        MTChain *chain;
        NSEnumerator *e_chain = [chains objectEnumerator];
        while ((chain = [e_chain nextObject]))
        {
                NSEnumerator *e_res = [chain allResidues];
                MTResidue *residue;
                while ((residue = [e_res nextObject]))
                {
                        [self writePDBConectResidue: residue to: strout];
                }
                e_res = [chain allHeterogens];
                while ((residue = [e_res nextObject]))
                {
                        [self writePDBConectResidue: residue to: strout];
                }
        }
}


-(void)writePDBConectResidue:(MTResidue*)residue to:(MTStream*)strout        //@nodoc
{
        NSEnumerator *e_atm = [residue allAtoms];
        MTAtom *atom;
        while ((atom = [e_atm nextObject]))
        {
                unsigned int i=0;
                NSEnumerator *e_atm2 = [atom allBondedAtoms];
                MTAtom *atom2;
                char buffer[82];
                while ( (atom2 = [e_atm2 nextObject]) 
                        && !([[atom name] isEqualToString:@"N"] && [[atom2 name] isEqualToString:@"C"])
                        && ([[atom number] compare: [atom2 number]] == NSOrderedDescending) )
                        /* we don't write covalent bonds N-C betweenn residues
                         * we don't write bonds twice (atom bonds to atom2, and
                         * atom2 bonds to atom)  */
                {
                        if (i==0)
                        {
                                memset(buffer,32,82);
                                buffer[81]='\0';
                                buffer[80]='\n';
                                sprintf(buffer,"CONECT% 5u",[[atom number] intValue]);
                                buffer[11]=' ';
                        }
                        snprintf(buffer+(i*5)+11,6,"% 5u",[[atom2 number] intValue]);
                        i++;
                        buffer[(i*5)+11]=' ';
                        if (i>=4)
                        {
                                i=0;
                                [strout writeCString: buffer];
                        }
                }
                if (i>0)
                {
                        [strout writeCString: buffer];
                }
        }
}


-(void)writePDBChain:(MTChain*)chain to:(MTStream *)strout fromSerial:(unsigned int*)serial        //@nodoc
{
        MTResidue *residue;
        NSEnumerator *e_res = [chain allResidues];
        MTResidue *lastres = nil;
        while ((residue = [e_res nextObject]))
        {
                if ([residue isModified])
                {
                        [self writePDBHeterogen: residue inChain: chain to: strout fromSerial: serial];
                } else {
                        [self writePDBResidue: residue inChain: chain to: strout fromSerial: serial];
                }
                lastres=residue;
        } /* all residues */
        
        /* write out TER */
        if (lastres != nil)
        { /* only if there is an amino acid/nucleic acid in this chain */
                int i, length;
		char buffer[82];
                char tbuffer[10];
                memset(buffer,32,80);
                buffer[81]='\0';
                buffer[80]='\n';
                buffer[0]='T';buffer[1]='E';buffer[2]='R';
                buffer[21] = [chain code]; /* chain identifier */
		//Only using three here leads to putting the null character in tbuffer[2]
		//Which then causes the buffer to be terminated at position 19
                [[lastres name] getCString: tbuffer maxLength: 4]; /* residue name */
		//Handle variable length residue ids 
		//(up to 4 - although strictly 4 letter res ids shouldnt be allowed)
		length = ([[lastres name] length] > 4) ? 4: [[lastres name] length];
		for(i=0; i<length; i++)
			buffer[i+17] = tbuffer[i];
			
                snprintf(tbuffer, 10, "% 4u    ", [[lastres number] intValue]); /* residue number */
                buffer[22]=tbuffer[0]; buffer[23]=tbuffer[1]; buffer[24]=tbuffer[2]; buffer[25]=tbuffer[3];
                snprintf(buffer+6,6,"% 5u",*serial); buffer[11]=' '; *serial = *serial + 1;
                [strout writeCString: buffer];
        }
        
        e_res = [chain allHeterogens];
        while ((residue = [e_res nextObject]))
        {
                [self writePDBHeterogen: residue inChain: chain to: strout fromSerial: serial];
        } /* all heterogens */
        
        e_res = [chain allSolvent];
        while ((residue = [e_res nextObject]))
        {
                [self writePDBHeterogen: residue inChain: chain to: strout fromSerial: serial];
        } /* all solvent */
        
}


-(void)writePDBResidue:(MTResidue*)residue inChain:(MTChain*)chain to:(MTStream*)strout fromSerial:(unsigned int*)serial        //@nodoc
{
        NSString *t_str;
        int t_chrg;
        char buffer[82];
        char tbuffer[10];
        char tbuffer2[5];
        memset(buffer,32,80);
        buffer[0]='A';buffer[1]='T';buffer[2]='O';buffer[3]='M';
        buffer[21] = [chain code]; /* chain identifier */

	if([[residue name] length] == 3)
	{
		//Only using three for tbuffer size leads to putting the null character in tbuffer[2]
		//Which then causes the buffer to be terminated at position 19
		[[residue name] getCString: tbuffer maxLength: 8]; /* residue name */
		buffer[17] = tbuffer[0]; buffer[18] = tbuffer[1]; buffer[19] = tbuffer[2];
	}
	else if([[residue name] length] == 1)	
	{
		//Single letter nucleic acid id - Using the same code as above
		//leads to putting the NULL character in buffer[18].
		[[residue name] getCString: tbuffer maxLength: 8]; /* residue name */
		buffer[17] = tbuffer[0]; buffer[18] = 32; buffer[19] = 32;
	}
	else if([[residue name] length] == 4)
	{
		NSWarnLog(@"Four letter residue names are not supported by PDB standard");
		[[residue name] getCString: tbuffer maxLength: 8];
		buffer[17] = tbuffer[0]; 
		buffer[18] = tbuffer[1]; 
		buffer[19] = tbuffer[2];
		if(isStrict)
		{
			NSWarnLog(@"StrictPDBWriting is YES. Writing a three letter code");
		}
		else
		{
			NSWarnLog(@"StrictPDBWriting is NO. Writing a four letter code");
			buffer[20] = tbuffer[3];	
		}
	}
	
        snprintf(tbuffer, 10, "% 4u    ", [[residue number] intValue]); /* residue number */
        buffer[22]=tbuffer[0]; buffer[23]=tbuffer[1]; buffer[24]=tbuffer[2]; buffer[25]=tbuffer[3];
        buffer[26] = [residue subcode]; /* insertion code */
        buffer[56]='1';buffer[57]='.';buffer[58]='0';buffer[59]='0'; /* occupancy */

        NSEnumerator *e_atms = [residue allAtoms];
        MTAtom *atom;
        while ((atom = [e_atms nextObject]))
        {
                double temperature,x,y,z;
                temperature = [atom temperature];
                x = [atom x];
                y = [atom y];
                z = [atom z];
                [atom setNumber: *serial];
                snprintf(buffer+6,6,"% 5u",*serial); *serial = *serial + 1;
                buffer[11]=' ';
                tbuffer[0]=32; tbuffer[1]=32; tbuffer[2]=32; tbuffer[3]=32;
                [[atom name] getCString: tbuffer maxLength: 5];
		tbuffer[4]='\0';
                if (tbuffer[1]==0) tbuffer[1]=32;
                if (tbuffer[2]==0) tbuffer[2]=32;
                if (tbuffer[3]==0) tbuffer[3]=32;
                [[atom elementName] getCString: tbuffer2 maxLength: 3];
                /* elementName is prefix? */
                if (tbuffer[0]==tbuffer2[0])
                {
			//Some RNA names break pdb convention eg. H5''
			//which should be 'H5' since the H should be in the
			//second column of the atom name field. Hence if
			//we follow the convention H5'' will become H5'
			//and thus be wrong. We have to check for this case here.
                        if (tbuffer2[1]==0 && ([[atom name] length] < 4)) 
                        {  // length == 1
                                buffer[12]=32; buffer[13]=tbuffer[0];
                                buffer[14]=tbuffer[1]; buffer[15]=tbuffer[2];
                        } else {
                           // length == 2
                                buffer[12]=tbuffer[0]; buffer[13]=tbuffer[1];
                                buffer[14]=tbuffer[2]; buffer[15]=tbuffer[3];
                        }
                } else {
                        buffer[12]=tbuffer[0]; buffer[13]=tbuffer[1];
                        buffer[14]=tbuffer[2]; buffer[15]=tbuffer[3];
                }
                sprintf(buffer+30,"% 8.3f",x);
                sprintf(buffer+38,"% 8.3f",y);
                sprintf(buffer+46,"% 8.3f",z);
                buffer[54]=' ';
                sprintf(buffer+60,"%6.2f",temperature);
                buffer[66]=' ';
                t_str = [atom elementName];
                buffer[76] = ' ';
                buffer[77] = ' ';
                if (t_str)
                {
                        if ([t_str length]==1)
                        {
                                buffer[77] = (char)[t_str characterAtIndex:0];
                        } else {
                                buffer[76] = (char)[t_str characterAtIndex:0];
                                buffer[77] = (char)[t_str characterAtIndex:1];
                        }
                }
                buffer[78] = ' ';
                buffer[79] = ' ';
                t_chrg = [atom charge];
                if (t_chrg != 0)
                {
                        if (t_chrg < 0)
                        {
                                buffer[78] = (char)(0-t_chrg+48);
                                buffer[79] = '-';
                        } else {
                                buffer[78] = (char)(t_chrg+48);
                                buffer[79] = '+';
                        }
                }
                buffer[81]='\0';
                buffer[80]='\n';
                [strout writeCString: buffer];
        }
}


-(void)writePDBHeterogen:(MTResidue*)residue inChain:(MTChain*)chain to:(MTStream*)strout fromSerial:(unsigned int*)serial        //@nodoc
{
        NSString *t_str;
        int t_chrg;
        char buffer[82];
        char tbuffer[10];
        char tbuffer2[5];
        memset(buffer,32,82);
        buffer[81]='\0';
        buffer[80]='\n';
        buffer[0]='H';buffer[1]='E';buffer[2]='T';buffer[3]='A';buffer[4]='T';buffer[5]='M';
        buffer[21] = [chain code]; /* chain identifier */
	//Only using three here leads to putting the null character in tbuffer[2]
	//Which then causes the buffer to be terminated at position 19
        [[residue name] getCString: tbuffer maxLength: 4]; /* residue name */
        buffer[17] = tbuffer[0]; buffer[18] = tbuffer[1]; buffer[19] = tbuffer[2];
        snprintf(tbuffer, 10, "% 4u    ", [[residue number] intValue]); /* residue number */
        buffer[22]=tbuffer[0]; buffer[23]=tbuffer[1]; buffer[24]=tbuffer[2]; buffer[25]=tbuffer[3];
        buffer[26] = [residue subcode]; /* insertion code */
        buffer[56]='1';buffer[57]='.';buffer[58]='0';buffer[59]='0'; /* occupancy */

        NSEnumerator *e_atms = [residue allAtoms];
        MTAtom *atom;
        while ((atom = [e_atms nextObject]))
        {
                double temperature,x,y,z;
                temperature = [atom temperature];
                x = [atom x];
                y = [atom y];
                z = [atom z];
                [atom setNumber: *serial];
                snprintf(buffer+6,6,"% 5u",*serial); *serial = *serial + 1;
                buffer[11]=' ';
                tbuffer[0]=32; tbuffer[1]=32; tbuffer[2]=32; tbuffer[3]=32;
                [[atom name] getCString: tbuffer maxLength: 5];
                if (tbuffer[1]==0) tbuffer[1]=32;
                if (tbuffer[2]==0) tbuffer[2]=32;
                if (tbuffer[3]==0) tbuffer[3]=32;
                [[atom elementName] getCString: tbuffer2 maxLength: 3];
                /* elementName is prefix? */
                if (tbuffer[0]==tbuffer2[0])
                {
                        if (tbuffer2[1]==0) 
                        {  // length == 1
                                buffer[12]=32; buffer[13]=tbuffer[0];
                                buffer[14]=tbuffer[1]; buffer[15]=tbuffer[2];
                        } else {
                           // length == 2
                                buffer[12]=tbuffer[0]; buffer[13]=tbuffer[1];
                                buffer[14]=tbuffer[2]; buffer[15]=tbuffer[3];
                        }
                } else {
                        buffer[12]=tbuffer[0]; buffer[13]=tbuffer[1];
                        buffer[14]=tbuffer[2]; buffer[15]=tbuffer[3];
                }
                sprintf(buffer+30,"% 8.3f",x);
                sprintf(buffer+38,"% 8.3f",y);
                sprintf(buffer+46,"% 8.3f",z);
                buffer[54]=' ';
                sprintf(buffer+60,"%6.2f",temperature);
                buffer[66]=' ';
                buffer[76] = ' ';
                buffer[77] = ' ';
                t_str = [atom elementName];
                if ([t_str length]==1)
                {
                        buffer[77] = (char)[t_str characterAtIndex:0];
                } else {
                        buffer[76] = (char)[t_str characterAtIndex:0];
                        buffer[77] = (char)[t_str characterAtIndex:1];
                }
                buffer[78] = ' ';
                buffer[79] = ' ';
                t_chrg = [atom charge];
                if (t_chrg != 0)
                {
                        if (t_chrg < 0)
                        {
                                buffer[78] = (char)(0-t_chrg+48);
                                buffer[79] = '-';
                        } else {
                                buffer[78] = (char)(t_chrg+48);
                                buffer[79] = '+';
                        }
                }
                [strout writeCString: buffer];
        }
}


-(MTChain*)mkChain:(NSNumber*)p_chain        //@nodoc
{
        MTChain *chain = [self getChain:p_chain];
        if (chain == nil)
        {
                chain = [MTChainFactory newChainWithCode:[p_chain charValue]];
                [chains addObject:chain];
                [chain setStructure:self];
        }
        return chain;
}


-(void)expdata:(int)p_expdata        //@nodoc
{
        [self setDescriptor: [NSNumber numberWithInt: p_expdata] withKey: MTSTRX_EXPERIMENT_key];
}


-(void)resolution:(float)p_resolution        //@nodoc
{
        [self setDescriptor: [NSNumber numberWithFloat: p_resolution] withKey: MTSTRX_RESOLUTION_key];
}


-(void)header:(NSString*)p_header        //@nodoc
{
        [self setDescriptor: p_header withKey: MTSTRX_HEADER_key];
}


-(void)title:(NSString*)p_title        //@nodoc
{
        [self setDescriptor: p_title withKey: MTSTRX_TITLE_key];
}


-(void)keywords:(NSString*)p_kw        //@nodoc
{
        if (!p_kw)
        {
                return;
        }
        NSMutableArray *t_arr = [NSMutableArray new];
        char *t_str = (char*)[p_kw lossyCString];
        int slen = strlen(t_str);
        int lasti=0;
        int i;
        for (i=0; i<slen; i++)
        {
                if (t_str[i]=='\0')
                {
                        break;
                }
                // ',' is the field delimiter
                if (t_str[i]==',')
                {
                        t_str[i]='\0';
                        [t_arr addObject:[[NSString stringWithCString:(t_str+lasti)]clipleft]];
                        lasti = i+1;
                }
        }
        if (i>0 && lasti != i)
        {
                [t_arr addObject:[[NSString stringWithCString:(t_str+lasti)]clipleft]];
        }
        [self setDescriptor: t_arr withKey: MTSTRX_KEYWORDS_key];
}

/*
 *   The SCALE1 record in PDB files defines the transformation from
 *   orthogonal coordinates to fractional crystallographic representation.
 *   This code computes the back transformation matrix to regain the
 *   orthogonal coordinates from the crystallographic ones.
 */
-(MTMatrix53*)backTransformation
{
        MTVector *uv = [self getDescriptorForKey: @"UNITVECTOR"];
        MTVector *ua = [self getDescriptorForKey: @"UNITANGLES"];
        if (!(uv && ua))
        {
                return nil;
        }
        double a = [uv atDim: 0];
        double b = [uv atDim: 1];
        double c = [uv atDim: 2];
        double aalpha = [ua atDim: 0]*M_PI/180.0;
        double abeta = [ua atDim: 1]*M_PI/180.0;
        double agamma = [ua atDim: 2]*M_PI/180.0;

        double tCOSA = cos(aalpha);
        double tCOSB = cos(abeta);
        double tCOSG = cos(agamma);
        double tSINA = sin(aalpha);
        double tSINB = sin(abeta);
        double tSING = sin(agamma);

        double V = a*b*c*sqrt(1-tCOSA*tCOSA-tCOSB*tCOSB-tCOSG*tCOSG+2*tCOSA*tCOSB*tCOSG);

        MTMatrix53 *res = [MTMatrix53 matrixIdentity];
        [res atRow: 0 col: 0 value: a];
        [res atRow: 1 col: 0 value: (b*tCOSG)];
        [res atRow: 2 col: 0 value: (c*tCOSB)];
        [res atRow: 0 col: 1 value: 0.0];
        [res atRow: 1 col: 1 value: (b*tSING)];
        [res atRow: 2 col: 1 value: (c*(tCOSA-tCOSB*tCOSG)/tSING)];
        [res atRow: 0 col: 2 value: 0.0];
        [res atRow: 1 col: 2 value: 0.0];
        [res atRow: 2 col: 2 value: (V/a/b/tSING)];

        //printf("back transformation:\n%@\n",[res description]);

        return res;
}


-(void)date:(NSCalendarDate*)p_date        //@nodoc
{
        [self setDescriptor: p_date withKey: MTSTRX_DATE_key];
}


-(void)revdate:(NSCalendarDate*)p_date        //@nodoc
{
        [self setDescriptor: p_date withKey: MTSTRX_REVDATE_key];
}


-(void)pdbcode:(NSString*)p_pdbcode        //@nodoc
{
        [self setDescriptor: p_pdbcode withKey: MTSTRX_PDBCODE_key];
}


-(void)hetname:(id)name forKey:(NSString*)key        //@nodoc
{
        if (hetnames==nil)
        {
                hetnames = RETAIN([NSMutableDictionary new]);
        }
        [hetnames setObject:name forKey:key];
}


@end



/* convert NSCalendarDate to the format DD-MMM-YY, where MMM is a textual 
 * representation of a month
 */
NSString *mkTextDate (NSCalendarDate *caldate)
{
        NSString *t_m;
        int month=1;
        int year=2000;
        int day=1;

        if (caldate)
        {
                month = [caldate monthOfYear];
                day = [caldate dayOfMonth];
                year = [caldate yearOfCommonEra];
        }
        if (year >= 2000)
        {
                year -= 2000;
        } else {
                year -= 1900;
        }

        switch (month)
        {
        case 1:  t_m = @"JAN"; break;
        case 2:  t_m = @"FEB"; break;
        case 3:  t_m = @"MAR"; break;
        case 4:  t_m = @"APR"; break;
        case 5:  t_m = @"MAI"; break;
        case 6:  t_m = @"JUN"; break;
        case 7:  t_m = @"JUL"; break;
        case 8:  t_m = @"AUG"; break;
        case 9:  t_m = @"SEP"; break;
        case 10:  t_m = @"OCT"; break;
        case 11:  t_m = @"NOV"; break;
        case 12:  t_m = @"DEC"; break;
        default: t_m = @"XXX";
        }

        return [NSString stringWithFormat:@"%02d-%@-%02d",day,t_m,year];
}


