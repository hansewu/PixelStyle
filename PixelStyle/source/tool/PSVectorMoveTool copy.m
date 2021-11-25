//
//  PSVectorMoveTool.m
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//
#include <stdio.h>
#import "PSVectorMoveTool.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSHelpers.h"
#import "PSTools.h"
#import "PSVecLayer.h"
#import "PSVectorMoveOptions.h"
#import "PSView.h"

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
#import "PSShowInfoPanel.h"


#define KMinDifferent 1
@implementation PSVectorMoveTool

@synthesize groupSelect = groupSelect_;


- (int)toolId
{
    return kVectorMoveTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Path Selection Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"A";
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
    
    if(m_strToolTips) {[m_strToolTips release]; m_strToolTips = nil;}
    m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt & drag the selected object to copy. Press Command & Shift to select all shapes. Press Command to select multiple shapes.", nil)];
//    m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt & drag the selected object to copy. Double click to convert the selected point. Press Command & Shift to select all shapes. Press Command to select multiple shapes. Press Opt to operate control handles independently.", nil)];
    
    return self;
}

- (void)dealloc
{
    if(lastMouseMoveOnObject_) {[lastMouseMoveOnObject_ release]; lastMouseMoveOnObject_ = nil;}
    
    [super dealloc];
}

#pragma mark - Mouse Events
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    activeNode_ = nil;
    activeTextHandle_ = kWDEther;
    activeGradientHandle_ = kWDEther;
    transformingNodes_ = NO;
    transformingHandles_ = NO;
    convertingNode_ = NO;
    transformingGradient_ = NO;
    transformingTextKnobs_ = NO;
    transformingTextPathStartKnob_ = NO;
    m_bMouseDown = YES;
    m_bDragged = NO;
    lastTappedObject_ = nil;
//    m_transform = CGAffineTransformIdentity;
    if(lastMouseMoveOnObject_) {[lastMouseMoveOnObject_ release]; lastMouseMoveOnObject_ = nil;}
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    
    m_cgPointInitial.x = where.x + [[[m_idDocument contents] activeLayer] xoff];
    m_cgPointInitial.y = where.y + [[[m_idDocument contents] activeLayer] yoff];
    m_cgPointCurrent = m_cgPointInitial;
    
    int nLayerIndex = -1;
    WDPickResult *result = [self objectUnderPoint:m_cgPointInitial viewScale:1 whichLayerIndex:&nLayerIndex];
    
    //按住alt键移动，复制
    if([(PSVectorMoveOptions *)m_idOptions optionKeyEnable] && (result.type == kWDEdge || result.type == kWDObjectFill))
            [self copySelectedObjects:wdDrawingController.selectedObjects];
    
    int action = [(PSVectorMoveOptions *)m_idOptions getActionStyle];
    if (action == 1) {
        if (![result.element isKindOfClass:[WDPath class]]) {
            return;
        }
        
        WDPath              *path = (WDPath *) result.element;
        
        if (result.type == kWDEdge) {
            if ([wdDrawingController singleSelection] != path) {
                // we want this path to be the exclusive selection
                [wdDrawingController selectNone:nil];
                [wdDrawingController selectObject:result.element];
            }
            
            WDBezierNode *newestNode = [path addAnchorAtPoint:result.snappedPoint viewScale:1.0];
            [wdDrawingController selectNode:newestNode];
        }
        
        if (result.type == kWDAnchorPoint) {
            if ([wdDrawingController isSelected:path]) {
                [wdDrawingController deselectAllNodes];
                [wdDrawingController selectNode:result.node];
                
                [path deleteAnchor:result.node];
            } else {
                // just select the path and do nothing
                [wdDrawingController selectNone:nil];
                [wdDrawingController selectObject:result.element];
            }
        }
        return;

    }
    
    if (result.type == kWDEther) {
        // didn't hit anything: marquee mode!
        [wdDrawingController selectNone:nil];
        wdDrawingController.propertyManager.ignoreSelectionChanges = YES;
        marqueeMode_ = YES;
        
        [[m_idDocument docView] setNeedsDisplay:YES];
        return;
    }
    
    self.groupSelect = [(PSVectorMoveOptions *)m_idOptions groupSelect];
    WDElement *element = result.element;
    
    if (![wdDrawingController isSelected:element]) {
//        int nActiveLayerIndex = [contents activeLayerIndex];
//        if (nActiveLayerIndex != nLayerIndex)
//        {
//            if (self.groupSelect && wdDrawingController.selectedObjects.count)
//            {
//                NSBeep();
//                return;
//            }
//            
//            [[m_idDocument contents] setActiveLayerIndex:nLayerIndex];
//            [[m_idDocument helpers] activeLayerChanged:kLayerSwitched rect:NULL];
//            [[m_idDocument contents] setLinked:NO forLayer:nActiveLayerIndex];
//        }
        
        WDPath *path = nil;
        
        if ([element isKindOfClass:[WDPath class]]) {
            path = (WDPath *) element;
        }
        
        if (!path || !path.superpath || (path.superpath && ![wdDrawingController isSelected:path.superpath])) {
            if (!self.groupSelect) {
                [wdDrawingController selectNone:nil];
            }
            [wdDrawingController selectObject:element];
        } else if (path && path.superpath && [wdDrawingController isSelected:path.superpath] && ![wdDrawingController singleSelection]) {
            lastTappedObject_ = path.superpath;
            objectWasSelected_ = YES;
        }
    }
//    else if ([wdDrawingController singleSelection]) {
//        // we have a single selection, and the hit element is already selected... it must be the single selection
//        
//        if ([element isKindOfClass:[WDPath class]] && result.node) {
//            nodeWasSelected_ = result.node.selected;
//            activeNode_ = result.node;
//            
//            if (!nodeWasSelected_) {
//                if (!self.groupSelect) {
//                    // only allow one node to be selected at a time
//                    [wdDrawingController deselectAllNodes];
//                }
//                [wdDrawingController selectNode:result.node];
//            }
//            
//            if (event.clickCount == 2) {
//                // convert node mode, start transforming handles in pure reflection mode
//                pointToMove_ = (result.type == kWDAnchorPoint) ? kWDOutPoint : result.type;
//                pointToConvert_ = result.type;
//                originalReflectionMode_ = WDReflect;
//                transformingHandles_ = YES;
//                convertingNode_ = YES;
//            } else if (result.type == kWDInPoint || result.type == kWDOutPoint) {
//                pointToMove_ = result.type;
//                originalReflectionMode_ = activeNode_.reflectionMode;
//                transformingHandles_ = YES;
//            } else {
//                // we're dragging a node, we should treat it as the snap point
//                //self.initialEvent.snappedLocation = result.node.anchorPoint;
//                transformingNodes_ = YES;
//            }
//            
////            if (result.type == kWDInPoint || result.type == kWDOutPoint) {
////                pointToMove_ = result.type;
////                originalReflectionMode_ = activeNode_.reflectionMode;
////                transformingHandles_ = YES;
////            } else {
////                // we're dragging a node, we should treat it as the snap point
//////                self.initialEvent.snappedLocation = result.node.anchorPoint;
////                transformingNodes_ = YES;
////            }
//        }
//        else if ([element isKindOfClass:[WDPath class]] && result.type == kWDEdge) {
//            // only allow one node to be selected at a time
//            [wdDrawingController deselectAllNodes];
//            
////            if (event.count == 2 && [element conformsToProtocol:@protocol(WDTextRenderer)]) {
////                [canvas.controller editTextObject:(WDText *)element selectAll:NO];
////            }
//        } else if ([element isKindOfClass:[WDStylable class]] && (result.type == kWDFillEndPoint || result.type == kWDFillStartPoint)) {
//            activeGradientHandle_ = result.type;
//            transformingGradient_ = YES;
//        } else if ([element isKindOfClass:[WDTextPath class]] && (result.type == kWDTextPathStartKnob)) {
//            activeTextPath_ = (WDTextPath *) element;
//            transformingTextPathStartKnob_ = YES;
//            [activeTextPath_ cacheOriginalStartOffset];
//        } else if ([element isKindOfClass:[WDAbstractPath class]]) {
//            if (result.type == kWDObjectFill) {
//                [wdDrawingController deselectAllNodes];
//                
////                if (event.count == 2 && [element conformsToProtocol:@protocol(WDTextRenderer)]) {
////                    [canvas.controller editTextObject:(WDText *)element selectAll:NO];
////                }
//            }
//        } else if ([element isKindOfClass:[WDText class]]) {
////            if (event.count == 2) {
////                [canvas.controller editTextObject:(WDText *)element selectAll:NO];
////            } else
//                if (result.type == kWDLeftTextKnob || result.type == kWDRightTextKnob) {
//                    activeTextHandle_ = result.type;
//                    transformingTextKnobs_ = YES;
//                    [(WDText *)element cacheTransformAndWidth];
//                }
//        }
//    }
    else {
        lastTappedObject_ = element;
        objectWasSelected_ = [wdDrawingController isSelected:result.element];
    }
    
    
    WDElement           *singleSelection = [wdDrawingController singleSelection];
    int nSelectionLayerIndex = [self getLayerIndexWithElement:singleSelection];
    int nActiveLayerIndex = [contents activeLayerIndex];
    if(nSelectionLayerIndex != nActiveLayerIndex)
    {
        [contents setActiveLayerIndexComplete:nSelectionLayerIndex];
    }
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    int action = [(PSVectorMoveOptions *)m_idOptions getActionStyle];
    if (action == 1)
        return;
    if(!m_bMouseDown) return;
    
    where.x = where.x + [[[m_idDocument contents] activeLayer] xoff];     //转成相对画布的点
    where.y = where.y + [[[m_idDocument contents] activeLayer] yoff];
    
    
    if(!m_bDragged)
        if(fabs(where.x - m_cgPointInitial.x) < KMinDifferent && (fabs(where.y - m_cgPointInitial.y) < KMinDifferent)) return;
    
    m_bDragged = YES;
    
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    WDDynamicGuideController *guideController = wdDrawingController.dynamicGuideController;
    CGPoint currentPt = CGPointMake(where.x, where.y);
    
    NSUInteger snapFlags = 0 | kWDSnapLocked | kWDSnapSubelement;
    WDPickResult *result = [wdDrawingController snappedPoint:m_cgPointInitial viewScale:1 snapFlags:(int)snapFlags];
    CGPoint initialSnapped = result.snapped ? result.snappedPoint : m_cgPointInitial;
    
    result = [wdDrawingController snappedPoint:currentPt viewScale:1 snapFlags:(int)snapFlags];
    CGPoint snapped = result.snapped ? result.snappedPoint : currentPt;
    CGPoint delta;
    
    if (marqueeMode_) {
//        CGRect selectionRect;
        
//        if (self.flags & WDToolSecondaryTouch || self.flags & WDToolOptionKey) {
//            delta = WDSubtractPoints(m_cgPointInitial, currentPt);
//            selectionRect = WDRectWithPoints(WDAddPoints(m_cgPointInitial, delta), WDSubtractPoints(m_cgPointInitial, delta));
//        } else {
            m_cgRectMarquee = WDRectWithPoints(m_cgPointInitial, currentPt);
//        }
        
//        canvas.marquee = [NSValue valueWithCGRect:selectionRect];
        [self selectObjectsInRect:m_cgRectMarquee];
    }  else if (transformingNodes_) {
        m_bTransforming = m_bTransformingNode = YES;
        m_cgPointCurrent = CGPointMake(where.x, where.y);
//        delta = CGPointMake(where.x - m_cgPointInitial.x, where.y - m_cgPointInitial.y);
        
//        if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch) {
//            delta = WDConstrainPoint(delta);
//        }
//        
//        if ([canvas.drawing dynamicGuides]) {
//            // find guides that are snapped to the result
//            canvas.dynamicGuides = [guideController snappedGuidesForPoint:WDAddPoints(initialSnapped, delta)];
//        }
        
//        m_transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
//        [canvas transformSelection:transform_];
    } else if (transformingHandles_) {
        m_bTransforming = m_bTransformingNode = YES;
        //canvas.transforming = canvas.transformingNode = YES;

        WDPath *path = (WDPath *) [wdDrawingController singleSelection];
        WDBezierNodeReflectionMode reflect = [(PSVectorMoveOptions *)m_idOptions optionKeyEnable] ? WDIndependent : originalReflectionMode_;
        //WDBezierNodeReflectionMode reflect = originalReflectionMode_;
        
        CGAffineTransform transform = [self getLayerTransformForElement:path];
        transform = CGAffineTransformInvert(transform);
        snapped = CGPointApplyAffineTransform(snapped, transform);
        replacementNode_ = [activeNode_ moveControlHandle:(int)pointToMove_ toPoint:snapped reflectionMode:reflect];
        replacementNode_.selected = YES;
        
        NSMutableArray *newNodes = [NSMutableArray array];
        
        for (WDBezierNode *node in path.nodes) {
            if (node == activeNode_) {
                [newNodes addObject:replacementNode_];
            } else {
                [newNodes addObject:node];
            }
        }
        
        
        path.displayNodes = newNodes;
        path.displayClosed = path.closed;
        
    } else if (transformingGradient_) {
//        m_bTransforming = m_bTransformingNode = YES;
//
//        WDPath *path = (WDPath *) [canvas.drawingController.selectedObjects anyObject];
//        if (activeGradientHandle_ == kWDFillStartPoint) {
//            path.displayFillTransform = [path.fillTransform transformWithTransformedStart:snapped];
//        } else {
//            path.displayFillTransform = [path.fillTransform transformWithTransformedEnd:snapped];
//        }
//        
//        [canvas invalidateSelectionView];
    } else if (transformingTextKnobs_) {
//        m_bTransforming = YES;
//        
//        WDText *text = (WDText *) [canvas.drawingController singleSelection];
//        [text moveHandle:activeTextHandle_ toPoint:snapped];
//        
//        [canvas invalidateSelectionView];
    } else if (transformingTextPathStartKnob_) {
//        WDTextPath *path = (WDTextPath *) [canvas.drawingController.selectedObjects anyObject];
//        [path moveStartKnobToNearestPoint:currentPt];
//        [canvas invalidateSelectionView];
    } else {
        // transform selected
        m_bTransforming = YES;
        m_bTransformingNode = [wdDrawingController selectedNodes].count;
        m_cgPointCurrent = currentPt;
//        delta = WDSubtractPoints(currentPt, initialSnapped);
        
//        if (self.flags & WDToolShiftKey || self.flags & WDToolSecondaryTouch) {
//            delta = WDConstrainPoint(delta);
//        }
//        
//        BOOL snapToGuides = [canvas.drawing dynamicGuides];
//        
//        if (snapToGuides) {
//            // can be harmlessly called multiple times
//            [guideController beginGuideOperation];
//        }
//        
//        // grid snapping overrides guide snapping
//        if ([canvas.drawing snapFlags] & kWDSnapGrid) {
//            delta = [self offsetSelection:delta inCanvas:canvas];
//        } else if (snapToGuides) {
//            delta = [guideController offsetSelectionForGuides:delta viewScale:canvas.viewScale];
//        }
//        
//        if (snapToGuides) {
//            // find guides that are snapped to the result
//            CGRect snapRect = CGRectOffset([canvas.drawingController selectionBounds], delta.x, delta.y);
//            canvas.dynamicGuides = [guideController snappedGuidesForRect:snapRect];
//        }
//        
//        m_transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    }

    [[m_idDocument docView] setNeedsDisplay:YES];
}


- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    int action = [(PSVectorMoveOptions *)m_idOptions getActionStyle];
    if (action == 1)
        return;
    
    m_bMouseDown = NO;

    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    if (marqueeMode_) {
        marqueeMode_ = NO;
        m_cgRectMarquee = NSZeroRect;
        m_cgPointInitial = m_cgPointCurrent = CGPointZero;
        wdDrawingController.propertyManager.ignoreSelectionChanges = NO;
        return;
    }
    
    
    if (transformingNodes_) {
        if (!m_bDragged && nodeWasSelected_) {
            [wdDrawingController deselectNode:activeNode_];;
        } else if (m_bDragged) {
            // apply the transform to the drawing
            
            [self moveSelectionFromPointToPointInCanvas:m_cgPointInitial toPoint:m_cgPointCurrent];
            m_cgPointInitial = m_cgPointCurrent = CGPointZero;
//            [wdDrawingController transformSelection:m_transform];
//            m_transform = CGAffineTransformIdentity;
        }
    }
    else if (convertingNode_ && !m_bDragged) {
        WDPath *path = ((WDPath *) [wdDrawingController singleSelection]);
        
        WDBezierNode *node = [path convertNode:activeNode_ whichPoint:(int)pointToConvert_];
        [wdDrawingController deselectNode:activeNode_];
        [wdDrawingController selectNode:node];
    }
    else if (transformingHandles_ && replacementNode_) {
        WDPath *path = ((WDPath *) [wdDrawingController singleSelection]);
        path.displayNodes = nil;
        NSMutableArray *newNodes = [NSMutableArray array];
        
        for (WDBezierNode *node in path.nodes) {
            if (node == activeNode_) {
                [newNodes addObject:replacementNode_];
            } else {
                [newNodes addObject:node];
            }
        }
        
        [wdDrawingController selectNode:replacementNode_];
        replacementNode_ = nil;
        path.nodes = newNodes;
    }
//    else if (transformingTextPathStartKnob_) {
//        [activeTextPath_ registerUndoWithCachedStartOffset];
//        activeTextPath_ = nil;
//    }
//    else if (transformingTextKnobs_) {
//        WDText *text = (WDText *) [wdDrawingController singleSelection];
//        [text registerUndoWithCachedTransformAndWidth];
//    }
    else {
        if (m_bDragged) {
            // apply the transform to the drawing
            [self moveSelectionFromPointToPointInCanvas:m_cgPointInitial toPoint:m_cgPointCurrent];
            m_cgPointInitial = m_cgPointCurrent = CGPointZero;
//            [wdDrawingController transformSelection:m_transform];
//            m_transform = CGAffineTransformIdentity;
        } else if (self.groupSelect && lastTappedObject_ && objectWasSelected_) {
            [wdDrawingController deselectObject:lastTappedObject_];
        }
    }
    
    // turn these off here to make sure we don't snap to guides when we don't want to
    transformingNodes_ = NO;
    transformingHandles_ = NO;
    m_bTransforming = m_bTransformingNode = NO;
    m_bDragged = NO;
    lastTappedObject_ = nil;
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event    //where
{
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    if((NSPointInRect([NSEvent mouseLocation], [gColorPanel frame]) && [gColorPanel isVisible]))
    {
        m_cursor = [[NSCursor arrowCursor] retain];
        [m_cursor set];
        return;
    }
    
    NSArray *arrChildWindows = [[m_idDocument window] childWindows];
    for(NSWindow *window in arrChildWindows)
    {
        if((NSPointInRect([NSEvent mouseLocation], [window frame]) && [window isVisible]))
        {
            m_cursor = [[NSCursor arrowCursor] retain];
            [m_cursor set];
            
            return;
        }
    }
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSRect operableRect;
    IntRect operableIntRect;
    
    operableIntRect = IntMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * xScale, [(PSContent *)[m_idDocument contents] height] *yScale);
    operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([[m_idDocument docView] frame]), operableIntRect));
    
    
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    
    // Convert to the scrollview's origin
    operableRect.origin = [scrollView convertPoint: operableRect.origin fromView: [m_idDocument docView]];
    
    // Clip to the centering clipview
    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], operableRect);
    
    // Convert the point back to the seaview
    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor arrowCursor] retain];
    if(!NSPointInRect(where, clippedRect))
    {
        [m_cursor set];
        return;
    }
    
    CGPoint pointInCanvas;
//    float xScale = [[m_idDocument contents] xscale];
//    float yScale = [[m_idDocument contents] yscale];
    pointInCanvas.x = where.x / xScale;
    pointInCanvas.y = where.y / yScale;
    
    WDPickResult *result = [self objectUnderPoint:pointInCanvas viewScale:1 whichLayerIndex:&m_nMouseMoveOnObjecLayerIndex];
    if(result.type != kWDEther)
    {
        int action = [(PSVectorMoveOptions *)m_idOptions getActionStyle];
        if (action == 1){
            if (result.type == kWDEdge) {
                if(m_cursor) {[m_cursor release]; m_cursor = nil;}
                m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"anchor-add-cursor"] hotSpot:NSMakePoint(1, 0)];
            }else if (result.type == kWDAnchorPoint){
                if(m_cursor) {[m_cursor release]; m_cursor = nil;}
                m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"anchor-delete-cursor"] hotSpot:NSMakePoint(1, 0)];
            }
        }
    }
    
    [m_cursor set];
    
    
    
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
        
        // TODO: act as if we tapped the fill, or show node handles?
        //if ([singlePath allNodesSelected]) {
        //    [self deselectAllNodes];
        //}
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

-(CGPoint)convertPointFromCanvasToLayer:(CGPoint)point layerIndex:(int)nLayerIndex
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    PSAbstractLayer *pLayer = [contents layer:nLayerIndex];
    if(pLayer.layerFormat != PS_VECTOR_LAYER) return point;
    
    PSVecLayer *pVecLayer = (PSVecLayer *)pLayer;
    CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
    CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(point), transform);
    return pointTransformInvert;
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

//#pragma mark - Transform
//-(void)setTransformType:(TransformType)TransformType
//{
//    m_enumTransfomType = TransformType;
//    
//    [m_vectorTransformManager setTransformStatus:TransformType];
//}

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
    float scale = [[m_idDocument docView] zoom];
//    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
    
    
    WDElement           *singleSelection = [wdDrawingController singleSelection];
    // draw all object outlines, using the selection transform if applicable
    for (WDElement *element in wdDrawingController.selectedObjects) //选中之后的移动
    {
        PSVecLayer *pVecLayer = [element layer].layerDelegate;
        
        if (![self judgeVectorElementNeedDraw:element]) {
            continue;
        }

        
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx,[pVecLayer transform]);
        CGAffineTransform transform = [self transformMakeFromPointToPointInCanvasForElement:element fromPoint:m_cgPointInitial toPoint:m_cgPointCurrent];
        
        if(!CGRectEqualToRect(m_cgRectMarquee, CGRectZero))
            [element drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
        else
            [element drawHighlightWithTransformInContext:ctx :transform viewTransform:CGAffineTransformIdentity scale:scale];
        CGContextRestoreGState(ctx);
    }
    
    BOOL isCombine = NO;
    if (!singleSelection) {
        isCombine = YES;
    }
    if (singleSelection && [singleSelection isKindOfClass:[WDCompoundPath class]]) {
        isCombine = YES;
    }
    // if we're not transforming, draw filled anchors on all paths
    if (!m_bTransforming && isCombine) {
        for (WDElement *element in wdDrawingController.selectedObjects) {
            PSVecLayer *pVecLayer = [element layer].layerDelegate;
            if (![self judgeVectorElementNeedDraw:element]) {
                continue;
            }
            CGContextSaveGState(ctx);
            CGContextConcatCTM(ctx,[pVecLayer transform]);
            [element drawAnchorsWithViewTransform:ctx :CGAffineTransformIdentity scale:scale];
            CGContextRestoreGState(ctx);
        }
    }
    
    if ((!m_bTransforming || m_bTransformingNode) && !isCombine)
    {
        PSVecLayer *pVecLayer = [singleSelection layer].layerDelegate;
        if ([self judgeVectorElementNeedDraw:singleSelection]) {
            CGContextSaveGState(ctx);
            CGContextConcatCTM(ctx,[pVecLayer transform]);
            [singleSelection drawHandlesWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
            CGContextRestoreGState(ctx);
        }
        
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
    
    if(lastMouseMoveOnObject_)
        [lastMouseMoveOnObject_ renderInContext:ctx metaData:WDRenderingMetaDataMake(2.0, WDRenderOutlineOnly)];
    
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

- (void)drawToolExtra
{
    if(lastMouseMoveOnObject_)
        [self drawMoveMouseOnObjectExtra];
    
    [self drawSelectedObjectExtra];
    
    [super drawToolExtra];
//        [m_vectorTransformManager drawToolExtra];
}

#pragma mark - Layer Changed
- (void)layerAttributesChanged:(int)nLayerType
{
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    [wdDrawingController selectNone:nil];
//    
//    [[m_idDocument docView] setNeedsDisplay:YES];
}

-(void)checkCurrentLayerIsSupported
{
    return;
}

-(BOOL)showSelectionBoundaries
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    id activeLayer = [contents activeLayer];
    if([activeLayer layerFormat] == PS_VECTOR_LAYER)
        return NO;
    
    return YES;
    
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    return YES;
}

//#pragma mark - Tool Enter/Exit
//-(BOOL)enterTool
//{
//    [self showInfoView];
//    
//    
//    return [super enterTool];
//}
//
//-(BOOL)exitTool:(int)newTool
//{
//    return [super exitTool:newTool];
//}


-(void)showInfoView
{
    PSShowInfoPanel *showInfoPanel = [[[PSShowInfoPanel alloc] init] autorelease];
//    [showInfoPanel addMessageText:NSLocalizedString(@"Double-click could reset bezier control points", nil)];
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

//#pragma mark - resetCursorRects
//- (void)resetCursorRects
//{
//    if(m_enumTransfomType == Transform_NO)
//        [super resetCursorRects];
//    else
//        [m_vectorTransformManager resetCursorRects];
//}

-(BOOL)enterTool
{
    [super enterTool];
    
    return YES;
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{

    return [super validateMenuItem:menuItem];
}

@end
