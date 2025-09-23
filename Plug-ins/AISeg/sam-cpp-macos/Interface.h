//
//  Interface.hpp
//  sam_cpp_lib
//
//  Created by wzq on 11/9/2025.
//

#ifndef SAMSEG_Interface_hpp
#define SAMSEG_Interface_hpp

#include <stdio.h>

#ifdef __cplusplus
extern "C"
{
#endif

int SAMSEG_LoadModel(char *cPreModel, char *cModel);
void SAMSEG_SetMode(int bSam2);
int SAMSEG_GetMaskForRect(unsigned char *pcOutMask, unsigned char *pcBufRGBA, int nWidth, int nHeight, float rectx, float recty, float rectW, float rectH);
int SAMSEG_GetMaskForPoints(unsigned char *pcOutMask, unsigned char *pcBufRGBA, int nWidth, int nHeight, int numPoints, float *xPoints, float *yPoints);
int SAMSEG_Exit();

#ifdef __cplusplus
}
#endif
#endif /* SAMSEG_Interface_hpp */
