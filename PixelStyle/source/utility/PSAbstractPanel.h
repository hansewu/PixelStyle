//
//  PSAbstractPanel.h
//  PixelStyle
//
//  Created by wyl on 16/3/7.
//
//

#import <Cocoa/Cocoa.h>

@interface PSAbstractPanel : NSWindowController
{
    IBOutlet id m_winWindow;
    
    NSWindow *m_winParent;
    
    
    id m_idEventLocalMonitor;
    id m_idEventGlobalMonitor;
}

/*!
	@method		showPanelFrom:
	@discussion	Brings the panel to the front (it's modal).
	@param		p
 This is an NSPoint which is the point the pointy part
 of the panel should be located at. Generally, it is just
 the point the mouse was, though it can be any point.
	@param		parent
 This is the window that the panel is attached to.
 */
- (void)showPanelFrom:(NSPoint)p onWindow:(NSWindow*) parent;

/*!
	@method		closePanel:
	@discussion	Closes the modal panel shown earlier.
	@param		sender
 Ignored.
 */
- (IBAction)closePanel:(id)sender;

@end
