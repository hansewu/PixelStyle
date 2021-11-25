#import "PSMargins.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSWhiteboard.h"
#import "PSView.h"
#import "PSLayer.h"
#import "PSLayerUndo.h"
#import "PSHelpers.h"
#import "PSScale.h"
#import "PSSelection.h"
#import "Units.h"

@implementation PSMargins

- (id)init
{
	m_nUndoMax = kNumberOfMarginRecordsPerMalloc;
	m_pMURUndoRecords = malloc(m_nUndoMax * sizeof(MarginUndoRecord));
	m_nUndoCount = 0;
	m_bSheetShown = FALSE;
	
	return self;
}

- (void)dealloc
{
	free(m_pMURUndoRecords);
	[super dealloc];
}

- (void)determineContentBorders
{
	int width, height;
	int spp = [[m_idDocument contents] spp];
	unsigned char *data;
	int i, j, k;
	id layer;
	
	// Start out with invalid content borders
	m_nContentLeft = m_nContentRight = m_nContentTop = m_nContentBottom =  -1;
	
    BOOL bNeedUnLock = NO;
	// Select the appropriate data for working out the content borders
	if (m_nWorkingIndex == kAllLayers) {
//		data = [(PSWhiteboard *)[m_idDocument whiteboard] data];
		width = [(PSContent *)[m_idDocument contents] width];
		height = [(PSContent *)[m_idDocument contents] height];
        
        data = malloc(width * height * 4);
        [self getWhiteBoardData:width height:height bufferOut:data];
	}
	else {
		layer = [[m_idDocument contents] layer:m_nWorkingIndex];
		data = [(PSLayer *)layer getRawData]; bNeedUnLock = YES;
		width = [(PSLayer *)layer width];
		height = [(PSLayer *)layer height];
        
        
	}
	
	// Determine left content margin
	for (i = 0; i < width && m_nContentLeft == -1; i++) {
		for (j = 0; j < height && m_nContentLeft == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						m_nContentLeft = i;
				}
			}
		}
	}
	
	// Determine right content margin
	for (i = width - 1; i >= 0 && m_nContentRight == -1; i--) {
		for (j = 0; j < height && m_nContentRight == -1; j++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						m_nContentRight = width - 1 - i;
				}
			}
		}
	}
	
	// Determine top content margin
	for (j = 0; j < height && m_nContentTop == -1; j++) {
		for (i = 0; i < width && m_nContentTop == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						m_nContentTop = j;
				}
			}
		}
	}
	
	// Determine bottom content margin
	for (j = height - 1; j >= 0 && m_nContentBottom == -1; j--) {
		for (i = 0; i < width && m_nContentBottom == -1; i++) {
			if (data[j * width * spp + i * spp + (spp - 1)] != 0) {
				for (k = 0; k < spp; k++) {
					if (data[j * width * spp + i * spp + k] != data[k])
						m_nContentBottom = height - 1 - j;
				}
			}
		}
	}
    
    if(bNeedUnLock)
    {
        layer = [[m_idDocument contents] layer:m_nWorkingIndex];
        [(PSLayer *)layer unLockRawData];
    }
    else
    {
        free(data); data = nil;
    }
}

-(int)getWhiteBoardData:(int)nWidth height:(int)nHeight bufferOut:(unsigned char *)pBufRGBA
{
    memset(pBufRGBA, 0, nWidth*nHeight*4);
    CGContextRef context = MyCreateBitmapContext(nWidth , nHeight, pBufRGBA, true);
    assert(nil != context);
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:nHeight];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
//    RENDER_CONTEXT_INFO info;
//    info.context = context;
//    info.offset = CGPointMake(0, 0);
//    info.scale = CGSizeMake(1.0, 1.0);
//    info.refreshMode = 2;
//    info.state = NULL;
//    
//    [[[m_idDocument whiteboard] compositor] compositeLayersToContext:info];
    
    [[[m_idDocument whiteboard] compositor] compositeLayersToContextFull:context];
    
    unsigned char *pBuf1 = (unsigned char *)CGBitmapContextGetData(context);
    assert(pBuf1 == pBufRGBA);
    
    CGContextRelease(context);
    
    return 0;
}

- (void)run:(BOOL)global
{
    [self initViews];
    
    id contents = [m_idDocument contents];
    id layer = NULL;
    id menuItem;
    NSString *string;
    float xres, yres;
    
    // Determine the working index
    if (global)
        m_nWorkingIndex = kAllLayers;
    else
        m_nWorkingIndex = [[m_idDocument contents] activeLayerIndex];
    
    // Set the selection label correctly
    if (m_nWorkingIndex == kAllLayers) {
        [m_idSelectionLabel setStringValue:LOCALSTR(@"whole m_idDocument", @"Whole Document")];
    }
    else {
        layer = [contents layer:m_nWorkingIndex];
        [m_idSelectionLabel setStringValue:[layer name]];
        
    }
 
    /*
    // Set paper name
    if ([[m_idDocument printInfo] respondsToSelector:@selector(localizedPaperName)]) {
        menuItem = [m_idPresetsMenu itemAtIndex:[m_idPresetsMenu indexOfItemWithTag:2]];
        string = [NSString stringWithFormat:@"%@ (%@)", LOCALSTR(@"paper size", @"Paper size"), [[m_idDocument printInfo] localizedPaperName]];
        [menuItem setTitle:string];
    }
    */
    // Set units
    m_nUnits = [m_idDocument measureStyle];
    
    // Get the resolutions
    xres = [contents xres];
    yres = [contents yres];
    
    // Set the values properly
    [m_idWidthPopdown selectItemAtIndex:m_nUnits];
    [m_idHeightPopdown selectItemAtIndex:m_nUnits];
    [m_idTopPopdown selectItemAtIndex:m_nUnits];
    [m_idBottomPopdown selectItemAtIndex:m_nUnits];
    [m_idLeftPopdown selectItemAtIndex:m_nUnits];
    [m_idRightPopdown selectItemAtIndex:m_nUnits];
    
    [m_idTopValue setStringValue:StringFromPixels(0, m_nUnits, yres)]; [m_idBottomValue setStringValue:StringFromPixels(0, m_nUnits, yres)];
	[m_idLeftValue setStringValue:StringFromPixels(0, m_nUnits, xres)]; [m_idRightValue setStringValue:StringFromPixels(0, m_nUnits, xres)];
	if (m_nWorkingIndex == kAllLayers) {
		[m_idWidthValue setStringValue:StringFromPixels([(PSContent *)contents width], m_nUnits, xres)];
		[m_idHeightValue setStringValue:StringFromPixels([(PSContent *)contents height],m_nUnits, yres)];
	}
	else {
		[m_idWidthValue setStringValue:StringFromPixels([(PSLayer *)layer width], m_nUnits, xres)];
		[m_idHeightValue setStringValue:StringFromPixels([(PSLayer *)layer height], m_nUnits, yres)];
	}
	
	// Determine the content borders
	[self determineContentBorders];
	
	// If we have invalid content borders don't allow them to be used
	[m_idContentRelative setState:NSOffState];
	if (m_nContentLeft == -1 || m_nContentTop == -1)
		[m_idContentRelative setEnabled:NO];
	else
		[m_idContentRelative setEnabled:YES];
		
	// If we are not playing with the whole m_idDocument don't let the user apply to all
	if (m_nWorkingIndex == kAllLayers){
		[m_idClippingMatrix setHidden:NO];
		[m_idSheet setFrame:NSMakeRect([m_idSheet frame].origin.x, [m_idSheet frame].origin.y, [m_idSheet frame].size.width, 376) display: TRUE];
	}else{
		[m_idClippingMatrix setHidden:YES];
		[m_idSheet setFrame:NSMakeRect([m_idSheet frame].origin.x, [m_idSheet frame].origin.y, [m_idSheet frame].size.width, 318) display: TRUE];
	}
	// Make sure the size is correct depending on when we display it
	if(!m_bSheetShown){
		[m_idSheet setFrame:NSMakeRect([m_idSheet frame].origin.x, [m_idSheet frame].origin.y, [m_idSheet frame].size.width, [m_idSheet frame].size.height + 22) display: TRUE];
		m_bSheetShown = TRUE;
	}
	// Update values
	[self marginsChanged:NULL];

	// Show the sheet
	[NSApp beginSheet:m_idSheet modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
//    NSRect windowRect = [[m_idDocument window] frame];
//    [m_idSheet setFrameOrigin:NSMakePoint(windowRect.origin.x + windowRect.size.width / 2.0 - [m_idSheet frame].size.width/2.0, windowRect.origin.y + windowRect.size.height/2.0 - [m_idSheet frame].size.height/2.0)];
//    
//    [[m_idDocument window] addChildWindow:m_idSheet ordered:NSWindowAbove];
}

-(void)initViews
{
    [m_labelPreset setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Preset", nil)]];
    [m_labelTop setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Top", nil)]];
    [m_labelBottom setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Bottom", nil)]];
    [m_labelLeft setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Left", nil)]];
    [m_labelRight setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Right", nil)]];
    [m_labelWidth setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Width", nil)]];
    [m_labelHeight setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Height", nil)]];
    
    [m_btnCancel setTitle:NSLocalizedString(@"Cancel", nil)];
    [m_btnSet setTitle:NSLocalizedString(@"Set", nil)];
    
    NSCell *cell = [(NSMatrix *)m_idClippingMatrix cellAtRow:0 column:0];
    [cell setTitle:NSLocalizedString(@"Do not clip any content", nil)];
    cell = [(NSMatrix *)m_idClippingMatrix cellAtRow:1 column:0];
    [cell setTitle:NSLocalizedString(@"Clip full-image layers only", nil)];
    cell = [(NSMatrix *)m_idClippingMatrix cellAtRow:2 column:0];
    [cell setTitle:NSLocalizedString(@"Clip all layers", nil)];
    
    NSMenuItem *menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Presets", nil)];
    menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Current Selection", nil)];
    menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:2];
    [menuItem setTitle:NSLocalizedString(@"Clipboard", nil)];
    menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:3];
    [menuItem setTitle:NSLocalizedString(@"Screen size", nil)];
    
    // Set paper name
    if ([[gCurrentDocument printInfo] respondsToSelector:@selector(localizedPaperName)])
    {
        menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:[(NSPopUpButton *)m_idPresetsMenu indexOfItemWithTag:2]];
        NSString *string = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"Paper size", nil), [[gCurrentDocument printInfo] localizedPaperName]];
        [menuItem setTitle:string];
    }
}

- (IBAction)apply:(id)sender
{

	float trueLeft, trueRight, trueBottom, trueTop;
	float oldWidth, oldHeight;
	float xres, yres;
	PSLayer *layer;
	int i;
	
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
//    [[m_idDocument window] removeChildWindow:m_idSheet];
	[m_idSheet orderOut:self];
	
	// Find the resolution
	xres = [[m_idDocument contents] xres];
	yres = [[m_idDocument contents] yres];
	
	// Calculate the margin changes in pixels
	trueLeft = PixelsFromFloat([m_idLeftValue floatValue], m_nUnits, xres);
	trueRight = PixelsFromFloat([m_idRightValue floatValue], m_nUnits, xres);
	trueTop = PixelsFromFloat([m_idTopValue floatValue], m_nUnits, yres);
	trueBottom = PixelsFromFloat([m_idBottomValue floatValue], m_nUnits, yres);
	
	// Make changes if values are content relative 
	if ([m_idContentRelative state]) {
		trueLeft -= m_nContentLeft; trueRight -= m_nContentRight;
		trueTop -= m_nContentTop; trueBottom -= m_nContentBottom;
	}
	
	// Work out the old width and height
	if (m_nWorkingIndex == kAllLayers) {
		oldWidth = [(PSContent *)[m_idDocument contents] width];
		oldHeight = [(PSContent *)[m_idDocument contents] height];
	}
	else {
		oldWidth = [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width];
		oldHeight = [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height];
	}
	
	// Don't continue if values are unreasonable or unchanged
	if (trueLeft + oldWidth + trueRight < kMinImageSize) { NSBeep(); return; }
	if (trueTop + oldHeight + trueBottom < kMinImageSize) { NSBeep(); return; }
	if (trueLeft + oldWidth + trueRight > kMaxImageSize) { NSBeep(); return; }
	if (trueTop + oldHeight + trueBottom > kMaxImageSize) { NSBeep(); return; }
	if (trueLeft == 0 && trueRight == 0 && trueTop == 0 && trueBottom == 0) { return; }
	
	// Make the margin changes
	if (m_nWorkingIndex == kAllLayers && [m_idClippingMatrix selectedRow] > kNoClipMode) {
		for (i = 0; i < [[m_idDocument contents] layerCount]; i++) {
			layer = [[m_idDocument contents] layer:i];
			if ([layer width] == oldWidth && [layer height] == oldHeight && [layer xoff] == 0 && [layer yoff] == 0){
				[self setMarginLeft:trueLeft top:trueTop right:trueRight bottom:trueBottom index:i];
			}else if([m_idClippingMatrix selectedRow] == kAllClipMode){
				int newLeft = 0, newRight = 0, newTop = 0, newBottom = 0;
				if([layer xoff] < -1 * trueLeft) newLeft = trueLeft + [layer xoff];
				if([layer yoff] < -1 * trueTop) newTop = trueTop + [layer yoff];
				if([layer xoff] + [layer width] > oldWidth + trueRight) newRight = (int)(oldWidth + trueRight) - ([layer width] + [layer xoff]);
				if([layer yoff] + [layer height] > oldHeight + trueBottom) newBottom = (int)(oldHeight + trueBottom) - ([layer height] + [layer yoff]);
				if((newLeft + newRight + [layer width] < kMinImageSize) || (newTop + newBottom + [layer height] < kMinImageSize)) NSLog(@"Delete Layer?");
				else [self setMarginLeft:newLeft top:newTop right:newRight bottom:newBottom index:i];
			}
		}
	}
	[self setMarginLeft:trueLeft top:trueTop right:trueRight bottom:trueBottom index:m_nWorkingIndex];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
//    [[m_idDocument window] removeChildWindow:m_idSheet];
	[m_idSheet orderOut:self];
}

- (IBAction)condenseLayer:(id)sender
{
	int index = [[m_idDocument contents] activeLayerIndex];
	
	m_nWorkingIndex = index;
	[self determineContentBorders];
	[self setMarginLeft:-m_nContentLeft top:-m_nContentTop right:-m_nContentRight bottom:-m_nContentBottom index:index];
}

- (IBAction)condenseToSelection:(id)sender
{
	int index = [[m_idDocument contents] activeLayerIndex];
	m_nWorkingIndex = index;

	PSLayer *activeLayer = [[m_idDocument contents] activeLayer];
	IntRect selRect = [[m_idDocument selection] localRect];

	int top = [(PSLayer *)activeLayer height] - selRect.origin.y - selRect.size.height;
	int right = [(PSLayer *)activeLayer width] - selRect.origin.x - selRect.size.width;
	
	[self setMarginLeft:-selRect.origin.x top:-selRect.origin.y right:-right bottom:-top index:index];
}

- (IBAction)expandLayer:(id)sender
{
	id layer;
	int width, height;
	
	layer = [[m_idDocument contents] activeLayer];
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
	[self setMarginLeft:[layer xoff] top:[layer yoff] right:width - ([layer xoff] + [(PSLayer *)layer width]) bottom:height - ([layer yoff] + [(PSLayer *)layer height]) index:kActiveLayer];
}

- (IBAction)cropImage:(id)sender
{
	NSLog(@"Cropping Not Implemented Yet. \n");
}

- (IBAction)maskImage:(id)sender
{
	NSLog(@"Masking Not Implemented Yet. \n");
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(int)index undoRecord:(MarginUndoRecord *)undoRecord
{
	id contents = [m_idDocument contents], layer = NULL;
	int i;
	
	// Correct the index if necessary
	if (index == kActiveLayer)
		index = [[m_idDocument contents] activeLayerIndex];
		
	// Get the layer if appropriate
	if (index != kAllLayers)
		layer = [contents layer:index];
	
	// Take the snapshots if necessary
	if (undoRecord) {
		undoRecord->left = left;
		undoRecord->top = top;
		undoRecord->right = right;
		undoRecord->bottom = bottom;
		if (index != kAllLayers) {
			for (i = 0; i < 4; i++)
				undoRecord->indicies[i] = -1;
			if (left < 0)
				undoRecord->indicies[0] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, -left, [(PSLayer *)layer height]) automatic:NO];
			if (top < 0)
				undoRecord->indicies[1] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(PSLayer *)layer width],  -top) automatic:NO];
			if (right < 0)
				undoRecord->indicies[2] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect([(PSLayer *)layer width] + right, 0, -right, [(PSLayer *)layer height]) automatic:NO];
			if (bottom < 0)
				undoRecord->indicies[3] = [[layer seaLayerUndo] takeSnapshot:IntMakeRect(0, [(PSLayer *)layer height] + bottom, [(PSLayer *)layer width], -bottom) automatic:NO];
		}
	}
	
	// Adjust the margins
	if (index == kAllLayers) {
		[[m_idDocument contents] setMarginLeft:left top:top right:right bottom:bottom];
	}
	else {
		[layer setMarginLeft:left top:top right:right bottom:bottom];
	}
	
	// Update the undo record
	if (undoRecord) {
		undoRecord->index = index;
		undoRecord->isChanged = YES;
	}
}

- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom index:(int)index
{	
	MarginUndoRecord undoRecord;
	
	// Don't do anything if no changes are needed
	if (left == 0 && top == 0 && right == 0 && bottom == 0)
		return;
	
	// Do the adjustment
	[self setMarginLeft:left top:top right:right bottom:bottom index:index undoRecord:&undoRecord];

	// Allow the undo
	if (m_nUndoCount + 1 > m_nUndoMax) {
		m_nUndoMax += kNumberOfMarginRecordsPerMalloc;
		m_pMURUndoRecords = realloc(m_pMURUndoRecords, m_nUndoMax * sizeof(MarginUndoRecord));
	}
	m_pMURUndoRecords[m_nUndoCount] = undoRecord;
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMargins:m_nUndoCount];
	m_nUndoCount++;
	
	// Do appropriate updating
	if (index == kAllLayers)
		[[m_idDocument helpers] boundariesAndContentChanged:NO];
	else
		[[m_idDocument helpers] layerBoundariesChanged:index];
}

- (void)undoMargins:(int)undoIndex
{
	MarginUndoRecord undoRecord;
	id layer, contents = [m_idDocument contents];
	int i;
	
	// Get the undo record
	undoRecord = m_pMURUndoRecords[undoIndex];
	
	// We have different responses depending on whether the change is current or not
	if (undoRecord.isChanged) {
		if (undoRecord.index == kAllLayers) {
			[contents setMarginLeft:-undoRecord.left top:-undoRecord.top right:-undoRecord.right bottom:-undoRecord.bottom];
		}
		else {
			layer = [contents layer:undoRecord.index];
			[layer setMarginLeft:-undoRecord.left top:-undoRecord.top right:-undoRecord.right bottom:-undoRecord.bottom];
			for (i = 0; i < 4; i++) {
				if (undoRecord.indicies[i] != -1) {
					[[layer seaLayerUndo] restoreSnapshot:undoRecord.indicies[i] automatic: NO];
				}
			}
		}
		undoRecord.isChanged = NO;
	}
	else {
		[self setMarginLeft:undoRecord.left top:undoRecord.top right:undoRecord.right bottom:undoRecord.bottom index:undoRecord.index undoRecord:NULL];
		undoRecord.isChanged = YES;
	}
	
	// Put the updated undo record back and allow the undo
	m_pMURUndoRecords[undoIndex] = undoRecord;
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMargins:undoIndex];
	
	// Do appropriate updating
	if (undoRecord.index == kAllLayers)
		[[m_idDocument helpers] boundariesAndContentChanged:NO];
	else
		[[m_idDocument helpers] layerBoundariesChanged:undoRecord.index];
}

- (IBAction)marginsChanged:(id)sender
{
	int trueLeft, trueRight, trueBottom, trueTop;
	float xres, yres;
	int width, height;
	
	// Find the resolution
	xres = [[m_idDocument contents] xres];
	yres = [[m_idDocument contents] yres];
	
	// Calculate the margin changes in pixels
	trueLeft = PixelsFromFloat([m_idLeftValue floatValue], m_nUnits, xres);
	trueRight = PixelsFromFloat([m_idRightValue floatValue], m_nUnits, xres);
	trueTop = PixelsFromFloat([m_idTopValue floatValue], m_nUnits, yres);
	trueBottom = PixelsFromFloat([m_idBottomValue floatValue], m_nUnits, yres);
	
	// Make changes if values are content relative
	if ([m_idContentRelative state]) {
		trueLeft -= m_nContentLeft; trueRight -= m_nContentRight;
		trueTop -= m_nContentTop; trueBottom -= m_nContentBottom;
	}
	
	// Determine the new width and height
	if (m_nWorkingIndex == kAllLayers) {
		width = [(PSContent *)[m_idDocument contents] width] + trueLeft + trueRight;
		height = [(PSContent *)[m_idDocument contents] height] + trueTop + trueBottom;
	}
	else {
		width = [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width] + trueLeft + trueRight;
		height = [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height] + trueTop + trueBottom;
	}

	// Finally display the changes
	[m_idWidthValue setStringValue:StringFromPixels(width, m_nUnits, xres)];
	[m_idHeightValue setStringValue:StringFromPixels(height, m_nUnits, yres)];
}

- (IBAction)dimensionsChanged:(id)sender
{
	float xres, yres;
	int width, height, curLeft, curRight, curTop, curBottom;
	
	// Find the resolution
	xres = [[m_idDocument contents] xres];
	yres = [[m_idDocument contents] yres];
	
	// Determine the new width and height
	width = PixelsFromFloat([m_idWidthValue floatValue], m_nUnits, xres);
	height = PixelsFromFloat([m_idHeightValue floatValue], m_nUnits, yres);

	IntSize delta = IntMakeSize(0,0);
	// Work out the margin adjustment needed
	if ([m_idContentRelative state]) {
		if (m_nWorkingIndex == kAllLayers) {
			delta.width = (width + m_nContentLeft + m_nContentRight) - [(PSContent *)[m_idDocument contents] width];
			delta.height = (height + m_nContentTop + m_nContentBottom) - [(PSContent *)[m_idDocument contents] height];
		}
		else {
			delta.width = (width + m_nContentLeft + m_nContentRight) - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width];
			delta.height = (height + m_nContentTop + m_nContentBottom) - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height];
		}
	}
	else {
		if (m_nWorkingIndex == kAllLayers) {
			delta.width = width - [(PSContent *)[m_idDocument contents] width];
			delta.height = height - [(PSContent *)[m_idDocument contents] height];
		}
		else {
			delta.width = width - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width];
			delta.height = height - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height];
		}
	}
	
	// Calculate how this affects the current margins
	curLeft = PixelsFromFloat([m_idLeftValue floatValue], m_nUnits, xres);
	curRight = PixelsFromFloat([m_idRightValue floatValue], m_nUnits, xres);
	curTop = PixelsFromFloat([m_idTopValue floatValue], m_nUnits, yres);
	curBottom = PixelsFromFloat([m_idBottomValue floatValue], m_nUnits, yres);
	delta.width -= (curLeft + curRight);
	delta.height -= (curTop + curBottom);

	// Finally display the changes
	[m_idLeftValue setStringValue:StringFromPixels(delta.width / 2 + curLeft, m_nUnits, xres)];
	[m_idRightValue setStringValue:StringFromPixels(delta.width / 2 + delta.width % 2 + curRight , m_nUnits, xres)];
	[m_idTopValue setStringValue:StringFromPixels(delta.height / 2 + curTop, m_nUnits, yres)];
	[m_idBottomValue setStringValue:StringFromPixels(delta.height / 2 + delta.height % 2 + curBottom, m_nUnits, yres)];
}

- (IBAction)unitsChanged:(id)sender
{
	id contents = [m_idDocument contents];
	float xres, yres;
	int oldTopValue, oldLeftValue, oldBottomValue, oldRightValue;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Remember the old values
	oldTopValue = PixelsFromFloat([m_idTopValue floatValue], m_nUnits, yres);
	oldBottomValue = PixelsFromFloat([m_idBottomValue floatValue], m_nUnits, yres);
	oldLeftValue = PixelsFromFloat([m_idLeftValue floatValue], m_nUnits, xres);
	oldRightValue = PixelsFromFloat([m_idRightValue floatValue], m_nUnits, xres);
				
	// Set units
	m_nUnits = [sender indexOfSelectedItem];
	
	// Set the new labels
	[m_idWidthPopdown selectItemAtIndex:m_nUnits];
	[m_idHeightPopdown selectItemAtIndex:m_nUnits];
	[m_idTopPopdown selectItemAtIndex:m_nUnits];
	[m_idBottomPopdown selectItemAtIndex:m_nUnits];
	[m_idLeftPopdown selectItemAtIndex:m_nUnits];
	[m_idRightPopdown selectItemAtIndex:m_nUnits];

	// Set the new margins
	[m_idTopValue setStringValue:StringFromPixels(oldTopValue, m_nUnits, yres)];
	[m_idBottomValue setStringValue:StringFromPixels(oldBottomValue, m_nUnits, yres)];
	[m_idLeftValue setStringValue:StringFromPixels(oldLeftValue, m_nUnits, xres)];
	[m_idRightValue setStringValue:StringFromPixels(oldRightValue, m_nUnits, xres)];
	
	// Update the rest
	[self marginsChanged:NULL];
}

- (IBAction)changeToPreset:(id)sender
{
	NSPasteboard *pboard;
	NSString *availableType;
	NSImage *image;
	NSSize paperSize;
	IntSize size = IntMakeSize(0, 0);
	float xres, yres;
	id focusObject;
	id contents = [m_idDocument contents];
	BOOL customOrigin = NO;
	
	// Get the preset's size
	if (m_nWorkingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layer:m_nWorkingIndex];
	xres = [contents xres];
	yres = [contents yres];
	switch ([[m_idPresetsMenu selectedItem] tag]) {
		case 0:
			pboard = [NSPasteboard generalPasteboard];
//			availableType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NSPICTPboardType, NULL]];
            availableType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType, NULL]];
			if (availableType) {
				image = [[NSImage alloc] initWithData:[pboard dataForType:availableType]];
				size = NSSizeMakeIntSize([image size]);
				[image autorelease];
			}
			else {
				NSBeep();
				return;
			}
		break;
		case 1:
			size = NSSizeMakeIntSize([[NSScreen mainScreen] frame].size);
		break;
		case 2:
			paperSize = [[m_idDocument printInfo] paperSize];
			paperSize.height -= [[m_idDocument printInfo] topMargin] + [[m_idDocument printInfo] bottomMargin];
			paperSize.width -= [[m_idDocument printInfo] leftMargin] + [[m_idDocument printInfo] rightMargin];
			size = NSSizeMakeIntSize(paperSize);
			size.width = (float)size.width * (xres / 72.0);
			size.height = (float)size.height * (yres / 72.0);
		break;
		case 3:
			if(![[m_idDocument selection] active])
				return;
			size = [[m_idDocument selection] localRect].size;
			customOrigin = YES;
		break;
		default:
			NSLog(@"Preset not supported.");
		break;
	}
	
	// Work out the margin adjustment needed
	if(customOrigin){
		IntPoint origin;
		if(m_nWorkingIndex == kAllLayers){
			origin = [[m_idDocument selection] globalRect].origin;
			[m_idRightValue setStringValue:StringFromPixels( origin.x + size.width - [(PSContent *)[m_idDocument contents] width], m_nUnits, xres)];
			[m_idBottomValue setStringValue:StringFromPixels(origin.y + size.height - [(PSContent *)[m_idDocument contents] height] , m_nUnits, yres)];
		}else{
			origin = [[m_idDocument selection] localRect].origin;
			[m_idRightValue setStringValue:StringFromPixels(origin.x + size.width - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width] , m_nUnits, xres)];
			[m_idBottomValue setStringValue:StringFromPixels(origin.y + size.height  - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height], m_nUnits, yres)];
		}
		[m_idLeftValue setStringValue:StringFromPixels(-1 * origin.x, m_nUnits, xres)];
		[m_idTopValue setStringValue:StringFromPixels(-1 * origin.y, m_nUnits, yres)];
	}else{
		if ([m_idContentRelative state]) {
			if (m_nWorkingIndex == kAllLayers) {
				size.width = (size.width + m_nContentLeft + m_nContentRight) - [(PSContent *)[m_idDocument contents] width];
				size.height = (size.height + m_nContentTop + m_nContentBottom) - [(PSContent *)[m_idDocument contents] height];
			}
			else {
				size.width = (size.width + m_nContentLeft + m_nContentRight) - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width];
				size.height = (size.height + m_nContentTop + m_nContentBottom) - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height];
			}
		}
		else {
			if (m_nWorkingIndex == kAllLayers) {
				size.width = size.width - [(PSContent *)[m_idDocument contents] width];
				size.height = size.height - [(PSContent *)[m_idDocument contents] height];
			}
			else {
				size.width = size.width - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] width];
				size.height = size.height - [(PSLayer *)[[m_idDocument contents] layer:m_nWorkingIndex] height];
			}
		}
		
		// Fill out the panel correctly
		[m_idLeftValue setStringValue:StringFromPixels(size.width / 2, m_nUnits, xres)];
		[m_idRightValue setStringValue:StringFromPixels(size.width / 2 + size.width % 2, m_nUnits, xres)];
		[m_idTopValue setStringValue:StringFromPixels(size.height / 2, m_nUnits, yres)];
		[m_idBottomValue setStringValue:StringFromPixels(size.height / 2 + size.height % 2, m_nUnits, yres)];
	}
	
	[self marginsChanged:NULL];
}

static CGContextRef MyCreateBitmapContext(int pixelsWidth,int pixelsHigh, void * pBuffer, int bAlphaPremultiplied)
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void * bitmapData;
    int  bitmapByteCount;
    int  bitmapBytesPerRow;
    
    bitmapBytesPerRow  = (pixelsWidth * 4);
    bitmapByteCount  = (bitmapBytesPerRow * pixelsHigh);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    //bitmapData = malloc( bitmapByteCount );
    bitmapData = pBuffer;
    //bitmapData =(char*)CGBitmapContextGetData((CGContextRef)[EAGLContext currentContext]);//   m_glContext
    if (bitmapData == NULL)
    {
        assert(false);
        fprintf (stderr, "Memory not allocated!");
        return NULL;
    }
    
    //  if(bAlphaPremultiplied)
    context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    //  else
    //context = CGBitmapContextCreate(bitmapData, pixelsWidth, pixelsHigh, 8, bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Big);
    if (context== NULL)
    {
        //free (bitmapData);
        assert(false);
        fprintf (stderr, "Context not created!");
        return NULL;
    }
    CGColorSpaceRelease( colorSpace );
    
    return context;
}


@end
