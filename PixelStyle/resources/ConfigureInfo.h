//
//  ConfigureInfo.h
//  PixelStyle
//
//  Created by wyl on 15/12/3.
//
//

#ifndef ConfigureInfo_h
#define ConfigureInfo_h


#define TEXT_COLOR                     [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.85]
#define TEXT_BACKGROUND_COLOR          [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5]
#define WINDOW_TITLE_BAR_BEGIN_COLOR   [NSColor colorWithDeviceRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]
#define WINDOW_TITLE_BAR_END_COLOR     [NSColor colorWithDeviceRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1.0]
//#define BACKGROUND_COLOR

#define TEXT_FONT_SIZE 11
#define TITLE_FONT_SIZE 12



#ifdef PROPAINT_VERSION
#define URL_BUY                     @"https://checkout.bluesnap.com/buynow/checkout?sku3319670=1&storeid=48664"
#define URL_FORUM                   @"http://www.effectmatrix.com/forum/viewforum.php?f=54"
#define URL_PRODUCT                 @"http://www.effectmatrix.com/mac-appstore/pro-paint-for-mac-tool.htm"
#define URL_WEB_CONFIG_INFO         @"http://www.effectmatrix.com/PixelStyle/ProPaintAppServerConfig.xml"
#define  README_FILE    @"readme_propaint.rtfd"
#define APPLE_ID                    1127869373
#define REGISTER_PUBLIC_KEY         {0x67,0xb4,0xbe,0xdf,0xdc,0xeb,0xd1,0x66,0xee,0xd4,0xd2,0x27,0xc4,0xff,0x04,0x9c,0x43,0x41,0xca,0x95,0x93,0x9b,0x27,0xdb,0xf5,0x5a,0xbf,0x15}

#elif defined PROPAINT_FREE

#define URL_BUY                     @"https://www.bluesnap.com/jsp/buynow.jsp?contractId=3319670"
#define URL_FORUM                   @"http://www.effectmatrix.com/forum/viewforum.php?f=54"
#define URL_PRODUCT                 @"http://www.effectmatrix.com/mac-appstore/pro-paint-for-mac-tool.htm"
#define URL_WEB_CONFIG_INFO         @"http://www.effectmatrix.com/PixelStyle/ProPaintAppServerConfig.xml"
#define     README_FILE     @"readme_propaint.rtfd"
#define APPLE_ID                    1127869373
#define REGISTER_PUBLIC_KEY         {0x67,0xb4,0xbe,0xdf,0xdc,0xeb,0xd1,0x66,0xee,0xd4,0xd2,0x27,0xc4,0xff,0x04,0x9c,0x43,0x41,0xca,0x95,0x93,0x9b,0x27,0xdb,0xf5,0x5a,0xbf,0x15}

#elif defined FREE_VERSION
#define URL_BUY                     @"https://www.bluesnap.com/jsp/buynow.jsp?contractId=1695191"
#define URL_FORUM                   @"http://www.effectmatrix.com/forum/viewforum.php?f=5&sid=2724153edd90697789f99d4ea080bb84"
#define URL_PRODUCT                 @"http://www.effectmatrix.com/mac-appstore/mac-photo-editor-pixelstyle.htm"
#define URL_WEB_CONFIG_INFO         @"http://www.effectmatrix.com/PixelStyle/PixelStyleAppServerConfig.xml"
#define README_FILE                 @"readme.rtfd"
#define APPLE_ID                    1244649277
#define REGISTER_PUBLIC_KEY         {0xc6,0x32,0xe8,0x14,0x59,0xd2,0x23,0xe7,0x6f,0x79,0x36,0x3b,0x4d,0xa3,0xc0,0xf7,0x86,0x5c,0xc6,0xbc,0x19,0x57,0x99,0xa1,0x5a,0x40,0xcc,0x3d}
#else
#define URL_BUY                     @"https://checkout.bluesnap.com/buynow/checkout?sku1695191=1&storeid=48664"
#define URL_FORUM                   @"http://www.effectmatrix.com/forum/viewforum.php?f=5&sid=2724153edd90697789f99d4ea080bb84"
#define URL_PRODUCT                 @"http://www.effectmatrix.com/mac-appstore/mac-photo-editor-pixelstyle.htm"
#define URL_WEB_CONFIG_INFO         @"http://www.effectmatrix.com/PixelStyle/PixelStyleAppServerConfig.xml"
#define README_FILE                 @"readme.rtfd"
#define APPLE_ID                    1127869373
#define REGISTER_PUBLIC_KEY         {0xc6,0x32,0xe8,0x14,0x59,0xd2,0x23,0xe7,0x6f,0x79,0x36,0x3b,0x4d,0xa3,0xc0,0xf7,0x86,0x5c,0xc6,0xbc,0x19,0x57,0x99,0xa1,0x5a,0x40,0xcc,0x3d}

#endif

#endif /* ConfigureInfo_h */
