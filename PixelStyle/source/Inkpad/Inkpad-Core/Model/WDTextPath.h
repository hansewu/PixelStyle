//
//  WDTextPath.h
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDPath.h"
#import "WDTextRenderer.h"
#import "WDUtilities.h"

typedef enum {
    kWDTextPathAlignmentBaseline,
    kWDTextPathAlignmentCentered, // currently unsupported
    kWDTextPathAlignmentVertical  // currently unsupported
} WDTextPathAlignment;


struct CUSTOM_TRANSFORM_;

@interface WDTextPath : WDPath <NSCoding, NSCopying, WDTextRenderer>
{
    NSString                *text_;
    NSString                *fontName_;
    float                   fontSize_;
    WDTextPathAlignment     alignment_;
    float                   startOffset_;
    CGAffineTransform       transform_;

    struct CUSTOM_TRANSFORM_        transformCustom_;
    PSPerspectiveTransform   perspectiveTransform_; //add by lcz
    
    CTFontRef               fontRef_;
    BOOL                    needsLayout_;
    NSMutableArray          *glyphs_;
    BOOL                    overflow_;
    CGRect                  styleBounds_;
    NSString                *cachedText_;
    NSNumber                *cachedStartOffset_;
    
    NSMutableArray          *arrayCharacterAffineTransform_;
    NSMutableArray          *arrayCharacterBounds_;
    NSMutableArray          *arrayBlinkCursor_;
    NSMutableArray          *arrayTextAux_;

    NSMutableArray          *arrayUnderline_;
    NSMutableArray          *arrayStrikethrough_;
    
    BOOL                    bActiveForEdit_;
    int                     posBlinkCursor_;
    
    int                     nFontBoldWidth_;
    int                     nFontItalicsValue_;
    int                     nFontUnderlineValue_;
    int                     nFontStrikethroughValue_;
    int                     nFontCharacterSpace_;
    
    NSMutableIndexSet       *m_indexSpace;
    
    CGRect                  baseBounds_;
}

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, assign) struct CUSTOM_TRANSFORM_        transformCustom;
@property (nonatomic, assign) PSPerspectiveTransform   perspectiveTransform;
@property (nonatomic, assign) int                     nFontBoldWidth;
@property (nonatomic, assign) int                     nFontItalicsValue;
@property (nonatomic, assign) int                     nFontUnderlineValue;
@property (nonatomic, assign) int                     nFontStrikethroughValue;
@property (nonatomic, assign) int                     nFontCharacterSpace;

@property (nonatomic, readonly) CTFontRef fontRef;

@property (nonatomic, assign) WDTextPathAlignment alignment;
@property (nonatomic, assign) float startOffset;
@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, strong) NSNumber *cachedStartOffset;

+ (WDTextPath *) textPathWithPath:(WDPath *)path;

- (void) setWithPath:(WDPath *)path;
- (void) setFontName:(NSString *)fontName;
- (void) setFontSize:(float)fontSize;

- (void) moveStartKnobToNearestPoint:(CGPoint)pt;

- (void) cacheOriginalText;
- (void) registerUndoWithCachedText;

- (void) cacheOriginalStartOffset;
- (void) registerUndoWithCachedStartOffset;

- (void) resetTransform;
- (void) setTransform:(CGAffineTransform)transform;

- (void) setAffineTransformForCharacter:(int) nIndex transform:(NSAffineTransform *) transform;
- (NSAffineTransform *)getAffineTransformForCharacter:(int) nIndex;
- (CGRect) getBoundRectForCharacter:(int) nIndex;

- (void) setBlinkCursor:(int)nIndex batvie:(BOOL)bActive;
- (CGPathRef) getBlinkCursor:(int)nIndex;
- (CGRect) textBounds;

- (void) setBaseBounds:(CGRect)rect;
- (CGRect) getBaseBounds;
@end
