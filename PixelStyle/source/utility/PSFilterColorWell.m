//
//  PSFilterColorWell.m
//  PixelStyle
//
//  Created by lchzh on 9/3/16.
//
//

#import "PSFilterColorWell.h"

@implementation PSFilterColorWell

- (void)activate:(BOOL)exclusive
{
    [super activate:exclusive];
    
    [[NSColorPanel sharedColorPanel] setContinuous:NO];
    [[NSColorPanel sharedColorPanel] setAction:NULL];
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

- (id)initWithFrame:(NSRect)frame delegate:(id)delegate
{
    self = [super initWithFrame:frame];
    m_delegate = delegate;
    
    return self;
}


- (void)setColor:(NSColor *)color
{
    [super setColor:color];
    if (m_delegate) {
        [m_delegate setColor:color colorWell:self];
    }
}

- (void)changeUIColor:(NSColor *)color
{
    [super setColor:color];
}


@end
