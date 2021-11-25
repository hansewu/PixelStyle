//
//  PSLayerEffect.m
//  PixelStyle
//
//  Created by lchzh on 6/9/15.
//
//

#import "PSLayerEffect.h"

#include "PSvxldt.h"
#import "GPUImageEffectFilter.h"

#import "PSLayer.h"
#import "UtilitiesManager.h"
#import "PSController.h"
#import "PegasusUtility.h"

#import "PSSecureImageData.h"

#import "PSSmartFilterManager.h"

#define STROKE_SIZE 10
#define OUTERGLOW_SIZE 30
#define kNumberOfUndoRecordsPerMalloc 50

@implementation PSLayerEffect

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInt:m_nEffectNum] forKey:@"effectNum"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:m_bIsStrokeEnable] forKey:@"strokeEnable"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_strokeColor.one] forKey:@"strokeColorRed"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_strokeColor.two] forKey:@"strokeColorGreen"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_strokeColor.three] forKey:@"strokeColorBlue"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_strokeColorAlpha] forKey:@"strokeColorAlpha"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_strokePosition] forKey:@"strokePosition"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_strokeSize] forKey:@"strokeSize"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:m_bIsFillEnable] forKey:@"fillEnable"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_fillColor.one] forKey:@"fillColorRed"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_fillColor.two] forKey:@"fillColorGreen"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_fillColor.three] forKey:@"fillColorBlue"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_fillColorAlpha] forKey:@"fillColorAlpha"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:m_bIsOuterGlowEnable] forKey:@"outerGlowEnable"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_outerGlowColor.one] forKey:@"outerGlowColorRed"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_outerGlowColor.two] forKey:@"outerGlowColorGreen"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_outerGlowColor.three] forKey:@"outerGlowColorBlue"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_outerGlowColorAlpha] forKey:@"outerGlowColorAlpha"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_outerGlowSize] forKey:@"outerGlowSize"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:m_bIsInnerGlowEnable] forKey:@"innerGlowEnable"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_innerGlowColor.one] forKey:@"innerGlowColorRed"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_innerGlowColor.two] forKey:@"innerGlowColorGreen"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_innerGlowColor.three] forKey:@"innerGlowColorBlue"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_innerGlowColorAlpha] forKey:@"innerGlowColorAlpha"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_innerGlowSize] forKey:@"innerGlowSize"];
    
    [aCoder encodeObject:[NSNumber numberWithBool:m_bLayerShadowEnable] forKey:@"layerShadowEnable"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_sLayerShadow.offset.width] forKey:@"layerShadowOffsetX"];
    [aCoder encodeObject:[NSNumber numberWithInt:m_sLayerShadow.offset.height] forKey:@"layerShadowOffsetY"];
    [aCoder encodeObject:[NSNumber numberWithFloat:m_sLayerShadow.fBlur] forKey:@"layerShadowBlur"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedChar:m_sLayerShadow.color[0]] forKey:@"layerShadowColor0"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedChar:m_sLayerShadow.color[1]] forKey:@"layerShadowColor1"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedChar:m_sLayerShadow.color[2]] forKey:@"layerShadowColor2"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedChar:m_sLayerShadow.color[3]] forKey:@"layerShadowColor3"];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    
    m_nEffectNum = [[aDecoder decodeObjectForKey:@"effectNum"] intValue];
    
    m_bIsStrokeEnable = [[aDecoder decodeObjectForKey:@"strokeEnable"] boolValue];
    m_strokeColor.one = [[aDecoder decodeObjectForKey:@"strokeColorRed"] floatValue];
    m_strokeColor.two = [[aDecoder decodeObjectForKey:@"strokeColorGreen"] floatValue];
    m_strokeColor.three = [[aDecoder decodeObjectForKey:@"strokeColorBlue"] floatValue];
    m_strokeColorAlpha = [[aDecoder decodeObjectForKey:@"strokeColorAlpha"] floatValue];
    m_strokeSize = [[aDecoder decodeObjectForKey:@"strokeSize"] floatValue];
    m_strokePosition = [[aDecoder decodeObjectForKey:@"strokePosition"] intValue];
    
    m_bIsFillEnable = [[aDecoder decodeObjectForKey:@"fillEnable"] boolValue];
    m_fillColor.one = [[aDecoder decodeObjectForKey:@"fillColorRed"] floatValue];
    m_fillColor.two = [[aDecoder decodeObjectForKey:@"fillColorGreen"] floatValue];
    m_fillColor.three = [[aDecoder decodeObjectForKey:@"fillColorBlue"] floatValue];
    m_fillColorAlpha = [[aDecoder decodeObjectForKey:@"fillColorAlpha"] floatValue];
    
    m_bIsOuterGlowEnable = [[aDecoder decodeObjectForKey:@"outerGlowEnable"] boolValue];
    m_outerGlowColor.one = [[aDecoder decodeObjectForKey:@"outerGlowColorRed"] floatValue];
    m_outerGlowColor.two = [[aDecoder decodeObjectForKey:@"outerGlowColorGreen"] floatValue];
    m_outerGlowColor.three = [[aDecoder decodeObjectForKey:@"outerGlowColorBlue"] floatValue];
    m_outerGlowColorAlpha = [[aDecoder decodeObjectForKey:@"outerGlowColorAlpha"] floatValue];
    m_outerGlowSize = [[aDecoder decodeObjectForKey:@"outerGlowSize"] floatValue];
    
    m_bIsInnerGlowEnable = [[aDecoder decodeObjectForKey:@"innerGlowEnable"] boolValue];
    m_innerGlowColor.one = [[aDecoder decodeObjectForKey:@"innerGlowColorRed"] floatValue];
    m_innerGlowColor.two = [[aDecoder decodeObjectForKey:@"innerGlowColorGreen"] floatValue];
    m_innerGlowColor.three = [[aDecoder decodeObjectForKey:@"innerGlowColorBlue"] floatValue];
    m_innerGlowColorAlpha = [[aDecoder decodeObjectForKey:@"innerGlowColorAlpha"] floatValue];
    m_innerGlowSize = [[aDecoder decodeObjectForKey:@"innerGlowSize"] floatValue];
    
    m_bLayerShadowEnable = [[aDecoder decodeObjectForKey:@"layerShadowEnable"] boolValue];
    m_sLayerShadow.offset.width = [[aDecoder decodeObjectForKey:@"layerShadowOffsetX"] intValue];
    m_sLayerShadow.offset.height = [[aDecoder decodeObjectForKey:@"layerShadowOffsetY"] intValue];
    m_sLayerShadow.fBlur = [[aDecoder decodeObjectForKey:@"layerShadowBlur"] floatValue];
    m_sLayerShadow.color[0] = [[aDecoder decodeObjectForKey:@"layerShadowColor0"] unsignedCharValue];
    m_sLayerShadow.color[1] = [[aDecoder decodeObjectForKey:@"layerShadowColor1"] unsignedCharValue];
    m_sLayerShadow.color[2] = [[aDecoder decodeObjectForKey:@"layerShadowColor2"] unsignedCharValue];
    m_sLayerShadow.color[3] = [[aDecoder decodeObjectForKey:@"layerShadowColor3"] unsignedCharValue];
    
    return self;
}

- (id)initWithDocument:(id)doc forLayer:(id)ilayer
{
    [self init];
    m_idDocument = doc;
    m_idLayer = ilayer;
    return self;    
}

- (id)initWithDelegate:(id)delegate
{
    [self init];
    m_idDelegateForEffect = delegate;
    return self;
}

- (void)setDelegateForEffect:(id)delegate
{
    m_idDelegateForEffect = delegate;
}

- (id)init
{
    self = [super init];
    
    
    
    m_undoRecords = NULL;
    m_undoRecordsCount = 0;
    m_undoRecordsMaxLen = 0;
    
    
    //m_sLayerShadow.offset = IntMakeSize(10, 10);
    m_sLayerShadow.fBlur = 0;
    m_sLayerShadow.color[0] = 255;
    m_sLayerShadow.color[1] = 0;
    m_sLayerShadow.color[2] = 0;
    m_sLayerShadow.color[3] = 255;
    m_bLayerShadowEnable = NO;

    
    m_nEffectNum = 4;
    
    m_bIsStrokeEnable = 0;
    m_strokeSize = STROKE_SIZE;
    m_strokePosition = 0;
    m_strokeColor = makeGPUVector3(1.0, 0.0, 0.0);
    m_strokeColorAlpha = 1.0;
    m_effectFilter.strokeEnable = m_bIsStrokeEnable;
    m_effectFilter.strokeSize = m_strokeSize;
    m_effectFilter.strokePosition = m_strokePosition;
    m_effectFilter.strokeColor = m_strokeColor;
    m_effectFilter.strokeColorAlpha = m_strokeColorAlpha;
    
    m_bIsFillEnable = 0;
    m_fillColor = makeGPUVector3(0.0, 1.0, 0.0);
    m_fillColorAlpha = 1.0;
    m_effectFilter.fillEnable = m_bIsFillEnable;
    m_effectFilter.fillColor = m_fillColor;
    m_effectFilter.fillColorAlpha = m_fillColorAlpha;
    
    m_bIsOuterGlowEnable = 0;
    m_outerGlowColor = makeGPUVector3(1.0, 1.0, 0.0);
    m_outerGlowColorAlpha = 1.0;
    m_outerGlowSize = OUTERGLOW_SIZE;
    m_effectFilter.outerGlowEnable = m_bIsOuterGlowEnable;
    m_effectFilter.outerGlowColor = m_outerGlowColor;
    m_effectFilter.outerGlowColorAlpha = m_outerGlowColorAlpha;
    m_effectFilter.outerGlowSize = m_outerGlowSize;
    
    m_bIsInnerGlowEnable = 0;
    m_innerGlowColor = makeGPUVector3(1.0, 1.0, 0.0);
    m_innerGlowColorAlpha = 1.0;
    m_innerGlowSize = OUTERGLOW_SIZE;
    m_effectFilter.innerGlowEnable = m_bIsInnerGlowEnable;
    m_effectFilter.innerGlowColor = m_innerGlowColor;
    m_effectFilter.innerGlowColorAlpha = m_innerGlowColorAlpha;
    m_effectFilter.innerGlowSize = m_innerGlowSize;
    
    m_bLayerShadowEnable = 0;
    m_sLayerShadow.color[0] = 0;
    m_sLayerShadow.color[1] = 0;
    m_sLayerShadow.color[2] = 0;
    m_sLayerShadow.color[3] = 200;
    m_sLayerShadow.fBlur = 5.0;
    m_sLayerShadow.offset.width = 10;
    m_sLayerShadow.offset.height = 10;
    
//    m_effectFilter.redVisible = 1;
//    m_effectFilter.greenVisible = 1;
//    m_effectFilter.blueVisible = 1;
//    m_effectFilter.alphaVisible = 1;
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


#pragma mark - set effect parameters

- (void)setStrokeEnable:(BOOL)enable
{
    m_bIsStrokeEnable = enable;
    
//    PSSmartFilterManager *filterManager = [(PSLayer*)m_idLayer ];
//    COMMON_FILTER_INFO filterInfo = [filterManager getsm
    m_effectFilter.strokeEnable = (int)m_bIsStrokeEnable;
    if (enable) {
        [m_idLayer setLayerEffectEnable:YES];
    }
}
- (void)setStrokeColorRed:(float)red green:(float)green blue:(float)blue
{
    m_strokeColor = makeGPUVector3(red, green, blue);
    m_effectFilter.strokeColor = m_strokeColor;
}
- (void)setStrokePositon:(int)nPosition
{
    m_strokePosition = nPosition;
    m_effectFilter.strokePosition = m_strokePosition;
}
- (void)setStrokeColorAlpha:(float)alpha
{
    m_strokeColorAlpha = alpha;
    m_effectFilter.strokeColorAlpha = alpha;
}
- (void)setStrokeSize:(float)size
{
    m_strokeSize = size;
    m_effectFilter.strokeSize = m_strokeSize;
}

- (void)setFillEnable:(BOOL)enable
{
    m_bIsFillEnable = enable;
    m_effectFilter.fillEnable = (int)m_bIsFillEnable;
    if (enable) {
        [m_idLayer setLayerEffectEnable:YES];
    }
}
- (void)setFillColorRed:(float)red green:(float)green blue:(float)blue
{
    m_fillColor = makeGPUVector3(red, green, blue);
    m_effectFilter.fillColor = m_fillColor;
}
- (void)setFillColorAlpha:(float)alpha
{
    m_fillColorAlpha = alpha;
    m_effectFilter.fillColorAlpha = alpha;
}


- (void)setOuterGlowEnable:(BOOL)enable
{
    m_bIsOuterGlowEnable = enable;
    m_effectFilter.outerGlowEnable = (int)m_bIsOuterGlowEnable;
    if (enable) {
        [m_idLayer setLayerEffectEnable:YES];
    }
}
- (void)setOuterGlowColorRed:(float)red green:(float)green blue:(float)blue
{
    m_outerGlowColor = makeGPUVector3(red, green, blue);
    m_effectFilter.outerGlowColor = m_outerGlowColor;
}
- (void)setOuterGlowColorAlpha:(float)alpha
{
    m_outerGlowColorAlpha = alpha;
    m_effectFilter.outerGlowColorAlpha = m_outerGlowColorAlpha;
}
- (void)setOuterGlowSize:(float)size
{
    m_outerGlowSize = size;
    m_effectFilter.outerGlowSize = m_outerGlowSize;
}

- (void)setInnerGlowEnable:(BOOL)enable
{
    m_bIsInnerGlowEnable = enable;
    m_effectFilter.innerGlowEnable = (int)m_bIsInnerGlowEnable;
    if (enable) {
        [m_idLayer setLayerEffectEnable:YES];
    }
}
- (void)setInnerGlowColorRed:(float)red green:(float)green blue:(float)blue
{
    m_innerGlowColor = makeGPUVector3(red, green, blue);
    m_effectFilter.innerGlowColor = m_innerGlowColor;
}
- (void)setInnerGlowColorAlpha:(float)alpha
{
    m_innerGlowColorAlpha = alpha;
    m_effectFilter.innerGlowColorAlpha = m_innerGlowColorAlpha;
}
- (void)setInnerGlowSize:(float)size
{
    m_innerGlowSize = size;
    m_effectFilter.innerGlowSize = m_innerGlowSize;
}


- (void)setShadowEnable:(BOOL)enable
{
    m_bLayerShadowEnable = enable;
}

-(void)setShadow:(LAYER_SHADOW)sShadow
{
    m_sLayerShadow = sShadow;
}

#pragma mark - get effect parameters

- (BOOL)strokeIsEnable
{
    return m_bIsStrokeEnable;
}
- (GPUVector3)getStrokeColor
{
    return m_strokeColor;
}
- (int)getStrokePositon
{
    return m_strokePosition;
}
- (float)getStrokeColorAlpha
{
    return m_strokeColorAlpha;
}
- (float)getStrokeSize
{
    return m_strokeSize;
}

- (BOOL)fillIsEnable
{
    return m_bIsFillEnable;
}
- (GPUVector3)getFillColor
{
    return m_fillColor;
}
- (float)getFillColorAlpha
{
    return m_fillColorAlpha;
}


- (BOOL)outerGlowIsEnable
{
    return m_bIsOuterGlowEnable;
}
- (GPUVector3)getOuterGlowColor
{
    return m_outerGlowColor;
}
- (float)getOuterGlowColorAlpha
{
    return m_outerGlowColorAlpha;
}
- (float)getOuterGlowSize
{
    return m_outerGlowSize;
}

- (BOOL)innerGlowIsEnable
{
    return m_bIsInnerGlowEnable;
}
- (GPUVector3)getInnerGlowColor
{
    return m_innerGlowColor;
}
- (float)getInnerGlowColorAlpha
{
    return m_innerGlowColorAlpha;
}
- (float)getInnerGlowSize
{
    return m_innerGlowSize;
}

- (BOOL)shadowIsEnable
{
    return m_bLayerShadowEnable;
}
-(LAYER_SHADOW)getShadow
{
    return m_sLayerShadow;
}

- (BOOL)getEffectFilterIsEnable
{
    return m_bIsStrokeEnable || m_bIsFillEnable || m_bIsOuterGlowEnable || m_bIsInnerGlowEnable;
}

#pragma mark - distance, make effect

- (void)setChannelRedVisible:(BOOL)rvisible GreenVisible:(BOOL)gvisible BlueVisible:(BOOL)bvisible AlphaVisible:(BOOL)avisible
{
//    m_effectFilter.redVisible = (int)rvisible;
//    m_effectFilter.greenVisible = (int)gvisible;
//    m_effectFilter.blueVisible = (int)bvisible;
//    m_effectFilter.alphaVisible = (int)avisible;
}


//- (NSRect)getNeededRectForDistanceOfRect:(NSRect)srcRect
//{
//    NSRect desRect = srcRect;
//    desRect.origin.x -= MAX_DISTANCE_RADIUS * 2;
//    desRect.origin.y -= MAX_DISTANCE_RADIUS * 2;
//    desRect.size.width += MAX_DISTANCE_RADIUS * 4;
//    desRect.size.height += MAX_DISTANCE_RADIUS * 4;
//    
//    NSLog(@"srcRect %@",NSStringFromRect(srcRect));
//    NSLog(@"desRect %@",NSStringFromRect(desRect));
//    return desRect;
//}


- (NSRect)getNeededRectForDistanceOfRect:(NSRect)srcRect
{
    NSRect desRect = srcRect;
    desRect.origin.x -= MAX_DISTANCE_RADIUS * 1 + 1;
    desRect.origin.y -= MAX_DISTANCE_RADIUS * 1 + 1;
    desRect.size.width += MAX_DISTANCE_RADIUS * 2 + 2;
    desRect.size.height += MAX_DISTANCE_RADIUS * 2 + 2;
    
    NSLog(@"srcRect %@",NSStringFromRect(srcRect));
    NSLog(@"desRect %@",NSStringFromRect(desRect));
    return desRect;
}

- (NSRect)getEffectedRectForDistanceOfRect:(NSRect)srcRect
{
    NSRect desRect = srcRect;
    desRect.origin.x -= MAX_DISTANCE_RADIUS;
    desRect.origin.y -= MAX_DISTANCE_RADIUS;
    desRect.size.width += MAX_DISTANCE_RADIUS * 2;
    desRect.size.height += MAX_DISTANCE_RADIUS * 2;
    return desRect;
}


- (NSRect)getNeededRectForEffectOfRect:(NSRect)srcRect
{
    NSRect desRect = srcRect;
    CGFloat minx = srcRect.origin.x;
    CGFloat maxx = srcRect.origin.x + srcRect.size.width;
    CGFloat miny = srcRect.origin.y;
    CGFloat maxy = srcRect.origin.y + srcRect.size.height;
    
    for (int i = 0; i < m_nEffectNum; i++) {
        NSRect temp = [self getNeededRectForEffect:i OfRect:srcRect];
        if (temp.origin.x < minx) {
            minx = temp.origin.x;
        }
        if (temp.origin.x + temp.size.width > maxx) {
            maxx = temp.origin.x + temp.size.width;
        }
        if (temp.origin.y < miny) {
            miny = temp.origin.y;
        }
        if (temp.origin.y + temp.size.height > maxy) {
            maxy = temp.origin.y + temp.size.height;
        }
    }
    
    desRect = NSMakeRect(minx, miny, maxx - minx, maxy - miny);
    
    return desRect;
}


- (NSRect)getNeededRectForEffect:(int)effectIndex OfRect:(NSRect)srcRect
{
    NSRect desRect = srcRect;
    switch (effectIndex) {
        case 0:{
            if (m_bIsStrokeEnable) {
                float extend = m_strokeSize + 2;
                desRect.origin.x -= extend;
                desRect.origin.y -= extend;
                desRect.size.width += extend * 2;
                desRect.size.height += extend * 2;
            }
            break;
        }
        case 1:{ //fill
            break;
        }
        case 2:{
            if (m_bIsOuterGlowEnable) {
                float extend = m_outerGlowSize + 2;
                desRect.origin.x -= extend;
                desRect.origin.y -= extend;
                desRect.size.width += extend * 2;
                desRect.size.height += extend * 2;
            }
            break;
        }
            
        default:
            break;
    }
    
    return desRect;
}

- (NSRect)getEffectedRectForEffectOfRect:(NSRect)srcRect
{
    NSRect desRect = srcRect;
    CGFloat minx = srcRect.origin.x;
    CGFloat maxx = srcRect.origin.x + srcRect.size.width;
    CGFloat miny = srcRect.origin.y;
    CGFloat maxy = srcRect.origin.y + srcRect.size.height;
    
    for (int i = 0; i < m_nEffectNum; i++) {
        NSRect temp = [self getEffectedRectForEffect:i OfRect:srcRect];
        if (temp.origin.x < minx) {
            minx = temp.origin.x;
        }
        if (temp.origin.x + temp.size.width > maxx) {
            maxx = temp.origin.x + temp.size.width;
        }
        if (temp.origin.y < miny) {
            miny = temp.origin.y;
        }
        if (temp.origin.y + temp.size.height > maxy) {
            maxy = temp.origin.y + temp.size.height;
        }
    }
    
    desRect = NSMakeRect(minx, miny, maxx - minx, maxy - miny);
    
    return desRect;
}

- (NSRect)getEffectedRectForEffect:(int)effectIndex OfRect:(NSRect)srcRect
{
    NSRect desRect = srcRect;
    switch (effectIndex) {
        case 0:{
            if (m_bIsStrokeEnable) {
                float extend = m_strokeSize + 1;
                desRect.origin.x -= extend;
                desRect.origin.y -= extend;
                desRect.size.width += extend * 2;
                desRect.size.height += extend * 2;
            }
            break;
        }
        case 1:{ //fill
            break;
        }
        case 2:{
            if (m_bIsOuterGlowEnable) {
                float extend = m_outerGlowSize + 1;
                desRect.origin.x -= extend;
                desRect.origin.y -= extend;
                desRect.size.width += extend * 2;
                desRect.size.height += extend * 2;
            }
            break;
        }
            
        default:
            break;
    }
    return desRect;
}



- (void)computeDistanceForImage:(unsigned char*)srcData width:(int)width height:(int)height spp:(int)spp radius:(float)radius distanceDes:(float*)distData
{
    NSTimeInterval beigin = [NSDate timeIntervalSinceReferenceDate];
    vil_computeDistance(srcData, width, height, spp, radius, distData);
    NSLog(@"computeDistance time : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
}

- (void)computeDistanceFastWithImage:(unsigned char*)srcData srcDistance:(float*)srcDis originx:(int)originx originy:(int)originy width:(int)width height:(int)height  srcWidth:(int)srcWidth srcHeight:(int)srcHeight spp:(int)spp radius:(float)radius distanceDes:(float*)distData extendInfo:(int)extendInfo effectState:(int*)effectState
{
    NSTimeInterval beigin = [NSDate timeIntervalSinceReferenceDate];
    vil_computeDistanceFast(srcData, srcDis, originx, originy, width, height, srcWidth, srcHeight, spp, radius, distData, extendInfo, effectState);
    NSLog(@"computeDistance time : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
}



- (unsigned char*)getEffectResultForImage:(unsigned char*)srcData width:(int)width height:(int)height spp:(int)spp distanceInfo:(float*)distData effectState:(int*)effectState scale:(float)scale
{
    //NSTimeInterval beigin = [NSDate timeIntervalSinceReferenceDate];
    
//    m_effectFilter.texelWidth = 1.0 / (float)width;
//    m_effectFilter.texelHeight = 1.0 / (float)height;
    
    GPUImageRawDataInput *imageInput = [[GPUImageRawDataInput alloc] initWithBytes:srcData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
    //NSLog(@"effect time2 : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
    
    if (effectState && *effectState == 0) {
        [imageInput release];
        return NULL;
    }
    unsigned char* udistData = (unsigned char*)distData;
    GPUImageRawDataInput *distanceInput = NULL;
    if (distData) {
        distanceInput = [[GPUImageRawDataInput alloc] initWithBytes:udistData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatLuminance type:GPUPixelTypeFloat];
    }else{
        distanceInput = [[GPUImageRawDataInput alloc] initWithBytes:udistData size:CGSizeMake(0, 0) pixelFormat:GPUPixelFormatLuminance type:GPUPixelTypeFloat];
    }
    if (effectState && *effectState == 0) {
        [imageInput release];
        if (distanceInput) {
            [distanceInput release];
        }
        return NULL;
    }
    [m_effectFilter setDistanceScale:scale];
    GPUImageRawDataOutput *resultOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:NO];
    [imageInput addTarget:m_effectFilter];
    [imageInput processData];
    [distanceInput addTarget:m_effectFilter];
    [distanceInput processData];
    [m_effectFilter addTarget:resultOut];
    unsigned char* resultData = [resultOut rawBytesForImage];
    
    [imageInput removeTarget:m_effectFilter];
    if (distanceInput) {
        [distanceInput removeTarget:m_effectFilter];
    }
    [m_effectFilter removeTarget:resultOut];
    
    [imageInput release];
    if (distanceInput) {
        [distanceInput release];
    }
    
    //NSLog(@"effect time4 : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
        
    return resultData;
    
}


#pragma mark - message from ui

-(void)refreshEffect
{
    m_bHasRefresh = YES;
    [m_idLayer refreshLayerEffect:NO];
}


-(void)effectEventWillBegin
{
    m_oldRecords.effectNum = m_nEffectNum;
    m_oldRecords.strokeEnable = m_bIsStrokeEnable;
    m_oldRecords.strokeColor = m_strokeColor;
    m_oldRecords.strokeColorAlpha = m_strokeColorAlpha;
    m_oldRecords.strokePosition = m_strokePosition;
    m_oldRecords.fillEnable = m_bIsFillEnable;
    m_oldRecords.fillColor = m_fillColor;
    m_oldRecords.fillColorAlpha = m_fillColorAlpha;
    m_oldRecords.outerGlowEnable = m_bIsOuterGlowEnable;
    m_oldRecords.outerGlowColor = m_outerGlowColor;
    m_oldRecords.outerGlowColorAlpha = m_outerGlowColorAlpha;
    m_oldRecords.outerGlowSize = m_outerGlowSize;
    m_oldRecords.innerGlowEnable = m_bIsInnerGlowEnable;
    m_oldRecords.innerGlowColor = m_innerGlowColor;
    m_oldRecords.innerGlowColorAlpha = m_innerGlowColorAlpha;
    m_oldRecords.innerGlowSize = m_innerGlowSize;
    m_oldRecords.shadowEnable = m_bLayerShadowEnable;
    m_oldRecords.shadow = m_sLayerShadow;
    
    m_bHasRefresh = NO;
}

-(void)cancelEffectEvent
{
    m_nEffectNum = m_oldRecords.effectNum;
    m_bIsStrokeEnable = m_oldRecords.strokeEnable;
    m_strokeColor = m_oldRecords.strokeColor;
    m_strokeColorAlpha = m_oldRecords.strokeColorAlpha;
    m_strokePosition = m_oldRecords.strokePosition;
    m_bIsFillEnable = m_oldRecords.fillEnable;
    m_fillColor = m_oldRecords.fillColor;
    m_fillColorAlpha = m_oldRecords.fillColorAlpha;
    m_bIsOuterGlowEnable = m_oldRecords.outerGlowEnable;
    m_outerGlowColor = m_oldRecords.outerGlowColor;
    m_outerGlowColorAlpha = m_oldRecords.outerGlowColorAlpha;
    m_outerGlowSize = m_oldRecords.outerGlowSize;
    m_bIsInnerGlowEnable = m_oldRecords.innerGlowEnable;
    m_innerGlowColor = m_oldRecords.innerGlowColor;
    m_innerGlowColorAlpha = m_oldRecords.innerGlowColorAlpha;
    m_innerGlowSize = m_oldRecords.innerGlowSize;
    m_bLayerShadowEnable = m_oldRecords.shadowEnable;
    m_sLayerShadow = m_oldRecords.shadow;
    
    m_effectFilter.strokeEnable = m_bIsStrokeEnable;
    m_effectFilter.strokeSize = m_strokeSize;
    m_effectFilter.strokePosition = m_strokePosition;
    m_effectFilter.strokeColor = m_strokeColor;
    m_effectFilter.strokeColorAlpha = m_strokeColorAlpha;
    
    m_effectFilter.fillEnable = m_bIsFillEnable;
    m_effectFilter.fillColor = m_fillColor;
    m_effectFilter.fillColorAlpha = m_fillColorAlpha;
    
    
    m_effectFilter.outerGlowEnable = m_bIsOuterGlowEnable;
    m_effectFilter.outerGlowColor = m_outerGlowColor;
    m_effectFilter.outerGlowColorAlpha = m_outerGlowColorAlpha;
    m_effectFilter.outerGlowSize = m_outerGlowSize;
    
    
    m_effectFilter.innerGlowEnable = m_bIsInnerGlowEnable;
    m_effectFilter.innerGlowColor = m_innerGlowColor;
    m_effectFilter.innerGlowColorAlpha = m_innerGlowColorAlpha;
    m_effectFilter.innerGlowSize = m_innerGlowSize;
    
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:0];
    
    if (m_bIsStrokeEnable || m_bIsFillEnable || m_bIsOuterGlowEnable || m_bIsInnerGlowEnable)
    {
        [m_idLayer setLayerEffectEnable:YES];
    }
    
    if (m_bHasRefresh) {
        [self refreshEffect];
    }
    
}

-(void)okEffectEvent
{
    if (m_bHasRefresh) {
        [self makeUndoRecord];
    }
    m_bHasRefresh = NO;
}

#pragma mark - undo,redo

- (void)undoEffectForRecord:(int)index
{
    UndoRecordForEffect oldRecord;  // = m_undoRecords[index]; //can be direct
    oldRecord.effectNum = m_undoRecords[index].effectNum;
    oldRecord.strokeEnable = m_undoRecords[index].strokeEnable;
    oldRecord.strokeColor = m_undoRecords[index].strokeColor;
    oldRecord.strokeColorAlpha = m_undoRecords[index].strokeColorAlpha;
    oldRecord.strokePosition = m_undoRecords[index].strokePosition;
    oldRecord.fillEnable = m_undoRecords[index].fillEnable;
    oldRecord.fillColor = m_undoRecords[index].fillColor;
    oldRecord.fillColorAlpha = m_undoRecords[index].fillColorAlpha;
    oldRecord.outerGlowEnable = m_undoRecords[index].outerGlowEnable;
    oldRecord.outerGlowColor = m_undoRecords[index].outerGlowColor;
    oldRecord.outerGlowColorAlpha = m_undoRecords[index].outerGlowColorAlpha;
    oldRecord.outerGlowSize = m_undoRecords[index].outerGlowSize;
    oldRecord.innerGlowEnable = m_undoRecords[index].innerGlowEnable;
    oldRecord.innerGlowColor = m_undoRecords[index].innerGlowColor;
    oldRecord.innerGlowColorAlpha = m_undoRecords[index].innerGlowColorAlpha;
    oldRecord.innerGlowSize = m_undoRecords[index].innerGlowSize;
    oldRecord.shadowEnable = m_undoRecords[index].shadowEnable;
    oldRecord.shadow = m_undoRecords[index].shadow;
    
    
    m_undoRecords[index].effectNum = m_nEffectNum;
    m_undoRecords[index].strokeEnable = m_bIsStrokeEnable;
    m_undoRecords[index].strokeColor = m_strokeColor;
    m_undoRecords[index].strokeColorAlpha = m_strokeColorAlpha;
    m_undoRecords[index].strokePosition = m_strokePosition;
    m_undoRecords[index].fillEnable = m_bIsFillEnable;
    m_undoRecords[index].fillColor = m_fillColor;
    m_undoRecords[index].fillColorAlpha = m_fillColorAlpha;
    m_undoRecords[index].outerGlowEnable = m_bIsOuterGlowEnable;
    m_undoRecords[index].outerGlowColor = m_outerGlowColor;
    m_undoRecords[index].outerGlowColorAlpha = m_outerGlowColorAlpha;
    m_undoRecords[index].outerGlowSize = m_outerGlowSize;
    m_undoRecords[index].innerGlowEnable = m_bIsInnerGlowEnable;
    m_undoRecords[index].innerGlowColor = m_innerGlowColor;
    m_undoRecords[index].innerGlowColorAlpha = m_innerGlowColorAlpha;
    m_undoRecords[index].innerGlowSize = m_innerGlowSize;
    m_undoRecords[index].shadowEnable = m_bLayerShadowEnable;
    m_undoRecords[index].shadow = m_sLayerShadow;
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoEffectForRecord:index];
    
    m_nEffectNum = oldRecord.effectNum;
    m_bIsStrokeEnable = oldRecord.strokeEnable;
    m_strokeColor = oldRecord.strokeColor;
    m_strokeColorAlpha = oldRecord.strokeColorAlpha;
    m_strokePosition = oldRecord.strokePosition;
    m_bIsFillEnable = oldRecord.fillEnable;
    m_fillColor = oldRecord.fillColor;
    m_fillColorAlpha = oldRecord.fillColorAlpha;
    m_bIsOuterGlowEnable = oldRecord.outerGlowEnable;
    m_outerGlowColor = oldRecord.outerGlowColor;
    m_outerGlowColorAlpha = oldRecord.outerGlowColorAlpha;
    m_outerGlowSize = oldRecord.outerGlowSize;
    m_bIsInnerGlowEnable = oldRecord.innerGlowEnable;
    m_innerGlowColor = oldRecord.innerGlowColor;
    m_innerGlowColorAlpha = oldRecord.innerGlowColorAlpha;
    m_innerGlowSize = oldRecord.innerGlowSize;
    m_bLayerShadowEnable = oldRecord.shadowEnable;
    m_sLayerShadow = oldRecord.shadow;
    
    m_effectFilter.strokeEnable = m_bIsStrokeEnable;
    m_effectFilter.strokeSize = m_strokeSize;
    m_effectFilter.strokePosition = m_strokePosition;
    m_effectFilter.strokeColor = m_strokeColor;
    m_effectFilter.strokeColorAlpha = m_strokeColorAlpha;
    
    m_effectFilter.fillEnable = m_bIsFillEnable;
    m_effectFilter.fillColor = m_fillColor;
    m_effectFilter.fillColorAlpha = m_fillColorAlpha;
    
    
    m_effectFilter.outerGlowEnable = m_bIsOuterGlowEnable;
    m_effectFilter.outerGlowColor = m_outerGlowColor;
    m_effectFilter.outerGlowColorAlpha = m_outerGlowColorAlpha;
    m_effectFilter.outerGlowSize = m_outerGlowSize;
    
    
    m_effectFilter.innerGlowEnable = m_bIsInnerGlowEnable;
    m_effectFilter.innerGlowColor = m_innerGlowColor;
    m_effectFilter.innerGlowColorAlpha = m_innerGlowColorAlpha;
    m_effectFilter.innerGlowSize = m_innerGlowSize;
    
    [(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:m_idDocument] update:0];
    
    if (m_bIsStrokeEnable || m_bIsFillEnable || m_bIsOuterGlowEnable || m_bIsInnerGlowEnable)
    {
        [m_idLayer setLayerEffectEnable:YES];
    }
    
    [self refreshEffect];
}

- (int)makeUndoRecord
{
    if (!m_undoRecords) {
        m_undoRecords = (UndoRecordForEffect*)malloc(kNumberOfUndoRecordsPerMalloc * sizeof(UndoRecordForEffect));
        m_undoRecordsMaxLen = kNumberOfUndoRecordsPerMalloc;
    }else{
        if (m_undoRecordsCount >= m_undoRecordsMaxLen) {
            m_undoRecordsMaxLen += kNumberOfUndoRecordsPerMalloc;
            m_undoRecords = (UndoRecordForEffect*)realloc(m_undoRecords, m_undoRecordsMaxLen * sizeof(UndoRecordForEffect));
        }
    }
    m_undoRecords[m_undoRecordsCount].effectNum = m_oldRecords.effectNum;
    m_undoRecords[m_undoRecordsCount].strokeEnable = m_oldRecords.strokeEnable;
    m_undoRecords[m_undoRecordsCount].strokeColor = m_oldRecords.strokeColor;
    m_undoRecords[m_undoRecordsCount].strokeColorAlpha = m_oldRecords.strokeColorAlpha;
    m_undoRecords[m_undoRecordsCount].strokePosition = m_oldRecords.strokePosition;
    m_undoRecords[m_undoRecordsCount].fillEnable = m_oldRecords.fillEnable;
    m_undoRecords[m_undoRecordsCount].fillColor = m_oldRecords.fillColor;
    m_undoRecords[m_undoRecordsCount].fillColorAlpha = m_oldRecords.fillColorAlpha;
    m_undoRecords[m_undoRecordsCount].outerGlowEnable = m_oldRecords.outerGlowEnable;
    m_undoRecords[m_undoRecordsCount].outerGlowColor = m_oldRecords.outerGlowColor;
    m_undoRecords[m_undoRecordsCount].outerGlowColorAlpha = m_oldRecords.outerGlowColorAlpha;
    m_undoRecords[m_undoRecordsCount].outerGlowSize = m_oldRecords.outerGlowSize;
    m_undoRecords[m_undoRecordsCount].innerGlowEnable = m_oldRecords.innerGlowEnable;
    m_undoRecords[m_undoRecordsCount].innerGlowColor = m_oldRecords.innerGlowColor;
    m_undoRecords[m_undoRecordsCount].innerGlowColorAlpha = m_oldRecords.innerGlowColorAlpha;
    m_undoRecords[m_undoRecordsCount].innerGlowSize = m_oldRecords.innerGlowSize;
    m_undoRecords[m_undoRecordsCount].shadowEnable = m_oldRecords.shadowEnable;
    m_undoRecords[m_undoRecordsCount].shadow = m_oldRecords.shadow;
    
    [[[m_idDocument undoManager] prepareWithInvocationTarget:self] undoEffectForRecord:m_undoRecordsCount];
    
    m_undoRecordsCount++;
    return m_undoRecordsCount - 1;
}


- (BOOL)getLayerEffectEnable
{
    return m_isLayerEffectEnable;
}

@end
