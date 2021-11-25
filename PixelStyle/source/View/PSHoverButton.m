//
//  PSHoverButton.m
//  PixelStyle
//
//  Created by wyl on 16/4/14.
//
//

#import "PSHoverButton.h"

@interface PSHoverButton ()
{
    NSTrackingArea *trackingArea;
    
    BOOL m_bHover;
}
@end

@implementation PSHoverButton


-(void)drawRect:(NSRect)dirtyRect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:self.frame.size.height];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
    
    if(self.state)
    {
        NSImage *image = [NSImage imageNamed:@"btn-a"];
        CGContextDrawImage(context, self.bounds, [image CGImageForProposedRect:nil context:nil hints:nil]);
        CGContextDrawImage(context, self.bounds, [self.image CGImageForProposedRect:nil context:nil hints:nil]);
    }
    else if(m_bHover)
    {
        NSImage *image = [NSImage imageNamed:@"btn-h"];
        
        CGContextDrawImage(context, self.bounds, [self.image CGImageForProposedRect:nil context:nil hints:nil]);
        CGContextDrawImage(context, self.bounds, [image CGImageForProposedRect:nil context:nil hints:nil]);
    }
    else
    {
        CGContextDrawImage(context, self.bounds, [self.image CGImageForProposedRect:nil context:nil hints:nil]);
    }

    
//    if(self.state)
//        CGContextDrawImage(context, self.bounds, [self.alternateImage CGImageForProposedRect:nil context:nil hints:nil]);
//    else if(m_bHover)
//        CGContextDrawImage(context, self.bounds, [self.hoverImage CGImageForProposedRect:nil context:nil hints:nil]);
//    else
//        CGContextDrawImage(context, self.bounds, [self.image CGImageForProposedRect:nil context:nil hints:nil]);
}

- (void) createTrackingArea
{
    NSTrackingAreaOptions options = NSTrackingInVisibleRect | NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
    trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint: mouseLocation fromView: nil];
    
    if (NSPointInRect(mouseLocation, [self bounds]))
    {
        [self mouseEntered:nil];
    }
    else
    {
        [self mouseExited:nil];
    }
}

-(void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if(trackingArea)
    {
        [self removeTrackingArea:trackingArea];
        [trackingArea release];
    }
   
    [self createTrackingArea];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    if(!self.state)
        m_bHover = YES;
    
    [self setNeedsDisplay:YES];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    m_bHover = NO;
    
    [self setNeedsDisplay:YES];
}

-(void)dealloc
{
    if(trackingArea)
    {
        [self removeTrackingArea:trackingArea];
        [trackingArea release];
    }
    
    if(self.hoverImage) self.hoverImage = nil;
    
    [super dealloc];
}

@end

@interface PSPopButtonImage ()
{
    NSTrackingArea *trackingArea;
    
    BOOL m_bHover;
}
@end

@implementation PSPopButtonImage

-(void)drawRect:(NSRect)dirtyRect
{
    if(!m_showImage) return;
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:self.frame.size.height];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
    
//    if(self.state)
//    {
//        NSImage *image = [NSImage imageNamed:@"btn-a"];
//        CGContextDrawImage(context, self.bounds, [image CGImageForProposedRect:nil context:nil hints:nil]);
//        CGContextDrawImage(context, self.bounds, [m_showImage CGImageForProposedRect:nil context:nil hints:nil]);
//    }
//    else
    if(m_bHover)
    {
        NSImage *image = [NSImage imageNamed:@"btn-h"];
        
        CGContextDrawImage(context, self.bounds, [m_showImage CGImageForProposedRect:nil context:nil hints:nil]);
        CGContextDrawImage(context, self.bounds, [image CGImageForProposedRect:nil context:nil hints:nil]);
    }
    else
    {
        CGContextDrawImage(context, self.bounds, [m_showImage CGImageForProposedRect:nil context:nil hints:nil]);
    }
    
    CGContextRestoreGState(context);
}

-(void)awakeFromNib
{
    [self.cell setArrowPosition:NSPopUpNoArrow];
    [self.cell setBezeled:YES];
    [self setBordered:NO];
    
    self.state = NSOffState;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popUpButtonCellWillPopUp) name:NSPopUpButtonCellWillPopUpNotification object:nil];
}

-(void)popUpButtonCellWillPopUp
{
    [self selectItem:nil];
}

-(void)setShowImage:(NSImage *)image
{
    if(m_showImage) {[m_showImage release]; m_showImage = nil;}
    
    m_showImage = [image retain];
}


-(void)dealloc
{
    if(m_showImage) {[m_showImage release]; m_showImage = nil;}
    
    if(trackingArea)
    {
        [self removeTrackingArea:trackingArea];
        [trackingArea release];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPopUpButtonCellWillPopUpNotification object:nil];
    
    [super dealloc];
}

- (void) createTrackingArea
{
    NSTrackingAreaOptions options = NSTrackingInVisibleRect | NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited;
    trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds] options:options owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint: mouseLocation fromView: nil];
    
    if (NSPointInRect(mouseLocation, [self bounds]))
    {
        [self mouseEntered:nil];
    }
    else
    {
        [self mouseExited:nil];
    }
}

-(void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    if(trackingArea)
    {
        [self removeTrackingArea:trackingArea];
        [trackingArea release];
    }
    
    [self createTrackingArea];
}

-(void)mouseEntered:(NSEvent *)theEvent
{
//    if(!self.state)
        m_bHover = YES;
    
    [self setNeedsDisplay:YES];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    m_bHover = NO;
    
    [self setNeedsDisplay:YES];
}


@end

