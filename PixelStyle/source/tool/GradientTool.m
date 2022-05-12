#import "GradientTool.h"
#import "PSTools.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSSelection.h"
#import "PSWhiteboard.h"
#import "PSLayer.h"
#import "GradientOptions.h"
#import "PSHelpers.h"
#import "PSController.h"
#import "PSPrefs.h"

@implementation GradientTool

- (int)toolId
{
	return kGradientTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Gradient Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"G";
}

- (id)init
{
    self = [super init];
    if(self)
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
        
        
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Ctrl to lock gradients to 45.", nil)];

    }
    return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
    [super mouseDownAt:where withEvent:event];
    
	m_sStartPoint = where;
	m_bIntermediate = YES;
	m_poiStart = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];

}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	GimpGradientInfo info;
	id contents = [m_idDocument contents];
	IntRect rect;
	NSColor *color;
	double angle;
	int deltaX, deltaY;
    
    NSGradient *gradient = [[m_idOptions gradient] autorelease];
	
    if(gradient.numberOfColorStops <2) return;
    float posRoom[gradient.numberOfColorStops -2];
    unsigned char colorsRoom[gradient.numberOfColorStops -2][4];
    if(gradient.numberOfColorStops >2)
    {
        info.other_colors.nCount = gradient.numberOfColorStops -2;
        info.other_colors.fArrPositions = posRoom;//(float *)malloc(sizeof(float)*info.other_colors.nCount );
        info.other_colors.ArrayColors   = colorsRoom;//(unsigned char (*)[4])malloc(sizeof(unsigned char)*4*info.other_colors.nCount);
        for(int i=0; i< info.other_colors.nCount; i++)
        {
            CGFloat location;
            [gradient getColor:&color location:&location atIndex:i+1];
            info.other_colors.ArrayColors[i][0] = [color redComponent] * 255;
            info.other_colors.ArrayColors[i][1] = [color greenComponent] * 255;
            info.other_colors.ArrayColors[i][2] = [color blueComponent] * 255;
            info.other_colors.ArrayColors[i][3] = [color alphaComponent] * 255;
            info.other_colors.fArrPositions[i]  = location;
        }
    }
    else info.other_colors.nCount = 0;
        
	// Get ready
	[[m_idDocument whiteboard] setOverlayOpacity:255];
    
    float alpha = [m_idOptions getOpacityValue];
	
	// Determine gradient information
    
	info.repeat = [m_idOptions repeat];
	info.gradient_type = [(GradientOptions *)m_idOptions type];
	info.supersample = [m_idOptions supersample];
	if (info.gradient_type == GIMP_GRADIENT_CONICAL_ASYMMETRIC || info.gradient_type == GIMP_GRADIENT_SPIRAL_CLOCKWISE || info.gradient_type == GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE) {
		info.supersample = YES;
	}
	else {
		if (info.repeat == GIMP_REPEAT_SAWTOOTH && info.gradient_type <= GIMP_GRADIENT_SQUARE)
			info.supersample = YES;
	}
	info.max_depth = [m_idOptions maximumDepth];
	info.threshold = [m_idOptions threshold];
	info.start = m_sStartPoint;
	deltaX = where.x - m_sStartPoint.x;
	deltaY = where.y - m_sStartPoint.y;
	if ([(GradientOptions *)m_idOptions modifier] == kControlModifier) {
		angle = atan((double)deltaY / (double)abs(deltaX));
		if (angle > -0.3927 && angle < 0.3927)
			where.y = m_sStartPoint.y;
		else if (angle > 1.1781 || angle < -1.1781)
			where.x = m_sStartPoint.x;
		else if (angle > 0.0)
			where.y = m_sStartPoint.y + abs(deltaX);
		else 
			where.y = m_sStartPoint.y - abs(deltaX);
	}
	if ([contents spp] == 4) {
        color = [contents foreground];
        //if(gradient.numberOfColorStops == 2)
        {
            [gradient getColor:&color location:nil atIndex:0];
        }
		
		info.start_color[0] = [color redComponent] * 255;
		info.start_color[1] = [color greenComponent] * 255;
		info.start_color[2] = [color blueComponent] * 255;
		info.start_color[3] = alpha * 255;
		info.end = where;
		color = [contents background];
        //if(gradient.numberOfColorStops == 2)
        {
            [gradient getColor:&color location:nil atIndex:gradient.numberOfColorStops-1];
        }
		info.end_color[0] = [color redComponent] * 255;
		info.end_color[1] = [color greenComponent] * 255;
		info.end_color[2] = [color blueComponent] * 255;
		info.end_color[3] = alpha * 255;
	}
	else {
		color = [contents foreground];
		info.start_color[0] = info.start_color[1] = info.start_color[2] = [color whiteComponent] * 255;
		info.start_color[3] = alpha * 255;
		info.end = where;
		color = [contents background];
		info.end_color[0] = info.end_color[1] = info.end_color[2] = [color whiteComponent] * 255;
		info.end_color[3] = alpha * 255;
	}
	
	// Work out the rectangle for the gradient
	if ([[m_idDocument selection] active])
		rect = [[m_idDocument selection] localRect];
	else
		rect = IntMakeRect(0, 0, [(PSLayer *)[contents activeLayer] width], [(PSLayer *)[contents activeLayer] height]);
	
	// Draw the gradient
    PSSecureImageData *overlayData = [[m_idDocument whiteboard] overlaySecureData];
    IMAGE_DATA imageData = [overlayData lockDataForWrite];
    unsigned char *overlay = imageData.pBuffer;
	GCFillGradient(overlay, [(PSLayer *)[contents activeLayer] width], [(PSLayer *)[contents activeLayer] height], rect, [contents spp], info, NULL);
    [overlayData unLockDataForWrite];
	
    // Apply the changes
	[(PSHelpers *)[m_idDocument helpers] applyOverlay];
	
	m_bIntermediate = NO;
    
    /*if(info.other_colors.nCount >2)
    {
        free(info.other_colors.fArrPositions);
        free(info.other_colors.ArrayColors);
    }*/
}


//- (void)mouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	m_poiTemp = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
	[[m_idDocument docView] setNeedsDisplay: YES];
}


- (NSPoint)start
{
	return m_poiStart;
}

- (NSPoint)current
{
	return m_poiTemp;
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return NO;
    
    return YES;
}

-(BOOL)isAffectedBySelection //此工具处理特殊
{
    return NO;
}

@end
