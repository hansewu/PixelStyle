#import "InfoUtility.h"
#import "PSDocument.h"
#import "ToolboxUtility.h"
#import "PSTools.h"
#import "EyedropTool.h"
#import "PSSelection.h"
#import "PSView.h"
#import "PSContent.h"
#import "PSPrefs.h"
#import "PSController.h"
#import "UtilitiesManager.h"
#import "PSPrefs.h"
#import "PositionTool.h"
#import "RectSelectTool.h"
#import "EllipseSelectTool.h"
#import "CropTool.h"
#import "Units.h"
#import "LayerControlView.h"
#import "PSWindowContent.h"

@implementation InfoUtility

- (id)init
{
	return self;
}

- (void)awakeFromNib
{
	// Shown By Default
	[[PSController utilitiesManager] setInfoUtility: self for:m_idDocument];
	[(LayerControlView *)m_idControlView setHasResizeThumb:YES];
	[(LayerControlView *)m_idControlViewChannel setHasResizeThumb:YES];
    
	if(![self visible]){
		[m_idToggleButton setImage:[NSImage imageNamed:@"show-info"]];
	}
    
    [m_textFieldRadius setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Radius", nil)]];
    [m_textFieldSample setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Sample", nil)]];
}

- (void)shutdown
{	
}

- (void)activate
{
	if([self visible]){
		[self update];
	}
}

- (void)deactivate
{
	
}

- (IBAction)show:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility: YES forRegion: kPointInformation];
	[m_idToggleButton setImage:[NSImage imageNamed:@"hide-info"]];
}

- (IBAction)hide:(id)sender
{
	[[[m_idDocument window] contentView] setVisibility: NO forRegion: kPointInformation];	
	[m_idToggleButton setImage:[NSImage imageNamed:@"show-info"]];
}

- (IBAction)toggle:(id)sender
{
	if ([self visible]) {
		[self hide:sender];
	}
	else {
		[self show:sender];
	}
}

- (void)update
{
	IntPoint point, delta;
	IntSize size;
	NSColor *color;
	int xres, yres, units;
	int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
	
	// Show no values
	if (!m_idDocument) {
		[m_idXValue setStringValue:@""];
		[m_idYValue setStringValue:@""];
		[m_idWidthValue setStringValue:@""];
		[m_idHeightValue setStringValue:@""];
		[m_idDeltaX setStringValue:@""];
		[m_idDeltaY setStringValue:@""];
		[m_idRedValue setStringValue:@""];
		[m_idGreenValue setStringValue:@""];
		[m_idBlueValue setStringValue:@""];
		[m_idAlphaValue setStringValue:@""];
		[m_idRadiusValue setStringValue:@""];
		[m_idColorWell setColor: [NSColor colorWithCalibratedWhite: 0 alpha:1.0]];
		return;
	}
	
	// Set the radius value
	[m_idRadiusValue setIntValue:[[[m_idDocument tools] getTool:kEyedropTool] sampleSize]];

	// Update the document information
	xres = [[m_idDocument contents] xres];
	yres = [[m_idDocument contents] yres];

	// Get the selection
	if (curToolIndex == kCropTool) {
        size = [[[m_idDocument tools] getTool:kCropTool] cropRect].size;
	}
	else if ([[m_idDocument selection] active]) {
		size = [[m_idDocument selection] globalRect].size;
	}
	else {
		size.height = size.width = 0;
	}

	point = [[m_idDocument docView] getMousePosition:YES];
	delta = [[m_idDocument docView] delta];
	units = [m_idDocument measureStyle];

	NSString *label = UnitsString(units);
	[m_idWidthValue setStringValue:[StringFromPixels(size.width, units, xres) stringByAppendingFormat:@" %@", label]];
	[m_idHeightValue setStringValue:[StringFromPixels(size.height, units, yres) stringByAppendingFormat:@" %@", label]];
	[m_idDeltaX setStringValue:[StringFromPixels(delta.x, units, xres) stringByAppendingFormat:@" %@", label]];
	[m_idDeltaY setStringValue:[StringFromPixels(delta.y, units, yres) stringByAppendingFormat:@" %@", label]];
	[m_idXValue setStringValue:[StringFromPixels(point.x, units, xres) stringByAppendingFormat:@" %@", label]];
	[m_idYValue setStringValue:[StringFromPixels(point.y, units, yres) stringByAppendingFormat:@" %@", label]];

	// Update the RGBA values
	color = [[[m_idDocument tools] getTool:kEyedropTool] getColor];
	if (color) {
		[m_idColorWell setColor:color];
        NSString *colorSpaceName = [color colorSpaceName];
        
        if (![colorSpaceName isEqualToString:NSDeviceRGBColorSpace] && ![colorSpaceName isEqualToString:NSDeviceWhiteColorSpace]) {
            color = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
            colorSpaceName = [color colorSpaceName];
        }
        

		if ([colorSpaceName isEqualToString:NSDeviceRGBColorSpace]) {
			[m_idRedValue setIntValue:[color redComponent] * 255.0];
			[m_idGreenValue setIntValue:[color greenComponent] * 255.0];
			[m_idBlueValue setIntValue:[color blueComponent] * 255.0];
			[m_idAlphaValue setIntValue:[color alphaComponent] * 255.0];
		}
		else if ([colorSpaceName isEqualToString:NSDeviceWhiteColorSpace]) {
			[m_idRedValue setIntValue:[color whiteComponent] * 255.0];
			[m_idGreenValue setIntValue:[color whiteComponent] * 255.0];
			[m_idBlueValue setIntValue:[color whiteComponent] * 255.0];
			[m_idAlphaValue setIntValue:[color alphaComponent] * 255.0];
		}
		else {
			NSLog(@"Color space not recognized by information utility.");
		}
	}
	
	if(point.x == -1){
		[m_idXValue setStringValue:@""];
		[m_idYValue setStringValue:@""];
		[m_idRedValue setStringValue:@""];
		[m_idGreenValue setStringValue:@""];
		[m_idBlueValue setStringValue:@""];
		[m_idAlphaValue setStringValue:@""];
		
		[m_idColorWell setColor: [NSColor colorWithCalibratedWhite: 0 alpha:1.0]];
	}
}

- (BOOL)visible
{
	return [[[m_idDocument window] contentView] visibilityForRegion: kPointInformation];
}

@end
