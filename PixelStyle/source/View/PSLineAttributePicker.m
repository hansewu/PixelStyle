//
//  PSLineAttributePicker.m


#import "PSLineAttributePicker.h"
#import "PSStrokeLineTypeController.h"

#define kIconDimension  36
#define kIconSpacing (kIconDimension + 12)

@implementation PSLineAttributePicker

@synthesize cap = cap_;
@synthesize join = join_;
@synthesize mode = mode_;

#define KDefaultColorR 171.0/255
#define KDefaultColorG 200.0/255
#define KDefaultColorB 255.0/255

const CGFloat highlightComponents[] = {171.0/255, 200.0/255, 255.0/255, 1.0};
const CGFloat normalComponents[] = {125.0f / 255.0f, 147.0f / 255.0f, 178.0f / 255.0f, 0.8f};
const CGFloat highlightGray = 0.9f;
const CGFloat normalGray = 0.2f;
const float radius = 3.0f;

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

+ (NSImage *) joinImageWithSize:(CGSize)size join:(CGLineJoin)join highlight:(BOOL)highlight
{
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    NSImage *result = [[NSImage alloc] initWithSize:NSSizeFromCGSize(size) ];
    [result lockFocus];
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    // set this up so that we can set colors via component array
    CGColorSpaceRef strokeColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetStrokeColorSpace(ctx, strokeColorSpace);
    CGColorSpaceRelease(strokeColorSpace);
    
    float x = floor(size.width * 0.4f) + 0.5;
    float y = floor(size.width * 0.4f) + 0.5 - 1;
    int lineWidth = size.width * 0.6f;
    lineWidth += (lineWidth + 1) % 2;
    
    CGContextSetLineJoin(ctx, join);
    
    CGPathMoveToPoint(pathRef, NULL, x, size.height);
    CGPathAddLineToPoint(pathRef, NULL, x, y);
    CGPathAddLineToPoint(pathRef, NULL, size.width, y);
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetLineWidth(ctx, lineWidth);
    CGContextSetStrokeColor(ctx, highlight ? highlightComponents : normalComponents);
    CGContextStrokePath(ctx);
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetLineWidth(ctx, 1);
    CGContextSetGrayStrokeColor(ctx, highlight ? highlightGray : normalGray, 1);
    CGContextStrokePath(ctx);
    
    CGContextSetGrayFillColor(ctx, highlight ? highlightGray : normalGray, 1);
    CGContextAddEllipseInRect(ctx, CGRectMake(x - radius, y - radius, radius * 2, radius * 2));
    CGContextFillPath(ctx);
    
    [result unlockFocus];
    
    CGPathRelease(pathRef);
    
    return [result autorelease];
}

+ (NSImage *) capImageWithSize:(CGSize)size cap:(CGLineCap)cap highlight:(BOOL)highlight
{
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    NSImage *result = [[NSImage alloc] initWithSize:NSSizeFromCGSize(size) ];
    [result lockFocus];
    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    
    // set this up so that we can set colors via component array
    CGColorSpaceRef strokeColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetStrokeColorSpace(ctx, strokeColorSpace);
    CGColorSpaceRelease(strokeColorSpace);
    
    float x = (cap == kCGLineCapButt) ? floor(size.width * 0.25f) : floor(size.width * 0.5f);
    float y = floor(size.width * 0.5f) + 0.5;
    int lineWidth = size.width * 0.9f;
    lineWidth += (lineWidth + 1) % 2;
    
    CGContextSetLineCap(ctx, cap);
    
    CGPathMoveToPoint(pathRef, NULL, size.width, y);
    CGPathAddLineToPoint(pathRef, NULL, cap != kCGLineCapButt ? x - 0.5f : x, y);
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetLineWidth(ctx, lineWidth);
    CGContextSetStrokeColor(ctx, highlight ? highlightComponents : normalComponents);
    CGContextStrokePath(ctx);
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetLineWidth(ctx, 1);
    CGContextSetGrayStrokeColor(ctx, highlight ? highlightGray : normalGray, 1);
    CGContextStrokePath(ctx);
    
    CGContextSetGrayFillColor(ctx, highlight ? highlightGray : normalGray, 1);
    x = round(x) + 0.5f;
    y = round(y) - 0.5f;
    CGContextAddEllipseInRect(ctx, CGRectMake(x - radius, y - radius, radius * 2, radius * 2));
    CGContextFillPath(ctx);
    
    [result unlockFocus];
    
    CGPathRelease(pathRef);
    
    return [result autorelease];
}

- (void) setCap:(CGLineCap)cap
{
    capButton_[cap_].state = NO;
    cap_ = cap;
    capButton_[cap_].state = YES;
}

- (void) setJoin:(CGLineJoin)join
{
    joinButton_[join_].state = NO;
    join_ = join;
    joinButton_[join_].state = YES;
}

- (void) takeJoinFrom:(id)sender
{
    NSButton *button = (NSButton *)sender;
    
    if (button.tag == join_) {
        return;
    }
    
    [self setJoin:(CGLineJoin)button.tag];
//    [self sendActionsForControlEvents:UIControlEventValueChanged];

//    [self sendAction:self.action to:self.target];
    
    [m_controller takeJoinFrom:self];
}

- (void) takeCapFrom:(id)sender
{
    NSButton *button = (NSButton *)sender;
    
    if (button.tag == cap_) {
        return;
    }
    
    [self setCap:(CGLineCap)button.tag];
//    [self sendActionsForControlEvents:UIControlEventValueChanged];
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"takeCapFrom" object:nil];
//    [self sendAction:self.action to:self.target];
    [m_controller takeCapFrom:self];
}

- (void) setMode:(WDStrokeAttributes)mode
{
    NSImage *icon;
    CGRect  frame = CGRectMake(0, 0, kIconDimension, kIconDimension);
    
    mode_ = mode;
    
    if (mode_ == kStrokeJoinAttribute) {
        
        // create join buttons
        
        for (int i = 0; i < 3; i++) {
            joinButton_[i] = [[NSButton alloc] init];
            [joinButton_[i] setButtonType:NSSwitchButton];
            [joinButton_[i] setBezelStyle:NSThickSquareBezelStyle];
            [joinButton_[i] setBordered:NO];
            icon = [PSLineAttributePicker joinImageWithSize:CGSizeMake(kIconDimension, kIconDimension) join:i highlight:NO];
            [joinButton_[i] setImage:icon];
            
            icon = [PSLineAttributePicker joinImageWithSize:CGSizeMake(kIconDimension, kIconDimension) join:i highlight:YES];
            [joinButton_[i] setAlternateImage:icon];
            
            joinButton_[i].tag = i;
            joinButton_[i].state = (i == join_);
            
            [joinButton_[i] setTarget:self];
            [joinButton_[i] setAction:@selector(takeJoinFrom:)];
            
            joinButton_[i].frame = NSRectFromCGRect(frame);
            frame = CGRectOffset(frame, kIconSpacing, 0);
            [self addSubview:joinButton_[i]];
            [joinButton_[i] release];
        }
    } else {
        
        // create cap buttons
        
        for (int i = 0; i < 3; i++) {
            capButton_[i] = [[NSButton alloc] init];
            [capButton_[i] setButtonType:NSSwitchButton];
            [capButton_[i] setBezelStyle:NSThickSquareBezelStyle];
            [capButton_[i] setBordered:NO];
            icon = [PSLineAttributePicker capImageWithSize:CGSizeMake(kIconDimension, kIconDimension) cap:i highlight:NO];
            [capButton_[i] setImage:icon];
            
            icon = [PSLineAttributePicker capImageWithSize:CGSizeMake(kIconDimension, kIconDimension) cap:i highlight:YES];
            [capButton_[i] setAlternateImage:icon];
            
            capButton_[i].tag = i;
            capButton_[i].state = (i == cap_);
            
            [capButton_[i] setTarget:self];
            [capButton_[i] setAction:@selector(takeCapFrom:)];
            
            capButton_[i].frame = NSRectFromCGRect(frame);
            frame = CGRectOffset(frame, kIconSpacing, 0);
            [self addSubview:capButton_[i]];
            [capButton_[i] release];
        }
    }
}

- (void) awakeFromNib
{
    self.layer.backgroundColor = nil;
    self.layer.opaque = NO;
}

@end
