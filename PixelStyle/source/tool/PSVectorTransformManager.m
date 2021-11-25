//
//  PSVectorTransformManager.m
//  PixelStyle
//
//  Created by wyl on 16/3/29.
//
//

#import "PSVectorTransformManager.h"
#import "PSView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSShadowView.h"
#import "PSVecLayer.h"
#import "PSTools.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "AbstractTool.h"

#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDLayer.h"
#import "WDPickResult.h"

#define DIS_ROTATE_UI 40

typedef struct
{
    BOOL leftValid;
    BOOL rightValid;
    BOOL topValid;
    BOOL bottumValid;
    
}VALID_EDGE_INFO;

@implementation PSVectorTransformManager


- (id)initWithDocument:(id)document
{
    self = [super init];
    
    m_idDocument = document;
    
    m_enumTransformTypeInit = Transform_NO;
    
    m_bTransfoming = NO;
    
    m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    
    
    curLr = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"scale-lr"] hotSpot:NSMakePoint(8, 8)];
    curUd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"scale-ud"] hotSpot:NSMakePoint(8, 8)];
    curUrdl = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"scale-urdl"] hotSpot:NSMakePoint(8, 8)];
    curUldr = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"scale-uldr"] hotSpot:NSMakePoint(8, 8)];
    curMoveCenter = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-center"] hotSpot:NSMakePoint(1, 1)];
    curMove = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"move-total"] hotSpot:NSMakePoint(1, 1)];
    curRotate = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"rotate-cursor"] hotSpot:NSMakePoint(8, 8)];
    curSkewLr = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"skew-lr"] hotSpot:NSMakePoint(1, 1)];
    curSkewUd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"skew-ud"] hotSpot:NSMakePoint(1, 1)];
    curSkewUrdl = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"skew-urdl"] hotSpot:NSMakePoint(1, 1)];
    curSkewUldr = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"skew-uldr"] hotSpot:NSMakePoint(1, 1)];
    curSkewCorner = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"skew-corner"] hotSpot:NSMakePoint(1, 1)];
    
    for(int i=0; i<8; i++)
    {
        NSString *stringImg = [NSString stringWithFormat:@"Rotate%d", i ];
        curRotate8[i] = [[NSCursor alloc] initWithImage:[NSImage imageNamed:stringImg] hotSpot:NSMakePoint(8, 8)];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawVectorToolExtraExtent:) name:@"DRAWTOOLEXTRAEXTENT" object:nil];
 
    CGRect rectBoundsInCanvas = CGRectMake(0, 0, 3, 3);
    
    for (int i = 0; i < 5; i++)
        m_pointsInit[i] = [self getAffineDesPointAtIndex:i InRect:rectBoundsInCanvas];
    
    for (int i = 0; i < 5; i++)
        m_pointsCur[i] = m_pointsInit[i];
 
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(curLr) {[curLr release];curLr = nil;}
    if(curUd) {[curUd release];curUd = nil;}
    if(curUrdl) {[curUrdl release];curUrdl = nil;}
    if(curUldr) {[curUldr release];curUldr = nil;}
    if(curMoveCenter) {[curMoveCenter release];curMoveCenter = nil;}
    if(curMove) {[curMove release];curMove = nil;}
    if(curRotate) {[curRotate release];curRotate = nil;}
    if(curSkewLr) {[curSkewLr release];curSkewLr = nil;}
    if(curSkewUd) {[curSkewUd release];curSkewUd = nil;}
    if(curSkewUrdl) {[curSkewUrdl release];curSkewUrdl = nil;}
    if(curSkewUldr) {[curSkewUldr release];curSkewUldr = nil;}
    if(curSkewCorner) {[curSkewCorner release];curSkewCorner = nil;}
    if(m_curNormal) {[m_curNormal release];m_curNormal = nil;}
    if(m_cursor) {[m_cursor release];m_cursor = nil;}
    
    for(int i = 0; i < 8; i++)
    {
        [curRotate8[i] release]; curRotate8[i] = nil;
    }
    
    [super dealloc];
}

- (void)setTransformStatus:(TransformType)nTransformState
{
    if(m_enumTransformTypeInit == Transform_NO || (nTransformState == Transform_NO))
    {
        [[m_idDocument docView] setNeedsDisplay:YES];
        
        if ([NSDate timeIntervalSinceReferenceDate] - m_lastRefreshTime > 0.1)
        {
            NSArray *arrSubViews = [[[m_idDocument scrollView] superview] subviews];
            for(NSView *view in arrSubViews)
            {
                if([view isKindOfClass:[PSShadowView class]])
                {
                    [view setNeedsDisplay:YES];
                    break;
                }
            }
            
            m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
        }

    }
    if(m_enumTransformTypeInit == Transform_NO && nTransformState != Transform_NO)  //wzq
        [self initialAffineInfo];
    
    m_enumTransformTypeInit = nTransformState;
}

- (PSPickResultType)getPickType
{
    return m_enumPickType;
}

#pragma mark - Mouse Events
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    PSContent *contents = [m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if([wdDrawingController.selectedObjects count] == 0)
    {
        m_bTransfoming = NO;
        return;
    }
    
    // Record the inital point for dragging
    m_pointInitial.x = where.x + [[[m_idDocument contents] activeLayer] xoff];
    m_pointInitial.y = where.y + [[[m_idDocument contents] activeLayer] yoff];
    
    //judge point position

    m_enumPickType = [self objectPickType:m_pointInitial InPointsBoundaries:m_pointsInit];

    
    m_enumTransformType = m_enumTransformTypeInit;
    if (m_enumPickType == PICK_INNER)                   m_enumTransformType = Transform_Move;
    else if (m_enumPickType == PICK_CENTER)             m_enumTransformType = Transform_MoveCenter;
    
  //  if (m_enumTransformType != Transform_MoveCenter) m_bTransfoming = YES;
}

- (VALID_EDGE_INFO)getAutoAlignValidEdgeInfo:(PSPickResultType)enumPickType
{
    VALID_EDGE_INFO validEdgeInfo;
    validEdgeInfo.leftValid = YES;
    validEdgeInfo.rightValid = YES;
    validEdgeInfo.topValid = YES;
    validEdgeInfo.bottumValid = YES;
    switch (enumPickType) {
        case PICK_TOPLEFT:{
            validEdgeInfo.rightValid = NO;
            validEdgeInfo.bottumValid = NO;
        }
            break;
        case PICK_TOP:{
            validEdgeInfo.bottumValid = NO;
        }
            break;
        case PICK_TOPRIGHT:{
            validEdgeInfo.leftValid = NO;
            validEdgeInfo.bottumValid = NO;
        }
            break;
        case PICK_RIGHT:{
            validEdgeInfo.leftValid = NO;
        }
            break;
        case PICK_BOTTOMRIGHT:{
            validEdgeInfo.leftValid = NO;
            validEdgeInfo.topValid = NO;
        }
            break;
        case PICK_BOTTOM:{
            validEdgeInfo.topValid = NO;
        }
            break;
        case PICK_BOTTOMLEFT:{
            validEdgeInfo.rightValid = NO;
            validEdgeInfo.topValid = NO;
        }
            break;
        case PICK_LEFT:{
            validEdgeInfo.rightValid = NO;
        }
            break;
        case PICK_CENTER:{
        }
            break;
        
        default:
            break;
    }
    
    return validEdgeInfo;
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    PSContent *contents = [m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if([wdDrawingController.selectedObjects count] == 0)
        return;
    
    m_bTransfoming = YES;
    // Record the inital point for dragging
    CGPoint curPointInCanvas;
    curPointInCanvas.x = where.x + [[[m_idDocument contents] activeLayer] xoff];       //转换成画布
    curPointInCanvas.y = where.y + [[[m_idDocument contents] activeLayer] yoff];
    
    CGPoint pointOffset = CGPointMake(curPointInCanvas.x - m_pointInitial.x, curPointInCanvas.y - m_pointInitial.y);
    // Vary behaviour based on function
    if(m_enumPickType == PICK_ROTATE)
    {
        CGAffineTransform transformRotate = [self computeTransform:m_pointInitial toPoint:curPointInCanvas center:m_pointsInit[4]];
        
        for (int i = 0; i < 4; i++)
            m_pointsCur[i] = CGPointApplyAffineTransform(m_pointsInit[i], transformRotate);
        
        [[m_idDocument docView] setNeedsDisplay:YES];
        return;
    }
    
    
    switch (m_enumTransformType)
    {
        case Transform_Move:
        {
            int disX = 0;
            int disY = 0;
            
            NSPoint pointsCur[5];
            for (int i = 0; i < 5; i++)
                pointsCur[i] = m_pointsInit[i];
            
            [self moveTransformPointsWithOffsets:m_pointsInit offset:pointOffset points:pointsCur];
            VALID_EDGE_INFO validEdgeInfo;
            validEdgeInfo.leftValid = YES;
            validEdgeInfo.rightValid = YES;
            validEdgeInfo.topValid = YES;
            validEdgeInfo.bottumValid = YES;
            BOOL align = [self judgeLayersNeedAutoAlign:pointsCur disX:&disX disY:&disY validEdgeInfo:validEdgeInfo];
            if (align) {
                pointOffset.x += disX;
                pointOffset.y += disY;
            }
            [self moveTransformPointsWithOffsets:m_pointsInit offset:pointOffset points:m_pointsCur];
            
        }
            
            break;
        case Transform_Rotate:
        {
            if (m_enumPickType != PICK_INNER)
            {
                CGAffineTransform transformRotate = [self computeTransform:m_pointInitial toPoint:curPointInCanvas center:m_pointsInit[4]];
                
                for (int i = 0; i < 4; i++)
                    m_pointsCur[i] = CGPointApplyAffineTransform(m_pointsInit[i], transformRotate);
            }
        }
            
            break;
        case Transform_Scale:
        {
            int disX = 0;
            int disY = 0;
            
            NSPoint pointsCur[5];
            for (int i = 0; i < 5; i++)
                pointsCur[i] = m_pointsInit[i];
            
            [self scaleTransformPointsWithOffsets:m_pointsInit offset:pointOffset InPickResultType:m_enumPickType points:pointsCur];
            
            VALID_EDGE_INFO validEdgeInfo = [self getAutoAlignValidEdgeInfo:m_enumPickType];
            
            BOOL align = [self judgeLayersNeedAutoAlign:pointsCur disX:&disX disY:&disY validEdgeInfo:validEdgeInfo];
            if (align) {
                pointOffset.x += disX;
                pointOffset.y += disY;
            }
            
            [self scaleTransformPointsWithOffsets:m_pointsInit offset:pointOffset InPickResultType:m_enumPickType points:m_pointsCur];
        }
            break;
        case Transform_Skew:
        {
            [self skewTransformPointsWithOffsets:m_pointsInit offset:pointOffset InPickResultType:m_enumPickType points:m_pointsCur];
        }
            break;
            
        case Transform_Perspective:
        {
            [self perspectiveTransformPointsWithOffsets:m_pointsInit offset:pointOffset InPickResultType:m_enumPickType points:m_pointsCur];
        }
            break;
            
        case Transform_MoveCenter:
        {
            m_pointsCur[4] = NSMakePoint(m_pointsInit[4].x + pointOffset.x, m_pointsInit[4].y + pointOffset.y);
            break;
        }
        default:
            break;
    }
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}



- (BOOL)judgeLayersNeedAutoAlign:(CGPoint *)pointsCur disX:(int*)disX disY:(int*)disY validEdgeInfo:(VALID_EDGE_INFO)validEdgeInfo
{
    BOOL align = NO;
    
    
    int left = pointsCur[0].x;
    int right = pointsCur[2].x;
    int top = pointsCur[0].y;
    int bottum = pointsCur[2].y;
    for (int i = 0; i < 4; i++) {
        if (pointsCur[i].x < left) {
            left = pointsCur[i].x;
        }
        if (pointsCur[i].x > right) {
            right = pointsCur[i].x;
        }
        if (pointsCur[i].y < top) {
            top = pointsCur[i].y;
        }
        if (pointsCur[i].y > bottum) {
            bottum = pointsCur[i].y;
        }
    }
    
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    int threshold = 10;
    int minDx = threshold;
    int minDy = threshold;
    
    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
        if([layer layerFormat] != PS_VECTOR_LAYER)
            continue;
        
        PSVecLayer *layerVector = (PSVecLayer *)layer;
        
        
        int left1 = 0;
        int right1 = 0;
        int top1 = 0;
        int bottum1 = 0;
        
        WDLayer *wdLayer = [layerVector getLayer];
        for (WDElement *el in wdLayer.elements)
        {
            if ([wdDrawingController isSelectedOrSubelementIsSelected:el]) {
                continue;
            }
            NSRect bunds = el.bounds;
            left1 = bunds.origin.x;
            right1 = bunds.origin.x + bunds.size.width - 1;
            top1 = bunds.origin.y;
            bottum1 = bunds.origin.y + bunds.size.height - 1;
            
            //重合
            if (abs(left - left1) < threshold && abs(left - left1) < abs(minDx) && validEdgeInfo.leftValid) {
                minDx = left - left1;
                align = YES;
            }
            if (abs(top - top1) < threshold && abs(top - top1) < abs(minDy) && validEdgeInfo.topValid) {
                minDy = top - top1;
                align = YES;
            }
            if (abs(right - right1) < threshold && abs(right - right1) < abs(minDx) && validEdgeInfo.rightValid) {
                minDx = right - right1;
                align = YES;
            }
            if (abs(bottum - bottum1) < threshold && abs(bottum - bottum1) < abs(minDy) && validEdgeInfo.bottumValid) {
                minDy = bottum - bottum1;
                align = YES;
            }
            
            //并列
            if (abs(left - right1) < threshold && abs(left - right1) < abs(minDx) && validEdgeInfo.leftValid) {
                minDx = left - right1;
                align = YES;
            }
            if (abs(top - bottum1) < threshold && abs(top - bottum1) < abs(minDy) && validEdgeInfo.topValid) {
                minDy = top - bottum1;
                align = YES;
            }
            if (abs(right - left1) < threshold && abs(right - left1) < abs(minDx) && validEdgeInfo.rightValid) {
                minDx = right - left1;
                align = YES;
            }
            if (abs(bottum - top1) < threshold && abs(bottum - top1) < abs(minDy) && validEdgeInfo.bottumValid) {
                minDy = bottum - top1;
                align = YES;
            }
        }
    }
    
    
    if (abs(minDx) < threshold) {
        *disX = -minDx;
    }
    if (abs(minDy) < threshold) {
        *disY = -minDy;
    }
    
    return align;

    
}

//- (BOOL)judgeLayersNeedAutoAlign:(CGPoint *)pointsCur disX:(int*)disX disY:(int*)disY
//{
//    BOOL align = NO;
//    
//    
//    
//    int left = pointsCur[0].x;
//    int right = pointsCur[2].x;
//    int top = pointsCur[0].y;
//    int bottum = pointsCur[2].y;
//    for (int i = 0; i < 4; i++) {
//        if (pointsCur[i].x < left) {
//            left = pointsCur[i].x;
//        }
//        if (pointsCur[i].x > right) {
//            right = pointsCur[i].x;
//        }
//        if (pointsCur[i].y < top) {
//            top = pointsCur[i].y;
//        }
//        if (pointsCur[i].y > bottum) {
//            bottum = pointsCur[i].y;
//        }
//    }
//    
//    
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    
//    int threshold = 10;
//    int minDx = threshold;
//    int minDy = threshold;
//    
//    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
//    {
//        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
//        if([layer layerFormat] != PS_VECTOR_LAYER)
//            continue;
//        
//        PSVecLayer *layerVector = (PSVecLayer *)layer;
//        
//        
//        int left1 = 0;
//        int right1 = 0;
//        int top1 = 0;
//        int bottum1 = 0;
//        
//        WDLayer *wdLayer = [layerVector getLayer];
//        for (WDElement *el in wdLayer.elements)
//        {
//            if ([wdDrawingController isSelectedOrSubelementIsSelected:el]) {
//                continue;
//            }
//            NSRect bunds = el.bounds;
//            left1 = bunds.origin.x;
//            right1 = bunds.origin.x + bunds.size.width - 1;
//            top1 = bunds.origin.y;
//            bottum1 = bunds.origin.y + bunds.size.height - 1;
//            
//            //重合
//            if (abs(left - left1) < threshold && abs(left - left1) < abs(minDx)) {
//                minDx = left - left1;
//                align = YES;
//            }
//            if (abs(top - top1) < threshold && abs(top - top1) < abs(minDy)) {
//                minDy = top - top1;
//                align = YES;
//            }
//            if (abs(right - right1) < threshold && abs(right - right1) < abs(minDx)) {
//                minDx = right - right1;
//                align = YES;
//            }
//            if (abs(bottum - bottum1) < threshold && abs(bottum - bottum1) < abs(minDy)) {
//                minDy = bottum - bottum1;
//                align = YES;
//            }
//            
//            //并列
//            if (abs(left - right1) < threshold && abs(left - right1) < abs(minDx)) {
//                minDx = left - right1;
//                align = YES;
//            }
//            if (abs(top - bottum1) < threshold && abs(top - bottum1) < abs(minDy)) {
//                minDy = top - bottum1;
//                align = YES;
//            }
//            if (abs(right - left1) < threshold && abs(right - left1) < abs(minDx)) {
//                minDx = right - left1;
//                align = YES;
//            }
//            if (abs(bottum - top1) < threshold && abs(bottum - top1) < abs(minDy)) {
//                minDy = bottum - top1;
//                align = YES;
//            }
//        }
//    }
//    
//    
//    if (abs(minDx) < threshold) {
//        *disX = -minDx;
//    }
//    if (abs(minDy) < threshold) {
//        *disY = -minDy;
//    }
//    
//    return align;
//    
//    
//}

//- (BOOL)judgeLayersNeedAutoAlignDeltax:(int)deltax deltay:(int)deltay newx:(int*)newx newy:(int*)newy
//{
//    BOOL align = NO;
//    
//    int leftFrom = m_pointsInit[0].x;
//    int rightFrom = m_pointsInit[2].x;
//    int topFrom = m_pointsInit[0].y;
//    int bottumFrom = m_pointsInit[2].y;
//    for (int i = 0; i < 4; i++) {
//        if (m_pointsInit[i].x < leftFrom) {
//            leftFrom = m_pointsInit[i].x;
//        }
//        if (m_pointsInit[i].x > rightFrom) {
//            rightFrom = m_pointsInit[i].x;
//        }
//        if (m_pointsInit[i].y < topFrom) {
//            topFrom = m_pointsInit[i].y;
//        }
//        if (m_pointsInit[i].y > bottumFrom) {
//            bottumFrom = m_pointsInit[i].y;
//        }
//    }
//    
//    int left = leftFrom + deltax;
//    int right = rightFrom + deltax;
//    int top = topFrom + deltay;
//    int bottum = bottumFrom + deltay;
//    
//    
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    
//    int threshold = 5;
//    int minDx = threshold;
//    int minDy = threshold;
//    
//    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
//    {
//        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
//        if([layer layerFormat] != PS_VECTOR_LAYER)
//            continue;
//        
//        PSVecLayer *layerVector = (PSVecLayer *)layer;
//        
//        
//        int left1 = 0;
//        int right1 = 0;
//        int top1 = 0;
//        int bottum1 = 0;
//        
//        WDLayer *wdLayer = [layerVector getLayer];
//        for (WDElement *el in wdLayer.elements)
//        {
//            if ([wdDrawingController isSelectedOrSubelementIsSelected:el]) {
//                continue;
//            }
//            NSRect bunds = el.bounds;
//            left1 = bunds.origin.x;
//            right1 = bunds.origin.x + bunds.size.width - 1;
//            top1 = bunds.origin.y;
//            bottum1 = bunds.origin.y + bunds.size.height - 1;
//            
//            //重合
//            if (abs(left - left1) < threshold && abs(left - left1) < minDx) {
//                *newx = left1 - leftFrom;
//                minDx = abs(left - left1);
//                align = YES;
//            }
//            if (abs(top - top1) < threshold && abs(top - top1) < minDy) {
//                *newy = top1 - topFrom;
//                minDy = abs(top - top1);
//                align = YES;
//            }
//            if (abs(right - right1) < threshold && abs(right - right1) < minDx) {
//                *newx = right1 - rightFrom;
//                minDx = abs(right - right1);
//                align = YES;
//            }
//            if (abs(bottum - bottum1) < threshold && abs(bottum - bottum1) < minDy) {
//                *newy = bottum1 - bottumFrom;
//                minDy = abs(bottum - bottum1);
//                align = YES;
//            }
//            
//            //并列
//            if (abs(left - right1) < threshold && abs(left - right1) < minDx) {
//                *newx = right1 - leftFrom;
//                minDx = abs(left - right1);
//                align = YES;
//            }
//            if (abs(top - bottum1) < threshold && abs(top - bottum1) < minDy) {
//                *newy = bottum1 - topFrom;
//                minDy = abs(top - bottum1);
//                align = YES;
//            }
//            if (abs(right - left1) < threshold && abs(right - left1) < minDx) {
//                *newx = left1 - rightFrom;
//                minDx = abs(right - left1);
//                align = YES;
//            }
//            if (abs(bottum - top1) < threshold && abs(bottum - top1) < minDy) {
//                *newy = top1 - bottumFrom;
//                minDy = abs(bottum - top1);
//                align = YES;
//            }
//            
//        }
//        
//    }
//    return align;
//
//}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    m_bTransfoming = NO;
    PSContent *contents = [m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    if([wdDrawingController.selectedObjects count] == 0)
        return;
    
    BOOL hasChange = NO;
    for (int i = 0; i < 5; i++) {
        if (!NSEqualPoints(m_pointsInit[i], m_pointsCur[i])) {
            hasChange = YES;
        }
    }
    if (hasChange) {
        [self transformNodes:m_pointsInit ToPoint:m_pointsCur];
    }
    

 //   if(!m_bTransfoming)  wzq test
 //       m_pointsInit[4] = m_pointsCur[4];
 //   else
 //       [self initialAffineInfo];
    memcpy(m_pointsInit, m_pointsCur, sizeof(m_pointsCur));
    
 //   m_bTransfoming = NO;
    
    m_enumPickType = PICK_NONE;
}

- (int)getRotationDirectionFrom:(NSPoint)pointCurrent pointCenter:(NSPoint)pointCenter
{
    if(pointCurrent.x > pointCenter.x  && 2*ABS(pointCenter.y - pointCurrent.y) < pointCurrent.x - pointCenter.x)
    {
        return 0;
    }
    else if(pointCurrent.x < pointCenter.x  && 2*ABS(pointCenter.y - pointCurrent.y) < pointCenter.x - pointCurrent.x )
    {
        return 4;
    }
    else if(pointCurrent.y < pointCenter.y  && 2*ABS(pointCenter.x - pointCurrent.x) < pointCenter.y - pointCurrent.y)
    {
        return 2;
    }
    else if(pointCurrent.y > pointCenter.y  && 2*ABS(pointCenter.x - pointCurrent.x) < pointCurrent.y - pointCenter.y)
    {
        return 6;
    }
    else if(pointCurrent.x > pointCenter.x  && pointCurrent.y < pointCenter.y)
        return 1;
    else if(pointCurrent.x < pointCenter.x  && pointCurrent.y < pointCenter.y)
        return 3;
    else if(pointCurrent.x < pointCenter.x  && pointCurrent.y > pointCenter.y)
        return 5;
    return 7;
    
}

- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    NSPoint whereInScrollView = [scrollView convertPoint: where fromView: [m_idDocument docView]];
    if(!NSPointInRect(whereInScrollView, [scrollView bounds]))  //出了画布范围
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor arrowCursor] retain];
        
        [m_cursor set];
        return;
    }

    
    NSMutableArray *arrViewsAbovePSView = [[[gCurrentDocument tools] currentTool] arrViewsAbovePSView];
    if([arrViewsAbovePSView count])
    {
        for (NSView *view in arrViewsAbovePSView)
        {
            NSPoint whereInViewsAbovePSView = [view convertPoint: where fromView: [m_idDocument docView]];
            if(NSPointInRect(whereInViewsAbovePSView, [view bounds]))
            {
                if(m_cursor) {[m_cursor release]; m_cursor = nil;}
                m_cursor = [[NSCursor arrowCursor] retain];
                
                [m_cursor set];
                return;
            }
        }
    }

    
    
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    if(nSelection <= 0) return;
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    //judge point position
    int enumPickType = [self objectPickType:CGPointMake(where.x / xScale, where.y / yScale) InPointsBoundaries:m_pointsCur];
    
    NSCursor *cursor = [NSCursor arrowCursor];
    switch (m_enumTransformTypeInit)
    {
        case Transform_Move:
        {
            if (enumPickType == PICK_CENTER)                cursor = curMoveCenter;
            else if (enumPickType == PICK_INNER)            cursor = curMove;
            else                                            cursor = m_curNormal;//[NSCursor arrowCursor];
        }
            break;
        case Transform_Scale:
        {
            if (enumPickType == PICK_TOPLEFT)               cursor = curUldr;
            else if (enumPickType == PICK_TOPRIGHT)         cursor = curUrdl;
            else if (enumPickType == PICK_BOTTOMRIGHT)      cursor = curUldr;
            else if (enumPickType == PICK_BOTTOMLEFT)       cursor = curUrdl;
            else if (enumPickType == PICK_CENTER)           cursor = curMoveCenter;
            
            else if (enumPickType == PICK_TOP)              cursor = curUd;
            else if (enumPickType == PICK_RIGHT)            cursor = curLr;
            else if (enumPickType == PICK_BOTTOM)           cursor = curUd;
            else if (enumPickType == PICK_LEFT)             cursor = curLr;
            else if (enumPickType == PICK_INNER)            cursor = curMove;
            else if (enumPickType == PICK_ROTATE)
            {
                int nDir = [self getRotationDirectionFrom:CGPointMake(where.x / xScale, where.y / yScale) pointCenter:m_pointsCur[4]];
                //cursor = curRotate;
                cursor = curRotate8[nDir];
            }
            else                                            cursor = m_curNormal;//[NSCursor arrowCursor];
            
        }
            break;
        case Transform_Rotate:
        {
            if (enumPickType == PICK_CENTER)                cursor = curMoveCenter;
            else if (enumPickType == PICK_INNER)            cursor = curMove;
            else
            {
                int nDir = [self getRotationDirectionFrom:CGPointMake(where.x / xScale, where.y / yScale) pointCenter:m_pointsCur[4]];
                //cursor = curRotate;
                cursor = curRotate8[nDir];
             //   cursor = curRotate;
            }
        }
            break;
        case Transform_Skew:
        case Transform_Perspective:
        {
            if (enumPickType == PICK_TOPLEFT)               cursor = curSkewCorner;
            else if (enumPickType == PICK_TOPRIGHT)         cursor = curSkewCorner;
            else if (enumPickType == PICK_BOTTOMRIGHT)      cursor = curSkewCorner;
            else if (enumPickType == PICK_BOTTOMLEFT)       cursor = curSkewCorner;
            else if (enumPickType == PICK_CENTER)           cursor = curMoveCenter;
            else if (enumPickType == PICK_TOP)              cursor = curSkewLr;
            else if (enumPickType == PICK_RIGHT)            cursor = curSkewUd;
            else if (enumPickType == PICK_BOTTOM)           cursor = curSkewLr;
            else if (enumPickType == PICK_LEFT)             cursor = curSkewUd;
            else if (enumPickType == PICK_INNER)            cursor = curMove;
            else if (enumPickType == PICK_ROTATE)           cursor = curRotate;
            else                                            cursor = m_curNormal;//[NSCursor arrowCursor];
        }
            break;
        default:
            break;
    }
    
//    [self addCursor:cursor];
    
    if(m_cursor) {[m_cursor release];m_cursor = nil;}
    m_cursor = [cursor retain];
    
    [m_cursor set];
}

#pragma mark - Mouse cursor
- (void)setNormalCursor:(NSCursor *)cursor
{
    if(m_curNormal) {[m_curNormal release];m_curNormal = nil;}
    m_curNormal = [cursor retain];
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
    
    
        
    NSMutableArray *arrViewsAbovePSView = [[[gCurrentDocument tools] currentTool] arrViewsAbovePSView];
    if([arrViewsAbovePSView count])
    {
        for (NSView *view in arrViewsAbovePSView)
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
    }

    
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    // Clip to the centering clipview
    NSRect clippedRect = [scrollView bounds];
    if(m_cursor)
        [[m_idDocument docView] addCursorRect:clippedRect cursor: m_cursor];
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

-(void)addCursor:(NSCursor *)cursor
{
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSRect operableRect;
    IntRect operableIntRect;
    
    operableIntRect = IntMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * xScale, [(PSContent *)[m_idDocument contents] height] *yScale);
    operableRect    = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([[m_idDocument docView] frame]), operableIntRect));
    
    
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
    
    // Convert to the scrollview's origin
    operableRect.origin = [scrollView convertPoint: operableRect.origin fromView: [m_idDocument docView]];
    
    // Clip to the centering clipview
    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], operableRect);
    
    // Convert the point back to the seaview
    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    [[m_idDocument docView] addCursorRect:clippedRect cursor: cursor];
}

- (NSBezierPath*)getRectBetweenTwoPoints:(NSPoint)point1 point2:(NSPoint)point2 width:(float)width
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSPoint vector = NSMakePoint(point2.x - point1.x, point2.y - point1.y);
    float length = sqrtf(vector.x * vector.x + vector.y * vector.y);
    NSPoint changeVector = NSMakePoint(-vector.y / length * width / 2.0, vector.x / length * width / 2.0);
    NSPoint point11 = NSMakePoint(point1.x + changeVector.x, point1.y + changeVector.y);
    NSPoint point12 = NSMakePoint(point1.x - changeVector.x, point1.y - changeVector.y);
    NSPoint point21 = NSMakePoint(point2.x + changeVector.x, point2.y + changeVector.y);
    NSPoint point22 = NSMakePoint(point2.x - changeVector.x, point2.y - changeVector.y);
    [path moveToPoint:point11];
    [path lineToPoint:point12];
    [path lineToPoint:point22];
    [path lineToPoint:point21];
    [path closePath];
    return path;
}

#define SQR(x)  ((x)*(x))
//#define ABS(x)  (((x)>0)?(x):(-x))
#pragma mark - Mouse Pick Type
-(PSPickResultType)objectPickType:(CGPoint)curPoint InPointsBoundaries:(CGPoint *)pointsInit
{
    NSBezierPath *rectPath = [NSBezierPath bezierPath];
    [rectPath moveToPoint:pointsInit[0]];
    [rectPath lineToPoint:pointsInit[1]];
    [rectPath lineToPoint:pointsInit[2]];
    [rectPath lineToPoint:pointsInit[3]];
    [rectPath closePath];
    
    float rectwidth = 20;
    NSRect topLeftRect          = NSMakeRect(pointsInit[0].x - rectwidth/2, pointsInit[0].y - rectwidth/2, rectwidth, rectwidth);
    NSRect topRightRect         = NSMakeRect(pointsInit[1].x - rectwidth/2, pointsInit[1].y - rectwidth/2, rectwidth, rectwidth);
    NSRect bottomRightRect      = NSMakeRect(pointsInit[2].x - rectwidth/2, pointsInit[2].y - rectwidth/2, rectwidth, rectwidth);
    NSRect bottomLeftRect       = NSMakeRect(pointsInit[3].x - rectwidth/2, pointsInit[3].y - rectwidth/2, rectwidth, rectwidth);
    NSRect centerRect           = NSMakeRect(pointsInit[4].x - rectwidth/2, pointsInit[4].y - rectwidth/2, rectwidth, rectwidth);
    
    float yScale = [[m_idDocument contents] yscale];
    
    NSPoint pointFrom = NSMakePoint((pointsInit[0].x + pointsInit[1].x)/2.0, (pointsInit[0].y + pointsInit[1].y)/2.0);
    NSPoint pointTo;
    
    CGFloat  fLengthBetweenPoint3And0 = sqrt(SQR(pointsInit[3].x - pointsInit[0].x) + SQR(pointsInit[3].y - pointsInit[0].y));
    
    if(fLengthBetweenPoint3And0 < 0.001)  return PICK_TOPLEFT;
    
    pointTo.x = pointFrom.x - (yScale * DIS_ROTATE_UI * (pointsInit[3].x - pointsInit[0].x)/fLengthBetweenPoint3And0);
    pointTo.y = pointFrom.y - (yScale * DIS_ROTATE_UI * (pointsInit[3].y - pointsInit[0].y)/fLengthBetweenPoint3And0);
    
  //  NSRect rotateRect           = NSMakeRect(pointTo.x - rectwidth/2, pointTo.y - rectwidth/2, rectwidth, rectwidth);
    
    float bandWidth = 20;//16;
    NSBezierPath *topPath       = [self getRectBetweenTwoPoints:pointsInit[0] point2:pointsInit[1] width:bandWidth];
    NSBezierPath *rightPath     = [self getRectBetweenTwoPoints:pointsInit[1] point2:pointsInit[2] width:bandWidth];
    NSBezierPath *bottomPath    = [self getRectBetweenTwoPoints:pointsInit[2] point2:pointsInit[3] width:bandWidth];
    NSBezierPath *leftPath      = [self getRectBetweenTwoPoints:pointsInit[3] point2:pointsInit[0] width:bandWidth];
    
    PSPickResultType enumPickType = PICK_NONE;
    if (NSPointInRect(curPoint, topLeftRect))                   enumPickType = PICK_TOPLEFT;
    else if (NSPointInRect(curPoint, topRightRect))             enumPickType = PICK_TOPRIGHT;
    else if (NSPointInRect(curPoint, bottomRightRect))          enumPickType = PICK_BOTTOMRIGHT;
    else if (NSPointInRect(curPoint, bottomLeftRect))           enumPickType = PICK_BOTTOMLEFT;
    else if (NSPointInRect(curPoint, centerRect))               enumPickType = PICK_CENTER;
  //  else if (NSPointInRect(curPoint, rotateRect))               enumPickType = PICK_ROTATE;
    else if ([topPath containsPoint:curPoint])                  enumPickType = PICK_TOP;
    else if ([rightPath containsPoint:curPoint])                enumPickType = PICK_RIGHT;
    else if ([bottomPath containsPoint:curPoint])               enumPickType = PICK_BOTTOM;
    else if ([leftPath containsPoint:curPoint])                 enumPickType = PICK_LEFT;
    else if ([rectPath containsPoint:curPoint])                 enumPickType = PICK_INNER;
    else
    {
        CGPoint pointAncor[8];
        
        for(int i=0; i<4; i++)  pointAncor[i] = pointsInit[i];
        for(int i=0; i<4; i++)  pointAncor[i+4] = CGPointMake((pointsInit[i].x+pointsInit[(i+1)%4].x)/2.0, (pointsInit[i].y+pointsInit[(i+1)%4].y)/2.0);
        
        BOOL bTooFar = YES;
        for(int i=0; i<8; i++)
        {
            if(fabs(curPoint.x - pointAncor[i].x) + fabs(curPoint.y - pointAncor[i].y) < 40.0)
            {
                bTooFar = NO; break;
            }
        }
        
        if(!bTooFar)
            enumPickType = PICK_ROTATE;
    }
    
    return enumPickType;
}

#pragma mark - Transform Points

- (void) moveTransformPointsWithOffsets:(CGPoint *)pointsInit offset:(CGPoint)pointOffset points:(CGPoint *)pointsTransfromed
{
    for (int i = 0; i < 5; i++)
        pointsTransfromed[i] = NSMakePoint(pointsInit[i].x + pointOffset.x, pointsInit[i].y + pointOffset.y);
}

- (void) scaleTransformPointsWithOffsets:(CGPoint *)pointsInit offset:(CGPoint)pointOffset InPickResultType:(PSPickResultType)nPickResultType points:(CGPoint *)pointsTransfromed
{
    switch (nPickResultType)
    {
        case PICK_TOP:
        {
            for (int i = 0; i < 2; i++)
                pointsTransfromed[i].y  = pointsInit[i].y + pointOffset.y;
            
            break;
        }
        case PICK_TOPRIGHT: //
        {
            pointsTransfromed[0].y      = pointsInit[0].y + pointOffset.y;
            pointsTransfromed[1]        = NSMakePoint(pointsInit[1].x + pointOffset.x, pointsInit[1].y + pointOffset.y);
            pointsTransfromed[2].x      = pointsInit[2].x + pointOffset.x;
            
            break;
        }
        case PICK_RIGHT:
        {
            for (int i = 1; i < 3; i++)
                pointsTransfromed[i].x  = pointsInit[i].x + pointOffset.x;
            
            break;
        }
        case PICK_BOTTOMRIGHT:
        {
            pointsTransfromed[1].x      = pointsInit[1].x + pointOffset.x;
            pointsTransfromed[2]        = NSMakePoint(pointsInit[2].x + pointOffset.x, pointsInit[2].y + pointOffset.y);
            pointsTransfromed[3].y      = pointsInit[3].y + pointOffset.y;
            break;
        }
        case PICK_BOTTOM:
        {
            for (int i = 2; i < 4; i++)
                pointsTransfromed[i].y  = pointsInit[i].y + pointOffset.y;
            
            break;
        }
        case PICK_BOTTOMLEFT:
        {
            pointsTransfromed[2].y      = pointsInit[2].y + pointOffset.y;
            pointsTransfromed[3]        = NSMakePoint(pointsInit[3].x + pointOffset.x, pointsInit[3].y + pointOffset.y);
            pointsTransfromed[0].x      = pointsInit[0].x + pointOffset.x;
            break;
        }
        case PICK_LEFT:
        {
            pointsTransfromed[3].x      = pointsInit[3].x + pointOffset.x;
            pointsTransfromed[0].x      = pointsInit[0].x + pointOffset.x;
            break;
        }
        case PICK_TOPLEFT:
        {
            pointsTransfromed[3].x      = pointsInit[3].x + pointOffset.x;
            pointsTransfromed[0]        = NSMakePoint(pointsInit[0].x + pointOffset.x, pointsInit[0].y + pointOffset.y);
            pointsTransfromed[1].y      = pointsInit[1].y + pointOffset.y;
            
            break;
        }
        default:
            break;
    }
}

- (void) skewTransformPointsWithOffsets:(CGPoint *)pointsInit offset:(CGPoint)pointOffset InPickResultType:(PSPickResultType)nPickResultType points:(CGPoint *)pointsTransfromed
{
    switch (nPickResultType)
    {
        case PICK_TOP:
        {
            pointsTransfromed[0].x = pointsInit[0].x + pointOffset.x;
            pointsTransfromed[1].x = pointsInit[1].x + pointOffset.x;
            
            break;
        }
        case PICK_TOPRIGHT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
                pointsTransfromed[1].y = pointsInit[1].y + pointOffset.y;
            else
                pointsTransfromed[1].x = pointsInit[1].x + pointOffset.x;
            
            break;
        }
        case PICK_RIGHT:
        {
            pointsTransfromed[1].y = pointsInit[1].y + pointOffset.y;
            pointsTransfromed[2].y = pointsInit[2].y + pointOffset.y;
            break;
        }
        case PICK_BOTTOMRIGHT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
                pointsTransfromed[2].y = pointsInit[2].y + pointOffset.y;
            else
                pointsTransfromed[2].x = pointsInit[2].x + pointOffset.x;
            break;
        }
        case PICK_BOTTOM:
        {
            pointsTransfromed[2].x = pointsInit[2].x + pointOffset.x;
            pointsTransfromed[3].x = pointsInit[3].x + pointOffset.x;
            
            break;
        }
        case PICK_BOTTOMLEFT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
                pointsTransfromed[3].y = pointsInit[3].y + pointOffset.y;
            else
                pointsTransfromed[3].x = pointsInit[3].x + pointOffset.x;
            break;
        }
        case PICK_LEFT:
        {
            pointsTransfromed[3].y = pointsInit[3].y + pointOffset.y;
            pointsTransfromed[0].y = pointsInit[0].y + pointOffset.y;
            break;
        }
        case PICK_TOPLEFT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
                pointsTransfromed[0].y = pointsInit[0].y + pointOffset.y;
            else
                pointsTransfromed[0].x = pointsInit[0].x + pointOffset.x;
            break;
        }
        default:
            break;
    }
}

- (void) perspectiveTransformPointsWithOffsets:(CGPoint *)pointsInit offset:(CGPoint)pointOffset InPickResultType:(PSPickResultType)nPickResultType points:(CGPoint *)pointsTransfromed
{
    switch (nPickResultType)
    {
        case PICK_TOP:
        {
            pointsTransfromed[0].x = pointsInit[0].x + pointOffset.x;
            pointsTransfromed[1].x = pointsInit[1].x + pointOffset.x;
            break;
        }
        case PICK_TOPRIGHT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
            {
                pointsTransfromed[1].y = pointsInit[1].y + pointOffset.y;
                pointsTransfromed[2].y = pointsInit[2].y - pointOffset.y;
            }
            else
            {
                pointsTransfromed[1].x = pointsInit[1].x + pointOffset.x;
                pointsTransfromed[0].x = pointsInit[0].x - pointOffset.x;
            }
            
            break;
        }
        case PICK_RIGHT:
        {
            pointsTransfromed[1].y = pointsInit[1].y + pointOffset.y;
            pointsTransfromed[2].y = pointsInit[2].y + pointOffset.y;
            break;
        }
        case PICK_BOTTOMRIGHT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
            {
                pointsTransfromed[2].y = pointsInit[2].y + pointOffset.y;
                pointsTransfromed[1].y = pointsInit[1].y - pointOffset.y;
            }
            else
            {
                pointsTransfromed[2].x = pointsInit[2].x + pointOffset.x;
                pointsTransfromed[3].x = pointsInit[3].x - pointOffset.x;
            }
            
            break;
        }
        case PICK_BOTTOM:
        {
            pointsTransfromed[2].x = pointsInit[2].x + pointOffset.x;
            pointsTransfromed[3].x = pointsInit[3].x + pointOffset.x;
            
            break;
        }
        case PICK_BOTTOMLEFT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
            {
                pointsTransfromed[3].y = pointsInit[3].y + pointOffset.y;
                pointsTransfromed[0].y = pointsInit[0].y - pointOffset.y;
            }
            else
            {
                pointsTransfromed[3].x = pointsInit[3].x + pointOffset.x;
                pointsTransfromed[2].x = pointsInit[2].x - pointOffset.x;
            }
            
            break;
        }
        case PICK_LEFT:
        {
            pointsTransfromed[3].y = pointsInit[3].y + pointOffset.y;
            pointsTransfromed[0].y = pointsInit[0].y + pointOffset.y;
            break;
        }
        case PICK_TOPLEFT:
        {
            if(fabs(pointOffset.y) > fabs(pointOffset.x))
            {
                pointsTransfromed[0].y = pointsInit[0].y + pointOffset.y;
                pointsTransfromed[3].y = pointsInit[3].y - pointOffset.y;
            }
            else
            {
                pointsTransfromed[0].x = pointsInit[0].x + pointOffset.x;
                pointsTransfromed[1].x = pointsInit[1].x - pointOffset.x;
            }
            
            break;
        }
        default:
            break;
    }
}

#pragma mark - Get Transform
- (CGAffineTransform) computeTransform:(CGPoint)fromPoint toPoint:(CGPoint)toPoint center:(CGPoint)pointCenter
{
    CGPoint delta = CGPointMake(fromPoint.x - pointCenter.x, fromPoint.y - pointCenter.y);
    double offsetAngle = atan2(delta.y, delta.x);
    
    delta = CGPointMake(toPoint.x - pointCenter.x, toPoint.y - pointCenter.y);
    double angle = atan2(delta.y, delta.x);
    double diff = angle - offsetAngle;
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(pointCenter.x, pointCenter.y);
    transform = CGAffineTransformRotate(transform, diff);
    transform = CGAffineTransformTranslate(transform, -pointCenter.x, -pointCenter.y);
    
    return transform;
}

#pragma mark - transform Nodes
-(void)transformNodes:(CGPoint *)pointSource ToPoint:(CGPoint *)pointDes
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    for (WDElement *element in wdDrawingController.selectedObjects)
    {
        PSVecLayer *pVecLayer = [element layer].layerDelegate;
        if(![pVecLayer visible]) continue;
        
        if (![[element layer].elements containsObject:element])   continue;

        CGPoint pointFrom[4],toPoint[4];
        CGAffineTransform transformInvert = CGAffineTransformInvert([pVecLayer transform]);
        for(int i = 0; i < 4; i++)
            pointFrom[i] = CGPointApplyAffineTransform(pointSource[i], transformInvert);
        
        for(int i = 0; i < 4; i++)
            toPoint[i] = CGPointApplyAffineTransform(pointDes[i], transformInvert);
       
        
        PSPerspectiveTransform transform = quadrilateralToQuadrilateral(pointFrom[0].x, pointFrom[0].y, pointFrom[1].x, pointFrom[1].y, pointFrom[2].x, pointFrom[2].y, pointFrom[3].x, pointFrom[3].y, toPoint[0].x, toPoint[0].y, toPoint[1].x, toPoint[1].y, toPoint[2].x, toPoint[2].y, toPoint[3].x, toPoint[3].y);
        
        [(WDPath *)element setPerspectiveTransform:transform];
        
        m_pointsCur[4] = perspectiveTransfromPoint(m_pointsInit[4], transform);
    }
    
    
}



#pragma mark - draw Extra
- (void)drawVectorToolExtraExtent:(NSNotification*) notification
{
    
//    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
//    if (curToolIndex != kVectorMoveTool) return;
//    
    if(m_enumTransformTypeInit == Transform_NO)
        return;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    if(nSelection <= 0) return;
    
  //  if(m_enumTransformType != Transform_MoveCenter && !m_bTransfoming)
   //     [self initialAffineInfo];
    
    NSArray *arrSubViews = [[[m_idDocument scrollView] superview] subviews];
    PSShadowView *shadowView;
    for(NSView *view in arrSubViews)
    {
        if([view isKindOfClass:[PSShadowView class]])
        {
            shadowView = (PSShadowView *)view;
            break;
        }
    }
    
    if (notification.object != shadowView)      return;
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    
    NSPoint viewPoint0 = NSMakePoint(m_pointsCur[0].x * xScale, m_pointsCur[0].y * yScale);
    NSPoint viewPoint1 = NSMakePoint(m_pointsCur[1].x * xScale, m_pointsCur[1].y * yScale);
    NSPoint viewPoint2 = NSMakePoint(m_pointsCur[2].x * xScale, m_pointsCur[2].y * yScale);
    NSPoint viewPoint3 = NSMakePoint(m_pointsCur[3].x * xScale, m_pointsCur[3].y * yScale);
    NSPoint viewPoint4 = NSMakePoint(m_pointsCur[4].x * xScale, m_pointsCur[4].y * yScale);
    
    PSView *psview = [m_idDocument docView];
    NSPoint pointInView[5];
    pointInView[0] = [shadowView convertPoint: viewPoint0 fromView: psview];
    pointInView[1] = [shadowView convertPoint: viewPoint1 fromView: psview];
    pointInView[2] = [shadowView convertPoint: viewPoint2 fromView: psview];
    pointInView[3] = [shadowView convertPoint: viewPoint3 fromView: psview];
    pointInView[4] = [shadowView convertPoint: viewPoint4 fromView: psview];
    
//    NSPoint pointInitInShadowView[5];
//    NSPoint pointCurInShadowView[5];
//    for (int i = 0; i < 5; i++)
//    {
//        pointInitInShadowView[i] = NSMakePoint(m_pointsInit[i].x * xScale, m_pointsInit[i].y * yScale);
//        pointInitInShadowView[i] = [shadowView convertPoint: pointInitInShadowView[i] fromView: psview];
//        pointInitInShadowView[i] = NSMakePoint(pointInitInShadowView[i].x/xScale, pointInitInShadowView[i].y/yScale);
//        
//        pointCurInShadowView[i] = pointInView[i];
//        pointCurInShadowView[i] = NSMakePoint(pointInView[i].x/xScale, pointInView[i].y/yScale);
//    }
//
    
  //  if(m_bTransfoming)
    //    [self drawPrewViewNodesBoundaries:pointInitInShadowView curPoint:pointCurInShadowView];
 
 //   [self drawAuxiliaryRotate:pointInView];
    [self drawAuxiliaryLine:pointInView];
}


- (void)drawToolExtra
{
//    if(m_enumTransformTypeInit == Transform_NO) return;

    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    if(nSelection <= 0) return;
    
  //  if(m_enumTransformType != Transform_MoveCenter && !m_bTransfoming)
    //    [self initialAffineInfo];
    
    if ([NSDate timeIntervalSinceReferenceDate] - m_lastRefreshTime > 0.1)
    {
        NSArray *arrSubViews = [[[m_idDocument scrollView] superview] subviews];
        PSShadowView *shadowView;
        for(NSView *view in arrSubViews)
        {
            if([view isKindOfClass:[PSShadowView class]])
            {
                shadowView = (PSShadowView *)view;
                break;
            }
        }
        [shadowView setNeedsDisplay:YES];
        
        m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    if(m_enumTransformTypeInit == Transform_NO) return;
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSPoint pointInView[5];
    pointInView[0] = NSMakePoint(m_pointsCur[0].x * xScale, m_pointsCur[0].y * yScale);
    pointInView[1] = NSMakePoint(m_pointsCur[1].x * xScale, m_pointsCur[1].y * yScale);
    pointInView[2] = NSMakePoint(m_pointsCur[2].x * xScale, m_pointsCur[2].y * yScale);
    pointInView[3] = NSMakePoint(m_pointsCur[3].x * xScale, m_pointsCur[3].y * yScale);
    pointInView[4] = NSMakePoint(m_pointsCur[4].x * xScale, m_pointsCur[4].y * yScale);
    
    if(m_bTransfoming)
        [self drawPrewViewNodesBoundaries:m_pointsInit curPoint:m_pointsCur];
  //  [self drawAuxiliaryRotate:pointInView];
    [self drawAuxiliaryLine:pointInView];
}

-(void)drawAuxiliaryLine:(NSPoint *)point
{
  /*  CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeNormal);//kCGBlendModeDifference);
    NSColor *color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.3];
    [color set];
    
    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath setLineWidth:1.0];
    [tempPath moveToPoint:point[0]];
    [tempPath lineToPoint:point[1]];
    [tempPath lineToPoint:point[2]];
    [tempPath lineToPoint:point[3]];
    [tempPath closePath];
    [tempPath stroke];
    
    CGContextRestoreGState(context);
    */
    
//    return;
    [self drawDragAffineHandlesPoint1:point[0] point2:point[1] point3:point[2] point4:point[3] point5:point[4]];
}

-(void)drawPrewViewNodesBoundaries:(NSPoint *)initPoint curPoint:(NSPoint *)curPoint
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    if(nSelection <= 0) return;
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);
    
//    float scale = MAX(1.0 / MAX(xScale, yScale), 0.5);
    float scale = [[m_idDocument docView] zoom];
    // draw all object outlines, using the selection transform if applicable
    for (WDElement *element in wdDrawingController.selectedObjects) //选中之后的移动
    {
        PSVecLayer *pVecLayer = [element layer].layerDelegate;
        if(![pVecLayer visible]) continue;
        
        if (![[element layer].elements containsObject:element])   continue;

        
        CGAffineTransform transformInvert = CGAffineTransformInvert([pVecLayer transform]);
        
        WDElement *elementTemp = [[element copyWithZone:nil] autorelease];
        
        CGPoint pointSource[5],toPoint[5];
        for(int i = 0; i < 4; i++)
            pointSource[i] = CGPointApplyAffineTransform(initPoint[i], transformInvert);
        for(int i = 0; i < 4; i++)
            toPoint[i] = CGPointApplyAffineTransform(curPoint[i], transformInvert);
        
        PSPerspectiveTransform transform = quadrilateralToQuadrilateral(pointSource[0].x, pointSource[0].y, pointSource[1].x, pointSource[1].y, pointSource[2].x, pointSource[2].y, pointSource[3].x, pointSource[3].y, toPoint[0].x, toPoint[0].y, toPoint[1].x, toPoint[1].y, toPoint[2].x, toPoint[2].y, toPoint[3].x, toPoint[3].y);
        
        [(WDPath *)elementTemp setPerspectiveTransform:transform];
        
        
        CGContextSaveGState(ctx);
        CGContextConcatCTM(ctx,[pVecLayer transform]);
        
        [elementTemp drawHighlightWithTransformInContext:ctx :CGAffineTransformIdentity viewTransform:CGAffineTransformIdentity scale:scale];
        CGContextRestoreGState(ctx);
    }
    
    CGContextRestoreGState(ctx);
}

- (void)drawDragAffineHandlesPoint1:(NSPoint)point1  point2:(NSPoint)point2  point3:(NSPoint)point3  point4:(NSPoint)point4 point5:(NSPoint)point5
{
    //PSView *psview = [m_idDocument docView];
    NSPoint tempPoint;
    tempPoint.x = point1.x;
    tempPoint.y = point1.y;
    [self drawHandle: tempPoint type: kPositionType index: 0];
    tempPoint.x = (point1.x + point2.x) / 2;
    tempPoint.y = (point1.y + point2.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 1];
    tempPoint.x = point2.x;
    tempPoint.y = point2.y;
    [self drawHandle: tempPoint type: kPositionType index: 2];
    tempPoint.x = (point2.x + point3.x) / 2;
    tempPoint.y = (point2.y + point3.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 3];
    tempPoint.x = point3.x;
    tempPoint.y = point3.y;
    [self drawHandle: tempPoint type: kPositionType index: 4];
    tempPoint.x = (point3.x + point4.x) / 2;
    tempPoint.y = (point3.y + point4.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 5];
    tempPoint.x = point4.x;
    tempPoint.y = point4.y;
    [self drawHandle: tempPoint type: kPositionType index: 6];
    tempPoint.x = (point1.x + point4.x) / 2;
    tempPoint.y = (point1.y + point4.y) / 2;
    [self drawHandle: tempPoint type: kPositionType index: 7];
    
    [self drawHandle: point5 type: kPositionType index: 8]; //centerpoint
}

- (void)drawHandle:(NSPoint) origin  type: (int)type index:(int) index
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeNormal);//kCGBlendModeDifference);
    NSColor *color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.5];
    [color set];
    
    NSRect outside  = NSMakeRect(origin.x - 3, origin.y - 3, 7, 7);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect: outside];
    [path setLineWidth:1.0];
    [path stroke];
    
    color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0.7];
    [color set];
    outside  = NSMakeRect(origin.x - 2, origin.y - 2, 5, 5);
    path = [NSBezierPath bezierPathWithRect: outside];
    [path fill];
    
    CGContextRestoreGState(context);
    
    return;
    
}


-(void)drawAuxiliaryRotate:(NSPoint *)point
{
    NSPoint pointFrom = NSMakePoint((point[0].x + point[1].x)/2.0, (point[0].y + point[1].y)/2.0);
    NSPoint pointTo;
    float yScale = [[m_idDocument contents] yscale];
    
    CGFloat  fLengthBetweenPoint3And0 = sqrt(SQR(point[3].x - point[0].x) + SQR(point[3].y - point[0].y));
    
    if(fLengthBetweenPoint3And0 < 0.001)  return;
    
    pointTo.x = pointFrom.x - (yScale * DIS_ROTATE_UI * (point[3].x - point[0].x)/fLengthBetweenPoint3And0);
    pointTo.y = pointFrom.y - (yScale * DIS_ROTATE_UI * (point[3].y - point[0].y)/fLengthBetweenPoint3And0);
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeNormal);//kCGBlendModeDifference);
    NSColor *color = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.3];
    [color set];
    
    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath setLineWidth:1.0];
    [tempPath moveToPoint:pointFrom];
    [tempPath lineToPoint:pointTo];
    [tempPath closePath];
    [tempPath stroke];
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    
    NSImage *image;
    if(m_enumTransformType == Transform_Rotate && m_bTransfoming) //旋转状态下切正在旋转
        image = [NSImage imageNamed:@"rotate_flag_a.png"];
    else if(m_bTransfoming && m_enumPickType == PICK_ROTATE) //正在旋转
        image = [NSImage imageNamed:@"rotate_flag_a.png"];
    else
        image = [NSImage imageNamed:@"rotate_flag.png"];
    CGImageRef imageRef = [image CGImageForProposedRect:nil context:nil hints:nil];
    CGContextDrawImage(context, CGRectMake(pointTo.x - 10, pointTo.y - 10, 21, 21), imageRef);
    
    CGContextRestoreGState(context);
}

#pragma mark -
- (void)initialAffineInfo
{
    CGRect rectBoundsInCanvas = CGRectNull;
    PSContent *contents = [m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    
    if([wdDrawingController.selectedObjects count] == 0) return;
    
    for(WDElement *element in wdDrawingController.selectedObjects)
    {
        PSVecLayer *pVecLayer = [element layer].layerDelegate;
        if(![pVecLayer visible]) continue;
        if (![[element layer].elements containsObject:element])   continue;

        CGRect rectElementBoundsInLayer = element.bounds;
        CGRect rectElementBoundsInCanvas = CGRectApplyAffineTransform(rectElementBoundsInLayer, [pVecLayer transform]);
        rectBoundsInCanvas = CGRectUnion(rectBoundsInCanvas, rectElementBoundsInCanvas);
    }
    
    if(CGRectIsNull(rectBoundsInCanvas) || rectBoundsInCanvas.size.width == 0 || rectBoundsInCanvas.size.height == 0)
        rectBoundsInCanvas = CGRectMake(0, 0, 3, 3);

    for (int i = 0; i < 5; i++)
            m_pointsInit[i] = [self getAffineDesPointAtIndex:i InRect:rectBoundsInCanvas];
        
    for (int i = 0; i < 5; i++)
        m_pointsCur[i] = m_pointsInit[i];
    
    
}

-(NSPoint)getAffineDesPointAtIndex:(int)index InRect:(CGRect)rect
{
    switch (index) {
        case 0:
            return NSMakePoint(rect.origin.x, rect.origin.y);
            break;
        case 1:
            return NSMakePoint(rect.origin.x + rect.size.width - 1, rect.origin.y);
            break;
        case 2:
            return NSMakePoint(rect.origin.x + rect.size.width - 1, rect.origin.y + rect.size.height - 1);
            break;
        case 3:
            return NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height - 1);
            break;
        case 4:
            return NSMakePoint(NSMidX(rect), NSMidY(rect)) ;
            break;
            
        default:
            break;
    }
    
    return NSMakePoint(0, 0);
}



#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    if (m_bTransfoming) return NO;
    
    return YES;
}

@end
