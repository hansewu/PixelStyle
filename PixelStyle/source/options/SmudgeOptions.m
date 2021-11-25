#import "SmudgeOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"

@implementation SmudgeOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Brush Preset” Selector", nil)];
    
    //[self performSelector:@selector(initViews) withObject:nil afterDelay:0.05];
    [self initViews];
}

-(void)initViews
{
    int value;
    
    if ([gUserDefaults objectForKey:@"smudge rate"] == NULL) {
        value = 50;
    }
    else {
        value = [gUserDefaults integerForKey:@"smudge rate"];
        if (value < 0 || value > 100)
            value = 50;
    }
    
    [m_myCustomComboRate setDelegate:self];
    [m_myCustomComboRate setSliderMaxValue:100];
    [m_myCustomComboRate setSliderMinValue:0];
    [m_myCustomComboRate setStringValue:[NSString stringWithFormat:@"%d%%",value]];
    [m_myCustomComboRate setToolTip:NSLocalizedString(@"Set strength for the stroke", nil)];
    
    [m_labelStrength setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Strength", nil)]];
}

/*
- (BOOL)mergedSample
{
	return [m_idMergedCheckbox state];
}
*/

- (int)rate
{
	return [[m_myCustomComboRate getStringValue] intValue] * 2.55;
}

- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setInteger:[[m_myCustomComboRate getStringValue] intValue] forKey:@"smudge rate"];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComboRate)
    {
        [m_myCustomComboRate setStringValue:[NSString stringWithFormat:@"%d%%",sValue.intValue]];
    }
}

@end
