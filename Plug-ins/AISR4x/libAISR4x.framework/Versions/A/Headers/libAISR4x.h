//
//  libAISR4x.h
//  libAISR4x
//
//  Created by apple on 1/22/22.
//

#import <Foundation/Foundation.h>

//! Project version number for roboHumanMatting.
//FOUNDATION_EXPORT double libAISR4xVersionNumber;

//! Project version string for roboHumanMatting.
//FOUNDATION_EXPORT const unsigned char libAISR4xVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <roboHumanMatting/PublicHeader.h>

typedef void (*FOURXPROGRESSCallback) (float progress, void *pData);

@interface libAISR4x : NSObject

- (void)loadModel;
-(int)predictImage:(unsigned char *)imageBGRA width:(int)width height:(int)height outImage:(unsigned char *)outBGRA4x  outProgress:(FOURXPROGRESSCallback)ProgressCB callbackData:(void *)pData;

@end
