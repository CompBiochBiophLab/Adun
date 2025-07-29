#include "AdunKernel/AdunMultithreadedNonbondedTerm.h"
#include <unistd.h>
#ifdef __APPLE__
#include <sys/sysctl.h>
#endif
#include "AdunKernel/AdunPureNonbondedTerm.h"
#include "AdunKernel/AdunShiftedNonbondedTerm.h"
#include "AdunKernel/AdunGRFNonbondedTerm.h"

static id workerThreadManager;

/**
Object which manages a set of worker threads - one for each available
 processor after the first.
 \todo Generalise so it can be used to thread any operation
 Just replace evaluateForces with performSelector:
 however have to handle when you want to thread a number of different operations.
 */
@interface AdNonbondedWorkerThreadManager: NSObject
{
	BOOL isFinished;
	int numberOfProcessors;
	int finishedThreads;
	NSMutableArray* workerThreads;
	NSLock* lock;
}
/**
Returns the applications singleton AdNonbondedWorkerThreadManager instance.
*/
+ (id) nonbondedWorkerThreadManager;
/**
Returns the number of processors detected.
The number of worker threads is one minus this number.
*/
- (int) numberOfProcessors;
/**
Distributes each of the AdNonbondedTerm objects in \e terms
to a worker thread each of which calls evaluteForces: on the 
provided object. The number of objects in \e terms must
be equal to the number of threads available.
The method returns immediately - use isFinished() to
determine when the threads have finished there calculations.
*/
- (void) evaluateForcesForTerms: (NSArray*) terms;
/**
Distributes each of the AdNonbondedTerm objects in \e terms
to a worker thread each of which calls evaluteEnergies: on the 
provided object. The number of objects in \e terms must
be equal to the number of threads available.
The method returns immediately - use isFinished() to
determine when the threads have finished there calculations.
*/
- (void) evaluateEnergiesForTerms: (NSArray*) terms;
/**
Updates the nonbonded lists of each of the threaded terms.
*/
- (void) updateTerms: (NSArray*) terms;
/**
After calling either evaluateForcesForTerms:() or evaluateEnergiesForTerms()
this method can be used to check when the threads have finish the calculation.
*/
- (BOOL) isFinished;
/**
Used be the worker threads to notify the manager when they have finished.
Must not be called by other objects.
*/
- (void) threadFinished;
@end

/**
Class representing a worker thread managed by an AdNonbondedWorkerThreadManager.
Objects of this class should only be created by the applications
AdNonbondedWorkerThreadManager instance.
*/
@interface AdWorkerThread: NSObject
{
	BOOL runWorker;
	BOOL invoke;
	BOOL threadReady;
	NSInvocation* invocation;
	NSPort* receivePort;
	NSPort* sendPort;
	id theObject;
	id manager;
}
/**
Same as initWithThreadManager except returns an autoreleased object
 */
+ (id) threadWithManager: (AdNonbondedWorkerThreadManager*) object;
/**
Designated initialiser. Only use this method to initialise this object.
*/
- (id) initWithThreadManager: (AdNonbondedWorkerThreadManager*) object;
/**
Should be called using detachNewThread:target:selector:.
When launched using this method the reciever creates an
NSConnetion using the supplied ports and sets itself
as the root proxy. It then enters a run loop and waits
for communication.
*/
- (void) runWorker: (NSArray*) ports;
/**
Ends a thread started with runWorker. 
Can be called on the proxy or main thread instance.
*/
- (void) endWorker;
/**
Sets the AdNonbondedTerm object that will be
operated on in the thread.
*/
- (void) setObject: (AdNonbondedTerm*) object;
/**
Sets the invocation that will be sent in the thread
*/
- (void) setInvocation: (NSInvocation*) invocation;
/**
Invokes the current invocation
*/
- (void) invoke;
/**
Returns YES if the worker thread has been spawned and is waiting.
*/
- (BOOL) threadReady;
@end

@implementation AdMultithreadedNonbondedTerm

- (NSArray*) _dividePairs: (id) pairs
{
	BOOL forward;
	int i, j, start, index;
	NSMutableArray* arrays = [NSMutableArray array], *array;

	for(i=0; i < numberOfProcessors; i++)
		[arrays addObject: [NSMutableArray array]];
	
	for(start=0, i=0; i < (int)[pairs count]; i++)
	{
		index = start;
		array = [arrays objectAtIndex: index];
		[array addObject: [pairs objectAtIndex: i]];
		//Add from first to last
		for(j=1; j < numberOfProcessors; j++)
		{
			if(j == (int)[pairs count])
				break;
				
			//Add empty sets to others
			index++;
			index = index%numberOfProcessors;
			//NSDebugLLog(@"Index %d", index);
			//NSDebugLLog(@"J is %d", j);
			array = [arrays objectAtIndex: index];
			[array addObject: [NSIndexSet indexSet]];
		}	
		
		start++;
		start = start%numberOfProcessors;
		
		/*if(forward)
		{
			[array1 addObject: [pairs objectAtIndex: i]];
			[array2 addObject: [NSIndexSet indexSet]];
			i++;
			if(i<(int)[pairs count])
			{
				[array1 addObject: [NSIndexSet indexSet]];
				[array2 addObject: [pairs objectAtIndex: i]];
			}
			forward = NO;
		}
		else
		{
			[array1 addObject: [NSIndexSet indexSet]];
			[array2 addObject: [pairs objectAtIndex: i]];
			i++;
			if(i<(int)[pairs count])
			{
				[array1 addObject: [pairs objectAtIndex: i]];
				[array2 addObject: [NSIndexSet indexSet]];
			}
			forward = YES;
		}*/
	}

	return arrays;
}

- (id) initWithDictionary: (NSDictionary*) dict
{
	return [self initWithTerm: [dict objectForKey: @"term"]];
}

- (id) initWithTerm: (AdNonbondedTerm*) nonbondedTerm	
{
	int i;
	id threadedTerm;

	NSDebugLLog(@"Threading", @"Multi Term - Initialising. Creating worker thread manager");
	threadManager = [AdNonbondedWorkerThreadManager nonbondedWorkerThreadManager];
	
	//Check how many processors there are
	//If there is only one then just return the nonbondedTerm
	numberOfProcessors = [threadManager numberOfProcessors];
	if(numberOfProcessors == 1)
	{
		NSWarnLog(@"Only one processor available - abandoning multi-threading");
		return [nonbondedTerm retain];
	}

	//Check that nonbondedTerm isnt nil
	//If it is then for the moment print a message and return nil
	if(nonbondedTerm == nil)
	{
		NSWarnLog(@"(AdMulithreadedNonbondedTerm) Nobonded term cannot be nil");
		return nil;
	}

	if((self = [super init]))
	{
		if(nonbondedTerm == nil)
			return self;
	
		mainTerm = [nonbondedTerm retain];
		threadedTerms = [NSMutableArray new];
		allTerms = [NSMutableArray new];
		[allTerms addObject: mainTerm];
		
		NSDebugLLog(@"Threading", @"Multi Term - Original nonbonded term:\n %@", [mainTerm description]);
		
		//Divide the nonbonded pairs	
		NSDebugLLog(@"Threading", @"Multi Term - Dividing original term into %d instances", numberOfProcessors);
		dividedPairs = [self _dividePairs: [mainTerm nonbondedPairs]];
		[dividedPairs retain];
		
		//Create thread objects
		[mainTerm setNonbondedPairs: [dividedPairs objectAtIndex: 0]];
		[mainTerm setAutoUpdateList: NO];
		NSDebugLLog(@"Threading", @"\tMain Term (Runs in main thread):\n %@", [mainTerm description]);
		for(i=1; i < numberOfProcessors; i++)
		{
			NSDebugLLog(@"Threading", @"Multi Term - Creating copy for processor %d", i);
			threadedTerm =  [[nonbondedTerm copy] autorelease];
			[threadedTerms addObject: threadedTerm];
			[allTerms addObject: threadedTerm]; 
			[threadedTerm setNonbondedPairs: [dividedPairs objectAtIndex: i]];
			[threadedTerm setAutoUpdateList: NO];
			NSDebugLLog(@"Threading", @"\tThread %d:\n %@",i, [threadedTerm description]);
		}
		
		NSDebugLLog(@"Threading", @"Multi Term - Setting update interval %d", [mainTerm updateInterval]);
		[[AdMainLoopTimer mainLoopTimer]
			sendMessage: @selector(updateTerms) 
			toObject: self 
			interval: [mainTerm updateInterval] 
			name: @"AdMultiThreadedTermUpdateMessage"];

	}

	return self;
}

- (void) dealloc
{
	if(mainTerm != nil)
		[[AdMainLoopTimer mainLoopTimer]
			removeMessageWithName: @"AdMultiThreadedTermUpdateMessage"];
			
	[dividedPairs release];
	[mainTerm release];
	[threadedTerms release];
	[allTerms release];
	[super dealloc];
}

- (void) evaluateEnergy
{
	NSDebugLLog(@"Threading", @"Multi Term - Calling evaluateEnergies on %@", threadManager);
	[threadManager evaluateEnergiesForTerms: threadedTerms];
	NSDebugLLog(@"Threading", @"Multi Term - Calling evaluateEnergies on main thread instance");
	[mainTerm evaluateEnergy];
	NSDebugLLog(@"Threading", @"Multi Term - Main thread finished. Waiting for others ...");
	while(![threadManager isFinished])
	{
		//wait;
	}
	
	NSDebugLLog(@"Threading", @"Multi Term - Done");	
}

- (void) evaluateForces
{
	int i, j, k, finishedThreads = 0;
	AdMatrix* forces1;
	id threadedObj;

	[allTerms makeObjectsPerformSelector: @selector(clearForces)];
	NSDebugLLog(@"Threading", @"Multi Term - Calling evaluateForces on %@", threadManager);
	[threadManager evaluateForcesForTerms: threadedTerms];
	NSDebugLLog(@"Threading", @"Multi Term - Calling evaluateForces on main thread instance");
	[mainTerm evaluateForces];
	
	NSDebugLLog(@"Threading", @"Multi Term - Main thread finished. Waiting for others ...");
	while(![threadManager isFinished])
	{
		//wait;
	}
	NSDebugLLog(@"Threading", @"Multi Term - Threads finished - collating forces");
	
	//Possibly all threads can write to shared memory
	//Probably wont have that great an impact however.
	for(k=0; k < numberOfProcessors; k++)
	{
		forces1 = [[allTerms objectAtIndex: k] forces];
		for(i=0; i<forces->no_rows; i++)
			for(j=0; j<3; j++)
				forces->matrix[i][j] += forces1->matrix[i][j];	
	}
	
	NSDebugLLog(@"Threading", @"Multi Term - Done");
}

- (void) updateTerms
{
	int i, j, k, finishedThreads = 0;
	AdMatrix* forces1;
	id threadedObj;
	
	NSDebugLLog(@"Threading", @"Multi Term - Calling updateTerms on %@", threadManager);
	[threadManager updateTerms: threadedTerms];
	NSDebugLLog(@"Threading", @"Multi Term - Calling updateList: on main thread instance");
	[mainTerm updateList: NO];
	
	NSDebugLLog(@"Threading", @"Multi Term - Main thread finished. Waiting for others ...");
	while(![threadManager isFinished])
	{
		//wait;
	}
		
	NSDebugLLog(@"Threading", @"Multi Term - Done");	
}

- (void) setExternalForceMatrix: (AdMatrix*) matrix
{
	forces = matrix;
}

- (double) electrostaticEnergy;
{
	int i;
	double energy = 0;
	
	for(i=0; i < numberOfProcessors; i++)
		energy += [[allTerms objectAtIndex: i] electrostaticEnergy];
		
	return energy;
}	

- (double) lennardJonesEnergy;
{
	int i;
	double energy = 0;
	
	for(i=0; i < numberOfProcessors; i++)
		energy += [[allTerms objectAtIndex: i] lennardJonesEnergy];
	
	return energy;
}

- (id) system
{
	return [mainTerm system];
}

- (NSString*) lennardJonesType
{
	return [mainTerm lennardJonesType];
}

@end

/**
Implementation of AdNonbondedTermWorkerThread
*/
@implementation AdNonbondedWorkerThreadManager

+ (void) initialize
{
	workerThreadManager = nil;
}

+ (id) nonbondedWorkerThreadManager
{
	if(workerThreadManager == nil)
		workerThreadManager =  [AdNonbondedWorkerThreadManager new];
		
	return [[workerThreadManager retain] autorelease];	
}

- (id) init
{
	int i;
	AdWorkerThread* workerThread;
	NSPort *sendPort, *receivePort;
	NSMutableArray* ports = [NSMutableArray array];
	id proxy;

	NSDebugLLog(@"Threading", @"Thread Manager - Initialising. " 
		"Will create and manage one worker thread for each processor beyond the first");

	if(self = [super init])
	{
		lock = [NSLock new];
		workerThreads = [NSMutableArray new];
		[self numberOfProcessors];
		for(i=1; i<numberOfProcessors; i++)
		{
			[ports removeAllObjects];	
			workerThread = [AdWorkerThread threadWithManager: self];
		
			NSDebugLLog(@"Threading", @"Thread Manager - Preparing to detach worker thread %d of %d.", i, numberOfProcessors -1);
			//Detach the thread 		
			[NSThread detachNewThreadSelector: @selector(runWorker:)
				toTarget: workerThread
				withObject: ports];
			
			[workerThreads addObject: workerThread];
		}
	}

	NSDebugLLog(@"Threading", @"Thread Manager - Waiting for worker threads to register with me");
	i = 0;
	while(i < (numberOfProcessors - 1))
	{
		while(![[workerThreads objectAtIndex: i] threadReady]);
		NSDebugLLog(@"Threading",  @"Thread %d ready", i);
		i++;	
	}
	
	NSDebugLLog(@"Threading", @"Thread Manager - All worker threads registered -  %@", workerThreads);
	
	return self;
}

- (void) dealloc
{
	[lock release];
	[workerThreads release];
	[super dealloc];
}

- (int) numberOfProcessors
{
	//FIXME: Should also check which are available etc.
#ifdef __APPLE__ 
	//On apple this is the way is has to be done
	//They don't have _SC_NPROCESSORS_CONF since its not posix standard.
	//mib stands for Management Information Base.
	size_t length = sizeof(numberOfProcessors); 
	int mib[2]; 
	
	mib[0] = CTL_HW; 
	mib[1] = HW_NCPU; 
	
	if (sysctl(mib, 2, &numberOfProcessors, &length, 0, 0) < 0)
		numberOfProcessors = 1;
	
	if(length != sizeof(numberOfProcessors))
		numberOfProcessors = 1; 
#else
	numberOfProcessors = sysconf(_SC_NPROCESSORS_CONF);  
#endif	 
	NSDebugLLog(@"Threading", @"Thread Manager - There are %d processors", numberOfProcessors);
	
	return numberOfProcessors;
}

- (void) evaluateForcesForTerms: (NSArray*) terms
{
	unsigned int i;
	NSMethodSignature* signature;
	NSInvocation* invocation;
	
	NSDebugLLog(@"Threading", @"Thread Manager - Requesting that workers perform force calculation");

	signature = [[terms objectAtIndex: 0] methodSignatureForSelector: @selector(evaluateForces)];
	invocation = [NSInvocation invocationWithMethodSignature: signature];
	[invocation setSelector: @selector(evaluateForces)];

	finishedThreads = 0;
	isFinished = NO;
	for(i=0; i<[terms count]; i++)
	{
		[[workerThreads objectAtIndex: i] setObject: [terms objectAtIndex: i]];
		[[workerThreads objectAtIndex: i] setInvocation: invocation];
	}
	
	[workerThreads makeObjectsPerformSelector: @selector(invoke)];	
}

- (void) evaluateEnergiesForTerms: (NSArray*) terms
{
	unsigned int i;
	NSMethodSignature* signature;
	NSInvocation* invocation;
	
	signature = [[terms objectAtIndex: 0] methodSignatureForSelector: @selector(evaluateEnergy)];
	invocation = [NSInvocation invocationWithMethodSignature: signature];
	[invocation setSelector: @selector(evaluateEnergy)];
	
	NSDebugLLog(@"Threading", @"Thread Manager - Requesting that workers perform energy calculation");
	finishedThreads = 0;
	isFinished = NO;
	for(i=0; i<[terms count]; i++)
	{
		[[workerThreads objectAtIndex: i] setObject: [terms objectAtIndex: i]];
		[[workerThreads objectAtIndex: i] setInvocation: invocation];
	}
	
	[workerThreads makeObjectsPerformSelector: @selector(invoke)];	
}

- (void) updateTerms: (NSArray*) terms
{
	BOOL reset = NO;
	unsigned int i;
	NSMethodSignature* signature;
	NSInvocation* invocation;
	
	signature = [[terms objectAtIndex: 0] methodSignatureForSelector: @selector(updateList:)];
	invocation = [NSInvocation invocationWithMethodSignature: signature];
	[invocation setSelector: @selector(updateList:)];
	[invocation setArgument: &reset atIndex: 2];
	
	NSDebugLLog(@"Threading", @"Thread Manager - Requesting that workers perform energy calculation");
	finishedThreads = 0;
	isFinished = NO;
	for(i=0; i<[terms count]; i++)
	{
		[[workerThreads objectAtIndex: i] setObject: [terms objectAtIndex: i]];
		[[workerThreads objectAtIndex: i] setInvocation: invocation];
	}
	
	[workerThreads makeObjectsPerformSelector: @selector(invoke)];	
}

- (BOOL) isFinished
{
	return isFinished;
}

- (void) threadFinished
{
	[lock lock];
	finishedThreads++;
	NSDebugLLog(@"Threading", @"Thread Manager - Worker thread finished - total %d of %d", finishedThreads, [workerThreads count]);
	if(finishedThreads == numberOfProcessors - 1)
		isFinished = YES;
	[lock unlock];
}

@end

/**
Implementation of AdNonbondedTermWorkerThread class
*/
@implementation AdWorkerThread

+ (id) threadWithManager: (AdNonbondedWorkerThreadManager*) object
{
	return [[[self alloc] initWithThreadManager: object] autorelease];
}

- (id) initWithThreadManager: (AdNonbondedWorkerThreadManager*) object
{
	if(self = [super init])
	{
		invoke = NO;
		threadReady = NO;
	
		//Only retain a weak reference to the manager
		if(object == nil)
		{
			[self release];
			self = nil;
		}
		else
			manager = object;
			
		sendPort = [[NSPort port] retain];
		receivePort = [[NSPort port] retain];	
	}
	
	return self;
}

- (void) dealloc
{
	[sendPort release];
	[receivePort release];
	[invocation release];
	[theObject release];
	[super dealloc];
}

- (void) runWorker: (NSArray*) ports
{
	NSAutoreleasePool* pool;
	
	pool = [NSAutoreleasePool new];
	runWorker = YES;
	
	NSDebugLLog(@"AdNonbondedTermWorkerThread", 
		     @"Worker Thread - Starting to run. Using ports %@", ports);

	threadReady = YES;
	[sendPort setDelegate: self];
	NSDebugLLog(@"AdNonbondedTermWorkerThread", @"Worker Thread - Receiving messages on %@", sendPort);
	[[NSRunLoop currentRunLoop] addPort: sendPort forMode: NSDefaultRunLoopMode];
	
	NSDebugLLog(@"AdNonbondedTermWorkerThread", 
		    @"Worker Thread - Entering run loop %@", [NSRunLoop currentRunLoop]);			
									     	
	while(runWorker)
	{
		[[NSRunLoop currentRunLoop] 
			runMode: NSDefaultRunLoopMode 
			beforeDate: [NSDate dateWithTimeIntervalSinceNow: 5]];
	}
	
	NSDebugLLog(@"AdNonbondedTermWorkerThread", @"Worker Thread - Exiting thread");
	[pool release];
}

- (void)handlePortMessage:(NSPortMessage *)portMessage
{
	NSDebugLLog(@"AdNonbondedTermWorkerThread", 
		    @"Worker Thread - Invoking %@", invocation);	
	[invocation invokeWithTarget: theObject];
	invoke=NO;
	NSDebugLLog(@"AdNonbondedTermWorkerThread", @"Worker thread - Finised.");
	[manager threadFinished];
}

- (void) endWorker
{
	runWorker = NO;
	threadReady = NO;
}

- (void) setObject: (AdNonbondedTerm*) object
{
	[theObject release];
	theObject = [object retain];
}

- (void) setManager: (AdNonbondedWorkerThreadManager*) object
{
	manager = object;
}

/**
 Sets the invocation that will be sent in the thread
 */
 - (void) setInvocation: (NSInvocation*) anObject
 {
	[invocation release];
	invocation = [anObject retain];
}
 
/**
 Invokes the current invocation
 */
- (void) invoke
{
	NSPortMessage* message;
		
	message = [[NSPortMessage alloc] 
			initWithSendPort: sendPort 
			receivePort: receivePort 
			components: [NSArray arrayWithObject: [NSData data]]];
		
	NSDebugLLog(@"AdNonbondedTermWorkerThread", @"Sending message %@ - receive port %@", message, receivePort);			
	[message sendBeforeDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
	[message release];		
}

- (BOOL) threadReady
{
	return threadReady;
}
@end
