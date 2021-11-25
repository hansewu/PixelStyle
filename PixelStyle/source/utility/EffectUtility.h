//
//  EffectUtility.h
//  PixelStyle
//
//  Created by wyl on 15/11/8.
//
//

#import "AbstractPanelUtility.h"
@class PSEffectColorWell;
@class PSGradientWindow;
@class PSGradientButton;

@interface EffectUtility : NSObject<NSTableViewDataSource,NSTableViewDelegate, NSTextFieldDelegate>
{
    // The document that owns the utility
    IBOutlet id m_idDocument;
    
    IBOutlet id m_idPanel;
    // The actual view that is the status bar
    IBOutlet id m_idView;
    
    
    IBOutlet NSTableView *m_tableView;
    NSTableView *m_tableViewEffectType;
    
    IBOutlet NSView *m_viewFill;
    IBOutlet NSView *m_viewStroke;
    IBOutlet NSView *m_viewOuterGlow;
    IBOutlet NSView *m_viewInnerGlow;
    IBOutlet NSView *m_viewShadow;
    
    //fill
    IBOutlet NSPopUpButton *m_popBtnFillBlendMode;
    IBOutlet NSPopUpButton *m_popBtnFillColorStyle;
    
    IBOutlet PSEffectColorWell *m_cwFillColor;
    IBOutlet NSSlider *m_sliderFillOpacity;
    IBOutlet NSTextField *m_textFieldFillOpacity;
    IBOutlet PSGradientButton *m_btnFillGradient;
    
    IBOutlet NSView *m_viewFillGradientInfo;
    IBOutlet NSPopUpButton *m_popBtnFillGradientStyle;
    IBOutlet NSSlider *m_sliderFillGradientAngle;
    IBOutlet NSTextField *m_textFieldFillGradientAngle;
    IBOutlet NSSlider *m_sliderFillGradientScaleRatio;
    IBOutlet NSTextField *m_textFieldFillGradientScaleRatio;
    
    
    //stroke
    IBOutlet NSPopUpButton *m_popBtnStrokeBlendMode;
    IBOutlet NSPopUpButton *m_popBtnStrokeColorStyle;
    IBOutlet PSEffectColorWell *m_cwStrokeColor;
    IBOutlet PSGradientButton *m_btnStrokeGradient;
    IBOutlet NSPopUpButton *m_popBtnStrokePos;
    IBOutlet NSSlider *m_sliderStrokeOpacity;
    IBOutlet NSTextField *m_textFieldStrokeOpacity;
    IBOutlet NSSlider *m_sliderStrokeSize;
    IBOutlet NSTextField *m_textFieldStrokeSize;
    
    IBOutlet NSView *m_viewStrokeGradientInfo;
    IBOutlet NSPopUpButton *m_popBtnStrokeGradientStyle;
    IBOutlet NSSlider *m_sliderStrokeGradientAngle;
    IBOutlet NSTextField *m_textFieldStrokeGradientAngle;
    IBOutlet NSTextField *m_titleStrokeGradientAngle;
    IBOutlet NSTextField *m_labelStrokeGradientAngle;
    
    IBOutlet NSSlider *m_sliderStrokeGradientScaleRatio;
    IBOutlet NSTextField *m_textFieldStrokeGradientScaleRatio;
    IBOutlet NSTextField *m_titleStrokeGradientScaleRatio;
    IBOutlet NSTextField *m_labelStrokeGradientScaleRatio;
    
    
    
    //innner glow
    IBOutlet NSPopUpButton *m_popBtnInnerGlowBlendMode;
    IBOutlet NSPopUpButton *m_popBtnInnerGlowColorStyle;
    IBOutlet PSEffectColorWell *m_cwInnerGlowColor;
    IBOutlet NSSlider *m_sliderInnerGlowOpacity;
    IBOutlet NSTextField *m_textFieldInnerGlowOpacity;
    IBOutlet NSSlider *m_sliderInnerGlowSize;
    IBOutlet NSTextField *m_textFieldInnerGlowSize;
    IBOutlet PSGradientButton *m_btnInnerGlowGradient;
    
    
    //outer glow
    IBOutlet NSPopUpButton *m_popBtnOuterGlowBlendMode;
    IBOutlet NSPopUpButton *m_popBtnOuterGlowColorStyle;
    IBOutlet PSEffectColorWell *m_cwOuterGlowColor;
    IBOutlet NSSlider *m_sliderOuterGlowOpacity;
    IBOutlet NSTextField *m_textFieldOuterGlowOpacity;
    IBOutlet NSSlider *m_sliderOuterGlowSize;
    IBOutlet NSTextField *m_textFieldOuterGlowSize;
    IBOutlet PSGradientButton *m_btnOuterGlowGradient;
    
    
    //shadow
    IBOutlet NSPopUpButton *m_popBtnShadowBlendMode;
    IBOutlet PSEffectColorWell *m_cwShadowColor;
    IBOutlet NSSlider *m_sliderShadowOpacity;
    IBOutlet NSTextField *m_textFieldShadowOpacity;
    IBOutlet NSSlider *m_sliderShadowAngel;
    IBOutlet NSTextField *m_textFieldShadowAngel;
    IBOutlet NSSlider *m_sliderShadowDistance;
    IBOutlet NSTextField *m_textFieldShadowDistance;
    IBOutlet NSSlider *m_sliderShadowSize;
    IBOutlet NSTextField *m_textFieldShadowSize;
    
    IBOutlet NSTextField *m_labelFillBlend;
    IBOutlet NSTextField *m_labelFillColor;
    IBOutlet NSTextField *m_labelFillOpacity;
    
    IBOutlet NSTextField *m_labelStrokeBlend;
    IBOutlet NSTextField *m_labelStrokeColor;
    IBOutlet NSTextField *m_labelStrokeOpacity;
    IBOutlet NSTextField *m_labelStrokePos;
    IBOutlet NSTextField *m_labelStrokeSize;
    
    IBOutlet NSTextField *m_labelInnerGlowBlend;
    IBOutlet NSTextField *m_labelInnerGlowColor;
    IBOutlet NSTextField *m_labelInnerGlowOpacity;
    IBOutlet NSTextField *m_labelInnerGlowSize;
    
    IBOutlet NSTextField *m_labelOuterGlowBlend;
    IBOutlet NSTextField *m_labelOuterGlowColor;
    IBOutlet NSTextField *m_labelOuterGlowOpacity;
    IBOutlet NSTextField *m_labelOuterGlowSize;
    
    IBOutlet NSTextField *m_labelShadowColor;
    IBOutlet NSTextField *m_labelShadowOpacity;
    IBOutlet NSTextField *m_labelShadowSize;
    IBOutlet NSTextField *m_labelShadowAngle;
    IBOutlet NSTextField *m_labelShadowDistance;
    
    
    IBOutlet NSTextField *m_labelFillGradientStyle;
    IBOutlet NSTextField *m_labelFillGradientAngle;
    IBOutlet NSTextField *m_labelFillGradientScale;
    
    IBOutlet NSTextField *m_labelStrokeGradientStyle;
    
    IBOutlet PSGradientWindow *m_windowGradient;
    IBOutlet NSButton    *m_btnOK;
    IBOutlet NSButton    *m_btnCancel;
}

- (void)selectRow:(int)row;
- (void)update;
- (void)runWindow;

#pragma mark - Actions
-(IBAction)onCancel:(id)sender;
-(IBAction)onApply:(id)sender;

-(IBAction)onFillOpacity:(id)sender;

-(IBAction)onStrokePos:(id)sender;
-(IBAction)onStrokeOpacity:(id)sender;
-(IBAction)onStrokeSize:(id)sender;

-(IBAction)onOuterGlowOpacity:(id)sender;
-(IBAction)onOuterGlowSize:(id)sender;

-(IBAction)onInnerGlowOpacity:(id)sender;
-(IBAction)onInnerGlowSize:(id)sender;

-(IBAction)onShadowOpacity:(id)sender;
-(IBAction)onShadowAngel:(id)sender;
-(IBAction)onShadowDistance:(id)sender;
-(IBAction)onShadowSize:(id)sender;

@end
