//
//  PSEffectColorWell.h
//  PixelStyle
//
//  Created by wyl on 15/12/31.
//
//

#import <Cocoa/Cocoa.h>

@interface PSEffectColorWell : NSColorWell
{
    IBOutlet id m_idEffectUtility;
}

- (void)changeUIColor:(NSColor *)color;


@end
