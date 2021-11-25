#import "PencilOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSDocument.h"

@implementation PencilOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_imageViewTexture setToolTip:NSLocalizedString(@"Display the current texture", nil)];
    [m_idSizeSlider setToolTip:NSLocalizedString(@"Size of drawing square", nil)];
    [m_idOpenTexturePanel setToolTip:NSLocalizedString(@"Tap to open the “Texture Preset” Selector", nil)];
    [m_idDrawTyle setToolTip:NSLocalizedString(@"Design the painting way for connecting the previous drawing stroke", nil)];
    [m_idDrawTyle45 setToolTip:NSLocalizedString(@"Design the painting way for connecting the previous drawing stroke", nil)];

    
    [m_labelOpacity setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [m_labelTextures setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Textures", nil)]];

    [(NSButton *)m_idDrawTyle setTitle:NSLocalizedString(@"Draw straight lines", nil)];
    [(NSButton *)m_idDrawTyle45 setTitle:NSLocalizedString(@"Draw straight lines at 45°", nil)];
    [(NSButton *)m_idEraseCheckbox setTitle:NSLocalizedString(@"Erase", nil)];
    
    int value;
    
    if ([gUserDefaults objectForKey:@"pencil size"] == NULL) {
        value = 1;
    }
    else {
        value = [gUserDefaults integerForKey:@"pencil size"];
        if (value < [m_idSizeSlider minValue] || value > [m_idSizeSlider maxValue])
            value = 1;
    }
    
    [m_idSizeSlider setIntValue:value];
    [m_textFieldSize setStringValue:[NSString stringWithFormat:@"%@ :%d", NSLocalizedString(@"Size", nil), [m_idSizeSlider intValue]]];
//    [m_textFieldSize setStringValue:[NSString stringWithFormat:LOCALSTR(@"size", @"Size : %d"), [m_idSizeSlider intValue]]];
    
    m_bIsErasing = NO;
    m_nStraightLineType = STRAIGHT_NO;
    m_bLastEraseState = NO;
    
    //[self performSelector:@selector(initViews) withObject:nil afterDelay:0.05];
    [self initViews];
}

-(void)initViews
{
    
    [m_myCustomComboOpacity setDelegate:self];
    [m_myCustomComboOpacity setSliderMaxValue:100.0];
    [m_myCustomComboOpacity setSliderMinValue:0.0];
    [m_myCustomComboOpacity setStringValue:@"100.0%"];
    
}

- (int)pencilSize
{
    return [m_idSizeSlider intValue];
}

- (BOOL)useTextures
{
	return [[PSController m_idPSPrefs] useTextures];
}

- (BOOL)pencilIsErasing
{
	return m_bIsErasing;
}

- (void)updateModifiers:(unsigned int)modifiers
{
//    return;
    
	[super updateModifiers:modifiers];
    
    if ((modifiers & NSShiftKeyMask) >> 17 && (modifiers & NSControlKeyMask) >> 18)
    {
        [self setModeFromModifier:kShiftControlModifier];
    }
    else if ((modifiers & NSShiftKeyMask) >> 17)
    {
        [self setModeFromModifier:kShiftModifier];
    }
    else
    {
        [self setModeFromModifier:m_enumLastModifier];
    }
    
	int modifier = [super modifier];
	
    if (modifier == kAltModifier) {
        [(NSButton *)m_idEraseCheckbox setState:YES];
        m_bIsErasing = YES;
    }else{
        [(NSButton *)m_idEraseCheckbox setState:m_bLastEraseState];
        m_bIsErasing = m_bLastEraseState;
    }
    
}

- (void)setModeFromModifier:(unsigned int)modifier
{
    switch (modifier)
    {
        case kNoModifier:
        {
            [self resumeDrawLinesTypeStatus];
        }
            break;
        case kShiftModifier:
        {
            NSButton *btn = (NSButton *)[m_idView viewWithTag:100 + 0];
            [btn setState:YES];
            [self drawLinesType:btn];
        }
            break;
        case kShiftControlModifier:
        {
            NSButton *btn = (NSButton *)[m_idView viewWithTag:100 + 1];
            [btn setState:YES];
            [self drawLinesType:btn];
        }
            break;
        
        default:
            break;
    }
}


- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setInteger:[m_idSizeSlider intValue] forKey:@"pencil size"];
}

-(IBAction)changeSize:(id)sender
{
    [m_textFieldSize setStringValue:[NSString stringWithFormat:@"%@ :%d", NSLocalizedString(@"Size", nil), [m_idSizeSlider intValue]]];
}

-(IBAction)onDrawLinesType:(id)sender
{
    [self drawLinesType:sender];
    
    m_enumLastModifier = m_enumModifier;
}

-(void)drawLinesType:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    if([btn state])
    {
        [self resumeDrawLinesTypeStatus];
        [btn setState:YES];
        if([btn tag] -100 == 0) m_enumModifier = kShiftModifier;
        else if ([btn tag] -100 == 1) m_enumModifier = kShiftControlModifier;
    }
    else
        m_enumModifier = kNoModifier; 
}

-(IBAction)onChangeEraseMode:(id)sender
{
    BOOL bState = [(NSButton *)m_idEraseCheckbox state];
    if (bState) {
        m_bIsErasing = YES;
        m_bLastEraseState = YES;
    }else{
        m_bIsErasing = NO;
        m_bLastEraseState = NO;
    }
}

-(void)resumeDrawLinesTypeStatus
{
    for (int nIndex = 0; nIndex < STRAIGHT_LINE_COUNT; nIndex++)
    {
        NSButton *btn = (NSButton *)[m_idView viewWithTag:100 + nIndex];
        [btn setState:NO];
    }
}

-(STRAIGHT_LINE_TYPE)getDrawLinesType
{
    return m_nStraightLineType;
}


- (float)getOpacityValue
{
    if ([m_myCustomComboOpacity getStringValue] == nil) {
        [m_myCustomComboOpacity setStringValue:@"100.0%"];
    }
    float fAlpha = [m_myCustomComboOpacity getStringValue].floatValue / 100.0;
    return fAlpha;
}



#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if(customComboBox == m_myCustomComboOpacity){
        float alpha = sValue.floatValue;
        alpha = MAX(0, MIN(100, alpha));
        [m_myCustomComboOpacity setStringValue:[NSString stringWithFormat:@"%.1f%%", alpha]];
    }
}


@end
