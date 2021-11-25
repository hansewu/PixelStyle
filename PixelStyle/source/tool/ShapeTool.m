//
//  ShapeTool.m
//  PixelStyle
//
//  Created by wyl on 16/2/24.
//
//

#import "ShapeTool.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSHelpers.h"
#import "PSContent.h"
#import "PSVecLayer.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "ToolboxUtility.h"
#import "PSTools.h"
#import "ShapeOptions.h"

#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDUtilities.h"
#import "WDPath.h"
#import "WDBezierNode.h"
#import "WDLayer.h"

#define KMinDifferent 3
@implementation ShapeTool

- (int)toolId
{
    return kShapeTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Shape Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"U";
}

- (id)init
{
    if(![super init])
        return NULL;
    
    m_MouseDownInfo.bMouseDownInArea   = NO;
    
    m_pathTemp                          = nil;
    
    m_cursor = [[NSCursor crosshairCursor] retain];
    
    return self;
}

- (void)dealloc
{
    if(m_pathTemp){[m_pathTemp release]; m_pathTemp = nil;}
    
    [super dealloc];
}

- (void)shutDown
{
    
}

- (void)fineMouseDownAt_paint:(NSPoint)iwhere withEvent:(NSEvent *)event
{
    m_MouseDownInfo.bMouseDownInArea   = YES;
    m_MouseDownInfo.bMovingInLayer        = NO;
    m_MouseDownInfo.pointMouseDown    = iwhere;
    
    m_MouseDownInfo.timeMouseDown      = [[NSDate date] timeIntervalSince1970];
    
    if(m_pathTemp) { [m_pathTemp release]; m_pathTemp = nil;}
}

- (void)fineMouseDraggedTo_paint:(NSPoint)where withEvent:(NSEvent *)event
{
    if(!m_MouseDownInfo.bMouseDownInArea)
    {
        [self fineMouseDownAt:where withEvent:event];
        
        return;
    }
    
    if(!m_MouseDownInfo.bMovingInLayer)
        if(fabs(where.x - m_MouseDownInfo.pointMouseDown.x) < KMinDifferent || (fabs(where.y - m_MouseDownInfo.pointMouseDown.y) < KMinDifferent)) return;
    
    if([[NSDate date] timeIntervalSince1970] - m_MouseDownInfo.timeMouseDown > 0.1)
    {
        
        PSContent *contents = (PSContent *)[m_idDocument contents];
        WDDrawingController *wdDrawingController = [contents wdDrawingController];
        [wdDrawingController selectNone:nil];
        
        m_MouseDownInfo.bMovingInLayer        = YES;
        
        if(m_pathTemp) { [m_pathTemp release]; m_pathTemp = nil;}
        
        BOOL constrain = NO;
        if ([m_idOptions modifier] == kShiftModifier)
        {
            constrain = YES;
        }
        m_pathTemp = [self pathWithPoint:where constrain:constrain];
        
        PSView *view =  (PSView *)[m_idDocument docView];
        [view setNeedsDisplay:YES];
    }

}

- (void)fineMouseUpAt_paint:(NSPoint)iwhere withEvent:(NSEvent *)theEvent
{
    m_MouseDownInfo.bMouseDownInArea   = NO;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    
    if(m_MouseDownInfo.bMovingInLayer)
    {
        if ([(ShapeOptions *)m_idOptions isNewLayerOptionEnable])
        {
            [contents addVectorLayer:kActiveLayer];
        }
        else
        {
            [super checkCurrentLayerIsSupported];
        }
        
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
        if([layer layerFormat] != PS_VECTOR_LAYER)  return;
        
        PSVecLayer *layerVector = (PSVecLayer *)layer;
        
        CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
        
        [m_pathTemp transform:transform];
        [layerVector addPathObject:m_pathTemp];
        WDDrawingController *wdDrawingController = [contents wdDrawingController];
        [wdDrawingController selectObject:m_pathTemp];
        
        [(PSHelpers *)[m_idDocument helpers] updateLayerThumbnailInHelper];
        
        [self setTransformType:Transform_Scale];
        
        return;
    }
    
    [self setTransformType:Transform_Scale];
    
    
    
    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
        if([layer layerFormat] != PS_VECTOR_LAYER)
            continue;
        
        PSVecLayer *layerVector = (PSVecLayer *)layer;
        
        IntRect layerRect = [layerVector localRect];
        if(CGRectContainsPoint(IntRectMakeNSRect(layerRect), iwhere))//IntPointMakeNSPoint(iwhere)))
        {
            if([[m_idDocument contents] activeLayer] != layer)
            {
                [contents setActiveLayerIndexComplete:[layer index]];
            }
            
            return;
        }
    }

}



- (void)fineMouseDownAt:(NSPoint)iwhere withEvent:(NSEvent *)event
{
    m_cgPointInit = NSPointToCGPoint(iwhere);
    m_bDragged = NO;
    //变换
    if(![(ShapeOptions *)m_idOptions optionKeyEnable])
    {
        if(m_enumTransfomType != Transform_NO)
        {
            IntPoint point;
            point.x = iwhere.x - [[[m_idDocument contents] activeLayer] xoff];
            point.y = iwhere.y - [[[m_idDocument contents] activeLayer] yoff];
            [m_vectorTransformManager mouseDownAt:point withEvent:event];
            
            PSPickResultType pickType = [m_vectorTransformManager getPickType];
            if(pickType != PICK_NONE) {
                [self fineMouseDownAt_paint:iwhere withEvent:event];
                return;
            }
          //  else
            //    [m_vectorTransformManager mouseUpAt:point withEvent:event];
        
        }
    }
  
    if(m_enumTransfomType != Transform_NO)
        [self setTransformType:Transform_NO];
  
    //移动
    [super fineMouseDownAt:iwhere withEvent:event];
    
    if([(ShapeOptions *)m_idOptions optionKeyEnable]) return;
    if([(ShapeOptions *)m_idOptions shiftKeyEnable]) return;
  
    //绘制
    
    [self fineMouseDownAt_paint:iwhere withEvent:event];
    
    return;

}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(!m_bDragged)
        if(fabs(where.x - m_cgPointInit.x) < KMinDifferent && (fabs(where.y - m_cgPointInit.y) < KMinDifferent)) return;
    
    m_bDragged = YES;
    
    //变换
     if(![(ShapeOptions *)m_idOptions optionKeyEnable])
     {
         if((m_enumTransfomType != Transform_NO && ([m_vectorTransformManager getPickType] != PICK_NONE)))
         {
            IntPoint point;
            point.x = where.x - [[[m_idDocument contents] activeLayer] xoff];
            point.y = where.y - [[[m_idDocument contents] activeLayer] yoff];
            [m_vectorTransformManager mouseDraggedTo:point withEvent:event];
            return;
         }
     }
    
    //移动
    [super fineMouseDraggedTo:where withEvent:event];
    if([(ShapeOptions *)m_idOptions optionKeyEnable]) return;
    if([(ShapeOptions *)m_idOptions shiftKeyEnable]) return;
    //绘制
    
    [self fineMouseDraggedTo_paint:where withEvent:event];
    
    return;
    

}

- (void)fineMouseUpAt:(NSPoint)iwhere withEvent:(NSEvent *)theEvent
{
    //变换
    if(![(ShapeOptions *)m_idOptions optionKeyEnable])
    {
        if((m_enumTransfomType != Transform_NO && ([m_vectorTransformManager getPickType] != PICK_NONE)))
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
    }
    
    //移动
    [self setTransformType:Transform_NO];
    [super fineMouseUpAt:iwhere withEvent:theEvent];
    if([(ShapeOptions *)m_idOptions optionKeyEnable] || ([(ShapeOptions *)m_idOptions shiftKeyEnable]))
    {
        [self setTransformType:Transform_Scale];
        return;
    }
    
    //绘制
    [self fineMouseUpAt_paint:iwhere withEvent:theEvent];
    
    return;
    
    
}



-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
//    if(m_enumTransfomType == Transform_NO)
//    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor crosshairCursor] retain];
//    }
    [super mouseMoveTo:where withEvent:event];
}

- (void)layerAttributesChanged:(int)nLayerType
{
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    WDDrawingController *wdDrawingController = [contents wdDrawingController];
//    [wdDrawingController selectNone:nil];
}



- (void)drawToolExtra
{

    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if( curToolIndex != [self toolId]) return;
    
    if(m_MouseDownInfo.bMouseDownInArea)
        [self drawAuxiliaryLine];  //painting
//
//    else
//        [self drawSelectedObjectExtra];
    
    [super drawToolExtra];
}

- (WDPath *) pathWithPoint:(CGPoint)pt constrain:(BOOL)constrain
{
    WDPath *path = nil;
    CGPoint initialPoint = m_MouseDownInfo.pointMouseDown;
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    WDStrokeStyle *stroke = [propertyManager activeStrokeStyle];
    
    
    int nShapeMode = [(ShapeOptions *)m_idOptions shapeMode];
    if (nShapeMode == PSShapeOval)
    {
        CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
        path = [WDPath pathWithOvalInRect:rect];
        [path retain];
        
    }
    else if (nShapeMode == PSShapeRectangle)
    {
        CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
        
        float fRectCornerRadius = [(ShapeOptions *)m_idOptions rectCornerRadius];
        path = [WDPath pathWithRoundedRect:rect cornerRadius:fRectCornerRadius];
        [path retain];
    }
    else if (nShapeMode == PSShapeLine)
    {
        if (constrain)
        {
            CGPoint delta = WDConstrainPoint(WDSubtractPoints(pt, initialPoint));
            pt = WDAddPoints(initialPoint, delta);
        }
        
        path = [WDPath pathWithStart:initialPoint end:pt];
        [path retain];
    }
    else if (nShapeMode== PSShapePolygon)
    {
        int nPolygonNumPoints = [(ShapeOptions *)m_idOptions polygonNumPoints];
        
        NSMutableArray  *nodes = [NSMutableArray array];
        CGPoint         delta = WDSubtractPoints(pt, initialPoint);
        float           angle, x, y, theta = M_PI * 2 / nPolygonNumPoints;
        float           radius = WDDistance(initialPoint, pt);
        float           offsetAngle = atan2(delta.y, delta.x);
        
        for(int i = 0; i < nPolygonNumPoints; i++)
        {
            angle = theta * i + offsetAngle;
            
            x = cos(angle) * radius;
            y = sin(angle) * radius;
            
            [nodes addObject:[WDBezierNode bezierNodeWithAnchorPoint:CGPointMake(x + initialPoint.x, y + initialPoint.y)]];
        }
        
        path = [[WDPath alloc] init];
        path.nodes = nodes;
        path.closed = YES;
        //    return path;
    }
    else if (nShapeMode == PSShapeStar)
    {
        
        int nStarNumPoints = [(ShapeOptions *)m_idOptions starNumPoints];
        float fStarInnerRadiusRatio = [(ShapeOptions *)m_idOptions starInnerRadiusRatio];
        
        float   outerRadius = WDDistance(pt, initialPoint);
        
        if (outerRadius == 0)
        {
            return nil;
        }
        
        if (constrain)
        {
            float tempInner = fStarInnerRadiusRatio * m_fLastStarRadius;
            fStarInnerRadiusRatio = WDClamp(0.05, 2.0, tempInner / outerRadius);
        }
        m_fLastStarRadius = outerRadius;
        
        float   ratioToUse = fStarInnerRadiusRatio;
        float   kappa = (M_PI * 2) / nStarNumPoints;
        float   optimalRatio = cos(kappa) / cos(kappa / 2);
        
        if ((nStarNumPoints > 4) && (fStarInnerRadiusRatio / optimalRatio > 0.95) && (fStarInnerRadiusRatio / optimalRatio < 1.05)) {
            ratioToUse = optimalRatio;
        }
        
        //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //    [defaults setFloat:ratioToUse forKey:WDShapeToolStarInnerRadiusRatio];
        
        NSMutableArray  *nodes = [NSMutableArray array];
        CGPoint         delta = WDSubtractPoints(pt, initialPoint);
        float           innerRadius = outerRadius * ratioToUse;
        float           angle, x, y;
        float           theta = M_PI / nStarNumPoints; // == (360 degrees / numPoints) / 2.0
        float           offsetAngle = atan2(delta.y, delta.x);
        
        for(int i = 0; i < nStarNumPoints * 2; i += 2)
        {
            angle = theta * i + offsetAngle;
            x = cos(angle) * outerRadius;
            y = sin(angle) * outerRadius;
            
            [nodes addObject:[WDBezierNode bezierNodeWithAnchorPoint:CGPointMake(x + initialPoint.x, y + initialPoint.y)]];
            
            angle = theta * (i+1) + offsetAngle;
            x = cos(angle) * innerRadius;
            y = sin(angle) * innerRadius;
            
            [nodes addObject:[WDBezierNode bezierNodeWithAnchorPoint:CGPointMake(x + initialPoint.x, y + initialPoint.y)]];
        }
        
        path = [[WDPath alloc] init];
        path.nodes = nodes;
        path.closed = YES;
        //  return path;
    }
    else if (nShapeMode == PSShapeSpiral)
    {
        int nSpiralDecay = [(ShapeOptions *)m_idOptions spiralDecay];
        
        float       radius = WDDistance(pt, initialPoint);
        CGPoint     delta = WDSubtractPoints(pt, initialPoint);
        float       offsetAngle = atan2(delta.y, delta.x) + M_PI;
        int         segments = 20;
        float       b = 1.0f - (nSpiralDecay / 100.f);
        float       a = radius / pow(M_E, b * segments * M_PI_4);
        
        NSMutableArray  *nodes = [NSMutableArray array];
        
        for (int segment = 0; segment <= segments; segment++)
        {
            float t = segment * M_PI_4;
            float f = a * pow(M_E, b * t);
            float x = f * cos(t);
            float y = f * sin(t);
            
            CGPoint P3 = CGPointMake(x, y);
            
            // derivative
            float t0 = t - M_PI_4;
            float deltaT = (t - t0) / 3;
            
            float xPrime = a*b*pow(M_E,b*t)*cos(t) - a*pow(M_E,b*t)*sin(t);
            float yPrime = a*pow(M_E,b*t)*cos(t) + a*b*pow(M_E,b*t)*sin(t);
            
            CGPoint P2 = WDSubtractPoints(P3, WDMultiplyPointScalar(CGPointMake(xPrime, yPrime), deltaT));
            CGPoint P1 = WDAddPoints(P3, WDMultiplyPointScalar(CGPointMake(xPrime, yPrime), deltaT));
            
            [nodes addObject:[WDBezierNode bezierNodeWithInPoint:P2 anchorPoint:P3 outPoint:P1]];
        }
        
        path = [[WDPath alloc] init];
        path.nodes = nodes;
        
        CGAffineTransform transform = CGAffineTransformMakeTranslation(initialPoint.x, initialPoint.y);
        transform = CGAffineTransformRotate(transform, offsetAngle);
        
        [path transform:transform];
        //  return path;
    }
    
    path.strokeStyle = (nShapeMode == PSShapeLine) ? stroke : [stroke strokeStyleSansArrows];
//    path.strokeStyle = [stroke strokeStyleSansArrows];
    path.fill = [propertyManager activeFillStyle];
    
    return path;
    // return nil;
}

-(void)updatePath
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_VECTOR_LAYER)  return;
    
    PSVecLayer *layerVector = (PSVecLayer *)layer;
    [layerVector refreshLayer];
}

-(void)checkCurrentLayerIsSupported
{
    return;
}

- (BOOL)deleteKeyPressed
{
    PSContent *contents = [m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    NSMutableArray *objects = [wdDrawingController orderedSelectedObjects];
    if ([objects count] > 0) {
        [wdDrawingController deleteSelectedPath:nil];
        lastMouseMoveOnObject_ = nil;
        [self setTransformType:Transform_NO];
        [[m_idDocument docView] setNeedsDisplay:YES];
        return YES;
    }
    
    return NO;
}

- (BOOL)moveKeyPressedOffset:(NSPoint)offset needUndo:(BOOL)undo
{
    [super moveKeyPressedOffset:offset needUndo:undo];
    [m_vectorTransformManager initialAffineInfo];
    
    return YES;
    
}


@end
