//
//  PSVectorEraserOptions.h
//  PixelStyle
//
//  Created by lchzh on 31/3/16.
//
//

#import "PSAbstractVectorSelectOptions.h"
#import "MyCustomComboBox.h"

@interface PSVectorEraserOptions : PSAbstractVectorSelectOptions<MyCustomComboBoxDelegate>
{
    IBOutlet MyCustomComboBox   *m_myCustomComboSize;
    IBOutlet NSTextField        *m_labelSize;
}

- (int)getEraserSize;

@end
