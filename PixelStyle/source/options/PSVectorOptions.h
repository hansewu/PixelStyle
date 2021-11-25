//
//  PSVectorOptions.h
//  PixelStyle
//
//  Created by lchzh on 1/4/16.
//
//

//#import "AbstractOptions.h"
#import "PSAbstractVectorSelectOptions.h"
@class PSColorWell;
@class PSFillController;
@class PSStrokeController;
@class PSArrowController;
@class PSStrokeLineTypeController;
@class PSPopButtonImage;

@interface PSVectorOptions : PSAbstractVectorSelectOptions
{
    IBOutlet PSColorWell                *fillWell_;
    IBOutlet PSColorWell                *strokeWell_;
    IBOutlet NSTextField                *m_labelFill;
    IBOutlet NSTextField                *m_labelStroke;

    IBOutlet NSButton                   *m_btnArrow;
    IBOutlet NSButton                   *m_btnLineStyle;
    
    IBOutlet NSButton                   *m_btnNewLayerCheck;
    
    PSFillController                    *m_fillController;
    PSStrokeController                  *m_strokeController;
    PSArrowController                   *m_arrowController;
    PSStrokeLineTypeController          *m_lineTypeController;
    
    IBOutlet PSPopButtonImage           *m_popBtnAlign;
    IBOutlet PSPopButtonImage           *m_popBtnArrange;
    IBOutlet PSPopButtonImage           *m_popBtnPathsMode;
}

- (BOOL)isNewLayerOptionEnable;

@end
