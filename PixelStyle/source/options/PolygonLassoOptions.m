#import "PolygonLassoOptions.h"
#import "PSSelection.h"
#import "ToolboxUtility.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSTools.h"

@implementation PolygonLassoOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //feather 初始值获取设置
    int nValue;
    if ([gUserDefaults objectForKey:@"polygonLasso selection feather"] == NULL) {
        nValue = 0;
    }
    else {
        nValue = [gUserDefaults integerForKey:@"polygonLasso selection feather"];
//        if (nValue < [m_sliderFeather minValue] || nValue > [m_sliderFeather maxValue])
//            nValue = 0;
    }
//    [m_sliderFeather setIntValue:nValue];
//    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"feather: %d"), nValue]];
    
    [m_texFieldFeather setStringValue:[NSString stringWithFormat:LOCALSTR(@"feather", @"%d px"), nValue]];
}

- (void)shutdown
{
    [gUserDefaults setInteger:[m_texFieldFeather intValue] forKey:@"polygonLasso selection feather"];
}

@end
