#import "PSApplication.h"

@implementation PSApplication


- (unsigned int)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return NSFontPanelFaceModeMask | NSFontPanelSizeModeMask | NSFontPanelCollectionModeMask;
}

- (void)terminate:(nullable id)sender
{
    [super terminate:sender];
}

@end
