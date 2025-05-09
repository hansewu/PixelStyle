//
//  UIImage+Additions.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "UIImage+Additions.h"
#import "WDUtilities.h"
#import "UIImage+Resize.h"

@implementation UIImage (WDAdditions)

- (void) drawToFillRect:(CGRect)bounds
{
    float   wScale = CGRectGetWidth(bounds) / self.size.width;
    float   hScale = CGRectGetHeight(bounds) / self.size.height;
    float   scale = MAX(wScale, hScale);
    float   hOffset = 0.0f, vOffset = 0.0f;
    
    CGRect  rect = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), self.size.width * scale, self.size.height * scale);
    
    if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
        hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
        hOffset /= -2;
    } 
    
    if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
        vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
        vOffset /= -2;
    }
    
    rect = CGRectOffset(rect, hOffset, vOffset);
#if TARGET_OS_IPHONE
    [self drawInRect:rect];
#else
    [self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
#endif
}
/*
- (UIImage *) rotatedImage:(int)rotation
{
    CGSize size = self.size;
    CGSize rotatedSize = (rotation % 2 == 1) ? CGSizeMake(size.height, size.width) : size;
    
  //  CGContextRef context = (CGContextRef)[[NSGraphicsContext graphicsContextWithWindow:[self window]] graphicsPort];
  //  if(!context) return;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if (rotation == 1) {
        CGContextTranslateCTM(ctx, size.height, 0.0f);
    } else if (rotation == 2) {
        CGContextTranslateCTM(ctx, size.width, size.height);
    } else if (rotation == 3) {
        CGContextTranslateCTM(ctx, 0.0f, size.width);
    }
    
    CGContextRotateCTM(ctx, (M_PI / 2.0f) * rotation);
    
    [self drawAtPoint:CGPointZero];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}
*/
#if TARGET_OS_IPHONE
- (UIImage *) downsampleWithMaxDimension:(float)constraint
{
    CGSize newSize, size = self.size;
    
    if (size.width <= constraint && size.height <= constraint && self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    if (size.width > size.height) {
        newSize.height = size.height / size.width * constraint;
        newSize.width = constraint;
    } else {
        newSize.width = size.width / size.height * constraint;
        newSize.height = constraint;
    }
    
    newSize = WDRoundSize(newSize);

    return [self resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
}
#else
- (UIImage *) downsampleWithMaxDimension:(float)constraint
{
    NSArray * imageReps = [self representations];
    
    NSInteger width = 0;
    NSInteger height = 0;
    
    for (NSImageRep * imageRep in imageReps)
    {
        if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
        if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
    }
    
    NSSize size = NSMakeSize(width, height);
    
    CGSize newSize;
    
    if (size.width <= constraint && size.height <= constraint)
    {
        return self;
    }
    
    if (size.width > size.height)
    {
        newSize.height = size.height / size.width * constraint;
        newSize.width = constraint;
    }
    else
    {
        newSize.width = size.width / size.height * constraint;
        newSize.height = constraint;
    }
    
    newSize = WDRoundSize(newSize);
    
    return [self resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
}
#endif

#if TARGET_OS_IPHONE
- (UIImage *) downsampleWithMaxArea:(float)maxArea
{
    CGSize  size = self.size;
    double  area = size.width * size.height;
    
    if (area > maxArea)
    {
        double scale = sqrt(maxArea) / sqrt(area);
        size = WDMultiplySizeScalar(size, scale);
        // whole pixel size
        size = WDRoundSize(size);
    }
    else if (self.imageOrientation == UIImageOrientationUp)
    {
        // we're small enough and have the right orientation
        return self;
    }
    
    return [self resizedImage:size interpolationQuality:kCGInterpolationHigh];
}

#else
- (UIImage *) downsampleWithMaxArea:(float)maxArea
{
    NSArray * imageReps = [self representations];
    
    NSInteger width = 0;
    NSInteger height = 0;
    
    for (NSImageRep * imageRep in imageReps)
    {
        if ([imageRep pixelsWide] > width) width = [imageRep pixelsWide];
        if ([imageRep pixelsHigh] > height) height = [imageRep pixelsHigh];
    }
    
    NSSize size = NSMakeSize(width, height);
    double  area = size.width * size.height;
    
    if (area > maxArea)
    {
        double scale = sqrt(maxArea) / sqrt(area);
        size = WDMultiplySizeScalar(size, scale);
        // whole pixel size
        size = WDRoundSize(size);
    }
    else //if (self.imageOrientation == UIImageOrientationUp)
    {
        // we're small enough and have the right orientation
        return self;
    }
    
    return [self resizedImage:size interpolationQuality:kCGInterpolationHigh];
}
#endif
/*
- (UIImage *) JPEGify:(float)compressionFactor
{
    NSData * jpegData = UIImageJPEGRepresentation(self, compressionFactor);
    return [UIImage imageWithData:jpegData];
}
*/
@end
