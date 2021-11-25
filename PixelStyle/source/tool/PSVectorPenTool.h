//
//  PSVectorPenTool.h
//  PixelStyle
//
//  Created by lchzh on 23/3/16.
//
//

#import "PSAbstractVectorDrawTool.h"
#import "WDBezierNode.h"
#import "WDPath.h"

@interface PSVectorPenTool : PSAbstractVectorDrawTool
{
    int                         m_nPenStyle;

    WDPath                      *m_activePath;
    WDBezierNode                *replacementNode_;
    BOOL                        updatingOldNode_;
    WDBezierNodeReflectionMode  oldNodeMode_;
    BOOL                        closingPath_;
    BOOL                        shouldResetFillTransform_;
   
    BOOL            pathStarted_;
}

@property (nonatomic, strong) WDBezierNode *replacementNode;


@end
