//
//  PSSpongeToolOptions.m
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//

#import "PSSpongeToolOptions.h"

@implementation PSSpongeToolOptions

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initView];
}

-(void)initView
{
    [m_idPSComboxFlow setDelegate:self];
    [m_idPSComboxFlow setSliderMaxValue:1.0];
    [m_idPSComboxFlow setSliderMinValue:0.0];
    [m_idPSComboxFlow setStringValue:@"0.5"];
    [m_idPSComboxFlow setToolTip:NSLocalizedString(@"Set flow rate", nil)];
    
    [m_idButtonSpongeMode setToolTip:NSLocalizedString(@"Set mode", nil)];
    [m_idButtonSpongeMode removeAllItems];
    [m_idButtonSpongeMode addItemWithTitle:NSLocalizedString(@"Saturate", nil)];
    [m_idButtonSpongeMode addItemWithTitle:NSLocalizedString(@"Desaturate", nil)];
    [m_idButtonSpongeMode selectItemAtIndex:1];
    
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Brush Preset” Selector", nil)];
    
    [m_labelMode setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Mode", nil)]];
    [m_labelFlow setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Flow", nil)]];
}



- (SpongeMode)getSpongeMode
{
    return [m_idButtonSpongeMode indexOfSelectedItem];
}


- (float)getFlowValue
{
    return [[m_idPSComboxFlow getStringValue] floatValue];

}


#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_idPSComboxFlow)
    {
        [m_idPSComboxFlow setStringValue:[NSString stringWithFormat:@"%.2f",sValue.floatValue]];
    }
}


@end
