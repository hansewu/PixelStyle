//
//  MyCustomPanel.m
//  PixelStyle
//
//  Created by wyl on 15/11/21.
//
//

#import "MyCustomPanel.h"

@implementation MyCustomPanel

- (void)setCustomDelegate:(id)delegate
{
    m_delegate = delegate;
}


- (void)showPanel:(NSRect)rect
{
    [self setAnimationBehavior:NSWindowAnimationBehaviorDefault];//NSWindowAnimationBehaviorDocumentWindow]; wzq
    [self showPanel];
    
    
    
//    [self setFrame:rect display:YES animate:YES];

   
    
    
    
//  
//    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
//        [context setDuration:2.0];
////        float rotation = animationView.frameRotation;
//        [[self animator] setFrameOrigin:NSZeroPoint];
//        [[self animator] setAlphaValue:0.0];
//        //[[animationView animator] setFrameRotation:rotation+360];
//    } completionHandler:^{
//        NSLog(@"All done!");
//    }];

//    [[NSAnimationContext currentContext] setDuration:2.0f];

//    [[self animator] setFrame:rect display:YES];
//    [[self animator] setAlphaValue:0.8];
//    
//    [NSAnimationContext endGrouping];
    
    [self setFrame:rect display:YES animate:YES];
    NSDocument *currentDoucemnt = [[NSDocumentController sharedDocumentController] currentDocument];
    
    NSWindow *window = [currentDoucemnt window];
    [window addChildWindow:self ordered:NSWindowAbove];
    
    [self orderFront:nil];
}

- (void)closePanel:(id)sender
{
    [NSApp stopModal];
    
    NSDocument *currentDoucemnt = [[NSDocumentController sharedDocumentController] currentDocument];
    NSWindow *window = [currentDoucemnt window];
    [window removeChildWindow:self];
    
    [self orderOut:nil];
}

-(void)showPanel
{
    if(!m_idEventLocalMonitor)
    {
        m_idEventLocalMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^NSEvent*(NSEvent *event)
                                 {
                                     
                                     if(CGRectContainsPoint([self frame],  [NSEvent mouseLocation]) == false)
                                     {
                                         [self hidePanel];
                                         return event;// wzq return nil eat this event
                                     }
                                     return event;
                                 }];
    }
    
}

-(void)hidePanel
{
    if(m_idEventLocalMonitor)
    {
        [NSEvent removeMonitor:m_idEventLocalMonitor];
        m_idEventLocalMonitor = nil;
    }
    
    
    NSNotification *notification = [NSNotification notificationWithName:@"" object:self];
    if(m_delegate)
        [m_delegate panelDidDismiss:notification];
    
    [self closePanel:nil];
}


-(void)dealloc
{
    [super dealloc];
}


@end
