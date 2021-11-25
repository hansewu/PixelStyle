//
//  PSColorSlider.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class PSColorIndicator;
@class WDColor;

typedef enum {
    PSColorSliderModeHue,
    PSColorSliderModeSaturation,
    PSColorSliderModeBrightness,
    PSColorSliderModeRed,
    PSColorSliderModeGreen,
    PSColorSliderModeBlue,
    PSColorSliderModeAlpha,
    PSColorSliderModeRedBalance,
    PSColorSliderModeGreenBalance,
    PSColorSliderModeBlueBalance
} PSColorSliderMode;

@interface PSColorSlider : NSSlider {
    CGImageRef          hueImage_;
    WDColor             *color_;
    float               value_;
    PSColorIndicator    *indicator_;
    CGShadingRef        shadingRef_;
    PSColorSliderMode   mode_;
    BOOL                reversed_;
}

@property (nonatomic, assign) PSColorSliderMode mode;
@property (nonatomic, assign) float floatValue;
@property (nonatomic, strong) WDColor *color;
@property (nonatomic, assign) BOOL reversed;
@property (nonatomic, strong, readonly) PSColorIndicator *indicator;

@end
