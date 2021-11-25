//
//  PSVecLayer.h
//  PixelStyle
//
//  Created by wzq on 15/11/30.
//
//

#import "PSLayer.h"

#import "WDUtilities.h"

@class WDLayer;
@class WDPath;

@interface PSVecLayer : PSLayer
{
    WDLayer *m_wdLayer;
    
    CGContextRef m_contextData;
    
    CGAffineTransform  m_Transformed;
    
    NSLock  *m_lockMakeTransform;
    
    BOOL  m_bIsEffectValid;
}

- (id)initWithDocument:(id)doc;
- (id)initWithDocument:(id)doc width:(int)lwidth height:(int)lheight opaque:(BOOL)opaque spp:(int)lspp;
- (id)initWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata spp:(int)lspp;
- (id)initWithDocument:(id)doc layer:(PSVecLayer*)layer;
- (id)initFloatingWithDocument:(id)doc rect:(IntRect)lrect data:(unsigned char *)ldata;

- (id)initWithDocumentAfterCoder:(id)doc layer:(PSVecLayer*)endocerLayer;
- (id)initWithDocument:(id)doc textLayer:(PSVecLayer*)layer;

-(WDLayer *)getLayer;
-(void) invalidData;


- (void)addPathObject:(id)obj;
- (void)removePathObject:(id)obj;
-(void)setPath:(WDPath*)path;
-(void)refreshLayer;

- (void)setPerspectiveTransform:(PSPerspectiveTransform)perspectiveTransform;
- (void)concatPerspectiveTransform:(PSPerspectiveTransform)perspectiveTransform withReverseTransform:(PSPerspectiveTransform)reversePerspectiveTransform;

- (CGAffineTransform)transform;
- (void)concatAffineTransform:(CGAffineTransform) transform;
- (void)applyTransform;
- (void)setOffsetsNoTransform:(IntPoint)newOffsets;

@end
