//
//  NSData+SecureCompress.m
//  PixelStyle
//
//  Created by lchzh on 6/20/16.
//
//

#import "NSData+SecureCompress.h"
#import <zlib.h>

@implementation NSData (SecureCompress)

+ (NSData *)compressSecureData:(PSSecureImageData*)secureData
{
    
    IMAGE_DATA ImageData = [secureData lockDataForRead];
    NSData *layerData = [NSData dataWithBytes:ImageData.pBuffer length:ImageData.nWidth * ImageData.nHeight * ImageData.nSpp];
    assert(layerData);
    
    if ([layerData length] == 0) {
        return layerData;
    }
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[layerData bytes];
    strm.avail_in = (uInt) [layerData length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        return nil;
    }
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    //NSTimeInterval begin = [NSDate timeIntervalSinceReferenceDate];
    do {
        if (strm.total_out >= [compressed length]) {
            [compressed increaseLengthBy: 16384];
        }
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt) ([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        //NSLog(@"length %ld",[compressed length]);
        
        [secureData unLockDataForRead];
        [NSThread sleepForTimeInterval:0.01];
        [secureData lockDataForRead];
        
    } while (strm.avail_out == 0);
    
    //NSLog(@"timeendoce2 %f", [NSDate timeIntervalSinceReferenceDate] - begin);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    
    [secureData unLockDataForRead];
    
    return [NSData dataWithData:compressed];
}

@end
