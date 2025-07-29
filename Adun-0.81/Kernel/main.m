#define _GNU_SOURCE
#include <stdio.h>
#include <float.h>
#include <fenv.h>
#include <unistd.h>
#ifndef __FREEBSD__
#include <mcheck.h>
#endif
#include <stdlib.h>
#include <locale.h>
#include "AdunKernel/AdCoreAdditions.h"
#include "AdunKernel/AdunController.h"
#include "AdunKernel/AdunCore.h"
#include "AdunKernel/AdunIOManager.h"
//If this is a parallel build include mpi.h
#ifdef PARALLEL
#include <mpi.h>
#endif

/**
\defgroup Base AdunBase Library 
\ingroup Kernel
**/

/**

\defgroup Kernel Kernel

The Kernel part of Adun contains the AdunCore simulation program along with the AdunKernel framework and the AdunBase
library on which it is built. 
**/

void printHelp(void);

void printHelp(void)
{
	GSPrintf(stdout, @"\nUsage: AdunCore [options]\n\n");
	GSPrintf(stdout, @"All Options must be specified as option value pairs\n");
	GSPrintf(stdout, @"Invalid options are ignored\n\n");
	GSPrintf(stdout, @"Command Line Options\n\n");
	GSPrintf(stdout, @"  Required:\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-Template", @"A valid Adun template file"); 
	GSPrintf(stdout, @"\tOR\n"); 
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-Continue", @"An Adun simulation output file");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"The corresponding simulation data must be in the same directory."); 
	GSPrintf(stdout, @"\n  General Optional Arguments\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-RunInteractive", @"If YES the simulation loop is spawned as a separate thread.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"The main thread then enters a run loop and can serve external requests.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"If NO then interaction is not possible with the simulation.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: NO\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-ConnectToAdServer", @"If YES the simulation registers its existance with a local AdServer daemon.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"This allows the simulation to be viewed and controlled from the Adun GUI.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: NO\n");
	GSPrintf(stdout, @"\n  Template Optional Arguments: (Only compatible with -Template)\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-ExternalObjects", @"A dictionary in plist format.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Its contents extend the externalObjects section of the template.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"If there are duplicate keys this dictionary takes precedence.\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-SimulationOutputDir", @"Directory where simulation data directory will be stored.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: SimulationOutput\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-ControllerOutputDir", @"Directory where controller data will be stored.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: ControllerOutput\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-CreateLogFiles", @"If YES log files are created. If NO they are not.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: YES\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-LogFile", @"File where the program output will be written.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: AdunCore.log\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-ErrorFile", @"File where program errors and warnings will be written.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: AdunCore.errors\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-RedirectOutput", @"If YES the log files will be moved to the simulation output directory.");
	GSPrintf(stdout, @"\t%25@%-@\n", @"", @"Default value: YES.\n");
	GSPrintf(stdout, @"\n  Continue Optional Arguments: (Only compatible with -Continue)\n");
	GSPrintf(stdout, @"\t%-25@%-@\n", @"-Options", @"An Adun continuation options file");
}

//Wrapper around AdLogError adding some extra print outs
void logError(NSError*);

void logError(NSError* error)
{
	GSPrintf(stdout, @"Simulation exited due to an error. See the error log for more details\n");
	NSLog(@"Detected error at top level - Simulation exiting");
	NSLog(@"Error details follow\n");
	AdLogError(error);
}

void uncaughtExceptionHandler(NSException* exception);

void uncaughtExceptionHandler(NSException* exception)
{
	NSError* error;
	AdIOManager* ioManager;
	
	ioManager = [AdIOManager appIOManager];
	NSWarnLog(@"Caught an %@ exception at the top level", [exception name]);
	NSWarnLog(@"Reason %@", [exception reason]);
	NSWarnLog(@"User info %@", [exception userInfo]);

	error = AdCreateError(AdunCoreErrorDomain,
				AdCoreUnexpectedExceptionError,
				@"Caught unexpected exception",
				@"This is probably due to a programming error in the program or the AdunKernel library",
				@"Notify the adun developers supplying the log for the simulation run");
	NSWarnLog(@"Error details follow ...");			
	logError(error);
	NSWarnLog(@"Cleaning up core");	
	if([ioManager isConnected])
		[ioManager closeConnection: error];

	[ioManager release];
#ifdef GNUSTEP
	NSLog(@"HERE");
	//Not really necessary but anyway ...
	[[NSAutoreleasePool currentPool] release];
#endif	
#ifdef PARALLEL
	NSLog(@"HERE");
	MPI_Abort(MPI_COMM_WORLD, [error code]);
#else
	exit([error code]);
#endif
}

//Logs the precision of the double type for the current processor
//Checks which floating point exceptions are enabled
//Clears floating point traps if any are set	

void floatingPointSettings(void);

void floatingPointSettings(void)
{
	GSPrintf(stdout, @"Floating Point Parameters for DOUBLE type.\n\n");
	GSPrintf(stdout, @"\tMantissa precision (base 2)  : %d.\n", DBL_MANT_DIG); 
	GSPrintf(stdout, @"\tMantissa precision (base 10) : %d.\n", DBL_DIG); 
	GSPrintf(stdout, @"\tMinumum exponent: %d -  Corresponds to %d in base 10.\n", DBL_MIN_EXP, DBL_MIN_10_EXP);
	GSPrintf(stdout, @"\tMaximum exponent: %d -  Corresponds to %d in base 10.\n", DBL_MAX_EXP, DBL_MAX_10_EXP);
	GSPrintf(stdout, @"\tMinumum floating point number %E\n", DBL_MIN);
	GSPrintf(stdout, @"\tMaximum floating point number %E\n", DBL_MAX);
	GSPrintf(stdout, @"\tEpsilon: %E.\n", DBL_EPSILON);
	GSPrintf(stdout, @"\tEpsilon is the smallest number such that '1.0 + epsilon != 1.0' is true.\n\n");

	AdFloatingPointExceptionMask = 0;

#ifdef FE_DIVBYZERO
		AdFloatingPointExceptionMask = AdFloatingPointExceptionMask | FE_DIVBYZERO;
		GSPrintf(stdout, @"FE_DIVBYZERO detection supported and enabled\n");
#else
		GSPrintf(stdout, @"FE_DIVBYZERO not supported by the processor\n");
#endif

#ifdef FE_OVERFLOW
		AdFloatingPointExceptionMask = AdFloatingPointExceptionMask | FE_OVERFLOW;
		GSPrintf(stdout, @"FE_OVERFLOW detection supported and enabled\n");
#else
		GSPrintf(stdout, @"FE_OVERFLOW not supported by the processor\n");
#endif

#ifdef FE_UNDERFLOW
		AdFloatingPointExceptionMask = AdFloatingPointExceptionMask | FE_UNDERFLOW;
		GSPrintf(stdout, @"FE_UNDERFLOW detection supported and enabled\n");
#else
		GSPrintf(stdout, @"FE_UNDERFLOW not supported by the processor\n");
#endif

#ifdef FE_INVALID
		AdFloatingPointExceptionMask = AdFloatingPointExceptionMask | FE_INVALID;
		GSPrintf(stdout, @"FE_INVALID detection supported and enabled\n");
#else
		GSPrintf(stdout, @"FE_INVALID not supported by the processor\n");
#endif

/*
 * Disabling exception trapping is not supported on Mac OSX.
 * This means any floating point exception will cause SIGFPE
 * rendering the checking useless - may be a way around this.
 */

#if NeXT_RUNTIME != 1
	//disable traping of the supported errors
	fedisableexcept(AdFloatingPointExceptionMask);
#endif	
	
}

BOOL registerDefaults(NSError** error);

BOOL registerDefaults(NSError** error)
{
	BOOL success = YES;
	char *locale = "C";
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	NSMutableSet* debugLevels;
	NSProcessInfo  *processInfo = [NSProcessInfo processInfo];
	NSUserDefaults* userDefaults;

	setlocale(LC_ALL, locale);

	[defaults setObject: [NSNumber numberWithBool: NO] forKey:@"OutputMemoryStatistics"];
	[defaults setObject: [NSNumber numberWithBool: NO] forKey:@"TraceMemory"];
	[defaults setObject: [NSNumber numberWithBool: NO] forKey: @"ConnectToAdServer"];
	[defaults setObject: [NSNumber numberWithBool: NO] forKey: @"RunInteractive"];
	[defaults setObject: @"Cell" forKey: @"ListManagementMethod"];
	userDefaults = [NSUserDefaults standardUserDefaults];
	//Probably not strictly necessary
	[userDefaults synchronize];
	
	[userDefaults registerDefaults:defaults];
	debugLevels = [processInfo debugSet];
	[debugLevels addObjectsFromArray: 
	[[NSUserDefaults standardUserDefaults] objectForKey: @"DebugLevels"]];

	return success;
}

int main(int argc, char** argv)
{
	BOOL retval;
	int errorCode;
	id pool = [[NSAutoreleasePool alloc] init];	
	NSError* error;
	NSUserDefaults* userDefaults;
	AdIOManager* ioManager = nil;
	AdCore* core;
	id results, fileName;

#ifdef PARALLEL
	int rank, size;
	int dummy = 0;
	MPI_Status mpi_err;
	
	//Initialise the parallel environment if this is a parallel version   
	MPI_Init(&argc, &argv);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
#ifdef INIT_PASSES_ARGS
	//Pass arguments to other processes (required for some MPI distributions)
	if (rank != 0) 
		[NSProcessInfo initializeWithArguments: argv 
						 count: argc
					   environment: NULL];
#endif
	//Wait here until we get freed by the process in the next rank 
	//Ensures that one simulation gets started at a time
	if ( rank != (size - 1) )
		MPI_Ssend(&dummy,1,MPI_INT, rank+1,2,MPI_COMM_WORLD);
		
	GSPrintf(stdout, @"Starting rank %i\n",rank);
	fflush(stdout);
#endif	
 	
	error = nil;
	NSSetUncaughtExceptionHandler(uncaughtExceptionHandler);
	//Turn stack trace on
#ifdef GNUSTEP	
	setenv("GNUSTEP_STACK_TRACE", "YES", 1);
#endif	
	if(!registerDefaults(&error))
	{
		logError(error);
		errorCode = [error code];
		[pool release];
		exit(errorCode);
	}
	userDefaults = [NSUserDefaults standardUserDefaults];

	//setup tracing
	if([userDefaults boolForKey: @"TraceMemory"] == YES)
	{
#ifndef __FREEBSD__
		mtrace();
		//Possible this is too late for this call ...
		//Must be called before malloc is called anywhere.
		//Don't now if NSUserDefaults uses malloc at some stage but
		//I suspect it does.
		mcheck(NULL);
#endif
	}

	ioManager = [AdIOManager appIOManager];
	
	GSPrintf(stdout, @"\nChecking program directory structure\n\n");
	if(![ioManager checkProgramDirectories: &error])
	{
		logError(error);
		errorCode = [error code];
		printHelp();
		[ioManager release];
		[pool release];
		exit(errorCode);
	}

	/*
	 * Process the command line and determines the run mode and
	 * whether a continuation of a previous simulation was requested.
	 */
	GSPrintf(stdout, @"\nProcessing command line\n\n");
	if(![ioManager processCommandLine: &error])
	{
		logError(error);
		errorCode = [error code];
		printHelp();
		[ioManager release];
		[pool release];
		exit(errorCode);
	}

	/*
	 * Create the simulation log files. 
	 * Their names and location are determined by command-line
	 * arguments but default to AdunCore.log, AdunCore.error
	 * and the directory the program was launched from. 
	 * This call redirects the output to the previous log files
	 * if a continuation of a previous simulation was requested.
	 */
	GSPrintf(stdout, @"\nCreating log files\n\n");
	if(![ioManager createLogFiles: &error])
	{
		logError(error);
		errorCode = [error code];
		printHelp();
		[ioManager release];
		[pool release];
		exit(errorCode);
	}		
	
	/*
	 * Connect to the local AdunServer instance if requested and one is present.
	 * Connection is always attempted if the program was launched by the server.
	 * Otherwise it depends on the command line options.
	 * If the server launched the program and we cant connect to it we exit as
	 * we will not be able to retrieve necessary data from the server later. 
	 */
	if([userDefaults boolForKey: @"ConnectToAdServer"])
	{
		GSPrintf(stdout, @"\nConnecting to AdServer ...\n");
		if(![ioManager connectToServer: &error])
		{
			logError(error);
			//Exit if we are in server run mode
			if([ioManager runMode] == AdCoreServerRunMode)
			{
				errorCode = [error code];
				printHelp();
				[ioManager release];
				[pool release];
				exit(errorCode);
			}	
			else
			{
				NSWarnLog(@"Continuing since program is in command line mode");
				GSPrintf(stdout, @"Unable to connect to an AdServer instance - Continuing\n");
				error = nil;
			}	
		}
		else
			GSPrintf(stdout, @"Connected\n");
	}

	GSPrintf(stdout, @"%@%@", divider, divider);
	GSPrintf(stdout,  @"Checking floating point accuracy and exception detection support\n\n");
	floatingPointSettings();
	GSPrintf(stdout, @"%@", divider);

	/*
	 * Retrive the program data. 
	 * If we are starting a new simulation the template and
	 * external objects are retrieved from the server (AdServerRunMode)
	 * or the files specified on the command line (AdCommandLineRunMode) depending.
	 * If we are continuing a simulation this method loads the necessary data
	 * from the specified simulation. In this case the process of loading the
	 * data is the same regardless of the run mode.
	 */
	GSPrintf(stdout, @"%@", divider);
	GSPrintf(stdout, @"Loading program data\n");
	if(![ioManager loadData: &error])
	{
		logError(error);
		errorCode = [error code];
		if([ioManager isConnected])
			[ioManager closeConnection: error];

		printHelp();
		[ioManager release];
		[pool release];
		exit(errorCode);
	}
	GSPrintf(stdout, @"Program data loaded\n\n");
	
	/*
	 * Create the simulation output directory plus the simulation data file. 
	 * Skip this step if we are continuing a previous simulation as these files
	 * already exist.
	 */
	if(![ioManager restartRequested]) 
	{
		GSPrintf(stdout, @"Creating simulation output directory\n\n");
		if(![ioManager createSimulationOutputDirectory: &error])
		{
			logError(error);
			errorCode = [error code];
			if([ioManager isConnected])
				[ioManager closeConnection: error];
			
			printHelp();
			[ioManager release];
			[pool release];
			exit(errorCode);
		}
		GSPrintf(stdout, @"\nDone\n");
	}

	GSPrintf(stdout, @"%@", divider);
	
#ifdef PARALLEL
	//Free the following rank process
	if (rank != 0 )
		MPI_Recv(&dummy,1,MPI_INT,rank-1,2,MPI_COMM_WORLD,&mpi_err);
	
	//Wait here until all processes get released
	MPI_Barrier(MPI_COMM_WORLD);
	
	//Print out some information on the parallel environment
	GSPrintf(stdout, @"%@", divider);
	GSPrintf(stdout, @"Running in parallel mode\n");
	GSPrintf(stdout, @"I am process %d of %d\n", rank, size);
	GSPrintf(stdout, @"%@", divider);
#endif
	
	fflush(stdout);
	core = [AdCore new];
	[ioManager setCore: core];
	
	//Check if a new simulation or a continuation was 
	//requested and act accordingly.
	if([ioManager restartRequested])
		retval = [core prepareRestart: &error];
	else
		retval = [core setup: &error];
	
	if(!retval)
	{
		logError(error);
		errorCode = [error code];
		if([ioManager isConnected])
			[ioManager closeConnection: error];
		
		printHelp();
		[core release];
		[ioManager release];
		[pool release];
		exit(errorCode);
	}
	
	/*
	 * Exceptions during the call to main can only be due
	 * to core commands.
	 */
	NS_DURING
	{
		GSPrintf(stdout, @"%@", divider);
		GSPrintf(stdout, @"Beginning simulation\n\n");
		fflush(stdout);
		[core main: nil];
		GSPrintf(stdout, @"\nSimulation complete\n");
		error = [core terminationError];
		if(error != nil)
		{
			NSWarnLog(@"Simulation ended due to an error");
			logError(error);
		}	
	}
	NS_HANDLER
	{
		//main exited due to an exception
		//If the controller running the simulation was programmed properly
		//(Contollers should not let exceptions escape)
		//then this can only have been caused by an interactive command
		//End the controller thread without entering the normal end sequence.
		if([core simulationIsRunning])
			[[core controller] terminateSimulation: core];

		NSWarnLog(@"Caught an %@ exception", [localException name]);
		NSWarnLog(@"Reason %@", [localException reason]);
		NSWarnLog(@"User info %@", [localException userInfo]);
		error = AdCreateError(AdunCoreErrorDomain,
				AdCoreUnexpectedExceptionError,
				@"Caught unexpected exception",
				@"This is probably due to a programming error in the program or the AdunKernel library",
				@"Notify the adun developers supplying the log for the simulation run");
	}
	NS_ENDHANDLER
	GSPrintf(stdout, @"%@", divider);
	
	/*
	 * Begin clean up procedure -
	 * 1) Core clean up
	 *	   1) Write simulation energies
	 *	   2) Write controller results
	 * 2) If we are connected to a server -
	 *	   1) Send controller results to server
	 *	   2) Notify server of errors
	 *	   3) Close connections
	 * 3) Set exit code
	 */
	GSPrintf(stdout, @"%@", divider);
	GSPrintf(stdout, @"Beginning core clean up\n");
	[core cleanUp];
	
	if([ioManager isConnected])
	{
		GSPrintf(stdout, @"Sending controller results\n");
		[ioManager sendControllerResults: 
			[core controllerResults: nil]];
		GSPrintf(stdout, @"Notifying server of any errors and closing connection.\n");
		[ioManager closeConnection: error];
	}
	GSPrintf(stdout, @"Clean up complete\n");

	
	if(error != nil)
	{
		NSWarnLog(@"Logging termination error");
		logError(error);
		NSWarnLog(@"Done");
	 	errorCode = [error code];
	}	
	else
		errorCode = 0;
	
	fflush(stdout);
	NSWarnLog(@"Deallocing core");
	[core release];
	GSPrintf(stdout, @"Goodbye!\n");
	NSWarnLog(@"Done");
	[ioManager release];
	[[AdMemoryManager appMemoryManager] release];

#ifdef GNUSTEP
	//Trying to release this pool using cocoa
	//causes the program to hang. Its not really
	//necessary as I dont think the dealloc method
	//of any of the objects in it needs to be executed.
	//However we'll keep it on gnustep since it works there.	
	[pool release];
#endif	
#ifdef PARALLEL
	//End the parallel environment if this is a parallel version
	MPI_Finalize();
#endif

	return errorCode;
}


