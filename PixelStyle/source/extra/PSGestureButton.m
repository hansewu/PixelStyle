//
//  PSGestureButton.m
//  PixelStyle
//
//  Created by wyl on 16/1/23.
//
//

#import "PSGestureButton.h"

@implementation PSPanGestureRecognizer

@end


@implementation PSGestureButton



- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        m_panGestureRecognizer = [[PSPanGestureRecognizer alloc] init];
        m_gestureRecognizerDelegate = nil;
        m_bGestureRecognizerStateBegan = NO;
    }
    
    return self;
}

-(void)dealloc
{
    if (m_panGestureRecognizer) {[m_panGestureRecognizer release]; m_panGestureRecognizer = nil;}
    
    [super dealloc];
}

- (void)addPSGestureRecognizer:(id)gestureRecognizerDelegate
{
    m_gestureRecognizerDelegate = gestureRecognizerDelegate;
}

- (void)removePSGestureRecognizer:(id)gestureRecognizerDelegate
{
    m_gestureRecognizerDelegate = nil;
}

#pragma mark - Mouse Events 
-(void)mouseDown:(NSEvent *)theEvent
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
    {
        [super mouseDown:theEvent];
        return;
    }
    
    
    [self sendAction:self.action to:self.target];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
    {
        [super mouseDragged:theEvent];
        return;
    }

    if(!m_gestureRecognizerDelegate) return;
    
    NSPoint point = [theEvent locationInWindow];
    if(!m_bGestureRecognizerStateBegan)  //PSGestureRecognizerStateBegan
    {
        m_bGestureRecognizerStateBegan = YES;
        
        m_pointPrev = [self convertPoint:point toView:self];
        
        [m_panGestureRecognizer setView:self];
        [m_panGestureRecognizer setState:PSGestureRecognizerStateBegan];
        [m_panGestureRecognizer setOffsetPoint:NSZeroPoint];
        [m_gestureRecognizerDelegate handlePSPan:m_panGestureRecognizer];
        
        return;
    }
    
    point = [self convertPoint:point toView:self];
   
    NSPoint offsetPoint = NSMakePoint(point.x - m_pointPrev.x, point.y - m_pointPrev.y);
   
    [m_panGestureRecognizer setView:self];
    [m_panGestureRecognizer setState:PSGestureRecognizerStateChanged];
    [m_panGestureRecognizer setOffsetPoint:offsetPoint];
    [m_gestureRecognizerDelegate handlePSPan:m_panGestureRecognizer];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_9)
    {
        [super mouseUp:theEvent];
        return;
    }
    
    if(!m_gestureRecognizerDelegate) return;
    
    if(!m_bGestureRecognizerStateBegan) return;
    
    m_bGestureRecognizerStateBegan = NO;
    
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point toView:self];
    [m_panGestureRecognizer setView:self];
    [m_panGestureRecognizer setState:PSGestureRecognizerStateEnded];
    [m_panGestureRecognizer setOffsetPoint:NSMakePoint(point.x - m_pointPrev.x, point.y - m_pointPrev.y)];
    [m_gestureRecognizerDelegate handlePSPan:m_panGestureRecognizer];
}


@end
