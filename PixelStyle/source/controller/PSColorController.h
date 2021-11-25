//
//  PSColorController.h
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
#import <AppKit/AppKit.h>

@class PSColorSlider;
@class PSColorWell;
@class WDColor;

typedef enum {
    WDColorSpaceRGB,
    WDColorSpaceHSB,
} WDColorSpace;

@interface PSColorController : NSViewController {
    IBOutlet PSColorSlider      *component0Slider_;
    IBOutlet PSColorSlider      *component1Slider_;
    IBOutlet PSColorSlider      *component2Slider_;
    IBOutlet PSColorSlider      *alphaSlider_;
    
    IBOutlet NSTextField            *component0Name_;
    IBOutlet NSTextField            *component1Name_;
    
    IBOutlet NSTextField            *component0Value_;
    IBOutlet NSTextField            *component1Value_;
    IBOutlet NSTextField            *component2Value_;
    IBOutlet NSTextField            *alphaValue_;
    
    IBOutlet NSButton           *colorSpaceButton_;
    IBOutlet NSButton           *colorSpaceHSBButton_;
    IBOutlet NSButton           *colorSpaceRGBButton_;
    
    IBOutlet PSColorWell        *colorWell_;
    
    WDColorSpace                 colorSpace_;
}

@property (nonatomic, strong) WDColor *color;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;
@property (assign, nonatomic, readonly) PSColorWell *colorWell;

- (IBAction) takeColorSpaceFrom:(id)sender;

@end

extern NSString *WDColorSpaceDefault;
