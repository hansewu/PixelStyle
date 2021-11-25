#import "BrushOptions.h"
#import "ToolboxUtility.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSWarning.h"
#import "PSDocument.h"

enum {
	kQuadratic,
	kLinear,
	kSquareRoot
};

@implementation BrushOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_imageViewBrush setToolTip:NSLocalizedString(@"Display the current brush", nil)];
    [m_imageViewTexture setToolTip:NSLocalizedString(@"Display the current texture", nil)];
    [m_idOpenTexturePanel setToolTip:NSLocalizedString(@"Tap to open the “Texture Preset” Selector", nil)];
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Brush Preset” Selector", nil)];
    [m_idDrawTyle setToolTip:NSLocalizedString(@"Design the painting way for connecting the previous drawing stroke", nil)];
    [m_idDrawTyle45 setToolTip:NSLocalizedString(@"Design the painting way for connecting the previous drawing stroke", nil)];
    
    [m_idFadeCheckbox setToolTip:NSLocalizedString(@"Fades brush with drawing", nil)];
    [m_idPressureCheckbox setToolTip:NSLocalizedString(@"Enables tablet support", nil)];
    
    [m_idScaleCheckbox setToolTip:NSLocalizedString(@"Scales brush with fading or drawing", nil)];
    [m_idPSComboxFadeOut setToolTip:NSLocalizedString(@"Fades brush with drawing", nil)];
    
    [m_myCustomComboOpacity setToolTip:NSLocalizedString(@"Adjust brush transparency", nil)];
    
    [m_idPressurePopup setToolTip:NSLocalizedString(@"Applies transform to pressure readings", nil)];
    [m_idPressurePopup removeAllItems];
    [m_idPressurePopup addItemWithTitle:NSLocalizedString(@"Lighter", nil)];
    [m_idPressurePopup addItemWithTitle:NSLocalizedString(@"Normal", nil)];
    [m_idPressurePopup addItemWithTitle:NSLocalizedString(@"Darker", nil)];

    int rate, style;
    BOOL fadeOn, pressureOn;
    
    if ([gUserDefaults objectForKey:@"brush pressure"] == NULL) {
        [m_idPressureCheckbox setState:NSOffState];
        [m_idPressurePopup selectItemAtIndex:kLinear];
        [m_idPressurePopup setEnabled:NO];
    }
    else {
        style = [gUserDefaults integerForKey:@"brush pressure style"];
        if (style < kQuadratic || style > kSquareRoot)
			style = kLinear;
		pressureOn = [gUserDefaults boolForKey:@"brush pressure"];
		[m_idPressureCheckbox setState:pressureOn];
		[m_idPressurePopup selectItemAtIndex:style];
		[m_idPressurePopup setEnabled:pressureOn];
	}
	
	if ([gUserDefaults objectForKey:@"brush scale"] == NULL) {
		[m_idScaleCheckbox setState:NSOnState];
	}
	else {
		[m_idScaleCheckbox setState:[gUserDefaults boolForKey:@"brush scale"]];
	}
	
	m_bIsErasing = NO;
	m_bWarnedUser = NO;
    m_bLastEraseState = NO;
    
    //[self performSelector:@selector(initViews) withObject:nil afterDelay:0.05];
    [self initViews];
}

-(void)initViews
{
    [m_idPSComboxFadeOut setDelegate:self];
    [m_idPSComboxFadeOut setSliderMaxValue:120];
    [m_idPSComboxFadeOut setSliderMinValue:1];
    
    [m_myCustomComboOpacity setDelegate:self];
    [m_myCustomComboOpacity setSliderMaxValue:100.0];
    [m_myCustomComboOpacity setSliderMinValue:1.0];
    [m_myCustomComboOpacity setStringValue:@"100.0%"];
    
    int rate;
    BOOL fadeOn;
    if ([gUserDefaults objectForKey:@"brush fade"] == NULL) {
        [m_idFadeCheckbox setState:NSOffState];
        [m_idFadeCheckbox setTitle:@"Fade-out :"];
        
        [m_idPSComboxFadeOut setStringValue:@"10"];
        [m_idPSComboxFadeOut setEnabled:NO];
    }
    else {
        rate = [gUserDefaults integerForKey:@"brush fade rate"];
        if (rate < 1 || rate > 120)
            rate = 10;
        fadeOn = [gUserDefaults boolForKey:@"brush fade"];
        [m_idFadeCheckbox setState:fadeOn];
        [m_idFadeCheckbox setTitle: [NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Fade-out", nil)]];
        
        [m_idPSComboxFadeOut setStringValue:[NSString stringWithFormat:@"%d",rate]];
        [m_idPSComboxFadeOut setEnabled:fadeOn];
    }
    
    [m_labelOpacity setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [m_labelTextures setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Textures", nil)]];
    
    [(NSButton *)m_idDrawTyle setTitle:NSLocalizedString(@"Draw straight lines", nil)];
    [(NSButton *)m_idDrawTyle45 setTitle:NSLocalizedString(@"Draw straight lines at 45°", nil)];
    [(NSButton *)m_idEraseCheckbox setTitle:NSLocalizedString(@"Erase", nil)];
    [(NSButton *)m_idPressureCheckbox setTitle:NSLocalizedString(@"Pressure sensitive", nil)];
    [(NSButton *)m_idScaleCheckbox setTitle:NSLocalizedString(@"Brush scaling", nil)];
}

- (IBAction)update:(id)sender
{
	if (!m_bWarnedUser && [sender tag] == 3) {
		if ([m_idPressureCheckbox state]) {
			if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_4 && NSAppKitVersionNumber < NSAppKitVersionNumber10_4_6) {
				[[PSController seaWarning] addMessage:LOCALSTR(@"tablet bug message", @"There is a bug in Mac OS 10.4 that causes some tablets to incorrectly register their first touch at full strength. A workaround is provided in the \"Preferences\" dialog however the best solution is to upgrade to Mac OS 10.4.6 or later.") level:kModerateImportance];
				m_bWarnedUser = YES;
			}
		}
	}
	[m_idPSComboxFadeOut setEnabled:[m_idFadeCheckbox state]];
	[m_idFadeCheckbox setTitle: @"Fade-out :"];
	[m_idPressurePopup setEnabled:[m_idPressureCheckbox state]];
}

- (BOOL)fade
{
	return [m_idFadeCheckbox state];
}

- (int)fadeValue
{
	return [[m_idPSComboxFadeOut getStringValue] intValue];
}

- (BOOL)pressureSensitive
{
	return [m_idPressureCheckbox state];
}

- (int)pressureValue:(NSEvent *)event
{
	double p;
	
	if ([m_idPressureCheckbox state] == NSOffState)
		return 255;
	
	if (event == NULL)
		return 255;
			
	p = [event pressure];
	
	switch ([m_idPressurePopup indexOfSelectedItem]) {
		case kLinear:
			return (int)(p * 255.0);
		break;
		case kQuadratic:
			return (int)((p * p) * 255.0);
		break;
		case kSquareRoot:
			return (int)(sqrt(p) * 255.0);
		break;
	}

	return 255;
}

- (BOOL)scale
{
	return [m_idScaleCheckbox state];
}

- (BOOL)useTextures
{
	return [[PSController m_idPSPrefs] useTextures];
}

- (BOOL)brushIsErasing
{
	return m_bIsErasing;
}

- (void)updateModifiers:(unsigned int)modifiers
{
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
	[gUserDefaults setObject:[m_idFadeCheckbox state] ? @"YES" : @"NO" forKey:@"brush fade"];
	[gUserDefaults setInteger:[[m_idPSComboxFadeOut getStringValue] intValue] forKey:@"brush fade rate"];
	[gUserDefaults setObject:[m_idPressureCheckbox state] ? @"YES" : @"NO" forKey:@"brush pressure"];
	[gUserDefaults setInteger:[m_idPressurePopup indexOfSelectedItem] forKey:@"brush pressure style"];
	[gUserDefaults setInteger:[m_idScaleCheckbox state] forKey:@"brush scale"];
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
    if (customComboBox == m_idPSComboxFadeOut)
    {
        [m_idPSComboxFadeOut setStringValue:[NSString stringWithFormat:@"%.0f",sValue.floatValue]];
    }else if(customComboBox == m_myCustomComboOpacity){
        float alpha = sValue.floatValue;
        alpha = MAX(0, MIN(100, alpha));
        [m_myCustomComboOpacity setStringValue:[NSString stringWithFormat:@"%.1f%%", alpha]];
    }
}

//#pragma mark -TextFieldDelegate
//
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
//{
//    NSTextField *textField = (NSTextField *)control;
//    ;
//    int nValue = [textField intValue];
//    if(nValue < [(NSSlider *)m_idFadeSlider minValue]) nValue = [(NSSlider *)m_idFadeSlider minValue];
//    else if (nValue > [(NSSlider *)m_idFadeSlider maxValue]) nValue = [(NSSlider *)m_idFadeSlider maxValue];
//    
//    [m_texFieldFade setIntValue:nValue];
//    [m_idFadeSlider setIntValue:nValue];
//    
//    
//    return YES;
//}

@end
