//
//  PSShapePositionTool.h
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//

#import "Globals.h"
//#import "PSAbstractVectorDrawTool.h"
#import "PSAbstractVectorSelectTool.h"
@class WDBezierNode;
@class WDTextPath;
@class WDElement;
@interface PSVectorMoveTool : PSAbstractVectorSelectTool

{
    // The point from which the drag started
    CGPoint m_cgPointInitial;   //相对画布的位置
//    CGPoint m_cgPointCurrent;   //相对画布的位置
//    BOOL m_bDragged;
//    BOOL m_bMouseDown;
    CGAffineTransform m_transform;
    BOOL                    groupSelect_;
    
//    BOOL        m_bTransforming;
    BOOL        m_bTransformingNode;
    

//    BOOL                    marqueeMode_;
//    CGRect                  m_cgRectMarquee;

    WDBezierNode            *activeNode_;
    NSUInteger              activeTextHandle_;
    NSUInteger              activeGradientHandle_;
//
    BOOL                    transformingGradient_;
    BOOL                    transformingNodes_;
    BOOL                    transformingHandles_;
    BOOL                    convertingNode_;
    BOOL                    transformingTextKnobs_;
    BOOL                    transformingTextPathStartKnob_;
//
    WDTextPath              *activeTextPath_;
//
    int                     originalReflectionMode_;
    WDBezierNode            *replacementNode_;
    NSUInteger              pointToMove_;
    NSUInteger              pointToConvert_;
    
    BOOL                    nodeWasSelected_;
//    BOOL                    objectWasSelected_;
//    WDElement               *lastTappedObject_;
//    
//    //mouse move
//    WDElement               *lastMouseMoveOnObject_;
//    int                     m_nMouseMoveOnObjecLayerIndex;

}

@property (nonatomic, assign) BOOL groupSelect;

-(void)selectAllObjects;

@end
