//
//  ShapeOptions.m
//  PixelStyle
//
//  Created by wyl on 16/2/23.
//
//

#import "ShapeOptions.h"
#import "PSDocument.h"
#import "PSTools.h"
#import "ShapeTool.h"

#import "WDUtilities.h"

@implementation ShapeOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    m_nStarNumPoints                      = 8;
    
    // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    m_fStarInnerRadiusRatio = 0.5;//[defaults floatForKey:WDShapeToolStarInnerRadiusRatio];
    m_fStarInnerRadiusRatio = WDClamp(0.05, 2.0, m_fStarInnerRadiusRatio);
    
    m_nStarNumPoints = (int) 5;//[defaults integerForKey:WDShapeToolStarPointCount];
    m_nPolygonNumPoints = (int) 5;//[defaults integerForKey:WDShapeToolPolygonSideCount];
    m_fRectCornerRadius = 0;//[defaults floatForKey:WDShapeToolRectCornerRadius];
    m_nSpiralDecay = 80.0;//[defaults floatForKey:WDShapeToolSpiralDecay];
    
    m_nShapeMode = PSShapeRectangle;
    
    //[self performSelector:@selector(initView) withObject:nil afterDelay:.05];
    [self initView];
}

-(void)initView
{
    [m_myCustomComBoxToolOptions setDelegate:self];
    
    [self setShapeMode:PSShapeRectangle];
    
    
    NSButton *btn = [m_idView viewWithTag:100 + 0];
    [btn setToolTip:NSLocalizedString(@"Rectangle", nil)];
    btn = [m_idView viewWithTag:100 + 1];
    [btn setToolTip:NSLocalizedString(@"Ellipse", nil)];
    btn = [m_idView viewWithTag:100 + 2];
    [btn setToolTip:NSLocalizedString(@"Star", nil)];
    btn = [m_idView viewWithTag:100 + 3];
    [btn setToolTip:NSLocalizedString(@"Polygon", nil)];
    btn = [m_idView viewWithTag:100 + 4];
    [btn setToolTip:NSLocalizedString(@"Line", nil)];
    btn = [m_idView viewWithTag:100 + 5];
    [btn setToolTip:NSLocalizedString(@"Clockwise spiral", nil)];
}

#pragma mark - Actions
-(IBAction)onBtnShapeMode:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    m_nShapeMode = btn.tag - 100;
    
    [self resumeTypeButtonImage];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"shape-%d-a",m_nShapeMode]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"shape-%d-a",m_nShapeMode]]];
    
    [self changeToolOptionsUI];
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

-(void)changeToolOptionsUI
{
    if(m_nShapeMode == PSShapeOval || (m_nShapeMode == PSShapeLine))
        [self hideToolOptionsUI:YES];
    else
        [self hideToolOptionsUI:NO];
    
    if(m_nShapeMode == PSShapeLine)
    {
        [m_btnArrow setEnabled:YES];
        [m_btnArrow2 setEnabled:YES];
    }
    else
    {
        [m_btnArrow setEnabled:NO];
        [m_btnArrow2 setEnabled:NO];
    }
    
    int nSliderMinValue = 0;
    int nSliderMaxValue = 0;
    
    if (m_nShapeMode == PSShapeRectangle)
    {
        nSliderMinValue = 0;
        nSliderMaxValue = 100;
        [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d pt",(int)m_fRectCornerRadius]];
        [m_myCustomComBoxToolOptions setToolTip:NSLocalizedString(@"Set the fillet radius", nil)];
        [m_textFieldToolOptions setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Corner Radius", nil)]];
    }
    else if (m_nShapeMode == PSShapePolygon)
    {
        nSliderMinValue = 3;
        nSliderMaxValue = 20;
        [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d",(int)m_nPolygonNumPoints]];
        [m_myCustomComBoxToolOptions setToolTip:NSLocalizedString(@"Set the number of sides", nil)];
        [m_textFieldToolOptions setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Number of Sides", nil)]];
    }
    else if  (m_nShapeMode == PSShapeStar)
    {
        nSliderMinValue = 3;
        nSliderMaxValue = 50;
        [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d",(int)m_nStarNumPoints]];
        [m_myCustomComBoxToolOptions setToolTip:NSLocalizedString(@"Set the number of points", nil)];
        [m_textFieldToolOptions setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Number of Points", nil)]];
    }
    else if  (m_nShapeMode == PSShapeSpiral)
    {
        nSliderMinValue = 10;
        nSliderMaxValue = 99;
        
        [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d %%",(int)m_nSpiralDecay]];
        [m_myCustomComBoxToolOptions setToolTip:NSLocalizedString(@"Set the decay", nil)];
        [m_textFieldToolOptions setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Decay", nil)]];
    }
    
    [m_myCustomComBoxToolOptions setSliderMaxValue:nSliderMaxValue];
    [m_myCustomComBoxToolOptions setSliderMinValue:nSliderMinValue];
}

-(void)hideToolOptionsUI:(BOOL)bHide
{
    [m_textFieldToolOptions setHidden:bHide];
    [m_myCustomComBoxToolOptions setHidden:bHide];
}


#pragma mark - properties
- (void)setShapeMode:(int)nShapeMode
{
    NSButton *btn = [self.view viewWithTag:100 + nShapeMode];
    [self onBtnShapeMode:btn];
    
    m_nShapeMode = nShapeMode;
}

- (int)shapeMode
{
    return m_nShapeMode;
}

- (void)setPolygonNumPoints:(int)nPolygonNumPoints
{
    m_nPolygonNumPoints = nPolygonNumPoints;
    
    [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d",m_nPolygonNumPoints]];
    
}

- (int)polygonNumPoints
{
    return m_nPolygonNumPoints;
}

- (void)setStarNumPoints:(int)nStarNumPoints
{
    m_nStarNumPoints = nStarNumPoints;
    
    [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d",m_nStarNumPoints]];
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

- (void)setRectCornerRadius:(float)fRectCornerRadius
{
    m_fRectCornerRadius = fRectCornerRadius;
    
    [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d pt",(int)m_fRectCornerRadius]];
}

- (float)rectCornerRadius
{
    return m_fRectCornerRadius;
}

- (void)setSpiralDecay:(int)nSpiralDecay
{
    m_nSpiralDecay = nSpiralDecay;
    
    [m_myCustomComBoxToolOptions setStringValue:[NSString stringWithFormat:@"%d %%",m_nSpiralDecay]];
}

- (int)spiralDecay
{
    return m_nSpiralDecay;
}


- (void)shutdown
{
   [super shutdown];
}

#pragma mark - MyCustomCombo Delegate -
-(void)valueDidChange:(MyCustomComboBox *)customComboBox value:(NSString *)sValue
{
    if (customComboBox == m_myCustomComBoxToolOptions)
    {
        if (m_nShapeMode == PSShapeRectangle)
        {
            [self setRectCornerRadius:sValue.floatValue];
        }
        else if (m_nShapeMode == PSShapePolygon)
        {
            [self setPolygonNumPoints:sValue.intValue];
        }
        else if  (m_nShapeMode == PSShapeStar)
        {
            [self setStarNumPoints:sValue.intValue];
        }
        else if  (m_nShapeMode == PSShapeSpiral)
        {
            [self setSpiralDecay:sValue.intValue];
        }
        
        [(ShapeTool *)[[m_idDocument tools] getTool:kShapeTool] updatePath];
    }
}

@end





