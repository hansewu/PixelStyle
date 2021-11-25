#import "BucketOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSHelp.h"
#import "PSTools.h"

#define LABEL_TOLERANCES_TAG 200
#define LABEL_INTERVALS_TAG 201

@implementation BucketOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
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
    
    [m_imageViewTexture setToolTip:NSLocalizedString(@"Display the current texture", nil)];
    [m_idOpenTexturePanel setToolTip:NSLocalizedString(@"Tap to open the “Texture Preset” Selector", nil)];
    [m_myCustomComboBoxTolerance setToolTip:NSLocalizedString(@"Set the sampling range for color", nil)];
    [m_myCustomComboBoxIntervals setToolTip:NSLocalizedString(@"Set the number of sample points", nil)];
    [m_btnFloodAllSelecion setToolTip:NSLocalizedString(@"Set the fill-mode", nil)];
    [m_btnPreviewFlood setToolTip:NSLocalizedString(@"Check the box to preview the filling effects", nil)];
    
    [m_myCustomComboOpacity setDelegate:self];
    [m_myCustomComboOpacity setSliderMaxValue:100.0];
    [m_myCustomComboOpacity setSliderMinValue:0.0];
    [m_myCustomComboOpacity setStringValue:@"100.0%"];
    
    int value;
    if ([gUserDefaults objectForKey:@"bucket tolerance"] == NULL) {
        value = 15;
    }
    else {
        value = [gUserDefaults integerForKey:@"bucket tolerance"];
        if (value < 0 || value > 255)
            value = 0;
        
    }
    [m_myCustomComboBoxTolerance setStringValue:[NSString stringWithFormat:@"%d",value]];
    
    if([gUserDefaults objectForKey:@"bucket intervals"] == NULL){
        value = 15;
    }else{
        value = [gUserDefaults integerForKey:@"bucket intervals"];
        if (value < 1 || value > 128)
            value = 1;
    }
    [m_myCustomComboBoxIntervals setStringValue:[NSString stringWithFormat:@"%d",value]];
    
    
    [m_labelOpacity setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [m_labelIntervals setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Intervals", nil)]];
    [m_labelTolerance setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Tolerance", nil)]];
    
    [(NSButton *)m_btnFloodAllSelecion setTitle:NSLocalizedString(@"Flood all selection", nil)];
    [(NSButton *)m_btnPreviewFlood setTitle:NSLocalizedString(@"Preview flood", nil)];
}

//- (IBAction)toleranceSliderChanged:(id)sender
//{
////	[m_idToleranceLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"tolerance", @"Tolerance: %d"), [m_idToleranceSlider intValue]]];
//    [m_idToleranceLabel setIntValue: [m_idToleranceSlider intValue]];
//}

- (int)tolerance
{
	return [[m_myCustomComboBoxTolerance getStringValue] intValue];
}

//- (IBAction)intervalsSliderChanged:(id)sender
//{
//    [m_idIntervalsLabel setIntValue: [m_idIntervalsSlider intValue]];
//}

- (int)numIntervals
{
	return [[m_myCustomComboBoxIntervals getStringValue] intValue];
}

- (BOOL)useTextures
{
	return [[PSController m_idPSPrefs] useTextures];
}

- (void)shutdown
{
    [super shutdown];
    [gUserDefaults setInteger:[[m_myCustomComboBoxTolerance getStringValue] intValue] forKey:@"bucket tolerance"];
    [gUserDefaults setInteger:[[m_myCustomComboBoxIntervals getStringValue] intValue] forKey:@"bucket intervals"];
}

-(IBAction)onFloodAllSelection:(id)sender
{
    [self floodAllSelection:sender];
    m_enumLastModifier = m_enumModifier;
}

-(IBAction)onPreviewFlood:(id)sender
{
    [self previewFlood:sender];
    
    m_enumLastModifier = m_enumModifier;
}

-(void)floodAllSelection:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    if([btn state])
    {
        [m_btnPreviewFlood setState:NO];
        
        m_enumModifier = kAltModifier;
    }
    else
    {
        m_enumModifier = kNoModifier;
    }
}

-(void)previewFlood:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    if([btn state])
    {
        [m_btnFloodAllSelecion setState:NO];
        
        m_enumModifier = kShiftModifier;
    }
    else
    {
        m_enumModifier = kNoModifier;
    }
}

- (void)updateModifiers:(unsigned int)modifiers
{
    [super updateModifiers:modifiers];
    int modifier = [super modifier];
    
    switch (modifier)
    {
        case kNoModifier:
        {
            [self setModeFromModifier:m_enumLastModifier];
        }
            break;

        case kAltModifier:
        {
            [self setModeFromModifier:kAltModifier];
        }
            break;
        case kShiftModifier:
        {
            [self setModeFromModifier:kShiftModifier];
        }
            break;
        default:
            break;
    }
}

- (void)setModeFromModifier:(unsigned int)modifier
{
    switch (modifier)
    {
        case kNoModifier:
        {
            [m_btnFloodAllSelecion setState:NO];
            [m_btnPreviewFlood setState:NO];
        }
            break;
            
        case kAltModifier:
        {
            [m_btnFloodAllSelecion setState:YES];
            [self floodAllSelection:m_btnFloodAllSelecion];
        }
            break;
        case kShiftModifier:
        {
            [m_btnPreviewFlood setState:YES];
            [self previewFlood:m_btnPreviewFlood];
        }
            break;
        default:
            break;
    }
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
    if (customComboBox == m_myCustomComboBoxTolerance)
    {
        [m_myCustomComboBoxTolerance setStringValue:[NSString stringWithFormat:@"%.0f",sValue.floatValue]];
    }
    else if (customComboBox == m_myCustomComboBoxIntervals)
    {
        [m_myCustomComboBoxIntervals setStringValue:[NSString stringWithFormat:@"%.0f",sValue.floatValue]];
    }else if(customComboBox == m_myCustomComboOpacity){
        float alpha = sValue.floatValue;
        alpha = MAX(0, MIN(100, alpha));
        [m_myCustomComboOpacity setStringValue:[NSString stringWithFormat:@"%.1f%%", alpha]];
    }
}

//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
//{
//    NSTextField *textField = (NSTextField *)control;
//    ;
//    int nValue = [textField intValue];
//    
//    if(textField.tag == LABEL_TOLERANCES_TAG)
//    {
//        if(nValue < [(NSSlider *)m_idToleranceSlider minValue]) nValue = [(NSSlider *)m_idToleranceSlider minValue];
//        else if (nValue > [(NSSlider *)m_idToleranceSlider maxValue]) nValue = [(NSSlider *)m_idToleranceSlider maxValue];
//        
//        [m_idToleranceLabel setIntValue:nValue];
//        [m_idToleranceSlider setIntValue:nValue];
//    }
//    else if(textField.tag == LABEL_INTERVALS_TAG)
//    {
//        if(nValue < [(NSSlider *)m_idIntervalsSlider minValue]) nValue = [(NSSlider *)m_idIntervalsSlider minValue];
//        else if (nValue > [(NSSlider *)m_idIntervalsSlider maxValue]) nValue = [(NSSlider *)m_idIntervalsSlider maxValue];
//        
//        [m_idIntervalsLabel setIntValue:nValue];
//        [m_idIntervalsSlider setIntValue:nValue];
//    }
//    
//    
//    return YES;
//}

@end
