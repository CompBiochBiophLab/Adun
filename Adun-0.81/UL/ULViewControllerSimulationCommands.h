#ifndef _VIEWCONTROLLER_SIMULATIONCOMMANDS_
#define _VIEWCONTROLLER_SIMULATIONCOMMANDS_

#include "ViewController.h"

/**
Category for commands that can be dynamically 
sent to a running simulation.
\ingroup interface
*/

@interface ViewController (SimulationCommands)
/**
Description forthcoming
*/
- (void) halt: (id) sender;
/**
Description forthcoming
*/
- (void) restart: (id) sender;
/**
Description forthcoming
*/
- (void) terminateProcess: (id) sender;
/**
Description forthcoming
*/
- (void) start: (id) sender;
/**
Description forthcoming
*/
- (void) execute: (id) sender;
@end

#endif
