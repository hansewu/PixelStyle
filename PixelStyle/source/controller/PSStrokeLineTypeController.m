//
//  PSStrokeLineTypeController.m
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDColor.h"
#import "PSColorController.h"
#import "PSColorWell.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "PSStrokeLineTypeController.h"
#import "WDPropertyManager.h"
#import "WDUtilities.h"
#import "PSSparkSlider.h"
#import "PSLineAttributePicker.h"

const float kMaxStrokeWidth = 300.0f;

@implementation PSStrokeLineTypeController

@synthesize drawingController = drawingController_;


-(id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    if (!self) {
        return nil;
    }
    
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:self.window.contentView.frame];
    [self.window.contentView addSubview:imageView];
    [imageView release];
    
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    if(drawingController_) [drawingController_ release];
    
    [super dealloc];
}

- (void) setDrawingController:(WDDrawingController *)drawingController
{
    if(drawingController_) [drawingController_ release];
    drawingController_ = [drawingController retain];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(invalidProperties:)
                                                 name:WDInvalidPropertiesNotification
                                               object:drawingController.propertyManager];
}

- (void) invalidProperties:(NSNotification *)aNotification
{
    NSSet *properties = [aNotification userInfo][WDInvalidPropertiesKey];
    
    for (NSString *property in properties) {
        id value = [drawingController_.propertyManager defaultValueForProperty:property];
        
        if ([property isEqualToString:WDStrokeWidthProperty]) {
            widthSlider_.floatValue = [self strokeWidthToSliderValue:[value floatValue]];
            widthLabel_.stringValue = [NSString stringWithFormat:@"%.1f pt", [value floatValue]];
            
            decrement.enabled = widthSlider_.floatValue != widthSlider_.minValue;
            increment.enabled = widthSlider_.floatValue != widthSlider_.maxValue;
        } else if ([property isEqualToString:WDStrokeCapProperty]) {
            capPicker_.cap = (CGLineCap) [value integerValue];
        } else if ([property isEqualToString:WDStrokeJoinProperty]) {
            joinPicker_.join = (CGLineJoin) [value integerValue];
        } else if ([property isEqualToString:WDStrokeDashPatternProperty]) {
            [self setDashSlidersFromArray:value];
        }
    }
}


#pragma mark - Width Slider

#define kX 40.0f
#define kXLog log(kX + 1)

- (float) widthSliderDelta
{
    return (widthSlider_.maxValue - widthSlider_.minValue);
}

- (float) strokeWidthToSliderValue:(float)strokeWidth
{
    float delta = [self widthSliderDelta];
    float v = (strokeWidth - widthSlider_.minValue) * (kX / delta) + 1.0f;
    v = log(v);
    v /= kXLog;
    
    return (v * kMaxStrokeWidth);
}

- (float) sliderValueToStrokeWidth
{
    float percentage = WDClamp(0.0f, 1.0f, (widthSlider_.floatValue) / kMaxStrokeWidth);
    float delta = [self widthSliderDelta];
    float v = delta * (exp(kXLog * percentage) - 1.0f) / kX + widthSlider_.minValue;
    
    return v;
}

- (IBAction) takeStrokeWidthFrom:(id)sender
{
    widthLabel_.stringValue = [NSString stringWithFormat:@"%.1f pt", [self sliderValueToStrokeWidth]];
    
    NSSlider *slider = (NSSlider *)sender;
    decrement.enabled = slider.doubleValue != slider.minValue;
    increment.enabled = slider.doubleValue != slider.maxValue;
}

- (IBAction) takeFinalStrokeWidthFrom:(id)sender
{
    [self takeStrokeWidthFrom:sender];
    
    [drawingController_ setValue:@([self sliderValueToStrokeWidth])
                     forProperty:WDStrokeWidthProperty];
}

- (float) roundingFactor:(float)strokeWidth
{
    if (strokeWidth <= 5.0) {
        return 10.0f;
    } else if (strokeWidth <= 10) {
        return 5.0f;
    } else if (strokeWidth <= 20) {
        return 2.0f;
    }
    
    return 1.0f;
}

- (void) changeSliderBy:(float)change
{
    float strokeWidth = [self sliderValueToStrokeWidth];
    float roundingFactor = [self roundingFactor:strokeWidth];
    
    strokeWidth *= roundingFactor;
    strokeWidth += change;
    strokeWidth = roundf(strokeWidth);
    strokeWidth /= roundingFactor;
    
    widthSlider_.floatValue = [self strokeWidthToSliderValue:strokeWidth];
    
    [self takeFinalStrokeWidthFrom:widthSlider_];
}

- (IBAction) increment:(id)sender
{
    [self changeSliderBy:1];
}

- (IBAction) decrement:(id)sender
{
    [self changeSliderBy:(-1)];
}

#pragma mark - Actions


- (void) takeCapFrom:(id)sender
{
    PSLineAttributePicker *picker = (PSLineAttributePicker *)sender;
    [drawingController_ setValue:@(picker.cap) forProperty:WDStrokeCapProperty];
}

- (void) takeJoinFrom:(id)sender
{
    PSLineAttributePicker *picker = (PSLineAttributePicker *)sender;
    [drawingController_ setValue:@(picker.join) forProperty:WDStrokeJoinProperty];
}



- (void) dashChanged:(id)sender
{
    NSMutableArray *pattern = [NSMutableArray array];
    
    [pattern addObject:dash0_.numberValue];
    [pattern addObject:gap0_.numberValue];
    [pattern addObject:dash1_.numberValue];
    [pattern addObject:gap1_.numberValue];
    
    [drawingController_ setValue:pattern forProperty:WDStrokeDashPatternProperty];
}

- (void) setDashSlidersFromArray:(NSArray *)pattern
{
    PSSparkSlider   *sliders[4] = {dash0_, gap0_, dash1_, gap1_};
    int             i;
    
    float sum = 0.0f;
    for (NSNumber *number in pattern) {
        sum += [number floatValue];
    }
    
    modeSegment_.selectedSegment = (pattern && pattern.count && sum > 0) ? 1 : 0;
    
    if (pattern && pattern.count)
    {
        for (i = 0; i < pattern.count; i++)
        {
            sliders[i].value = [pattern[i] floatValue];
        }
        
        for ( ; i < 4; i++)
        {
            sliders[i].value = 0;
        }
    }
    else
    {
        for (i = 0; i < 4; i++)
        {
            sliders[i].value = 0;
        }
    }
    
    
    if(modeSegment_.selectedSegment == 1)
        [viewDash_ setHidden:NO];
    else
        [viewDash_ setHidden:YES];
    
    [self updateDashSolodImage];
}

#pragma mark - Actions

- (IBAction) modeChanged:(id)sender
{
    int nMode = (int) [modeSegment_ selectedSegment];
    
    NSMutableArray *pattern = [NSMutableArray array];
    if (nMode == 1)
    {
        WDStrokeStyle *strokeStyle = [drawingController_.propertyManager activeStrokeStyle];
        
        if (!strokeStyle) {
            strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
        }
        
        int dash = MIN(100, round(strokeStyle.width * 2));
        [pattern addObject:@((float)dash)];
    }
    
    if(modeSegment_.selectedSegment == 1)
        [viewDash_ setHidden:NO];
    else
        [viewDash_ setHidden:YES];
    
    [drawingController_ setValue:pattern forProperty:WDStrokeDashPatternProperty];
    
    [self updateDashSolodImage];
    
    
}

- (void)updateDashSolodImage
{
    if (modeSegment_.selectedSegment == 0) {
        [modeSegment_ setImage:[NSImage imageNamed:@"solid_white.png"] forSegment:0];
        [modeSegment_ setImage:[NSImage imageNamed:@"dash_black.png"] forSegment:1];
    }else{
        [modeSegment_ setImage:[NSImage imageNamed:@"solid_black.png"] forSegment:0];
        [modeSegment_ setImage:[NSImage imageNamed:@"dash_white.png"] forSegment:1];
    }
}


#pragma mark - View Life Cycle

- (void) windowDidLoad
{
    [super windowDidLoad];
    
//    self.edgesForExtendedLayout = UIRectEdgeNone;

    
    widthSlider_.minValue = 0.1f;
    widthSlider_.maxValue = kMaxStrokeWidth;

    capPicker_.mode = kStrokeCapAttribute;
    [capPicker_ setTarget:self];
    [capPicker_ setAction:@selector(takeCapFrom:)];
    [capPicker_ setController:self];
    
    joinPicker_.mode = kStrokeJoinAttribute;
    [joinPicker_ setTarget:self];
    [joinPicker_ setAction:@selector(takeJoinFrom:)];
    [joinPicker_ setController:self];
    // need to add/remove this target when programmatically changing the segment controller's value
    
    dash0_.title.stringValue = NSLocalizedString(@"dash", nil);
    dash1_.title.stringValue = NSLocalizedString(@"dash", nil);
    gap0_.title.stringValue = NSLocalizedString(@"gap", nil);
    gap1_.title.stringValue = NSLocalizedString(@"gap", nil);
    
    [dash0_ setTarget:self];
    [dash0_ setAction:@selector(dashChanged:)];
    [dash1_ setTarget:self];
    [dash1_ setAction:@selector(dashChanged:)];
    [gap0_ setTarget:self];
    [gap0_ setAction:@selector(dashChanged:)];
    [gap1_ setTarget:self];
    [gap1_ setAction:@selector(dashChanged:)];
    
    [dash0_ setController:self];
    [dash1_ setController:self];
    [gap0_ setController:self];
    [gap1_ setController:self];
//    [dash0_ addTarget:self action:@selector(dashChanged:) forControlEvents:UIControlEventValueChanged];
//    [dash1_ addTarget:self action:@selector(dashChanged:) forControlEvents:UIControlEventValueChanged];
//    [gap0_ addTarget:self action:@selector(dashChanged:) forControlEvents:UIControlEventValueChanged];
//    [gap1_ addTarget:self action:@selector(dashChanged:) forControlEvents:UIControlEventValueChanged];
    
//    self.preferredContentSize = self.view.frame.size;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(takeCapFrom:) name:@"takeCapFrom" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(takeJoinFrom:) name:@"takeJoinFrom" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashChanged:) name:@"dashChanged" object:nil];
}


- (void)showPanelFrom:(NSPoint)p onWindow: (NSWindow *)parent
{
    [super showPanelFrom:p onWindow:parent];
    
    // configure UI elements
    WDStrokeStyle *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
    
    widthSlider_.floatValue = [self strokeWidthToSliderValue:strokeStyle.width];
    widthLabel_.stringValue = [NSString stringWithFormat:@"%.1f pt", strokeStyle.width];
    capPicker_.cap = strokeStyle.cap;
    joinPicker_.join = strokeStyle.join;
    
    [self setDashSlidersFromArray:strokeStyle.dashPattern];
    

    float sum = 0.0f;
    for (NSNumber *number in strokeStyle.dashPattern) {
        sum += [number floatValue];
    }
    
    modeSegment_.selectedSegment = (strokeStyle.dashPattern && strokeStyle.dashPattern.count && sum > 0) ? 1 : 0;
    
    [self updateDashSolodImage];
}

@end
