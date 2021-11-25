#import "RectSelectTool.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "PSHelpers.h"
#import "RectSelectOptions.h"
#import "PSContent.h"
#import "PSTools.h"
#import "AspectRatio.h"
#import "PSAbstractLayer.h"

@implementation RectSelectTool

- (int)toolId
{
	return kRectSelectTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Rectangular Marquee Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"M";
}

- (IntRect) selectionRect
{
	return m_sSelectionRect;
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDownAt:where withEvent:event];
	
	// Do the following rect select specific behvior
	if (![super isMovingOrScaling]) {
		int aspectType = [m_idOptions aspectType];
		NSSize ratio;
		double xres, yres;
		int modifier;
		
		// Get mode
		modifier = [m_idOptions modifier];
		if(modifier == kShiftModifier){
			m_bOneToOne = YES;
		}else{
			m_bOneToOne = NO;
		}
		
		// Clear the active selection and start the selection
		if ([m_idOptions selectionMode] == kDefaultMode || [m_idOptions selectionMode] == kForceNewMode){
			//[[m_idDocument selection] clearSelectionShow];
            m_bOldActive = [[m_idDocument selection] active];
            [[m_idDocument selection] setActive:NO];
		}
		
		// Record the start point
		m_sStartPoint = where;

		m_sSelectionRect.origin = where;
		
		// If we have a fixed size selection
		if (aspectType >= kExactPixelAspectType) {
		
			// Determine it
			ratio = [m_idOptions ratio];
			xres = [[m_idDocument contents] xres];
			yres = [[m_idDocument contents] yres];
			switch (aspectType) {
				case kExactPixelAspectType:
					m_sSelectionRect.size.width = ratio.width;
					m_sSelectionRect.size.height = ratio.height;
				break;
				case kExactInchAspectType:
					m_sSelectionRect.size.width = ratio.width * xres;
					m_sSelectionRect.size.height = ratio.height * yres;
				break;
				case kExactMillimeterAspectType:
					m_sSelectionRect.size.width = ratio.width * xres * 0.03937;
					m_sSelectionRect.size.height = ratio.height * yres * 0.03937;
				break;
			}
		}
		m_bIntermediate = YES;
		[[m_idDocument helpers] selectionChanged];
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDraggedTo:where withEvent:event];
	
	// Check we have a valid start point
	if (m_bIntermediate && ![super isMovingOrScaling]) {
		int aspectType = [m_idOptions aspectType];
		NSSize ratio;

		if (aspectType == kNoAspectType || aspectType == kRatioAspectType || m_bOneToOne) {
			
			// Determine the width of the selection rectangle
			if (m_sStartPoint.x < where.x) {
				m_sSelectionRect.size.width = where.x - m_sStartPoint.x;
				m_sSelectionRect.origin.x = m_sStartPoint.x;
			} else {
				m_sSelectionRect.origin.x = where.x;
				m_sSelectionRect.size.width = m_sStartPoint.x - where.x;
			}
			
			// Determine the height of the selection rectangle
			if (aspectType == kRatioAspectType || m_bOneToOne) {
				if (m_bOneToOne)
					ratio = NSMakeSize(1, 1);
				else
					ratio = [m_idOptions ratio];
				if (m_sStartPoint.y < where.y) {
					m_sSelectionRect.size.height = m_sSelectionRect.size.width * ratio.height;
					m_sSelectionRect.origin.y = m_sStartPoint.y;
				}
				else {
					m_sSelectionRect.size.height = m_sSelectionRect.size.width * ratio.height;
					m_sSelectionRect.origin.y = m_sStartPoint.y - m_sSelectionRect.size.height;
				}
			}
			else {
				if (m_sSelectionRect.origin.y < where.y) {
					m_sSelectionRect.size.height = where.y - m_sStartPoint.y;
					m_sSelectionRect.origin.y = m_sStartPoint.y;
				}
				else {
					m_sSelectionRect.origin.y = where.y;
					m_sSelectionRect.size.height = m_sStartPoint.y - where.y;
				}
			}		
		}
		else {
			// Just change the origin
			m_sSelectionRect.origin.x = where.x;
			m_sSelectionRect.origin.y = where.y;
		}
		[[m_idDocument helpers] selectionChanged];
		
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseUpAt:where withEvent:event];
	
	if(m_bIntermediate && ![super isMovingOrScaling]){
        m_sSelectionRect.origin.x += [[[m_idDocument contents] activeLayer] xoff];
        m_sSelectionRect.origin.y += [[[m_idDocument contents] activeLayer] yoff];
        
		if([(RectSelectOptions*)m_idOptions radius]){
			[[m_idDocument selection] selectRoundedRect:m_sSelectionRect radius:[(RectSelectOptions*)m_idOptions radius] mode:[m_idOptions selectionMode] feather:[m_idOptions feather]];
		}else{
			[[m_idDocument selection] selectRect:m_sSelectionRect mode:[m_idOptions selectionMode] feather:[m_idOptions feather]];
		}
		m_sSelectionRect = IntMakeRect(0,0,0,0);
		m_bIntermediate = NO;
	}
	
	// It's the responsibility of the subclass to reset these when its done
	m_nScalingDir = kNoDir;
	m_bTranslating = NO;
}

- (void)cancelSelection
{
	m_sSelectionRect = IntMakeRect(0,0,0,0);
	[super cancelSelection];
}

- (void)reset
{
	NSLog(@"RectSelectTool invalidly being asked to reset");
}

- (IntRect)cropRect
{
	NSLog(@"RectSelectTool invalidly being asked for the crop rect");
	return IntMakeRect(0, 0, 0, 0);
}

- (BOOL)stopCurrentOperation
{
    m_bIntermediate = NO;
    m_bTranslating = NO;
    m_nScalingDir = kNoDir;
    m_sSelectionRect = IntMakeRect(0,0,0,0);
    [[m_idDocument selection] setActive:m_bOldActive];
    
    //[self cancelSelection];
    
    return YES;
    
}


@end
