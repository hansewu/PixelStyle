//
//  GlobalDefine.h
//  GraphicsMagickImporter
//
//  Created by lchzh on 6/7/17.
//  Copyright © 2017 lchzh. All rights reserved.
//

#ifndef GlobalDefine_h
#define GlobalDefine_h

//图像buffer数据
typedef struct GM_IMAGE_BUFFER
{
    int nWidth;
    int nHeight;
    int nChannel;
    unsigned char *pBuffer;
}GM_IMAGE_BUFFER;

typedef struct GM_FORMAT_INFO
{
    char name[512];
    char description[512];
    bool readable;
    bool writeable;
    bool multiframe;
}GM_FORMAT_INFO;

typedef struct GM_LAYER_INFO
{
    int nWidth;
    int nHeight;
    int nChannel;
    unsigned char *pBuffer;
    int nXOffset;
    int nYOffset;
}GM_LAYER_INFO;

typedef struct GM_DOCUMENT_INFO
{
    int nWidth;
    int nHeight;
    int nLayerCount;
    int m_nXres;
    int m_nYres;
}GM_DOCUMENT_INFO;

#endif /* GlobalDefine_h */
