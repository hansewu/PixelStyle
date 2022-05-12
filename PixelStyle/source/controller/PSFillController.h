//
//  PSFillController.h
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

#import "WDPathPainter.h"
#import "PSAbstractPanel.h"

@class PSColorController;
@class WDDrawingController;
@class PSGradientController;

typedef enum {
    kFillNone,
    kFillColor,
    kFillGradient
} WDFillMode;


@interface PSFillController : PSAbstractPanel {
    PSColorController       *colorController_;
    PSGradientController    *gradientController_;
    WDFillMode              fillMode_;
    IBOutlet NSSegmentedControl      *modeSegment_;
    id<WDPathPainter>       fill_;
}

- (void)showGradientPanelFrom:(NSPoint)p onWindow: (NSWindow *)parent;

@property (nonatomic, assign) WDDrawingController *drawingController;
@end
