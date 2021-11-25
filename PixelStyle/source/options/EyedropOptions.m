#import "EyedropOptions.h"
#import "ToolboxUtility.h"
#import "PSHelp.h"
#import "PSController.h"
#import "PSTools.h"

@implementation EyedropOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idSizeSlider setToolTip:NSLocalizedString(@"Adjust the sample quantity of sample colors picked by eyedropper tool", nil)];
    [m_idMergedCheckbox setToolTip:NSLocalizedString(@"Define the selection mode for the sample point of eyedropper tool", nil)];
    [m_idSelectBackColorCheckbox setToolTip:NSLocalizedString(@"Designate the sampling color as the foreground/background", nil)];
    
    [m_textFieldSize setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Sample size", nil)]];
    [(NSButton *)m_idMergedCheckbox setTitle:NSLocalizedString(@"Use sample from all layer", nil)];
    [(NSButton *)m_idSelectBackColorCheckbox setTitle:NSLocalizedString(@"Select background color", nil)];
    
    int value;
    
    if ([gUserDefaults objectForKey:@"eyedrop size"] == NULL) {
        value = 1;
    }
    else {
        value = [gUserDefaults integerForKey:@"eyedrop size"];
        if (value < [m_idSizeSlider minValue] || value > [m_idSizeSlider maxValue])
			value = 1;
	}
	[m_idSizeSlider setIntValue:value];
	[m_idMergedCheckbox setState:[gUserDefaults boolForKey:@"eyedrop merged"]];
}

- (int)sampleSize
{
	return [m_idSizeSlider intValue];
}

- (BOOL)mergedSample
{
	return [m_idMergedCheckbox state];
}

- (BOOL)dropAsBackgroundColor
{
    return [m_idSelectBackColorCheckbox state];
}

- (void)shutdown
{
	[gUserDefaults setInteger:[self sampleSize] forKey:@"eyedrop size"];
	[gUserDefaults setObject:[self mergedSample] ? @"YES" : @"NO" forKey:@"eyedrop merged"];
}

@end
