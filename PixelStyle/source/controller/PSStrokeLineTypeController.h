//
//  PSStrokeLineTypeController.h
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

#import "PSAbstractPanel.h"

@class WDDrawingController;
@class PSColorController;
@class PSLineAttributePicker;
@class PSSparkSlider;

//typedef enum {
//    kStrokeNone,
//    kStrokeColor,
//} WDStrokeMode;

@interface PSStrokeLineTypeController : PSAbstractPanel
{
    IBOutlet NSSegmentedControl      *modeSegment_;
//    WDStrokeMode                    mode_;
    IBOutlet NSSlider               *widthSlider_;
    IBOutlet NSTextField                *widthLabel_;
    IBOutlet PSLineAttributePicker  *capPicker_;
    IBOutlet PSLineAttributePicker  *joinPicker_;
    
    IBOutlet NSButton               *increment;
    IBOutlet NSButton               *decrement;
    
    IBOutlet PSSparkSlider          *dash0_;
    IBOutlet PSSparkSlider          *dash1_;
    IBOutlet PSSparkSlider          *gap0_;
    IBOutlet PSSparkSlider          *gap1_;
    
    IBOutlet NSView      *viewDash_;
}

@property (nonatomic, retain) WDDrawingController *drawingController;

- (void) takeCapFrom:(id)sender;

- (void) takeJoinFrom:(id)sender;


- (void) dashChanged:(id)sender;
@end
