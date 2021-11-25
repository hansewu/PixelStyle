//
//  WDUtilities.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "PSUtilities.h"


void PSDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest)
{
    float   minX = CGRectGetMinX(dest);
    float   maxX = CGRectGetMaxX(dest);
    float   minY = CGRectGetMinY(dest);
    float   maxY = CGRectGetMaxY(dest);
    
    // preserve the existing color
    CGContextSaveGState(ctx);
    [[NSColor whiteColor] set];
    CGContextFillRect(ctx, dest);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, minX, minY);
    CGPathAddLineToPoint(path, NULL, maxX, maxY);
    CGPathAddLineToPoint(path, NULL, minX, maxY);
    
    CGPathCloseSubpath(path);
    
    [[NSColor blackColor] set];
    CGContextAddPath(ctx, path);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
    
    CGPathRelease(path);
}

