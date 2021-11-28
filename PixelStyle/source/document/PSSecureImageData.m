//
//  PSSecureImageData.m
//  PixelStyle
//
//  Created by wzq on 15/11/20.
//
//

#import "PSSecureImageData.h"

@implementation PSSecureImageData

-(id)initData:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied
{
    self = [super init];
    m_lockRead  = [[NSRecursiveLock alloc] init];
    m_lockWrite = [[NSRecursiveLock alloc] init];
    
    if(nWidth * nHeight != 0)
        m_imageData.pBuffer = (unsigned char *)malloc((nWidth * nHeight * nSpp + 15)/16*16);//128 bit operator such as _mm_srli_epi32
    else m_imageData.pBuffer =  NULL;
    
    m_nReadLockCount                = 0;
    m_imageData.nWidth              = nWidth;
    m_imageData.nHeight             = nHeight;
    m_imageData.nSpp                = nSpp;
    m_imageData.bAlphaPremultiplied = bAlphaPremultiplied;
    
    return self;
}

-(id)initDataWithBuffer:(unsigned char *)pBuffer width:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied
{
    self = [super init];
    m_lockRead  = [[NSRecursiveLock alloc] init];
    m_lockWrite = [[NSRecursiveLock alloc] init];
    
    [self reInitDataWithBuffer:pBuffer width:nWidth height:nHeight spp:nSpp alphaPremultiplied:bAlphaPremultiplied];
    
    return self;
}

-(void)dealloc
{
    [m_lockWrite lock];
    [m_lockRead lock];
    [m_lockWrite unlock];
    [m_lockRead unlock];
    
    [m_lockWrite release];
    [m_lockRead release];
    
    if(m_imageData.pBuffer)
        free(m_imageData.pBuffer);
    
    [super dealloc];
}

-(void)reInitData:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied
{
    [self lockDataForWriteSecure];
    
    if(m_imageData.nWidth != nWidth || m_imageData.nHeight != nHeight || m_imageData.nSpp != nSpp)
    {
        if(m_imageData.pBuffer)
            free(m_imageData.pBuffer);
        
        m_imageData.pBuffer = (unsigned char *)malloc((nWidth * nHeight * nSpp + 15)/16*16);
        
        m_nReadLockCount    = 0;
        m_imageData.nWidth              = nWidth;
        m_imageData.nHeight             = nHeight;
        m_imageData.nSpp                = nSpp;
        m_imageData.bAlphaPremultiplied = bAlphaPremultiplied;
    }
    
    [self unLockDataForWriteSecure];
}

-(void)reInitDataWithBuffer:(unsigned char *)pBuffer width:(int)nWidth height:(int)nHeight spp:(int)nSpp  alphaPremultiplied:(int)bAlphaPremultiplied
{
    [self lockDataForWriteSecure];
    
    {
        if(m_imageData.pBuffer)
            free(m_imageData.pBuffer);
        
        m_imageData.pBuffer = pBuffer;
        
        m_nReadLockCount    = 0;
        m_imageData.nWidth            = nWidth;
        m_imageData.nHeight           = nHeight;
        m_imageData.nSpp              = nSpp;
        m_imageData.bAlphaPremultiplied = bAlphaPremultiplied;
    }
    
    [self unLockDataForWriteSecure];
}

-(void)copyFrom:(PSSecureImageData *)dataImage
{
    [self lockDataForWriteSecure];
    
    IMAGE_DATA imageFrom = [dataImage lockDataForRead];
    
    if(imageFrom.nWidth != m_imageData.nWidth || m_imageData.nHeight != imageFrom.nHeight)
    {
        if(m_imageData.pBuffer)
            free(m_imageData.pBuffer);
        
        m_imageData.pBuffer = (unsigned char *)malloc((imageFrom.nWidth * imageFrom.nHeight * imageFrom.nSpp + 15)/16*16);
        
        m_nReadLockCount                    = 0;
        m_imageData.nWidth                  = imageFrom.nWidth;
        m_imageData.nHeight                 = imageFrom.nHeight;
        m_imageData.nSpp                    = imageFrom.nSpp;
        m_imageData.bAlphaPremultiplied     = imageFrom.bAlphaPremultiplied;
    }
    
    memcpy(m_imageData.pBuffer, imageFrom.pBuffer, imageFrom.nWidth * imageFrom.nHeight * imageFrom.nSpp);
    
    [dataImage unLockDataForRead];
    
    [self unLockDataForWriteSecure];
}

-(void)copyFromAndExpand:(PSSecureImageData *)dataImage expand:(int)nRadius
{
    [self lockDataForWriteSecure];
    
    IMAGE_DATA imageFrom = [dataImage lockDataForRead];
    
    if(imageFrom.nWidth + 2*nRadius != m_imageData.nWidth || imageFrom.nHeight + 2*nRadius != m_imageData.nHeight   )
    {
        if(m_imageData.pBuffer)
            free(m_imageData.pBuffer);
        
        m_imageData.pBuffer = (unsigned char *)malloc(((imageFrom.nWidth+ 2*nRadius) * (imageFrom.nHeight+ 2*nRadius) * imageFrom.nSpp + 15)/16*16);
        
        m_nReadLockCount                    = 0;
        m_imageData.nWidth                  = imageFrom.nWidth+ 2*nRadius;
        m_imageData.nHeight                 = imageFrom.nHeight+ 2*nRadius;
        m_imageData.nSpp                    = imageFrom.nSpp;
        m_imageData.bAlphaPremultiplied     = imageFrom.bAlphaPremultiplied;
    }
    
    memset(m_imageData.pBuffer, 0, m_imageData.nWidth * m_imageData.nSpp * nRadius);
    memset(m_imageData.pBuffer + (imageFrom.nHeight+ nRadius) * m_imageData.nWidth * m_imageData.nSpp, 0, m_imageData.nWidth * m_imageData.nSpp * nRadius);
    
    for(int y=0; y< imageFrom.nHeight; y++)
    {
        unsigned char *pLine = m_imageData.pBuffer + (y+nRadius) *m_imageData.nWidth* m_imageData.nSpp;
        memset(pLine, 0, nRadius * imageFrom.nSpp);
        memcpy(pLine + nRadius * imageFrom.nSpp, imageFrom.pBuffer+y*imageFrom.nWidth* imageFrom.nSpp, imageFrom.nWidth * imageFrom.nSpp);
        memset(pLine + (nRadius+ imageFrom.nWidth) * imageFrom.nSpp, 0, nRadius * imageFrom.nSpp);
    }
    
    [dataImage unLockDataForRead];
    
    [self unLockDataForWriteSecure];
}

-(void)transferFrom:(PSSecureImageData *)dataImage
{
    [self lockDataForWriteSecure];
    
    IMAGE_DATA imageFrom = [dataImage lockAndTransferData];
    
    if(m_imageData.pBuffer)
        free(m_imageData.pBuffer);
    m_imageData = imageFrom;
    
     [self unLockDataForWriteSecure];
}

-(void)readLock
{
     [m_lockWrite lock];
    return;
  //  [m_lockWrite lock]; //没有在写，才能读
  /*
    if(m_nReadLockCount >= 1)
        m_nReadLockCount++;
    else
    {*/
  //      m_nReadLockCount++;
   //     [m_lockRead lock];
 //   }
    
  //  [m_lockWrite unlock];
  //  printf("lock %d\n", m_nReadLockCount);
}

-(void)readUnlock
{
    [m_lockWrite unlock];
    return;
   
    /*if(m_nReadLockCount <= 0)
        assert(false);
    
 //   if(m_nReadLockCount >= 1)
        m_nReadLockCount--;
    
 //   if(m_nReadLockCount == 0)
        [m_lockRead unlock];
    
    printf("unlock %d\n", m_nReadLockCount);*/
}

-(IMAGE_DATA)lockAndTransferData
{
    IMAGE_DATA imageData;
    
    [self lockDataForWriteSecure];
    imageData = m_imageData;
    
    m_imageData.nWidth = 0;
    m_imageData.nHeight = 0;
    m_imageData.nSpp = 0;
    m_imageData.pBuffer = NULL;
    [self unLockDataForWriteSecure];
    
    return imageData;
}

-(IMAGE_DATA)lockDataForRead
{
    [self readLock];
    return m_imageData;
}

-(void)unLockDataForRead
{
    [self readUnlock];
}

-(IMAGE_DATA)lockDataForWrite
{
    
    [m_lockWrite lock];
    return m_imageData;
}

-(void)unLockDataForWrite
{
    [m_lockWrite unlock];
}


-(IMAGE_DATA)lockDataForWriteSecure
{
  //  [m_lockRead lock];
    [m_lockWrite lock];
    
     return m_imageData;
}

-(void)unLockDataForWriteSecure
{
  //  [m_lockRead unlock];
    [m_lockWrite unlock];
}

@end
