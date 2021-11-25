//
//  PSTransformManager.h
//  PixelStyle
//
//  Created by lchzh on 29/10/15.
//
//

#import <Foundation/Foundation.h>
@class PSDocument;

@interface PSTransformManager : NSObject
{
    PSDocument  *m_idDocument;
    NSMutableArray *m_transformedLayerInfoArray;
    
    BOOL m_useSelection;
    BOOL m_hasBeginTransform;
    BOOL m_needUpdateCenterPoint;
    
    NSPoint m_topLeftPointOriginal;
    NSPoint m_topRightPointOriginal;
    NSPoint m_bottumRightPointOriginal;
    NSPoint m_bottumLeftPointOriginal;
    
    NSPoint m_topLeftPoint;
    NSPoint m_topRightPoint;
    NSPoint m_bottumRightPoint;
    NSPoint m_bottumLeftPoint;
    NSPoint m_centerPoint;
    
    
    NSRecursiveLock * m_lockNewCGLayerLock;

    
}

- (id)initWithDocument:(id)document;

- (void)initialAffineInfo;
-(NSPoint)getAffineDesPointAtIndex:(int)index;
-(void)setAffineDesPoint:(NSPoint)point AtIndex:(int)index;
-(void)moveLayerWithOffset:(NSPoint)offset;

-(NSPoint)getAffineOriginalPointAtIndex:(int)index;
-(CGSize)getAffineOriginalSize;

- (void)setIfHasBeginTransform:(BOOL)hasBegin;
- (BOOL)getIfHasBeginTransform;
- (NSMutableArray*)getTransformedLayerInfoArray;

-(void)makeAffineTransform;
- (void)doNotApplyAffineTransform;
- (void)applyAffineTransform;

- (void)lockNewCGLayer:(BOOL)isLock;

@end
