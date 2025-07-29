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


#ifndef MTMOLTALK_OH
#define MTMOLTALK_OH

#ifdef GNUSTEP
//For an unknown reason cocoa doest like this
extern const char *moltalk_version();
#endif


#include "MolTalk/MTAtom.h"
#include "MolTalk/MTAlPos.h"
#include "MolTalk/MTResidue.h"
#include "MolTalk/MTChain.h"
#include "MolTalk/MTStructure.h"
#include "MolTalk/MTVector.h"
#include "MolTalk/MTCoordinates.h"
#include "MolTalk/MTString.h"
#include "MolTalk/MTStream.h"
#include "MolTalk/MTFileStream.h"
#include "MolTalk/MTCompressedFileStream.h"
#include "MolTalk/MTMatrix.h"
#include "MolTalk/MTMatrix53.h"
#include "MolTalk/MTMatrix44.h"
#include "MolTalk/MTSelection.h"
#include "MolTalk/MTPairwiseStrxAlignment.h"
#include "MolTalk/MTPairwiseSequenceAlignment.h"
#include "MolTalk/MTSubstitutionMatrix.h"
#include "MolTalk/MTStructureFactory.h"
#include "MolTalk/MTChainFactory.h"
#include "MolTalk/MTResidueFactory.h"
#include "MolTalk/MTAtomFactory.h"

#endif /* MTMOLTALK_OH */
