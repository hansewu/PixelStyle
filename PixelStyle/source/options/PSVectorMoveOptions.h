//
//  PSVectorMoveOptions.h
//  PixelStyle
//
//  Created by wyl on 16/3/22.
//
//

#import "PSVectorOptions.h"
#import "PSVectorTransformManager.h"


enum {
    PSMoveActionDefault = 0,
    PSMoveActionAddDelete,
    PSMoveActionTransfrom,
};

@interface PSVectorMoveOptions : PSVectorOptions
{
//    bool                m_bGroupSelect;
//    BOOL                m_bOptionKeyEnable;
    
    int                 m_nActionStyle;
    
    TransformType       m_nTransformType;
}

- (bool)groupSelect;
- (BOOL)optionKeyEnable;

- (int)getActionStyle;

- (TransformType)getTransformStyle;

@end
