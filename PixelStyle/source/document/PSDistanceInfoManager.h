//
//  PSDistanceInfoManager.h
//  PixelStyle
//
//  Created by lchzh on 7/12/15.
//
//

#import <Foundation/Foundation.h>

#define MAX_DISTANCE_RADIUS 200

typedef struct
{
    CGSize fullSize;
    int spp;
    
    unsigned char *dirtyData;
    CGRect dirtyRect;
    CGRect validRect;
    
    //int extendInfo;
    int *state;
    float *dstDis;
    
}INPUT_DISTANCE_INFO;



@interface PSDistanceInfoManager : NSObject
{
    unsigned char *m_pSrcMaskData; //单通道
    CGSize m_fullSize;
    float *m_pSrcDistanceData; //有正负
    
    NSLock *m_lockDistInfo;
    
    BOOL m_bIsReady;
}

- (void)computeDistanceFastWithImage:(unsigned char*)srcData srcDistance:(float*)srcDis originx:(int)originx originy:(int)originy width:(int)width height:(int)height srcWidth:(int)srcWidth srcHeight:(int)srcHeight spp:(int)spp radius:(float)radius distanceDes:(float*)distData extendInfo:(int)extendInfo effectState:(int*)effectState;

- (void)computeDistanceFastWithDataInfo:(INPUT_DISTANCE_INFO)inputInfo;

- (void)computeDistanceSimpleWithImage:(unsigned char*)srcData width:(int)width height:(int)height spp:(int)spp radius:(float)radius distanceDes:(float*)distData extendInfo:(int)extendInfo effectState:(int*)effectState;

@end
