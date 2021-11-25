#import "TransparentUtility.h"
#import "PSDocument.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "UtilitiesManager.h"

@implementation TransparentUtility

- (id)init
{
	float values[4];
	NSData *tempData;
	
	// Determine the initial color (from preferences if possible)
	if ([gUserDefaults objectForKey:@"transparency color data"] == NULL) {
		values[0] = values[1] = values[2] = values[3] = 1.0;
		m_clCurrTransparent = [NSColor colorWithCalibratedRed:values[0] green:values[1] blue:values[2] alpha:values[3]];
	}
	else {
		tempData = [gUserDefaults dataForKey:@"transparency color data"];
		if (tempData != nil)
			m_clCurrTransparent = (NSColor *)[NSUnarchiver unarchiveObjectWithData:tempData];
	}
	[m_clCurrTransparent retain];
	
	return self;
}

- (void)dealloc
{
	if (m_clCurrTransparent) [m_clCurrTransparent autorelease];
	[super dealloc];
}

- (IBAction)toggle:(id)sender
{
	BOOL panelOpen = [gColorPanel isVisible] && [[gColorPanel title] isEqualToString:LOCALSTR(@"transparent", @"Transparent")];
	
	if (!panelOpen) {
		[gColorPanel setAction:NULL];
		[gColorPanel setShowsAlpha:NO];
		[gColorPanel setColor:m_clCurrTransparent];
		[gColorPanel orderFront:self];
		[gColorPanel setTitle:LOCALSTR(@"transparent", @"Transparent")];
		[gColorPanel setContinuous:NO];
		[gColorPanel setAction:@selector(changeColor:)];
		[gColorPanel setTarget:self];
	}
	else
		[gColorPanel orderOut:self];
}

- (void)changeColor:(id)sender
{
	NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
	int i;
	
	// Change the colour
	[m_clCurrTransparent autorelease];
	m_clCurrTransparent = [sender color];
	if (![[m_clCurrTransparent colorSpaceName] isEqualToString:NSNamedColorSpace])
		[[sender color] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	[m_clCurrTransparent retain];
	
	// Call for all documents' views to respond to the change
	for (i = 0; i < [documents count]; i++) {
		[[[documents objectAtIndex:i] docView] setNeedsDisplay:YES];
	}

	[gUserDefaults setObject:[NSArchiver archivedDataWithRootObject:m_clCurrTransparent] forKey:@"transparency color data"];

}

- (id)color
{		
	return m_clCurrTransparent;
}

@end
