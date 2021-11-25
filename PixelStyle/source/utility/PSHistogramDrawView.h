//
//  PSHistogramDrawView.h
//  PixelStyle
//
//  Created by lchzh on 4/11/15.
//
//

#import <Cocoa/Cocoa.h>

@interface PSHistogramDrawView : NSView
{
    id m_idDelegate;
}

- (void)setCustomDelegate:(id)delegate;

@end

@interface NSObject (PSHistogramDrawViewDelegate)

- (int)getSelectedColorIndex;
- (unsigned char*)getGrayHistogramInfo;
- (unsigned char*)getRGBHistogramInfo;

@end
