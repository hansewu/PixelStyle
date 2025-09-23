//
//  Interface.cpp
//  sam_cpp_lib
//
//  Created by wzq on 11/9/2025.
//

#include "Interface.h"
#include <opencv2/opencv.hpp>
#include <thread>
#include "sam.h"

Sam *s_sam;
int SAMSEG_LoadModel(char *cPreModel, char *cModel)
{
    printf("SAMSEG_LoadModel %s, %s\n", cPreModel,  cModel);
    if(!s_sam)
        s_sam= new Sam();
    else
        s_sam->clearLoadModel();
    
    std::string encoderPath = std::string(cPreModel);
    std::string decoderPath = std::string(cModel);
    bool bRet= s_sam->loadModel(encoderPath, decoderPath, std::thread::hardware_concurrency());
    
    if(bRet == false)  return -1;
    return 0;
}

int SAMSEG_Exit()
{
    delete s_sam;
    s_sam = NULL;
    
    return 0;
}

void SAMSEG_SetMode(int bSam2)
{
    if(bSam2 == 0)
        s_sam->changeMode(SAM);
    else
        s_sam->changeMode(SAM2);
}

int SAMSEG_GetMaskForRect(unsigned char *pcOutMask, unsigned char *pcBufRGBA, int nWidth, int nHeight, float rectx, float recty, float rectW, float rectH)
{
    /*cv::Mat image = cv::Mat::zeros(cv::Size(nWidth, nHeight), CV_8UC3);
    for (int j = 0; j < nHeight; ++j)
    {
        unsigned char* data = image.ptr<unsigned char>(j);
        unsigned char* pSubBuffer = pcBufRGB + j * nWidth* 3; //(nHeight - 1 - j) * nWidth* 3;
        memcpy(data, pSubBuffer, nWidth*3);
    }*/
    
    cv::Mat_<cv::Vec4b> image1 = cv::Mat(nHeight,nWidth,  CV_8UC4, pcBufRGBA);
 
    cv::Mat image;
    cv::cvtColor(image1, image, cv::COLOR_BGRA2BGR);
    
    cv::Size imageSize = cv::Size(image.cols, image.rows);
    cv::Size inputSize = s_sam->getInputSize();
    cv::resize(image, image, inputSize);
    
    std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
    bool successPreprocessImage = s_sam->preprocessImage(image);
    
    std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
    std::cout << "sec = " << (std::chrono::duration_cast<std::chrono::microseconds>(end - begin).count()) / 1000000.0 <<std::endl;
    if(!successPreprocessImage)
    {
      std::cout<<"preprocessImage error"<<std::endl;
      return -1;
    }
    std::cout<<"getMask started"<<std::endl;
    cv::Rect rect1 = cv::Rect(rectx * inputSize.width / imageSize.width,
                              recty * inputSize.height / imageSize.height,
                              rectW * inputSize.width / imageSize.width,
                              rectH * inputSize.height / imageSize.height);
    
    std::list<cv::Rect> rects;
    rects.push_back(rect1);
    
    std::vector<float> inputPointValues, inputLabelValues;
    int previousMaskIdx = -1;
    bool isNextGetMask = true;
    
    s_sam->setRectsLabels(rects, &inputPointValues, &inputLabelValues);
    cv::Mat mask = s_sam->getMask(inputPointValues, inputLabelValues, imageSize, previousMaskIdx, isNextGetMask);
    
    for (int i = 0; i < nHeight; i++)
    {
        for (int j = 0; j < nWidth; j++)
        {
            pcOutMask[i * nWidth + j] = mask.at<uchar>(i, j);
        }
    }
    
    return 0;
}
