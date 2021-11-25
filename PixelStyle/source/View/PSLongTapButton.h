//
//  PSLongTapButton.h
//  PixelStyle
//
//  Created by wyl on 16/3/10.
//
//

#import <Cocoa/Cocoa.h>

@protocol PSLongTapButtonDelegate <NSObject>

-(void)longTapDelegate:(id)sender;

@end

@interface PSLongTapButton : NSButton
{
    bool m_bTap;
    float m_dBeginTime;
    id<PSLongTapButtonDelegate> m_delegate;
}

-(void)setDelegate:(id<PSLongTapButtonDelegate>)delegate;
-(id<PSLongTapButtonDelegate>)delegate;

@end
