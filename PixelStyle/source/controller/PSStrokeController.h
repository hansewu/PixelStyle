//
//  PSStrokeController.h
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
@class WDStrokeStyle;

typedef enum {
    kStrokeNone,
    kStrokeColor,
} WDStrokeMode;

@interface PSStrokeController : PSAbstractPanel
{
    PSColorController               *colorController_;
    IBOutlet NSSegmentedControl      *modeSegment_;
    WDStrokeMode                    mode_;
}

@property (nonatomic, retain) WDDrawingController *drawingController;


@end
