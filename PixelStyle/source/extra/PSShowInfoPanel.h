//
//  PSShowInfoPanel.h
//  PixelStyle
//
//  Created by wyl on 16/3/24.
//
//

#import <Cocoa/Cocoa.h>

@interface PSShowInfoPanel : NSPanel
{
    float m_fDelayTime;
}

-(void)addMessageText:(NSString *)sMessage;
-(void)setMessageTextFontSize:(int)nFontSize;
-(void)setAutoHiddenDelay:(float)fDelayTime;

- (void)showPanel:(NSRect)rect;
-(void)closePanel;

@end
