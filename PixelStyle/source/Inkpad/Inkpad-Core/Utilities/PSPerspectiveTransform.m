//
//  PSPerspectiveTransform.c
//  PixelStyle
//
//  Created by lchzh on 9/1/16.
//
//

#include <stdio.h>
#include "PSPerspectiveTransform.h"

PSPerspectiveTransform PSPerspectiveTransformMake(float inA11, float inA21,
                                                  float inA31, float inA12,
                                                  float inA22, float inA32,
                                                  float inA13, float inA23,
                                                  float inA33)
{
    PSPerspectiveTransform result;
    result.a11 = inA11;
    result.a12 = inA12;
    result.a13 = inA13;
    result.a21 = inA21;
    result.a22 = inA22;
    result.a23 = inA23;
    result.a31 = inA31;
    result.a32 = inA32;
    result.a33 = inA33;
    return result;
}

PSPerspectiveTransform quadrilateralToQuadrilateral(float x0, float y0, float x1, float y1, float x2, float y2, float x3, float y3, float x0p, float y0p, float x1p, float y1p, float x2p, float y2p, float x3p, float y3p)
{
    PSPerspectiveTransform qToS = quadrilateralToSquare(x0, y0, x1, y1, x2, y2, x3, y3);
    PSPerspectiveTransform sToQ =
    squareToQuadrilateral(x0p, y0p, x1p, y1p, x2p, y2p, x3p, y3p);
    return productTransform(sToQ, qToS);
}
PSPerspectiveTransform squareToQuadrilateral(float x0, float y0, float x1, float y1, float x2,
                                             float y2, float x3, float y3)
{
    float dx3 = x0 - x1 + x2 - x3;
    float dy3 = y0 - y1 + y2 - y3;
    if (dx3 == 0.0f && dy3 == 0.0f) {
        PSPerspectiveTransform result = PSPerspectiveTransformMake(x1 - x0, x2 - x1, x0, y1 - y0, y2 - y1, y0, 0.0f,
                                                             0.0f, 1.0f);
        return result;
    } else {
        float dx1 = x1 - x2;
        float dx2 = x3 - x2;
        float dy1 = y1 - y2;
        float dy2 = y3 - y2;
        float denominator = dx1 * dy2 - dx2 * dy1;
        float a13 = (dx3 * dy2 - dx2 * dy3) / denominator;
        float a23 = (dx1 * dy3 - dx3 * dy1) / denominator;
        PSPerspectiveTransform result = PSPerspectiveTransformMake(x1 - x0 + a13 * x1, x3 - x0 + a23 * x3, x0, y1 - y0
                                                                 + a13 * y1, y3 - y0 + a23 * y3, y0, a13, a23, 1.0f);
        ;
        return result;
    }

}


PSPerspectiveTransform quadrilateralToSquare(float x0, float y0, float x1, float y1, float x2,
                                             float y2, float x3, float y3)
{
    return buildAdjoint(squareToQuadrilateral(x0, y0, x1, y1, x2, y2, x3, y3));
}

PSPerspectiveTransform buildAdjoint(PSPerspectiveTransform from)
{
    PSPerspectiveTransform result = PSPerspectiveTransformMake(from.a22 * from.a33 - from.a23 * from.a32, from.a23 * from.a31 - from.a21 * from.a33, from.a21 * from.a32
                                                     - from.a22 * from.a31, from.a13 * from.a32 - from.a12 * from.a33, from.a11 * from.a33 - from.a13 * from.a31, from.a12 * from.a31 - from.a11 * from.a32, from.a12 * from.a23 - from.a13 * from.a22,
                                                     from.a13 * from.a21 - from.a11 * from.a23, from.a11 * from.a22 - from.a12 * from.a21);
    return result;
}

PSPerspectiveTransform productTransform(PSPerspectiveTransform this, PSPerspectiveTransform other)
{
    PSPerspectiveTransform result = PSPerspectiveTransformMake(this.a11 * other.a11 + this.a21 * other.a12 + this.a31 * other.a13,
                                                     this.a11 * other.a21 + this.a21 * other.a22 + this.a31 * other.a23, this.a11 * other.a31 + this.a21 * other.a32 + this.a31
                                                     * other.a33, this.a12 * other.a11 + this.a22 * other.a12 + this.a32 * other.a13, this.a12 * other.a21 + this.a22
                                                     * other.a22 + this.a32 * other.a23, this.a12 * other.a31 + this.a22 * other.a32 + this.a32 * other.a33, this.a13
                                                     * other.a11 + this.a23 * other.a12 + this.a33 * other.a13, this.a13 * other.a21 + this.a23 * other.a22 + this.a33
                                                     * other.a23, this.a13 * other.a31 + this.a23 * other.a32 + this.a33 * other.a33);
    return result;
}

CGPoint perspectiveTransfromPoint(CGPoint srcPoint, PSPerspectiveTransform transform)
{
    CGPoint desPoint = srcPoint;
    float x = srcPoint.x;
    float y = srcPoint.y;
    float denominator = transform.a13 * x + transform.a23 * y + transform.a33;
    desPoint.x = (transform.a11 * x + transform.a21 * y + transform.a31) / denominator;
    desPoint.y = (transform.a12 * x + transform.a22 * y + transform.a32) / denominator;
    
    return desPoint;
}


