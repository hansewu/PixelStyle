#import "PSScale.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSLayer.h"
#import "PSLayerUndo.h"
#import "PSView.h"
#import "PSWhiteboard.h"
#import "PSHelpers.h"
#import "PSSelection.h"
#import "Units.h"

@implementation PSScale

- (id)init
{
	m_nUndoMax = kNumberOfScaleRecordsPerMalloc;
	m_pSURUndoRecords = malloc(m_nUndoMax * sizeof(ScaleUndoRecord));
	m_nUndoCount = 0;
	
	return self;
}

- (void)dealloc
{
	int i;
	
	for (i = 0; i < m_nUndoCount; i++) {
		free(m_pSURUndoRecords[i].indicies);
		free(m_pSURUndoRecords[i].rects);
	}
	free(m_pSURUndoRecords);
	[super dealloc];
}

- (void)run:(BOOL)global
{
    [self initViews];
    
	id contents = [m_idDocument contents];
	id layer = NULL;
	id menuItem;
	int value;
	NSString *string;
	float xres, yres;
	
	// Determine the working index
	if (global)
		m_nWorkingIndex = kAllLayers;
	else
		m_nWorkingIndex = [contents activeLayerIndex];
		
	// Set the selection label correctly
	if (m_nWorkingIndex == kAllLayers) {
		[m_idSelectionLabel setStringValue:LOCALSTR(@"whole document", @"Whole Document")];
	}
	else {
		layer = [contents layer:m_nWorkingIndex];
		if ([layer floating])
			[m_idSelectionLabel setStringValue:LOCALSTR(@"floating", @"Floating Selection")];
		else
			[m_idSelectionLabel setStringValue:[NSString stringWithFormat:@"%@", [layer name]]];
	}
	
//	// Set paper name
//	if ([[gCurrentDocument printInfo] respondsToSelector:@selector(localizedPaperName)]) {
//		menuItem = [m_idPresetsMenu itemAtIndex:[m_idPresetsMenu indexOfItemWithTag:2]];
//		string = [NSString stringWithFormat:@"%@ (%@)", LOCALSTR(@"paper size", @"Paper size"), [[gCurrentDocument printInfo] localizedPaperName]];
//		[menuItem setTitle:string];
//	}
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	m_nUnits = [m_idDocument measureStyle];
	[m_idWidthPopdown selectItemAtIndex:m_nUnits];
//	[m_idHeightUnits setTitle:UnitsString(m_nUnits)];
    [m_idHeightPopdown selectItemAtIndex:m_nUnits];
    
	
	// Set the initial scale values
	[m_idXScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", 100.0]];
	[m_idYScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", 100.0]];
	
	// Set the initial width and height values
	if (m_nWorkingIndex == kAllLayers) {
		[m_idWidthValue setStringValue:StringFromPixels([(PSContent *)contents width], m_nUnits, xres)];
		[m_idHeightValue setStringValue:StringFromPixels([(PSContent *)contents height], m_nUnits, yres)];
	}
	else {
		[m_idWidthValue setStringValue:StringFromPixels([(PSLayer *)layer width], m_nUnits, xres)];
		[m_idHeightValue setStringValue:StringFromPixels([(PSLayer *)layer height], m_nUnits, yres)];
	}
	
	// Set the options appropriately
	[m_idKeepProportions setState:NSOnState];
	[m_idInterpolationPopup selectItemAtIndex:[m_idInterpolationPopup indexOfItemWithTag:GIMP_INTERPOLATION_LINEAR]];
	
	// Set the interpolation style
	if ([gUserDefaults objectForKey:@"interpolation"] == NULL) {
		value = GIMP_INTERPOLATION_CUBIC;
	}
	else {
		value = [gUserDefaults integerForKey:@"interpolation"];
		if (value < 0 || value >= [m_idInterpolationPopup numberOfItems])
			value = GIMP_INTERPOLATION_CUBIC;
	}
	[m_idInterpolationPopup selectItemAtIndex:value];
	
	// Show the sheet
	[NSApp beginSheet:m_idSheet modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
    
    
//    NSRect windowRect = [[m_idDocument window] frame];
//    [m_idSheet setFrameOrigin:NSMakePoint(windowRect.origin.x + windowRect.size.width / 2.0 - [m_idSheet frame].size.width/2.0, windowRect.origin.y + windowRect.size.height/2.0 - [m_idSheet frame].size.height/2.0)];
//    
//    [[m_idDocument window] addChildWindow:m_idSheet ordered:NSWindowAbove];
//    
//    [m_idSheet orderFront:nil];
}

-(void)initViews
{
    [m_labelPreset setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Preset", nil)]];
    [m_labelHorizontal setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Horizontal", nil)]];
    [m_labelVertical setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Vertical", nil)]];
    [m_labelWidth setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Width", nil)]];
    [m_labelHeight setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Height", nil)]];
    
    [m_btnCancel setTitle:NSLocalizedString(@"Cancel", nil)];
    [m_btnScale setTitle:NSLocalizedString(@"Scale", nil)];
    
    NSMenuItem *menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Presets", nil)];
    menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Clipboard", nil)];
    menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:2];
    [menuItem setTitle:NSLocalizedString(@"Screen size", nil)];
    
    // Set paper name
    if ([[gCurrentDocument printInfo] respondsToSelector:@selector(localizedPaperName)])
    {
        menuItem = [(NSPopUpButton *)m_idPresetsMenu itemAtIndex:[(NSPopUpButton *)m_idPresetsMenu indexOfItemWithTag:2]];
        NSString *string = [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"Paper size", nil), [[gCurrentDocument printInfo] localizedPaperName]];
        [menuItem setTitle:string];
    }
    
    
    menuItem = [(NSPopUpButton *)m_idInterpolationPopup itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"No Interpolation", nil)];
    menuItem = [(NSPopUpButton *)m_idInterpolationPopup itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Linear Interpolation", nil)];
    menuItem = [(NSPopUpButton *)m_idInterpolationPopup itemAtIndex:2];
    [menuItem setTitle:NSLocalizedString(@"Cubic Interpolation", nil)];
}

- (IBAction)apply:(id)sender
{
	id contents = [m_idDocument contents];
	int newWidth, newHeight;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
//    [[m_idDocument window] removeChildWindow:m_idSheet];
	[m_idSheet orderOut:self];
	[gUserDefaults setInteger:[m_idInterpolationPopup indexOfSelectedItem] forKey:@"interpolation"];

	// Parse width and height	
	newWidth = PixelsFromFloat([m_idWidthValue floatValue],m_nUnits,xres);
	newHeight = PixelsFromFloat([m_idHeightValue floatValue],m_nUnits,yres);
	
	// Don't do if values are unreasonable or unchanged
	if (newWidth < kMinImageSize || newWidth > kMaxImageSize) { NSBeep(); return; }
	if (newHeight < kMinImageSize || newHeight > kMaxImageSize) { NSBeep(); return; }
	if (m_nWorkingIndex == kAllLayers) {
		if (newWidth == [(PSContent *)contents width] && newHeight == [(PSContent *)contents height]) { return; }
	}
	else {
		if (newWidth == [(PSContent *)[contents activeLayer] width] && newHeight == [(PSContent *)[contents activeLayer] height]) { return; }
	}
	
	// Make the changes
	[self scaleToWidth:newWidth height:newHeight interpolation:[m_idInterpolationPopup indexOfSelectedItem] index:m_nWorkingIndex]; 
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
//    [[m_idDocument window] removeChildWindow:m_idSheet];
	[m_idSheet orderOut:self];
}

- (void)scaleToWidth:(int)width height:(int)height xorg:(int)xorg yorg:(int)yorg moving:(BOOL)isMoving interpolation:(int)interpolation index:(int)index undoRecord:(ScaleUndoRecord *)undoRecord
{
	id contents = [m_idDocument contents], curLayer;
	int whichLayer, count, oldWidth, oldHeight;
	int layerCount = [contents layerCount];
	float xScale, yScale;
	int x, y;
	
	// Correct the index if necessary
	if (index == kActiveLayer)
		index = [[m_idDocument contents] activeLayerIndex];
	
	// Work out the old height and width
	if (index == kAllLayers) {
		oldWidth = [(PSContent *)contents width];
		oldHeight = [(PSContent *)contents height];
	}
	else {
		oldWidth = [(PSLayer *)[contents layer:index] width];
		oldHeight = [(PSLayer *)[contents layer:index] height];
	}
	
	// Prepare an undo record
	if (undoRecord) {
		undoRecord->unscaledWidth = oldWidth;
		undoRecord->unscaledHeight = oldHeight;
		undoRecord->scaledWidth = width;
		undoRecord->scaledHeight = height;
		undoRecord->scaledXOrg = xorg;
		undoRecord->scaledYOrg = yorg;
		undoRecord->isMoving = isMoving;
		undoRecord->index = index;
		undoRecord->interpolation = interpolation;
		undoRecord->isScaled = YES;
	}

	// Change the document's size if required
	if (index == kAllLayers)
		[[m_idDocument contents] setWidth:width height:height];
	
	// Create room for the snapshot indicies
	if (undoRecord) {
		if (index == kAllLayers) {
			undoRecord->indicies = malloc(layerCount * sizeof(int));
			undoRecord->rects = malloc(layerCount * sizeof(IntRect));
		}
		else {
			undoRecord->indicies = malloc(sizeof(int));
			undoRecord->rects = malloc(sizeof(IntRect));		
		}
	}
	
	// Determine the scaling rate
	xScale = ((float)width / (float)oldWidth);
	yScale = ((float)height / (float)oldHeight);
	[[m_idDocument selection] scaleSelectionHorizontally:xScale vertically:yScale interpolation:interpolation];
	count = 0;
	
	// Go through each layer
	for (whichLayer = 0; whichLayer < layerCount; whichLayer++) {
	
		// Check if the layer is needs to be scaled
		if (index == kAllLayers || index == whichLayer) {
			
			// Get the layer
			curLayer = [[m_idDocument contents] layer:whichLayer];
			
			// Take a manual snapshot (recording the snapshot index)
			if (undoRecord) {
				undoRecord->indicies[count] = [[curLayer seaLayerUndo] takeSnapshot:IntMakeRect(0, 0, [(PSLayer *)curLayer width], [(PSLayer *)curLayer height]) automatic:NO];
				undoRecord->rects[count].origin.x = [curLayer xoff];
				undoRecord->rects[count].origin.y = [curLayer yoff];
				undoRecord->rects[count].size.width = [(PSLayer *)curLayer width];
				undoRecord->rects[count].size.height = [(PSLayer *)curLayer height];
				count++;
			}
			
            if ([curLayer layerFormat] == PS_VECTOR_LAYER) {
                [curLayer setWidth:[(PSLayer *)curLayer width] * xScale height:[(PSLayer *)curLayer height] * yScale interpolation:interpolation];
            }else{
                // Change the layer's size
                [curLayer setWidth:[(PSLayer *)curLayer width] * xScale height:[(PSLayer *)curLayer height] * yScale interpolation:interpolation];
                if (index == kAllLayers){
                    [curLayer setOffsets:IntMakePoint([curLayer xoff] * xScale, [curLayer yoff] * yScale)];
                }else if(isMoving) {
                    [curLayer setOffsets:IntMakePoint(xorg, yorg)];
                }else {
                    x = [curLayer xoff] + ((float)oldWidth - (float)oldWidth * xScale) / 2.0;
                    y = [curLayer yoff] + ((float)oldHeight - (float)oldHeight * yScale) / 2.0;
                    [curLayer setOffsets:IntMakePoint(x, y)];
                }
            }
            
			
		}
	}
	
	// Adjust for floating selections
	if (index != kAllLayers) {
		curLayer = [[m_idDocument contents] layer:index];
		if ([curLayer floating]) {
			[[m_idDocument selection] selectOpaque];
		}
	}
}


- (void)scaleToWidth:(int)width height:(int)height interpolation:(int)interpolation index:(int)index
{
    id contents = [m_idDocument contents];
    int oldWidth, oldHeight;
    
    // Work out the old height and width
    if (index == kAllLayers) {
        oldWidth = [(PSContent *)contents width];
        oldHeight = [(PSContent *)contents height];
    }
    else {
        oldWidth = [(PSLayer *)[contents layer:index] width];
        oldHeight = [(PSLayer *)[contents layer:index] height];
    }
    
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] scaleToWidth:oldWidth height:oldHeight interpolation:interpolation index:index];
    
    
	ScaleUndoRecord undoRecord;
	
	// Do the scale
	[self scaleToWidth:width height:height xorg: 0 yorg: 0 moving: NO interpolation:interpolation index:index undoRecord:&undoRecord];

//	// Allow the undo
//	if (m_nUndoCount + 1 > m_nUndoMax) {
//		m_nUndoMax += kNumberOfScaleRecordsPerMalloc;
//		m_pSURUndoRecords = realloc(m_pSURUndoRecords, m_nUndoMax * sizeof(ScaleUndoRecord));
//	}
//	m_pSURUndoRecords[m_nUndoCount] = undoRecord;
//	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoScale:m_nUndoCount];
//	m_nUndoCount++;
	
	// Clear selection
	[[m_idDocument selection] clearSelection];
	
	// Do appropriate updating
	if (index == kAllLayers)
		[[m_idDocument helpers] boundariesAndContentChanged:YES];
	else
		[[m_idDocument helpers] layerBoundariesChanged:index];
}

- (void)scaleToWidth:(int)width height:(int)height xorg:(int)xorg yorg:(int)yorg interpolation:(int)interpolation index:(int)index
{
	ScaleUndoRecord undoRecord;
	
	// Do the scale
	[self scaleToWidth:width height:height xorg: xorg yorg: yorg moving: YES interpolation:interpolation index:index undoRecord:&undoRecord];
	
	// Allow the undo
	if (m_nUndoCount + 1 > m_nUndoMax) {
		m_nUndoMax += kNumberOfScaleRecordsPerMalloc;
		m_pSURUndoRecords = realloc(m_pSURUndoRecords, m_nUndoMax * sizeof(ScaleUndoRecord));
	}
	m_pSURUndoRecords[m_nUndoCount] = undoRecord;
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoScale:m_nUndoCount];
	m_nUndoCount++;
	
	// Clear selection
	[[m_idDocument selection] clearSelection];
	
	// Do appropriate updating
	if (index == kAllLayers){
		[[m_idDocument helpers] boundariesAndContentChanged:YES];
	}else{
		[[m_idDocument helpers] layerBoundariesChanged:index];
	}
}

- (void)undoScale:(int)undoIndex
{
	id contents = [m_idDocument contents], curLayer;
	int whichLayer;
	int layerCount = [contents layerCount];
	ScaleUndoRecord undoRecord;
	int changeX, changeY;
	
	// Get the undo record
	undoRecord = m_pSURUndoRecords[undoIndex];

	// We have different responses depending on whether the image is scaled or not
	if (undoRecord.isScaled) {
		
		if (undoRecord.index == kAllLayers) {
			
			// Change the document's size
			[[m_idDocument contents] setWidth:undoRecord.unscaledWidth height:undoRecord.unscaledHeight];
			
			// Go through each layer
			for (whichLayer = 0; whichLayer < layerCount; whichLayer++) {
			
				// Determine the current layer
				curLayer = [[m_idDocument contents] layer:whichLayer];
				
				// Change the layer's size
				changeX = undoRecord.rects[whichLayer].size.width - [(PSLayer *)curLayer width];
				changeY = undoRecord.rects[whichLayer].size.height - [(PSLayer *)curLayer height];
				[curLayer setMarginLeft:0 top:0 right:changeX bottom:changeY];
				[curLayer setOffsets:undoRecord.rects[whichLayer].origin];
				[[curLayer seaLayerUndo] restoreSnapshot:undoRecord.indicies[whichLayer] automatic:NO];

			}
			
			// Now the image is no longer scaled
			undoRecord.isScaled = NO;
			
		}
		else {
		
			// Determine the current layer
			curLayer = [[m_idDocument contents] layer:undoRecord.index];
			
			// Change the layer's size
			changeX = undoRecord.rects[0].size.width - [(PSLayer *)curLayer width];
			changeY = undoRecord.rects[0].size.height - [(PSLayer *)curLayer height];
			[curLayer setMarginLeft:0 top:0 right:changeX bottom:changeY];
			[curLayer setOffsets:undoRecord.rects[0].origin];
			[[curLayer seaLayerUndo] restoreSnapshot:undoRecord.indicies[0] automatic:NO];
			
			// Now the image is no longer scaled
			undoRecord.isScaled = NO;
		
		}
	
	}
	else {
		
		// Otherwise just reverse the process with the information we stored on the original scaling
		[self scaleToWidth:undoRecord.scaledWidth height:undoRecord.scaledHeight xorg: undoRecord.scaledXOrg yorg: undoRecord.scaledYOrg moving: undoRecord.isMoving interpolation:undoRecord.interpolation index:undoRecord.index undoRecord:NULL];
		undoRecord.isScaled = YES;
	
	}
	
	// Put the updated undo record back and allow the undo
	m_pSURUndoRecords[undoIndex] = undoRecord;
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoScale:undoIndex];
	
	// Clear selection
	[[m_idDocument selection] clearSelection];
	
	// Do appropriate updating
	if (undoRecord.index == kAllLayers)
		[[m_idDocument helpers] boundariesAndContentChanged:YES];
	else
		[[m_idDocument helpers] layerBoundariesChanged:undoRecord.index];
	
	// Adjust for floating selections
	if (undoRecord.index != kAllLayers) {
		curLayer = [[m_idDocument contents] layer:undoRecord.index];
		if ([curLayer floating]) {
			[[m_idDocument selection] selectOpaque];
		}
	}
}

- (IBAction)toggleKeepProportions:(id)sender
{
	float scaleValue = [m_idXScaleValue floatValue];
	id contents = [m_idDocument contents], layer;
	
	if ([m_idKeepProportions state]) {
		
		// Make the scale values the same
		[m_idXScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", scaleValue]];
		[m_idYScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", scaleValue]];
		
		// Determine the width and height values
		if (m_nWorkingIndex == kAllLayers) {
			[m_idWidthValue setIntValue:[(PSContent *)contents width] * (scaleValue / 100.0)];
			[m_idHeightValue setIntValue:[(PSContent *)contents height] * (scaleValue / 100.0)];
		}
		else {
			layer = [contents layer:m_nWorkingIndex];
			[m_idWidthValue setIntValue:[(PSLayer *)layer width] * (scaleValue / 100.0)];
			[m_idHeightValue setIntValue:[(PSContent *)layer height] * (scaleValue / 100.0)];
		}
	}
}

- (IBAction)valueChanged:(id)sender
{
	BOOL keepProp = [m_idKeepProportions state];
	id contents = [m_idDocument contents];
	id focusObject;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Work out the focus object
	if (m_nWorkingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layer:m_nWorkingIndex];
	
	// Handle a horizontal scale change
	if ([sender tag] == 0) {
//		[m_idXScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [m_idXScaleValue floatValue]]];
//        NSLog(@"xscale %f", [m_idXScaleValue floatValue]);
		if (keepProp) [m_idYScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [m_idXScaleValue floatValue]]];
		[m_idWidthValue setStringValue:StringFromPixels([(PSContent *)focusObject width] * ([m_idXScaleValue floatValue] / 100.0), m_nUnits, xres)];
		if (keepProp) [m_idHeightValue setStringValue:StringFromPixels([(PSContent *)focusObject height] * ([m_idYScaleValue floatValue] / 100.0), m_nUnits, yres)];
		return;
	}
	
	// Handle a vertical scale change
	if ([sender tag] == 1) {
//		[m_idYScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [m_idYScaleValue floatValue]]];
		if (keepProp) [m_idXScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [m_idYScaleValue floatValue]]];
		[m_idHeightValue setStringValue:StringFromPixels([(PSContent *)focusObject height] * ([m_idYScaleValue floatValue] / 100.0), m_nUnits, yres)];
		if (keepProp) [m_idWidthValue setStringValue:StringFromPixels([(PSContent *)focusObject width] * ([m_idXScaleValue floatValue] / 100.0), m_nUnits, xres)];
		return;
	}
	
	
	// Handle a width change
	if ([sender tag] == 2) {
		[m_idXScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", PixelsFromFloat([m_idWidthValue floatValue],m_nUnits, xres) / (float)[(PSContent *)focusObject width] * 100.0]];
		if (keepProp) {
			[m_idYScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [m_idXScaleValue floatValue]]];
			[m_idHeightValue setStringValue:StringFromPixels([(PSContent *)focusObject height] * ([m_idYScaleValue floatValue] / 100.0),m_nUnits, yres)];
		}
		return;
	}
	
	// Handle a height change
	if ([sender tag] == 3) {
		[m_idYScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", PixelsFromFloat([m_idHeightValue floatValue],m_nUnits, yres) / (float)[(PSContent *)focusObject height] * 100.0]];
		if (keepProp) {
			[m_idXScaleValue setStringValue:[NSString stringWithFormat:@"%.1f", [m_idYScaleValue floatValue]]];
			[m_idWidthValue setStringValue:StringFromPixels([(PSContent *)focusObject width] * ([m_idXScaleValue floatValue] / 100.0),m_nUnits, xres)];
		}
		return;
	}
}

- (IBAction)unitsChanged:(id)sender
{
	// BOOL keepProp = [m_idKeepProportions state];
	id contents = [m_idDocument contents];
	id focusObject;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	
	// Work out the focus object
	if (m_nWorkingIndex == kAllLayers)
		focusObject = contents;
	else
		focusObject = [contents layer:m_nWorkingIndex];
	
	// Handle a unit change
	m_nUnits = [sender indexOfSelectedItem];
	[m_idWidthValue setStringValue:StringFromPixels([(PSContent *)focusObject width] * ([m_idXScaleValue floatValue] / 100.0), m_nUnits, xres)];
	[m_idHeightValue setStringValue:StringFromPixels([(PSContent *)focusObject height] * ([m_idYScaleValue floatValue] / 100.0), m_nUnits, yres)];
//	[m_idHeightUnits setTitle:UnitsString(m_nUnits)];
    [m_idHeightPopdown selectItemAtIndex:m_nUnits];
    [m_idWidthPopdown selectItemAtIndex:m_nUnits];
}

- (IBAction)changeToPreset:(id)sender
{
	NSPasteboard *pboard;
	NSString *availableType;
	NSImage *image;
	NSSize paperSize;
	IntSize size = IntMakeSize(0, 0);
	float xres, yres;
	int pchoice;
	id focusObject;
	id contents = [m_idDocument contents];
	
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
			paperSize = [[gCurrentDocument printInfo] paperSize];
			paperSize.height -= [[gCurrentDocument printInfo] topMargin] + [[gCurrentDocument printInfo] bottomMargin];
			paperSize.width -= [[gCurrentDocument printInfo] leftMargin] + [[gCurrentDocument printInfo] rightMargin];
			size = NSSizeMakeIntSize(paperSize);
			size.width = (float)size.width * (xres / 72.0);
			size.height = (float)size.height * (yres / 72.0);
		break;
	}
	
	// Deal with keep proportions checkbox
	if ([m_idKeepProportions state]) {
		if ((float)size.width / (float)[(PSContent *)focusObject width] < (float)size.height / (float)[(PSContent *)focusObject height])
			pchoice = 1;
		else
			pchoice = 2;
	}
	else {
		pchoice = 0;
	}
	
	// Make the change
	switch (m_nUnits) {
		case kPixelUnits:
			switch (pchoice) {
				case 0:
					[m_idWidthValue setIntValue:size.width];
					[self valueChanged:m_idWidthValue];
					[m_idHeightValue setIntValue:size.height];
					[self valueChanged:m_idHeightValue];
				break;
				case 1:
					[m_idWidthValue setIntValue:size.width];
					[self valueChanged:m_idWidthValue];
				break;
				case 2:
					[m_idHeightValue setIntValue:size.height];
					[self valueChanged:m_idHeightValue];
				break;
			}
		break;
		case kInchUnits:
			switch (pchoice) {
				case 0:
					[m_idWidthValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.width / xres]];
					[self valueChanged:m_idWidthValue];
					[m_idHeightValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.height / yres]];
					[self valueChanged:m_idHeightValue];
				break;
				case 1:
					[m_idWidthValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.width / xres]];
					[self valueChanged:m_idWidthValue];
				break;
				case 2:
					[m_idHeightValue setStringValue:[NSString stringWithFormat:@"%.2f", (float)size.height / yres]];
					[self valueChanged:m_idHeightValue];
				break;
			}
		break;
		case kMillimeterUnits:
			switch (pchoice) {
				case 0:
					[m_idWidthValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.width / xres * 25.4]];
					[self valueChanged:m_idWidthValue];
					[m_idHeightValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.height / yres * 25.4]];
					[self valueChanged:m_idHeightValue];
				break;
				case 1:
					[m_idWidthValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.width / xres * 25.4]];
					[self valueChanged:m_idWidthValue];
				break;
				case 2:
				[m_idHeightValue setStringValue:[NSString stringWithFormat:@"%.0f", (float)size.height / yres * 25.4]];
					[self valueChanged:m_idHeightValue];
				break;
			}
		break;
	}
}



- (void)controlTextDidChange:(NSNotification *)obj
{
//    NSLog(@"controlTextDidChange");
    [self valueChanged:obj.object];
}

@end
