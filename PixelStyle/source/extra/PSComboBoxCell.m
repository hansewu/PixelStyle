//
//  PSComboBoxCell.m
//  PixelStyle
//
//  Created by wyl on 15/12/4.
//
//

#import "PSComboBoxCell.h"
#import "ConfigureInfo.h"

@implementation PSComboBoxCell


-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(context);
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:cellFrame.size.height];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];

    NSImage *image = [NSImage imageNamed:@"box-left"];
    CGRect rect = CGRectMake(0, 0, 4, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);

    image = [NSImage imageNamed:@"box-midle"];
    rect = CGRectMake(4, 0, cellFrame.size.width - 4 - 18, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);

    image = [NSImage imageNamed:@"box-right"];
    rect = CGRectMake(cellFrame.size.width - 18, 0, 18, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);


    image = [NSImage imageNamed:@"box-down-arrow"];
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);

    CGContextRestoreGState(context);

    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:cellFrame]  inView:controlView];
}


- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
//    CGFloat fontSize = self.font.boundingRectForFont.size.height;
//    NSInteger offset = floor((NSHeight(frame) - floor(fontSize))/2);
//    NSRect centeredRect = NSInsetRect(frame, 0, offset);
    
    CGFloat stringHeight    = self.attributedStringValue.size.height;
    NSRect centeredRect     = [super titleRectForBounds:frame];
    centeredRect.origin.y   = frame.origin.y + ceilf((frame.size.height - stringHeight) / 2.0);
    
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

-(void)awakeFromNib
{
    [self setTextColor:TEXT_COLOR];
    [self setBordered:NO];
    [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
}


@end
