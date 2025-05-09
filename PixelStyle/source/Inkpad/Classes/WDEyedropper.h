//
//  WDEyedropper.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "UIKitOS.h"

@class WDColor;

@interface WDEyedropper : UIView {
    float   borderWidth_;
    float   alphaComponent_;
}

@property (nonatomic, strong) id fill;

- (void) setBorderWidth:(float)width;

@end
