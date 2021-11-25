//
//  HelpWindow.h
//  ImageMatting
//
//  Created by wyl on 15/2/7.
//  Copyright (c) 2015年 effectmatrix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HelpWindow : NSWindow<NSWindowDelegate>
{
    NSButton *m_checkButton;
    NSTextField *m_forumField;
}

-(void)hideCheckButton:(BOOL)bHide;

@end
