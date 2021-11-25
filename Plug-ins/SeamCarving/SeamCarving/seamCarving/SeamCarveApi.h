//
//  SeamCarveApi.h
//
//  Created by wyl on 8/11/16.
//  Copyright © 2016 effectmatrix. All rights reserved.
//

#ifndef SeamCarveApi_h
#define SeamCarveApi_h

typedef struct
{
    int             nWidth;
    int             nHeight;
    int             nChannels;
    unsigned char  *pData;
}IMAGE_DATA;

//3 通道或者4通道
#ifdef __cplusplus
extern "C"
{
#endif
    /*pHorizontalSeamsData  
     pHorizontalSeamsData.nWidth = pInputData.nWidth;
     pHorizontalSeamsData.nHeight = pInputData.nHeight;
     pHorizontalSeamsData.nChannels = 1;
     */
    
    /*pVerticalSeamsData
     pVerticalSeamsData.nWidth = pInputData.nWidth;
     pVerticalSeamsData.nHeight = pOutputData.nHeight;
     pVerticalSeamsData.nChannels = 1;
     */
    //seamcarveImage 算法先进行HorizontalSeams计算，后进行VerticalSeams计算
    int seamcarveImage(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData, IMAGE_DATA *pOutputHorizontalSeamsData, IMAGE_DATA *pOutputVerticalSeamsData);
    
    /*pHorizontalSeamsData
     pHorizontalSeamsData.nWidth = pInputData.nWidth;
     pHorizontalSeamsData.nHeight = pInputData.nHeight;
     pHorizontalSeamsData.nChannels = 1;
     */
    
    /*pVerticalSeamsData
     pVerticalSeamsData.nWidth = pInputData.nWidth;
     pVerticalSeamsData.nHeight = pOutputData.nHeight;
     pVerticalSeamsData.nChannels = 1;
     */
    //resizeImageWithSeams 算法先进行HorizontalSeams计算，后进行VerticalSeams计算
    int resizeImageWithSeams(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData , IMAGE_DATA *pHorizontalSeamsData, IMAGE_DATA *pVerticalSeamsData);
    void stopSeamcarveImage(bool bStop);
    
    /*
    INTER_NEAREST=0, //!< nearest neighbor interpolation
    INTER_LINEAR=1, //!< bilinear interpolation
    INTER_CUBIC=2, //!< bicubic interpolation
    INTER_AREA=3, //!< area-based (or super) interpolation
    INTER_LANCZOS4=4, //!< Lanczos interpolation over 8x8 neighborhood
    INTER_MAX=7,
    WARP_INVERSE_MAP=16
     */
    int resizeImage(IMAGE_DATA *pInputData, IMAGE_DATA *pOutputData, int nInterpolation);
#ifdef __cplusplus
}
#endif

#endif /* SeamCarveApi_h */
