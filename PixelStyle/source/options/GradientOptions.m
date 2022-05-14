#import "GradientOptions.h"
#import "PSController.h"
#import "PSTools.h"
#import "PSHelp.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSGradientButton.h"
#import "PSFillController.h"
#import "PSColorWell.h"

#import "WDGradient.h"
#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDUtilities.h"
#import "WDInspectableProperties.h"

@implementation GradientOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idGradientLinear setToolTip:NSLocalizedString(@"Linear gradient", nil)];
    [m_idGradientRadius setToolTip:NSLocalizedString(@"Radial gradient", nil)];
    [m_idGradientSymmetry setToolTip:NSLocalizedString(@"Reflected gradient", nil)];
    [m_idGradientDiamond setToolTip:NSLocalizedString(@"Diamond gradient", nil)];
    [m_idGradientCone setToolTip:NSLocalizedString(@"Conical gradient", nil)];
    [m_idGradientAngle setToolTip:NSLocalizedString(@"Angular gradient", nil)];
    [m_idGradientClockwiseSpiral setToolTip:NSLocalizedString(@"Clockwise spiral gradient", nil)];
    [m_idGradientCounterClockwiseSpiral setToolTip:NSLocalizedString(@"Counterclockwise spiral gradient", nil)];
    [m_idTypeTile setToolTip:NSLocalizedString(@"Set gradient with a tiled image", nil)];
    [m_idTypeSymmetryTile setToolTip:NSLocalizedString(@"Set gradient with a symmetrical tiling image", nil)];
    [m_btnLockGradients45 setToolTip:NSLocalizedString(@"Set the gradient direction", nil)];
    
    [m_labelOpacity setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Opacity", nil)]];
    [(NSButton *)m_idTypeTile setTitle:NSLocalizedString(@"Sawtooth Wave", nil)];
    [(NSButton *)m_idTypeSymmetryTile setTitle:NSLocalizedString(@"Triangular Wave", nil)];
    
    int index;
    
    if ([gUserDefaults objectForKey:@"gradient type"] == NULL) {
        [self onBtnGradientType:[m_idView viewWithTag:100 + 0]];
        //		[m_idTypePopup selectItemAtIndex:GIMP_GRADIENT_LINEAR];
    }
    else {
        index = [m_idTypePopup indexOfItemWithTag:[gUserDefaults integerForKey:@"gradient type"]];
		if (index != -1)
//			[m_idTypePopup selectItemAtIndex:index];
            [self onBtnGradientType:[m_idView viewWithTag:100 + index]];
		else
//			[m_idTypePopup selectItemAtIndex:0];
            [self onBtnGradientType:[m_idView viewWithTag:100 + 0]];
	}
	
	if ([gUserDefaults objectForKey:@"gradient repeat"] == NULL) {
//		[m_idRepeatPopup selectItemAtIndex:GIMP_REPEAT_NONE];
        [self onWaveType:[m_idView viewWithTag:200 + 0]];
	}
	else {
		index = [m_idRepeatPopup indexOfItemWithTag:[gUserDefaults integerForKey:@"gradient repeat"]];
		if (index != -1)
			[self onWaveType:[m_idView viewWithTag:200 + index]];
		else
			[self onWaveType:[m_idView viewWithTag:200 + 0]];
	}
    
    //[self performSelector:@selector(initViews) withObject:nil afterDelay:0.05];
    [self initViews];
}

-(void)initViews
{
    NSMutableArray *subviews = [[m_idView subviews] mutableCopy];
     for (NSView *view in subviews)
     {
         if(view.frame.origin.x > 50)
         {
             NSPoint originPoint = NSMakePoint(view.frame.origin.x+50, view.frame.origin.y);
             [view setFrameOrigin:originPoint];
         }
         
     }
    

    m_fillWell = [[PSColorWell alloc] initWithFrame:NSMakeRect(55, 10, 40, 18)];
    
    [m_fillWell setTarget:self];
    [m_idView addSubview:m_fillWell];
    

    
    WDGradient *gradient = [WDGradient defaultGradient];
    [m_fillWell setPainter:gradient];
    
    [m_fillWell setAction:@selector(handlePopBtn:)];
    
    [m_myCustomComboOpacity setDelegate:self];
    [m_myCustomComboOpacity setSliderMaxValue:100.0];
    [m_myCustomComboOpacity setSliderMinValue:0.0];
    [m_myCustomComboOpacity setStringValue:@"100.0%"];
    
    m_fillController = nil;
    

}

-(NSGradient *)gradient
{
    if([m_fillWell.painter isKindOfClass:[WDGradient class]])
    {
            WDGradient *wgradient = (WDGradient *)m_fillWell.painter;
            return [wgradient newNSGradient];
    }
    return nil;
}

-(void)activate:(id)sender
{
    [super activate:sender];
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    
    if([[propertyManager activeFillStyle] isKindOfClass:[WDGradient class]])
        [m_fillWell setPainter:[propertyManager activeFillStyle]];
    
    if(!m_fillController)
        m_fillController = [[PSFillController alloc] initWithWindowNibName:@"Fill"];
    
    if(!m_fillController.drawingController)
    {
        PSContent *contents = (PSContent *)[m_idDocument contents];
        m_fillController.drawingController = [contents wdDrawingController];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(invalidProperties:)
                                                     name:@"PSFillGradientChanged"
                                                   object:m_fillController];
    }

}

- (void)handlePopBtn:(NSPopUpButton *)popBtn
{
    NSWindow *w = [m_idDocument window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
        
    [m_fillController showGradientPanelFrom: p onWindow: w];
}

- (void) invalidProperties:(NSNotification *)aNotification
{
    WDGradient *wGradient = [aNotification userInfo][@"gradient"];
    
    [m_fillWell setPainter:wGradient];
   /* if ([properties containsObject:WDFillProperty])
    {
        id<WDPathPainter> fill = [m_fillController.drawingController.propertyManager defaultValueForProperty:WDFillProperty];
        [m_fillWell setPainter:fill];
    }*/
}

- (GRADIENT_COLOR)makeGradientColorFromGradient:(NSGradient *)gradient
{
    int count = [gradient numberOfColorStops];
    GRADIENT_COLOR gradientColor;
    gradientColor.colorInfo[0] = count;
    gradientColor.colorAlphaInfo[0] = count;
    
    for (int i = 0; i < count; i++) {
        NSColor *color;
        CGFloat location = 0.0;
        [gradient getColor:&color location:&location atIndex:i];
        gradientColor.colorInfo[i * 4 + 1] = [color redComponent];
        gradientColor.colorInfo[i * 4 + 2] = [color greenComponent];
        gradientColor.colorInfo[i * 4 + 3] = [color blueComponent];
        gradientColor.colorInfo[i * 4 + 4] = location;
        gradientColor.colorAlphaInfo[i * 2 + 1] = [color alphaComponent];
        gradientColor.colorAlphaInfo[i * 2 + 2] = location;
    }
    
    return gradientColor;
}




- (int)type
{
	return m_nGradientType;
}

- (int)repeat
{
    return m_nWaveType;//[[m_idRepeatPopup selectedItem] tag];
}

- (BOOL)supersample
{
	return NO;
}

- (int)maximumDepth
{
	return 3;
}

- (double)threshold
{
	return 0.2;
}

- (void)shutdown
{
    [super shutdown];
	[gUserDefaults setInteger:m_nGradientType forKey:@"gradient type"];
	[gUserDefaults setInteger:m_nWaveType forKey:@"gradient repeat"];
}

#pragma mark - Actions
-(IBAction)onBtnGradientType:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    m_nGradientType = btn.tag - 100;
    
    [self resumeTypeButtonImage];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"gradient-%d-a",m_nGradientType]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"gradient-%d-a",m_nGradientType]]];
}

-(void)resumeTypeButtonImage
{
    NSButton *btn;
    
    for(int i = 0; i < 8; i++)
    {
        btn = [m_idView viewWithTag:100 + i];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"gradient-%d",i]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"gradient-%d",i]]];
    }
    
}

-(IBAction)onWaveType:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    if (![btn state])
    {
        m_nWaveType = 0;
    }
    else
    {
        [self resumeWaveButtonImage];
        [btn setState:YES];
        m_nWaveType = [btn tag] - 200;
    }
}

-(void)resumeWaveButtonImage
{
    NSButton *btn;
    
    for(int i = 0; i < 2; i++)
    {
        btn = [m_idView viewWithTag:200 + i + 1];
        [btn setState:NO];
    }
    
}

-(IBAction)onLockGradients45:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    if([btn state])
    {
        m_enumModifier = kControlModifier;
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
    
    switch (modifier) {
        case kControlModifier:
        {
            [m_btnLockGradients45 setState:YES];
        }
            break;
        case kNoModifier:
        {
            [m_btnLockGradients45 setState:NO];
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
    if(customComboBox == m_myCustomComboOpacity){
        float alpha = sValue.floatValue;
        alpha = MAX(0, MIN(100, alpha));
        [m_myCustomComboOpacity setStringValue:[NSString stringWithFormat:@"%.1f%%", alpha]];
    }
}

@end
