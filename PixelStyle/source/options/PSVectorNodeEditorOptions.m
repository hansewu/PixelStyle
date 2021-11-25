//
//  PSVectorNodeEditorOptions.m
//  PixelStyle
//
//  Created by wyl on 16/3/22.
//
//

#import "PSVectorNodeEditorOptions.h"

@implementation PSVectorNodeEditorOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
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
}

- (void)updateModifiers:(unsigned int)modifiers
{
    m_bGroupSelect = NO;
    
    if ((modifiers & NSCommandKeyMask) >> 20)  //多选
    {
        m_bGroupSelect = YES;
    }
    
    m_bOptionKeyEnable = NO;
    if ((modifiers & NSAlternateKeyMask) >> 19)  //全选
    {
        m_bOptionKeyEnable = YES;
    }
}

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

@end