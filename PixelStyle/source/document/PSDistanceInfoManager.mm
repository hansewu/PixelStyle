//
//  PSDistanceInfoManager.m
//  PixelStyle
//
//  Created by lchzh on 7/12/15.
//
//

#import "PSDistanceInfoManager.h"
#include "PSvxldt.h"

@implementation PSDistanceInfoManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        m_pSrcMaskData = nil;
        m_pSrcDistanceData = nil;
        m_fullSize = CGSizeMake(0, 0);
    }
    return self;
}

- (void)dealloc
{
    [m_lockDistInfo lock];
    if (m_pSrcMaskData) {
        free(m_pSrcMaskData);
    }
    if (m_pSrcDistanceData) {
        free(m_pSrcDistanceData);
    }
    [m_lockDistInfo unlock];
    [m_lockDistInfo release];
    [super dealloc];
}

- (void)computeDistanceFastWithImage:(unsigned char*)srcData srcDistance:(float*)srcDis originx:(int)originx originy:(int)originy width:(int)width height:(int)height  srcWidth:(int)srcWidth srcHeight:(int)srcHeight spp:(int)spp radius:(float)radius distanceDes:(float*)distData extendInfo:(int)extendInfo effectState:(int*)effectState
{
    //NSTimeInterval beigin = [NSDate timeIntervalSinceReferenceDate];
    vil_computeDistanceFast(srcData, srcDis, originx, originy, width, height, srcWidth, srcHeight, spp, radius, distData, extendInfo, effectState);
    //NSLog(@"computeDistance time : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
}


- (void)computeDistanceSimpleWithImage:(unsigned char*)srcData width:(int)width height:(int)height spp:(int)spp radius:(float)radius distanceDes:(float*)distData extendInfo:(int)extendInfo effectState:(int*)effectState
{
    //NSTimeInterval beigin = [NSDate timeIntervalSinceReferenceDate];
    float *distData1 = (float *)malloc(width * height * sizeof(float));
    
    
    NSString *strQueueToken =[NSString stringWithFormat:@"com.effect.dist"];
    static dispatch_queue_t dispatch_queue = nil;
    
    if(!dispatch_queue)
        dispatch_queue = dispatch_queue_create(strQueueToken.UTF8String, DISPATCH_QUEUE_SERIAL);
    
    volatile int processed = 0;
    volatile int *pProcessed = &processed;
     dispatch_async(dispatch_queue, ^{
    
         vil_computeDistanceSimple_in(srcData, width, height, spp, radius, distData1, extendInfo, effectState);
         
         *pProcessed = 1;
     });
                    
    vil_computeDistanceSimple_out(srcData, width, height, spp, radius, distData, extendInfo, effectState);

    while(processed == 0)
    {
        [NSThread sleepForTimeInterval:0.001];
    }

    //NSLog(@"computeDistance time : %f", [NSDate timeIntervalSinceReferenceDate] - beigin);
    
    for(int i=0; i< width*height; i++)
    {
        if(srcData[i*spp + spp -1] > 0)
        {
            distData[i] = - distData1[i];
        }
        
    }
    
    free(distData1);
}

- (void)computeDistanceFastWithDataInfo:(INPUT_DISTANCE_INFO)inputInfo
{
    //vil_computeDistanceFast(inputInfo.srcData, inputInfo.srcDis, inputInfo.dirtyRect.origin.x, inputInfo.dirtyRect.origin.y, inputInfo.dirtyRect.size.width, inputInfo.dirtyRect.size.height, inputInfo.dataSize.width, inputInfo.dataSize.height, inputInfo.spp, MAX_DISTANCE_RADIUS, inputInfo.dstDis, inputInfo.extendInfo, inputInfo.state);
    [m_lockDistInfo lock];
    
    if (!(inputInfo.fullSize.width > 0 && inputInfo.fullSize.height > 0))
    {
        [m_lockDistInfo unlock];
        return;
    }
    
    
    if (!m_pSrcMaskData)
    {
        m_pSrcMaskData = (unsigned char*)malloc(inputInfo.fullSize.width * inputInfo.fullSize.height);
        memset(m_pSrcMaskData, 0, inputInfo.fullSize.width * inputInfo.fullSize.height);
        m_pSrcDistanceData = (float*)malloc(inputInfo.fullSize.width * inputInfo.fullSize.height * sizeof(float));
        int width = inputInfo.fullSize.width;
        int height = inputInfo.fullSize.height;
        for (int i = 0; i < width; i++)
        {
            for (int j = 0; j < height; j++)
            {
                m_pSrcDistanceData[j * width + i] = MAX_DISTANCE_RADIUS;
            }
        }
        m_fullSize = inputInfo.fullSize;
    }
    else
    {
        if (!CGSizeEqualToSize(m_fullSize, inputInfo.fullSize))
        {
            free(m_pSrcMaskData);
            free(m_pSrcDistanceData);
            m_pSrcMaskData = (unsigned char*)malloc(inputInfo.fullSize.width * inputInfo.fullSize.height);
            m_pSrcDistanceData = (float*)malloc(inputInfo.fullSize.width * inputInfo.fullSize.height * sizeof(float));
            m_fullSize = inputInfo.fullSize;
        }
    }
    
    BOOL isReady = [self dataIsReady:inputInfo];
    if (isReady)
    {
        for (int j = inputInfo.dirtyRect.origin.y; j < inputInfo.dirtyRect.origin.y + inputInfo.dirtyRect.size.height; j++)
        {
            int src = j * m_fullSize.width + inputInfo.dirtyRect.origin.x;
            int des = (j - inputInfo.dirtyRect.origin.y) * inputInfo.dirtyRect.size.width;
            int size = inputInfo.dirtyRect.size.width * sizeof(float);
            memcpy(&inputInfo.dstDis[des], &m_pSrcDistanceData[src], size);
        }
    }
    else
    {
        vil_computeDistanceFast(inputInfo.dirtyData, inputInfo.dstDis, 0, 0, inputInfo.dirtyRect.size.width, inputInfo.dirtyRect.size.height, inputInfo.dirtyRect.size.width, inputInfo.dirtyRect.size.height, inputInfo.spp, MAX_DISTANCE_RADIUS, inputInfo.dstDis, 15, inputInfo.state);
        
//        for (int j = inputInfo.dirtyRect.origin.y; j < inputInfo.dirtyRect.origin.y + inputInfo.dirtyRect.size.height; j++) {
//            int des = (j - inputInfo.dirtyRect.origin.y) * inputInfo.dirtyRect.size.width;
//            int src = j * m_fullSize.width + inputInfo.dirtyRect.origin.x;
//            int size = inputInfo.dirtyRect.size.width * sizeof(float);
//            memcpy(&m_pSrcDistanceData[src], &inputInfo.dstDis[des], size);
//        }
        
        for (int j = inputInfo.validRect.origin.y; j < inputInfo.validRect.origin.y + inputInfo.validRect.size.height; j++) {
            int src = (j - inputInfo.dirtyRect.origin.y) * inputInfo.dirtyRect.size.width + inputInfo.validRect.origin.x - inputInfo.dirtyRect.origin.x;
            int des = j * m_fullSize.width + inputInfo.validRect.origin.x;
            int size = inputInfo.validRect.size.width * sizeof(float);
            memcpy(&m_pSrcDistanceData[des], &inputInfo.dstDis[src], size);
        }
        
        for (int i = inputInfo.dirtyRect.origin.x; i < inputInfo.dirtyRect.origin.x + inputInfo.dirtyRect.size.width; i++)
        {
            for (int j = inputInfo.dirtyRect.origin.y; j < inputInfo.dirtyRect.origin.y + inputInfo.dirtyRect.size.height; j++)
            {
                int pos1 = ((j - inputInfo.dirtyRect.origin.y) * inputInfo.dirtyRect.size.width + (i - inputInfo.dirtyRect.origin.x) + 1) * inputInfo.spp - 1;
                int pos2 = j * m_fullSize.width + i;
                m_pSrcMaskData[pos2] = inputInfo.dirtyData[pos1];
            }
        }

    }
    [m_lockDistInfo unlock];
    
}

- (BOOL)dataIsReady:(INPUT_DISTANCE_INFO)inputInfo
{
    for (int i = inputInfo.dirtyRect.origin.x; i < inputInfo.dirtyRect.origin.x + inputInfo.dirtyRect.size.width; i++)
    {
        for (int j = inputInfo.dirtyRect.origin.y; j < inputInfo.dirtyRect.origin.y + inputInfo.dirtyRect.size.height; j++) {
            int pos1 = ((j - inputInfo.dirtyRect.origin.y) * inputInfo.dirtyRect.size.width + (i - inputInfo.dirtyRect.origin.x) + 1) * inputInfo.spp - 1;
            int pos2 = j * m_fullSize.width + i;
            if (inputInfo.dirtyData[pos1] != m_pSrcMaskData[pos2]) {
                return NO;
            }
        }
    }
    return YES;
}

@end
