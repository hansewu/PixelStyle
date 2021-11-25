#import <time.h>
#import "TextTool.h"
#import "PSTextLayer.h"
#import "PSWhiteboard.h"
#import "PSDocument.h"
#import "PSView.h"
#import "PSContent.h"
#import "StandardMerge.h"
#import "PSTools.h"
#import "PSHelpers.h"
#import "VectorOptions.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "UtilitiesManager.h"
#import "TextureUtility.h"
#import "PSTexture.h"
#import "Bucket.h"
#import "Bitmap.h"
#import "OptionsUtility.h"
#import "PSTextInputView.h"
#import "ToolboxUtility.h"
#import "TextOptions.h"

extern id gNewFont;

@implementation TextTool

- (int)toolId
{
    return kTextTool;
}

-(NSString *)toolTip
{
    return NSLocalizedString(@"Text Tool", nil);
}

-(NSString *)toolShotKey
{
    return @"T";
}

- (id)init
{
    if(![super init])
        return NULL;
    // Set up the font manager
    m_idFontManager = [NSFontManager sharedFontManager];
    m_bRunning      = NO;
    
    m_MouseDownInfo.bMouseDownInArea   = NO;
    m_MouseDownInfo.bMovingText        = NO;
    
    m_timerTextCursor = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                         target:self
                                                       selector:@selector(handleShowTextCursorTimer)
                                                       userInfo:nil
                                                        repeats:YES];
    m_timeIntervalPast = [NSDate timeIntervalSinceReferenceDate];
    
    if(m_cursor) {[m_cursor release]; m_cursor = nil;}
    m_cursor = [[NSCursor IBeamCursor] retain];
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
    
}

- (BOOL)isFineTool
{
    return YES;
}



- (void)shutDown
{
    [m_timerTextCursor invalidate];
    m_timerTextCursor = nil;
}

- (void)fineMouseUpAt:(NSPoint)iwhere withEvent:(NSEvent *)theEvent
{
    if(m_MouseDownInfo.bMovingText)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
        if([layer layerFormat] != PS_TEXT_LAYER)  return;
        
        PSTextLayer *layerVector = (PSTextLayer *)layer;
        IntPoint offset = {iwhere.x - m_MouseDownInfo.pointMouseDown.x, iwhere.y - m_MouseDownInfo.pointMouseDown.y};
        
        //CGPoint pointOld = m_MouseDownInfo.pointOldStart;
        //[layerVector setStartPoint:CGPointMake(pointOld.x + (CGFloat)offset.x, pointOld.y + (CGFloat)offset.y)];
        
        [layerVector setOffsets:IntMakePoint(m_MouseDownInfo.oldOffsets.x + offset.x, m_MouseDownInfo.oldOffsets.y + offset.y)];
        [[m_idDocument helpers] layerOffsetsChanged:kLinkedLayers from:m_MouseDownInfo.oldOffsets];
    }
    
    m_MouseDownInfo.bMouseDownInArea   = NO;
    m_MouseDownInfo.bMovingText        = NO;
  
    
//    PSContent *contents = (PSContent *)[m_idDocument contents];
//    
//    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
//    {
//        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
//        if([layer layerFormat] != PS_TEXT_LAYER)
//            continue;
//        
//        PSTextLayer *layerVector = (PSTextLayer *)layer;
//        CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
//        CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(iwhere), transform);
//        if(CGRectContainsPoint([layerVector getValidRect], pointTransformInvert))//IntPointMakeNSPoint(iwhere)))
//        {
//            if([[m_idDocument contents] activeLayer] != layer)
//            {
//                [[[m_idDocument contents] activeLayer] setLinked:NO]; //add by wyl
//                [[m_idDocument helpers] activeLayerWillChange];
//                [contents setActiveLayerIndex:[layer index]];
//                [[m_idDocument helpers] activeLayerChanged:kLayerSwitched rect:NULL];
//            }
//            
//            return;
//            
//        }
//    }
//    
//    [contents addTextLayer:kActiveLayer atPoint:iwhere ];//IntPointMakeNSPoint(iwhere)];
    
    
    return;
    
}

- (void)fineMouseDownAt:(NSPoint)iwhere withEvent:(NSEvent *)event
{
    m_MouseDownInfo.bMouseDownInArea   = NO;
    m_MouseDownInfo.bMovingText        = NO;
    
    PSContent *contents = (PSContent *)[m_idDocument contents];
    BOOL hasTextLayer = NO;
    for (int whichLayer = 0; whichLayer < [contents layerCount]; whichLayer++)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[contents layer:whichLayer];
        if([layer layerFormat] != PS_TEXT_LAYER || ![layer visible])
            continue;
        
        PSTextLayer *layerVector = (PSTextLayer *)layer;
        CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
        CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(iwhere), transform);
        if(CGRectContainsPoint([layerVector getValidRect], pointTransformInvert))//IntPointMakeNSPoint(iwhere)))
        {
            if([[m_idDocument contents] activeLayer] != layer)
            {
                [contents setActiveLayerIndexComplete:[layer index]];
            }
            hasTextLayer = YES;
            break;
            
        }
    }
    if (!hasTextLayer) {
        NSView *docView = [m_idDocument docView];
        NSPoint point = [docView convertPoint:[event locationInWindow] fromView:NULL];
        if (NSPointInRect(point, docView.bounds)){
            [contents addTextLayer:kActiveLayer atPoint:iwhere ];
        }else{
            return;
        }
        
    }
    
   
    
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    CGAffineTransform transform = CGAffineTransformInvert([layerVector transform]);
    CGPoint pointTransformInvert = CGPointApplyAffineTransform(NSPointToCGPoint(iwhere), transform);
    if(CGRectContainsPoint([layerVector getValidRect], pointTransformInvert)) //IntPointMakeNSPoint(iwhere)))
    {
        m_MouseDownInfo.bMouseDownInArea   = YES;
        m_MouseDownInfo.bMovingText        = NO;
        m_MouseDownInfo.pointMouseDown    = iwhere;
        
        m_MouseDownInfo.timeMouseDown      = [[NSDate date] timeIntervalSince1970];
        m_MouseDownInfo.pointOldStart      = [layerVector getStartPoint];
        
        m_MouseDownInfo.oldOffsets.x = [layerVector xoff];
        m_MouseDownInfo.oldOffsets.y = [layerVector yoff];
        
    }
}

- (void)undoToOrigin:(IntPoint)origin forLayer:(int)index
{
    IntPoint oldOffsets;
    id layer = [[m_idDocument contents] layer:index];
    
    oldOffsets.x = [layer xoff]; oldOffsets.y = [layer yoff];
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoToOrigin:oldOffsets forLayer:index];
    [layer setOffsets:origin];
    [[m_idDocument helpers] layerOffsetsChanged:index from:oldOffsets];
}

- (void)fineMouseDraggedTo:(NSPoint)where withEvent:(NSEvent *)event
{
    if(m_MouseDownInfo.bMouseDownInArea && m_MouseDownInfo.bMovingText == NO && [[NSDate date] timeIntervalSince1970] - m_MouseDownInfo.timeMouseDown > 0.3)
    {
        m_MouseDownInfo.bMovingText        = YES;
        
        //NSLog(@"%f %f",m_MouseDownInfo.timeMouseDown, [[NSDate date] timeIntervalSince1970]);
        int layer = [[m_idDocument contents] activeLayerIndex];
        [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoToOrigin:m_MouseDownInfo.oldOffsets forLayer:layer];
    }
    
    if(m_MouseDownInfo.bMovingText)
    {
        PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
        if([layer layerFormat] != PS_TEXT_LAYER)  return;
        
        PSTextLayer *layerVector = (PSTextLayer *)layer;
        
        IntPoint offset = {where.x - m_MouseDownInfo.pointMouseDown.x, where.y - m_MouseDownInfo.pointMouseDown.y};
        
        //CGPoint pointOld = m_MouseDownInfo.pointOldStart;
        //[layerVector setStartPoint:CGPointMake(pointOld.x + (CGFloat)offset.x, pointOld.y + (CGFloat)offset.y)];
        
        [layerVector setOffsets:IntMakePoint(m_MouseDownInfo.oldOffsets.x + offset.x, m_MouseDownInfo.oldOffsets.y + offset.y)];
        [[m_idDocument helpers] layerOffsetsChanged:kLinkedLayers from:m_MouseDownInfo.oldOffsets];
    }
}

-(void)fontFramilySelected:(NSString *)strFamilyName fontName:(NSString *)strFontName
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFontName:strFontName];
}

- (void)insertText:(id)aString
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    if(!m_textInputView) return;
    
    NSRange replacementRange = {NSNotFound, 0};
    [m_textInputView insertText:aString replacementRange:replacementRange];
}

- (void)changeFontColor:(NSColor *)color
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFillColor:color];
}

- (void)changeFontBold:(int)nWidth
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFontBold:nWidth];
}
- (void)changeFontItalics:(int)nItalicsValue
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFontItalics:nItalicsValue];
}
- (void)changeFontUnderline:(int)nUnderlineValue
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFontUnderline:nUnderlineValue];
}
- (void)changeFontStrikethrough:(int)nStrikethroughValue
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFontStrikethrough:nStrikethroughValue];
}

- (void)changeCharacterSpacing:(int)nCharacterSpacing
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setCharacterSpace:nCharacterSpacing];
}

- (void)changeFontSize:(CGFloat)fontSize
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    [layerVector setFontSize:fontSize];
    
    [[m_textInputView window] makeFirstResponder:m_textInputView];
}

- (void)changeCustomTransformType:(int)type
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    
    CUSTOM_TRANSFORM trans = [layerVector getCustomTransform];
    trans.nTransformStyleID = type;
    [layerVector setCustomTransform:trans];
    
    [[m_textInputView window] makeFirstResponder:m_textInputView];
}
- (void)changeCustomTransformValue:(CGFloat)fValue
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    
    CUSTOM_TRANSFORM trans = [layerVector getCustomTransform];
    trans.nBendPercent = (int)fValue;
    [layerVector setCustomTransform:trans];
    
    [[m_textInputView window] makeFirstResponder:m_textInputView];
}

- (void)layerAttributesChanged:(int)nLayerType
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    
    if([layer layerFormat] != PS_TEXT_LAYER)
    {
        if(m_textInputView)
        {
            [m_textInputView removeFromSuperview];
            [m_textInputView release];
            m_textInputView = nil;
        }
        [[[m_idDocument docView] window] makeFirstResponder:[m_idDocument docView]];
        return;
    }
    
    if(m_textInputView)
    {
        [m_textInputView removeFromSuperview];
        [m_textInputView release];
        m_textInputView = nil;
    }
    
    PSTextLayer *layerVector = (PSTextLayer *)layer;
    m_textInputView = [[PSTextInputView alloc] initWithDocument:m_idDocument string:[layerVector getText]];
    [m_textInputView setAutoresizingMask:NSViewWidthSizable |  NSViewHeightSizable];
    [[m_idDocument docView] addSubview:m_textInputView];
    
    [[m_textInputView window] makeFirstResponder:m_textInputView];
    [m_textInputView setDelegateTextInfoNotify:layerVector];
    
    [m_idOptions updtaeUIForFont:[layerVector getFontName]];
    [m_idOptions updateUIForFontSize:[layerVector getFontSize]];
    
    CUSTOM_TRANSFORM trans = [layerVector getCustomTransform];
    [m_idOptions updateUIForCustomTransformType:trans.nTransformStyleID];
    [m_idOptions updateUIForCustomTransformValue:(CGFloat)trans.nBendPercent];
    
    [m_idOptions updtaeUIForFontColor:[layerVector getFillColor]];
    
    [m_idOptions updtaeUIForFontBold:[layerVector getFontBold]];
    [m_idOptions updtaeUIForFontItalics:[layerVector getFontItalics]];
    [m_idOptions updtaeUIForFontUnderline:[layerVector getFontUnderline]];
    [m_idOptions updtaeUIForFontStrikethrough:[layerVector getFontStrikethrough]];
    [m_idOptions updtaeUIForFontCharacterSpacing:[layerVector getCharacterSpace]];
}

-(void)handleShowTextCursorTimer
{
    if (!m_timerTextCursor || ![m_timerTextCursor isValid]) {
        return;
    }
    
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if(curToolIndex != kTextTool || layer == nil || [layer layerFormat] != PS_TEXT_LAYER)
        return;
    
    PSView *view =  (PSView *)[m_idDocument docView];
    [view setNeedsDisplay:YES];
}


- (void)drawToolExtra
{
    static int s_timeBlink = 0;
    int curToolIndex = [[[PSController utilitiesManager] toolboxUtilityFor:m_idDocument] tool];
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if(curToolIndex != kTextTool || layer == nil || [layer visible] == NO||[layer layerFormat] != PS_TEXT_LAYER)
        return;
    
    PSTextLayer *vectorLayer = (PSTextLayer *)layer;
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
    CGContextRef ctx = (CGContextRef)[nsCtx graphicsPort];
    if(ctx == nil)  return;
    
    CGContextSaveGState(ctx);
    //  assert(ctx);
    float xScale, yScale;
    xScale = [[m_idDocument contents] xscale];
    yScale = [[m_idDocument contents] yscale];
    CGContextScaleCTM(ctx, xScale, yScale);
    CGPathRef pathCursor = [vectorLayer getBlinkCursor];
    
    CGContextSetBlendMode(ctx, kCGBlendModeDifference);
    
    NSTimeInterval current = [NSDate timeIntervalSinceReferenceDate];
    if (ABS(current - m_timeIntervalPast) > 0.3) {
        s_timeBlink++;
        m_timeIntervalPast = current;
    }
    
    if(s_timeBlink %2 == 0)
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.8] set];
    else
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
    
    
    
    CGContextAddPath(ctx, pathCursor);
    //CGContextFillPath(ctx);
    CGContextDrawPath(ctx, kCGPathStroke);
    CGContextRestoreGState(ctx);
    
    if(pathCursor) CGPathRelease(pathCursor);
}
/*
 - (IntRect)drawOverlay
 {
 int i, j, k, width, height, spp = [[m_idDocument contents] spp], ispp, ispp2 = 0;
 NSFont *font;
 IntSize fontSize;
 NSDictionary *attributes;
 unsigned char *bitmapData, *bitmapData2 = NULL, *initData, *initData2, *overlay, *data, *replace;
 unsigned char basePixel[4];
 NSColor *color;
 NSString *text;
 IntPoint pos, off;
 id layer, activeTexture = [[[PSController utilitiesManager] textureUtilityFor:m_idDocument] activeTexture];
 NSBitmapImageRep *imageRep, *imageRep2 = NULL;
 
 NSMutableParagraphStyle *paraStyle;
 int slantWidth;
 int outline = [m_idOptions outline];
 
 // Set up the colour
 if ([m_idOptions useTextures])
 color = [activeTexture textureAsNSColor:(spp == 4)];
 else
 color = [[m_idDocument contents] foreground];
 [[m_idDocument whiteboard] setOverlayBehaviour:kReplacingBehaviour];
 [[m_idDocument whiteboard] setOverlayOpacity:255];
 
 // Get the font
 font = (gNewFont) ? gNewFont : [m_idFontManager selectedFont];
 if (font == NULL) return IntMakeRect(0, 0, 0, 0);
 paraStyle = [[NSMutableParagraphStyle alloc] init];
 [paraStyle setAlignment:[m_idOptions alignment]];
 if (outline)
 attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, [NSNumber numberWithInt:outline], NSStrokeWidthAttributeName, NULL];
 else
 attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, color, NSForegroundColorAttributeName, paraStyle, NSParagraphStyleAttributeName, NULL];
 [paraStyle autorelease];
 text = [[m_idTextbox textStorage] string];
 fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
 fontSize.width += [@"x" sizeWithAttributes:attributes].width;
 slantWidth = ceil(MAX(sin([font italicAngle]) * [font pointSize], 0.0));
 if (outline) slantWidth += (outline + 1) / 2;
 fontSize.width += slantWidth * 2;
 overlay = [[m_idDocument whiteboard] overlay];
 replace = [[m_idDocument whiteboard] replace];
 layer = [[m_idDocument contents] activeLayer];
 data = [(PSLayer *)layer getRawData];
 width = [(PSLayer *)layer width];
 height = [(PSLayer *)layer height];
 
 // Determine the position
 switch([m_idOptions alignment])
 {
 case NSRightTextAlignment:
 pos.x = m_sWhere.x - fontSize.width;
 break;
 case NSCenterTextAlignment:
 pos.x = m_sWhere.x - (int)round(fontSize.width / 2);
 break;
 default:
 pos.x = m_sWhere.x;
 break;
 }
 pos.y = m_sWhere.y - [font ascender];
 off.x = [(PSLayer *)layer xoff];
 off.y = [(PSLayer *)layer yoff];
 
 
 // Create the initial data
 if ([m_idOptions allowFringe])
 {
 initData = [[m_idDocument contents] bitmapUnderneath:IntMakeRect(off.x + pos.x, off.y + pos.y, fontSize.width, fontSize.height)];
 initData2 = calloc(fontSize.width * fontSize.height * spp, sizeof(unsigned char));
 }
 else
 {
 initData = malloc(fontSize.width * fontSize.height * spp);
 for (j = 0; j < fontSize.height; j++)
 {
 for (i = 0; i < fontSize.width; i++)
 {
 if (pos.y + j < height && pos.x + i < width)
 {
 for (k = 0; k < spp; k++)
 initData[(j * fontSize.width + i) * spp + k] = data[((pos.y + j) * width + pos.x + i) * spp + k];
 }
 else
 {
 for (k = 0; k < spp; k++)
 initData[(j * fontSize.width + i) * spp + k] = 0;
 }
 }
 }
 }
 
 // Draw the text
 if (![m_idOptions allowFringe]) premultiplyBitmap(spp, initData, initData, fontSize.height * fontSize.width);
 
 imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&initData pixelsWide:fontSize.width pixelsHigh:fontSize.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:fontSize.width * spp bitsPerPixel:8 * spp];
 [NSGraphicsContext saveGraphicsState];
 [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep]];
 [text drawInRect:NSMakeRect(slantWidth, 0.0, fontSize.width - slantWidth, fontSize.height) withAttributes:attributes];
 [NSGraphicsContext restoreGraphicsState];
 
 
 ispp = [imageRep samplesPerPixel];
 bitmapData = [imageRep bitmapData];
 
 int nBitmapWidth    = [imageRep pixelsWide];// [(NSImage *)image size].width;
 int nBitmapHeight   = [imageRep pixelsHigh];//[(NSImage *)image size].height;
 
 if (ispp == 4) unpremultiplyBitmap(ispp, bitmapData, bitmapData, nBitmapHeight * nBitmapWidth);
 if ([m_idOptions allowFringe]) unpremultiplyBitmap(spp, initData, initData, nBitmapHeight * nBitmapWidth);
 
 // Calculate fringe mask
 if ([m_idOptions allowFringe])
 {
 imageRep2 = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&initData2 pixelsWide:fontSize.width pixelsHigh:fontSize.height bitsPerSample:8 samplesPerPixel:spp hasAlpha:YES isPlanar:NO colorSpaceName:(spp == 4) ? NSDeviceRGBColorSpace : NSDeviceWhiteColorSpace bytesPerRow:fontSize.width * spp bitsPerPixel:8 * spp];
 [NSGraphicsContext saveGraphicsState];
 [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep2]];
 [text drawInRect:NSMakeRect(slantWidth, 0.0, fontSize.width - slantWidth, fontSize.height) withAttributes:attributes];
 [NSGraphicsContext restoreGraphicsState];
 
 ispp2 = [imageRep2 samplesPerPixel];
 bitmapData2 = [imageRep2 bitmapData];
 
 if (ispp2 == 4) unpremultiplyBitmap(ispp2, bitmapData2, bitmapData2, [imageRep2 pixelsWide] * [imageRep2 pixelsHigh]);
 }
 
 // Go through all pixels and change them
 basePixel[spp - 1] = 0xFF;
 
 
 for (j = 0; j < nBitmapHeight; j++)
 {
 for (i = 0; i < nBitmapWidth; i++)
 {
 if (pos.x + i >= 0 && pos.y + j >= 0 && pos.x + i < width && pos.y + j < height)
 {
 for (k = 0; k < ispp; k++)
 basePixel[k] = bitmapData[(j * nBitmapWidth + i) * ispp + k];
 for (k = 0; k < spp; k++)
 overlay[((pos.y + j) * width + pos.x + i) * spp + k] = basePixel[k];
 
 if ([m_idOptions allowFringe] && (ispp2 == 2 || ispp2 == 4)) {
 if (bitmapData2[(j * nBitmapWidth + i + 1) * ispp2 - 1] == 0)
 replace[(pos.y + j) * width + pos.x + i] = 0;
 else
 replace[(pos.y + j) * width + pos.x + i] = 255;
 }
 else
 {
 replace[(pos.y + j) * width + pos.x + i] = 255;
 }
 
 }
 }
 }
 
 // Clean-up everything
 
 [imageRep autorelease];
 
 if ([m_idOptions allowFringe])
 {
 [imageRep2 autorelease];
 }
 free(initData);
 
 return IntMakeRect(pos.x, pos.y, fontSize.width, fontSize.height);
 }
 */
- (IBAction)apply:(id)sender
{
    // End the panel
    if (sender != NULL)
    {
        [NSApp stopModal];
        [NSApp endSheet:m_idPanel];
        [m_idPanel orderOut:self];
    }
    m_bRunning = NO;
    
    // Apply the changes
    [[m_idDocument whiteboard] clearOverlay];
    if ([[[m_idTextbox textStorage] string] length] > 0)
    {
        [self drawOverlay];
        [(PSHelpers *)[m_idDocument helpers] applyOverlay];
    }
}

- (IBAction)cancel:(id)sender
{
    // End the panel
    [[m_idDocument whiteboard] clearOverlay];
    if (m_sPreviewRect.size.width != 0)
    {
        [[m_idDocument helpers] overlayChanged:m_sPreviewRect inThread:NO];
    }
    m_bRunning = NO;
    [NSApp stopModal];
    [NSApp endSheet:m_idPanel];
    [m_idPanel orderOut:self];
}

- (IBAction)preview:(id)sender
{
    // Apply the changes
    if (m_bRunning) {
        [[m_idDocument whiteboard] clearOverlay];
        if (m_sPreviewRect.size.width != 0)
        {
            [[m_idDocument helpers] overlayChanged:m_sPreviewRect inThread:NO];
        }
        if ([[[m_idTextbox textStorage] string] length] > 0)
        {
            //        m_sPreviewRect = [self drawOverlay];
            [[m_idDocument helpers] overlayChanged:m_sPreviewRect inThread:NO];
        }
    }
}

- (IBAction)showFonts:(id)sender
{
    [m_idFontManager orderFrontFontPanel:self];
}

- (void)textDidChange:(NSNotification *)notification
{
    PSAbstractLayer *layer = (PSAbstractLayer *)[[m_idDocument contents] activeLayer];
    if([layer layerFormat] != PS_TEXT_LAYER)  return;
    
    /*  PSTextLayer *layerVector = (PSTextLayer *)layer;
     
     NSString *text = [[m_idTextbox textStorage] string];//	[self preview:notification];
     
     [layerVector createTextObjectWithTextAtPath:text at];
     
     [[m_idDocument docView] setNeedsDisplay:YES];
     */
}

- (IBAction)move:(id)sender
{
    [NSApp stopModal];
    [NSApp endSheet:m_idPanel];
    [m_idPanel orderOut:self];
    [NSApp beginSheet:m_idMovePanel modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)doneMove:(id)sender
{
    [NSApp stopModal];
    [NSApp endSheet:m_idMovePanel];
    [m_idMovePanel orderOut:self];
    [self apply:NULL];
}

- (IBAction)cancelMove:(id)sender
{
    [NSApp stopModal];
    [NSApp endSheet:m_idMovePanel];
    [m_idMovePanel orderOut:self];
    [NSApp beginSheet:m_idPanel modalForWindow:[m_idDocument window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

- (void)setNudge:(IntPoint)nudge
{
    m_sWhere.x += nudge.x;
    m_sWhere.y += nudge.y;
    [self preview:NULL];
}

- (void)centerHorizontally
{
    IntSize fontSize;
    NSDictionary *attributes;
    NSString *text;
    int width;
    id layer;
    
    layer = [[m_idDocument contents] activeLayer];
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:[m_idFontManager selectedFont], NSFontAttributeName, NULL];
    text = [[m_idTextbox textStorage] string];
    fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
    width = [(PSLayer *)layer width];
    m_sWhere.x = width / 2 - fontSize.width / 2;
    [self preview:NULL];
}

- (void)centerVertically
{
    IntSize fontSize;
    NSDictionary *attributes;
    NSString *text;
    int height;
    id layer, font;
    
    layer = [[m_idDocument contents] activeLayer];
    font = [m_idFontManager selectedFont];
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, NULL];
    text = [[m_idTextbox textStorage] string];
    fontSize = NSSizeMakeIntSize([text sizeWithAttributes:attributes]);
    height = [(PSLayer *)layer height];
    m_sWhere.y = height / 2 + [font ascender] - fontSize.height / 2;
    [self preview:NULL];
}

- (BOOL)isSupportLayerFormat:(int)nLayerFormat
{
    if(nLayerFormat == PS_VECTOR_LAYER || (nLayerFormat == PS_TEXT_LAYER))
        return YES;
    
    return NO;
}

-(void)checkCurrentLayerIsSupported
{
    return;
}

#pragma mark - Tool Enter/Exit

-(BOOL)exitTool:(int)newTool
{
    if(m_textInputView)
    {
        [m_textInputView removeFromSuperview];
        [m_textInputView release];
        m_textInputView = nil;
    }
    [[[m_idDocument docView] window] makeFirstResponder:[m_idDocument docView]];
    return [super exitTool:newTool];
}

-(BOOL)isAffectedBySelection
{
    return NO;
}

@end
