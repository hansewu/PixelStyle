#import "PSHelpers.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PegasusUtility.h"
#import "PSWhiteboard.h"
#import "PSPrefs.h"
#import "PSView.h"
#import "PSSelection.h"
#import "PSTools.h"
#import "StatusUtility.h"
#import "LayerDataSource.h"
#import "AbstractTool.h"

@implementation PSHelpers


- (void)selectionChanged
{
    [[m_idDocument docView] setRefreshWhiteboardImage:false];
    [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
	[[m_idDocument docView] setNeedsDisplay:YES];
    [[m_idDocument shadowView] setNeedsDisplay:YES];
	[[[PSController utilitiesManager] infoUtilityFor:m_idDocument] update];
}

- (void)endLineDrawing
{
	id curTool = [[m_idDocument tools] currentTool];

	// We only need to act if the document is locked
	if ([m_idDocument locked] && [[m_idDocument window] attachedSheet] == NULL) {
		
		// Apply the changes
		[(PSWhiteboard *)[m_idDocument whiteboard] applyOverlay];
		
		// Notify ourselves of the change
		[self layerContentsChanged:kActiveLayer];
		
		// End line drawing once
		if ([curTool respondsToSelector:@selector(endLineDrawing)])
			[curTool endLineDrawing];		
		
		// End line drawing twice
		[[m_idDocument docView] endLineDrawing];
		
		// Unlock the document
		[m_idDocument unlock];
		
	}
	
	// Special case for the effect tool
	if ([[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool] == kEffectTool) {
		[curTool reset];
	}
}

- (void)channelChanged
{
	if ([[m_idDocument contents] spp] != 2)
		[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:NO];
	[[m_idDocument whiteboard] readjustAltData:YES];
	[(StatusUtility *)[[PSController utilitiesManager] statusUtilityFor:m_idDocument] update];
}

- (void)resolutionChanged
{
	[[m_idDocument docView] readjust:YES];
	[[[PSController utilitiesManager] statusUtilityFor:m_idDocument] update];
}

- (void)zoomChanged
{
    [[m_idDocument docView] setNeedsUpdateSelectBoundPoints];
	[[[PSController utilitiesManager] optionsUtilityFor:m_idDocument] update];
	[[[PSController utilitiesManager] statusUtilityFor:m_idDocument] updateZoom];
    
    
    
    //不需要去重刷了
//    SEL sel = @selector(resetSynthesizedImageRenderInThread);
//    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:
//     sel object: nil];
//    [self performSelector: sel withObject: nil afterDelay: 0.3];
    
    
}



-(void)resetSynthesizedImageRenderInThread
{
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)boundariesAndContentChanged:(BOOL)scaling
{
	id contents = [m_idDocument contents];
	int i;
	
	[[m_idDocument whiteboard] readjust];
	[[m_idDocument docView] readjust:scaling];
	for (i = 0; i < [contents layerCount]; i++) {
		[[contents layer:i] updateThumbnail];
	}
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
	[(StatusUtility *)[[PSController utilitiesManager] statusUtilityFor:m_idDocument] update];
	[[m_idDocument docView] setRefreshWhiteboardImage:true];
    [[m_idDocument docView] setNeedsDisplay:YES];

}

- (void)activeLayerWillChange
{
	[self endLineDrawing];
}

- (void)activeLayerChanged:(int)eventType rect:(IntRect *)rect
{
	id whiteboard = [m_idDocument whiteboard];
	id docView = [m_idDocument docView];
    
	id layer = [[m_idDocument contents] activeLayer];
    [layer notifyLayerActive:YES];
    
	[[m_idDocument selection] readjustSelection];
	if (![[[m_idDocument contents] activeLayer] hasAlpha] && ![[m_idDocument selection] floating] && [[m_idDocument contents] selectedChannel] == kAlphaChannel) {
		[[m_idDocument contents] setSelectedChannel:kAllChannels];
		[[m_idDocument helpers] channelChanged];
	}
	switch (eventType) {
		case kLayerSwitched:
		case kTransparentLayerAdded:
            [whiteboard readjustLayer:NO];
			if ([whiteboard whiteboardIsLayerSpecific]) {
				[whiteboard readjustAltData:YES];
			}
			else if ([[PSController m_idPSPrefs] layerBounds]) {
				[docView setNeedsDisplay:YES];
			}
		break;
		case kLayerAdded:
		case kLayerDeleted:
            [whiteboard readjustLayer:NO];
			[whiteboard readjustAltData:YES];
		break;
	}
	[(LayerDataSource *)[m_idDocument dataSource] update];
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateAll];
    [[[PSController utilitiesManager] histogramUtilityFor:m_idDocument] update];
    
    [[[m_idDocument tools] currentTool] layerAttributesChanged:kActiveLayer];
}

- (void)documentWillFlatten
{
	[self activeLayerWillChange];
}

- (void)documentFlattened
{
	[self activeLayerChanged:kLayerAdded rect:NULL];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)typeChanged
{
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] update:NO];
	[[m_idDocument whiteboard] readjust];
	[self layerContentsChanged:kAllLayers];
	[[[PSController utilitiesManager] statusUtilityFor:m_idDocument] update];
	
}

- (void)updateLayerThumbnailInHelper
{
    id layer = [[m_idDocument contents] activeLayer];
    [self updateLayerThumbnailInHelperForLayer:layer];
}

- (void)updateLayerThumbnailInHelperForLayer:(id)layer
{
    [layer updateThumbnail];
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
    
    [[[PSController utilitiesManager] histogramUtilityFor:m_idDocument] update];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATECHANNELVIEW" object:m_idDocument];
}

- (void)applyOverlay
{
	id contents = [m_idDocument contents], layer;
	IntRect rect;
	
	rect = [(PSWhiteboard *)[m_idDocument whiteboard] applyOverlay];
	layer = [contents activeLayer];
	[layer updateThumbnail];
    
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
    return;
    
//	[(PSWhiteboard *)[m_idDocument whiteboard] update:rect inThread:NO];
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
}

- (void)overlayChanged:(IntRect)rect inThread:(BOOL)thread
{
	id contents = [m_idDocument contents];
    id layer = [contents activeLayer];
    if ([[m_idDocument whiteboard] getOverlayOpacity] == 0) {        
        return;
    }
    [layer updatePreviewEffectForInRect:IntRectMakeNSRect(rect) inThread:thread mode:1];
}



- (void)layerAttributesChanged:(int)index hold:(BOOL)hold
{
	id contents = [m_idDocument contents], layer;
	IntRect rect;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index)
    {
		case kAllLayers:
		case kLinkedLayers:
//			[[m_idDocument whiteboard] update];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:YES];
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
//			[(PSWhiteboard *)[m_idDocument whiteboard] update:rect inThread:NO];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:NO];
		break;
	}
    
    [[[m_idDocument tools] currentTool] layerAttributesChanged:index];
	
	if (!hold)
		[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateAll];
}

- (void)layerBoundariesChanged:(int)index
{
	id contents = [m_idDocument contents], layer;
	IntRect rect;
	int i;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				[[contents layer:i] updateThumbnail];
			}
		break;
		case kLinkedLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				if ([[contents layer:i] linked])
                {
					[[contents layer:i] updateThumbnail];
                }
			}
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
			[layer updateThumbnail];
		break;
	}
	
	[[m_idDocument selection] readjustSelection];
    [[m_idDocument whiteboard] readjustLayer:NO];
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateAll];
    [[m_idDocument docView] setRefreshWhiteboardImage:true];
	[[m_idDocument docView] setNeedsDisplay:YES]; 

}

- (void)layerContentsChanged:(int)index
{
	id contents = [m_idDocument contents], layer;
	IntRect rect;
	int i;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				[[contents layer:i] updateThumbnail];
			}
//			[[m_idDocument whiteboard] update];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:YES];
		break;
		case kLinkedLayers:
			for (i = 0; i < [contents layerCount]; i++) {
				if ([[contents layer:i] linked])
					[[contents layer:i] updateThumbnail];
			}
//			[[m_idDocument whiteboard] update];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:YES];
            
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
			[layer updateThumbnail];
//			[(PSWhiteboard *)[m_idDocument whiteboard] update:rect inThread:NO];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:NO];
		break;
	}
    
   
	
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
}

- (void)layerOffsetsChanged:(int)index from:(IntPoint)oldOffsets
{
	id contents = [m_idDocument contents], layer;
	IntRect rectA, rectB, rectC;
	int xoff, yoff;

	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
//			[[m_idDocument whiteboard] update];
            
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rectA isAllContent:YES];
			layer = [contents activeLayer];
			xoff = [layer xoff];
			yoff = [layer yoff];
		break;
		default:
			layer = [contents layer:index];
			xoff = [layer xoff];
			yoff = [layer yoff];
			rectA.origin.x = MIN(xoff, oldOffsets.x);
			rectA.origin.y = MIN(yoff, oldOffsets.y);
			rectA.size.width = MAX(xoff, oldOffsets.x) - MIN(xoff, oldOffsets.x) + [(PSLayer *)layer width];
			rectA.size.height = MAX(yoff, oldOffsets.y) - MIN(yoff, oldOffsets.y) + [(PSLayer *)layer height];
			rectB = IntMakeRect(oldOffsets.x, oldOffsets.y, [(PSLayer *)layer width], [(PSLayer *)layer height]);
			rectC = IntMakeRect(xoff, yoff, [(PSLayer *)layer width], [(PSLayer *)layer height]);
			if (rectA.size.width * rectA.size.height < rectB.size.width * rectB.size.height + rectC.size.width * rectC.size.height) {
//				[(PSWhiteboard *)[m_idDocument whiteboard] update:rectA inThread:NO];
                [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rectA isAllContent:NO];
			}
			else {
//				[(PSWhiteboard *)[m_idDocument whiteboard] update:rectB inThread:NO];
                [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rectB isAllContent:NO];
//				[(PSWhiteboard *)[m_idDocument whiteboard] update:rectC inThread:NO];
                [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rectC isAllContent:NO];
			}
		break;
	}
	
    
//	if ([[m_idDocument selection] active]) {
//		[[m_idDocument selection] adjustOffset:IntMakePoint(xoff - oldOffsets.x, yoff - oldOffsets.y)];
//	}
    
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)layerLevelChanged:(int)index
{
	id contents = [m_idDocument contents], layer;
	IntRect rect;
	
	if (index == kActiveLayer)
		index = [contents activeLayerIndex];
	
	switch (index) {
		case kAllLayers:
		case kLinkedLayers:
//			[[m_idDocument whiteboard] update];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:YES];
            
		break;
		default:
			layer = [contents layer:index];
			rect = IntMakeRect([layer xoff], [layer yoff], [(PSLayer *)layer width], [(PSLayer *)layer height]);
//			[(PSWhiteboard *)[m_idDocument whiteboard] update:rect inThread:NO];
            [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:NO];
		break;
	}
	[(LayerDataSource *)[m_idDocument dataSource] update];
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateAll];
}

- (void)layerSnapshotRestored:(int)index rect:(IntRect)rect
{
	id layer;
	
	layer = [[m_idDocument contents] layer:index];
    
    // add by lcz
    [layer updateFullDataWithFilterAfterDataChangeInRect:IntRectMakeNSRect(rect)];
    [layer updateThumbnail];
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
    return;

    
//	[(PSWhiteboard *)[m_idDocument whiteboard] update:rect inThread:NO];
    [(PSWhiteboard *)[m_idDocument whiteboard] Refresh:rect isAllContent:NO];
	[layer updateThumbnail];
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
}

- (void)layerTitleChanged
{
	[(LayerDataSource *)[m_idDocument dataSource] update];
	[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:kPegasusUpdateLayerView];
}

@end
