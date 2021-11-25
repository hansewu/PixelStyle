//
//  PSVectorMoveOptions.m
//  PixelStyle
//
//  Created by wyl on 16/3/22.
//
//

#import "PSVectorMoveOptions.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSVectorMoveTool.h"
#import "PSTools.h"

#import "PSShowInfoPanel.h"
#import "WDDrawingController.h"

@implementation PSVectorMoveOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
#ifdef PROPAINT_VERSION
    [[m_idView viewWithTag:100 + 0] setHidden:YES];
    [[m_idView viewWithTag:100 + 1] setHidden:YES];
#else
#endif

    NSButton *btn;
    btn = [m_idView viewWithTag:100 + 0];
    [btn setToolTip:NSLocalizedString(@"Select and move", nil)];
    btn = [m_idView viewWithTag:100 + 1];
    [btn setToolTip:NSLocalizedString(@"Add and delete anchor", nil)];
    
    [self performSelector:@selector(delayInitData) withObject:nil afterDelay:.05];
    

}

-(void)delayInitData
{
    m_bGroupSelect = NO;
    
    m_nActionStyle = 0;
    [self setActionStyle:m_nActionStyle];
    
    m_nTransformType = Transform_NO;
}

//- (void)updateModifiers:(unsigned int)modifiers
//{
//    m_bGroupSelect = NO;
//    
//    if ((modifiers & NSCommandKeyMask) >> 20 && (modifiers & NSShiftKeyMask) >> 17)  //全选
//    {
//        [(PSVectorMoveTool *)[[m_idDocument tools] getTool:kVectorMoveTool] selectAllObjects];
//    }
//    else if ((modifiers & NSCommandKeyMask) >> 20)  //多选
//    {
//        m_bGroupSelect = YES;
//    }
//    
//    m_bOptionKeyEnable = NO;
//    if ((modifiers & NSAlternateKeyMask) >> 19)  //全选
//    {
//        m_bOptionKeyEnable = YES;
//    }
//}
//
//- (bool)groupSelect
//{
//    return m_bGroupSelect;
//}
//
//- (BOOL)optionKeyEnable
//{
//    return m_bOptionKeyEnable;
//}

#pragma mark - Actions Style

- (void)setActionStyle:(int)nActionStyle
{
    NSButton *btn = [self.view viewWithTag:100 + nActionStyle];
    [self onBtnActionStyle:btn];
    m_nActionStyle = nActionStyle;
}


- (int)getActionStyle
{
    return m_nActionStyle;
}



-(IBAction)onBtnActionStyle:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    m_nActionStyle = btn.tag - 100;
    
    [self resumeTypeButtonImage];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"anchorcontrol-%d-a",m_nActionStyle]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"anchorcontrol-%d-a",m_nActionStyle]]];
    
    [self resumeTransformTypeButtonImage];
    m_nTransformType = Transform_NO;
//    [(PSVectorMoveTool *)[[m_idDocument tools] getTool:kVectorMoveTool] setTransformType:m_nTransformType];
}

-(void)resumeTypeButtonImage
{
    NSButton *btn;
    
    for(int i = 0; i < 2; i++)
    {
        btn = [m_idView viewWithTag:100 + i];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"anchorcontrol-%d",i]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"anchorcontrol-%d",i]]];
    }
    
}


#pragma mark - Transform Style

- (TransformType)getTransformStyle
{
    return m_nTransformType;
}

-(IBAction)changeTransform:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    BOOL bCanDoTransform = [self canDoTransform];
    if(!bCanDoTransform)
    {
        btn.state = !btn.state;
        [self showInfoView];
    }
    
    
    
    if (!btn.state) {
        m_nTransformType = Transform_NO;
    }
    else
    {
        m_nTransformType = btn.tag - 200;
    }
    
    [self resumeTransformTypeButtonImage];
    if(m_nTransformType != Transform_NO)
        [btn setState:NSOnState];
    
//    [(PSVectorMoveTool *)[[m_idDocument tools] getTool:kVectorMoveTool] setTransformType:m_nTransformType];
}



-(void)resumeTransformTypeButtonImage
{
    NSButton *btn;
    
    for(int i = 1; i < 5; i++)
    {
        btn = [m_idView viewWithTag:200 + i];
        [btn setState:NO];
    }
}

-(BOOL)canDoTransform
{
    PSContent *contents = (PSContent *)[m_idDocument contents];
    WDDrawingController *wdDrawingController = [contents wdDrawingController];
    int nSelection = wdDrawingController.selectedObjects.count;
    
    return (nSelection > 0);
}

#pragma mark - showPanel
-(void)showInfoView
{
    PSShowInfoPanel *showInfoPanel = [[[PSShowInfoPanel alloc] init] autorelease];
    [showInfoPanel addMessageText:NSLocalizedString(@"No shape is selected", nil)];
    [showInfoPanel setAutoHiddenDelay:1.5];
    [showInfoPanel showPanel:NSZeroRect];
}



@end