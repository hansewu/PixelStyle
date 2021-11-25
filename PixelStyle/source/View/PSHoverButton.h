//
//  PSHoverButton.h
//  PixelStyle
//
//  Created by wyl on 16/4/14.
//
//

#import <Cocoa/Cocoa.h>

@interface PSHoverButton : NSButton

@property (nullable, strong) NSImage *hoverImage;

@end


@interface PSPopButtonImage : NSPopUpButton
{
    NSImage *m_showImage;
}

-(void)setShowImage:(NSImage *)image;

@end

