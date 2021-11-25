//
//  MyBrushDrawView.h
//  PixelStyle
//
//  Created by wyl on 15/9/10.
//
//

#import "Globals.h"

@interface MyBrushDrawView : NSView
{
    // The BrushUtility controlling this view
    id m_idMaster;
    
    void *m_hCanvas;
    
    NSMutableDictionary *m_mdCellBuffer;
    int m_nDrawPositionX;
}

- (id)initWithMaster:(id)sender;

-(void)update;

-(void)stopUpdate;

@end
