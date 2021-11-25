//
//  PSDodgeToolOptions.h
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

typedef enum DodgeRange {
    kDodgeRange_Highlights,
    kDodgeRange_Midtones,
    kDodgeRange_Shadows
} DodgeRange;

@interface PSDodgeToolOptions : AbstractPaintOptions<MyCustomComboBoxDelegate>
{
    IBOutlet id m_idPSComboxExposure;
    IBOutlet id m_idButtonDodgeRange;
    IBOutlet id m_idOpenBrushPanel;
    
    IBOutlet NSTextField *m_labelRange;
    IBOutlet NSTextField *m_labelExposure;
}


- (DodgeRange)getDodgeRange;
- (float)getExposureValue;


@end
