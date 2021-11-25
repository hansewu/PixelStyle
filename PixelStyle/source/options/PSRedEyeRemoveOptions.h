//
//  PSRedEyeRemoveOptions.h
//  PixelStyle
//
//  Created by wyl on 16/4/20.
//
//

#import "AbstractOptions.h"
#import "MyCustomComboBox.h"

@interface PSRedEyeRemoveOptions : AbstractOptions <MyCustomComboBoxDelegate>
{
    IBOutlet MyCustomComboBox *m_myCustomComboRadius;
    
    IBOutlet NSTextField *m_labelRadius;
}

-(float)getRadiusSize;

@end
