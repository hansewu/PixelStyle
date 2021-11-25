//
//  PSColorSelectView.h
//  Curves
//
//  Created by lchzh on 10/10/15.
//  Copyright © 2015 lchzh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PSColorSelectView : NSView
{
    id m_delegate;
    int m_viewTag;
    unsigned char m_viewColor[3];
}

- (void)setCustumDelegate:(id)delegate;
- (void)setViewTag:(int)tag;

@end


@interface NSObject (PSColorSelectViewDelegate)

- (unsigned char*)getViewColorWithTag:(int)tag;
- (void)colorSelectViewClickedWithTag:(int)tag;


@end