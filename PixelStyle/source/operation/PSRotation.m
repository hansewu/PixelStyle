#import "PositionTool.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSWhiteboard.h"
#import "PSView.h"
#import "PSHelpers.h"
#import "PSTools.h"
#import "PSSelection.h"
#import "PSLayerUndo.h"
#import "PSRotation.h"

@implementation PSRotation

- (id)init
{
	m_nUndoMax = kNumberOfRotationRecordsPerMalloc;
	m_pRURUndoRecords = malloc(m_nUndoMax * sizeof(RotationUndoRecord));
	m_nUndoCount = 0;
	
	return self;
}

- (void)dealloc
{
	free(m_pRURUndoRecords);
	[super dealloc];
}

- (void)run
{
    [self initViews];
	id contents = [m_idDocument contents];
	id layer = NULL;

	// Fill out the selection label
	layer = [contents layer:[contents activeLayerIndex]];
	if ([layer floating])
		[m_idSelectionLabel setStringValue:LOCALSTR(@"floating", @"Floating Selection")];
	else
		[m_idSelectionLabel setStringValue:[NSString stringWithFormat:@"%@", [layer name]]];
	
	// Set the initial values
	[m_idRotateValue setStringValue:@"0"];

	// Show the sheet
	[NSApp beginSheet:m_idSheet modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

-(void)initViews
{
    [m_labelRotate setStringValue:NSLocalizedString(@"Rotate", nil)];
    [m_labelDegrees setStringValue:NSLocalizedString(@"degress", nil)];
    
    [m_btnCancel setTitle:NSLocalizedString(@"Cancel", nil)];
    [m_btnRotate setTitle:NSLocalizedString(@"Rotate", nil)];
}

- (IBAction)apply:(id)sender
{
	id contents = [m_idDocument contents];
	id layer = NULL;
	
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
	[m_idSheet orderOut:self];

	// Rotate the image
	if ([m_idRotateValue floatValue] != 0)
    {
		layer = [contents layer:[contents activeLayerIndex]];
		[self rotate:[m_idRotateValue floatValue] withTrim:[layer floating]];
	}
}

- (IBAction)cancel:(id)sender
{
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
	[m_idSheet orderOut:self];
}

 float mod_float(float value, float divisor)
{
	float result;
	
	if (value < 0.0) result = value * -1.0;
	else result = value;
	while (result - 360.0 >= 0.0) {
		result -= 360.0;
	}
	
	return result;
}

- (void)rotate:(float)degrees withTrim:(BOOL)trim
{
	id contents = [m_idDocument contents];
	id activeLayer = [contents activeLayer];
	RotationUndoRecord undoRecord;
	
	// Only rotate
	if (degrees > 0) degrees = 360 - mod_float(degrees, 360);
	else degrees = mod_float(degrees, 360);
	if (degrees == 0.0)
		return;

	// Record the undo details
	undoRecord.index =  [contents activeLayerIndex];
	undoRecord.rotation = degrees;
	undoRecord.undoIndex = [[activeLayer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(PSLayer *)activeLayer width], [(PSLayer *)activeLayer height]) automatic:NO];
	undoRecord.rect = IntMakeRect([activeLayer xoff], [activeLayer yoff], [(PSLayer *)activeLayer width], [(PSLayer *)activeLayer height]);
	undoRecord.isRotated = YES;
	undoRecord.withTrim = trim;
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoRotation:m_nUndoCount];
	[activeLayer setRotation:degrees interpolation:GIMP_INTERPOLATION_CUBIC withTrim:trim];
	if ([activeLayer floating] && trim) [[m_idDocument selection] selectOpaque];
	else [[m_idDocument selection] clearSelection];
	if (!trim && ![activeLayer hasAlpha])
    {
		undoRecord.disableAlpha = YES;
		[activeLayer toggleAlpha];
	}
	else
    {
		undoRecord.disableAlpha = NO;
	}
	[[m_idDocument helpers] layerBoundariesChanged:kActiveLayer];

	// Allow the undo
	if (m_nUndoCount + 1 > m_nUndoMax)
    {
		m_nUndoMax += kNumberOfRotationRecordsPerMalloc;
		m_pRURUndoRecords = realloc(m_pRURUndoRecords, m_nUndoMax * sizeof(RotationUndoRecord));
	}
	m_pRURUndoRecords[m_nUndoCount] = undoRecord;
	m_nUndoCount++;
}

- (void)undoRotation:(int)undoIndex
{
	id contents = [m_idDocument contents];
	RotationUndoRecord undoRecord;
	id layer;
	
	// Prepare for redo
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoRotation:undoIndex];
	
	// Get the undo record
	undoRecord = m_pRURUndoRecords[undoIndex];
	
	// Behave differently depending on whether things are already rotated
	if (undoRecord.isRotated)
    {
	
		// If already rotated...
		layer = [contents layer:undoRecord.index];
		[layer setOffsets:IntMakePoint(undoRecord.rect.origin.x, undoRecord.rect.origin.y)];
		[layer setMarginLeft:0 top:0 right:undoRecord.rect.size.width - [(PSLayer *)layer width] bottom:undoRecord.rect.size.height - [(PSLayer *)layer height]];
		[[layer seaLayerUndo] restoreSnapshot:undoRecord.undoIndex automatic:NO];
		if (undoRecord.withTrim) [[m_idDocument selection] selectOpaque];
		else [[m_idDocument selection] clearSelection];
		if (undoRecord.disableAlpha) [layer toggleAlpha];
		[[m_idDocument helpers] layerBoundariesChanged:kActiveLayer];
		m_pRURUndoRecords[undoIndex].isRotated = NO;
		
	}
	else
    {
	
		// If not rotated...
		layer = [contents layer:undoRecord.index];
		[layer setRotation:undoRecord.rotation interpolation:NSImageInterpolationHigh withTrim:undoRecord.withTrim];
		if (undoRecord.withTrim) [[m_idDocument selection] selectOpaque];
		else [[m_idDocument selection] clearSelection];
		[[m_idDocument helpers] layerBoundariesChanged:kActiveLayer];
		m_pRURUndoRecords[undoIndex].isRotated = YES;
		
	}
}


@end
