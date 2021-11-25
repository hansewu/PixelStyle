#import "Globals.h"
#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

@interface SmudgeOptions : AbstractPaintOptions<MyCustomComboBoxDelegate>
{
    IBOutlet id m_idOpenBrushPanel;
    IBOutlet MyCustomComboBox *m_myCustomComboRate;
    
    IBOutlet NSTextField *m_labelStrength;
}


- (void)awakeFromNib;

- (int)rate;

- (void)shutdown;

@end
