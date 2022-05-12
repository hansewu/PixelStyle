//
//  PSGradientController.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>


@class PSColorController;
@class PSColorWell;
@class PSGradientEditor;
@class WDGradient;
@class WDColor;

@interface PSGradientController : NSViewController <NSTextFieldDelegate>{
    IBOutlet PSGradientEditor       *gradientEditor_;
    IBOutlet PSColorWell            *colorWell_;
    IBOutlet NSButton               *typeButton_;
    
    IBOutlet NSSlider   *m_sliderAngle;
    IBOutlet NSTextField *m_textFiledAngle;
    
}

@property (nonatomic, strong) WDGradient *gradient;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) PSColorController *colorController;
@property (nonatomic, assign) BOOL inactive;

- (IBAction) takeGradientTypeFrom:(id)sender;
- (IBAction) takeGradientStopsFrom:(id)sender;

- (void) colorSelected:(WDColor *)color;
- (void) setColor:(WDColor *)color;

- (void) reverseGradient:(id)sender;
- (void) distributeGradientStops:(id)sender;

-(void)noAccessory;

@end
