//
//  MyCustomView.h
//  PixelStyle
//
//  Created by wyl on 15/11/16.
//
//

#import <Cocoa/Cocoa.h>

@protocol MyCustomVewDelegate <NSObject>

@optional
-(void)viewDidDismiss:(NSNotification *)notification;

@end

@interface MyCustomView : NSView
{
    id m_idEventLocalMonitor;
    id <MyCustomVewDelegate> m_delegate;
}

- (void)setCustomDelegate:(id)delegate;

@end
