//
//  PSTransformOptions.h
//  PixelStyle
//
//  Created by lchzh on 2/11/15.
//
//

#import "AbstractScaleOptions.h"


@interface PSTransformOptions : AbstractScaleOptions <NSTextFieldDelegate>
{
    IBOutlet NSButton *m_btnScale;
    IBOutlet NSButton *m_btnRotate;
    IBOutlet NSButton *m_btnSkew;
    IBOutlet NSButton *m_btnPerspective;
    
    IBOutlet NSTextField *m_textFieldWidth;
    IBOutlet NSTextField *m_textFieldHeight;
    IBOutlet NSTextField *m_textFieldPosX;
    IBOutlet NSTextField *m_textFieldPosY;
    IBOutlet NSTextField *m_textFieldAngle;
    
    IBOutlet NSButton *m_btnApply;
    IBOutlet NSButton *m_btnCancel;
    
    TransformType m_curTransformType;

    id m_idTransformedTool;
}

-(IBAction)onApply:(id)sender;
-(IBAction)onCancel:(id)sender;

-(IBAction)onBtnScale:(id)sender;
-(IBAction)onBtnRotate:(id)sender;
-(IBAction)onBtnSkew:(id)sender;
-(IBAction)onBtnPerspective:(id)sender;

- (void)setTransformTool:(id)tool;

-(void)setTransform:(TransformType)transformType;
-(TransformType)getTransformType;


-(void)setWidth:(float)fWidth;
-(void)setHeight:(float)fHeight;
-(void)setPosX:(float)fPosX;
-(void)setPosY:(float)fPosY;
-(void)setRotate:(float)fAngle;

-(void)setApplyCancelBtnHidden:(BOOL)bHide;


@end
