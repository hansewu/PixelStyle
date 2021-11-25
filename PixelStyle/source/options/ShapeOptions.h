//
//  ShapeOptions.h
//  PixelStyle
//
//  Created by wyl on 16/2/23.
//
//

#import "PSVectorOptions.h"
#import "MyCustomComboBox.h"

enum {
    PSShapeRectangle = 0,
    PSShapeOval,
    PSShapeStar,
    PSShapePolygon,
    PSShapeLine,
    PSShapeSpiral
};

@interface ShapeOptions : PSVectorOptions
{
    IBOutlet NSButton                   *m_btnArrow2;
    IBOutlet NSTextField                *m_textFieldToolOptions;
    IBOutlet MyCustomComboBox           *m_myCustomComBoxToolOptions;
    

    
    int m_nShapeMode;
    // polygon support
    int                 m_nPolygonNumPoints;
    // rect support
    float               m_fRectCornerRadius;
    // star support
    int                 m_nStarNumPoints;
    float               m_fStarInnerRadiusRatio;
    
    // spiral support
    int                 m_nSpiralDecay;
}

- (void)awakeFromNib;


- (void)setShapeMode:(int)nShapeMode;
- (int)shapeMode;

- (void)setPolygonNumPoints:(int)nPolygonNumPoints;
- (int)polygonNumPoints;

- (void)setRectCornerRadius:(float)fRectCornerRadius;
- (float)rectCornerRadius;

- (void)setStarNumPoints:(int)nStarNumPoints;
- (int)starNumPoints;

- (void)setStarInnerRadiusRatio:(float)fStarInnerRadiusRatio;
- (float)starInnerRadiusRatio;

- (void)setSpiralDecay:(int)nSpiralDecay;
- (int)spiralDecay;


/*!
	@method		shutdown
	@discussion	Saves current options upon shutdown.
 */
- (void)shutdown;


@end
