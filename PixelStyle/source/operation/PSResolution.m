#import "PSResolution.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSScale.h"
#import "PSContent.h"
#import "PSHelpers.h"
#import "PSSelection.h"
#import "PSWarning.h"
#import "PSController.h"

extern IntPoint gScreenResolution;

@implementation PSResolution

- (void)run
{
    [self initViews];
    
	id contents = [m_idDocument contents];
	
	// Set the text fields correctly
	[m_idXValue setIntValue:(int)[contents xres]];
	[m_idYValue setIntValue:(int)[contents yres]];
	if ([contents xres] == [contents yres]) {
		[m_idYValue setEnabled:NO];
		[m_idForceSquare setState:NSOnState];
	}
	else {
		[m_idYValue setEnabled:YES];
		[m_idForceSquare setState:NSOffState];
	}
	
	// Set the options correctly
	[m_idPreserveSize setState:NSOffState];
	
	// Show the sheet
	[NSApp beginSheet:m_idSheet modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
//    NSRect windowRect = [[m_idDocument window] frame];
//    [m_idSheet setFrameOrigin:NSMakePoint(windowRect.origin.x + windowRect.size.width / 2.0 - [m_idSheet frame].size.width/2.0, windowRect.origin.y + windowRect.size.height/2.0 - [m_idSheet frame].size.height/2.0)];
//    
//    [[m_idDocument window] addChildWindow:m_idSheet ordered:NSWindowAbove];
//    
//    [m_idSheet orderFront:nil];
}

-(void)initViews
{
    [m_labelHorizontal setStringValue:NSLocalizedString(@"Horizontal", nil)];
    [m_labelVertical setStringValue:NSLocalizedString(@"Vertical", nil)];
    [m_idPreserveSize setTitle:NSLocalizedString(@"Scale to preserve size", nil)];
    [m_btnCancel setTitle:NSLocalizedString(@"Cancel", nil)];
    [m_btnSet setTitle:NSLocalizedString(@"Set", nil)];
}

- (IBAction)apply:(id)sender
{
	id contents = [m_idDocument contents];
	IntResolution newRes;
	
	// Get the values
	newRes.x = [m_idXValue intValue];
	newRes.y = [m_idYValue intValue];
	
	// End the sheet
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
//    [[m_idDocument window] removeChildWindow:m_idSheet];
	[m_idSheet orderOut:self];
	
	// Don't do if values are unreasonable or unchanged
	if ([m_idForceSquare state]) newRes.y = newRes.x;
	if (newRes.x < 9) { NSBeep(); return; }
	if (newRes.y < 9) { NSBeep(); return; }
	if (newRes.x > 73728) { NSBeep(); return; }
	if (newRes.y > 73728) { NSBeep(); return; }
	if (newRes.x == [contents xres] && newRes.y == [contents yres]) { return; }
	if (gScreenResolution.x == 0 || gScreenResolution.y == 0) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"resolution no effect message", @"The resolution of this image has been changed and this will affect printing and saving. However this will not affect the viewing window because your Preferences are set to ignore image resolution.") forDocument: m_idDocument level:kModerateImportance];
	}
	
	// Make the changes
	if ([m_idPreserveSize state]) [m_idPSScale scaleToWidth:[(PSContent *)contents width] * ((float)newRes.x / (float)[contents xres]) height:[(PSContent *)contents height] * ((float)newRes.y / (float)[contents yres]) interpolation:GIMP_INTERPOLATION_CUBIC index:kAllLayers];
	[self setResolution:newRes];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[NSApp endSheet:m_idSheet];
//    [[m_idDocument window] removeChildWindow:m_idSheet];
	[m_idSheet orderOut:self];
}

- (void)setResolution:(IntResolution)newRes
{
	IntResolution oldRes;
	
	// Allow the undo/redo
	oldRes.x = [[m_idDocument contents] xres];
	oldRes.y = [[m_idDocument contents] yres];
	[[[m_idDocument undoManager] prepareWithInvocationTarget:self] setResolution:oldRes];
	
	// Change the resolution
	[[m_idDocument contents] setResolution:newRes];
	
	// Inform the helpers
	[[m_idDocument helpers] resolutionChanged];
}

- (IBAction)toggleForceSquare:(id)sender
{
	[m_idYValue setStringValue:[m_idXValue stringValue]];
	if ([m_idForceSquare state])
		[m_idYValue setEnabled:NO];
	else
		[m_idYValue setEnabled:YES];
}

- (IBAction)togglePreserveSize:(id)sender
{
}

//- (IBAction)xValueChanged:(id)sender
//{
//	if ([m_idForceSquare state]) [m_idYValue setStringValue:[m_idXValue stringValue]];
//}

- (void)controlTextDidChange:(NSNotification *)obj
{
//        NSLog(@"controlTextDidChange %@",[m_idXValue stringValue]);
//    [self valueChanged:obj.object];
    if ([m_idForceSquare state]) [m_idYValue setStringValue:[m_idXValue stringValue]];
}

@end
