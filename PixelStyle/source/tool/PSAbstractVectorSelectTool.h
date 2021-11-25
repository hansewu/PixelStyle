//
//  PSAbstractVectorSelectTool.h
//  PixelStyle
//
//  Created by wyl on 16/3/18.
//
//

#import "Globals.h"
#import "AbstractTool.h"

@class WDBezierNode;
@class WDTextPath;
@class WDElement;
@class WDPickResult;
@interface PSAbstractVectorSelectTool : AbstractTool

{
    CGPoint m_cgPointInit;
    CGPoint m_cgPointCurrent;
    // The point from which the drag started
    BOOL m_bDragged;
    BOOL m_bMouseDown;
    
    BOOL                    m_bTransforming;
    
    BOOL                    marqueeMode_;
    CGRect                  m_cgRectMarquee;
    
    BOOL                    objectWasSelected_;
    WDElement               *lastTappedObject_;
    
    //mouse move
    WDElement               *lastMouseMoveOnObject_;
    int                     m_nMouseMoveOnObjecLayerIndex;
}

-(void)selectAllObjects;
- (BOOL)isSelectedObject:(WDElement *)element;

- (BOOL)judgeVectorLayerContainsElement:(WDElement*)element;
- (BOOL)judgeVectorElementNeedDraw:(WDElement*)element;

- (WDPickResult *) objectUnderPoint:(CGPoint)pt viewScale:(float)viewScale whichLayerIndex:(int *)nLayerIndex;

-(void)drawSelectedObjectExtra;


@end
