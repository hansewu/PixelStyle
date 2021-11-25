//
//  PSAbstractVectorSelectOptions.m
//  PixelStyle
//
//  Created by wyl on 16/3/22.
//
//

#import "PSAbstractVectorSelectOptions.h"
#import "PSAbstractVectorSelectTool.h"
#import "PSDocument.h"
#import "PSTools.h"


@implementation PSAbstractVectorSelectOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    m_bGroupSelect = NO;
}

- (void)updateModifiers:(unsigned int)modifiers
{
    m_bGroupSelect = NO;
    
    if ((modifiers & NSCommandKeyMask) >> 20 && (modifiers & NSShiftKeyMask) >> 17)  //全选
    {
        id curTool = [[m_idDocument tools] currentTool];
        if([curTool isKindOfClass:[PSAbstractVectorSelectTool class]])
            [(PSAbstractVectorSelectTool *)curTool selectAllObjects];
    }
    else if ((modifiers & NSCommandKeyMask) >> 20)  //多选
    {
        m_bGroupSelect = YES;
    }
    
    m_bOptionKeyEnable = NO;
    if ((modifiers & NSAlternateKeyMask) >> 19)  //拷贝
    {
        m_bOptionKeyEnable = YES;
    }
    
    m_bShiftKeyEnable = NO;
    if ((modifiers & NSShiftKeyMask) >> 17)  //Ctrl
    {
        m_bShiftKeyEnable = YES;
    }
}

- (bool)groupSelect
{
    return m_bGroupSelect;
}

- (BOOL)optionKeyEnable
{
    return m_bOptionKeyEnable;
}

- (BOOL)shiftKeyEnable
{
    return m_bShiftKeyEnable;
}

@end