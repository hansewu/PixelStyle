#import "CropOptions.h"
#import "PSController.h"
#import "PSHelp.h"
#import "PSDocument.h"
#import "PSTools.h"
#import "CropTool.h"
#import "PSMargins.h"
#import "PSOperations.h"
#import "PSContent.h"
#import "AspectRatio.h"

#define customItemIndex 2

@implementation CropOptions

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //[m_idAspectRatio setToolTip:NSLocalizedString(@"Set the drawing shape of marquee tool", nil)];
    [m_idCrop setToolTip:NSLocalizedString(@"Crop", nil)];
    
    [m_idAspectRatio awakeWithMaster:self andString:@"crop"];
}

- (NSSize)ratio
{
	return [m_idAspectRatio ratio];
}

- (int)aspectType
{
	return [m_idAspectRatio aspectType];
}

- (IBAction)crop:(id)sender
{
	IntRect cropRect;
	int width, height;
	
	cropRect = [[[gCurrentDocument tools] currentTool] cropRect];
	if (cropRect.size.width < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.height < kMinImageSize) { NSBeep(); return; }
	if (cropRect.size.width > kMaxImageSize) { NSBeep(); return; }
	if (cropRect.size.height > kMaxImageSize) { NSBeep(); return; }
	width = [(PSContent *)[gCurrentDocument contents] width];
	height = [(PSContent *)[gCurrentDocument contents] height];
	[(PSMargins *)[(PSOperations *)[gCurrentDocument operations] seaMargins] setMarginLeft:-cropRect.origin.x top:-cropRect.origin.y right:(cropRect.origin.x + cropRect.size.width) - width bottom:(cropRect.origin.y + cropRect.size.height) - height index:kAllLayers];
	[[[gCurrentDocument tools] currentTool] clearCrop];
}

- (void)shutdown
{
	[m_idAspectRatio shutdown];
}

- (void)setCropButtonHidden:(BOOL)hidden
{
    [m_idCrop setHidden:hidden];
}

@end
