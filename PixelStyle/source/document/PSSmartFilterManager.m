//
//  PSSmartFilterManager.m
//  SmartFilterDesign
//
//  Created by lchzh on 1/12/15.
//  Copyright © 2015 effectmatrix. All rights reserved.
//

#import "PSSmartFilterManager.h"

#import "PSDistanceInfoManager.h"
#import "PSSecureImageData.h"
#import "Bitmap.h" //unpremultiplyBitmap
#import "GPUImageDTFilter.h"

#define kNumberOfUndoRecordsPerMalloc 10

typedef struct
{
    BOOL isFull;
    CGRect validRect;
    CGSize fullSize;
    
}FULL_DATA_INFO;

@implementation PSSmartFilterManager

NSRecursiveLock *g_lockGPUUse = nil;

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInt:m_filtersCount] forKey:@"smartFilterCount"];

    
    for (int nIndex = 0; nIndex < m_filtersCount; nIndex++)
    {
        SMART_FILTER_INFO smartFilterInfo = m_allFilters[nIndex];
        
        
        [aCoder encodeObject:[NSNumber numberWithInt:smartFilterInfo.uniqueID] forKey:[NSString stringWithFormat:@"uniqueID_%d",nIndex]];
        [aCoder encodeObject:smartFilterInfo.filterName forKey:[NSString stringWithFormat:@"filterName_%d",nIndex]];
        [aCoder encodeObject:[NSNumber numberWithBool:smartFilterInfo.isEnable] forKey:[NSString stringWithFormat:@"isEnable_%d",nIndex]];
       
        [aCoder encodeObject:[NSString stringWithUTF8String:smartFilterInfo.filterInfo.filterName] forKey:[NSString stringWithFormat:@"filterInfo.filterName_%d",nIndex]];
        [aCoder encodeObject:[NSString stringWithUTF8String:smartFilterInfo.filterInfo.filterCatagoryName] forKey:[NSString stringWithFormat:@"filterInfo.filterCatagoryName_%d",nIndex]];
        [aCoder encodeObject:[NSString stringWithUTF8String:smartFilterInfo.filterInfo.filterClassName] forKey:[NSString stringWithFormat:@"filterInfo.filterClassName_%d",nIndex]];
        
        [aCoder encodeObject:[NSNumber numberWithInt:smartFilterInfo.filterInfo.parametersCount] forKey:[NSString stringWithFormat:@"filterInfo.parametersCount_%d",nIndex]];
        [aCoder encodeObject:[NSNumber numberWithInt:smartFilterInfo.filterInfo.textureCount] forKey:[NSString stringWithFormat:@"filterInfo.textureCount_%d",nIndex]];
        
        int paraCount = smartFilterInfo.filterInfo.parametersCount;
        for (int nParametersIndex = 0; nParametersIndex < paraCount; nParametersIndex++)
        {
            FILTER_PARAMETER_INFO filterParameterInfo = smartFilterInfo.filterInfo.filterParameters[nParametersIndex];
            NSData *filterParameters = [NSData dataWithBytes:&filterParameterInfo length:sizeof(FILTER_PARAMETER_INFO)];
            [aCoder encodeObject:filterParameters forKey:[NSString stringWithFormat:@"filterInfo.filterParameters_%d_%d", nParametersIndex, nIndex]];
        }
    }
    
//    NSData *allFiltersData = [NSData dataWithBytes:m_allFilters length:m_filtersCount * sizeof(SMART_FILTER_INFO)];
//    [aCoder encodeObject:allFiltersData forKey:@"smartFilterInfo"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (!self)      return nil;
    
    m_filtersCount = [[aDecoder decodeObjectForKey:@"smartFilterCount"] intValue];
    
    m_allFilters = (SMART_FILTER_INFO*)malloc(m_filtersCount * sizeof(SMART_FILTER_INFO));
    
    
    for (int nIndex = 0; nIndex < m_filtersCount; nIndex++)
    {
        m_allFilters[nIndex].uniqueID = [[aDecoder decodeObjectForKey:[NSString stringWithFormat:@"uniqueID_%d",nIndex]] intValue];
        m_allFilters[nIndex].filterName = [aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterName_%d",nIndex]];
        m_allFilters[nIndex].isEnable = [[aDecoder decodeObjectForKey:[NSString stringWithFormat:@"isEnable_%d",nIndex]] boolValue];
        
        NSString *filterName = [aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterInfo.filterName_%d",nIndex]];
        [filterName getCString:m_allFilters[nIndex].filterInfo.filterName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
        NSString *filterCatagoryName = [aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterInfo.filterCatagoryName_%d",nIndex]];
        [filterCatagoryName getCString:m_allFilters[nIndex].filterInfo.filterCatagoryName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
        NSString *filterClassName = [aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterInfo.filterClassName_%d",nIndex]];
        [filterClassName getCString:m_allFilters[nIndex].filterInfo.filterClassName maxLength:CHAR_ARRAY_SIZE encoding:NSASCIIStringEncoding];
        
        m_allFilters[nIndex].filterInfo.parametersCount = [[aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterInfo.parametersCount_%d",nIndex]] intValue];
        m_allFilters[nIndex].filterInfo.textureCount = [[aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterInfo.textureCount_%d",nIndex]] intValue];
        
        
        Class filterClass = NSClassFromString(filterClassName);
        GPUImageOutput *filter = [[filterClass alloc] init];
        [filter useNextFrameForImageCapture];
        m_allFilters[nIndex].filterInfo.gpuImageFilter = filter;
        
        
        int paraCount = m_allFilters[nIndex].filterInfo.parametersCount;
        
        m_allFilters[nIndex].filterInfo.filterParameters = (FILTER_PARAMETER_INFO*)malloc(paraCount * sizeof(FILTER_PARAMETER_INFO));
        
        for (int nParametersIndex = 0; nParametersIndex < paraCount; nParametersIndex++)
        {
            NSData *filterParameters = [aDecoder decodeObjectForKey:[NSString stringWithFormat:@"filterInfo.filterParameters_%d_%d", nParametersIndex, nIndex]];
            memcpy(&m_allFilters[nIndex].filterInfo.filterParameters[nParametersIndex], [filterParameters bytes], sizeof(FILTER_PARAMETER_INFO));
        }
    }
    
    
//    NSData *allFiltersData = [aDecoder decodeObjectForKey:@"smartFilterInfo"];
//    
//    m_allFilters = (SMART_FILTER_INFO*)malloc(m_filtersCount * sizeof(SMART_FILTER_INFO));
//    memcpy(m_allFilters, [allFiltersData bytes], m_filtersCount * sizeof(SMART_FILTER_INFO));
//
    
    return self;
}

- (id)init
{
    self = [super init];
    m_allFilters = nil;
    m_filtersCount = 0;
    m_filterSourceLock = [[NSRecursiveLock alloc] init];
    
    m_filterState = 1;
    m_isProcessFull = NO;
    
    m_undoRecords = NULL;
    m_undoRecordsCount = 0;
    m_undoRecordsMaxLen = 0;
    m_oldRecords.allFilters = NULL;
    m_oldRecords.filtersCount = 0;
    
    m_distanceInfoManager = [[PSDistanceInfoManager alloc] init];
    
    if (g_lockGPUUse == nil)
    {
        g_lockGPUUse = [[NSRecursiveLock alloc] init];
    }
    
    return self;
}

- (void)setSmartFilterInfo:(SMART_FILTER_INFO *)filterInfo
{
    m_allFilters = filterInfo;
}

- (void)setSmartFilterCount:(int)count
{
    m_filtersCount = count;
}


- (id)customCopy
{
    PSSmartFilterManager *manager = [[PSSmartFilterManager alloc] init];
    
    [manager setSmartFilterCount:m_filtersCount];
    SMART_FILTER_INFO *copyInfo = (SMART_FILTER_INFO*)malloc(sizeof(SMART_FILTER_INFO) * m_filtersCount);;
    
    for (int i = 0; i < m_filtersCount; i++)
    {
        copyInfo[i] = m_allFilters[i];
        copyInfo[i].filterName = [[NSString alloc] initWithString:m_allFilters[i].filterName];
        
        FILTER_PARAMETER_INFO *filterParameters = malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFilters[i].filterInfo.parametersCount);
        memcpy(filterParameters, m_allFilters[i].filterInfo.filterParameters, sizeof(FILTER_PARAMETER_INFO) * m_allFilters[i].filterInfo.parametersCount);
        copyInfo[i].filterInfo.filterParameters = filterParameters;
        
        NSString *fliterClassName = [NSString stringWithUTF8String:m_allFilters[i].filterInfo.filterClassName];
        Class filterClass = NSClassFromString(fliterClassName);
        GPUImageOutput *filter = [[filterClass alloc] init];
        
        [filter useNextFrameForImageCapture];
        copyInfo[i].filterInfo.gpuImageFilter = filter;
    }
    
    [manager setSmartFilterInfo:copyInfo];
    return manager;
}

- (id)initWithDelegate:(id)delegate
{
    self = [self init];
    m_delegateForManager = delegate;
    return self;
}

- (void)setDelegateForManager:(id)delegate
{
    m_delegateForManager = delegate;
}

- (void)dealloc
{
    [m_filterSourceLock lock];
    
    if(m_distanceInfoManager)
    {
        [m_distanceInfoManager release];
        m_distanceInfoManager = nil;
    }
    
    if(m_allFilters)
    {
        for (int i = 0; i < m_filtersCount; i++)
        {
            if (m_allFilters[i].filterInfo.filterParameters)
            {
                free(m_allFilters[i].filterInfo.filterParameters);
                [m_allFilters[i].filterInfo.gpuImageFilter release];
                m_allFilters[i].filterInfo.gpuImageFilter = nil;
                [m_allFilters[i].filterName release];
            }
        }
        
        free(m_allFilters);
        m_allFilters = NULL;
        m_filtersCount = 0;
    }
    
    [m_filterSourceLock unlock];
    
    if(m_filterSourceLock)
    {
        [m_filterSourceLock release];
        m_filterSourceLock = nil;
    }
    
    [super dealloc];
}

#pragma mark -
#pragma mark add/remove filters

//因为修改频率低，暂采用临时添加，用多少开多少空间 不去预开了
- (void)addNewSmartFilter:(NSString*)filterName
{
    [m_filterSourceLock lock];
    
    if (m_allFilters == nil)
    {
        m_allFilters = (SMART_FILTER_INFO*)malloc(sizeof(SMART_FILTER_INFO));
    }
    else
    {
        m_allFilters = realloc(m_allFilters, (m_filtersCount + 1) * sizeof(SMART_FILTER_INFO));
    }
    
    COMMON_FILTER_INFO filterInfo = [PSSmartFilterRegister filterWithName:filterName];
   
    m_allFilters[m_filtersCount].uniqueID = m_filtersCount;
    m_allFilters[m_filtersCount].filterName = [[NSString alloc] initWithString:filterName];
    m_allFilters[m_filtersCount].isEnable = YES;
    m_allFilters[m_filtersCount].filterInfo = filterInfo; //注意数据是否一致
    
    m_filtersCount++;
    
    [m_filterSourceLock unlock];
}

- (void)insertNewSmartFilter:(NSString*)filterName atIndex:(int)index
{
    if (index < 0 || index > m_filtersCount)
    {
        return;
    }
    
    COMMON_FILTER_INFO filterInfo = [PSSmartFilterRegister filterWithName:filterName];
    
    if (filterInfo.gpuImageFilter == nil)
    {
        return;
    }
    
    [m_filterSourceLock lock];
    
    SMART_FILTER_INFO *filtersInfo = (SMART_FILTER_INFO*)malloc(sizeof(SMART_FILTER_INFO) * (m_filtersCount + 1));
    
    for (int i = 0; i < index; i++)
    {
        filtersInfo[i] = m_allFilters[i];
        //filtersInfo[i].filterName = [[NSString alloc] initWithString:m_allFilters[i].filterName];
    }
    
    filtersInfo[index].filterInfo = filterInfo;
    filtersInfo[index].isEnable = YES;
    filtersInfo[index].filterName = [[NSString alloc] initWithString:filterName];
    
    for (int i = index; i < m_filtersCount; i++)
    {
        filtersInfo[i + 1] = m_allFilters[i];
        //filtersInfo[i + 1].filterName = [[NSString alloc] initWithString:m_allFilters[i].filterName];
    }
    
    if (m_allFilters)
    {
        free(m_allFilters);
    }
    
    m_filtersCount ++;
    m_allFilters = filtersInfo;
    
    [m_filterSourceLock unlock];
}

- (void)removeSmartFilter:(int)index
{
    if (index >= m_filtersCount || index < 0)
    {
        return;
    }
    
    [m_filterSourceLock lock];
    
    SMART_FILTER_INFO* filtersInfo = (SMART_FILTER_INFO*)malloc(sizeof(SMART_FILTER_INFO) * (m_filtersCount - 1));
    
    for (int i = 0; i < index; i++)
    {
        filtersInfo[i] = m_allFilters[i];
        //filtersInfo[i].filterName = [NSString stringWithString:m_allFilters[i].filterName];
    }
    
    for (int i = index + 1; i < m_filtersCount; i++)
    {
        filtersInfo[i - 1] = m_allFilters[i];
        //filtersInfo[i - 1].filterName = [NSString stringWithString:m_allFilters[i].filterName];
    }
    
    if (m_allFilters[index].filterInfo.filterParameters)
    {
        free(m_allFilters[index].filterInfo.filterParameters);
//        [m_allFilters[index].filterInfo.gpuImageFilter release];
//        m_allFilters[index].filterInfo.gpuImageFilter = nil;
//        [m_allFilters[index].filterName release];
    }
    
    if (m_allFilters)
    {
        free(m_allFilters);
    }
    m_filtersCount --;
    m_allFilters = filtersInfo;
    
    [m_filterSourceLock unlock];
    
}

- (void)moveSmartFilterFrom:(int)fromIndex to:(int)toIndex
{
    if (fromIndex >= m_filtersCount || fromIndex < 0 || toIndex >= m_filtersCount || toIndex < 0)
    {
        return;
    }
    [m_filterSourceLock lock];
    
    SMART_FILTER_INFO filtersInfoFrom = m_allFilters[fromIndex];
    //filtersInfoFrom.filterName = [NSString stringWithString:m_allFilters[fromIndex].filterName];
    SMART_FILTER_INFO filtersInfoTo = m_allFilters[toIndex];
    //filtersInfoTo.filterName = [NSString stringWithString:m_allFilters[toIndex].filterName];
    if (fromIndex > toIndex)
    {
        for (int i = fromIndex - 1; i >= toIndex && i < m_filtersCount; i--)
        {
            m_allFilters[i + 1] = m_allFilters[i];
            //m_allFilters[i + 1].filterName = [NSString stringWithString:m_allFilters[i].filterName];
        }
        m_allFilters[toIndex] = filtersInfoFrom;
        //m_allFilters[toIndex].filterName = [NSString stringWithString:filtersInfoFrom.filterName];
    }
    else if (fromIndex < toIndex)
    {
        for (int i = fromIndex + 1; i <= toIndex && i >= 0; i++)
        {
            m_allFilters[i - 1] = m_allFilters[i];
            //m_allFilters[i - 1].filterName = [NSString stringWithString:m_allFilters[i].filterName];
        }
        m_allFilters[toIndex] = filtersInfoFrom;
        //m_allFilters[toIndex].filterName = [NSString stringWithString:filtersInfoFrom.filterName];
    }
    
    [m_filterSourceLock unlock];
}

- (void)flatternFilters
{
    [self saveFilterRecord];
    
    [m_filterSourceLock lock];

    if(m_allFilters)
    {
        for (int i = 0; i < m_filtersCount; i++)
        {
            if (m_allFilters[i].filterInfo.filterParameters)
            {
                free(m_allFilters[i].filterInfo.filterParameters);
            }
        }
        
        free(m_allFilters);
        m_allFilters = NULL;
        m_filtersCount = 0;
    }
    
    [m_filterSourceLock unlock];
    
    [self addNewSmartFilter:@"Effect"];
    [self addNewSmartFilter:@"Channel"];
    
    [self makeUndoRecord];
}



#pragma mark -
#pragma mark set/get filter info

- (void)resetSmartFilter:(int)index
{
    if (index < m_filtersCount)
    {
        COMMON_FILTER_INFO cinfo = m_allFilters[index].filterInfo;
        
        for (int i = 0; i < cinfo.parametersCount; i++)
        {
            cinfo.filterParameters[i].value = cinfo.filterParameters[i].defaultValue;
        }
    }
}


- (SMART_FILTER_INFO)getSmartFilterAtIndex:(int)index
{
    if (index < m_filtersCount)
    {
        return m_allFilters[index];
    }
    
    assert(false);
    SMART_FILTER_INFO filterInfo;
    return filterInfo;
}


- (void)setSmartFilter:(SMART_FILTER_INFO)filterInfo AtIndex:(int)index
{
    if (index < m_filtersCount)
    {
//        m_allFilters[index].filterName = [NSString stringWithString:filterInfo.filterName];
//        m_allFilters[index].uniqueID = filterInfo.uniqueID;
//        m_allFilters[index].isEnable = filterInfo.isEnable;
//        m_allFilters[index].filterInfo = filterInfo.filterInfo;
        m_allFilters[index] = filterInfo;
    }
}


- (FILTER_PARAMETER_INFO)getSmartFilterParameterInfo:(int)filterIndex parameterIndex:(int)paraIndex
{
    return m_allFilters[filterIndex].filterInfo.filterParameters[paraIndex];
}

- (FILTER_PARAMETER_INFO)getSmartFilterParameterInfo:(int)filterIndex parameterName:(const char *)pParaName
{
    if (filterIndex >= m_filtersCount || (filterIndex < 0))
    {
        FILTER_PARAMETER_INFO info;
        return info;
    }
    
    int paraIndex = [self getFilterParaIndexWithName:pParaName forFilter:filterIndex];
    
    return [self getSmartFilterParameterInfo:filterIndex parameterIndex:paraIndex];
    
}

- (PARAMETER_VALUE)getSmartFilterParameterForFilter:(int)filterIndex parameterName:(const char *)pParaName
{
    if (filterIndex >= m_filtersCount || (filterIndex < 0))
    {
        PARAMETER_VALUE value;
        value.nIntValue = 0;
        value.fFloatValue = 0.0;
        return value;
    }
    
    int paraIndex = [self getFilterParaIndexWithName:pParaName forFilter:filterIndex];
    
    return [self getSmartFilterParameterForFilter:filterIndex parameterIndex:paraIndex];
}

- (PARAMETER_VALUE)getSmartFilterParameterForFilter:(int)filterIndex parameterIndex:(int)paraIndex
{
    if (filterIndex >= m_filtersCount || (filterIndex < 0))
    {
        PARAMETER_VALUE value;
        value.nIntValue = 0;
        value.fFloatValue = 0.0;
        return value;
    }
    
    return m_allFilters[filterIndex].filterInfo.filterParameters[paraIndex].value;
}

-(int)getFilterParaIndexWithName:(const char *)pParaName forFilter:(int)filterIndex
{
    if (filterIndex < 0) return 0;
    
    if (filterIndex >= m_filtersCount)
    {
        return 0;
    }
    
    int paraCount   = m_allFilters[filterIndex].filterInfo.parametersCount;
    FILTER_PARAMETER_INFO *paraInfo = m_allFilters[filterIndex].filterInfo.filterParameters;
    NSString *name  = [NSString stringWithUTF8String:pParaName];
    
    for (int i = 0; i < paraCount; i++)
    {
        NSString *paraName = [NSString stringWithCString:paraInfo[i].parameterName encoding:NSASCIIStringEncoding];
        if ([paraName isEqualToString:name])
        {
            return i;
        }
    }
    
    return 0;
}

-(void)setSmartFilterParameter:(PARAMETER_VALUE)value filterIndex:(int)filterIndex parameterIndex:(int)paraIndex
{
    if (filterIndex >= m_filtersCount || (filterIndex < 0))
    {
        return;
    }
    
    m_allFilters[filterIndex].filterInfo.filterParameters[paraIndex].value = value;

}

-(void)setSmartFilterParameter:(PARAMETER_VALUE)value filterIndex:(int)filterIndex parameterName:(const char *)pParaName
{
    int paraIndex = [self getFilterParaIndexWithName:pParaName forFilter:filterIndex];
    [self setSmartFilterParameter:value filterIndex:filterIndex parameterIndex:paraIndex];
}


- (int)getSmartFiltersCount
{
    return m_filtersCount;
}

#pragma mark -
#pragma mark process data



// 做级联 根据filter输入纹理个数 有的要特殊处理  甚至从gpu出来 再进去
- (OUTPUT_DATA_INFO)getFilteredDataForSrcData:(INPUT_DATA_INFO ) inputDataInfo
{
    
    //NSLog(@"getFilteredDataForSrcData %d %@",inputDataInfo.precision, NSStringFromRect(inputDataInfo.dirtyRect));
   // INPUT_DATA_INFO  inputDataInfo = inputDataInfo1;
   // assert(inputDataInfo.dirtyRect.size.width);
    
   // CGRect recttest = inputDataInfo.dirtyRect;
  //  CGRect needRecttest = [self getNeedInputRectForDirtyRect:recttest fullSize:CGSizeMake(1280, 720)];
   // assert(CGRectEqualToRect(recttest, needRecttest));
    
   
     [m_filterSourceLock lock];
    m_filterState = 1;
    
    if (inputDataInfo.precision == 1)
    {
        m_isProcessFull = YES;
    }
    else
    {
        m_isProcessFull = NO;
    }
    assert(inputDataInfo.dirtyRect.size.width);
    
    PSSecureImageData *dataImage = inputDataInfo.dataImage;//[[PSSecureImageData alloc] initData:1 height:1 spp:4 alphaPremultiplied:false];
//    [dataImage copyFrom:inputDataInfo.dataImage];
    
    IMAGE_DATA imageData = [dataImage lockDataForRead];
    //IMAGE_DATA imageData = [inputDataInfo.dataImage lockDataForRead];
    assert(inputDataInfo.dirtyRect.size.width);
    OUTPUT_DATA_INFO outDataInfo;
    memset(&outDataInfo, 0, sizeof(outDataInfo));
    
    outDataInfo.bAlphaPremultiplied = imageData.bAlphaPremultiplied;
    outDataInfo.nSpp = imageData.nSpp;
    outDataInfo.pBuffer = NULL;
    
    int spp = imageData.nSpp;
    int fullWidth = imageData.nWidth;
    int fullHeight = imageData.nHeight;
    
    INPUT_DATA_INFO infoBackup =  inputDataInfo;
    inputDataInfo.dirtyRect = CGRectIntersection(inputDataInfo.dirtyRect, CGRectMake(0, 0, fullWidth, fullHeight));
    
    if(CGRectIsNull(inputDataInfo.dirtyRect) || inputDataInfo.dirtyRect.size.width == 0 || inputDataInfo.dirtyRect.size.height == 0)
    {
        if(infoBackup.dirtyRect.size.width == 0 || infoBackup.dirtyRect.size.height == 0)
            outDataInfo.state = 0;
        else
            outDataInfo.state = 1;
        [dataImage unLockDataForRead];
     //   [dataImage release];
        
       // m_isProcessFull = NO;
        [m_filterSourceLock unlock];
        
        return outDataInfo;
    }
 
    unsigned char *pBuffer = imageData.pBuffer;  //wzq
    
    //对于第一次用filtergroup，必须要初始化一下这个，暂不知道为什么，以后再研究
    if (m_filtersCount > 2)
    {
        [g_lockGPUUse lock];
        
        unsigned char *pBuffer = imageData.pBuffer;
    //    GPUImageRawDataInput *imageInput = [[GPUImageRawDataInput alloc] initWithBytes:pBuffer size:CGSizeMake(fullWidth, fullHeight) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
        GPUImageRawDataInput *imageInput = [[GPUImageRawDataInput alloc] initWithBytes:pBuffer size:CGSizeMake(1, 1) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
        [imageInput release];
        
        [g_lockGPUUse unlock];
    }    
    
    
    float bufferScale = 1.0;
    [self setGPUImageFilterParamterInfoWithScale:bufferScale isFull:NO];
    BOOL isFilterValid = [self getFilterIsValid];
    
    assert(inputDataInfo.dirtyRect.size.width);
    if (isFilterValid)
    {
        
        if (inputDataInfo.precision == 0)
        {
            CGRect needRect = [self getNeedInputRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
            CGRect effectRect = [self getEffectedRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
            
            needRect = CGRectIntegral(needRect);
            effectRect = CGRectIntegral(effectRect);
            
            float scale = MAX(inputDataInfo.sizeScale.width, inputDataInfo.sizeScale.height);
            
            unsigned char *inputData = nil;
            inputData = malloc(needRect.size.width * needRect.size.height * spp);

            for (int i = needRect.origin.y; i < needRect.origin.y + needRect.size.height; i++)
            {
                int srcPos = (i * fullWidth + needRect.origin.x) * spp;
                int desPos = ((i - needRect.origin.y) * needRect.size.width) * spp;
                
                memcpy(inputData + desPos, pBuffer + srcPos, needRect.size.width * spp);
            }
            
            float needScale = sqrtf(1000000.0 / (needRect.size.width * needRect.size.height));
            
            if (scale < 0.99 || needScale < 0.99)
            {
                if ([self isCanScaleFilterParameter])
                {
                    bufferScale = MIN(scale, needScale);//
                    
                    CGRect scaledNeedRect = [self CGRectCustomScale:needRect scale:bufferScale];
                    unsigned char *mallocInputData = malloc(scaledNeedRect.size.width * scaledNeedRect.size.height * spp);
                    
                    [self resizeImageData:inputData srcWidth:needRect.size.width srcHeight:needRect.size.height toDesData:mallocInputData desWidth:scaledNeedRect.size.width desHeight:scaledNeedRect.size.height spp:spp];
                    
                    needRect = scaledNeedRect;
                    effectRect = [self CGRectCustomScale:effectRect scale:bufferScale];
                    
                    free(inputData);
                    inputData = mallocInputData;
                }
            }
            
            FULL_DATA_INFO fullInfo;
            
            fullInfo.isFull = NO;
            fullInfo.fullSize = [self CGRectCustomScale:CGRectMake(0, 0, fullWidth, fullHeight) scale:bufferScale].size;
            if (imageData.bAlphaPremultiplied)
            {
                unpremultiplyBitmap(spp, inputData, inputData, needRect.size.width * needRect.size.height);
            }
            
            unsigned char *outputData = [self processsData:inputData needRect:needRect spp:spp outputRect:effectRect bufferScale:bufferScale fullInfo:fullInfo];
            if (imageData.bAlphaPremultiplied)
            {
                if (outputData)
                {
                    premultiplyBitmap(spp, outputData, outputData, effectRect.size.width * effectRect.size.height);
                }
            }
            outDataInfo.pBuffer = outputData;
            outDataInfo.bufferRect = effectRect;
            outDataInfo.nSpp = spp;
            outDataInfo.sizeScale = CGSizeMake(bufferScale, bufferScale);
            
            if (m_filterState)
            {
                outDataInfo.state = 0;
            }
            else
            {
                outDataInfo.state = 1;
            }
            
            free(inputData);

        }
        else
        {
            [self splitBigDataToSmall:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
            
            CGRect needRect = [self getNeedInputRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
            CGRect effectRect = [self getEffectedRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
            
            needRect = CGRectIntegral(needRect);
            effectRect = CGRectIntegral(effectRect);
            
        //    int *bBlockProcessed = (int *)malloc(m_blockCount);
         //   memset(bBlockProcessed, 0, m_blockCount * sizeof(int));
            
            for (int j = 0; j < m_blockCount; j++)
            {
 
                if (!m_filterState)
                {
                    break;
                }
                
                CGRect needRect = m_blockDataInfo[j].neededRect;
                CGRect effectRect = m_blockDataInfo[j].effectedRect;

             //   NSString *strQueueToken =[NSString stringWithFormat:@"com.effect.dist.%d", j];
            //    dispatch_queue_t dispatch_queue = dispatch_queue_create(strQueueToken.UTF8String, DISPATCH_QUEUE_SERIAL);
                
               // dispatch_async(dispatch_queue, ^{
                               
                    unsigned char *inputData = malloc(needRect.size.width * needRect.size.height * spp);
                
                for (int i = needRect.origin.y; i < needRect.origin.y + needRect.size.height; i++)
                    {
                        int srcPos = (i * fullWidth + needRect.origin.x) * spp;
                        int desPos = ((i - needRect.origin.y) * needRect.size.width) * spp;
                        
                        memcpy(inputData + desPos, pBuffer + srcPos, needRect.size.width * spp);
                    }
                    
                    if (!m_filterState)
                    {
                        if (inputData)
                        {
                            free(inputData);
                        }
                        break;
                    }
                    
                    FULL_DATA_INFO fullInfo;
                    fullInfo.isFull = NO;
                    fullInfo.fullSize = CGSizeMake(fullWidth, fullHeight);
                    fullInfo.validRect = m_blockDataInfo[j].dirtyRect;

                    if (imageData.bAlphaPremultiplied)
                    {
                        unpremultiplyBitmap(spp, inputData, inputData, needRect.size.width * needRect.size.height);
                    }
                    
                    unsigned char* outputData = [self processsData:inputData needRect:needRect spp:spp outputRect:effectRect bufferScale:bufferScale fullInfo:fullInfo];
                    
                    if (imageData.bAlphaPremultiplied)
                    {
                        if (outputData)
                        {
                            premultiplyBitmap(spp, outputData, outputData, effectRect.size.width * effectRect.size.height);
                        }
                    }
                    
                    m_blockDataInfo[j].outputData = outputData;

                    free(inputData);
                   
              //      bBlockProcessed[j] = 1;
              // });
            }
            
     /*       {
                for(int i=0; i< m_blockCount; i++)
                {
                    while(bBlockProcessed[i] == 0)
                    {
                        [NSThread sleepForTimeInterval:0.01];
                    }
                }
            }
       */
         //   free(bBlockProcessed);
            
            if (m_filterState)
            {
                unsigned char *outputData = (unsigned char *)malloc(effectRect.size.width * effectRect.size.height * spp);
                [self combineBlockDataToBig:effectRect desData:outputData spp:spp];
                outDataInfo.pBuffer = outputData;
            }
            
            outDataInfo.bufferRect = effectRect;
            outDataInfo.nSpp = spp;
            outDataInfo.sizeScale = CGSizeMake(bufferScale, bufferScale);
            if (m_filterState)
            {
                outDataInfo.state = 0;
                //NSLog(@"outDataInfo.state0");
            }
            else
            {
                outDataInfo.state = 1;
                //NSLog(@"outDataInfo.state1");
            }

        }
        
  //      assert(outDataInfo.pBuffer);
        
    }
    else
    {
        assert(inputDataInfo.dirtyRect.size.width);
     //   assert(CGRectEqualToRect(inputDataInfo.dirtyRect, CGRectIntersection(inputDataInfo1->dirtyRect, CGRectMake(0, 0, fullWidth, fullHeight))));
        CGRect needRect1 = [self getNeedInputRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
        assert(needRect1.size.width);
        assert(needRect1.size.height);
        
        CGRect effectRect = [self getEffectedRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
        
        needRect1 = CGRectIntegral(needRect1);
        effectRect = CGRectIntegral(effectRect);
        
        //float scale = MAX(inputDataInfo.sizeScale.width, inputDataInfo.sizeScale.height);
        unsigned char* rawData = nil; //dirty raw data, not scaled
        unsigned char* mallocRawData = nil;
        
     /*   IMAGE_DATA dataNow = [inputDataInfo.dataImage lockDataForRead];
        if(dataNow.nWidth != imageData.nWidth || dataNow.nHeight != imageData.nHeight)
        {
            outDataInfo.state = 1 ;
            [inputDataInfo.dataImage unLockDataForRead];
            [m_filterSourceLock unlock];
            
            return outDataInfo;
        }*/
        assert(needRect1.size.width);
        assert(needRect1.size.height);
        assert(needRect1.origin.x >= 0);
        assert(needRect1.origin.y >= 0);
        
        mallocRawData = malloc(needRect1.size.width * needRect1.size.height * spp);
        
        for (int i = needRect1.origin.y; i < needRect1.origin.y + needRect1.size.height; i++)
        {
            int srcPos = (i * fullWidth + needRect1.origin.x) * spp;
            int desPos = ((i - needRect1.origin.y) * needRect1.size.width) * spp;
        
            assert(desPos < needRect1.size.width * needRect1.size.height * spp);
            assert(desPos >= 0);
            assert(srcPos < fullWidth * fullHeight * spp);
            assert(srcPos >= 0);
            assert(((srcPos/spp)%(fullWidth))+needRect1.size.width  <= fullWidth);
        //    unsigned char *pBuffer = dataNow.pBuffer;
            memcpy(mallocRawData + desPos, pBuffer + srcPos, needRect1.size.width * spp);
        }
        rawData = mallocRawData;
        
      //  [inputDataInfo.dataImage unLockDataForRead];
        
        outDataInfo.bufferRect = needRect1;
        outDataInfo.nSpp = spp;
        outDataInfo.pBuffer = rawData;
        outDataInfo.sizeScale = CGSizeMake(1.0, 1.0);
        outDataInfo.state = 0;
  
   //     assert(outDataInfo.pBuffer);
    }
    
    [dataImage unLockDataForRead];
 //   [dataImage release];
    
    m_isProcessFull = NO;
    [m_filterSourceLock unlock];
    
 //   assert(outDataInfo.pBuffer);
    return outDataInfo;
    
}

- (unsigned char*)processsData_new:(unsigned char*)inputData needRect:(CGRect)needRect spp:(int)spp outputRect:(CGRect)effectRect bufferScale:(float)bufferScale fullInfo:(FULL_DATA_INFO)fullInfo
{
    [g_lockGPUUse lock];
    
    PARAMETER_VALUE value;
    
    float fullwidth = fullInfo.fullSize.width;
    float fullheight = fullInfo.fullSize.height;
    float rect[4] = {needRect.origin.x / fullwidth, needRect.origin.y / fullheight, needRect.size.width / fullwidth, needRect.size.height / fullheight};
    
    if (fullwidth > fullheight)
    {
        float originy = needRect.origin.y + (fullwidth - fullheight) / 2.0;
        rect[1] = originy / fullwidth;
        rect[3] = needRect.size.height / fullwidth;
    }
    else
    {
        float originx = needRect.origin.x + (fullheight - fullwidth) / 2.0;
        rect[0] = originx / fullheight;
        rect[2] = needRect.size.width / fullheight;
    }
    
    memcpy(value.fFloatVector4, rect, 4 * sizeof(float));
    [self setSmartFilterParameter:value filterIndex:m_filtersCount - 2 parameterName:[@"imageRect" UTF8String]];
    
    [self setGPUImageFilterParamterInfoWithScale:bufferScale isFull:NO];
    
    
    int width   = needRect.size.width;
    int height  = needRect.size.height;
    
    GPUImageRawDataInput *imageInput = [[GPUImageRawDataInput alloc] initWithBytes:inputData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
    GPUImageOutput *lastFilter = imageInput;
    GPUImageDTFilter *dtFilter = nil;
    
    dtFilter = [[GPUImageDTFilter alloc] initWithWidth:width height:height];
    [dtFilter useNextFrameForImageCapture];
    
//    GPUImageResample *resampleFilter = [[GPUImageResample alloc] init];
//    [resampleFilter useNextFrameForImageCapture];
//    [resampleFilter forceProcessingAtSize:CGSizeMake(256.0, 256.0)];
    
    GPUImageRawDataInput *imageInput2 = [[GPUImageRawDataInput alloc] initWithBytes:inputData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
    [imageInput2 forceProcessingAtSize:CGSizeMake(256.0, 256.0)];
    
    [imageInput2 addTarget:dtFilter];
    
    for (int nFilterItem = 0; nFilterItem < m_filtersCount; nFilterItem++)
    {
        SMART_FILTER_INFO *filterInfo = &m_allFilters[nFilterItem];
        
        if (!filterInfo->isEnable)
        {
            continue;
        }
        
        if (![self getFilterIsValidAtIndex:nFilterItem])
        {
            continue;
        }
        
        if (m_filterState == 0)
        {
            break;
        }
        
        GPUImageOutput<GPUImageInput> *currentFilter = nil;
        currentFilter = filterInfo->filterInfo.gpuImageFilter;
        
        
        switch (filterInfo->filterInfo.textureCount)
        {
            case 1:
            {
                [lastFilter addTarget:currentFilter];
            }
                break;
                
            case 2:
            {
                NSString *filterName = [NSString stringWithUTF8String:filterInfo->filterInfo.filterName];
                if ([filterName isEqualToString:@"Effect"])
                {
                    if (m_filterState)
                    {
                        [lastFilter addTarget:currentFilter];
                        [dtFilter addTarget:currentFilter];
                    }
                    
                }
            }
                break;
                
            case 3:
            {
                
            }
                break;
                
            default:
                break;
        }
        
        lastFilter = currentFilter;
    }
    
    GPUImageRawDataOutput *resultOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:NO];
    
  //  [dtFilter addTarget:resultOut]; //for test
    [lastFilter addTarget:resultOut];
    
    [imageInput processData];
    [imageInput2 processData];
    
   
    unsigned char *resultData = [resultOut rawBytesForImage];
    unsigned char *effectData = nil;
    
    if (m_filterState)
    {
        CGRect outputIntRect = needRect;
        
        effectData = malloc(effectRect.size.width * effectRect.size.height * spp);
        
        for (int i = effectRect.origin.y; i < effectRect.origin.y + effectRect.size.height; i++)
        {
            int srcPos = ((i - outputIntRect.origin.y) * outputIntRect.size.width + (effectRect.origin.x - outputIntRect.origin.x)) * spp;
            int desPos = ((i - effectRect.origin.y) * effectRect.size.width) * spp;
            
            if(srcPos >=0 && srcPos +  effectRect.size.width * spp <= width * height * spp)
                memcpy(effectData + desPos, resultData + srcPos, effectRect.size.width * spp);
        }
    }

    [imageInput removeAllTargets];
    
    for (int i = 0; i < m_filtersCount; i++)
    {
        [m_allFilters[i].filterInfo.gpuImageFilter removeAllTargets];
    }
    
    [imageInput release];
    [resultOut release];
    
    [imageInput2 removeAllTargets];
    [imageInput2 release];
    [dtFilter release];
 //   [resampleFilter release];
    
    [g_lockGPUUse unlock];
    
    return effectData;
    
}


- (unsigned char*)processsData:(unsigned char*)inputData needRect:(CGRect)needRect spp:(int)spp outputRect:(CGRect)effectRect bufferScale:(float)bufferScale fullInfo:(FULL_DATA_INFO)fullInfo
{
    [g_lockGPUUse lock];
    
    PARAMETER_VALUE value;
    
    float fullwidth = fullInfo.fullSize.width;
    float fullheight = fullInfo.fullSize.height;
    float rect[4] = {needRect.origin.x / fullwidth, needRect.origin.y / fullheight, needRect.size.width / fullwidth, needRect.size.height / fullheight};
    
    if (fullwidth > fullheight)
    {
        float originy = needRect.origin.y + (fullwidth - fullheight) / 2.0;
        rect[1] = originy / fullwidth;
        rect[3] = needRect.size.height / fullwidth;
    }
    else
    {
        float originx = needRect.origin.x + (fullheight - fullwidth) / 2.0;
        rect[0] = originx / fullheight;
        rect[2] = needRect.size.width / fullheight;
    }
    
    memcpy(value.fFloatVector4, rect, 4 * sizeof(float));
    [self setSmartFilterParameter:value filterIndex:m_filtersCount - 2 parameterName:[@"imageRect" UTF8String]];

    [self setGPUImageFilterParamterInfoWithScale:bufferScale isFull:NO];
    
    float *distanceData = nil;
    GPUImageRawDataInput *distanceInput = nil;
    
    int width = needRect.size.width;
    int height = needRect.size.height;
    
    GPUImageRawDataInput *imageInput = [[GPUImageRawDataInput alloc] initWithBytes:inputData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
    GPUImageOutput *lastFilter = imageInput;
    
    for (int i = 0; i < m_filtersCount; i++)
    {
        SMART_FILTER_INFO *filterInfo = &m_allFilters[i];
        
        if (!filterInfo->isEnable)
        {
            continue;
        }
        
        if (![self getFilterIsValidAtIndex:i])
        {
            continue;
        }
        
        if (m_filterState == 0)
        {
            break;
        }
        
        GPUImageOutput<GPUImageInput> *currentFilter = nil;
        currentFilter = filterInfo->filterInfo.gpuImageFilter;
        
        switch (filterInfo->filterInfo.textureCount)
        {
            case 1:
            {
                [lastFilter addTarget:currentFilter];
            }
                break;
                
            case 2:
            {
                NSString *filterName = [NSString stringWithUTF8String:filterInfo->filterInfo.filterName];
                if ([filterName isEqualToString:@"Effect"])
                {
                    unsigned char *needFreeData = nil;
                    GPUImageRawDataOutput *needFreeResultOut = nil;
                    unsigned char *realSrcData = inputData;
                    
                    if (i != 0)
                    {
                        [imageInput processData];
                        
                        GPUImageRawDataOutput *resultOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:NO];
                        
                        [lastFilter addTarget:resultOut];
                        realSrcData = [resultOut rawBytesForImage];
                        
                        [imageInput removeAllTargets];
                        
                        for (int j = 0; j < i; j++)
                        {
                            [m_allFilters[j].filterInfo.gpuImageFilter removeAllTargets];
                        }
                        
                        [imageInput release];
                        needFreeResultOut = resultOut;
                        needFreeData = realSrcData;
                        
                        imageInput = [[GPUImageRawDataInput alloc] initWithBytes:realSrcData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
                        [imageInput addTarget:currentFilter];
                        lastFilter = imageInput;
                        
                    }
                    
                    distanceData = (float*)malloc(width * height * sizeof(float));
                    if (m_filterState)
                    {
                        //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
                        
                        if (fullInfo.isFull)
                        {
                            INPUT_DISTANCE_INFO inputDisInfo;
                            inputDisInfo.dirtyData = realSrcData;
                            inputDisInfo.dirtyRect = needRect;
                            inputDisInfo.validRect = fullInfo.validRect;
                            inputDisInfo.fullSize = fullInfo.fullSize;
                            inputDisInfo.spp = spp;
                            inputDisInfo.state = (int*)&m_filterState;
                            inputDisInfo.dstDis = distanceData;
                            [m_distanceInfoManager computeDistanceFastWithDataInfo:inputDisInfo];
                        }
                        else
                        {
                            //[m_distanceInfoManager computeDistanceFastWithImage:realSrcData srcDistance:distanceData originx:0 originy:0 width:width height:height srcWidth:width srcHeight:height spp:spp radius:MAX_DISTANCE_RADIUS distanceDes:distanceData extendInfo:15 effectState:(int*)&m_filterState];
                            int extenderInfo = 0;
                            if (needRect.origin.y == 0.0)
                            {
                                extenderInfo |= 8;
                            }
                            if (needRect.origin.y + needRect.size.height == fullInfo.fullSize.height)
                            {
                                extenderInfo |= 4;
                            }
                            if (needRect.origin.x == 0.0)
                            {
                                extenderInfo |= 2;
                            }
                            if (needRect.origin.x + needRect.size.width == fullInfo.fullSize.width)
                            {
                                extenderInfo |= 1;
                            }
                            [m_distanceInfoManager computeDistanceSimpleWithImage:realSrcData width:width height:height spp:spp radius:MAX_DISTANCE_RADIUS distanceDes:distanceData extendInfo:extenderInfo effectState:(int*)&m_filterState];
                        }
                        
                        //NSLog(@"distancetime %f,%@,%d",[NSDate timeIntervalSinceReferenceDate] - begin, NSStringFromRect(needRect),m_filterState);
                    }
                    
                    if (m_filterState)
                    {
                        unsigned char* udistData = (unsigned char*)distanceData;
                        distanceInput = [[GPUImageRawDataInput alloc] initWithBytes:udistData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatLuminance type:GPUPixelTypeFloat];
                        
                        [lastFilter addTarget:currentFilter];
                        [distanceInput addTarget:currentFilter];
                        
                    }
                    if (distanceData)
                    {
                        free(distanceData);
                    }
                    
                    if (needFreeResultOut)
                    {
                        [needFreeResultOut release];
                    }
                    
                }
            }
                break;
                
            case 3:{
                
            }
                break;
                
            default:
                break;
        }
        lastFilter = currentFilter;
    }
    
    [imageInput processData];
    if (distanceInput)
    {
        [distanceInput processData];
    }
    
    GPUImageRawDataOutput *resultOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:NO];
    [lastFilter addTarget:resultOut];
    unsigned char *resultData = [resultOut rawBytesForImage];
    
    unsigned char *effectData = nil;
    
    if (m_filterState)
    {
        CGRect outputIntRect = needRect;
        
        effectData = malloc(effectRect.size.width * effectRect.size.height * spp);
        
        for (int i = effectRect.origin.y; i < effectRect.origin.y + effectRect.size.height; i++)
        {
            int srcPos = ((i - outputIntRect.origin.y) * outputIntRect.size.width + (effectRect.origin.x - outputIntRect.origin.x)) * spp;
            int desPos = ((i - effectRect.origin.y) * effectRect.size.width) * spp;
            
            if(srcPos >=0 && srcPos +  effectRect.size.width * spp <= width * height * spp)
                memcpy(effectData + desPos, resultData + srcPos, effectRect.size.width * spp);
        }
    }
    //remove target
    [imageInput removeAllTargets];
    if (distanceInput) {
        [distanceInput removeAllTargets];
    }
    
    for (int i = 0; i < m_filtersCount; i++)
    {
        [m_allFilters[i].filterInfo.gpuImageFilter removeAllTargets];
    }
    
    [imageInput release];
    [resultOut release];
    
    if (distanceInput)
    {
        [distanceInput release];
    }
    
    [g_lockGPUUse unlock];
    
    return effectData;
    
}

/*
// 做级联 根据filter输入纹理个数 有的要特殊处理  甚至从gpu出来 再进去
- (OUTPUT_DATA_INFO)getFilteredDataForSrcData:(INPUT_DATA_INFO)inputDataInfo
{
    //NSLog(@"getFilteredDataForSrcData %d",inputDataInfo.precision);
 
    [m_filterSourceLock lock];
 
    m_filterState = 1;
    if (inputDataInfo.precision == 1) {
        m_isProcessFull = YES;
    }else{
        m_isProcessFull = NO;
    }
 
    IMAGE_DATA imageData = [inputDataInfo.dataImage lockDataForRead];
 
    OUTPUT_DATA_INFO outDataInfo;
    outDataInfo.bAlphaPremultiplied = imageData.bAlphaPremultiplied;
    outDataInfo.nSpp = imageData.nSpp;
 
    int spp = imageData.nSpp;
    int fullWidth = imageData.nWidth;
    int fullHeight = imageData.nHeight;
    unsigned char *pBuffer = imageData.pBuffer;
 
    inputDataInfo.dirtyRect = CGRectIntersection(inputDataInfo.dirtyRect, CGRectMake(0, 0, fullWidth, fullHeight));
 
 
    CGRect needRect = [self getNeedInputRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
    CGRect effectRect = [self getEffectedRectForDirtyRect:inputDataInfo.dirtyRect fullSize:CGSizeMake(fullWidth, fullHeight)];
    
    float scale = MAX(inputDataInfo.sizeScale.width, inputDataInfo.sizeScale.height);
    
    
    needRect = CGRectIntegral(needRect);
    effectRect = CGRectIntegral(effectRect);
    
    unsigned char* rawData = nil; //dirty raw data, not scaled
    unsigned char* mallocRawData = nil;
    if (YES) //!CGRectEqualToRect(needRect, CGRectMake(0, 0, fullWidth, fullHeight))
    {
        mallocRawData = malloc(needRect.size.width * needRect.size.height * spp);
        for (int i = needRect.origin.y; i < needRect.origin.y + needRect.size.height; i++) {
            int srcPos = (i * fullWidth + needRect.origin.x) * spp;
            int desPos = ((i - needRect.origin.y) * needRect.size.width) * spp;
            memcpy(mallocRawData + desPos, pBuffer + srcPos, needRect.size.width * spp);
        }
        rawData = mallocRawData;
    }else{
        rawData = pBuffer;
    }
    
    [inputDataInfo.dataImage unLockDataForRead];
    
    if (![self getFilterIsValid]) {
        outDataInfo.bufferRect = needRect;
        outDataInfo.nSpp = spp;
        outDataInfo.pBuffer = rawData;
        outDataInfo.sizeScale = CGSizeMake(1.0, 1.0);
        outDataInfo.state = 0;
        
        m_isProcessFull = NO;
        [m_filterSourceLock unlock];
        return outDataInfo;
    }
    
    
    float bufferScale = 1.0;
    unsigned char *inputData = nil;
    unsigned char *mallocInputData = nil; //input data, scaled
    if (inputDataInfo.precision == 0)
    {
        float needScale = sqrtf(250000.0 / (needRect.size.width * needRect.size.height));
        if (scale < 0.99 || needScale < 0.99) {
            if ([self isCanScaleFilterParameter]) {
                bufferScale = MIN(scale, needScale);
                
                CGRect scaledNeedRect = [self CGRectCustomScale:needRect scale:bufferScale];
                mallocInputData = malloc(scaledNeedRect.size.width * scaledNeedRect.size.height * spp);
                [self resizeImageData:rawData srcWidth:needRect.size.width srcHeight:needRect.size.height toDesData:mallocInputData desWidth:scaledNeedRect.size.width desHeight:scaledNeedRect.size.height spp:spp];
                
                needRect = scaledNeedRect;
                effectRect = [self CGRectCustomScale:effectRect scale:bufferScale];
                
                inputData = mallocInputData;
                
            }
        }else{
            inputData = rawData;
        }
        
    }
    else if (inputDataInfo.precision == 1) //full
    {
        inputData = rawData;
    }
    
    
    //process data
    {
        [self setGPUImageFilterParamterInfoWithScale:bufferScale isFull:NO];
        //[self setFilterTextureWidth:1.0 / needRect.size.width height:1.0 / needRect.size.height isFull:isFull];
        
       
        float *distanceData = nil;
        GPUImageRawDataInput *distanceInput = nil;
        
        int width = needRect.size.width;
        int height = needRect.size.height;
        GPUImageRawDataInput *imageInput = [[GPUImageRawDataInput alloc] initWithBytes:inputData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatRGBA type:GPUPixelTypeUByte];
        GPUImageOutput *lastFilter = imageInput;
        for (int i = 0; i < m_filtersCount; i++) {
            SMART_FILTER_INFO *filterInfo = &m_allFilters[i];
            if (!filterInfo->isEnable) {
                continue;
            }
            if (![self getFilterIsValidAtIndex:i]) {
                continue;
            }
            if (m_filterState == 0) {
                break;
            }
            GPUImageFilter *currentFilter = nil;
            currentFilter = filterInfo->filterInfo.gpuImageFilter;
            switch (filterInfo->filterInfo.textureCount) {
                case 1:{
                    [lastFilter addTarget:currentFilter];
                }
                    break;
                    
                case 2:{
                    if ([filterInfo->filterInfo.filterName isEqualToString:@"Effect"]) {
                        unsigned char *realSrcData = inputData;
                        if (i != 0) {
                            GPUImageRawDataOutput *resultOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:NO];
                            [lastFilter addTarget:resultOut];
                            realSrcData = [resultOut rawBytesForImage];
                        }
                        
                        distanceData = (float*)malloc(width * height * sizeof(float));
                        if (m_filterState) {
                            NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
                            [m_distanceInfoManager computeDistanceFastWithImage:realSrcData srcDistance:distanceData originx:0 originy:0 width:width height:height srcWidth:width srcHeight:height spp:spp radius:MAX_DISTANCE_RADIUS distanceDes:distanceData extendInfo:15 effectState:&m_filterState];
                            NSLog(@"distancetime %f,%@,%d",[NSDate timeIntervalSinceReferenceDate] - begin, NSStringFromRect(needRect),m_filterState);
                        }
                        
                        
                        if (m_filterState) {
                            unsigned char* udistData = (unsigned char*)distanceData;
                            distanceInput = [[GPUImageRawDataInput alloc] initWithBytes:udistData size:CGSizeMake(width, height) pixelFormat:GPUPixelFormatLuminance type:GPUPixelTypeFloat];
                            
                            [lastFilter addTarget:currentFilter];
                            [distanceInput addTarget:currentFilter];
                            [distanceInput processData];
                            
                        }
                        
                        
                    }
                }
                    break;
                    
                case 3:{
                    
                }
                    break;
                    
                default:
                    break;
            }
            lastFilter = currentFilter;
        }
        [imageInput processData];
        GPUImageRawDataOutput *resultOut = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:NO];
        [lastFilter addTarget:resultOut];
        unsigned char *resultData = [resultOut rawBytesForImage];
        
        
        if (m_filterState)
        {
            CGRect outputIntRect = needRect;
            unsigned char *effectData = malloc(effectRect.size.width * effectRect.size.height * spp);
            for (int i = effectRect.origin.y; i < effectRect.origin.y + effectRect.size.height; i++) {
                int srcPos = ((i - outputIntRect.origin.y) * outputIntRect.size.width + (effectRect.origin.x - outputIntRect.origin.x)) * spp;
                int desPos = ((i - effectRect.origin.y) * effectRect.size.width) * spp;
                memcpy(effectData + desPos, resultData + srcPos, effectRect.size.width * spp);
            }
            outDataInfo.pBuffer = effectData;
        }else{
            outDataInfo.pBuffer = NULL;
        }
        
        outDataInfo.bufferRect = effectRect;
        outDataInfo.nSpp = spp;
        outDataInfo.sizeScale = CGSizeMake(bufferScale, bufferScale);
        if (m_filterState) {
            outDataInfo.state = 0;
            NSLog(@"outDataInfo.state0");
        }else{
            outDataInfo.state = 1;
            NSLog(@"outDataInfo.state1");
        }
        
        
        //remove target
        [imageInput removeAllTargets];
        if (distanceInput) {
            [distanceInput removeAllTargets];
        }
        for (int i = 0; i < m_filtersCount; i++) {
            [m_allFilters[i].filterInfo.gpuImageFilter removeAllTargets];
        }
        
        [imageInput release];
        [resultOut release];
        if (distanceInput) {
            [distanceInput release];
        }
        
        if (mallocRawData) {
            free(mallocRawData);
        }
        if (mallocInputData) {
            free(mallocInputData);
        }
        if (distanceData) {
            free(distanceData);
        }

    }
    
    NSLog(@"getFilteredDataForSrcData2 %@,%@",NSStringFromRect(needRect),NSStringFromRect(effectRect));
    
    m_isProcessFull = NO;
    [m_filterSourceLock unlock];
    
    return outDataInfo;
    
}
*/

- (void)cancleCurrentFullProcess
{
    if (m_isProcessFull) {
        m_filterState = 0;
    }
    //NSLog(@"cancleCurrentFullProcess");
}

- (void)resetBlockDataInfo
{
    for (int i = 0; i < m_blockCount; i++)
    {
        if (m_blockDataInfo[i].outputData)
        {
            free(m_blockDataInfo[i].outputData);
        }
    }
    
    m_blockCount = 0;
    
    if (m_blockDataInfo)
    {
        free(m_blockDataInfo);
        m_blockDataInfo = NULL;
    }
}

- (void)splitBigDataToSmall:(CGRect)dirtyRect fullSize:(CGSize)fullSize
{
    int blockWidth = 768;//1024*4;//768;  wzq
    int blockHeight = 768;//1024*4;//768;
    
    if (dirtyRect.size.width * dirtyRect.size.height > blockWidth * blockWidth)
    {
        int horCount = ceilf(dirtyRect.size.width / blockWidth);
        int verCount = ceilf(dirtyRect.size.height / blockHeight);
        
        m_blockCount = horCount * verCount;
        
        m_blockDataInfo = (BLOCK_DATA_INFO*)malloc(sizeof(BLOCK_DATA_INFO) * m_blockCount);
        
        for (int i = 0; i < horCount; i++)
        {
            for (int j = 0; j < verCount; j++)
            {
                CGRect blockRect = CGRectMake(dirtyRect.origin.x + i * blockWidth, dirtyRect.origin.y + j * blockHeight, blockWidth, blockHeight);
                blockRect = CGRectIntersection(blockRect, dirtyRect);
                m_blockDataInfo[j * horCount + i].dirtyRect = CGRectIntegral(blockRect);
                m_blockDataInfo[j * horCount + i].neededRect = CGRectIntegral([self getNeedInputRectForDirtyRect:blockRect fullSize:fullSize]);
                m_blockDataInfo[j * horCount + i].effectedRect = CGRectIntegral([self getEffectedRectForDirtyRect:blockRect fullSize:fullSize]);
            }
        }
        
    }
    else
    {
        m_blockCount = 1;
        
        m_blockDataInfo = (BLOCK_DATA_INFO*)malloc(sizeof(BLOCK_DATA_INFO) * m_blockCount);
        
        m_blockDataInfo[0].dirtyRect = CGRectIntegral(dirtyRect);
        m_blockDataInfo[0].neededRect = CGRectIntegral([self getNeedInputRectForDirtyRect:dirtyRect fullSize:fullSize]);
        m_blockDataInfo[0].effectedRect = CGRectIntegral([self getEffectedRectForDirtyRect:dirtyRect fullSize:fullSize]);
    }
}

- (void)combineBlockDataToBig:(CGRect)outputRect desData:(unsigned char*)desData spp:(int)spp
{
    for (int index = 0; index < m_blockCount; index++)
    {
        if (!m_blockDataInfo[index].outputData)
        {
            return;
        }
        
        CGRect effectRect = CGRectIntersection(m_blockDataInfo[index].effectedRect, outputRect);
        
        for (int i = effectRect.origin.y; i < effectRect.origin.y + effectRect.size.height; i++)
        {
            int srcPos = ((i - effectRect.origin.y) * effectRect.size.width) * spp;
            int desPos = (((i - outputRect.origin.y) * outputRect.size.width) + effectRect.origin.x - outputRect.origin.x) * spp;
            
            
            memcpy(desData + desPos, m_blockDataInfo[index].outputData + srcPos, effectRect.size.width * spp);
        }
    }
    
    [self resetBlockDataInfo];
}

#pragma mark -
#pragma mark undo event


//for undo/redo
- (void)filtersEditWillBegin
{
    [self saveFilterRecord];
}
- (void)filtersEditDidEnd
{
    [self makeUndoRecord];
}

- (void)filtersEditDidCancel
{
    //free new filters info
    if (m_allFilters)
    {
        for (int i = 0; i < m_filtersCount; i++)
        {
            if (m_allFilters[i].filterInfo.filterParameters)
            {
                free(m_allFilters[i].filterInfo.filterParameters);
//                [m_allFilters[i].filterInfo.gpuImageFilter release];
//                m_allFilters[i].filterInfo.gpuImageFilter = nil;
            }
        }
        
        free(m_allFilters);
        m_allFilters = NULL;
        m_filtersCount = 0;
    }
    
    m_allFilters = m_oldRecords.allFilters;
    m_filtersCount = m_oldRecords.filtersCount;
    
    m_oldRecords.allFilters = NULL;
    m_oldRecords.filtersCount = 0;
    [m_delegateForManager updateSmartFilterInterface];
}

- (void)saveFilterRecord
{
    if (m_oldRecords.allFilters)
    {
        for (int i = 0; i < m_oldRecords.filtersCount; i++)
        {
            if (m_oldRecords.allFilters[i].filterInfo.filterParameters)
            {
                free(m_oldRecords.allFilters[i].filterInfo.filterParameters);
//                [m_allFilters[i].filterInfo.gpuImageFilter release];
//                m_allFilters[i].filterInfo.gpuImageFilter = nil;
            }
        }
        
        free(m_oldRecords.allFilters);
    }
    
    m_oldRecords.allFilters = NULL;
    m_oldRecords.filtersCount = 0;
    
    //[m_filterSourceLock lock];
    
    SMART_FILTER_INFO *allFilters = malloc(sizeof(SMART_FILTER_INFO) * m_filtersCount);
    
    for (int i = 0; i < m_filtersCount; i++)
    {
        allFilters[i] = m_allFilters[i];
        //NSLog(@"ttt %@",m_allFilters[i].filterName);
        allFilters[i].filterName = [[NSString alloc] initWithString:m_allFilters[i].filterName];
        FILTER_PARAMETER_INFO *filterParameters = malloc(sizeof(FILTER_PARAMETER_INFO) * m_allFilters[i].filterInfo.parametersCount);
        memcpy(filterParameters, m_allFilters[i].filterInfo.filterParameters, sizeof(FILTER_PARAMETER_INFO) * m_allFilters[i].filterInfo.parametersCount);
        
        allFilters[i].filterInfo.filterParameters = filterParameters;
    }
    //[m_filterSourceLock unlock];
    
    m_oldRecords.allFilters = allFilters;
    m_oldRecords.filtersCount = m_filtersCount;
}

- (int)makeUndoRecord
{
    if (!m_undoRecords)
    {
        m_undoRecords = (UndoRecordForSmartFilter*)malloc(kNumberOfUndoRecordsPerMalloc * sizeof(UndoRecordForSmartFilter));
        m_undoRecordsMaxLen = kNumberOfUndoRecordsPerMalloc;
    }
    else
    {
        if (m_undoRecordsCount >= m_undoRecordsMaxLen)
        {
            m_undoRecordsMaxLen += kNumberOfUndoRecordsPerMalloc;
            m_undoRecords = (UndoRecordForSmartFilter*)realloc(m_undoRecords, m_undoRecordsMaxLen * sizeof(UndoRecordForSmartFilter));
        }
    }
    
    m_undoRecords[m_undoRecordsCount].allFilters = m_oldRecords.allFilters;
    m_undoRecords[m_undoRecordsCount].filtersCount = m_oldRecords.filtersCount;
    
    m_oldRecords.allFilters = NULL;
    m_oldRecords.filtersCount = 0;
    
    [[[m_delegateForManager getUndoManager] prepareWithInvocationTarget:self] undoEffectForRecord:m_undoRecordsCount];
    
    m_undoRecordsCount++;
    return m_undoRecordsCount - 1;
}

- (void)undoEffectForRecord:(int)index
{
    [m_filterSourceLock lock];
    
    UndoRecordForSmartFilter oldRecord = m_undoRecords[index];
    m_undoRecords[index].allFilters = m_allFilters;
    m_undoRecords[index].filtersCount = m_filtersCount;
    
    [[[m_delegateForManager getUndoManager] prepareWithInvocationTarget:self] undoEffectForRecord:index];
    m_allFilters = oldRecord.allFilters;
    m_filtersCount = oldRecord.filtersCount;
    
    [m_filterSourceLock unlock];
    
    [m_delegateForManager updateSmartFilterInterface];
    [m_delegateForManager refreshTotalToRender];

}


#pragma mark -
#pragma mark assistant function
- (BOOL)isHasEffect
{
    int filterIndex = [self getSmartFiltersCount] - 2;
    FILTER_PARAMETER_INFO paraInfo = [self getSmartFilterParameterInfo:filterIndex parameterName:[@"strokeEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [self getSmartFilterParameterInfo:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [self getSmartFilterParameterInfo:filterIndex parameterName:[@"innerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    paraInfo = [self getSmartFilterParameterInfo:filterIndex parameterName:[@"outerGlowEnable" UTF8String]];
    if (paraInfo.value.nIntValue == 1) {
        return YES;
    }
    
    return NO;
}

- (CGRect)getNeedInputRectForDirtyRect:(CGRect)srcRect fullSize:(CGSize)fullSize
{
    CGRect desRect = srcRect;
    
    float extension = 0;
    for (int i = 0; i < m_filtersCount; i++)
    {
        if (!m_allFilters[i].isEnable)
        {
            continue;
        }
        if (![self getFilterIsValidAtIndex:i])
        {
            continue;
        }
        
        FILTER_PARAMETER_INFO *filterParameters = m_allFilters[i].filterInfo.filterParameters;
        int parametersCount = m_allFilters[i].filterInfo.parametersCount;
        
        for (int i = 0; i < parametersCount; i++)
        {
            //NSLog(@"nama %@",[NSString stringWithCString:filterParameters[i].parameterName encoding:NSASCIIStringEncoding]);
            switch (filterParameters[i].nNeedExtensionType)
            {
                case 0:
                    break;
                    
                case 1:
                {
                    if (filterParameters[i].parameterType == V_INT)
                    {
                        extension = MAX(filterParameters[i].value.nIntValue, extension);
                    }
                    else if (filterParameters[i].parameterType == V_FLOAT)
                    {
                        extension = MAX(filterParameters[i].value.fFloatValue, extension);
                    }
                }
                    break;
                    
                case 2:
                    if (filterParameters[i].parameterType == V_INT)
                    {
                        extension = MAX(filterParameters[i].value.nIntValue * 2, extension);
                    }
                    else if (filterParameters[i].parameterType == V_FLOAT)
                    {
                        extension = MAX(filterParameters[i].value.fFloatValue * 2, extension);
                    }
                    break;
                    
                case 10:
                    return CGRectMake(0, 0, fullSize.width, fullSize.height);
                    break;
                    
                default:
                    break;
            }
        }
        
        if (i == 0)
        { //距离变换扩张
            extension += 10.0;
        }
    }
    
    extension += 2.0;
    desRect.origin.x -= extension;
    desRect.origin.y -= extension;
    desRect.size.width += 2 * extension;
    desRect.size.height += 2 * extension;
    desRect = CGRectIntersection(desRect, CGRectMake(0, 0, fullSize.width, fullSize.height));
    
    return desRect;
}

- (CGRect)getEffectedRectForDirtyRect:(CGRect)srcRect fullSize:(CGSize)fullSize
{
    CGRect desRect = srcRect;
    float extension = 0;
    
    for (int i = 0; i < m_filtersCount; i++)
    {
        if (!m_allFilters[i].isEnable)
        {
            continue;
        }
        
        if (![self getFilterIsValidAtIndex:i])
        {
            continue;
        }
        
        FILTER_PARAMETER_INFO *filterParameters = m_allFilters[i].filterInfo.filterParameters;
        int parametersCount = m_allFilters[i].filterInfo.parametersCount;
        for (int i = 0; i < parametersCount; i++)
        {
            switch (filterParameters[i].nEffectExtensionType)
            {
                case 0:
                    break;
                    
                case 1:
                {
                    if (filterParameters[i].parameterType == V_INT)
                    {
                        extension = MAX(filterParameters[i].value.nIntValue, extension);
                    }
                    else if (filterParameters[i].parameterType == V_FLOAT)
                    {
                        extension = MAX(filterParameters[i].value.fFloatValue, extension);
                    }
                }
                    break;
                    
                case 2:
                    if (filterParameters[i].parameterType == V_INT)
                    {
                        extension = MAX(filterParameters[i].value.nIntValue * 2, extension);
                    }
                    else if (filterParameters[i].parameterType == V_FLOAT)
                    {
                        extension = MAX(filterParameters[i].value.fFloatValue * 2, extension);
                    }
                    
                    break;
                    
                case 10:
                    return CGRectMake(0, 0, fullSize.width, fullSize.height);
                    break;
                    
                default:
                    break;
            }
        }
    }
    
    extension += 1.0;
    desRect.origin.x -= extension;
    desRect.origin.y -= extension;
    desRect.size.width += 2 * extension;
    desRect.size.height += 2 * extension;
    desRect = CGRectIntersection(desRect, CGRectMake(0, 0, fullSize.width, fullSize.height));
    
    return desRect;
}

- (BOOL)getFilterIsValid
{
    for (int i = 0; i < m_filtersCount; i++)
    {
        if ([self getFilterIsValidAtIndex:i])
        {
            return YES;
        }
    }
    
    return NO;
}

//应该根据参数自动计算,以后优化
- (BOOL)getFilterIsValidAtIndex:(int)filterIndex
{
    if (filterIndex >= m_filtersCount || (filterIndex < 0))
    {
        return NO;
    }
    
    return [m_allFilters[filterIndex].filterInfo.gpuImageFilter getFilterIsValid];
}

- (BOOL)isCanScaleFilterParameter
{
    for (int i = 0; i < m_filtersCount; i++)
    {
        if (!m_allFilters[i].isEnable)
        {
            continue;
        }
        
        int parametersCount = m_allFilters[i].filterInfo.parametersCount;
        FILTER_PARAMETER_INFO *filterParameters = m_allFilters[i].filterInfo.filterParameters;
        
        for (int i = 0; i < parametersCount; i++)
        {
            if (filterParameters[i].nScaleType == 10)
            {
                return NO;
            }
        }
        
    }
    
    return YES;
    
}

- (void)setGPUImageFilterParamterInfoWithScale:(float)scale isFull:(BOOL)isFull
{
    for (int i = 0; i < m_filtersCount; i++)
    {
        if (!m_allFilters[i].isEnable)
        {
            continue;
        }
        
        GPUImageOutput *filter = m_allFilters[i].filterInfo.gpuImageFilter;
        
        int parametersCount = m_allFilters[i].filterInfo.parametersCount;
        FILTER_PARAMETER_INFO *filterParameters = (FILTER_PARAMETER_INFO *) malloc(sizeof(FILTER_PARAMETER_INFO) * parametersCount);
        
        memcpy(filterParameters, m_allFilters[i].filterInfo.filterParameters, sizeof(FILTER_PARAMETER_INFO) * parametersCount);
        
        for (int i = 0; i < parametersCount; i++)
        {
            if (filterParameters[i].nScaleType == 1)
            {
                switch (filterParameters[i].parameterType)
                {
                    case V_INT:
                        filterParameters[i].value.nIntValue = filterParameters[i].value.nIntValue * scale;
                        break;
                        
                    case V_FLOAT:
                        filterParameters[i].value.fFloatValue = filterParameters[i].value.fFloatValue * scale;
                        break;
                        
                    default:
                        break;
                }
                
            }
        }
        
        [filter setFilterParameter:filterParameters parameterCount:parametersCount];
        free(filterParameters);
        
    }

}

inline CGRect CGRectCustomScale(CGRect srcRect, float scale)
{
    CGRect desRect = srcRect;
    desRect.origin.x *= scale;
    desRect.origin.y *= scale;
    desRect.size.width *= scale;
    desRect.size.height *= scale;
    desRect = CGRectIntegral(desRect);
    
    return desRect;
}

- (CGRect)CGRectCustomScale:(CGRect)srcRect scale:(float)scale
{
    CGRect desRect = srcRect;
    
    desRect.origin.x *= scale;
    desRect.origin.y *= scale;
    desRect.size.width *= scale;
    desRect.size.height *= scale;
    desRect = CGRectIntegral(desRect);
    
    return desRect;
}

- (void)resizeImageData:(unsigned char*)srcData srcWidth:(int)srcWidth srcHeight:(int)srcHeight toDesData:(unsigned char*)desData desWidth:(int)desWidth desHeight:(int)desHeight spp:(int)spp
{
    CGColorSpaceRef defaultColorSpace = ((spp == 4) ? CGColorSpaceCreateDeviceRGB() : CGColorSpaceCreateDeviceGray());

    CGContextRef bitmapContext = CGBitmapContextCreate(desData, desWidth, desHeight, 8, spp * desWidth, defaultColorSpace, kCGImageAlphaPremultipliedLast);
    assert(bitmapContext);
    
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(self, srcData, srcWidth * srcHeight * spp, NULL);
    assert(dataProvider);
    CGImageRef cgImage = CGImageCreate(srcWidth, srcHeight, 8, 8 * spp, srcWidth * spp, defaultColorSpace, kCGImageAlphaLast | kCGBitmapByteOrderDefault, dataProvider, NULL, NO, kCGRenderingIntentDefault);
    assert(cgImage);
    
    CGContextClearRect(bitmapContext, CGRectMake(0, 0, desWidth, desHeight));
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, desWidth, desHeight), cgImage);
    
    CGColorSpaceRelease(defaultColorSpace);
    CGContextRelease(bitmapContext);
    CGDataProviderRelease(dataProvider);
    CGImageRelease(cgImage);
}


@end


