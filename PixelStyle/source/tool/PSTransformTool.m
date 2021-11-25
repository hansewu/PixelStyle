//
//  PSTransformTool.m
//  PixelStyle
//
//  Created by lchzh on 2/11/15.
//
//

#import "PSTransformTool.h"

#import "PSTransformOptions.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSWhiteboard.h"
#import "PSView.h"
#import "PSHelpers.h"
#import "PSTools.h"
#import "PSSelection.h"
#import "PSLayerUndo.h"
#import "PSOperations.h"
#import "PSRotation.h"
#import "PSScale.h"

#import "PSTransformManager.h"
#import "PSLayerTransformInfo.h"

#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSTransformOptions.h"

@implementation PSTransformTool

- (int)toolId
{
    return kTransformTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Transform Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"T";
}

- (id)init
{
    if(![super init])
        return NULL;
    
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
    
    m_currentWidthRatio = 1.0;
    m_currentHeightRatio = 1.0;
    m_currentDegree = 0.0;
    m_centerPointType = 0;
    
    m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    
    return self;
}

- (void)awakeFromNib
{
    m_transformManager = [[PSTransformManager alloc] initWithDocument:m_idDocument];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawToolExtraExtent:) name:@"DRAWTOOLEXTRAEXTENT" object:nil];
    [m_idOptions setTransformTool:self];
}

- (void)dealloc
{
    if (curLr) {[curLr release]; curLr = nil;}
    if (curUd) {[curUd release]; curUd = nil;}
    if (curUrdl) {[curUrdl release]; curUrdl = nil;}
    if (curUldr) {[curUldr release]; curUldr = nil;}
    if (curMoveCenter) {[curMoveCenter release]; curMoveCenter = nil;}
    if (curMove) {[curMove release]; curMove = nil;}
    if (curRotate) {[curRotate release]; curRotate = nil;}
    
    for(int i = 0; i < 8; i++)
    {
        [curRotate8[i] release]; curRotate8[i] = nil;
    }
    if (curSkewLr) {[curSkewLr release]; curSkewLr = nil;}
    if (curSkewUd) {[curSkewUd release]; curSkewUd = nil;}
    if (curSkewUrdl) {[curSkewUrdl release]; curSkewUrdl = nil;}
    if (curSkewUldr) {[curSkewUldr release]; curSkewUldr = nil;}
    if (curSkewCorner) {[curSkewCorner release]; curSkewCorner = nil;}
    
    if (m_transformManager) {[m_transformManager release]; m_transformManager = nil;}
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DRAWTOOLEXTRAEXTENT" object:nil];
    [super dealloc];
}


- (BOOL)isFineTool
{
    return YES;
}

- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event
{
    m_oldPoint0 = [m_transformManager getAffineDesPointAtIndex:0];
    m_oldPoint1 = [m_transformManager getAffineDesPointAtIndex:1];
    m_oldPoint2 = [m_transformManager getAffineDesPointAtIndex:2];
    m_oldPoint3 = [m_transformManager getAffineDesPointAtIndex:3];
    m_oldPoint4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    if (![self judgePointsIsValid:m_oldPoint0 point1:m_oldPoint1 point2:m_oldPoint2 point3:m_oldPoint3]) {
        m_scaleSyle = SCALESTYLE_NONE;
        return;
    }
    
    id activeLayer = [[m_idDocument contents] activeLayer];
    [activeLayer setFullRenderState:NO];
    
    m_currentTransformType = [m_idOptions getTransformType];
    // Record the inital point for dragging
    m_sInitialPoint = where;
    
    
    //judge point position
    m_scaleSyle = SCALESTYLE_NONE;
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSPoint point0 = m_oldPoint0;
    NSPoint point1 = m_oldPoint1;
    NSPoint point2 = m_oldPoint2;
    NSPoint point3 = m_oldPoint3;
    NSPoint point4 = m_oldPoint4;
    
    NSPoint viewPoint0 = NSMakePoint(point0.x * xScale, point0.y * yScale);
    NSPoint viewPoint1 = NSMakePoint(point1.x * xScale, point1.y * yScale);
    NSPoint viewPoint2 = NSMakePoint(point2.x * xScale, point2.y * yScale);
    NSPoint viewPoint3 = NSMakePoint(point3.x * xScale, point3.y * yScale);
    NSPoint viewPoint4 = NSMakePoint(point4.x * xScale, point4.y * yScale);
    
    NSBezierPath *rectPath = [NSBezierPath bezierPath];
    [rectPath moveToPoint:viewPoint0];
    [rectPath lineToPoint:viewPoint1];
    [rectPath lineToPoint:viewPoint2];
    [rectPath lineToPoint:viewPoint3];
    [rectPath closePath];
    
    float rectwidth = 20;
    NSRect topLeftRect = NSMakeRect(viewPoint0.x - rectwidth / 2, viewPoint0.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect topRightRect = NSMakeRect(viewPoint1.x - rectwidth / 2, viewPoint1.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect bottomRightRect = NSMakeRect(viewPoint2.x - rectwidth / 2, viewPoint2.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect bottomLeftRect = NSMakeRect(viewPoint3.x - rectwidth / 2, viewPoint3.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect centerRect = NSMakeRect(viewPoint4.x - rectwidth / 2, viewPoint4.y - rectwidth / 2, rectwidth, rectwidth);
    float bandWidth = 20;//16;
    NSBezierPath *topPath = [self getRectBetweenTwoPoints:viewPoint0 point2:viewPoint1 width:bandWidth];
    NSBezierPath *rightPath = [self getRectBetweenTwoPoints:viewPoint1 point2:viewPoint2 width:bandWidth];
    NSBezierPath *bottomPath = [self getRectBetweenTwoPoints:viewPoint2 point2:viewPoint3 width:bandWidth];
    NSBezierPath *leftPath = [self getRectBetweenTwoPoints:viewPoint3 point2:viewPoint0 width:bandWidth];
    
    NSPoint viewWhere = NSMakePoint(where.x * xScale, where.y * yScale);
    
    PSView *psview = [m_idDocument docView];
    NSScrollView *scrollView = (NSScrollView *)[[psview superview] superview];
    NSPoint superWhere = [scrollView convertPoint: viewWhere fromView: psview];
    NSRect superBounds = [scrollView bounds];
    
    if (NSPointInRect(viewWhere, topLeftRect)) {
        m_scaleSyle = SCALESTYLE_TOPLEFT;
    }else if (NSPointInRect(viewWhere, topRightRect)){
        m_scaleSyle = SCALESTYLE_TOPRIGHT;
    }else if (NSPointInRect(viewWhere, bottomRightRect)){
        m_scaleSyle = SCALESTYLE_BOTTOMRIGHT;
    }else if (NSPointInRect(viewWhere, bottomLeftRect)){
        m_scaleSyle = SCALESTYLE_BOTTOMLEFT;
    }else if (NSPointInRect(viewWhere, centerRect)){
        m_scaleSyle = SCALESTYLE_CENTER;
    }else if ([topPath containsPoint:viewWhere]){
        m_scaleSyle = SCALESTYLE_TOP;
    }else if ([rightPath containsPoint:viewWhere]){
        m_scaleSyle = SCALESTYLE_RIGHT;
    }else if ([bottomPath containsPoint:viewWhere]){
        m_scaleSyle = SCALESTYLE_BOTTOM;
    }else if ([leftPath containsPoint:viewWhere]){
        m_scaleSyle = SCALESTYLE_LEFT;
    }else if ([rectPath containsPoint:viewWhere]){
        m_scaleSyle = SCALESTYLE_MOVE;
    }else{
        if (m_currentTransformType == Transform_Rotate) {
            m_scaleSyle = SCALESTYLE_ROTATE;
        }else{
            if (NSPointInRect(superWhere, superBounds) && m_currentTransformType == Transform_Scale){
                m_scaleSyle = SCALESTYLE_ROTATE;
            }else{
                m_scaleSyle = SCALESTYLE_NONE;
            }
            
        }
    }
    if (m_scaleSyle == SCALESTYLE_MOVE) {
        m_currentTransformType = Transform_Move;
    }else if (m_scaleSyle == SCALESTYLE_CENTER){
        m_currentTransformType = Transform_MoveCenter;
    }
    if (m_scaleSyle == SCALESTYLE_NONE) {
        return;
    }
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (!hasBegin && m_currentTransformType != Transform_MoveCenter) {
        [m_transformManager setIfHasBeginTransform:YES];
        [m_transformManager initialAffineInfo];
    }
    
    hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }

    // Vary behaviour based on function
    switch (m_currentTransformType) {
        case Transform_Move:
        {

        }
            break;
        case Transform_Rotate:
        {
            NSPoint beginPoint = NSMakePoint(m_sInitialPoint.x - m_oldPoint4.x, m_sInitialPoint.y - m_oldPoint4.y);
            m_originalRotateDegree = [self getRotatedDegreeWithBeginPoint:beginPoint endPoint:beginPoint];
            
            //[[m_idDocument docView] setNeedsDisplay:YES];
        }
            break;
        case Transform_Scale:
        {
            if (m_scaleSyle == SCALESTYLE_ROTATE) {
                NSPoint beginPoint = NSMakePoint(m_sInitialPoint.x - m_oldPoint4.x, m_sInitialPoint.y - m_oldPoint4.y);
                m_originalRotateDegree = [self getRotatedDegreeWithBeginPoint:beginPoint endPoint:beginPoint];
            }
        }
            break;
//        case kAnchoringLayer:
//        {
//            // Anchor the layer
//            [contents anchorSelection];
//            
//        }
//            break;
        case Transform_Skew:
        {
            
        }
            break;
        case Transform_Perspective:
        {
            
        }
            break;
    }
    
}


- (NSPoint)adjustToKeepRatio:(NSPoint)pointTo pointNear:(NSPoint)pointFrom pointFar:(NSPoint)pointFar
{
    CGFloat distOffset = sqrt((pointTo.x - pointFrom.x) * (pointTo.x - pointFrom.x) + (pointTo.y - pointFrom.y) * (pointTo.y - pointFrom.y));
    CGFloat distDiag = sqrt((pointFar.x - pointFrom.x) * (pointFar.x - pointFrom.x) + (pointFar.y - pointFrom.y) * (pointFar.y - pointFrom.y));
    
    if(distDiag < 0.5)  return pointTo;
    
    CGFloat flagSgn = 1.0;
    
    
    if(((pointTo.x > pointFar.x && pointTo.x < pointFrom.x)
       || (pointTo.x > pointFrom.x && pointTo.x < pointFar.x))
       && ((pointTo.y > pointFar.y && pointTo.y < pointFrom.y)
       || (pointTo.y > pointFrom.y && pointTo.y < pointFar.y)))
        flagSgn = -1.0;
    
    NSPoint point;
    point.x = pointFrom.x + flagSgn * distOffset*(pointFrom.x - pointFar.x)/distDiag;
    point.y = pointFrom.y + flagSgn * distOffset*(pointFrom.y - pointFar.y)/distDiag;
    
    return point;
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    id contents = [m_idDocument contents];
    id activeLayer = [contents activeLayer];
    int xoff, yoff, whichLayer;
    
    
    int deltax = where.x - m_sInitialPoint.x, deltay = where.y - m_sInitialPoint.y;
    IntPoint oldOffsets = IntMakePoint(0, 0);
    
    KEY_MODIFIER modifier = [(AbstractOptions*)m_idOptions modifier];
    
    if (m_scaleSyle == SCALESTYLE_NONE) {
        return;
    }
    
//    if (modifier == kShiftModifier && m_currentTransformType == Transform_Scale) {
//        CGSize size = [m_transformManager getAffineOriginalSize];
//        if (m_scaleSyle == SCALESTYLE_TOPRIGHT) {
//            deltay = -deltax;
//            where.y= deltay + m_sInitialPoint.y;
//        }
//    }
    
    // Vary behaviour based on function
    switch (m_currentTransformType) {  //[m_idOptions  toolFunction]
        case Transform_Move:
        {
            if ([m_transformManager getIfHasBeginTransform])
            {
                NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + deltax, m_oldPoint0.y + deltay);
                NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + deltax, m_oldPoint1.y + deltay);
                NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + deltax, m_oldPoint2.y + deltay);
                NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + deltax, m_oldPoint3.y + deltay);
                [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                
            }
            else //can't go here
            {
                [m_transformManager initialAffineInfo];
                
                // If the active layer is linked we have to move all associated layers
                if ([activeLayer linked]) {
                    // Move all of the linked layers
                    for (whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
                        if ([[contents layer:whichLayer] linked]) {
                            xoff = [[contents layer:whichLayer] xoff]; yoff = [[contents layer:whichLayer] yoff];
                            [[contents layer:whichLayer] setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
                        }
                    }
                    [[m_idDocument helpers] layerOffsetsChanged:kLinkedLayers from:oldOffsets];
                    m_sInitialPoint = where;
                    
                }
                else {
                    // Move the active layer
                    xoff = [activeLayer xoff]; yoff = [activeLayer yoff];
                    oldOffsets = IntMakePoint(xoff, yoff);
                    [activeLayer setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
                    [[m_idDocument helpers] layerOffsetsChanged:kActiveLayer from:oldOffsets];
                    m_sInitialPoint = where;
                    
                }
                
            }
            
        }
            
            break;
        case Transform_Rotate:
        {
            if (m_scaleSyle == SCALESTYLE_ROTATE) {
                NSPoint beginPoint = NSMakePoint(m_sInitialPoint.x - m_oldPoint4.x, m_sInitialPoint.y - m_oldPoint4.y);
                NSPoint endPoint = NSMakePoint(where.x - m_oldPoint4.x, where.y - m_oldPoint4.y);
                float rotatedD = [self getRotatedDegreeWithBeginPoint:beginPoint endPoint:endPoint];
                float degree = m_originalRotateDegree - rotatedD;
                
                
                //NSLog(@"rotate degree %f,%@,%@",degree,NSStringFromPoint(beginPoint),NSStringFromPoint(endPoint));
                
                if (modifier == kShiftModifier) {
                    if (degree >= 0) {
                        float number = ceilf(degree / 15.0);
                        if ( ABS(number - degree / 15.0) < 0.2) {
                            degree = 15.0 * number;
                        }else{
                            degree = 15.0 * (number - 1);
                        }
                    }else{
                        float number = ceilf(-degree / 15.0);
                        if ( ABS(number - (-degree) / 15.0) < 0.2) {
                            degree = 15.0 * -number;
                        }else{
                            degree = 15.0 * (-number + 1);
                        }
                    }
                }
                
                
                NSPoint newPoint0 = [self getRotatedPoint:m_oldPoint0 degree:degree center:m_oldPoint4];
                NSPoint newPoint1 = [self getRotatedPoint:m_oldPoint1 degree:degree center:m_oldPoint4];
                NSPoint newPoint2 = [self getRotatedPoint:m_oldPoint2 degree:degree center:m_oldPoint4];
                NSPoint newPoint3 = [self getRotatedPoint:m_oldPoint3 degree:degree center:m_oldPoint4];
                [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
            }
        }
            
            break;
        case Transform_Scale:
        {
            
            switch (m_scaleSyle) {
                case SCALESTYLE_TOP:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint1.x - m_oldPoint0.x, m_oldPoint1.y - m_oldPoint0.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint2.x - m_oldPoint1.x, m_oldPoint2.y - m_oldPoint1.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    
                    partVector2 = NSMakePoint(-partVector2.x, -partVector2.y); //invert vector
                    float part2 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector3.y - partVector3.x * partVector2.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset2.x, m_oldPoint1.y + offset2.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    break;
                }
                case SCALESTYLE_TOPRIGHT:
                {
                    where = [self adjustToKeepRatio:where pointNear:m_oldPoint1 pointFar:m_oldPoint3];
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint1.x - m_oldPoint0.x, m_oldPoint1.y - m_oldPoint0.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint3.x - m_oldPoint2.x, m_oldPoint3.y - m_oldPoint2.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint partVector4 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length4 = sqrtf(partVector4.x * partVector4.x + partVector4.y * partVector4.y);
                    partVector4 = NSMakePoint(partVector4.x / length4, partVector4.y / length4);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    
                    float part2 = (partVector4.x * offset.y - offset.x * partVector4.y) / (partVector4.x * partVector3.y - partVector3.x * partVector4.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset2.x, m_oldPoint2.y + offset2.y);
                    
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset.x, m_oldPoint1.y + offset.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    break;
                }
                case SCALESTYLE_RIGHT:{
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint2.x - m_oldPoint1.x, m_oldPoint2.y - m_oldPoint1.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint3.x - m_oldPoint2.x, m_oldPoint3.y - m_oldPoint2.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    
                    partVector2 = NSMakePoint(-partVector2.x, -partVector2.y); //invert vector
                    float part2 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector3.y - partVector3.x * partVector2.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset2.x, m_oldPoint2.y + offset2.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    break;
                }
                case SCALESTYLE_BOTTOMRIGHT:{
                    where = [self adjustToKeepRatio:where pointNear:m_oldPoint2 pointFar:m_oldPoint0];
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint2.x - m_oldPoint1.x, m_oldPoint2.y - m_oldPoint1.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint0.x - m_oldPoint3.x, m_oldPoint0.y - m_oldPoint3.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint partVector4 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length4 = sqrtf(partVector4.x * partVector4.x + partVector4.y * partVector4.y);
                    partVector4 = NSMakePoint(partVector4.x / length4, partVector4.y / length4);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    
                    float part2 = (partVector4.x * offset.y - offset.x * partVector4.y) / (partVector4.x * partVector3.y - partVector3.x * partVector4.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset2.x, m_oldPoint3.y + offset2.y);
                    
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset.x, m_oldPoint2.y + offset.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_BOTTOM:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.x - m_oldPoint2.x, m_oldPoint3.y - m_oldPoint2.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint0.x - m_oldPoint3.x, m_oldPoint0.y - m_oldPoint3.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset1.x, m_oldPoint2.y + offset1.y);
                    
                    partVector2 = NSMakePoint(-partVector2.x, -partVector2.y); //invert vector
                    float part2 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector3.y - partVector3.x * partVector2.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset2.x, m_oldPoint3.y + offset2.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_BOTTOMLEFT:
                {
                    where = [self adjustToKeepRatio:where pointNear:m_oldPoint3 pointFar:m_oldPoint1];
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.x - m_oldPoint2.x, m_oldPoint3.y - m_oldPoint2.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint1.x - m_oldPoint0.x, m_oldPoint1.y - m_oldPoint0.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint partVector4 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length4 = sqrtf(partVector4.x * partVector4.x + partVector4.y * partVector4.y);
                    partVector4 = NSMakePoint(partVector4.x / length4, partVector4.y / length4);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset1.x, m_oldPoint2.y + offset1.y);
                    
                    float part2 = (partVector4.x * offset.y - offset.x * partVector4.y) / (partVector4.x * partVector3.y - partVector3.x * partVector4.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset2.x, m_oldPoint0.y + offset2.y);
                    
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset.x, m_oldPoint3.y + offset.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_LEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint0.x, m_oldPoint1.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    
                    partVector2 = NSMakePoint(-partVector2.x, -partVector2.y); //invert vector
                    float part2 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector3.y - partVector3.x * partVector2.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset2.x, m_oldPoint3.y + offset2.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_TOPLEFT:
                {
                    where = [self adjustToKeepRatio:where pointNear:m_oldPoint0 pointFar:m_oldPoint2];
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint2.x - m_oldPoint1.x, m_oldPoint2.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint partVector3 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length3 = sqrtf(partVector3.x * partVector3.x + partVector3.y * partVector3.y);
                    partVector3 = NSMakePoint(partVector3.x / length3, partVector3.y / length3);
                    NSPoint partVector4 = NSMakePoint(m_oldPoint0.x - m_oldPoint3.x, m_oldPoint0.y - m_oldPoint3.y);
                    float length4 = sqrtf(partVector4.x * partVector4.x + partVector4.y * partVector4.y);
                    partVector4 = NSMakePoint(partVector4.x / length4, partVector4.y / length4);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    
                    float part2 = (partVector4.x * offset.y - offset.x * partVector4.y) / (partVector4.x * partVector3.y - partVector3.x * partVector4.y);
                    NSPoint offset2 = NSMakePoint(part2 * partVector3.x, part2 * partVector3.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset2.x, m_oldPoint3.y + offset2.y);
                    
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset.x, m_oldPoint0.y + offset.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                    
                case SCALESTYLE_ROTATE:{
                    NSPoint beginPoint = NSMakePoint(m_sInitialPoint.x - m_oldPoint4.x, m_sInitialPoint.y - m_oldPoint4.y);
                    NSPoint endPoint = NSMakePoint(where.x - m_oldPoint4.x, where.y - m_oldPoint4.y);
                    float degree = m_originalRotateDegree - [self getRotatedDegreeWithBeginPoint:beginPoint endPoint:endPoint];
                    
                    //NSLog(@"rotate degree %f,%@,%@",degree,NSStringFromPoint(beginPoint),NSStringFromPoint(endPoint));
                    
                    if (modifier == kShiftModifier) {
                        if (degree >= 0) {
                            float number = ceilf(degree / 15.0);
                            if ( ABS(number - degree / 15.0) < 0.2) {
                                degree = 15.0 * number;
                            }else{
                                degree = 15.0 * (number - 1);
                            }
                        }else{
                            float number = ceilf(-degree / 15.0);
                            if ( ABS(number - (-degree) / 15.0) < 0.2) {
                                degree = 15.0 * -number;
                            }else{
                                degree = 15.0 * (-number + 1);
                            }
                        }
                    }

                    
                    NSPoint newPoint0 = [self getRotatedPoint:m_oldPoint0 degree:degree center:m_oldPoint4];
                    NSPoint newPoint1 = [self getRotatedPoint:m_oldPoint1 degree:degree center:m_oldPoint4];
                    NSPoint newPoint2 = [self getRotatedPoint:m_oldPoint2 degree:degree center:m_oldPoint4];
                    NSPoint newPoint3 = [self getRotatedPoint:m_oldPoint3 degree:degree center:m_oldPoint4];
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                }
                    
                default:
                    break;
            }
            
        }
            break;
        case Transform_Skew:{
            switch (m_scaleSyle) {
                case SCALESTYLE_TOP:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint1.y - m_oldPoint0.y, m_oldPoint0.x - m_oldPoint1.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    break;
                }
                case SCALESTYLE_TOPRIGHT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint2.x - m_oldPoint1.x, m_oldPoint2.y - m_oldPoint1.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint1;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint1 = NSMakePoint(m_oldPoint1.x + realoffset.x, m_oldPoint1.y + realoffset.y);
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint1 = NSMakePoint(m_oldPoint1.x + realoffset.x, m_oldPoint1.y + realoffset.y);
                    }
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    break;
                }
                case SCALESTYLE_RIGHT:{
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint2.y - m_oldPoint1.y, m_oldPoint1.x - m_oldPoint2.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset1.x, m_oldPoint2.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    break;
                }
                case SCALESTYLE_BOTTOMRIGHT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.x - m_oldPoint2.x, m_oldPoint3.y - m_oldPoint2.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint2;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint2 = NSMakePoint(m_oldPoint2.x + realoffset.x, m_oldPoint2.y + realoffset.y);
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint2 = NSMakePoint(m_oldPoint2.x + realoffset.x, m_oldPoint2.y + realoffset.y);
                    }
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    break;
                }
                case SCALESTYLE_BOTTOM:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.y - m_oldPoint2.y, m_oldPoint2.x - m_oldPoint3.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset1.x, m_oldPoint2.y + offset1.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset1.x, m_oldPoint3.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_BOTTOMLEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint0.x - m_oldPoint3.x, m_oldPoint0.y - m_oldPoint3.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint3;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint3 = NSMakePoint(m_oldPoint3.x + realoffset.x, m_oldPoint3.y + realoffset.y);
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint3 = NSMakePoint(m_oldPoint3.x + realoffset.x, m_oldPoint3.y + realoffset.y);
                    }
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_LEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint0.y - m_oldPoint3.y, m_oldPoint3.x - m_oldPoint0.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset1.x, m_oldPoint3.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_TOPLEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint1.x - m_oldPoint0.x, m_oldPoint1.y - m_oldPoint0.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint0;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint0 = NSMakePoint(m_oldPoint0.x + realoffset.x, m_oldPoint0.y + realoffset.y);
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint0 = NSMakePoint(m_oldPoint0.x + realoffset.x, m_oldPoint0.y + realoffset.y);
                    }
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    
                    break;
                }
                    
                default:
                    break;
            }
        }
            break;
            
        case Transform_Perspective:{
            switch (m_scaleSyle) {
                case SCALESTYLE_TOP:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint1.y - m_oldPoint0.y, m_oldPoint0.x - m_oldPoint1.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    break;
                }
                case SCALESTYLE_TOPRIGHT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint0.x - m_oldPoint1.x, m_oldPoint0.y - m_oldPoint1.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint2.x - m_oldPoint1.x, m_oldPoint2.y - m_oldPoint1.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint1;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint1 = NSMakePoint(m_oldPoint1.x + realoffset.x, m_oldPoint1.y + realoffset.y);
                        NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x - realoffset.x, m_oldPoint2.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                        [m_transformManager setAffineDesPoint:m_oldPoint0 AtIndex:0];
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint1 = NSMakePoint(m_oldPoint1.x + realoffset.x, m_oldPoint1.y + realoffset.y);
                        NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x - realoffset.x, m_oldPoint0.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                        [m_transformManager setAffineDesPoint:m_oldPoint2 AtIndex:2];
                    }
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    break;
                }
                case SCALESTYLE_RIGHT:{
                    
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint2.y - m_oldPoint1.y, m_oldPoint1.x - m_oldPoint2.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x + offset1.x, m_oldPoint1.y + offset1.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset1.x, m_oldPoint2.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    break;
                }
                case SCALESTYLE_BOTTOMRIGHT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint1.x - m_oldPoint2.x, m_oldPoint1.y - m_oldPoint2.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.x - m_oldPoint2.x, m_oldPoint3.y - m_oldPoint2.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint2;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint2 = NSMakePoint(m_oldPoint2.x + realoffset.x, m_oldPoint2.y + realoffset.y);
                        NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x - realoffset.x, m_oldPoint3.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                        [m_transformManager setAffineDesPoint:m_oldPoint1 AtIndex:1];
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint2 = NSMakePoint(m_oldPoint2.x + realoffset.x, m_oldPoint2.y + realoffset.y);
                        NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x - realoffset.x, m_oldPoint1.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                        [m_transformManager setAffineDesPoint:m_oldPoint3 AtIndex:3];
                    }
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    break;
                }
                case SCALESTYLE_BOTTOM:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint3.y - m_oldPoint2.y, m_oldPoint2.x - m_oldPoint3.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x + offset1.x, m_oldPoint2.y + offset1.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset1.x, m_oldPoint3.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_BOTTOMLEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint2.x - m_oldPoint3.x, m_oldPoint2.y - m_oldPoint3.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint0.x - m_oldPoint3.x, m_oldPoint0.y - m_oldPoint3.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint3;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint3 = NSMakePoint(m_oldPoint3.x + realoffset.x, m_oldPoint3.y + realoffset.y);
                        NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x - realoffset.x, m_oldPoint0.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                        [m_transformManager setAffineDesPoint:m_oldPoint2 AtIndex:2];
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint3 = NSMakePoint(m_oldPoint3.x + realoffset.x, m_oldPoint3.y + realoffset.y);
                        NSPoint newPoint2 = NSMakePoint(m_oldPoint2.x - realoffset.x, m_oldPoint2.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
                        [m_transformManager setAffineDesPoint:m_oldPoint0 AtIndex:0];
                    }
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_LEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint0.y - m_oldPoint3.y, m_oldPoint3.x - m_oldPoint0.x);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    NSPoint offset1 = NSMakePoint(part1 * partVector1.x, part1 * partVector1.y);
                    NSPoint newPoint0 = NSMakePoint(m_oldPoint0.x + offset1.x, m_oldPoint0.y + offset1.y);
                    NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x + offset1.x, m_oldPoint3.y + offset1.y);
                    
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                    break;
                }
                case SCALESTYLE_TOPLEFT:{
                    NSPoint partVector1 = NSMakePoint(m_oldPoint3.x - m_oldPoint0.x, m_oldPoint3.y - m_oldPoint0.y);
                    float length1 = sqrtf(partVector1.x * partVector1.x + partVector1.y * partVector1.y);
                    partVector1 = NSMakePoint(partVector1.x / length1, partVector1.y / length1);
                    NSPoint partVector2 = NSMakePoint(m_oldPoint1.x - m_oldPoint0.x, m_oldPoint1.y - m_oldPoint0.y);
                    float length2 = sqrtf(partVector2.x * partVector2.x + partVector2.y * partVector2.y);
                    partVector2 = NSMakePoint(partVector2.x / length2, partVector2.y / length2);
                    NSPoint offset = NSMakePoint(where.x - m_sInitialPoint.x, where.y - m_sInitialPoint.y);
                    float part1 = (partVector2.x * offset.y - offset.x * partVector2.y) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    float part2 = (partVector1.y * offset.x - offset.y * partVector1.x) / (partVector2.x * partVector1.y - partVector1.x * partVector2.y);
                    
                    NSPoint newPoint0;
                    NSPoint realoffset;
                    if (ABS(part2) > ABS(part1)) {
                        realoffset = NSMakePoint(partVector2.x * part2, partVector2.y * part2);
                        newPoint0 = NSMakePoint(m_oldPoint0.x + realoffset.x, m_oldPoint0.y + realoffset.y);
                        NSPoint newPoint1 = NSMakePoint(m_oldPoint1.x - realoffset.x, m_oldPoint1.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
                        [m_transformManager setAffineDesPoint:m_oldPoint3 AtIndex:3];
                    }else{
                        realoffset = NSMakePoint(partVector1.x * part1, partVector1.y * part1);
                        newPoint0 = NSMakePoint(m_oldPoint0.x + realoffset.x, m_oldPoint0.y + realoffset.y);
                        NSPoint newPoint3 = NSMakePoint(m_oldPoint3.x - realoffset.x, m_oldPoint3.y - realoffset.y);
                        [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
                        [m_transformManager setAffineDesPoint:m_oldPoint1 AtIndex:1];
                    }
                    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
                    
                    break;
                }
                    
                default:
                    break;
            }
            
        }
            break;
            
        case Transform_MoveCenter:{
            NSPoint newPoint4 = NSMakePoint(m_oldPoint4.x + deltax, m_oldPoint4.y + deltay);
            [m_transformManager setAffineDesPoint:newPoint4 AtIndex:4];
        }
            break;
    }
    if (m_currentTransformType == Transform_MoveCenter) {
        
    }else{
        [m_transformManager makeAffineTransform];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
    [self resetTransformToolOptions];
}

- (void)resetTransformToolOptions
{
    NSPoint point0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint point1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint point2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint point3 = [m_transformManager getAffineDesPointAtIndex:3];
    NSPoint point4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    NSPoint pointOriginal0 = [m_transformManager getAffineOriginalPointAtIndex:0];
    NSPoint pointOriginal1 = [m_transformManager getAffineOriginalPointAtIndex:1];
    NSPoint pointOriginal2 = [m_transformManager getAffineOriginalPointAtIndex:2];
    NSPoint pointOriginal3 = [m_transformManager getAffineOriginalPointAtIndex:3];
    
    [m_idOptions setPosX:point4.x];
    [m_idOptions setPosY:point4.y];
    
    NSPoint newVector = NSMakePoint(point1.x - point0.x, point1.y - point0.y);
    float degree = atan(newVector.y / newVector.x) * 180.0 / PI;
    if (newVector.x < 0) {
        degree += 180;
    }
    if (degree < 0) {
        degree += 360;
    }
    m_currentDegree = degree;
    [m_idOptions setRotate:degree];
    
    float originalWidth = sqrtf((pointOriginal1.x - pointOriginal0.x) * (pointOriginal1.x - pointOriginal0.x) + (pointOriginal1.y - pointOriginal0.y) * (pointOriginal1.y - pointOriginal0.y));
    NSPoint rightVector = NSMakePoint(point2.x - point1.x, point2.y - point1.y);
    float length = sqrtf(rightVector.x * rightVector.x + rightVector.y * rightVector.y);
    NSPoint nomalVector = NSMakePoint(-rightVector.y / length, rightVector.x / length);
    NSPoint AB = NSMakePoint(point0.x - point1.x, point0.y - point1.y);
    NSPoint AC = NSMakePoint(point0.x - point2.x, point0.y - point2.y);
    float distanceAB = ABS(nomalVector.x * AB.x + nomalVector.y * AB.y);
    float distanceAC = ABS(nomalVector.x * AC.x + nomalVector.y * AC.y);
    m_currentWidthRatio = MAX(distanceAB, distanceAC) / originalWidth;
    [(PSTransformOptions*)m_idOptions setWidth:m_currentWidthRatio];
    
    float originalHeight = sqrtf((pointOriginal2.x - pointOriginal1.x) * (pointOriginal2.x - pointOriginal1.x) + (pointOriginal2.y - pointOriginal1.y) * (pointOriginal2.y - pointOriginal1.y));
    NSPoint bottomVector = NSMakePoint(point3.x - point2.x, point3.y - point2.y);
    length = sqrtf(bottomVector.x * bottomVector.x + bottomVector.y * bottomVector.y);
    nomalVector = NSMakePoint(-bottomVector.y / length, bottomVector.x / length);
    AB = NSMakePoint(point0.x - point2.x, point0.y - point2.y);
    AC = NSMakePoint(point0.x - point3.x, point0.y - point3.y);
    distanceAB = ABS(nomalVector.x * AB.x + nomalVector.y * AB.y);
    distanceAC = ABS(nomalVector.x * AC.x + nomalVector.y * AC.y);
    m_currentHeightRatio = MAX(distanceAB, distanceAC) / originalHeight;
    [(PSTransformOptions*)m_idOptions setHeight:m_currentHeightRatio];
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;
{
    if ([m_transformManager getIfHasBeginTransform]) {
        //disable window
        if (!m_hasDisableWindow) {
            m_hasDisableWindow = YES;
        }
    }
    m_scaleSyle = SCALESTYLE_NONE;
    
    id activeLayer = [[m_idDocument contents] activeLayer];
    [activeLayer setFullRenderState:YES];
    
}

- (float)getRotatedDegreeWithBeginPoint:(NSPoint)beginPoint endPoint:(NSPoint)endPoint
{
    float length = sqrtf(beginPoint.x * beginPoint.x + beginPoint.y * beginPoint.y);
    beginPoint = NSMakePoint(beginPoint.x / length, beginPoint.y / length);
    length = sqrtf(endPoint.x * endPoint.x + endPoint.y * endPoint.y);
    beginPoint = NSMakePoint(endPoint.x / length, endPoint.y / length);
    float len_y = endPoint.y - beginPoint.y;
    float len_x = endPoint.x - beginPoint.x;
    
    float tan_yx = tan_yx = fabsf(len_y)/fabsf(len_x);
    float angle = 0;
    if(len_y > 0 && len_x < 0) {
        angle = atan(tan_yx)*180/M_PI - 90;
    } else if (len_y > 0 && len_x > 0) {
        angle = 90 - atan(tan_yx)*180/M_PI;
    } else if(len_y < 0 && len_x < 0) {
        angle = -atan(tan_yx)*180/M_PI - 90;
    } else if(len_y < 0 && len_x > 0) {
        angle = atan(tan_yx)*180/M_PI + 90;
    }
    return angle;
}

- (NSPoint)getRotatedPoint:(NSPoint)srcPoint degree:(float)degree center:(NSPoint)center
{
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:center.x yBy:center.y];
    [transform rotateByDegrees:degree];
    [transform translateXBy:-center.x yBy:-center.y];
    return [transform transformPoint:srcPoint];
}


- (void)layerAttributesChanged:(int)nLayerType
{
    if (![self getIfHasBeginTransform])
    {
        [self initialInfoForTransformTool];
    }
    
}

- (BOOL)judgePointsIsValid:(NSPoint)point0 point1:(NSPoint)point1 point2:(NSPoint)point2 point3:(NSPoint)point3
{
    if (point0.x < -45000.0 || point0.x > 45000.0)
    {
        return NO;
    }
    if (isnan(point0.x) || isnan(point0.y))
    {
        return NO;
    }
    if (ABS((point0.x - point1.x)) < 0.5 && ABS((point2.x - point3.x)) < 0.5) {
        return NO;
    }
    
    return YES;
}

- (void)drawToolExtraExtent:(NSNotification*) notification
{
    if (notification.object != [m_idDocument shadowView])
    {
        return;
    }
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex != kTransformTool)
    {
        return;
    }
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSPoint point0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint point1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint point2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint point3 = [m_transformManager getAffineDesPointAtIndex:3];
    NSPoint point4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    if (![self judgePointsIsValid:point0 point1:point1 point2:point2 point3:point3])
    {
        return;
    }
    
    NSPoint viewPoint0 = NSMakePoint(point0.x * xScale, point0.y * yScale);
    NSPoint viewPoint1 = NSMakePoint(point1.x * xScale, point1.y * yScale);
    NSPoint viewPoint2 = NSMakePoint(point2.x * xScale, point2.y * yScale);
    NSPoint viewPoint3 = NSMakePoint(point3.x * xScale, point3.y * yScale);
    NSPoint viewPoint4 = NSMakePoint(point4.x * xScale, point4.y * yScale);
    
    PSView *psview = [m_idDocument docView];
    NSView *shadowView = notification.object;
    NSPoint superPoint0 = [shadowView convertPoint: viewPoint0 fromView: psview];
    NSPoint superPoint1 = [shadowView convertPoint: viewPoint1 fromView: psview];
    NSPoint superPoint2 = [shadowView convertPoint: viewPoint2 fromView: psview];
    NSPoint superPoint3 = [shadowView convertPoint: viewPoint3 fromView: psview];
    NSPoint superPoint4 = [shadowView convertPoint: viewPoint4 fromView: psview];
    
    [self drawDragAffineHandlesPoint1:superPoint0 point2:superPoint1 point3:superPoint2 point4:superPoint3 point5:superPoint4];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeDifference);
    NSColor *color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [color set];
    
    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath setLineWidth:1.0];
    [tempPath moveToPoint:superPoint0];
    [tempPath lineToPoint:superPoint1];
    [tempPath lineToPoint:superPoint2];
    [tempPath lineToPoint:superPoint3];
    [tempPath closePath];
    [tempPath stroke];
    
    CGContextRestoreGState(context);
}


- (void)drawToolExtra
{
    //防止没有及时刷新，initial很快
    if (![self getIfHasBeginTransform])
    {
        [self initialInfoForTransformTool];
    }
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    NSPoint point0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint point1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint point2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint point3 = [m_transformManager getAffineDesPointAtIndex:3];
    NSPoint point4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    if (![self judgePointsIsValid:point0 point1:point1 point2:point2 point3:point3])
    {
        return;
    }
    
    if ([NSDate timeIntervalSinceReferenceDate] - m_lastRefreshTime > 0.1)
    {
        [[m_idDocument shadowView] setNeedsDisplay:YES];
        m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    NSPoint viewPoint0 = NSMakePoint(point0.x * xScale, point0.y * yScale);
    NSPoint viewPoint1 = NSMakePoint(point1.x * xScale, point1.y * yScale);
    NSPoint viewPoint2 = NSMakePoint(point2.x * xScale, point2.y * yScale);
    NSPoint viewPoint3 = NSMakePoint(point3.x * xScale, point3.y * yScale);
    NSPoint viewPoint4 = NSMakePoint(point4.x * xScale, point4.y * yScale);
    [self drawDragAffineHandlesPoint1:viewPoint0 point2:viewPoint1 point3:viewPoint2 point4:viewPoint3 point5:viewPoint4];
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeDifference);
    NSColor *color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [color set];
    
    NSBezierPath *tempPath = [NSBezierPath bezierPath];
    [tempPath setLineWidth:1.0];
    [tempPath moveToPoint:viewPoint0];
    [tempPath lineToPoint:viewPoint1];
    [tempPath lineToPoint:viewPoint2];
    [tempPath lineToPoint:viewPoint3];
    [tempPath closePath];
    [tempPath stroke];
    
    CGContextRestoreGState(context);
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
    CGContextSetBlendMode(context, kCGBlendModeDifference);
    NSColor *color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [color set];
    
    NSRect outside  = NSMakeRect(origin.x - 4, origin.y - 4, 8, 8);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect: outside];
    [path setLineWidth:1.0];
    [path stroke];

    CGContextRestoreGState(context);
    
    return;
    
}



- (NSMutableArray *)getToolPreviewEnabledLayer
{
    NSMutableArray *infoArray = [m_transformManager getTransformedLayerInfoArray];
    if ([infoArray count] == 0)
    {
        return nil;
    }
    else
    {
        NSMutableArray *tempArray = [NSMutableArray array];
        for (int i = 0; i < [infoArray count]; i++)
        {
            PSLayerTransformInfo *info = [infoArray objectAtIndex:i];
            [tempArray addObject:info.transformedLayer];
        }
        return tempArray;
    }
    return  nil;
    
}

- (void)drawLayerToolPreview:(RENDER_CONTEXT_INFO)contextInfo layerid:(id)layer
{
    CGContextRef context = contextInfo.context;
    NSMutableArray *infoArray = [m_transformManager getTransformedLayerInfoArray];

    for (int i = 0; i < [infoArray count]; i++)
    {
        PSLayerTransformInfo *info = [infoArray objectAtIndex:i];
        if (layer == info.transformedLayer)
        {
            int newXOffset = info.newXOffset;
            int newYOffset = info.newYOffset;
            int width = info.newWidth;
            int height = info.newHeight;
            int mode = [(PSAbstractLayer *)layer mode];
            int layerAlpha = [(PSAbstractLayer *)layer opacity];
            
            float xScale = contextInfo.scale.width;
            float yScale = contextInfo.scale.height;
            
            CGContextSaveGState(context);
            CGContextSetAlpha(context, layerAlpha/255.0);
            CGContextSetBlendMode(context, mode);
            CGRect destRect = CGRectMake(newXOffset * xScale, newYOffset * yScale, width * xScale, height * yScale);
            [m_transformManager lockNewCGLayer:YES];
            CGLayerRef cgLayer = info.newCGLayerRef;
            if (cgLayer)
            {
                CGContextDrawLayerInRect(context, destRect, cgLayer);
            }
            [m_transformManager lockNewCGLayer:NO];
            
            CGContextRestoreGState(context);

        }
    }

}

//- (void)drawLayerToolPreview:(CGContextRef)context layerid:(id)layer
//{
//    NSMutableArray *infoArray = [m_transformManager getTransformedLayerInfoArray];
//    for (int i = 0; i < [infoArray count]; i++) {
//        PSLayerTransformInfo *info = [infoArray objectAtIndex:i];
//        if (layer == info.transformedLayer) {
//            int newXOffset = info.newXOffset;
//            int newYOffset = info.newYOffset;
//            int width = info.newWidth;
//            int height = info.newHeight;
//            int mode = [(PSAbstractLayer *)layer mode];
//            int layerAlpha = [(PSAbstractLayer *)layer opacity];
//            
//            float xScale = [[m_idDocument contents] xscale];
//            float yScale = [[m_idDocument contents] yscale];
//            
//            CGContextSaveGState(context);
//            CGContextSetAlpha(context, layerAlpha/255.0);
//            CGContextSetBlendMode(context, mode);
//            CGRect destRect = CGRectMake(newXOffset * xScale, newYOffset * yScale, width * xScale, height * yScale);
//            CGLayerRef cgLayer = info.newCGLayerRef;
//            if (cgLayer) {
//                CGContextDrawLayerInRect(context, destRect, cgLayer);
//            }
//            CGContextRestoreGState(context);
//        }
//    }
//}

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

//line style 0lr 1ud 2urdl 3uldr
- (int)getSkewStyleForLine:(NSPoint)point1 point2:(NSPoint)point2
{
    int skewStyle = 0;
    float threshold = tanf(10.0 / 180.0 * PI);
    if (ABS(point1.x - point2.x) > ABS(point1.y - point2.y))
    {
        if (ABS(point1.x - point2.x) * threshold > ABS(point1.y - point2.y))
        {
            skewStyle = 0;
        }else{
            if (point1.x - point2.x > 0)
            {
                if (point1.y - point2.y > 0)
                {
                    skewStyle = 2;
                }
                else
                {
                    skewStyle = 3;
                }
            }else
            {
                if (point1.y - point2.y > 0)
                {
                    skewStyle = 3;
                }
                else
                {
                    skewStyle = 2;
                }
            }
        }
    }
    else
    {
        if (ABS(point1.y - point2.y) * threshold > ABS(point1.x - point2.x))
        {
            skewStyle = 1;
        }
        else
        {
            if (point1.x - point2.x > 0)
            {
                if (point1.y - point2.y > 0)
                {
                    skewStyle = 2;
                }
                else
                {
                    skewStyle = 3;
                }
            }
            else
            {
                if (point1.y - point2.y > 0)
                {
                    skewStyle = 3;
                }
                else
                {
                    skewStyle = 2;
                }
            }
        }
    }
    return skewStyle;
}

- (int)getSkewStyleForCorner:(NSPoint)corner point1:(NSPoint)point1 point2:(NSPoint)point2
{
    int skewStyle = 0;
    NSPoint vector = NSMakePoint(point1.x - corner.x, point1.y - corner.y);
    float length = sqrtf(vector.x * vector.x + vector.y * vector.y);
    NSPoint vector1 = NSMakePoint(vector.x / length, vector.y / length);
    
    vector = NSMakePoint(point2.x - corner.x, point2.y - corner.y);
    length = sqrtf(vector.x * vector.x + vector.y * vector.y);
    
    NSPoint vector2 = NSMakePoint(vector.x / length, vector.y / length);
    NSPoint normalVector = NSMakePoint(vector2.x - vector1.x, vector2.y - vector1.y);
    skewStyle = [self getSkewStyleForLine:NSMakePoint(0, 0) point2:normalVector];
    
    return skewStyle;
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
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
//    NSRect operableRect;
//    IntRect operableIntRect;
//    
//    operableIntRect = IntMakeRect(0, 0, [(PSContent *)[m_idDocument contents] width] * xScale, [(PSContent *)[m_idDocument contents] height] *yScale);
//    operableRect = IntRectMakeNSRect(IntConstrainRect(NSRectMakeIntRect([[m_idDocument docView] frame]), operableIntRect));
    
    
    NSScrollView *scrollView = (NSScrollView *)[[[m_idDocument docView] superview] superview];
//
//    // Convert to the scrollview's origin
//    operableRect.origin = [scrollView convertPoint: operableRect.origin fromView: [m_idDocument docView]];
//    
//    // Clip to the centering clipview
//    NSRect clippedRect = NSIntersectionRect([[[m_idDocument docView] superview] frame], operableRect);
//    
//    // Convert the point back to the seaview
//    clippedRect.origin = [[m_idDocument docView] convertPoint: clippedRect.origin fromView: scrollView];
    
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor arrowCursor] retain];
    NSPoint whereInScrollView = [scrollView convertPoint: where fromView: [m_idDocument docView]];
    if(!NSPointInRect(whereInScrollView, [scrollView bounds]))
    {
        [m_cursor set];
        return;
    }
    
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
    
    
    //NSLog(@"mouseMoveTo");
//    float xScale = [[m_idDocument contents] xscale];
//    float yScale = [[m_idDocument contents] yscale];
    NSPoint point0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint point1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint point2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint point3 = [m_transformManager getAffineDesPointAtIndex:3];
    NSPoint point4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    if (![self judgePointsIsValid:point0 point1:point1 point2:point2 point3:point3]) {
        return;
    }
    
    NSPoint viewPoint0 = NSMakePoint(point0.x * xScale, point0.y * yScale);
    NSPoint viewPoint1 = NSMakePoint(point1.x * xScale, point1.y * yScale);
    NSPoint viewPoint2 = NSMakePoint(point2.x * xScale, point2.y * yScale);
    NSPoint viewPoint3 = NSMakePoint(point3.x * xScale, point3.y * yScale);
    NSPoint viewPoint4 = NSMakePoint(point4.x * xScale, point4.y * yScale);
    
    
    int function = [m_idOptions getTransformType];
    
    NSBezierPath *rectPath = [NSBezierPath bezierPath];
    [rectPath moveToPoint:viewPoint0];
    [rectPath lineToPoint:viewPoint1];
    [rectPath lineToPoint:viewPoint2];
    [rectPath lineToPoint:viewPoint3];
    [rectPath closePath];
    
    float rectwidth = 20;
    NSRect topLeftRect = NSMakeRect(viewPoint0.x - rectwidth / 2, viewPoint0.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect topRightRect = NSMakeRect(viewPoint1.x - rectwidth / 2, viewPoint1.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect bottomRightRect = NSMakeRect(viewPoint2.x - rectwidth / 2, viewPoint2.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect bottomLeftRect = NSMakeRect(viewPoint3.x - rectwidth / 2, viewPoint3.y - rectwidth / 2, rectwidth, rectwidth);
    NSRect centerRect = NSMakeRect(viewPoint4.x - rectwidth / 2, viewPoint4.y - rectwidth / 2, rectwidth, rectwidth);
    
    float bandWidth = 16;
    NSBezierPath *topPath = [self getRectBetweenTwoPoints:viewPoint0 point2:viewPoint1 width:bandWidth];
    NSBezierPath *rightPath = [self getRectBetweenTwoPoints:viewPoint1 point2:viewPoint2 width:bandWidth];
    NSBezierPath *bottomPath = [self getRectBetweenTwoPoints:viewPoint2 point2:viewPoint3 width:bandWidth];
    NSBezierPath *leftPath = [self getRectBetweenTwoPoints:viewPoint3 point2:viewPoint0 width:bandWidth];
    
    
    //four skew syle
    int topSkewStyle = [self getSkewStyleForLine:viewPoint0 point2:viewPoint1];
    int rightSkewStyle = [self getSkewStyleForLine:viewPoint1 point2:viewPoint2];
    int bottomSkewStyle = [self getSkewStyleForLine:viewPoint2 point2:viewPoint3];
    int leftSkewStyle = [self getSkewStyleForLine:viewPoint3 point2:viewPoint0];
    int topLeftSkewStyle = [self getSkewStyleForCorner:viewPoint0 point1:viewPoint1 point2:viewPoint3];
    int topRightSkewStyle = [self getSkewStyleForCorner:viewPoint1 point1:viewPoint0 point2:viewPoint2];
    int bottomRightSkewStyle = [self getSkewStyleForCorner:viewPoint2 point1:viewPoint1 point2:viewPoint3];
    int bottomLeftSkewStyle = [self getSkewStyleForCorner:viewPoint3 point1:viewPoint2 point2:viewPoint0];
    
    PSView *psview = [m_idDocument docView];
//    NSScrollView *scrollView = (NSScrollView *)[[psview superview] superview];
    NSPoint superWhere = [scrollView convertPoint: where fromView: psview];
    NSRect superBounds = [scrollView bounds];
    //NSLog(@"super %@,%@,%@",NSStringFromPoint(superWhere),NSStringFromPoint(where), NSStringFromRect(superBounds));
    
    
    switch (function)
    {
        case Transform_Move:
        {
            if (NSPointInRect(where, centerRect))
            {
                [curMoveCenter set];
            }
            else if ([rectPath containsPoint:where])
            {
                [curMove set];
            }
            else
            {
                [[NSCursor arrowCursor] set];
            }
        }
            break;
        case Transform_Scale:
        {
            if (NSPointInRect(where, topLeftRect))
            {
                switch (topLeftSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if (NSPointInRect(where, topRightRect))
            {
                switch (topRightSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if (NSPointInRect(where, bottomRightRect))
            {
                switch (bottomRightSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if (NSPointInRect(where, bottomLeftRect))
            {
                switch (bottomLeftSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if (NSPointInRect(where, centerRect))
            {
                [curMoveCenter set];
            }
            else if ([topPath containsPoint:where])
            {
                switch (topSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if ([rightPath containsPoint:where])
            {
                switch (rightSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if ([bottomPath containsPoint:where])
            {
                switch (bottomSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if ([leftPath containsPoint:where])
            {
                switch (leftSkewStyle)
                {
                    case 0:
                        [curUd set];
                        break;
                    case 1:
                        [curLr set];
                        break;
                    case 2:
                        [curUrdl set];
                        break;
                    case 3:
                        [curUldr set];
                        break;
                    default:
                        break;
                }
            }
            else if ([rectPath containsPoint:where])
            {
                [curMove set];
            }
            else if (NSPointInRect(superWhere, superBounds))
            {
                int nDir = [self getRotationDirectionFrom:where pointCenter:viewPoint4];
                [curRotate8[nDir] set];
                //[curRotate set];
            }
            else
            {
                [[NSCursor arrowCursor] set];
            }
            
        }
            break;
        case Transform_Rotate:
        {
            if (NSPointInRect(where, centerRect))
            {
                [curMoveCenter set];
            }
            else if ([rectPath containsPoint:where])
            {
                [curMove set];
            }
            else if (NSPointInRect(superWhere, superBounds))
            {
                int nDir = [self getRotationDirectionFrom:where pointCenter:viewPoint4];
                [curRotate8[nDir] set];
            }
            else
            {
                [[NSCursor arrowCursor] set];
            }
            
        }
            break;
            
        case Transform_Skew:
        {
            if (NSPointInRect(where, NSMakeRect(viewPoint0.x - rectwidth / 2, viewPoint0.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint1.x - rectwidth / 2, viewPoint1.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint2.x - rectwidth / 2, viewPoint2.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint3.x - rectwidth / 2, viewPoint3.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint4.x - rectwidth / 2, viewPoint4.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curMoveCenter set];
            }
            else if ([topPath containsPoint:where])
            {
                switch (topSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([rightPath containsPoint:where])
            {
                switch (rightSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([bottomPath containsPoint:where])
            {
                switch (bottomSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }else if ([leftPath containsPoint:where])
            {
                switch (leftSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([rectPath containsPoint:where])
            {
                [curMove set];
            }
            else
            {
                [[NSCursor arrowCursor] set];
            }
            
        }
            break;
            
        case Transform_Perspective:
        {
            if (NSPointInRect(where, NSMakeRect(viewPoint0.x - rectwidth / 2, viewPoint0.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint1.x - rectwidth / 2, viewPoint1.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint2.x - rectwidth / 2, viewPoint2.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint3.x - rectwidth / 2, viewPoint3.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curSkewCorner set];
            }
            else if (NSPointInRect(where, NSMakeRect(viewPoint4.x - rectwidth / 2, viewPoint4.y - rectwidth / 2, rectwidth, rectwidth)))
            {
                [curMoveCenter set];
            }
            else if ([topPath containsPoint:where])
            {
                switch (topSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([rightPath containsPoint:where])
            {
                switch (rightSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([bottomPath containsPoint:where])
            {
                switch (bottomSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([leftPath containsPoint:where])
            {
                switch (leftSkewStyle)
                {
                    case 0:
                        [curSkewLr set];
                        break;
                    case 1:
                        [curSkewUd set];
                        break;
                    case 2:
                        [curSkewUldr set];
                        break;
                    case 3:
                        [curSkewUrdl set];
                        break;
                    default:
                        break;
                }
            }
            else if ([rectPath containsPoint:where])
            {
                [curMove set];
            }
            else
            {
                [[NSCursor arrowCursor] set];
            }
            
        }
            break;
            
            
        default:
            break;
    }
    
}

- (void)setScaleStyle:(int)style
{
    m_scaleSyle = style;
}

- (void)initialInfoForTransformTool
{
    [m_idOptions setTransformTool:self];
    m_hasDisableWindow = NO;
    [m_transformManager initialAffineInfo];
    [[m_idDocument window] disableCursorRects];
    [self resetTransformToolOptions];
}

- (BOOL)getIfHasBeginTransform
{
    return [m_transformManager getIfHasBeginTransform];
}

- (void)changeToolFromTransformTool:(int)newtool
{
    m_willChangeToTool = newtool;
    BOOL hasBeginApply = [m_transformManager getIfHasBeginTransform];
    if (hasBeginApply) {
        //NSAlert *alert = [NSAlert alertWithMessageText:@"will apply the transform?" defaultButton:@"Apply" alternateButton:@"Don't Apply" otherButton:@"Cancel" informativeTextWithFormat:@""];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Apply", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Don't Apply", nil)];
        [alert setMessageText:NSLocalizedString(@"Will apply the transform ?", nil) ];
        [alert setInformativeText:@""];
        
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[m_idDocument window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        
    }
    else{
        [m_transformManager doNotApplyAffineTransform];
        [[m_idDocument shadowView] setNeedsDisplay:YES];
        [[m_idDocument window] enableCursorRects];
        [[m_idDocument window] resetCursorRects];
    }
    
    
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo

{
    if (returnCode == NSAlertFirstButtonReturn)
    {
        [m_transformManager applyAffineTransform];
        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:m_willChangeToTool];
    }
    else if (returnCode == NSAlertSecondButtonReturn)
    { //cancle
        return;
    }
    else if (returnCode == NSAlertThirdButtonReturn)
    {
        [m_transformManager doNotApplyAffineTransform];
        [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] changeToolTo:m_willChangeToTool];
    }
    
    [[m_idDocument shadowView] setNeedsDisplay:YES];
    [[m_idDocument window] enableCursorRects];
    [[m_idDocument window] resetCursorRects];
    
}


- (void)redoUndoEventDidEndForLayer:(id)layer;
{
    [self initialInfoForTransformTool];
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelperForLayer:layer];
}


#pragma mark - change transform matrix data

- (void)applyTransform
{
    [m_transformManager applyAffineTransform];
    
    [[m_idDocument shadowView] setNeedsDisplay:YES];
    [[m_idDocument window] enableCursorRects];
    [[m_idDocument window] resetCursorRects];
    m_hasDisableWindow = NO;
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex == kTransformTool) {
        [self initialInfoForTransformTool];
    }
    
    [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
    
}

- (void)cancelTransform
{
    [m_transformManager doNotApplyAffineTransform];
    
    [[m_idDocument shadowView] setNeedsDisplay:YES];
    [[m_idDocument window] enableCursorRects];
    [[m_idDocument window] resetCursorRects];
    m_hasDisableWindow = NO;
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex == kTransformTool) {
        [self initialInfoForTransformTool];
    }
}

- (void)setCenterPointPositionType:(int)type
{
    NSPoint oldPoint0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint oldPoint1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint oldPoint2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint oldPoint3 = [m_transformManager getAffineDesPointAtIndex:3];
    NSPoint oldPoint4 = [m_transformManager getAffineDesPointAtIndex:4];
    NSPoint topPoint = NSMakePoint((oldPoint0.x + oldPoint1.x) / 2.0, (oldPoint0.y + oldPoint1.y) / 2.0);
    NSPoint rightPoint = NSMakePoint((oldPoint1.x + oldPoint2.x) / 2.0, (oldPoint1.y + oldPoint2.y) / 2.0);
    NSPoint bottomPoint = NSMakePoint((oldPoint2.x + oldPoint3.x) / 2.0, (oldPoint2.y + oldPoint3.y) / 2.0);
    NSPoint leftPoint = NSMakePoint((oldPoint0.x + oldPoint3.x) / 2.0, (oldPoint0.y + oldPoint3.y) / 2.0);
    switch (type) {
        case 0:
            break;
        case 1:
            [m_transformManager setAffineDesPoint:oldPoint0 AtIndex:4];
            break;
        case 2:
            [m_transformManager setAffineDesPoint:topPoint AtIndex:4];
            break;
        case 3:
            [m_transformManager setAffineDesPoint:oldPoint1 AtIndex:4];
            break;
        case 4:
            [m_transformManager setAffineDesPoint:leftPoint AtIndex:4];
            break;
        case 5:
            [m_transformManager setAffineDesPoint:oldPoint4 AtIndex:4];
            break;
        case 6:
            [m_transformManager setAffineDesPoint:rightPoint AtIndex:4];
            break;
        case 7:
            [m_transformManager setAffineDesPoint:oldPoint3 AtIndex:4];
            break;
        case 8:
            [m_transformManager setAffineDesPoint:bottomPoint AtIndex:4];
            break;
        case 9:
            [m_transformManager setAffineDesPoint:oldPoint2 AtIndex:4];
            break;
            
        default:
            break;
    }
    
    m_centerPointType = type;
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (void)setCenterXOffset:(float)xoff
{
    NSPoint oldPoint4 = [m_transformManager getAffineDesPointAtIndex:4];
    NSPoint newPoint4 = NSMakePoint(xoff, oldPoint4.y);
    [m_transformManager setAffineDesPoint:newPoint4 AtIndex:4];
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (void)setCenterYOffset:(float)yoff
{
    NSPoint oldPoint4 = [m_transformManager getAffineDesPointAtIndex:4];
    NSPoint newPoint4 = NSMakePoint(oldPoint4.x, yoff);
    [m_transformManager setAffineDesPoint:newPoint4 AtIndex:4];
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
    
}

- (void)setWidthRatio:(float)newRatio
{
    NSPoint point0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint point1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint point2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint point3 = [m_transformManager getAffineDesPointAtIndex:3];
    //NSPoint point4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    NSPoint pointOriginal0 = [m_transformManager getAffineOriginalPointAtIndex:0];
    NSPoint pointOriginal1 = [m_transformManager getAffineOriginalPointAtIndex:1];
    //NSPoint pointOriginal2 = [m_transformManager getAffineOriginalPointAtIndex:2];
    //NSPoint pointOriginal3 = [m_transformManager getAffineOriginalPointAtIndex:3];
    
    
    float originalWidth = sqrtf((pointOriginal1.x - pointOriginal0.x) * (pointOriginal1.x - pointOriginal0.x) + (pointOriginal1.y - pointOriginal0.y) * (pointOriginal1.y - pointOriginal0.y));
    float currentWidth = originalWidth * m_currentWidthRatio;
    float newWidth = originalWidth * newRatio;
    float difWidth = newWidth - currentWidth;
    NSPoint rightVector = NSMakePoint(point2.x - point1.x, point2.y - point1.y);
    float length = sqrtf(rightVector.x * rightVector.x + rightVector.y * rightVector.y);
    NSPoint difVector = NSMakePoint(-rightVector.y / length * difWidth / 2.0, rightVector.x / length * difWidth / 2.0);
    NSPoint newPoint0 = NSMakePoint(point0.x + difVector.x, point0.y + difVector.y);
    NSPoint newPoint3 = NSMakePoint(point3.x + difVector.x, point3.y + difVector.y);
    NSPoint newPoint1 = NSMakePoint(point1.x - difVector.x, point1.y - difVector.y);
    NSPoint newPoint2 = NSMakePoint(point2.x - difVector.x, point2.y - difVector.y);
    
    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
    
    m_currentWidthRatio = newRatio;
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
    
    [m_transformManager makeAffineTransform];
    
    
}

- (void)setHeightRatio:(float)newRatio
{
    NSPoint point0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint point1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint point2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint point3 = [m_transformManager getAffineDesPointAtIndex:3];
    //NSPoint point4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    //NSPoint pointOriginal0 = [m_transformManager getAffineOriginalPointAtIndex:0];
    NSPoint pointOriginal1 = [m_transformManager getAffineOriginalPointAtIndex:1];
    NSPoint pointOriginal2 = [m_transformManager getAffineOriginalPointAtIndex:2];
    //NSPoint pointOriginal3 = [m_transformManager getAffineOriginalPointAtIndex:3];
    
    
    float originalHeight = sqrtf((pointOriginal2.x - pointOriginal1.x) * (pointOriginal2.x - pointOriginal1.x) + (pointOriginal2.y - pointOriginal1.y) * (pointOriginal2.y - pointOriginal1.y));
    float currentHeight = originalHeight * m_currentHeightRatio;
    float newHeight = originalHeight * newRatio;
    float difHeight = newHeight - currentHeight;
    NSPoint bottomVector = NSMakePoint(point3.x - point2.x, point3.y - point2.y);
    float length = sqrtf(bottomVector.x * bottomVector.x + bottomVector.y * bottomVector.y);
    NSPoint difVector = NSMakePoint(-bottomVector.y / length * difHeight / 2.0, bottomVector.x / length * difHeight / 2.0);
    NSPoint newPoint0 = NSMakePoint(point0.x + difVector.x, point0.y + difVector.y);
    NSPoint newPoint1 = NSMakePoint(point1.x + difVector.x, point1.y + difVector.y);
    NSPoint newPoint2 = NSMakePoint(point2.x - difVector.x, point2.y - difVector.y);
    NSPoint newPoint3 = NSMakePoint(point3.x - difVector.x, point3.y - difVector.y);
    
    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
    
    m_currentHeightRatio = newRatio;
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
    
    [m_transformManager makeAffineTransform];
    
}

- (void)setRotateDegree:(float)newDegree
{
    float degree = newDegree - m_currentDegree;
    
    NSPoint oldPoint0 = [m_transformManager getAffineDesPointAtIndex:0];
    NSPoint oldPoint1 = [m_transformManager getAffineDesPointAtIndex:1];
    NSPoint oldPoint2 = [m_transformManager getAffineDesPointAtIndex:2];
    NSPoint oldPoint3 = [m_transformManager getAffineDesPointAtIndex:3];
    NSPoint oldPoint4 = [m_transformManager getAffineDesPointAtIndex:4];
    
    NSPoint newPoint0 = [self getRotatedPoint:oldPoint0 degree:degree center:oldPoint4];
    NSPoint newPoint1 = [self getRotatedPoint:oldPoint1 degree:degree center:oldPoint4];
    NSPoint newPoint2 = [self getRotatedPoint:oldPoint2 degree:degree center:oldPoint4];
    NSPoint newPoint3 = [self getRotatedPoint:oldPoint3 degree:degree center:oldPoint4];
    [m_transformManager setAffineDesPoint:newPoint0 AtIndex:0];
    [m_transformManager setAffineDesPoint:newPoint1 AtIndex:1];
    [m_transformManager setAffineDesPoint:newPoint2 AtIndex:2];
    [m_transformManager setAffineDesPoint:newPoint3 AtIndex:3];
    
    m_currentDegree = newDegree;
    
    BOOL hasBegin = [m_transformManager getIfHasBeginTransform];
    if (hasBegin) {
        [m_idOptions setApplyCancelBtnHidden:NO];
    }else{
        [m_idOptions setApplyCancelBtnHidden:YES];
    }
    [[m_idDocument docView] setNeedsDisplay:YES];
    
    [m_transformManager makeAffineTransform];
}

#pragma mark - Tool Enter/Exit
-(BOOL)enterTool
{
    [super enterTool];
    
    [self initialInfoForTransformTool];
    
    return YES;
}

-(BOOL)exitTool:(int)newTool
{
    [self changeToolFromTransformTool:newTool];
    if ([self getIfHasBeginTransform])
    {
        return NO;
    }
    
    [m_idOptions setApplyCancelBtnHidden:YES];
    
    return [super exitTool:newTool];
}

- (BOOL)enterKeyPressed
{
    if ([self getIfHasBeginTransform]) {
        [self applyTransform];
        [m_idOptions setApplyCancelBtnHidden:YES];
        
        ToolboxUtility *toolUtility = (ToolboxUtility *)[(UtilitiesManager *)[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
        if(toolUtility)
        {
            [toolUtility switchToolWithToolIndex:kPositionTool];
        }
        
        return YES;
    }
    return NO;
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    switch ([menuItem tag]) {
        case 210:
        case 211:
        case 212:
            return YES;
            break;
            
        default:
            break;
    }
    BOOL hasBeginApply = [m_transformManager getIfHasBeginTransform];
    if (hasBeginApply) return NO;
    
    return YES;
}

#pragma mark - UI View
- (BOOL)canResponseForView:(id)view
{
    if ([self getIfHasBeginTransform])
    {
        //先这样处理，以后若要分多个View不同 响应方式时，可以 直接在基类中引入几个view的IBoutlet直接判断view是否相等，再进行返回
//        if(view == [[PSController utilitiesManager] pegasusUtilityFor:gCurrentDocument])
        
        NSBeep();
        return NO;
    }

    return YES;
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
//    if(nLayerFormat == PS_VECTOR_LAYER)
//        return NO;
    
    return YES;
}

- (void)autoTransformKeepRatio
{
    NSCAssert(m_transformManager, @"autoTransformKeepRatio m_transformManager");

    id contents = [m_idDocument contents];
    PSAbstractLayer *activeLayer = (PSAbstractLayer *)[contents activeLayer];

    if(!activeLayer)  return;
    if([activeLayer layerFormat] != PS_RASTER_LAYER)  return;
    
    int widthCanvas   = [(PSContent *)[m_idDocument contents] width];
    int heightCanvas  = [(PSContent *)[m_idDocument contents] height];
    int widthLayer    = [activeLayer width];
    int heightLayer    = [activeLayer height];
    
    if(!widthLayer || !heightLayer || !widthCanvas || !heightCanvas)
        return;
 
    [m_transformManager setIfHasBeginTransform:YES];
    [m_transformManager initialAffineInfo];
    
    if(widthLayer > widthCanvas || heightLayer > heightCanvas)
    {

        if((CGFloat)widthCanvas/(CGFloat)heightCanvas > (CGFloat)widthLayer/(CGFloat)heightLayer)
        {
            CGFloat newWidth = (CGFloat)widthLayer/((CGFloat)heightLayer/(CGFloat)heightCanvas);
            CGFloat xoffset = ((CGFloat)widthCanvas - (CGFloat)newWidth)/2.0;
            
            [m_transformManager setAffineDesPoint:NSMakePoint(xoffset, 0.0)             AtIndex:0];
            [m_transformManager setAffineDesPoint:NSMakePoint(xoffset+newWidth, 0.0)    AtIndex:1];
            [m_transformManager setAffineDesPoint:NSMakePoint(xoffset+newWidth, heightCanvas) AtIndex:2];
            [m_transformManager setAffineDesPoint:NSMakePoint(xoffset, heightCanvas)    AtIndex:3];
        }
        else
        {
            CGFloat newHeight = (CGFloat)heightLayer/((CGFloat)widthLayer/(CGFloat)widthCanvas);
            CGFloat yoffset = ((CGFloat)heightCanvas - (CGFloat)newHeight)/2.0;
            
            [m_transformManager setAffineDesPoint:NSMakePoint(0.0, yoffset)             AtIndex:0];
            [m_transformManager setAffineDesPoint:NSMakePoint(widthCanvas, yoffset)    AtIndex:1];
            [m_transformManager setAffineDesPoint:NSMakePoint(widthCanvas, yoffset + newHeight) AtIndex:2];
            [m_transformManager setAffineDesPoint:NSMakePoint(0.0, yoffset + newHeight)    AtIndex:3];
        }
    }
    
    [m_transformManager makeAffineTransform];
    
  //  [[m_idDocument docView] setNeedsDisplay:YES];
    [self resetTransformToolOptions];
     [(PSTransformOptions *)m_idOptions setApplyCancelBtnHidden:NO];

}

- (void)autoTransformStretch
{
}

- (void)autoTransformCutEdge
{
}


@end
