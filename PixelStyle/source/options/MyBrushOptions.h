//
//  MyBrushOptions.h
//  PixelStyle
//
//  Created by wyl on 15/9/9.
//
//

#import "AbstractPaintOptions.h"
#import "MyCustomComboBox.h"

@interface MyBrushOptions : AbstractPaintOptions <MyCustomComboBoxDelegate>
{
    IBOutlet NSImageView *m_imageViewMyBrush;
    IBOutlet id m_idOpenBrushPanel;
    IBOutlet MyCustomComboBox *m_myCustomComboRadius;
    IBOutlet MyCustomComboBox *m_myCustomComboOpacity;
    IBOutlet MyCustomComboBox *m_myCustomComboHardness;
    IBOutlet MyCustomComboBox *m_myCustomComboSmooth;
    IBOutlet MyCustomComboBox *m_myCustomComboPressure;
    
    IBOutlet NSTextField *m_labelRadius;
    IBOutlet NSTextField *m_labelOpacity;
    IBOutlet NSTextField *m_labelHardness;
    IBOutlet NSTextField *m_labelSmooth;
    IBOutlet NSTextField *m_labelPressure;

    IBOutlet NSScrollView *m_idFavoriteBrushesView;
    NSMutableArray *m_arrFavoriteBrushNames;
    int m_nFavoriteBrushIndex;
    
    NSMutableDictionary *m_mdFavoriteBrushHistoryPara;
}

- (float)smooth;
- (void)setSmooth:(float)fSmooth;

- (float)radius;
-(void)setRadius:(float)fRadius;

- (float)hardness;
- (void)setHardness:(float)fHardness;

- (float)opacity;
- (void)setOpacity:(float)fOpacity;

- (float)pressure;
- (void)setPressure:(float)fPressure;

-(void)loadFavoriteBrush;
-(void)setFavoriteBrushIndex:(int)nIndex;
-(int)getFavoriteBrushIndex;

- (IBAction)toggleMyBrushes:(id)sender;

-(void)updateBrushImage:(NSImage *)image;

- (void)addRadius:(BOOL)isAdd;

@end
