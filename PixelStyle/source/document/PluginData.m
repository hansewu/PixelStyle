#import "PluginData.h"
#import "PSLayer.h"
#import "PSDocument.h"
#import "PSContent.h"
#import "PSSelection.h"
#import "PSWhiteboard.h"
#import "PSHelpers.h"
#import "PSController.h"
#import "PSPrefs.h"
#import "EffectTool.h"
#import "PSTools.h"

#import "UtilitiesManager.h"

@implementation PluginData

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pluginShouldRun:) name:@"PLUGINSHOULDRUN" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PLUGINSHOULDRUN" object:nil];
    [super dealloc];
}

- (IntRect)selection
{
    if ([[(PSDocument *)document selection] active]){
        IntRect layerRect = IntMakeRect(0, 0, [(PSLayer *)[[document contents] activeLayer] width], [(PSLayer *)[[document contents] activeLayer] height]);
        IntRect validRect = IntConstrainRect([[(PSDocument *)document selection] localRect], layerRect);
		return validRect;
    }
	else
		return IntMakeRect(0, 0, [(PSLayer *)[[document contents] activeLayer] width], [(PSLayer *)[[document contents] activeLayer] height]);
}

- (unsigned char *)data
{
	return [(PSLayer *)[[document contents] activeLayer] getDirectData];
}

- (unsigned char *)whiteboardData
{
	return [(PSWhiteboard *)[document whiteboard] data];
}

- (unsigned char *)replace
{
	return [(PSWhiteboard *)[document whiteboard] replace];
}

- (unsigned char *)overlay
{
	return [(PSWhiteboard *)[document whiteboard] overlay];
}

- (int)spp
{
	return [[document contents] spp];
}

- (int)channel
{
	if ([[(PSDocument *)document selection] floating])
		return kAllChannels;
	else
		return [[document contents] selectedChannel];	
}

- (int)width
{
	return [(PSLayer *)[[document contents] activeLayer] width];
}

- (int)height
{
	return [(PSLayer *)[[document contents] activeLayer] height];
}

- (BOOL)hasAlpha
{
    return YES; //都当做普通层来处理，无背景层
	return [(PSLayer *)[[document contents] activeLayer] hasAlpha];
}

- (IntPoint)point:(int)index;
{
	return [[[document tools] getTool:kEffectTool] point:index];
}

- (NSColor *)foreColor:(BOOL)calibrated
{
	if (calibrated)
		if ([[document contents] spp] == 2)
			return [[[document contents] foreground] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		else
			return [[[document contents] foreground] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	else
		return [[document contents] foreground];
}

- (NSColor *)backColor:(BOOL)calibrated
{
	if (calibrated)
		if ([[document contents] spp] == 2)
			return [[[document contents] background] colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		else
			return [[[document contents] background] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	else
		return [[document contents] background];
}

- (CGColorSpaceRef)displayProf
{
	return [[document whiteboard] displayProf];
}

- (id)window
{
	if ([[PSController m_idPSPrefs] effectsPanel])
		return NULL;
	else
		return [document window];
}

- (void)setOverlayBehaviour:(int)value
{
	[[document whiteboard] setOverlayBehaviour:value];
}

- (void)setOverlayOpacity:(int)value
{
	[[document whiteboard] setOverlayOpacity:value];
}

- (void)applyWithNewDocumentData:(unsigned char *)data spp:(int)spp width:(int)width height:(int)height
{
	NSDocument *newDocument;
	
	if (data == NULL || data == [(PSWhiteboard *)[document whiteboard] data] || data == [(PSLayer *)[[document contents] activeLayer] getDirectData])
    {
		NSRunAlertPanel(@"Critical Plug-in Malfunction", @"The plug-in has returned the same pointer passed to it (or returned NULL). This is a critical malfunction, please refrain from further use of this plug-in and contact the plug-in's developer.", @"OK", NULL, NULL);
	}
	else
    {
		newDocument = [[PSDocument alloc] initWithData:data type:(spp == 4) ? 0 : 1 width:width height:height];
		[[NSDocumentController sharedDocumentController] addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
		[newDocument autorelease];
	}
}

- (void)apply
{
    id contents = [document contents], layer;
    layer = [contents activeLayer];
    [layer applyPreviewInRect:[self selection] changeDis:YES];
    [layer updateThumbnail];
    
    //[(PegasusUtility *)[[PSController utilitiesManager] pegasusUtilityFor:document] update:kPegasusUpdateLayerView];
}

- (void)preview
{
    id contents = [document contents];
    id layer = [contents activeLayer];
    if ([[document whiteboard] getOverlayOpacity] == 0) {
        [layer canclePreviewInRect:IntRectMakeNSRect([self selection])];
        return;
    }
	//[(PSHelpers *)[document helpers] overlayChanged:[self selection] inThread:NO];
    
    [layer updatePreviewEffectForInRect:IntRectMakeNSRect([self selection]) inThread:NO mode:0];
}

- (void)cancel
{
	[(PSWhiteboard *)[document whiteboard] clearOverlay];
	
    //[(PSHelpers *)[document helpers] overlayChanged:[self selection] inThread:NO];
    
    id contents = [document contents];
    id layer = [contents activeLayer];
    [layer canclePreviewInRect:IntRectMakeNSRect([self selection])];
}

- (void)pluginShouldRun:(NSNotification*) notification
{
    id contents = [document contents];
    id layer = [contents activeLayer];
    [layer InitialPreviewDataForRect:[self selection]];
}

@end
