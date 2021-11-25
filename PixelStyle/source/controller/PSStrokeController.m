//
//  PSStrokeController.m
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
#import "PSStrokeController.h"
#import "WDPropertyManager.h"
#import "WDUtilities.h"

@implementation PSStrokeController

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
        
        if ([property isEqualToString:WDStrokeColorProperty]) {
            colorController_.color = value;
        } else if ([property isEqualToString:WDStrokeVisibleProperty])
        {
            modeSegment_.selectedSegment = [value boolValue] ? 1 : 0;
        }
    }
}


#pragma mark - Actions

- (void) modeChanged:(id)sender
{
    mode_ = (int) [modeSegment_ selectedSegment];
    
    if (mode_ == kStrokeNone) {
        [drawingController_ setValue:@NO forProperty:WDStrokeVisibleProperty];
    } else if (mode_ == kStrokeColor) {
        [drawingController_ setValue:@YES forProperty:WDStrokeVisibleProperty];
    }
}

- (void) takeColorFrom:(id)sender
{
    PSColorController   *colorController = (PSColorController *)sender;
    WDColor             *color = colorController.color;
    
    [drawingController_ setValue:color forProperty:WDStrokeColorProperty];
}

#pragma mark - View Life Cycle

- (void) windowDidLoad
{
    [super windowDidLoad];
    
//    self.edgesForExtendedLayout = UIRectEdgeNone;

    colorController_ = [[PSColorController alloc] initWithNibName:@"Color" bundle:nil];
    
    [self.window.contentView addSubview:colorController_.view];
    CGRect frame = colorController_.view.frame;
    frame.origin = CGPointMake(5, 10);
    colorController_.view.frame = frame;
    colorController_.colorWell.strokeMode = YES;
    
    colorController_.target = self;
    colorController_.action = @selector(takeColorFrom:);
    
    

    
//    self.preferredContentSize = self.view.frame.size;
}


- (void)showPanelFrom:(NSPoint)p onWindow: (NSWindow *)parent
{
    [super showPanelFrom:p onWindow:parent];
    
    // configure UI elements
    WDStrokeStyle *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
    
    colorController_.color = strokeStyle.color;
    
    modeSegment_.selectedSegment = [[drawingController_.propertyManager defaultValueForProperty:WDStrokeVisibleProperty] boolValue] ? 1 : 0;
//    [modeSegment_ addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    
    
}

//- (void) viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    
//    // configure UI elements
//    WDStrokeStyle *strokeStyle = [drawingController_.propertyManager defaultStrokeStyle];
//    
//    colorController_.color = strokeStyle.color;
//    widthSlider_.value = [self strokeWidthToSliderValue:strokeStyle.width];
//    widthLabel_.text = [NSString stringWithFormat:@"%.1f pt", strokeStyle.width];
//    capPicker_.cap = strokeStyle.cap;
//    joinPicker_.join = strokeStyle.join;
//    
//    [self updateArrowPreview];
//    [self setDashSlidersFromArray:strokeStyle.dashPattern];
//    
//    
//    modeSegment_.selectedSegmentIndex = [[drawingController_.propertyManager defaultValueForProperty:WDStrokeVisibleProperty] boolValue] ? 1 : 0;
//    [modeSegment_ addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
//}

@end
