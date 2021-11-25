//
//  PSVectorOptions.m
//  PixelStyle
//
//  Created by lchzh on 1/4/16.
//
//

#import "PSVectorOptions.h"

#import "PSDocument.h"
#import "PSContent.h"

#import "PSColorWell.h"
#import "PSFillController.h"
#import "PSStrokeController.h"
#import "PSArrowController.h"
#import "PSStrokeLineTypeController.h"

#import "WDDrawingController.h"
#import "WDPropertyManager.h"
#import "WDUtilities.h"
#import "WDStrokeStyle.h"
#import "WDArrowhead.h"

#import "PSHoverButton.h"

@implementation PSVectorOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_labelFill setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Fill", nil)]];
    [m_labelStroke setStringValue:[NSString stringWithFormat:@"%@ :", NSLocalizedString(@"Stroke", nil)]];
    [m_btnNewLayerCheck setTitle:NSLocalizedString(@"New Layer", nil)];
    [m_btnNewLayerCheck setToolTip:NSLocalizedString(@"Draw a path in a new layer", nil)];
    
    [fillWell_ setToolTip:NSLocalizedString(@"Set shape fill type", nil)];
    [strokeWell_ setToolTip:NSLocalizedString(@"Set shape stroke type", nil)];
    [m_btnLineStyle setToolTip:NSLocalizedString(@"Set shape stroke type", nil)];
    [m_btnArrow setToolTip:NSLocalizedString(@"Set shape arrowheads type", nil)];
    
    strokeWell_.strokeMode = YES;
    
    m_fillController = nil;
    if(!m_fillController) m_fillController = [[PSFillController alloc] initWithWindowNibName:@"Fill"];
    
    m_strokeController = nil;
    if(!m_strokeController) m_strokeController = [[PSStrokeController alloc] initWithWindowNibName:@"Stroke"];
    
    m_arrowController = nil;
    if(!m_arrowController) m_arrowController = [[PSArrowController alloc] initWithWindowNibName:@"StrokeArrow"];
    
    
    m_lineTypeController = nil;
    if(!m_lineTypeController) m_lineTypeController = [[PSStrokeLineTypeController alloc] initWithWindowNibName:@"StrokeLineType"];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(fillChanged:) name:WDActiveFillChangedNotification object:nil];
    [nc addObserver:self selector:@selector(strokeStyleChanged:) name:WDActiveStrokeChangedNotification object:nil];
    
    
    [m_popBtnAlign setShowImage:[NSImage imageNamed:@"vector-move-align"]];
    
    [m_popBtnArrange setShowImage:[NSImage imageNamed:@"vector-move-arrange"]];
    
    [m_popBtnPathsMode setShowImage:[NSImage imageNamed:@"vector-move-shape-modes"]];
    
    
    NSMenuItem *menuItem = [(NSPopUpButton *)m_popBtnPathsMode itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Unite Paths", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnPathsMode itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Subtract From Paths", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnPathsMode itemAtIndex:2];
    [menuItem setTitle:NSLocalizedString(@"Intersect Paths", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnPathsMode itemAtIndex:3];
    [menuItem setTitle:NSLocalizedString(@"Exclude Paths", nil)];
    
    
    menuItem = [(NSPopUpButton *)m_popBtnArrange itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Bring to Front", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnArrange itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Bring Forward", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnArrange itemAtIndex:2];
    [menuItem setTitle:NSLocalizedString(@"Send Backward", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnArrange itemAtIndex:3];
    [menuItem setTitle:NSLocalizedString(@"Send to Back", nil)];
    
    menuItem = [(NSPopUpButton *)m_popBtnAlign itemAtIndex:0];
    [menuItem setTitle:NSLocalizedString(@"Align Left", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnAlign itemAtIndex:1];
    [menuItem setTitle:NSLocalizedString(@"Align Horizontal Center", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnAlign itemAtIndex:2];
    [menuItem setTitle:NSLocalizedString(@"Align Right", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnAlign itemAtIndex:4];
    [menuItem setTitle:NSLocalizedString(@"Align Top", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnAlign itemAtIndex:5];
    [menuItem setTitle:NSLocalizedString(@"Align Vertical Center", nil)];
    menuItem = [(NSPopUpButton *)m_popBtnAlign itemAtIndex:6];
    [menuItem setTitle:NSLocalizedString(@"Align Bottom", nil)];
    
    
    
//#ifdef PROPAINT_VERSION
//    [m_popBtnAlign setHidden:YES];
//    [m_popBtnArrange setHidden:YES];
//    [m_popBtnPathsMode setHidden:YES];
//#else
//#endif
}


- (void)dealloc
{
    if(m_fillController) {[m_fillController release]; m_fillController = nil;}
    if(m_strokeController) {[m_strokeController release]; m_strokeController = nil;}
    if(m_arrowController) {[m_arrowController release]; m_arrowController = nil;}
    if(m_lineTypeController) {[m_lineTypeController release]; m_lineTypeController = nil;}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

-(void)activate:(id)sender
{
    [super activate:sender];    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    
    [fillWell_ setPainter:[propertyManager activeFillStyle]];
    [strokeWell_ setPainter:[propertyManager activeStrokeStyle].color];
    [self updateArrowPreview];
    [self updateLineTypePreview];
}



#pragma mark - Notification -
- (void) fillChanged:(NSNotification *)aNotification
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    
    [fillWell_ setPainter:[propertyManager activeFillStyle]];
    
    //[(ShapeTool *)[[m_idDocument tools] getTool:kShapeTool] updatePath];
}

- (void) strokeStyleChanged:(NSNotification *)aNotification
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    
    [strokeWell_ setPainter:[propertyManager activeStrokeStyle].color];
    
    [self updateArrowPreview];
    [self updateLineTypePreview];
    
    //[(ShapeTool *)[[m_idDocument tools] getTool:kShapeTool] updatePath];
}


#pragma mark - Notification - Arrow
- (void) updateArrowPreview
{
    [m_btnArrow setImage:[self arrowPreview]];
    [m_btnArrow setAlternateImage:[self arrowPreview]];
}

- (NSImage *) arrowPreview
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    WDStrokeStyle   *strokeStyle = [propertyManager defaultStrokeStyle];
    NSColor         *color = [NSColor whiteColor];//[NSColor colorWithDeviceRed:0.0f green:(118.0f / 255) blue:1.0f alpha:1.0f];
    WDArrowhead     *arrow;
    CGContextRef    ctx;
    NSSize          size = m_btnArrow.frame.size;
    float           scale = 1.5;//3.0;
    float           y = floor(size.height / 2) + 0.5f;
    float           arrowInset;
    float           stemStart;
    float           stemEnd = 40;
    
    NSImage *result = [[NSImage alloc] initWithSize:size];
    [result lockFocus];
    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [color set];
    CGContextSetLineWidth(ctx, scale);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    // start arrow
    arrow = [WDArrowhead arrowheads][strokeStyle.startArrow];
    arrowInset = arrow.insetLength;
    if (arrow) {
        [arrow addArrowInContext:ctx position:CGPointMake(arrowInset * scale, y)
                           scale:scale angle:M_PI useAdjustment:NO];
        CGContextFillPath(ctx);
        stemStart = arrowInset * scale;
    } else {
        stemStart = 10;
    }
    
    CGContextMoveToPoint(ctx, stemStart, y);
    CGContextAddLineToPoint(ctx, stemEnd, y);
    CGContextStrokePath(ctx);
    
    // end arrow
    arrow = [WDArrowhead arrowheads][strokeStyle.endArrow];
    arrowInset = arrow.insetLength;
    if (arrow) {
        [arrow addArrowInContext:ctx position:CGPointMake(size.width - (arrowInset * scale), y)
                           scale:scale angle:0 useAdjustment:NO];
        CGContextFillPath(ctx);
        stemStart = arrowInset * scale;
    } else {
        stemStart = 10;
    }
    
    CGContextMoveToPoint(ctx, size.width - stemStart, y);
    CGContextAddLineToPoint(ctx, size.width - stemEnd, y);
    CGContextStrokePath(ctx);
    
    // draw interior line
    [[color colorWithAlphaComponent:0.5f] set];
    CGContextMoveToPoint(ctx, stemEnd + 10, y);
    CGContextAddLineToPoint(ctx, size.width - (stemEnd + 10), y);
    CGContextSetLineWidth(ctx, scale - 1);
    CGContextStrokePath(ctx);
    
    //    // draw a label
    //    NSString *label = NSLocalizedString(@"arrowheads", @"arrowheads");
    //    NSDictionary *attrs = @{NSFontAttributeName: [UIFont systemFontOfSize:15.0f],
    //                            NSForegroundColorAttributeName:color};
    //    CGRect bounds = CGRectZero;
    //    bounds.size = [label sizeWithAttributes:attrs];
    //    bounds.origin.x = (size.width - CGRectGetWidth(bounds)) / 2;
    //    bounds.origin.y = (size.height - CGRectGetHeight(bounds)) / 2 - 1;
    //    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    //    CGContextFillRect(ctx, CGRectInset(bounds, -10, -10));
    //    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    //    [label drawInRect:bounds withAttributes:attrs];
    
    [result unlockFocus];
    
    
    return [result autorelease];
}


#pragma mark - Notification - Line Type
-(void)updateLineTypePreview
{
    [m_btnLineStyle setImage:[self strokeLineTypePreview]];
    [m_btnLineStyle setAlternateImage:[self strokeLineTypePreview]];
}

-(NSImage *)strokeLineTypePreview
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    WDPropertyManager *propertyManager = wdDrawingController.propertyManager;
    WDStrokeStyle   *strokeStyle = [propertyManager defaultStrokeStyle];
    NSColor         *color = [NSColor whiteColor];
    CGContextRef    ctx;
    NSSize          size = m_btnLineStyle.frame.size;
    
    float fWidth = strokeStyle.width;
    fWidth = fWidth > 8 ? 8 : fWidth;
    
    CGFloat fDash[4] = {0};
    float sum = 0.0f;
    for (NSNumber *number in strokeStyle.dashPattern) {
        sum += [number floatValue];
    }
    
    BOOL bDash = (strokeStyle.dashPattern && strokeStyle.dashPattern.count && sum > 0) ? 1 : 0;
    
    if (bDash)
    {
        for (int i = 0; i < strokeStyle.dashPattern.count; i++)
        {
            fDash[i] = [strokeStyle.dashPattern[i] floatValue];
        }
    }
    
    
    NSImage *result = [[NSImage alloc] initWithSize:size];
    [result lockFocus];
    ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    [color set];
    CGContextSetLineWidth(ctx, fWidth);
    
    if(bDash)
        CGContextSetLineDash(ctx, 0, fDash, 4);
    CGContextMoveToPoint(ctx, 0, size.height/2.0);
    CGContextAddLineToPoint(ctx, size.width - 40, size.height/2.0);
    CGContextStrokePath(ctx);
    
    // draw a label
    NSString *label = [NSString stringWithFormat:@"%.1f pt", strokeStyle.width];
    NSDictionary *attrs = @{NSFontAttributeName: [NSFont systemFontOfSize:11.0f],
                            NSForegroundColorAttributeName:color};
    CGRect bounds = CGRectZero;
    bounds.size = [label sizeWithAttributes:attrs];
    bounds.origin.x = size.width - 35;
    bounds.origin.y = (size.height - CGRectGetHeight(bounds)) / 2 - 1;
    //    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    //    CGContextFillRect(ctx, CGRectInset(bounds, -10, -10));
    //    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    [label drawInRect:bounds withAttributes:attrs];
    
    [result unlockFocus];
    
    
    return [result autorelease];
    
}


#pragma mark - Actions



- (IBAction)showFillStylePanel:(id)sender
{
    NSWindow *w = [m_idDocument window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    
    if(!m_fillController)  m_fillController = [[PSFillController alloc] initWithWindowNibName:@"Fill"];
    
    if(!m_fillController.drawingController)
    {
        PSContent *contents = (PSContent *)[m_idDocument contents];
        m_fillController.drawingController = [contents wdDrawingController];
    }
    
    [m_fillController showPanelFrom: p onWindow: w];
}

- (IBAction) showStrokeStylePanel:(id)sender
{
    NSWindow *w = [m_idDocument window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    
    if(!m_strokeController)  m_strokeController = [[PSStrokeController alloc] initWithWindowNibName:@"Stroke"];
    
    if(!m_strokeController.drawingController)
    {
        PSContent *contents = (PSContent *)[m_idDocument contents];
        m_strokeController.drawingController = [contents wdDrawingController];
    }
    
    [m_strokeController showPanelFrom: p onWindow: w];
}

- (IBAction)showArrowheads:(id)sender
{
    
    NSWindow *w = [m_idDocument window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    
    if(!m_arrowController)  m_arrowController = [[PSArrowController alloc] initWithWindowNibName:@"StrokeArrow"];
    
    if(!m_arrowController.drawingController)
    {
        PSContent *contents = (PSContent *)[m_idDocument contents];
        m_arrowController.drawingController = [contents wdDrawingController];
    }
    
    [m_arrowController showPanelFrom: p onWindow: w];
}

- (IBAction)showLineStyle:(id)sender
{
    
    NSWindow *w = [m_idDocument window];
    NSPoint p = [w convertBaseToScreen:[w mouseLocationOutsideOfEventStream]];
    
    if(!m_lineTypeController)  m_lineTypeController = [[PSStrokeLineTypeController alloc] initWithWindowNibName:@"StrokeLineType"];
    
    if(!m_lineTypeController.drawingController)
    {
        PSContent *contents = (PSContent *)[m_idDocument contents];
        m_lineTypeController.drawingController = [contents wdDrawingController];
    }
    
    [m_lineTypeController showPanelFrom: p onWindow: w];
}


- (BOOL)isNewLayerOptionEnable
{
    return [m_btnNewLayerCheck state];
}

@end
