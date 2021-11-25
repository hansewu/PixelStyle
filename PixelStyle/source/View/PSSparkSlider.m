//
//  PSSparkSlider.m

#import "PSSparkSlider.h"
#import "WDUtilities.h"
#import "NSViewAdditions.h"
#import "PSStrokeLineTypeController.h"

#define kValueLabelHeight   20
#define kTitleLabelHeight   18
#define kBarInset           8
#define kBarHeight          1
#define kDragDampening      1.5

@implementation PSSparkSlider

@synthesize title = title_;
@synthesize value = value_;
@synthesize minValue = minValue_;
@synthesize maxValue = maxValue_;

- (void) awakeFromNib
{
    self.layer.opaque = NO;
    self.layer.backgroundColor = nil;
    
    // set up the label that indicates the current value
    CGRect frame = self.bounds;
    frame.size.height = kValueLabelHeight;
    
    
    valueLabel_ = [[NSTextField alloc] initWithFrame:frame];
    
    valueLabel_.layer.opaque = NO;
    valueLabel_.layer.backgroundColor = nil;
    valueLabel_.stringValue = @"0 pt";
    valueLabel_.bordered = NO;
    valueLabel_.drawsBackground = NO;
    valueLabel_.font = [NSFont systemFontOfSize:13];
    valueLabel_.textColor = [NSColor whiteColor];
    valueLabel_.editable = NO;
    valueLabel_.cell.alignment = NSTextAlignmentCenter;
    
    [self addSubview:valueLabel_];
    [valueLabel_ release];
    
    
    // set up the title label
    frame = self.bounds;
    frame.origin.y = CGRectGetMaxY(frame) - kTitleLabelHeight;
    frame.size.height = kTitleLabelHeight;
    frame = CGRectInset(frame, -4, 0);
    
    
    title_ = [[NSTextField alloc] initWithFrame:frame];
    
    title_.layer.opaque = NO;
    title_.layer.backgroundColor = nil;
    title_.bordered = NO;
    title_.drawsBackground = NO;
    title_.font = [NSFont systemFontOfSize:13];
    title_.textColor = [NSColor whiteColor];
    title_.editable = NO;
    title_.cell.alignment = NSTextAlignmentCenter;
    //    title_.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:title_];
    [title_ release];

    
    maxValue_ = 100;
}

-(void)setController:(id)controller
{
    if(m_controller) [m_controller release];
    m_controller = [controller retain];
}

-(void)dealloc
{
    if(m_controller) [m_controller release];
    
    [super dealloc];
}

- (CGRect) trackRect
{
    CGRect  trackRect = self.bounds;
    
    trackRect.origin.y += kValueLabelHeight;
    trackRect.size.height -= kValueLabelHeight + kTitleLabelHeight;
    trackRect = CGRectInset(trackRect, kBarInset, 0);
    
    trackRect.origin.y = WDCenterOfRect(trackRect).y;
    trackRect.size.height = kBarHeight;
    
    return trackRect;
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect          trackRect = [self trackRect];
    
    // gray track backround
    [[NSColor colorWithDeviceWhite:0.75f alpha:1.0f] set];
    CGContextFillRect(ctx, trackRect);
    
    // bottom highlight
    [[NSColor colorWithDeviceWhite:1 alpha:0.6] set];
    CGContextFillRect(ctx, CGRectOffset(trackRect, 0,1));
    
    // "progress" bar
    trackRect.size.width *= ((float) value_) / maxValue_;
    [[NSColor blackColor] set];
    CGContextFillRect(ctx, trackRect);
}

- (void) updateIndicator
{
    if (!indicator_) {
//        indicator_ = [[NSImageView alloc] initWithImage:[NSImage imageNamed:@"spark_knob.png"]];
        indicator_ = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 5, 5)];
        [indicator_ setImage:[NSImage imageNamed:@"spark_knob.png"]];
        [self addSubview:indicator_];
        [indicator_ release];
    }
    
    CGRect trackRect = [self trackRect];
    
    trackRect = CGRectInset(trackRect, 2.5f, 0);
    trackRect.size.width *= ((float) value_) / maxValue_;
    
    indicator_.sharpCenter = CGPointMake(CGRectGetMaxX(trackRect), CGRectGetMidY(trackRect));
}

- (NSNumber *) numberValue
{
    return @((int)value_);
}

- (void) setValue:(float)value
{
    if (value == value_) {
        if (!indicator_) {
            // make sure we start in a good state
            [self updateIndicator];
        }
        
        return;
    }

    value_ = value;
    [self setNeedsDisplay:YES];
    
    [self updateIndicator];
    
    int rounded = round(value_);
    valueLabel_.stringValue = [NSString stringWithFormat:@"%d pt", rounded];
}

-(void)mouseDown:(NSEvent *)theEvent
{
    initialValue_ = value_;
    
    dragging_ = YES;
    moved_ = NO;
    
    indicator_.image = [NSImage imageNamed:@"spark_knob_highlighted.png"];
    
    [self setNeedsDisplay:YES];
    
    [self _trackMouse];
    
    return;
}

- (void)_trackMouse
{
    // track!
    NSEvent *event = nil;
    while([event type] != NSLeftMouseUp)
    {
        
//        [self sendAction: [self action] to: [self target]];
        event = [[self window] nextEventMatchingMask: NSLeftMouseDraggedMask | NSLeftMouseUpMask];
        [self mouseDragged:event];
    }
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    CGPoint     delta;
    CGPoint pt = [theEvent locationInWindow];
    pt = [self.window.contentView convertPoint:pt toView:self];
    float       changedValue;
    
    if (!moved_) {
        moved_ = YES;
        initialPt_ = pt;
    }
    
    delta = WDSubtractPoints(pt, initialPt_);
    changedValue = round(initialValue_ + (delta.x / kDragDampening));
    
    if (changedValue < minValue_) {
        changedValue = minValue_;
    } else if (changedValue > maxValue_) {
        changedValue = maxValue_;
    }
    
    self.value = changedValue;
    [m_controller dashChanged:nil];
    return [super mouseDragged:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    dragging_ = NO;
    [self setNeedsDisplay:YES];
    
    indicator_.image = [NSImage imageNamed:@"spark_knob.png"];
    
    [m_controller dashChanged:nil];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"dashChanged" object:nil];
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [super mouseUp:theEvent];
}

//- (void)cancelTrackingWithEvent:(UIEvent *)event
//{
//    dragging_ = NO;
//    [self setNeedsDisplay];
//    
//    indicator_.image = [UIImage imageNamed:@"spark_knob.png"];
//}

@end
