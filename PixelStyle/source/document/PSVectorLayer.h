#import "Globals.h"
#import "PSLayer.h"
#import "WDUtilities.h"
#import "PSTextInputView.h"

@class WDLayer;
@class WDTextPath;



@interface PSTextLayer : PSLayer<ProtocolTextInfoNotify>
{
    WDLayer *m_wdLayer;
    
    id m_idLastTextObject;
    
    CGContextRef m_contextData;
    
    CGAffineTransform  m_Transformed;
    
    int     m_nTextCursorPos;
    
    CGPoint m_pointTextStart;
}


- (id)initWithDocument:(id)doc;
- (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp;
- (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp atPoint:(CGPoint)pointStart;
- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp;
- (id)initWithDocument:(id)doc layer:(PSVectorLayer*)layer;
- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata;

- (void)compress;
- (void)decompress;

- (id)document;
- (int)width;
- (int)height;
- (int)xoff;
- (int)yoff;
- (IntRect)localRect;
- (void)setOffsets:(IntPoint)newOffsets;
- (void)trimLayer;
- (void)flipHorizontally;
- (void)flipVertically;
- (void)rotateLeft;
- (void)rotateRight;
- (void)setRotation:(float)degrees interpolation:(int)interpolation withTrim:(BOOL)trim;
- (BOOL)visible;
- (void)setVisible:(BOOL)value;
- (BOOL)linked;
- (void)setLinked:(BOOL)value;
- (int)opacity;
- (void)setOpacity:(int)value;
- (int)mode;
- (void)setMode:(int)value;
- (NSString *)name;
- (void)setName:(NSString *)newName;
- (BOOL)hasAlpha;
- (void)toggleAlpha;
- (void)introduceAlpha;
- (BOOL)canToggleAlpha;
- (char *)lostprops;
- (int)lostprops_len;
- (int)uniqueLayerID;
- (int)index;
- (BOOL)floating;
- (id)seaLayerUndo;
- (NSImage *)thumbnail;
- (void)updateThumbnail;
- (NSData *)TIFFRepresentation;
- (void)setMarginLeft:(int)left top:(int)top right:(int)right bottom:(int)bottom;
- (void)setWidth:(int)newWidth height:(int)newHeight interpolation:(int)interpolation;
- (void)convertFromType:(int)srcType to:(int)destType;

- (void)setTextInfo:(WDTextPath *)textObject;
- (NSString *)getText;
//- (void) createTextObjectWithTextAtPath:(NSString *)string;
//- (void)setNSTextInputContext:(NSTextInputContext *)inputContext1;

- (CGPathRef) getBlinkCursor;
- (NSRect)getValidRect;

- (void)setFontName:(NSString *)strFontName;
- (void)setFontSize:(CGFloat)fSize;
- (void)setCustomTransform:(struct CUSTOM_TRANSFORM_)transform;

- (void)setStrokeStyle:(BOOL)bStroke width:(int)nWidth color:(NSColor *)color;
- (void)setStartPoint:(CGPoint)pointStart;

- (void)setFillColor:(NSColor *)color;
- (void)setFontBold:(int)nWidth;
- (void)setFontItalics:(int)nItalicsValue;
- (void)setFontUnderline:(int)nUnderlineValue;
- (void)setFontStrikethrough:(int)nStrikethroughValue;
- (void)setCharacterSpace:(int)CharacterSpace;

- (NSString *)getFontName;
- (CGFloat)getFontSize;
- (struct CUSTOM_TRANSFORM_ )getCustomTransform;
- (CGPoint)getStartPoint;

- (NSColor *)getStrokeStyle:(BOOL *)bStroke width:(int *)nWidth;

- (NSColor *)getFillColor;
- (int)getFontBold;
- (int)getFontItalics;
- (int)getFontUnderline;
- (int)getFontStrikethrough;
- (int)getCharacterSpace;

@end
