//
//  HelpWindow.m
//  ImageMatting
//
//  Created by wyl on 15/2/7.
//  Copyright (c) 2015年 effectmatrix. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "HelpWindow.h"
#import "ConfigureInfo.h"

#define HELP_VIEW_BOTTOM_HEIGHT 38
#define HELP_VIEW_BUTTON_HEIGHT 38


@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    
    //[[NSAttributedString alloc] initWithString:inString attributes:attributes] size];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:range];
    [attrString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:16] range:range];
//    [attrString addAttribute:NSCursorAttributeName value:[NSCursor pointingHandCursor] range:range];
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    [attrString endEditing];
    
    
    return [attrString autorelease];
}
@end

@implementation HelpWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    
    if (self) {
        
        [self initViews];
    }
    
    return self;
}


-(void)setHyperlinkWithTextField:(NSTextField*)inTextField title:(NSString*)title url:(NSString*)urlString
{
    // both are needed, otherwise hyperlink won't accept mousedown
    [inTextField setAllowsEditingTextAttributes: YES];
    [inTextField setSelectable: YES];
    
    NSURL* url = [NSURL URLWithString:urlString];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:title withURL:url]];
    
    // set the attributed string to the NSTextField
    [inTextField setAttributedStringValue: string];
    [string release];
}

-(void)initViews
{
    NSString *sProductName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    
    self.title = [NSString stringWithFormat:@"%@ Tutorial",sProductName];
    
    self.delegate = self;
    
    NSView *view = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)] autorelease];
    
    
    WebView *urlView = [[[WebView alloc] initWithFrame:NSMakeRect(0, HELP_VIEW_BOTTOM_HEIGHT, self.frame.size.width, self.frame.size.height - HELP_VIEW_BOTTOM_HEIGHT)] autorelease];
    
    NSURL *url = [NSURL URLWithString:URL_PRODUCT];
    NSURLRequest *requestUrl = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [[urlView mainFrame] loadRequest:requestUrl];    
    [view addSubview:urlView];
    
    
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, HELP_VIEW_BOTTOM_HEIGHT)] autorelease];
    
    NSImage *bottomImage = [[[NSImage alloc] initWithSize:NSMakeSize(self.frame.size.width, HELP_VIEW_BOTTOM_HEIGHT)] autorelease];
    [bottomImage lockFocus];
    
    float fRadius = 0.0;
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    [bezierPath moveToPoint:NSMakePoint(0, fRadius)];
    [bezierPath lineToPoint:NSMakePoint(0,  bottomImage.size.height)];
    [bezierPath lineToPoint:NSMakePoint(bottomImage.size.width, bottomImage.size.height)];
    [bezierPath lineToPoint:NSMakePoint(bottomImage.size.width, fRadius)];
    //[bezierPath appendBezierPathWithArcWithCenter:NSMakePoint(bottomImage.size.width - fRadius, fRadius) radius:fRadius startAngle:0 endAngle:PI/2.0 clockwise:YES];
    [bezierPath lineToPoint:NSMakePoint(bottomImage.size.width - fRadius, 0)];
    [bezierPath lineToPoint:NSMakePoint(fRadius, 0)];
    //[bezierPath appendBezierPathWithArcWithCenter:NSMakePoint(fRadius, fRadius) radius:fRadius startAngle:PI/2.0 endAngle:PI clockwise:YES];
    
    [[NSColor colorWithCalibratedWhite:0.25 alpha:1.0] set];
    [bezierPath fill];
    
    [bottomImage unlockFocus];
    [imageView setImage:bottomImage];
    
    [view addSubview:imageView];
    
    //NSFont *font = [NSFont fontWithName:@"Arial" size:16];
    NSString *title = [NSString stringWithFormat:@"Welcome to %@ Forum", sProductName];
    m_forumField = [[[NSTextField alloc] initWithFrame:NSMakeRect(32, 7, 230, 20)] autorelease];
    [m_forumField setEditable:NO];
    [m_forumField setBordered:NO];
    [m_forumField setBackgroundColor:[NSColor clearColor]];
    //[m_forumField setFont:font];
    
    [m_forumField setBezelStyle:NSRegularSquareBezelStyle];
    [self setHyperlinkWithTextField:m_forumField title:title url:URL_FORUM];
    [view addSubview:m_forumField];
    
    int originx = self.frame.size.width - 200;
    m_checkButton = [[NSButton alloc] initWithFrame:NSMakeRect(originx, 0, 200, HELP_VIEW_BUTTON_HEIGHT)];
    [m_checkButton setBezelStyle:NSRegularSquareBezelStyle];
    [m_checkButton setButtonType:NSSwitchButton];
    [m_checkButton setBordered:NO];
    [m_checkButton setAction:@selector(setHideHelpWindow:)];
    [m_checkButton setTitle:@" Don't show this on startup"];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc]
                                            initWithAttributedString:[m_checkButton attributedTitle]];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    [attrTitle addAttribute:NSForegroundColorAttributeName
                      value:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1]
                      range:range];
    [attrTitle fixAttributesInRange:range];
    [m_checkButton setAttributedTitle:attrTitle];
    [attrTitle release];
    
    
    [m_checkButton setTarget:self];
    [m_checkButton setImagePosition:NSImageLeft];
    [view addSubview:m_checkButton];
    
    
    
//    NSButton *closeButton = [[[NSButton alloc] initWithFrame:NSMakeRect(self.frame.size.width - 105, 5, 60, HELP_VIEW_BUTTON_HEIGHT - 2*5)] autorelease];
//    [closeButton setBordered:NO];
//    [closeButton setImage:[NSImage imageNamed:@"mat-close.png"]];
//    [closeButton setAction:@selector(closeHelpWindow:)];
//    [closeButton setTitle:@"Close"];
//    [closeButton setTarget:self];
//    [closeButton setImagePosition:NSImageOverlaps];
//    [closeButton.cell setImageScaling:NSImageScaleAxesIndependently
//     ];
//    [closeButton setBezelStyle:NSRoundedBezelStyle];
//    [view addSubview:closeButton];
    
    
    [self setContentView:view];
    
    NSTrackingArea *trackingArea = [[[NSTrackingArea alloc] initWithRect:m_forumField.frame options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited owner:self userInfo:nil] autorelease];
    [view addTrackingArea:trackingArea];
}

-(void)setHideHelpWindow:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    bool bHide = [btn state];
    
    
    [[NSUserDefaults standardUserDefaults] setBool:bHide forKey:@"HidePixelStyleHelpWindow"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)closeHelpWindow:(id)sender
{
    [self close];
}

-(void)hideCheckButton:(BOOL)bHide
{
    [m_checkButton setHidden:bHide];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModal];
}


-(void)dealloc
{
    if (m_checkButton)
    {
        [m_checkButton release];
        m_checkButton = nil;
    }
    
    [super dealloc];
}

# pragma mark - Mouse Events
-(void)mouseEntered:(NSEvent *)theEvent
{
    [[NSCursor pointingHandCursor] set];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    [[NSCursor arrowCursor] set];
//    [self setHyperlinkWithTextField:m_forumField title:@"Welcome to PixelStyle Forum" url:URL_FORUM];
}

@end
