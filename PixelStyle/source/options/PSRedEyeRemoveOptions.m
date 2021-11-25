//
//  PSRedEyeRemoveOptions.m
//  PixelStyle
//
//  Created by wyl on 16/4/20.
//
//

#import "PSRedEyeRemoveOptions.h"

@implementation PSRedEyeRemoveOptions

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initView];
}

-(void)initView
{
    [m_myCustomComboRadius setDelegate:self];
    [m_myCustomComboRadius setSliderMaxValue:100];
    [m_myCustomComboRadius setSliderMinValue:0];
    [m_myCustomComboRadius setStringValue:@"10 px"];
    
    [m_myCustomComboRadius setToolTip:NSLocalizedString(@"Adjust brush size", nil)];
    
    [m_labelRadius setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Pupil Size", nil)]];
}

-(float)getRadiusSize
{
    return [[m_myCustomComboRadius getStringValue] floatValue];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComboRadius)
    {
        [m_myCustomComboRadius setStringValue:[NSString stringWithFormat:@"%d px",sValue.intValue]];
    }
    
}

@end
