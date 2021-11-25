//
//  PSGestureButton.h
//  PixelStyle
//
//  Created by wyl on 16/1/23.
//
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, PSGestureRecognizerState)
{
    PSGestureRecognizerStatePossible,
    PSGestureRecognizerStateBegan,
    PSGestureRecognizerStateChanged,
    PSGestureRecognizerStateEnded,
    PSGestureRecognizerStateCancelled,
    PSGestureRecognizerStateFailed,
    PSGestureRecognizerStateRecognized = PSGestureRecognizerStateEnded
};

@interface PSPanGestureRecognizer : NSObject

@property(assign) NSView *view;
@property PSGestureRecognizerState state;
@property NSPoint offsetPoint;

@end


@protocol PSGestureRecognizerProtocal <NSObject>

-(void)handlePSPan:(PSPanGestureRecognizer*)recongnizer;

@end

@interface PSGestureButton : NSButton
{
    PSPanGestureRecognizer *m_panGestureRecognizer;
    id<PSGestureRecognizerProtocal>m_gestureRecognizerDelegate;
    
    BOOL m_bGestureRecognizerStateBegan;
    NSPoint m_pointPrev;
}

- (void)addPSGestureRecognizer:(id)gestureRecognizerDelegate;
- (void)removePSGestureRecognizer:(id)gestureRecognizerDelegate;

@end
