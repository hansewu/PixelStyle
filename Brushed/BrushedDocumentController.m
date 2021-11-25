#import "BrushedDocumentController.h"

@implementation BrushedDocumentController

- (int)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions
{
	[openPanel setTreatsFilePackagesAsDirectories:YES];
	[openPanel setDirectory:@"/Applications/PixelStyle.app/Contents/Resources/brushes/"];
	
	return [openPanel runModalForDirectory:nil file:nil types:extensions];
}

@end
