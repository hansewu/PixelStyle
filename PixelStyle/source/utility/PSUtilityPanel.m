#import "PSUtilityPanel.h"

@implementation PSUtilityPanel

- (void)awakeFromNib
{
	[self setDelegate:self];
}

- (BOOL)canBecomeKeyWindow
{
	return NO;
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}

- (IBAction)shade:(id)sender
{
	NSRect frame;
	
	frame = [self frame];
	if (frame.size.height == 16) {
		frame.origin.y -= m_fPriorShadeHeight - 16;
		frame.size.height = m_fPriorShadeHeight;
		[self setFrame:frame display:YES animate:YES];
		[self setContentView:m_idPriorContentView];
		[m_idPriorContentView autorelease];
        [self isVisible];
        [self setIsVisible:YES];
	}
	else {
		m_fPriorShadeHeight = frame.size.height;
		frame.origin.y += frame.size.height - 16;
		frame.size.height = 16;
		m_idPriorContentView = [self contentView];
		[m_idPriorContentView retain];
		if (m_idNullView) [self setContentView:m_idNullView];
		[self setFrame:frame display:YES animate:NO];
	}
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [gCurrentDocument undoManager];
}

- (void)saveFrameUsingName:(NSString *)name
{
	NSRect frame;
	
	frame = [self frame];
	if (frame.size.height != 16) {
		[super saveFrameUsingName:name];
	}
}

- (void)miniaturize:(id)sender
{
	[self shade:sender];
}

- (BOOL)isMiniaturized
{
	return NO;
}

@end
