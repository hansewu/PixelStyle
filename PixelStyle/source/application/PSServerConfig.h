//
//  PSServerConfig.h
//  PixelStyle
//
//  Created by wyl on 16/2/25.
//
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface PSServerConfig : NSObject

+ (PSServerConfig *)ShareInstance;
- (void)checkClientVersion;

@end
