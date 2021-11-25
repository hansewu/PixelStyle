//
//  GraphicsToBuffer.h
//  MyBrushesPlugin_mac
//
//  Created by wu zhiqiang on 1/22/15.
//  Copyright (c) 2015 effectmatrix. All rights reserved.
//

#ifndef __MyBrushesPlugin_mac__GraphicsToBuffer__
#define __MyBrushesPlugin_mac__GraphicsToBuffer__

#include  <CoreGraphics/CGGeometry.h>

typedef struct
{
    int nWidth;
    int nHeight;
    unsigned char *pBuffer;
}IMAGE_BUFFER;

typedef struct
{
    unsigned char byteRed;
    unsigned char byteGreen;
    unsigned char byteBlue;
    unsigned char byteAlpha;
}COLOR_STRUCT;


int CreateImageBufferFromPolygon(IMAGE_BUFFER *pBufOut, CGPoint *points, int nPointNum, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fGaussanRadius);
int CreateImageBufferFromRect(IMAGE_BUFFER *pBufOut, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fGaussanRadius);
int CreateImageBufferFromEllipse(IMAGE_BUFFER *pBufOut, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fGaussanRadius);
int CreateImageBufferFromRoundRect(IMAGE_BUFFER *pBufOut, CGRect rect, COLOR_STRUCT color, bool bFill, COLOR_STRUCT colorFill, float fCornerRadius, float fGaussanRadius);
void DestroyImageBuffer(IMAGE_BUFFER *pBuf);

int GetNSImageBuffer(NSImage *image, int nWidth, int nHeight, unsigned char *pBufRGBA, int bAlphaPremultiplied);

int GaussianBlurImageBuffer(IMAGE_BUFFER *pBufOut, float fGaussanRadius);
#endif /* defined(__MyBrushesPlugin_mac__GraphicsToBuffer__) */
