#import "XBMImporter.h"
#import "XBMLayer.h"
#import "PSController.h"
#import "PSWarning.h"
#import "PSContent.h"
#import "PSDocument.h"
#import "PSOperations.h"
#import "PSAlignment.h"

@implementation XBMImporter

inline static int parse_value(char *input, char *value)
{
	char *temp;
	int i = 0;
	
	if (strstr(input, "#define")) {
		temp = strstr(input, value);
		if (temp) {
			temp += strlen(value);
			do { 
				temp++;
				if (*temp == 0x00) return -1;
			} while (*temp < '0' || *temp > '9');
			do {
				input[i] = *temp;
				i++; temp++;
			} while (*temp >= '0' && *temp <= '9');
			input[i] = 0x00;
			return atoi(input);
		}
	}
	
	return -1;
}

- (BOOL)addToDocument:(id)doc contentsOfFile:(NSString *)path
{
	FILE *file;
	char buffer[4096], temp;
	SharedXBMInfo info;
	id layer;
	int newType = [(PSContent *)[doc contents] type];
		
	// Parse the width and height of the image
	file = fopen([path fileSystemRepresentation], "rb");
	info.width = info.height = -1;
	do {
		fgets(buffer, 4096, file);
		if (info.width == -1) info.width = parse_value(buffer, "width");
		if (info.height == -1) info.height = parse_value(buffer, "height");
	} while ((info.width == -1 || info.height == -1) && !(ferror(file) || feof(file)));
	
	// Fail if something went wrong
	if (info.width == -1 || info.height == -1) {
		fclose(file);
		return NO;
	}

	// Goto the thingy
	do {
		temp = fgetc(file);
	} while ((temp != '{') && !(ferror(file) || feof(file)));
	
	// Fail if something went wrong
	if (ferror(file) || feof(file)) {
		fclose(file);
		return NO;
	}
	
	// Create the layer
	fseek(file, -1, SEEK_CUR);
	layer = [[XBMLayer alloc] initWithFile:file offset:ftell(file) document:doc sharedInfo:&info];
	if (layer == NULL) {
		fclose(file);
		return NO;
	}
	[layer convertFromType:XCF_GRAY_IMAGE to:newType];
	[[doc contents] addLayerObject:layer];

	// Close the file
	fclose(file);
	
	// Position the new layer correctly
//	[[(PSOperations *)[doc operations] seaAlignment] centerLayerHorizontally:NULL];
//	[[(PSOperations *)[doc operations] seaAlignment] centerLayerVertically:NULL];
    
    [layer setOffsets:IntMakePoint(([(PSContent*)[doc contents] width] - [(PSLayer *)layer width]) / 2, ([(PSContent*)[doc contents] height] - [(PSLayer *)layer height]) / 2)];
	
	return YES;
}

@end
