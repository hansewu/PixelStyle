//
//  ThressPointsAffine.m
//  PixelStyle
//
//  Created by wzq on 15/12/1.
//
//

#import "ThressPointsAffine.h"

CGAffineTransform GetTransformPoints3(CGPoint *pointFrom, CGPoint *pointTo)
{
    float a = ((pointTo[0].x - pointTo[1].x) *(pointFrom[0].y - pointFrom[2].y) - (pointTo[0].x - pointTo[2].x) *(pointFrom[0].y - pointFrom[1].y));
    a /= ((pointFrom[0].x - pointFrom[1].x) * (pointFrom[0].y - pointFrom[2].y) - (pointFrom[0].x - pointFrom[2].x) * (pointFrom[0].y - pointFrom[1].y));
    
    float c = ((pointTo[0].x - pointTo[2].x) *(pointFrom[0].x - pointFrom[1].x) - (pointTo[0].x - pointTo[1].x)* (pointFrom[0].x- pointFrom[2].x));
    c /= ((pointFrom[0].y - pointFrom[2].y) *(pointFrom[0].x - pointFrom[1].x) - (pointFrom[0].y - pointFrom[1].y)*(pointFrom[0].x- pointFrom[2].x));
    
    
    float b = ((pointTo[0].y - pointTo[1].y) *(pointFrom[0].y - pointFrom[2].y) - (pointTo[0].y - pointTo[2].y) *(pointFrom[0].y - pointFrom[1].y));
    b /= ((pointFrom[0].x - pointFrom[1].x) * (pointFrom[0].y - pointFrom[2].y) - (pointFrom[0].x - pointFrom[2].x) * (pointFrom[0].y - pointFrom[1].y));
    
    float d = ((pointTo[0].y - pointTo[2].y) *(pointFrom[0].x - pointFrom[1].x) - (pointTo[0].y - pointTo[1].y)* (pointFrom[0].x- pointFrom[2].x));
    d /= ((pointFrom[0].y - pointFrom[2].y) *(pointFrom[0].x - pointFrom[1].x) - (pointFrom[0].y - pointFrom[1].y)*(pointFrom[0].x- pointFrom[2].x));
    
    float e = pointTo[0].x - a*pointFrom[0].x - c*pointFrom[0].y;
    float f = pointTo[0].y - b*pointFrom[0].x - d*pointFrom[0].y;
    
  //  float  x4 = a*pointFrom[3].x + c*pointFrom[3].y +e;
  //  float  y4 = b*pointFrom[3].x + d*pointFrom[3].y +f;
    
  //  assert(fabs(x4- pointTo[3].x) < 0.001);
 //   assert(fabs(y4- pointTo[3].y) < 0.001);
    
    //    float fRotatation = atanf(c/a)*180/3.1415926; //http://math.stackexchange.com/questions/78137/decomposition-of-a-nonsquare-affine-matrix
    //    printf("rotation angle = %.3f\n", fRotatation);
    
    return CGAffineTransformMake(a, b, c, d, e, f);
}
