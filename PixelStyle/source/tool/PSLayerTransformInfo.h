//
//  PSLayerTransformInfo.h
//  PixelStyle
//
//  Created by lchzh on 29/10/15.
//
//

#import <Foundation/Foundation.h>
#import "Rects.h"

@class PSAffinePerspectiveTransform;


@interface PSLayerTransformInfo : NSObject
{
    id transformedLayer;
    PSAffinePerspectiveTransform *transformController;
    
    unsigned char * selectedData;
    IntRect selectedRect;
    unsigned char * stayedData;   
    CGImageRef stayedImageRef;
    
    CGLayerRef newCGLayerRef;
    int newXOffset;
    int newYOffset;
    int newWidth;
    int newHeight;
    
    
    NSPoint topLeftPoint;
    NSPoint topRightPoint;
    NSPoint bottumRightPoint;
    NSPoint bottumLeftPoint;
    NSPoint centerPoint;
        
}

@property(retain) id transformedLayer;
@property(retain) PSAffinePerspectiveTransform *transformController;

@property IntRect selectedRect;
@property unsigned char * selectedData;
@property unsigned char * stayedData;
@property CGImageRef stayedImageRef;

@property CGLayerRef newCGLayerRef;
@property int newXOffset;
@property int newYOffset;
@property int newWidth;
@property int newHeight;

@property NSPoint topLeftPoint;
@property NSPoint topRightPoint;
@property NSPoint bottumRightPoint;
@property NSPoint bottumLeftPoint;
@property NSPoint centerPoint;

- (void)lockNewCGLayer:(BOOL)isLock;

@end
