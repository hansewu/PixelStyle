//
//  PSAbstractLayer.m
//  PixelStyle
//
//  Created by a on 4/22/14.
//
//

#import "PSAbstractLayer.h"
#import "PSSmartFilterManager.h"

@implementation PSAbstractLayer

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInt:1] forKey:@"versionMajor"];
    [aCoder encodeObject:[NSNumber numberWithInt:0] forKey:@"versionMinor"];
    
    [aCoder encodeObject:[NSNumber numberWithInt:m_enumLayerFormat] forKey:@"layerFormat"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nHeight] forKey:@"height"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nWidth] forKey:@"width"];
    [aCoder encodeObject:m_strName forKey:@"layerName"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nOpacity] forKey:@"opacity"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nXoff] forKey:@"offsetX"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_nYoff] forKey:@"offsetY"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bVisible] forKey:@"visible"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bLockd] forKey:@"lock"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bLinked] forKey:@"link"];
    [aCoder encodeObject:[NSNumber numberWithBool:m_bFloating] forKey:@"floating"];
    
    [NSThread sleepForTimeInterval:0.001];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (!self)
    {
        return nil;
    }
    
    
    m_nVersionMajor = [[aDecoder decodeObjectForKey:@"versionMajor"] intValue];
    m_nVersionMinor = [[aDecoder decodeObjectForKey:@"versionMinor"] intValue];
    
    if(m_nVersionMajor == 1 && m_nVersionMinor == 0)
    {
        m_enumLayerFormat = [[aDecoder decodeObjectForKey:@"layerFormat"] intValue];
        m_nHeight = [[aDecoder decodeObjectForKey:@"height"] intValue];
        m_nWidth = [[aDecoder decodeObjectForKey:@"width"] intValue];
        m_strName = [aDecoder decodeObjectForKey:@"layerName"];
        m_nOpacity = [[aDecoder decodeObjectForKey:@"opacity"] intValue];
        m_nXoff = [[aDecoder decodeObjectForKey:@"offsetX"] intValue];
        m_nYoff = [[aDecoder decodeObjectForKey:@"offsetY"] intValue];
        m_bVisible = [[aDecoder decodeObjectForKey:@"visible"] boolValue];
        m_bLockd = [[aDecoder decodeObjectForKey:@"lock"] boolValue];
        m_bLinked = [[aDecoder decodeObjectForKey:@"link"] boolValue];
        m_bFloating = [[aDecoder decodeObjectForKey:@"floating"] boolValue];
    }
    else if(m_nVersionMajor > 1 || (m_nVersionMajor == 1 && m_nVersionMinor > 0))//大于当前应用程序支持版本，查找当前版本应用的变量，若获取到，就赋值，获取不到就不赋值
    {
        return NULL;
    }
    else //小于当前应用程序支持版本，查找当前版本应用的变量，若获取到，就赋值，获取不到就不赋值
    {
        m_nHeight = m_nWidth = 0;
        m_nOpacity = 255;
        m_nXoff = m_nYoff = 0;
        m_bVisible = YES;
        m_bFloating = NO;
        m_bLockd = NO;
        m_bLinked = NO;
        
        if([aDecoder decodeObjectForKey:@"layerFormat"])
            m_enumLayerFormat = [[aDecoder decodeObjectForKey:@"layerFormat"] intValue];
        if([aDecoder decodeObjectForKey:@"height"])
            m_nHeight = [[aDecoder decodeObjectForKey:@"height"] intValue];
        if([aDecoder decodeObjectForKey:@"width"])
            m_nWidth = [[aDecoder decodeObjectForKey:@"width"] intValue];
        if([aDecoder decodeObjectForKey:@"layerName"])
            m_strName = [aDecoder decodeObjectForKey:@"layerName"];
        if([aDecoder decodeObjectForKey:@"opacity"])
            m_nOpacity = [[aDecoder decodeObjectForKey:@"opacity"] intValue];
        if([aDecoder decodeObjectForKey:@"offsetX"])
            m_nXoff = [[aDecoder decodeObjectForKey:@"offsetX"] intValue];
        if([aDecoder decodeObjectForKey:@"offsetY"])
            m_nYoff = [[aDecoder decodeObjectForKey:@"offsetY"] intValue];
        if([aDecoder decodeObjectForKey:@"visible"])
            m_bVisible = [[aDecoder decodeObjectForKey:@"visible"] boolValue];
        if([aDecoder decodeObjectForKey:@"lock"])
            m_bLockd = [[aDecoder decodeObjectForKey:@"lock"] boolValue];
        if([aDecoder decodeObjectForKey:@"link"])
            m_bLinked = [[aDecoder decodeObjectForKey:@"link"] boolValue];
        if([aDecoder decodeObjectForKey:@"floating"])
            m_bFloating = [[aDecoder decodeObjectForKey:@"floating"] boolValue];
    }
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

- (BOOL)isEmpty
{
    if(m_nWidth && m_nHeight)
        return NO;
    
    return YES;
}

- (void)shutdown
{
    
}

- (int)width
{
    return m_nWidth;
}

- (int)height
{
    return m_nHeight;
}

- (int)xoff
{
    return m_nXoff;
}

- (int)yoff
{
    return m_nYoff;
}

- (IntRect)localRect
{
    return IntMakeRect(m_nXoff, m_nYoff, m_nWidth, m_nHeight);
}


- (PA_LAYER_FORMAT)layerFormat
{
    return m_enumLayerFormat;
}

- (int)versionMajor
{
    return m_nVersionMajor;
}

- (int)versionMinor
{
    return m_nVersionMinor;
}

- (id)document
{
    return m_idDocument;
}



- (void)render:(CGContextRef)context viewRect:(NSRect)viewRect
{
    
}

- (void)renderToContext:(RENDER_CONTEXT_INFO)info
{
    
}

- (void)setFullRenderState:(BOOL)canBegin
{
    [m_pLayerRender setFullRenderState:canBegin];
}


- (BOOL)isRenderCompleted:(BOOL)isFull
{
    if (m_nWidth <= 1 || m_nHeight <= 1) {
        return YES;
    }
    return [m_pLayerRender isRenderCompleted:isFull];
}

-(PSSmartFilterManager *)getSmartFilterManager
{
    
    return m_pSmartFilterManager;
}

- (BOOL)effectFilterIsValid
{
    int filterIndex = [m_pSmartFilterManager getSmartFiltersCount] - 2;
    FILTER_PARAMETER_INFO paraInfo = [m_pSmartFilterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [m_pSmartFilterManager getSmartFilterParameterInfo:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    
    return NO;
}


- (int)selectedChannelOfLayer
{
    return kAllChannels;
}



- (PS_EDIT_CHANNEL_TYPE)editedChannelOfLayer
{
    return kEditAllChannels;
}

#pragma mark - Menu
- (BOOL)validateMenuItem:(id)menuItem
{
    return YES;
}

@end
