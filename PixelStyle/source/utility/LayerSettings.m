#import "LayerSettings.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSLayer.h"
#import "PegasusUtility.h"
#import "PSDocument.h"
#import "PSHelpers.h"
#import "Units.h"
#import "InfoPanel.h"
#import "PSView.h"

#import "PSSmartFilterManager.h"

#import "EffectUtility.h"
#import "PSSmartFilterUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"

@implementation LayerSettings

- (void)awakeFromNib
{
	m_pslSettingsLayer = nil;
	[(InfoPanel *)m_idPanel setPanelStyle:kHorizontalPanelStyle];
    
    //[self performSelector:@selector(initView) withObject:nil afterDelay:.05];
    [self initView];
/*#ifdef PROPAINT_VERSION
    [m_viewEffect setHidden:YES];
    [m_viewLayer setFrameSize:NSMakeSize(m_viewLayer.frame.size.width, m_viewLayer.frame.size.height + m_viewEffect.frame.size.height - 20)];
#else
 */
    [m_viewEffect setHidden:NO];
// #endif
}

-(void)initView
{
    [m_myComboxOpacity setDelegate:self];
    [m_myComboxOpacity setSliderMaxValue:100];
    [m_myComboxOpacity setSliderMinValue:0];
    [m_myComboxOpacity setStringValue:@"100"];
    
    [m_idOpacityLabel setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    
    [m_idModePopupOut setToolTip:NSLocalizedString(@"Change Layer Blending Modes", nil)];
    [m_myComboxOpacity setToolTip:NSLocalizedString(@"Change Layer Opacity", nil)];
    [m_btnEffectFill setToolTip:NSLocalizedString(@"Fill", nil)];
    [m_btnEffectStroke setToolTip:NSLocalizedString(@"Outline", nil)];
    [m_btnEffectOuterGlow setToolTip:NSLocalizedString(@"Outer Glow", nil)];
    [m_btnEffectInnerGlow setToolTip:NSLocalizedString(@"Inner Glow", nil)];
    [m_btnEffectShadow setToolTip:NSLocalizedString(@"Shadow", nil)];
    
    for(int nIndex = 0; nIndex < [m_idModePopupOut numberOfItems]; nIndex++)
    {
        NSMenuItem *menuItem = [(NSPopUpButton *)m_idModePopupOut itemAtIndex:nIndex];
        [menuItem setTitle:NSLocalizedString([menuItem title], nil)];
    }
}

- (void)activate
{
}

- (void)deactivate
{
}

- (void)showSettings:(PSLayer *)layer from:(NSPoint)point
{
    [m_idPanel setVisible:YES];
    
    return;
    
	id contents = [m_idDocument contents];
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];
	m_nUnits = [m_idDocument measureStyle];
	
	// Set the layer title correctly
	if ([layer name]) {
		[m_idLayerTitle setStringValue:[layer name]];
		[m_idLayerTitle setEnabled:YES];
	}
	else {
		[m_idLayerTitle setStringValue:LOCALSTR(@"floating", @"Floating Selection")];
		[m_idLayerTitle setEnabled:NO];
	}
	
	[m_idLeftValue setStringValue:StringFromPixels([layer xoff],m_nUnits,xres)];
	[m_idTopValue setStringValue:StringFromPixels([layer yoff], m_nUnits, yres)];
	[m_idWidthValue setStringValue:StringFromPixels([layer width],m_nUnits,xres)];
	[m_idHeightValue setStringValue:StringFromPixels([layer height],m_nUnits, yres)];	
	[m_idLeftUnits setTitle:UnitsString(m_nUnits)];
	[m_idTopUnits setTitle:UnitsString(m_nUnits)];	
	[m_idWidthUnits setTitle:UnitsString(m_nUnits)];
	[m_idHeightUnits setTitle:UnitsString(m_nUnits)];
	
	[m_idChannelEditingMatrix selectCellAtRow:[[m_idDocument contents] selectedChannel] column:0];

	if([layer hasAlpha]){
		[[m_idChannelEditingMatrix cellAtRow:1 column:0] setEnabled:YES];
		[[m_idChannelEditingMatrix cellAtRow:2 column:0] setEnabled:YES];
	}else {
		[[m_idChannelEditingMatrix cellAtRow:1 column:0] setEnabled:NO];
		[[m_idChannelEditingMatrix cellAtRow:2 column:0] setEnabled:NO];
	}

	
	if (m_idDocument && layer)
    {
		
		// Set the opacity correctly
		if ([layer floating]) {
			[m_idOpacitySlider setIntValue:[layer opacity]];
			[m_idOpacitySlider setEnabled:NO];
			[m_idOpacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[layer opacity] / 2.55]];
		}
		else {
			[m_idOpacitySlider setIntValue:[layer opacity]];
			[m_idOpacitySlider setEnabled:YES];
			[m_idOpacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[layer opacity] / 2.55]];
		}
		
		// Set the mode correctly
		if ([layer floating]) {
			[m_idModePopup selectItemAtIndex:[m_idModePopup indexOfItemWithTag:[layer mode]]];
			[m_idModePopup setEnabled:NO];
		}
		else {
			[m_idModePopup selectItemAtIndex:[m_idModePopup indexOfItemWithTag:[layer mode]]];
			[m_idModePopup setEnabled:YES];
		}
		
		[m_idLinkedCheckbox setEnabled: YES];
		[m_idLinkedCheckbox setState:[layer linked]];

		[m_idAlphaEnabledCheckbox setEnabled: [layer canToggleAlpha]];
		[m_idAlphaEnabledCheckbox setState:[layer hasAlpha]];
	}
    else
    {
		// Turn off the opacity
		[m_idOpacitySlider setIntValue:255];
		[m_idOpacitySlider setEnabled:NO];
		[m_idOpacityLabel setStringValue:@"100.0%"];
		
		// Turn off the mode
		[m_idModePopup selectItemAtIndex:0];
		[m_idModePopup setEnabled:NO];
		
		[m_idLinkedCheckbox setEnabled:NO];
		[m_idAlphaEnabledCheckbox setEnabled:NO];
	}
	
	// Display layer settings panel
	[m_idPanel orderFrontToGoal:point onWindow: [m_idDocument window]];
	
	m_pslSettingsLayer = layer;
	[NSApp runModalForWindow:m_idPanel];
}

- (IBAction)apply:(id)sender
{
	id contents = [m_idDocument contents];
	PSLayer* layer = m_pslSettingsLayer;
	int newLeftValue, newTopValue;
	float xres, yres;
	
	// Get the resolutions
	xres = [contents xres];
	yres = [contents yres];

	// Parse width and height	
	newLeftValue = PixelsFromFloat([m_idLeftValue floatValue],m_nUnits, xres);
	newTopValue = PixelsFromFloat([m_idTopValue floatValue],m_nUnits,yres);
	
	if ([layer xoff] != newLeftValue || [layer yoff] != newTopValue)
		[self setOffsetsLeft:newLeftValue top:newTopValue index:[layer index]];
	
	// Change the layer's name
	if ([layer name]) {
		if (![[m_idLayerTitle stringValue] isEqualToString:[layer name]])
			[self setName:[NSString stringWithString:[m_idLayerTitle stringValue]] index:[layer index]];
	}
	
	// End the panel
	[NSApp stopModal];
	[[m_idDocument window] removeChildWindow:m_idPanel];
	[m_idPanel orderOut:self];

	m_pslSettingsLayer = nil;
}

- (IBAction)cancel:(id)sender
{
	m_pslSettingsLayer = nil;
	[NSApp stopModal];
	[[m_idDocument window] removeChildWindow:m_idPanel];
	[m_idPanel orderOut:self];
}

- (void)setOffsetsLeft:(int)left top:(int)top index:(int)index
{
	PSLayer* layer;
	IntPoint oldOffsets;
	
	// Correct the index
	if (index == kActiveLayer)
		index = [[m_idDocument contents] activeLayerIndex];
	layer = [[m_idDocument contents] layer:index];
	
	// Allow the undo/redo
	oldOffsets = IntMakePoint([layer xoff], [layer yoff]);
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] setOffsetsLeft:oldOffsets.x top:oldOffsets.y index:index];
	
	// Change the offsets
	[layer setOffsets:IntMakePoint(left, top)];
	
	// Update as required
	[[m_idDocument helpers] layerOffsetsChanged:index from:oldOffsets];
}

- (void)setName:(NSString *)newName index:(int)index
{
	PSLayer* layer;
	
	// Correct the index
	if (index == kActiveLayer)
		index = [[m_idDocument contents] activeLayerIndex];
	layer = [[m_idDocument contents] layer:index];
	
	// Allow the undo/redo
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] setName:[layer name] index:index];
	
	// Change the name
	[layer setName:newName];
	
	// Update the view
	[[m_idDocument helpers] layerTitleChanged];
}

- (IBAction)changeMode:(id)sender
{
	PSLayer* layer = m_pslSettingsLayer;
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMode:[layer index] to:[layer mode]];
	[layer setMode:[[m_idModePopup selectedItem] tag]];
	[[m_idDocument helpers] layerAttributesChanged:kActiveLayer hold:YES];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (void)undoMode:(int)index to:(int)value
{
	PSLayer* layer = [[m_idDocument contents] layer:index];
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMode:index to:[layer mode]];
	[layer setMode:value];
	//[[m_idDocument contents] setActiveLayerIndex:index];
	[[m_idDocument helpers] layerAttributesChanged:index hold:NO];
    
    [[m_idDocument docView] resetSynthesizedImageRender];
}

- (IBAction)changeOpacity:(id)sender
{
	PSLayer* layer = m_pslSettingsLayer;
	
    if ([[NSApp currentEvent] type] == NSLeftMouseDown){
		[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOpacity:[layer index] to:[layer opacity]];
        NSLog(@"[layer opacity] %d",[layer opacity]);
    }
	if ([layer width] * [layer height] < kMaxPixelsForLiveUpdate || [[NSApp currentEvent] type] == NSLeftMouseUp) {
		[layer setOpacity:[m_idOpacitySlider intValue]];
		[[m_idDocument helpers] layerAttributesChanged:kActiveLayer hold:YES];
        
        [[m_idDocument docView] resetSynthesizedImageRender];
	}
	[m_idOpacityLabel setStringValue:[NSString stringWithFormat:@"%.1f%%", (float)[m_idOpacitySlider intValue] / 2.55]];
}

- (void)undoOpacity:(int)index to:(int)value
{
	PSLayer* layer = [[m_idDocument contents] layer:index];
	
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOpacity:index to:[layer opacity]];
	[layer setOpacity:value];
	//[[m_idDocument contents] setActiveLayerIndex:index];
	[[m_idDocument helpers] layerAttributesChanged:index hold:NO];
    [[m_idDocument docView] resetSynthesizedImageRender];
}


- (IBAction)changeLinked:(id)sender
{
	[[m_idDocument contents] setLinked:[m_idLinkedCheckbox state] forLayer: [m_pslSettingsLayer index]];
	[m_idLinkedCheckbox setState:[m_pslSettingsLayer linked]];
}

- (IBAction)changeEnabledAlpha:(id)sender
{
	PSLayer* layer = m_pslSettingsLayer;

	if([layer canToggleAlpha]){
		[layer toggleAlpha];
	}
	[m_idAlphaEnabledCheckbox setState: [layer hasAlpha]];
}



- (IBAction)changeChannelEditing:(id)sender
{
	[[m_idDocument contents] setSelectedChannel:[m_idChannelEditingMatrix selectedRow]];
	[[m_idDocument helpers] channelChanged];
}

//普通混合模式(normal blend mode) 正片叠底混合模式(MutiplyBlend Mode) 屏幕混合模式(ScreenBlend Mode) 叠加混合模式(OverlayBlend Mode) 暗化混合模式(Darken BlendMode) 亮化混合模式(LightenBlend Mode) 色彩减淡模式(ColorDodge Blend Mode)  色彩加深模式(ColorBurn Blend Mode) 柔光混合模式(SoftLight Blend Mode) 强光混合模式(Hard Light Blend Mode) 差值混合模式(DifferenceBlend Mode) 排除混合模式(ExclusionBlend Mode) 色相混合模式(Hue BlendMode) 饱和度混合模式(Saturation Blend Mode) 颜色混合模式(Color Blend Mode) 亮度混合模式(LuminosityBlend Mode)
//add by lcz
- (IBAction)changeModeFromOut:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoMode:[layer index] to:[layer mode]];
    [layer setMode:[[m_idModePopupOut selectedItem] tag]];
    [[m_idDocument helpers] layerAttributesChanged:kActiveLayer hold:YES];
    [[m_idDocument docView] resetSynthesizedImageRender];

}

- (IBAction)changeLinkedFromOut:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    
    [[m_idDocument contents] setLinked:[m_idLinkedCheckboxOut state] forLayer: [layer index]];
    [m_idLinkedCheckboxOut setState:[layer linked]];
}

- (IBAction)changeEnabledAlphaFromOut:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    
    if([layer canToggleAlpha]){
        [layer toggleAlpha];
    }
    [m_idAlphaEnabledCheckboxOut setState: [layer hasAlpha]];
}

- (void)changeLayerOpacity:(int)nOpacity
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    
    if ([[NSApp currentEvent] type] == NSLeftMouseDown || [[NSApp currentEvent] type] == NSKeyDown)
        [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoOpacity:[layer index] to:[layer opacity]];
    if ([layer width] * [layer height] < kMaxPixelsForLiveUpdate || [[NSApp currentEvent] type] == NSLeftMouseUp || [[NSApp currentEvent] type] == NSKeyDown) {
        [layer setOpacity:nOpacity];
        [[m_idDocument helpers] layerAttributesChanged:kActiveLayer hold:YES];
        [[m_idDocument docView] resetSynthesizedImageRender];
    }
}

- (void)changeLayerSettingsAfterUpdateActiveLayer
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    
    if (m_idDocument && layer)
    {
        
        // Set the opacity correctly
        [m_myComboxOpacity setStringValue:[NSString stringWithFormat:@"%.0f%%",(float)[layer opacity] / 2.55]];
        
        // Set the mode correctly
        if ([layer floating]) {
//            [m_idModePopupOut selectItemAtIndex:[layer mode]];
            [m_idModePopupOut selectItemWithTag:[layer mode]];
            [m_idModePopupOut setEnabled:NO];
        }
        else {
//            [m_idModePopupOut selectItemAtIndex:[layer mode]];
            [m_idModePopupOut selectItemWithTag:[layer mode]];
            [m_idModePopupOut setEnabled:YES];
        }
        
        [m_idLinkedCheckboxOut setEnabled: YES];
        [m_idLinkedCheckboxOut setState:[layer linked]];
        
        [m_idAlphaEnabledCheckboxOut setEnabled: [layer canToggleAlpha]];
        [m_idAlphaEnabledCheckboxOut setState:[layer hasAlpha]];
        
        [self updateEffectUI];
    }
    else
    {
        // Turn off the opacity
        [m_myComboxOpacity setStringValue:@"100.0%"];
        
        // Turn off the mode
        [m_idModePopupOut selectItemAtIndex:0];
        [m_idModePopupOut setEnabled:NO];
        
        [m_idLinkedCheckboxOut setEnabled:NO];
        [m_idAlphaEnabledCheckboxOut setEnabled:NO];
    }

}

- (IBAction)changeEffect:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    int nTag = [btn tag];
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    
    [filterManager filtersEditWillBegin];
    
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    if(nTag == 101)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    }
    else if(nTag == 102)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillEnable" UTF8String]];
    }
    else if(nTag == 103)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    }
    else if(nTag == 104)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
    }
    else if(nTag == 105)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowEnable" UTF8String]];
    }
    [layer refreshTotalToRender];
    
    //[filterManager filtersEditDidEnd];
    
    
    [(EffectUtility *)[[PSController utilitiesManager] effectUtilityFor :m_idDocument] update];
    [(EffectUtility *)[[PSController utilitiesManager] effectUtilityFor :m_idDocument] selectRow:nTag - 101];
    [(PSSmartFilterUtility *)[[PSController utilitiesManager] smartFilterUtilityFor :m_idDocument] update];
    [(EffectUtility *)[[PSController utilitiesManager] effectUtilityFor :m_idDocument] runWindow];
    
}



-(void)updateEffectUI
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    int filterIndex = [[layer getSmartFilterManager] getSmartFiltersCount] - 2;
    
    PARAMETER_VALUE value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillEnable" UTF8String]];
    [m_btnEffectFill setState:value.nIntValue];
    
    value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    [m_btnEffectStroke setState:value.nIntValue];
    
    value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    [m_btnEffectOuterGlow setState:value.nIntValue];
    
    value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
    [m_btnEffectInnerGlow setState:value.nIntValue];
    
    value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowEnable" UTF8String]];
    [m_btnEffectShadow setState:value.nIntValue];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myComboxOpacity)
    {
        [m_myComboxOpacity setStringValue:[NSString stringWithFormat:@"%.0f%%",sValue.floatValue]];
        
        [self changeLayerOpacity:(int)([sValue floatValue] * 2.55)];
    }
}

@end
