#import "WandTool.h"
#import "PSTools.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "Bucket.h"
#import "PSWhiteboard.h"
#import "WandOptions.h"
#import "PSSelection.h"

@implementation WandTool

- (id)init
{
    if (![super init])
        return NULL;
    
    if(m_curDefault)            {[m_curDefault release]; m_curDefault = nil;}
    if(m_curAdd)                {[m_curAdd release]; m_curAdd = nil;}
    if(m_curSubtract)           {[m_curSubtract release]; m_curSubtract = nil;}
    if(m_curMultipy)            {[m_curMultipy release]; m_curMultipy = nil;}
    if(m_curSubtractProduct)    {[m_curSubtractProduct release]; m_curSubtractProduct = nil;}
    m_curDefault = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curAdd = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-add-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curSubtract = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subtract-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curMultipy = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-multiply-cursor"] hotSpot:NSMakePoint(7, 7)];
    m_curSubtractProduct = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"crosspoint-subProduct-cursor"] hotSpot:NSMakePoint(7, 7)];
    
    return self;
}

- (int)toolId
{
	return kWandTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Magic Wand Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"W";
}

- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDownAt:where withEvent:event];
	
	if(![super isMovingOrScaling]){
		m_sStartPoint = where;
		m_poiStart = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
		m_poiCurrent = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
		m_bIntermediate = YES;
	}
}

- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseDraggedTo:where withEvent:event];
	
	if(![super isMovingOrScaling]){
		m_poiCurrent = [[m_idDocument docView] convertPoint:[event locationInWindow] fromView:NULL];
		[[m_idDocument docView] setNeedsDisplay: YES];
	}
}

- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event
{
	[super mouseUpAt:where withEvent:event];

	if(![super isMovingOrScaling]){
		// Check for a valid click
        
        id layer = [[m_idDocument contents] activeLayer];
        int tolerance, width = [(PSLayer *)layer width], height = [(PSLayer *)layer height], spp = [[m_idDocument contents] spp], k;
        
        
		if (where.x >= 0 && where.y >= 0 && where.x < width && where.y < height) {
            
            MAKE_OVERLAYER_INFO info;
            info.activeLayer = [[m_idDocument contents] activeLayerIndex];
            info.startPoint = m_sStartPoint;
            info.endPoint = where;
            info.intervals = [m_idOptions numIntervals];
            info.tolerance = [(WandOptions *)m_idOptions tolerance];
            info.mode = [m_idOptions selectionMode];
            info.destructively = YES;
            info.nFeather = [m_idOptions feather];
            [[m_idDocument selection] selectOverlay:info];
		}
		m_bIntermediate = NO;
        
        

	}

	m_bTranslating = NO;
	m_nScalingDir = kNoDir;
}


- (NSPoint)start
{
	return m_poiStart;
}

-(NSPoint)current
{
	return m_poiCurrent;
}

@end
