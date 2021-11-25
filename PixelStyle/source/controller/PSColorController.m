//
//  PSColorController.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "PSColorController.h"
#import "PSColorSlider.h"
#import "PSColorWell.h"
#import "WDColor.h"

NSString *WDColorSpaceDefault = @"WDColorSpaceDefault";

@implementation PSColorController

@synthesize color = color_;
@synthesize target = target_;
@synthesize action = action_;
@synthesize colorWell = colorWell_;

- (void) setColor:(WDColor *)color notify:(BOOL)notify
{
    if(color_) [color_ release];
    color_ = [color retain];
    
    [component0Slider_ setColor:color_];
    [component1Slider_ setColor:color_];
    [component2Slider_ setColor:color_];
    [alphaSlider_ setColor:color_];
    
    [colorWell_ setPainter:color_];
    
    if (colorSpace_ == WDColorSpaceHSB) {
        component0Value_.stringValue = [NSString stringWithFormat:@"%d°", (int) round(color_.hue * 360)];
        component1Value_.stringValue = [NSString stringWithFormat:@"%d%%", (int) round(color_.saturation * 100)];
        component2Value_.stringValue = [NSString stringWithFormat:@"%d%%", (int) round(color_.brightness * 100)];
    } else {
        component0Value_.stringValue = [NSString stringWithFormat:@"%d", (int) round(color_.red * 255)];
        component1Value_.stringValue = [NSString stringWithFormat:@"%d", (int) round(color_.green * 255)];
        component2Value_.stringValue = [NSString stringWithFormat:@"%d", (int) round(color_.blue * 255)];
    }
    
    alphaValue_.stringValue = [NSString stringWithFormat:@"%d%%", (int) round(color_.alpha * 100)];
    
    if (notify) {
        
        [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
    }
}

- (void) setColor:(WDColor *)color
{
    [self setColor:color notify:NO];
}

- (void) setColorSpace:(WDColorSpace)space
{
    colorSpace_ = space;
    
    if (space == WDColorSpaceRGB) {
        component0Slider_.mode = PSColorSliderModeRed;
        component1Slider_.mode = PSColorSliderModeGreen;
        component2Slider_.mode = PSColorSliderModeBlue;
        
        component0Name_.stringValue = @"R";
        component1Name_.stringValue = @"G";
        
        [colorSpaceButton_ setTitle:@"HSB"];
//        [colorSpaceButton_ setTitle:@"HSB" forState:UIControlStateNormal];
        [colorSpaceHSBButton_ setState:NSOffState];
        [colorSpaceRGBButton_ setState:NSOnState];
    } else {
        component0Slider_.mode = PSColorSliderModeHue;
        component1Slider_.mode = PSColorSliderModeSaturation;
        component2Slider_.mode = PSColorSliderModeBrightness;
        
        component0Name_.stringValue = @"H";
        component1Name_.stringValue = @"S";
        
        [colorSpaceButton_ setTitle:@"RGB"];
//        [colorSpaceButton_ setTitle:@"RGB" forState:UIControlStateNormal];
        [colorSpaceRGBButton_ setState:NSOffState];
        [colorSpaceHSBButton_ setState:NSOnState];
    }
    
    [self setColor:color_ notify:NO];
    
    [[NSUserDefaults standardUserDefaults] setInteger:colorSpace_ forKey:WDColorSpaceDefault];
}

- (void) takeColorSpaceFrom:(id)sender
{
    if (colorSpace_ == WDColorSpaceRGB) {
        [self setColorSpace:WDColorSpaceHSB];
    } else {
        [self setColorSpace:WDColorSpaceRGB];
    }
}

-(void)awakeFromNib
//- (void)viewDidLoad
{
//    [super viewDidLoad];
    [super awakeFromNib];
    
    self.view.layer.backgroundColor = nil;
    self.view.layer.opaque = NO;
    
    [self setColorSpace:(WDColorSpace)[[NSUserDefaults standardUserDefaults] integerForKey:WDColorSpaceDefault]];
    alphaSlider_.mode = PSColorSliderModeAlpha;
    
//    [component0Slider_ setContinuous:YES];
    [component0Slider_ setTarget:self];
    [component0Slider_ setAction:@selector(takeFinalComponent0From:)];
    
//    [component1Slider_ setContinuous:YES];
    [component1Slider_ setTarget:self];
    [component1Slider_ setAction:@selector(takeFinalComponent1From:)];
    
//    [component2Slider_ setContinuous:YES];
    [component2Slider_ setTarget:self];
    [component2Slider_ setAction:@selector(takeFinalComponent2From:)];
    
//    [alphaSlider_ setContinuous:YES];
    [alphaSlider_ setTarget:self];
    [alphaSlider_ setAction:@selector(takeFinalOpacityFrom:)];
    
    
//    // set up connections
//    UIControlEvents dragEvents = (UIControlEventTouchDown | UIControlEventTouchDragInside | UIControlEventTouchDragOutside);
//    
//    [component0Slider_ addTarget:self action:@selector(takeComponent0From:) forControlEvents:dragEvents];
//    [component1Slider_ addTarget:self action:@selector(takeComponent1From:) forControlEvents:dragEvents];
//    [component2Slider_ addTarget:self action:@selector(takeComponent2From:) forControlEvents:dragEvents];
//    [alphaSlider_ addTarget:self action:@selector(takeOpacityFrom:) forControlEvents:dragEvents];
//    
//    UIControlEvents touchEndEvents = (UIControlEventTouchUpInside | UIControlEventTouchUpOutside);
//    
//    [component0Slider_ addTarget:self action:@selector(takeFinalComponent0From:) forControlEvents:touchEndEvents];
//    [component1Slider_ addTarget:self action:@selector(takeFinalComponent1From:) forControlEvents:touchEndEvents];
//    [component2Slider_ addTarget:self action:@selector(takeFinalComponent2From:) forControlEvents:touchEndEvents];
//    [alphaSlider_ addTarget:self action:@selector(takeFinalOpacityFrom:) forControlEvents:touchEndEvents];
}

- (void) takeComponent0From:(id)sender notify:(BOOL)notify
{
    WDColor     *newColor;
    float       component0 = [sender floatValue];
    
    if (colorSpace_ == WDColorSpaceHSB) {
        newColor = [WDColor colorWithHue:component0 saturation:[color_ saturation] brightness:[color_ brightness] alpha:[color_ alpha]];
    } else {
        newColor = [WDColor colorWithRed:component0 green:[color_ green] blue:[color_ blue] alpha:[color_ alpha]];
    }
    
    [self setColor:newColor notify:notify];
}

- (void) takeComponent1From:(id)sender notify:(BOOL)notify
{
    WDColor     *newColor;
    float       component1 = [sender floatValue];
    
    if (colorSpace_ == WDColorSpaceHSB) {
        newColor = [WDColor colorWithHue:[color_ hue] saturation:component1 brightness:[color_ brightness] alpha:[color_ alpha]];
    } else {
        newColor = [WDColor colorWithRed:[color_ red] green:component1 blue:[color_ blue] alpha:[color_ alpha]];
    }
    
    [self setColor:newColor notify:notify];
}

- (void) takeComponent2From:(id)sender notify:(BOOL)notify
{
    WDColor     *newColor;
    float       component2 = [sender floatValue];
    
    if (colorSpace_ == WDColorSpaceHSB) {
        newColor = [WDColor colorWithHue:[color_ hue] saturation:[color_ saturation] brightness:component2 alpha:[color_ alpha]];
    } else {
        newColor = [WDColor colorWithRed:[color_ red] green:[color_ green] blue:component2 alpha:[color_ alpha]];
    }
    
    [self setColor:newColor notify:notify];
}

- (void) takeOpacityFrom:(id)sender
{
    float alpha = [sender floatValue];
    [self setColor:[color_ colorWithAlphaComponent:alpha] notify:NO];
}

- (void) takeComponent0From:(id)sender
{
    [self takeComponent0From:sender notify:NO];
}

- (void) takeComponent1From:(id)sender
{
    [self takeComponent1From:sender notify:NO];
}

- (void) takeComponent2From:(id)sender
{
    [self takeComponent2From:sender notify:NO];
}

- (void) takeFinalComponent0From:(id)sender
{
    [self takeComponent0From:sender notify:YES];
}

- (void) takeFinalComponent1From:(id)sender
{
    [self takeComponent1From:sender notify:YES];
}

- (void) takeFinalComponent2From:(id)sender
{
    [self takeComponent2From:sender notify:YES];
}

- (void) takeFinalOpacityFrom:(id)sender
{
    float alpha = [sender floatValue];
    [self setColor:[color_ colorWithAlphaComponent:alpha] notify:YES];
}

-(void)dealloc
{
    if(color_) [color_ release];
    
    [super dealloc];
}

@end
