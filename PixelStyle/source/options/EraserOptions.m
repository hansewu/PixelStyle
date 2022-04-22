#import "EraserOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSButtonCell.h"

@implementation EraserOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_imageViewBrush setToolTip:NSLocalizedString(@"Display the current brush", nil)];
    [m_idOpenBrushPanel setToolTip:NSLocalizedString(@"Tap to open the “Brush Preset” Selector", nil)];
    [m_idDrawTyle setToolTip:NSLocalizedString(@"Design the painting way for connecting the previous drawing stroke", nil)];
    [m_idDrawTyle45 setToolTip:NSLocalizedString(@"Design the painting way for connecting the previous drawing stroke", nil)];
    [m_idMimicBrushCheckbox setToolTip:NSLocalizedString(@"Mimic paintbrush fading", nil)];
    
    
    [m_idMimicBrushCheckbox setState:[gUserDefaults boolForKey:@"eraser mimicBrush"]];
    
    //[self performSelector:@selector(initViews) withObject:nil afterDelay:0.05];
    [self initViews];
}




-(void)initViews
{
    NSMutableArray *subviews = [[[m_idDrawTyle superview] subviews] mutableCopy];
     for (NSView *view in subviews)
     {
         if(view.frame.origin.x > 50)
         {
             NSPoint originPoint = NSMakePoint(view.frame.origin.x+100, view.frame.origin.y);
             [view setFrameOrigin:originPoint];
         }
         
     }
    
    NSPopUpButton *popBtn = [[NSPopUpButton alloc] initWithFrame:
          NSMakeRect(55, 8, 100, 18) pullsDown:YES];
    [popBtn addItemWithTitle:@"Fill Type"];
    [popBtn addItemWithTitle:NSLocalizedString(@"No Fill", nil)];
    [popBtn addItemWithTitle:NSLocalizedString(@"Auto Fill", nil)];
    [popBtn addItemWithTitle:NSLocalizedString(@"Fast Auto Fill", nil)];
    [popBtn addItemWithTitle:NSLocalizedString(@"Slow Auto Fill", nil)];
    
    [popBtn setTarget:self];
    
    popBtn.title = NSLocalizedString(@"Fast Auto Fill", nil);
        
    [[m_idDrawTyle superview] addSubview:popBtn];
    [popBtn setAction:@selector(handlePopBtn:)];
    [popBtn selectItemAtIndex:3];
    
    m_nFillType = 3;
    /*
    NSComboBox *popBtn = [[NSComboBox alloc] initWithFrame:
          NSMakeRect(52, 5, 100, 20)];
    //[popBtn addItemWithObjectValue:@"Fill Type"];
    [popBtn addItemWithObjectValue:@"No Fill"];
    [popBtn addItemWithObjectValue:@"Auto Fill"];
    [popBtn addItemWithObjectValue:@"Fast Auto Fill"];
    [popBtn addItemWithObjectValue:@"Slow Auto Fill" ];
    //[popBtn setFont:<#(NSFont * _Nullable)#>]
     [[m_idDrawTyle superview] addSubview:popBtn];
    [popBtn selectItemAtIndex:1];
    
     */
    
    [m_idPSComboxOpacity setDelegate:self];
    [m_idPSComboxOpacity setSliderMaxValue:100];
    [m_idPSComboxOpacity setSliderMinValue:5];
    [m_idPSComboxOpacity setToolTip:NSLocalizedString(@"Adjust eraser transparency", nil)];
    
    int value;
    
    if ([gUserDefaults objectForKey:@"eraser opacity"] == NULL) {
        value = 100;
    }
    else {
        value = [gUserDefaults integerForKey:@"eraser opacity"];
        if (value < 0 || value > 100)
            value = 100;
    }
    [m_idPSComboxOpacity setStringValue:[NSString stringWithFormat:@"%d%%", value]];
    [m_idOpacityLabel setStringValue:@"Opacity :"];
    
    [m_idOpacityLabel setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [(NSButton *)m_idDrawTyle setTitle:NSLocalizedString(@"Draw straight lines", nil)];
    [(NSButton *)m_idDrawTyle45 setTitle:NSLocalizedString(@"Draw straight lines at 45°", nil)];
    [(NSButton *)m_idMimicBrushCheckbox setTitle:NSLocalizedString(@"Mimic paintbrush fading", nil)];
}

- (void)handlePopBtn:(NSPopUpButton *)popBtn
{
    // 选中item 的索引
    NSLog(@"%d", popBtn.indexOfSelectedItem);
//    [popBtn selectItemAtIndex:popBtn.indexOfSelectedItem];
    popBtn.title = popBtn.selectedItem.title;
    m_nFillType = popBtn.indexOfSelectedItem;
}

-(int)fillType
{
    return m_nFillType;
}

//- (IBAction)opacityChanged:(id)sender
//{		
//	[m_idOpacityLabel setStringValue:@"Opacity :"];
//    
//    [m_texFieldOpacity setStringValue:[NSString stringWithFormat:@"%d%%", [m_idOpacitySlider intValue]]];
//}

- (int)opacity
{
	return [[m_idPSComboxOpacity getStringValue] intValue] * 2.55;
}

- (BOOL)mimicBrush
{
	return [m_idMimicBrushCheckbox state];
}

- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setInteger:[[m_idPSComboxOpacity getStringValue] intValue] forKey:@"eraser opacity"];
	[gUserDefaults setObject:[m_idMimicBrushCheckbox state] ? @"YES" : @"NO" forKey:@"eraser mimicBrush"];
}

- (void)updateModifiers:(unsigned int)modifiers
{
    [super updateModifiers:modifiers];
    int modifier = [super modifier];
    
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

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_idPSComboxOpacity)
    {
        [m_idPSComboxOpacity setStringValue:[NSString stringWithFormat:@"%.0f%%",sValue.floatValue]];
    }
}
//#pragma mark -TextFieldDelegate
//
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
//{
//    NSTextField *textField = (NSTextField *)control;
//    ;
//    int nValue = [textField intValue];
//    if(nValue < [(NSSlider *)m_texFieldOpacity minValue]) nValue = [(NSSlider *)m_texFieldOpacity minValue];
//    else if (nValue > [(NSSlider *)m_texFieldOpacity maxValue]) nValue = [(NSSlider *)m_texFieldOpacity maxValue];
//    
//    [m_texFieldOpacity setStringValue:[NSString stringWithFormat:@"%d%%", nValue]];
//    [m_idOpacitySlider setIntValue:nValue];
//    
//    
//    return YES;
//}

@end
