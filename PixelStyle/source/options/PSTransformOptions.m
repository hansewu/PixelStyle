//
//  PSTransformOptions.m
//  PixelStyle
//
//  Created by lchzh on 2/11/15.
//
//

#import "PSTransformOptions.h"
#import "PSTransformTool.h"
#import "PSController.h"
#import "ToolboxUtility.h"
#import "UtilitiesManager.h"
#import "PSTools.h"
#import <QuartzCore/QuartzCore.h>

#define TEXTFIELD_WIDTH_TAG 101
#define TEXTFIELD_HEIGHT_TAG 102
#define TEXTFIELD_POSX_TAG 103
#define TEXTFIELD_POSY_TAG 104
#define TEXTFIELD_ANGLE_TAG 105

@implementation PSTransformOptions

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_btnScale setToolTip:NSLocalizedString(@"Scale", nil)];
    [m_btnRotate setToolTip:NSLocalizedString(@"Rotate", nil)];
    [m_btnSkew setToolTip:NSLocalizedString(@"Skew", nil)];
    [m_btnPerspective setToolTip:NSLocalizedString(@"Perspective", nil)];
    [m_textFieldWidth setToolTip:NSLocalizedString(@"Adjust horizontal scale", nil)];
    [m_textFieldHeight setToolTip:NSLocalizedString(@"Adjust vertical scale", nil)];
    [m_textFieldPosX setToolTip:NSLocalizedString(@"Set horizontal position of reference point", nil)];
    [m_textFieldPosY setToolTip:NSLocalizedString(@"Set vertical position of reference point", nil)];
    [m_textFieldAngle setToolTip:NSLocalizedString(@"Set rotation", nil)];
    [m_btnApply setToolTip:NSLocalizedString(@"Apply transform", nil)];
    [m_btnCancel setToolTip:NSLocalizedString(@"Cancel transform", nil)];
    
    
    m_curTransformType = Transform_Scale;
    [self resumeButtonImage];
    [m_btnScale setImage:[NSImage imageNamed:@"transform-scale-a"]];
    [m_btnScale setAlternateImage:[NSImage imageNamed:@"transform-scale-a"]];
    
    [m_textFieldWidth setTag:TEXTFIELD_WIDTH_TAG];
    [m_textFieldHeight setTag:TEXTFIELD_HEIGHT_TAG];
    [m_textFieldPosX setTag:TEXTFIELD_POSX_TAG];
    [m_textFieldPosY setTag:TEXTFIELD_POSY_TAG];
    [m_textFieldAngle setTag:TEXTFIELD_ANGLE_TAG];
    
    [self setPosX:0.0];
    [self setPosY:0.0];
    [self setWidth:1.0];
    [self setHeight:1.0];
    [self setRotate:0.0];
    
    [self setApplyCancelBtnHidden:YES];
}


#pragma mark - actions
-(IBAction)onApply:(id)sender
{
    [self setApplyCancelBtnHidden:YES];
    [m_idTransformedTool applyTransform];
    
    ToolboxUtility *toolUtility = (ToolboxUtility *)[(UtilitiesManager *)[PSController utilitiesManager] toolboxUtilityFor:m_idDocument];
    if(toolUtility)
    {
        [toolUtility switchToolWithToolIndex:kPositionTool];
    }
}
-(IBAction)onCancel:(id)sender
{
    [self setApplyCancelBtnHidden:YES];
    [m_idTransformedTool cancelTransform];
}

-(void)onBtnScale:(id)sender
{
    if(m_curTransformType == Transform_Scale) return;
    
    m_curTransformType = Transform_Scale;
    [self resumeButtonImage];
    [m_btnScale setImage:[NSImage imageNamed:@"transform-scale-a"]];
    [m_btnScale setAlternateImage:[NSImage imageNamed:@"transform-scale-a"]];
    
}

-(void)onBtnRotate:(id)sender
{
    if(m_curTransformType == Transform_Rotate) return;
    
    m_curTransformType = Transform_Rotate;
    [self resumeButtonImage];
    [m_btnRotate setImage:[NSImage imageNamed:@"transform-rotate-a"]];
    [m_btnRotate setAlternateImage:[NSImage imageNamed:@"transform-rotate-a"]];
}

-(void)onBtnSkew:(id)sender
{
    if(m_curTransformType == Transform_Skew) return;
    
    m_curTransformType = Transform_Skew;
    [self resumeButtonImage];
    [m_btnSkew setImage:[NSImage imageNamed:@"transform-miter-a"]];
    [m_btnSkew setAlternateImage:[NSImage imageNamed:@"transform-miter-a"]];
}

-(void)onBtnPerspective:(id)sender
{
    if(m_curTransformType == Transform_Perspective) return;
    
    m_curTransformType = Transform_Perspective;
    [self resumeButtonImage];
    [m_btnPerspective setImage:[NSImage imageNamed:@"transform-perspective-a"]];
    [m_btnPerspective setAlternateImage:[NSImage imageNamed:@"transform-perspective-a"]];
}

-(void)resumeButtonImage
{
    [m_btnScale setImage:[NSImage imageNamed:@"transform-scale"]];
    [m_btnScale setAlternateImage:[NSImage imageNamed:@"transform-scale"]];
    [m_btnRotate setImage:[NSImage imageNamed:@"transform-rotate"]];
    [m_btnRotate setAlternateImage:[NSImage imageNamed:@"transform-rotate"]];
    [m_btnSkew setImage:[NSImage imageNamed:@"transform-miter"]];
    [m_btnSkew setAlternateImage:[NSImage imageNamed:@"transform-miter"]];
    [m_btnPerspective setImage:[NSImage imageNamed:@"transform-perspective"]];
    [m_btnPerspective setAlternateImage:[NSImage imageNamed:@"transform-perspective"]];
}

- (void)setTransformTool:(id)tool
{
    m_idTransformedTool = tool;
}

-(void)setTransform:(TransformType)transformType
{
    if(m_curTransformType == transformType) return;
    
    switch (transformType)
    {
        case Transform_NO:
        {
            [self resumeButtonImage];
            m_curTransformType = Transform_NO;
        }
            break;
        case Transform_Scale:
            [self onBtnScale:m_btnScale];
            break;
            
        case Transform_Rotate:
            [self onBtnRotate:m_btnRotate];
            break;
            
        case Transform_Skew:
            [self onBtnSkew:m_btnSkew];
            break;
        
        case Transform_Perspective:
            [self onBtnPerspective:m_btnPerspective];
            break;
            
        default:
            break;
    }
    
}

-(TransformType)getTransformType
{
    return m_curTransformType;
}


#pragma mark - textField
-(void)setWidth:(float)fWidth
{
    NSString *text = [[NSString stringWithFormat:@"%0.0f",fWidth * 100] stringByAppendingString:@"%"];
    [m_textFieldWidth setStringValue:text];
}

-(void)setHeight:(float)fHeight
{
    NSString *text = [[NSString stringWithFormat:@"%0.0f",fHeight * 100] stringByAppendingString:@"%"];
    [m_textFieldHeight setStringValue:text];
}

-(void)setPosX:(float)fPosX
{
    NSString *text = [NSString stringWithFormat:@"%0.0f",fPosX];
    [m_textFieldPosX setStringValue:text];
}

-(void)setPosY:(float)fPosY
{
    NSString *text = [NSString stringWithFormat:@"%0.0f",fPosY];
    [m_textFieldPosY setStringValue:text];
}

-(void)setRotate:(float)fAngle
{
    NSString *text = [NSString stringWithFormat:@"%0.0f",fAngle];
    [m_textFieldAngle setStringValue:text];
}


#pragma mark -TextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSTextField *textField = (NSTextField *)control;
    switch (textField.tag) {
        case TEXTFIELD_POSX_TAG:{
            float value = [m_textFieldPosX floatValue];
            value = MIN(5000, MAX(-5000, value));
            [self setPosX:value];
            [m_idTransformedTool setCenterXOffset:value];
        }
            break;
        case TEXTFIELD_POSY_TAG:{
            float value = [m_textFieldPosX floatValue];
            value = MIN(5000, MAX(-5000, value));
            [self setPosY:value];
            [m_idTransformedTool setCenterYOffset:value];
        }
            break;
        case TEXTFIELD_WIDTH_TAG:{
            float value = [m_textFieldWidth floatValue];
            value = MIN(1000, MAX(5, value)) / 100.0;
            [self setWidth:value];
            [m_idTransformedTool setWidthRatio:value];
        }
            break;
        case TEXTFIELD_HEIGHT_TAG:{
            float value = [m_textFieldHeight floatValue];
            value = MIN(1000, MAX(5, value)) / 100.0;
            [self setHeight:value];
            [m_idTransformedTool setHeightRatio:value];
        }
            break;
        case TEXTFIELD_ANGLE_TAG:{
            float value = [m_textFieldAngle floatValue];
            value = MIN(360, MAX(0, value));
            [self setRotate:value];
            [m_idTransformedTool setRotateDegree:value];
        }
            break;
            
        default:
            break;
    }
    
    
    return YES;
}

-(void)setApplyCancelBtnHidden:(BOOL)bHide
{
    [m_btnApply setHidden:bHide];
    [m_btnCancel setHidden:bHide];
    
    if(!bHide)
    {
        if(![m_btnApply.layer animationForKey:@"scaling"])
        {
            [m_btnApply superview].wantsLayer = YES;
            CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            a.fromValue = [NSNumber numberWithFloat:0.95];
            a.toValue = [NSNumber numberWithFloat:1.2];
            a.beginTime = 0.;
            a.duration = 2.0; // seconds
        //    a.repeatCount = HUGE_VAL;
            
            CABasicAnimation *a2 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            a2.fromValue = [NSNumber numberWithFloat:1.2];
            a2.toValue = [NSNumber numberWithFloat:0.95];
            a2.beginTime = 2.0;
            a2.duration = 2.0; // seconds
         //   a2.repeatCount = HUGE_VAL;
            
            CAAnimationGroup*   group = [CAAnimationGroup new];
            group.beginTime = 0.0;
            group.duration = 4;
            group.animations = @[ a, a2 ];
            group.repeatCount = HUGE_VAL;
            
            [m_btnApply.layer addAnimation:group forKey:@"scaling"];
        }
    }
}

@end
