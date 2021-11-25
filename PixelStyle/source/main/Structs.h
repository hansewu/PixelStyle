//
//  Structs.h
//  PixelStyle
//
//  Created by lchzh on 6/1/16.
//
//

#ifndef Structs_h
#define Structs_h

typedef struct
{
    CGContextRef context;
    CGPoint offset; //context offset relative to canvas 1:1
    CGSize scale; //context scale
 //   CGRect renderRect; //unused
    int refreshMode; //0 all 1 preview  2 full
    int *state; //0 keep wait 1 stop  2 no mode
    
    CGRect   rectSliceInCanvas; //psview visible rect relative to canvas 1:1
    CGSize              sizeScale; //psview scale
    CGPoint             pointImageDataOffset; //layer offset relative to canvas 1:1
    
}RENDER_CONTEXT_INFO;

typedef struct
{
    int activeLayer;
    IntPoint startPoint;
    IntPoint endPoint;
    int tolerance;
    int intervals;
    IntRect rect;
    int mode;
    BOOL destructively;
    int nFeather;
}MAKE_OVERLAYER_INFO;

typedef enum
{
    Transform_NO = 0,
    Transform_Scale,
    Transform_Skew,
    Transform_Perspective,
    Transform_Rotate,
    Transform_Move,
    Transform_MoveCenter
} TransformType;


#endif /* Structs_h */
