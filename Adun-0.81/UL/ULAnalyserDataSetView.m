#include "ULAnalyserDataSetView.h"

@implementation ULAnalyserDataSetView

- (id) init
{	
	NSError* error = nil;

	if(self = [super init])
	{
		//Controls the width of the cells in the table view
		//so we can always see a four decimal floating point number.
		//We should be able to remove this if NSNumberFormatter is implemented.
		defaultWidth = [[NSFont userFontOfSize: 12] widthOfString:
				[NSString stringWithFormat: @"%.4e", 0.0]];
		defaultWidth +=10;
		dataSet = nil;
		currentTable = nil;
		terms = nil;	
	}	

	return self;
}

- (void) dealloc
{
	[terms release];
	[dataSet release];
	[super dealloc];
}

- (void)awakeFromNib
{
	NSEnumerator* columnEnum;
	NSTableColumn* column;

	[resultsTable setAllowsColumnReordering: YES];
	[resultsTable setAllowsColumnResizing: YES];
	[resultsTable setDataSource: self];
	[resultsTable setDelegate: self];
	[resultsTable sizeToFit];
	[displayList removeAllItems];
	[displayList setAutoenablesItems: NO];
	
	//Dragging	
	if([resultsTable respondsToSelector:
		@selector(setDraggingSourceOperationMask:forLocal:)])
	{
		[resultsTable setDraggingSourceOperationMask: NSDragOperationGeneric
			forLocal: NO];	
		[resultsTable setVerticalMotionCanBeginDrag: YES];
	}
	
	//Make all the column headers the same - the ones added by GORM
	//don't draw their background. The ones added programatically do.
#ifdef GNUSTEP	
	columnEnum = [[resultsTable tableColumns] objectEnumerator];
	while(column = [columnEnum nextObject]) 
		[(NSTextFieldCell*)[column headerCell] setDrawsBackground: YES];
#endif		
}


- (void) setDataSet: (AdDataSet*) aDataSet
{
	if(aDataSet != dataSet)
		[dataSet release];
	dataSet = [aDataSet retain];	
}

- (id) dataSet
{
	return dataSet;	
}

- (id) displayedMatrix
{
	return [[currentTable retain] autorelease];
}

- (NSArray*) orderedColumnHeaders
{
	NSEnumerator* columnEnum;
	NSMutableArray* currentOrder;
	id column;

	currentOrder = [NSMutableArray array];
	columnEnum = [[resultsTable tableColumns] objectEnumerator];
	while(column = [columnEnum nextObject])
		[currentOrder addObject: [[column headerCell] stringValue]];
	
	return currentOrder;
}

- (void) _displayCurrentDataSetTable
{
	int i;
	int currentNumberOfColumns, requiredNumberOfColumns, diff;
	id subsystem, newColumn, columns;
	NSRange range;

	NS_DURING
	{
		requiredNumberOfColumns = [currentTable numberOfColumns];
		currentNumberOfColumns = [resultsTable numberOfColumns];
		columns = [resultsTable tableColumns];
	
		[terms release];
		terms = [currentTable columnHeaders];
		[terms retain];

		if(currentNumberOfColumns < requiredNumberOfColumns)
		{
			for(i=0; i<currentNumberOfColumns; i++)
			{
				[[[columns objectAtIndex: i] headerCell]
					 setObjectValue: [terms objectAtIndex: i]];

				[[columns objectAtIndex: i] sizeToFit];
				if([[columns objectAtIndex: i] width] < defaultWidth)
					[[columns objectAtIndex: i] setWidth: defaultWidth];

				[[columns objectAtIndex: i] setIdentifier:[terms objectAtIndex: i]];
				[[[columns objectAtIndex: i] dataCell]
					setAlignment: NSCenterTextAlignment];
			}

			for(i=currentNumberOfColumns; i<requiredNumberOfColumns; i++)
			{
				newColumn = [[NSTableColumn alloc] 
						initWithIdentifier: [terms objectAtIndex: i]];
				[[newColumn headerCell] setObjectValue: [terms objectAtIndex: i]];
				[newColumn sizeToFit];
				
				if([newColumn width] < defaultWidth)
					[newColumn setWidth: defaultWidth];

				[[newColumn dataCell] setAlignment: NSCenterTextAlignment];
				[resultsTable addTableColumn: newColumn];
				[newColumn autorelease];
			}
		}
		else
		{
			for(i=0; i<requiredNumberOfColumns; i++)
			{
				[[[columns objectAtIndex: i] headerCell]
				 	setObjectValue: [terms objectAtIndex: i]];
				[[columns objectAtIndex: i] setIdentifier:[terms objectAtIndex: i]];
				[[columns objectAtIndex: i] sizeToFit];

				if([[columns objectAtIndex: i] width] < defaultWidth)
					[[columns objectAtIndex: i] setWidth: defaultWidth];

				[[[columns objectAtIndex: i] dataCell] 
					setAlignment: NSCenterTextAlignment];
			}

			for(i=currentNumberOfColumns-1; i>=requiredNumberOfColumns; i--)
				[resultsTable removeTableColumn: [columns objectAtIndex: i]];
		}

		[resultsTable setNeedsDisplay: YES];
		[resultsTable reloadData];
	}
	NS_HANDLER
	{
		NSRunAlertPanel(@"Alert", [localException reason], @"Dismiss", nil, nil);
	}
	NS_ENDHANDLER
}

- (void) displayData
{
	NSEnumerator* dataSetTablesEnum;
	NSMutableArray* tableNames = [NSMutableArray array];
	NSString* name;
	AdDataMatrix* table;
	
	dataSetTablesEnum = [[dataSet dataMatrices] objectEnumerator];
	while(table = [dataSetTablesEnum nextObject])
	{
		name = [table name];
		if(name != nil)
			[tableNames addObject: name];
		else
			[tableNames addObject: @"Table One"];
	}

	[displayList removeAllItems];
	[displayList addItemsWithTitles: tableNames];
	[displayList selectItemAtIndex: 0];
	currentTable = [[dataSet dataMatrices] objectAtIndex: 0];

	if(currentTable != nil)
		[self _displayCurrentDataSetTable];
}

- (void) selectedNewTableItem: (id) sender
{
	int index;

	index = [displayList indexOfSelectedItem];
	currentTable = [[dataSet dataMatrices] objectAtIndex: index];
	
	if(currentTable != nil)
		[self _displayCurrentDataSetTable];
}

- (void) clearDataSet
{
	int i, currentNumberOfColumns;
	NSArray* columns;

	[displayList removeAllItems];
	[dataSet release];
	dataSet = nil;
	currentTable = nil;

	//Care here using cocoa as the array returned seems
	//to be the table views actual ivar and not a copy.
	currentNumberOfColumns = [resultsTable numberOfColumns];
	columns = [[resultsTable tableColumns] copy];

	/*
	 * If there are more than five columns we remove
	 * the extra ones. This is because the result of
	 * sizeToFit when there are hundreds of columns
	 * looks very strange
	 */
	for(i=0; i<currentNumberOfColumns; i++)
	{
		if(i < 5)
		{
			[[[columns objectAtIndex: i] headerCell]
					setObjectValue: @""];
			[[columns objectAtIndex: i] setIdentifier:@""];
			[[columns objectAtIndex: i] sizeToFit];
		}
		else
		{
			[resultsTable removeTableColumn: 
				[columns objectAtIndex: i]];
		}
	}

	currentNumberOfColumns = (currentNumberOfColumns < 5) ? currentNumberOfColumns : 5;

	[resultsTable sizeToFit];
	[resultsTable setNeedsDisplay: YES];
	[resultsTable reloadData];
	[columns release];
}

/*******************

Table Delegate Methods

*******************/

- (void) tableViewColumnDidMove: (NSNotification*) aNotification
{
	[[NSNotificationCenter defaultCenter]
		postNotificationName: @"ULAnalyserDataSetViewColumnOrderDidChangeNotification"
		object: currentTable];
}

/******************

TableData Source methods

********************/

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [currentTable numberOfRows];
}

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	row:(int)rowIndex
{
	int index;
	id value;

	index = [terms indexOfObject: [aTableColumn identifier]];
	value = [currentTable elementAtRow: rowIndex column: index];

	//FIXME: temporary hack until I think of something better
	//or NSNumberFomatter is implemented.

	if([[currentTable dataTypeForColumn: index] isEqual: @"int"]) 
		value = [NSString stringWithFormat: @"%d", [value intValue]];
	else if([[currentTable dataTypeForColumn: index] isEqual: @"double"])
		value = [NSString stringWithFormat: @"%.2e", [value doubleValue]];
	
	return value;
}

- (BOOL) tableView: (NSTableView*)aTableView
	writeRowsWithIndexes: (NSIndexSet*) indexSet
	toPasteboard: (NSPasteboard*) aPasteboard
{	
	int index;
	NSMutableString* string;
	
	string = [NSMutableString string];
	
	[aPasteboard declareTypes: [NSArray arrayWithObjects: NSTabularTextPboardType, NSStringPboardType, nil]
		owner: self];
		
	index = [indexSet firstIndex];	
	while(index != NSNotFound)
	{	
		[string appendFormat: @"%@\n", 
			[[currentTable row: index] componentsJoinedByString: @"\t"]];
		index = [indexSet indexGreaterThanIndex: index];
	}
	
	[aPasteboard setData: [string dataUsingEncoding: NSASCIIStringEncoding] 
		forType: NSStringPboardType];
	
	return YES;	
}

@end

