//
//  PSWindow.m
//  PixelStyle
//
//  Created by wyl on 15/12/4.
//
//

#import "PSWindow.h"
#import "ConfigureInfo.h"


@interface MyTitleView : NSView
{
    NSString *m_windowTitle;
}

@property (nonatomic,retain) NSString *m_windowTitle;
@end

@implementation MyTitleView

@synthesize m_windowTitle;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
//    m_windowTitle= NSLocalizedString(@"Untitled", nil);
    
    return self;
}

- (void)drawString:(NSString *)string inRect:(NSRect)rect {
    static NSDictionary *att = nil;
    if (!att) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
        [style setAlignment:NSCenterTextAlignment];
        att = [[NSDictionary alloc] initWithObjectsAndKeys: style, NSParagraphStyleAttributeName,TEXT_COLOR, NSForegroundColorAttributeName,[NSFont systemFontOfSize:TITLE_FONT_SIZE], NSFontAttributeName, nil];
        [style release];
        
    }
    
    NSRect titlebarRect = NSMakeRect(rect.origin.x, rect.origin.y-4, rect.size.width, rect.size.height);
    
    
    [string drawInRect:titlebarRect withAttributes:att];
}


- (void)drawRect:(NSRect)dirtyRect
{
    NSRect windowFrame = [NSWindow  frameRectForContentRect:[[[self window] contentView] bounds] styleMask:[[self window] styleMask]];
    NSRect contentBounds = [[[self window] contentView] bounds];
    
    NSRect titlebarRect = NSMakeRect(0, 0, self.bounds.size.width, windowFrame.size.height - contentBounds.size.height);
    titlebarRect.origin.y = self.bounds.size.height - titlebarRect.size.height;
    
    
    NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4.0 yRadius:4.0];
    [[NSBezierPath bezierPathWithRect:titlebarRect] addClip];
    NSGradient * gradient = [[[NSGradient alloc] initWithStartingColor:WINDOW_TITLE_BAR_BEGIN_COLOR endingColor:WINDOW_TITLE_BAR_END_COLOR] autorelease];
    [path addClip];
 //   [gradient drawInRect:titlebarRect angle:270.0];
    
    m_windowTitle = [[self window] title];
  //  [self drawString:m_windowTitle inRect:titlebarRect];
}

@end

@implementation PSWindow


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    

    if (self) {
        [self setBackgroundColor:[NSColor colorWithDeviceRed:79.0/255.0 green:79.0/255.0  blue:79.0/255.0  alpha:1.0]];
        [self setOpaque:NO];
        
        NSRect boundsRect = [[[self contentView] superview] bounds];
        
//        MyTitleView * titleview = [[MyTitleView alloc] initWithFrame:boundsRect];
//        titleview.m_windowTitle = [self title];
//
//        [titleview setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    //    [titleview setStyleMask:0];
        
    /*    if (NSClassFromString(@"NSTitlebarAccessoryViewController"))
        {
            // 10.10+, use new NSWindow API
            NSTitlebarAccessoryViewController* vc = [[NSTitlebarAccessoryViewController alloc] init];
            
            vc.view = titleview;
            vc.layoutAttribute = NSLayoutAttributeRight;
            
            [[[NSApplication sharedApplication] mainWindow] addTitlebarAccessoryViewController:vc];
        }
        else*/
        {
      //      [[[self contentView] superview] addSubview:titleview positioned:NSWindowBelow relativeTo:[[[[self contentView] superview] subviews] objectAtIndex:0]];
        
        }
        
//        self.movableByWindowBackground = YES;
//        self.titleVisibility = NSWindowTitleHidden;
////        self.titlebarAppearsTransparent = YES;
//        NSView *themeView = [self.contentView superview];
//        if (NSAppKitVersionNumber <= NSAppKitVersionNumber10_9)
//        {
//            [themeView addSubview:titleview positioned:NSWindowBelow relativeTo:[[themeView subviews] objectAtIndex:0]];
//        }
//        else
//        {
//            NSTitlebarAccessoryViewController *vc = [[[NSTitlebarAccessoryViewController alloc] init] autorelease];
//            vc.view = [[[NSView alloc] initWithFrame:((NSView *)self.contentView).frame] autorelease];
//            [self addTitlebarAccessoryViewController:vc];
////            [vc.view addSubview:[[NSButton alloc] initWithFrame:rect]];
//            NSView *containerView = themeView.subviews[1];
//            [containerView addSubview:titleview positioned:NSWindowBelow relativeTo: nil];
//        }
        
      //  [titleview release];
    }
    
    return self;
}


@end



@implementation PSDocmentWindow

-(void)awakeFromNib
{
    NSRect boundsRect = [[[self contentView] superview] bounds];
    NSButton *forumButton = [[NSButton alloc] initWithFrame:NSMakeRect(boundsRect.size.width - 150, boundsRect.size.width - 20, 110, 20)];
    [forumButton setBezelStyle:NSThickSquareBezelStyle];
    [forumButton setBordered:NO];
    
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    [forumButton setTitle:[NSString stringWithFormat:@"%@ %@",sProductName, NSLocalizedString(@"Forum", nil)]];
    [forumButton setImage:[NSImage imageNamed:@"win-btn-bg"]];
    [(NSButtonCell *)forumButton.cell setImageScaling:NSImageScaleAxesIndependently];
    NSMutableAttributedString *attrTitle =[[NSMutableAttributedString alloc] initWithAttributedString:[forumButton attributedTitle]];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:255.0/255.0 green:131.0/255.0 blue:13.0/255.0 alpha:1] range:range];
    [attrTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] range:range];
    [attrTitle fixAttributesInRange:range];
    [forumButton setAttributedTitle:attrTitle];
    [attrTitle release];
    
    [forumButton setAction:@selector(onForum:)];
    [forumButton setTarget:self];
   
//    [self addViewToTitleBar:forumButton atXPosition:70]; // wzq
    
    [forumButton release];
    
//    [self addSEOButtons];
}

-(IBAction)onForum:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL_PRODUCT]];//URL_FORUM]];
}

//- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
//{
//    //return the unaltered frame, or do some other interesting things
//    return frameRect;
//}

# pragma mark - add SEO UI
-(void)addSEOButtons
{
    NSArray *seoTitles = [[[NSArray alloc] initWithObjects:@"Remove Background", @"Image to Vector", nil] autorelease];
    int nSEOCount = (int)[seoTitles count];
    for (int nIndex = 0; nIndex < nSEOCount; nIndex++)
    {
        NSString *sSEOTitle = [seoTitles objectAtIndex:nIndex];
        NSRect boundsRect = [[[self contentView] superview] bounds];
        NSButton *seoButton = [[NSButton alloc] initWithFrame:NSMakeRect(boundsRect.size.width - 150 - 150*(nSEOCount - nIndex), boundsRect.size.width - 20, 120, 20)];
        [seoButton setTitle:NSLocalizedString(sSEOTitle, nil)];
        
        [seoButton setBezelStyle:NSThickSquareBezelStyle];
        [seoButton setBordered:NO];
        [seoButton setImage:[NSImage imageNamed:@"win-btn-bg"]];
        [(NSButtonCell *)seoButton.cell setImageScaling:NSImageScaleAxesIndependently];
        NSMutableAttributedString *attrTitle =[[NSMutableAttributedString alloc] initWithAttributedString:[seoButton attributedTitle]];
        NSUInteger len = [attrTitle length];
        NSRange range = NSMakeRange(0, len);
        [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:255.0/255.0 green:131.0/255.0 blue:13.0/255.0 alpha:1] range:range];
        [attrTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] range:range];
        [attrTitle fixAttributesInRange:range];
        [seoButton setAttributedTitle:attrTitle];
        [attrTitle release];
        
        SEL sel = nil;
        switch (nIndex)
        {
            case 0:
                sel = @selector(onSEO1:);
                break;
            case 1:
                sel = @selector(onSEO2:);
                break;
            default:
                sel = nil;
                break;
        }
        [seoButton setAction:sel];
        [seoButton setTarget:self];
        
        [self addViewToTitleBar:seoButton atXPosition:70]; // wzq
        
        [seoButton release];
    }
}

-(void)onSEO1:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id966457795"]];
}

-(void)onSEO2:(id)sender
{
   [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/id1152204742"]];
}

@end


@implementation NSWindow (NSWindow_AccessoryView)

-(void)addViewToTitleBar:(NSView*)viewToAdd atXPosition:(CGFloat)x
{
    viewToAdd.frame = NSMakeRect(viewToAdd.frame.origin.x, [[self contentView] frame].size.height + 2, viewToAdd.frame.size.width, [self heightOfTitleBar] - 4);
    
    NSUInteger mask = 0;
    if( viewToAdd.frame.origin.x > self.frame.size.width / 2.0 )
    {
        mask |= NSViewMinXMargin;
    }
    else
    {
        mask |= NSViewMaxXMargin;
    }
    [viewToAdd setAutoresizingMask:mask | NSViewMinYMargin];
    
    [[[self contentView] superview] addSubview:viewToAdd];
}

-(CGFloat)heightOfTitleBar
{
    NSRect outerFrame = [[[self contentView] superview] frame];
    NSRect innerFrame = [[self contentView] frame];
    
    return outerFrame.size.height - innerFrame.size.height;
}

@end




