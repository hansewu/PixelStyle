//
//  PSTransformTool.h
//  PixelStyle
//
//  Created by lchzh on 2/11/15.
//
//


#import "Globals.h"
#import "AbstractTool.h"
#import "PSTransformOptions.h"

enum{
    SCALESTYLE_TOPLEFT,
    SCALESTYLE_TOP,
    SCALESTYLE_TOPRIGHT,
    SCALESTYLE_RIGHT,
    SCALESTYLE_BOTTOMRIGHT,
    SCALESTYLE_BOTTOM,
    SCALESTYLE_BOTTOMLEFT,
    SCALESTYLE_LEFT,
    SCALESTYLE_CENTER,
    SCALESTYLE_MOVE,
    SCALESTYLE_ROTATE,
    SCALESTYLE_NONE,
};

@class PSTransformManager;

@interface PSTransformTool : AbstractTool {
    
    // The point from which the drag started
    //IntPoint m_sInitialPoint;
    NSPoint m_sInitialPoint;
    int m_scaleSyle;
    
    int m_currentTransformType;
    float m_originalRotateDegree;
    
    
    NSPoint m_oldPoint0;
    NSPoint m_oldPoint1;
    NSPoint m_oldPoint2;
    NSPoint m_oldPoint3;
    NSPoint m_oldPoint4;
    
    PSTransformManager *m_transformManager;
    BOOL m_hasDisableWindow;
    int m_willChangeToTool;
    NSCursor *m_currentCursor;
       
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
    NSCursor *curRotate8[8];
    
    float m_currentWidthRatio;
    float m_currentHeightRatio;
    float m_currentDegree;
    int m_centerPointType;
    
    double m_lastRefreshTime;
}


/*!
	@method		dealloc
	@discussion	Frees memory occupied by an instance of this class.
 */
- (void)dealloc;

//- (void)undoToOrigin:(IntPoint)origin forLayer:(int)index;

//add by lcz
- (void)redoUndoEventDidEndForLayer:(id)layer; //tool need do something after redo


- (void)setScaleStyle:(int)style;
- (void)initialInfoForTransformTool;
- (void)changeToolFromTransformTool:(int)newtool;
- (BOOL)getIfHasBeginTransform;

- (void)applyTransform;
- (void)cancelTransform;

- (void)setCenterXOffset:(float)xoff;
- (void)setCenterYOffset:(float)yoff;
- (void)setWidthRatio:(float)newRatio;
- (void)setHeightRatio:(float)newRatio;
- (void)setRotateDegree:(float)newDegree;

- (void)autoTransformKeepRatio;

@end
