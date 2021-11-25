#import "XCFContent.h"
#import "XCFLayer.h"
#import "PSController.h"
#import "PSWarning.h"
#import "PSDocument.h"
#import "PSDocumentController.h"
#import "PSSelection.h"

@implementation XCFContent

static inline void fix_endian_read(int *input, int size)
{
#ifdef __i386__
	int i;
	
	for (i = 0; i < size; i++) {
		input[i] = ntohl(input[i]);
	}
#endif
}

+ (BOOL)typeIsEditable:(NSString *)aType
{
	return [[PSDocumentController sharedDocumentController] type: aType isContainedInDocType: @"GIMP image"];
}

- (BOOL)readHeader:(FILE *)file
{
	// Check signature
	if (fread(tempString, sizeof(char), 9, file) == 9) {
		if (memcmp(tempString, "gimp xcf", 8))
			return NO;
	}
	else 
		return NO;
	
	// Read the version of the file
	fread(tempString, sizeof(char), 5, file);
	if (memcmp(tempString, "file", 4) == 0)
		version = 0;
	else {
		if (tempString[0] == 'v') {
			version = atoi(&(tempString[1]));
		}
	}
	
	// Read in the width, height and type
	fread(tempIntString, sizeof(int), 3, file);
	fix_endian_read(tempIntString, 3);
	m_nWidth = tempIntString[0];
	m_nHeight = tempIntString[1];
	m_nType = tempIntString[2];
	
	return YES;
}

- (BOOL)readProperties:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int propType, propSize;
	BOOL finished = NO;
	int lostprops_pos;
	int parasites_start;
	char *nameString;
	int pos, i;
	
	// Keep reading until we're finished or hit an error
	while (!finished && !ferror(file)) {
	
		// Read the property information
		fread(tempIntString, sizeof(int), 2, file);
		fix_endian_read(tempIntString, 2);
		propType = tempIntString[0];
		propSize = tempIntString[1];
		
		// Act appropriately on the property type
		switch (propType) {
			case PROP_END:
				finished = YES;
			break;
			case PROP_COLORMAP:
			
				// Store the color map and complain if we are using the problematic version 0 XCF file
				if (version == 0) {
					NSRunAlertPanel(LOCALSTR(@"indexed color title", @"Indexed colour not supported"), LOCALSTR(@"indexed color body", @"XCF files using indexed colours are only supported if they are of version 1 or greater. This is because version 0 is known to have certain problems with indexed colours."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
					return NO;
				}
				else {
					fread(tempIntString, sizeof(int), 1, file);
					fix_endian_read(tempIntString, 1);
					info->cmap_len = (int)tempIntString[0];
					info->cmap = calloc(256 * 3, sizeof(char));
					fread(info->cmap, sizeof(char), info->cmap_len * 3, file);
				}
				
			break;
			case PROP_COMPRESSION:
			
				// Remember the compression
				fread(tempString, sizeof(char), 1, file);
				info->compression = (int)(tempString[0]);
				if (info->compression != COMPRESS_NONE && info->compression != COMPRESS_RLE)
					return NO;
				
			break;
			case PROP_RESOLUTION:
				
				// Remember the resolution
				fread(tempString, sizeof(float), 2, file);
				fix_endian_read((int *)tempIntString, 2);
				m_nXres = ((float *)tempString)[0];
				m_nYres = ((float *)tempString)[1];
				
			break;
			case PROP_PARASITES:
			
				// Remember the parasites
				parasites_start = ftell(file);
				while (ftell(file) - parasites_start < propSize && !ferror(file)) {
				
					// Expand list of parasites
					if (m_nParasitesCount == 0) {
						m_nParasitesCount++;
						m_psParasites = malloc(sizeof(ParasiteData));
					}
					else {
						m_nParasitesCount++;
						m_psParasites = realloc(m_psParasites, sizeof(ParasiteData) * m_nParasitesCount);
					}
					pos = m_nParasitesCount - 1; 
					
					// Remember name
					fread(tempIntString, sizeof(int), 1, file);
					fix_endian_read(tempIntString, 1);
					if (tempIntString[0] > 0) {
						nameString = malloc(tempIntString[0]);
						i = 0;
						do {
							if (i < tempIntString[0]) {
								nameString[i] = fgetc(file);
								i++;
							}
						} while (nameString[i - 1] != 0 && !ferror(file));
						m_psParasites[pos].name = [[NSString alloc] initWithUTF8String:nameString];
						free (nameString);
					}
					else {
						m_psParasites[pos].name = [[NSString alloc] initWithString:@"unnamed"];
					}
					
					// Remember flags and data size
					fread(tempIntString, sizeof(int), 2, file);
					fix_endian_read(tempIntString, 2);
					m_psParasites[pos].flags = tempIntString[0];
					m_psParasites[pos].size = tempIntString[1];
					
					// Remember data
					if (m_psParasites[pos].size > 0) {
						m_psParasites[pos].data = malloc(m_psParasites[pos].size);
						fread(m_psParasites[pos].data, sizeof(char), m_psParasites[pos].size, file);
					}
					
				}
				
			break;
			default:

				// Skip these properties but record them for saving
				fseek(file, -2 * sizeof(int), SEEK_CUR);
				lostprops_pos = m_nLostpropsLen;
				if (m_nLostpropsLen == 0) {
					m_nLostpropsLen = 2 * sizeof(int) + propSize;
					m_pLostprops = malloc(m_nLostpropsLen);
				}
				else {
					m_nLostpropsLen += 2 * sizeof(int) + propSize;
					m_pLostprops = realloc(m_pLostprops, m_nLostpropsLen);
				}
				fread(&(m_pLostprops[lostprops_pos]), sizeof(char), 2 * sizeof(int) + propSize, file);
				
			break;
		}
	}
	
	// If we've had a problem fail
	if (ferror(file))
		return NO;
	
	return YES;
}

- (id)initWithDocument:(id)doc contentsOfFile:(NSString *)path;
{
	SharedXCFInfo info;
	int layerOffsets, offset;
	FILE *file;
	id layer;
	int i;
	BOOL maskToAlpha = NO;
	ParasiteData *exifParasite;
	NSString *errorString;
	NSData *exifContainer;
	
	// Initialize superclass first
	if (![super initWithDocument:doc])
		return NULL;
	
	// Open the file
	file = fopen([path fileSystemRepresentation], "rb");
	if (file == NULL) {
		[self autorelease];
		return NULL;
	}
	
	// Read the header
	if ([self readHeader:file] == NO) {
		fclose(file);
		[self autorelease];
		return NULL;
	}
	
	// Express warning if necessary
	if (version > 2)
		NSRunAlertPanel(LOCALSTR(@"xcf version title", @"XCF version not supported"), LOCALSTR(@"xcf version body", @"The version of the XCF file you are trying to load is not supported by this program, loading may fail."), LOCALSTR(@"ok", @"OK"), NULL, NULL);
	
	// NSLog(@"Properties begin: %d", ftell(file));
	
	// Read properties
	if ([self readProperties:file sharedInfo:&info] == NO) {
		fclose(file);
		[self autorelease];
		return NULL;
	}
	
	// NSLog(@"Properties end: %d", ftell(file));
	
	// Provide the type for the layer
	info.type = m_nType;
	
	// Determine the offset for the next layer
	i = 0;
	layerOffsets = ftell(file);
	m_arrLayers = [NSArray array];
	do {
		fseek(file, layerOffsets + i * sizeof(int), SEEK_SET);
		fread(tempIntString, sizeof(int), 1, file);
		fix_endian_read(tempIntString, 1);
		offset = tempIntString[0];
		// NSLog(@"Layer begins: %d", offset);
		
		// If it exists, move to it
		if (offset != 0) {
			layer = [[XCFLayer alloc] initWithFile:file offset:offset document:doc sharedInfo:&info];
			if (layer == NULL) {
				fclose(file);
				[m_arrLayers retain];
				[self autorelease];
				return NULL;
			}
			m_arrLayers = [m_arrLayers arrayByAddingObject:layer];
			if (info.active)
				m_nActiveLayerIndex = i;
			maskToAlpha = maskToAlpha || info.maskToAlpha;
		}
		
		i++;
	} while (offset != 0);
	[m_arrLayers retain];
    
    m_nActiveLayerIndex = 0;
    [self setActiveLayerIndexComplete:m_nActiveLayerIndex];
	
	// Check for channels
	fseek(file, layerOffsets + i * sizeof(int), SEEK_SET);
	fread(tempIntString, sizeof(int), 1, file);
	fix_endian_read(tempIntString, 1);
	if (tempIntString[0] != 0) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"channels message", @"This XCF file contains channels which are not currently supported by PixelStyle. These channels will be lost upon saving.") forDocument: doc level:kHighImportance];
	}
	
	// Close the file
	fclose(file);
	
	// Do some final checks to make sure we're are working with reasonable figures before returning ourselves
	if ( m_nXres < kMinResolution || m_nYres < kMinResolution || m_nXres > kMaxResolution || m_nYres > kMaxResolution)
		m_nXres = m_nYres = 72;
	if (m_nWidth < kMinImageSize || m_nHeight < kMinImageSize || m_nWidth > kMaxImageSize || m_nHeight > kMaxImageSize) {
		[self autorelease];
		return NULL;
	}
	
	// We don't support indexed images any more
	if (m_nType == XCF_INDEXED_IMAGE) {
		m_nType = XCF_RGB_IMAGE;
		free(info.cmap);
	}
	
	// Inform user if we've composited the mask to the alpha channel
	if (maskToAlpha) {
		[[PSController seaWarning] addMessage:LOCALSTR(@"mask-to-alpha message", @"Some of the masks in this image have been composited to their layer's alpha channel. These masks will be lost upon saving.") forDocument: doc level:kHighImportance];
	}
	
	// Store EXIF data
	exifParasite = [self parasiteWithName:@"exif-plist"];
	if (exifParasite) {
		exifContainer = [NSData dataWithBytesNoCopy:exifParasite->data length:exifParasite->size freeWhenDone:NO];
		m_dicExifData = [NSPropertyListSerialization propertyListFromData:exifContainer mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
		[m_dicExifData retain];
	}
	[self deleteParasiteWithName:@"exif-plist"];
	
	return self;
}

@end
