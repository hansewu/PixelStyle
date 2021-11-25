//
//  PSVectorEraserOptions.m
//  PixelStyle
//
//  Created by lchzh on 31/3/16.
//
//

#import "PSVectorEraserOptions.h"

@implementation PSVectorEraserOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self initView];
    
}

-(void)initView
{
    int fSize = 5;
    [m_myCustomComboSize setDelegate:self];
    [m_myCustomComboSize setSliderMaxValue:100];
    [m_myCustomComboSize setSliderMinValue:1];
    [m_myCustomComboSize setStringValue:[NSString stringWithFormat:@"%d",fSize]];
    [m_myCustomComboSize setToolTip:NSLocalizedString(@"设置橡皮大小", nil)];

    [m_labelSize setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Size", nil)]];
}


- (int)getEraserSize
{
    return [[m_myCustomComboSize getStringValue] intValue];
}


#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComboSize)
    {
        [m_myCustomComboSize setStringValue:[NSString stringWithFormat:@"%d",sValue.intValue]];
        
//        [(MyBrushUtility *)[[PSController utilitiesManager] myBrushUtilityFor:gCurrentDocument] changeBrushPara:BRUSH_SLOW_TRACKING value:sValue.floatValue];
//        [self recodeFavoriteBrushHistoryPara];
    }
    
}


@end
