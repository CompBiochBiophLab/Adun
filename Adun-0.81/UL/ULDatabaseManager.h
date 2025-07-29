/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "ULFramework/ULFramework.h"

/**
Controls interface elements which allow the user
to maintain the different databases.
\ingroup interfaces
*/
@interface ULDatabaseManager : NSObject
{
	ULDatabaseInterface* databaseInterface;
	id addClientField;
	id removeClientField;
	id databaseLocation;
	id databasePanel;
	id tabView;
	id actionButton;
}
/**
Description forthcoming
*/
- (void) closeDatabasePanel: (id)sender;
/**
Description forthcoming
*/
- (void) addDatabase: (id)sender;
/**
Description forthcoming
*/
- (void) removeDatabase: (id)sender;
/**
Description forthcoming
*/
- (void) showAddDatabasePanel: (id)sender;
/**
Description forthcoming
*/
- (void) showRemoveDatabasePanel: (id)sender;
@end
