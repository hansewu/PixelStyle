//
//  PSBurnToolOptions.h
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

typedef enum BurnRange {
    kBurnRange_Highlights,
    kBurnRange_Midtones,
    kBurnRange_Shadows
} BurnRange;

@interface PSBurnToolOptions : AbstractPaintOptions<MyCustomComboBoxDelegate>
{
    IBOutlet id m_idPSComboxExposure;
    IBOutlet id m_idButtonBurnRange;
    IBOutlet id m_idOpenBrushPanel;
    
    IBOutlet NSTextField *m_labelRange;
    IBOutlet NSTextField *m_labelExposure;
}


- (BurnRange)getBurnRange;
- (float)getExposureValue;

@end
