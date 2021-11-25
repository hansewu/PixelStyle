//
//  PSFilterColorWell.h
//  PixelStyle
//
//  Created by lchzh on 9/3/16.
//
//

#import <Cocoa/Cocoa.h>

@interface PSFilterColorWell : NSColorWell
{
    id m_delegate;
}

- (id)initWithFrame:(NSRect)frame delegate:(id)delegate;

- (void)changeUIColor:(NSColor *)color;

@end
