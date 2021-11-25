//
//  PSSpongeToolOptions.h
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

typedef enum SpongeMode {
    kSpongeMode_Saturate,
    kSpongeMode_Desaturate
} SpongeMode;

@interface PSSpongeToolOptions : AbstractPaintOptions<MyCustomComboBoxDelegate>
{
    IBOutlet id m_idPSComboxFlow;
    IBOutlet id m_idButtonSpongeMode;
    IBOutlet id m_idOpenBrushPanel;
    
    IBOutlet NSTextField *m_labelMode;
    IBOutlet NSTextField *m_labelFlow;
}


- (SpongeMode)getSpongeMode;
- (float)getFlowValue;



@end
