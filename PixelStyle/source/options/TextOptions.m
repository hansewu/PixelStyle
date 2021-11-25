#import "AppKit/AppKit.h"
#import "TextOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSPrefs.h"
#import "PSProxy.h"
#import "TextTool.h"
#import "PSDocument.h"
#import "PSFontPanel.h"
#import "WDFontManager.h"

id gNewFont;


@implementation TextOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idButtonFontType setToolTip:NSLocalizedString(@"Design font family", nil)];
    [m_btSelectFontFamily setToolTip:NSLocalizedString(@"Design font style", nil)];
    [m_comboFontSize setToolTip:NSLocalizedString(@"Design font size", nil)];
    [m_btColorFill setToolTip:NSLocalizedString(@"Design text color", nil)];
    [m_btBold setToolTip:NSLocalizedString(@"Faux bold", nil)];
    [m_btItalics setToolTip:NSLocalizedString(@"Faux italic", nil)];
    [m_btUnderline setToolTip:NSLocalizedString(@"Underlined", nil)];
    [m_btStrikethrough setToolTip:NSLocalizedString(@"Strikethrough", nil)];
    [m_btnShowCustomTransformPanel setToolTip:NSLocalizedString(@"Design text deformation", nil)];
    [m_labelType setStringValue:NSLocalizedString(@"Style :", nil)];
    [m_labelBending setStringValue:NSLocalizedString(@"Bending :", nil)];
    
    
    NSPopUpButton *btPopCustomTransform = ( NSPopUpButton *)m_btCustomTransform;
    
    [btPopCustomTransform removeAllItems];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Arc Warp", nil)];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Arc lower Warp", nil)];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Arc upper Warp", nil)];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Arch Warp", nil)];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Buldge Warp", nil)];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Shell lower Warp", nil)];
    [btPopCustomTransform addItemWithTitle:NSLocalizedString(@"Shell upper Warp", nil)];
    
    //    NSSlider *slider = m_sliderSpacing;
    //    [slider setMaxValue:8];
    //    [slider setMinValue:-5];
    /*
     No impletension:
     FLAG_WARP_METHOD,
     WAVE_WARP_METHOD,
     FISH_WARP_METHOD,
     RISE_WARP_METHOD,
     FISHEYE_WARP_METHOD,
     INFLATE_WARP_METHOD,
     SQUEEZE_WARP_METHOD,
     TWIST_WARP_METHOD,*/
    [btPopCustomTransform selectItemAtIndex:0];
//    [btPopCustomTransform setTitle:@"Arc Warp"];
    
    [m_comboFontSize setDelegate:self];
    
    [m_idCustomTransformPanel setCustomDelegate:self];
    
    
    NSColor *color = [NSColor redColor];
    NSImage *image = [self getImageFromColor:color size:NSMakeSize(70.0, 21.0)];
    
    [m_colorFontFill release];
    m_colorFontFill = color;
    [m_colorFontFill retain];
    
    [m_btColorFill setImage:image];
    
    
    //[self performSelector:@selector(initView) withObject:nil afterDelay:.05];
    [self initView];
    
    
    /*   int ivalue;
     BOOL bvalue;
     NSFont *font;
     
     // Handle the text alignment
     if ([gUserDefaults objectForKey:@"text alignment"] == NULL) {
     ivalue = NSLeftTextAlignment;
     }
     else {
     ivalue = [gUserDefaults integerForKey:@"text alignment"];
     if (ivalue < 0 || ivalue >= [m_idToolControl segmentCount])
     ivalue = NSLeftTextAlignment;
     }
     [m_idToolControl setSelectedSegment:ivalue];
     
     // Handle the text outline slider
     if ([gUserDefaults objectForKey:@"text outline slider"] == NULL) {
     ivalue = 5;
     }
     else {
     ivalue = [gUserDefaults integerForKey:@"text outline slider"];
     if (ivalue < 1 || ivalue > 24)
     ivalue = 5;
     }
     [m_idOutlineSlider setIntValue:ivalue];
     
     // Handle the text outline checkbox
     if ([gUserDefaults objectForKey:@"text outline checkbox"] == NULL) {
     bvalue = NO;
     }
     else {
     bvalue = [gUserDefaults boolForKey:@"text outline checkbox"];
     }
     [m_idOutlineCheckbox setState:bvalue];
     
     // Enable or disable the slider appropriately
     if ([m_idOutlineCheckbox state])
     [m_idOutlineSlider setEnabled:YES];
     else
     [m_idOutlineSlider setEnabled:NO];
     
     // Show the slider value
     [m_idOutlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [m_idOutlineSlider intValue]]];
     
     // Handle the text fringe checkbox
     if ([gUserDefaults objectForKey:@"text fringe checkbox"] == NULL) {
     bvalue = YES;
     }
     else {
     bvalue = [gUserDefaults boolForKey:@"text fringe checkbox"];
     }
     [m_idFringeCheckbox setState:bvalue];
     
     // Set up font manager
     gNewFont = NULL;
     m_idFontManager = [NSFontManager sharedFontManager];
     [m_idFontManager setAction:@selector(changeSpecialFont:)];
     if ([gUserDefaults objectForKey:@"text font"] == NULL) {
     font = [NSFont userFontOfSize:0];
     [m_idFontManager setSelectedFont:font isMultiple:NO];
     [m_idFontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [font displayName],  (int)[font pointSize]]];
     }
     else {
     font = [NSFont fontWithName:[gUserDefaults objectForKey:@"text font"] size:[gUserDefaults integerForKey:@"text size"]];
     [m_idFontManager setSelectedFont:font isMultiple:NO];
     [m_idFontLabel setStringValue:[NSString stringWithFormat:@"%@ %d pt",  [font displayName],  (int)[font pointSize]]];
     }
     */
}


-(void)initView
{
    [m_myCustomBoxSpacing setDelegate:self];
    [m_myCustomBoxSpacing setSliderMaxValue:8];
    [m_myCustomBoxSpacing setSliderMinValue:-5];
    [m_myCustomBoxSpacing setStringValue:@"0"];
    [m_myCustomBoxSpacing setToolTip:NSLocalizedString(@"Design text kerning", nil)];
}


- (void)dealloc
{
    [m_colorFontFill release];
    
    [super dealloc];
}

- (IBAction)showFonts:(id)sender
{
    NSView *viewFrom = (NSView *)sender;
    NSRect rect = NSMakeRect(300, 300, 100, 10);
    if(viewFrom)
    {
        rect = viewFrom.frame;
        rect.origin.x = 0; rect.origin.y = 0;
        rect = [viewFrom convertRect:rect  toView:nil];
        
        rect = [[viewFrom window] convertRectToScreen:rect];
    }
    
    if(!m_fontPanel)
    {
        m_fontPanel = [[PSFontPanel alloc] initWithRect:CGRectMake(rect.origin.x, rect.origin.y- 550, 250, 550) selectedFont:m_strFontFamily];
        [m_fontPanel setDelegateFontFamilyNotify:self];
    }
    else
    {
        [m_fontPanel showPanel:CGRectMake(rect.origin.x, rect.origin.y- 550, 250, 550) selectedFont:m_strFontFamily];
    }
    
    [m_fontPanel orderFront:m_fontPanel ];
    
    //  m_btSelectFontFamily = sender;
    //[m_idFontManager orderFrontFontPanel:self];
}

- (IBAction)changeFontType:(id)sender
{
    if([m_idButtonFontType indexOfSelectedItem] != -1)
    {
        NSString *fontName = [[WDFontManager sharedInstance] fontsInFamily:m_strFontFamily][[m_idButtonFontType indexOfSelectedItem]];
        
        NSFontManager *manager = [NSFontManager sharedFontManager];
        NSString *familyName = [manager localizedNameForFamily:m_strFontFamily face:nil];
        
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] fontFramilySelected:familyName fontName:fontName];
    }
}

- (IBAction)changeFontSize:(id)sender
{
//    id objectValue = [sender objectValueOfSelectedItem];
//    
//    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontSize:[objectValue floatValue]];
    
    NSComboBox *comboBox = m_comboFontSize;
    
    int nFontSize = [comboBox intValue];
    if(nFontSize > 300) nFontSize = 300;
    else if (nFontSize < 1) nFontSize = 1;
    [comboBox setStringValue:[NSString stringWithFormat:@"%d", nFontSize]];
    
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontSize:nFontSize];
}

- (IBAction)changeFontBold:(id)sender
{
    NSInteger stateValue = ((NSButton *)sender).state;
    
    if(stateValue == NSOnState)
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontBold:3];
    else
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontBold:0];
    
}

- (IBAction)changeFontItalics:(id)sender
{
    NSInteger stateValue = ((NSButton *)sender).state;
    
    if(stateValue == NSOnState)
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontItalics:1];
    else
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontItalics:0];
}

- (IBAction)changeFontUnderline:(id)sender
{
    NSInteger stateValue = ((NSButton *)sender).state;
    
    if(stateValue == NSOnState)
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontUnderline:1];
    else
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontUnderline:0];
    
}
- (IBAction)changeFontStrikethrough:(id)sender
{
    NSInteger stateValue = ((NSButton *)sender).state;
    
    if(stateValue == NSOnState)
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontStrikethrough:1];
    else
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontStrikethrough:0];
}

- (IBAction)changeCharacterSpacing:(id)sender
{
    NSSlider *slider = (NSSlider *)sender;
    
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeCharacterSpacing:(int)slider.floatValue];
}
/*
-(void)controlTextDidChange:(NSNotification*)notification

{
    id object = [notification object];
    
    if(object == m_comboFontSize)
    {
        NSComboBox *box = object;
        
        float fValue = [box.stringValue  floatValue];
        
        if(fValue <1)  fValue = 1.0;
        if(fValue > 300.0)  fValue = 300.0;
        
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontSize:fValue];
    }
    //    [object setComplete:YES];//这个函数可以实现自动匹配功能
}
*/

- (IBAction)changeFontColor:(id)sender
{
    [self showColorPanel:m_colorFontFill];
}


-(void)changeColorFromColorPanel:(id)sender
{
    NSColor *color = [(NSColorPanel*)sender color];
    NSImage *image = [self getImageFromColor:color size:NSMakeSize(70.0, 21.0)];
    
    [m_colorFontFill release];
    m_colorFontFill = color;
    [m_colorFontFill retain];
    
    [m_btColorFill setImage:image];
    
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeFontColor:m_colorFontFill];
}

- (IBAction)showCustomTransformPanel:(id)sender
{
    NSPoint originalPoint = [(NSButton *)m_btnShowCustomTransformPanel frame].origin;
    NSPoint centerPoint;
    centerPoint.x += [(NSButton *)m_btnShowCustomTransformPanel frame].size.width/2.0;
    centerPoint.y += [(NSButton *)m_btnShowCustomTransformPanel frame].size.height/2.0;
    
    NSWindow *w = [gCurrentDocument window];
    centerPoint = [m_idView convertPoint:originalPoint toView:[w contentView]];
    centerPoint.x += w.frame.origin.x;
    centerPoint.y += w.frame.origin.y;
    [m_idCustomTransformPanel showPanel:NSMakeRect(centerPoint.x, centerPoint.y - 123, [(MyCustomPanel *)m_idCustomTransformPanel frame].size.width, [(MyCustomPanel *)m_idCustomTransformPanel frame].size.height)];
}

- (IBAction)changeCustomTransformType:(id)sender
{
    if([m_btCustomTransform indexOfSelectedItem] != -1)
    {
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeCustomTransformType:[m_btCustomTransform indexOfSelectedItem]];
    }
}

- (IBAction)changeCustomTransformValue:(id)sender
{
    NSSlider *slider = (NSSlider *)sender;
    
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeCustomTransformValue:slider.floatValue];
    
    [m_textFieldTransformValue setIntValue:slider.floatValue];
    
}



- (void)updtaeUIForFont:(NSString *)strFontName
{
    NSString *strFamilyName = [[WDFontManager sharedInstance] familyNameForFont:strFontName];
    
    [self updtaeUIForFont:strFamilyName fontName:strFontName];
}

- (BOOL)isString:(NSString*)fullString contains:(NSString*)other
{
    NSRange range = [fullString rangeOfString:other];
    return range.length != 0;
}

- (void)updtaeUIForFont:(NSString *)strFamilyName fontName:(NSString *)strFontName
{
    
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSString *familyName = [manager localizedNameForFamily:strFamilyName face:nil];
    
    [m_btSelectFontFamily setTitle:familyName];
    
    [m_idButtonFontType removeAllItems];
    
    int count = [[[WDFontManager sharedInstance] fontsInFamily:strFamilyName] count];
    
    int nSelected = 0;
    for(int i=0; i< count; i++)
    {
        NSString *fontName = [[WDFontManager sharedInstance] fontsInFamily:strFamilyName][i];
        
        NSString *faceType = [[WDFontManager sharedInstance] typefaceNameForFont:fontName];
        NSString *fontNameLocal = [manager localizedNameForFamily:familyName face:nil];
        
        if([self isString:faceType contains:fontNameLocal] == NO)
        {
            fontNameLocal = [fontNameLocal stringByAppendingString:@" "];
            fontNameLocal = [fontNameLocal stringByAppendingString:faceType];
        }
        else
            fontNameLocal = faceType;
        
        [m_idButtonFontType addItemWithTitle:fontNameLocal];
        
        if([strFontName isEqualToString:fontName])
            nSelected = i;
    }
    
    [m_idButtonFontType selectItemAtIndex:nSelected];
}

-(void)fontFramilySelected:(NSString *)strFamilyName fontName:(NSString *)strFontName
{
    if(m_strFontFamily) [m_strFontFamily release];
    
    m_strFontFamily = strFamilyName;
    [m_strFontFamily retain];
    
    [self updtaeUIForFont:strFamilyName fontName:strFontName];
    
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] fontFramilySelected:strFamilyName fontName:strFontName];
}


- (void)updtaeUIForFontColor:(NSColor *)color
{
    [m_colorFontFill release];
    m_colorFontFill = color;
    [m_colorFontFill retain];
    
    NSImage *image = [self getImageFromColor:m_colorFontFill size:NSMakeSize(70.0, 21.0)];
    
    [m_btColorFill setImage:image];
}

- (void)updtaeUIForFontBold:(int)nWidth
{
    if(nWidth == 0)
        [m_btBold setState:NSOffState];
    else
        [m_btBold setState:NSOnState];
    
}
- (void)updtaeUIForFontItalics:(int)nItalicsValue
{
    if(nItalicsValue == 0)
        [m_btItalics setState:NSOffState];
    else
        [m_btItalics setState:NSOnState];
    
}
- (void)updtaeUIForFontUnderline:(int)nUnderlineValue
{
    if(nUnderlineValue == 0)
        [m_btUnderline setState:NSOffState];
    else
        [m_btUnderline setState:NSOnState];
    
}
- (void)updtaeUIForFontStrikethrough:(int)nStrikethroughValue
{
    if(nStrikethroughValue == 0)
        [m_btStrikethrough setState:NSOffState];
    else
        [m_btStrikethrough setState:NSOnState];
}

- (IBAction)updtaeUIForFontCharacterSpacing:(int)nSpaceValue
{
    //     NSSlider *slider = (NSSlider *)m_sliderSpacing;
    //
    //    slider.floatValue = (float)nSpaceValue;
    
    [m_myCustomBoxSpacing setStringValue:[NSString stringWithFormat:@"%d",nSpaceValue]];
}

- (void)updateUIForFontSize:(CGFloat)fSize
{
    int nSize  = (int)(fSize + 0.0001);
    NSComboBox *box = (NSComboBox *)m_comboFontSize;
    
    box.stringValue = [NSString stringWithFormat:@"%d",nSize];
}

- (void)updateUIForCustomTransformType:(int)type
{
    NSPopUpButton *btCustomTransform = m_btCustomTransform;
    
    NSMenuItem *menuItem = [btCustomTransform itemAtIndex:type];
    
    if(menuItem)
    {
        [btCustomTransform setTitle:menuItem.title];
    }
}

- (void)updateUIForCustomTransformValue:(CGFloat)fValue
{
    NSSlider *slider = (NSSlider *)m_sliderTransformValue;
    
    slider.floatValue = fValue;
    
    [m_textFieldTransformValue setIntValue:slider.floatValue];
}
/*
 - (NSTextAlignment)alignment
 {
 switch ([m_idToolControl selectedSegment]) {
 case 0:
 return NSLeftTextAlignment;
 break;
 case 1:
 return NSCenterTextAlignment;
 break;
 case 2:
 return NSRightTextAlignment;
 break;
 }
 
 return NSLeftTextAlignment;
 }
 
 - (int)outline
 {
 if ([m_idOutlineCheckbox state]) {
 return [m_idOutlineSlider intValue];
 }
 
 return 0;
 }
 */

- (BOOL)useSubpixel
{
    return YES;
}

- (BOOL)useTextures
{
    return [[PSController m_idPSPrefs] useTextures];
}

/*- (BOOL)allowFringe
 {
 return [m_idFringeCheckbox state];
 }
 
 - (IBAction)update:(id)sender
 {
 // Enable or disable the slider appropriately
 if ([m_idOutlineCheckbox state])
 [m_idOutlineSlider setEnabled:YES];
 else
 [m_idOutlineSlider setEnabled:NO];
 
 // Show the slider value
 [m_idOutlineCheckbox setTitle:[NSString stringWithFormat:LOCALSTR(@"outline", @"Outline: %d pt"), [m_idOutlineSlider intValue]]];
 
 // Update the text tool
 //	[(TextTool *)[[m_idDocument tools] getTool:kTextTool] preview:NULL];
 }
 */
- (void)shutdown
{
    [super shutdown];
    [(TextTool *)[[m_idDocument tools] getTool:kTextTool] shutDown];
    /*
     [gUserDefaults setInteger:[m_idToolControl selectedSegment] forKey:@"text alignment"];
     [gUserDefaults setObject:[m_idOutlineCheckbox state] ? @"YES" : @"NO" forKey:@"text outline checkbox"];
     [gUserDefaults setInteger:[m_idOutlineSlider intValue] forKey:@"text outline slider"];
     [gUserDefaults setObject:[m_idFringeCheckbox state] ? @"YES" : @"NO" forKey:@"text fringe checkbox"];
     [gUserDefaults setObject:[[m_idFontManager selectedFont] fontName] forKey:@"text font"];
     [gUserDefaults setInteger:(int)[[m_idFontManager selectedFont] pointSize] forKey:@"text size"];*/
}


-(NSImage *)getImageFromColor:(NSColor *)color size:(NSSize)size
{
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height) xRadius:4.0 yRadius:4.0];
    [color set];
    [path fill];
    
    path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height) xRadius:4.0 yRadius:4.0];
    path.lineWidth = 6.0;
    [[NSColor whiteColor] set];
    [path stroke];
    
    path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0, 0, size.width, size.height) xRadius:4.0 yRadius:4.0];
    path.lineWidth = 2.0;
    [[NSColor blackColor] set];
    [path stroke];
    
    
    [image unlockFocus];
    
    return [image autorelease];
}

-(void)showColorPanel:(NSColor *)color
{
    NSColorPanel* colorPanel = [NSColorPanel sharedColorPanel];
    [colorPanel setMode:NSNoModeColorPanel];
    [colorPanel setShowsAlpha:NO];
    
    if(color!= nil)
        [colorPanel setColor:color];
    [colorPanel orderFront:self];
    [colorPanel setContinuous:YES];
    [colorPanel setAction:@selector(changeColorFromColorPanel:)];
    [colorPanel setTarget:self];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomBoxSpacing)
    {
        [m_myCustomBoxSpacing setStringValue:[NSString stringWithFormat:@"%d",(int)sValue.floatValue]];
        
        [(TextTool *)[[m_idDocument tools] getTool:kTextTool] changeCharacterSpacing:(int)(int)sValue.floatValue];
    }
}

#pragma mark - MyCustomView delegate -

-(void)panelDidDismiss:(NSNotification *)notification
{
    MyCustomPanel *customPanel = [notification object];
    if(customPanel == m_idCustomTransformPanel)
    {
        [m_btnShowCustomTransformPanel setState:NSOffState];
    }
}

#pragma mark - NSTextField delegate -
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    int nValue = [textField intValue];

    if(textField == m_textFieldTransformValue)
    {
        if(nValue < [(NSSlider *)m_sliderTransformValue minValue]) nValue = [(NSSlider *)m_sliderTransformValue minValue];
        else if (nValue > [(NSSlider *)m_sliderTransformValue maxValue]) nValue = [(NSSlider *)m_sliderTransformValue maxValue];

        [m_textFieldTransformValue setIntValue:nValue];
        [m_sliderTransformValue setIntValue:nValue];
        
        [self changeCustomTransformValue:m_sliderTransformValue];
    }


    return YES;
}

@end
