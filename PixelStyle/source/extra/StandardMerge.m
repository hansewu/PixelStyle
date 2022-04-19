#import "StandardMerge.h"
#import "ColorConversion.h"

#define alphaPos (spp - 1)

 void specialMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	unsigned char multi, alpha;
	int t1, t2;
	int k;
	
	if (srcPtr[srcLoc + alphaPos] == 0 || srcOpacity <= 0)
		return;
	
	if (srcOpacity < 255)
		alpha = int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
	else
		alpha = srcPtr[srcLoc + alphaPos];
	
	if (alpha + destPtr[destLoc + alphaPos] < 255)
		multi = (unsigned char)(((float)alpha / ((float)alpha + (float)destPtr[destLoc + alphaPos])) * 255.0);
	else
		multi = alpha;
	for (k = 0; k < spp - 1; k++) {
		destPtr[destLoc + k] = int_mult(srcPtr[srcLoc + k], multi, t1) + int_mult(destPtr[destLoc + k], 255 - multi, t2);
	}
	destPtr[destLoc + alphaPos] += int_mult(255 - destPtr[destLoc + alphaPos], alpha, t1);
}

void specialAlphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
    unsigned char multi, alpha;
    int t1;
 
    
    if (srcPtr[srcLoc + alphaPos] == 0 || srcOpacity <= 0)
        return;
    
    if (srcOpacity < 255)
        alpha = int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
    else
        alpha = srcPtr[srcLoc + alphaPos];
    
    if (alpha + destPtr[destLoc + alphaPos] < 255)
        multi = (unsigned char)(((float)alpha / ((float)alpha + (float)destPtr[destLoc + alphaPos])) * 255.0);
    else
        multi = alpha;
    destPtr[destLoc + alphaPos] += int_mult(255 - destPtr[destLoc + alphaPos], alpha, t1);
}

void specialMergeCustom(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr1, int srcLoc1, unsigned char *srcPtr2, int srcLoc2, int srcOpacity)
{
    unsigned char multi, alpha;
    int t1, t2;
    int k;
    
    if (srcPtr1[srcLoc1 + alphaPos] == 0 || srcOpacity <= 0)
        return;
    
    if (srcOpacity < 255)
        alpha = int_mult(srcPtr1[srcLoc1 + alphaPos], srcOpacity, t1);
    else
        alpha = srcPtr1[srcLoc1 + alphaPos];
    
    if (alpha + srcPtr2[srcLoc2 + alphaPos] < 255)
        multi = (unsigned char)(((float)alpha / ((float)alpha + (float)srcPtr2[srcLoc2 + alphaPos])) * 255.0);
    else
        multi = alpha;
    for (k = 0; k < spp - 1; k++) {
        destPtr[destLoc + k] = int_mult(srcPtr1[srcLoc1 + k], multi, t1) + int_mult(srcPtr2[srcLoc2 + k], 255 - multi, t2);
    }
    destPtr[destLoc + alphaPos] = srcPtr2[srcLoc2 + alphaPos] + int_mult(255 - srcPtr2[srcLoc2 + alphaPos], alpha, t1);
}


 void replaceMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	int t1, t2, k;
	
	if (srcOpacity == 0) return;
	
	if (srcOpacity == 255) {
		memcpy(&(destPtr[destLoc]), &(srcPtr[srcLoc]), spp);
	}
	else {
		for (k = 0; k < spp; k++)
			destPtr[destLoc + k] = int_mult(destPtr[destLoc + k], 255 - srcOpacity, t1) + int_mult(srcPtr[srcLoc + k], srcOpacity, t2);
	}
}

//type 0 all channel  1 primary 2 alpha
void replaceMergeCustom(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr1, int srcLoc1, unsigned char *srcPtr2, int srcLoc2, int srcOpacity, int type)
{
    unsigned char multi, alpha;
    
    int t1, t2, k;
    
    if (srcOpacity == 0) return;
    
    switch (type) {
        case 0:
        {
            if (srcOpacity == 255) {
                memcpy(&(destPtr[destLoc]), &(srcPtr1[srcLoc1]), spp);
            }
            else {
                alpha = int_mult(srcPtr1[srcLoc1 + alphaPos], srcOpacity, t1);
                
                if (alpha + srcPtr2[srcLoc2 + alphaPos] < 255)
                    multi = (unsigned char)(((float)alpha / ((float)alpha + (float)srcPtr2[srcLoc2 + alphaPos])) * 255.0);
                else
                    multi = alpha;
                
                for (k = 0; k < spp - 1; k++) {
                    destPtr[destLoc + k] = int_mult(srcPtr1[srcLoc1 + k], multi, t1) + int_mult(srcPtr2[srcLoc2 + k], 255 - multi, t2);
                }
                destPtr[destLoc + alphaPos] = int_mult(srcPtr1[srcLoc1 + alphaPos], alpha, t1) + int_mult(srcPtr2[srcLoc2 + alphaPos], 255 - alpha, t2);
            }
        }
            break;
            
        case 1:
        {
            if (srcOpacity == 255) {
                memcpy(&(destPtr[destLoc]), &(srcPtr1[srcLoc1]), spp - 1);
            }
            else {
                alpha = int_mult(srcPtr1[srcLoc1 + alphaPos], srcOpacity, t1);
                
                if (alpha + srcPtr2[srcLoc2 + alphaPos] < 255)
                    multi = (unsigned char)(((float)alpha / ((float)alpha + (float)srcPtr2[srcLoc2 + alphaPos])) * 255.0);
                else
                    multi = alpha;
                
                for (k = 0; k < spp - 1; k++) {
                    destPtr[destLoc + k] = int_mult(srcPtr1[srcLoc1 + k], multi, t1) + int_mult(srcPtr2[srcLoc2 + k], 255 - multi, t2);
                }
            }
        }
            break;

        case 2:
        {
            if (srcOpacity == 255) {
                destPtr[destLoc + alphaPos] = srcPtr1[srcLoc1 + alphaPos];
            }
            else {
                alpha = int_mult(srcPtr1[srcLoc1 + alphaPos], srcOpacity, t1);
                destPtr[destLoc + alphaPos] = int_mult(srcPtr1[srcLoc1 + alphaPos], alpha, t1) + int_mult(srcPtr2[srcLoc2 + alphaPos], 255 - alpha, t2);
            }
        }
            break;

            
        default:
            break;
    }
    
    
}

void replacePrimaryMergeCustomSimple(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr1, int srcLoc1, unsigned char *srcPtr2, int srcLoc2, int srcOpacity)
{
    int t1, t2, k;
    
    if (srcOpacity <= 0) return;
    
    if (srcOpacity >= 255) {
        memcpy(&(destPtr[destLoc]), &(srcPtr1[srcLoc1]), spp - 1);
    }
    else {
        for (k = 0; k < spp - 1; k++) {
            destPtr[destLoc + k] = int_mult(srcPtr1[srcLoc1 + k], srcOpacity, t1) + int_mult(srcPtr2[srcLoc2 + k], 255 - srcOpacity, t2);
        }
    }
    
}



 void replacePrimaryMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	int t1, t2, k;
	
	if (srcOpacity == 0) return;
	
	if (srcOpacity == 255) {
		memcpy(&(destPtr[destLoc]), &(srcPtr[srcLoc]), spp - 1);
	}
	else {
		for (k = 0; k < spp - 1; k++)
			destPtr[destLoc + k] = int_mult(destPtr[destLoc + k], 255 - srcOpacity, t1) + int_mult(srcPtr[srcLoc + k], srcOpacity, t2);
	}
}

 void replaceAlphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	int t1, t2;
	
	if (srcOpacity == 0) return;
	
	if (srcOpacity == 255) {
		destPtr[destLoc + spp - 1] = srcPtr[srcLoc];
	}
	else {
		destPtr[destLoc + spp - 1] = int_mult(destPtr[destLoc + spp - 1], 255 - srcOpacity, t1) + int_mult(srcPtr[srcLoc], srcOpacity, t2);
	}
}

 void normalMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	unsigned char alpha;
	int t1, t2;
	int k;
	
	alpha = int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
	if (alpha == 0)
		return;
		
	if (alpha == 255) {
		for (k = 0; k < alphaPos; k++)
			destPtr[destLoc + k] = srcPtr[srcLoc + k];
		destPtr[destLoc + alphaPos] = 255;
	}
	else {
		for (k = 0; k < alphaPos; k++)
			destPtr[destLoc + k] = int_mult (srcPtr[srcLoc + k], alpha, t1) + int_mult (destPtr[destLoc + k], (255 - alpha), t2);
        destPtr[destLoc + alphaPos] = alpha + int_mult((255 - alpha), destPtr[destLoc + alphaPos], t1);
	}
}

void normalMergeCustom(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, unsigned char *srcPtr2, int srcLoc2, int srcOpacity)
{
    unsigned char alpha;
    int t1, t2;
    int k;
    
    alpha = int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
    if (alpha == 0)
        return;
    
    if (alpha == 255) {
        for (k = 0; k < alphaPos; k++)
            destPtr[destLoc + k] = srcPtr[srcLoc + k];
        destPtr[destLoc + alphaPos] = 255;
    }
    else {
        for (k = 0; k < alphaPos; k++)
            destPtr[destLoc + k] = int_mult (srcPtr[srcLoc + k], alpha, t1) + int_mult (destPtr[destLoc + k], (255 - alpha), t2);
        destPtr[destLoc + alphaPos] = alpha + int_mult((255 - alpha), destPtr[destLoc + alphaPos], t1);
    }
}



 void eraseMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	unsigned char alpha;
	int t1;
	
	if (destPtr[destLoc + alphaPos] == 0 || srcPtr[srcLoc + alphaPos] == 0 || srcOpacity <= 0)
		return;
	
	if (srcOpacity < 255)
		alpha = 255 - int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
	else
		alpha = 255 - srcPtr[srcLoc + alphaPos];
	
	destPtr[destLoc + alphaPos] = int_mult(destPtr[destLoc + alphaPos], alpha, t1);
	
}

void flexibleEraseMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity, PS_EDIT_CHANNEL_TYPE type)
{
    unsigned char alpha;
    int t1;
    
    if (destPtr[destLoc + alphaPos] == 0 || srcPtr[srcLoc + alphaPos] == 0 || srcOpacity <= 0)
        return;
    
    switch (type) {
        case kEditRedChannels:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 0], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 0];
            destPtr[destLoc + 0] = int_mult(destPtr[destLoc + 0], alpha, t1);
        }
            break;
            
        case kEditGreenChannels:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 1], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 1];
            destPtr[destLoc + 1] = int_mult(destPtr[destLoc + 1], alpha, t1);
        }
            break;
            
        case kEditBlueChannels:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 2], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 2];
            destPtr[destLoc + 2] = int_mult(destPtr[destLoc + 2], alpha, t1);
            
        }
            break;
            
        case kEditRedGreenChannel:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 0], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 0];
            destPtr[destLoc + 0] = int_mult(destPtr[destLoc + 0], alpha, t1);
            
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 1], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 1];
            destPtr[destLoc + 1] = int_mult(destPtr[destLoc + 1], alpha, t1);
        }
            break;
            
        case kEditRedBlueChannel:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 0], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 0];
            destPtr[destLoc + 0] = int_mult(destPtr[destLoc + 0], alpha, t1);
            
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 2], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 2];
            destPtr[destLoc + 2] = int_mult(destPtr[destLoc + 2], alpha, t1);
        }
            break;
            
        case kEditGreenBlueChannel:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 1], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 1];
            destPtr[destLoc + 1] = int_mult(destPtr[destLoc + 1], alpha, t1);
            
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + 2], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + 2];
            destPtr[destLoc + 2] = int_mult(destPtr[destLoc + 2], alpha, t1);
        }
            break;
            
        default:
        {
            if (srcOpacity < 255)
                alpha = 255 - int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
            else
                alpha = 255 - srcPtr[srcLoc + alphaPos];
            
            destPtr[destLoc + alphaPos] = int_mult(destPtr[destLoc + alphaPos], alpha, t1);
        }
            break;
    }
    
    
    
}

void eraseMergeCustom(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr1, int srcLoc1, unsigned char *srcPtr2, int srcLoc2, int srcOpacity)
{
    unsigned char alpha;
    int t1;
    
    if (srcPtr2[srcLoc2 + alphaPos] == 0 || srcPtr1[srcLoc1 + alphaPos] == 0 || srcOpacity <= 0)
        return;
    
    if (srcOpacity < 255)
        alpha = 255 - int_mult(srcPtr1[srcLoc1 + alphaPos], srcOpacity, t1);
    else
        alpha = 255 - srcPtr1[srcLoc1 + alphaPos];
    
    destPtr[destLoc + alphaPos] = int_mult(srcPtr2[srcLoc2 + alphaPos], alpha, t1);
    
}

void eraseMergeCustomWithFlag(int spp, unsigned char *destPtr, unsigned char *flagPtr, int destLoc, unsigned char *srcPtr1, int srcLoc1, unsigned char *srcPtr2, int srcLoc2, int srcOpacity)
{
    unsigned char alpha;
    int t1;
    
    if (srcPtr2[srcLoc2 + alphaPos] == 0 || srcPtr1[srcLoc1 + alphaPos] == 0 || srcOpacity <= 0)
        return;
    
    if (srcOpacity < 255)
        alpha = 255 - int_mult(srcPtr1[srcLoc1 + alphaPos], srcOpacity, t1);
    else
        alpha = 255 - srcPtr1[srcLoc1 + alphaPos];
    
    destPtr[destLoc + alphaPos] = int_mult(srcPtr2[srcLoc2 + alphaPos], alpha, t1);
    
    flagPtr[destLoc/spp] = 255;
}

 void primaryMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity, BOOL lazy)
{
	unsigned char oldAlpha;

	oldAlpha = destPtr[destLoc + alphaPos];
	if ((lazy && oldAlpha == 0x00) || srcOpacity == 0)
		return;
	
	destPtr[destLoc + alphaPos] = 0xFF;
	normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, srcOpacity);
	destPtr[destLoc + alphaPos] = oldAlpha;
}

void flexibleMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity, BOOL lazy, PS_EDIT_CHANNEL_TYPE type)
{
    unsigned char oldAlpha;
    oldAlpha = destPtr[destLoc + alphaPos];
    if ((lazy && oldAlpha == 0x00) || srcOpacity == 0)
        return;
    
    
    
    unsigned char alpha;
    int t1, t2;
    int k;
    
    alpha = int_mult(srcPtr[srcLoc + alphaPos], srcOpacity, t1);
    if (alpha == 0)
        return;
    
    switch (type) {
        case kEditAllChannels:
        {
            if (alpha == 255) {
                for (k = 0; k < alphaPos; k++)
                    destPtr[destLoc + k] = srcPtr[srcLoc + k];
                destPtr[destLoc + alphaPos] = 255;
            }
            else {
                for (k = 0; k < alphaPos; k++)
                    destPtr[destLoc + k] = int_mult (srcPtr[srcLoc + k], alpha, t1) + int_mult (destPtr[destLoc + k], (255 - alpha), t2);
                destPtr[destLoc + alphaPos] = alpha + int_mult((255 - alpha), destPtr[destLoc + alphaPos], t1);
            }
            
        }
            break;
        case kEditPrimaryChannels:
        {
            if (alpha == 255) {
                for (k = 0; k < alphaPos; k++)
                    destPtr[destLoc + k] = srcPtr[srcLoc + k];
            }
            else {
                for (k = 0; k < alphaPos; k++)
                    destPtr[destLoc + k] = int_mult (srcPtr[srcLoc + k], alpha, t1) + int_mult (destPtr[destLoc + k], (255 - alpha), t2);
            }
        }
            break;
        case kEditRedChannels:
        {
            if (alpha == 255) {
                destPtr[destLoc + 0] = srcPtr[srcLoc + 0];
            }
            else {
                destPtr[destLoc + 0] = int_mult (srcPtr[srcLoc + 0], alpha, t1) + int_mult (destPtr[destLoc + 0], (255 - alpha), t2);
            }
        }
            break;
        case kEditGreenChannels:
        {
            if (alpha == 255) {
                destPtr[destLoc + 1] = srcPtr[srcLoc + 1];
            }
            else {
                destPtr[destLoc + 1] = int_mult (srcPtr[srcLoc + 1], alpha, t1) + int_mult (destPtr[destLoc + 1], (255 - alpha), t2);
            }
        }
            break;
        case kEditBlueChannels:
        {
            if (alpha == 255) {
                destPtr[destLoc + 2] = srcPtr[srcLoc + 2];
            }
            else {
                destPtr[destLoc + 2] = int_mult (srcPtr[srcLoc + 2], alpha, t1) + int_mult (destPtr[destLoc + 2], (255 - alpha), t2);
            }
        }
            break;
            
        case kEditRedGreenChannel:
        {
            if (alpha == 255) {
                destPtr[destLoc + 0] = srcPtr[srcLoc + 0];
                destPtr[destLoc + 1] = srcPtr[srcLoc + 1];
            }
            else {
                destPtr[destLoc + 0] = int_mult (srcPtr[srcLoc + 0], alpha, t1) + int_mult (destPtr[destLoc + 0], (255 - alpha), t2);
                destPtr[destLoc + 1] = int_mult (srcPtr[srcLoc + 1], alpha, t1) + int_mult (destPtr[destLoc + 1], (255 - alpha), t2);
            }
        }
            break;
            
        case kEditRedBlueChannel:
        {
            if (alpha == 255) {
                destPtr[destLoc + 0] = srcPtr[srcLoc + 0];
                destPtr[destLoc + 2] = srcPtr[srcLoc + 2];
            }
            else {
                destPtr[destLoc + 0] = int_mult (srcPtr[srcLoc + 0], alpha, t1) + int_mult (destPtr[destLoc + 0], (255 - alpha), t2);
                destPtr[destLoc + 2] = int_mult (srcPtr[srcLoc + 2], alpha, t1) + int_mult (destPtr[destLoc + 2], (255 - alpha), t2);
            }
        }
            break;
            
        case kEditGreenBlueChannel:
        {
            if (alpha == 255) {
                destPtr[destLoc + 1] = srcPtr[srcLoc + 1];
                destPtr[destLoc + 2] = srcPtr[srcLoc + 2];
            }
            else {
                destPtr[destLoc + 1] = int_mult (srcPtr[srcLoc + 1], alpha, t1) + int_mult (destPtr[destLoc + 1], (255 - alpha), t2);
                destPtr[destLoc + 2] = int_mult (srcPtr[srcLoc + 2], alpha, t1) + int_mult (destPtr[destLoc + 2], (255 - alpha), t2);
            }
        }
            break;
            
        case kEditAlphaChannel:
        {
            unsigned char tempDest[2], tempSrc[2];
            
            if (srcOpacity == 0)
                return;
            
            unsigned char nullValue[4];
            memset(nullValue, 0, 4);
            if (memcmp(destPtr, nullValue, spp) == 0) {
                return;
            }

            tempDest[0] = destPtr[destLoc + alphaPos];
            tempDest[1] = 0xFF;
            tempSrc[0] = srcPtr[srcLoc];
            tempSrc[1] = srcPtr[srcLoc + alphaPos];
            normalMerge(2, tempDest, 0, tempSrc, 0, srcOpacity);
            destPtr[destLoc + alphaPos] = tempDest[0];
            
//            if (alpha == 255) {
//                destPtr[destLoc + alphaPos] = srcPtr[srcLoc + alphaPos];
//            }
//            else {
//                destPtr[destLoc + alphaPos] = int_mult (srcPtr[srcLoc + alphaPos], alpha, t1) + int_mult (destPtr[destLoc + alphaPos], (255 - alpha), t2);
//            }
            
        }
            break;
            
        default:{
            if (alpha == 255) {
                for (k = 0; k < alphaPos; k++)
                    destPtr[destLoc + k] = srcPtr[srcLoc + k];
                destPtr[destLoc + alphaPos] = 255;
            }
            else {
                for (k = 0; k < alphaPos; k++)
                    destPtr[destLoc + k] = int_mult (srcPtr[srcLoc + k], alpha, t1) + int_mult (destPtr[destLoc + k], (255 - alpha), t2);
                destPtr[destLoc + alphaPos] = alpha + int_mult((255 - alpha), destPtr[destLoc + alphaPos], t1);
            }

        }
            break;
    }
    
}

void primaryMergeCustom(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr1, int srcLoc1, unsigned char *srcPtr2, int srcLoc2, int srcOpacity, BOOL lazy)
{
    unsigned char oldAlpha;
    
    oldAlpha = srcPtr2[srcLoc2 + alphaPos];
    if ((lazy && oldAlpha == 0x00) || srcOpacity == 0)
        return;
    
    destPtr[destLoc + alphaPos] = 0xFF;
    normalMergeCustom(spp, destPtr, destLoc, srcPtr1, srcLoc1, srcPtr2, srcLoc2, srcOpacity);
    destPtr[destLoc + alphaPos] = oldAlpha;
}

 void alphaMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int srcOpacity)
{
	unsigned char tempDest[2], tempSrc[2];

	if (srcOpacity == 0)
		return;
		
	tempDest[0] = destPtr[destLoc + alphaPos];
	tempDest[1] = 0xFF;
	tempSrc[0] = srcPtr[srcLoc];
	tempSrc[1] = srcPtr[srcLoc + alphaPos];
	
	normalMerge(2, tempDest, 0, tempSrc, 0, srcOpacity);
	
	destPtr[destLoc + alphaPos] = tempDest[0];
}

 void blendPixel(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc, int blend)
{
	const int blend1 = 256 - blend;
	const int blend2 = blend + 1;
	int a1, a2, a, k;
	
	a1 = blend1 * srcPtr[srcLoc + alphaPos];
	a2 = blend2 * destPtr[destLoc + alphaPos];
	a = a1 + a2;
	
	if (a == 0) {
		for (k = 0; k < spp; k++)
			destPtr[destLoc + k] = 0;
	}
	else {
		for (k = 0; k < alphaPos; k++)
			destPtr[destLoc + k] = (srcPtr[srcLoc + k] * a1 + destPtr[destLoc + k] * a2) / a;
		destPtr[destLoc + alphaPos] = a >> 8;
	}
}

 void dissolveMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int randVal;
	int k;
		
	alpha = srcPtr[srcLoc + alphaPos];

	for (k = 0; k < alphaPos; k++)
		destPtr[destLoc + k] = srcPtr[srcLoc + k];

	randVal = (random() & 0xff);
	destPtr[destLoc + alphaPos] = (randVal > alpha) ? 0 : alpha;
}

 void additiveMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
		if (srcPtr[srcLoc + k] + destPtr[destLoc + k] < 255)
			destPtr[destLoc + k] = srcPtr[srcLoc + k] + destPtr[destLoc + k];
		else
			destPtr[destLoc + k] = 255;
	}
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void differenceMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
		if (srcPtr[srcLoc + k] > destPtr[destLoc + k])
			destPtr[destLoc + k] = srcPtr[srcLoc + k] - destPtr[destLoc + k];
		else
			destPtr[destLoc + k] = destPtr[destLoc + k] - srcPtr[srcLoc + k];
	}
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void multiplyMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int t1;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) 
		destPtr[destLoc + k] = int_mult(srcPtr[srcLoc + k], destPtr[destLoc + k], t1);

	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void overlayMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int t1, t2;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) 
		destPtr[destLoc + k] = int_mult(destPtr[destLoc + k], destPtr[destLoc + k] + int_mult(2 * srcPtr[srcLoc + k], 255 - destPtr[destLoc + k], t1), t2);
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void screenMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int t1;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
	    destPtr[destLoc + k] = 255 - int_mult((255 - srcPtr[srcLoc + k]), (255 - destPtr[destLoc + k]), t1);
	}

	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void subtractiveMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
		if (destPtr[destLoc + k] - srcPtr[srcLoc + k] > 0)
			destPtr[destLoc + k] = destPtr[destLoc + k] - srcPtr[srcLoc + k];
		else
			destPtr[destLoc + k] = 0;
	}
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void darkenMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
		if (srcPtr[srcLoc + k] > destPtr[destLoc + k])
			destPtr[destLoc + k] = destPtr[destLoc + k];
		else
			destPtr[destLoc + k] = srcPtr[srcLoc + k];
	}
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void lightenMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
		if (destPtr[destLoc + k] > srcPtr[srcLoc + k])
			destPtr[destLoc + k] = destPtr[destLoc + k];
		else
			destPtr[destLoc + k] = srcPtr[srcLoc + k];
	}
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void divideMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	unsigned char alpha;
	int temp;
	int k;
	
	alpha = srcPtr[srcLoc + alphaPos];
	
	for (k = 0; k < alphaPos; k++) {
		temp = ((destPtr[destLoc + k] * 256) / (1 + srcPtr[srcLoc + k]));
		destPtr[destLoc + k] = MIN (temp, 255);
	}
	
	destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
}

 void hueMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int r1, g1, b1, r2, g2, b2;
	int alpha;

	if (spp > 2) {
	
		alpha = srcPtr[srcLoc + alphaPos];
	
		r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
		r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];
		
		RGBtoHSV(&r1, &g1, &b1);
		RGBtoHSV(&r2, &g2, &b2);
		
		r1 = r2;
		
		HSVtoRGB(&r1, &g1, &b1);
		
		destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;
		
		destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
	
	}
	else
		normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

 void saturationMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int r1, g1, b1, r2, g2, b2;
	int alpha;

	if (spp > 2) {
	
		alpha = srcPtr[srcLoc + alphaPos];
		
		r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
		r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];
		
		RGBtoHSV(&r1, &g1, &b1);
		RGBtoHSV(&r2, &g2, &b2);
		
		g1 = g2;
		
		HSVtoRGB(&r1, &g1, &b1);
		
		destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;
		
		destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
	
	}
	else
		normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

 void valueMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int r1, g1, b1, r2, g2, b2;
	int alpha;

	if (spp > 2) {
	
		alpha = srcPtr[srcLoc + alphaPos];
	
		r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
		r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];
		
		RGBtoHSV(&r1, &g1, &b1);
		RGBtoHSV(&r2, &g2, &b2);
		
		b1 = b2;
		
		HSVtoRGB(&r1, &g1, &b1);
		
		destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;
		
		destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
	
	}
	else
		normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

 void colorMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int r1, g1, b1, r2, g2, b2;
	int alpha;

	if (spp > 2) {
	
		alpha = srcPtr[srcLoc + alphaPos];
			
		r1 = destPtr[destLoc]; g1 = destPtr[destLoc + 1]; b1 = destPtr[destLoc + 2];
		r2 = srcPtr[srcLoc]; g2 = srcPtr[srcLoc + 1]; b2 = srcPtr[srcLoc + 2];
		
		RGBtoHLS(&r1, &g1, &b1);
		RGBtoHLS(&r2, &g2, &b2);
		
		r1 = r2;
		b1 = b2;
		
		HLStoRGB(&r1, &g1, &b1);
		
		destPtr[destLoc] = r1; destPtr[destLoc + 1] = g1; destPtr[destLoc + 2] = b1;
		
		destPtr[destLoc + alphaPos] = MIN(alpha, destPtr[destLoc + alphaPos]);
	
	}
	else
		normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
}

 void dodgeMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int t1, k;
	
	for (k = 0; k < alphaPos; k++) {
		t1 = destPtr[k] << 8;
		t1 /= 256 - srcPtr[k];
		destPtr[k] = MAX(0, MIN(255, t1));
	}
	
	destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

 void burnMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int t1, k;
	
	for (k = 0; k < alphaPos; k++) {
		t1 = (255 - destPtr[k]) << 8;
		t1 /= srcPtr[k] + 1;
		destPtr[k] = MAX(0, MIN(255, 255 - t1));
	}
	
	destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

 void hardlightMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int t1, k;
	
	for (k = 0; k < alphaPos; k++) {
		if (srcPtr[k] > 128) {
			t1 = (255 - destPtr[k]) * (255 - ((srcPtr[k] - 128) << 1));
			destPtr[k] = MAX(0, MIN(255, 255 - (t1 >> 8)));
		}
		else {
			t1 = destPtr[k] * (srcPtr[k] << 1);
			destPtr[k] = MAX(0, MIN(255, t1 >> 8));
		}
	}
	
	destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

 void softlightMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int t1, t2, tM, tS, k;
	
	for (k = 0; k < alphaPos; k++) {
		tM = int_mult(destPtr[k], srcPtr[k], t1);
		tS = 255 - int_mult(255 - destPtr[k], 255 - srcPtr[k], t1);
		destPtr[k] = int_mult(255 - destPtr[k], tM, t1) + int_mult(destPtr[k], tS, t2);
	}
	
	destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

 void grainExtractMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int t1, k;
	
	for (k = 0; k < alphaPos; k++) {
		t1 = destPtr[k] - srcPtr[k] + 128;
		destPtr[k] = MAX(0, MIN(255, t1));
	}
	
	destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

 void grainMergeMerge(int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	int t1, k;
	
	for (k = 0; k < alphaPos; k++) {
		t1 = destPtr[k] + srcPtr[k] - 128;
		destPtr[k] = MAX(0, MIN(255, t1));
	}
	
	destPtr[destLoc + alphaPos] = MIN(srcPtr[srcLoc + alphaPos], destPtr[destLoc + alphaPos]);
}

 void selectMerge(int choice, int spp, unsigned char *destPtr, int destLoc, unsigned char *srcPtr, int srcLoc)
{
	switch (choice) {
		case XCF_DISSOLVE_MODE:
			dissolveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_MULTIPLY_MODE:
			multiplyMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_SCREEN_MODE:
			screenMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_OVERLAY_MODE:
			overlayMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_DIFFERENCE_MODE:
			differenceMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_ADDITION_MODE:
			additiveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_SUBTRACT_MODE:
			subtractiveMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_DARKEN_ONLY_MODE:
			darkenMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_LIGHTEN_ONLY_MODE:
			lightenMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_HUE_MODE:
			hueMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_SATURATION_MODE:
			saturationMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_VALUE_MODE:
			valueMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_COLOR_MODE:
			colorMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_DIVIDE_MODE:
			divideMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_DODGE_MODE:
			dodgeMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_BURN_MODE:
			burnMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_HARDLIGHT_MODE:
			hardlightMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_SOFTLIGHT_MODE:
			softlightMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_GRAIN_EXTRACT_MODE:
			grainExtractMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		case XCF_GRAIN_MERGE_MODE:
			grainMergeMerge(spp, destPtr, destLoc, srcPtr, srcLoc);
		break;
		default:
			normalMerge(spp, destPtr, destLoc, srcPtr, srcLoc, 255);
			NSLog(@"Unknown mode passed to selectMerge()");
		break;
	}
}

