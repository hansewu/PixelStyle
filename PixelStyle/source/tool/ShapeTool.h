//
//  ShapeTool.h
//  PixelStyle
//
//  Created by wyl on 16/2/24.
//
//

#import "PSAbstractVectorDrawTool.h"
@class WDPath;

typedef struct
{
    BOOL        bMouseDownInArea;
    BOOL        bMovingInLayer;
    CGPoint    pointMouseDown;
    NSTimeInterval      timeMouseDown;
}VECTOR_MOUSE_DOWN_INFO;

@interface ShapeTool : PSAbstractVectorDrawTool
{
    
//    int                 shapeMode_;
//    
//    // polygon support
//    int                 numPolygonPoints_;
//    
//    // rect support
//    float               rectCornerRadius_;
//    
//    // star support
//    int                 numStarPoints_;
//    float               starInnerRadiusRatio_;
    float               m_fLastStarRadius;
//
//    // spiral support
//    int                 decay_;
    
    VECTOR_MOUSE_DOWN_INFO m_MouseDownInfo;
}

- (void)layerAttributesChanged:(int)nLayerType;


- (void)shutDown;

-(void)updatePath;

@end




