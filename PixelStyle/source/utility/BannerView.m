#import "BannerView.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSWarning.h"

@implementation BannerView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        m_strBannerText = [[NSString string] retain];
		m_nBannerImportance = kVeryLowImportance;
    }
    return self;
}

- (void)dealloc
{
	[m_strBannerText release];
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    // We use images for the backgrounds
	NSImage *background = NULL;
	switch(m_nBannerImportance){
		case kUIImportance:
			background = [NSImage imageNamed:@"floatbar"];
			break;
		case kHighImportance:
			background = [NSImage imageNamed:@"errorbar"];
			break;
        case kVeryLowImportance:
            background = [NSImage imageNamed:@"info-win-backer-2"];
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
	
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, [NSColor lightGrayColor], NSForegroundColorAttributeName, shadow ,NSShadowAttributeName ,nil];
    
	
	// We need to calculate the width of the text box
	NSRect drawRect = NSMakeRect(10, 8, [self frame].size.width, 18);
    if(!m_idAlternateButton && !m_idDefaultButton)
       drawRect.size.width -= 0; //bottum info bar
	else if([m_idAlternateButton frame].origin.x < [self frame].size.width){
		drawRect.size.width -= 232;
	}else if ([m_idDefaultButton frame].origin.x < [self frame].size.width){
		drawRect.size.width -= 124;
	}
	
    if (m_nBannerImportance == kVeryLowImportance) {
        NSDictionary *attrsHigh = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12] , NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, shadow ,NSShadowAttributeName ,nil];
        NSMutableAttributedString *mutAttriString = [[NSMutableAttributedString alloc] initWithString:m_strBannerText attributes:attrs];
        
        NSArray *patterns = [NSArray arrayWithObjects:@"Opt", @"Shift", @"Click", @"Drag", @"\\]", @"\\[", @"Command", @"Ctrl", @"Double-Click", @"Double Click", nil];
        
        for (int i = 0; i < [patterns count]; i++) {
            NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:[patterns objectAtIndex:i] options:NSRegularExpressionCaseInsensitive error:nil];
            
            [regularExpression enumerateMatchesInString:mutAttriString.string options:0 range:NSMakeRange(0, mutAttriString.string.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
                [mutAttriString setAttributes:attrsHigh range:result.range];
                
            }];
        }
        
        [mutAttriString drawInRect:drawRect];
        
    }else{
        [m_strBannerText drawInRect: drawRect withAttributes:attrs];
        if(drawRect.size.width < [m_strBannerText sizeWithAttributes:attrs].width){
            [@"..." drawInRect:NSMakeRect(drawRect.size.width + 8, 8, 18, 18) withAttributes:attrs];
        }
    }
    
	[NSGraphicsContext restoreGraphicsState];
}

- (NSArray*)getAllRangesOfSubstring:(NSString*)subStr FromFull:(NSString*)fullStr
{
    NSMutableArray *ranges = [[[NSMutableArray alloc] init] autorelease];
    int index = 0;
    NSString *lastStr = [fullStr substringFromIndex:index];
    NSRange range = [lastStr rangeOfString:subStr options:NSCaseInsensitiveSearch];
//    NSRange searchRange = NSMakeRange(index, <#NSUInteger len#>)
//    while (range.location != NSNotFound) {
//        [ranges addObject:[NSValue valueWithRange:range]];
//        lastStr = [fullStr substringFromIndex:index];
//        range = [lastStr rangeOfString:subStr options:NSCaseInsensitiveSearch range:<#(NSRange)#>];
//        
//    }
    
    return ranges;
}

- (void)setBannerText:(NSString *)text defaultButtonText:(NSString *)dText alternateButtonText:(NSString *)aText andImportance:(int)importance
{
	[m_strBannerText release];
	m_strBannerText = [text retain];
	m_nBannerImportance = importance;
	
	if(dText){
		[m_idDefaultButton setTitle:dText];
		NSRect frame = [m_idDefaultButton frame];
		frame.origin.x = [self frame].size.width - 108;
		[m_idDefaultButton setFrame:frame];
	}else{
		NSRect frame = [m_idDefaultButton frame];
		frame.origin.x = [self frame].size.width;
		[m_idDefaultButton setFrame:frame];
	}
		
	if(aText && dText){
		[m_idAlternateButton setTitle:aText];
		NSRect frame = [m_idAlternateButton frame];
		frame.origin.x = [self frame].size.width - 216;
		[m_idAlternateButton setFrame:frame];
	}else {
		NSRect frame = [m_idAlternateButton frame];
		frame.origin.x = [self frame].size.width;
		[m_idAlternateButton setFrame:frame];
	}
	[self setNeedsDisplay: YES];
}
@end
