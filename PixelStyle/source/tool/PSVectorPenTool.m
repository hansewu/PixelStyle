//
//  PSVectorPenTool.m
//  PixelStyle
//
//  Created by lchzh on 23/3/16.
//
//

#import "PSVectorPenTool.h"

#import "PSDocument.h"
#import "PSContent.h"
#import "PSTools.h"
#import "PSVecLayer.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSView.h"

#import "WDBezierNode.h"
#import "WDPath.h"
#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDCompoundPath.h"
#import "WDCurveFit.h"
#import "WDLayer.h"

#import "PSVectorPenOptions.h"
#import "PSShowInfoPanel.h"


#define kMaxError 10.0f
#define KMinDifferent 3

@implementation PSVectorPenTool

@synthesize replacementNode = replacementNode_;


- (int)toolId
{
    return kVectorPenTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Pen Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"P";
}

- (id)init
{
    self = [super init];
    if(self){
        m_nPenStyle = 0;
        
        replacementNode_ = nil;
        updatingOldNode_ = NO;
        oldNodeMode_ = nil;
        closingPath_ = NO;
        shouldResetFillTransform_ = NO;
        
        m_pathTemp = nil;
        pathStarted_ = NO;
        
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"pen-cursor"] hotSpot:NSMakePoint(1, 1)];
        
        if(m_strToolTips) {[m_strToolTips release]; m_strToolTips = nil;}
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@. %@.",NSLocalizedString(@"Double-Click could finish bezier path", nil), NSLocalizedString(@"Command+Ctrl - Close a bezier path", nil)];
    }
    return self;
}


- (void)fineMouseDownAt:(NSPoint)iwhere withEvent:(NSEvent *)event
{
    m_cgPointInit = NSPointToCGPoint(iwhere);
    m_bDragged = NO;

    //变换
        if(m_enumTransfomType != Transform_NO)
        {
            IntPoint point;
            point.x = iwhere.x - [[[m_idDocument contents] activeLayer] xoff];
            point.y = iwhere.y - [[[m_idDocument contents] activeLayer] yoff];
            [m_vectorTransformManager mouseDownAt:point withEvent:event];
            
            PSPickResultType pickType = [m_vectorTransformManager getPickType];
            if(pickType != PICK_NONE)
            {
                
                return;
            }
            else
            {
                [m_vectorTransformManager mouseUpAt:point withEvent:event];
            }
        }
    
    if(m_enumTransfomType != Transform_NO)
        [self setTransformType:Transform_NO];
    
    
    //绘制
    PSContent *contents = (PSContent *)[gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    m_nPenStyle = [(PSVectorPenOptions*)m_idOptions getPenStyle];
    
    switch (m_nPenStyle) {
        case 0:
        {
            PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
            CGAffineTransform transform = CGAffineTransformIdentity;
            if([layer layerFormat] == PS_VECTOR_LAYER && m_activePath)
            {
                PSVecLayer *layerVector = (PSVecLayer *)layer;
                transform = CGAffineTransformInvert([layerVector transform]);
            }

            
            CGPoint tap = iwhere;
            tap = CGPointApplyAffineTransform(tap, transform);
            
            updatingOldNode_ = NO;
            closingPath_ = NO;
            
            float xScale, yScale;
            xScale = [[m_idDocument contents] xscale];
            yScale = [[m_idDocument contents] yscale];
            float viewScale = xScale;
            
            if (m_activePath && WDDistance([m_activePath lastNode].anchorPoint, tap) < (25.0f / viewScale)) {
                if (event.clickCount == 2) {
                    if([(PSVectorPenOptions *)m_idOptions controlKeyEnable])
                        m_activePath.closed = YES;
                    m_activePath.displayNodes = nil;
                    m_activePath = nil;
                    self.replacementNode = nil;
                    [self setTransformType:Transform_Scale];
                } else {
                    self.replacementNode = [[m_activePath lastNode] chopOutHandle];
                    updatingOldNode_ = YES;
                    oldNodeMode_ = [m_activePath lastNode].reflectionMode;
                }
            } else if (m_activePath && WDDistance([m_activePath firstNode].anchorPoint, tap) < (25.0f / viewScale)) {
                oldNodeMode_ = [m_activePath firstNode].reflectionMode;
                self.replacementNode = [m_activePath firstNode];
                closingPath_ = YES;
                m_activePath.displayClosed = YES;
            } else {
                self.replacementNode = [WDBezierNode bezierNodeWithAnchorPoint:tap];
                self.replacementNode.selected = YES;
                
                if (m_activePath) {
                    [wdDrawingController deselectAllNodes];
                    NSMutableArray *displayNodes = [m_activePath.nodes mutableCopy];
                    
//                    WDBezierNode *tNode = [self.replacementNode transform:transform];
//                    tNode.selected = self.replacementNode.selected;
//                    self.replacementNode = tNode;
//                    [displayNodes addObject:tNode];
                    
                    [displayNodes addObject:self.replacementNode];
                    
                    m_activePath.displayNodes = displayNodes;
                } else {
                    WDPickResult *result = [wdDrawingController snappedPoint:iwhere viewScale:viewScale snapFlags:(kWDSnapNodes | kWDSnapSelectedOnly)];
                    
                    if (result.type == kWDAnchorPoint && result.nodePosition != kWDMiddleNode && [wdDrawingController isSelected:result.element]) {
                        WDPath *path = (WDPath *) result.element;
                        
                        if (result.nodePosition == kWDFirstNode) {
                            path.nodes = [path reversedNodes];
                            [path reversePathDirection];
                        }
                        
                        [wdDrawingController selectNone:nil];
                        m_activePath = path;
                        
                        updatingOldNode_ = YES;
                        oldNodeMode_ = [path lastNode].reflectionMode;
                        self.replacementNode = [[path lastNode] chopOutHandle];
                    } else {
                        [wdDrawingController selectNone:nil];
                        //wdDrawingController.tempDisplayNode = self.replacementNode;
                    }
                }
            }
            
        }
            break;
            
        case 1:
        {
            
        }
            
        case 2:
        {
            [wdDrawingController selectNone:nil];
            pathStarted_ = YES;
            
            m_pathTemp = [[WDPath alloc] init];
            //canvas.shapeUnderConstruction = m_pathTemp;
            
            [self fineMouseDraggedTo:iwhere withEvent:event];
            
        }
            break;
            
            
        default:
            break;
    }

    
    
    // we should only reset the active path's fill transform if it is the default fill transform for the shape
//    BOOL centered = [activePath.fill wantsCenteredFillTransform];
//    shouldResetFillTransform_ = activePath.fillTransform && [activePath.fillTransform isDefaultInRect:activePath.bounds centered:centered];
    
}


- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(!m_bDragged)
        if(fabs(where.x - m_cgPointInit.x) < KMinDifferent && (fabs(where.y - m_cgPointInit.y) < KMinDifferent)) return;
    
    m_bDragged = YES;
    
    //变换
   
        if(m_enumTransfomType != Transform_NO && ([m_vectorTransformManager getPickType] != PICK_NONE))
        {
            IntPoint point;
            point.x = where.x - [[[m_idDocument contents] activeLayer] xoff];
            point.y = where.y - [[[m_idDocument contents] activeLayer] yoff];
            [m_vectorTransformManager mouseDraggedTo:point withEvent:event];
            return;
        }
   
    
    //绘制
    switch (m_nPenStyle) {
        case 0:
        {
            PSContent *contents = (PSContent *)[gCurrentDocument contents];
            WDDrawingController *wdDrawingController = [contents wdDrawingController];
            
            PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
            CGAffineTransform transform = CGAffineTransformIdentity;
            if([layer layerFormat] == PS_VECTOR_LAYER && m_activePath)
            {
                PSVecLayer *layerVector = (PSVecLayer *)layer;
                transform = CGAffineTransformInvert([layerVector transform]);
            }
            
            CGPoint tap = where;
            tap = CGPointApplyAffineTransform(tap, transform);
            
            if (closingPath_) {
                WDBezierNodeReflectionMode mode = [(PSVectorPenOptions *)m_idOptions optionKeyEnable] ? WDIndependent : oldNodeMode_;
                self.replacementNode = [self.replacementNode setInPoint:tap reflectionMode:mode];
            } else {
                WDBezierNodeReflectionMode mode = [(PSVectorPenOptions *)m_idOptions optionKeyEnable] ? WDIndependent : (updatingOldNode_ ? oldNodeMode_ : WDReflect);
                self.replacementNode = [self.replacementNode moveControlHandle:kWDOutPoint toPoint:tap reflectionMode:mode];
            }
            
            if (m_activePath) {
                self.replacementNode.selected = YES;
                NSMutableArray *displayNodes = [m_activePath.nodes mutableCopy];
                
                if (updatingOldNode_) {
                    displayNodes[(displayNodes.count - 1)] = self.replacementNode;
                } else if (closingPath_) {
                    displayNodes[0] = self.replacementNode;
                } else {
//                    WDBezierNode *tNode = [self.replacementNode transform:transform];
//                    tNode.selected = self.replacementNode.selected;
//                    self.replacementNode = tNode;
//                    [displayNodes addObject:tNode];
                    
                    [displayNodes addObject:self.replacementNode];
                }
                
                m_activePath.displayNodes = displayNodes;
            } else {
                //wdDrawingController.tempDisplayNode = self.replacementNode;
            }

            
        }
            break;
            
        case 1:
        {
        }
        case 2:
        {
            [m_pathTemp.nodes addObject:[WDBezierNode bezierNodeWithAnchorPoint:where]];
        }
            break;

            
        default:
            break;
    }
    
    
    [[m_idDocument docView] setNeedsDisplay:YES];
    
}


- (void)fineMouseUpAt:(NSPoint)iwhere withEvent:(NSEvent *)theEvent
{
    //变换
    
        if(m_enumTransfomType != Transform_NO && ([m_vectorTransformManager getPickType] != PICK_NONE))
        {
            IntPoint point;
            point.x = iwhere.x - [[[m_idDocument contents] activeLayer] xoff];
            point.y = iwhere.y - [[[m_idDocument contents] activeLayer] yoff];
            [m_vectorTransformManager mouseUpAt:point withEvent:theEvent];
            
            if(m_bDragged) return;
            else
            {
                [self setTransformType:Transform_NO];
                [super fineMouseDownAt:iwhere withEvent:theEvent];
            }

        }
   
    
    //绘制
    PSContent *contents = (PSContent *)[gCurrentDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    BOOL closeShape = NO;
    if (m_nPenStyle == 2 || [(PSVectorPenOptions *)m_idOptions controlKeyEnable]) {
        closeShape = YES;
    }
    
    
    
    switch (m_nPenStyle) {
        case 0:
        {
            if ([(PSVectorPenOptions *)m_idOptions isNewLayerOptionEnable]) {
                if (m_activePath == nil && self.replacementNode && !closingPath_) {
                    [contents addVectorLayer:kActiveLayer];
                }
            }else{
                [super checkCurrentLayerIsSupported];
            }
            
            //[super checkCurrentLayerIsSupported];
            PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
            if([layer layerFormat] != PS_VECTOR_LAYER)  return;
            PSVecLayer *layerVector = (PSVecLayer *)layer;
            
            
            
            m_activePath.displayNodes = nil;
            m_activePath.displayClosed = NO;
            m_activePath.displayColor = nil;
            
            if (!m_activePath && self.replacementNode) {
                [wdDrawingController selectNode:self.replacementNode];
                m_activePath = [[WDPath alloc] initWithNode:self.replacementNode];
                
                wdDrawingController.tempDisplayNode = nil;
                
//                CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
//                [path transform:transform];
                
                [wdDrawingController selectObject:m_activePath];
                [layerVector addPathObject:m_activePath];
                
                
            } else if (self.replacementNode) {
                self.replacementNode.selected = NO;
                if (closingPath_) {
                    [m_activePath replaceFirstNodeWithNode:self.replacementNode];
                    m_activePath.closed = YES;
                    m_activePath = nil;
                    
                    [self setTransformType:Transform_Scale];
                } else if (updatingOldNode_) {
                    [m_activePath replaceLastNodeWithNode:self.replacementNode];
                } else {
                    [wdDrawingController selectNode:[m_activePath lastNode]];
                    
//                    CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
//                    WDBezierNode *tNode = [self.replacementNode transform:transform];
//                    tNode.selected = self.replacementNode.selected;
//                    self.replacementNode = tNode;
//                    [activePath addNode:tNode];
                    
                    [m_activePath addNode:self.replacementNode];
                }
                
                
                [wdDrawingController deselectAllNodes];
                [wdDrawingController selectNode:self.replacementNode];
                
            }
            
            m_activePath.fill = nil;
            m_activePath.fill = [wdDrawingController.propertyManager activeFillStyle];
            m_activePath.strokeStyle = [[wdDrawingController.propertyManager activeStrokeStyle] strokeStyleSansArrows];
            m_activePath.shadow = [wdDrawingController.propertyManager activeShadow];
            

            
            self.replacementNode = nil;
            
        }
            break;
            
        case 1:
        {
        }
        case 2:
        {
            if ([(PSVectorPenOptions *)m_idOptions isNewLayerOptionEnable]) {
                [contents addVectorLayer:kActiveLayer];
            }else{
                [super checkCurrentLayerIsSupported];
            }
            
            float scale = 1.0;
            if (pathStarted_ && [m_pathTemp.nodes count] > 1) {
                float maxError = (kMaxError / scale);
                
                //canvas.shapeUnderConstruction = nil;
                
                NSMutableArray *points = [NSMutableArray array];
                for (WDBezierNode *node in m_pathTemp.nodes) {
                    [points addObject:[NSValue valueWithPoint:node.anchorPoint]];
                }
                
                if (closeShape && m_pathTemp.nodes.count > 2) {
                    // we're drawing free form closed shapes... let's relax the error
                    maxError *= 5;
                    
                    // add the first point at the end to make sure we close
                    CGPoint first = [points[0] pointValue];
                    CGPoint last = [[points lastObject] pointValue];
                    
                    if (WDDistance(first, last) >= (maxError*2)) {
                        [points addObject:points[0]];
                    }
                }
                
                WDPath *smoothPath = [WDCurveFit smoothPathForPoints:points error:maxError attemptToClose:YES];
                
                if (smoothPath) {
                    smoothPath.fill = [wdDrawingController.propertyManager activeFillStyle];
                    smoothPath.strokeStyle = [wdDrawingController.propertyManager activeStrokeStyle];
                    //smoothPath.opacity = [[wdDrawingController.propertyManager defaultValueForProperty:WDOpacityProperty] floatValue];
                    smoothPath.shadow = [wdDrawingController.propertyManager activeShadow];
                    
                    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
                    if([layer layerFormat] != PS_VECTOR_LAYER)  return;
                    PSVecLayer *layerVector = (PSVecLayer *)layer;
                    CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
                    [smoothPath transform:transform];                    
                  
                    [wdDrawingController selectObject:smoothPath];
                    [layerVector addPathObject:smoothPath];
                    
                    [self setTransformType:Transform_Scale];
                }
            }
            
            pathStarted_ = NO;
            m_pathTemp = nil;

            
        }
            break;
            
            
        default:
            break;
    }

    [[m_idDocument docView] setNeedsDisplay:YES];
    
}

- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event    //where
{
//    if(m_enumTransfomType == Transform_NO)
//    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"pen-cursor"] hotSpot:NSMakePoint(1, 1)];
//    }
    [super mouseMoveTo:where withEvent:event];
    
    CGPoint pointInCanvas;
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    pointInCanvas.x = where.x / xScale;
    pointInCanvas.y = where.y / yScale;
    
    
    if(m_activePath)
    {
        self.replacementNode = [WDBezierNode bezierNodeWithAnchorPoint:pointInCanvas];
        self.replacementNode.selected = NO;
        
        PSContent *contents = (PSContent *)[gCurrentDocument contents];
        
        WDDrawingController *wdDrawingController = [contents wdDrawingController];
        [wdDrawingController deselectAllNodes];
        NSMutableArray *displayNodes = [m_activePath.nodes mutableCopy];
                
        [displayNodes addObject:self.replacementNode];
        m_activePath.displayNodes = displayNodes;
        
    }
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (CGPathRef) computePathRef:(NSArray*)nodes isClosed:(BOOL)closed
{
    // construct the path ref from the node list
    WDBezierNode                *prevNode = nil;
    BOOL                        firstTime = YES;
    
    CGMutablePathRef pathRef_ = CGPathCreateMutable();
    
    for (WDBezierNode *node in nodes) {
        if (firstTime) {
            CGPathMoveToPoint(pathRef_, NULL, node.anchorPoint.x, node.anchorPoint.y);
            firstTime = NO;
        } else if ([prevNode hasOutPoint] || [node hasInPoint]) {
            CGPathAddCurveToPoint(pathRef_, NULL, prevNode.outPoint.x, prevNode.outPoint.y,
                                  node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        } else {
            CGPathAddLineToPoint(pathRef_, NULL, node.anchorPoint.x, node.anchorPoint.y);
        }
        prevNode = node;
    }
    
    if (closed && prevNode) {
        WDBezierNode *node = nodes[0];
        CGPathAddCurveToPoint(pathRef_, NULL, prevNode.outPoint.x, prevNode.outPoint.y,
                              node.inPoint.x, node.inPoint.y, node.anchorPoint.x, node.anchorPoint.y);
        
        CGPathCloseSubpath(pathRef_);
    }
    
    return pathRef_;
}




- (void)drawToolExtra
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if( curToolIndex != [self toolId]) return;
    //NSLog(@"drawToolExtra");
    
    switch (m_nPenStyle) {
        case 0:
        {
            [self drawToolExtraForPen];
        }
            break;
        case 1:
        {
        }

        case 2:
        {
            [self drawToolExtraForFreePen];
        }
            break;

            
        default:
            break;
    }    
    
    [super drawToolExtra];
}


- (void)drawToolExtraForPen
{
    if (m_activePath)
        [self drawAuxiliaryLine];
    else
        [self drawSelectedObjectExtra];
}


- (void)drawToolExtraForFreePen
{
    if (m_pathTemp)
        [self drawAuxiliaryLine];
    else
        [self drawSelectedObjectExtra];
}

-(void)drawAuxiliaryLine
{
    //NSLog(@"drawAuxiliaryLine %d %d", [m_activePath.nodes count], [m_activePath.displayNodes count]);
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if( curToolIndex != [self toolId]) return;
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    //  assert(ctx);
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);
    
//    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
    float scale = [[m_idDocument docView] zoom];
    switch (m_nPenStyle)
    {
        case 0:
        {
            if (![self judgeVectorLayerContainsElement:m_activePath]) {
                m_activePath = nil;
                CGContextRestoreGState(ctx);
                return;
            }
            PSVecLayer *pVecLayer = [m_activePath layer].layerDelegate;
            
            if (pVecLayer == NULL) {
                [m_activePath drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
                [m_activePath drawHandlesWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
            }else{
                if(pVecLayer && [pVecLayer visible])
                {
                    CGContextConcatCTM(ctx,[pVecLayer transform]);
                    
                    [m_activePath drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
                    [m_activePath drawHandlesWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
                }
            }
            
        }
            break;
        case 1:
        case 2:
        {
            [m_pathTemp drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
        }
            break;
        default:
            break;
    }

    CGContextRestoreGState(ctx);
}




- (void)layerAttributesChanged:(int)nLayerType
{
    if (m_activePath) {
        [m_activePath.displayNodes removeAllObjects];
        m_activePath.displayNodes = nil;
        m_activePath = nil;
    }
}

-(void)checkCurrentLayerIsSupported
{
    return;
}

#pragma mark - Tool Enter/Exit
//-(BOOL)enterTool
//{
//    [self showInfoView];
//    return [super enterTool];
//}

-(BOOL)exitTool:(int)newTool
{
    if (m_activePath) {
        [m_activePath.displayNodes removeAllObjects];
        m_activePath.displayNodes = nil;
        m_activePath = nil;
    }
    return [super exitTool:newTool];
}

-(void)showInfoView
{
    PSShowInfoPanel *showInfoPanel = [[[PSShowInfoPanel alloc] init] autorelease];
    [showInfoPanel addMessageText:NSLocalizedString(@"Double-Click could finish bezier path", nil)];
    [showInfoPanel addMessageText:NSLocalizedString(@"Command+Ctrl - Close a bezier path", nil)];
    [showInfoPanel setAutoHiddenDelay:1.5];
    [showInfoPanel showPanel:NSZeroRect];
}

- (BOOL)deleteKeyPressed
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_VECTOR_LAYER)  return NO;
    if (m_activePath) {
        if ([m_activePath.nodes count] == 1) {
            PSVecLayer *layerVector = (PSVecLayer *)layer;
            [layerVector removePathObject:m_activePath];
            [m_activePath.displayNodes removeAllObjects];
            m_activePath.displayNodes = nil;
            m_activePath = nil;
            return YES;
        }
        if ([m_activePath.nodes count] > 1)
        {
            NSMutableArray *nodes = [m_activePath.nodes mutableCopy];
            [nodes removeLastObject];
            m_activePath.nodes = nodes;
            if (m_activePath.displayNodes && [m_activePath.displayNodes count] > 0) {
                NSMutableArray *temp = [m_activePath.nodes mutableCopy];
                [temp addObject:[m_activePath.displayNodes lastObject]];
                [m_activePath.displayNodes removeAllObjects];
                m_activePath.displayNodes = temp;                
            }
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)enterKeyPressed
{
    if(m_nPenStyle == 0){
        m_activePath.displayNodes = nil;
        m_activePath = nil;
        [self setTransformType:Transform_Scale];
        self.replacementNode = nil;
        
        [[m_idDocument docView] setNeedsDisplay:YES];
        return YES;
    }
    return NO;
}


- (BOOL)stopCurrentOperation
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_VECTOR_LAYER)  return NO;
    if (m_activePath) {
        if ([m_activePath.nodes count] > 0) {
            PSVecLayer *layerVector = (PSVecLayer *)layer;
            [layerVector removePathObject:m_activePath];
            [m_activePath.displayNodes removeAllObjects];
            m_activePath.displayNodes = nil;
            m_activePath = nil;
            return YES;
        }
    }
    
    return NO;
}

@end
