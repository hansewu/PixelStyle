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
int PatchMatch(cv::Mat &matImage, cv::Mat &matMask, cv::Mat &matOutImage);

int ocInpaint(unsigned char *pBuffer, unsigned char *pMask, int nWidth, int nHeight)
{
    cv::Mat_<cv::Vec4b> cvImage = cv::Mat(nHeight, nWidth, CV_8UC4, pBuffer);
    cv::Mat cvMask = cv::Mat(nHeight, nWidth, CV_8UC1, pMask);
    cv::Mat cvImage1, cvRes;
    
    cv::cvtColor(cvImage, cvImage1, cv::COLOR_RGBA2RGB);
    PatchMatch(cvImage1, cvMask, cvRes);
    //inpaint(cvImage1, cvMask, cvRes, 3, INPAINT_TELEA);//INPAINT_NS);//
    cv::cvtColor(cvRes, cvImage1, cv::COLOR_RGB2RGBA);
    
    memcpy(pBuffer, cvImage1.data, nHeight*nWidth*4);
    
    return 0;
}
