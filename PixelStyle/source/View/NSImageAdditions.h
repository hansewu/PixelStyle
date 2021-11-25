//
//  NSImageAdditions.h
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <AppKit/AppKit.h>


@interface NSImage (Additions)

//保持四周一定区域像素不拉伸，将图像扩散到一定的大小
- (NSImage *)stretchableImageWithSize:(NSSize)size edgeInsets:(NSEdgeInsets)insets;
//保持leftWidth,rightWidth这左右一定区域不拉伸，将图片宽度拉伸到(leftWidth+middleWidth+rightWidth)
- (NSImage *)stretchableImageWithLeftCapWidth:(float)leftWidth middleWidth:(float)middleWidth rightCapWidth:(float)rightWidth;

@end
