//
//  PSVectorNodeEditorTool.h
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//

#import "Globals.h"
#import "PSAbstractVectorSelectTool.h"
@class WDBezierNode;
@class WDTextPath;
@class WDElement;
@interface PSVectorNodeEditorTool : PSAbstractVectorSelectTool

{
    // The point from which the drag started
    CGPoint m_cgPointInitial;   //相对画布的位置
    CGAffineTransform m_transform;
    BOOL                    groupSelect_;
    BOOL        m_bTransformingNode;
 
    WDBezierNode            *activeNode_;
    NSUInteger              activeTextHandle_;
    NSUInteger              activeGradientHandle_;

    BOOL                    transformingGradient_;
    BOOL                    transformingNodes_;
    BOOL                    transformingHandles_;
    BOOL                    convertingNode_;
    BOOL                    transformingTextKnobs_;
    BOOL                    transformingTextPathStartKnob_;

    WDTextPath              *activeTextPath_;

    int                     originalReflectionMode_;
    WDBezierNode            *replacementNode_;
    NSUInteger              pointToMove_;
    NSUInteger              pointToConvert_;
    
    BOOL                    nodeWasSelected_;
}

@end
