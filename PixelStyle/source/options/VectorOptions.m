#import "AppKit/AppKit.h"
#import "VectorOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSPrefs.h"
#import "PSProxy.h"
#import "VectorTool.h"
#import "PSDocument.h"
#import "PSFontPanel.h"
#import "WDFontManager.h"

id gNewFont;



@implementation VectorOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    m_nShapeMode = 0;
    
    m_nPolygonNumPoints = 5;
    
    m_fRectCornerRadius = 0.;
    
    // star support
    m_nStarNumPoints = 5;
    m_fStarInnerRadiusRatio = 0.5;
    m_fStarLastRadius = 0.0;
    m_nSpiralDecay = 80.0;

}

- (void)dealloc
{
    [m_colorFontFill release];
    
    [super dealloc];
}


#pragma mark - Actions
-(IBAction)onBtnShapeMode:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    m_nShapeMode = btn.tag - 100;
    
    [self resumeTypeButtonImage];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"shape-%d-a",m_nShapeMode]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"shape-%d-a",m_nShapeMode]]];
}

-(void)resumeTypeButtonImage
{
    NSButton *btn;
    
    for(int i = 0; i < 6; i++)
    {
        btn = [m_idView viewWithTag:100 + i];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"shape-%d",i]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"shape-%d",i]]];
    }
    
}

- (void)setShapeMode:(int)nShapeMode
{
    m_nShapeMode = nShapeMode;
}

- (int)shapeMode
{
    return m_nShapeMode;
}

- (void)setPolygonNumPoints:(int)nPolygonNumPoints
{
    m_nPolygonNumPoints = nPolygonNumPoints;
}

- (int)polygonNumPoints
{
    return m_nPolygonNumPoints;
}

- (void)setStarNumPoints:(int)nStarNumPoints
{
    m_nStarNumPoints = nStarNumPoints;
}

- (int)starNumPoints
{
    return m_nStarNumPoints;
}

- (void)setStarInnerRadiusRatio:(float)fStarInnerRadiusRatio
{
    m_fStarInnerRadiusRatio = fStarInnerRadiusRatio;
}

- (float)starInnerRadiusRatio
{
    return m_fStarInnerRadiusRatio;
}

- (void)setStarLastRadius:(float)fStarLastRadius
{
    m_fStarLastRadius = fStarLastRadius;
}

- (float)starLastRadius
{
    return m_fStarLastRadius;
}


- (void)setRectCornerRadius:(float)fRectCornerRadius
{
    m_fRectCornerRadius = fRectCornerRadius;
}

- (float)rectCornerRadius
{
    return m_fRectCornerRadius;
}

- (void)setSpiralDecay:(int)nSpiralDecay
{
    m_nSpiralDecay = nSpiralDecay;
}

- (int)spiralDecay
{
    return m_nSpiralDecay;
}

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
    [(VectorTool *)[[m_idDocument tools] getTool:kVectorTool] shutDown];
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
        
        [(VectorTool *)[[m_idDocument tools] getTool:kVectorTool] changeCharacterSpacing:(int)(int)sValue.floatValue];
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

@end
