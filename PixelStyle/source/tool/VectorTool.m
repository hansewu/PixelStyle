#import <time.h>
#import "VectorTool.h"
#import "PSTextLayer.h"
#import "PSWhiteboard.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSContent.h"
#import "StandardMerge.h"
#import "PSTools.h"
#import "PSHelpers.h"
#import "VectorOptions.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "PSTexture.h"
#import "Bucket.h"
#import "Bitmap.h"
#import "OptionsUtility.h"
#import "PSTextInputView.h"
#import "ToolboxUtility.h"

#import "WDBezierNode.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"

extern id gNewFont;

@implementation VectorTool

- (int)toolId
{
    return kVectorTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Vector Tool", nil);
}

-(NSString *)toolShotKey
{
    return @" ";
}

- (id)init
{
    if(![super init])
        return NULL;
    
    m_MouseDownInfo.bMouseDownInArea   = NO;

    m_pathTemp                          = nil;
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
    
}

- (BOOL)isFineTool
{
    return YES;
}

- (void)shutDown
{

}

- (void)fineMouseUpAt:(NSPoint)iwhere withEvent:(NSEvent *)theEvent
{
    m_MouseDownInfo.bMouseDownInArea   = NO;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    
    if(m_MouseDownInfo.bMovingInLayer)
    {
//        [m_pathTemp release];
//        m_pathTemp = [self pathWithPoint:iwhere constrain:NO];
//
//        PSView *view =  (PSView *)[m_idDocument docView];
//        [view setNeedsDisplay:YES];
        
        [contents addVectorLayer:kActiveLayer];
        
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
        if([layer layerFormat] != PS_VECTOR_LAYER)  return;
        
        PSVecLayer *layerVector = (PSVecLayer *)layer;
        [layerVector setPath:m_pathTemp];
        
        return;
    }
    
    
    
    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
        if([layer layerFormat] != PS_VECTOR_LAYER)
            continue;
        
        PSVecLayer *layerVector = (PSVecLayer *)layer;
        
        IntRect layerRect = [layerVector localRect];
//        localActiveLayerPoint.x = localPoint.x - [layerVector xoff];
//        localActiveLayerPoint.y = localPoint.y - [layerVector yoff];
        if(CGRectContainsPoint(IntRectMakeNSRect(layerRect), iwhere))//IntPointMakeNSPoint(iwhere)))
        {
            if([[m_idDocument contents] activeLayer] != layer)
            {                
                [contents setActiveLayerIndexComplete:[layer index]];
            }
            
            return;
        }
    }
    
    
    return;
}

- (void)fineMouseDownAt:(NSPoint)iwhere withEvent:(NSEvent *)event
{
//    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
//    if([layer layerFormat] != PS_VECTOR_LAYER)  return;
//    
//    PSVecLayer *layerVector = (PSVecLayer *)layer;
//    
//    IntRect layerRect = [layerVector localRect];
//    if(CGRectContainsPoint(IntRectMakeNSRect(layerRect), iwhere))
//    {
//        m_MouseDownInfo.bMouseDownInArea   = YES;
//        m_MouseDownInfo.bMovingInLayer        = NO;
//        m_MouseDownInfo.pointMouseDown    = iwhere;
//        
//        m_MouseDownInfo.timeMouseDown      = [[NSDate date] timeIntervalSince1970];
//    }
    
    m_MouseDownInfo.bMouseDownInArea   = YES;
    m_MouseDownInfo.bMovingInLayer        = NO;
    m_MouseDownInfo.pointMouseDown    = iwhere;
    
    m_MouseDownInfo.timeMouseDown      = [[NSDate date] timeIntervalSince1970];
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(!m_MouseDownInfo.bMouseDownInArea)
    {
        [self fineMouseDownAt:where withEvent:event];
        
        return;
    }
    
    
    if([[NSDate date] timeIntervalSince1970] - m_MouseDownInfo.timeMouseDown > 0.1)
    {
        m_MouseDownInfo.bMovingInLayer        = YES;
        
        if(m_pathTemp) [m_pathTemp release];
        m_pathTemp = [self pathWithPoint:where constrain:NO];
        
        PSView *view =  (PSView *)[m_idDocument docView];
        [view setNeedsDisplay:YES];
    }
    
//    if(m_MouseDownInfo.bMouseDownInArea && m_MouseDownInfo.bMovingInLayer == NO && [[NSDate date] timeIntervalSince1970] - m_MouseDownInfo.timeMouseDown > 0.1)
//    {
//        m_MouseDownInfo.bMovingInLayer        = YES;
//    }
//    
//    if(m_MouseDownInfo.bMovingInLayer)
//    {
//        [m_pathTemp release];
//        m_pathTemp = [self pathWithPoint:where constrain:NO];
//        
//        PSView *view =  (PSView *)[m_idDocument docView];
//        [view setNeedsDisplay:YES];
//    }
}


- (void)layerAttributesChanged:(int)nLayerType
{
 /*   PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    
    if([layer layerFormat] != PS_TEXT_LAYER)
    {
        if(m_textInputView)
        {
            [m_textInputView removeFromSuperview];
            [m_textInputView release];
            m_textInputView = nil;
        }
        return;
    }
    
    if(m_textInputView)
    {
        [m_textInputView removeFromSuperview];
        [m_textInputView release];
    }
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    m_textInputView = [[PSTextInputView alloc] initWithDocument:m_idDocument string:[layerVector getText]];
    [m_textInputView setAutoresizingMask:NSViewWidthSizable |  NSViewHeightSizable];
    [[m_idDocument docView] addSubview:m_textInputView];
    
    [[m_textInputView window] makeFirstResponder:m_textInputView];
    [m_textInputView setDelegateTextInfoNotify:layerVector];
    
    [m_idOptions updtaeUIForFont:[layerVector getFontName]];
    [m_idOptions updateUIForFontSize:[layerVector getFontSize]];
    
    CUSTOM_TRANSFORM trans = [layerVector getCustomTransform];
    [m_idOptions updateUIForCustomTransformType:trans.nTransformStyleID];
    [m_idOptions updateUIForCustomTransformValue:(CGFloat)trans.nBendPercent];
    
    [m_idOptions updtaeUIForFontColor:[layerVector getFillColor]];
    
    [m_idOptions updtaeUIForFontBold:[layerVector getFontBold]];
    [m_idOptions updtaeUIForFontItalics:[layerVector getFontItalics]];
    [m_idOptions updtaeUIForFontUnderline:[layerVector getFontUnderline]];
    [m_idOptions updtaeUIForFontStrikethrough:[layerVector getFontStrikethrough]];
    [m_idOptions updtaeUIForFontCharacterSpacing:[layerVector getCharacterSpace]];
  */
}



- (void)drawToolExtra
{
    if(!m_MouseDownInfo.bMouseDownInArea) return;
    if(m_pathTemp == nil) return;
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if(curToolIndex != kVectorTool) return;
//    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
//    if(curToolIndex != kVectorTool || layer == nil || [layer visible] == NO||[layer layerFormat] != PS_VECTOR_LAYER)
//        return;
    
   // PSTextLayer *vectorLayer = (PSTextLayer *)layer;
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    //  assert(ctx);
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);

    [m_pathTemp renderInContext:ctx metaData:WDRenderingMetaDataMake(1.0, WDRenderOutlineOnly)];
    //CGContextFillPath(ctx);
    CGContextDrawPath(ctx, kCGPathStroke);
    CGContextRestoreGState(ctx);
   
}

/*
- (PSShapePath *) pathWithPoint:(CGPoint)pt constrain:(BOOL)constrain
{
   
    PSShapePath *path;
    CGPoint initialPoint = m_MouseDownInfo.pointMouseDown;
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    WDStrokeStyle *stroke = [propertyManager activeStrokeStyle];
    
    int nShapeMode = [m_idOptions shapeMode];
    if (nShapeMode == PSShapeOval)
    {
        CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
        path = (PSShapePath *)[PSShapePath pathWithOvalInRect:rect];
        [path retain];
    }
    else if (nShapeMode == PSShapeRectangle)
    {
        float fRectCornerRadius = [m_idOptions rectCornerRadius];
        CGRect rect = WDRectWithPointsConstrained(initialPoint, pt, constrain);
        path = (PSShapePath *)[PSShapePath pathWithRoundedRect:rect cornerRadius:fRectCornerRadius];
        [path retain];
    }
    else if (nShapeMode == PSShapeLine)
    {
        if (constrain)
        {
            CGPoint delta = WDConstrainPoint(WDSubtractPoints(pt, initialPoint));
            pt = WDAddPoints(initialPoint, delta);
        }
        
        path = (PSShapePath *)[PSShapePath pathWithStart:initialPoint end:pt];
        [path retain];
    }
    else if (nShapeMode== PSShapePolygon)
    {
        int nPolygonNumPoints = [m_idOptions polygonNumPoints];
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
        
        path = [[PSShapePath alloc] init];
        path.nodes = nodes;
        path.closed = YES;
    }
    else if (nShapeMode == PSShapeStar)
    {
        int nStarNumPoints = [m_idOptions starNumPoints];
        float fStarInnerRadiusRatio = [m_idOptions starInnerRadiusRatio];
        float fStarLastRadius = [m_idOptions starLastRadius];
        
        float   outerRadius = WDDistance(pt, initialPoint);
        
        if (outerRadius == 0)
        {
            return nil;
        }
        
        if (constrain)
        {
            float tempInner = fStarInnerRadiusRatio * fStarLastRadius;
            fStarInnerRadiusRatio = WDClamp(0.05, 2.0, tempInner / outerRadius);
        }
        fStarLastRadius = outerRadius;
        
        float   ratioToUse = fStarInnerRadiusRatio;
        float   kappa = (M_PI * 2) / nStarNumPoints;
        float   optimalRatio = cos(kappa) / cos(kappa / 2);
        
        if ((nStarNumPoints > 4) && (fStarInnerRadiusRatio / optimalRatio > 0.95) && (fStarInnerRadiusRatio / optimalRatio < 1.05)) {
            ratioToUse = optimalRatio;
        }
 
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
        
        path = [[PSShapePath alloc] init];
        path.nodes = nodes;
        path.closed = YES;
    }
    else if (nShapeMode == PSShapeSpiral)
    {
        int nSpiralDecay = [m_idOptions spiralDecay];
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
        
        path = [[PSShapePath alloc] init];
        path.nodes = nodes;
        
        CGAffineTransform transform = CGAffineTransformMakeTranslation(initialPoint.x, initialPoint.y);
        transform = CGAffineTransformRotate(transform, offsetAngle);
        
        [path transform:transform];
    }
    
    path.strokeStyle = [stroke strokeStyleSansArrows];
    path.fill = [propertyManager activeFillStyle];
    
    return path;
}
*/
-(void)checkCurrentLayerIsSupported
{
    return;
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return YES;
    
    return NO;
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

@end
