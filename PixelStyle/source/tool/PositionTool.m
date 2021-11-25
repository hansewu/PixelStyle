#import "PositionTool.h"
#import "PositionOptions.h"
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

#import "PSVecLayer.h"


@implementation PositionTool

- (int)toolId
{
	return kPositionTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Move and Align Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"V";
}

- (id)init
{
	if(![super init])
		return NULL;
		
    m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    
    m_linkedLayers = [[NSMutableArray alloc] init];
    m_linkedLayersRects = [[NSMutableArray alloc] init];
    
	return self;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawToolExtraExtent:) name:@"DRAWTOOLEXTRAEXTENT" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DRAWTOOLEXTRAEXTENT" object:nil];
    
    [m_linkedLayers removeAllObjects];
    [m_linkedLayers release];
    [m_linkedLayersRects removeAllObjects];
    [m_linkedLayersRects release];
    
    [super dealloc];
}

- (BOOL)isFineTool
{
    return YES;
}

- (void) selectLayer: (NSPoint)where
{
    id contents = [m_idDocument contents];

    NSCAssert(contents, @"");
    
    for(int layerIndex =0; layerIndex< [contents layerCount]; layerIndex++)
    {
        PSAbstractLayer *layer = [contents layer:layerIndex];
        NSCAssert(layer, @"");
        
        if(![layer visible])  continue;
        
        IntRect rect = [layer localRect];
        CGRect rectF = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
        
        if(CGRectContainsPoint(rectF, where))
        {
            [contents setActiveLayerIndexComplete:layerIndex];
            break;
        }
        
    }
    
}

- (void)fineMouseDownAt:(NSPoint)where withEvent:(NSEvent *)event;
{
    id contents = [m_idDocument contents];
    id activeLayer = [contents activeLayer];
    IntPoint oldOffsets;
    int whichLayer;
    int function = kMovingLayer;
    
    [activeLayer setFullRenderState:NO];
    
    if([(PositionOptions *)m_idOptions isAutoSelectLayer])
    {
        [self selectLayer:where];
    }
    
    // Determine the function
    if ([activeLayer floating] && [(PositionOptions *)m_idOptions canAnchor] && (where.x < 0 || where.y < 0 || where.x >= [(PSLayer *)activeLayer width] || where.y >= [(PSLayer *)activeLayer height])){
        function = kAnchoringLayer;
    }else{
        function = [(PositionOptions *)m_idOptions toolFunction];
    }
    
    // Record the inital point for dragging
    m_sInitialPoint = NSPointMakeIntPoint(where);
    
    //m_sOldSelectionOrigin = [[m_idDocument selection] trueLocalRect].origin;
    m_sOldSelectionOrigin = [[m_idDocument selection] globalRect].origin;
    
    // Vary behaviour based on function
    switch (function) {
        case kMovingLayer:
        {
            [m_linkedLayers removeAllObjects];
            [m_linkedLayersRects removeAllObjects];
            
            // Go through all linked layers allowing a satisfactory undo
            for (whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
                PSAbstractLayer* layer = [contents layer:whichLayer];
                if ([layer linked]) {
                    oldOffsets.x = [layer xoff];
                    oldOffsets.y = [layer yoff];
                    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:whichLayer];
                    
                    [m_linkedLayers addObject:layer];
                    [m_linkedLayersRects addObject:NSStringFromRect(NSMakeRect([layer xoff], [layer yoff], [layer width], [layer height]))];
                }
            }
        }
            
            break;
            
        case kAnchoringLayer:
            
            // Anchor the layer
            [contents anchorSelection];
            
            break;
    }

}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event;
{
    int xoff, yoff;
    int deltax = where.x - m_sInitialPoint.x, deltay = where.y - m_sInitialPoint.y;
    IntPoint oldOffsets = IntMakePoint(0, 0);
    
    // Vary behaviour based on function
    switch ([(PositionOptions *)m_idOptions  toolFunction]) {
        case kMovingLayer:
        {
            int newx = deltax;
            int newy = deltay;
            
            BOOL align = [self judgeLayersNeedAutoAlign:m_linkedLayers deltax:deltax deltay:deltay newx:&newx newy:&newy];
            if (align) {
                deltax = newx;
                deltay = newy;
            }
            
            // Move all of the linked layers
            for (int i = 0; i < [m_linkedLayers count]; i++)
            {
                NSRect rect = NSRectFromString([m_linkedLayersRects objectAtIndex:i]);
                xoff = rect.origin.x;
                yoff = rect.origin.y;
                //NSLog(@"%d,%d,%f,%f",xoff,yoff,where.x,where.y);
                //[[m_linkedLayers objectAtIndex:i] setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
                if ([[m_linkedLayers objectAtIndex:i] layerFormat] == PS_VECTOR_LAYER)
                {
                    [[m_linkedLayers objectAtIndex:i] setOffsetsNoTransform:IntMakePoint(xoff + deltax, yoff + deltay)];
                }
                else
                {
                    [[m_linkedLayers objectAtIndex:i] setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
                }
            }
            [[m_idDocument helpers] layerOffsetsChanged:kLinkedLayers from:oldOffsets];
        }
            break;
            
    }
    
    
    //选区移动
    IntPoint newOrigin;
    newOrigin.x = m_sOldSelectionOrigin.x + (where.x - m_sInitialPoint.x);
    newOrigin.y = m_sOldSelectionOrigin.y + (where.y - m_sInitialPoint.y);
    [[m_idDocument selection] moveSelection:newOrigin];
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}

- (void)fineMouseUpAt:(NSPoint)where withEvent:(NSEvent *)event;
{
    for (int i = 0; i < [m_linkedLayers count]; i++) {
        id layer = [m_linkedLayers objectAtIndex:i];
        if ([layer layerFormat] == PS_VECTOR_LAYER)  {
            [(PSVecLayer*)layer applyTransform];
        }
    }
    
    [m_linkedLayers removeAllObjects];
    [m_linkedLayersRects removeAllObjects];
    
    id contents = [m_idDocument contents];
    id activeLayer = [contents activeLayer];
    [activeLayer setFullRenderState:YES];

}



- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	id contents = [m_idDocument contents];
	id activeLayer = [contents activeLayer];
	IntPoint oldOffsets;
	int whichLayer;
	int function = kMovingLayer;
    
	
	// Determine the function
	if ([activeLayer floating] && [(PositionOptions *)m_idOptions canAnchor] && (where.x < 0 || where.y < 0 || where.x >= [(PSLayer *)activeLayer width] || where.y >= [(PSLayer *)activeLayer height])){
		function = kAnchoringLayer;
	}else{
		function = [(PositionOptions *)m_idOptions toolFunction];
	}

	// Record the inital point for dragging
	m_sInitialPoint = where;
    
    m_sOldSelectionOrigin = [[m_idDocument selection] globalRect].origin;

	// Vary behaviour based on function
	switch (function) {
		case kMovingLayer:
        {
            [m_linkedLayers removeAllObjects];
            [m_linkedLayersRects removeAllObjects];
            
            // Go through all linked layers allowing a satisfactory undo
            for (whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++) {
                PSAbstractLayer* layer = [contents layer:whichLayer];
                if ([layer linked]) {
                    oldOffsets.x = [layer xoff];
                    oldOffsets.y = [layer yoff];
                    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:whichLayer];
                    
                    [m_linkedLayers addObject:layer];
                    [m_linkedLayersRects addObject:NSStringFromRect(NSMakeRect([layer xoff], [layer yoff], [layer width], [layer height]))];
                }
            }
        }
			
		break;
		
		case kAnchoringLayer:
		
			// Anchor the layer
			[contents anchorSelection];
			
		break;
	}
}

- (void)undoToOrigin:(IntPoint)origin forLayer:(int)index
{
    IntPoint oldOffsets;
    id layer = [[m_idDocument contents] layer:index];
    
    oldOffsets.x = [layer xoff]; oldOffsets.y = [layer yoff];
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:index];
    [layer setOffsets:origin];
    [[m_idDocument helpers] layerOffsetsChanged:index from:oldOffsets];
    
    [[m_idDocument selection] adjustOffset:IntMakePoint(origin.x - oldOffsets.x, origin.y - oldOffsets.y)];
}


- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
    
    id contents = [m_idDocument contents];
    int xoff, yoff, whichLayer;
    int deltax = where.x - m_sInitialPoint.x, deltay = where.y - m_sInitialPoint.y;
    IntPoint oldOffsets = IntMakePoint(0, 0);
    
    // Vary behaviour based on function
    switch ([(PositionOptions *)m_idOptions  toolFunction]) {
        case kMovingLayer:
        {
            int newx = deltax;
            int newy = deltay;
            BOOL align = [self judgeLayersNeedAutoAlign:m_linkedLayers deltax:deltax deltay:deltay newx:&newx newy:&newy];
            if (align) {
                deltax = newx;
                deltay = newy;
            }
            
            // Move all of the linked layers
            for (whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
            {
                if ([[contents layer:whichLayer] linked])
                {
                    xoff = [[contents layer:whichLayer] xoff];
                    yoff = [[contents layer:whichLayer] yoff];
                    //NSLog(@"%d,%d,%d,%d",xoff,yoff,where.x,where.y);
                    [[contents layer:whichLayer] setOffsets:IntMakePoint(xoff + deltax, yoff + deltay)];
                }
            }
            [[m_idDocument helpers] layerOffsetsChanged:kLinkedLayers from:oldOffsets];
        }
            break;
            
    }
    
    
    //选区移动
    IntPoint newOrigin;
    newOrigin.x = m_sOldSelectionOrigin.x + (where.x - m_sInitialPoint.x);
    newOrigin.y = m_sOldSelectionOrigin.y + (where.y - m_sInitialPoint.y);
    [[m_idDocument selection] moveSelection:IntMakePoint(newOrigin.x, newOrigin.y)];
    
    
    [[m_idDocument docView] setNeedsDisplay:YES];
}



- (BOOL)judgeLayersNeedAutoAlign:(NSArray*)layers deltax:(int)deltax deltay:(int)deltay newx:(int*)newx newy:(int*)newy
{
    if(![(PositionOptions *)m_idOptions isAutoAlignLayer])
    {
        return NO;
    }
    id contents = [m_idDocument contents];
    
    assert(contents != nil);
    int threshold = (int)(20.0 * sqrt((double)[(PSContent*)contents width] * (double)[(PSContent*)contents height])/1024.0);
    
    
    int count = [contents layerCount];
    NSMutableArray *otherLayers= [NSMutableArray array];
    for (int index = 0; index < count; index++) {
        id layer = [contents layer:index];
        if (![layers containsObject:layer] && [layer visible]) {
            [otherLayers addObject:layer];
        }
    }
    BOOL align = NO;
    int minDx = 100;
    int minDy = 100;
    for (int i = 0; i < [layers count]; i++) {
//        NSRect rect = NSRectFromString([m_linkedLayersRects objectAtIndex:i]);
//        int xoff = rect.origin.x;
//        int yoff = rect.origin.y;
//        int width = rect.size.width;
//        int height = rect.size.height;
        PSAbstractLayer* layer = [layers objectAtIndex:i];
        int xoff = [layer xoff];
        int yoff = [layer yoff];
        int width = [layer width];
        int height = [layer height];
        if ([self isFineTool]) {
            NSRect rect = NSRectFromString([m_linkedLayersRects objectAtIndex:i]);
            xoff = rect.origin.x;
            yoff = rect.origin.y;
            width = rect.size.width;
            height = rect.size.height;
        }
        int left = xoff + deltax;
        int top = yoff + deltay;
        int right = xoff + deltax + width;
        int bottum = yoff + deltay + height;
        for (int j = 0; j < [otherLayers count]; j++) {
            PSAbstractLayer* otherLayer = [otherLayers objectAtIndex:j];
            int xoff1 = [otherLayer xoff];
            int yoff1 = [otherLayer yoff];
            int width1 = [otherLayer width];
            int height1 = [otherLayer height];
            int left1 = xoff1;
            int top1 = yoff1;
            int right1 = xoff1 + width1;
            int bottum1 = yoff1 + height1;
            
            //重合
            if (abs(left - left1) < threshold && abs(left - left1) < minDx) {
                *newx = left1 - xoff;
                minDx = abs(left - left1);
                align = YES;
            }
            if (abs(top - top1) < threshold && abs(top - top1) < minDy) {
                *newy = top1 - yoff;
                minDy = abs(top - top1);
                align = YES;
            }
            if (abs(right - right1) < threshold && abs(right - right1) < minDx) {
                *newx = right1 - xoff - width;
                minDx = abs(right - right1);
                align = YES;
            }
            if (abs(bottum - bottum1) < threshold && abs(bottum - bottum1) < minDy) {
                *newy = bottum1 - yoff - height;
                minDy = abs(bottum - bottum1);
                align = YES;
            }
            
            //并列
            if (abs(left - right1) < threshold && abs(left - right1) < minDx) {
                *newx = right1 - xoff;
                minDx = abs(left - right1);
                align = YES;
            }
            if (abs(top - bottum1) < threshold && abs(top - bottum1) < minDy) {
                *newy = bottum1 - yoff;
                minDy = abs(top - bottum1);
                align = YES;
            }
            if (abs(right - left1) < threshold && abs(right - left1) < minDx) {
                *newx = left1 - xoff - width;
                minDx = abs(right - left1);
                align = YES;
            }
            if (abs(bottum - top1) < threshold && abs(bottum - top1) < minDy) {
                *newy = top1 - yoff - height;
                minDy = abs(bottum - top1);
                align = YES;
            }
            
        }
        
        //canvas
        int xoff1 = 0;
        int yoff1 = 0;
        int width1 = [(PSContent*)contents width];
        int height1 = [(PSContent*)contents height];
        int left1 = xoff1;
        int top1 = yoff1;
        int right1 = xoff1 + width1;
        int bottum1 = yoff1 + height1;
        
        //重合
        if (abs(left - left1) < threshold && abs(left - left1) < minDx) {
            *newx = left1 - xoff;
            minDx = abs(left - left1);
            align = YES;
        }
        if (abs(top - top1) < threshold && abs(top - top1) < minDy) {
            *newy = top1 - yoff;
            minDy = abs(top - top1);
            align = YES;
        }
        if (abs(right - right1) < threshold && abs(right - right1) < minDx) {
            *newx = right1 - xoff - width;
            minDx = abs(right - right1);
            align = YES;
        }
        if (abs(bottum - bottum1) < threshold && abs(bottum - bottum1) < minDy) {
            *newy = bottum1 - yoff - height;
            minDy = abs(bottum - bottum1);
            align = YES;
        }
        
        //并列
        if (abs(left - right1) < threshold && abs(left - right1) < minDx) {
            *newx = right1 - xoff;
            minDx = abs(left - right1);
            align = YES;
        }
        if (abs(top - bottum1) < threshold && abs(top - bottum1) < minDy) {
            *newy = bottum1 - yoff;
            minDy = abs(top - bottum1);
            align = YES;
        }
        if (abs(right - left1) < threshold && abs(right - left1) < minDx) {
            *newx = left1 - xoff - width;
            minDx = abs(right - left1);
            align = YES;
        }
        if (abs(bottum - top1) < threshold && abs(bottum - top1) < minDy) {
            *newy = top1 - yoff - height;
            minDy = abs(bottum - top1);
            align = YES;
        }

    }
    
    
    return align;
    
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [m_linkedLayers removeAllObjects];
    [m_linkedLayersRects removeAllObjects];
}

- (void)drawToolExtraExtent:(NSNotification*) notification
{
    return;
    
    if (notification.object != [m_idDocument shadowView]) {
        return;
    }
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    if (curToolIndex != kPositionTool) {
        return;
    }
    int minx = 100000;
    int maxx = -100000;
    int miny = 100000;
    int maxy = -100000;
    for (int whichLayer = 0; whichLayer < [[m_idDocument contents] layerCount]; whichLayer++) {
        id tempLayer = [[m_idDocument contents] layer:whichLayer];
        if ([tempLayer linked]) {
            int xoffset = [(PSAbstractLayer*)tempLayer xoff];
            int yoffset = [(PSAbstractLayer*)tempLayer yoff];
            int width = [(PSAbstractLayer*)tempLayer width];
            int height = [(PSAbstractLayer*)tempLayer height];
            
            if (xoffset < minx) {
                minx = xoffset;
            }
            if (xoffset + width > maxx) {
                maxx = xoffset + width;
            }
            if (yoffset < miny) {
                miny = yoffset;
            }
            if (yoffset + height > maxy) {
                maxy = yoffset + height;
            }
        }
    }
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    
    NSPoint point0 = NSMakePoint(minx, miny);
    NSPoint point1 = NSMakePoint(maxx, miny);
    NSPoint point2 = NSMakePoint(maxx, maxy);
    NSPoint point3 = NSMakePoint(minx, maxy);
    
    
    NSPoint viewPoint0 = NSMakePoint(point0.x * xScale, point0.y * yScale);
    NSPoint viewPoint1 = NSMakePoint(point1.x * xScale, point1.y * yScale);
    NSPoint viewPoint2 = NSMakePoint(point2.x * xScale, point2.y * yScale);
    NSPoint viewPoint3 = NSMakePoint(point3.x * xScale, point3.y * yScale);
    
    PSView *psview = [m_idDocument docView];
    NSView *shadowView = notification.object;
    NSPoint superPoint0 = [shadowView convertPoint: viewPoint0 fromView: psview];
    NSPoint superPoint1 = [shadowView convertPoint: viewPoint1 fromView: psview];
    NSPoint superPoint2 = [shadowView convertPoint: viewPoint2 fromView: psview];
    NSPoint superPoint3 = [shadowView convertPoint: viewPoint3 fromView: psview];
    
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
    return;
    
    if ([NSDate timeIntervalSinceReferenceDate] - m_lastRefreshTime > 0.1) {
        [[m_idDocument shadowView] setNeedsDisplay:YES];
        m_lastRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    }
    
    
    int minx = 100000;
    int maxx = -100000;
    int miny = 100000;
    int maxy = -100000;
    for (int whichLayer = 0; whichLayer < [[m_idDocument contents] layerCount]; whichLayer++) {
        id tempLayer = [[m_idDocument contents] layer:whichLayer];
        if ([tempLayer linked]) {
            int xoffset = [(PSAbstractLayer*)tempLayer xoff];
            int yoffset = [(PSAbstractLayer*)tempLayer yoff];
            int width = [(PSAbstractLayer*)tempLayer width];
            int height = [(PSAbstractLayer*)tempLayer height];
                        
            if (xoffset < minx) {
                minx = xoffset;
            }
            if (xoffset + width > maxx) {
                maxx = xoffset + width;
            }
            if (yoffset < miny) {
                miny = yoffset;
            }
            if (yoffset + height > maxy) {
                maxy = yoffset + height;
            }
        }
    }
    
    float xScale = [[m_idDocument contents] xscale];
    float yScale = [[m_idDocument contents] yscale];
    
    NSPoint point0 = NSMakePoint(minx, miny);
    NSPoint point1 = NSMakePoint(maxx, miny);
    NSPoint point2 = NSMakePoint(maxx, maxy);
    NSPoint point3 = NSMakePoint(minx, maxy);
    
    
    NSPoint viewPoint0 = NSMakePoint(point0.x * xScale, point0.y * yScale);
    NSPoint viewPoint1 = NSMakePoint(point1.x * xScale, point1.y * yScale);
    NSPoint viewPoint2 = NSMakePoint(point2.x * xScale, point2.y * yScale);
    NSPoint viewPoint3 = NSMakePoint(point3.x * xScale, point3.y * yScale);
    
    
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


- (void)layerAttributesChanged:(int)nLayerType
{
    //NSLog(@"layerAttributesChanged");
    //[self drawToolExtra];
}


#pragma mark - Tool Enter/Exit

-(BOOL)exitTool:(int)newTool
{
    [[m_idDocument shadowView] setNeedsDisplay:YES];
    
    return [super exitTool:newTool];
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

@end
