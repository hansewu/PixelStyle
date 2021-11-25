//
//  MyBrushUtility.h
//  PixelStyle
//
//  Created by wyl on 15/9/8.
//
//

#import "AbstractPanelUtility.h"
#import "PSGestureButton.h"
@interface MyBrushUtility : AbstractPanelUtility<PSGestureRecognizerProtocal>
{
    // The view that displays the brushes
    IBOutlet NSScrollView *m_idView;
    IBOutlet NSScrollView *m_idFavoriteBrushesView;
    IBOutlet NSImageView *m_imageViewShowHelp;
    // The document which is the focus of this utility
    IBOutlet id m_idDocument;
    
    id m_idMyBrushesDrawView;
    
    // The index of the currently group
    int m_nActiveBrushGroup;
    
    NSMutableArray *m_arrGroupNames;
    NSMutableArray *m_arrFavoriteBrushNames;
    
    void *m_hBrush;
    NSString *m_strCurrBrushName;
    
    NSDictionary *m_dictFavoriteBrushHistoryPara;
    
    IBOutlet id m_idBrushType;
    IBOutlet id m_idPenType;
    IBOutlet id m_idPencilType;
    IBOutlet id m_idAirbrushType;
    IBOutlet id m_idScrawlType;
    IBOutlet id m_idSpecialType;
}

- (void)awakeFromNib;

-(IBAction)changeBrushStyle:(id)sender;

-(void)changeBrushPara:(int)nItem value:(float)fValue;

-(void)changeCurrentBrush:(NSString *)sBrushName;

- (void *)activeMyBrush;
- (NSString *)activeMyBrushName;

- (void)shutdown;


@end
