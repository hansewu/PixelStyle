#import "ColorSelectView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSController.h"
#import "PSTools.h"
#import "AbstractTool.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "PSTexture.h"
#import "TransparentUtility.h"
#import "TextureUtility.h"
#import "PSWhiteboard.h"
#import "ToolboxUtility.h"


@implementation ColorSelectView

- (id)initWithFrame:(NSRect)frame
{
	// Initialize the super
	if (![super initWithFrame:frame])
		return NULL;
	
	// Set data members appropriately
	m_bMouseDownOnSwap = NO;
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)setDocument:(id)doc
{
	m_idDocument = doc;
	[self setNeedsDisplay:YES];
	
	if (doc == NULL) {
	
		// If we are closing the last document hide the panel for selecting the foreround or background colour
		if ([gColorPanel isVisible] && ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")] || [[gColorPanel title] isEqualToString:LOCALSTR(@"background", @"Background")])) {
			if ([[[NSDocumentController sharedDocumentController] documents] count] == 1)
				[gColorPanel orderOut:self];
		}
		
	}
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return YES;
}

- (void)drawRect:(NSRect)rect
{
    
	BOOL foregroundIsTexture = [[[m_idDocument tools] currentTool] foregroundIsTexture];
	
	NSBezierPath *tempPath;
	// White
	[[NSColor whiteColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(32, 16)];
	[tempPath lineToPoint:NSMakePoint(16, 32)];
	[tempPath lineToPoint:NSMakePoint(32,32)];
	[tempPath fill];
	// Black
	[[NSColor blackColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(16, 16)];
	[tempPath lineToPoint:NSMakePoint(32, 16)];
	[tempPath lineToPoint:NSMakePoint(16,32)];
	[tempPath fill];
    
    
    
	// Actual Color
	if (m_idDocument == NULL)
		[[NSColor whiteColor] set];
	else {
		if ([[m_idDocument whiteboard] CMYKPreview])
			[[[m_idDocument whiteboard] matchColor:[[m_idDocument contents] background]] set];
		else
			[[[m_idDocument contents] background] set];
	}
    
	[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(16, 16, 16, 16) xRadius:0 yRadius:0] fill];
    // Background color
    // Border
    [[NSColor colorWithCalibratedWhite:0 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(14, 14, 18, 18) xRadius:0 yRadius:0] stroke];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(15, 15, 17, 17) xRadius:0 yRadius:0] stroke];

	// White
	[[NSColor whiteColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(19, 7)];
	[tempPath lineToPoint:NSMakePoint(3, 23)];
	[tempPath lineToPoint:NSMakePoint(19,23)];
	[tempPath fill];
	// Black
	[[NSColor blackColor] set];
	tempPath = [NSBezierPath bezierPath];
	[tempPath moveToPoint:NSMakePoint(3, 7)];
	[tempPath lineToPoint:NSMakePoint(16, 7)];
	[tempPath lineToPoint:NSMakePoint(3,23)];
	[tempPath fill];
    
    	// Actual Color
	// Draw the foreground button
	if (foregroundIsTexture)
    {
		[[NSColor colorWithPatternImage:[[[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture] thumbnail]] set];
		[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(3, 7, 16, 16) xRadius:0 yRadius:0] fill];
	}
	else
    {
		if (m_idDocument == NULL)
			[[NSColor blackColor] set];
		else {
			if ([[m_idDocument whiteboard] CMYKPreview])
				[[[m_idDocument whiteboard] matchColor:[[m_idDocument contents] foreground]] set];
			else
				[[[m_idDocument contents] foreground] set];
		}
		[[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(3, 7, 16, 16) xRadius:0 yRadius:0] fill];
	}
    // Forground Color
    // Border
    [[NSColor colorWithCalibratedWhite:0 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(1, 5, 18, 18) xRadius:0 yRadius:0] stroke];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
    [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(2, 6, 17, 17) xRadius:0 yRadius:0] stroke];
    

	
	// Draw the images
//    [[NSImage imageNamed:@"swap"] drawInRect:NSMakeRect(5, 27, 12, 12)];
    [[NSImage imageNamed:@"swap"] drawInRect:NSMakeRect(1, 25, 12, 12) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1 respectFlipped:YES hints:nil];
	//[[NSImage imageNamed:@"samp"] compositeToPoint:NSMakePoint(0, 27) operation:NSCompositeSourceOver];
	//[[NSImage imageNamed:@"def"] compositeToPoint:NSMakePoint(44, 6) operation:NSCompositeSourceOver];
    
    [self addToolTipRect:NSMakeRect(16, 16, 18, 18) owner:NSLocalizedString(@"Set the Background Color", nil) userData:nil];
    [self addToolTipRect:NSMakeRect(3, 7, 18, 18) owner:NSLocalizedString(@"Set the Foreground Color", nil) userData:nil];
    [self addToolTipRect:NSMakeRect(1, 25, 12, 12) owner:NSLocalizedString(@"Switch Foreground/Background Colors", nil) userData:nil];
}

- (IBAction)activateForegroundColor:(id)sender
{	
	// Displays colour panel for setting the foreground 
	[gColorPanel setAction:NULL];
	[gColorPanel setShowsAlpha:NO];
	[gColorPanel setColor:[[m_idDocument contents] foreground]];	
	[gColorPanel setTitle:LOCALSTR(@"foreground", @"Foreground")];
	[gColorPanel setContinuous:YES];
	[gColorPanel setAction:@selector(changeForegroundColor:)];
    [gColorPanel setTarget:self];
    [gColorPanel orderFront:self];
  
}

- (IBAction)activateBackgroundColor:(id)sender
{
	// Displays colour panel for setting the background
	[gColorPanel setAction:NULL];
	[gColorPanel setShowsAlpha:NO];
	[gColorPanel setColor:[[m_idDocument contents] background]];
	[gColorPanel setTitle:LOCALSTR(@"background", @"Background")];
	[gColorPanel setContinuous:YES];
	[gColorPanel setAction:@selector(changeBackgroundColor:)];
	[gColorPanel setTarget:self];
    [gColorPanel orderFront:self];
}

- (IBAction)swapColors:(id)sender
{
	NSColor *tempColor;
	[self setNeedsDisplay:YES];
	tempColor = [[m_idDocument contents] foreground];
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] setForeground:[[m_idDocument contents] background]];
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] setBackground:tempColor];
	[self update];
}

- (IBAction)defaultColors:(id)sender
{
	[self setNeedsDisplay:YES];
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] setForeground:[NSColor blackColor]];
	[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] setBackground:[NSColor whiteColor]];
	[self update];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	// Don't do anything if there isn't a document to do it on
	if (!m_idDocument)
		return;
	
	if (NSMouseInRect(clickPoint, NSMakeRect(2, 2, 26, 21), [self isFlipped])) {
		[self activateForegroundColor: self];
	
	}
	else if (NSMouseInRect(clickPoint, NSMakeRect(22, 16, 26, 21), [self isFlipped])) {
		[self activateBackgroundColor: self];
	}
	else if (NSMouseInRect(clickPoint, NSMakeRect(0, 26, 16, 20), [self isFlipped])) {
		
		// Highlight the swap button
		m_bMouseDownOnSwap = YES;
		[self setNeedsDisplay:YES];
		
	}
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:NULL];
	
	if (m_bMouseDownOnSwap) {
	
		// Return the swap button to normal
		m_bMouseDownOnSwap = NO;
		[self setNeedsDisplay:YES];
		
		// If the button was released in the same rectangle swap the colours
		if (NSMouseInRect(clickPoint, NSMakeRect(0, 26, 16, 20), [self isFlipped]))
			[self swapColors: self];
	}
}

- (void)changeForegroundColor:(id)sender
{
	id toolboxUtility = (ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
	
	[toolboxUtility setForeground:[sender color]];
	[m_idTextureUtility setActiveTextureIndex:-1];
	[self setNeedsDisplay:YES];
}

- (void)changeBackgroundColor:(id)sender
{
	id toolboxUtility = (ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
	
	[toolboxUtility setBackground:[sender color]];
	[self setNeedsDisplay:YES];
}

- (void)update
{
	// Reconfigure the colour panel correctly
	if ([gColorPanel isVisible] && ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")] || [[gColorPanel title] isEqualToString:LOCALSTR(@"background", @"Background")])) {
				
		// Set colour correctly
		if ([[gColorPanel title] isEqualToString:LOCALSTR(@"foreground", @"Foreground")])
			[gColorPanel setColor:[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] foreground]];
		else
			[gColorPanel setColor:[(ToolboxUtility *)[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] background]];
		
	}
	
	// Call for an update of the view
	[self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
	return YES;
}

- (BOOL)isOpaque
{
	return NO;
}

@end
