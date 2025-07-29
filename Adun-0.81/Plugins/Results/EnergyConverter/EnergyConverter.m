/*
   Project: EnergyConverter

   Copyright (C) 2005 Michael Johnston & Jordi Villa-Freixa

   Author: Michael Johnston

   Created: 2005-11-04 16:42:49 +0100 by michael johnston

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

#include "EnergyConverter.h"
#include <gsl/gsl_histogram.h>
#include <math.h>

@implementation EnergyConverter

- (AdDataMatrix*) thermodynamicAveragesFor: (AdDataMatrix*) matrix from: (unsigned int) start windowSize: (unsigned int) size
{
	int i;
	double cumulative, average, value;
	gsl_vector* vector;
	NSString *unit, *header, *progressHeader;
	NSArray *column;
	NSMutableArray *columnHeaders,  *newColumn = [NSMutableArray new];
	NSEnumerator* columnHeadersEnum;
	AdMutableDataMatrix* averagesMatrix = nil;
	int initialStep, firstAverage;
	
	columnHeaders = [[matrix columnHeaders] mutableCopy];

	if([columnHeaders containsObject: @"Time"])
	{
		[columnHeaders removeObject: @"Time"];
		progressHeader = @"Time";
	}
	else if([columnHeaders containsObject: @"Iteration"])
	{
		[columnHeaders removeObject: @"Iteration"];
		progressHeader = @"Iteration";
	}
		
	initialStep = [[matrix elementAtRow: 0 ofColumnWithHeader: progressHeader] intValue];
	firstAverage = [[matrix elementAtRow: start ofColumnWithHeader: progressHeader] intValue];	
	
	if([progressHeader isEqual: @"Time"])
	{
		[resultsString appendFormat: 
		 @"Thermodynamic Averages:\n\tAverages accumulated from time point %.3lf ps. First average calculated at %.3lf ps\n\n",
		((float)initialStep)/1000, ((float)firstAverage)/(1000)];
	}
	else
	{
		[resultsString appendFormat: 
		 @"Thermodynamic Averages:\n\tAverages accumulated from step %E. First average calculated at step %E\n\n",
		 initialStep, firstAverage];			      
	}

	columnHeadersEnum = [columnHeaders objectEnumerator];	
	while(header = [columnHeadersEnum nextObject])
	{
		column = [matrix columnWithHeader: header];
		vector = [column gslVectorRepresentation];
		for(cumulative = 0, i=0; i<start; i++)
		{
			value = gsl_vector_get(vector, i);
			cumulative += value;
		}
		
		average = cumulative/start;
		[newColumn addObject: [NSNumber numberWithDouble: average]];
		for(i=start; i<vector->size; i++)
		{
			value = gsl_vector_get(vector, i);
			cumulative += value;
			average = cumulative/(i+1);
			[newColumn addObject: [NSNumber numberWithDouble: average]];
		}
		
		gsl_vector_free(vector);
		
		if(averagesMatrix == nil)
		{
			vector = [newColumn gslVectorRepresentation];
			averagesMatrix = [AdMutableDataMatrix matrixFromGSLVector: vector];
			[averagesMatrix setName: 
				[NSString stringWithFormat: @"%@ Averages", [matrix name]]];
			gsl_vector_free(vector);
		}
		else
		{
			[averagesMatrix extendMatrixWithColumn: newColumn];
		}
		
		[newColumn removeAllObjects];
	}
	
	[newColumn release];
	[averagesMatrix setColumnHeaders: columnHeaders];
	
	return averagesMatrix;
}

- (AdDataSet*) histogramsFor: (AdDataMatrix*) matrix numberOfBins: (unsigned int) numberBins
{
	int i;
	double min, max, value, median, size;
	gsl_histogram* histogram;
	gsl_vector* vector;
	NSMutableArray* row = [NSMutableArray array];
	NSArray* column;
	NSEnumerator* columnHeadersEnum;
	NSString* header;
	AdMutableDataMatrix* histogramMatrix;
	AdDataSet* dataSet;

	dataSet = [[AdDataSet alloc] 
			initWithName: @"Histograms"
			inputReferences: nil 
			dataGeneratorName: @"EnergyConverter"
			dataGeneratorVersion: [infoDict objectForKey: @"PluginVersion"]];

	[resultsString appendFormat: @"Information for histograms derived from table %@:\n", [matrix name]];

	//Create a histogram for each column of \e matrix
	columnHeadersEnum = [[matrix columnHeaders] objectEnumerator];
	while(header = [columnHeadersEnum nextObject])
	{
		if([header isEqual: @"Time"] || [header isEqual: @"Iteration"])
			continue;
	
		column = [matrix columnWithHeader: header];
		vector = [column gslVectorRepresentation];
		gsl_vector_minmax(vector, &min, &max);
		min = floor(min);
		max = ceil(max);
		size = (max - min)/numberBins;
		
		histogram = gsl_histogram_alloc(numberBins);
		gsl_histogram_set_ranges_uniform(histogram, min, max);
		
		for(i=0; i<vector->size; i++)
			gsl_histogram_increment(histogram, gsl_vector_get(vector, i));
		
		histogramMatrix = [[AdMutableDataMatrix alloc] 
					initWithNumberOfColumns: 2 
					columnHeaders: [NSArray arrayWithObjects: @"Energy", @"Count", nil]
					columnDataTypes: nil];
		[histogramMatrix autorelease];		
		for(median = min + size/2, i=0; i<histogram->n; i++, median += size)
		{
			value = gsl_histogram_get(histogram, i);
			[row addObject: [NSNumber numberWithDouble: median]];
			[row addObject: [NSNumber numberWithDouble: value]];
			[histogramMatrix extendMatrixWithRow: row];
			[row removeAllObjects];
		}
		
		[histogramMatrix setName: header];
		[dataSet addDataMatrix: histogramMatrix];
		
		[resultsString appendFormat: @"\t%@: Min bound %lf. Max bound %lf. Bin width %.2lf\n", header, min, max, size];
		
		gsl_vector_free(vector);
	}
	
	[resultsString appendString: @"\n"];
	
	return [dataSet autorelease];
}

- (AdDataSet*) processEnergies: (AdDataSet*) energies withOptions: (NSMutableDictionary*) options
{
	int i, start, end, stepsize, tdStart;
	double value, conversionFactor;
	AdDataSet* processedEnergies;
	AdDataMatrix* energyMatrix, *averageMatrix;
	AdMutableDataMatrix *processedMatrix;
	NSEnumerator* systemNamesEnum, *termEnum;
	NSString* unit;
	NSArray* selectedTerms;
	NSMutableArray *row;
	id systemName, term;
	
	//Read the options	
	systemNamesEnum = [[[options valueForMenuItem: @"Systems"]
				selectedItems] objectEnumerator];
	
	start = [[options valueForKeyPath: @"Frames.Start"] intValue];
	end = start + [[options valueForKeyPath: @"Frames.Length"] intValue];
	stepsize = [[options valueForKeyPath: @"Frames.StepSize"] intValue];
	tdStart = [[options valueForKeyPath: @"Thermodynamic Averages.Start"] intValue];
	
	if(stepsize <= 0)
		stepsize = 1;
		
	unit = [[[options valueForMenuItem: @"Units"]
			selectedItems] objectAtIndex: 0];
	conversionFactor = [[conversionFactors objectForKey: unit]
				doubleValue];
	
	//Process the energies
	processedEnergies = [[AdDataSet alloc] 
				initWithName: @"Energies"
				inputReferences: nil
				dataGeneratorName: @"EnergyConverter"
				dataGeneratorVersion:
				[infoDict objectForKey: @"PluginVersion"]];
	[processedEnergies autorelease];

	while((systemName = [systemNamesEnum nextObject]))
	{
		selectedTerms = [[[options valueForMenuItem: @"Systems"]
					valueForMenuItem: systemName]
					selectedItems];
		energyMatrix = [energies dataMatrixWithName: systemName];
		processedMatrix = [[AdMutableDataMatrix alloc] 
					initWithNumberOfColumns: [selectedTerms count]
					columnHeaders: selectedTerms
					columnDataTypes: nil];
		[processedMatrix setName: systemName];
		[processedMatrix autorelease];			
		for(i=start; i<end; i+= stepsize)
		{
			termEnum = [selectedTerms objectEnumerator];
			row = [NSMutableArray array];
			while((term = [termEnum nextObject]))
			{
				value = [[energyMatrix elementAtRow: i
						ofColumnWithHeader: term] 
						doubleValue];
				if(!([term isEqual: @"Time"] || [term isEqual: @"Temperature"] 
					||[term isEqual: @"Iteration"]))
					value *= conversionFactor;

				[row addObject: 
					[NSNumber numberWithDouble: value]];
			}
			[processedMatrix extendMatrixWithRow: row];
		}
		[processedEnergies addDataMatrix: processedMatrix];
		
		//Create Thermodynamic Average Tables
		if([processedMatrix numberOfRows] > 500 && [processedMatrix numberOfColumns] > 1)
		{
			averageMatrix = [self thermodynamicAveragesFor: processedMatrix 
								  from: tdStart 
							    windowSize: 200];
			[processedEnergies addDataMatrix: averageMatrix];
		}
	}
	
	return processedEnergies;
}

/**********

Protocols

************/

- (id) init
{
	if(self == [super init])
	{
		infoDict = [[NSBundle bundleForClass: [self class]]
				infoDictionary];
		[infoDict retain];
		conversionFactors = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithDouble: 1.0], @"Simulation",
					[NSNumber numberWithDouble: STCAL], @"KCal per mol",
					[NSNumber numberWithDouble: STJMOL], @"J per mol",
					nil];
		[conversionFactors retain];
		resultsString = [NSMutableString new];		
	}

	return self;
}

- (void) dealloc
{
	[resultsString release];
	[conversionFactors release];
	[super dealloc];
}

//Default implementation
- (BOOL) checkInputs: (NSArray*) inputs error: (NSError**) error
{
	return YES;
}

- (NSDictionary*) pluginOptions: (NSArray*) inputs
{
	NSMutableDictionary* options, *systemMenu, *termMenu, *unitsMenu;
	NSMutableDictionary* averagesMenu, *histogramMenu, *framesMenu;
	NSEnumerator* matrixEnum;
	AdSimulationData* data;
	AdDataSet* energies;
	AdSystem* system;
	id matrix;

	data = [inputs objectAtIndex: 0];
	energies = [data energies];

	options = [NSMutableDictionary newNodeMenu: NO];
	
	//SystemsMenu
	systemMenu = [NSMutableDictionary newNodeMenu: YES];
	[systemMenu setSelectionMenuType: @"Multiple"];
	
	matrixEnum = [[energies dataMatrices] objectEnumerator];
	while((matrix = [matrixEnum nextObject]))
	{
		termMenu = [NSMutableDictionary newLeafMenu];
		[termMenu addMenuItems: [matrix columnHeaders]];
		[termMenu setSelectionMenuType: @"Multiple"];
		[systemMenu addMenuItem: [matrix name]
			withValue: termMenu];
	}

	if([[systemMenu menuItems] count] != 0)
		[options addMenuItem: @"Systems"
			withValue: systemMenu];

	//Units Menu
	unitsMenu = [NSMutableDictionary newLeafMenu];
	[unitsMenu addMenuItems: 
		[NSArray arrayWithObjects: 
			@"Simulation",
			@"KCal per mol",
			@"J per mol",
			nil]];
	[unitsMenu setDefaultSelection: @"KCal per mol"];
	[options addMenuItem: @"Units"
		withValue: unitsMenu];

	//Assume same number of frames for all systems
	system = [[[data systemCollection] fullSystems] objectAtIndex: 0];

	//Frames Menu
	framesMenu = [NSMutableDictionary newNodeMenu: NO];
	[framesMenu addMenuItem: @"Start"
		withValue: [NSNumber numberWithInt: 0]];
	//FIXME: May have different number of frames per system	
	[framesMenu addMenuItem: @"Length"
		      withValue: [NSNumber numberWithInt:
				  [data numberOfFramesForSystem: system]]];
	[framesMenu addMenuItem: @"StepSize"
		withValue: [NSNumber numberWithInt: 1]];
	[options addMenuItem: @"Frames"
		withValue: framesMenu];
		
	//TD Averages Menu	
	averagesMenu = [NSMutableDictionary newNodeMenu: NO];
	[averagesMenu addMenuItem: @"Start"
		      withValue: [NSNumber numberWithInt: 400]];
	//FIXME: May have different number of frames per system	
	/*[averagesMenu addMenuItem: @"Window Size"
		      withValue: [NSNumber numberWithInt: 500]];*/
	[options addMenuItem: @"Thermodynamic Averages"
		   withValue: averagesMenu];
		   
	//Histograms Menu	
	histogramMenu = [NSMutableDictionary newNodeMenu: NO];
	[histogramMenu addMenuItem: @"Create Histograms" 
		withValue: [NSNumber numberWithBool: NO]];
	[histogramMenu addMenuItem: @"Number Bins"
		withValue: [NSNumber numberWithInt: 100]];
	[options addMenuItem: @"Histogram"
		   withValue: histogramMenu];	   
	
	return  options;
}	

- (NSDictionary*) processInputs: (NSArray*) inputs userOptions: (NSDictionary*) options; 
{ 
	BOOL createHistograms;
	int start, end;
	double numberBins;
	NSMutableDictionary* resultsDict = [NSMutableDictionary dictionary];
	NSMutableDictionary* mutableOptions;
	NSMutableArray* results;
	NSEnumerator* matrixEnum;
	AdDataMatrix* matrix;
	AdSimulationData* simulationData;
	AdDataSet* processedEnergies, *dataSet;
	id energies;

	[resultsString deleteCharactersInRange: NSMakeRange(0, [resultsString length])];
	simulationData = [inputs objectAtIndex: 0];

	if(![simulationData isKindOfClass: [AdSimulationData class]])
		[NSException raise: NSInvalidArgumentException
			format: @"EnergyConverter cannot process %@ objects", 
			NSStringFromClass([simulationData class])];
	
	energies = [simulationData energies];
	if([[energies dataMatrices] count] == 0)
		return nil;
		
	//FIXME: Remove need for mutable options - use ivar
	mutableOptions = [[options mutableCopy] autorelease];
	pluginOptions = (NSMutableDictionary*)options;
	
	//Check the specified frames are within limits.	
	//If not adjust ...
	//FIXME: Since option is mutable all subsequent calls to this
	//method using this options dict will have the fixed length.
	//This will not be reflected in the interface ... 
	start = [[options valueForKeyPath: @"Frames.Start"] intValue];
	end = start + [[options valueForKeyPath: @"Frames.Length"] intValue];	
	if(end > [simulationData numberOfFrames])
	{
		[resultsString appendFormat: 
			@"Specified length %@ (from start frame %d) exceeds available number of frames (%d).\n",
			[options valueForKeyPath: @"Frames.Length"], start, [simulationData numberOfFrames] - start];
		
		end = [simulationData numberOfFrames];
		[resultsString appendFormat: @"Adjusting length to %d.\n\n",
			end - start];	
		[options setValue: [NSNumber numberWithInt: end - start]
		       forKeyPath: @"Frames.Length"];		
	}
	
	if([[[options valueForKey: @"Systems"] selectedItems] count] == 0)
		[NSException raise: NSInvalidArgumentException
			    format: @"No system selected"];
	
	
	processedEnergies = [self processEnergies: energies 
				withOptions: mutableOptions];
	if([[processedEnergies dataMatrices] count] == 0)
		return nil;
		
	results = [NSMutableArray arrayWithObject: processedEnergies]; 
	createHistograms = [[options valueForKeyPath: @"Histogram.Create Histograms"]
				boolValue];	
		
	if(createHistograms)
	{
		numberBins =  [[options valueForKeyPath: @"Histogram.Number Bins"]
				doubleValue];
		matrixEnum = [processedEnergies dataMatrixEnumerator];
		while(matrix = [matrixEnum nextObject])
		{
			dataSet = [self histogramsFor: matrix numberOfBins: numberBins];
			
			//If there is more than one system change the data set names
			//so they aren't all the same
			if([[processedEnergies dataMatrices] count] > 1)
				[dataSet setValue: [NSString stringWithFormat: @"%@ Histograms", [matrix name]] 
					forMetadataKey: @"Name" 
					inDomain: AdUserMetadataDomain];
					
			[results addObject: dataSet];
		}
	}	
		
	[resultsDict setObject: results 
		forKey: @"ULAnalysisPluginDataSets"];
	[resultsDict setObject: resultsString forKey: @"ULAnalysisPluginString"];

	return resultsDict;
}

@end
