//
//  WDTextPath.m
//  Inkpad
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

//#if !TARGET_OS_IPHONE
//#import <UIKit/UIKit.h>
//#import "NSCoderAdditions.h"
//#endif
#import "UIKitOS.h"

#import <CoreText/CoreText.h>
#import <VideoToolBox/VTCompressionProperties.h>
#import "NSString+Additions.h"
#import "UIColor+Additions.h"
#import "WDBezierNode.h"
#import "WDColor.h"
#import "WDFillTransform.h"
#import "WDFontManager.h"
#import "WDGLUtilities.h"
#import "WDGradient.h"
#import "WDInspectableProperties.h"
#import "WDLayer.h"
#import "WDSVGHelper.h"
#import "WDTextPath.h"
#import "WDUtilities.h"
#import "WDShadow.h"

NSString *WDTextPathMethodKey = @"WDTextPathMethodKey";
NSString *WDTextPathOrientationKey = @"WDTextPathOrientationKey";
NSString *WDTextPathStartOffsetKey = @"WDTextPathStartOffsetKey";
NSString *WDTextPathAlignmentKey = @"WDTextPathAlignmentKey";

#define kOverflowRadius             4
#define kMaxOutwardKernAdjustment   (-0.25f)

@interface WDTextPath (WDPrivate)
- (NSInteger) segmentCount;
- (void) layout;
- (void) getStartKnobBase:(CGPoint *)base andTop:(CGPoint *)top viewScale:(float)viewScale;
@end

@implementation WDTextPath

@synthesize text = text_;
@synthesize fontName = fontName_;
@synthesize fontSize = fontSize_;
@synthesize alignment = alignment_;
@synthesize startOffset = startOffset_;
@synthesize attributedString = attributedString_;
@synthesize cachedStartOffset = cachedStartOffset_;
@synthesize transformCustom = transformCustom_;
@synthesize perspectiveTransform = perspectiveTransform_;
@synthesize nFontBoldWidth          =  nFontBoldWidth_;
@synthesize nFontItalicsValue       =  nFontItalicsValue_;
@synthesize nFontUnderlineValue     =  nFontUnderlineValue_;
@synthesize nFontStrikethroughValue =  nFontStrikethroughValue_;
@synthesize nFontCharacterSpace     =  nFontCharacterSpace_;

+ (WDTextPath *) textPathWithPath:(WDPath *)path
{
    WDTextPath *typePath = [[WDTextPath alloc] init];

    NSMutableArray *nodes = [path.nodes copy];
    typePath.nodes = nodes;
    
    typePath.reversed = path.reversed;
    typePath.closed = path.closed;
    
    return typePath;
}

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    transform_ = CGAffineTransformIdentity;
    transformCustom_.nTransformStyleID = -1;
    perspectiveTransform_ = PSPerspectiveTransformMake(1.0, 0, 0, 0, 1.0, 0, 0, 0, 1.0);
    bActiveForEdit_ = NO;
    posBlinkCursor_ = -1;
    
    nFontBoldWidth_             = 0;
    nFontItalicsValue_          = 0;
    nFontUnderlineValue_        = 0;
    nFontStrikethroughValue_    = 0;
    nFontCharacterSpace_        = 0;

    
    m_indexSpace = [[NSMutableIndexSet alloc] init];
    
    return self;
}

- (void) dealloc
{
    if (fontRef_) {
        CFRelease(fontRef_);
    }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:text_ forKey:WDTextKey];
    [coder encodeObject:fontName_ forKey:WDFontNameKey];
    [coder encodeFloat:fontSize_ forKey:WDFontSizeKey];
    [coder encodeInt32:alignment_ forKey:WDTextPathAlignmentKey];
    [coder encodeFloat:startOffset_ forKey:WDTextPathStartOffsetKey];
#if TARGET_OS_IPHONE
    [coder encodeCGAffineTransform:transform_ forKey:WDTransformKey];
#else
    NSValue *vlTransform = [NSValue valueWithBytes:&transform_ objCType:@encode(CGAffineTransform)];
    
    [coder encodeObject:vlTransform forKey:WDTransformKey];
    
    [coder encodeObject:[NSData dataWithBytes:&transformCustom_ length:sizeof(transformCustom_)]
                 forKey:@"PStransformCustom"];
    [coder encodeObject:[NSData dataWithBytes:&perspectiveTransform_ length:sizeof(PSPerspectiveTransform)] forKey:@"PSPerspectiveTransform"];
    
    [coder encodeInt32:nFontBoldWidth_ forKey:@"PSFontBoldWidth"];
    [coder encodeInt32:nFontItalicsValue_ forKey:@"PSFontItalicsValue"];
    [coder encodeInt32:nFontUnderlineValue_ forKey:@"PSFontUnderlineValue"];
    [coder encodeInt32:nFontStrikethroughValue_ forKey:@"PSFontStrikethroughValue"];
    [coder encodeInt32:nFontCharacterSpace_ forKey:@"PSFontCharacterSpace"];

    
    [coder encodeObject:m_indexSpace forKey:@"PSIndexSpace"];
#endif
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    text_ = [coder decodeObjectForKey:WDTextKey];
    startOffset_ = [coder decodeFloatForKey:WDTextPathStartOffsetKey]; 
    
    if ([coder containsValueForKey:WDTextPathAlignmentKey]) {
        alignment_ = [coder decodeInt32ForKey:WDTextPathAlignmentKey];
    }
    
    fontName_ = [coder decodeObjectForKey:WDFontNameKey];
    fontSize_ = [coder decodeFloatForKey:WDFontSizeKey];
    
#if TARGET_OS_IPHONE
    transform_ = [coder decodeCGAffineTransformForKey:WDTransformKey];
#else
    NSValue *vlTransform = [coder decodeObjectForKey:WDTransformKey];
    [vlTransform getValue:&transform_];
    
    NSData *data = [coder decodeObjectForKey:@"PStransformCustom"];
    [data getBytes:&transformCustom_ length:sizeof(transformCustom_)];
    data = [coder decodeObjectForKey:@"PSPerspectiveTransform"];
    [data getBytes:&perspectiveTransform_ length:sizeof(PSPerspectiveTransform)];
    
    nFontBoldWidth_         = [coder  decodeInt32ForKey:@"PSFontBoldWidth"];
    nFontItalicsValue_      = [coder  decodeInt32ForKey:@"PSFontItalicsValue"];
    nFontUnderlineValue_    = [coder  decodeInt32ForKey:@"PSFontUnderlineValue"];
    nFontStrikethroughValue_ = [coder  decodeInt32ForKey:@"PSFontStrikethroughValue"];
    nFontCharacterSpace_    = [coder  decodeInt32ForKey:@"PSFontCharacterSpace"];
#endif
    
    if (![[WDFontManager sharedInstance] validFont:fontName_]) {
        fontName_ = @"Helvetica";
    }
    
    m_indexSpace = [coder decodeObjectForKey:@"PSIndexSpace"];
    
    needsLayout_ = YES;
    
    return self; 
}

- (CGRect) styleBounds 
{
    [self layout];
    return CGRectUnion([self expandStyleBounds:styleBounds_], self.bounds);
}

- (CGRect) textBounds
{
    WDShadow *shadow = [self shadowForStyleBounds];
    
    if (!shadow) {
        return styleBounds_;
    }
    
    // expand by the shadow radius
    CGRect shadowRect = CGRectInset(styleBounds_, -shadow.radius, -shadow.radius);
    
    // offset
    float x = cos(shadow.angle) * shadow.offset;
    float y = sin(shadow.angle) * shadow.offset;
    shadowRect = CGRectOffset(shadowRect, x, y);
    
    
    return CGRectUnion(shadowRect, styleBounds_);
}

- (BOOL) hasEditableText
{
    return YES;
}

- (BOOL) hasFill
{
    return NO; // only the text has a fill, not the path itself
}

- (BOOL) canPlaceText
{
    return NO;
}

- (NSSet *) inspectableProperties
{
    static NSMutableSet *inspectableProperties = nil;
    
    if (!inspectableProperties) {
        inspectableProperties = [NSMutableSet setWithObjects:WDFontNameProperty, WDFontSizeProperty, nil];
        [inspectableProperties unionSet:[super inspectableProperties]];
    }
    
    return inspectableProperties;
}

- (void) setValue:(id)value forProperty:(NSString *)property propertyManager:(WDPropertyManager *)propertyManager 
{
    if (![[self inspectableProperties] containsObject:property]) {
        // we don't care about this property, let's bail
        return [super setValue:value forProperty:property propertyManager:propertyManager];
    }
    
    if ([property isEqualToString:WDFontNameProperty]) {
        [self setFontName:value];
    } else if ([property isEqualToString:WDFontSizeProperty]) {
        [self setFontSize:[value intValue]];
    } else {
        [super setValue:value forProperty:property propertyManager:propertyManager];
    }
}

- (id) valueForProperty:(NSString *)property
{
    if (![[self inspectableProperties] containsObject:property]) {
        // we don't care about this property, let's bail
        return [super valueForProperty:property];
    }
    
    if ([property isEqualToString:WDFontNameProperty]) {
        return fontName_;
    } else if ([property isEqualToString:WDFontSizeProperty]) {
        return @(fontSize_);
    } else {
        return [super valueForProperty:property];
    }
    
    return nil;
}

- (void) cacheOriginalText
{
    cachedText_ = [self.text copy];
}

- (void) registerUndoWithCachedText
{   
    if ([cachedText_ isEqualToString:text_]) {
        return;
    }
    
    [[self.undoManager prepareWithInvocationTarget:self] setText:cachedText_];
    cachedText_ = nil;
}

- (CTFontRef) fontRef
{
    if (!fontRef_) {
        fontRef_ = [[WDFontManager sharedInstance] newFontRefForFont:fontName_ withSize:fontSize_ provideDefault:YES];
    }
    
    return fontRef_;
}

- (NSString *)text
{
    NSMutableString *strConverted = [[NSMutableString  alloc] initWithString:text_];
    for(int i= 0; i< text_.length; i++)
    {
        if([text_ characterAtIndex:i] == 't'&& [m_indexSpace containsIndex:i])
        {
            [strConverted replaceCharactersInRange:NSMakeRange(i,1) withString:@" "];
        }
    }
    
    return strConverted;

}

- (void) setText:(NSString *)text
{
    if ([text isEqualToString:text_]) {
        return;
    }
    
    [self cacheDirtyBounds];
    
    if (!cachedText_) {
        [[self.undoManager prepareWithInvocationTarget:self] setText:text_];
    }
    
    BOOL first = YES;
    NSArray *substrings = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *stripped = @"";
    for (NSString *sub in substrings) {
        if (!first) {
            stripped = [stripped stringByAppendingString:@" "];
        } else {
            first =  NO;
        }
        stripped = [stripped stringByAppendingString:sub];
    }
    text = stripped;
    
    [m_indexSpace removeAllIndexes];
     NSMutableString *strConverted = [[NSMutableString  alloc] initWithString:text];
    for(int i= 0; i< text.length; i++)
    {
        if([text characterAtIndex:i] == ' ')
        {
            [strConverted replaceCharactersInRange:NSMakeRange(i,1) withString:@"t"];
            [m_indexSpace addIndex:i];
        }
    }

    text_ = strConverted;
    attributedString_ = nil;
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
}

- (void) setWithPath:(WDPath *)path
{
    NSMutableArray *nodes = [path.nodes copy];
    self.nodes = nodes;
    
    self.reversed = path.reversed;
    self.closed = path.closed;
    
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
    
}

- (void) setFontName:(NSString *)fontName
{
    [self cacheDirtyBounds];
    
    [[self.undoManager prepareWithInvocationTarget:self] setFontName:fontName_];
    
    fontName_ = fontName;
    
    if (fontRef_) {
        CFRelease(fontRef_);
        fontRef_ = NULL;
    }
    
    CGPathRelease(pathRef_);
    pathRef_ = NULL;
    
    attributedString_ = nil;
    
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
    
    [self propertiesChanged:[NSSet setWithObjects:WDFontNameProperty, nil]];
}

- (void) setFontSize:(float)size
{
    [self cacheDirtyBounds];
    
    [(WDTextPath *)[self.undoManager prepareWithInvocationTarget:self] setFontSize:fontSize_];
    
    fontSize_ = size;
    
    if (fontRef_) {
        CFRelease(fontRef_);
        fontRef_ = NULL;
    }
    
    CGPathRelease(pathRef_);
    pathRef_ = NULL;
    
    attributedString_ = nil;
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
    
    [self propertiesChanged:[NSSet setWithObjects:WDFontSizeProperty, nil]];
}

- (void) setAlignment:(WDTextPathAlignment)alignment
{
    [self cacheDirtyBounds];
    
    [(WDTextPath *)[self.undoManager prepareWithInvocationTarget:self] setAlignment:alignment_];
    
    alignment_ = alignment;
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
}

- (void) invalidateAll
{
    if (fontRef_) {
        CFRelease(fontRef_);
        fontRef_ = NULL;
    }
    
    CGPathRelease(pathRef_);
    pathRef_ = NULL;
    
    attributedString_ = nil;
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
    
    [self propertiesChanged:[NSSet setWithObjects:WDFontSizeProperty, nil]];
    
}

- (void) setTransformCustom:(CUSTOM_TRANSFORM)transformCustom
{
    [self cacheDirtyBounds];
    
    [(WDTextPath *)[self.undoManager prepareWithInvocationTarget:self] setTransformCustom:transformCustom_];
    
    transformCustom_ = transformCustom;
    
    [self invalidateAll];
}

- (void) setPerspectiveTransform:(PSPerspectiveTransform)perspectiveTransform
{
    [self cacheDirtyBounds];
    
    //奇怪
    //[(WDTextPath *)[self.undoManager prepareWithInvocationTarget:self] setPerspectiveTransform:perspectiveTransform_];
    //la_release(perspectiveTransform_);
    perspectiveTransform_ = perspectiveTransform;
    
    [self invalidateAll];
}

- (void) setNFontBoldWidth:(int)nFontBoldWidth
{
    nFontBoldWidth_ = nFontBoldWidth;
    
    NSObject *fillColor = self.fill;
    
    if([fillColor isKindOfClass:[WDColor class]] == NO)
        return;
    
    self.strokeStyle = [WDStrokeStyle strokeStyleWithWidth:nFontBoldWidth_
                                cap:0
                                join:1
                                color:(WDColor *)fillColor
                                dashPattern:nil];
    
    [self invalidateAll];
}

- (void) setNFontItalicsValue:(int)nFontItalicsValue
{
    nFontItalicsValue_ = nFontItalicsValue;
    
    if(nFontItalicsValue_ != 0)
    {
        transform_ = CGAffineTransformMake(1.f, 0.f, -0.5, 1.f, 0.f, 0.f);
    }
    else
        transform_ = CGAffineTransformIdentity;
    
    [self invalidateAll];
}

- (void) setNFontUnderlineValue:(int)nFontUnderlineValue
{
    nFontUnderlineValue_ = nFontUnderlineValue;
    
    [self invalidateAll];
}

- (void) setNFontStrikethroughValue:(int)nFontStrikethroughValue
{
    nFontStrikethroughValue_ = nFontStrikethroughValue;
    
    [self invalidateAll];
}

- (void) setNFontCharacterSpace:(int)nFontCharacterSpace
{
    nFontCharacterSpace_ = nFontCharacterSpace;
    
    [self invalidateAll];
}

- (NSAttributedString *) attributedString
{
    if (!text_ || !fontName_) {
        return nil;
    }
    
    if (!attributedString_) {
        
       /* CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
        
        CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), (CFStringRef)text_);
        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)text_)), kCTFontAttributeName, [self fontRef]);
        
        // paint with the foreground color
        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)text_)), kCTForegroundColorFromContextAttributeName, kCFBooleanTrue);
        CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength((CFStringRef)text_)), kCTLigatureAttributeName, kCFBooleanFalse);
        
        attributedString_ = (NSAttributedString *) CFBridgingRelease(attrString);
        */
         // NSObliquenessAttributeName         设置字形倾斜度，取值为 NSNumber （float）,正值右倾，负值左倾
        // NSStrikethroughStyleAttributeName  设置删除线，取值为 NSNumber 对象（整数）
        
        //NSStrikethroughStyleAttributeName 设置删除线，取值为 NSNumber 对象（整数），枚举常量 NSUnderlineStyle中的值
        // NSUnderlineStyleNone   不设置删除线
        // NSUnderlineStyleSingle 设置删除线为细单实线
        // NSUnderlineStyleThick  设置删除线为粗单实线
        // NSUnderlineStyleDouble 设置删除线为细双实线
        //NSUnderlineStyleAttributeName 设置下划线，取值为 NSNumber 对象（整数），枚举常量 NSUnderlineStyle中的值，与删除线类似
        
        //NSDictionary *attrDict1 = @{ NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),

        float fFontItalicsValue = 0.0;
        if(nFontItalicsValue_ > 0)
            fFontItalicsValue = 0.5;

        NSDictionary *atrrib1 = @{ NSFontAttributeName:             [UIFont fontWithName: fontName_ size: fontSize_],
                                   NSKernAttributeName:             @(nFontCharacterSpace_),
                              //     NSObliquenessAttributeName:      @(fFontItalicsValue),
                                   NSStrikethroughStyleAttributeName:@(nFontStrikethroughValue_),
                                   NSUnderlineStyleAttributeName:   @(nFontUnderlineValue_)
                                   };
        attributedString_ = [[NSAttributedString alloc] initWithString: text_ attributes:atrrib1];

    }
    
    return attributedString_;
}

- (CGPoint) getPointOnPathAtDistance:(float)distance tangentVector:(CGPoint *)tangent transformed:(BOOL)transformed
{
    NSArray             *nodes = reversed_ ? [self reversedNodes] : nodes_;
    NSInteger           numNodes = closed_ ? (nodes.count + 1) : nodes.count;
    WDBezierSegment     segment;
    WDBezierNode        *prev, *curr;
    float               length = 0;
    CGAffineTransform   inverse = transformed ? CGAffineTransformInvert(transform_) : CGAffineTransformIdentity;
    
    prev = [nodes[0] transform:inverse];
    for (int i = 1; i < numNodes; i++) {
        curr = [nodes[(i % nodes.count)] transform:inverse];
        
        segment = WDBezierSegmentMake(prev, curr);
        length = WDBezierSegmentLength(segment);
        
        if (distance < length) {
            // this is our segment, baby
            return WDBezierSegmentPointAndTangentAtDistance(segment, distance, tangent, NULL);
        }
                                                                      
        distance -= length;
        prev = curr;
    }
    
    return CGPointZero;
}

- (void) invalidatePath
{
    [super invalidatePath];
    needsLayout_ = YES;
}

- (float) getSegments:(WDBezierSegment *)segments andLengths:(float *)lengths naturalSpace:(BOOL)transform
{
    NSArray             *nodes = reversed_ ? [self reversedNodes] : nodes_;
    NSInteger           numNodes = closed_ ? (nodes.count + 1) : nodes.count;
    WDBezierNode        *prev, *curr;
    CGAffineTransform   inverse = transform ? CGAffineTransformInvert(transform_) : CGAffineTransformIdentity;
    float               totalLength = 0.0f;
    
    prev = [nodes[0] transform:inverse];
    for (int i = 1; i < numNodes; i++) {
        curr = [nodes[(i % nodes.count)] transform:inverse];
        
        segments[i-1] = WDBezierSegmentMake(prev, curr);
        lengths[i-1] = WDBezierSegmentLength(segments[i-1]);
        totalLength += lengths[i-1];

        prev = curr;
    }
    
    return totalLength;
}

- (float) length:(BOOL)naturalSpace
{
    NSInteger           numSegments = [self segmentCount];
    WDBezierSegment     segments[numSegments];
    float               lengths[numSegments];
    
    // precalculate the segments and their arc lengths
    return [self getSegments:segments andLengths:lengths naturalSpace:naturalSpace];
}

- (BOOL) cornerAtEndOfSegment:(int)ix segments:(WDBezierSegment *)segments count:(NSInteger)numSegments
{
    if (!closed_ && (ix < 0 || ix >= numSegments)) {
        return NO;
    }
    
    return WDBezierSegmentsFormCorner(segments[ix % numSegments], segments[(ix+1) % numSegments]);
}

- (NSInteger) segmentCount
{
    return (closed_ ? nodes_.count : (nodes_.count - 1));
}

static CGPathRef createStrikethroghPath(CGRect rect, CGFloat fHeightOffset )
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, rect.origin.x, rect.origin.y+fHeightOffset);
    
    int nCount = rect.size.width/10;
    for(int i=1; i< nCount; i++)
    {
        CGPathAddLineToPoint(path, NULL, rect.origin.x+i*10, rect.origin.y+fHeightOffset);
    }
    
    CGPathAddLineToPoint(path, NULL, rect.origin.x+rect.size.width, rect.origin.y+fHeightOffset);
    fHeightOffset += 3;
    CGPathAddLineToPoint(path, NULL, rect.origin.x+rect.size.width, rect.origin.y+fHeightOffset);
    
    for(int i=nCount-1; i>= 1; i--)
    {
        CGPathAddLineToPoint(path, NULL, rect.origin.x+i*10, rect.origin.y+fHeightOffset);
    }
    
    CGPathAddLineToPoint(path, NULL, rect.origin.x, rect.origin.y+fHeightOffset);
    
    CGPathCloseSubpath(path);
    
    return path;
}

- (void) addTextAux
{
    if (!arrayTextAux_)
    {
        arrayTextAux_ = [[NSMutableArray alloc] init];
    }
    [arrayTextAux_ removeAllObjects];
    
    CGPathRef path1 = createStrikethroghPath(styleBounds_, styleBounds_.size.height*8/9);
    //CGPathRef path = WDCreateTransformedCGPathRef(path1, tX);
    //CGPathRelease(path);
    
    [arrayTextAux_ addObject: (__bridge id)path1];
    CGPathRelease(path1);
    
    CGPathRef path2 = createStrikethroghPath(styleBounds_, styleBounds_.size.height*1/2);
    //CGPathRef path = WDCreateTransformedCGPathRef(path1, tX);
    //CGPathRelease(path);
    
    [arrayTextAux_ addObject: (__bridge id)path2];
    CGPathRelease(path2);
}

- (void) customTransform
{
    [self addTextAux];
    
    if(transformCustom_.nTransformStyleID >= 0)
    {
        CGRect   styleBoundsTemp = CGRectNull;
        
        NSMutableArray          *glyphstransed;
        glyphstransed = [[NSMutableArray alloc] init];
        [arrayCharacterBounds_ removeAllObjects];
        
        for (id pathRef in glyphs_)
        {
            CGPathRef glyphPath1 = (__bridge CGPathRef) pathRef;
            
            CGPathRef glyphPath2 = WDCreateCustomTransformedCGPathRef(glyphPath1, &transformCustom_, styleBounds_);
            CGRect rectGlyphPath = WDStrokeBoundsForPath(glyphPath2, self.strokeStyle);
            
            styleBoundsTemp = CGRectUnion(styleBoundsTemp, rectGlyphPath);
            
            [glyphstransed addObject:(__bridge id) glyphPath2];
            [arrayCharacterBounds_ addObject:[NSValue valueWithCGRect:rectGlyphPath]];
            
            CGPathRelease(glyphPath2);
        }
        

        NSMutableArray          *textAuxTransed;
        textAuxTransed = [[NSMutableArray alloc] init];
        for( id pathRef in arrayTextAux_)
        {
            CGPathRef Path1 = (__bridge CGPathRef) pathRef;
            CGPathRef Path2 = WDCreateCustomTransformedCGPathRef(Path1, &transformCustom_, styleBounds_);
            [textAuxTransed addObject:(__bridge id)Path2];
            
            CGPathRelease(Path2);
        }


        NSMutableArray          *cursorPathTransed;
        cursorPathTransed = [[NSMutableArray alloc] init];
        for( id pathRef in arrayBlinkCursor_)
        {
            CGPathRef Path1 = (__bridge CGPathRef) pathRef;
            CGPathRef Path2 = WDCreateCustomTransformedCGPathRef(Path1, &transformCustom_, styleBounds_);
            [cursorPathTransed addObject:(__bridge id)Path2];
            
            CGPathRelease(Path2);
        }
        
        [glyphs_ removeAllObjects];
        glyphs_ = glyphstransed;
        
        [arrayBlinkCursor_ removeAllObjects];
        arrayBlinkCursor_ = cursorPathTransed;
        
        [arrayTextAux_ removeAllObjects];
        arrayTextAux_ = textAuxTransed;
        
        styleBounds_ = styleBoundsTemp;
    }
}

- (void) customPerspectiveTransform
{
    [self addTextAux];
    
    if(YES)
    {
        CGRect   styleBoundsTemp = CGRectNull;
        
        NSMutableArray          *glyphstransed;
        glyphstransed = [[NSMutableArray alloc] init];
        [arrayCharacterBounds_ removeAllObjects];
        
        for (id pathRef in glyphs_)
        {
            CGPathRef glyphPath1 = (__bridge CGPathRef) pathRef;
            
            //CGPathRef glyphPath2 = WDCreateCustomTransformedCGPathRef(glyphPath1, &transformCustom_, styleBounds_);
            CGPathRef glyphPath2 = WDCreateCustomPerspectiveTransformedCGPathRef(glyphPath1, perspectiveTransform_, styleBounds_);
            CGRect rectGlyphPath = WDStrokeBoundsForPath(glyphPath2, self.strokeStyle);
            
            styleBoundsTemp = CGRectUnion(styleBoundsTemp, rectGlyphPath);
            
            [glyphstransed addObject:(__bridge id) glyphPath2];
            [arrayCharacterBounds_ addObject:[NSValue valueWithCGRect:rectGlyphPath]];
            
            CGPathRelease(glyphPath2);
        }
        
        
        NSMutableArray          *textAuxTransed;
        textAuxTransed = [[NSMutableArray alloc] init];
        for( id pathRef in arrayTextAux_)
        {
            CGPathRef Path1 = (__bridge CGPathRef) pathRef;
            //CGPathRef Path2 = WDCreateCustomTransformedCGPathRef(Path1, &transformCustom_, styleBounds_);
            CGPathRef Path2 = WDCreateCustomPerspectiveTransformedCGPathRef(Path1, perspectiveTransform_, styleBounds_);
            [textAuxTransed addObject:(__bridge id)Path2];
            
            CGPathRelease(Path2);
        }
        
        
        NSMutableArray          *cursorPathTransed;
        cursorPathTransed = [[NSMutableArray alloc] init];
        for( id pathRef in arrayBlinkCursor_)
        {
            CGPathRef Path1 = (__bridge CGPathRef) pathRef;
            //CGPathRef Path2 = WDCreateCustomTransformedCGPathRef(Path1, &transformCustom_, styleBounds_);
            CGPathRef Path2 = WDCreateCustomPerspectiveTransformedCGPathRef(Path1, perspectiveTransform_, styleBounds_);
            [cursorPathTransed addObject:(__bridge id)Path2];
            
            CGPathRelease(Path2);
        }
        
        [glyphs_ removeAllObjects];
        glyphs_ = glyphstransed;
        
        [arrayBlinkCursor_ removeAllObjects];
        arrayBlinkCursor_ = cursorPathTransed;
        
        [arrayTextAux_ removeAllObjects];
        arrayTextAux_ = textAuxTransed;
        
        styleBounds_ = styleBoundsTemp;
    }
}


CGPathRef createCursorPath(CGPoint origin, CGFloat fheight)
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, origin.x, origin.y);
    for(int i=0; i< 10; i++)
    {
        CGPathAddLineToPoint(path, NULL, origin.x, origin.y+ fheight*(i+1)/10.0);
    }
    
   // CGPathCloseSubpath(path);
    
    return path;
}



- (void) addCursorPosPath:(CGRect)rectBaseGlyphPath transform: (CGAffineTransform)tX
{
    CGPathRef path1, path;
    if(arrayBlinkCursor_.count == 0)
    {
        path1 = createCursorPath(rectBaseGlyphPath.origin, rectBaseGlyphPath.size.height);
        
        path = WDCreateTransformedCGPathRef(path1, tX);
        
        CGPathRelease(path1);
        
        [arrayBlinkCursor_ addObject: (__bridge id)path];
        CGPathRelease(path);
    }
    CGPoint point = rectBaseGlyphPath.origin;
    point.x += rectBaseGlyphPath.size.width+1;
    path1 = createCursorPath(point, rectBaseGlyphPath.size.height);
    path = WDCreateTransformedCGPathRef(path1, tX);

    CGPathRelease(path1);

    [arrayBlinkCursor_ addObject: (__bridge id)path];
    CGPathRelease(path);
}

- (void) layout
{
    if (!needsLayout_)
    {
        return;
    }
    
    // compute glyph positions and angles and determine style bounds
    if (!glyphs_)
    {
        glyphs_ = [[NSMutableArray alloc] init];
    }
    if (!arrayCharacterBounds_)
    {
        arrayCharacterBounds_ = [[NSMutableArray alloc] init];
    }
    if (!arrayBlinkCursor_)
    {
        arrayBlinkCursor_ = [[NSMutableArray alloc] init];
    }
    
    [glyphs_ removeAllObjects];
    [arrayCharacterBounds_ removeAllObjects];
    [arrayBlinkCursor_ removeAllObjects];
    
    styleBounds_ = CGRectNull;
    overflow_ = NO;
    
    // get the attributed string, and bail if it's empty
    CFAttributedStringRef attrString = (__bridge CFAttributedStringRef)self.attributedString;
    if (!attrString)
    {
        return;
    }
    
    CTLineRef line = CTLineCreateWithAttributedString(attrString);
    
    // see if we have any glyphs to render
    CFIndex glyphCount = CTLineGetGlyphCount(line);
    if (glyphCount == 0)
    {
        CFRelease(line);
        return;
    }
    
    NSInteger           numSegments = [self segmentCount];
    WDBezierSegment     segments[numSegments];
    float               lengths[numSegments];
    float               totalLength = 0;
    WDQuad              glyphQuad, prevGlyphQuad = WDQuadNull();
    
    // precalculate the segments and their arc lengths
    totalLength = [self getSegments:segments andLengths:lengths naturalSpace:YES];
    
    CFArrayRef  runArray = CTLineGetGlyphRuns(line);
    CFIndex     runCount = CFArrayGetCount(runArray);
    int         currentSegment = 0; // increment this as the distance accumulates
    float       cumulativeSegmentLength = 0;
    float       kern = 0;
    
    // find the segment that contains the start offset
    for (int i = 0; i < numSegments; i++)
    {
        if (cumulativeSegmentLength + lengths[i] > startOffset_)
        {
            currentSegment = i;
            break;
        }
        cumulativeSegmentLength += lengths[i];
    }
    
    for (CFIndex runIndex = 0; runIndex < runCount; runIndex++)
    {
        CTRunRef    run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CFIndex     runGlyphCount = CTRunGetGlyphCount(run);
        CTFontRef   runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        CGGlyph     buffer[glyphCount];
        CGPoint     positions[glyphCount];
        BOOL        avoidPreviousGlyph = NO;
        CGPoint     tangent;
        float       curvature, start, end, midGlyph=0.0;
        
        CTRunGetGlyphs(run, CFRangeMake(0, 0), buffer);
        CTRunGetPositions(run, CFRangeMake(0,0), positions);
        
        for (CFIndex runGlyphIndex = 0; runGlyphIndex < runGlyphCount; runGlyphIndex++)
        {
            CGPathRef baseGlyphPath = CTFontCreatePathForGlyph(runFont, buffer[runGlyphIndex], NULL);
            
          /*  if (!baseGlyphPath)
            {
                continue;
            }
            else if (CGPathIsEmpty(baseGlyphPath))
            {
                CGPathRelease(baseGlyphPath);
                continue;
            }*/
            
            CGFloat glyphWidth = CTRunGetTypographicBounds(run, CFRangeMake(runGlyphIndex, 1), NULL, NULL, NULL);
            BOOL fits = NO;
            
            while (!fits)
            {
                start = startOffset_ + positions[runGlyphIndex].x + kern;
                end = start + glyphWidth;
                midGlyph = (start + end) / 2;
                
                if (end > (totalLength + (closed_ ? startOffset_ : 0)))
                {
                    // we've run out of room for glyphs
                    overflow_ = YES;
                    if(baseGlyphPath)
                        CGPathRelease(baseGlyphPath);
                    goto done;
                }
                
                // find the segment where the current mid glyph falls
                while (midGlyph >= (cumulativeSegmentLength + lengths[currentSegment % numSegments]))
                {
                    // we're advancing to the next segment, see if we've got a corner
                    if ([self cornerAtEndOfSegment:currentSegment segments:segments count:numSegments])
                    {
                        avoidPreviousGlyph = YES;
                    }
                    
                    cumulativeSegmentLength += lengths[currentSegment % numSegments];
                    currentSegment++;
                }
                
                if (end > (cumulativeSegmentLength + lengths[currentSegment % numSegments]) && [self cornerAtEndOfSegment:currentSegment segments:segments count:numSegments])
                {
                    // if the end is overshooting a corner, we need to adjust the kern to move onto the next segment
                    kern = (cumulativeSegmentLength + lengths[currentSegment % numSegments]) - (startOffset_ + positions[runGlyphIndex].x);
                }
                else
                {
                    // otherwise, we're good to go
                    fits =  YES;
                }
            }

            CGPoint result = WDBezierSegmentPointAndTangentAtDistance(segments[currentSegment % numSegments], (midGlyph - cumulativeSegmentLength), &tangent, &curvature);
            
            if (curvature > 0)
            {
                avoidPreviousGlyph = YES;
            }
            else if (!avoidPreviousGlyph)
            {
                kern += MAX(curvature * 5, kMaxOutwardKernAdjustment) * glyphWidth;
            }

            CGAffineTransform tX = CGAffineTransformMakeTranslation(result.x, result.y);
            tX = CGAffineTransformScale(tX, 1, -1);  // wzq
            tX = CGAffineTransformRotate(tX, atan2(-tangent.y, tangent.x));
            tX = CGAffineTransformTranslate(tX, -(glyphWidth / 2), 0);
            tX = CGAffineTransformConcat(tX, transform_);
                  
            CGPathRef glyphPath = WDCreateTransformedCGPathRef(baseGlyphPath, tX);
            
            CGRect rectBaseGlyphPath = CGPathGetPathBoundingBox(baseGlyphPath);
            glyphQuad = WDQuadWithRect(WDShrinkRect(rectBaseGlyphPath, 0.01f), tX);
            
            [self addCursorPosPath:rectBaseGlyphPath transform: tX];
                
            if (avoidPreviousGlyph && WDQuadIntersectsQuad(glyphQuad, prevGlyphQuad))
            {
                // advance slightly and try to lay out this glyph again
                runGlyphIndex--;
                kern += (glyphWidth / 8); // step by 1/8 glyph width
            }
            else
            {
                [glyphs_ addObject:(__bridge id) glyphPath];
                CGRect rectGlyphPath = WDStrokeBoundsForPath(glyphPath, self.strokeStyle);
                styleBounds_ = CGRectUnion(styleBounds_, rectGlyphPath);
                avoidPreviousGlyph = NO;
                prevGlyphQuad = glyphQuad;
                
                [arrayCharacterBounds_ addObject:[NSValue valueWithCGRect:rectGlyphPath]];
            }
                
            CGPathRelease(glyphPath);
            CGPathRelease(baseGlyphPath);
        }
    }
done:
    
    [self customTransform];
    
    [self customPerspectiveTransform];
    
    
    CFRelease(line);
    needsLayout_ = NO;
}

- (void) strokeStyleChanged
{
    needsLayout_ = YES;
}

- (CGAffineTransform) transform
{
    return transform_;
}

- (void) setTransform:(CGAffineTransform)transform
{
    [self cacheDirtyBounds];
    
    [(WDTextPath *)[self.undoManager prepareWithInvocationTarget:self] setTransform:transform_];
    
    transform_ = transform;
    [self invalidatePath];
    
    [self postDirtyBoundsChange];
}

- (void) setStartOffset:(float)offset
{
    [self cacheDirtyBounds];
    
    if (!self.cachedStartOffset) {
        [[self.undoManager prepareWithInvocationTarget:self] setStartOffset:startOffset_];
    }
    
    startOffset_ = offset;
    needsLayout_ = YES;
    
    [self postDirtyBoundsChange];
}

- (NSSet *) transform:(CGAffineTransform)transform
{
    BOOL anyWereSelected = [self anyNodesSelected];
    
    NSSet *changedNodes = [super transform:transform];
    
    if (!anyWereSelected) {
        self.transform = CGAffineTransformConcat(transform_, transform);
    }
    
    return changedNodes;
}

- (void) resetTransform
{
    self.transform = CGAffineTransformIdentity;
}

- (void) setBlinkCursor:(int)nIndex batvie:(BOOL)bActive
{
    bActiveForEdit_ = bActive;
    posBlinkCursor_ = nIndex;
}

- (void) setAffineTransformForCharacter:(int) nIndex transform:(NSAffineTransform *) transform
{
    
}

- (NSAffineTransform *)getAffineTransformForCharacter:(int) nIndex
{
    return nil;
}

- (CGRect) getBoundRectForCharacter:(int) nIndex
{
    NSValue *value1 = [arrayCharacterBounds_ objectAtIndex:nIndex];
    CGRect rect = value1.rectValue;
    return rect;
}

- (CGPathRef) getBlinkCursor:(int)nIndex
{
    if(arrayBlinkCursor_.count > nIndex)
    {
        CGPathRef path = (__bridge CGPathRef) [arrayBlinkCursor_ objectAtIndex: nIndex];
        return path;
    }
    
    return nil;
}

- (void) drawTextInContext:(CGContextRef)ctx drawingMode:(CGTextDrawingMode)mode
{
    [self drawTextInContext:ctx drawingMode:mode didClip:NULL];
}

- (void) drawTextInContext:(CGContextRef)ctx drawingMode:(CGTextDrawingMode)mode didClip:(BOOL *)didClip
{
    [self layout];
    
    int i=0;
    for (id pathRef in glyphs_) {
        if([m_indexSpace containsIndex:i])
        {
            i++;
            continue;
        }
        i++;
        CGPathRef glyphPath = (__bridge CGPathRef) pathRef;
        
        if (mode == kCGTextStroke) {
            CGPathRef sansQuadratics = WDCreateCubicPathFromQuadraticPath(glyphPath);
            CGContextAddPath(ctx, sansQuadratics);
            CGPathRelease(sansQuadratics);
            
            // stroke each glyph immediately for better performance
            CGContextSaveGState(ctx);
            CGContextStrokePath(ctx);
            CGContextRestoreGState(ctx);
        } else {
            CGContextAddPath(ctx, glyphPath);
        }
    }
    
//    if(nFontUnderlineValue_)
//    {
//        CGPathRef path = (__bridge CGPathRef) [arrayTextAux_ objectAtIndex: 0];
//        CGContextAddPath(ctx, path);
//    }
//
//    if(nFontStrikethroughValue_)
//    {
//        CGPathRef path = (__bridge CGPathRef) [arrayTextAux_ objectAtIndex: 1];
//        CGContextAddPath(ctx, path);
//    }
    
    if(bActiveForEdit_)
    {
        if(arrayBlinkCursor_.count > posBlinkCursor_)
        {
            CGPathRef path = (__bridge CGPathRef) [arrayBlinkCursor_ objectAtIndex: posBlinkCursor_];
            CGContextAddPath(ctx, path);
        }
    }
    
    if (mode == kCGTextClip && !CGContextIsPathEmpty(ctx)) {
        if (didClip) {
            *didClip = YES; 
        }
        CGContextClip(ctx);
    }
    
    if (mode == kCGTextFill) {
        CGContextFillPath(ctx);
    }
    
    
    NSObject *fillColor = self.fill;
    
    if([fillColor isKindOfClass:[WDColor class]] == YES)
    {
        WDColor *colorFill = (WDColor *)fillColor;
        NSColor *nsColor = [NSColor colorWithDeviceRed:colorFill.red green:colorFill.green blue:colorFill.blue alpha:colorFill.alpha];
        [nsColor set];
    }
    
    if(nFontUnderlineValue_)
    {
        CGPathRef path = (__bridge CGPathRef) [arrayTextAux_ objectAtIndex: 0];
        CGContextAddPath(ctx, path);
    }
    
    if(nFontStrikethroughValue_)
    {
        CGPathRef path = (__bridge CGPathRef) [arrayTextAux_ objectAtIndex: 1];
        CGContextAddPath(ctx, path);
    }
    
    CGContextFillPath(ctx);
}

- (void) renderInContext:(CGContextRef)ctx metaData:(WDRenderingMetaData)metaData
{
    UIGraphicsPushContext(ctx);
    
    if (metaData.flags & WDRenderOutlineOnly) {
        CGContextAddPath(ctx, self.pathRef);
        CGContextStrokePath(ctx);
        
        [self drawTextInContext:ctx drawingMode:kCGTextFill];
    } else if ([self.strokeStyle willRender] || self.fill || self.maskedElements) {
        [self beginTransparencyLayer:ctx metaData:metaData];
        
        if (self.fill) {
            CGContextSaveGState(ctx);
            [self.fill paintText:self inContext:ctx];
            CGContextRestoreGState(ctx);
        }
        
        if (self.maskedElements) {
            BOOL didClip;
            
            CGContextSaveGState(ctx);
            // clip to the mask boundary
            [self drawTextInContext:ctx drawingMode:kCGTextClip didClip:&didClip];
            
            if (didClip) {
                // draw all the elements inside the mask
                for (WDElement *element in self.maskedElements) {
                    [element renderInContext:ctx metaData:metaData];
                }
            }
            
            CGContextRestoreGState(ctx);
        }
        
        if ([self.strokeStyle willRender]) {
            [self.strokeStyle applyInContext:ctx];
            [self drawTextInContext:ctx drawingMode:kCGTextStroke];
        }
        
        [self endTransparencyLayer:ctx metaData:metaData];
    }
    
    UIGraphicsPopContext();
}
        
- (NSArray *) outlines
{
    NSMutableArray *paths = [NSMutableArray array];
    
    [self layout];
    
    for (id pathRef in glyphs_) {
        CGPathRef glyphPath = (__bridge CGPathRef) pathRef;
        [paths addObject:[WDAbstractPath pathWithCGPathRef:glyphPath]];
    }
    
    return paths;
}

- (void) drawOpenGLHandlesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
    [super drawOpenGLHandlesWithTransform:transform viewTransform:viewTransform];

    if (!overflow_ || !CGAffineTransformIsIdentity(transform) || self.displayNodes) {
        return;
    }
    
    CGPoint     overflowPoint;
    CGRect      overflowRect;
    BOOL        selected = NO;
    UIColor     *color = displayColor_ ? displayColor_ : self.layer.highlightColor;
    
    if (!closed_) {
        NSArray *nodes = reversed_ ? [self reversedNodes] : nodes_;
        WDBezierNode *lastNode = [nodes lastObject];
        overflowPoint = CGPointApplyAffineTransform(lastNode.anchorPoint, viewTransform);
        selected = lastNode.selected;
    } else {
        CGPoint tangent;
        CGPoint startBarAttachment = [self getPointOnPathAtDistance:startOffset_ tangentVector:&tangent transformed:YES];
        
        overflowPoint = CGPointApplyAffineTransform(startBarAttachment, CGAffineTransformConcat(transform_, viewTransform));
    }
    
    overflowRect = CGRectMake(overflowPoint.x - kOverflowRadius, overflowPoint.y - kOverflowRadius,
                                     kOverflowRadius * 2, kOverflowRadius * 2);
    if (selected) {
        [color openGLSet];
        WDGLFillRect(overflowRect);
        glColor4f(1, 1, 1, 1);
        WDGLStrokeRect(overflowRect);
    } else {
        glColor4f(1, 1, 1, 1);
        WDGLFillRect(overflowRect);
        [color openGLSet];
        WDGLStrokeRect(overflowRect);
    }
    
    // draw +
    overflowPoint = WDRoundPoint(overflowPoint);
    float fudge = (getScreenScale() - 1.0 <0.00001) ? 2.0f : 2.5f;

    WDGLLineFromPointToPoint(CGPointMake(overflowPoint.x - 3, overflowPoint.y),
                             CGPointMake(overflowPoint.x + fudge, overflowPoint.y));
    
    WDGLLineFromPointToPoint(CGPointMake(overflowPoint.x, overflowPoint.y - fudge),
                             CGPointMake(overflowPoint.x, overflowPoint.y + 3));
}

- (void) drawTextPathControlsWithViewTransform:(CGAffineTransform)viewTransform viewScale:(float)viewScale
{
    // draw start bar
    CGPoint     base, top;
    UIColor     *color = displayColor_ ? displayColor_ : self.layer.highlightColor;
    
    [self getStartKnobBase:&base andTop:&top viewScale:viewScale];
    
    base = CGPointApplyAffineTransform(base, viewTransform);
    base = WDRoundPoint(base);
    
    top = CGPointApplyAffineTransform(top, viewTransform);
    top = WDRoundPoint(top);
    
    [color openGLSet];
    WDGLLineFromPointToPoint(base, top);
    
    [[UIColor whiteColor] openGLSet];
    WDGLFillCircle(top, 4, 12);
    [color openGLSet];
    WDGLStrokeCircle(top, 4, 12);
}

- (void) drawOpenGLZoomOutlineWithViewTransform:(CGAffineTransform)viewTransform visibleRect:(CGRect)visibleRect
{
    if (CGRectIntersectsRect(self.bounds, visibleRect)) {
        [self drawOpenGLHighlightWithTransform:CGAffineTransformIdentity viewTransform:viewTransform];
        [self drawOpenGLTextOutlinesWithTransform:CGAffineTransformIdentity viewTransform:viewTransform];
    }
}

- (void) drawOpenGLHighlightWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
    [super drawOpenGLHighlightWithTransform:transform viewTransform:viewTransform];
    
    if ((![self anyNodesSelected] && !CGAffineTransformEqualToTransform(transform, CGAffineTransformIdentity)) || cachedStartOffset_) {
        [self drawOpenGLTextOutlinesWithTransform:transform viewTransform:viewTransform];
    }
}

- (void) drawOpenGLTextOutlinesWithTransform:(CGAffineTransform)transform viewTransform:(CGAffineTransform)viewTransform
{
    [self.layer.highlightColor openGLSet];
    
    CGAffineTransform glTransform = CGAffineTransformConcat(transform, viewTransform);
    
    [self layout];
    
    for (id pathRef in glyphs_) {
        CGPathRef glyphPath = (__bridge CGPathRef) pathRef;
        
        CGPathRef transformed = WDCreateTransformedCGPathRef(glyphPath, glTransform);
        WDGLRenderCGPathRef(transformed);
        CGPathRelease(transformed);
    }
}

- (BOOL) isErasable
{
    return NO;
}

- (BOOL) canOutlineStroke
{
    return NO;
}

- (void) getStartKnobBase:(CGPoint *)base andTop:(CGPoint *)top viewScale:(float)viewScale
{
    float       startDistance = MIN(startOffset_ + 0.01, [self length:YES] - 0.01); // add some fudge
    CGPoint     tangent = CGPointZero;
    CGPoint     startPt = [self getPointOnPathAtDistance:startDistance tangentVector:&tangent transformed:YES];
    float       barLength = MIN(MAX(fontSize_ * viewScale, 10), 200); // scale with the font size, but keep the length manageable
    CGPoint     endPt = CGPointMake(tangent.y, -tangent.x);
    
    endPt = WDScaleVector(endPt, barLength / viewScale);
    endPt = WDAddPoints(startPt, endPt);
    
    startPt = CGPointApplyAffineTransform(startPt, transform_);
    endPt = CGPointApplyAffineTransform(endPt, transform_);
    
    *base = startPt;
    *top = endPt;
}

- (CGRect) controlBounds:(float)viewScale
{
    CGPoint base, top;
    [self getStartKnobBase:&base andTop:&top viewScale:viewScale];
    
    return WDGrowRectToPoint([super controlBounds], top);
}

- (WDPickResult *) hitResultForPoint:(CGPoint)point viewScale:(float)viewScale snapFlags:(int)flags
{
    WDPickResult        *result = [WDPickResult pickResult];
    CGRect              pointRect = WDRectFromPoint(point, kNodeSelectionTolerance / viewScale, kNodeSelectionTolerance / viewScale);
    float               distance;
    float               tolerance = kNodeSelectionTolerance / viewScale;
    
    if (!CGRectIntersectsRect(pointRect, [self controlBounds:viewScale])) {
        return result;
    }
    
    if (flags & kWDSnapNodes) {
        CGPoint base, top;
        [self getStartKnobBase:&base andTop:&top viewScale:viewScale];
        
        distance = WDDistance(top, point);
        if (distance < tolerance) {
            result.type = kWDTextPathStartKnob;
            result.element = self;
        }
    }
    
    if (result.type == kWDEther) {
        return [super hitResultForPoint:point viewScale:viewScale snapFlags:flags];
    }
    
    return result;
}

- (void) cacheOriginalStartOffset
{
    [self cacheDirtyBounds];
    self.cachedStartOffset = @(startOffset_);
}

- (void) registerUndoWithCachedStartOffset
{   
    if ([self.cachedStartOffset floatValue] == startOffset_) {
        self.cachedStartOffset = nil;
        // make the selection view update
        [self postDirtyBoundsChange];
        return;
    }
    
    [[self.undoManager prepareWithInvocationTarget:self] setStartOffset:[self.cachedStartOffset floatValue]];
    self.cachedStartOffset = nil;
    
    [self postDirtyBoundsChange];
}

- (void) moveStartKnobToNearestPoint:(CGPoint)pt
{
    NSInteger           numSegments = [self segmentCount];
    WDBezierSegment     segments[numSegments];
    float               lengths[numSegments];
    float               lowestError = MAXFLOAT;
    int                 closestSegmentIx = 0;
    float               distanceAlongPath = 0;
    
    CGAffineTransform invert = CGAffineTransformInvert(transform_);
    pt = CGPointApplyAffineTransform(pt, invert);
    
    // precalculate the segments and their arc lengths
    [self getSegments:segments andLengths:lengths naturalSpace:YES];
    
    for (int i = 0; i < numSegments; i++) {
        float   error, distance;
        WDBezierSegmentGetClosestPoint(segments[i], pt, &error, &distance);
        
        if (error < lowestError) {
            lowestError = error;
            closestSegmentIx = i;
            distanceAlongPath = distance;
        }
    }
    
    float sum = distanceAlongPath;
    for (int i = 0; i < closestSegmentIx; i++) {
        sum += lengths[i];
    }
    
    startOffset_ = sum;
    needsLayout_ = YES;
}

- (void) addSVGFillAttributes:(WDXMLElement *)element
{
    if ([self.fill isKindOfClass:[WDGradient class]]) {
        WDGradient *gradient = (WDGradient *)self.fill;
        NSString *uniqueID = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:(gradient.type == kWDRadialGradient ? @"RadialGradient" : @"LinearGradient")];
        
        WDFillTransform *fillTransform = [self.fillTransform transform:CGAffineTransformInvert(self.transform)];
        [[WDSVGHelper sharedSVGHelper] addDefinition:[gradient SVGElementWithID:uniqueID fillTransform:fillTransform]];
        
        [element setAttribute:@"fill" value:[NSString stringWithFormat:@"url(#%@)", uniqueID]];
    } else {
        [super addSVGFillAttributes:element];
    }
}

- (WDXMLElement *) SVGElement
{
    NSString *uniquePath = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"TextPath"];
    
    WDXMLElement *path = [WDXMLElement elementWithName:@"path"];
    [path setAttribute:@"id" value:uniquePath];
    [path setAttribute:@"d" value:[self nodeSVGRepresentation]];
    [path setAttribute:@"transform" value:WDSVGStringForCGAffineTransform(CGAffineTransformInvert(transform_))];
    [[WDSVGHelper sharedSVGHelper] addDefinition:path];
    
    WDXMLElement *text = [WDXMLElement elementWithName:@"text"];
    [text setAttribute:@"font-family" value:[NSString stringWithFormat:@"'%@'", fontName_]];
    [text setAttribute:@"font-size" floatValue:fontSize_];
    [text setAttribute:@"transform" value:WDSVGStringForCGAffineTransform(transform_)];
    [self addSVGOpacityAndShadowAttributes:text];
    [self addSVGFillAndStrokeAttributes:text];
    
    WDXMLElement *textPath = [WDXMLElement elementWithName:@"textPath"];
    [textPath setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniquePath]];
    [textPath setAttribute:@"startOffset" value:[NSString stringWithFormat:@"%gpt", startOffset_]];
    [textPath setAttribute:@"method" value:@"align"];
    [textPath setValue:[text_ stringByEscapingEntities]];
    [text addChild:textPath];
    
    if (self.maskedElements && [self.maskedElements count] > 0) {
        // Produces an element such as:
        // <defs>
        //   <path id="TextPathN" d="..."/>
        //   <text id="TextN"><textPath xlink:href="#TextPathN">...</textPath></text>
        // </defs>
        // <g opacity="..." inkpad:shadowColor="...">
        //   <use xlink:href="#TextN" fill="..."/>
        //   <clipPath id="ClipPathN">
        //     <use xlink:href="#TextN" overflow="visible"/>
        //   </clipPath>
        //   <g clip-path="url(#ClipPathN)">
        //     <!-- clipped elements -->
        //   </g>
        //   <use xlink:href="#TextN" stroke="..."/>
        // </g>
        NSString        *uniqueMask = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"Text"];
        NSString        *uniqueClip = [[WDSVGHelper sharedSVGHelper] uniqueIDWithPrefix:@"ClipPath"];
        
        [[WDSVGHelper sharedSVGHelper] addDefinition:path];
        
        WDXMLElement *text = [WDXMLElement elementWithName:@"text"];
        [text setAttribute:@"id" value:uniqueMask];
        
        WDXMLElement *textPath = [WDXMLElement elementWithName:@"textPath"];
        [textPath setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniquePath]];
        [textPath setAttribute:@"startOffset" value:[NSString stringWithFormat:@"%g", startOffset_]];
        [textPath setAttribute:@"method" value:@"align"];
        [textPath setValue:[text_ stringByEscapingEntities]];
        [text addChild:textPath];
        
        WDXMLElement *group = [WDXMLElement elementWithName:@"g"];
        [group setAttribute:@"inkpad:mask" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
        [self addSVGOpacityAndShadowAttributes:group];
        
        if (self.fill) {
            // add a path for the fill
            WDXMLElement *use = [WDXMLElement elementWithName:@"use"];
            [use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
            [self addSVGFillAttributes:use];
            [group addChild:use];
        }
        
        WDXMLElement *clipPath = [WDXMLElement elementWithName:@"clipPath"];
        [clipPath setAttribute:@"id" value:uniqueClip];
        
        WDXMLElement *use = [WDXMLElement elementWithName:@"use"];
        [use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
        [use setAttribute:@"overflow" value:@"visible"];
        [clipPath addChild:use];
        [group addChild:clipPath];
        
        WDXMLElement *elements = [WDXMLElement elementWithName:@"g"];
        [elements setAttribute:@"clip-path" value:[NSString stringWithFormat:@"url(#%@)", uniqueClip]];
        
        for (WDElement *element in self.maskedElements) {
            [elements addChild:[element SVGElement]];
        }
        [group addChild:elements];
        
        if (self.strokeStyle) {
            // add a path for the stroke
            WDXMLElement *use = [WDXMLElement elementWithName:@"use"];
            [use setAttribute:@"xlink:href" value:[NSString stringWithFormat:@"#%@", uniqueMask]];
            [use setAttribute:@"fill" value:@"none"];
            [self.strokeStyle addSVGAttributes:use];
            [group addChild:use];
        }
        
        return group;
    } else {
        return text;
    }
}

- (id) copyWithZone:(NSZone *)zone
{
    WDTextPath *text = [super copyWithZone:zone];
    
    text->text_ = [text_ copy];
    text->startOffset_ = startOffset_;
    text->alignment_ = alignment_;
    text->transform_ = transform_;
    text->fontName_ = [fontName_ copy];
    text->fontSize_ = fontSize_;
    
    text->transformCustom_ = transformCustom_;
    text->perspectiveTransform_ = perspectiveTransform_;
    
    text->glyphs_ = [glyphs_ mutableCopy];
    text->needsLayout_ = needsLayout_;
    
    text->overflow_ = overflow_;
    text->styleBounds_ = styleBounds_;
    text->cachedText_ = [cachedText_ copy];
    text->cachedStartOffset_ = [cachedStartOffset_ copy];
    text->overflow_ = overflow_;
    
    text->nFontBoldWidth_ = nFontBoldWidth_;
    text->nFontItalicsValue_ = nFontItalicsValue_;
    text->nFontUnderlineValue_ = nFontUnderlineValue_;
    text->nFontStrikethroughValue_ = nFontStrikethroughValue_;
    text->nFontCharacterSpace_ = nFontCharacterSpace_;
    text->bActiveForEdit_ = bActiveForEdit_;
    text->posBlinkCursor_ = posBlinkCursor_;
    
    text->arrayCharacterAffineTransform_ = [arrayCharacterAffineTransform_ mutableCopy];
    text->arrayCharacterBounds_ = [arrayCharacterBounds_ mutableCopy];
    text->arrayBlinkCursor_ = [arrayBlinkCursor_ mutableCopy];
    text->arrayTextAux_ = [arrayTextAux_ mutableCopy];
    
//    NSMutableIndexSet *copySet = [[NSMutableIndexSet alloc] initWithIndexSet:m_indexSpace];
//    text->m_indexSpace = copySet;
    text->m_indexSpace =  [m_indexSpace mutableCopy];
    //text->attributedString_ = attributedString_;
    
    return text;
}


/*
 http://www.cnblogs.com/qingche/p/3574995.html
 
 //关于粗体
 UIFont *baseFont = [UIFont systemFontOfSize:fontSize];//设置字体
 [attrString addAttribute:NSFontAttributeName value:baseFont
 range:NSMakeRange(0, length)];//设置所有的字体
 UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
 [attrString addAttribute:NSFontAttributeName value:boldFont range:[string rangeOfString:@"Text"]];//设置Text这四个字母的字体为粗体
 
 
 
 
 // NSFontAttributeName                设置字体属性，默认值：字体：Helvetica(Neue) 字号：12
 // NSForegroundColorAttributeNam      设置字体颜色，取值为 UIColor对象，默认值为黑色
 // NSBackgroundColorAttributeName     设置字体所在区域背景颜色，取值为 UIColor对象，默认值为nil, 透明色
 // NSLigatureAttributeName            设置连体属性，取值为NSNumber 对象(整数)，0 表示没有连体字符，1 表示使用默认的连体字符
 // NSKernAttributeName                设定字符间距，取值为 NSNumber 对象（整数），正值间距加宽，负值间距变窄
 // NSStrikethroughStyleAttributeName  设置删除线，取值为 NSNumber 对象（整数）
 
     //NSStrikethroughStyleAttributeName 设置删除线，取值为 NSNumber 对象（整数），枚举常量 NSUnderlineStyle中的值
     // NSUnderlineStyleNone   不设置删除线
     // NSUnderlineStyleSingle 设置删除线为细单实线
     // NSUnderlineStyleThick  设置删除线为粗单实线
     // NSUnderlineStyleDouble 设置删除线为细双实线
     NSDictionary *attrDict1 = @{ NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
     NSFontAttributeName: [UIFont systemFontOfSize:20] };
        另外，删除线属性取值除了上面的4种外，其实还可以取其他整数值，有兴趣的可以自行试验，取值为 0 - 7时，效果为单实线，随着值得增加，单实线逐渐变粗，取值为 9 - 15时，效果为双实线，取值越大，双实线越粗。
 // NSStrikethroughColorAttributeName  设置删除线颜色，取值为 UIColor 对象，默认值为黑色
         NSDictionary *attrDict1 = @{ NSStrikethroughColorAttributeName: [UIColor blueColor],
         NSStrikethroughStyleAttributeName: @(1),
         NSFontAttributeName: [UIFont systemFontOfSize:20] };
 
 // NSUnderlineStyleAttributeName      设置下划线，取值为 NSNumber 对象（整数），枚举常量 NSUnderlineStyle中的值，与删除线类似
 
         /NSUnderlineStyleAttributeName 设置下划线，取值为 NSNumber 对象（整数），枚举常量 NSUnderlineStyle中的值，与删除线类似
         
         NSDictionary *attrDict1 = @{ NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
         NSFontAttributeName: [UIFont systemFontOfSize:20] };
 
 // NSUnderlineColorAttributeName      设置下划线颜色，取值为 UIColor 对象，默认值为黑色
 
 // NSStrokeWidthAttributeName         设置笔画宽度，取值为 NSNumber 对象（整数），负值填充效果，正值中空效果
 //NSStrokeWidthAttributeName 设置笔画宽度，取值为 NSNumber 对象（整数），负值填充效果，正值中空效果
 
         NSDictionary *attrDict1 = @{ NSStrokeWidthAttributeName: @(-3),
         NSFontAttributeName: [UIFont systemFontOfSize:30] };
         _label01.attributedText = [[NSAttributedString alloc] initWithString: originStr attributes: attrDict1];
         
 
 // NSStrokeColorAttributeName         填充部分颜色，不是字体颜色，取值为 UIColor 对象

         NSDictionary *attrDict1 = @{ NSStrokeWidthAttributeName: @(-3),
         NSStrokeColorAttributeName: [UIColor orangeColor],
         NSFontAttributeName: [UIFont systemFontOfSize:30] };
         
 
 // NSShadowAttributeName              设置阴影属性，取值为 NSShadow 对象
 // NSTextEffectAttributeName          设置文本特殊效果，取值为 NSString 对象，目前只有图版印刷效果可用：
 // NSBaselineOffsetAttributeName      设置基线偏移值，取值为 NSNumber （float）,正值上偏，负值下偏
 
 
 // NSObliquenessAttributeName         设置字形倾斜度，取值为 NSNumber （float）,正值右倾，负值左倾
 
 
 // NSExpansionAttributeName           设置文本横向拉伸属性，取值为 NSNumber （float）,正值横向拉伸文本，负值横向压缩文本
 
 
 
 
 // NSWritingDirectionAttributeName    设置文字书写方向，从左向右书写或者从右向左书写
 
 // NSVerticalGlyphFormAttributeName   设置文字排版方向，取值为 NSNumber 对象(整数)，0 表示横排文本，1 表示竖排文本
 
 
 // NSLinkAttributeName                设置链接属性，点击后调用浏览器打开指定URL地址
 // NSAttachmentAttributeName          设置文本附件,取值为NSTextAttachment对象,常用于文字图片混排
 // NSParagraphStyleAttributeName      设置文本段落排版格式，取值为 NSParagraphStyle 对象
 
 
 1> NSFontAttributeName(字体)
 
 该属性所对应的值是一个 UIFont 对象。该属性用于改变一段文本的字体。如果不指定该属性，则默认为12-point Helvetica(Neue)。
 
 2> NSParagraphStyleAttributeName(段落)
 
 该属性所对应的值是一个 NSParagraphStyle 对象。该属性在一段文本上应用多个属性。如果不指定该属性，则默认为 NSParagraphStyle 的defaultParagraphStyle 方法返回的默认段落属性。
 
 3> NSForegroundColorAttributeName(字体颜色)
 
 该属性所对应的值是一个 UIColor 对象。该属性用于指定一段文本的字体颜色。如果不指定该属性，则默认为黑色。
 
 4> NSBackgroundColorAttributeName(字体背景色)
 
 该属性所对应的值是一个 UIColor 对象。该属性用于指定一段文本的背景颜色。如果不指定该属性，则默认无背景色。
 
 5> NSLigatureAttributeName(连字符)
 
 该属性所对应的值是一个 NSNumber 对象(整数)。连体字符是指某些连在一起的字符，它们采用单个的图元符号。0 表示没有连体字符。1 表示使用默认的连体字符。2表示使用所有连体符号。默认值为 1（注意，iOS 不支持值为 2）。
 
 6> NSKernAttributeName(字间距)
 
 该属性所对应的值是一个 NSNumber 对象(整数)。字母紧排指定了用于调整字距的像素点数。字母紧排的效果依赖于字体。值为 0 表示不使用字母紧排。默认值为0。
 
 7> NSStrikethroughStyleAttributeName(删除线)
 
 该属性所对应的值是一个 NSNumber 对象(整数)。该值指定是否在文字上加上删除线，该值参考“Underline Style Attributes”。默认值是NSUnderlineStyleNone。
 
 8> NSUnderlineStyleAttributeName(下划线)
 
 该属性所对应的值是一个 NSNumber 对象(整数)。该值指定是否在文字上加上下划线，该值参考“Underline Style Attributes”。默认值是NSUnderlineStyleNone。
 
 9> NSStrokeColorAttributeName(边线颜色)
 
 该属性所对应的值是一个 UIColor 对象。如果该属性不指定（默认），则等同于 NSForegroundColorAttributeName。否则，指定为删除线或下划线颜色。更多细节见“Drawing attributedstrings that are both filled and stroked”。
 
 10> NSStrokeWidthAttributeName(边线宽度)
 
 该属性所对应的值是一个 NSNumber 对象(小数)。该值改变描边宽度（相对于字体size 的百分比）。默认为 0，即不改变。正数只改变描边宽度。负数同时改变文字的描边和填充宽度。例如，对于常见的空心字，这个值通常为3.0。
 
 11> NSShadowAttributeName(阴影)
 
 该属性所对应的值是一个 NSShadow 对象。默认为 nil。
 
 12> NSVerticalGlyphFormAttributeName(横竖排版)
 
 该属性所对应的值是一个 NSNumber 对象(整数)。0 表示横排文本。1 表示竖排文本。在 iOS 中，总是使用横排文本，0 以外的值都未定义。

 */
@end
