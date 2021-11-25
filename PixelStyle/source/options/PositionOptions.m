#import "PositionOptions.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "AspectRatio.h"


@implementation PositionOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [m_idTop setToolTip:NSLocalizedString(@"Align top edges", nil)];
    [m_idVerticalCenter setToolTip:NSLocalizedString(@"Vertical align center", nil)];
    [m_idBottom setToolTip:NSLocalizedString(@"Align bottom edges", nil)];
    [m_idLeft setToolTip:NSLocalizedString(@"Align left edges", nil)];
    [m_idHorizonCenter setToolTip:NSLocalizedString(@"Horizontal align center", nil)];
    [m_idRight setToolTip:NSLocalizedString(@"Align right edges", nil)];
    [(NSButton *)m_idAutoSelection setTitle:NSLocalizedString(@"Auto Selection", nil)];
    [(NSButton *)m_idAutoAlign setTitle:NSLocalizedString(@"Auto Alignment", nil)];
    
    if ([gUserDefaults objectForKey:@"position anchor"] == NULL) {
        [m_idCanAnchorCheckbox setState:NSOffState];
    }
    else {
        [m_idCanAnchorCheckbox setState:[gUserDefaults boolForKey:@"position anchor"]];
    }
    m_nFunction = kMovingLayer;
}

- (BOOL)canAnchor
{
    return [m_idCanAnchorCheckbox state];
}

- (BOOL)isAutoSelectLayer
{
    return [m_idAutoSelection state];
}

- (BOOL)isAutoAlignLayer
{
    return [m_idAutoAlign state];
}

- (int)toolFunction
{
    return m_nFunction;
}
- (void)setFunctionFromIndex:(unsigned int)index
{
    switch (index) {
        case kShiftModifier:
            m_nFunction = kScalingLayer;
            break;
        case kControlModifier:
			m_nFunction = kRotatingLayer;
			break;
		default:
			m_nFunction = kMovingLayer;
			break;
	}
	// Let's not check for floating, maybe we can do it all
	/*if(m_nFunction == kRotatingLayer){
		if(![[document selection] floating])
			m_nFunction = kMovingLayer;
	}else if(m_nFunction == kScalingLayer){
		if([[document selection] floating])
			m_nFunction = kMovingLayer;
	}*/
}

- (void)updateModifiers:(unsigned int)modifiers
{
	[super updateModifiers:modifiers];
	int modifier = [super modifier];
	[self setFunctionFromIndex: modifier];
}



- (void)shutdown
{
	[gUserDefaults setObject:[m_idCanAnchorCheckbox state] ? @"YES" : @"NO" forKey:@"position anchor"];
}


@end
