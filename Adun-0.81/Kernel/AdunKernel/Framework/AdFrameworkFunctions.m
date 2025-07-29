#include "AdunKernel/AdFrameworkFunctions.h"

NSError* AdErrorWithUnderlyingError(NSString* domain, int code, NSString* localizedDescription,
		       NSString* detailedDescription,
		       NSString* recoverySuggestion,
		       NSError* underlyingError)
{
	NSMutableDictionary* errorInfo;
	NSError* error;
	
	errorInfo = [NSMutableDictionary dictionary];
	
	if(localizedDescription != nil)
		[errorInfo setObject: localizedDescription 
			      forKey: NSLocalizedDescriptionKey];
	
	if(detailedDescription != nil)
		[errorInfo setObject: detailedDescription 
			      forKey: @"AdDetailedDescriptionKey"];
	
	if(recoverySuggestion != nil)		
		[errorInfo setObject: recoverySuggestion
			      forKey: @"NSRecoverySuggestionKey"];
			      
	if(underlyingError != nil)
		[errorInfo setObject: underlyingError
			forKey: NSUnderlyingErrorKey];
	
	if([errorInfo count] == 0)
		errorInfo = nil;
	
	error = [NSError errorWithDomain: domain
				    code: code
				userInfo: errorInfo];
	
	return error;		
}

NSError* AdCreateError(NSString* domain, int code, NSString* localizedDescription,
	NSString* detailedDescription,
	NSString* recoverySuggestion)
{
	return AdErrorWithUnderlyingError(domain, code, 
		localizedDescription, 
		detailedDescription, 
		recoverySuggestion, nil);		
}

NSError* AdKnownExceptionError(int code, NSString* localizedDescription,
	NSString* detailedDescription,
	NSString* recoverySuggestion)
{
	return AdCreateError(AdunKernelErrorDomain,
		code,
		localizedDescription,
		detailedDescription,
		recoverySuggestion);
}

NSError* AdCreateEnergyError(AdSystem* system, NSString* interactionType, NSArray* interactingAtoms)
{
	int numberOfAtoms, i;
	NSMutableString* warning = [NSMutableString string];
	AdDataSource* dataSource;
        AdMutableDataMatrix* elementProperties;
        NSArray* pdbNames;
	
        dataSource = [system dataSource];
        elementProperties = [[dataSource elementProperties] mutableCopy];
        pdbNames = [elementProperties columnWithHeader: @"PDBName"];
	[elementProperties release];

	//Create a string detailing which atoms were involved.
	[warning appendFormat: @"Error when calculating %@ interaction involving atoms: \n", interactionType];
	numberOfAtoms = [interactingAtoms count];
	for (i=0; i<numberOfAtoms; i++)
	{
		[warning appendFormat: @"%@ (%@)\t", 
			[interactingAtoms objectAtIndex: i], 
			[pdbNames objectAtIndex: [[interactingAtoms objectAtIndex: i] intValue]]];
	}
	
	NSWarnLog(warning);
	return AdKnownExceptionError(AdKernelEnergyCalculationError,
			@"Error detected when calculating FourierTorsion",
			warning, 
			@"Please see Adun guide for information on dealing with energy errors");
}

inline void AdRemoveTranslationalDOF(AdMatrix* velocities, double* masses)
{
	int i, j;
	double total_mass;
	double centre[3];
	
	/*
	 * Remove the translational degrees of freedom
	 * by subtracting the centre of mass velocity.
	 * This sets the inital momentum to zero.
	 */

	for(i=0; i<3; i++)
		centre[i] = 0;

	for(total_mass = 0, i=0; i<velocities->no_rows; i++)
	{
		total_mass += masses[i];		

		for(j=0; j<3; j++)
			centre[j] += velocities->matrix[i][j]*masses[i];
	}

	for(i=0; i<3; i++)
		centre[i] = centre[i]/total_mass;	
		
	NSDebugLLog(@"AdDynamics", 
		@"Current centre of mass velocity - %10.3lf %10.3lf %10.3lf",	
		centre[0], centre[1], centre[2]);

	for(i=0; i<velocities->no_rows; i++)
		for(j=0; j<3; j++)
			velocities->matrix[i][j] -= centre[j];
}

Vector3D Ad3DVectorFromNSArray(NSArray* array)
{
	int i;
	Vector3D vector;

	if([array count] != 3)
	{
		NSWarnLog(@"Cannot convert to Vector3D - Incorrect number of elements");
		array = [NSArray arrayWithObjects: 
				[NSNumber numberWithDouble: 0.0],
				[NSNumber numberWithDouble: 0.0],
				[NSNumber numberWithDouble: 0.0],
				nil];
	}	

	for(i=0; i<3; i++)
		vector.vector[i] = [[array objectAtIndex: i] doubleValue];

	return vector;	
}

gsl_vector* AdGSLVectorFromNSArray(NSArray* array)
{
	int numberOfElements, i;
	gsl_vector* vector;
	
	numberOfElements = [array count];
	vector = gsl_vector_calloc(numberOfElements);
	for(i=0; i<numberOfElements; i++)
		gsl_vector_set(vector, i, 
			       [[array objectAtIndex: i] doubleValue]);
	
	return vector;
}

gsl_vector* AdGSLVectorFromGSLMatrix(gsl_matrix* matrix)
{
	unsigned int i, j, count;
	gsl_vector* vector;
	
	vector = gsl_vector_calloc(matrix->size1*matrix->size2);
	for(count=0, i=0; i<matrix->size1; i++)
		for(j=0; j<matrix->size2; j++, count++)
			gsl_vector_set(vector,count,gsl_matrix_get(matrix,i,j));
	
	return vector;
}

void AdCopyGSLMatrixToAdMatrix(gsl_matrix* matrixOne, AdMatrix* matrixTwo)
{
	unsigned int i,j;
	
	//Check dimensions
	if(matrixOne->size1 != (unsigned)matrixTwo->no_rows)
		[NSException raise: NSInvalidArgumentException
			    format: @"GSl - AdMatrix have different number of rows"];
	
	if(matrixOne->size2 != (unsigned)matrixTwo->no_columns)
		[NSException raise: NSInvalidArgumentException
			    format: @"GSl - AdMatrix have different number of columns"];
	
	for(i=0; i<matrixOne->size1; i++)
		for(j=0;j<matrixOne->size2; j++)
			matrixTwo->matrix[i][j] = gsl_matrix_get(matrixOne, i, j);
}

void AdWriteMatrixToFile(AdMatrix* matrix, NSString* fileName, NSString* fileFlag)
{
	int i, j;
	FILE* stream;

	if(matrix == NULL)
		[NSException raise: NSInvalidArgumentException
			format: @"Matrix cannot be NULL"];

	if(fileName == nil)
		fileName = @"matrix.out";

	if(fileFlag == nil)
		fileFlag = @"w";

	//open the file
	stream = fopen([fileName cString], [fileFlag cString]);
	for(i=0; i<matrix->no_rows; i++)
	{
		for(j=0; j<matrix->no_columns; j++)
			fprintf(stream, "%-12E ", matrix->matrix[i][j]);
		fprintf(stream, "\n");
	}

	fclose(stream);
}

void AdLogTimingInformation(struct tms *start, struct tms *end, int steps)
{
	AdLogTimingInformationToStream(start, end, steps, stdout);
}

void AdLogTimingInformationToStream(struct tms *start, struct tms *end, int steps, FILE* stream)
{
	int clockTicks;
	
	clockTicks = sysconf(_SC_CLK_TCK);
	
	GSPrintf(stream, @"Timing information\n");	
	GSPrintf(stream, @"Clock granularity %lf. Steps %d\n\n", 1.0/clockTicks, steps);
	GSPrintf(stream, @"%-12@\t%-12@\t%-12@\t%-12@\n",
		 @"User", @"System", @"Total", @"Time Per Step");
	end->tms_utime -= start->tms_utime;
	end->tms_stime -= start->tms_stime;
	GSPrintf(stream, @"%-12.3lf\t%-12.3lf\t%-12.3lf\t%-12.6lf\n",
		 ((double)end->tms_utime)/clockTicks, 
		 ((double)end->tms_stime)/clockTicks, 
		 ((double)(end->tms_utime + end->tms_stime))/clockTicks,
		 ((double)(end->tms_utime + end->tms_stime))/(clockTicks*steps));
	fflush(stream);	 
}

void AdLogMemoryUsage(void)
{
#ifndef __FREEBSD__
	struct mallinfo mem_struct;
	float factor = 1048576.0;

	mem_struct = mallinfo();
	NSLog(@"Arena : %lf MB. Hblks : %lf MB. Uordblocks %lf MB. Fordblocks %lf MB", 
		(float)mem_struct.arena/factor,
		(float)mem_struct.hblkhd/factor, 
		(float)mem_struct.uordblks/factor, 
		(float)mem_struct.fordblks/factor);
#else
	NSLog(@"Memory logging not available under FreeBSD");
#endif		
}


void AdLogError(NSError* error)
{
	NSString* string;
	NSError* underlyingError;

	if(error == nil)
	{
		NSWarnLog(@"Supplied nil error");
		return;
	}	

	NSWarnLog(@"Detected error from domain %@", [error domain]);
	NSWarnLog(@"Error code %d", [error code]);
	if((string = [[error userInfo] objectForKey: NSLocalizedDescriptionKey]) !=  nil)
		NSWarnLog(@"Description - %@", string);

	if((string = [[error userInfo] objectForKey: @"AdDetailedDescriptionKey"]) !=  nil)
		NSWarnLog(@"Detail - %@", string );
	
	if((string = [[error userInfo] objectForKey: @"NSRecoverySuggestionKey"]) !=  nil)
		NSWarnLog(@"Recovery suggestion - %@", string);

	if((underlyingError = [[error userInfo] objectForKey: @"NSUnderlyingErrorKey"]) != nil)
	{
		NSWarnLog(@"Underlying error present - Details follow:\n");
		AdLogError(underlyingError);
	}	
}

BOOL AdCheckMatrixDimensions(AdDataMatrix* matrixOne, AdDataMatrix* matrixTwo)
{
	BOOL rows, columns;

	rows = ([matrixOne numberOfRows] == [matrixTwo numberOfRows]) ? YES : NO;
	columns = ([matrixOne numberOfColumns] == [matrixTwo numberOfColumns]) ? YES : NO;
	return rows && columns;
}

gsl_matrix* AdGSLMatrixFromAdMatrix(AdMatrix* matrix)
{
	int i, j;
	gsl_matrix* newMatrix;
	
	newMatrix = gsl_matrix_alloc(matrix->no_rows, matrix->no_columns);

	for(i=0; i<matrix->no_rows; i++)
		for(j=0; j<matrix->no_columns; j++)
		{
			gsl_matrix_set(newMatrix, 
				i, j, 
				matrix->matrix[i][j]);
		}			
	
	return newMatrix;
}

gsl_matrix* AdGSLMatrixFromAdDataMatrix(AdDataMatrix* matrix)
{
	int i, j;
	gsl_matrix* newMatrix;
	AdMatrix* temp;
	
	newMatrix = gsl_matrix_alloc([matrix numberOfRows], [matrix numberOfColumns]);
	temp = [matrix cRepresentation];

	for(i=0; i<(int)[matrix numberOfRows]; i++)
		for(j=0; j<(int)[matrix numberOfColumns]; j++)
		{
			gsl_matrix_set(newMatrix, 
				i, j, 
				temp->matrix[i][j]);
		}			
	
	[[AdMemoryManager appMemoryManager] freeMatrix: temp];
	return newMatrix;
}

void AdLogMatrixRow(int rowNumber, AdMatrix* matrix)
{
	int i;
	NSMutableString* aString = [NSMutableString new];

	[aString appendFormat: @"%d: ", rowNumber];
	for(i=0; i< matrix->no_columns; i++)
		[aString appendFormat: @"%-12lf ", matrix->matrix[rowNumber][i]];
	
	NSLog(@"%@", aString); 
	[aString release];
}

void AdLogMatrixRows(NSIndexSet* indexSet, AdMatrix* matrix)
{
	int index;
	
	index = [indexSet indexGreaterThanIndex: matrix->no_rows - 1];
	if(index != NSNotFound)
		[NSException raise: NSRangeException 
			format: @"Index %d is out of range (%d, %d)", 
				index, 0, matrix->no_rows];

	index = [indexSet firstIndex];
	if(index != NSNotFound)
	{
		do
		{
			AdLogMatrixRow(index, matrix);
		}
		while((index = [indexSet indexGreaterThanIndex: index]) != NSNotFound);
	}
}

NSString* AdTimeStamp(void)
{
	NSDate *date = [NSDate date];
	NSString* stamp;
	NSString* user;
	NSDateFormatter *formatter;
	
	formatter = [[NSDateFormatter alloc] 
			initWithDateFormat: @"%H:%M %d/%m"
			allowNaturalLanguage: NO];

	user = NSUserName();
	if([user isEqual: @""])
		user = @"Unknown";

	stamp = [NSString stringWithFormat: @"%@\t%@ -\n", 
			user, 
			[formatter stringForObjectValue: date]];
	[formatter release];
	return stamp;
}

void AdGSLErrorHandler(const char* reason, const char* file, int line, int gsl_errno)
{
	NSString* reasonObj, *fileObj;
	NSError* error;
	NSException* exception;

	//Convert the char arrays to NSString objects
	reasonObj = [NSString stringWithCString: reason];
	fileObj = [NSString stringWithCString: file];
	
	error = AdCreateError(GSLErrorDomain, gsl_errno,
			[NSString stringWithFormat: 
				@"GSL Error: %@",
				reasonObj],
			[NSString stringWithFormat: 
				@"Function %@. Line: %d",
				fileObj, line], nil);
	exception = [NSException exceptionWithName: NSInternalInconsistencyException
			reason: reasonObj 
			userInfo: [NSDictionary dictionaryWithObject: error 
				forKey: NSUnderlyingErrorKey]]; 
	[exception raise];				
}

double AdCalculateVDWRadii(double paramOne, double paramTwo, NSString* type)
{
	double radius = 0;
	
	if([type isEqual: @"A"])
	{
		if(paramTwo == 0)
			radius = 1.0;
		else	
			radius = 0.5*pow((paramOne/paramTwo), 1.0/3.0);
	}
	else if([type isEqual: @"B"])
	{
		radius = paramOne/pow(2, 1.0/6.0);
	}
	else 
		[NSException raise: NSInvalidArgumentException
			format: @"Unable to assign radius. Unknown VdW type %@", type];
	
	return radius;
}



