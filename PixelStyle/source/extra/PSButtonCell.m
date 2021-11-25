//
//  PSButtonCell.m
//  PixelStyle
//
//  Created by wyl on 15/12/4.
//
//

#import "PSButtonCell.h"
#import "ConfigureInfo.h"

@implementation PSButtonCell

-(void)awakeFromNib
{
    NSMutableAttributedString *colorTitle = [[[NSMutableAttributedString alloc] initWithString:[self title]] autorelease];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:TEXT_COLOR range:titleRange];
    [colorTitle setAlignment:[self alignment] range:titleRange];
    [colorTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:TEXT_FONT_SIZE] range:titleRange];
    [self setAttributedTitle:colorTitle];
}

-(void)setTitle:(NSString *)title
{
    NSMutableAttributedString *colorTitle = [[[NSMutableAttributedString alloc] initWithString:title] autorelease];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:TEXT_COLOR range:titleRange];
    [colorTitle setAlignment:[self alignment] range:titleRange];
    [colorTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:TEXT_FONT_SIZE] range:titleRange];
    [super setAttributedTitle:colorTitle];
}

@end


@implementation PSButtonImageCell

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(context);
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:cellFrame.size.height];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];

    NSImage *image = [NSImage imageNamed:@"btn-l"];
    CGRect rect = CGRectMake(0, 0, 5, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);

    image = [NSImage imageNamed:@"btn-m"];
    rect = CGRectMake(5, 0, cellFrame.size.width - 10, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);

    image = [NSImage imageNamed:@"btn-r"];
    rect = CGRectMake(cellFrame.size.width - 5, 0, 5, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);

    CGContextRestoreGState(context);

    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:cellFrame]  inView:controlView];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if(!flag)
    {
        [self drawWithFrame:cellFrame inView:controlView];
        return;
    }
    
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(context);
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:0 yBy:cellFrame.size.height];
    [transform scaleXBy:1.0 yBy:-1.0];
    [transform concat];
    
    NSImage *image = [NSImage imageNamed:@"btn-a-l"];
    CGRect rect = CGRectMake(0, 0, 5, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);
    
    image = [NSImage imageNamed:@"btn-a-m"];
    rect = CGRectMake(5, 0, cellFrame.size.width - 10, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);
    
    image = [NSImage imageNamed:@"btn-a-r"];
    rect = CGRectMake(cellFrame.size.width - 5, 0, 5, cellFrame.size.height);
    CGContextDrawImage(context, rect, [image CGImageForProposedRect:nil context:nil hints:nil]);
    
    CGContextRestoreGState(context);
    
    [super drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:cellFrame]  inView:controlView];
}

- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    CGFloat fontSize = self.font.boundingRectForFont.size.height;
    NSInteger offset = floor((NSHeight(frame) - floor(fontSize))/2);
    NSRect centeredRect = NSInsetRect(frame, 0, offset);
    return centeredRect;
}

-(void)awakeFromNib
{
    [self setBezeled:YES];
    [self setBordered:NO];
    [self setButtonType:NSMomentaryChangeButton];
    
    NSMutableAttributedString *colorTitle = [[[NSMutableAttributedString alloc] initWithString:[self title]] autorelease];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:TEXT_COLOR range:titleRange];
    [colorTitle setAlignment:[self alignment] range:titleRange];
    [colorTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:TEXT_FONT_SIZE] range:titleRange];
    [self setAttributedTitle:colorTitle];
}

-(void)setTitle:(NSString *)title
{
    NSMutableAttributedString *colorTitle = [[[NSMutableAttributedString alloc] initWithString:title] autorelease];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:TEXT_COLOR range:titleRange];
    [colorTitle setAlignment:[self alignment] range:titleRange];
    [colorTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:TEXT_FONT_SIZE] range:titleRange];
    [super setAttributedTitle:colorTitle];
}

@end



@implementation PSPopButtonCell

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
    
    [self drawInteriorWithFrame:[self adjustedFrameToVerticallyCenterText:cellFrame]  inView:controlView];
}


- (NSRect)adjustedFrameToVerticallyCenterText:(NSRect)frame
{
    // super would normally draw text at the top of the cell
    CGFloat fontSize = self.font.boundingRectForFont.size.height;
    NSInteger offset = floor((NSHeight(frame) - floor(fontSize))/2);
    NSRect centeredRect = NSInsetRect(frame, 0, offset);
    return centeredRect;
}

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSMutableAttributedString *colorTitle = [[[NSMutableAttributedString alloc] initWithString:[[self selectedItem] title]] autorelease];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:TEXT_COLOR range:titleRange];
    [colorTitle setAlignment:[self alignment] range:titleRange];
    [colorTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:TEXT_FONT_SIZE] range:titleRange];
    [colorTitle drawInRect:NSMakeRect(4, 3, cellFrame.size.width - 4 - 18, cellFrame.size.height)];
}

-(void)awakeFromNib
{
    [self setFont:[NSFont systemFontOfSize:TEXT_FONT_SIZE]];
    [self setArrowPosition:NSPopUpNoArrow];
    [self setBezeled:YES];
    [self setBordered:NO];
}

@end

#import <CoreImage/CoreImage.h>
@implementation PSPopButton

-(void)awakeFromNib
{
    [self setFont:[NSFont boldSystemFontOfSize:TEXT_FONT_SIZE]];
    
    [self setWantsLayer:YES];
    
//    CIFilter *filter = [CIFilter filterWithName:@"CIFalseColor"];
//    CIColor *color = [CIColor colorWithRed:[TEXT_COLOR redComponent] green:[TEXT_COLOR greenComponent] blue:[TEXT_COLOR blueComponent] alpha:[TEXT_COLOR alphaComponent]];
//    [filter setValue:color forKey:@"inputColor0"];
//    [filter setValue:color forKey:@"inputColor1"];
//    [self setContentFilters:[NSArray arrayWithObject:filter]];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [self setContentFilters:[NSArray arrayWithObject:filter]];
}

@end
