#import "PSBrush.h"
#import "Bitmap.h"

typedef struct {
  unsigned int   header_size;  /*  header_size = sizeof (BrushHeader) + brush name  */
  unsigned int   version;      /*  brush file version #  */
  unsigned int   width;        /*  width of brush  */
  unsigned int   height;       /*  height of brush  */
  unsigned int   bytes;        /*  depth of brush in bytes */
  unsigned int   magic_number; /*  GIMP brush magic number  */
  unsigned int   spacing;      /*  brush spacing  */
} BrushHeader;

#define GBRUSH_MAGIC    (('G' << 24) + ('I' << 16) + ('M' << 8) + ('P' << 0))

#ifdef TODO
#warning Anti-aliasing for pixmap brushes?
#endif

extern void determineBrushMask(unsigned char *input, unsigned char *output, int width, int height, int index1, int index2);

@implementation PSBrush

- (id)initWithContentsOfFile:(NSString *)path
{
	FILE *file;
	BrushHeader header;
	BOOL versionGood = NO;
	char nameString[512];
	int nameLen, tempSize;
	
	// Open the brush file
	file = fopen([path fileSystemRepresentation] ,"rb");
	if (file == NULL) {
		NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
		[self autorelease];
		return NULL;
	}
	
	// Read in the header
	fread(&header, sizeof(BrushHeader), 1, file);
	
	// Convert brush header to proper endianess
//#ifdef __i386__
	header.header_size = ntohl(header.header_size);
	header.version = ntohl(header.version);
	header.width = ntohl(header.width);
	header.height = ntohl(header.height);
	header.bytes = ntohl(header.bytes);
	header.magic_number = ntohl(header.magic_number);
	header.spacing = ntohl(header.spacing);
//#endif
    
	// Check version compatibility
	versionGood = (header.version == 2 && header.magic_number == GBRUSH_MAGIC);
	versionGood = versionGood || (header.version == 1); 
	if (!versionGood) {
		NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
		[self autorelease];
		return NULL;
	}
	
	// Accomodate version 1 brushes (no spacing)
	if (header.version == 1) {
		fseek(file, -8, SEEK_CUR);
		header.header_size += 8;
		header.spacing = 25;
	}
	
	// Store information from the header
	m_nWidth = header.width;
	m_nHeight = header.height;
	m_nSpacing = header.spacing;
	
	// Read in brush name
	nameLen = header.header_size - sizeof(header);
	if (nameLen > 512) { [self autorelease]; return NULL; }
	if (nameLen > 0) {
		fread(nameString, sizeof(char), nameLen, file);
		m_strName = [[NSString alloc] initWithUTF8String:nameString];
	}
	else {
		m_strName = [[NSString alloc] initWithString:LOCALSTR(@"untitled", @"Untitled")];
	}
	
	// And then read in the important stuff
	switch (header.bytes) {
		case 1:
			m_bUsePixmap = NO;
			tempSize = m_nWidth * m_nHeight;
			m_pMask = malloc(make_128(tempSize));
			if (fread(m_pMask, sizeof(char), tempSize, file) < tempSize) {
				NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
				[self autorelease];
				return NULL;
			}
		break;
		case 4:
			m_bUsePixmap = YES;
			tempSize = m_nWidth * m_nHeight * 4;
			m_pPixmap = malloc(make_128(tempSize));
			if (fread(m_pPixmap, sizeof(char), tempSize, file) < tempSize) {
				NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
				[self autorelease];
				return NULL;
			}
			m_pPrePixmap = malloc(tempSize);
			premultiplyBitmap(4, m_pPrePixmap, m_pPixmap, m_nWidth * m_nHeight);
		break;
		default:
			NSLog(@"Brush \"%@\" failed to load\n", [path lastPathComponent]);
			[self autorelease];
			return NULL;
		break;
	}

	// Close the brush file
	fclose(file);
	
	return self;
}

- (void)dealloc
{
	int i;
	
	if (m_pCMMaskCache) {
		for (i = 0; i < kBrushCacheSize; i++) {
			if (m_pCMMaskCache[i].cache) free(m_pCMMaskCache[i].cache);
		}
		free(m_pCMMaskCache);
	}
	if (m_pScaled) free(m_pScaled);
	if (m_pPositioned) free(m_pPositioned);
	if (m_strName) [m_strName autorelease];
	if (m_pMask) free(m_pMask);
	if (m_pPixmap) free(m_pPixmap);
	if (m_pPrePixmap) free(m_pPrePixmap);
	[super dealloc];
}

- (void)activate
{
	int i;
	
	// Deactivate ourselves first (just in case)
	[self deactivate];
	
	// Reset the cache
	m_nCheckCount = 0;
	m_pCMMaskCache = malloc(sizeof(CachedMask) * kBrushCacheSize);
	for (i = 0; i < kBrushCacheSize; i++) {
		m_pCMMaskCache[i].cache = malloc(make_128((m_nWidth + 2) * (m_nHeight + 2)));
		m_pCMMaskCache[i].index1 = m_pCMMaskCache[i].index2 = m_pCMMaskCache[i].scale = -1;
		m_pCMMaskCache[i].lastCheck = 0;
	}
	m_pScaled = malloc(make_128(m_nWidth * m_nHeight));
	m_pPositioned = malloc(make_128(m_nWidth * m_nHeight));
}

- (void)deactivate
{
	int i;
	
	// Free the cache
	if (m_pCMMaskCache) {
		for (i = 0; i < kBrushCacheSize; i++) {
			if (m_pCMMaskCache[i].cache) free(m_pCMMaskCache[i].cache);
			m_pCMMaskCache[i].cache = NULL;
		}
		free(m_pCMMaskCache);
		m_pCMMaskCache = NULL;
	}
	if (m_pScaled) { free(m_pScaled); m_pScaled = NULL; }
	if (m_pPositioned) { free(m_pPositioned); m_pPositioned = NULL; }
}

- (NSString *)pixelTag
{
	unichar tchar;
	int i, start, end;
	BOOL canCut = NO;
	
	if (m_nWidth > 40 || m_nHeight > 40) {
		start = end = -1;
		for (i = 0; i < [m_strName length]; i++) {
			tchar = [m_strName characterAtIndex:i];
			if (tchar == '(') { 
				start = i + 1;
				canCut = YES;
			}
			else if (canCut) {
				if (tchar == '0')
					start = i + 1;
				else
					canCut = NO;
			}
			if (tchar == ')') end = i;
		}
		if (start != -1 && end != -1) {
			return [m_strName substringWithRange:NSMakeRange(start, end - start)];
		}
	}
	
	return NULL;
}

- (NSImage *)thumbnail
{
	NSBitmapImageRep *tempRep;
	int thumbWidth, thumbHeight;
	NSImage *thumbnail;
	
	// Determine the thumbnail size
	thumbWidth = m_nWidth;
	thumbHeight = m_nHeight;
	if (m_nWidth > 40 || m_nHeight > 40) {
		if (m_nWidth > m_nHeight) {
			thumbHeight = (int)((float)m_nHeight * (40.0 / (float)m_nWidth));
			thumbWidth = 40;
		}
		else {
			thumbWidth = (int)((float)m_nWidth * (40.0 / (float)m_nHeight));
			thumbHeight = 40;
		}
	}
	
	// Create the representation
	if (m_bUsePixmap)
		tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pPrePixmap pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:m_nWidth * 4 bitsPerPixel:8 * 4];
	else
		tempRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&m_pMask pixelsWide:m_nWidth pixelsHigh:m_nHeight bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceBlackColorSpace bytesPerRow:m_nWidth * 1 bitsPerPixel:8 * 1];
	
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

- (int)spacing
{
	return m_nSpacing;
}

- (int)width
{
	return m_nWidth;
}

- (int)height
{
	return m_nHeight;
}

- (int)fakeWidth
{
	return m_bUsePixmap ? m_nWidth : m_nWidth + 2;
}

- (int)fakeHeight
{
	return m_bUsePixmap ? m_nHeight : m_nHeight + 2;
}

- (unsigned char *)mask
{
	return m_pMask;
}

- (unsigned char *)pixmap
{
	return m_pPixmap;
}

- (unsigned char *)maskForPoint:(NSPoint)point pressure:(int)value
{
	float remainder, factor, xextra, yextra;
	int i, index1, index2, scale, scalew, scaleh, minCheckPos;
	
	// Determine the scale
	factor = (0.30 * ((float)value / 255.0) + 0.70);
	if (m_nWidth >= m_nHeight) {
		scale = factor * m_nWidth;
	}
	else {
		scale = factor * m_nHeight;
	}
	scalew = factor * m_nWidth;
	scaleh = factor * m_nHeight;
	if ((scalew % 2 == 1 && m_nWidth % 2 == 0) || (scalew % 2 == 0 && m_nWidth % 2 == 1)) xextra = 1;
	else xextra = 0;
	if ((scaleh % 2 == 1 && m_nHeight % 2 == 0) || (scaleh % 2 == 0 && m_nHeight % 2 == 1)) yextra = 1;
	else yextra = 0;
	 
	// Determine the horizontal shift
	remainder = (point.x + xextra) - floor (point.x + xextra);
	index1 = (int)(remainder * (float)(kSubsampleLevel + 1));
	
	// Determine the vertical shift
	remainder = (point.y + yextra) - floor (point.y + yextra);
	index2 = (int)(remainder * (float)(kSubsampleLevel + 1));

	 // Increment the m_nCheckCount
	 m_nCheckCount++;
	 minCheckPos = 0;
	 
	// Check for existing brushes
	for (i = 0; i < kBrushCacheSize; i++) {
		if (m_pCMMaskCache[i].index1 == index1) {
			if (m_pCMMaskCache[i].index2 == index2) {
				if (m_pCMMaskCache[i].scale == scale) {
					m_pCMMaskCache[i].lastCheck = m_nCheckCount;
					return m_pCMMaskCache[i].cache;
				}
			}
		}
		if (m_pCMMaskCache[minCheckPos].lastCheck < m_pCMMaskCache[i].lastCheck) {
			minCheckPos = i;
		}
	}
	
	// Determine the mask
	if ((m_nWidth >= m_nHeight && scale != m_nWidth) || (m_nHeight > m_nWidth && scale != m_nHeight)) {
		GCScalePixels(m_pScaled, scalew, scaleh,  m_pMask, m_nWidth, m_nHeight, GIMP_INTERPOLATION_LINEAR, 1);
		arrangePixels(m_pPositioned, m_nWidth, m_nHeight, m_pScaled, scalew, scaleh);
		determineBrushMask(m_pPositioned, m_pCMMaskCache[minCheckPos].cache, m_nWidth, m_nHeight, index1, index2);
	}
	else {
		determineBrushMask(m_pMask, m_pCMMaskCache[minCheckPos].cache, m_nWidth, m_nHeight, index1, index2);
	}
	m_pCMMaskCache[minCheckPos].index1 = index1;
	m_pCMMaskCache[minCheckPos].index2 = index2;
	m_pCMMaskCache[minCheckPos].scale = scale;
	m_pCMMaskCache[minCheckPos].lastCheck = m_nCheckCount;
	
	return m_pCMMaskCache[minCheckPos].cache;
}

- (unsigned char *)pixmapForPoint:(NSPoint)point
{
	return m_pPixmap;
}

- (BOOL)usePixmap
{
	return m_bUsePixmap;
}

- (NSComparisonResult)compare:(id)other
{
	return [[self name] caseInsensitiveCompare:[other name]];
}

@end
