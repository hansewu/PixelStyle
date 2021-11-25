#import "StatusUtility.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSHelpers.h"
#import "Units.h"
#import "LayerControlView.h"
#import "ToolboxUtility.h"
#import "PSView.h"
// #import "WebSlider.h"
#import "PSWindowContent.h"

@implementation StatusUtility
- (void)awakeFromNib
{
    [self addSEOButtons];
    
    [m_idZoomNormal setToolTip:NSLocalizedString(@"Zoom to the Actual Size", nil)];
    [m_idZoomIn setToolTip:NSLocalizedString(@"Zoom In", nil)];
    [m_idZoomOut setToolTip:NSLocalizedString(@"Zoom Out", nil)];
    [m_idZoomLabel setToolTip:NSLocalizedString(@"Display Canvas Scale", nil)];
    [m_idZoomSlider setToolTip:NSLocalizedString(@"Adjust Canvas Scale", nil)];
    

    [m_idZoomLabel setFont:[NSFont systemFontOfSize:12]];
    [m_idZoomLabel setDrawsBackground:YES];
    [m_idZoomLabel setFocusRingType:NSFocusRingTypeNone];
    
    
	[[PSController utilitiesManager] setStatusUtility: self for:m_idDocument];
	
	[(LayerControlView *)m_idView setHasResizeThumb: NO];
	
	// This is how you're SUPPOSED to change these things
	[[m_idChannelSelectionPopup itemAtIndex: 0] setTitle: @""];
	[[m_idChannelSelectionPopup itemAtIndex: 0] setImage: [NSImage imageNamed: @"channels-menu"]];
	// But this is what apparently works in 10.4
	[m_idChannelSelectionPopup setTitle: @""];
	[m_idChannelSelectionPopup setImage: [NSImage imageNamed: @"channels-menu"]];
	
	/*
	 
	// Stub function calls for when this feature is implemented
	 
	if([(PSContent *)[m_idDocument contents] type] == 0){	
		[(WebSlider *)m_idRedSlider setSliderType: kRedSlider];
		[(WebSlider *)m_idGreenSlider setSliderType: kGreenSlider];
		[(WebSlider *)m_idBlueSlider setSliderType: kBlueSlider];
	}else{
		[(WebSlider *)m_idRedSlider setSliderType: kGraySlider];
		[(WebSlider *)m_idGreenSlider setSliderType: kGraySlider];
		[(WebSlider *)m_idBlueSlider setSliderType: kGraySlider];
	}
	[(WebSlider *)m_idAlphaSlider setSliderType:kAlphaSlider];
	*/
	
	[self update];
}

- (IBAction)show:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility: YES forRegion: kStatusBar];
	[self update];
	[self updateZoom];
}

- (IBAction)hide:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility: NO forRegion: kStatusBar];
}

- (IBAction)toggle:(id)sender
{
	if([[[m_idDocument window] contentView] visibilityForRegion: kStatusBar]) {
		[self hide:sender];
	}else{
		[self show:sender];
	}
}

- (void)update
{
	if(m_idDocument){
		PSContent *contents = [m_idDocument contents];
		
		int newUnits = [m_idDocument measureStyle];
		NSString *statusString = @"";
		unichar ch = 0x00B7; // replace this with your code pointNSString
		NSString *divider = [NSString stringWithCharacters:&ch length:1];
		if([m_idView frame].size.width > 445){
			statusString = [statusString stringByAppendingFormat: @"%@ %C %@ %@", StringFromPixels([contents width] , newUnits, [contents xres]), 0x00D7, StringFromPixels([contents height], newUnits, [contents yres]), UnitsString(newUnits)];
//            statusString = [statusString stringByAppendingFormat: @"W : %@ %@  %@  H : %@ %@", StringFromPixels([contents width] , newUnits, [contents xres]), UnitsString(newUnits),divider, StringFromPixels([contents height], newUnits, [contents yres]), UnitsString(newUnits)];
		}
		if([m_idView frame].size.width > 480){
//			statusString = [[NSString stringWithFormat:@"%.0f%% %@ ", [contents xscale] * 100, divider] stringByAppendingString: statusString];
		}
		if([m_idView frame].size.width > 525){
			statusString = [statusString stringByAppendingFormat: @", %d dpi", [contents xres]];
		}
		if([m_idView frame].size.width > 575){
			//statusString = [statusString stringByAppendingFormat: @" %@ %@", divider, [contents type] ? @"Grayscale" : @"Full Color"];
		}
		
        if(![[m_idDimensionLabel stringValue] isEqualToString:statusString])
        {
            [m_idDimensionLabel setStringValue: statusString];

            [m_idView setNeedsDisplay: YES];
        }
	}
}

-(void)updateZoom
{
//    NSLog(@" zoom =%d %d",[[m_idDocument contents] xscale], (int)log2([[m_idDocument contents] xscale]));
	if(m_idDocument)
    {
        NSSlider *slider = (NSSlider *)m_idZoomSlider;
        [m_idZoomSlider setIntValue: [[m_idDocument docView] zoom] * 100];
//		[m_idZoomSlider setIntValue: (slider.minValue + [[m_idDocument docView] zoomIndex])];
        [m_idZoomLabel setStringValue:[NSString stringWithFormat:@"%.0f%%", [[m_idDocument docView] zoom] * 100]];
	}else{
		[m_idZoomSlider setEnabled: NO];
		[m_idZoomSlider setIntValue: 0];
        [m_idZoomLabel setStringValue:[NSString stringWithFormat:@"100.0%%"]];
	}
}


- (IBAction)changeChannel:(id)sender
{
	[NSMenu popUpContextMenu:[sender menu] withEvent:[[NSEvent alloc] init]  forView: sender];
}

- (IBAction)channelChanged:(id)sender
{
	[[m_idDocument contents] setSelectedChannel:[sender tag] % 10];
	[[m_idDocument helpers] channelChanged];	
}

- (IBAction)trueViewChanged:(id)sender
{
	[[m_idDocument contents] setTrueView:![[m_idDocument contents] trueView]];
	[[m_idDocument helpers] channelChanged];	
	[self update];
}

- (IBAction)quickColorChange:(id)sender
{
	ToolboxUtility *util = (ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
	
	//NSLog(@"red value %d set to color value %f (which currently is %f or %d)",[m_idRedBox intValue], (float)[m_idRedBox intValue] / 255.0, ([foreground redComponent]), (int)round([foreground redComponent] * 255));
	if([(PSContent *)[m_idDocument contents] type]){
		[util setForeground: [NSColor colorWithCalibratedWhite:[sender intValue] / 255.0 alpha:[m_idAlphaBox intValue] /255.0]];
	}else{
		[util setForeground: [NSColor colorWithCalibratedRed:[m_idRedBox intValue] / 255.0 + 1.0/512.0 green:[m_idGreenBox intValue] / 255.0 blue:[m_idBlueBox intValue]/255.0 alpha:[m_idAlphaBox intValue] /255.0]];
	}
	[util update:YES];
}

- (IBAction)changeZoom:(id)sender
{
    //NSLog(@" changeZoom = %d",[sender intValue]);
	[(PSView *)[m_idDocument docView] zoomTo: [sender intValue]/100.0];
}

- (IBAction)zoomIn:(id)sender
{
	[(PSView *)[m_idDocument docView] zoomIn: self];
}

- (IBAction)zoomOut:(id)sender
{
	[(PSView *)[m_idDocument docView] zoomOut: self];
}

- (IBAction)zoomNormal:(id)sender
{
	[(PSView *)[m_idDocument docView] zoomNormal: self];
}

- (id)view
{
	return m_idView;
}



- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    ;
    
    if(textField == m_idZoomLabel)
    {
        int nZoom = [textField intValue];
        if(nZoom > 3200) nZoom = 3200;
        else if (nZoom < 5) nZoom = 5;
        [m_idZoomLabel setStringValue:[NSString stringWithFormat:@"%d%%", nZoom]];
        
        [(PSView *)[m_idDocument docView] zoomTo: (float)nZoom/100.0];
    }
    
    return YES;
}

# pragma mark - add SEO UI
-(void)addSEOButtons
{
    NSArray *seoTitles = [[[NSArray alloc] initWithObjects:@"Remove Background(Paid)", @"Image to Vector(Paid)", nil] autorelease];
    int nSEOCount = (int)[seoTitles count];
    for (int nIndex = 0; nIndex < nSEOCount; nIndex++)
    {
        NSString *sSEOTitle = [seoTitles objectAtIndex:nIndex];
        NSRect boundsRect = [m_idView bounds];
        NSButton *seoButton = [[NSButton alloc] initWithFrame:NSMakeRect(boundsRect.size.width - 140*(nSEOCount - nIndex) + 55, boundsRect.size.height - 32, 25, 25)];
        [seoButton setBezelStyle:NSThickSquareBezelStyle];
        [seoButton setBordered:NO];
        [(NSButtonCell *)seoButton.cell setImageScaling:NSImageScaleAxesIndependently];
        [seoButton setAutoresizingMask:NSViewMinXMargin];
        SEL sel = nil;
        switch (nIndex)
        {
            case 0:
                [seoButton setImage:[NSImage imageNamed:@"spc_icon_16x16"]];
                sel = @selector(onSEO1:);
                break;
            case 1:
                [seoButton setImage:[NSImage imageNamed:@"sv_icon_32x32"]];
                sel = @selector(onSEO2:);
                break;
            default:
                sel = nil;
                break;
        }
        [seoButton setAction:sel];
        [seoButton setTarget:self];
        
        [m_idView addSubview:seoButton];
        
        [seoButton release];
        
        NSTextField *label = [[[NSTextField alloc] initWithFrame:NSMakeRect(boundsRect.size.width - 140*(nSEOCount - nIndex), -4, 150, 20)] autorelease];
        [label setTextColor:[NSColor colorWithCalibratedRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1]];
        [label setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        [label setBordered:NO];
        [label setEditable:NO];
        [label setBezeled:NO];
        label.drawsBackground = NO;
        label.alignment = NSTextAlignmentCenter;
        [label setStringValue:NSLocalizedString(sSEOTitle, nil)];
        [label setAutoresizingMask:NSViewMinXMargin];
        [m_idView addSubview:label];
    }
}

-(void)onSEO1:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"https://itunes.apple.com/app/id966457795", nil)]];
}

-(void)onSEO2:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"https://itunes.apple.com/app/id1152204742", nil)]];
}

@end
