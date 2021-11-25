//
//  PSAbstractVectorDrawTool.h
//  PixelStyle
//
//  Created by wyl on 16/4/1.
//
//

//#import "AbstractTool.h"
#import "PSAbstractVectorSelectTool.h"
#import "PSVectorTransformManager.h"

@class WDPath;
@class WDElement;

@interface PSAbstractVectorDrawTool : PSAbstractVectorSelectTool
{
    WDPath              *m_pathTemp;
    
    NSView                     *m_bottomToolView;
    //transform
    PSVectorTransformManager    *m_vectorTransformManager;
    TransformType               m_enumTransfomType;
}

//-(void)drawSelectedObjectExtra;
-(void)drawAuxiliaryLine;

//- (BOOL)judgeVectorLayerContainsElement:(WDElement*)element;
//- (BOOL)judgeVectorElementNeedDraw:(WDElement*)element;

-(void)setTransformType:(TransformType)TransformType;

@end
