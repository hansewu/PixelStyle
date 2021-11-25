#import "CropTool.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "CropOptions.h"
#import "PSContent.h"
#import "PSTools.h"
#import "AspectRatio.h"
#import "PSLayer.h"
#import "PSController.h"
#import "UtilitiesManager.h"

@implementation CropTool

- (int)toolId
{
	return kCropTool;
}	

-(NSString *)toolTip
{
    return NSLocalizedString(@"Crop Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"C";
}

- (id)init
{
	if(![super init])
		return NULL;
	
	m_sCropRect.size.width = m_sCropRect.size.height = 0;
    
    m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Shift to keep 1:1 aspect ration.", nil)];
    
	return self;
}


#define ALPHA 128
- (void)mouseDownAt:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
    m_bTranslating = NO;
    m_nScalingDir = kNoDir;
    
    if([m_idOptions ignoresMove]){
        return;
    }
    
    // We need the global point for the handles
    NSPoint globalPoint = IntPointMakeNSPoint(localPoint);
    globalPoint.x += [[[m_idDocument contents] activeLayer] xoff];
    globalPoint.y += [[[m_idDocument contents] activeLayer] yoff];
    globalPoint.x *= [[m_idDocument contents] xscale];
    globalPoint.y *= [[m_idDocument contents] yscale];
    
    // Check if location is in existing rect
    m_nScalingDir = [self point:globalPoint
                  isInHandleFor:globalRect
                     ];
    
    // But the local rect for the moving
    IntRect localRect = globalRect;
    
    localRect.origin.x -= [[[m_idDocument contents] activeLayer]  xoff];
    localRect.origin.y -= [[[m_idDocument contents] activeLayer]  yoff];
    
    m_sMoveOrigin = localPoint;
    
    if(m_nScalingDir > kNoDir){
        // 1. Resizing selection
        m_sPreScaledRect = globalRect;
        
        //        IntRect trueLocalRect = [[m_idDocument selection] trueLocalRect];
        //        id layer = [[m_idDocument contents] activeLayer];
        //
        //        m_sPreScaledRect.origin.x = trueLocalRect.origin.x + [layer xoff];
        //        m_sPreScaledRect.origin.y = trueLocalRect.origin.y + [layer yoff];
        //        m_sPreScaledRect.size = trueLocalRect.size;
        
        if(mask){
            m_pPreScaledMask = malloc(m_sPreScaledRect.size.width * m_sPreScaledRect.size.height);
            memcpy(m_pPreScaledMask, mask, m_sPreScaledRect.size.width * m_sPreScaledRect.size.height);
        } else {
            m_pPreScaledMask = NULL;
        }
    } else if (	IntPointInRect(localPoint, localRect)){
        if(mask && mask[(localPoint.y - localRect.origin.y)*localRect.size.width + (localPoint.x - localRect.origin.x)] <= ALPHA)
            return;
        // 2. Moving Selection
        m_bTranslating = YES;
        m_sMoveOrigin = localPoint;
        
        if([self isKindOfClass:[CropTool class]])//crop
        {
            localRect.origin.x += [[[m_idDocument contents] activeLayer]  xoff];
            localRect.origin.y += [[[m_idDocument contents] activeLayer]  yoff];
            m_sOldOrigin =  localRect.origin;
        }
        else
        {
            m_sOldOrigin.x = localRect.origin.x - [[m_idDocument selection] maskOffset].x;
            m_sOldOrigin.y = localRect.origin.y - [[m_idDocument selection] maskOffset].y;
        }
        
    }
    
}

- (IntRect)mouseDraggedTo:(IntPoint)localPoint forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
    if(m_nScalingDir > kNoDir){
        //		IntRect currTempRect;
        //		// We need the global point for the handles
        //		NSPoint globalPoint = IntPointMakeNSPoint(localPoint);
        //		globalPoint.x += [[[m_idDocument contents] activeLayer] xoff];
        //		globalPoint.y += [[[m_idDocument contents] activeLayer] yoff];
        //		currTempRect = globalRect;
        
        NSPoint offset;
        offset.x = localPoint.x - m_sMoveOrigin.x;
        offset.y = localPoint.y - m_sMoveOrigin.y;
        
        BOOL usesAspect = NO;
        NSSize ratio = NSZeroSize;
        if([m_idOptions aspectType] == kRatioAspectType){
            usesAspect = YES;
            ratio = [m_idOptions ratio];
        }
        
        float newHeight = m_sPreScaledRect.size.height;
        float newWidth  = m_sPreScaledRect.size.width;
        float newX = m_sPreScaledRect.origin.x;
        float newY = m_sPreScaledRect.origin.y;
        
        switch(m_nScalingDir){
            case kULDir:
                newX = m_sPreScaledRect.origin.x + offset.x;
                newWidth = m_sPreScaledRect.size.width - offset.x;
                if(usesAspect){
                    newHeight = newWidth * ratio.height;
                    newY = m_sPreScaledRect.origin.y + m_sPreScaledRect.size.height - newHeight;
                }else{
                    newHeight = m_sPreScaledRect.size.height - offset.y;
                    newY = m_sPreScaledRect.origin.y + offset.y;
                }
                break;
            case kUDir:
                newHeight = m_sPreScaledRect.size.height - offset.y;
                newY = m_sPreScaledRect.origin.y + offset.y;
                break;
            case kURDir:
                newWidth = m_sPreScaledRect.size.width + offset.x;
                if(usesAspect){
                    newHeight = newWidth * ratio.height;
                    newY = m_sPreScaledRect.origin.y + m_sPreScaledRect.size.height - newHeight;
                }else{
                    newHeight = m_sPreScaledRect.size.height - offset.y;
                    newY = m_sPreScaledRect.origin.y + offset.y;
                }
                break;
            case kRDir:
                newWidth = m_sPreScaledRect.size.width + offset.x;
                break;
            case kDRDir:
                newWidth = m_sPreScaledRect.size.width + offset.x;
                if(usesAspect){
                    newHeight = newWidth * ratio.height;
                }else{
                    newHeight = m_sPreScaledRect.size.height + offset.y;
                }
                break;
            case kDDir:
                newHeight = m_sPreScaledRect.size.height + offset.y;
                break;
            case kDLDir:
                newX = m_sPreScaledRect.origin.x + offset.x;
                newWidth = m_sPreScaledRect.size.width - offset.x;
                if(usesAspect){
                    newHeight = newWidth * ratio.height;
                }else{
                    newHeight = m_sPreScaledRect.size.height + offset.y;
                }
                break;
            case kLDir:
                newX = m_sPreScaledRect.origin.x + offset.x;
                newWidth = m_sPreScaledRect.size.width - offset.x;
                break;
            default:
                NSLog(@"Scaling direction not supported.");
        }
        
        
        
        //		switch(m_nScalingDir){
        //			case kULDir:
        //				newWidth = m_sPreScaledRect.origin.x -  globalPoint.x + m_sPreScaledRect.size.width;
        //				newX = globalPoint.x;
        //				if(usesAspect){
        //					newHeight = newWidth * ratio.height;
        //					newY = m_sPreScaledRect.origin.y + m_sPreScaledRect.size.height - newHeight;
        //				}else{
        //					newHeight = m_sPreScaledRect.origin.y - globalPoint.y + m_sPreScaledRect.size.height;
        //					newY = globalPoint.y;
        //				}
        //				break;
        //			case kUDir:
        //				newHeight = m_sPreScaledRect.origin.y - globalPoint.y + m_sPreScaledRect.size.height;
        //				newY = globalPoint.y;
        //				break;
        //			case kURDir:
        //				newWidth = globalPoint.x - m_sPreScaledRect.origin.x;
        //				if(usesAspect){
        //					newHeight = newWidth * ratio.height;
        //					newY = m_sPreScaledRect.origin.y + m_sPreScaledRect.size.height - newHeight;
        //				}else{
        //					newHeight = m_sPreScaledRect.origin.y - globalPoint.y + m_sPreScaledRect.size.height;
        //					newY = globalPoint.y;
        //				}
        //				break;
        //			case kRDir:
        //				newWidth = globalPoint.x - m_sPreScaledRect.origin.x;
        //				break;
        //			case kDRDir:
        //				newWidth = globalPoint.x - m_sPreScaledRect.origin.x;
        //				if(usesAspect){
        //					newHeight = newWidth * ratio.height;
        //				}else{
        //					newHeight = globalPoint.y - m_sPreScaledRect.origin.y;
        //				}
        //				break;
        //			case kDDir:
        //				newHeight = globalPoint.y - m_sPreScaledRect.origin.y;
        //				break;
        //			case kDLDir:
        //				newX = globalPoint.x;
        //				newWidth = m_sPreScaledRect.origin.x -  globalPoint.x + m_sPreScaledRect.size.width;
        //				if(usesAspect){
        //					newHeight = newWidth * ratio.height;
        //				}else{
        //					newHeight = globalPoint.y - m_sPreScaledRect.origin.y;
        //				}
        //				break;
        //			case kLDir:
        //				newX = globalPoint.x;
        //				newWidth = m_sPreScaledRect.origin.x -  globalPoint.x + m_sPreScaledRect.size.width;
        //				break;
        //			default:
        //				NSLog(@"Scaling direction not supported.");
        //		}
        
        return IntMakeRect((int)newX, (int)newY, (int)newWidth, (int)newHeight);
    } else if (m_bTranslating) {
        IntPoint newOrigin;
        // Move the thing
        newOrigin.x = m_sOldOrigin.x + (localPoint.x - m_sMoveOrigin.x);
        newOrigin.y = m_sOldOrigin.y + (localPoint.y - m_sMoveOrigin.y);
        return IntMakeRect(newOrigin.x, newOrigin.y, globalRect.size.width, globalRect.size.height);
    }
    return IntMakeRect(0,0,0,0);
}


- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	if(m_sCropRect.size.width > 0 && m_sCropRect.size.height > 0){
		[self mouseDownAt: where
				  forRect: m_sCropRect
				  andMask: NULL];
	}
	
	if(![self isMovingOrScaling]){
		int aspectType = [m_idOptions aspectType];
		NSSize ratio;
		double xres, yres;
		int modifier = [(CropOptions *)m_idOptions modifier];
		id activeLayer;
		
		// Make where appropriate
		activeLayer = [[m_idDocument contents] activeLayer];
		where.x += [activeLayer xoff];
		where.y += [activeLayer yoff];
		
		// Check if location is in existing rect
		m_sStartPoint = where;
		
		// Start the cropping rectangle
		m_bOneToOne = (modifier == kShiftModifier);
		if (aspectType == kNoAspectType || aspectType == kRatioAspectType || m_bOneToOne) {
			m_sCropRect.origin.x = m_sStartPoint.x;
			m_sCropRect.origin.y = m_sStartPoint.y;
			m_sCropRect.size.width = 0;
			m_sCropRect.size.height = 0;
		}
		else {
			ratio = [m_idOptions ratio];
			m_sCropRect.origin.x = m_sStartPoint.x;
			m_sCropRect.origin.y = m_sStartPoint.y;
			xres = [[m_idDocument contents] xres];
			yres = [[m_idDocument contents] yres];
			switch (aspectType) {
				case kExactPixelAspectType:
					m_sCropRect.size.width = ratio.width;
					m_sCropRect.size.height = ratio.height;
				break;
				case kExactInchAspectType:
					m_sCropRect.size.width = ratio.width * xres;
					m_sCropRect.size.height = ratio.height * yres;
				break;
				case kExactMillimeterAspectType:
					m_sCropRect.size.width = ratio.width * xres * 0.03937;
					m_sCropRect.size.height = ratio.height * yres * 0.03937;
				break;
			}
			[[m_idDocument helpers] selectionChanged];
		}
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	IntRect draggedRect = [self mouseDraggedTo: where
									   forRect: m_sCropRect
									   andMask: NULL];
	
	if(![self isMovingOrScaling]){
	
		int aspectType = [m_idOptions aspectType];
		NSSize ratio;
		id activeLayer;
		
		// Make where appropriate
		activeLayer = [[m_idDocument contents] activeLayer];
		where.x += [activeLayer xoff];
		where.y += [activeLayer yoff];
		
		if (aspectType == kNoAspectType || aspectType == kRatioAspectType || m_bOneToOne) {

			// Determine the width of the cropping rectangle
			if (m_sStartPoint.x < where.x) {
				m_sCropRect.origin.x = m_sStartPoint.x;
				m_sCropRect.size.width = where.x - m_sStartPoint.x;
			}
			else {
				m_sCropRect.origin.x = where.x;
				m_sCropRect.size.width = m_sStartPoint.x - where.x;
			}
			
			// Determine the height of the cropping rectangle
			if (m_bOneToOne) {
				if (m_sStartPoint.y < where.y) {
					m_sCropRect.size.height = m_sCropRect.size.width;
					m_sCropRect.origin.y = m_sStartPoint.y;
				}
				else {
					m_sCropRect.size.height = m_sCropRect.size.width;
					m_sCropRect.origin.y = m_sStartPoint.y - m_sCropRect.size.height;
				}
			}
			else if (aspectType == kRatioAspectType) {
				ratio = [m_idOptions ratio];
				if (m_sStartPoint.y < where.y) {
					m_sCropRect.size.height = m_sCropRect.size.width * ratio.height;
					m_sCropRect.origin.y = m_sStartPoint.y;
				}
				else {
					m_sCropRect.size.height = m_sCropRect.size.width * ratio.height;
					m_sCropRect.origin.y = m_sStartPoint.y - m_sCropRect.size.height;
				}
			}
			else {
				if (m_sStartPoint.y < where.y) {
					m_sCropRect.origin.y = m_sStartPoint.y;
					m_sCropRect.size.height = where.y - m_sStartPoint.y;
				}
				else {
					m_sCropRect.origin.y = where.y;
					m_sCropRect.size.height = m_sStartPoint.y - where.y;
				}
			}
			
		}
		else {
		
			m_sCropRect.origin.x = where.x;
			m_sCropRect.origin.y = where.y;
			
		}

		// Update the changes
		[[m_idDocument helpers] selectionChanged];
	} else {
		[self setCropRect:draggedRect];
	}

}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[self mouseDraggedTo:where withEvent:event];
	
	m_nScalingDir = kNoDir;
	m_bTranslating = NO;
    
    [self updateCropState];
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
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
    
    
    
    if(m_cursor) {[m_cursor release]; m_cursor  = nil;}
    if(!NSPointInRect(where, clippedRect))
    {
        m_cursor = [[NSCursor arrowCursor] retain];
        [m_cursor set];
        return ;
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

    
    int nScalingDir = m_nScalingDir;
    if(nScalingDir <= kNoDir)
        nScalingDir = [self point:where isInHandleFor:m_sCropRect];
    
    switch(nScalingDir)
    {
        case kULDir:
        {
            m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-nw-se-cursor"] hotSpot:NSMakePoint(7, 7)];
        }
            break;
        case kUDir:
            m_cursor = [[NSCursor resizeUpDownCursor] retain];
            
            break;
        case kURDir:
        {
            m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-ne-sw-cursor"] hotSpot:NSMakePoint(7, 7)];
        }
            break;
        case kRDir:
            m_cursor = [[NSCursor resizeLeftRightCursor] retain];
            break;
        case kDRDir:
        {
            m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-nw-se-cursor"] hotSpot:NSMakePoint(7, 7)];
        }
            break;
        case kDDir:
            m_cursor = [[NSCursor resizeUpDownCursor] retain];
            break;
        case kDLDir:
        {
            m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resize-ne-sw-cursor"] hotSpot:NSMakePoint(7, 7)];
        }
            break;
        case kLDir:
            m_cursor = [[NSCursor resizeLeftRightCursor] retain];
            break;
        default:
        {
            float xScale = [[m_idDocument contents] xscale];
            float yScale = [[m_idDocument contents] yscale];
            NSRect cropRect = NSMakeRect(m_sCropRect.origin.x * xScale, m_sCropRect.origin.y * yScale, m_sCropRect.size.width * xScale, m_sCropRect.size.height * yScale);
            if(NSPointInRect(where, cropRect))
                m_cursor = [[NSCursor openHandCursor] retain];
            else
                m_cursor = [[NSCursor crosshairCursor] retain];

        }
    }
    
    [m_cursor set];
}

- (IntRect)cropRect
{
	int width, height;
	
	width = [(PSContent *)[m_idDocument contents] width];
	height = [(PSContent *)[m_idDocument contents] height];
	return IntConstrainRect(m_sCropRect, IntMakeRect(0, 0, width, height));
}

- (void)updateCropState
{
    if (m_sCropRect.size.width <= 0 || m_sCropRect.size.height <= 0) {
        [m_idOptions setCropButtonHidden:YES];
    }else{
        [m_idOptions setCropButtonHidden:NO];
    }
}

- (void)clearCrop
{
	m_sCropRect.size.width = m_sCropRect.size.height = 0;
	[[m_idDocument helpers] selectionChanged];
    [self updateCropState];
}

- (void)adjustCrop:(IntPoint)offset
{
	m_sCropRect.origin.x += offset.x;
	m_sCropRect.origin.y += offset.y;
	[[m_idDocument helpers] selectionChanged];
    [self updateCropState];
}

- (void)setCropRect:(IntRect)newCropRect
{
	m_sCropRect = newCropRect;
	[[m_idDocument helpers] selectionChanged];
    [self updateCropState];
}

- (BOOL)stopCurrentOperation
{
    [self clearCrop];
    return YES;
}


#pragma mark - Tool Enter/Exit
-(BOOL)enterTool
{
    [self updateCropState];
    [super enterTool];
    
    [[m_idDocument docView] setNeedsDisplay:YES];
    [[[PSController utilitiesManager] infoUtilityFor:m_idDocument] update];
    
    return YES;
}

-(BOOL)exitTool:(int)newTool
{
    [super exitTool:newTool];
    
    [[m_idDocument docView] setNeedsDisplay:YES];
    [[[PSController utilitiesManager] infoUtilityFor:m_idDocument] update];
    
    [self clearCrop];
    
    return YES;
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

- (BOOL)enterKeyPressed
{
    if (m_sCropRect.size.width > 0 || m_sCropRect.size.height > 0) {
        [m_idOptions crop:nil];
        return YES;
    }
    return NO;
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    if (m_sCropRect.size.width <= 0 || m_sCropRect.size.height <= 0) {
        return YES;
        
    }else{
        return NO;
    }
    return NO;
}

#pragma mark - UI View
- (BOOL)canResponseForView:(id)view
{
//    if(view == [[PSController utilitiesManager] pegasusUtilityFor:gCurrentDocument])
//        return NO;
//    
//    return YES;
    
    if (m_sCropRect.size.width <= 0 || m_sCropRect.size.height <= 0)
    {
        return YES;
    }
    
    NSBeep();
    
    return NO;
}

@end
