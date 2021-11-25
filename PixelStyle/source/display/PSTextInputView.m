//
//  PSTextInputView.m
//  PixelStyle
//
//  Created by wzq on 15/11/3.
//
//

#import "PSTextInputView.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSLayerUndo.h"
#import "PSController.h"
#import "PSView.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDDrawingController.h"
#import "WDInspectableProperties.h"
#import "WDPropertyManager.h"
#import "WDText.h"
#import "WDTextPath.h"
#import "WDFontManager.h"
#import "WDColor.h"
#import "NSString+Additions.h"

@implementation PSTextInputView

- (id)initWithDocument:(id)doc string:(NSString *)strInput
{
    m_idDocument        = doc;
//    m_pointTextStart    = pointStart;
    
    PSView *view        =  (PSView *)[m_idDocument docView];
    NSRect rect         = view.frame;
    
    if ([super initWithFrame:rect] == NULL)
    {
        return NULL;
    }
    
    // Set up the text system
    // Set up text attributes
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSFont *font = [NSFont systemFontOfSize:20];
    
    m_defaultAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                         paragraphStyle, NSParagraphStyleAttributeName,
                         font, NSFontAttributeName,
                         nil];
    m_markedAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                        paragraphStyle, NSParagraphStyleAttributeName,
                        font, NSFontAttributeName,
                        [NSColor lightGrayColor], NSForegroundColorAttributeName,
                        nil];
    [paragraphStyle release];
    m_backingStore = [[NSTextStorage alloc] initWithString:strInput attributes:m_defaultAttributes];
    
    // Initial values for various things
    m_selectedRange = NSMakeRange(strInput.length, 0);
    m_markedRange = NSMakeRange(NSNotFound, 0);
    
    m_delegateInfoNotify= nil;

    
    return self;
}

- (void)dealloc
{
    [m_defaultAttributes release];
    [m_markedAttributes release];
    [m_backingStore release];
    
    [super dealloc];
    

}

- (BOOL)isOpaque
{
    return NO;//YES;//
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
  //  NSColor *bgColor = [NSColor yellowColor ];//clearColor];
  //  [bgColor set];
}


- (void)setDelegateTextInfoNotify:(id) delegateInfoNotify
{
    m_delegateInfoNotify = delegateInfoNotify;
}


- (BOOL)validateMenuItem:(id)menuItem
{
    switch ([menuItem tag])
    {
        case 262: /* Paste */
        {
                NSString *str = [[NSPasteboard generalPasteboard] stringForType:NSPasteboardTypeString];
                if(str != nil)  return YES;
            return NO;
        }
            break;
        default:
            return NO;
        
    }
    
    return YES;
}
/*
- (NSView *)hitTest:(NSPoint)aPoint
{
    NSView* hitView = [super hitTest:aPoint];
    if(hitView)
        return self;
    return nil;
}
*/
- (void)keyDown:(NSEvent *)theEvent
{
    [[self inputContext] handleEvent:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [[self inputContext] handleEvent:theEvent];
    int nIndex = [self characterIndexForPoint:[NSEvent mouseLocation]];
    
    m_selectedRange = NSMakeRange(nIndex, 0);
    
    [m_delegateInfoNotify textCursorPosChanged:m_selectedRange.location];
    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    [[self inputContext] handleEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    [[self inputContext] handleEvent:theEvent];

}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return YES;
}

 - (BOOL)resignFirstResponder
 {
 return YES;
 }

- (void)insertNewline:(id)sender
{
    
}

- (void)deleteBackward:(id)sender
{
    // Find the range to delete, handling an empty selection and the input point being at 0
    NSRange deleteRange = m_selectedRange;
    if (deleteRange.length == 0)
    {
        if (deleteRange.location == 0)
        {
            return;
        }
        else
        {
            deleteRange.location -= 1;
            deleteRange.length = 1;
            
            // Make sure we handle composed characters correctly
            deleteRange = [[m_backingStore string] rangeOfComposedCharacterSequencesForRange:deleteRange];
        }
    }
    
    [self deleteCharactersInRange:deleteRange];
}

- (void)deleteForward:(id)sender
{
    // Find the range to delete, handling an empty selection and the input point being at the end
    NSRange deleteRange = m_selectedRange;
    if (deleteRange.length == 0)
    {
        if (deleteRange.location == [m_backingStore length])
        {
            return;
        }
        else
        {
            deleteRange.length = 1;
            
            // Make sure we handle composed characters correctly
            deleteRange = [[m_backingStore string] rangeOfComposedCharacterSequencesForRange:deleteRange];
        }
    }
    
    [self deleteCharactersInRange:deleteRange];
}

- (void)deleteCharactersInRange:(NSRange)range
{
    // Update the marked range
    if (NSLocationInRange(NSMaxRange(range), m_markedRange))
    {
        m_markedRange.length -= NSMaxRange(range) - m_markedRange.location;
        m_markedRange.location = range.location;
    }
    else if (m_markedRange.location > range.location)
    {
        m_markedRange.location -= range.length;
    }
    
    if (m_markedRange.length == 0)
    {
        [self unmarkText];
    }
    
    // Actually delete the characters
    [m_backingStore deleteCharactersInRange:range];
    m_selectedRange.location = range.location;
    m_selectedRange.length = 0;
    
    [[self inputContext] invalidateCharacterCoordinates];
    
    NSString *text = [m_backingStore string];//	[self preview:notification];
    
    [self setString:text];
    

}



- (void)doCommandBySelector:(SEL)aSelector
{
 //   [m_delegatePSViewText doCommandBySelector:aSelector];
 //   [self setNeedsDisplay:YES];
  //  if([self respondsToSelector:aSelector])
  //      [self performSelector:aSelector withObject:self];
      [super doCommandBySelector:aSelector]; // NSResponder's implementation will do nicely
}

- (void)moveRight:(id)sender
{
    int nlocation = m_selectedRange.location;
    if(nlocation < [m_backingStore length])
        nlocation++;
    
    m_selectedRange = NSMakeRange(nlocation, 0);
    
    [m_delegateInfoNotify textCursorPosChanged:m_selectedRange.location];
    //  [self.view setNeedsDisplay];
}

- (void)moveLeft:(id)sender
{
    int nlocation = m_selectedRange.location;
    if(nlocation > 0)
        nlocation--;
    m_selectedRange = NSMakeRange(nlocation, 0);
    
    [m_delegateInfoNotify textCursorPosChanged:m_selectedRange.location];
    //   [self.view setNeedsDisplay];
}

/*
 - (void)moveRightAndModifySelection:(id)sender
 {
 NSInteger max = [TEXT length];
 _selectionEnd = MIN(_selectionEnd + 1, max);
 [self.view setNeedsDisplay];
 }
 
 - (void)moveLeftAndModifySelection:(id)sender
 {
 NSInteger min = 0;
 _selectionEnd = MAX(_selectionEnd - 1, min);
 [self.view setNeedsDisplay];
 }
 
 - (void)moveWordRight:(id)sender
 {
 _selectionStart = _selectionEnd = [TEXT ab_endOfWordGivenCursor:MAX(_selectionStart, _selectionEnd)];
 [self.view setNeedsDisplay];
 }
 
 - (void)moveWordLeft:(id)sender
 {
 _selectionStart = _selectionEnd = [TEXT ab_beginningOfWordGivenCursor:MIN(_selectionStart, _selectionEnd)];
 [self.view setNeedsDisplay];
 }
 
 - (void)moveWordRightAndModifySelection:(id)sender
 {
 _selectionEnd = [TEXT ab_endOfWordGivenCursor:_selectionEnd];
 [self.view setNeedsDisplay];
 }
 
 - (void)moveWordLeftAndModifySelection:(id)sender
 {
 _selectionEnd = [TEXT ab_beginningOfWordGivenCursor:_selectionEnd];
 [self.view setNeedsDisplay];
 }
 
 - (void)moveToBeginningOfLineAndModifySelection:(id)sender
 {
 _selectionEnd = 0; // fixme for multiline
 [self.view setNeedsDisplay];
 }
 
 - (void)moveToEndOfLineAndModifySelection:(id)sender
 {
 _selectionEnd = [TEXT length]; // fixme for multiline
 [self.view setNeedsDisplay];
 }
 
 - (void)moveToBeginningOfLine:(id)sender
 {
 _selectionStart = _selectionEnd = 0;
 [self.view setNeedsDisplay];
 }
 
 - (void)moveToEndOfLine:(id)sender
 {
 _selectionStart = _selectionEnd = [TEXT length];
 [self.view setNeedsDisplay];
 }
 */

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{

    if (replacementRange.location == NSNotFound)
    {
        if (m_markedRange.location != NSNotFound)
        {
            replacementRange = m_markedRange;
        }
        else
        {
            replacementRange = m_selectedRange;
        }
    }
    
    // Add the text
    [m_backingStore beginEditing];
    if ([aString isKindOfClass:[NSAttributedString class]])
    {
        [m_backingStore replaceCharactersInRange:replacementRange withAttributedString:aString];
    }
    else
    {
        [m_backingStore replaceCharactersInRange:replacementRange withString:aString];
    }
    [m_backingStore setAttributes:m_defaultAttributes range:NSMakeRange(replacementRange.location, [aString length])];
    [m_backingStore endEditing];
    
    // Redisplay
    //  m_selectedRange = NSMakeRange([m_backingStore length], 0); // We don't support selection, so just place the insertion point at the end
    m_selectedRange = NSMakeRange(replacementRange.location+[aString length], 0);
    [self unmarkText];
    [[self inputContext] invalidateCharacterCoordinates]; // recentering
    
    NSString *text = [m_backingStore string];//	[self preview:notification];
  //  [self createTextObjectWithTextAtPath:text atPoint:m_pointTextStart];
    [self setString:text];
    
  //  [(PSHelpers *)[m_idDocument helpers] layerContentsChanged:kActiveLayer];
    
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)newSelection replacementRange:(NSRange)replacementRange
{

    if (replacementRange.location == NSNotFound)
    {
        if (m_markedRange.location != NSNotFound)
        {
            replacementRange = m_markedRange;
        }
        else
        {
            replacementRange = m_selectedRange;
        }
    }
    
    // Add the text
    [m_backingStore beginEditing];
    if ([aString length] == 0)
    {
        [m_backingStore deleteCharactersInRange:replacementRange];
        [self unmarkText];
    }
    else
    {
        m_markedRange = NSMakeRange(replacementRange.location, [aString length]);
        if ([aString isKindOfClass:[NSAttributedString class]])
        {
            [m_backingStore replaceCharactersInRange:replacementRange withAttributedString:aString];
        }
        else
        {
            [m_backingStore replaceCharactersInRange:replacementRange withString:aString];
        }
        [m_backingStore addAttributes:m_markedAttributes range:m_markedRange];
    }
    [m_backingStore endEditing];
    
    // Redisplay
    m_selectedRange.location = replacementRange.location + newSelection.location; // Just for now, only select the marked text
    m_selectedRange.length = newSelection.length;
    [[self inputContext] invalidateCharacterCoordinates]; // recentering
}

- (void)unmarkText
{
    m_markedRange = NSMakeRange(NSNotFound, 0);
    [[self inputContext] discardMarkedText];
}

- (NSRange)selectedRange
{
    
      return m_selectedRange;
}

- (NSRange)markedRange
{
    
        return m_markedRange;
}

- (BOOL)hasMarkedText
{
    
       return (m_markedRange.location == NSNotFound ? NO : YES);
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
    
    // We choose not to adjust the range, though we have the option
    if (actualRange)
    {
        *actualRange = aRange;
    }
    return [m_backingStore attributedSubstringFromRange:aRange];
}

- (NSArray *)validAttributesForMarkedText
{
    // We only allow these attributes to be set on our marked text (plus standard attributes)
    // NSMarkedClauseSegmentAttributeName is important for CJK input, among other uses
    // NSGlyphInfoAttributeName allows alternate forms of characters
    return [NSArray arrayWithObjects:NSMarkedClauseSegmentAttributeName, NSGlyphInfoAttributeName, nil];
}

//Returns the first logical rectangular area for aRange. The return value is in the screen coordinate. The size value can be negative if the text flows to the left. If non-NULL, actuallRange contains the character range corresponding to the returned area.
- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{

    if(m_delegateInfoNotify)
    {
         NSRect glyphRect =  [m_delegateInfoNotify firstRectForCharacterRange:aRange actualRange:actualRange];
//        glyphRect = [self convertRectToBase:glyphRect];
//        glyphRect.origin = [[self window] convertBaseToScreen:glyphRect.origin];
        glyphRect = [self convertRectToBacking:glyphRect];
        glyphRect = [[self window] convertRectToScreen:glyphRect]; //lcz modify
        
        return glyphRect;
    }
    
    return CGRectNull;
}

extern IntPoint gScreenResolution;
/* Returns the index for character that is nearest to aPoint. aPoint is in the screen coordinate system.
 */
- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint
{

//    NSPoint localPoint = [self convertPointFromBase:[[self window] convertScreenToBase:aPoint]];
    NSPoint localPoint = [self convertPoint:[[self window] convertScreenToBase:aPoint] fromView:[[self window] contentView]];
    localPoint.y = self.bounds.size.height - localPoint.y - 1;
    
    
    float zoom = [(PSView *)[m_idDocument docView] zoom];
    int xres = [[m_idDocument contents] xres], yres = [[m_idDocument contents] yres];
    
    if (gScreenResolution.x != 0 && xres != gScreenResolution.x)
        localPoint.x *= ((float)xres / gScreenResolution.x);
   
    if (gScreenResolution.y != 0 && yres != gScreenResolution.y)
        localPoint.y *= ((float)yres / gScreenResolution.y);
    
    localPoint.x /= zoom;
    localPoint.y /= zoom;
    
    
    if(m_delegateInfoNotify)
        return [m_delegateInfoNotify characterIndexForPoint:localPoint];
    
    return 0;


}

- (NSAttributedString *)attributedString
{
   // return [m_delegatePSViewText attributedString];
    // This method is optional, but our backing store is an attributed string anyway
      return m_backingStore;
}

- (NSInteger)windowLevel
{
    // This method is optional but easy to implement
    return [[self window] level];
}

- (CGFloat)fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint
{
    return 0.0;
    // This method is optional but would help with mouse-related activities, such as selection
    // Unfortunately we don't support selection
    
    // Convert the point from screen coordinates
    /*    NSPoint localPoint = [self convertPointFromBase:[[self window] convertScreenToBase:aPoint]];
     localPoint.x -= centerOffset;
     
     // Ask the layout manager
     CGFloat fraction = 0.5;
     [layoutManager glyphIndexForPoint:localPoint inTextContainer:textContainer fractionOfDistanceThroughGlyph:&fraction];
     return fraction;
     */
}

- (CGFloat)baselineDeltaForCharacterAtIndex:(NSUInteger)anIndex
{
    return 0.0;
    // This method is optional but helps position other elements next to the characters, such as the box that allows you to choose which Chinese or Japanese characters you want to input.
    
    // Get the first glyph corresponding to this character
    /*    NSUInteger glyphIndex = [layoutManager glyphIndexForCharacterAtIndex:anIndex];
     
     if (glyphIndex != NSNotFound)
     {
     // Ask the layout manager's typesetter
     return [[layoutManager typesetter] baselineOffsetInLayoutManager:layoutManager glyphIndex:glyphIndex];
     }
     else
     {
     // Fall back to the layout manager and font
     return [layoutManager defaultBaselineOffsetForFont:[m_defaultAttributes objectForKey:NSFontAttributeName]];
     }
     */
}


- (void)setString:(NSString *)string
{

    if(m_delegateInfoNotify)
    {
        [m_delegateInfoNotify textCursorPosChanged:m_selectedRange.location];
        [m_delegateInfoNotify textChanged:string];
    }

}

@end
