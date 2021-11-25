//
//  PSGradientController.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "PSColorController.h"
#import "PSColorWell.h"
#import "WDColor.h"
#import "WDGradient.h"
#import "PSGradientController.h"
#import "PSGradientEditor.h"

#define kInactiveAlpha  0.5

@implementation PSGradientController

@synthesize gradient = gradient_;
@synthesize target = target_;
@synthesize action = action_;
@synthesize colorController = colorController_;
@synthesize inactive = inactive_;

- (IBAction) takeGradientTypeFrom:(id)sender
{
    if (gradient_.type == kWDRadialGradient) {
        WDGradient *lgradient = [gradient_ gradientWithType:kWDLinearGradient];
        lgradient.angle = [m_sliderAngle floatValue];
        [self setGradient:lgradient];
    } else {
        [self setGradient:[gradient_ gradientWithType:kWDRadialGradient]];
    }
    
    [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
}

- (IBAction) takeGradientAngleFrom:(id)sender
{
    if (gradient_.type == kWDLinearGradient) {
        self.gradient.angle = [m_sliderAngle floatValue];
        [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
    }
}

- (void) setGradient:(WDGradient *)gradient
{
    if(gradient_) [gradient_ release];
    gradient_ = [gradient retain];
    
    [colorWell_ setPainter:gradient_];
    [gradientEditor_ setGradient:gradient_];
    
    
    if (gradient_.type == kWDLinearGradient) {
        [typeButton_ setImage:[UIImage imageNamed:@"linear.png"]];
        [m_sliderAngle setFloatValue:gradient.angle];
        [m_textFiledAngle setStringValue:[NSString stringWithFormat:@"%.1f",gradient.angle]];
        //NSLog(@"setGradient %f",gradient.angle);
    } else {
        [typeButton_ setImage:[UIImage imageNamed:@"radial.png"]];
    }
}

- (IBAction) takeGradientStopsFrom:(id)sender
{
    PSGradientEditor *editor = (PSGradientEditor *) sender;
    
    self.gradient = [self.gradient gradientWithStops:[editor stops]];
//    self.gradient.angle = [m_sliderAngle floatValue];
//    self.gradient.scale = 1.0;
    
    [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
}
    
- (void) setColor:(WDColor *)color
{
    [gradientEditor_ setColor:color];
}

- (void) colorSelected:(WDColor *)color
{
    [colorController_ setColor:color];
}

- (void) setInactive:(BOOL)inactive
{
    if (inactive_ == inactive) {
        return;
    }
    
    inactive_ = inactive;
    gradientEditor_.inactive = inactive;
}

- (void) reverseGradient:(id)sender
{
    self.gradient = [self.gradient gradientByReversing];
    [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
}

- (void) distributeGradientStops:(id)sender
{
    self.gradient = [self.gradient gradientByDistributingEvenly];
    [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.gradient = [WDGradient defaultGradient];
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    self.view.layer.backgroundColor = nil;
    self.view.layer.opaque = NO;
    
    gradientEditor_.controller = self;
    [m_textFiledAngle setStringValue:@"0.0"];
    [m_textFiledAngle setDelegate:self];
}

-(void)dealloc
{
    if(gradient_) [gradient_ release];
    [super dealloc];
}

#pragma mark - Mouse Events
-(void)mouseDragged:(NSEvent *)theEvent
{
    [gradientEditor_ mouseUp:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    [gradientEditor_ mouseUp:theEvent];
}


#pragma mark - angle textfield delegate
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    
    if(textField == m_textFiledAngle)
    {
        float angle = [m_textFiledAngle floatValue];
        angle = MAX(0, MIN(360, angle));
        [m_sliderAngle setFloatValue:angle];
        [m_textFiledAngle setStringValue:[NSString stringWithFormat:@"%.1f",angle]];
        if (gradient_.type == kWDLinearGradient) {
            self.gradient.angle = [m_sliderAngle floatValue];
            [[NSApplication sharedApplication] sendAction:action_ to:target_ from:self];
        }
        
    }
    
    return YES;
}


@end
