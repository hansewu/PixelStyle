#import "XCFImporter.h"
#import "XCFLayer.h"
#import "PSController.h"
#import "PSWarning.h"
#import "PSDocument.h"
#import "PSSelection.h"
#import "PSAlignment.h"
#import "PSOperations.h"

@implementation XCFImporter

static inline void fix_endian_read(int *input, int size)
{
#ifdef __i386__
	int i;
	
	for (i = 0; i < size; i++) {
		input[i] = ntohl(input[i]);
	}
#endif
}


- (BOOL)readHeader:(FILE *)file
{
	// Check signature
	if (fread(m_aTempString, sizeof(char), 9, file) == 9) {
		if (memcmp(m_aTempString, "gimp xcf", 8))
			return NO;
	}
	else 
		return NO;
	
	// Read the version of the file
	fread(m_aTempString, sizeof(char), 5, file);
	if (memcmp(m_aTempString, "file", 4) == 0)
		m_nVersion = 0;
	else {
		if (m_aTempString[0] == 'v') {
			m_nVersion = atoi(&(m_aTempString[1]));
		}
	}
	
	// Read in the width, height and type
	fread(m_aTempIntString, sizeof(int), 3, file);
	fix_endian_read(m_aTempIntString, 2);
	// width = m_aTempIntString[0];
	// height = m_aTempIntString[1];
	m_nYype = m_aTempIntString[2];
	
	return YES;
}

- (BOOL)readProperties:(FILE *)file sharedInfo:(SharedXCFInfo *)info
{
	int propType, propSize;
	BOOL finished = NO;
	
	// Keep reading until we're finished or hit an error
	while (!finished && !ferror(file)) {
	
		// Read the property information
		fread(m_aTempIntString, sizeof(int), 2, file);
		fix_endian_read(m_aTempIntString, 2);
		propType = m_aTempIntString[0];
		propSize = m_aTempIntString[1];
		
		// Act appropriately on the property type
		switch (propType) {
			case PROP_END:
				finished = YES;
			break;
			case PROP_COLORMAP:
			
				// Store the color map and complain if we are using the problematic version 0 XCF file
				if (m_nVersion == 0) {
					return NO;
				}
				else {
					fread(m_aTempIntString, sizeof(int), 1, file);
					fix_endian_read(m_aTempIntString, 1);
					info->cmap_len = (int)m_aTempIntString[0];
					info->cmap = calloc(256 * 3, sizeof(char));
					fread(info->cmap, sizeof(char), info->cmap_len * 3, file);
				}
				
			break;
			case PROP_COMPRESSION:
			
				// Remember the compression
				fread(m_aTempString, sizeof(char), 1, file);
				info->compression = (int)(m_aTempString[0]);
				if (info->compression != COMPRESS_NONE && info->compression != COMPRESS_RLE)
					return NO;
				
			break;
			default:

				// Skip these properties but record them for saving
				fseek(file, propSize, SEEK_CUR);
				
			break;
		}
	}
	
	// If we've had a problem fail
	if (ferror(file))
		return NO;
	
	return YES;
}

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
	SharedXCFInfo info;
	int layerOffsets, offset;
	FILE *file;
	id layer;
	int i, newType = [(PSContent *)[doc contents] type];
	NSArray *layers;

	// Clear all links
	[[doc contents] clearAllLinks];

	// Open the file
	file = fopen([path fileSystemRepresentation], "rb");
	if (file == NULL) {
		return NO;
	}
	
	// Read the header
	if ([self readHeader:file] == NO) {
		fclose(file);
		return NO;
	}
	
	// NSLog(@"Properties begin: %d", ftell(file));
	
	// Read properties
	if ([self readProperties:file sharedInfo:&info] == NO) {
		fclose(file);
		return NO;
	}
	
	// NSLog(@"Properties end: %d", ftell(file));
	
	// Provide the type for the layer
	info.type = m_nYype;
	
	// Determine the offset for the next layer
	i = 0;
	layerOffsets = ftell(file);
	layers = [NSArray array];
	do {
		fseek(file, layerOffsets + i * sizeof(int), SEEK_SET);
		fread(m_aTempIntString, sizeof(int), 1, file);
		fix_endian_read(m_aTempIntString, 1);
		offset = m_aTempIntString[0];
		// NSLog(@"Layer begins: %d", offset);
		
		// If it exists, move to it
		if (offset != 0) {
			layer = [[XCFLayer alloc] initWithFile:file offset:offset document:doc sharedInfo:&info];
			if (layer == NULL) {
				for (i = 0; i < [layers count]; i++)
					[[layers objectAtIndex:i] autorelease];
				fclose(file);
				return NO;
			}
			[layer convertFromType:(m_nYype == XCF_INDEXED_IMAGE) ? XCF_RGB_IMAGE : m_nYype to:newType];
			[layer setLinked:YES];
			layers = [layers arrayByAddingObject:layer];
		}
		
		i++;
	} while (offset != 0);
	
	// Add the layers
	for (i = [layers count] - 1; i >= 0; i--) {
		[[doc contents] addLayerObject:[layers objectAtIndex:i]];
	}
	
	// Close the file
	fclose(file);
	
	// We don't support indexed images any more
	if (m_nYype == XCF_INDEXED_IMAGE) {
		m_nYype = XCF_RGB_IMAGE;
		free(info.cmap);
	}
	
	// Position the new layer correctly
//	[[(PSOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
//	[[(PSOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
    
    [layer setOffsets:IntMakePoint(([(PSContent*)[doc contents] width] - [(PSLayer *)layer width]) / 2, ([(PSContent*)[doc contents] height] - [(PSLayer *)layer height]) / 2)];
	
	return YES;
}

@end
