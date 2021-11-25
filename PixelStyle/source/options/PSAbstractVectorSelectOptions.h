//
//  PSAbstractVectorSelectOptions.h
//  PixelStyle
//
//  Created by wyl on 16/3/22.
//
//

#import "AbstractOptions.h"

@interface PSAbstractVectorSelectOptions : AbstractOptions
{
    bool                m_bGroupSelect;
    BOOL                m_bOptionKeyEnable;
    BOOL                m_bShiftKeyEnable;

}

- (bool)groupSelect;
- (BOOL)optionKeyEnable;
- (BOOL)shiftKeyEnable;

@end
