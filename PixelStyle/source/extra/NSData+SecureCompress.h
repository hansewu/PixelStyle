//
//  NSData+SecureCompress.h
//  PixelStyle
//
//  Created by lchzh on 6/20/16.
//
//

#import <Foundation/Foundation.h>

#import "PSSecureImageData.h"

@interface NSData (SecureCompress)

+ (NSData *)compressSecureData:(PSSecureImageData*)secureData;

@end
