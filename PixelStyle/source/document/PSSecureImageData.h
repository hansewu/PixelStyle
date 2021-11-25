//
//  PSSecureImageData.h
//  PixelStyle
//
//  Created by wzq on 15/11/20.
//
//

#import <Foundation/Foundation.h>

typedef struct
{
    int             nWidth;
    int             nHeight;
    int             nSpp;
    int             bAlphaPremultiplied;
    unsigned char  *pBuffer;
}IMAGE_DATA;

@interface PSSecureImageData : NSObject
{
    IMAGE_DATA      m_imageData;
    
    volatile int             m_nReadLockCount;
    NSRecursiveLock   *m_lockRead;
    NSRecursiveLock          *m_lockWrite;
}
//初始化
-(id)initData:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied;
-(id)initDataWithBuffer:(unsigned char *)pBuffer width:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied;
-(void)reInitData:(int)nWidth height:(int)nHeight spp:(int)nSpp alphaPremultiplied:(int)bAlphaPremultiplied;
-(void)reInitDataWithBuffer:(unsigned char *)pBuffer width:(int)nWidth height:(int)nHeight spp:(int)nSpp  alphaPremultiplied:(int)bAlphaPremultiplied;
-(void)copyFrom:(PSSecureImageData *)dataImage;
-(void)transferFrom:(PSSecureImageData *)dataImage;

-(void)copyFromAndExpand:(PSSecureImageData *)dataImage expand:(int)nRadius;

//返回m_pBuffer  允许多次 read lock,访问一次m_nReadLockCount++  但只有等到write lock解锁才能返回
-(IMAGE_DATA)lockDataForRead;
//m_nReadLockCount--
-(void)unLockDataForRead;

//返回m_pBuffer  同时只允许一个线程在写 但仍然可以读
-(IMAGE_DATA)lockDataForWrite;
//解写锁
-(void)unLockDataForWrite;

//没有谁读的时候返回
-(IMAGE_DATA)lockDataForWriteSecure;
-(void)unLockDataForWriteSecure;

-(IMAGE_DATA)lockAndTransferData;
@end