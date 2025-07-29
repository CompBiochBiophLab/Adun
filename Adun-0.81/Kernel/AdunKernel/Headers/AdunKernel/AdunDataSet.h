#ifndef _ADDATASET_
#define _ADDATASET_

#include <Foundation/Foundation.h>
#include "AdunKernel/AdunModelObject.h"
#include "AdunKernel/AdunDataMatrix.h"

/**
\ingroup Inter
AdDataSet objects hold a collection of related AdDataMatrix instances along with information on how
they were generated i.e. who they were generated from and how. AdDataSet is the basic
class for transmitting and storing information in both AdunKernel and ULFramework. 

\todo Refactor - Implement mutable and immutable classes, AdDataSet, AdMutableDataSet.
*/

@interface AdDataSet: AdModelObject
{
	@private
	NSString* dataGeneratorID;
	NSMutableArray* dataMatrices;
}

/**
As AdDataSet::initWithName:inputReferences:dataGeneratorName:dataGeneratorVersion: 
with all arguements set to nil.
*/
- (id) init;
/**
As AdDataSet::initWithName:inputReferences: passing nil
for \e aDict.
*/
- (id) initWithName: (NSString*) aString;
/**
As AdDataSet::initWithName:inputReferences:dataGeneratorName:dataGeneratorVersion: 
passing nil for \e aDict, \e stringTwo and \e aNumber.
*/
- (id) initWithName: (NSString*) name inputReferences: (NSDictionary*) aDict;
/**
As AdDataSet::initWithName:inputReferences:dataGeneratorName:dataGeneratorVersion: 
with \e stringTwo being set to [aBundle bundleIdentifier] and \e aNumber given
by the value for "PluginVersion" in \e aBundles info dictionary.
*/
- (id) initWithName: (NSString*) aString 
	inputReferences: (NSDictionary*) aDict
	dataGenerator: (NSBundle*) aBundle;
/**
Creates a new AdDataSet instance for data generated from the objects 
referenced by \e aDict by the plugin \e aBundle. 
\param  aString The name of the new object. If nil defaults to "None".
\param aDict A dictionary whose keys are class types and whose values are
NSDictionaries. The keys of these dictionaries are object idents. The 
values are also NSDictionaries with the following keys, "Identification",
"Class", "Schema" and "Database". If nil no references are set.
\param dataGeneratorName The name of the plugin that generated the data. If nil
this defaults to "Unknown".
\param dataGeneratorVersion The version of the plugin that generated the data as a NSString.
If nil this defaults to "1" 
\note Simplfy input references arguement e.g. pass an array of dictionaries with
each dictionary containing an object reference.
*/
- (id) initWithName: (NSString*) stringOne 
	inputReferences: (NSDictionary*) aDict
	dataGeneratorName: (NSString*) stringTwo
	dataGeneratorVersion: (NSString*) aNumber;
/**
Returns YES if \e aDataMatrix is part of the data set.
Returns NO otherwise.
*/
- (BOOL) containsDataMatrix: (AdDataMatrix*) aDataMatrix;
/**
Returns YES the object contains a matrix called \e aString.
Returns NO otherwise.
*/
- (BOOL) containsDataMatrixWithName: (NSString*) aString;
/**
Adds \e aDataMatrix to the data set
*/
- (void) addDataMatrix: (AdDataMatrix*) aDataMatrix;
/**
Removes the matrix \e aDataMatrix from the data set. 
Does nothing if \e aDataMatrix is not part of the data set or if it is nil.
*/
- (void) removeDataMatrix: (AdDataMatrix*) aDataMatrix;
/**
Removes the AdDataMatrix object with name \e aString from the data set returning
YES on success. 
If no data matrix with name \e aString is present or it is nil this method 
return NO. If there is more than one AdDataMatrix instance with name \e aString the first
one found is removed.
*/
- (BOOL) removeDataMatrixWithName: (NSString*) aString;
/**
Returns an array containing all the AdDataMatrix objects in the data set.
*/
- (NSArray*) dataMatrices;
/**
Returns the AdDataMatrix instance with name \e aString . Returns nil 
if no matrix with name \e aString is present. If there
is more than one AdDataMatrix object with name \e aString it returns the first
one found.
*/
- (AdDataMatrix*) dataMatrixWithName: (NSString*) aString;
/**
Returns the id of the plugin that generated the data - usually \e pluginName_pluginVersion.
*/
- (NSString*) dataGeneratorID;
/**
Returns the name of the plugin that generated the data. This is "Unknown" if no
name was supplied on creation.
*/
- (NSString*) dataGeneratorName;
/**
Returns the version number of the plugin that generated the data or "1.0" if none was supplied
on creation.
*/
- (double) dataGeneratorVersion;
/**
 Returns an array containining the names of all the data matrix names
 */	
- (NSArray*) dataMatrixNames;
/**
Returns an enumerator over the data matrices
*/
- (NSEnumerator*) dataMatrixEnumerator;
/**
Returns an enumerator over the matrix names
*/
- (NSEnumerator*) nameEnumerator;
@end

#endif
