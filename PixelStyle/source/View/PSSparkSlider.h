//
//  PSSparkSlider.h
//

#import <AppKit/AppKit.h>

@interface PSSparkSlider : NSControl {
    NSTextField         *valueLabel_;
    NSImageView         *indicator_;
    
    CGPoint             initialPt_;
    NSUInteger          initialValue_;
    
    BOOL                dragging_;
    BOOL                moved_;
    
    
    id                  m_controller;
}

@property (nonatomic, readonly) NSTextField *title;
@property (assign, nonatomic, readonly) NSNumber *numberValue;
@property (nonatomic, assign) float value;
@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float maxValue;

-(void)setController:(id)controller;
- (void) updateIndicator;

@end
