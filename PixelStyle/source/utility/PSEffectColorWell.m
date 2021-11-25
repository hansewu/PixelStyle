//
//  PSEffectColorWell.m
//  PixelStyle
//
//  Created by wyl on 15/12/31.
//
//

#import "PSEffectColorWell.h"

@implementation PSEffectColorWell

- (void)activate:(BOOL)exclusive
{
    [super activate:exclusive];
    
    [[NSColorPanel sharedColorPanel] setContinuous:NO];
    [[NSColorPanel sharedColorPanel] setAction:NULL];
    [[NSColorPanel sharedColorPanel] setShowsAlpha:NO];
}

- (void)setColor:(NSColor *)color
{
    [super setColor:color];
    
    [m_idEffectUtility setColor:color];
}

- (void)changeUIColor:(NSColor *)color
{
    [super setColor:color];
}

@end
