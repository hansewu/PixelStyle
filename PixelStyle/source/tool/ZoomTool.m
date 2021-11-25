//
//  ZoomTool.m
//  PixelStyle
//
//  Created by wyl on 15/12/31.
//
//

#import "ZoomTool.h"
#import "PSDocument.h"
#import "PSView.h"
#import "ZoomOptions.h"
#import "PSTools.h"

@implementation ZoomTool

- (int)toolId
{
    return kZoomTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Zoom Tool", nil);
}


-(NSString *)toolShotKey
{
    return @"Z";
}

- (id)init
{
    self = [super init];
    if(self)
    {
        if(m_cursor) {[m_cursor release]; m_cursor = nil;}
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom-cursor"] hotSpot:NSMakePoint(5, 6)];
        
        m_strToolTips = [[NSString alloc] initWithFormat:@"%@",NSLocalizedString(@"Press Opt to switch scaling mode.", nil)];
    }
    return self;
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

- (void)mouseDownAt:(IntPoint)localPoint withEvent:(NSEvent *)event
{
    PSView *docView = [m_idDocument docView];
    NSPoint globalPoint = [docView convertPoint:[event locationInWindow] fromView:NULL];
    
    
    if ([(ZoomOptions *)m_idOptions IsZoomOut])
    {
        if ([docView canZoomOut])
            [docView zoomOutFromPoint:globalPoint];
        else
            NSBeep();
    }
    else {
        if ([docView canZoomIn])
            [docView zoomInToPoint:globalPoint];
        else
            NSBeep();
    }
}

-(void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    
    if ([(ZoomOptions *)m_idOptions IsZoomOut])
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoomOut-cursor"] hotSpot:NSMakePoint(7, 7)];
    else
        m_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoomIn-cursor"] hotSpot:NSMakePoint(7, 7)];
    
    [super mouseMoveTo:where withEvent:event];
}

@end
