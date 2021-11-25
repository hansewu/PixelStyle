#import "AbstractTool.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "AbstractOptions.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSHelpers.h"
#import "PSLayer.h"
#import "ToolboxUtility.h"
#import "PSTools.h"
#import "PSSelection.h"
#import "PSHelpInfoUtility.h"
#import "PSTipsUtility.h"

@implementation AbstractTool

- (int)toolId
{
	return -1;
}

- (id)init
{
	self = [super init];
	if(self){
		m_bIntermediate = NO;
        
        m_brushAlpha = 0;
        m_layerRawData = nil;
        memset(m_blockInfo, 0, BLOCKCOUNT_BRUSHTOOL * BLOCKCOUNT_BRUSHTOOL);
        
        m_curNoop = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"noop-cursor"] hotSpot:NSMakePoint(7, 7)];
        [m_curNoop setOnMouseEntered:YES];
        m_strToolTips = nil;
        m_arrViewsAbovePSView = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc
{
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    if (m_curNoop) {[m_curNoop release]; m_curNoop = nil;}
    if (m_strToolTips) {
        [m_strToolTips release];
        m_strToolTips = nil;
    }
    
    if (m_arrViewsAbovePSView) {
        [m_arrViewsAbovePSView release];
        m_arrViewsAbovePSView = nil;
    }
    
    [super dealloc];
}

- (void)setOptions:(id)newOptions
{
	m_idOptions = newOptions;
}

- (BOOL)acceptsLineDraws
{
	return NO;
}

- (BOOL)useMouseCoalescing
{
	return YES;
}

- (BOOL)foregroundIsTexture
{
	return [m_idOptions useTextures];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
//    [self checkCurrentLayerIsSupported];
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
}

- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event;
{
//    [self checkCurrentLayerIsSupported];
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event;
{
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;
{
}

- (BOOL)isFineTool
{
	return NO;
}

- (BOOL) intermediate
{
	return m_bIntermediate;
}

- (void)layerAttributesChanged:(int)nLayerType //	nLayerType : kActiveLayer = -1, kAllLayers = -2, kLinkedLayers = -3
{
}

- (void)combineWillBeProcessDataRect:(IntRect)srcRect
{
    //NSLog(@"%@ %@",NSStringFromRect(srcRect),NSStringFromRect(m_willBeProcessDataRect));
    if (srcRect.size.width <= 0 || srcRect.size.height <= 0) {
        //NSLog(@"combineWillBeProcessDataRect1");
        return;
    }
    if (m_dataChangedRect.size.width <= 0 || m_dataChangedRect.size.height <= 0) {
        if (srcRect.size.width > 0 && srcRect.size.height > 0) {
            m_dataChangedRect = srcRect;
        }
        return;
    }
    int minx = m_dataChangedRect.origin.x;
    int maxx = m_dataChangedRect.origin.x + m_dataChangedRect.size.width;
    int miny = m_dataChangedRect.origin.y;
    int maxy = m_dataChangedRect.origin.y + m_dataChangedRect.size.height;
    IntRect temp = srcRect;
    if (temp.origin.x < minx) {
        minx = temp.origin.x;
    }
    if (temp.origin.x + temp.size.width > maxx) {
        maxx = temp.origin.x + temp.size.width;
    }
    if (temp.origin.y < miny) {
        miny = temp.origin.y;
    }
    if (temp.origin.y + temp.size.height > maxy) {
        maxy = temp.origin.y + temp.size.height;
    }
//    m_dataChangedRect.origin.x = minx;
//    m_dataChangedRect.origin.y = miny;
//    m_dataChangedRect.size.width = maxx - minx;
//    m_dataChangedRect.size.height = maxy - miny;
    m_dataChangedRect = IntMakeRect(minx, miny, maxx - minx, maxy - miny);
}


- (void)copyRawDataToTempInRect:(IntRect)rect
{
    if (!m_layerRawData) {
        return;
    }
    
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    id layer = [[m_idDocument contents] activeLayer];
    int width = [(PSLayer *)layer width];
    int height = [(PSLayer *)layer height];
    int spp = [[m_idDocument contents] spp];
    
    if (rect.origin.x < 0 || rect.origin.y < 0 || rect.size.width > width || rect.size.height > height)
    {
        return;
    }
    if (rect.size.width <= 0 || rect.size.height <= 0)
    {
        return;
    }

    
    unsigned char *layerData = [layer getRawData];
    
    int blockBeginX = rect.origin.x / BLOCKSIZE_BRUSHTOOL;
    int blockEndX = (rect.origin.x + rect.size.width) / BLOCKSIZE_BRUSHTOOL;
    int blockBeginY = rect.origin.y / BLOCKSIZE_BRUSHTOOL;
    int blockEndY = (rect.origin.y + rect.size.height) / BLOCKSIZE_BRUSHTOOL;
    for (int i = blockBeginX; i <= blockEndX; i++)
    {
        for (int j = blockBeginY; j <= blockEndY; j++)
        {
            if (m_blockInfo[j * BLOCKCOUNT_BRUSHTOOL + i] == 0)
            {
                for (int k = j * BLOCKSIZE_BRUSHTOOL ; k < (j + 1) * BLOCKSIZE_BRUSHTOOL; k++)
                {
                    if (k < height)
                    {
                        int offset = (k * width + i * BLOCKSIZE_BRUSHTOOL) * spp;
                        int copySize = MIN(BLOCKSIZE_BRUSHTOOL, width - (i * BLOCKSIZE_BRUSHTOOL));
                        if (copySize > 0)
                        {
                            memcpy(m_layerRawData + offset, layerData + offset, copySize * spp);
                        }
                    }
                }
                m_blockInfo[j * BLOCKCOUNT_BRUSHTOOL + i] = 1;
            }
        }
    }
    
    [layer unLockRawData];
    //NSLog(@"copyRawData %f,%@",[NSDate timeIntervalSinceReferenceDate] - begin,NSStringFromRect(IntRectMakeNSRect(rect)));
    
}

- (void)drawToolExtra
{
    
}

- (NSMutableArray *)getToolPreviewEnabledLayer
{
    return NULL;
}

- (void)drawLayerToolPreview:(RENDER_CONTEXT_INFO)contextInfo layerid:(id)layer
{
    
}


- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    return YES;
}



-(void)checkCurrentLayerIsSupported
{
    PSAbstractLayer *pLayer = [[m_idDocument contents] activeLayer];
    PA_LAYER_FORMAT nCurrentLayerFormat = pLayer.layerFormat;
    
    BOOL bSupport = [self isSupportLayerFormat:nCurrentLayerFormat];
    int nActiveLayerIndex = [[m_idDocument contents] activeLayerIndex];
    
    if (!bSupport)
    {
        int nLayerCount = [[m_idDocument contents] layerCount];
        for (int nIndex = 0; nIndex < nLayerCount; nIndex++)
        {
            pLayer = [[m_idDocument contents] layer:nIndex];
            nCurrentLayerFormat = pLayer.layerFormat;
            bSupport = [self isSupportLayerFormat:nCurrentLayerFormat] && [pLayer visible];
            if(bSupport)
            {
                [[m_idDocument contents] setActiveLayerIndexComplete:nIndex];                
                return;
            }
        }
    }
    
    // 没有找到合适的图层，需要创建
    if (!bSupport)
    {
        int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
        if(curToolIndex == kShapeTool || (curToolIndex == kVectorPenTool))
            [(PSContent*)[m_idDocument contents] addVectorLayer:kActiveLayer];
        else
            [(PSContent*)[m_idDocument contents] addLayer:kActiveLayer];
        
    }
}

#pragma mark - Tool Enter/Exit
-(BOOL)enterTool
{
    [[m_idDocument helpers] endLineDrawing];
    
    [self layerAttributesChanged:kActiveLayer];
    [[[PSController utilitiesManager] helpInfoUtilityFor:m_idDocument] updateHelpInfo:m_strToolTips];
    
    
    if(m_strToolTips)
    {
        [[m_idDocument tips] setWarning:m_strToolTips ofImportance:4];
        
        [m_arrViewsAbovePSView addObject:[[m_idDocument tips] contentView]];
    
    }
    return YES;
}

-(BOOL)exitTool:(int)newTool
{
    [[m_idDocument tips] hideBanner];
    
    for(NSView *view in m_arrViewsAbovePSView)
        if([[m_idDocument tips] contentView] == view)
        {
            [m_arrViewsAbovePSView removeObject:view];
            break;
        }
    
    return YES;
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    return YES;
}

#pragma mark - UI View
- (NSMutableArray *)arrViewsAbovePSView
{
    return m_arrViewsAbovePSView;
}

- (BOOL)canResponseForView:(id)view
{
    return YES;
}

- (void)resetCursorRects
{
    [[m_idDocument docView] discardCursorRects];
    
    
    NSRect colorPanelRect = [[NSColorPanel sharedColorPanel] frame];
    if( (NSPointInRect([NSEvent mouseLocation], colorPanelRect) && [gColorPanel isVisible]))
    {
        NSWindow *window = (NSWindow *)[[m_idDocument docView] window];
        NSRect colorPanelRect = [[NSColorPanel sharedColorPanel] frame];
        colorPanelRect.origin.x = colorPanelRect.origin.x - window.frame.origin.x;
        colorPanelRect.origin.y = colorPanelRect.origin.y - window.frame.origin.y;
        colorPanelRect = [window.contentView convertRect:colorPanelRect toView:[[m_idDocument docView] superview]];
        [self addCursorRect:colorPanelRect cursor:[NSCursor arrowCursor]];
        return;
    }

    NSArray *arrChildWindows = [[m_idDocument window] childWindows];
    for(NSWindow *window in arrChildWindows)
    {
        NSRect windowRect = [window frame];
        if((NSPointInRect([NSEvent mouseLocation], windowRect) && [window isVisible]))
        {
            NSWindow *window = (NSWindow *)[[m_idDocument docView] window];
            windowRect.origin.x = windowRect.origin.x - window.frame.origin.x;
            windowRect.origin.y = windowRect.origin.y - window.frame.origin.y;
            windowRect = [window.contentView convertRect:windowRect toView:[[m_idDocument docView] superview]];
            [self addCursorRect:windowRect cursor:[NSCursor arrowCursor]];
            return;
        }
    }
    
    for (NSView *view in m_arrViewsAbovePSView)
    {
        NSPoint tempPoint = [(NSWindow *)[[m_idDocument docView] window] convertScreenToBase:[NSEvent mouseLocation]];
        tempPoint = [view convertPoint:tempPoint fromView:[(NSWindow *)[[m_idDocument docView] window] contentView]];
        if((NSPointInRect(tempPoint, view.bounds) && ![view isHidden]))
        {
            NSRect viewRect = [view convertRect:view.bounds toView:[[m_idDocument docView] superview]];
            [self addCursorRect:viewRect cursor:[NSCursor arrowCursor]];
            return;
        }
    }
    
    NSRect operableRect = [[m_idDocument docView] frame];
    
    if([self isAffectedBySelection])
    {
        PSLayer *activeLayer = [[m_idDocument contents] activeLayer];
        float xScale = [[m_idDocument contents] xscale];
        float yScale = [[m_idDocument contents] yscale];
        IntRect operableIntRect = IntMakeRect([activeLayer xoff] * xScale, [activeLayer yoff] * yScale, [activeLayer width] * xScale, [activeLayer height] *yScale);
        operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect(operableRect), operableIntRect));
        if([[m_idDocument selection] active])
        {
            operableIntRect = [[m_idDocument selection] globalRect];
            operableIntRect = IntMakeRect(operableIntRect.origin.x * xScale, operableIntRect.origin.y * yScale, operableIntRect.size.width * xScale, operableIntRect.size.height * yScale);
            operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([[m_idDocument docView] frame]), operableIntRect));
            
        }
    }
    
    if (m_cursor)
        [self addCursorRect:operableRect cursor:m_cursor];
    
    
    if([self isAffectedBySelection]){
        // Now we need the noop section
        if(operableRect.origin.x > 0){
            NSRect leftRect = NSMakeRect(0,0,operableRect.origin.x,[[m_idDocument docView] frame].size.height);
            [self addCursorRect:leftRect cursor:m_curNoop];
        }
        float rightX = operableRect.origin.x + operableRect.size.width;
        if(rightX < [[m_idDocument docView] frame].size.width){
            NSRect rightRect = NSMakeRect(rightX, 0, [[m_idDocument docView] frame].size.width - rightX, [[m_idDocument docView] frame].size.height);
            [self addCursorRect:rightRect cursor:m_curNoop];
        }
        if(operableRect.origin.y > 0){
            NSRect bottomRect = NSMakeRect(0, 0, [[m_idDocument docView] frame].size.width, operableRect.origin.y);
            [self addCursorRect:bottomRect cursor:m_curNoop];
        }
        float topY = operableRect.origin.y + operableRect.size.height;
        if(topY < [[m_idDocument docView] frame].size.height){
            NSRect topRect = NSMakeRect(0, topY, [[m_idDocument docView] frame].size.width, [[m_idDocument docView] frame].size.height - topY);
            [self addCursorRect:topRect cursor:m_curNoop];
        }
    }
}

- (void)addCursorRect:(NSRect)rect cursor:(NSCursor *)cursor
{
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    
    // Convert to the scrollview's origin
    rect.origin = [scrollView convertPoint: rect.origin fromView: [m_idDocument docView]];
    
    // Clip to the centering clipview
    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], rect);
    
    // Convert the point back to the seaview
    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    [[m_idDocument docView] addCursorRect:clippedRect cursor:cursor];
    
    //NSLog(@"clippedRect = %@", NSStringFromRect(clippedRect));
}

- (BOOL)setCursor:(NSPoint)point rect:(NSRect)rect cursor:(NSCursor *)cursor //point：相对于[m_idDocument docView]， rect 相对于[[m_idDocument docView] superview]
{
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    
    // Convert to the scrollview's origin
    rect.origin = [scrollView convertPoint: rect.origin fromView: [m_idDocument docView]];
    
    // Clip to the centering clipview
    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], rect);
    
    // Convert the point back to the seaview
    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    if(NSPointInRect(point, clippedRect))
    {
        [cursor set];
        return YES;
    }
    
    return NO;
}

- (BOOL)updateCursor:(NSEvent *)event
{
    NSPoint point = [NSEvent mouseLocation];
    point.x = point.x - [[m_idDocument window] frame].origin.x;
    point.y = point.y - [[m_idDocument window] frame].origin.y;
    
    NSPoint where = [[m_idDocument docView] convertPoint:point fromView:[[m_idDocument window] contentView]];
    
    [self mouseMoveTo:where withEvent:event];
    
    return YES;
}

#pragma mark - MouseEvent
- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    [self resetCursorRects];
    
    
    if([event window] != [m_idDocument window])
    {
        [[NSCursor arrowCursor] set];
        return;
    }
    
    NSRect colorPanelRect = [[NSColorPanel sharedColorPanel] frame];
    if( (NSPointInRect([NSEvent mouseLocation], colorPanelRect) && [gColorPanel isVisible]))
    {
        [[NSCursor arrowCursor] set];
        return;
    }
    
    NSArray *arrChildWindows = [[m_idDocument window] childWindows];
    for(NSWindow *window in arrChildWindows)
    {
        if((NSPointInRect([NSEvent mouseLocation], [window frame]) && [window isVisible]))
        {
            [[NSCursor arrowCursor] set];
            return;
        }
    }
    
    for (NSView *view in m_arrViewsAbovePSView)
    {
        NSPoint tempPoint = [(NSWindow *)[[m_idDocument docView] window] convertScreenToBase:[NSEvent mouseLocation]];
        tempPoint = [view convertPoint:tempPoint fromView:[(NSWindow *)[[m_idDocument docView] window] contentView]];
        if((NSPointInRect(tempPoint, view.bounds) && ![view isHidden]))
        {
            [[NSCursor arrowCursor] set];
            return;
        }
    }

    
    
    NSRect operableRect = [[m_idDocument docView] frame];
    
    if([self isAffectedBySelection])
    {
        PSLayer *activeLayer = [[m_idDocument contents] activeLayer];
        float xScale = [[m_idDocument contents] xscale];
        float yScale = [[m_idDocument contents] yscale];
        IntRect operableIntRect = IntMakeRect([activeLayer xoff] * xScale, [activeLayer yoff] * yScale, [activeLayer width] * xScale, [activeLayer height] *yScale);
        operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect(operableRect), operableIntRect));
        if([[m_idDocument selection] active])
        {
            operableIntRect = [[m_idDocument selection] globalRect];
            operableIntRect = IntMakeRect(operableIntRect.origin.x * xScale, operableIntRect.origin.y * yScale, operableIntRect.size.width * xScale, operableIntRect.size.height * yScale);
            operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([[m_idDocument docView] frame]), operableIntRect));
            
        }
    }
    
    if([self setCursor:where rect:operableRect cursor:m_cursor])
        return;
    
    if([self isAffectedBySelection])
    {
        // Now we need the noop section
        if(operableRect.origin.x > 0)
        {
            NSRect leftRect = NSMakeRect(0,0,operableRect.origin.x,[[m_idDocument docView] frame].size.height);
            if([self setCursor:where rect:leftRect cursor:m_curNoop])
            return;
        }
        float rightX = operableRect.origin.x + operableRect.size.width;
        if(rightX < [[m_idDocument docView] frame].size.width)
        {
            NSRect rightRect = NSMakeRect(rightX, 0, [[m_idDocument docView] frame].size.width - rightX, [[m_idDocument docView] frame].size.height);
            if([self setCursor:where rect:rightRect cursor:m_curNoop])
            return;
        }
        if(operableRect.origin.y > 0)
        {
            NSRect bottomRect = NSMakeRect(0, 0, [[m_idDocument docView] frame].size.width, operableRect.origin.y);
            if([self setCursor:where rect:bottomRect cursor:m_curNoop])
            return;
        }
        float topY = operableRect.origin.y + operableRect.size.height;
        if(topY < [[m_idDocument docView] frame].size.height)
        {
            NSRect topRect = NSMakeRect(0, topY, [[m_idDocument docView] frame].size.width, [[m_idDocument docView] frame].size.height - topY);
            if([self setCursor:where rect:topRect cursor:m_curNoop])
            return;
        }
    }
    
    
    
    [[NSCursor arrowCursor] set];
    
    return;

}

-(BOOL)showSelectionBoundaries
{
    return YES;
}

-(BOOL)isAffectedBySelection
{
    return YES;
}


- (BOOL)stopCurrentOperation
{
    return NO;
}

- (BOOL)deleteKeyPressed
{
    return NO;
}

- (BOOL)enterKeyPressed
{
    return NO;
}

- (BOOL)moveKeyPressedOffset:(NSPoint)offset needUndo:(BOOL)undo
{
    return NO;
}


@end
