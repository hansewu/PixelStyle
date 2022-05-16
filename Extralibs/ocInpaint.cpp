//
//  ocInpaint.cpp
//  PixelStyle
//
//  Created by apple on 2022/4/19.
//

#include "ocInpaint.h"
#include <opencv2/imgproc.hpp>
#include <opencv2/photo.hpp>

using namespace cv;
/*
int ocInpaint(unsigned char *pBuffer, unsigned char *pMask, int nWidth, int nHeight)
{
    cv::Mat_<cv::Vec4b> cvImage = cv::Mat(nHeight, nWidth, CV_8UC4, pBuffer);
    cv::Mat cvMask = cv::Mat(nHeight, nWidth, CV_8UC1, pMask);
    cv::Mat cvImage1, cvRes;
    
    cv::cvtColor(cvImage, cvImage1, cv::COLOR_RGBA2RGB);
    inpaint(cvImage1, cvMask, cvRes, 3, INPAINT_TELEA);//INPAINT_NS);//
    cv::cvtColor(cvRes, cvImage1, cv::COLOR_RGB2RGBA);
    
    memcpy(pBuffer, cvImage1.data, nHeight*nWidth*4);
    
    return 0;
}
*/
int patchMatchInpaint(cv::Mat &matImage, cv::Mat &matMask, cv::Mat &matOutImage);
void criminisiInpaint(
    cv::InputArray image,
    cv::InputArray targetMask,
    cv::InputArray sourceMask,
                      int patchSize);

int ocInpaint(unsigned char *pBuffer, unsigned char *pMaskAlpha, int nWidth, int nHeight, int nFillType)
{
    cv::Mat_<cv::Vec4b> cvImage = cv::Mat(nHeight, nWidth, CV_8UC4, pBuffer);
    unsigned char *pMask = new unsigned char[nHeight *nWidth];
    for(int i=0; i< nHeight *nWidth; i++)
        pMask[i] = pMaskAlpha[2*i];
    cv::Mat cvMask = cv::Mat(nHeight, nWidth, CV_8UC1, pMask);
    cv::Mat cvImage1, cvRes;
    
    cv::cvtColor(cvImage, cvImage1, cv::COLOR_RGBA2RGB);
    
    cv::Mat cvSMask;
    
    if(nFillType==3)
    {
        inpaint(cvImage1, cvMask, cvRes, 3, INPAINT_TELEA);//INPAINT_NS);//
    }
    else if(nFillType==2)
    {
        patchMatchInpaint(cvImage1, cvMask, cvRes);
    }
    else if(nFillType==4)
    {
        //cvSMask.create(cvImage.size(), CV_8UC1);
        //cvSMask.setTo(0);
        criminisiInpaint(cvImage1, cvMask, cvSMask, 7);
        cvRes = cvImage1;
    }

    cv::cvtColor(cvRes, cvImage1, cv::COLOR_RGB2RGBA);
    
    for(int y=0;y<nHeight; y++)
    for(int x=0; x<nWidth; x++)
    {
        int nPos = y*nWidth+x;
            if(pMaskAlpha[2*nPos] == 255)
            {
                pBuffer[nPos*4] = cvImage1.data[nPos*4];
                pBuffer[nPos*4+1] = cvImage1.data[nPos*4+1];
                pBuffer[nPos*4+2] = cvImage1.data[nPos*4+2];
                pBuffer[nPos*4+3] = 255;//pMaskAlpha[2*nPos+1];//cvImage.data[nPos*4+3];
            }
            
    }
    //memcpy(pBuffer, cvImage.data, nHeight*nWidth*4);
    delete []pMask;
    return 0;
}
