#import "AbstractPanelUtility.h"

#import "InfoPanel.h"

@implementation AbstractPanelUtility
- (void)awakeFromNib
{
	// Set up the window's properties
	[(InfoPanel *)m_winWindow setPanelStyle:kVerticalPanelStyle];
	m_winParent = NULL;
}	

- (void)showPanelFrom:(NSPoint)p onWindow: (NSWindow *)parent
{
	m_winParent = parent;
    [self showPanel];
    
	[(InfoPanel *)m_winWindow orderFrontToGoal: p onWindow: m_winParent];
//	[NSApp runModalForWindow:m_winWindow];
}


-(void)showPanel
{
    if(!m_idEventLocalMonitor)
    {
        m_idEventLocalMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^NSEvent*(NSEvent *event)
                                 {
                                     // NSLog(@"NSLeftMouseDownMask notification");
                                     if(CGRectContainsPoint([m_winWindow frame],  [NSEvent mouseLocation]) == false)
                                     {
                                         [self hidePanel];
                                         return nil;
                                     }
                                     return event;
                                 }];
    }
    
    if(!m_idEventGlobalMonitor)
    {
        m_idEventGlobalMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^void(NSEvent* event)
                                  {
                                      // NSLog(@"NSLeftMouseDownMask notification");
                                      if(CGRectContainsPoint([m_winWindow frame],  [NSEvent mouseLocation]) == false)
                                      {
                                          [self hidePanel];
                                      }
                                      
                                  }];
    }
    
}

-(void)hidePanel
{
    
    if(m_idEventLocalMonitor)
    {
        [NSEvent removeMonitor:m_idEventLocalMonitor];
    }
    
    if(m_idEventGlobalMonitor)
    {
        [NSEvent removeMonitor:m_idEventGlobalMonitor];
    }
    
    m_idEventLocalMonitor = nil;
    m_idEventGlobalMonitor = nil;
    
    [self closePanel:nil];
}


- (IBAction)closePanel:(id)sender
{
	[NSApp stopModal];
	if (m_winParent){
		[m_winParent removeChildWindow:m_winWindow];
		m_winParent = NULL;
	}
	[m_winWindow orderOut:self];	
}

@end
