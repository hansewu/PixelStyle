#import "ZoomOptions.h"
#import "ToolboxUtility.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"

@implementation ZoomOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_comboxZoom setBackgroundColor:[NSColor clearColor]];
   
    [m_btnZoomOut setToolTip:NSLocalizedString(@"Zoom Out", nil)];
    [m_btnZoomIn setToolTip:NSLocalizedString(@"Zoom In", nil)];
    [m_comboxZoom setToolTip:NSLocalizedString(@"Display/Adjust Canvas Scale", nil)];
    
}

-(id)init
{
    self = [super init];
    
    m_bZoomOut = YES;
    
    return self;
}

- (void)update
{
//	[m_idZoomLabel setStringValue:[NSString stringWithFormat:LOCALSTR(@"zoom", @"Zoom: %.0f%%"), [[m_idDocument docView] zoom] * 100.0]];
    
    int zoomRatio = roundf([[m_idDocument docView] zoom] * 100.0);
    [m_comboxZoom setStringValue:[NSString stringWithFormat:@"%d%%", zoomRatio]];
}

-(BOOL)IsZoomOut
{
    return m_bZoomOut;
}

-(IBAction)onBtnZoomOut:(id)sender
{
    [m_btnZoomOut setImage:[NSImage imageNamed:@"zoom--a"]];
    [m_btnZoomOut setAlternateImage:[NSImage imageNamed:@"zoom--a"]];
    [m_btnZoomIn setImage:[NSImage imageNamed:@"zoom+"]];
    [m_btnZoomIn setAlternateImage:[NSImage imageNamed:@"zoom+"]];
    
    m_bZoomOut = YES;
}

-(IBAction)onBtnZoomIn:(id)sender
{
    [m_btnZoomOut setImage:[NSImage imageNamed:@"zoom-"]];
    [m_btnZoomOut setAlternateImage:[NSImage imageNamed:@"zoom-"]];
    [m_btnZoomIn setImage:[NSImage imageNamed:@"zoom+-a"]];
    [m_btnZoomIn setAlternateImage:[NSImage imageNamed:@"zoom+-a"]];
    
    
    m_bZoomOut = NO;
}



- (void)updateModifiers:(unsigned int)modifiers
{
    [super updateModifiers:modifiers];
    int modifier = [super modifier];
    
    switch (modifier) {
        case kAltModifier:
        case kNoModifier:
            if(m_bZoomOut)
                [self onBtnZoomIn:m_btnZoomIn];
            else
                [self onBtnZoomOut:m_btnZoomOut];

            break;
        default:
            break;
    }
}

#pragma mark - NSCombox dataSource -
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
{
    return 20;
}

static float s_Zoom[] = {0.05, 0.10, 0.15, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0,7.0, 8.0, 10.0, 12.0, 16.0, 25.0, 32.0};
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"%d%%",(int)(s_Zoom[index] * 100)];
}

#pragma mark - NSCombox delegate -
- (void)comboBoxWillPopUp:(NSNotification *)notification
{
    [m_btnComboxRight setState:NSOnState];
}

- (void)comboBoxWillDismiss:(NSNotification *)notification
{
    [m_btnComboxRight setState:NSOffState];
}

//- (void)comboBoxSelectionDidChange:(NSNotification *)notification
//{
//    NSComboBox *cb = (NSComboBox *)[notification object];
//    int nIndex = [cb indexOfSelectedItem];
//    [(PSView *)[m_idDocument docView] zoomTo: s_Zoom[nIndex]];
//}



//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
//{
//    NSComboBox *comboBox = (NSComboBox *)control;
//    
//    int nZoom = [comboBox intValue];
//    if(nZoom > 3200) nZoom = 3200;
//    else if (nZoom < 5) nZoom = 5;
//    [comboBox setStringValue:[NSString stringWithFormat:@"%d%%", nZoom]];
//    
//    [(PSView *)[m_idDocument docView] zoomTo: (float)[comboBox intValue]/100.0];
//    
//    return YES;
//}


- (IBAction)changeZoomValue:(id)sender
{
    NSComboBox *comboBox = m_comboxZoom;
    
    int nZoom = [comboBox intValue];
    if(nZoom > 3200) nZoom = 3200;
    else if (nZoom < 5) nZoom = 5;
    [comboBox setStringValue:[NSString stringWithFormat:@"%d%%", nZoom]];
    
    [(PSView *)[m_idDocument docView] zoomTo: (float)[comboBox intValue]/100.0];
}


@end
