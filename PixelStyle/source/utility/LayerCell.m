#import "LayerCell.h"
#import "NSBezierPath_Extensions.h"
#import "ConfigureInfo.h"

@implementation LayerCell

- (id)init
{
    if (self = [super init]) {
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
        [self setSelectable:YES];
    }
    return self;
}

- (void)dealloc
{
    [m_img release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    LayerCell *cell = (LayerCell *)[super copyWithZone:zone];
    // The image ivar will be directly copied; we need to retain or copy it.
    cell->m_img = [m_img retain];
    return cell;
}

- (void)setImage:(NSImage *)anImage
{
    if (anImage != m_img) {
        [m_img release];
        m_img = [anImage retain];
    }
}

- (NSImage *)image
{
    return m_img;
}

- (NSRect)imageRectForBounds:(NSRect)cellFrame
{
    NSRect result;
    if (m_img != nil) {
        result.size = [m_img size];
        result.origin = cellFrame.origin;
        result.origin.x += 3;
        result.origin.y += ceil((cellFrame.size.height - result.size.height) / 2);
    } else {
        result = NSZeroRect;
    }
    return result;
}

// We could manually implement expansionFrameWithFrame:inView: and drawWithExpansionFrame:inView: or just properly implement titleRectForBounds to get expansion tooltips to automatically work for us
- (NSRect)titleRectForBounds:(NSRect)cellFrame
{
    NSRect result;
    if (m_img != nil) {
        float imageWidth = [m_img size].width;
        result = cellFrame;
        result.origin.x += (3 + imageWidth);
        result.size.width -= (3 + imageWidth);
    } else {
        result = NSZeroRect;
    }
    return result;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame, imageFrame;

    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [m_img size].width, NSMinXEdge);
    [super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [m_img size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (m_img != nil)
    {
		[NSGraphicsContext saveGraphicsState];
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset: NSMakeSize(1, 1)];
		[shadow setShadowBlurRadius:2];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow set];
		
		NSRect	imageFrame;
        NSSize imageSize = [m_img size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 8 + imageSize.width, NSMinXEdge);
        if ([self drawsBackground])
        {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;
		
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);

        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(imageSize.width, imageSize.height)] autorelease];
        [image lockFocus];
        [[NSColor colorWithPatternImage:[NSImage imageNamed:@"checkerboard1"]] set];
        NSRectFill(NSMakeRect(0, 0, imageSize.width, imageSize.height));
        [image unlockFocus];
        
        [image drawInRect:NSMakeRect(imageFrame.origin.x, imageFrame.origin.y - imageSize.height, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
        
//        [[NSImage imageNamed:@"checkerboard"] drawInRect:NSMakeRect(imageFrame.origin.x, imageFrame.origin.y - imageSize.height, imageSize.width, imageSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1.0];
        
        
        

		cellFrame.size.height = 18;
		cellFrame.origin.y += 10;
		NSDictionary *attrs;
        NSRect textRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + (cellFrame.size.height - 14)/2.0, cellFrame.size.width, 14);
		if(m_bSelected)
        {
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:TEXT_FONT_SIZE] , NSFontAttributeName, TEXT_COLOR, NSForegroundColorAttributeName, nil];
			[[self stringValue] drawInRect:textRect withAttributes:attrs];
			[NSGraphicsContext restoreGraphicsState];
		}
        else
        {
			[NSGraphicsContext restoreGraphicsState];
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:TEXT_FONT_SIZE] , NSFontAttributeName, TEXT_COLOR, NSForegroundColorAttributeName, nil];
			[[self stringValue] drawInRect:textRect withAttributes:attrs];
		}
		
        [m_img compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
	}
    else
    {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (m_img ? [m_img size].width : 0) + 3;
    return cellSize;
}

- (void) setSelected:(BOOL)isSelected
{
	m_bSelected = isSelected;
}

@end
