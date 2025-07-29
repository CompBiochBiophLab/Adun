#include "AdunKernel/AdunConfigurationGenerator.h"

@implementation AdConfigurationGenerator

- (void) checkFloatingPointErrors
{
	int raised;
	NSMutableDictionary* errorInfo;
	NSError* error;

	/*
	 * We want to detect floating point errors since they
	 * will affect the stability of our simulation.
	 * The errors we are detecting are based on IEEE754 standard
	 * 1 - Invalid Operation
	 * 2 - Division by Zero
	 * 3 - Overflow
	 * 4 - Underflow
	 * 5 - Inexact
	 * However error 5 is common since all irrational and transcendental
	 * numbers are inexact and we may be adding many numbers who differ by more than 
	 * DBL_EPSILON so we wont do anything in this case .
	 * Error 4 leads to a slow loss of precision - however it may occur 
	 * that tiny forces and energies are calculated in the course of
	 * a simulation. In this case we will just log when this happens and 
	 * let Error 2 handle cases where this will lead to a catastrophic error
	 * (due to the result being zero).
	 * See the Arithmetic section of the libc manual for more detail.
	 */

	raised = fetestexcept(AdFloatingPointExceptionMask);

#ifdef FE_INVALID
	if(raised & FE_INVALID)	
	{
		errorInfo = [NSMutableDictionary dictionary];
		[errorInfo setObject: @"Detected floating point exception during simulation."
			forKey: NSLocalizedDescriptionKey];
		[errorInfo setObject: @"Exception due to an invalid operation."
			forKey: @"AdDetailedDescriptionKey"];
		[errorInfo setObject: @"This is a critical error and likely due to a bug in an underlying algorithm.\n\
Please contact the Adun developers with information regarding the simulation you were running when this occurred.\n\
(Options, System, Results etc)\n"
			forKey: @"NSRecoverySuggestionKey"];
		error = [NSError errorWithDomain: AdunKernelErrorDomain
					code: AdKernelFloatingPointError
					userInfo: errorInfo];
		feclearexcept(FE_ALL_EXCEPT);
		[[NSException exceptionWithName: @"AdFloatingPointException"
			reason: @"Caught a IEEE74 floating point exception"
			userInfo: [NSDictionary dictionaryWithObject: error
					forKey: @"AdKnownExceptionError"]]
			raise];
	}
#endif

#ifdef FE_OVERFLOW
	if(raised & FE_OVERFLOW)
	{
		errorInfo = [NSMutableDictionary dictionary];
		[errorInfo setObject: @"Detected floating point exception during simulation."
			forKey: NSLocalizedDescriptionKey];
		[errorInfo setObject: @"Exception due to overflow"
			forKey: @"AdDetailedDescriptionKey"];
		[errorInfo setObject: @"This error indicates infinities entering the simulation.\n\
This is likely an indication of the simulation exploding due to excessive forces.\nUnrelaxed starting structures are\
a possible explanation.\nIn this case it is recommended you run an initial simulation with a smaller time step to relax\
the molecule.\nIt is also recommened that you examine the data collected so far which will provide more information on\
the cause.\n)"
			forKey: @"NSRecoverySuggestionKey"];
		error = [NSError errorWithDomain: AdunKernelErrorDomain
					code: AdKernelFloatingPointError
					userInfo: errorInfo];
		feclearexcept(FE_ALL_EXCEPT);
		[[NSException exceptionWithName: @"AdFloatingPointException"
			reason: @"Caught a IEEE74 floating point exception"
			userInfo: [NSDictionary dictionaryWithObject: error
					forKey: @"AdKnownExceptionError"]]
			raise];
	}
#endif

#ifdef FE_DIVBYZERO
	if(raised & FE_DIVBYZERO)
	{
		errorInfo = [NSMutableDictionary dictionary];
		[errorInfo setObject: @"Detected floating point exception during simulation."
			forKey: NSLocalizedDescriptionKey];
		[errorInfo setObject: @"Exception due to divide by zero"
			forKey: @"AdDetailedDescriptionKey"];
		[errorInfo setObject: @"This error could be due to a underflow event or a programming bug.\n\
Please contact the Adun developers with information regarding the simulation you were running when this occurred.\n\
(Options, System, Results etc)\n"
			forKey: @"NSRecoverySuggestionKey"];
		error = [NSError errorWithDomain: AdunKernelErrorDomain
					code: AdKernelFloatingPointError
					userInfo: errorInfo];
		feclearexcept(FE_ALL_EXCEPT);
		[[NSException exceptionWithName: @"AdFloatingPointException"
			reason: @"Caught a IEEE74 floating point exception"
			userInfo: [NSDictionary dictionaryWithObject: error
					forKey: @"AdKnownExceptionError"]]
			raise];
	}
#endif

#ifdef FE_UNDERFLOW 
	if(raised & FE_UNDERFLOW)
	{
		NSWarnLog(@"Detected an underflow exception.");
		NSWarnLog(@"This could be the result of extremly small forces and/or energies being calculated.");
		NSWarnLog(@"Such events are not uncommon but will lead to a loss of precision.");
		NSWarnLog(@"It is possible that underflows could lead to zeros entering the calculation and\
'divide by zero' errors as a result\n. However these will be caught independantly if they occur");
		NSWarnLog(@"Continuing simulation");
		feclearexcept(FE_ALL_EXCEPT);
	}
#endif

	//clear any FE_INEXACT exceptions
	feclearexcept(FE_ALL_EXCEPT);
}

- (BOOL) production: (NSError**) error
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (BOOL) restartFrom: (int) step error: (NSError**) error
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (void) endProduction
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (unsigned int) numberOfSteps
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (void) setNumberOfSteps: (unsigned int) aNumber
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (unsigned int) currentStep
{
	NSWarnLog(@"Abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromClass([self class]));
}

- (AdSystemCollection*) systems
{
	NSWarnLog(@"%@ is an abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromSelector(_cmd),
		NSStringFromClass([self class]));
}

- (AdForceFieldCollection*) forceFields 
{
	NSWarnLog(@"%@ is an abstract method. You should only initialise a concrete subclass of %@",
		NSStringFromSelector(_cmd),
		NSStringFromClass([self class]));
}

@end
