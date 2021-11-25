//
//  EffectUtility.m
//  PixelStyle
//
//  Created by wyl on 15/11/8.
//
//

#import "EffectUtility.h"
#import "PSLayerEffect.h"
#import "PSContent.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PegasusUtility.h"
#import "LayerSettings.h"
#import "PSLayer.h"
#import "MyTableRowView.h"
#import "ConfigureInfo.h"

#import "PSSmartFilterManager.h"
#import "PSEffectColorWell.h"

#import "PSGradientWindow.h"
#import "PSGradientButton.h"

#define EFFECT_COUNT 5
#define BTN_EFFECT_FILL_TAG 102
#define BTN_EFFECT_STROKE_TAG 101
#define BTN_EFFECT_OUTER_GOLOW_TAG 103
#define BTN_EFFECT_INNER_GLOW_TAG 104
#define BTN_EFFECT_SHADOW_TAG 105

@implementation EffectUtility

-(void)awakeFromNib
{
    [m_idPanel setTitle:NSLocalizedString(@"Layer Effects", nil)];
    [m_btnOK setTitle:NSLocalizedString(@"OK", nil)];
    [m_btnCancel setTitle:NSLocalizedString(@"Cancel", nil)];
    
    [m_labelFillBlend setStringValue:NSLocalizedString(@"Blend Mode :", nil)];
    [m_labelStrokeBlend setStringValue:NSLocalizedString(@"Blend Mode :", nil)];
    [m_labelInnerGlowBlend setStringValue:NSLocalizedString(@"Blend Mode :", nil)];
    [m_labelOuterGlowBlend setStringValue:NSLocalizedString(@"Blend Mode :", nil)];
    
    [m_labelFillColor setStringValue:NSLocalizedString(@"Color :", nil)];
    [m_labelStrokeColor setStringValue:NSLocalizedString(@"Color :", nil)];
    [m_labelInnerGlowColor setStringValue:NSLocalizedString(@"Color :", nil)];
    [m_labelOuterGlowColor setStringValue:NSLocalizedString(@"Color :", nil)];
    [m_labelShadowColor setStringValue:NSLocalizedString(@"Color :", nil)];
    
    
    [m_labelFillOpacity setStringValue:NSLocalizedString(@"Opacity :", nil)];
    [m_labelStrokeOpacity setStringValue:NSLocalizedString(@"Opacity :", nil)];
    [m_labelInnerGlowOpacity setStringValue:NSLocalizedString(@"Opacity :", nil)];
    [m_labelOuterGlowOpacity setStringValue:NSLocalizedString(@"Opacity :", nil)];
    [m_labelShadowOpacity setStringValue:NSLocalizedString(@"Opacity :", nil)];
    
    [m_labelStrokeSize setStringValue:NSLocalizedString(@"Size :", nil)];
    [m_labelInnerGlowSize setStringValue:NSLocalizedString(@"Size :", nil)];
    [m_labelOuterGlowSize setStringValue:NSLocalizedString(@"Size :", nil)];
    [m_labelShadowSize setStringValue:NSLocalizedString(@"Size :", nil)];
    
    [m_labelStrokePos setStringValue:NSLocalizedString(@"Position :", nil)];
    
    [m_labelShadowAngle setStringValue:NSLocalizedString(@"Angle :", nil)];
    [m_labelShadowDistance setStringValue:NSLocalizedString(@"Distance :", nil)];
    
    [[m_popBtnStrokePos itemAtIndex:0] setTitle:NSLocalizedString(@"Outer", nil)];
    [[m_popBtnStrokePos itemAtIndex:1] setTitle:NSLocalizedString(@"Central", nil)];
    [[m_popBtnStrokePos itemAtIndex:2] setTitle:NSLocalizedString(@"Inner", nil)];
    
    
    [[m_popBtnStrokeColorStyle itemAtIndex:0] setTitle:NSLocalizedString(@"Color", nil)];
    [[m_popBtnStrokeColorStyle itemAtIndex:1] setTitle:NSLocalizedString(@"Gradient", nil)];
    [[m_popBtnStrokeGradientStyle itemAtIndex:0] setTitle:NSLocalizedString(@"Linear", nil)];
    [[m_popBtnStrokeGradientStyle itemAtIndex:1] setTitle:NSLocalizedString(@"Radial", nil)];
    [[m_popBtnStrokeGradientStyle itemAtIndex:2] setTitle:NSLocalizedString(@"Shape Burst", nil)];
    
    [[m_popBtnFillColorStyle itemAtIndex:0] setTitle:NSLocalizedString(@"Color", nil)];
    [[m_popBtnFillColorStyle itemAtIndex:1] setTitle:NSLocalizedString(@"Gradient", nil)];
    [[m_popBtnFillGradientStyle itemAtIndex:0] setTitle:NSLocalizedString(@"Linear", nil)];
    [[m_popBtnFillGradientStyle itemAtIndex:1] setTitle:NSLocalizedString(@"Radial", nil)];

    
    [m_labelFillGradientStyle setStringValue:NSLocalizedString(@"Style :", nil)];
    [m_labelFillGradientAngle setStringValue:NSLocalizedString(@"Angle :", nil)];
    [m_labelFillGradientScale setStringValue:NSLocalizedString(@"Scale :", nil)];
    [m_labelStrokeGradientStyle setStringValue:NSLocalizedString(@"Style :", nil)];
    [m_titleStrokeGradientAngle setStringValue:NSLocalizedString(@"Angle :", nil)];
    [m_titleStrokeGradientScaleRatio setStringValue:NSLocalizedString(@"Scale :", nil)];
    
    
    [[m_popBtnOuterGlowColorStyle itemAtIndex:0] setTitle:NSLocalizedString(@"Color", nil)];
    [[m_popBtnOuterGlowColorStyle itemAtIndex:1] setTitle:NSLocalizedString(@"Gradient", nil)];
    
    [[m_popBtnInnerGlowColorStyle itemAtIndex:0] setTitle:NSLocalizedString(@"Color", nil)];
    [[m_popBtnInnerGlowColorStyle itemAtIndex:1] setTitle:NSLocalizedString(@"Gradient", nil)];
    
    NSArray *blendModes = [NSArray arrayWithObjects:NSLocalizedString(@"Normal", nil), NSLocalizedString(@"Multiply", nil), NSLocalizedString(@"Lighten", nil), NSLocalizedString(@"Darken", nil), NSLocalizedString(@"Source In", nil), nil];
    
    for (int  i = 0; i < [blendModes count]; i++) {
        [[m_popBtnStrokeBlendMode itemAtIndex:i] setTitle:[blendModes objectAtIndex:i]];
        [[m_popBtnFillBlendMode itemAtIndex:i] setTitle:[blendModes objectAtIndex:i]];
        [[m_popBtnOuterGlowBlendMode itemAtIndex:i] setTitle:[blendModes objectAtIndex:i]];
        [[m_popBtnInnerGlowBlendMode itemAtIndex:i] setTitle:[blendModes objectAtIndex:i]];
        [[m_popBtnShadowBlendMode itemAtIndex:i] setTitle:[blendModes objectAtIndex:i]];
        
    }
    
    
    [[PSController utilitiesManager] setEffectUtility:self  for:m_idDocument];
    
    [m_tableView setBackgroundColor:[NSColor clearColor]];
    [m_tableView setAllowsEmptySelection:NO];
    
    [m_windowGradient setGradientDelegate:self];
    [m_viewFillGradientInfo setHidden:YES];
}

- (void)runWindow
{
//    [[m_idDocument window] addChildWindow:m_idPanel ordered:NSWindowAbove];
//    [m_idPanel makeKeyAndOrderFront:nil];
    [NSApp runModalForWindow:m_idPanel];
    
}

#pragma mark - effect Action - Fill

-(IBAction)onFillBlendMode:(id)sender
{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillBlendMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}

-(IBAction)onFillOpacity:(id)sender
{
    [m_textFieldFillOpacity setIntValue:m_sliderFillOpacity.intValue];
    
    float fOpacity = m_sliderFillOpacity.intValue / 100.0;
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = fOpacity;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillColorAlpha" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onFillColorStyle:(id)sender
{
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    if (nSelectedIndex == 0) {
        [m_cwFillColor setHidden:NO];
        [m_btnFillGradient setHidden:YES];
        [m_viewFillGradientInfo setHidden:YES];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillColor" UTF8String]];
        NSColor *color = [self makeNSColorFromColorValue:value];
        [m_cwFillColor changeUIColor:color];
        
    }else if (nSelectedIndex == 1){
        [m_cwFillColor setHidden:YES];
        [m_btnFillGradient setHidden:NO];
        [m_viewFillGradientInfo setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientColorAlpha" UTF8String]];
        m_btnFillGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientStyle" UTF8String]];
        [m_popBtnFillGradientStyle selectItemAtIndex:value.nIntValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientAngle" UTF8String]];
        [m_sliderFillGradientAngle setFloatValue:value.fFloatValue];
        [m_textFieldFillGradientAngle setIntValue:m_sliderFillGradientAngle.intValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientScaleRatio" UTF8String]];
        [m_sliderFillGradientScaleRatio setFloatValue:value.fFloatValue];
        [m_textFieldFillGradientScaleRatio setIntValue:m_sliderFillGradientScaleRatio.floatValue * 100.0];
        
    }
    
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillColorMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}

-(IBAction)onFillGradientStyle:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillGradientStyle" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
}

-(IBAction)onFillGradientAngle:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    [m_textFieldFillGradientAngle setIntValue:m_sliderFillGradientAngle.floatValue];
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderFillGradientAngle.floatValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillGradientAngle" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onFillGradientScaleRatio:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    [m_textFieldFillGradientScaleRatio setIntValue:m_sliderFillGradientScaleRatio.floatValue * 100.0];
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderFillGradientScaleRatio.floatValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillGradientScaleRatio" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

#pragma mark - effect Action - Stroke

-(IBAction)onStrokeBlendMode:(id)sender
{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeBlendMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}

-(IBAction)onStrokePos:(id)sender
{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokePosition" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}

-(IBAction)onStrokeOpacity:(id)sender
{
    [m_textFieldStrokeOpacity setIntValue:m_sliderStrokeOpacity.intValue];
    float fOpacity = m_sliderStrokeOpacity.intValue / 100.0;
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = fOpacity;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeColorAlpha" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onStrokeSize:(id)sender
{
    
    [m_textFieldStrokeSize setIntValue:m_sliderStrokeSize.intValue];
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderStrokeSize.intValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeSize" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onStrokeColorStyle:(id)sender
{
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    if (nSelectedIndex == 0) {
        [m_cwStrokeColor setHidden:NO];
        [m_btnStrokeGradient setHidden:YES];
        [m_viewStrokeGradientInfo setHidden:YES];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeColor" UTF8String]];
        NSColor *color = [self makeNSColorFromColorValue:value];
        [m_cwStrokeColor changeUIColor:color];
        
    }else if (nSelectedIndex == 1){
        [m_cwStrokeColor setHidden:YES];
        [m_btnStrokeGradient setHidden:NO];
        [m_viewStrokeGradientInfo setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientColorAlpha" UTF8String]];
        m_btnStrokeGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientStyle" UTF8String]];
        [m_popBtnStrokeGradientStyle selectItemAtIndex:value.nIntValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientAngle" UTF8String]];
        [m_sliderStrokeGradientAngle setFloatValue:value.fFloatValue];
        [m_textFieldStrokeGradientAngle setIntValue:m_sliderStrokeGradientAngle.intValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientScaleRatio" UTF8String]];
        [m_sliderStrokeGradientScaleRatio setFloatValue:value.fFloatValue];
        [m_textFieldStrokeGradientScaleRatio setIntValue:m_sliderStrokeGradientScaleRatio.floatValue * 100.0];
        
    }
    
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeColorMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}

- (void)setGradientAngleInfoHidden:(BOOL)isHidden
{
    [m_sliderStrokeGradientAngle setHidden:isHidden];
    [m_textFieldStrokeGradientAngle setHidden:isHidden];
    [m_titleStrokeGradientAngle setHidden:isHidden];
    [m_labelStrokeGradientAngle setHidden:isHidden];
    [m_sliderStrokeGradientScaleRatio setHidden:isHidden];
    [m_textFieldStrokeGradientScaleRatio setHidden:isHidden];
    [m_titleStrokeGradientScaleRatio setHidden:isHidden];
    [m_labelStrokeGradientScaleRatio setHidden:isHidden];
}

-(IBAction)onStrokeGradientStyle:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    
    if (nSelectedIndex == 2) {
        [self setGradientAngleInfoHidden:YES];
    }else{
        [self setGradientAngleInfoHidden:NO];
    }
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeGradientStyle" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
}

-(IBAction)onStrokeGradientAngle:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    [m_textFieldStrokeGradientAngle setIntValue:m_sliderStrokeGradientAngle.floatValue];
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderStrokeGradientAngle.floatValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeGradientAngle" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onStrokeGradientScaleRatio:(id)sender
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    [m_textFieldStrokeGradientScaleRatio setIntValue:m_sliderStrokeGradientScaleRatio.floatValue * 100.0];
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderStrokeGradientScaleRatio.floatValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeGradientScaleRatio" UTF8String]];
    
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

#pragma mark - effect Action - Outer Glow

-(IBAction)onOuterGlowBlendMode:(id)sender
{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowBlendMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}


-(IBAction)onOuterGlowColorStyle:(id)sender
{
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    if (nSelectedIndex == 0) {
        [m_cwOuterGlowColor setHidden:NO];
        [m_btnOuterGlowGradient setHidden:YES];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowColor" UTF8String]];
        NSColor* color = [self makeNSColorFromColorValue:value];
        [m_cwOuterGlowColor changeUIColor:color];
        
    }else if (nSelectedIndex == 1){
        [m_cwOuterGlowColor setHidden:YES];
        [m_btnOuterGlowGradient setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowGradientColorAlpha" UTF8String]];
        m_btnOuterGlowGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
    }
    
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowColorMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}


-(IBAction)onOuterGlowOpacity:(id)sender
{
    [m_textFieldOuterGlowOpacity setIntValue:m_sliderOuterGlowOpacity.intValue];
    float fOpacity = m_sliderOuterGlowOpacity.intValue / 100.0;
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = fOpacity;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowColorAlpha" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onOuterGlowSize:(id)sender
{
    [m_textFieldOuterGlowSize setIntValue:m_sliderOuterGlowSize.intValue];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderOuterGlowSize.intValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowSize" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

#pragma mark - effect Action - Inner Glow

-(IBAction)onInnerGlowBlendMode:(id)sender
{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowBlendMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}


-(IBAction)onInnerGlowColorStyle:(id)sender
{
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    if (nSelectedIndex == 0) {
        [m_cwInnerGlowColor setHidden:NO];
        [m_btnInnerGlowGradient setHidden:YES];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowColor" UTF8String]];
        NSColor* color = [self makeNSColorFromColorValue:value];
        [m_cwInnerGlowColor changeUIColor:color];
        
    }else if (nSelectedIndex == 1){
        [m_cwInnerGlowColor setHidden:YES];
        [m_btnInnerGlowGradient setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowGradientColorAlpha" UTF8String]];
        m_btnInnerGlowGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
    }
    
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowColorMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}


-(IBAction)onInnerGlowOpacity:(id)sender
{
    [m_textFieldInnerGlowOpacity setIntValue:m_sliderInnerGlowOpacity.intValue];
    float fOpacity = m_sliderInnerGlowOpacity.intValue / 100.0;
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = fOpacity;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowColorAlpha" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onInnerGlowSize:(id)sender
{
    [m_textFieldInnerGlowSize setIntValue:m_sliderInnerGlowSize.intValue];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderInnerGlowSize.intValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowSize" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}


#pragma mark - effect Action - Shadow

-(IBAction)onShadowBlendMode:(id)sender
{
    NSPopUpButton *btn = (NSPopUpButton *)sender;
    int nSelectedIndex = [btn indexOfSelectedItem];
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.nIntValue = nSelectedIndex;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowBlendMode" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    
}

-(IBAction)onShadowOpacity:(id)sender
{
    [m_textFieldShadowOpacity setIntValue:m_sliderShadowOpacity.intValue];

    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderShadowOpacity.intValue / 100.0;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowColorAlpha" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onShadowAngel:(id)sender
{
    [m_textFieldShadowAngel setIntValue:m_sliderShadowAngel.intValue];

    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderShadowAngel.intValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowLightAngle" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onShadowDistance:(id)sender
{
    [m_textFieldShadowDistance setIntValue:m_sliderShadowDistance.intValue];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderShadowDistance.intValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowDistance" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

-(IBAction)onShadowSize:(id)sender
{
    [m_textFieldShadowSize setIntValue:m_sliderShadowSize.intValue];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    PARAMETER_VALUE value;
    value.fFloatValue = m_sliderShadowSize.intValue;
    [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowBlur" UTF8String]];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
}

#pragma mark - Gradient Event

-(IBAction)onGradientButton:(id)sender
{
    GRADIENT_COLOR gradientColor;
    gradientColor.colorInfo[0] = 0;
    gradientColor.colorAlphaInfo[0] = 0;
    
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    
    int nIndex = [m_tableView selectedRow];
    if (nIndex == 0)
    {
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientColorAlpha" UTF8String]];
        gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
    }
    else if (nIndex == 1)
    {
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientColorAlpha" UTF8String]];
        gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
        
    }
    else if (nIndex == 2)
    {
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowGradientColorAlpha" UTF8String]];
        gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
    }
    else if (nIndex == 3)
    {
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowGradientColorAlpha" UTF8String]];
        gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
    }
    else if (nIndex == 4)
    {
        
    }
    
    [m_windowGradient setGradientColor:gradientColor];
    
    [gColorPanel close];
    [gColorPanel setShowsAlpha:YES];
    
    //[m_windowGradient makeKeyAndOrderFront:nil];
    //[m_windowGradient orderFrontRegardless];
    //[m_windowGradient orderWindow:NSWindowAbove relativeTo:0];
    [NSApp runModalForWindow:m_windowGradient];
    
    
    
    
}


-(IBAction)onGradientOK:(id)sender
{
    [NSApp stopModal];
    [m_windowGradient orderOut:nil];
    
    //[m_windowGradient orderOut:nil];
}

#pragma mark - Apply & Cancel
-(IBAction)onApply:(id)sender
{
    [NSApp stopModal];
    [m_idPanel orderOut:self];
    
    [[[[m_idDocument contents] activeLayer] getSmartFilterManager] filtersEditDidEnd];
    
    [gColorPanel close];
}

-(IBAction)onCancel:(id)sender
{
    [NSApp stopModal];
    [m_idPanel orderOut:self];
    
    [[[[m_idDocument contents] activeLayer] getSmartFilterManager] filtersEditDidCancel];
    [[[m_idDocument contents] activeLayer] refreshTotalToRender];
    
    [gColorPanel close];
}

#pragma mark -
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

- (void)selectRow:(int)row
{
    [m_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void)update
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    //set max min
    FILTER_PARAMETER_INFO paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"strokeSize" UTF8String]];
    [m_sliderStrokeSize setMaxValue:paraInfo.maxValue.fFloatValue];
    paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"outerGlowSize" UTF8String]];
    [m_sliderOuterGlowSize setMaxValue:paraInfo.maxValue.fFloatValue];
    paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"innerGlowSize" UTF8String]];
    [m_sliderInnerGlowSize setMaxValue:paraInfo.maxValue.fFloatValue];
    paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"shadowDistance" UTF8String]];
    [m_sliderShadowDistance setMaxValue:paraInfo.maxValue.fFloatValue];
    paraInfo = [filterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"shadowBlur" UTF8String]];
    [m_sliderShadowSize setMaxValue:paraInfo.maxValue.fFloatValue];
    
    //set current value
    PARAMETER_VALUE value;
    NSColor *color = NULL;
    
    //fill
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillBlendMode" UTF8String]];
    [m_popBtnFillBlendMode selectItemAtIndex:value.nIntValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillColorMode" UTF8String]];
    [m_popBtnFillColorStyle selectItemAtIndex:value.nIntValue];
    
    if (value.nIntValue == 0) {
        [m_cwFillColor setHidden:NO];
        [m_btnFillGradient setHidden:YES];
        [m_viewFillGradientInfo setHidden:YES];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillColor" UTF8String]];
        color = [self makeNSColorFromColorValue:value];
        [m_cwFillColor changeUIColor:color];
        
    }else if (value.nIntValue == 1){
        [m_cwFillColor setHidden:YES];
        [m_btnFillGradient setHidden:NO];
        [m_viewFillGradientInfo setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientColorAlpha" UTF8String]];
        m_btnFillGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientStyle" UTF8String]];
        [m_popBtnFillGradientStyle selectItemAtIndex:value.nIntValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientAngle" UTF8String]];
        [m_sliderFillGradientAngle setFloatValue:value.fFloatValue];
        [m_textFieldFillGradientAngle setIntValue:m_sliderFillGradientAngle.intValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillGradientScaleRatio" UTF8String]];
        [m_sliderFillGradientScaleRatio setFloatValue:value.fFloatValue];
        [m_textFieldFillGradientScaleRatio setIntValue:m_sliderFillGradientScaleRatio.floatValue * 100.0];

        
    }
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillColorAlpha" UTF8String]];
    [m_sliderFillOpacity setIntValue:value.fFloatValue * 100];
    [m_textFieldFillOpacity setIntValue:m_sliderFillOpacity.intValue];
    
    
    
    
    // stroke
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeBlendMode" UTF8String]];
    [m_popBtnStrokeBlendMode selectItemAtIndex:value.nIntValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeColorMode" UTF8String]];
    [m_popBtnStrokeColorStyle selectItemAtIndex:value.nIntValue];
    if (value.nIntValue == 0) {
        [m_cwStrokeColor setHidden:NO];
        [m_btnStrokeGradient setHidden:YES];
        [m_viewStrokeGradientInfo setHidden:YES];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeColor" UTF8String]];
        NSColor *color = [self makeNSColorFromColorValue:value];
        [m_cwStrokeColor changeUIColor:color];
        
    }else if (value.nIntValue == 1){
        [m_cwStrokeColor setHidden:YES];
        [m_btnStrokeGradient setHidden:NO];
        [m_viewStrokeGradientInfo setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientColorAlpha" UTF8String]];
        m_btnStrokeGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientStyle" UTF8String]];
        [m_popBtnStrokeGradientStyle selectItemAtIndex:value.nIntValue];
        if (value.nIntValue == 2) {
            [self setGradientAngleInfoHidden:YES];
        }else{
            [self setGradientAngleInfoHidden:NO];
        }
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientAngle" UTF8String]];
        [m_sliderStrokeGradientAngle setFloatValue:value.fFloatValue];
        [m_textFieldStrokeGradientAngle setIntValue:m_sliderStrokeGradientAngle.intValue];
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeGradientScaleRatio" UTF8String]];
        [m_sliderStrokeGradientScaleRatio setFloatValue:value.fFloatValue];
        [m_textFieldStrokeGradientScaleRatio setIntValue:m_sliderStrokeGradientScaleRatio.floatValue * 100.0];
        
    }
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokePosition" UTF8String]];
    [m_popBtnStrokePos selectItemAtIndex:value.nIntValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeColorAlpha" UTF8String]];
    [m_sliderStrokeOpacity setIntValue:value.fFloatValue * 100];
    [m_textFieldStrokeOpacity setIntValue:m_sliderStrokeOpacity.intValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeSize" UTF8String]];
    [m_sliderStrokeSize setIntValue:value.fFloatValue];
    [m_textFieldStrokeSize setIntValue:m_sliderStrokeSize.intValue];
   
    
    // outer glow
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowBlendMode" UTF8String]];
    [m_popBtnOuterGlowBlendMode selectItemAtIndex:value.nIntValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowColorMode" UTF8String]];
    [m_popBtnOuterGlowColorStyle selectItemAtIndex:value.nIntValue];
    
    if (value.nIntValue == 0) {
        [m_cwOuterGlowColor setHidden:NO];
        [m_btnOuterGlowGradient setHidden:YES];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowColor" UTF8String]];
        color = [self makeNSColorFromColorValue:value];
        [m_cwOuterGlowColor changeUIColor:color];
        
    }else if (value.nIntValue == 1){
        [m_cwOuterGlowColor setHidden:YES];
        [m_btnOuterGlowGradient setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowGradientColorAlpha" UTF8String]];
        m_btnOuterGlowGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
    }
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowColorAlpha" UTF8String]];
    [m_sliderOuterGlowOpacity setIntValue:value.fFloatValue * 100];
    [m_textFieldOuterGlowOpacity setIntValue:m_sliderOuterGlowOpacity.intValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowSize" UTF8String]];
    [m_sliderOuterGlowSize setIntValue:value.fFloatValue];
    [m_textFieldOuterGlowSize setIntValue:m_sliderOuterGlowSize.intValue];
    
    
    
    // inner glow
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowBlendMode" UTF8String]];
    [m_popBtnInnerGlowBlendMode selectItemAtIndex:value.nIntValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowColorMode" UTF8String]];
    [m_popBtnInnerGlowColorStyle selectItemAtIndex:value.nIntValue];
    
    if (value.nIntValue == 0) {
        [m_cwInnerGlowColor setHidden:NO];
        [m_btnInnerGlowGradient setHidden:YES];
        
        value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowColor" UTF8String]];
        color = [self makeNSColorFromColorValue:value];
        [m_cwInnerGlowColor changeUIColor:color];
        
    }else if (value.nIntValue == 1){
        [m_cwInnerGlowColor setHidden:YES];
        [m_btnInnerGlowGradient setHidden:NO];
        
        PARAMETER_VALUE value1 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowGradientColor" UTF8String]];
        PARAMETER_VALUE value2 = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowGradientColorAlpha" UTF8String]];
        m_btnInnerGlowGradient.gradientColor = [self makeGradientColorFromColorValue:value1 alphaValue:value2];
    }
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowColorAlpha" UTF8String]];
    [m_sliderInnerGlowOpacity setIntValue:value.fFloatValue * 100];
    [m_textFieldInnerGlowOpacity setIntValue:m_sliderInnerGlowOpacity.intValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowSize" UTF8String]];
    [m_sliderInnerGlowSize setIntValue:value.fFloatValue];
    [m_textFieldInnerGlowSize setIntValue:m_sliderInnerGlowSize.intValue];
    
    
  
    //shadow
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowBlendMode" UTF8String]];
    [m_popBtnShadowBlendMode selectItemAtIndex:value.nIntValue];
    
    value = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowColor" UTF8String]];
    color = [self makeNSColorFromColorValue:value];
    [m_cwShadowColor changeUIColor:color];
    
    float fOpacity = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowColorAlpha" UTF8String]].fFloatValue;
    float nAngle = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowLightAngle" UTF8String]].fFloatValue;
    float fDistance = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowDistance" UTF8String]].fFloatValue;
    float fBlur = [filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowBlur" UTF8String]].fFloatValue;
    [m_sliderShadowOpacity setIntValue:fOpacity*100];
    [m_textFieldShadowOpacity setIntValue:fOpacity*100];
    [m_sliderShadowAngel setIntValue:nAngle];
    [m_textFieldShadowAngel setIntValue:nAngle];
    [m_sliderShadowDistance setIntValue:fDistance];
    [m_textFieldShadowDistance setIntValue:fDistance];
    [m_sliderShadowSize setIntValue:fBlur];
    [m_textFieldShadowSize setIntValue:fBlur];
    
    [m_tableView reloadData];
    
    
//    [m_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}



- (PARAMETER_VALUE)makeColorValueFromNSColor:(NSColor *)color
{
    PARAMETER_VALUE value;
    int red = color.redComponent * 255;
    int green = color.greenComponent * 255;
    int blue = color.blueComponent * 255;
    value.nUnsignedValue = ( red| (green<<8) | (blue<<16) );
    return value;
}

- (NSColor*)makeNSColorFromColorValue:(PARAMETER_VALUE)value
{
    unsigned int nUnsignedValue = value.nUnsignedValue;
    int red = nUnsignedValue & 0xFF;
    int green = (nUnsignedValue >> 8) & 0xFF;
    int blue = nUnsignedValue >> 16;
    return [NSColor colorWithCalibratedRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0];
}

- (GRADIENT_COLOR)makeGradientColorFromColorValue:(PARAMETER_VALUE)colorValue alphaValue:(PARAMETER_VALUE)alphaValue
{
    GRADIENT_COLOR gradientColor;
    memcpy(gradientColor.colorInfo, colorValue.fFloatArray, 100 * sizeof(float));
    memcpy(gradientColor.colorAlphaInfo, alphaValue.fFloatArray, 50 * sizeof(float));
    return gradientColor;
}

- (PARAMETER_VALUE)getColorValueFromGradientColor:(GRADIENT_COLOR)gradientColor
{
    PARAMETER_VALUE colorValue;
    memcpy(colorValue.fFloatArray, gradientColor.colorInfo, 100 * sizeof(float));
    return colorValue;
}

- (PARAMETER_VALUE)getColorAlphaValueFromGradientColor:(GRADIENT_COLOR)gradientColor
{
    PARAMETER_VALUE alphaValue;
    memcpy(alphaValue.fFloatArray, gradientColor.colorAlphaInfo, 50 * sizeof(float));
    return alphaValue;
}


- (void)setColor:(NSColor *)color
{
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    int filterIndex = [[layer getSmartFilterManager] getSmartFiltersCount] - 2;
    
    int nIndex = [m_tableView selectedRow];
    if (nIndex == 0)
    {
        PARAMETER_VALUE value = [self makeColorValueFromNSColor:color];
        [[layer getSmartFilterManager] setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeColor" UTF8String]];
        
    }
    else if (nIndex == 1)
    {
        PARAMETER_VALUE value = [self makeColorValueFromNSColor:color];
        [[layer getSmartFilterManager] setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillColor" UTF8String]];
    }
    else if (nIndex == 2)
    {
        PARAMETER_VALUE value = [self makeColorValueFromNSColor:color];
        [[layer getSmartFilterManager] setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowColor" UTF8String]];
    }
    else if (nIndex == 3)
    {
        PARAMETER_VALUE value = [self makeColorValueFromNSColor:color];
        [[layer getSmartFilterManager] setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowColor" UTF8String]];
    }
    else if (nIndex == 4)
    {
        PARAMETER_VALUE value = [self makeColorValueFromNSColor:color];
        [[layer getSmartFilterManager] setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowColor" UTF8String]];
    }
    
    [layer refreshTotalToRender];
}


- (void)gradientColorChanged:(GRADIENT_COLOR)gradientColor
{
    
    PSLayer* layer = [[m_idDocument contents] activeLayer];
    PSSmartFilterManager *filterManager = [layer getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    
    int nIndex = [m_tableView selectedRow];
    if (nIndex == 0)
    {
        m_btnStrokeGradient.gradientColor = gradientColor;
        PARAMETER_VALUE colorValue = [self getColorValueFromGradientColor:gradientColor];
        PARAMETER_VALUE alphaValue = [self getColorAlphaValueFromGradientColor:gradientColor];
        
        [[layer getSmartFilterManager] setSmartFilterParameter:colorValue filterIndex:filterIndex parameterName:[@"strokeGradientColor" UTF8String]];
        [[layer getSmartFilterManager] setSmartFilterParameter:alphaValue filterIndex:filterIndex parameterName:[@"strokeGradientColorAlpha" UTF8String]];
    }
    else if (nIndex == 1)
    {
        m_btnFillGradient.gradientColor = gradientColor;
        PARAMETER_VALUE colorValue = [self getColorValueFromGradientColor:gradientColor];
        PARAMETER_VALUE alphaValue = [self getColorAlphaValueFromGradientColor:gradientColor];
        
        [[layer getSmartFilterManager] setSmartFilterParameter:colorValue filterIndex:filterIndex parameterName:[@"fillGradientColor" UTF8String]];
        [[layer getSmartFilterManager] setSmartFilterParameter:alphaValue filterIndex:filterIndex parameterName:[@"fillGradientColorAlpha" UTF8String]];
        
        
    }
    else if (nIndex == 2)
    {
        m_btnOuterGlowGradient.gradientColor = gradientColor;
        PARAMETER_VALUE colorValue = [self getColorValueFromGradientColor:gradientColor];
        PARAMETER_VALUE alphaValue = [self getColorAlphaValueFromGradientColor:gradientColor];
        
        [[layer getSmartFilterManager] setSmartFilterParameter:colorValue filterIndex:filterIndex parameterName:[@"outerGlowGradientColor" UTF8String]];
        [[layer getSmartFilterManager] setSmartFilterParameter:alphaValue filterIndex:filterIndex parameterName:[@"outerGlowGradientColorAlpha" UTF8String]];
        
    }
    else if (nIndex == 3)
    {
        m_btnInnerGlowGradient.gradientColor = gradientColor;
        PARAMETER_VALUE colorValue = [self getColorValueFromGradientColor:gradientColor];
        PARAMETER_VALUE alphaValue = [self getColorAlphaValueFromGradientColor:gradientColor];
        
        [[layer getSmartFilterManager] setSmartFilterParameter:colorValue filterIndex:filterIndex parameterName:[@"innerGlowGradientColor" UTF8String]];
        [[layer getSmartFilterManager] setSmartFilterParameter:alphaValue filterIndex:filterIndex parameterName:[@"innerGlowGradientColorAlpha" UTF8String]];
        
    }
    else if (nIndex == 4)
    {
        
    }
    [layer refreshTotalToRender];

}


#pragma mark - NSTableView DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 5;
}

#pragma mark - NSTableView delegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 40;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    // Make the row view keep track of our main model object
    MyTableRowView *result = [[MyTableRowView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, tableView.rowHeight)];
    result.bDrawSperateLine = NO;
    return [result autorelease];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSRect rect = NSMakeRect(0, 0, [tableColumn width], [tableView rowHeight]);
    NSView *view  = [[[NSView alloc] initWithFrame:rect] autorelease];
    if ([tableColumn.identifier isEqualToString:@"effect_type"])
    {
        //PSLayerEffect *pLayerEffect = [[[m_idDocument contents] activeLayer] getLayerEffect];
        
        PSLayer* layer = [[m_idDocument contents] activeLayer];
        int filterIndex = [[layer getSmartFilterManager] getSmartFiltersCount] - 2;
        
        BOOL bEnable;
        int nTag;
        NSString *sTitle;
        if(row == 0)
        {
            PARAMETER_VALUE value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeEnable" UTF8String]];
            bEnable = value.nIntValue;
            nTag = BTN_EFFECT_STROKE_TAG;
            sTitle = NSLocalizedString(@"Stroke", nil);
            
        }
        else if (row == 1)
        {
            PARAMETER_VALUE value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillEnable" UTF8String]];
            bEnable = value.nIntValue;
            nTag = BTN_EFFECT_FILL_TAG;
            sTitle = NSLocalizedString(@"Fill", nil);
        }
        else if (row == 2)
        {
            PARAMETER_VALUE value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
            bEnable = value.nIntValue;
            nTag = BTN_EFFECT_OUTER_GOLOW_TAG;
            sTitle = NSLocalizedString(@"Outer Glow", nil);
        }
        else if (row == 3)
        {
            PARAMETER_VALUE value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
            bEnable = value.nIntValue;
            nTag = BTN_EFFECT_INNER_GLOW_TAG;
            sTitle = NSLocalizedString(@"Inner Glow", nil);
        }
        else
        {
            PARAMETER_VALUE value = [[layer getSmartFilterManager] getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowEnable" UTF8String]];
            bEnable = value.nIntValue;
            nTag = BTN_EFFECT_SHADOW_TAG;
            sTitle = NSLocalizedString(@"Shadow", nil);
        }
        
        NSButton *btn= [[[NSButton alloc] initWithFrame:NSMakeRect(rect.origin.x + 10, 12, 15, 15)] autorelease];
        [btn setTitle:nil];
        [btn setTag:nTag];
        [btn setImagePosition:NSImageOnly];
        NSButtonCell *btnCell = (NSButtonCell *)btn.cell;
        [btnCell setBezelStyle:NSThickSquareBezelStyle];
        [btnCell setButtonType:NSSwitchButton];
        [btnCell setImageScaling:NSImageScaleAxesIndependently];
        [btn setImage:[NSImage imageNamed:@"checkbox-not"]];
        [btn setAlternateImage:[NSImage imageNamed:@"checkbox-selected"]];
        [btn setState:NSOffState];
        [btn setTarget:self];
        [btn setAction:@selector(changeEffectEnable:)];
        if(bEnable)
            [btn setState:NSOnState];
        [view addSubview:btn];
        
        NSTextField *sTitleLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(rect.origin.x + 30,12, 100, 15)] autorelease];
        [sTitleLabel setStringValue:sTitle];
        [sTitleLabel setBezeled:YES];
        [sTitleLabel setBordered:NO];
        [sTitleLabel setEditable:NO];
        [sTitleLabel setBackgroundColor:[NSColor clearColor]];
        [sTitleLabel setTextColor:[NSColor whiteColor]];
        [sTitleLabel setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
        [view addSubview:sTitleLabel];
    }
    
    return view;
}

#pragma mark - ***** Notifications ***** -
-(void)tableViewSelectionIsChanging:(NSNotification *)notification
{
    NSIndexSet * selectedRows = [m_tableView selectedRowIndexes];
    if([selectedRows count] < 1) return;
    
    [m_viewFill setHidden:YES];
    [m_viewShadow setHidden:YES];
    [m_viewStroke setHidden:YES];
    [m_viewOuterGlow setHidden:YES];
    [m_viewInnerGlow setHidden:YES];
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    
    NSUInteger idx = [selectedRows firstIndex];
    while (idx != NSNotFound)
    {
        if(idx == BTN_EFFECT_FILL_TAG - 101)
        {
            if (![filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"fillEnable" UTF8String]].nIntValue)
            {
                NSButton *btn = (NSButton *)[m_tableView viewWithTag:BTN_EFFECT_FILL_TAG];
                [btn setState:NSOnState];
                [self changeEffectEnable:btn];
            }
            
            [m_viewFill setHidden:NO];
        }
        else if(idx == BTN_EFFECT_STROKE_TAG - 101)
        {
            if (![filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"strokeEnable" UTF8String]].nIntValue)
            {
                NSButton *btn = (NSButton *)[m_tableView viewWithTag:BTN_EFFECT_STROKE_TAG];
                [btn setState:NSOnState];
                [self changeEffectEnable:btn];
            }
            [m_viewStroke setHidden:NO];
        }
        else if(idx == BTN_EFFECT_OUTER_GOLOW_TAG - 101)
        {
            if (![filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"outerGlowEnable" UTF8String]].nIntValue)
            {
                NSButton *btn = (NSButton *)[m_tableView viewWithTag:BTN_EFFECT_OUTER_GOLOW_TAG];
                [btn setState:NSOnState];
                [self changeEffectEnable:btn];
            }
            
            [m_viewOuterGlow setHidden:NO];
        }
        else if(idx == BTN_EFFECT_INNER_GLOW_TAG - 101)
        {
            if (![filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"innerGlowEnable" UTF8String]].nIntValue)
            {
                NSButton *btn = (NSButton *)[m_tableView viewWithTag:BTN_EFFECT_INNER_GLOW_TAG];
                [btn setState:NSOnState];
                [self changeEffectEnable:btn];
            }
            
            [m_viewInnerGlow setHidden:NO];
        }
        else if(idx == BTN_EFFECT_SHADOW_TAG - 101)
        {
            if (![filterManager getSmartFilterParameterForFilter:filterIndex parameterName:[@"shadowEnable" UTF8String]].nIntValue)
            {
                NSButton *btn = (NSButton *)[m_tableView viewWithTag:BTN_EFFECT_SHADOW_TAG];
                [btn setState:NSOnState];
                [self changeEffectEnable:btn];
            }
            
            [m_viewShadow setHidden:NO];
        }
        
        // get the next index in the set
        idx = [selectedRows indexGreaterThanIndex:idx];
    }
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSIndexSet * selectedRows = [m_tableView selectedRowIndexes];
    if([selectedRows count] < 1) return;
    
    [m_viewFill setHidden:YES];
    [m_viewShadow setHidden:YES];
    [m_viewStroke setHidden:YES];
    [m_viewOuterGlow setHidden:YES];
    [m_viewInnerGlow setHidden:YES];
     
    
    NSUInteger idx = [selectedRows firstIndex];
    while (idx != NSNotFound)
    {
        if(idx == BTN_EFFECT_FILL_TAG - 101)
        {
            [m_viewFill setHidden:NO];
        }
        else if(idx == BTN_EFFECT_STROKE_TAG - 101)
        {
            [m_viewStroke setHidden:NO];
        }
        else if(idx == BTN_EFFECT_OUTER_GOLOW_TAG - 101)
        {
            [m_viewOuterGlow setHidden:NO];
        }
        else if(idx == BTN_EFFECT_INNER_GLOW_TAG - 101)
        {
            [m_viewInnerGlow setHidden:NO];
        }
        else if(idx == BTN_EFFECT_SHADOW_TAG - 101)
        {
            [m_viewShadow setHidden:NO];
        }

        // get the next index in the set
        idx = [selectedRows indexGreaterThanIndex:idx];
    }
}


//add by lcz
-(void)changeEffectEnableNeedRefresh:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    int nTag = [btn tag];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    BOOL bEffect = [filterManager isHasEffect];
    
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    if(nTag == BTN_EFFECT_FILL_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_STROKE_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_OUTER_GOLOW_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_INNER_GLOW_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_SHADOW_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowEnable" UTF8String]];
    }
    
    [[[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] layerSettings] updateEffectUI];
    
    if(bEffect && [filterManager isHasEffect] == NO)
        [[[m_idDocument contents] activeLayer] refreshTotalToRenderDisableEffect];
    else
        [[[m_idDocument contents] activeLayer] refreshTotalToRenderForEffect];
}

-(void)changeEffectEnable:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    int nTag = [btn tag];
    
    PSSmartFilterManager *filterManager = [[[m_idDocument contents] activeLayer] getSmartFilterManager];
    BOOL bEffect = [filterManager isHasEffect];
    
    int filterIndex = [filterManager getSmartFiltersCount] - 2;
    if(nTag == BTN_EFFECT_FILL_TAG)
    {
        //[layerEffect setFillEnable:[btn state]];
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"fillEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_STROKE_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_OUTER_GOLOW_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_INNER_GLOW_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
    }
    else if(nTag == BTN_EFFECT_SHADOW_TAG)
    {
        PARAMETER_VALUE value;
        value.nIntValue = [btn state];
        [filterManager setSmartFilterParameter:value filterIndex:filterIndex parameterName:[@"shadowEnable" UTF8String]];
    }
    
    [[[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] layerSettings] updateEffectUI];
    
    if(bEffect && [filterManager isHasEffect] == NO)
        [[[m_idDocument contents] activeLayer] refreshTotalToRenderDisableEffect];
    else
        [[[m_idDocument contents] activeLayer] refreshTotalToRenderForEffect];
}


#pragma mark - textFied delegate -
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    int nValue = [textField intValue];
    

    if(textField == m_textFieldFillOpacity)
    {
        if(nValue < [(NSSlider *)m_sliderFillOpacity minValue]) nValue = [(NSSlider *)m_sliderFillOpacity minValue];
        else if (nValue > [(NSSlider *)m_sliderFillOpacity maxValue]) nValue = [(NSSlider *)m_sliderFillOpacity maxValue];
        
        [m_sliderFillOpacity setIntValue:nValue];
        [self onFillOpacity:m_sliderFillOpacity];
    }
    else if(textField == m_textFieldStrokeOpacity)
    {
        if(nValue < [(NSSlider *)m_sliderStrokeOpacity minValue]) nValue = [(NSSlider *)m_sliderStrokeOpacity minValue];
        else if (nValue > [(NSSlider *)m_sliderStrokeOpacity maxValue]) nValue = [(NSSlider *)m_sliderStrokeOpacity maxValue];
       
        [m_sliderStrokeOpacity setIntValue:nValue];
        [self onStrokeOpacity:m_sliderStrokeOpacity];
    }
    else if(textField == m_textFieldStrokeSize)
    {
        if(nValue < [(NSSlider *)m_sliderStrokeSize minValue]) nValue = [(NSSlider *)m_sliderStrokeSize minValue];
        else if (nValue > [(NSSlider *)m_sliderStrokeSize maxValue]) nValue = [(NSSlider *)m_sliderStrokeSize maxValue];
        
        [m_sliderStrokeSize setIntValue:nValue];
        [self onStrokeSize:m_sliderStrokeSize];
    }
    else if(textField == m_textFieldOuterGlowOpacity)
    {
        if(nValue < [(NSSlider *)m_sliderOuterGlowOpacity minValue]) nValue = [(NSSlider *)m_sliderOuterGlowOpacity minValue];
        else if (nValue > [(NSSlider *)m_sliderOuterGlowOpacity maxValue]) nValue = [(NSSlider *)m_sliderOuterGlowOpacity maxValue];
        
        [m_sliderOuterGlowOpacity setIntValue:nValue];
        [self onOuterGlowOpacity:m_sliderOuterGlowOpacity];
    }
    else if(textField == m_textFieldOuterGlowSize)
    {
        if(nValue < [(NSSlider *)m_sliderOuterGlowSize minValue]) nValue = [(NSSlider *)m_sliderOuterGlowSize minValue];
        else if (nValue > [(NSSlider *)m_sliderOuterGlowSize maxValue]) nValue = [(NSSlider *)m_sliderOuterGlowSize maxValue];
        
        [m_sliderOuterGlowSize setIntValue:nValue];
        [self onOuterGlowSize:m_sliderOuterGlowSize];
    }
    else if(textField == m_textFieldInnerGlowOpacity)
    {
        if(nValue < [(NSSlider *)m_sliderInnerGlowOpacity minValue]) nValue = [(NSSlider *)m_sliderInnerGlowOpacity minValue];
        else if (nValue > [(NSSlider *)m_sliderInnerGlowOpacity maxValue]) nValue = [(NSSlider *)m_sliderInnerGlowOpacity maxValue];
        
        [m_sliderInnerGlowOpacity setIntValue:nValue];
        [self onInnerGlowOpacity:m_sliderInnerGlowOpacity];
    }
    else if(textField == m_textFieldInnerGlowSize)
    {
        if(nValue < [(NSSlider *)m_sliderInnerGlowSize minValue]) nValue = [(NSSlider *)m_sliderInnerGlowSize minValue];
        else if (nValue > [(NSSlider *)m_sliderInnerGlowSize maxValue]) nValue = [(NSSlider *)m_sliderInnerGlowSize maxValue];
        
        [m_sliderInnerGlowSize setIntValue:nValue];
        [self onInnerGlowSize:m_sliderInnerGlowSize];
    }
    else if(textField == m_textFieldShadowOpacity)
    {
        if(nValue < [(NSSlider *)m_sliderShadowOpacity minValue]) nValue = [(NSSlider *)m_sliderShadowOpacity minValue];
        else if (nValue > [(NSSlider *)m_sliderShadowOpacity maxValue]) nValue = [(NSSlider *)m_sliderShadowOpacity maxValue];
        
        [m_sliderShadowOpacity setIntValue:nValue];
        [self onShadowOpacity:m_sliderShadowOpacity];
    }
    else if(textField == m_textFieldShadowAngel)
    {
        if(nValue < [(NSSlider *)m_sliderShadowAngel minValue]) nValue = [(NSSlider *)m_sliderShadowAngel minValue];
        else if (nValue > [(NSSlider *)m_sliderShadowAngel maxValue]) nValue = [(NSSlider *)m_sliderShadowAngel maxValue];
        
        [m_sliderShadowAngel setIntValue:nValue];
        
        [self onShadowAngel:m_sliderShadowAngel];
    }
    else if(textField == m_textFieldShadowDistance)
    {
        if(nValue < [(NSSlider *)m_sliderShadowDistance minValue]) nValue = [(NSSlider *)m_sliderShadowDistance minValue];
        else if (nValue > [(NSSlider *)m_sliderShadowDistance maxValue]) nValue = [(NSSlider *)m_sliderShadowDistance maxValue];
        
        [m_sliderShadowDistance setIntValue:nValue];
        [self onShadowDistance:m_sliderShadowDistance];
    }
    else if(textField == m_textFieldShadowSize)
    {
        if(nValue < [(NSSlider *)m_sliderShadowSize minValue]) nValue = [(NSSlider *)m_sliderShadowSize minValue];
        else if (nValue > [(NSSlider *)m_sliderShadowSize maxValue]) nValue = [(NSSlider *)m_sliderShadowSize maxValue];
        
        [m_sliderShadowSize setIntValue:nValue];
        [self onShadowSize:m_sliderShadowSize];
    }
    else if(textField == m_textFieldFillGradientAngle)
    {
        if(nValue < [(NSSlider *)m_sliderFillGradientAngle minValue]) nValue = [(NSSlider *)m_sliderFillGradientAngle minValue];
        else if (nValue > [(NSSlider *)m_sliderFillGradientAngle maxValue]) nValue = [(NSSlider *)m_sliderFillGradientAngle maxValue];
        
        [m_sliderFillGradientAngle setIntValue:nValue];
        [self onFillGradientAngle:m_sliderFillGradientAngle];
    }
    else if(textField == m_textFieldFillGradientScaleRatio)
    {
        if(nValue < [(NSSlider *)m_sliderFillGradientScaleRatio minValue]) nValue = [(NSSlider *)m_sliderFillGradientScaleRatio minValue];
        else if (nValue > [(NSSlider *)m_sliderFillGradientScaleRatio maxValue]) nValue = [(NSSlider *)m_sliderFillGradientScaleRatio maxValue];
        
        [m_sliderFillGradientScaleRatio setIntValue:nValue];
        [self onFillGradientScaleRatio:m_sliderFillGradientScaleRatio];
    }
    else if(textField == m_textFieldStrokeGradientAngle)
    {
        if(nValue < [(NSSlider *)m_sliderStrokeGradientAngle minValue]) nValue = [(NSSlider *)m_sliderStrokeGradientAngle minValue];
        else if (nValue > [(NSSlider *)m_sliderStrokeGradientAngle maxValue]) nValue = [(NSSlider *)m_sliderStrokeGradientAngle maxValue];
        
        [m_sliderStrokeGradientAngle setIntValue:nValue];
        [self onStrokeGradientAngle:m_sliderStrokeGradientAngle];
    }
    else if(textField == m_textFieldStrokeGradientScaleRatio)
    {
        if(nValue < [(NSSlider *)m_sliderStrokeGradientScaleRatio minValue]) nValue = [(NSSlider *)m_sliderStrokeGradientScaleRatio minValue];
        else if (nValue > [(NSSlider *)m_sliderStrokeGradientScaleRatio maxValue]) nValue = [(NSSlider *)m_sliderStrokeGradientScaleRatio maxValue];
        
        [m_sliderStrokeGradientScaleRatio setIntValue:nValue];
        [self onStrokeGradientScaleRatio:m_sliderStrokeGradientScaleRatio];
    }
    return YES;
}

@end
