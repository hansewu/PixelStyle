//
//  PSPerspectiveTransform.cpp
//  PixelStyle
//
//  Created by lchzh on 9/1/16.
//
//

#include "PSPerspectiveTransform.h"

/*

PSPerspectiveTransform::PSPerspectiveTransform(float inA11, float inA21,
                                           float inA31, float inA12,
                                           float inA22, float inA32,
                                           float inA13, float inA23,
                                           float inA33) :
a11(inA11), a12(inA12), a13(inA13), a21(inA21), a22(inA22), a23(inA23),
a31(inA31), a32(inA32), a33(inA33) {;}

PSPerspectiveTransform PSPerspectiveTransform::quadrilateralToQuadrilateral(float x0, float y0, float x1, float y1,
                                                                        float x2, float y2, float x3, float y3, float x0p, float y0p, float x1p, float y1p, float x2p, float y2p,
                                                                        float x3p, float y3p) {
    PSPerspectiveTransform qToS = PSPerspectiveTransform::quadrilateralToSquare(x0, y0, x1, y1, x2, y2, x3, y3);
    PSPerspectiveTransform sToQ =
    PSPerspectiveTransform::squareToQuadrilateral(x0p, y0p, x1p, y1p, x2p, y2p, x3p, y3p);
    return sToQ.times(qToS);
}

PSPerspectiveTransform PSPerspectiveTransform::squareToQuadrilateral(float x0, float y0, float x1, float y1, float x2,
                                                                 float y2, float x3, float y3) {
    float dx3 = x0 - x1 + x2 - x3;
    float dy3 = y0 - y1 + y2 - y3;
    if (dx3 == 0.0f && dy3 == 0.0f) {
        PSPerspectiveTransform result(PSPerspectiveTransform(x1 - x0, x2 - x1, x0, y1 - y0, y2 - y1, y0, 0.0f,
                                                         0.0f, 1.0f));
        return result;
    } else {
        float dx1 = x1 - x2;
        float dx2 = x3 - x2;
        float dy1 = y1 - y2;
        float dy2 = y3 - y2;
        float denominator = dx1 * dy2 - dx2 * dy1;
        float a13 = (dx3 * dy2 - dx2 * dy3) / denominator;
        float a23 = (dx1 * dy3 - dx3 * dy1) / denominator;
        PSPerspectiveTransform result(PSPerspectiveTransform(x1 - x0 + a13 * x1, x3 - x0 + a23 * x3, x0, y1 - y0
                                                         + a13 * y1, y3 - y0 + a23 * y3, y0, a13, a23, 1.0f));
        return result;
    }
}

PSPerspectiveTransform PSPerspectiveTransform::quadrilateralToSquare(float x0, float y0, float x1, float y1, float x2,
                                                                 float y2, float x3, float y3) {
    // Here, the adjoint serves as the inverse:
    return squareToQuadrilateral(x0, y0, x1, y1, x2, y2, x3, y3).buildAdjoint();
}

PSPerspectiveTransform PSPerspectiveTransform::buildAdjoint() {
    // Adjoint is the transpose of the cofactor matrix:
    PSPerspectiveTransform result(PSPerspectiveTransform(a22 * a33 - a23 * a32, a23 * a31 - a21 * a33, a21 * a32
                                                     - a22 * a31, a13 * a32 - a12 * a33, a11 * a33 - a13 * a31, a12 * a31 - a11 * a32, a12 * a23 - a13 * a22,
                                                     a13 * a21 - a11 * a23, a11 * a22 - a12 * a21));
    return result;
}

PSPerspectiveTransform PSPerspectiveTransform::times(PSPerspectiveTransform other) {
    PSPerspectiveTransform result(PSPerspectiveTransform(a11 * other.a11 + a21 * other.a12 + a31 * other.a13,
                                                     a11 * other.a21 + a21 * other.a22 + a31 * other.a23, a11 * other.a31 + a21 * other.a32 + a31
                                                     * other.a33, a12 * other.a11 + a22 * other.a12 + a32 * other.a13, a12 * other.a21 + a22
                                                     * other.a22 + a32 * other.a23, a12 * other.a31 + a22 * other.a32 + a32 * other.a33, a13
                                                     * other.a11 + a23 * other.a12 + a33 * other.a13, a13 * other.a21 + a23 * other.a22 + a33
                                                     * other.a23, a13 * other.a31 + a23 * other.a32 + a33 * other.a33));
    return result;
}

void PSPerspectiveTransform::transformPoints(std::vector<float> &points) {
    int max = points.size();
    for (int i = 0; i < max; i += 2) {
        float x = points[i];
        float y = points[i + 1];
        float denominator = a13 * x + a23 * y + a33;
        points[i] = (a11 * x + a21 * y + a31) / denominator;
        points[i + 1] = (a12 * x + a22 * y + a32) / denominator;
    }
}

 */
