#import "PSController.h"
#import "PSHelp.h"
#import "PSDocument.h"
#import "RectSelectOptions.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSContent.h"
#import "PSSelection.h"
#import "PSOperations.h"
#import "PSMargins.h"
#import "Units.h"
#import "AspectRatio.h"

@implementation RectSelectOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //[m_idAspectRatio setToolTip:NSLocalizedString(@"Set the drawing shape of marquee tool", nil)];
    
    
    
    
	int value;
	
	
	[m_idAspectRatio awakeWithMaster:self andString:@"rect"];
    
    
    //feather 初始值获取设置
    if ([gUserDefaults objectForKey:@"rect selection feather"] == NULL) {
        value = 0;
    }
    else {
        value = [gUserDefaults integerForKey:@"rect selection feather"];
    }

    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"%d px"), value]];
    [m_labelCornerRadius setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Corner radius", nil)]];
//    m_nMode = [gUserDefaults integerForKey:@"rect selection mode"];
    
    [self performSelector:@selector(initView) withObject:nil afterDelay:.05];
    [self initView];
    
}

-(void)initView
{
    
    [m_myCustomComBoxRadius setSliderMaxValue:80];
    [m_myCustomComBoxRadius setSliderMinValue:0];
    [m_myCustomComBoxRadius setDelegate:self];
    [m_myCustomComBoxRadius setToolTip:NSLocalizedString(@"Set the fillet radius", nil)];
    
    int value;
    if ([gUserDefaults objectForKey:@"rect selection radius"] == NULL) {
        value = 8;
    }
    else {
        value = [gUserDefaults integerForKey:@"rect selection radius"];
        if (value < 0 || value > 80)
            value = 8;
    }
    [m_myCustomComBoxRadius setStringValue:[NSString stringWithFormat:@"%d",value]];
}

- (int)radius
{
//	if ([m_idRadiusCheckbox state])
//		return [m_idRadiusSlider intValue];
//	else
//		return 0;
    
    return [[m_myCustomComBoxRadius getStringValue] intValue];
//    return [m_idRadiusSlider intValue];
}

- (NSSize)ratio
{
	return [m_idAspectRatio ratio];
}

- (int)aspectType
{
	return [m_idAspectRatio aspectType];
}

- (IBAction)update:(id)sender;
{
//	[m_idRadiusCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"corner radius", @"Corner radius: %d"), [m_idRadiusSlider intValue]]];
//	[m_idRadiusSlider setEnabled:[m_idRadiusCheckbox state]];
}

//- (IBAction)changeFeather:(id)sender
//{
//    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"feather: %d"), [m_sliderFeather intValue]]];
//}

- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setInteger:[[m_myCustomComBoxRadius getStringValue] intValue] forKey:@"rect selection radius"];
//	[gUserDefaults setObject:[m_idRadiusCheckbox state] ? @"YES" : @"NO" forKey:@"rect selection radius enabled"];
    
    [gUserDefaults setInteger:[m_texFieldFeather intValue] forKey:@"rect selection feather"];
    
    [gUserDefaults setInteger:m_nMode forKey:@"rect selection mode"];
    
	[m_idAspectRatio shutdown];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComBoxRadius)
    {
        [m_myCustomComBoxRadius setStringValue:[NSString stringWithFormat:@"%.0f",sValue.floatValue]];
    }
}

@end
