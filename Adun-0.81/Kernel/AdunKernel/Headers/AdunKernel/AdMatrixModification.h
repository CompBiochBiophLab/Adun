#ifndef ADMATRIX_MODIFICATION
#define ADMATRIX_MODIFICATION
#include <Foundation/Foundation.h>

/**
\ingroup Protocols
Protocol defining methods that should be implemented by objects
if they wish to allow other objects to write directly to AdMatrix
structs returned by their methods. 

Usually AdMatrix structs returned by framework objects should not
be modified directly. Instead objects which allow such modification
provide set methods which copy the contents of another matrix
into the struct.

This is necessary since these objects may need to perform internal tasks 
before and after modification of such matrices.
If the matrices were modified directly the object would not know of the change
and hence would not perform, usually critical, tasks. It is also necessary to
maintain thread safety

However sometimes the extra efficency obtained through direct modification
i.e. due to not having to maintain a separate matrix and not having to
copy values from one matrix to another, is desirable. This protocol
defines a way to enable direct modification while allowing the 
object that owns the matrix to perform updates and ensuring the resulting
code is thread safe.

Objects who return modifiable #AdMatrix structs can implement the following methods
which must be called by other objects before and after writing to the returned matrix.

\note 
Never directly write to a matrix whose owner does not provide access to it through
this protocol
*/

@protocol AdMatrixModification
/**
Should return YES if \e matrix, which is owned by the receiver, can be
directly modified using the other methods of this protocol.
*/
- (BOOL) allowsDirectModificationOfMatrix: (AdMatrix*) matrix;
/**
Returns YES if writes to \e matrix are currently locked due to it being
modified from another thread. Returns NO otherwise.
Note that even if this method returns YES a lock may be aquired by another
thread in the interval between returning and a call to object:willBeginWritingToMatrix:()
*/
- (BOOL) matrixIsAvailableForModification: (AdMatrix*) matrix;
/**
Sent by objects who are about to perform a direct write to \e matrix which
is owned by the receiver. The receiver will perform any necessary updates before
returning. The receiver will only return when the matrix is not currently being
modified from another thread.
*/
- (void) object: (id) object willBeginWritingToMatrix: (AdMatrix*) matrix;
/**
Sent by objects who have performed a direct write to \e matrix which
is owned by the receiver. The receiver will perform any necessary updates before
returning and unlock the matrix for writing by other threads.
*/
- (void) object: (id) object didFinishWritingToMatrix: (AdMatrix*) matrix;
@end


#endif
