//
//  PSGradientWindow.h
//  PixelStyle
//
//  Created by lchzh on 5/18/16.
//
//

#import <Cocoa/Cocoa.h>

#import "PSWindow.h"
#import "PSGradientButton.h"



@interface PSGradientWindow : PSWindow
{
//    IBOutlet NSPopUpButton *m_popBtnGradientStyle;
//    IBOutlet NSSlider *m_sliderGradientAngle;
//    IBOutlet NSSlider *m_sliderGradientScaleRatio;
    
    IBOutlet PSGradientButton *m_btnGradient;
    
    IBOutlet NSButton          *m_btnReverse;
    IBOutlet NSButton          *m_btnOK;
    
    id m_idGradientDelegate;
    GRADIENT_COLOR m_structGradientColor;
    
}

@property (assign) IBOutlet NSPopUpButton *presetsButton;
@property (retain) NSMutableArray *checkBoxes;
@property (retain) NSMutableArray *colorWells;
@property (retain) NSMutableArray *sliders;
@property (retain) NSMutableArray *names;
@property (retain) NSMutableArray *gradients;

- (void)setGradientDelegate:(id)delegate;
- (void)setGradientColor:(GRADIENT_COLOR)gradientColor;

@end

@interface  NSObject (PSGradientWindowDelagate)

- (void)gradientColorChanged:(GRADIENT_COLOR)gradientColor;

@end
