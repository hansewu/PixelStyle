//
//  MyCustomView.m
//  PixelStyle
//
//  Created by wyl on 15/11/16.
//
//

#import "MyCustomView.h"

@implementation MyCustomView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)setCustomDelegate:(id)delegate
{
    m_delegate = delegate;
}

-(void)setHidden:(BOOL)hidden
{
    if (!hidden)
        [self showView];
    else
        [self hideView];
}

-(void)showView
{
    [super setHidden:NO];
    
    if(!m_idEventLocalMonitor)
    {
        m_idEventLocalMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^NSEvent*(NSEvent *event)
                                 {
                                     NSPoint point = [event locationInWindow];
                                     point = [[[self window] contentView] convertPoint:point toView:self];
                                     
                                     
                                     if(!CGRectContainsPoint([self bounds],  point))
                                    {
                                        [self hideView];
                                        return nil;
                                    }
                                     return event;
                                 }];
    }
    
}

-(void)hideView
{
    [super setHidden:YES];
    
    
    if(m_idEventLocalMonitor)
    {
        [NSEvent removeMonitor:m_idEventLocalMonitor];
        m_idEventLocalMonitor = nil;
    }
    
    
    NSNotification *notification = [NSNotification notificationWithName:@"" object:self];
    [m_delegate viewDidDismiss:notification];
}

-(void)dealloc
{
    [self hideView];
    
    [super dealloc];
}

@end
