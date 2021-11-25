//
//  PSVectorEraserTool.m
//  PixelStyle
//
//  Created by lchzh on 31/3/16.
//
//

#import "PSVectorEraserTool.h"
#import "PSVectorEraserOptions.h"

#import "WDLayer.h"
#import "PSView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSTools.h"
#import "PSVecLayer.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"

#import "WDBezierNode.h"
#import "WDPath.h"
#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDCompoundPath.h"
#import "WDCurveFit.h"
#import "WDColor.h"



#define kMaxError 10.0f
#define KMinDifferent 3

@implementation PSVectorEraserTool


- (int)toolId
{
    return kVectorEraserTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Path Eraser Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"E";
}

- (id)init
{
    self = [super init];
    if(self){
        m_pathTemp = nil;
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eraser-cursor"] hotSpot:NSMakePoint(2, 12)];
        
        if(m_strToolTips)   {   [m_strToolTips release];    m_strToolTips = nil;}
    }
    return self;
}

- (BOOL)isFineTool
{
    return YES;
}

- (void)fineMouseDownAt:(NSPoint)iwhere withEvent:(NSEvent *)event
{
    m_cgPointInit = NSPointToCGPoint(iwhere);
    m_bDragged = NO;
    
    m_pathTemp = [[WDPath alloc] initWithNode:[WDBezierNode bezierNodeWithAnchorPoint:iwhere]];
    NSUInteger eraserSize = [(PSVectorEraserOptions *)m_idOptions getEraserSize];
    m_pathTemp.strokeStyle = [WDStrokeStyle strokeStyleWithWidth:eraserSize cap:kCGLineCapRound
                                                           join:kCGLineJoinRound
                                                          color:[WDColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5]
                                                    dashPattern:nil];
    //canvas.eraserPath = m_pathTemp;
    
}


- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(!m_bDragged)
        if(fabs(where.x - m_cgPointInit.x) < KMinDifferent && (fabs(where.y - m_cgPointInit.y) < KMinDifferent)) return;
    m_bDragged = YES;
    
    if (WDDistance(where, [m_pathTemp lastNode].anchorPoint) < (3.0f / 1.0)) {
        return;
    }
    
    [m_pathTemp.nodes addObject:[WDBezierNode bezierNodeWithAnchorPoint:where]];
    [m_pathTemp invalidatePath];
    //canvas.eraserPath = m_pathTemp;
    
    //[canvas invalidateSelectionView];
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}


- (void)fineMouseUpAt:(NSPoint)iwhere withEvent:(NSEvent *)theEvent
{
    if(!m_bDragged)
    {
        [super fineMouseDownAt:iwhere withEvent:theEvent];
        [super fineMouseUpAt:iwhere withEvent:theEvent];
    }
    
    //canvas.eraserPath = nil;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    
    if (m_pathTemp && [m_pathTemp.nodes count] > 1) {
        NSMutableArray *points = [NSMutableArray array];
        for (WDBezierNode *node in m_pathTemp.nodes) {
            [points addObject:[NSValue valueWithPoint:node.anchorPoint]];
        }
        
        WDPath *smoothPath = [WDCurveFit smoothPathForPoints:points error:(kMaxError / 1.0) attemptToClose:NO];
        NSUInteger eraserSize = [(PSVectorEraserOptions *)m_idOptions getEraserSize];
        if (smoothPath) {
            smoothPath.strokeStyle = [WDStrokeStyle strokeStyleWithWidth:eraserSize
                                                                     cap:kCGLineCapRound
                                                                    join:kCGLineJoinRound
                                                                   color:[WDColor blackColor]
                                                             dashPattern:nil];
            WDAbstractPath *erasePath = [smoothPath outlineStroke];
            
            //[wdDrawingController eraseWithPath:erasePath];
            [self eraseWithPath:erasePath];
        }
    }
    
    m_pathTemp = nil;
    
    [[m_idDocument docView] setNeedsDisplay:YES];
    
}

- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event    //where
{
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"eraser-cursor"] hotSpot:NSMakePoint(2, 12)];
    [super mouseMoveTo:where withEvent:event];
}

- (void) eraseWithPath:(WDAbstractPath *)erasePath
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    
    NSMutableArray  *objectsToErase = [NSMutableArray array];
    
    if (wdDrawingController.selectedObjects.count != 0) {
        for (WDElement *element in [wdDrawingController orderedSelectedObjects]) {
            PSVecLayer *pVecLayer = [element layer].layerDelegate;
            if (![self judgeVectorElementNeedDraw:element]) {
                continue;
            }
            CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
            WDAbstractPath *tansformPath = [erasePath copyWithZone:nil];
            [tansformPath transform:transform];
            if ([element isErasable] && CGRectIntersectsRect(tansformPath.bounds, element.bounds)) {
                [objectsToErase addObject:element];
            }
        }
    } else {
//        NSArray *layers = drawing_.layers;
//        
//        if (drawing_.isolateActiveLayer) {
//            layers = @[drawing_.activeLayer];
//        }
//        
//        for (WDLayer *layer in layers) {
//            if (layer.locked || layer.hidden) {
//                continue;
//            }
//            
//            for (WDElement *element in layer.elements) {
//                if ([element isErasable] && CGRectIntersectsRect(erasePath.bounds, element.bounds)) {
//                    [objectsToErase addObject:element];
//                }
//            }
//        }
    }
    
    for (WDAbstractPath *ap in objectsToErase) {
        
        PSVecLayer *pVecLayer = [ap layer].layerDelegate;
        if (![self judgeVectorElementNeedDraw:ap]) {
            continue;
        }
        CGAffineTransform transform = CGAffineTransformInvert([pVecLayer transform]);
        WDAbstractPath *tansformPath = [erasePath copyWithZone:nil];
        [tansformPath transform:transform];
        NSArray *result = [ap erase:tansformPath];
        
        //NSArray *result = [ap erase:erasePath];
        
        // if there's anything left, add it to the layer
        if (result) {
            for (WDAbstractPath *resultPath in result) {
                [ap.layer insertObject:resultPath above:ap];
            }
        }
        
        if ([wdDrawingController isSelectedOrSubelementIsSelected:ap]) {
            [wdDrawingController deselectObjectAndSubelements:ap];
            
            if (result) {
                [wdDrawingController selectObjects:result];
            }
        }
        
        [ap.layer removeObject:ap];
    }
}

#pragma mark - Draw Extras


- (void)drawToolExtra
{
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if( curToolIndex != [self toolId]) return;
    
    if(m_pathTemp)
        [self drawAuxiliaryLine];
    
//    [self drawSelectedObjectExtra];
    
    [super drawToolExtra];
}

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
    
    float scale = [[m_idDocument docView] zoom];
    //    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
    
    
//    WDElement           *singleSelection = [wdDrawingController singleSelection];
    // draw all object outlines, using the selection transform if applicable
    for (WDElement *element in wdDrawingController.selectedObjects) //选中之后的移动
    {
        PSVecLayer *pVecLayer = [element layer].layerDelegate;
        
        if (![self judgeVectorElementNeedDraw:element]) {
            continue;
        }
        
        
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx,[pVecLayer transform]);
        
        [element drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
        CGContextRestoreGState(ctx);
    }
    
//    BOOL isCombine = NO;
//    if (!singleSelection) {
//        isCombine = YES;
//    }
//    if (singleSelection && [singleSelection isKindOfClass:[WDCompoundPath class]]) {
//        isCombine = YES;
//    }
    // if we're not transforming, draw filled anchors on all paths
//    if (!m_bTransforming && isCombine) {
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
//    }
    
//    if ((!m_bTransforming || m_bTransformingNode) && !isCombine)
//    {
//        PSVecLayer *pVecLayer = [singleSelection layer].layerDelegate;
//        if ([self judgeVectorElementNeedDraw:singleSelection]) {
//            CGContextSaveGState(ctx);
//            CGContextConcatCTM(ctx,[pVecLayer transform]);
//            [singleSelection drawHandlesWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
//            CGContextRestoreGState(ctx);
//        }
//        
//    }
    
    CGContextRestoreGState(ctx);
}


-(void)drawAuxiliaryLine
{
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);
    if (m_pathTemp)
        [m_pathTemp renderInContext:ctx metaData:WDRenderingMetaDataMake(1.0, WDRenderDefault)];
    CGContextRestoreGState(ctx);
}


-(void)checkCurrentLayerIsSupported
{
    return;
}


@end
