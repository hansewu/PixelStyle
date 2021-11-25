#import "PSTexture.h"




extern int GetImageBuffer(NSImage *Image, int nWidth, int nHeight, unsigned char *pBufRGBA, int bAlphaPremultiplied);


@implementation PSTexture

- (id)initWithContentsOfFile:(NSString *)path
{
	unsigned char *tempBitmap;
	NSBitmapImageRep *tempBitmapRep;
	int k, j, l, bpr, spp;
	BOOL isDir;
	
	// Check if file is a directory
	if ([gFileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		[self autorelease];
		return NULL;
	}
	
	// Get the image
	tempBitmapRep = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:path]];
	m_nWidth = [tempBitmapRep pixelsWide];
	m_nHeight = [tempBitmapRep pixelsHigh];
	spp = [tempBitmapRep samplesPerPixel];
	bpr = [tempBitmapRep bytesPerRow];
	tempBitmap = [tempBitmapRep bitmapData];
    
    tempBitmap = malloc(m_nWidth * m_nHeight * 4);
    memset(tempBitmap, 0, m_nWidth * m_nHeight * 4);
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
    GetImageBuffer(image, m_nWidth, m_nHeight, tempBitmap, 1);
    spp = 4;
    bpr = m_nWidth * spp;
	
	// Check the bps
	if ([tempBitmapRep bitsPerSample] != 8) {
		NSLog(@"Texture \"%@\" failed to load\n", [path lastPathComponent]);
		[self autorelease];
		return NULL;
	}
	
	// Allocate space for the greyscale and color textures
	m_pColorTexture = malloc(m_nWidth * m_nHeight * 3);
	m_pGreyTexture = malloc(m_nWidth * m_nHeight);
	
	// Copy in the data
	if (((spp == 3 || spp == 4) && [[tempBitmapRep colorSpaceName] isEqualTo:NSCalibratedRGBColorSpace]) || [[tempBitmapRep colorSpaceName] isEqualTo:NSDeviceRGBColorSpace]) {
		
		for (j = 0; j < m_nHeight; j++) {
			if (spp == 3)
				memcpy(&(m_pColorTexture[j * m_nWidth * 3]), &(tempBitmap[j * bpr]), m_nWidth * 3);
			else {
				for (k = 0; k < m_nWidth; k++) {
					for (l = 0; l < spp - 1; l++)
						m_pColorTexture[j * m_nWidth * 3 + k * 3 + l] = tempBitmap[j * bpr + k * 4 + l];
				}
			}
		}
		
		for (k = 0; k < m_nWidth * m_nHeight; k++) {
			m_pGreyTexture[k] = (unsigned char)(((int)(m_pColorTexture[k * 3]) + (int)(m_pColorTexture[k * 3 + 1]) + (int)(m_pColorTexture[k * 3 + 2])) / 3);
		}
		
	}
	else if (((spp == 1 || spp == 2) && [[tempBitmapRep colorSpaceName] isEqualTo:NSCalibratedWhiteColorSpace]) || [[tempBitmapRep colorSpaceName] isEqualTo:NSDeviceWhiteColorSpace]) {
		
		for (j = 0; j < m_nHeight; j++) {
			if (spp == 1) {
				memcpy(&(m_pGreyTexture[j * m_nWidth]), &(tempBitmap[j * bpr]), m_nWidth);
			}
			else {
				for (k = 0; k < m_nWidth * m_nHeight; k++) {
					m_pGreyTexture[k] = tempBitmap[j * bpr + k * 2];
				}
			}
		}
		
		for (k = 0; k < m_nWidth * m_nHeight; k++) {
			m_pColorTexture[k * 3] = m_pGreyTexture[k];
			m_pColorTexture[k * 3 + 1] = m_pGreyTexture[k];
			m_pColorTexture[k * 3 + 2] = m_pGreyTexture[k];
		}
		
	}
	else {
		NSLog(@"Texture \"%@\" failed to load\n", [path lastPathComponent]);
		[self autorelease];
		return NULL;
	}
	
	// Remember the texture name
	m_strName = [[[path lastPathComponent] stringByDeletingPathExtension] retain];
	
    free(tempBitmap);
    
	return self;
}

- (void)dealloc
{
	if (m_pColorTexture) free(m_pColorTexture);
	if (m_pGreyTexture) free(m_pGreyTexture);
	if (m_strName) [m_strName autorelease];
	[super dealloc];
}

- (void)activate
{
}

- (void)deactivate
{
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	int thumbWidth, thumbHeight;
	NSImage *thumbnail;
	
	// Determine the thumbnail size
	thumbWidth = m_nWidth;
	thumbHeight = m_nHeight;
	if (m_nWidth > 44 || m_nHeight > 44) {
		if (m_nWidth > m_nHeight) {
			thumbHeight = (int)((float)m_nHeight * (44.0 / (float)m_nWidth));
			thumbWidth = 44;
		}
		else {
			thumbWidth = (int)((float)m_nWidth * (44.0 / (float)m_nHeight));
			thumbHeight = 44;
		}
	}
    
	// Create the representation
	tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pColorTexture pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:m_nWidth * 3 bitsPerPixel:8 * 3];

	// Wrap it up in an NSImage
	thumbnail = [[NSImage alloc] initWithSize:NSMakeSize(thumbWidth, thumbHeight)];
	[thumbnail setScalesWhenResized:YES];
	[thumbnail addRepresentation:tempRep];
	[tempRep autorelease];
	[thumbnail autorelease];
	
	return thumbnail;
}

- (NSString *)name
{
	return m_strName;
}

- (int)width
{
	return m_nWidth;
}

- (int)height
{
	return m_nHeight;
}

- (unsigned char *)texture:(BOOL)color
{
	return (color) ? m_pColorTexture : m_pGreyTexture;
}

- (NSColor *)textureAsNSColor:(BOOL)color
{
	NSColor *nsColor;
	NSImage *image;
	NSBitmapImageRep *rep;
	
	image = [[NSImage alloc] initWithSize:NSMakeSize(m_nWidth, m_nHeight)];
	
	if (color)
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pColorTexture pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:m_nWidth * 3 bitsPerPixel:24];
	else
		rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pGreyTexture pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:m_nWidth bitsPerPixel:8];
	
	[image addRepresentation:rep];
	[image autorelease];
	[rep autorelease];
	
	nsColor = [NSColor colorWithPatternImage:image];
	
	return nsColor;
}

- (NSComparisonResult)compare:(id)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

@end
