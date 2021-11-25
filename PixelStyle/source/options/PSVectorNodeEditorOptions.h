//
//  PSVectorNodeEditorOptions.h
//  PixelStyle
//
//  Created by wyl on 16/3/22.
//
//

#import "PSVectorOptions.h"


@interface PSVectorNodeEditorOptions : PSAbstractVectorSelectOptions
{
    int                 m_nActionStyle;
}

- (int)getActionStyle;

@end
