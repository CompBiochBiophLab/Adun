#ifndef _ADFRAMEWORKFUNCTIONS_
#define _ADFRAMEWORKFUNCTIONS_
#include <sys/times.h>
#include <unistd.h>
#include <Foundation/Foundation.h>
#include "AdunKernel/AdunSystem.h"
#include <Base/AdVector.h>
#include "AdunKernel/AdunDefinitions.h"
#include "AdunKernel/AdunDataMatrix.h"

/**
\defgroup frameFunctions Functions
\ingroup Frame
@{
**/

/**
As AdCreateError but with domain set to AdunKernel.ErrorDomain.
\todo Rename to AdKernelFrameworkError.
*/
NSError* AdKnownExceptionError(int code, NSString* localizedDescription,
		NSString* detailedDescription ,
		NSString* recoverySuggestion);
/**
Returns an NSError object with domain \e domain and the given code.
In addition creates a userInfo dictionary with keys NSLocalizedDescriptionKey, 
AdDetailedDescriptionKey, and NSRecoverySuggestionKey whose values are the
strings given by localizedDescription, detailedDescription, and recoverySuggestion
respectively.
When Adun catches an exception is checks the userInfo dictionary for 
the key AdKnownExceptionError. If it exists the value for this key should be an NSError object
returned by this function. Adun knows what values can be present in the  
dictionary of an AdKnownExceptionError and hence will display this information to
the user.
*/
NSError* AdCreateError(NSString* domain, int code, NSString* localizedDescription,
	NSString* detailedDescription,
	NSString* recoverySuggestion);

/**
As AdCreateError() but adding \e underlyingError to the returned objects userInfo dictionary with key NSUnderlyingErrorKey.
If \e underlyingError is nil this method is the same as AdCreateError().
*/	
NSError* AdErrorWithUnderlyingError(NSString* domain, int code, NSString* localizedDescription,
		       NSString* detailedDescription,
		       NSString* recoverySuggestion, 
		       NSError* underlyingError);
/**
Function for creating an NSError object related to a problem when calculating the energy of a particular interaciton.
The returned NSError object details the atoms and interaction that caused the problem.
*/
NSError* AdCreateEnergyError(AdSystem* system, NSString* interactionType, NSArray* interactingAtoms);

/**
Removes the translational degrees of freedom from the set of elements
with \e velocities and \e masses. The number of rows in \e velocities
and the number of elements in \e masses must be the same. If they are not
a segmentation fault will occur.
\note Move to Base
*/
void AdRemoveTranslationalDOF(AdMatrix* velocities, double* masses);
/**
Converts an NSArray containing three NSNumbers/NSStrings into an Vector3D
structure. If \e array contains strings the resulting value in the Vector3D
structure depends on the result of doubleValue begin sent to the string.
If the array does not contain three objects this method returns the vector (0,0,0)
*/
Vector3D Ad3DVectorFromNSArray(NSArray* array);
/**
Converts a gsl_matrix to a vector by concatentaing all its rows.
Useful for transforming a coordinate matrix into a vector form
*/
gsl_vector* AdGSLVectorFromGSLMatrix(gsl_matrix* matrix);
/**
Writes the ::AdMatrix structure \e matrix to \e fileName. \e fileFlag indicates
the write mode. It can be "a" or "w" (append or write). 
If \e matrix is NULL an NSInvalidArgumentException is raised.
If \e fileName is nil it defaults to matrix.out. If fileFlag is nil it defaults
to "w".
*/
void AdWriteMatrixToFile(AdMatrix* matrix, NSString* fileName, NSString* fileFlag);
/**
Writes timing information to stdout based on the times given by
\e start, \e end and \e steps to stdout.
All information written is flushed immediately.
\e start and \e end are intialised by calls to the times() function.
\e steps is the number of loop steps (if any) between the two times() calls.
*/
void AdLogTimingInformation(struct tms *start, struct tms *end, int steps);
/**
As AdLogTimingInformation() except allows specification of the \e stream to write to.
*/
void AdLogTimingInformationToStream(struct tms *start, struct tms *end, int steps, FILE* stream);

/**
Returns YES if \e matrixOne and \e matrixTwo have the same dimensions.
NO otherwise.
*/
BOOL AdCheckMatrixDimensions(AdDataMatrix* matrixOne, AdDataMatrix* matrixTwo);
/**
Logs current memory usage as given by mallinfo to stderr
*/
void AdLogMemoryUsage(void);
/**
Writes the information contained in \e error and logs to stderr.
If underlying errors are detailed it recures and logs them aswell
*/
void AdLogError(NSError*);
/**
Converts the AdMatrix struct \e matrix into a gsl_matrix struct.
The reciever owns the returned matrix as is reponsible for deallocating it.
*/
gsl_matrix* AdGSLMatrixFromAdMatrix(AdMatrix* matrix);
/**
Converts the AdDataMatrix inistance \e matrix into a gsl_matrix struct.
The reciever owns the returned matrix as is reponsible for deallocating it.
*/
gsl_matrix* AdGSLMatrixFromAdDataMatrix(AdDataMatrix* matrix);
/**
Logs the row \e rowNumber of the AdMatrix \e matrix
*/
void AdLogMatrixRow(int rowNumber, AdMatrix* matrix);
/**
Logs the rows identified by the indexes in \e indexSet.
Raises a NSRangeException if an index in \e indexSet 
exceed the number of rows in \e matrix
*/
void AdLogMatrixRows(NSIndexSet* indexSet, AdMatrix* matrix);
/**
Returns a time stamp string with format "%H:%M %d/%m"
*/
NSString* AdTimeStamp(void);
/**
GSL Error handler for the framework.
Its raises an exception containing an error object detailing the cause of the error
in its user info dict with key NSUnderlyingErrorKey
 */
void AdGSLErrorHandler(const char* reason, const char* file, int line, int gsl_errno);

/**
Returns the VdW radius of an atom.
Type can be A or B.
If A then paramOne is the VdW A parameter value paramTwo is the VdW B parameter value for the atom.
If B then paramOne is the VdW Separation parameter for the atom and paramTwo is 0.0.
Raises an NSInvalidArgumentException if type is not A or B
*/
inline double AdCalculateVDWRadii(double paramOne, double paramTwo, NSString* type);

/** \@}**/

#endif		
