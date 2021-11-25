//
//  PSTextInputView.h
//  PixelStyle
//
//  Created by wzq on 15/11/3.
//
//

#import <Cocoa/Cocoa.h>

@class WDLayer;
@class WDPath;
@class WDTextPath;

@protocol ProtocolTextInfoNotify
@required
//-(void)textInfoChanged:(WDTextPath *) textPath;
-(void)textCursorPosChanged:(int)nIndex;
-(void)textChanged:(NSString *)text;
-(void)textSelectedChanged:(NSRange)rangeSelect;

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange;
- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint;
@end

//struct CUSTOM_TRANSFORM_;
@interface PSTextInputView : NSView<NSTextInputClient>
{
    // The document associated with this view
    id m_idDocument;
    
//    CGPoint m_pointTextStart;
  //  WDLayer *m_wdLayer;
  //  WDTextPath *m_idLastTextObject;
    
    NSRange m_markedRange;
    NSRange m_selectedRange;
  //  NSString *m_strInput;
    NSTextStorage *m_backingStore;
    
    NSMutableDictionary *m_defaultAttributes;
    NSMutableDictionary *m_markedAttributes;
    
    id<ProtocolTextInfoNotify> m_delegateInfoNotify;
}

- (id)initWithDocument:(id)doc string:(NSString *)strInput;
- (void)setDelegateTextInfoNotify:(id) delegateInfoNotify;
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange;
/*- (void)setWithPath:(WDPath *)pathRef;
- (void)setString:(NSString *)string;
- (void)setFontName:(NSString *)strFontName;
- (void)setFontSize:(CGFloat)fSize;
- (void)setCustomTransform:(struct CUSTOM_TRANSFORM_)transform;
- (void)setStrokeStyle:(BOOL)bStroke width:(int)nWidth color:(NSColor *)color;
*/
@end
