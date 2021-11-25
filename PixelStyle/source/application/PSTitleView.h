//
//  MyTitleView.h
//  testWindow
//
//  Created by lchzh on 27/3/15.
//  Copyright (c) 2015 lchzh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSTitleView : NSView
{
    NSString *m_windowTitle;
}

@property (nonatomic,retain) NSString *m_windowTitle;

@end
