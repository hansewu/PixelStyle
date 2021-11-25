//
//  PSGradientEditor.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class WDColor;
@class WDGradient;
@class PSGradientController;
@class PSGradientStopIndicator;

@interface PSGradientEditor : NSControl {
    NSMutableArray              *indicators_;
    PSGradientStopIndicator     *activeIndicator_;
    PSGradientStopIndicator     *indicatorToRemove_;
    PSGradientStopIndicator     *indicatorToDrag_;
    BOOL                        moved_;
}

@property (nonatomic, strong) WDGradient *gradient;
@property (nonatomic, strong) WDGradient *renderingGradient;
@property (assign, nonatomic, readonly) NSArray *stops;
@property (nonatomic, retain) PSGradientController *controller;
@property (nonatomic, assign) BOOL inactive;

- (void) setColor:(WDColor *)color;
- (void) setActiveIndicator:(PSGradientStopIndicator *)indicator;
- (PSGradientStopIndicator *) stopIndicatorWithRatio:(float)ratio;

@end
