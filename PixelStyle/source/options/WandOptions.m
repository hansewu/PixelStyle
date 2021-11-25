#import "WandOptions.h"
#import "PSSelection.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSHelp.h"
#import "PSTools.h"

@implementation WandOptions

- (void)awakeFromNib
{
	[super awakeFromNib];
    
    //feather 初始值获取设置
    int nValue;
    if ([gUserDefaults objectForKey:@"wand selection feather"] == NULL) {
        nValue = 0;
    }
    else {
        nValue = [gUserDefaults integerForKey:@"wand selection feather"];
    }
    
    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"%d px"), nValue]];
    
    //[self performSelector:@selector(initViews) withObject:nil afterDelay:0.05];
    [self initViews];
}

-(void)initViews
{
    [m_myCustomComboBoxTolerance setDelegate:self];
    [m_myCustomComboBoxTolerance setSliderMaxValue:255];
    [m_myCustomComboBoxTolerance setSliderMinValue:0];
    
    [m_myCustomComboBoxIntervals setDelegate:self];
    [m_myCustomComboBoxIntervals setSliderMaxValue:128];
    [m_myCustomComboBoxIntervals setSliderMinValue:1];
    [m_myCustomComboBoxTolerance setToolTip:NSLocalizedString(@"Set the sampling range for color", nil)];
    [m_myCustomComboBoxIntervals setToolTip:NSLocalizedString(@"Set the number of sample points", nil)];
    
    int value;
    if ([gUserDefaults objectForKey:@"wand tolerance"] == NULL) {
        value = 15;
    }
    else {
        value = [gUserDefaults integerForKey:@"wand tolerance"];
        if (value < 0 || value > 255)
            value = 0;
        
    }
    [m_myCustomComboBoxTolerance setStringValue:[NSString stringWithFormat:@"%d",value]];
    
    if([gUserDefaults objectForKey:@"wand intervals"] == NULL){
        value = 15;
    }else{
        value = [gUserDefaults integerForKey:@"wand intervals"];
        if (value < 1 || value > 128)
            value = 1;
    }
    [m_myCustomComboBoxIntervals setStringValue:[NSString stringWithFormat:@"%d",value]];
    

    [m_labelTolerance setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Tolerance", nil)]];
    [m_labelIntervals setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Intervals", nil)]];
}

- (int)tolerance
{
	return [[m_myCustomComboBoxTolerance getStringValue] intValue];
}

- (int)numIntervals
{
	return [[m_myCustomComboBoxIntervals getStringValue] intValue];
}

- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setInteger:[[m_myCustomComboBoxTolerance getStringValue] intValue] forKey:@"wand tolerance"];
	[gUserDefaults setInteger:[[m_myCustomComboBoxIntervals getStringValue] intValue] forKey:@"wand intervals"];
    [gUserDefaults setInteger:[m_texFieldFeather intValue] forKey:@"wand selection feather"];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComboBoxTolerance)
    {
        [m_myCustomComboBoxTolerance setStringValue:[NSString stringWithFormat:@"%.0f",sValue.floatValue]];
    }
    else if (customComboBox == m_myCustomComboBoxIntervals)
    {
        [m_myCustomComboBoxIntervals setStringValue:[NSString stringWithFormat:@"%.0f",sValue.floatValue]];
    }
}

//#pragma mark -TextFieldDelegate
//
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
//{
//    NSTextField *textField = (NSTextField *)control;
//    
//    if(textField == m_idToleranceLabel)
//    {
//        int nValue = [textField intValue];
//        if(nValue < [(NSSlider *)m_idToleranceSlider minValue]) nValue = [(NSSlider *)m_idToleranceSlider minValue];
//        else if (nValue > [(NSSlider *)m_idToleranceSlider maxValue]) nValue = [(NSSlider *)m_idToleranceSlider maxValue];
//        
//        [textField setIntValue:nValue];
//        [m_idToleranceSlider setIntValue:nValue];
//    }
//    else if(textField == m_idIntervalsLabel)
//    {
//        int nValue = [textField intValue];
//        if(nValue < [(NSSlider *)m_idIntervalsSlider minValue]) nValue = [(NSSlider *)m_idIntervalsSlider minValue];
//        else if (nValue > [(NSSlider *)m_idIntervalsSlider maxValue]) nValue = [(NSSlider *)m_idIntervalsSlider maxValue];
//        
//        [textField setIntValue:nValue];
//        [m_idIntervalsSlider setIntValue:nValue];
//    }
//
//    
//    return YES;
//}

@end
