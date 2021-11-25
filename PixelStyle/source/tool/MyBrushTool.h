//
//  MyBrushTool.h
//  PixelStyle
//
//  Created by wyl on 15/9/8.
//
//

#import "AbstractTool.h"
#import "PSSecureImageData.h"

@interface MyBrushTool : AbstractTool
{
    int m_nCurrentColor;
    double m_dPreTime;
    
    // Has the first touch been done?
    BOOL m_bFirstTouchDone;
    
    //The canvas for the document
    void *m_hCanvas;
    // A long list of the stroke buffer we can write/read
    NSMutableDictionary *m_mdStrokeBufferCache;
    
    IntRect         m_rectLayerLast;
    unsigned char * m_dataLayerLast;
    
    BOOL     m_bExpanded;
    BOOL     m_bAutoExpand;
    PSSecureImageData *m_imageDrawed;

    
}

- (void*)getCanvas;

@end
