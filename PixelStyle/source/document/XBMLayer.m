#import "PSDocument.h"
#import "PSContent.h"
#import "XBMLayer.h"
#import "XBMContent.h"
#import "bitstring.h"

@implementation XBMLayer

- (id)initWithFile:(FILE *)file offset:(int)offset document:(id)doc sharedInfo:(SharedXBMInfo *)info
{
	unsigned char value;
	char string[9], temp;
	int i, pos = 0;
	BOOL oddWidth = NO;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Set the samples per pixel correctly
	m_nSpp = 2; m_nWidth = info->width; m_nHeight = info->height;
    
    IMAGE_DATA dataImage = [self initImageAndLockWrite:m_nWidth height:m_nHeight spp:m_nSpp alphaPremultiplied:false];
//	m_pData = malloc(make_128(m_nWidth * m_nHeight * m_nSpp));
	memset(dataImage.pBuffer, 0xFF, m_nWidth * m_nHeight * m_nSpp);
	if (m_nWidth % 2 == 1) oddWidth = YES;
	
	do {
		
		// Throw away everything till we get to the good stuff
		do {
			temp = fgetc(file);
		} while ((temp < '0' || temp > '9') && !(ferror(file) || feof(file)));
		
		// Fail if something went wrong
		if (ferror(file) || feof(file)) {
			[self autorelease];
            [m_pImageData unLockDataForWrite];
			return NULL;
		}
		
		// Extract the string containing the value
		string[0] = temp;
		i = 0;
		do {
			i++;
			string[i] = fgetc(file);
		} while ((i < 8) && (string[i] >= '0' && string[i] <= '9' || string[i] >= 'a' && string[i] <= 'f' || string[i] >= 'A' && string[i] <= 'F' || string[i] == 'x') && !(ferror(file) || feof(file)));
		
		// Fail if something went wrong
		if (ferror(file) || feof(file)) {
			[self autorelease];
            [m_pImageData unLockDataForWrite];
			return NULL;
		}
		
		// Convert the string to a value
		string[i] = 0x00;
		value = strtol(string, NULL, 0);
		
		// Now figure out the bitmap
		i = 0;
		do {
			if (bit_test(&value, i))
				dataImage.pBuffer[pos * 2] = 0x00;
			pos++;
			i++;
		} while (pos < m_nWidth * m_nHeight && i < 8 && !(pos % m_nWidth == 0));
	
	} while (pos < m_nWidth * m_nHeight);
    
    [m_pImageData unLockDataForWrite];
	
    [self refreshTotalToRender];
	
	return self;
}

@end
