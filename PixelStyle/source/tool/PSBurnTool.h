//
//  PSBurnTool.h
//  PixelStyle
//
//  Created by lchzh on 4/28/16.
//
//


#import "Globals.h"
#import "AbstractTool.h"
#import "GraphicsToBuffer.h"

typedef struct {
    IntPoint point;
    unsigned char pressure;
    unsigned char special;
} BTPointRecord;

#define kMaxBTPoints 16384


@interface PSBurnTool : AbstractTool
{
    // The last point we've been and the last point a brush was plotted (there is a difference)
    NSPoint m_poiLast, m_poiLastPlotPoint;
    
    // The set of pixels upon which to base the brush plot
    unsigned char m_aBasePixel[4];
    
    // The distance travelled by the brush so far
    double m_dDistance;
    
    // The current position in the list we have drawing
    int m_nDrawingPos;
    
    // The current position in the list
    int m_nPos;
    
    // The list of points
    BTPointRecord *m_psPoints;
    
    // Have we finished drawing?
    BOOL m_bDrawingDone;
    
    // Is drawing multithreaded?
    BOOL m_bMultithreaded;
    
    // Has the first touch been done?
    BOOL m_bFirstTouchDone;
    
    // The last where recorded
    IntPoint m_sLastWhere;
    
    // The last pressure value
    int m_sLastPressure;
    
    
    IMAGE_BUFFER m_imageBuffer;
}

@end
