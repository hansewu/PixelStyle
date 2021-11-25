//
//  PSPerspectiveTransform.h
//  PixelStyle
//
//  Created by lchzh on 9/1/16.
//
//

#import <Cocoa/Cocoa.h>

#ifndef PSPerspectiveTransform_h
#define PSPerspectiveTransform_h

typedef struct
{ float a11,a12,a13,a21,a22,a23,a31,a32,a33;
} PSPerspectiveTransform;

#endif /* PSPerspectiveTransform_h */

PSPerspectiveTransform PSPerspectiveTransformMake(float inA11, float inA21,
                                                  float inA31, float inA12,
                                                  float inA22, float inA32,
                                                  float inA13, float inA23,
                                                  float inA33);
PSPerspectiveTransform quadrilateralToQuadrilateral(float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3, float x0p, float y0p, float x1p, float y1p, float x2p, float y2p, float x3p, float y3p);
PSPerspectiveTransform squareToQuadrilateral(float x0, float y0, float x1, float y1, float x2,
                                             float y2, float x3, float y3);
PSPerspectiveTransform quadrilateralToSquare(float x0, float y0, float x1, float y1, float x2,
                                             float y2, float x3, float y3);
PSPerspectiveTransform buildAdjoint(PSPerspectiveTransform from);
PSPerspectiveTransform productTransform(PSPerspectiveTransform left, PSPerspectiveTransform right);
CGPoint perspectiveTransfromPoint(CGPoint src, PSPerspectiveTransform transform);

 //transformPoints(nsp points) ;