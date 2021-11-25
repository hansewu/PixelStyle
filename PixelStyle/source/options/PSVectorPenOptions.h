//
//  PSVectorPenOptions.h
//  PixelStyle
//
//  Created by lchzh on 23/3/16.
//
//

#import "PSVectorOptions.h"

@interface PSVectorPenOptions : PSVectorOptions
{    
    int                         m_nPenStyle;
//    BOOL                m_bOptionKeyEnable;
    BOOL                m_bControlKeyEnable;
}

- (int)getPenStyle;
- (BOOL)optionKeyEnable;
- (BOOL)controlKeyEnable;

@end
