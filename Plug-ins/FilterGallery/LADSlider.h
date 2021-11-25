

#import <Cocoa/Cocoa.h>

@interface LADSlider : NSSlider

- (id)initWithKnobImage:(NSImage *)knob barImage:(NSImage*)barImage;
- (id)initWithKnobImage:(NSImage *)knob minimumValueImage:(NSImage *)minImage maximumValueImage:(NSImage *)maxImage;

@property (retain,nonatomic) IBInspectable NSImage *barImage;
@property (retain,nonatomic) IBInspectable NSImage *knobImage;
@property (retain,nonatomic) IBInspectable NSImage *minimumValueImage;
@property (retain,nonatomic) IBInspectable NSImage *maximumValueImage;

@end
