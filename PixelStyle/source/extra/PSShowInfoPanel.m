//
//  PSShowInfoPanel.m
//  PixelStyle
//
//  Created by wyl on 16/3/24.
//
//

#import "PSShowInfoPanel.h"
#import "ConfigureInfo.h"
#import "PSTextFieldCell.h"

@implementation PSShowInfoPanel

-(id)init
{
    self = [super initWithContentRect:NSMakeRect(0, 0, 0, TEXT_FONT_SIZE * 4) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    if(self)
    {
        m_fDelayTime = -1;
        
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        
        NSImageView *imageViewBg = [[[NSImageView alloc] initWithFrame:self.contentView.bounds] autorelease];
        [imageViewBg setImage:[NSImage imageNamed:@"pop-view-bg"]];
        [imageViewBg setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [imageViewBg setImageScaling:NSImageScaleAxesIndependently];
        [self.contentView addSubview:imageViewBg];
    }
    
    return self;
}

-(void)addMessageText:(NSString *)sMessage
{
    NSRect rect = self.contentView.bounds;
    int nTextFieldWidth = TEXT_FONT_SIZE * [sMessage length] * 1.0;
    if(nTextFieldWidth > rect.size.width) rect.size.width = nTextFieldWidth;
    rect.size.height += TEXT_FONT_SIZE * 2;
    
    [self changePanelBounds:rect];
    rect = self.contentView.bounds;
    
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(rect.size.width/2 -nTextFieldWidth/2.0 , rect.size.height - TEXT_FONT_SIZE * 4, nTextFieldWidth, TEXT_FONT_SIZE * 2)];
    PSTextFieldLabelCell *cell = [[PSTextFieldLabelCell alloc] init];
    [cell setAlignment:NSTextAlignmentCenter];
    [cell setStringValue:sMessage];
    [textField setCell:cell];
    [textField setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
    [[self contentView] addSubview:textField];
    [textField release];
}

-(void)setAutoHiddenDelay:(float)fDelayTime
{
    m_fDelayTime = fDelayTime;
}

-(void)changePanelBounds:(NSRect)boundsRect
{
    [self setFrame:boundsRect display:YES];
}

- (void)showPanel:(NSRect)rect
{
    [self setAnimationBehavior:NSWindowAnimationBehaviorDocumentWindow];
    
    NSDocument *currentDoucemnt = [[NSDocumentController sharedDocumentController] currentDocument];
    NSWindow *window = [currentDoucemnt window];
    
    NSPoint originPoint = NSMakePoint(window.frame.origin.x + window.frame.size.width/2.0 - self.frame.size.width/2.0, window.frame.origin.y + window.frame.size.height/2.0 - self.frame.size.height/2.0);
    [self setFrameOrigin:originPoint];
    
    
    if(!NSEqualRects(rect, NSZeroRect))
        [self setFrame:rect display:YES animate:YES];
    
    [window addChildWindow:self ordered:NSWindowAbove];
    
    [self orderFront:nil];
    
    
    if(m_fDelayTime > 0)
        [self performSelector:@selector(closePanel) withObject:nil afterDelay:m_fDelayTime];
}

- (void)closePanel
{
    [NSApp stopModal];
    
    NSDocument *currentDoucemnt = [[NSDocumentController sharedDocumentController] currentDocument];
    NSWindow *window = [currentDoucemnt window];
    [window removeChildWindow:self];
    
    [self orderOut:nil];
}


-(void)dealloc
{
    [super dealloc];
}

@end
