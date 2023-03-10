#import "Rects.h"

inline IntPoint NSPointMakeIntPoint(NSPoint point)
{
	IntPoint newPoint;
	
	newPoint.x = floorf(point.x);
	newPoint.y = floorf(point.y);
	
	return newPoint; 
}

inline IntSize NSSizeMakeIntSize(NSSize size)
{
	IntSize newSize;
	
	newSize.width = ceilf(size.width);
	newSize.height = ceilf(size.height);
	
	return newSize;
}

inline NSPoint IntPointMakeNSPoint(IntPoint point)
{
	NSPoint newPoint;
	
	newPoint.x = point.x;
	newPoint.y = point.y;
	
	return newPoint;
}

inline IntPoint IntMakePoint(int x, int y)
{
	IntPoint newPoint;
	
	newPoint.x = x;
	newPoint.y = y;
	
	return newPoint;
}

inline NSSize IntSizeMakeNSSize(IntSize size)
{
	NSSize newSize;
	
	newSize.width = size.width;
	newSize.height = size.height;
	
	return newSize;
}

inline IntSize IntMakeSize(int width, int height)
{
	IntSize newSize;
	
	newSize.width = width;
	newSize.height = height;
	
	return newSize;
}

inline IntRect IntMakeRect(int x, int y, int width, int height)
{
	IntRect newRect;
	
	newRect.origin.x = x;
	newRect.origin.y = y;
	newRect.size.width = width;
	newRect.size.height = height;
	
	return newRect;
}

inline void IntOffsetRect(IntRect *rect, int x, int y)
{
	rect->origin.x += x;
	rect->origin.y += y;
}

inline BOOL IntPointInRect(IntPoint point, IntRect rect)
{
	if (point.x < rect.origin.x) return NO;
	if (point.x >= rect.origin.x + rect.size.width) return NO;
	if (point.y < rect.origin.y) return NO;
	if (point.y >= rect.origin.y + rect.size.height) return NO;
	
	return YES;
}

inline BOOL IntContainsRect(IntRect bigRect, IntRect littleRect)
{
	if (littleRect.origin.x < bigRect.origin.x) return NO;
	if (littleRect.origin.x + littleRect.size.width > bigRect.origin.x + bigRect.size.width) return NO;
	if (littleRect.origin.y < bigRect.origin.y) return NO;
	if (littleRect.origin.y + littleRect.size.height > bigRect.origin.y + bigRect.size.height) return NO;
	
	return YES;
}

inline IntRect IntConstrainRect(IntRect littleRect, IntRect bigRect)
{
	IntRect rect = littleRect;
	
	if (littleRect.origin.x < bigRect.origin.x) { rect.origin.x = bigRect.origin.x; rect.size.width = littleRect.size.width - (bigRect.origin.x - littleRect.origin.x); }
	else { rect.origin.x = littleRect.origin.x; rect.size.width = littleRect.size.width; }
	if (rect.origin.x + rect.size.width > bigRect.origin.x + bigRect.size.width) { rect.size.width = (bigRect.origin.x + bigRect.size.width) - rect.origin.x; }
	if (rect.size.width < 0) rect.size.width = 0;
	
	if (littleRect.origin.y < bigRect.origin.y) { rect.origin.y = bigRect.origin.y; rect.size.height = littleRect.size.height - (bigRect.origin.y - littleRect.origin.y); }
	else { rect.origin.y = littleRect.origin.y; rect.size.height = littleRect.size.height; }
	if (rect.origin.y + rect.size.height > bigRect.origin.y + bigRect.size.height) { rect.size.height = (bigRect.origin.y + bigRect.size.height) - rect.origin.y; }
	if (rect.size.height < 0) rect.size.height = 0;
	
	return rect;
}

inline IntRect NSRectMakeIntRect(NSRect rect)
{
	IntRect newRect;
	
	newRect.origin = NSPointMakeIntPoint(rect.origin);
	newRect.size = NSSizeMakeIntSize(rect.size);
	
	return newRect;
}

inline NSRect IntRectMakeNSRect(IntRect rect)
{
	NSRect newRect;
	
	newRect.origin = IntPointMakeNSPoint(rect.origin);
	newRect.size = IntSizeMakeNSSize(rect.size);
	
	return newRect;
}


inline void premultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
	int i, j, alphaPos, temp;
	
	for (i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (input[alphaPos] == 255) {
			for (j = 0; j < spp; j++)
				output[i * spp + j] = input[i * spp + j];
		}
		else {
			if (input[alphaPos] != 0) {
				for (j = 0; j < spp - 1; j++)
					output[i * spp + j] = int_mult(input[i * spp + j], input[alphaPos], temp);
				output[alphaPos] = input[alphaPos];
			}
			else {
				for (j = 0; j < spp; j++)
					output[i * spp + j] = 0;
			}
		}
	}
}

inline void unpremultiplyBitmap(int spp, unsigned char *output, unsigned char *input, int length)
{
	int i, j, alphaPos, newValue;
	double alphaRatio;
	
	for (i = 0; i < length; i++) {
		alphaPos = (i + 1) * spp - 1;
		if (input[alphaPos] == 255) {
			for (j = 0; j < spp; j++)
				output[i * spp + j] = input[i * spp + j];
		}
		else {
			if (input[alphaPos] != 0) {
				alphaRatio = 255.0 / input[alphaPos];
				for (j = 0; j < spp - 1; j++) {
					newValue = 0.5 + input[i * spp + j] * alphaRatio;
					newValue = MIN(newValue, 255);
					output[i * spp + j] = newValue;
				}
				output[alphaPos] = input[alphaPos];
			}
			else {
				for (j = 0; j < spp; j++)
					output[i * spp + j] = 0;
			}
		}
	}
}

inline void swapRgbaToArgb(unsigned char *output, unsigned char *input, int length)
{
    unsigned char *from = input;
    unsigned char *to = output;

    if(input != output)
    {
        for(int i=0; i< length; i++)
        {
            to[0] = from[3];
            to[1] = from[0];
            to[2] = from[1];
            to[3] = from[2];
            from += 4;
            to += 4;
        }
    }
    else
    {
        for(int i=0; i< length; i++)
        {
            uint32 nValue = *(uint32 *)from;
            unsigned char *tfrom = (unsigned char *)&nValue;
            to[0] = tfrom[3];
            to[1] = tfrom[0];
            to[2] = tfrom[1];
            to[3] = tfrom[2];
            from += 4;
            to += 4;
        }
    }
}

inline void swapArgbToRgba(unsigned char *output, unsigned char *input, int length)
{
    unsigned char *from = input;
    unsigned char *to = output;

    if(input != output)
    {
        for(int i=0; i< length; i++)
        {
            to[0] = from[1];
            to[1] = from[2];
            to[2] = from[3];
            to[3] = from[0];
            from += 4;
            to += 4;
        }
    }
    else
    {
        for(int i=0; i< length; i++)
        {
            uint32 nValue = *(uint32 *)from;
            unsigned char *tfrom = (unsigned char *)&nValue;
            to[0] = tfrom[1];
            to[1] = tfrom[2];
            to[2] = tfrom[3];
            to[3] = tfrom[0];
            from += 4;
            to += 4;
        }
    }
}

#import "PluginData.h"
int preProcessToARGB(unsigned char *pBufRaw, int spp, int nWidth, int nHeight, unsigned char *pBufOut, int nChannelMode)
{
    if(spp == 2) //gray
    {
        for (int i = 0; i < nWidth * nHeight; i++)
        {
            if (nChannelMode == kPrimaryChannels)
            {
                pBufOut[i * 4] = 0xff; //pBufRaw[i * 2 + 1];
                pBufOut[i * 4 + 1] = pBufRaw[i * 2];
                pBufOut[i * 4 + 2] = pBufRaw[i * 2];
                pBufOut[i * 4 + 3] = pBufRaw[i * 2];
            }
            else if(nChannelMode == kAlphaChannel)
            {
                pBufOut[i * 4] = 0xff; //pBufRaw[i * 2 + 1];
                pBufOut[i * 4 + 1] = pBufRaw[i * 2+1];
                pBufOut[i * 4 + 2] = pBufRaw[i * 2+1];
                pBufOut[i * 4 + 3] = pBufRaw[i * 2+1];
            }
            else
            {
                int temp;
                pBufOut[i * 4] = pBufRaw[i * 2 + 1];
                pBufOut[i * 4 + 1] = int_mult(pBufRaw[i * 2], pBufRaw[i * 2 + 1], temp);
                pBufOut[i * 4 + 2] = pBufOut[i * 4 + 1];
                pBufOut[i * 4 + 3] = pBufOut[i * 4 + 1];
            }

        }
        return 0;
    }
    
    else if(spp == 4)
    {
        for (int i = 0; i < nWidth * nHeight; i++)
        {
            if (nChannelMode == kPrimaryChannels)
            {
                pBufOut[i * 4] = 0xff; //pBufRaw[i * 2 + 1];
                pBufOut[i * 4 + 1] = pBufRaw[i * 4];
                pBufOut[i * 4 + 2] = pBufRaw[i * 4 + 1];
                pBufOut[i * 4 + 3] = pBufRaw[i * 4 + 2];
            }
            else if(nChannelMode == kAlphaChannel)
            {
                pBufOut[i * 4] = 0xff; //pBufRaw[i * 2 + 1];
                pBufOut[i * 4 + 1] = pBufRaw[i * 4+3];
                pBufOut[i * 4 + 2] = pBufRaw[i * 4+3];
                pBufOut[i * 4 + 3] = pBufRaw[i * 4+3];
            }
            else
            {
                int temp;
                pBufOut[i * 4] = pBufRaw[i * 4 + 3];
                pBufOut[i * 4 + 1] = int_mult(pBufRaw[i * 4], pBufRaw[i * 4 + 3], temp);
                pBufOut[i * 4 + 2] = int_mult(pBufRaw[i * 4+1], pBufRaw[i * 4 + 3], temp);
                pBufOut[i * 4 + 3] = int_mult(pBufRaw[i * 4+2], pBufRaw[i * 4 + 3], temp);
            }

        }
        return 0;
    }
    
    return -1;
}


int postProcessToRGBA(unsigned char *pBufRawRGBA, IntRect selection, int rawWidth, int rawHeight, unsigned char *pBufDataARGBM, int spp, int nWidth, int nHeight, unsigned char *pBufOutRGBA, int nChannelMode)
{
    if(spp == 2) //gray
    {
        unsigned char *pBufGA = pBufRawRGBA + selection.origin.y * rawWidth *2 + selection.origin.x*2;
        unsigned char *pOutBufGA = pBufOutRGBA;
        
        for(int y=0; y<nHeight; y++)
        {
            for(int x=0; x<nWidth; x++)
            {
                int i = y*nWidth + x;
                //for (int i = 0; i < nWidth * nHeight; i++)
        
                if (nChannelMode == kPrimaryChannels)
                {
                    pOutBufGA[i * 2] = pBufDataARGBM[i * 4]; //gray
                    pOutBufGA[i * 2 + 1] = pBufGA[x * 2 +1]; //alpha
                }
                else if(nChannelMode == kAlphaChannel)
                {
                    pOutBufGA[i * 2] = pBufDataARGBM[i * 4]; //pBufGA[x * 2]; //gray
                    pOutBufGA[i * 2 + 1] = 0xff;//pBufDataARGBM[i * 4]; //alpha
                }
                else
                {
                    int temp;
                
                    pOutBufGA[i * 2 + 1] = pBufDataARGBM[i * 4 +1];
                    if (pOutBufGA[i * 2 + 1] != 0)
                    {
                        double alphaRatio = 255.0 / pOutBufGA[i * 2 + 1];
                        int newValue = 0.5 + pBufDataARGBM[i * 4] * alphaRatio;
                        newValue = MIN(newValue, 255);
                        pOutBufGA[i * 2] = newValue;
                    }
                    else
                    {
                        pOutBufGA[i * 2] = 0;
                    }
                }
            }
            pBufGA += rawWidth*2;
        }
        return 0;
    }
    
    else if(spp == 4)
    {
        unsigned char *pBufRGBA = pBufRawRGBA + selection.origin.y * rawWidth *4 + selection.origin.x*4;
        for(int y=0; y<nHeight; y++)
        {
            for(int x=0; x<nWidth; x++)
            {
                int i = y*nWidth + x;
                if (nChannelMode == kPrimaryChannels)
                {
                    pBufOutRGBA[i * 4] = pBufDataARGBM[i * 4];
                    pBufOutRGBA[i * 4 + 1] = pBufDataARGBM[i * 4+ 1];
                    pBufOutRGBA[i * 4 + 2] = pBufDataARGBM[i * 4+ 2];
                    pBufOutRGBA[i * 4 + 3] = pBufRGBA[x * 4 + 3];
                }
                else if(nChannelMode == kAlphaChannel)
                {
                    pBufOutRGBA[i * 4] = pBufDataARGBM[i * 4]; //pBufRGBA[x * 4];
                    pBufOutRGBA[i * 4 + 1] = pBufDataARGBM[i * 4]; //pBufRGBA[x * 4+1];
                    pBufOutRGBA[i * 4 + 2] = pBufDataARGBM[i * 4]; //pBufRGBA[x * 4+2];
                    pBufOutRGBA[i * 4 + 3] = 0xff;//pBufDataARGBM[i * 4];
                }
                else
                {
                    int temp;
                    pBufOutRGBA[i * 4 + 3] = pBufDataARGBM[i * 4 +3];
                    
                    if (pBufOutRGBA[i * 4 + 3] != 0)
                    {
                        double alphaRatio = 255.0 / pBufOutRGBA[i * 4 + 3];
                        
                        for(int j=0; j<3; j++)
                        {
                            int newValue = 0.5 + pBufDataARGBM[i * 4 + j] * alphaRatio;
                            newValue = MIN(newValue, 255);
                            pBufOutRGBA[i * 4+j] = newValue;
                        }
                    }
                    else
                    {
                        for(int j=0; j<3; j++)
                        {
                            pBufOutRGBA[i * 4+j] = 0;
                        }
                    }
                }
            }
            pBufRGBA += rawWidth*4;
        }
        return 0;
    }
    return -1;
}
