#import "Globals.h"
#import "AbstractTool.h"
#import "PSTextInputView.h"
/*!
	@class		VectorTool
	@abstract	The text tool's role is much the same as in any paint program.
	@discussion	N/A
 
 */

//enum {
//    PSShapeRectangle = 0,
//    PSShapeOval,
//    PSShapeStar,
//    PSShapePolygon,
//    PSShapeLine,
//    PSShapeSpiral
//};

typedef struct
{
    BOOL        bMouseDownInArea;
    BOOL        bMovingInLayer;
    CGPoint    pointMouseDown;
    NSTimeInterval      timeMouseDown;
}VECTOR_MOUSE_DOWN_INFO;

@class WDPath;
@interface VectorTool : AbstractTool
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
//    float               lastStarRadius_;
//    
//    // spiral support
//    int                 decay_;
 
    VECTOR_MOUSE_DOWN_INFO m_MouseDownInfo;
    WDPath              *m_pathTemp;
}


- (void)layerAttributesChanged:(int)nLayerType;


- (void)shutDown;


@end
