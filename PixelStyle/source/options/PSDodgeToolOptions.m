//
//  PSDodgeToolOptions.m
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "PSDodgeToolOptions.h"


@implementation PSDodgeToolOptions


-(void)awakeFromNib
{
    [super awakeFromNib];
    //[self performSelector:@selector(delayInitView) withObject:nil afterDelay:0.05];
    [self delayInitView];
}

-(void)delayInitView
{
    [m_idPSComboxExposure setDelegate:self];
    [m_idPSComboxExposure setSliderMaxValue:1.0];
    [m_idPSComboxExposure setSliderMinValue:0.0];
    [m_idPSComboxExposure setStringValue:@"0.5"];
    [m_idPSComboxExposure setToolTip:NSLocalizedString(@"Set exposure", nil)];
    
    [m_idButtonDodgeRange setToolTip:NSLocalizedString(@"Set range", nil)];
    [m_idButtonDodgeRange removeAllItems];
    [m_idButtonDodgeRange addItemWithTitle:NSLocalizedString(@"Highlights", nil)];
    [m_idButtonDodgeRange addItemWithTitle:NSLocalizedString(@"Midtones", nil)];
    [m_idButtonDodgeRange addItemWithTitle:NSLocalizedString(@"Shadows", nil)];
    [m_idButtonDodgeRange selectItemAtIndex:1];
    
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Brush Preset” Selector", nil)];
    
    [m_labelRange setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Range", nil)]];
    [m_labelExposure setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Exposure", nil)]];
}



- (DodgeRange)getDodgeRange
{
    return [m_idButtonDodgeRange indexOfSelectedItem];
}


- (float)getExposureValue
{
    return [[m_idPSComboxExposure getStringValue] floatValue];
}


#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_idPSComboxExposure)
    {
        [m_idPSComboxExposure setStringValue:[NSString stringWithFormat:@"%.2f",sValue.floatValue]];
    }
}


@end
