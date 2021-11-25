#import <Cocoa/Cocoa.h>

@interface LADSliderCell : NSSliderCell

/**
    knobImage - image of the knob
    depends on slider control size it should have the next size:
    NSRegularControlSize:   21x21
    NSSmallControlSize:     15x15
    NSMiniControlSize:
 */
@property (nonatomic,retain) NSImage* barImage;
@property (nonatomic,retain) NSImage *knobImage;
@property (nonatomic,retain) NSImage *minimumValueImage;
@property (nonatomic,retain) NSImage *maximumValueImage;


/**
    Return LADSlider with custom knob and standard NSSlider bar
    If the argument is nil
    the method will return nil
 */
- (id)initWithKnobImage:(NSImage *)knob barImage:(NSImage *)barImage;

/**
    Return LADSlider with custom knob and tack
        isProgressType == NO
    If the one of the followings arguments is nil
    the method will return nil
 */
- (id)initWithKnobImage:(NSImage *)knob minimumValueImage:(NSImage *)minImage maximumValueImage:(NSImage *)maxImage;

@end
