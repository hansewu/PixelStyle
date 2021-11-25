//
//  PSAbstractVectorSelectTool.m
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//
#include <stdio.h>
#import "PSAbstractVectorSelectTool.h"
#import "PSAbstractVectorSelectOptions.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSHelpers.h"
#import "PSTools.h"
#import "PSVecLayer.h"
#import "PSView.h"

#import "PSShowInfoPanel.h"

#import "WDBezierNode.h"
#import "WDPath.h"
#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDCompoundPath.h"
#import "WDLayer.h"
#import "WDPickResult.h"
#import "WDTextPath.h"
#import "WDText.h"
#import "WDGroup.h"



#define KMinDifferent 1
@implementation PSAbstractVectorSelectTool



- (int)toolId
{
    return kVectorMoveTool;
}

- (BOOL)isFineTool
{
    return NO;
}


- (id)init
{
    if(![super init])
        return NULL;
    
    lastMouseMoveOnObject_ = nil;
    m_nMouseMoveOnObjecLayerIndex = -1;
    
    m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt & Drag the selected object to copy. Press Command & Shift to select all shapes. Press Command to select multiple shapes. Press Shift & Drag to select multiple shapes.", nil)];
    
    return self;
}

- (void)dealloc
{
    if(lastMouseMoveOnObject_) {[lastMouseMoveOnObject_ release]; lastMouseMoveOnObject_ = nil;}
    
    [super dealloc];
}

#pragma mark - Mouse Events
- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event
{
    m_bMouseDown = YES;
    lastTappedObject_ = nil;
    if(lastMouseMoveOnObject_) {[lastMouseMoveOnObject_ release]; lastMouseMoveOnObject_ = nil;}
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    m_cgPointInit.x = where.x;
    m_cgPointInit.y = where.y;
    m_cgPointCurrent = m_cgPointInit;
    int nLayerIndex = -1;
    WDPickResult *result = [self objectUnderPoint:m_cgPointInit viewScale:1 whichLayerIndex:&nLayerIndex];
    
    //按住alt键移动，复制
    if([(PSAbstractVectorSelectOptions *)m_idOptions optionKeyEnable] && (result.type == kWDEdge || result.type == kWDObjectFill))
            [self copySelectedObjects:wdDrawingController.selectedObjects];
    
    
    if (result.type == kWDEther)
    {
        [wdDrawingController selectNone:nil];
        wdDrawingController.propertyManager.ignoreSelectionChanges = YES;
        if ([(PSAbstractVectorSelectOptions *)m_idOptions shiftKeyEnable])
        {
            // didn't hit anything: marquee mode!
            marqueeMode_ = YES;
            
            [[m_idDocument docView] setNeedsDisplay:YES];
        }
        return;
    }
    
    BOOL groupSelect = [(PSAbstractVectorSelectOptions *)m_idOptions groupSelect];
    WDElement *element = result.element;
    
    if (![wdDrawingController isSelected:element])
    {
        WDPath *path = nil;
        
        if ([element isKindOfClass:[WDPath class]]) {
            path = (WDPath *) element;
        }
        
        if (!path || !path.superpath || (path.superpath && ![wdDrawingController isSelected:path.superpath])) {
            if (!groupSelect) {
                [wdDrawingController selectNone:nil];
            }
            [wdDrawingController selectObject:element];
        } else if (path && path.superpath && [wdDrawingController isSelected:path.superpath] && ![wdDrawingController singleSelection]) {
            lastTappedObject_ = path.superpath;
            objectWasSelected_ = YES;
        }
    } else if ([wdDrawingController singleSelection]) {
        // we have a single selection, and the hit element is already selected... it must be the single selection
        
        if ([element isKindOfClass:[WDAbstractPath class]]) {
            if (result.type == kWDObjectFill) {
                [wdDrawingController deselectAllNodes];
                
            }
        }
    } else {
        lastTappedObject_ = element;
        objectWasSelected_ = [wdDrawingController isSelected:result.element];
    }
    
    
    WDElement           *singleSelection = [wdDrawingController singleSelection];
    NSInteger ccc = [[wdDrawingController selectedObjects] count];
    int nSelectionLayerIndex = [self getLayerIndexWithElement:singleSelection];
    int nActiveLayerIndex = [contents activeLayerIndex];
    if(nSelectionLayerIndex != nActiveLayerIndex)
    {
        [contents setActiveLayerIndexComplete:nSelectionLayerIndex];
    }
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(!m_bMouseDown) return;
    
    if(!m_bDragged)
        if(fabs(where.x - m_cgPointInit.x) < KMinDifferent && (fabs(where.y - m_cgPointInit.y) < KMinDifferent)) return;
    
    m_bDragged = YES;
    
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    CGPoint currentPt = CGPointMake(where.x, where.y);
    
    if (marqueeMode_)
    {
        m_cgRectMarquee = WDRectWithPoints(m_cgPointInit, currentPt);
        [self selectObjectsInRect:m_cgRectMarquee];
    }
    else {
        // transform selected
        m_bTransforming = YES;
        m_cgPointCurrent = currentPt;
    }

    [[m_idDocument docView] setNeedsDisplay:YES];
}


- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event
{
    m_bMouseDown = NO;

    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    if (marqueeMode_) {
        marqueeMode_ = NO;
        m_cgRectMarquee = NSZeroRect;
        m_cgPointInit = m_cgPointCurrent = CGPointZero;
        wdDrawingController.propertyManager.ignoreSelectionChanges = NO;
        return;
    }
    
    if (m_bDragged) {
        // apply the transform to the drawing
        [self moveSelectionFromPointToPointInCanvas:m_cgPointInit toPoint:m_cgPointCurrent];
        m_cgPointInit = m_cgPointCurrent = CGPointZero;
        //            [wdDrawingController transformSelection:m_transform];
        //            m_transform = CGAffineTransformIdentity;
    }
    else if ([(PSAbstractVectorSelectOptions *)m_idOptions groupSelect] && lastTappedObject_ && objectWasSelected_) {
        [wdDrawingController deselectObject:lastTappedObject_];
    }
    
    lastTappedObject_ = nil;
    m_bTransforming = NO;
    m_bDragged = NO;
//    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event    //where
{
//    if([m_idOptions respondsToSelector:@selector(optionKeyEnable)])
//    {
//        if ([(PSAbstractVectorSelectOptions *)m_idOptions optionKeyEnable])
//        {
//            if(m_cursor) {[m_cursor release]; m_cursor = nil;}
//            m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-copy.png"] hotSpot:NSMakePoint(1, 1)];
//            [m_cursor set];
//        }
//    }
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    
    CGPoint pointInCanvas;
    pointInCanvas.x = where.x / xScale;
    pointInCanvas.y = where.y / yScale;
    
    
    WDPickResult *result = [self objectUnderPoint:pointInCanvas viewScale:1 whichLayerIndex:&m_nMouseMoveOnObjecLayerIndex];
    
    //移动时，显示可以选择的对象
    if (result.type == kWDEther)
    {
        if(lastMouseMoveOnObject_)
        {
            [lastMouseMoveOnObject_ release];
            lastMouseMoveOnObject_ = nil;
            [[m_idDocument docView] setNeedsDisplay:YES];
        }
    }else
    {
        WDElement *element = result.element;
        if (element && ([element isKindOfClass:[WDPath class]] || [element isKindOfClass:[WDCompoundPath class]]|| [element isKindOfClass:[WDGroup class]]) && element != lastMouseMoveOnObject_)
        {
            WDElement *lastMouseMoveOnObjectTemp =  lastMouseMoveOnObject_;
            lastMouseMoveOnObject_ = [element retain];
            if(lastMouseMoveOnObjectTemp) {
                [lastMouseMoveOnObjectTemp release];
                lastMouseMoveOnObjectTemp = nil;
            }
            [[m_idDocument docView] setNeedsDisplay:YES];
        }
    }
    
    //update move-copy cursor
    if (result.type == kWDEdge || result.type == kWDObjectFill) {
        if([m_idOptions respondsToSelector:@selector(optionKeyEnable)])
        {
            if ([(PSAbstractVectorSelectOptions *)m_idOptions optionKeyEnable])
            {
                if(m_cursor) {[m_cursor release]; m_cursor = nil;}
                m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-copy.png"] hotSpot:NSMakePoint(1, 1)];
                [m_cursor set];
            }
        }
    }
}


- (WDPickResult *) objectUnderPoint:(CGPoint)pt viewScale:(float)viewScale whichLayerIndex:(int *)nLayerIndex
{
    WDPickResult    *pickResult;
    NSUInteger      flags = kWDSnapEdges;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if (!wdDrawingController.drawing.outlineMode) {
        flags |= kWDSnapFills;
    }
    
    // first test active path
    if (wdDrawingController.activePath) {
        int nLayerIndex = [self getLayerIndexWithElement:wdDrawingController.activePath];
        if([[contents layer:nLayerIndex] visible])
        {
            PSVecLayer *pVecLayer = [contents layer:nLayerIndex];
            CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
            CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(pt), transform);
            pickResult = [wdDrawingController.activePath hitResultForPoint:pointTransformInvert viewScale:viewScale snapFlags:kWDSnapNodes];
            
            if (pickResult.type != kWDEther) {
                return pickResult;
            }
        }
    }
    
    // check singly selected objects, which get specialized behavior
    if (!wdDrawingController.activePath && wdDrawingController.selectedObjects.count == 1) {
        int nLayerIndex = [self getLayerIndexWithElement:[wdDrawingController.selectedObjects anyObject]];
        if([[contents layer:nLayerIndex] visible])
        {
            PSVecLayer *pVecLayer = [contents layer:nLayerIndex];
            CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
            CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(pt), transform);
            
            pickResult = [[wdDrawingController.selectedObjects anyObject] hitResultForPoint:pointTransformInvert
                                                                   viewScale:viewScale
                                                                   snapFlags:(kWDSnapNodes | kWDSnapEdges)];
            if (pickResult.type != kWDEther) {
                return pickResult;
            }
        }
    }
   
    int nLayerCount = [contents layerCount];
    for (int nIndex = 0; nIndex < nLayerCount; nIndex ++)
    {
        PSAbstractLayer *pLayer = [contents layer:nIndex];
        if(![pLayer visible]) continue;
        if([pLayer layerFormat] != PS_VECTOR_LAYER) continue;
        
        PSVecLayer *pVecLayer = (PSVecLayer *)pLayer;
        WDLayer *wdLayer = [pVecLayer getLayer];
        for (WDElement *element in [wdLayer.elements reverseObjectEnumerator]) {
            
            CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
            CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(pt), transform);
            
            pickResult = [element hitResultForPoint:pointTransformInvert viewScale:viewScale snapFlags:(int)flags];
            
            if (pickResult.type != kWDEther) {
                
                *nLayerIndex = nIndex;
                return pickResult;
            }
        }
    }
    
    return [WDPickResult pickResult];
}

- (void) selectObjectsInRect:(CGRect)rect
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController.selectedObjects removeAllObjects];
    
    NSArray *layersToCheck = wdDrawingController.drawing.isolateActiveLayer ? @[wdDrawingController.drawing.activeLayer] : wdDrawingController.drawing.layers;
    
    for (WDLayer *layer in [layersToCheck reverseObjectEnumerator])
    {
        PSVecLayer *pVecLayer = layer.layerDelegate;
        if (![pVecLayer visible]) continue;
        
        CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
        CGRect rectTransformInvert = CGRectApplyAffineTransform(rect, transform);
        
        for (WDElement *element in [layer.elements reverseObjectEnumerator]) {
            if ([element intersectsRect:rectTransformInvert]) {
                [wdDrawingController.selectedObjects addObject:element];
            }
        }
    }
    
    [wdDrawingController deselectAllNodes];
    
    // if a single path is selected, select the nodes inside the marquee
    WDPath *singlePath = (WDPath *) [wdDrawingController singleSelection];
    if ([singlePath isKindOfClass:[WDPath class]])
    {
        CGAffineTransform transform = [self getLayerTransformForElement:singlePath];
        transform = CGAffineTransformInvert(transform);
        CGRect rectTransformInvert = CGRectApplyAffineTransform(rect, transform);
        
        [self setSelectedNodesFromSet:[singlePath nodesInRect:rectTransformInvert]];
    }
    
    [wdDrawingController notifySelectionChanged];
}

- (void) setSelectedNodesFromSet:(NSSet *)set
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    for (WDBezierNode *node in wdDrawingController.selectedNodes) {
        node.selected = NO;
    }
    
    [wdDrawingController.selectedNodes setSet:set];
    
    for (WDBezierNode *node in wdDrawingController.selectedNodes) {
        node.selected = YES;
    }
}

-(int)getLayerIndexWithElement:(WDElement *)elelment
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    int nLayerCount = [contents layerCount];
    for (int nIndex = 0; nIndex < nLayerCount; nIndex ++)
    {
        PSAbstractLayer *pLayer = [contents layer:nIndex];
        if([pLayer layerFormat] != PS_VECTOR_LAYER) continue;
        
        PSVecLayer *pVecLayer = (PSVecLayer *)pLayer;
        WDLayer *wdLayer = [pVecLayer getLayer];
        
        if([elelment layer] == wdLayer) return nIndex;
        //        for (WDElement *element in [wdLayer.elements reverseObjectEnumerator])
        //        {
        //            if(element == elelment)
        //                return nIndex;
        //        }
    }
    
    return [contents activeLayerIndex];
}

-(CGAffineTransform)getLayerTransformForElement:(WDElement *)elelment
{
    int nLayerIndex = [self getLayerIndexWithElement:elelment];
    PSContent *contents = (PSContent *)[m_idDocument contents];
    PSAbstractLayer *pLayer = [contents layer:nLayerIndex];
    
    if([pLayer layerFormat] != PS_VECTOR_LAYER) return CGAffineTransformIdentity;
    
    PSVecLayer *pVecLayer = (PSVecLayer *)pLayer;
    return [pVecLayer transform];
}

-(void)moveSelectionFromPointToPointInCanvas:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    for (WDElement *element in wdDrawingController.selectedObjects)
    {
        CGAffineTransform transform = [self transformMakeFromPointToPointInCanvasForElement:element fromPoint:fromPoint toPoint:toPoint];
        //[element transform:transform];
        NSSet *replacedNodes = [element transform:transform];
        if (replacedNodes && replacedNodes.count) {
            [self setSelectedNodesFromSet:replacedNodes];
        }
    }
}

-(CGAffineTransform)transformMakeFromPointToPointInCanvasForElement:(WDElement *)element fromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
    CGAffineTransform layerTransform = [self getLayerTransformForElement:element];
    
    CGAffineTransform transform = CGAffineTransformInvert(layerTransform);
    CGPoint pointTransformFrom = CGPointApplyAffineTransform(NSPointToCGPoint(fromPoint), transform);
    CGPoint pointTransformTo = CGPointApplyAffineTransform(NSPointToCGPoint(toPoint), transform);
    
    CGPoint delta = WDSubtractPoints(pointTransformTo, pointTransformFrom);
    transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, delta.x, delta.y);
    //    transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    
    return transform;
}

#pragma mark -
-(void)copySelectedObjects:(NSMutableSet *)arrElement
{
    for(WDElement *element in arrElement)
    {
        WDLayer *wdLayer = [element layer];
        WDElement *newElement = [element copyWithZone:nil];

        [wdLayer insertObject:newElement above:element];
        
    }
}

#pragma mark - ShapeVector

-(void)selectAllObjects
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    [wdDrawingController selectAll:nil];
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (BOOL)judgeVectorElementNeedDraw:(WDElement*)element
{
    PSVecLayer *pVecLayer = [element layer].layerDelegate;
    if(![pVecLayer visible]){
        return NO;
    }
    PSContent *contents = (PSContent *)[m_idDocument contents];
    int index = [contents layerIndex:pVecLayer];
    if (index == -1) {
        return NO;
    }
    
    if (![self judgeVectorLayerContainsElement:element]) {
        return NO;
    }
    
    return YES;
}


- (BOOL)judgeVectorLayerContainsElement:(WDElement*)element
{
    BOOL contain = NO;
    
    if ([[element layer].elements containsObject:element]){
        contain = YES;
    }else{
        WDPath *path = nil;
        if ([element isKindOfClass:[WDPath class]]) {
            path = (WDPath *) element;
        }
        
        if (path && path.superpath && [[element layer].elements containsObject:path.superpath]) {
            contain = YES;
        }
    }
    return contain;
}

#pragma mark - Draw Extras
-(void)drawSelectedObjectExtra
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    if(nSelection <= 0) return;
 
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);
    
    if(!CGRectEqualToRect(m_cgRectMarquee, CGRectZero))
        [self drawSelectMarquee:ctx scale:[[m_idDocument docView] zoom]];
    
//    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
    float scale = [[m_idDocument docView] zoom];
    
//    WDElement           *singleSelection = [wdDrawingController singleSelection];
//     draw all object outlines, using the selection transform if applicable
    for (WDElement *element in wdDrawingController.selectedObjects) //选中之后的移动
    {
        PSVecLayer *pVecLayer = [element layer].layerDelegate;
        
        if (![self judgeVectorElementNeedDraw:element]) {
            continue;
        }
        
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx,[pVecLayer transform]);
        CGAffineTransform transform = [self transformMakeFromPointToPointInCanvasForElement:element fromPoint:m_cgPointInit toPoint:m_cgPointCurrent];
        
        if([(PSAbstractVectorSelectOptions *)m_idOptions optionKeyEnable])
            [element drawHighlightWithTransformInContext:ctx :transform viewTransform:CGAffineTransformIdentity scale:scale];
        
        if([wdDrawingController.selectedObjects count] > 1 || (!CGRectEqualToRect(m_cgRectMarquee, CGRectZero)))  //选择多于一个对象时绘制描点方便看或者矩形框选择时
            [element drawAnchorsWithViewTransform:ctx :CGAffineTransformIdentity scale:scale];
        
        CGContextRestoreGState(ctx);
    }
    
    CGContextRestoreGState(ctx);
}

-(void)drawMoveMouseOnObjectExtra
{
    if(m_nMouseMoveOnObjecLayerIndex == -1) return;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    if(m_nMouseMoveOnObjecLayerIndex >= [contents layerCount]) return;
    id moveOnObjecLayer = [contents layer:m_nMouseMoveOnObjecLayerIndex];
    if([moveOnObjecLayer layerFormat] != PS_VECTOR_LAYER) return;
    PSVecLayer *pVecLayer = (PSVecLayer *)moveOnObjecLayer;
    
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    
    
    CGContextScaleCTM(ctx, xScale, yScale);
    CGContextConcatCTM(ctx,[pVecLayer transform]);
    
    if(lastMouseMoveOnObject_){
        [lastMouseMoveOnObject_ renderInContext:ctx metaData:WDRenderingMetaDataMake(2.0, WDRenderOutlineOnly)];
    }
    
    CGContextDrawPath(ctx, kCGPathStroke);
    CGContextRestoreGState(ctx);
}


-(void)drawSelectMarquee:(CGContextRef)ctx scale:(float)fScale
{
    [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.333f] set];
    
    CGContextFillRect(ctx, m_cgRectMarquee);
   
    CGContextSetLineWidth(ctx, 1.0/fScale);
    
    [[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.75f] set];
    CGContextStrokeRect(ctx, m_cgRectMarquee);
}

- (BOOL)isSelectedObject:(WDElement *)element
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    if([wdDrawingController.selectedObjects count] == 0) return NO;
    
    for(WDElement *elementSelected in wdDrawingController.selectedObjects)
    {
        if(elementSelected == element) return YES;
    }
    
    return NO;
}

- (void)drawToolExtra
{
    if(lastMouseMoveOnObject_ && [self isSelectedObject:lastMouseMoveOnObject_] == NO){
        [self drawMoveMouseOnObjectExtra];
    }
    
    [self drawSelectedObjectExtra];
    
    [super drawToolExtra];
}

-(void)showInfoView
{
    PSShowInfoPanel *showInfoPanel = [[[PSShowInfoPanel alloc] init] autorelease];
    [showInfoPanel addMessageText:NSLocalizedString(@"Alt - Operate control handles independently", nil)];
    [showInfoPanel addMessageText:NSLocalizedString(@"Command+Shift - Select all shapes", nil)];
    [showInfoPanel addMessageText:NSLocalizedString(@"Command - Select multiple shapes", nil)];
    [showInfoPanel setAutoHiddenDelay:3.0];
    [showInfoPanel showPanel:NSZeroRect];
}

- (BOOL)deleteKeyPressed
{
    PSContent *contents = [m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    NSMutableArray *objects = [wdDrawingController orderedSelectedObjects];
    if ([objects count] > 0) {
        [wdDrawingController deleteSelectedPath:nil];
        lastMouseMoveOnObject_ = nil;
        [[m_idDocument docView] setNeedsDisplay:YES];
        return YES;
    }
    
    return NO;
}

- (BOOL)moveKeyPressedOffset:(NSPoint)offset needUndo:(BOOL)undo
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if ([wdDrawingController.selectedObjects count] <= 0) {
        return NO;
    }
    
    [self moveSelectionFromPointToPointInCanvas:CGPointMake(0, 0) toPoint:offset];
    
    [[m_idDocument docView] setNeedsDisplay:YES];
    
    return YES;
    
}


@end
