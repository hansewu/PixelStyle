#import "AbstractScaleTool.h"
#import "AbstractTool.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "OptionsUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "AbstractSelectOptions.h"
#import "PSSelection.h"
#import "AbstractScaleTool.h"
#import "AbstractScaleOptions.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSHelpers.h"
#import "AspectRatio.h"
#import "PSLayer.h"

@class CropTool;
@implementation AbstractScaleTool
- (id)init
{
	if (![super init])
		return NULL;

	m_bTranslating = NO;
	m_nScalingDir = kNoDir;
	m_pPreScaledMask = NULL;
	
	return self;
}

- (BOOL) isMovingOrScaling
{
	return (m_bTranslating || m_nScalingDir > kNoDir);
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
//		m_sPreScaledRect = globalRect;

        IntRect trueLocalRect = [[m_idDocument selection] trueLocalRect];
        id layer = [[m_idDocument contents] activeLayer];
        
        m_sPreScaledRect.origin.x = trueLocalRect.origin.x + [layer xoff];
        m_sPreScaledRect.origin.y = trueLocalRect.origin.y + [layer yoff];
        m_sPreScaledRect.size = trueLocalRect.size;
        
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
//            m_sOldOrigin.x = localRect.origin.x - [[m_idDocument selection] maskOffset].x;
//            m_sOldOrigin.y = localRect.origin.y - [[m_idDocument selection] maskOffset].y;
            
            m_sOldOrigin = [[m_idDocument selection] globalRect].origin;
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

- (void)mouseUpAt:(IntPoint)localPoin forRect:(IntRect)globalRect andMask:(unsigned char *)mask
{
	if(m_nScalingDir > kNoDir){
		if(m_pPreScaledMask)
			free(m_pPreScaledMask);
	}
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    int nScalingDir = m_nScalingDir;
    
    if(nScalingDir <= kNoDir)
        nScalingDir = [self point:where isInHandleFor:[[m_idDocument selection] globalRect]];
   
    if(nScalingDir <= kNoDir) return;
    if(m_cursor) {[m_cursor release]; m_cursor  = nil;}
    
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
            m_cursor = [[NSCursor arrowCursor] retain];
    }
    
    [m_cursor set];
}

- (int)point:(NSPoint) point isInHandleFor:(IntRect)rect
{
	
	float xScale = [[m_idDocument contents] xscale];
	float yScale = [[m_idDocument contents] yscale];
	rect = IntMakeRect(rect.origin.x * xScale, rect.origin.y * yScale, rect.size.width * xScale, rect.size.height * yScale);
	
    int nOffset = 10;
	BOOL inTop = point.y + nOffset > rect.origin.y && point.y - nOffset < rect.origin.y;
	BOOL inMiddle = point.y+ nOffset > (rect.origin.y + rect.size.height / 2) && point.y - nOffset < (rect.origin.y + rect.size.height / 2);
	BOOL inBottom = point.y+ nOffset> (rect.origin.y + rect.size.height) && point.y - nOffset< (rect.origin.y + rect.size.height);
	
	BOOL inLeft = point.x + nOffset > rect.origin.x && point.x -nOffset  < rect.origin.x;
	BOOL inCenter = point.x + nOffset > (rect.origin.x + rect.size.width / 2) && point.x - nOffset < (rect.origin.x + rect.size.width / 2);
	BOOL inRight =  point.x + nOffset > (rect.origin.x + rect.size.width) && point.x - nOffset < (rect.origin.x + rect.size.width);
	
	if(inTop && inLeft )
		return kULDir;
	if(inTop&& inCenter)
		return kUDir;
	if(inTop && inRight)
		return kURDir;
	if(inMiddle && inRight)
		return kRDir;
	if(inBottom && inRight)
		return kDRDir;
	if(inBottom && inCenter)
		return kDDir;
	if(inBottom && inLeft)
		return kDLDir;
	if(inMiddle && inLeft)
		return kLDir;
	
	return kNoDir;
}

- (IntRect) preScaledRect
{
	return m_sPreScaledRect;
}

- (unsigned char *) preScaledMask
{
	return m_pPreScaledMask;
}

- (IntRect) postScaledRect
{
	return m_sPostScaledRect;
}

@end
