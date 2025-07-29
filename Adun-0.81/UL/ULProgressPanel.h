/*
   Project: Adun

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/
#ifndef _ULPROGRESSPANEL_
#define _ULPROGRESSPANEL_

#include <AppKit/AppKit.h>
#include "ULFramework/ULFrameworkDefinitions.h"

/**
Each instance creates and controls an onscreen progess panel.

\ingroup interface
*/

@interface ULProgressPanel : NSObject
{
	BOOL modalMode;
	BOOL observingNotification;
	id panel;
	id progressBar;
	id userInfo;
	id displayTitle;
	NSString* userInfoString;
}
/**
Description forthcoming
*/
+ (id) progressPanelWithTitle: (NSString*) string1
	message: (NSString*) string2 
	progressInfo: (NSString*) string3;
/**
Description forthcoming
*/
- (id) initWithTitle: (NSString*) string1 
	message: (NSString*) string2 
	progressInfo: (NSString*) string3; 
/**
Description forthcoming
*/
- (void) endPanel;
/**
Description forthcoming
*/
- (void) runProgressPanel: (BOOL) flag;
/**
Description forthcoming
*/
- (void) setPanelTitle: (NSString*) string;
/**
Description forthcoming
*/
- (void) setMessage: (NSString*) string;
/**
Description forthcoming
*/
- (void) setProgressInfo: (NSString*) string;
/**
Description forthcoming
*/
- (void) setProgressBarValue: (NSNumber*) value;
/**
Description forthcoming
*/
- (void) setIndeterminate: (BOOL) value;
/**
Description forthcoming
*/
- (BOOL) updateStatusOnNotification: (NSString*) notificationName fromObject: (id) object;
/**
Description forthcoming
*/
- (void) removeStatusNotification: (NSString*) notificationName fromObject: object;
/**
Order the panel to the front.
*/
- (void) orderFront;
@end
#endif
