#import "EllipseSelectOptions.h"
#import "AspectRatio.h"

@implementation EllipseSelectOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //[m_idAspectRatio setToolTip:NSLocalizedString(@"Set the drawing shape of marquee tool", nil)];
    
	[m_idAspectRatio awakeWithMaster:self andString:@"ell"];
    
    //feather 初始值获取设置
    int nValue;
    if ([gUserDefaults objectForKey:@"ellipse selection feather"] == NULL) {
        nValue = 0;
    }
    else {
        nValue = [gUserDefaults integerForKey:@"ellipse selection feather"];
//        if (nValue < [m_sliderFeather minValue] || nValue > [m_sliderFeather maxValue])
//            nValue = 0;
    }
    
    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"%d px"), nValue]];
}

- (NSSize)ratio
{
	return [m_idAspectRatio ratio];
}

- (int)aspectType
{
	return [m_idAspectRatio aspectType];
}

- (void)shutdown
{
    [gUserDefaults setInteger:[m_texFieldFeather intValue] forKey:@"ellipse selection feather"];
	[m_idAspectRatio shutdown];
}

@end
