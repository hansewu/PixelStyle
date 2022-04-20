//
//  ocInpaint.hpp
//  PixelStyle
//
//  Created by apple on 2022/4/19.
//

#ifndef ocInpaint_hpp
#define ocInpaint_hpp


#ifdef __cplusplus
extern "C"
{
#endif



int ocInpaint(unsigned char *pBuffer, unsigned char *pMask, int nWidth, int nHeight, int nFillType);



#ifdef __cplusplus
}
#endif /* ocInpaint_hpp */

#endif
