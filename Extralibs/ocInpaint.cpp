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

int ocInpaint(unsigned char *pBuffer, unsigned char *pMask, int nWidth, int nHeight, int nFillType)
{
    cv::Mat_<cv::Vec4b> cvImage = cv::Mat(nHeight, nWidth, CV_8UC4, pBuffer);
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

    cv::cvtColor(cvRes, cvImage, cv::COLOR_RGB2RGBA);
    
    memcpy(pBuffer, cvImage.data, nHeight*nWidth*4);
    
    return 0;
}
