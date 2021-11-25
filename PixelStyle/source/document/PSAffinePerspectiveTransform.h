//
//  PSAffinePerspectiveTransform.h
//  PixelStyle
//
//  Created by lchzh on 25/10/15.
//
//

#import <Foundation/Foundation.h>

#import "Rects.h"
#import "Bitmap.h"

@interface PSAffinePerspectiveTransform : NSObject
{
    unsigned char* m_srcData;
    CIImage *m_inputciImage;
    CIFilter *m_ciFilter;
    CIContext *m_ciContext;
    IntRect m_fromRect;
    int m_nSpp;
    
}

- (void)initWithSrcData:(unsigned char*)srcData FromRect:(IntRect)srcRect spp:(int)spp opaque:(BOOL)hasOpaque colorSpace:(CGColorSpaceRef)colorSpaceRef backColor:(NSColor *)nsBackColor premultied:(BOOL)premultied;



- (unsigned char*)makePerspectiveTransformWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl OnData:(unsigned char*)srcData FromRect:(IntRect)srcRect spp:(int)spp opaque:(BOOL)hasOpaque newWidth:(int*)newWidth newHeight:(int*)newHeight colorSpace:(CGColorSpaceRef)colorSpaceRef backColor:(NSColor *)nsBackColor;


- (CGLayerRef)makePerspectiveTransformWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl newWidth:(int*)newWidth newHeight:(int*)newHeight newXOff:(int*)newXOff newYOff:(int*)newYOff;

//now use this one
- (CGImageRef)makePerspectiveTransformImageRefWithPoint_tl:(IntPoint)point_tl Point_tr:(IntPoint)point_tr Point_br:(IntPoint)point_br Point_bl:(IntPoint)point_bl newWidth:(int*)newWidth newHeight:(int*)newHeight newXOff:(int*)newXOff newYOff:(int*)newYOff;

@end
