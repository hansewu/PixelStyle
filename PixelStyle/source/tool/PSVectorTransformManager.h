//
//  PSVectorTransformManager.h
//  PixelStyle
//
//  Created by wyl on 16/3/29.
//
//

#import "Globals.h"

typedef enum{
    PICK_TOPLEFT,
    PICK_TOP,
    PICK_TOPRIGHT,
    PICK_RIGHT,
    PICK_BOTTOMRIGHT,
    PICK_BOTTOM,
    PICK_BOTTOMLEFT,
    PICK_LEFT,
    PICK_CENTER,
    PICK_INNER,
    PICK_ROTATE,
    PICK_NONE,
} PSPickResultType;



@interface PSVectorTransformManager : NSObject
{
    id m_idDocument;
    NSPoint m_pointInitial;
    BOOL                m_bTransfoming;
    PSPickResultType m_enumPickType;
    TransformType m_enumTransformType;
    TransformType m_enumTransformTypeInit;
    
    NSPoint m_pointsCur[5]; // 0 左上 1 右上  2右下 3 左下  4 中心点
    NSPoint m_pointsInit[5];
    
    double m_lastRefreshTime;
    
    
    
    NSCursor *curLr;
    NSCursor *curUd;
    NSCursor *curUrdl;
    NSCursor *curUldr;
    NSCursor *curMoveCenter;
    NSCursor *curMove;
    NSCursor *curRotate;
    NSCursor *curSkewLr;
    NSCursor *curSkewUd;
    NSCursor *curSkewUrdl;
    NSCursor *curSkewUldr;
    NSCursor *curSkewCorner;
    NSCursor *m_curNormal;
    NSCursor *m_cursor;
    
    NSCursor *curRotate8[8];
}

- (id)initWithDocument:(id)document;

- (void)setTransformStatus:(TransformType)nTransformState;
- (void)initialAffineInfo;

- (PSPickResultType)getPickType;
- (void)mouseDownAt:(IntPoint)where withEvent:(NSEvent *)event;
- (void)mouseDraggedTo:(IntPoint)where withEvent:(NSEvent *)event;
- (void)mouseUpAt:(IntPoint)where withEvent:(NSEvent *)event;
- (void)mouseMoveTo:(NSPoint)where withEvent:(NSEvent *)event;

- (void)setNormalCursor:(NSCursor *)cursor;
- (void)resetCursorRects;

- (void)drawToolExtra;

- (BOOL)validateMenuItem:(id)menuItem;



@end
