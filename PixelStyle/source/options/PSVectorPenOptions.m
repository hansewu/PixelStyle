//
//  PSVectorPenOptions.m
//  PixelStyle
//
//  Created by lchzh on 23/3/16.
//
//

#import "PSVectorPenOptions.h"

@implementation PSVectorPenOptions


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSButton *btn;
    btn = [m_idView viewWithTag:100 + 0];
    [btn setToolTip:NSLocalizedString(@"Pen", nil)];
    btn = [m_idView viewWithTag:100 + 1];
    [btn setToolTip:NSLocalizedString(@"Freeform pen", nil)];
    btn = [m_idView viewWithTag:100 + 2];
    [btn setToolTip:NSLocalizedString(@"Closed freeform pen", nil)];
    
    
    m_nPenStyle = 0;
    [self setPenStyle:m_nPenStyle];
}

- (void)setPenStyle:(int)nPenStyle
{
    NSButton *btn = [self.view viewWithTag:100 + nPenStyle];
    [self onBtnPenStyle:btn];
    m_nPenStyle = nPenStyle;
}

- (int)getPenStyle
{
    return m_nPenStyle;
}

- (void)updateModifiers:(unsigned int)modifiers
{
    m_bOptionKeyEnable = NO;
    if ((modifiers & NSAlternateKeyMask) >> 19)
    {
        m_bOptionKeyEnable = YES;
    }
    
    
    m_bControlKeyEnable = NO;
    if ((modifiers & NSCommandKeyMask) >> 20 && (modifiers & NSControlKeyMask) >> 18)
    {
        m_bControlKeyEnable = YES;
    }
}

- (BOOL)optionKeyEnable
{
    return NO;//m_bOptionKeyEnable;
}

- (BOOL)controlKeyEnable
{
    return m_bControlKeyEnable;
}

-(IBAction)onBtnPenStyle:(id)sender
{
    NSButton *btn = (NSButton *)sender;
    m_nPenStyle = btn.tag - 100;
    
    [self resumeTypeButtonImage];
    [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"pen-%d-a",m_nPenStyle]]];
    [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"pen-%d-a",m_nPenStyle]]];
    
    //[self changeToolOptionsUI];
}

-(void)resumeTypeButtonImage
{
    NSButton *btn;
    
    for(int i = 0; i < 3; i++)
    {
        btn = [m_idView viewWithTag:100 + i];
        [btn setImage:[NSImage imageNamed:[NSString stringWithFormat:@"pen-%d",i]]];
        [btn setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"pen-%d",i]]];
    }
}

@end