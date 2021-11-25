//
//  PSTextFieldCell.m
//  PixelStyle
//
//  Created by wyl on 15/12/3.
//
//

#import "PSTextFieldCell.h"
#import "ConfigureInfo.h"

@implementation PSTextFieldCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTextColor:TEXT_COLOR];
        
        [self setBordered:NO];
        
        [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
        [self setDrawsBackground:NO];
        [self setFocusRingType:NSFocusRingTypeNone];
    }
    return self;
}

- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    CGFloat fontSize = self.font.boundingRectForFont.size.height;
    NSInteger offset = floor((NSHeight(frame) - floor(fontSize))/2);
    NSRect centeredRect = NSInsetRect(frame, 0, offset-1);
    return centeredRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView
               editor:(NSText *)editor delegate:(id)delegate event:(NSEvent *)event
{
    [super editWithFrame:[self adjustedFrameToVerticallyCenterText:aRect]
                  inView:controlView editor:editor delegate:delegate event:event];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView
                 editor:(NSText *)editor delegate:(id)delegate
                  start:(NSInteger)start length:(NSInteger)length
{
    
    [super selectWithFrame:[self adjustedFrameToVerticallyCenterText:aRect]
                    inView:controlView editor:editor delegate:delegate
                     start:start length:length];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColorWithColor(context, [TEXT_BACKGROUND_COLOR CGColor]);
    CGContextFillRect(context, NSRectToCGRect(cellFrame));
    
    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:cellFrame] inView:controlView];
}

-(void)awakeFromNib
{
    [self setTextColor:TEXT_COLOR];
    [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
    [self setDrawsBackground:NO];
    [self setFocusRingType:NSFocusRingTypeNone];
}

//重写该方法实现对光标颜色的修改
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
    NSText *text = [super setUpFieldEditorAttributes:textObj];
    [(NSTextView*)text setInsertionPointColor:[NSColor whiteColor]];
    
    return text;
}

@end


@implementation PSTextFieldLabelCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTextColor:TEXT_COLOR];
        [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
    }
    return self;
}

- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    CGFloat fontSize = self.font.boundingRectForFont.size.height;
    NSInteger offset = floor((NSHeight(frame) - floor(fontSize))/2);
    NSRect centeredRect = NSInsetRect(frame, 0, offset);
    return centeredRect;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView
               editor:(NSText *)editor delegate:(id)delegate event:(NSEvent *)event
{
    [super editWithFrame:[self adjustedFrameToVerticallyCenterText:aRect]
                  inView:controlView editor:editor delegate:delegate event:event];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView
                 editor:(NSText *)editor delegate:(id)delegate
                  start:(NSInteger)start length:(NSInteger)length
{
    
    [super selectWithFrame:[self adjustedFrameToVerticallyCenterText:aRect]
                    inView:controlView editor:editor delegate:delegate
                     start:start length:length];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:cellFrame] inView:controlView];
}

-(void)awakeFromNib
{
    [self setTextColor:TEXT_COLOR];
    [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
}



@end


@implementation PSColorTextFieldCell


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColorWithColor(context, [TEXT_BACKGROUND_COLOR CGColor]);
    CGContextFillRect(context, NSRectToCGRect(cellFrame));
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

-(void)awakeFromNib
{
    [self setTextColor:TEXT_COLOR];
    [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
    [self setDrawsBackground:NO];
    [self setFocusRingType:NSFocusRingTypeNone];
    
    NSAttributedString *string = [[[NSAttributedString alloc] initWithString:[self placeholderString] attributes:@{ NSFontAttributeName:[NSFont systemFontOfSize:TEXT_FONT_SIZE],NSForegroundColorAttributeName:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5]}] autorelease];
    [self setPlaceholderAttributedString:string];
}

//重写该方法实现对光标颜色的修改
- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
    NSText *text = [super setUpFieldEditorAttributes:textObj];
    [(NSTextView*)text setInsertionPointColor:[NSColor whiteColor]];
    
    return text;
}

@end
