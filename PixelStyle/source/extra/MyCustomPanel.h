//
//  MyCustomPanel.h
//  PixelStyle
//
//  Created by wyl on 15/11/21.
//
//

#import <Cocoa/Cocoa.h>


@protocol MyCustomPanelDelegate <NSObject>

@optional
-(void)panelDidDismiss:(NSNotification *)notification;

@end



@interface MyCustomPanel : NSWindow
{
    id m_idEventLocalMonitor;
    id <MyCustomPanelDelegate> m_delegate;
}

- (void)setCustomDelegate:(id)delegate;

- (void)showPanel:(NSRect)rect;

-(void)hidePanel;

@end
