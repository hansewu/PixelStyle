#import "MyToolBarView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSWarning.h"
#import <QuartzCore/QuartzCore.h>


@implementation MyToolBarView


-(void)targetMethod:(id)sender
{
//    [self addSubview:m_idColorSelectView];
//    NSRect frame = [m_idColorSelectView frame];
//    frame.origin.x = -10;
//    frame.origin.y = 20;
//    [m_idColorSelectView setFrame:frame];
 
   /* self.layer.masksToBounds = NO;
  //  [self.layer setBorderWidth:3.0];
  //  [self.layer setBorderColor:[[NSColor blackColor] CGColor]];
	[self.layer setShadowOffset: CGSizeMake(3, -3)];
	[self.layer setShadowRadius:5.0];//  setShadowBlurRadius: 1];
	[self.layer setShadowColor:[[NSColor blackColor] CGColor]];
    [self.layer setShadowOpacity:1];*/
  /*  self.layer.shadowOffset = CGSizeMake(10, 10);
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = 10.0;
    self.layer.shadowPath = [self quartzPathFromBezierPath:[NSBezierPath bezierPathWithRect:self.frame]];
    */
    //[self.layer setShadowOpacity:0.8];
  //[self se setClipsToBounds:NO];
  
  /*
    NSShadow *dropShadow = [[NSShadow alloc] init];
    [dropShadow setShadowColor:[NSColor redColor]];
    [dropShadow setShadowOffset:NSMakeSize(10, -10.0)];
    [dropShadow setShadowBlurRadius:1.0];
    
    [self  setWantsLayer: YES];
    [[self superview] setWantsLayer: YES];
    [[[self superview] superview ]setWantsLayer: YES];
    [[self superview] setShadow: dropShadow];
    
    [dropShadow release];
    */

}



- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        m_strBannerText = [[NSString string] retain];
	//	bannerImportance = kHighImportance;
        
        m_btnOldSelected = nil;
        
        
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(targetMethod:)
                                       userInfo:nil
                                        repeats:NO];
        
    }
    return self;
}

- (void)dealloc
{
	[m_strBannerText release];
	[super dealloc];
}


- (void)drawRect:(NSRect)dirtyRect
{


    NSColor *leftColor;
    NSColor *fillColor;
    NSColor *rightColor;
    NSBezierPath *path;
	BOOL usesOldStyle = YES;
    
	switch ((int)floor(NSAppKitVersionNumber))
    {
        case NSAppKitVersionNumber10_3:
        case NSAppKitVersionNumber10_4:
            usesOldStyle = YES;
			break;
	}
    
     //if(usesOldStyle) //[window isMainWindow] &&
     {
     leftColor = [NSColor colorWithDeviceWhite:0.91 alpha:1.0];
     fillColor = [NSColor colorWithDeviceWhite:0.84 alpha:1.0];
     rightColor = [NSColor colorWithDeviceWhite:0.50 alpha:1.0];
     }
   /*  else if(usesOldStyle)
     {
         leftColor = [NSColor colorWithDeviceWhite:0.96 alpha:1.0];
         fillColor = [NSColor colorWithDeviceWhite:0.93 alpha:1.0];
         rightColor = [NSColor colorWithDeviceWhite:0.50 alpha:1.0];
     }
    */
    /* else if([window isMainWindow])
     {
     topColor = [NSColor colorWithDeviceWhite:0.75 alpha:1.0];
     fillColor = [NSColor colorWithDeviceWhite:0.57 alpha:1.0];
     bottomColor = [NSColor colorWithDeviceWhite:0.50 alpha:1.0];
     }
     else
     {
         leftColor = [NSColor colorWithDeviceWhite:0.89 alpha:1.0];
         fillColor = [NSColor colorWithDeviceWhite:0.81 alpha:1.0];
         rightColor = [NSColor colorWithDeviceWhite:0.62 alpha:1.0];
     }*/
    
    [rightColor set];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect([self frame].size.width - 1.0, 0, 1.0, [self frame].size.height)];
    [path fill];
    
    [leftColor set];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, 1.0, [self frame].size.height)];
    [path fill];
    
    [fillColor set];
    path = [NSBezierPath bezierPathWithRect:NSMakeRect(1.0, 0.0, [self frame].size.width -2.0, [self frame].size.height)];
    [path fill];
    // We use images for the backgrounds
/*	NSImage *background = NULL;
	switch(bannerImportance)
    {
		case kUIImportance:
			background = [NSImage imageNamed:@"floatbar"];
			break;
		case kHighImportance:
			background = [NSImage imageNamed:@"errorbar"];
			break;
		default:
			background = [NSImage imageNamed:@"warningbar"];
			break;
	}
	
	[background drawInRect:NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height) fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0]; 
	[NSGraphicsContext saveGraphicsState];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset: NSMakeSize(0, 1)];
	[shadow setShadowBlurRadius:0];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
	[shadow set];
	
	NSDictionary *attrs;
	attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, shadow ,NSShadowAttributeName ,nil];
	
	// We need to calculate the width of the text box
	NSRect drawRect = NSMakeRect(10, 8, [self frame].size.width, 18);
	if([m_idAlternateButton frame].origin.x < [self frame].size.width)
    {
		drawRect.size.width -= 232;
	}
    else if ([m_idDefaultButton frame].origin.x < [self frame].size.width )
    {
		drawRect.size.width -= 124;
	}
	
	if(drawRect.size.width < [m_strBannerText sizeWithAttributes:attrs].width)
    {
		[@"..." drawInRect:NSMakeRect(drawRect.size.width + 8, 8, 18, 18) withAttributes:attrs];
	}
    
	[m_strBannerText drawInRect: drawRect withAttributes:attrs];
	[NSGraphicsContext restoreGraphicsState];
 */
 
}

- (void)setBannerText:(NSString *)text defaultButtonText:(NSString *)dText alternateButtonText:(NSString *)aText andImportance:(int)importance
{
	[m_strBannerText release];
	m_strBannerText = [text retain];
//	bannerImportance = importance;
	
	if(dText)
    {
		[m_idDefaultButton setTitle:dText];
		NSRect frame = [m_idDefaultButton frame];
		frame.origin.x = [self frame].size.width - 108;
		[m_idDefaultButton setFrame:frame];
	}
    else
    {
		NSRect frame = [m_idDefaultButton frame];
		frame.origin.x = [self frame].size.width;
		[m_idDefaultButton setFrame:frame];
	}
		
	if(aText && dText)
    {
		[m_idAlternateButton setTitle:aText];
		NSRect frame = [m_idAlternateButton frame];
		frame.origin.x = [self frame].size.width - 216;
		[m_idAlternateButton setFrame:frame];
	}
    else
    {
		NSRect frame = [m_idAlternateButton frame];
		frame.origin.x = [self frame].size.width;
		[m_idAlternateButton setFrame:frame];
	}
	[self setNeedsDisplay: YES];
}

- (void)enableButton:(id)btSender
{
    NSButton *btTool = btSender;
    
    if(!btTool) return;
    
    if(m_btnOldSelected)  [m_btnOldSelected setState:NSOffState];
    
    [btTool setState:NSOnState];
    
    m_btnOldSelected = btTool;
}
@end
