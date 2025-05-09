//
//  UIBarButtonItem+Additions.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Steve Sprang
//

#import "UIKitOS.h"

#if TARGET_OS_IPHONE

@interface UIBarButtonItem (Additions)

+ (UIBarButtonItem *) flexibleItem;
+ (UIBarButtonItem *) fixedItemWithWidth:(float)width;

@end

#endif